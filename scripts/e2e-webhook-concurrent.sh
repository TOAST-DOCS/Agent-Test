#!/usr/bin/env bash
#
# e2e-webhook-concurrent.sh — 같은 ko 파일을 만지는 동시 PR 시나리오를 **webhook
# 경로로** 검증한다. 시나리오는 `e2e-concurrent-prs.sh` 와 같고, 다른 것은 번역을
# 누가 돌리느냐 하나다:
#
#   e2e-concurrent-prs.sh    로컬 translate_pr.py 가 번역 (webhook 은 끈다)
#   e2e-webhook-concurrent   PR open/merge 를 GitHub 이 webhook pod 으로 보내고,
#                            배포된 ko-review / translate Jenkins 잡이 번역한다
#
# 그래서 이쪽은 로컬 코드가 아니라 **배포본**(webhook 이미지 + Jenkins 의 translate
# 잡 브랜치)을 검증한다. 로컬 판이 통과해도 webhook 이 PR 하나를 놓치거나, 두 번째
# PR 의 잡이 첫 번째 잡의 파라미터·base 를 물려받는 식의 결함은 여기서만 보인다.
#
# 시나리오:
#   0) Agent-Test 를 webhook 대상으로 활성화 + 세션 base e2e-webhook-conc/<ts> 를
#      alpha 에서 갈라 canonical 스냅샷(archive/alpha-origin) 으로 복원, 필터의
#      base_branches 에 세션 브랜치 append (종료 시 원복)
#   1) ko PR A (overview.md 섹션 본문 수정) · ko PR B (같은 파일에 신규 섹션 +
#      표 행 추가) 를 **연달아** open → 두 opened 딜리버리가 각각 ko-review 를
#      트리거하는지 (두 잡이 동시에 돈다)
#   2) B 머지 → webhook → B translate 잡 → B 번역 PR → 머지
#   3) A 머지 (git 3-way 로 ko 는 A+B) → webhook → A translate 잡 → A 번역 PR
#   4) 검증: A 번역 PR head 의 en/ja 가 B 의 콘텐츠(신규 섹션 anchor, 표 행)를
#      **보존**하는가 — A 번역이 "ko 에 없는 en 섹션" 으로 오판해 B 번역을 지우면
#      FAIL (merge-commit ref 수정 전의 결함, e2e-concurrent-prs.sh 헤더 참고)
#
# 번역 PR 의 merge 도 webhook 을 탄다 (head `translate/*` → 순차 큐의 완료 처리).
# 번역 PR 에는 `한글 검수` 라벨이 없어 translate 필터의 label_require(AND) 에서
# 걸러지므로 번역 PR 자체를 다시 번역하지는 않는다.
#
# 번역 큐(TRANSLATE_TRANSLATE_QUEUE_REPOS)가 켜져 있든 꺼져 있든 결과는 같아야
# 한다 — A 는 B 의 번역 PR 이 머지된 **뒤에** 머지되므로 큐에서 기다릴 일이 없다.
# 앞 번역이 미머지인 창에서 두 번째가 머지되는 경우(lag-order / 큐 대기)는 이
# 스크립트의 범위가 아니다.
#
# Exit code: 0 = PASS, 1 = B 콘텐츠 유실(결함 재현), 2 = 하네스 오류,
#            3 = webhook 트리거/빌드 실패
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-webhook-concurrent.sh
#   bash scripts/e2e-webhook-concurrent.sh --timeout 600 --build-timeout 1800
#   bash scripts/e2e-webhook-concurrent.sh --keep   # 세션 브랜치·작업 디렉터리 보존
#
# 의존성: git, gh(로그인), curl, python3, DASHBOARD_* (load_env.sh)
set -euo pipefail

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
REPO_URL="https://github.com/${REPO}.git"
BASE_SOURCE="alpha"
POLL_TIMEOUT=600      # 초. 딜리버리 → task 등장까지.
POLL_INTERVAL=5
BUILD_TIMEOUT=1800    # 초. 각 Jenkins 빌드 완료 대기 상한.
# 초. Jenkins executor 를 기다리는 시간 (task 가 queued 인 동안). 빌드 실행 시간
# (--build-timeout) 과 따로 센다 — 운영 번역 잡이 executor 를 잡고 있으면 e2e 빌드는
# 시작도 못 한 채 기다린다 (2026-10-01 실측: CDN#102 · Service-Gateway#87 두 운영
# 빌드 뒤에서 30분 대기 → 빌드 시간 제한에 걸려 거짓 실패).
EXECUTOR_TIMEOUT=3600
KEEP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout)       POLL_TIMEOUT="$2"; shift 2 ;;
    --build-timeout) BUILD_TIMEOUT="$2"; shift 2 ;;
    --executor-timeout) EXECUTOR_TIMEOUT="$2"; shift 2 ;;
    --keep)          KEEP=1; shift ;;
    -h|--help)       sed -n '2,45p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다. load_env.sh 를 source 하세요." >&2
  exit 2
