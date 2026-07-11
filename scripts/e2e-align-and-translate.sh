#!/usr/bin/env bash
#
# End-to-end 재현 스크립트 (Agent-Test alpha):
#   1. alpha 브랜치로 switch
#   2. scripts/restore-alpha-origin.sh 실행 (내부에서 commit+push)
#   3. dashboard /api/fix-heading-syntax 호출 (heading 문법 정정, base=alpha)
#   4. fix-heading-syntax 잡이 생성하는 PR 감지 → merge → alpha 최신화
#   5. scripts/restore-aligned-public-api.sh 실행 후 commit+push
#   6. dashboard /api/align 호출 (= fix_headings job, 권장 preset, base=alpha)
#   7. Jenkins align 잡이 새로 만든 PR 을 gh 로 감지
#   8. claude CLI(fable model)로 align PR 브랜치의 ko/en/ja heading·anchor-id 정렬 검사
#   9. 검증 통과 시 align PR 을 alpha 로 merge (실패 시 PR 은 open 으로 남김)
#  10. scripts/create-translate-test-pr.sh 실행 (ko 변형 → translate-test PR 생성)
#  11. ko 변경 PR 생성 확인
#  12. ko 변경 PR 대상으로 dashboard /api/translate 호출 (권장 preset)
#  13. translate 잡이 생성하는 번역 PR(base=ko PR head 브랜치) 감지 대기
#  14. claude CLI(fable)로 번역 PR 검증 (heading·id·표 행 수) → 결과를 PR 댓글로 등록
#
# 상단 두 변수(DASHBOARD_BASE_URL, DASHBOARD_API_TOKEN)를 채우고 실행.
# 아니면 같은 이름의 환경변수를 export 해도 됩니다.
#
# Usage:
#   scripts/e2e-align-and-translate.sh [--engine api|cli]
#
#   --engine api   translate 잡을 api 엔진으로 실행
#   --engine cli   translate 잡을 claude-code(CLI) 엔진으로 실행
#   (생략 시 engine 필드를 보내지 않음 → 서버 default)
#
# 의존성: git, gh (로그인), curl, python3, claude (Claude Code CLI)

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"   # 예: https://docs.internal.nhncloud.com
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}" # 대시보드 관리자에게서 발급받은 값

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH="alpha"
TARGET_URL="https://github.com/${REPO}"
# ─────────────────────────────────────────────────────────────────────

# ── 실행 옵션 ─────────────────────────────────────────────────────────
TRANSLATE_ENGINE=""   # ""(default) | api | claude-code
while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      case "${2:-}" in
        api) TRANSLATE_ENGINE="api" ;;
        cli) TRANSLATE_ENGINE="claude-code" ;;
        *) echo "error: --engine 은 api 또는 cli 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -h|--help) sed -n '3,30p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL 과 DASHBOARD_API_TOKEN 을 스크립트 상단(또는 env)으로 지정하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── 1) alpha 로 switch ───────────────────────────────────────────────
echo "[1/14] git checkout $BASE_BRANCH"
git fetch origin "$BASE_BRANCH"
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

# ── 2) restore-alpha-origin (내부에서 commit+push) ────────────────────
echo
echo "[2/14] scripts/restore-alpha-origin.sh"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"

# ── 3) dashboard /api/fix-heading-syntax (heading 문법 정정) ──────────
echo
echo "[3/14] POST $DASHBOARD_BASE_URL/api/fix-heading-syntax (base=$BASE_BRANCH)"

# 트리거 직전 open PR 목록을 baseline 으로 저장 (step 4 의 신규 PR 감지용)
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
  --jq '.[].url' | sort -u > "$tmpdir/fix_before"

fix_body=$(cat <<JSON
{
  "target": "$TARGET_URL",
  "base_ref": "$BASE_BRANCH"
}
JSON
)

fix_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$fix_body" \
  "$DASHBOARD_BASE_URL/api/fix-heading-syntax")"

echo "$fix_resp" | python3 -m json.tool

