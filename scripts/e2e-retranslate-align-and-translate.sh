#!/usr/bin/env bash
#
# End-to-end 재현 스크립트 (Agent-Test alpha) — public-api.md 전체 재번역 변형:
#   scripts/e2e-align-and-translate.sh 흐름에 dashboard /api/translate/file
#   을 통한 public-api.md 전체 재번역(DIFF_MODE=full) 을 추가한 변형. 재번역
#   결과는 alpha 에 직접 커밋하지 않고 **align PR 의 head 브랜치에 append**
#   되도록 pr_number 를 사용 → align + 재번역이 한 PR 로 리뷰됨.
#
#   재번역 소요 시간을 줄이기 위해 step 2 뒤에 public-api.md 를 40% 축소본
#   (archive/alpha-origin-40pct/{ko,en,ja}/public-api.md) 으로 덮어쓰는 단계
#   포함. 축소본은 원본에서 `<a id="create-instance"></a>` 앵커부터 파일 끝
#   까지 잘라낸 버전(각 언어별 ~42% 분량, 세 언어 공통 앵커 위치에서 잘라
#   구조 정합성 유지).
#
#   1. alpha 브랜치로 switch
#   2. scripts/restore-alpha-origin.sh 실행 (내부에서 commit+push)
#      + public-api.md 40% 축소본 덮어쓰기 → commit+push
#   3. dashboard /api/fix-heading-syntax 호출 (heading 문법 정정, base=alpha)
#   4. fix-heading-syntax 잡이 생성하는 PR 감지 → merge → alpha 최신화
#   5. dashboard /api/align 호출 (= fix_headings job, 권장 preset, base=alpha)
#   6. Jenkins align 잡이 새로 만든 PR 을 gh 로 감지 (base=alpha)
#   7. dashboard /api/translate/file 호출 (ko/public-api.md 전체 재번역,
#      pr_number=<align PR>) → 재번역 커밋이 align PR head 브랜치에 append,
#      job status 가 success 될 때까지 대기 후 로컬 head_ref 최신화
#   8. claude CLI(fable model)로 align PR 브랜치(재번역 포함)의
#      ko/en/ja heading·anchor-id 정렬 검사
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
#   scripts/e2e-retranslate-align-and-translate.sh [--engine api|cli] [--model haiku|sonnet|opus]
#                                                  [--tm-top-k N] [--chunk-workers N]
#                                                  [--guidelines-variant-en aws|unified|unified-v2|default]
#                                                  [--guidelines-variant-ja aws|unified|default]
#                                                  [--align-v2|--no-align-v2]
#
#   --engine api   translate 잡을 api 엔진으로 실행
#   --engine cli   translate 잡을 claude-code(CLI) 엔진으로 실행 (기본값)
#   (default 지정 시 engine 필드를 보내지 않음 → 서버 default)
#
#   --model haiku  claude-haiku-4-5 사용 (기본값)
#   --model sonnet claude-sonnet-4-6 사용
#   --model opus   claude-opus-4-8 사용
#
#   --tm-top-k N          TM few-shot 개수 (기본값 1). "default" 시 필드 미전송 (잡 .env default = 10)
#   --chunk-workers N     chunk 병렬도 (기본값 2, PR#192/#199).
#   --guidelines-variant-en <v>  en 가이드라인 크기 (aws|unified|unified-v2|default, PR#199)
#   --guidelines-variant-ja <v>  ja 가이드라인 크기 (aws|unified|default, PR#199)
#   --align-v2 / --no-align-v2   PR#218 v2 모드 (기본 --align-v2)
#
# 의존성: git, gh (로그인), curl, python3, claude (Claude Code CLI)

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"   # 예: https://docs.internal.nhncloud.com
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}" # 대시보드 관리자에게서 발급받은 값

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH=""                                # 미지정 시 e2e-retranslate/<timestamp> 자동 생성 (alpha 미오염)
BASE_SOURCE_BRANCH="alpha"                    # 새 세션 브랜치를 갈라낼 원본
TARGET_URL="https://github.com/${REPO}"
RETRANSLATE_PATH="public-api.md"   # {source}/ 기준 상대경로
RETRANSLATE_SOURCE="ko"
# ─────────────────────────────────────────────────────────────────────

