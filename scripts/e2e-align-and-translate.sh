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
#  12. dashboard /api/ko-review 호출 (ko 변경 PR 대상 한글 검수 트리거)
#  13. ko-review 잡 완료 대기 (Jobs 상태 polling)
#  14. ko 변경 PR 의 suggestion 검증 (1개 이상 존재해야 함) → 전체 accept 후
#      ko 변경 PR head 브랜치로 commit + push
#  15. ko 변경 PR (suggestion 반영본) 대상으로 dashboard /api/translate 호출
#  16. translate 잡이 생성하는 번역 PR(base=ko PR head 브랜치) 감지 대기
#  17. claude CLI(fable)로 번역 PR 검증 (heading·id·표 행 수) → 결과를 PR 댓글로 등록
#
# 상단 두 변수(DASHBOARD_BASE_URL, DASHBOARD_API_TOKEN)를 채우고 실행.
# 아니면 같은 이름의 환경변수를 export 해도 됩니다.
#
# Usage:
#   scripts/e2e-align-and-translate.sh [--engine api|cli] [--model haiku|sonnet|opus]
#                                      [--tm-top-k N] [--chunk-workers N]
#                                      [--guidelines-variant-en aws|unified|unified-v2|default]
#                                      [--guidelines-variant-ja aws|unified|default]
#                                      [--align-v2|--no-align-v2]
#                                      [--plan round1|round2|row-drop-repro|table-suite]
#                                      [--translate api|local]
#
#   --engine api   translate 잡을 api 엔진으로 실행
#   --engine cli   translate 잡을 claude-code(CLI) 엔진으로 실행 (기본값)
#   (default 지정 시 engine 필드를 보내지 않음 → 서버 default)
#
#   --model haiku  claude-haiku-4-5 사용 (기본값)
#   --model sonnet claude-sonnet-4-6 사용
#   --model opus   claude-opus-4-8 사용
#
#   --tm-top-k N          TM few-shot 개수 (기본값 1). "default" 지정 시 필드 미전송 (잡 .env default = 10)
#   --chunk-workers N     chunk 병렬도 (기본값 2). PR#192/#199 의 chunk 병렬화 exercise.
#                         "default" 시 잡 .env default (api=4, cli=2).
#   --guidelines-variant-en <v>  en 가이드라인 크기 (aws|unified|unified-v2|default).
#                                기본값 default (잡 .env default = unified-v2).
#   --guidelines-variant-ja <v>  ja 가이드라인 크기 (aws|unified|default).
#                                기본값 default (잡 .env default = unified).
#   --align-v2 / --no-align-v2   PR#218 ko-source-of-truth 모드로 align 실행 여부.
#                                기본값 --align-v2 (opinionated defaults: demote-extras +
#                                translate-headings 자동 활성; ancestor subtree 재번역 포함
#                                zero-residual sweep). fix_headings.py 는 --auto-align-v2-below
#                                (기본 5) 를 자동으로 사용하므로, --align-v2 가 꺼져 있어도
#                                잔여 diff 1..5 인 (doc, lang) 은 자동 escalation 됨.
#
#   --plan <name>                create-translate-test-pr.sh 에 전달할 ko 변형 plan.
#                                round1(기본) / round2 / row-drop-repro / table-suite.
#                                row-drop-repro: cloud-translate PR #283 회귀 재현용.
#                                version-guide.md (alpha 초기부터 en/ja 가 표 행 1개 stale)
#                                의 첫 문단만 짧게 수정 → load_chars/ko_diff_chars 비율이
#                                cap 2 를 초과 → LLM-patch fallback 활성. 결함 상태에서는
#                                번역 PR 의 en/ja 가 stale 행을 그대로 유지하고, PR #283
#                                fix 가 배포되어 있으면 행이 backfill 되거나 잡이 raise.
#                                table-suite: 결함 재현 2케이스 + 정상 표 변형들
#                                (중간 행 삽입·헤더 수정·행 삭제·행 수정·행 추가·신규 표)
#                                의 종합 검증.
#                                - version-guide: CK 인시던트 동형 (LLM-patch 경로).
#                                  PR #283 미배포 = FAIL(행 유실), 배포 후 = 해소 기대.
#                                - release-notes: row-splice positional 손상 (#283 범위 밖
#                                  별개 결함). #283 만 배포된 상태에서는 FAIL 이 정상.
#                                  cloud-translate PR #290 (table-row reconcile, #283 위
#                                  stacked) 배포 후에는 A·B 둘 다 PASS 가 기대값이다.
#                                - 그 외 파일의 FAIL 은 새로운 회귀를 의미한다.
#
#   --translate api|local        번역 실행 방식. api(기본) = dashboard /api/translate
#                                (배포된 Jenkins 잡). local = $CLOUD_TRANSLATE_DIR 의
#                                translate_pr.py 를 직접 실행 — 미배포 브랜치의 번역
#                                로직(예: PR #290 table-row reconcile)을 배포 없이 검증.
#                                engine/model 은 api+haiku 로 고정(기존 run 과 동일 조건),
#                                나머지 preset 플래그도 dashboard 와 동일하게 전달.
#
# 의존성: git, gh (로그인), curl, python3, claude (Claude Code CLI)

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"   # 예: https://docs.internal.nhncloud.com
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}" # 대시보드 관리자에게서 발급받은 값

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH=""                                # 미지정 시 e2e/<timestamp> 자동 생성 (alpha 미오염)
BASE_SOURCE_BRANCH="alpha"                    # 새 e2e 브랜치를 갈라낼 원본
TARGET_URL="https://github.com/${REPO}"
# ─────────────────────────────────────────────────────────────────────

