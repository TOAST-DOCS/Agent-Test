#!/usr/bin/env bash
#
# e2e-webhook-lag-order.sh — 앞선 번역 PR 이 아직 미머지인 창(window) 안에서 다른
# ko PR 이 머지되는 순서를 **webhook 경로로** 검증한다. 시나리오는
# `e2e-translation-lag-order.sh` 와 같고, 번역을 로컬 translate_pr.py 가 아니라
# GitHub webhook → 배포된 webhook pod → Jenkins translate 잡이 돌린다
# (`e2e-webhook-concurrent.sh` 가 concurrent 시나리오에 대해 하는 것과 같은 관계).
#
# 시나리오 (실운영 순서 그대로 — nhn-cloud-foundry#37→#38, Dooray
# cloud-user-guide-agent/359):
#   0) Agent-Test 를 webhook 대상으로 활성화 + 세션 base e2e-webhook-lag/<ts>
#      (canonical 스냅샷 + heading 정규화 + en/ja machine_translated 헤더 선삽입),
#      필터 base_branches 에 세션 브랜치 append (종료 시 원복)
#   1) ko PR B (문서 끝에 신규 섹션) · ko PR A (다른 섹션 본문 수정) 연달아 open
#      → ko-review 두 잡
#   2) B 머지 → webhook → B translate 잡 → B 번역 PR — **열어 둔다**
#   3) A 머지 (ko 에는 B 섹션, en/ja 에는 아직 없다) → webhook → A translate 잡
#   4) 검증 1: A 번역 PR 의 en/ja 에 B 섹션이 **없다** (A 의 잡은 자기 diff 안에서만
#      움직여야 하고, B 섹션은 B 번역 PR 의 몫이다)
#   5) B 번역 PR 머지 → A 번역 PR 머지 (#36 → #38 순서)
#   6) 검증 2: 세션 브랜치 en/ja 에 B 섹션 anchor · heading 이 **정확히 1번**
#
# 순차 번역 큐 (#1048, TRANSLATE_TRANSLATE_QUEUE_REPOS) 가 이 리포에 켜져 있으면
# 3) 의 A 잡은 번역하지 않고 A 에 `번역 대기열` 라벨을 남긴다 — 그때는 B 번역 PR
# 을 먼저 머지하고(webhook 이 A 를 깨운다) A 번역 PR 을 기다린다. 어느 모드로
# 돌았는지는 요약의 `queue` 줄에 남는다. 큐가 꺼져 있으면 이 e2e 는 lag 창을
# 그대로 재현한다.
#
# 픽스처는 `{ko,en,ja}/fix-links.md` (--doc 로 변경). `overview.md` 를 쓰지 않는
# 이유는 e2e-translation-lag-order.sh 헤더 참고 (앵커 없는 소절 churn → 두 번역
# PR 이 같은 절을 다른 문장으로 다시 써 충돌).
#
# Exit code: 0 = PASS, 1 = 결함 재현 (A 가 B 섹션을 넣음 · 최종 사본 ≠1 · 번역 PR
#            머지 충돌), 2 = 하네스 오류, 3 = webhook 트리거/빌드 실패
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-webhook-lag-order.sh
#   bash scripts/e2e-webhook-lag-order.sh --doc fix-links.md --build-timeout 1800 --keep
#
# 의존성: git, gh(로그인), curl, python3, DASHBOARD_* (load_env.sh)
set -euo pipefail

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
REPO_URL="https://github.com/${REPO}.git"
BASE_SOURCE="alpha"
POLL_TIMEOUT=600
POLL_INTERVAL=5
BUILD_TIMEOUT=1800
KEEP=0
DOC="${DOC:-fix-links.md}"
QUEUE_LABEL="번역 대기열"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout)       POLL_TIMEOUT="$2"; shift 2 ;;
    --build-timeout) BUILD_TIMEOUT="$2"; shift 2 ;;
    --doc)           DOC="$2"; shift 2 ;;
    --keep)          KEEP=1; shift ;;
    -h|--help)       sed -n '2,46p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다. load_env.sh 를 source 하세요." >&2
  exit 2
fi

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS/e2e-label.sh"
source "$SCRIPTS/e2e-webhook-task.sh"     # find/wait_for_webhook_task, wait_for_build_finish
source "$SCRIPTS/e2e-webhook-toggle.sh"   # set_webhook_repo_enabled
source "$SCRIPTS/e2e-webhook-filter.sh"   # extend_filters_for_branch, restore_filters

TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e-webhook-lag/${TS}"
BR_A="translate-test-webhook-lag/${TS}-a"
BR_B="translate-test-webhook-lag/${TS}-b"
TOKEN_B_ANCHOR="lag-order-b-added"
TOKEN_A_EDIT="lag-order-a-edit"

WORK="$(mktemp -d /tmp/e2e-webhook-lag-XXXXXX)"
SESSION_PUSHED=0

cleanup() {
  local ec=$?
  restore_filters
  set_webhook_repo_enabled false
  if (( SESSION_PUSHED && ! KEEP )); then
    echo "  [cleanup] deleting session branch origin/$SESSION (남아있는 PR 은 자동 close)"
    git -C "$WORK/repo" push --quiet origin ":$SESSION" 2>/dev/null || \
      echo "  [cleanup] WARN: 세션 브랜치 삭제 실패" >&2
  fi
  if (( KEEP )); then echo "  [keep] workdir=$WORK session=$SESSION"; else rm -rf "$WORK"; fi
  exit $ec
}
trap cleanup EXIT INT TERM

echo "==================================================================="
echo "  webhook lag-order e2e — Agent-Test (doc=$DOC)"
echo "  session base : $SESSION$( ((KEEP)) || echo ' (종료 시 삭제)' )"
echo "  PR B / A     : $BR_B / $BR_A"
echo "==================================================================="

