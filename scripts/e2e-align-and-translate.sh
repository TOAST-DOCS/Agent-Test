#!/usr/bin/env bash
#
# End-to-end 재현 스크립트 (Agent-Test alpha):
#   1. alpha 브랜치로 switch
#   2. scripts/restore-alpha-origin.sh 실행 (내부에서 commit+push)
#   3. scripts/restore-aligned-public-api.sh 실행 후 commit+push
#   4. dashboard /api/align 호출 (권장 preset, base=alpha)
#   5. Jenkins align 잡이 새로 만든 PR 을 gh 로 감지
#   6. dashboard /api/translate 호출 (권장 preset)
#
# 상단 두 변수(DASHBOARD_BASE_URL, DASHBOARD_API_TOKEN)를 채우고 실행.
# 아니면 같은 이름의 환경변수를 export 해도 됩니다.
#
# 의존성: git, gh (로그인), curl, python3

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"   # 예: https://docs.internal.nhncloud.com
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}" # 대시보드 관리자에게서 발급받은 값

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH="alpha"
TARGET_URL="https://github.com/${REPO}"
# ─────────────────────────────────────────────────────────────────────

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL 과 DASHBOARD_API_TOKEN 을 스크립트 상단(또는 env)으로 지정하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── 1) alpha 로 switch ───────────────────────────────────────────────
echo "[1/6] git checkout $BASE_BRANCH"
git fetch origin "$BASE_BRANCH"
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

# ── 2) restore-alpha-origin (내부에서 commit+push) ────────────────────
echo
echo "[2/6] scripts/restore-alpha-origin.sh"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"

# ── 3) restore-aligned-public-api + commit+push ──────────────────────
echo
echo "[3/6] scripts/restore-aligned-public-api.sh"
bash "$REPO_ROOT/scripts/restore-aligned-public-api.sh"

if git diff --quiet && git diff --cached --quiet; then
  echo "  (변경 없음, commit/push 건너뜀)"
else
  git add ko en ja
  git commit -m "restore: aligned public-api.md"
  git push origin "$BASE_BRANCH"
fi

# ── 4) dashboard /api/align 트리거 (권장 preset) ─────────────────────
echo
echo "[4/6] POST $DASHBOARD_BASE_URL/api/align (권장 preset, base=$BASE_BRANCH)"

# 권장 preset flags: --aligned-marker --demote-extras --translate-headings --reconcile-unmatched
align_body=$(cat <<JSON
{
  "target": "$TARGET_URL",
  "base_ref": "$BASE_BRANCH",
  "aligned_marker": true,
  "demote_extras": true,
  "translate_headings": true,
  "reconcile_unmatched": true
}
JSON
)

align_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$align_body" \
  "$DASHBOARD_BASE_URL/api/align")"

echo "$align_resp" | python3 -m json.tool

align_build_url=$(printf '%s' "$align_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("build_url") or "")')
if [[ -n "$align_build_url" ]]; then
  echo "  align build: $align_build_url"
fi

# ── 5) align PR 감지 (base=alpha 로 새로 open 된 PR) ─────────────────
echo
echo "[5/6] Jenkins align 잡이 생성하는 PR 감지 대기 (최대 30분)"

# 트리거 직전 시점 open PR 목록을 baseline 으로 저장
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
  --jq '.[].url' | sort -u > "$tmpdir/before"

deadline=$(( $(date +%s) + 1800 ))
align_pr_url=""
while (( $(date +%s) < deadline )); do
  gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
    --jq '.[].url' | sort -u > "$tmpdir/now"
  align_pr_url="$(comm -13 "$tmpdir/before" "$tmpdir/now" | head -n1 || true)"
  if [[ -n "$align_pr_url" ]]; then
    echo "  detected new PR: $align_pr_url"
    break
  fi
  sleep 30
done

if [[ -z "$align_pr_url" ]]; then
  echo "  timeout: 30분 내 새 PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# ── 6) dashboard /api/translate 트리거 (권장 preset) ─────────────────
echo
echo "[6/6] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$align_pr_url)"

# 권장 preset flags:
#   --diff-granularity block --glossary-mode service --max-load-ratio 2
#   --workers 1 --table-rows --skip-full-table --skip-anchor-only
#   --assign-anchors --align-headings
translate_body=$(cat <<JSON
{
  "pr_url": "$align_pr_url",
  "diff_granularity": "block",
  "glossary_mode": "service",
  "max_load_ratio": "2",
  "workers": "1",
  "table_rows": true,
  "skip_full_table": true,
  "skip_anchor_only": true,
  "assign_anchors": true,
  "align_headings": true
}
JSON
)

translate_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$translate_body" \
  "$DASHBOARD_BASE_URL/api/translate")"

echo "$translate_resp" | python3 -m json.tool

echo
echo "완료."