# ── 실행 옵션 ─────────────────────────────────────────────────────────
TRANSLATE_ENGINE="claude-code"            # 기본값 cli — api/default 로 override 가능
TRANSLATE_MODEL="claude-haiku-4-5"        # 기본값 haiku — sonnet/opus/default 로 override 가능
TRANSLATE_TM_TOP_K="1"                    # TM few-shot 개수 기본값 1 (잡 .env default 10 → 절감)
TRANSLATE_CHUNK_WORKERS="2"               # chunk 병렬도 (PR#192/#199). "default" → 필드 미전송
TRANSLATE_GUIDELINES_VARIANT_EN=""        # 기본값 default (잡 .env: unified-v2)
TRANSLATE_GUIDELINES_VARIANT_JA=""        # 기본값 default (잡 .env: unified)
ALIGN_V2=1                                # PR#218 v2 모드 (기본 활성)
PLAN_NAME="round1"                        # create-translate-test-pr.sh --plan 값. round1|round2|row-drop-repro|table-suite
TRANSLATE_VIA="api"                       # api = dashboard /api/translate (기본) | local = 로컬 translate_pr.py
# --translate local 이 사용할 cloud-translate 체크아웃/venv. 워크트리를 가리키면
# 미배포 브랜치(예: PR #290 fix/table-sync-repair)의 번역 로직을 그대로 검증할 수 있다.
# 전제: $CLOUD_TRANSLATE_DIR/.env 에 TRANSLATE_GITHUB_TOKEN + TRANSLATE_ANTHROPIC_API_KEY.
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
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
    --plan)
      case "${2:-}" in
        round1|round2|row-drop-repro|table-suite) PLAN_NAME="$2" ;;
        *) echo "error: --plan 은 round1|round2|row-drop-repro|table-suite 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --translate)
      case "${2:-}" in
        api|local) TRANSLATE_VIA="$2" ;;
        *) echo "error: --translate 는 api|local 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --base-branch)   BASE_BRANCH="$2"; shift 2 ;;        # 기존 e2e 세션 브랜치 재사용
    --base-source)   BASE_SOURCE_BRANCH="$2"; shift 2 ;; # 새 e2e 브랜치를 갈라낼 원본 (기본 alpha)
    -h|--help) sed -n '3,55p' "$0"; exit 0 ;;
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
  BASE_BRANCH="e2e/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/17] Creating fresh e2e session branch: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  git push -u origin "$BASE_BRANCH"
  echo "  E2E_BASE_BRANCH=$BASE_BRANCH"     # wrapper 가 파싱하는 마커
