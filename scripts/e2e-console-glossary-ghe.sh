#!/usr/bin/env bash
#
# 사내 GHE 콘솔 용어집 e2e — 사내 다국어 DB 참조 (cloud-translate#1341, Dooray 584).
#
# 사내 GitHub(github.nhnent.com) 의 문서 리포 `cloud-docs/Internal-Agent-Test` 가
# `.docs-workflow` 에
#     console_glossary:
#       - i18n: [SERVICE_SCHEDULER, SERVICE_SCHEDULER_SERVER]
# 을 적으면, 번역 잡이 **다른 조직**(TOASTCloud)의 다국어 DB
# `TOASTCloud/console-i18n-translate` 카탈로그를 읽어 ko 가 굵게 쓴 콘솔 라벨을 그
# 문자열로 옮기는지 본다. 사내 GHE 는 GitHub App 으로만 읽고(518), App 은 조직마다
# installation 이 따로다 — 문서 리포 조직(cloud-docs)의 토큰으로는 TOASTCloud 가 404 라
# #1341 이전 코드는 카탈로그를 조용히 못 읽는다 (fail-open, 경고 한 줄).
#
# 그래서 github.com 의 e2e-console-glossary.sh 와 달리 카탈로그를 리포에 심지 않는다 —
# 실제 사내 다국어 DB 를 그대로 읽는 것이 이 e2e 의 요점이다. 기대값은
# archive/console-glossary-ghe/expected.json (카탈로그 스냅샷).
#
# 흐름: (1) 세션 base = alpha + .docs-workflow  (2) ko PR = 새 문서 하나
#       (archive/console-glossary-ghe/ko-after/)  (3) 로컬 translate_pr.py (CLI 엔진, 권장
#       preset)  (4) scripts/check_console_glossary_ghe.py — exit 0 OK · 3 REPRO.
#
# BEFORE/AFTER 는 같은 입력에 코드만 바꿔 두 번:
#   scripts/e2e-console-glossary-ghe.sh --label BEFORE --cloud-translate-dir <#1341 이전 체크아웃>
#   scripts/e2e-console-glossary-ghe.sh --label AFTER  --cloud-translate-dir <#1341 이후 체크아웃> \
#       --base-branch <SESSION> --ko-pr <KO_PR>
#
# 사내 GHE 접근은 전부 GitHub App 토큰이다 (gh 개인 로그인 금지): App 설정은 --ghe-env
# (기본 ~/works/cloud-translate/dashboard/.env) 의 NHNENT_GITHUB_* 네 키, PEM 상대 경로는
# 그 체크아웃 루트 기준. git push · PR 생성 · 결과 읽기도 그 토큰.
#
# --run-dir: translate_pr.py 를 돌릴 cwd (`.env` · 용어집 · 가이드라인, 기본 =
#   --cloud-translate-dir). 워크트리 코드를 돌릴 때 메인 체크아웃을 준다.
#
# 엔진은 Claude Code CLI (권장 preset + e2e 비용 override — 다른 e2e 와 같다).
# 산출물(PR · 브랜치)은 증거라 남긴다 (--cleanup 으로 정리).
#
# exit: 0 OK · 3 REPRO · 2 인프라 · 1 사용법
set -euo pipefail

HOST="github.nhnent.com"
REPO="cloud-docs/Internal-Agent-Test"
API="https://$HOST/api/v3"
TS="$(date -u +%Y%m%d-%H%M%S)"
LABEL="AFTER"
SESSION_BRANCH=""
KO_PR=""
CLEANUP=0
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"
GHE_ENV="${GHE_ENV:-$HOME/works/cloud-translate/dashboard/.env}"
RUN_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)               LABEL="$2"; shift 2 ;;
    --base-branch)         SESSION_BRANCH="$2"; shift 2 ;;
    --ko-pr)               KO_PR="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --run-dir)             RUN_DIR="$2"; shift 2 ;;
    --ghe-env)             GHE_ENV="$2"; shift 2 ;;
    --cleanup)             CLEANUP=1; shift ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

RUN_DIR="${RUN_DIR:-$CLOUD_TRANSLATE_DIR}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
FIX="$REPO_ROOT/archive/console-glossary-ghe"
DOC="console-glossary-ghe-sample.md"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"

