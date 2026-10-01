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
# --case 로 B 의 변경 모양을 고른다. section-add 만 지금 배포본에서 통과하는
# 대조군이고, 나머지 셋은 순차 큐가 꺼져 있으면 **실패하는 것이 기대값**이다 —
# lag 창이 실제로 결함을 내는 모양들이다 (2026-09-28 시뮬레이션 · RDS-FOR-
# POSTGRESQL #90→#91). 큐(#1048)가 켜지면 셋 다 통과해야 한다.
#
#   section-add    B 가 문서 끝에 신규 섹션 추가. A 는 stale skip(#898) 으로 B
#                  섹션을 건너뛴다 → PASS (기본값)
#   anchor-rename  B 가 기존 섹션(#fix-links-langdir)의 anchor id 를 바꾼다. A 의
#                  ko 에는 옛 id 가 없으므로 en/ja 의 옛 id 섹션을 지우고, 새 id
#                  섹션은 자기 변경이 아니라 건너뛴다 → A 번역 PR 이 B 의 섹션을
#                  건드리고 두 번역 PR 이 충돌하거나 섹션이 사라진다 (기대 FAIL)
#   section-move   B 가 기존 섹션(#fix-links-nested)을 문서 끝으로 옮긴다. A 가
#                  en/ja 를 ko 순서로 맞추며 같은 섹션을 옮겨 두 번역 PR 이 같은
#                  자리를 건드린다 (기대 FAIL)
#   b-closed       B 의 번역 PR 이 머지되지 않고 닫힌다 (번역 실패·운영자 닫음과
#                  같은 상태). A 는 B 섹션을 건너뛰므로 B 섹션은 en/ja 에 **영영
#                  번역되지 않는다** (기대 FAIL — 검증 2 의 anchor 순서 불일치)
#
# 판정은 세 케이스 공통이다: 검증 1 = A 번역 PR 의 diff 가 B 가 건드린 anchor 를
# 담은 줄을 추가·삭제하지 않는가, 검증 2 = 최종 en/ja 의 `<a id>` 순서가 ko 와
# 같은가 (추가·이름 변경·이동·유실을 한 질문으로 덮는다).
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
#   bash scripts/e2e-webhook-lag-order.sh --case anchor-rename   # 기대 exit 1 (큐 꺼짐)
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
# 초. Jenkins executor 를 기다리는 시간 (task 가 queued 인 동안). 빌드 실행 시간
# (--build-timeout) 과 따로 센다 — 운영 번역 잡이 executor 를 잡고 있으면 e2e 빌드는
# 시작도 못 한 채 기다린다 (2026-10-01 실측: CDN#102 · Service-Gateway#87 두 운영
# 빌드 뒤에서 30분 대기 → 빌드 시간 제한에 걸려 거짓 실패).
EXECUTOR_TIMEOUT=3600
KEEP=0
DOC="${DOC:-fix-links.md}"
QUEUE_LABEL="번역 대기열"
CASE="section-add"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout)       POLL_TIMEOUT="$2"; shift 2 ;;
    --build-timeout) BUILD_TIMEOUT="$2"; shift 2 ;;
    --executor-timeout) EXECUTOR_TIMEOUT="$2"; shift 2 ;;
    --doc)           DOC="$2"; shift 2 ;;
    --keep)          KEEP=1; shift ;;
    --case)          CASE="$2"; shift 2 ;;
    -h|--help)       sed -n '2,70p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

# B 가 건드리는 anchor — 검증 1 은 A 번역 PR diff 에서 이 id 를 담은 줄을 찾는다.
RENAME_FROM="fix-links-langdir"; RENAME_TO="fix-links-langdir-renamed"
MOVE_ID="fix-links-nested"
case "$CASE" in
  section-add|b-closed) TOUCH=("lag-order-b-added") ;;
  anchor-rename)        TOUCH=("$RENAME_FROM" "$RENAME_TO") ;;
  section-move)         TOUCH=("$MOVE_ID") ;;
  *) echo "unknown --case: $CASE (section-add|anchor-rename|section-move|b-closed)" >&2; exit 2 ;;
