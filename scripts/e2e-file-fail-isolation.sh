#!/usr/bin/env bash
#
# 파일 단위 장애 격리 e2e — cloud-translate PR #593 검증.
#
# 검증 대상 동작: (파일 × 언어) 하나의 번역이 실패해도 잡 전체를 버리지 않고,
# 실패한 대상만 제외한 채 나머지를 커밋하고 번역 PR 을 연다.
#
#   이전 동작 (all-or-nothing): worker 의 bare asyncio.gather 가 첫 예외를 그대로
#   올려보내 두 단계 커밋 버퍼(pending_commits) 가 flush 되지 못했고, 이미 번역을
#   마친 파일들의 작업까지 통째로 폐기됐다 — Storage-Object-Storage#182 는 코드블록
#   유닛 하나 때문에 8개 파일 전부를 잃고 PR 도 안 열렸다.
#
# ── 왜 결함을 "주입" 하는가 ────────────────────────────────────────────────
# 실제 트리거(펜스/hr 패리티 가드, placeholder 생존 가드)는 **모델이 어긋날 때만**
# 발동한다. 원할 때 재현이 안 된다 — #182 에서 3/3 실패한 바로 그 유닛을 같은
# 모델로 재생하면 3/3 성공한다(실측 2026-08-20). 실패를 "바라는" e2e 는 대개 통과
# 하고 아무것도 검증하지 못하므로, cloud-translate 의 e2e 전용 설정
# TRANSLATE_FAULT_INJECT_PATHS 로 한 파일을 결정적으로 실패시킨다. 검증하려는 것은
# "무엇이 실패를 일으키는가" 가 아니라 "실패했을 때 나머지가 살아남는가" 이다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 e2e-failiso/<ts> 생성 (alpha 는 건드리지 않음)
#   2) ko 파일 3개를 소폭 수정한 head 브랜치 + PR 생성
#   3) 로컬 translate_pr.py 실행 — ko/<victim>.md 만 결함 주입
#   4) 판정 (아래 6개 규칙)
#   5) cleanup (--keep 로 보존 가능)
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) exit code != 0            — 남은 일이 있으므로 green 금지
#   (2) 콘솔에 `PARTIAL:` 마커     — 대시보드가 '부분 성공' 을 읽는 신호
#   (3) 번역 PR 이 열렸다          — 격리의 존재 이유
#   (4) 희생 파일의 en/ja 가 PR 에 없다
#   (5) 나머지 파일의 en/ja 는 PR 에 있다
#   (6) PR 본문에 실패 섹션 + PR 에 warning 라벨
#
# Usage:
#   source ./load_env.sh          # 이 스크립트는 dashboard 토큰을 쓰지 않지만
#                                 # 다른 e2e 와 같은 진입 규약을 유지한다
#   bash scripts/e2e-file-fail-isolation.sh
#   bash scripts/e2e-file-fail-isolation.sh --victim ko/overview.md
#   bash scripts/e2e-file-fail-isolation.sh --lang en      # en 만 실패 (ja 는 성공)
#   bash scripts/e2e-file-fail-isolation.sh --keep         # 세션 브랜치/PR 보존
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/review-obs-182 \
#     bash scripts/e2e-file-fail-isolation.sh              # 미배포 워크트리 검증
#
# 의존성: git, gh (로그인), python3
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-failiso/$TS"
HEAD_BRANCH="translate-test-failiso/$TS"

# 결함을 주입할 ko 파일. 나머지 두 파일은 정상 번역돼야 한다.
VICTIM="ko/component-guide.md"
# 정상 경로 대조군 — 이 파일들의 en/ja 는 반드시 PR 에 들어와야 한다.
HEALTHY=("ko/overview.md" "ko/troubleshooting-guide.md")
FAULT_LANG=""     # 비우면 두 언어 모두 실패. --lang en 이면 en 만.
KEEP=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --victim) VICTIM="$2"; shift 2 ;;
    --lang)   FAULT_LANG="$2"; shift 2 ;;
    --keep)   KEEP=1; shift ;;
    -h|--help) sed -n '1,50p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"