else
  echo "[1/17] Reusing existing base branch: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
fi

# ── 2) restore-alpha-origin (내부에서 commit+push) ────────────────────
echo
echo "[2/17] scripts/restore-alpha-origin.sh"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"

# ── 3) dashboard /api/fix-heading-syntax (heading 문법 정정) ──────────
echo
echo "[3/17] POST $DASHBOARD_BASE_URL/api/fix-heading-syntax (base=$BASE_BRANCH)"

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
echo "[4/17] fix-heading-syntax 잡이 생성하는 PR 감지 대기 (최대 30분)"

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
echo "[5/17] scripts/restore-aligned-public-api.sh"
bash "$REPO_ROOT/scripts/restore-aligned-public-api.sh"

if git diff --quiet && git diff --cached --quiet; then
  echo "  (변경 없음, commit/push 건너뜀)"
else
  git add ko en ja
  git commit -m "restore: aligned public-api.md"
  git push origin "$BASE_BRANCH"
fi

# ── 6) dashboard /api/align 트리거 (권장 preset + PR#218 align_v2) ────
echo
echo "[6/17] POST $DASHBOARD_BASE_URL/api/align (권장 preset, base=$BASE_BRANCH, align_v2=$( ((ALIGN_V2)) && echo true || echo false ))"

# 권장 preset flags: --aligned-marker --demote-extras --translate-headings --reconcile-unmatched
# PR#218 개선사항:
#   - --align-v2 (opinionated defaults 로 demote-extras/translate-headings 자동 활성,
#     ancestor subtree 재번역 + zero-residual sweep)
#   - --auto-align-v2-below N (기본 5) — Jenkins 잡이 fix_headings.py 를 그대로 호출
#     하므로 명시 파라미터 없이도 자동 escalation 이 동작함
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

# ── 7) align PR 감지 (base=alpha 로 새로 open 된 PR) ─────────────────
echo
echo "[7/17] Jenkins align 잡이 생성하는 PR 감지 대기 (최대 30분)"

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
echo "[8/17] claude CLI (fable model) heading/anchor-id 정렬 검사 (PR=$align_pr_url)"

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
echo "[9/17] 검증 통과 — align PR 을 $BASE_BRANCH 로 merge"
gh pr merge "$align_pr_url" --repo "$REPO" --merge --delete-branch
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated: $align_pr_url"

# ── 10) create-translate-test-pr (ko 변형 → translate-test PR 생성) ───
echo
echo "[10/17] scripts/create-translate-test-pr.sh"

create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh" --base-branch "$BASE_BRANCH" --plan "$PLAN_NAME")"
echo "$create_out"

# ── 11) ko 변경 PR 생성 확인 ──────────────────────────────────────────
echo
echo "[11/17] ko 변경 PR 생성 확인"

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

# ── 12) dashboard /api/ko-review 트리거 (ko 변경 PR 대상 한글 검수) ────
echo
echo "[12/17] POST $DASHBOARD_BASE_URL/api/ko-review (PR=$ko_pr_url)"

koreview_body=$(cat <<JSON
{
  "pr_url": "$ko_pr_url"
}
JSON
)

koreview_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$koreview_body" \
  "$DASHBOARD_BASE_URL/api/ko-review")"

echo "$koreview_resp" | python3 -m json.tool

