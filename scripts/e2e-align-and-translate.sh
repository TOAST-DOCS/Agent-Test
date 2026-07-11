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
#   8. dashboard /api/translate 호출 (권장 preset)
#   9. translate 잡 완료 대기 (PR head 에 새 커밋이 붙고 안정화될 때까지)
#  10. claude CLI(fable model)로 PR 브랜치의 ko/en/ja heading·anchor-id 정렬 검사
#  11. 검증 통과 시 align PR 을 alpha 로 merge (실패 시 PR 은 open 으로 남김)
#
# 상단 두 변수(DASHBOARD_BASE_URL, DASHBOARD_API_TOKEN)를 채우고 실행.
# 아니면 같은 이름의 환경변수를 export 해도 됩니다.
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

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL 과 DASHBOARD_API_TOKEN 을 스크립트 상단(또는 env)으로 지정하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── 1) alpha 로 switch ───────────────────────────────────────────────
echo "[1/11] git checkout $BASE_BRANCH"
git fetch origin "$BASE_BRANCH"
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

# ── 2) restore-alpha-origin (내부에서 commit+push) ────────────────────
echo
echo "[2/11] scripts/restore-alpha-origin.sh"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"

# ── 3) dashboard /api/fix-heading-syntax (heading 문법 정정) ──────────
echo
echo "[3/11] POST $DASHBOARD_BASE_URL/api/fix-heading-syntax (base=$BASE_BRANCH)"

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
echo "[4/11] fix-heading-syntax 잡이 생성하는 PR 감지 대기 (최대 30분)"

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
echo "[5/11] scripts/restore-aligned-public-api.sh"
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
echo "[6/11] POST $DASHBOARD_BASE_URL/api/align (권장 preset, base=$BASE_BRANCH)"

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
echo "[7/11] Jenkins align 잡이 생성하는 PR 감지 대기 (최대 30분)"

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

# ── 8) dashboard /api/translate 트리거 (권장 preset) ─────────────────
echo
echo "[8/11] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$align_pr_url)"

# 트리거 직전 PR head SHA 저장 (step 9 에서 새 커밋 감지용)
pr_head_before="$(gh pr view "$align_pr_url" --repo "$REPO" --json headRefOid --jq .headRefOid)"

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

translate_job_id=$(printf '%s' "$translate_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("job_id") or "")')

# ── 9) translate 잡 완료 대기 ─────────────────────────────────────────
echo
echo "[9/11] translate 잡 완료 대기 (PR head 새 커밋 or 잡 종료, 최대 60분)"

deadline=$(( $(date +%s) + 3600 ))
prev_sha=""
translated_sha=""
while (( $(date +%s) < deadline )); do
  sha="$(gh pr view "$align_pr_url" --repo "$REPO" --json headRefOid --jq .headRefOid 2>/dev/null || true)"
  # (a) 새 커밋이 붙었고, 직전 폴링과 같은 SHA(=60초간 안정)면 번역 완료로 판단
  if [[ -n "$sha" && "$sha" != "$pr_head_before" && "$sha" == "$prev_sha" ]]; then
    translated_sha="$sha"
    echo "  translate commits landed & stable: $translated_sha"
    break
  fi
  # (b) 잡이 이미 종료됐으면 커밋 유무와 무관하게 진행/중단 판단
  #     (번역할 diff 가 없으면 success 인데 커밋이 없을 수 있음 — Status: empty)
  if [[ -n "$translate_job_id" ]]; then
    job_status="$(curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
      "$DASHBOARD_BASE_URL/api/jobs/$translate_job_id" 2>/dev/null \
      | python3 -c 'import json,sys; print((json.load(sys.stdin).get("status") or ""))' \
      2>/dev/null || true)"
    case "$job_status" in
      success|partial)
        translated_sha="$sha"
        if [[ "$sha" == "$pr_head_before" ]]; then
          echo "  translate job $job_status — 커밋 없음(번역할 diff 없음). head=$sha"
        else
          echo "  translate job $job_status. head=$sha"
        fi
        break ;;
      failure|cancelled)
        echo "  translate job $job_status — 중단합니다." >&2
        exit 2 ;;
    esac
  fi
  prev_sha="$sha"
  sleep 60
done

if [[ -z "$translated_sha" ]]; then
  echo "  timeout: 60분 내 translate 완료를 감지하지 못했습니다." >&2
  exit 2
fi

# ── 10) claude CLI(fable)로 heading·anchor-id 정렬 검사 ───────────────
echo
echo "[10/11] claude CLI (fable model) heading/anchor-id 정렬 검사"

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

# ── 11) 검증 통과 → align PR 을 alpha 로 merge ────────────────────────
echo
echo "[11/11] 검증 통과 — align PR 을 $BASE_BRANCH 로 merge"
gh pr merge "$align_pr_url" --repo "$REPO" --merge --delete-branch
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated: $align_pr_url"

echo
echo "완료."