cleanup() {
  local rc=$?
  if (( KEEP )); then
    echo
    echo "--keep: 세션 브랜치/PR 보존 — $SESSION_BRANCH"
    return $rc
  fi
  echo
  echo "[cleanup] 세션 브랜치 정리"
  # 세션 브랜치를 base 로 하는 PR 은 base 삭제와 함께 자동 close 된다.
  # 번역 잡이 만든 translate/<head>-... 브랜치는 우리가 이름을 모르므로
  # prefix 로 조회해서 지운다 — 안 지우면 PR 이 닫혀도 브랜치만 남는다.
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/translate/$HEAD_BRANCH*" 2>/dev/null \
             | sed 's|.*refs/heads/||')
  git push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "repo        : $REPO"
echo "session base: $SESSION_BRANCH (from $BASE_SOURCE)"
echo "head        : $HEAD_BRANCH"
echo "victim      : $VICTIM${FAULT_LANG:+ (lang=$FAULT_LANG)}"
echo "healthy     : ${HEALTHY[*]}"
echo "translate   : $CLOUD_TRANSLATE_DIR"
echo

# ── 1) 세션 브랜치 ────────────────────────────────────────────────────────
# ── 0) webhook 비활성화 ───────────────────────────────────────────────
# 이 e2e 는 실제 PR 을 만들고 머지한다. webhook 이 켜져 있으면 그 PR 들이 배포된
# webhook pod -> Jenkins 의 translate/ko-review 를 중복 트리거하고, local 모드에선
# 로컬 번역과 배포본 번역이 같은 PR 을 동시에 처리해 결과가 섞인다.
# 예전에는 이 호출이 없어서 "앞서 돌린 다른 e2e 가 껐기를" 기대하고 있었다.
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화 (이 e2e 는 webhook 경유 잡 중복 트리거 방지)"
set_webhook_repo_enabled false

echo "[1/5] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git branch -f "$SESSION_BRANCH" "origin/$BASE_SOURCE" >/dev/null
git push -q origin "$SESSION_BRANCH"

# ── 2) ko 변형 + PR ───────────────────────────────────────────────────────
echo "[2/5] ko 변형 + PR 생성"
git checkout -q -B "$HEAD_BRANCH" "origin/$BASE_SOURCE"

mutate() {   # $1: ko 경로 — 첫 본문 문단 끝에 한 문장을 덧붙인다.
  local f="$1"
  [[ -f "$f" ]] || { echo "error: $f 없음" >&2; exit 1; }
  python3 - "$f" "$TS" <<'PY'
import sys, io
path, ts = sys.argv[1], sys.argv[2]
raw = io.open(path, encoding="utf-8", newline="").read()
eol = "\r\n" if "\r\n" in raw else "\n"
lines = raw.split(eol)
# 헤딩·앵커·빈 줄·펜스가 아닌 첫 산문 줄 뒤에 한 문장을 덧붙인다 —
# 유닛 하나만 "변경됨" 으로 만들어 번역 부하를 최소화.
for i, ln in enumerate(lines):
    s = ln.strip()
    if not s or s.startswith(("#", "<", "|", "```", "!!!", "-", "*", ">")):
        continue
    lines[i] = ln.rstrip() + f" (e2e 격리 검증 {ts})"
    break
else:
    raise SystemExit(f"no prose line found in {path}")
io.open(path, "w", encoding="utf-8", newline="").write(eol.join(lines))
print(f"  변형: {path}")
PY
}

mutate "$VICTIM"
for f in "${HEALTHY[@]}"; do mutate "$f"; done

# 변형한 ko 파일만 스테이지 — `git add -A` 는 절대 쓰지 말 것. 레포 루트의
# untracked 파일들(실토큰이 든 load_env.sh, archive/ 스크래치)까지 쓸어담아
# 커밋·push 한다. 2026-08-20 이 스크립트 초판이 실제로 그렇게 해서 PR #560 에
# DASHBOARD_API_TOKEN 을 노출시켰다 (브랜치를 지워도 refs/pull/<n>/head 로 계속
# 접근 가능 — 토큰 회전 외에 되돌릴 방법이 없다).
git add -- "$VICTIM" "${HEALTHY[@]}"
git commit -q -m "e2e(file-fail-isolation): ko 3개 파일 소폭 수정 ($TS)"
# 의도한 파일만 들어갔는지 커밋 후 확인 — 조용히 늘어나는 것을 막는 가드.
committed="$(git show --name-only --format= HEAD | sort)"
expected="$(printf '%s\n' "$VICTIM" "${HEALTHY[@]}" | sort)"
if [[ "$committed" != "$expected" ]]; then
  echo "error: 커밋에 의도치 않은 파일이 포함됨" >&2
  diff <(echo "$expected") <(echo "$committed") >&2 || true
  git reset -q --hard "origin/$BASE_SOURCE"
  exit 1
fi
git push -q origin "$HEAD_BRANCH"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" \
  --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(file-fail-isolation): ko 3개 파일 수정 ($TS)" \
  --body "파일 단위 장애 격리 e2e (cloud-translate #593). \`$VICTIM\` 에 결함을 주입해 그 파일만 번역에서 제외되고 나머지는 정상 번역/커밋되는지 검증합니다." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

# ── 3) 로컬 translate_pr.py (결함 주입) ───────────────────────────────────
fault_spec="$VICTIM${FAULT_LANG:+:$FAULT_LANG}"
echo
echo "[3/5] local translate_pr.py — TRANSLATE_FAULT_INJECT_PATHS=$fault_spec"
if [[ ! -f "$CLOUD_TRANSLATE_DIR/.env" ]]; then
  echo "error: $CLOUD_TRANSLATE_DIR/.env 없음 (TRANSLATE_GITHUB_TOKEN / TRANSLATE_ANTHROPIC_API_KEY 필요)" >&2
  exit 1
fi
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  # e2e 는 CLI 엔진으로 돈다 — 배포 잡의 .env 가 claude-code 이므로 프로덕션과
  # 같은 엔진을 태운다. 모델은 **두 env 모두** 필요하다: ClaudeCodeTranslator 는
  # settings.claude_code_model 을 쓰고 (translator.py:3918) anthropic_model 은 보지
  # 않으므로 CLI 에 ANTHROPIC_MODEL 만 주면 조용히 무시되고 .env 값(sonnet)이
  # 쓰인다 (2026-08-24 실측: retranslate plan 이 그 함정으로 6.07M 토큰). 반대로
  # CLI 엔진에서도 llm-patch judge·표 reconcile 등은 API translator 를 타고
  # anthropic_model 을 읽으므로 둘을 함께 둔다.
  TRANSLATE_TRANSLATE_ENGINE=claude-code \
  TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
  TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
  TRANSLATE_FAULT_INJECT_PATHS="$fault_spec" \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --diff-granularity block --glossary-mode service \
    --workers 2 --chunk-workers 2 --tm-top-k 1 \
) 2>&1 | tee "$LOG"
tx_rc=${PIPESTATUS[0]}
set -e
echo "  exit code: $tx_rc"