# ── 실행 옵션 ─────────────────────────────────────────────────────────
TRANSLATE_ENGINE="claude-code"            # 기본값 cli — api/default 로 override 가능
TRANSLATE_MODEL="claude-haiku-4-5"        # 기본값 haiku — sonnet/opus/default 로 override 가능
TRANSLATE_TM_TOP_K="1"                    # TM few-shot 개수 기본값 1
TRANSLATE_CHUNK_WORKERS="2"               # chunk 병렬도 (PR#192/#199)
TRANSLATE_GUIDELINES_VARIANT_EN=""        # 기본값 default (잡 .env: unified-v2)
TRANSLATE_GUIDELINES_VARIANT_JA=""        # 기본값 default (잡 .env: unified)
ALIGN_V2=1                                # PR#218 v2 모드 (기본 활성)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      case "${2:-}" in
        api)     TRANSLATE_ENGINE="api" ;;
        cli)     TRANSLATE_ENGINE="claude-code" ;;
        default) TRANSLATE_ENGINE="" ;;
        *) echo "error: --engine 은 api|cli|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --model)
      case "${2:-}" in
        haiku)   TRANSLATE_MODEL="claude-haiku-4-5" ;;
        sonnet)  TRANSLATE_MODEL="claude-sonnet-4-6" ;;
        opus)    TRANSLATE_MODEL="claude-opus-4-8" ;;
        default) TRANSLATE_MODEL="" ;;
        *) echo "error: --model 은 haiku|sonnet|opus|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --tm-top-k)
      case "${2:-}" in
        default) TRANSLATE_TM_TOP_K="" ;;
        ''|*[!0-9]*) echo "error: --tm-top-k 는 양의 정수 또는 default (got: ${2:-})" >&2; exit 1 ;;
        *) TRANSLATE_TM_TOP_K="$2" ;;
      esac
      shift 2 ;;
    --chunk-workers)
      case "${2:-}" in
        default) TRANSLATE_CHUNK_WORKERS="" ;;
        ''|*[!0-9]*) echo "error: --chunk-workers 는 양의 정수 또는 default (got: ${2:-})" >&2; exit 1 ;;
        *) TRANSLATE_CHUNK_WORKERS="$2" ;;
      esac
      shift 2 ;;
    --guidelines-variant-en)
      case "${2:-}" in
        aws|unified|unified-v2) TRANSLATE_GUIDELINES_VARIANT_EN="$2" ;;
        default) TRANSLATE_GUIDELINES_VARIANT_EN="" ;;
        *) echo "error: --guidelines-variant-en 은 aws|unified|unified-v2|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --guidelines-variant-ja)
      case "${2:-}" in
        aws|unified) TRANSLATE_GUIDELINES_VARIANT_JA="$2" ;;
        default) TRANSLATE_GUIDELINES_VARIANT_JA="" ;;
        *) echo "error: --guidelines-variant-ja 은 aws|unified|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --align-v2)      ALIGN_V2=1; shift ;;
    --no-align-v2)   ALIGN_V2=0; shift ;;
    --base-branch)   BASE_BRANCH="$2"; shift 2 ;;        # 기존 세션 브랜치 재사용
    --base-source)   BASE_SOURCE_BRANCH="$2"; shift 2 ;; # 새 세션 브랜치를 갈라낼 원본 (기본 alpha)
    -h|--help) sed -n '3,44p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL 과 DASHBOARD_API_TOKEN 을 스크립트 상단(또는 env)으로 지정하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── 1) e2e 세션 브랜치 준비 (기본: 새로 생성; --base-branch 로 override 가능) ─
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-retranslate/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/14] Creating fresh e2e session branch: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  git push -u origin "$BASE_BRANCH"
  echo "  E2E_BASE_BRANCH=$BASE_BRANCH"     # wrapper 가 파싱하는 마커
else
  echo "[1/14] Reusing existing base branch: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
fi

# ── 2) restore-alpha-origin (내부에서 commit+push) ────────────────────
echo
echo "[2/14] scripts/restore-alpha-origin.sh + public-api.md 40% 축소본 적용"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"