esac

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
SESSION="e2e-webhook-lag/${TS}-${CASE}"
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
echo "  webhook lag-order e2e — Agent-Test (doc=$DOC, case=$CASE)"
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
# 검증 2 는 "최종 en/ja 의 anchor 순서 == ko" 를 묻는다 — 시작점에서 이미 다르면
# 그 판정이 B·A 와 무관하게 실패하므로 여기서 하네스 전제로 확인한다.
anchor_seq() { grep -oE '<a id="[^"]+"' | sed -E 's/<a id="([^"]+)"/\1/'; }
for lang in en ja; do
  if [[ "$(anchor_seq < "ko/$DOC")" != "$(anchor_seq < "$lang/$DOC")" ]]; then
    echo "error: 시작점에서 ko/$lang $DOC 의 anchor 순서가 다름 (하네스 전제 실패)" >&2; exit 2
  fi
done
for id in "${TOUCH[@]}"; do
  [[ "$CASE" == anchor-rename && "$id" == "$RENAME_TO" ]] && continue
  [[ "$CASE" == section-add || "$CASE" == b-closed ]] && continue
  grep -q "<a id=\"$id\">" "ko/$DOC" || { echo "error: ko/$DOC 에 #$id 가 없음" >&2; exit 2; }
done
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
elif which == "b" and "${CASE}" == "anchor-rename":
    old, new = "${RENAME_FROM}", "${RENAME_TO}"
    assert f'<a id="{old}"></a>' in text and f"{{ #{old} }}" in text
    text = text.replace(f'<a id="{old}"></a>', f'<a id="{new}"></a>')
    text = text.replace(f"{{ #{old} }}", f"{{ #{new} }}")
elif which == "b" and "${CASE}" == "section-move":
    # 섹션 = 그 <a id> 줄부터 다음 <a id> 줄 직전까지. 문서 끝으로 옮긴다.
    lines = text.rstrip("\n").split("\n")
    start = lines.index('<a id="${MOVE_ID}"></a>')
    end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith("<a id="))
    block = lines[start:end]
    while block and not block[-1].strip():
        block.pop()
    rest = lines[:start] + lines[end:]
    text = "\n".join(rest) + "\n\n" + "\n".join(block) + "\n"
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
R_V1="-"; R_MERGE="-"; R_V2="-"; QUEUE_MODE="-"
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
  echo "  case                           : $CASE"
  echo "  검증1 A 번역이 B 변경 안 건드림: $R_V1"
  echo "  번역 PR 머지 (B → A)           : $R_MERGE"
  echo "  검증2 최종 en/ja anchor == ko  : $R_V2"
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
  # executor 대기는 빌드 시간 제한에 넣지 않는다 (위 EXECUTOR_TIMEOUT 주석).
  local qdeadline=$(( $(date +%s) + EXECUTOR_TIMEOUT ))
  while [[ "$(task_status "$jid" "$tid")" == queued ]] && (( $(date +%s) < qdeadline )); do sleep 10; done
  if [[ "$(task_status "$jid" "$tid")" == queued ]]; then
    echo "  FAIL: ${EXECUTOR_TIMEOUT}s 동안 Jenkins executor 를 못 받음 (task 가 queued)" >&2
    echo "FAIL (executor timeout)"; return 1
  fi
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
echo "[1/8] PR B ($CASE) · PR A (다른 섹션 본문 수정) 연달아 open"
PR_B_URL="$(make_pr "$BR_B" b "[e2e] webhook lag-order PR B — ${CASE} (${TS})")"
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
# FETCH_HEAD 는 다음 fetch 가 덮어쓴다 — 바로 SHA 로 고정한다 (아래에서 세션을
# fetch 한 뒤에도 FETCH_HEAD 를 B 번역으로 읽어 전제를 거짓 실패시킨 적이 있다).
TRANS_B_SHA="$(git rev-parse FETCH_HEAD)"
# 하네스 전제: B 번역 PR 이 en/ja 를 B 의 ko 와 같은 anchor 순서로 만들었는가 —
# 아니면 이후의 실패는 A 가 아니라 B 번역 자체의 결함이다.
git fetch --quiet origin "$SESSION"
ko_b_seq="$(git show "origin/${SESSION}:ko/$DOC" | anchor_seq)"
for lang in en ja; do
  if [[ "$(git show "${TRANS_B_SHA}:${lang}/$DOC" | anchor_seq)" != "$ko_b_seq" ]]; then
    echo "error: B 번역 PR 의 ${lang} anchor 순서가 B 의 ko 와 다름 (하네스 전제 실패)" >&2
    diff <(echo "$ko_b_seq") <(git show "${TRANS_B_SHA}:${lang}/$DOC" | anchor_seq) | sed 's/^/    /' >&2 || true
    summary; exit 2
  fi