# ── 0) 세션 base ─────────────────────────────────────────────────────
echo
echo "[0/8] webhook 활성화 + 세션 base 준비"
set_webhook_repo_enabled true
git clone --quiet "$REPO_URL" "$WORK/repo"
cd "$WORK/repo"
[[ -f "ko/$DOC" ]] || { echo "error: ko/$DOC 없음" >&2; exit 2; }
git checkout --quiet -b "$SESSION" "origin/${BASE_SOURCE}"
bash scripts/restore-alpha-origin.sh >/dev/null
sed -i -E 's/^(#{1,6})([^ #])/\1 \2/' ko/*.md en/*.md ja/*.md
# machine_translated 헤더 선삽입 — 이유는 e2e-translation-lag-order.sh 의 같은 자리.
for lang in en ja; do
  if ! head -1 "$lang/$DOC" | grep -q "machine_translated"; then
    printf '<!-- machine_translated: true -->\n\n%s' "$(cat "$lang/$DOC")" > "$lang/$DOC"
    echo >> "$lang/$DOC"
  fi
done
if ! git diff --quiet; then
  git add ko en ja
  git commit --quiet -m "e2e(webhook-lag-order): restore snapshot + normalize headings + machine_translated header"
fi
git push --quiet origin "$SESSION"
SESSION_PUSHED=1
extend_filters_for_branch "$SESSION"

mutate() {  # $1: a|b
  python3 - "$1" "ko/$DOC" <<PY
import sys
which, path = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
if which == "a":
    lines = text.split("\n")
    hit = None; seen_h2 = False
    for i, l in enumerate(lines):
        if l.startswith("## "):
            seen_h2 = True; continue
        s = l.strip()
        if seen_h2 and s and not s.startswith(("#", "<", "{", "|", "-", "*", ">", "\`")):
            hit = i; break
    assert hit is not None, "no prose paragraph found"
    lines[hit] = lines[hit] + " (순서 테스트 A: 이 문장은 ${TOKEN_A_EDIT} 검증용입니다.)"
    text = "\n".join(lines)
elif which == "b":
    if not text.endswith("\n"):
        text += "\n"
    text += (
        "\n"
        '<a id="${TOKEN_B_ANCHOR}"></a>\n'
        "## 번역 지연 순서 테스트 섹션 { #${TOKEN_B_ANCHOR} }\n"
        "\n"
        "이 섹션은 PR B 가 추가했습니다. PR A 의 번역 잡은 이 섹션을 건드리지 않아야 하고, "
        "B 의 번역 PR 이 머지되면 en/ja 에 한 번만 있어야 합니다.\n"
    )
open(path, "w", encoding="utf-8").write(text)
PY
}

for lbl in "content-agent" "한글 검수"; do
  if ! gh label list --repo "$REPO" --search "$lbl" --json name --jq '.[].name' 2>/dev/null | grep -Fxq "$lbl"; then
    gh label create "$lbl" --repo "$REPO" --color "1d76db" --description "webhook filter label" 2>/dev/null || true
  fi
done
e2e_ensure_label "$REPO"

make_pr() {  # $1: branch  $2: a|b  $3: title  → PR URL
  git checkout --quiet -b "$1" "$SESSION"
  mutate "$2"
  git add "ko/$DOC"
  git commit --quiet -m "$3"
  git push --quiet origin "$1"
  gh pr create --repo "$REPO" --base "$SESSION" --head "$1" \
    --label "content-agent" --label "한글 검수" --label "$E2E_LABEL" \
    --title "$3" --body "webhook lag-order e2e ($2) — scripts/e2e-webhook-lag-order.sh" 2>/dev/null | tail -1
  git checkout --quiet "$SESSION"
}

R_REVIEW_B="-"; R_REVIEW_A="-"; R_TRANS_B="-"; R_TRANS_A="-"
R_V1="-"; R_MERGE="-"; R_V2="-"; QUEUE_MODE="off (A 잡이 바로 번역)"
TRANS_A_URL=""; TRANS_B_URL=""

summary() {
  echo
  echo "==================================================================="
  echo "  결과 요약"
  echo "==================================================================="
  echo "  session                        : $SESSION"
  echo "  PR B / A                       : ${PR_B_URL:-} / ${PR_A_URL:-}"
  echo "  opened B / A → ko-review       : $R_REVIEW_B / $R_REVIEW_A"
  echo "  merged B → translate           : $R_TRANS_B  ${TRANS_B_URL}"
  echo "  merged A → translate           : $R_TRANS_A  ${TRANS_A_URL}"
  echo "  queue                          : $QUEUE_MODE"
  echo "  검증1 A 번역에 B 섹션 없음     : $R_V1"
  echo "  번역 PR 머지 (B → A)           : $R_MERGE"
  echo "  검증2 최종 B 섹션 정확히 1번   : $R_V2"
  echo "==================================================================="
}

task_status() {  # $1=job_id $2=task_id
  curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$1" 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
t = next((x for x in (d.get('job') or {}).get('tasks', []) if x.get('id') == '$2'), None) or {}
print(t.get('status') or '-')
" 2>/dev/null || echo "-"
}

await_job() {  # $1=pr_url $2=action $3=kind → stdout PASS / FAIL (...)
  local url="$1" action="$2" kind="$3" num="${1##*/}" tj jid tid st
  if ! tj="$(wait_for_webhook_task "$url" "$num" "$action" "$kind" "$POLL_TIMEOUT" "$POLL_INTERVAL")"; then
    echo "  FAIL: ${POLL_TIMEOUT}s 내에 #$num $action → $kind task 를 감지하지 못했습니다." >&2
    echo "FAIL (no task)"; return 1
  fi
  jid="$(task_field "$tj" job_id)"; tid="$(task_field "$tj" task_id)"
  echo "  #$num $action → $kind task 감지 (jobs/$jid task=$tid)" >&2
  wait_for_build_finish "$jid" "$tid" "$BUILD_TIMEOUT" >&2 || { echo "FAIL (build timeout)"; return 1; }
  st="$(task_status "$jid" "$tid")"
  if [[ "$st" == "success" ]]; then echo "PASS"; else echo "FAIL (build $st)"; return 1; fi
}