# ── GHE App 자격 (NHNENT_GITHUB_* 네 키만, PEM 은 그 체크아웃 루트 기준) ──────────
[[ -f "$GHE_ENV" ]] || { echo "error: $GHE_ENV 없음 — 사내 GHE App 설정 필요" >&2; exit 2; }
while IFS='=' read -r k v; do
  case "$k" in
    NHNENT_GITHUB_HOST|NHNENT_GITHUB_APP_ID|NHNENT_GITHUB_APP_INSTALLATION_ID|NHNENT_GITHUB_APP_PRIVATE_KEY_PATH)
      v="${v%\"}"; v="${v#\"}"; export "$k=$v" ;;
  esac
done < "$GHE_ENV"
if [[ "${NHNENT_GITHUB_APP_PRIVATE_KEY_PATH:-}" != /* ]]; then
  NHNENT_GITHUB_APP_PRIVATE_KEY_PATH="$(cd "$(dirname "$GHE_ENV")/.." && pwd)/${NHNENT_GITHUB_APP_PRIVATE_KEY_PATH#./}"
  export NHNENT_GITHUB_APP_PRIVATE_KEY_PATH
fi
[[ -f "$NHNENT_GITHUB_APP_PRIVATE_KEY_PATH" ]] || { echo "error: GHE App PEM 없음" >&2; exit 2; }

ghe_token() {   # 문서 리포 조직의 installation 토큰 — #1341 이전 코드는 owner 인자가 없다
  (cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" - <<'PY'
import sys
sys.path.insert(0, ".")
from shared import ghe_auth
try:
    print(ghe_auth.token("cloud-docs"))
except TypeError:
    print(ghe_auth.token())
PY
)
}
TOK="$(ghe_token)"
[[ -n "$TOK" ]] || { echo "error: GHE App 토큰 발급 실패" >&2; exit 2; }
api() {   # METHOD PATH [JSON]
  if [[ $# -ge 3 ]]; then
    curl -sS -X "$1" -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.github+json" \
      "$API$2" -d "$3"
  else
    curl -sS -X "$1" -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.github+json" "$API$2"
  fi
}
REMOTE="https://x-access-token:$TOK@$HOST/$REPO.git"

cleanup() {
  local rc=$?
  if (( CLEANUP )); then
    for n in "${tx_pr_num:-}" "${KO_PR##*/}"; do
      [[ -n "$n" ]] && api PATCH "/repos/$REPO/pulls/$n" '{"state":"closed"}' >/dev/null || true
    done
  fi
  rm -rf "$tmpdir"
  exit $rc
}
trap cleanup EXIT

echo "== e2e console glossary @ GHE [$LABEL] — $REPO =="
echo "  code:   $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log -1 --format=%h 2>/dev/null || echo '?'))"

# ── 1) 세션 base — alpha + .docs-workflow ────────────────────────────────────
git clone -q --depth 1 --branch alpha "$REMOTE" "$tmpdir/repo" 2>/dev/null \
  || { echo "error: $REPO clone 실패 (App 토큰)" >&2; exit 2; }
cd "$tmpdir/repo"
git config user.name "e2e-console-glossary-ghe"; git config user.email "e2e@localhost"
if [[ -z "$SESSION_BRANCH" ]]; then
  SESSION_BRANCH="e2e/ghe-consolegloss-$TS"
  [[ ! -e .docs-workflow ]] || { echo "error: alpha 에 .docs-workflow 가 이미 있다 — 덮지 않는다" >&2; exit 2; }
  cat > .docs-workflow <<'YAML'
# e2e-console-glossary-ghe.sh — 사내 다국어 DB (TOASTCloud/console-i18n-translate) 참조
console_glossary:
  - i18n: [SERVICE_SCHEDULER, SERVICE_SCHEDULER_SERVER]
YAML
  git add .docs-workflow
  git commit -q -m "e2e(console-glossary-ghe): 사내 다국어 DB 콘솔 용어집 선언 ($TS)"
  git push -q origin "HEAD:refs/heads/$SESSION_BRANCH"
fi
echo "  SESSION=$SESSION_BRANCH"