done
echo "  B 번역 PR en/ja anchor 순서 == B 의 ko ✓"
if [[ "$CASE" == b-closed ]]; then
  echo "  [b-closed] B 번역 PR 을 머지하지 않고 닫는다 (번역 실패·운영자 닫음과 같은 상태)"
  gh pr close "$TRANS_B_URL" --repo "$REPO" >/dev/null
  TRANS_B_URL="$TRANS_B_URL (닫음)"
fi

# ── 3) A 머지 → A 번역 ────────────────────────────────────────────────
echo
echo "[4/8] A 머지 (ko 에 B 섹션 · en/ja 에는 아직 없음) → webhook → A translate"
gh pr merge "$PR_A_URL" --repo "$REPO" --merge >/dev/null
git fetch --quiet origin "$SESSION"
if [[ "$(git show "origin/${SESSION}:ko/$DOC" | anchor_seq)" != "$ko_b_seq" ]]; then
  echo "error: A 머지 후 ko anchor 순서가 B 의 것과 다름 — git 머지가 예상과 다름" >&2; summary; exit 2
fi
if [[ "$(git show "origin/${SESSION}:en/$DOC" | anchor_seq)" == "$ko_b_seq" ]]; then
  echo "error: en 이 이미 B 의 모양 — 창(window) 재현 실패" >&2; summary; exit 2
fi
R_TRANS_A="$(await_job "$PR_A_URL" closed translate)" || true
echo "  A translate: $R_TRANS_A"
[[ "$R_TRANS_A" == PASS ]] || { summary; exit 3; }

TRANS_A_URL="$(find_translation_pr "$BR_A" 60)"
B_MERGED_EARLY=0
if [[ -z "$TRANS_A_URL" ]] && has_label "$PR_A_URL" "$QUEUE_LABEL"; then
  # 큐 모드 — A 는 B 번역 PR 머지를 기다린다. 머지하면 webhook 이 A 를 깨운다.
  if [[ "$CASE" == b-closed ]]; then
    # 닫힌 번역 PR 은 완료가 아니다 — A 는 B 가 재번역·머지될 때까지 기다리는 게
    # 정답이고, 그 대기 자체가 이 케이스의 기대 동작이다.
    QUEUE_MODE="on (B 번역 닫힘 → A 대기 유지)"
    R_V1="PASS (A 대기)"; R_MERGE="-"; R_V2="PASS (A 가 번역하지 않고 대기 — 닫힘은 완료가 아님)"
    summary
    echo "RESULT: PASS — 큐가 닫힌 번역 PR 을 완료로 치지 않고 A 를 대기시켰다"
    exit 0
  fi
  QUEUE_MODE="on (A 가 '$QUEUE_LABEL' 로 대기 → B 번역 머지 후 차례)"
  echo "  A 에 '$QUEUE_LABEL' — 큐 모드. B 번역 PR 을 먼저 머지해 A 를 깨운다"
  gh pr merge "$TRANS_B_URL" --repo "$REPO" --merge >/dev/null
  B_MERGED_EARLY=1
  TRANS_A_URL="$(find_translation_pr "$BR_A" "$BUILD_TIMEOUT")"