fix_build_url=$(printf '%s' "$fix_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("build_url") or "")')
if [[ -n "$fix_build_url" ]]; then
  echo "  fix-heading-syntax build: $fix_build_url"
fi

# ── 4) fix-heading-syntax PR 감지 대기 ────────────────────────────────
echo
echo "[4/14] fix-heading-syntax 잡이 생성하는 PR 감지 대기 (최대 30분)"

deadline=$(( $(date +%s) + 1800 ))
fix_pr_url=""
while (( $(date +%s) < deadline )); do
  gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open \
    --json url,headRefName \
    --jq '.[] | select(.headRefName | startswith("pre-align/fix-heading-syntax-")) | .url' \
    | sort -u > "$tmpdir/fix_now"
  fix_pr_url="$(comm -13 "$tmpdir/fix_before" "$tmpdir/fix_now" | head -n1 || true)"
  if [[ -n "$fix_pr_url" ]]; then
    echo "  detected fix-heading-syntax PR: $fix_pr_url"
    break
  fi
  sleep 30
done

if [[ -z "$fix_pr_url" ]]; then
  echo "  timeout: 30분 내 fix-heading-syntax PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# 감지한 PR 을 merge 하고 로컬 alpha 를 최신화
echo "  merging: $fix_pr_url"
gh pr merge "$fix_pr_url" --repo "$REPO" --merge --delete-branch
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated"

# ── 5) restore-aligned-public-api + commit+push ──────────────────────
echo
echo "[5/14] scripts/restore-aligned-public-api.sh"
bash "$REPO_ROOT/scripts/restore-aligned-public-api.sh"

if git diff --quiet && git diff --cached --quiet; then
  echo "  (변경 없음, commit/push 건너뜀)"
else
  git add ko en ja
  git commit -m "restore: aligned public-api.md"
  git push origin "$BASE_BRANCH"
fi

# ── 6) dashboard /api/align 트리거 (권장 preset) ─────────────────────
echo
echo "[6/14] POST $DASHBOARD_BASE_URL/api/align (권장 preset, base=$BASE_BRANCH)"

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

# ── 7) align PR 감지 (base=alpha 로 새로 open 된 PR) ─────────────────
echo
echo "[7/14] Jenkins align 잡이 생성하는 PR 감지 대기 (최대 30분)"

# 트리거 직전 시점 open PR 목록을 baseline 으로 저장
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

# ── 8) claude CLI(fable)로 align PR heading·anchor-id 정렬 검사 ───────
echo
echo "[8/14] claude CLI (fable model) heading/anchor-id 정렬 검사 (PR=$align_pr_url)"

head_ref="$(gh pr view "$align_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$head_ref"
check_wt="$tmpdir/pr-check"
git worktree add "$check_wt" "origin/$head_ref" >/dev/null

check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외한 (1) heading level 순서와 (2) anchor id 순서
(<a id="..."></a> 형식과 { #id } 형식 모두)가 세 언어에서 완전히 일치하는지 검사해줘.
파일별 결과를 OK/FAIL 표로 출력하고, FAIL 인 파일은 어긋난 위치와 내용을 설명해줘.
마지막 줄에는 다른 텍스트 없이 전체 판정만 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" 로 출력해.'

check_out="$(cd "$check_wt" && claude -p "$check_prompt" \
  --model fable \
  --allowedTools "Bash,Read,Grep,Glob")"

echo "$check_out"

git worktree remove "$check_wt" --force

if ! grep -q '^ALIGNMENT: OK' <<<"$check_out"; then
  echo "  heading/anchor-id 정렬 검사 실패 — PR 을 merge 하지 않고 open 으로 남깁니다: $align_pr_url" >&2
  exit 3
fi

# ── 9) 검증 통과 → align PR 을 alpha 로 merge ─────────────────────────
echo
echo "[9/14] 검증 통과 — align PR 을 $BASE_BRANCH 로 merge"
gh pr merge "$align_pr_url" --repo "$REPO" --merge --delete-branch
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated: $align_pr_url"

# ── 10) create-translate-test-pr (ko 변형 → translate-test PR 생성) ───
echo
echo "[10/14] scripts/create-translate-test-pr.sh"

create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh")"
echo "$create_out"

# ── 11) ko 변경 PR 생성 확인 ──────────────────────────────────────────
echo
echo "[11/14] ko 변경 PR 생성 확인"

# gh pr create 는 마지막 줄에 PR URL 을 출력
ko_pr_url="$(grep -oE 'https://github.com/[^ ]+/pull/[0-9]+' <<<"$create_out" | tail -n1 || true)"
if [[ -z "$ko_pr_url" ]]; then
  echo "  error: create-translate-test-pr.sh 출력에서 PR URL 을 찾지 못했습니다." >&2
  exit 2
fi

ko_pr_state="$(gh pr view "$ko_pr_url" --repo "$REPO" --json state --jq .state)"
if [[ "$ko_pr_state" != "OPEN" ]]; then
  echo "  error: ko 변경 PR 이 open 상태가 아닙니다 (state=$ko_pr_state): $ko_pr_url" >&2
  exit 2
fi
echo "  ko 변경 PR 확인: $ko_pr_url (state=$ko_pr_state)"

# ── 12) ko 변경 PR 대상 dashboard /api/translate 트리거 (권장 preset) ─
echo
echo "[12/14] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$ko_pr_url, engine=${TRANSLATE_ENGINE:-default})"

# --engine 옵션이 지정된 경우에만 engine 필드 포함
engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

# 권장 preset flags:
#   --diff-granularity block --glossary-mode service --max-load-ratio 2
#   --workers 2 --table-rows --skip-full-table --skip-anchor-only
#   --assign-anchors --align-headings
translate_body=$(cat <<JSON
{
  "pr_url": "$ko_pr_url",
  $engine_json
  "diff_granularity": "block",
  "glossary_mode": "service",
  "max_load_ratio": "2",
  "workers": "2",
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

# ── 13) 번역 PR 감지 대기 (base = ko PR head 브랜치) ──────────────────
echo
echo "[13/14] translate 잡이 생성하는 번역 PR 감지 대기 (최대 60분)"

ko_head_ref="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"

deadline=$(( $(date +%s) + 3600 ))
trans_pr_url=""
while (( $(date +%s) < deadline )); do
  trans_pr_url="$(gh pr list --repo "$REPO" --base "$ko_head_ref" --state open \
    --json url,headRefName \
    --jq '.[] | select(.headRefName | startswith("translate/")) | .url' \
    | sort -u | head -n1 || true)"
  if [[ -n "$trans_pr_url" ]]; then
    echo "  detected translation PR: $trans_pr_url"
    break
  fi
  sleep 60
done

if [[ -z "$trans_pr_url" ]]; then
  echo "  timeout: 60분 내 번역 PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# ── 14) claude CLI(fable)로 번역 PR 검증 → 결과를 PR 댓글로 등록 ───────
echo
echo "[14/14] claude CLI (fable model) 번역 PR 검증 (PR=$trans_pr_url)"

trans_head_ref="$(gh pr view "$trans_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$trans_head_ref"
trans_wt="$tmpdir/trans-check"
git worktree add "$trans_wt" "origin/$trans_head_ref" >/dev/null

trans_check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외하고 다음 세 가지가 세 언어에서 완전히 일치하는지 검사해줘.
(1) heading level 순서
(2) anchor id 순서 (<a id="..."></a> 형식과 { #id } 형식 모두)
(3) 표(table)가 있으면 표 개수와 각 표의 데이터 행(row) 개수
파일별 결과를 OK/FAIL 표로 출력하고 (표 개수·행 수 포함), FAIL 인 파일은 어긋난 위치와 내용을 설명해줘.
마지막 줄에는 다른 텍스트 없이 전체 판정만 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" 로 출력해.'

trans_check_out="$(cd "$trans_wt" && claude -p "$trans_check_prompt" \
  --model fable \
  --allowedTools "Bash,Read,Grep,Glob")"

echo "$trans_check_out"

git worktree remove "$trans_wt" --force

# 검증 결과를 번역 PR 댓글로 등록
if grep -q '^ALIGNMENT: OK' <<<"$trans_check_out"; then
  verdict_line="✅ 번역 PR 자동 검증 통과 (heading·anchor-id·표 행 수 일치)"
else
  verdict_line="❌ 번역 PR 자동 검증 실패 — 아래 상세 결과를 확인하세요"
fi

cat > "$tmpdir/trans_comment.md" <<EOF
## 번역 PR 자동 검증 결과 (claude CLI, fable)

$verdict_line

- 검증 브랜치: \`$trans_head_ref\`
- 검증 항목: ko/en/ja heading level 순서 · anchor id 순서 · 표 개수/행 수

<details>
<summary>상세 결과</summary>

$trans_check_out

</details>
EOF

gh pr comment "$trans_pr_url" --repo "$REPO" --body-file "$tmpdir/trans_comment.md"
echo "  검증 결과 댓글 등록 완료: $trans_pr_url"

if ! grep -q '^ALIGNMENT: OK' <<<"$trans_check_out"; then
  echo "  번역 PR 검증 실패 — PR 은 open 으로 남깁니다: $trans_pr_url" >&2
  exit 3
fi

echo
echo "완료."