# ── 4) 판정 ───────────────────────────────────────────────────────────────
echo
echo "[4/5] 판정"
fails=0
ok()   { echo "  PASS  $1"; }
bad()  { echo "  FAIL  $1"; fails=$((fails + 1)); }

# (1) exit code — 남은 일이 있으므로 green 금지 (Jenkins 는 이걸로 FAILURE).
if (( tx_rc != 0 )); then ok "(1) exit code $tx_rc (non-zero)"
else bad "(1) exit code 0 — 부분 번역인데 성공으로 보고됨"; fi

# (2) PARTIAL 마커 — 대시보드가 '부분 성공' 을 판별하는 유일한 신호.
if grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(2) PARTIAL 마커: $(grep -m1 -E '^[[:space:]]*PARTIAL:' "$LOG" | sed 's/^[[:space:]]*//' | cut -c1-120)"
else bad "(2) PARTIAL 마커 없음 — 대시보드가 실패와 구분 못 함"; fi

# (3) 번역 PR — 격리의 존재 이유. 없으면 나머지 전부 무의미.
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
if [[ -n "$tx_pr_url" ]]; then
  ok "(3) 번역 PR: $tx_pr_url"
  e2e_label_pr "$REPO" "$tx_pr_url"
else
  bad "(3) 번역 PR 미생성 — 격리 실패 (이전의 all-or-nothing 동작)"
  echo; echo "판정: FAIL ($fails)"; exit 1