fi
[[ -n "$TRANS_A_URL" ]] || { echo "error: A 번역 PR 을 찾지 못함" >&2; summary; exit 2; }
[[ "$QUEUE_MODE" == "-" ]] && QUEUE_MODE="off (A 잡이 바로 번역)"
echo "  A 번역 PR: $TRANS_A_URL"
e2e_label_pr "$REPO" "$TRANS_A_URL"

# ── 4) 검증 1 ────────────────────────────────────────────────────────
echo
echo "[5/8] 검증 1: A 번역 PR 의 diff 가 B 가 건드린 anchor (${TOUCH[*]}) 를 추가·삭제하지 않는가"
TRANS_A_REF="$(gh api "repos/${REPO}/pulls/${TRANS_A_URL##*/}" -q .head.ref)"
git fetch --quiet origin "$TRANS_A_REF"
TRANS_A_SHA="$(git rev-parse FETCH_HEAD)"
fail=0; v1_fail=0
for lang in en ja; do
  # 큐 모드에서는 A 가 B 번역이 머지된 en 위에서 돌므로 B 섹션이 있는 게 정상이다
  # — 그때는 '새로 넣었는가' 를 A 번역 PR 의 diff(추가 줄)로 본다.
  patch="$(gh api "repos/${REPO}/pulls/${TRANS_A_URL##*/}/files" --paginate \
             --jq ".[] | select(.filename == \"${lang}/$DOC\") | .patch" 2>/dev/null || true)"
  for id in "${TOUCH[@]}"; do
    added="$(grep -E '^\+' <<<"$patch" | grep -cF "$id" || true)"
    removed="$(grep -E '^-' <<<"$patch" | grep -cF "$id" || true)"
    if (( added + removed > 0 )); then
      echo "  [$lang] #$id: A 번역 PR 이 +${added} −${removed} 줄 ✗  ← A 의 잡이 B 의 변경을 건드렸다"
      v1_fail=1
    else
      echo "  [$lang] #$id: A 번역 PR 이 건드리지 않음 ✓"
    fi
  done
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
if [[ "$CASE" == b-closed ]]; then
  echo "  [b-closed] B 번역 PR 은 닫혀 있다 — A 번역 PR 만 머지"
elif (( ! B_MERGED_EARLY )); then
  gh pr merge "$TRANS_B_URL" --repo "$REPO" --merge >/dev/null
fi
if gh pr merge "$TRANS_A_URL" --repo "$REPO" --merge >/dev/null 2>&1; then
  R_MERGE="PASS"
else
  R_MERGE="FAIL (A 번역 PR 머지 충돌)"
  echo "RESULT: FAIL ($CASE) — A 번역 PR 이 B 번역 PR 과 충돌 (결함 재현)"
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
echo "[7/8] 검증 2: 세션 브랜치 en/ja 의 <a id> 순서가 ko 와 같은가"
v2_fail=0
ko_final="$(git show "origin/${SESSION}:ko/$DOC" | anchor_seq)"
for lang in en ja; do
  got="$(git show "origin/${SESSION}:${lang}/$DOC" | anchor_seq)"
  if [[ "$got" == "$ko_final" ]]; then
    echo "  [$lang] anchor $(wc -l <<<"$got")개 순서 == ko ✓"
  else
    echo "  [$lang] anchor 순서 ≠ ko ✗  (< ko · > $lang)"
    diff <(echo "$ko_final") <(echo "$got") | grep -E '^[<>]' | sed 's/^/      /' || true
    v2_fail=1
  fi
done
if (( v2_fail )); then R_V2="FAIL"; fail=1; else R_V2="PASS"; fi

echo
echo "[8/8] 결과"
summary
if (( fail )); then
  echo "RESULT: FAIL ($CASE) — A 번역이 B 의 변경을 건드렸거나 최종 en/ja 가 ko 와 어긋남 (결함 재현)"
  exit 1
fi
echo "RESULT: PASS ($CASE) — 번역 잡이 자기 PR 의 diff 안에서만 움직였고 최종 en/ja 가 ko 와 같다"
[[ "$R_REVIEW_A" == PASS && "$R_REVIEW_B" == PASS ]] || exit 3
exit 0