koreview_job_id=$(printf '%s' "$koreview_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("job_id") or "")')

if [[ -z "$koreview_job_id" ]]; then
  echo "  error: /api/ko-review 응답에서 job_id 를 찾지 못했습니다." >&2
  exit 2
fi

# ── 13) ko-review 완료 대기 ──────────────────────────────────────────
echo
echo "[13/17] ko-review 완료 대기 (job_id=$koreview_job_id, 최대 30분)"

deadline=$(( $(date +%s) + 1800 ))
koreview_status=""
while (( $(date +%s) < deadline )); do
  koreview_status="$(curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$koreview_job_id" \
    | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  tasks=(d.get("job") or {}).get("tasks") or []
  print(tasks[0].get("status") if tasks else "")
except Exception:
  print("")')"
  case "$koreview_status" in
    success|failure|cancelled|partial) break ;;
  esac
  sleep 30
done

if [[ "$koreview_status" != "success" ]]; then
  echo "  ko-review 실패 (status=$koreview_status, job_id=$koreview_job_id)" >&2
  exit 2
fi
echo "  ko-review 완료"

# ── 14) ko 변경 PR suggestion 검증 및 전체 accept ─────────────────────
echo
echo "[14/17] ko 변경 PR suggestion 검증 및 accept (PR=$ko_pr_url)"

ko_pr_number="$(gh pr view "$ko_pr_url" --repo "$REPO" --json number --jq .number)"
ko_head_ref_for_suggest="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"

# 리뷰 코멘트 (inline) 를 모두 조회 → ```suggestion 블록 개수 확인
gh api "repos/$REPO/pulls/$ko_pr_number/comments" --paginate > "$tmpdir/pr_comments.json"