fi

tx_files="$(gh pr view "$tx_pr_url" --repo "$REPO" --json files --jq '.files[].path' | sort)"
echo "  번역 PR 파일:"; echo "$tx_files" | sed 's/^/    /'

victim_stem="$(basename "$VICTIM")"
# (4) 희생 파일은 없어야 한다. --lang 으로 한 언어만 주입했으면 그 언어만.
if [[ -n "$FAULT_LANG" ]]; then
  if echo "$tx_files" | grep -qx "$FAULT_LANG/$victim_stem"; then
    bad "(4) 실패한 $FAULT_LANG/$victim_stem 가 커밋됨"
  else ok "(4) $FAULT_LANG/$victim_stem 제외됨"; fi
  other_lang=$([[ "$FAULT_LANG" == "en" ]] && echo ja || echo en)
  if echo "$tx_files" | grep -qx "$other_lang/$victim_stem"; then
    ok "(4b) 같은 파일의 성공 언어 $other_lang/$victim_stem 는 커밋됨 (언어 단위 격리)"
  else bad "(4b) $other_lang/$victim_stem 누락 — 실패하지 않은 언어까지 버렸다"; fi
else
  if echo "$tx_files" | grep -qE "^(en|ja)/$victim_stem$"; then
    bad "(4) 실패한 $victim_stem 가 커밋됨"
  else ok "(4) en/ja/$victim_stem 둘 다 제외됨"; fi
fi

# (5) 대조군 — 이게 없으면 격리가 아니라 그냥 전부 실패한 것.
for f in "${HEALTHY[@]}"; do
  stem="$(basename "$f")"
  for lang in en ja; do
    if echo "$tx_files" | grep -qx "$lang/$stem"; then ok "(5) $lang/$stem 커밋됨"
    else bad "(5) $lang/$stem 누락 — 정상 파일이 번역되지 않았다"; fi
  done
done

# (6) PR 본문 실패 섹션 + warning 라벨 — 부분 결과가 완전한 결과로 읽히지
#     않게 하는 사람 대상 신호.
body="$(gh pr view "$tx_pr_url" --repo "$REPO" --json body --jq .body)"
if grep -q "번역 실패로 제외된 파일" <<<"$body"; then ok "(6) PR 본문에 실패 섹션"
else bad "(6) PR 본문에 실패 섹션 없음"; fi
if grep -q "$VICTIM" <<<"$body"; then ok "(6b) 본문이 $VICTIM 를 명시"
else bad "(6b) 본문이 실패 파일을 명시하지 않음"; fi
labels="$(gh pr view "$tx_pr_url" --repo "$REPO" --json labels --jq '.labels[].name')"
if grep -qx "warning" <<<"$labels"; then ok "(6c) warning 라벨"
else bad "(6c) warning 라벨 없음 (labels: $(tr '\n' ',' <<<"$labels"))"; fi

echo
echo "[5/5] 결과"
if (( fails == 0 )); then
  echo "  PASS — 파일 단위 장애 격리 정상 (로그: $LOG)"
  exit 0
fi
echo "  FAIL — $fails 개 규칙 실패 (로그: $LOG)"
KEEP=1   # 실패 시 조사용으로 보존
exit 1