fi

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
# e2e 산출물 PR 에 'e2e' 라벨 (사람이 만든 PR 과 구분)
source "$SCRIPTS/e2e-label.sh"
source "$SCRIPTS/e2e-webhook-task.sh"     # find/wait_for_webhook_task, wait_for_build_finish
source "$SCRIPTS/e2e-webhook-toggle.sh"   # set_webhook_repo_enabled
source "$SCRIPTS/e2e-webhook-filter.sh"   # extend_filters_for_branch, restore_filters

TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e-webhook-conc/${TS}"
BR_A="translate-test-webhook-conc/${TS}-a"
BR_B="translate-test-webhook-conc/${TS}-b"
KO_FILE="ko/overview.md"
TOKEN_B_ANCHOR="concurrent-b-added"          # B 신규 섹션의 anchor id (언어 무관)
TOKEN_B_ROW="x9c"                            # B 신규 표 행의 key 셀 (한글 없음 → 그대로 복사됨)
TOKEN_A_EDIT="concurrent-a-edit"             # A 본문 수정 문장에 심는 ASCII 토큰

# 공유 체크아웃(~/works/toast-docs/Agent-Test)의 HEAD 를 건드리지 않도록 임시 clone.
WORK="$(mktemp -d /tmp/e2e-webhook-conc-XXXXXX)"
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
echo "  webhook concurrent-PR e2e — Agent-Test"
echo "  session base : $SESSION$( ((KEEP)) || echo ' (종료 시 삭제)' )"
echo "  PR A / B     : $BR_A / $BR_B"
echo "==================================================================="

# ── 0) 세션 base + webhook 활성화 + 필터 확장 ──────────────────────────
echo
echo "[0/7] webhook 활성화 + 세션 base 준비"
set_webhook_repo_enabled true