n_suggestions=$(PR_COMMENTS_FILE="$tmpdir/pr_comments.json" python3 -c '
import json, os, re
cs=json.load(open(os.environ["PR_COMMENTS_FILE"]))
print(sum(1 for c in cs if re.search(r"```suggestion", c.get("body") or "")))
')

if (( n_suggestions == 0 )); then
  echo "  error: ko-review 가 suggestion 을 남기지 않았습니다 (1개 이상 예상)" >&2
  exit 3
fi
echo "  detected suggestions: $n_suggestions"

# ko PR head 브랜치를 detached worktree 로 체크아웃 → 파일별 line 역순 정렬 적용 → commit + push
# (메인 워크트리가 같은 브랜치를 이미 checkout 한 상태라 -B 로는 충돌; detach 로 회피)
git fetch --quiet origin "$ko_head_ref_for_suggest"
apply_wt="$tmpdir/apply-suggestions"
git worktree add --detach "$apply_wt" "origin/$ko_head_ref_for_suggest" >/dev/null

PR_COMMENTS_FILE="$tmpdir/pr_comments.json" APPLY_WT="$apply_wt" python3 - <<'PYEOF'
import json, os, re
from collections import defaultdict

cs = json.load(open(os.environ["PR_COMMENTS_FILE"]))
by_file = defaultdict(list)
for c in cs:
    body = c.get("body") or ""
    m = re.search(r"```suggestion\n(.*?)```", body, flags=re.DOTALL)
    if not m:
        continue
    path = c.get("path")
    line = c.get("line") or c.get("original_line")
    start = c.get("start_line") or c.get("original_start_line") or line
    if not (path and line and start):
        continue
    by_file[path].append({"start": start, "end": line, "content": m.group(1)})

wt = os.environ["APPLY_WT"]
applied = 0
for path, items in by_file.items():
    fpath = os.path.join(wt, path)
    if not os.path.isfile(fpath):
        print(f"  skip (no such file): {path}")
        continue
    items.sort(key=lambda x: x["start"], reverse=True)
    with open(fpath, "r", encoding="utf-8") as f:
        lines = f.readlines()
    for it in items:
        s = it["start"] - 1
        e = it["end"]
        new = it["content"]
        if not new.endswith("\n"):
            new += "\n"
        new_lines = new.splitlines(keepends=True)
        lines[s:e] = new_lines
        applied += 1
    with open(fpath, "w", encoding="utf-8") as f:
        f.writelines(lines)
print(f"  applied files: {len(by_file)}, suggestions applied: {applied}")
PYEOF

pushd "$apply_wt" >/dev/null
git add -A
if git diff --cached --quiet; then
  echo "  변경 없음 (suggestion diff 매칭 실패 또는 이미 적용됨)"
else
  git commit -m "ko-review: accept $n_suggestions suggestion(s)"
  # detached HEAD → 원격 브랜치로 직접 push
  git push origin "HEAD:refs/heads/$ko_head_ref_for_suggest"
  echo "  suggestions committed & pushed to $ko_head_ref_for_suggest"
fi
popd >/dev/null
git worktree remove "$apply_wt" --force

# 메인 워크트리도 suggestion 반영본으로 최신화 (step 15 translate 트리거 전)
git fetch --quiet origin "$ko_head_ref_for_suggest"
git reset --hard "origin/$ko_head_ref_for_suggest"

# ── 15) ko 변경 PR (suggestion 반영본) 번역 실행 ─────────────────────
trans_pr_url=""
if [[ "$TRANSLATE_VIA" == "local" ]]; then
  # 로컬 cloud-translate 체크아웃의 translate_pr.py 를 직접 실행 — 배포된
  # dashboard/Jenkins 잡 대신 로컬 브랜치(예: PR #290)의 번역 로직을 검증.
  # 플래그는 dashboard 권장 preset 과 동일; engine/model 은 CLI 플래그가
  # 없으므로 env 로 고정 (api + haiku = 기존 e2e run 과 동일 조건).
  echo
  echo "[15/17] local translate_pr.py (dir=$CLOUD_TRANSLATE_DIR, PR=$ko_pr_url, engine=api, model=claude-haiku-4-5)"
  if [[ ! -f "$CLOUD_TRANSLATE_DIR/.env" ]]; then
    echo "error: $CLOUD_TRANSLATE_DIR/.env 가 없습니다 (TRANSLATE_GITHUB_TOKEN / TRANSLATE_ANTHROPIC_API_KEY 필요)" >&2
    exit 1
  fi
  local_log="$tmpdir/local_translate.log"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_TRANSLATE_ENGINE=api \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
      --diff-granularity block --glossary-mode service --max-load-ratio 2 \
      --workers 2 --chunk-workers 2 --tm-top-k 1 \
      --table-rows --skip-full-table --skip-anchor-only \
      --assign-anchors --align-headings --llm-patch-fallback \
  ) 2>&1 | tee "$local_log"
  local_rc=${PIPESTATUS[0]}
  set -e
  if (( local_rc != 0 )); then
    echo "  local translate_pr.py 실패 (exit $local_rc) — 로그: $local_log" >&2
    exit 2
  fi
  # 번역 PR 은 이미 생성된 상태 — step 16 의 gh 폴링이 즉시 감지한다.
else
echo
echo "[15/17] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$ko_pr_url, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default}, tm_top_k=${TRANSLATE_TM_TOP_K:-default}, chunk_workers=${TRANSLATE_CHUNK_WORKERS:-default}, gv_en=${TRANSLATE_GUIDELINES_VARIANT_EN:-default}, gv_ja=${TRANSLATE_GUIDELINES_VARIANT_JA:-default})"

# --engine 옵션이 지정된 경우에만 engine 필드 포함
engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

# --model 값이 설정된 경우에만 model 필드 포함 (default 는 서버가 결정)
model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

# --tm-top-k 값이 설정된 경우에만 tm_top_k 필드 포함
tm_top_k_json=""
if [[ -n "$TRANSLATE_TM_TOP_K" ]]; then
  tm_top_k_json="\"tm_top_k\": \"$TRANSLATE_TM_TOP_K\","
fi