# public-api.md 를 40% 축소본으로 덮어쓰기 (retranslate 소요 시간 단축용)
reduced_root="$REPO_ROOT/archive/alpha-origin-40pct"
for lang in ko en ja; do
  src="$reduced_root/$lang/public-api.md"
  dst="$REPO_ROOT/$lang/public-api.md"
  if [[ ! -f "$src" ]]; then
    echo "  error: 40% 축소본 없음: $src" >&2
    exit 1
  fi
  cp -f "$src" "$dst"
  echo "  reduced: $lang/public-api.md ($(wc -l < "$src") lines)"
done

if git diff --quiet -- ko/public-api.md en/public-api.md ja/public-api.md \
   && git diff --cached --quiet -- ko/public-api.md en/public-api.md ja/public-api.md; then
  echo "  (public-api.md 변경 없음, commit/push 건너뜀)"
else
  git add ko/public-api.md en/public-api.md ja/public-api.md
  git commit -m "test: apply 40% reduced public-api.md for retranslate e2e"
  git push origin "$BASE_BRANCH"
fi

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

# ── 5) dashboard /api/align 트리거 (권장 preset) ─────────────────────
echo
echo "[5/14] POST $DASHBOARD_BASE_URL/api/align (권장 preset, base=$BASE_BRANCH)"

# 트리거 직전 시점 open PR 목록을 baseline 으로 저장 (step 6 신규 PR 감지용)
gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
  --jq '.[].url' | sort -u > "$tmpdir/before"

# 권장 preset flags: --aligned-marker --demote-extras --translate-headings --reconcile-unmatched
# PR#218 개선: --align-v2 (opinionated defaults + ancestor subtree 재번역).
# Jenkins 는 fix_headings.py 를 그대로 호출하므로 --auto-align-v2-below (기본 5)
# 자동 escalation 도 항상 동작.
align_v2_json="false"
if (( ALIGN_V2 )); then align_v2_json="true"; fi