git clone --quiet "$REPO_URL" "$WORK/repo"
cd "$WORK/repo"
git checkout --quiet -b "$SESSION" "origin/${BASE_SOURCE}"
# alpha 의 ko/en/ja 는 다른 작업으로 드리프트할 수 있다 — e2e-concurrent-prs.sh
# 와 같은 canonical 스냅샷 + heading 문법 정규화로 시작점을 고정한다 (이유는 그
# 스크립트의 같은 자리 주석). 필터를 넓히기 **전에** push 하므로 이 커밋은 어떤
# 잡도 트리거하지 않는다 (push 는 pull_request 이벤트가 아니기도 하다).
bash scripts/restore-alpha-origin.sh >/dev/null
sed -i -E 's/^(#{1,6})([^ #])/\1 \2/' ko/*.md en/*.md ja/*.md
if ! git diff --quiet; then
  git add ko en ja
  git commit --quiet -m "e2e(webhook-concurrent): restore canonical snapshot + normalize heading syntax"
fi
git push --quiet origin "$SESSION"
SESSION_PUSHED=1
extend_filters_for_branch "$SESSION"

# ── ko/overview.md 변형기 (e2e-concurrent-prs.sh 와 같은 변형) ──────────
mutate() {  # $1: a|b
  python3 - "$1" "$KO_FILE" <<PY
import sys
which, path = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()

if which == "a":
    # 기존 섹션 본문 수정: 첫 h2 아래 첫 산문 문단 끝에 문장 추가
    lines = text.split("\n")
    hit = None
    seen_h2 = False
    for i, l in enumerate(lines):
        if l.startswith("## "):
            seen_h2 = True
            continue
        s = l.strip()
        if seen_h2 and s and not s.startswith(("#", "<", "{", "|", "-", "*", ">", "\`")):
            hit = i
            break
    assert hit is not None, "no prose paragraph found"
    lines[hit] = lines[hit] + " (동시 PR 테스트 A: 이 문장은 ${TOKEN_A_EDIT} 검증용입니다.)"
    text = "\n".join(lines)
elif which == "b":
    # (1) 첫 표의 마지막 행 뒤에 신규 행 추가
    lines = text.split("\n")
    last_row = None
    in_table = False
    for i, l in enumerate(lines):
        if l.lstrip().startswith("|"):
            in_table = True
            last_row = i
        elif in_table:
            break
    assert last_row is not None, "no table found"
    lines.insert(last_row + 1, "| ${TOKEN_B_ROW} | 동시 PR 테스트용으로 추가한 타입입니다. 실제 서비스에는 존재하지 않습니다. |")
    text = "\n".join(lines)
    # (2) 문서 끝에 신규 섹션 추가 (anchor + { #id })
    if not text.endswith("\n"):
        text += "\n"
    text += (
        "\n"
        '<a id="${TOKEN_B_ANCHOR}"></a>\n'
        "## 동시 PR 테스트 추가 섹션 { #${TOKEN_B_ANCHOR} }\n"
        "\n"
        "이 섹션은 동시 PR 시나리오 검증을 위해 PR B 가 추가한 섹션입니다. "
        "PR A 의 번역이 이 섹션의 번역을 지우면 안 됩니다.\n"
    )
open(path, "w", encoding="utf-8").write(text)
PY
}

# translate 필터의 label_require(`content-agent,한글 검수`, AND) 를 통과하도록 라벨.
for lbl in "content-agent" "한글 검수"; do
  if ! gh label list --repo "$REPO" --search "$lbl" --json name --jq '.[].name' 2>/dev/null | grep -Fxq "$lbl"; then
    gh label create "$lbl" --repo "$REPO" --color "1d76db" --description "webhook filter label" 2>/dev/null || true
  fi
done
e2e_ensure_label "$REPO"

make_pr() {  # $1: branch  $2: a|b  $3: title  → PR URL 출력
  git checkout --quiet -b "$1" "$SESSION"
  mutate "$2"
  git add "$KO_FILE"
  git commit --quiet -m "$3"
  git push --quiet origin "$1"
  gh pr create --repo "$REPO" --base "$SESSION" --head "$1" \
    --label "content-agent" --label "한글 검수" --label "$E2E_LABEL" \
    --title "$3" --body "webhook concurrent-PR e2e ($2) — scripts/e2e-webhook-concurrent.sh" 2>/dev/null | tail -1
  git checkout --quiet "$SESSION"
}

# 결과 요약용
R_REVIEW_A="-"; R_REVIEW_B="-"; R_TRANS_B="-"; R_TRANS_A="-"; R_VERIFY="-"
TRANS_A_URL=""; TRANS_B_URL=""

summary() {
  echo
  echo "==================================================================="
  echo "  결과 요약"
  echo "==================================================================="
  echo "  session                      : $SESSION"
  echo "  PR A                         : ${PR_A_URL:-}"
  echo "  PR B                         : ${PR_B_URL:-}"
  echo "  opened A → ko-review          : $R_REVIEW_A"
  echo "  opened B → ko-review          : $R_REVIEW_B"
  echo "  merged B → translate          : $R_TRANS_B  ${TRANS_B_URL}"
  echo "  merged A → translate          : $R_TRANS_A  ${TRANS_A_URL}"
  echo "  A 번역이 B 콘텐츠 보존        : $R_VERIFY"
  echo "==================================================================="
}

task_status() {  # $1=job_id $2=task_id → status 문자열
  curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$1" 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
t = next((x for x in (d.get('job') or {}).get('tasks', []) if x.get('id') == '$2'), None) or {}
print(t.get('status') or '-')
" 2>/dev/null || echo "-"
}

# 딜리버리 → task → 빌드 완료까지. stdout 마지막 줄 = PASS / FAIL (...).
# 진행 로그는 stderr 로 (호출부가 $( ) 로 결과만 받는다).
await_job() {  # $1=pr_url $2=action $3=kind
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

# 번역 잡이 연 번역 PR — head 가 `translate/<source head>-…`, base 는 세션 브랜치.
find_translation_pr() {  # $1=source head branch → URL (없으면 빈 문자열)
  local deadline=$(( $(date +%s) + 120 )) u=""
  while (( $(date +%s) < deadline )); do
    u="$(gh pr list --repo "$REPO" --base "$SESSION" --state open --limit 50 \
          --json url,headRefName \
          --jq "[.[] | select(.headRefName | startswith(\"translate/$1-\"))][0].url // \"\"" 2>/dev/null || true)"
    [[ -n "$u" ]] && { echo "$u"; return 0; }
    sleep 5
  done
  echo ""
}

# ── 1) 두 ko PR 을 연달아 open → 각각 ko-review ─────────────────────────
echo
echo "[1/7] PR A (본문 수정) · PR B (신규 섹션 + 표 행) 연달아 open"
PR_A_URL="$(make_pr "$BR_A" a "[e2e] webhook concurrent PR A — body edit (${TS})")"
echo "  A: $PR_A_URL"
PR_B_URL="$(make_pr "$BR_B" b "[e2e] webhook concurrent PR B — new section + table row (${TS})")"
echo "  B: $PR_B_URL"
[[ -n "$PR_A_URL" && -n "$PR_B_URL" ]] || { echo "error: PR 생성 실패" >&2; summary; exit 2; }

echo
echo "[2/7] opened × 2 → ko-review × 2 (두 잡이 동시에 돈다)"
# 두 딜리버리는 이미 거의 동시에 나갔다 — A 빌드를 기다리는 동안 B 잡도 돌고
# 있으므로, B 는 대개 등장 판정과 함께 이미 끝나 있다. 판정만 순서대로 한다.
R_REVIEW_A="$(await_job "$PR_A_URL" opened ko-review)" || true
R_REVIEW_B="$(await_job "$PR_B_URL" opened ko-review)" || true
echo "  ko-review A: $R_REVIEW_A · B: $R_REVIEW_B"

# ── 2) B 머지 → B 번역 → B 번역 PR 머지 ──────────────────────────────
echo
echo "[3/7] B 머지 → webhook → B translate"
gh pr merge "$PR_B_URL" --repo "$REPO" --merge >/dev/null
R_TRANS_B="$(await_job "$PR_B_URL" closed translate)" || true
echo "  B translate: $R_TRANS_B"
[[ "$R_TRANS_B" == PASS ]] || { summary; exit 3; }
TRANS_B_URL="$(find_translation_pr "$BR_B")"
[[ -n "$TRANS_B_URL" ]] || { echo "error: B 번역 PR 을 찾지 못함 (base=$SESSION head=translate/$BR_B-*)" >&2; summary; exit 2; }
echo "  B 번역 PR: $TRANS_B_URL"
e2e_label_pr "$REPO" "$TRANS_B_URL"

echo
echo "[4/7] B 번역 PR 머지"
gh pr merge "$TRANS_B_URL" --repo "$REPO" --merge >/dev/null
# sanity: 세션 브랜치 en/ja 양쪽에 B 콘텐츠가 실제로 들어갔는지 — 빠진 언어는 A
# 가 지운 게 아니라 B 번역이 스킵된 것이므로 하네스 전제 실패(exit 2)로 가른다.
git fetch --quiet origin "$SESSION"
for lang in en ja; do
  for tok in "$TOKEN_B_ANCHOR" "$TOKEN_B_ROW"; do
    if ! git show "origin/${SESSION}:${lang}/overview.md" | grep -q "$tok"; then
      echo "error: B 번역이 세션 브랜치 ${lang} 에 반영되지 않음 (token=${tok} — 하네스 전제 실패)" >&2
      summary; exit 2
    fi
  done
done
echo "  세션 en/ja 에 B 콘텐츠 반영 확인"

# ── 3) A 머지 → A 번역 ────────────────────────────────────────────────
echo
echo "[5/7] A 머지 → webhook → A translate"
gh pr merge "$PR_A_URL" --repo "$REPO" --merge >/dev/null
git fetch --quiet origin "$SESSION"
if ! git show "origin/${SESSION}:${KO_FILE}" | grep -q "$TOKEN_B_ANCHOR"; then
  echo "error: A 머지 후 ko 에서 B 섹션이 사라짐 — git 머지 자체가 예상과 다름" >&2
  summary; exit 2
fi
R_TRANS_A="$(await_job "$PR_A_URL" closed translate)" || true
echo "  A translate: $R_TRANS_A"
[[ "$R_TRANS_A" == PASS ]] || { summary; exit 3; }
TRANS_A_URL="$(find_translation_pr "$BR_A")"
[[ -n "$TRANS_A_URL" ]] || { echo "error: A 번역 PR 을 찾지 못함 (base=$SESSION head=translate/$BR_A-*)" >&2; summary; exit 2; }
echo "  A 번역 PR: $TRANS_A_URL"
e2e_label_pr "$REPO" "$TRANS_A_URL"

# ── 4) 검증 ───────────────────────────────────────────────────────────
echo
echo "[6/7] 검증: A 번역 PR head 의 en/ja 가 B 콘텐츠를 보존하는가"
TRANS_A_REF="$(gh api "repos/${REPO}/pulls/${TRANS_A_URL##*/}" -q .head.ref)"
git fetch --quiet origin "$TRANS_A_REF"
fail=0
for lang in en ja; do
  content="$(git show "FETCH_HEAD:${lang}/overview.md" 2>/dev/null || true)"
  if [[ -z "$content" ]]; then
    echo "  [$lang] overview.md 없음 — 하네스 오류" >&2
    summary; exit 2
  fi
  for tok in "$TOKEN_B_ANCHOR" "$TOKEN_B_ROW"; do
    if grep -q "$tok" <<<"$content"; then
      echo "  [$lang] B 토큰 '$tok': PRESENT ✓"
    else
      echo "  [$lang] B 토큰 '$tok': MISSING ✗  ← B 콘텐츠 유실"
      fail=1
    fi
  done
  if grep -qi "$TOKEN_A_EDIT" <<<"$content"; then
    echo "  [$lang] A 편집 토큰: PRESENT ✓"
  else
    echo "  [$lang] A 편집 토큰: MISSING (sanity — 비치명, 모델이 토큰을 번역했을 수 있음)"
  fi
done

echo
echo "[7/7] 결과"
if (( fail )); then
  R_VERIFY="FAIL — A 번역 PR 이 B 의 en/ja 콘텐츠를 유실"
  summary; exit 1
fi
R_VERIFY="PASS"
summary
[[ "$R_REVIEW_A" == PASS && "$R_REVIEW_B" == PASS ]] || exit 3
exit 0