# PR#192/#199 개선: chunk_workers 로 한 파일 안 chunk 병렬 API 호출 exercise
chunk_workers_json=""
if [[ -n "$TRANSLATE_CHUNK_WORKERS" ]]; then
  chunk_workers_json="\"chunk_workers\": \"$TRANSLATE_CHUNK_WORKERS\","
fi

# PR#199 개선: guidelines_variant 로 en/ja 가이드라인 크기 조절 (input 토큰 절감)
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
# PR#207/#211 (within/cross-opcode batching) 은 자동 활성 — 별도 설정 없음.
# PR#220 (api-guide dedup) 은 파일명 substring 매치 (기본 "api-guide"). Agent-Test
# 는 "public-api.md" 라 자동 미매치 — 대시보드에 dedup path override API 는 없음.
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
fi

# ── 16) 번역 PR 감지 대기 (base = ko PR head 브랜치) ──────────────────
ko_head_ref="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"

if [[ -z "$trans_pr_url" ]]; then
  echo
  echo "[16/17] translate 잡이 생성하는 번역 PR 감지 대기 (최대 60분)"

  deadline=$(( $(date +%s) + 3600 ))
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
else
  echo
  echo "[16/17] 번역 PR 확인 (local 실행 출력에서 획득): $trans_pr_url"
fi

if [[ -z "$trans_pr_url" ]]; then
  echo "  timeout: 60분 내 번역 PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# ── 17) claude CLI(fable)로 번역 PR 검증 → 결과를 PR 댓글로 등록 ───────
echo
echo "[17/17] claude CLI (fable model) 번역 PR 검증 (PR=$trans_pr_url)"

trans_head_ref="$(gh pr view "$trans_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$trans_head_ref"
trans_wt="$tmpdir/trans-check"
git worktree add "$trans_wt" "origin/$trans_head_ref" >/dev/null

trans_check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외하고 다음 다섯 가지를 검사해줘.
(1) heading level 순서가 세 언어에서 일치
(2) anchor id 순서가 세 언어에서 일치 (<a id="..."></a> 형식과 { #id } 형식 모두)
(3) 표(table)가 있으면 표 개수와 각 표의 데이터 행(row) 개수가 세 언어에서 일치
    — 표 직후에 빈 줄로 분리된 고아 표 행(| ... | 형태)이 있으면 그것도 FAIL 로 보고
(4) 표의 데이터 행 중 첫 셀이 언어 무관 식별자인 행들의 식별자 집합과 등장 순서가
    세 언어에서 일치. 식별자 = 공백 없이 라틴 문자/숫자/._+- 로만 구성된 버전/코드
    토큰 (예: 1.202602.1, 2.4.1, v1.35, INST-CREATE). CJK 문자(한글·한자·가나)가
    섞인 셀은 번역된 텍스트이므로 식별자가 아니다 (예: u2タイプ, 기본). 식별자는
    번역되지 않으므로 세 언어에서 동일해야 하고, 한 언어에서만 빠졌으면 행 유실,
    한 언어에서만 순서가 다르면 행 순서 불일치다.
(5) en/, ja/ 문서 본문에 한글 음절이 남아 있으면 안 된다 (fenced code block 과
    inline code(`...`) 안은 제외) — 남아 있으면 미번역 잔류(leak)로 FAIL.
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

# 검증 통과 → 번역 PR 을 ko PR head 브랜치로 merge → ko PR 을 alpha 로 merge
echo
echo "검증 통과 — 번역 PR merge: $trans_pr_url (base=$ko_head_ref)"
gh pr merge "$trans_pr_url" --repo "$REPO" --merge --delete-branch
echo "  merged: $trans_pr_url"

echo
echo "ko 변경 PR merge: $ko_pr_url (base=$BASE_BRANCH)"
gh pr merge "$ko_pr_url" --repo "$REPO" --merge --delete-branch
git fetch origin "$BASE_BRANCH"
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated: $ko_pr_url"

echo
echo "완료."