# ── 2) ko PR — 콘솔 라벨을 굵게 쓴 새 문서 ───────────────────────────────────
if [[ -z "$KO_PR" ]]; then
  HEAD_BRANCH="translate-test/ghe-consolegloss-$TS"
  git fetch -q --depth 1 origin "$SESSION_BRANCH"
  git checkout -q -B "$HEAD_BRANCH" FETCH_HEAD
  cp "$FIX/ko-after/$DOC" "ko/$DOC"
  git add "ko/$DOC"
  git commit -q -m "e2e(console-glossary-ghe): 콘솔 라벨을 굵게 쓴 문서 ($TS)"
  git push -q origin "HEAD:refs/heads/$HEAD_BRANCH"
  body=$(python3 -c 'import json,sys; print(json.dumps({"title": f"e2e(console-glossary-ghe): 사내 다국어 DB 콘솔 라벨 ({sys.argv[1]})", "head": sys.argv[2], "base": sys.argv[3], "body": "cloud-translate#1341 검증 입력. `.docs-workflow` 의 console_glossary i18n 카테고리 (사내 다국어 DB, TOASTCloud) 를 번역이 따르는지."}))' "$TS" "$HEAD_BRANCH" "$SESSION_BRANCH")
  KO_PR="$(api POST "/repos/$REPO/pulls" "$body" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("html_url",""))')"
  [[ -n "$KO_PR" ]] || { echo "error: ko PR 생성 실패" >&2; exit 2; }
fi
echo "  KO_PR=$KO_PR"

# ── 3) 번역 — 로컬 translate_pr.py, CLI 엔진, 권장 preset ─────────────────────
preset_eval="$(python3 "$SCRIPTS/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 2
eval "$preset_eval"
set +e
(cd "$RUN_DIR" && \
  TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
  "$CLOUD_TRANSLATE_PY" "$CLOUD_TRANSLATE_DIR/translate/translate_pr.py" "$KO_PR" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") > "$LOG" 2>&1
tx_rc=$?
set -e
cp "$LOG" "/tmp/e2e-console-glossary-ghe-$LABEL-$TS.log" 2>/dev/null || true
echo "  translate exit=$tx_rc · 로그 /tmp/e2e-console-glossary-ghe-$LABEL-$TS.log"
echo "  엔진: CLI 호출 $(grep -ac 'with Claude Code CLI' "$LOG" || true) · api.anthropic.com $(grep -ac 'api.anthropic.com' "$LOG" || true)"
tx_pr_url="$(grep -aoE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지"; tail -30 "$LOG"; exit 2; }
tx_pr_num="${tx_pr_url##*/}"
echo "  번역 PR: $tx_pr_url"
api PATCH "/repos/$REPO/pulls/$tx_pr_num" \
  "$(python3 -c 'import json,sys; t=sys.argv[2]; print(json.dumps({"title": t if t.startswith("["+sys.argv[1]+"]") else f"[{sys.argv[1]}] {t}"}))' "$LABEL" \
     "$(api GET "/repos/$REPO/pulls/$tx_pr_num" | python3 -c 'import json,sys; print(json.load(sys.stdin)["title"])')")" >/dev/null

# ── 4) 판정 ─────────────────────────────────────────────────────────────────
pr_json="$(api GET "/repos/$REPO/pulls/$tx_pr_num")"
python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("body") or "")' <<<"$pr_json" > "$tmpdir/pr_body.md"
head_sha="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["head"]["sha"])' <<<"$pr_json")"
for lang in en ja; do
  api GET "/repos/$REPO/contents/$lang/$DOC?ref=$head_sha" \
    | python3 -c 'import json,sys,base64; print(base64.b64decode(json.load(sys.stdin)["content"]).decode())' \
    > "$tmpdir/$lang.md" || { echo "error: $lang/$DOC 를 읽지 못함"; exit 2; }
done
echo
set +e
python3 "$SCRIPTS/check_console_glossary_ghe.py" --expected "$FIX/expected.json" \
  --log "$LOG" --pr-body "$tmpdir/pr_body.md" --en "$tmpdir/en.md" --ja "$tmpdir/ja.md"
rc=$?
set -e
echo "  SESSION=$SESSION_BRANCH KO_PR=$KO_PR TX_PR=$tx_pr_url"
exit $rc