align_body=$(cat <<JSON
{
  "target": "$TARGET_URL",
  "base_ref": "$BASE_BRANCH",
  "aligned_marker": true,
  "demote_extras": true,
  "translate_headings": true,
  "reconcile_unmatched": true,
  "align_v2": $align_v2_json
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

# ── 6) align PR 감지 (base=alpha 로 새로 open 된 PR) ─────────────────
echo
echo "[6/14] Jenkins align 잡이 생성하는 PR 감지 대기 (최대 30분)"

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

# align PR 의 head 브랜치 (재번역 커밋을 이 브랜치에 append)
align_pr_number="$(gh pr view "$align_pr_url" --repo "$REPO" --json number --jq .number)"
head_ref="$(gh pr view "$align_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"

# ── 7) /api/translate/file 로 public-api.md 전체 재번역 → align PR 커밋 ──
echo
echo "[7/14] POST $DASHBOARD_BASE_URL/api/translate/file ($RETRANSLATE_SOURCE/$RETRANSLATE_PATH 전체 재번역, pr_number=$align_pr_number, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default}, tm_top_k=${TRANSLATE_TM_TOP_K:-default})"

# pr_number 지정 시 서버가 GH 에서 head.ref 조회 → commit_to_branch=head_ref
retx_engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  retx_engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

retx_model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  retx_model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

retx_tm_top_k_json=""
if [[ -n "$TRANSLATE_TM_TOP_K" ]]; then
  retx_tm_top_k_json="\"tm_top_k\": \"$TRANSLATE_TM_TOP_K\","
fi

# PR#192/#199 개선: chunk_workers + guidelines_variant 를 /api/translate/file 에도 forward
retx_chunk_workers_json=""
if [[ -n "$TRANSLATE_CHUNK_WORKERS" ]]; then
  retx_chunk_workers_json="\"chunk_workers\": \"$TRANSLATE_CHUNK_WORKERS\","
fi
retx_gv_en_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_EN" ]]; then
  retx_gv_en_json="\"guidelines_variant_en\": \"$TRANSLATE_GUIDELINES_VARIANT_EN\","
fi
retx_gv_ja_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_JA" ]]; then
  retx_gv_ja_json="\"guidelines_variant_ja\": \"$TRANSLATE_GUIDELINES_VARIANT_JA\","
fi

retx_body=$(cat <<JSON
{
  "repo": "$REPO",
  "pr_number": $align_pr_number,
  "source": "$RETRANSLATE_SOURCE",
  "path": "$RETRANSLATE_PATH",
  $retx_engine_json
  $retx_model_json
  $retx_tm_top_k_json
  $retx_chunk_workers_json
  $retx_gv_en_json
  $retx_gv_ja_json
  "path_prefix": ""
}
JSON
)

retx_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$retx_body" \
  "$DASHBOARD_BASE_URL/api/translate/file")"

echo "$retx_resp" | python3 -m json.tool

retx_job_id=$(printf '%s' "$retx_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("job_id") or "")')
retx_build_url=$(printf '%s' "$retx_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("build_url") or "")')

if [[ -z "$retx_job_id" ]]; then
  echo "  error: /api/translate/file 응답에서 job_id 를 찾지 못했습니다." >&2
  exit 2
fi
if [[ -n "$retx_build_url" ]]; then
  echo "  retranslate build: $retx_build_url"
fi

# 잡 상태가 success 가 될 때까지 대기 (전체 재번역이라 최대 90분)
echo "  retranslate 완료 대기: job_id=$retx_job_id (최대 90분)"
deadline=$(( $(date +%s) + 5400 ))
retx_status=""
while (( $(date +%s) < deadline )); do
  retx_status="$(curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$retx_job_id" \
    | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  tasks=(d.get("job") or {}).get("tasks") or []
  print(tasks[0].get("status") if tasks else "")
except Exception:
  print("")')"
  case "$retx_status" in
    success|failure|cancelled|partial) break ;;
  esac
  sleep 30
done

if [[ "$retx_status" != "success" ]]; then
  echo "  retranslate 실패 (status=$retx_status, job_id=$retx_job_id)" >&2
  exit 2
fi

# align PR head 브랜치를 fetch 해서 재번역 커밋을 로컬로 가져옴
git fetch --quiet origin "$head_ref"
echo "  retranslate 완료 & align PR head branch ($head_ref) 최신화"

# ── 8) claude CLI(fable)로 align PR (재번역 포함) heading·anchor-id 정렬 검사 ─
echo
echo "[8/14] claude CLI (fable model) heading/anchor-id 정렬 검사 (PR=$align_pr_url, 재번역 포함)"

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

create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh" --base-branch "$BASE_BRANCH")"
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
echo "[12/14] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$ko_pr_url, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default}, tm_top_k=${TRANSLATE_TM_TOP_K:-default})"

# --engine 옵션이 지정된 경우에만 engine 필드 포함
engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

# --model 값이 설정된 경우에만 model 필드 포함
model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

# --tm-top-k 값이 설정된 경우에만 tm_top_k 필드 포함
tm_top_k_json=""
if [[ -n "$TRANSLATE_TM_TOP_K" ]]; then
  tm_top_k_json="\"tm_top_k\": \"$TRANSLATE_TM_TOP_K\","
fi

# PR#192/#199 개선: chunk_workers + guidelines_variant
chunk_workers_json=""
if [[ -n "$TRANSLATE_CHUNK_WORKERS" ]]; then
  chunk_workers_json="\"chunk_workers\": \"$TRANSLATE_CHUNK_WORKERS\","
fi
gv_en_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_EN" ]]; then
  gv_en_json="\"guidelines_variant_en\": \"$TRANSLATE_GUIDELINES_VARIANT_EN\","
fi
gv_ja_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_JA" ]]; then
  gv_ja_json="\"guidelines_variant_ja\": \"$TRANSLATE_GUIDELINES_VARIANT_JA\","
fi

# 권장 preset flags:
#   --diff-granularity block --glossary-mode service --max-load-ratio 2
#   --workers 2 --table-rows --skip-full-table --skip-anchor-only
#   --assign-anchors --align-headings
# PR#207/#211 (within/cross-opcode batching) 은 자동 활성.
translate_body=$(cat <<JSON
{
  "pr_url": "$ko_pr_url",
  $engine_json
  $model_json
  $tm_top_k_json
  $chunk_workers_json
  $gv_en_json
  $gv_ja_json
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