find_translation_pr() {  # $1=source head branch [$2=timeout s] → URL
  local deadline=$(( $(date +%s) + ${2:-120} )) u=""
  while (( $(date +%s) < deadline )); do
    u="$(gh pr list --repo "$REPO" --base "$SESSION" --state open --limit 50 \
          --json url,headRefName \
          --jq "[.[] | select(.headRefName | startswith(\"translate/$1-\"))][0].url // \"\"" 2>/dev/null || true)"
    [[ -n "$u" ]] && { echo "$u"; return 0; }
    sleep 5
  done
  echo ""
}

has_label() {  # $1=PR URL $2=label → 0/1
  gh pr view "$1" --repo "$REPO" --json labels --jq '.labels[].name' 2>/dev/null | grep -Fxq "$2"
}

# ── 1) open B, A ─────────────────────────────────────────────────────
echo
echo "[1/8] PR B (신규 섹션) · PR A (다른 섹션 본문 수정) 연달아 open"
PR_B_URL="$(make_pr "$BR_B" b "[e2e] webhook lag-order PR B — new section (${TS})")"
echo "  B: $PR_B_URL"
PR_A_URL="$(make_pr "$BR_A" a "[e2e] webhook lag-order PR A — body edit (${TS})")"
echo "  A: $PR_A_URL"
[[ -n "$PR_A_URL" && -n "$PR_B_URL" ]] || { echo "error: PR 생성 실패" >&2; summary; exit 2; }

echo
echo "[2/8] opened × 2 → ko-review × 2"
R_REVIEW_B="$(await_job "$PR_B_URL" opened ko-review)" || true
R_REVIEW_A="$(await_job "$PR_A_URL" opened ko-review)" || true
echo "  ko-review B: $R_REVIEW_B · A: $R_REVIEW_A"

# ── 2) B 머지 → B 번역 PR (열어 둔다) ─────────────────────────────────
echo
echo "[3/8] B 머지 → webhook → B translate (번역 PR 은 열어 둠)"
gh pr merge "$PR_B_URL" --repo "$REPO" --merge >/dev/null
R_TRANS_B="$(await_job "$PR_B_URL" closed translate)" || true
echo "  B translate: $R_TRANS_B"
[[ "$R_TRANS_B" == PASS ]] || { summary; exit 3; }
TRANS_B_URL="$(find_translation_pr "$BR_B")"
[[ -n "$TRANS_B_URL" ]] || { echo "error: B 번역 PR 을 찾지 못함" >&2; summary; exit 2; }
echo "  B 번역 PR: $TRANS_B_URL (미머지)"
e2e_label_pr "$REPO" "$TRANS_B_URL"
TRANS_B_REF="$(gh api "repos/${REPO}/pulls/${TRANS_B_URL##*/}" -q .head.ref)"
git fetch --quiet origin "$TRANS_B_REF"
for lang in en ja; do
  if ! git show "FETCH_HEAD:${lang}/$DOC" | grep -q "$TOKEN_B_ANCHOR"; then
    echo "error: B 번역 PR 의 ${lang} 에 B 섹션이 없음 (하네스 전제 실패)" >&2; summary; exit 2
  fi
done

# ── 3) A 머지 → A 번역 ────────────────────────────────────────────────
echo
echo "[4/8] A 머지 (ko 에 B 섹션 · en/ja 에는 아직 없음) → webhook → A translate"
gh pr merge "$PR_A_URL" --repo "$REPO" --merge >/dev/null
git fetch --quiet origin "$SESSION"
git show "origin/${SESSION}:ko/$DOC" | grep -q "$TOKEN_B_ANCHOR" \
  || { echo "error: A 머지 후 ko 에 B 섹션이 없음" >&2; summary; exit 2; }
if git show "origin/${SESSION}:en/$DOC" | grep -q "$TOKEN_B_ANCHOR"; then
  echo "error: en 에 B 섹션이 이미 있음 — 창(window) 재현 실패" >&2; summary; exit 2
fi
R_TRANS_A="$(await_job "$PR_A_URL" closed translate)" || true
echo "  A translate: $R_TRANS_A"
[[ "$R_TRANS_A" == PASS ]] || { summary; exit 3; }

TRANS_A_URL="$(find_translation_pr "$BR_A" 60)"
B_MERGED_EARLY=0
if [[ -z "$TRANS_A_URL" ]] && has_label "$PR_A_URL" "$QUEUE_LABEL"; then
  # 큐 모드 — A 는 B 번역 PR 머지를 기다린다. 머지하면 webhook 이 A 를 깨운다.
  QUEUE_MODE="on (A 가 '$QUEUE_LABEL' 로 대기 → B 번역 머지 후 차례)"
  echo "  A 에 '$QUEUE_LABEL' — 큐 모드. B 번역 PR 을 먼저 머지해 A 를 깨운다"
  gh pr merge "$TRANS_B_URL" --repo "$REPO" --merge >/dev/null
  B_MERGED_EARLY=1
  TRANS_A_URL="$(find_translation_pr "$BR_A" "$BUILD_TIMEOUT")"
fi
[[ -n "$TRANS_A_URL" ]] || { echo "error: A 번역 PR 을 찾지 못함" >&2; summary; exit 2; }
echo "  A 번역 PR: $TRANS_A_URL"
e2e_label_pr "$REPO" "$TRANS_A_URL"

# ── 4) 검증 1 ────────────────────────────────────────────────────────
echo
echo "[5/8] 검증 1: A 번역 PR 의 en/ja 는 B 섹션을 넣지 않았는가"
TRANS_A_REF="$(gh api "repos/${REPO}/pulls/${TRANS_A_URL##*/}" -q .head.ref)"
git fetch --quiet origin "$TRANS_A_REF"
TRANS_A_SHA="$(git rev-parse FETCH_HEAD)"
fail=0; v1_fail=0
for lang in en ja; do
  # 큐 모드에서는 A 가 B 번역이 머지된 en 위에서 돌므로 B 섹션이 있는 게 정상이다
  # — 그때는 '새로 넣었는가' 를 A 번역 PR 의 diff(추가 줄)로 본다.
  added="$(gh api "repos/${REPO}/pulls/${TRANS_A_URL##*/}/files" --paginate \
             --jq ".[] | select(.filename == \"${lang}/$DOC\") | .patch" 2>/dev/null \
           | grep -E '^\+' | grep -c "$TOKEN_B_ANCHOR" || true)"
  if (( added > 0 )); then
    echo "  [$lang] B 섹션: A 번역 PR 이 추가 ✗  ← A 의 잡이 자기 diff 밖의 섹션을 번역해 넣었다"
    v1_fail=1
  else
    echo "  [$lang] B 섹션: A 번역 PR 이 추가하지 않음 ✓"
  fi
  if git show "${TRANS_A_SHA}:${lang}/$DOC" 2>/dev/null | grep -qi "$TOKEN_A_EDIT"; then
    echo "  [$lang] A 편집 토큰: PRESENT ✓"
  else
    echo "  [$lang] A 편집 토큰: MISSING (sanity — 비치명, 모델이 토큰을 번역했을 수 있음)"
  fi
done
if (( v1_fail )); then R_V1="FAIL"; fail=1; else R_V1="PASS"; fi

# ── 5) 번역 PR 머지 B → A ────────────────────────────────────────────
echo
echo "[6/8] B 번역 PR 머지 → A 번역 PR 머지 (#36 → #38 순서)"
if (( ! B_MERGED_EARLY )); then
  gh pr merge "$TRANS_B_URL" --repo "$REPO" --merge >/dev/null
fi
if gh pr merge "$TRANS_A_URL" --repo "$REPO" --merge >/dev/null 2>&1; then
  R_MERGE="PASS"
else
  R_MERGE="FAIL (A 번역 PR 머지 충돌)"
  echo "  A 번역 PR 머지 실패 — 충돌 위치:" >&2
  git fetch --quiet origin "$SESSION"
  tree="$(git merge-tree --write-tree "origin/$SESSION" "$TRANS_A_SHA" 2>/dev/null | head -1 || true)"
  for lang in en ja; do
    git show "${tree}:${lang}/$DOC" 2>/dev/null | grep -n -A3 '^<<<<<<<' | head -12 | sed "s/^/    [$lang] /" >&2 || true
  done
  summary; exit 1
fi
git fetch --quiet origin "$SESSION"

# ── 6) 검증 2 ────────────────────────────────────────────────────────
echo
echo "[7/8] 검증 2: 세션 브랜치 en/ja 에 B 섹션 anchor 가 정확히 1번인가"
v2_fail=0
for lang in ko en ja; do
  n="$(git show "origin/${SESSION}:${lang}/$DOC" | grep -c "<a id=\"${TOKEN_B_ANCHOR}\"></a>" || true)"
  h="$(git show "origin/${SESSION}:${lang}/$DOC" | grep -c "{ #${TOKEN_B_ANCHOR} }" || true)"
  if [[ "$n" == "1" && "$h" == "1" ]]; then
    echo "  [$lang] anchor ×$n · heading ×$h ✓"
  else
    echo "  [$lang] anchor ×$n · heading ×$h ✗  ← 사본 중복 (또는 유실)"
    [[ "$lang" == "ko" ]] || v2_fail=1
  fi
done
if (( v2_fail )); then R_V2="FAIL"; fail=1; else R_V2="PASS"; fi

echo
echo "[8/8] 결과"
summary
if (( fail )); then
  echo "RESULT: FAIL — A 의 번역이 B 섹션을 넣었거나 최종 사본이 1개가 아님 (결함 재현)"
  exit 1
fi
echo "RESULT: PASS — 번역 잡이 자기 PR 의 diff 안에서만 움직였고 최종 사본 1개"
[[ "$R_REVIEW_A" == PASS && "$R_REVIEW_B" == PASS ]] || exit 3
exit 0
