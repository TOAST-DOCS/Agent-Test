#!/usr/bin/env bash
#
# 2라운드 번역 e2e (Agent-Test alpha):
#
# 전제: scripts/e2e-align-and-translate.sh 가 이미 실행되어 1라운드 ko 변경 PR 과
#       그 번역 PR 이 **alpha 브랜치에 머지된** 상태. 즉 alpha 에는 1라운드
#       산출물(추가 섹션·추가 표 행·변경 heading 등)과 그 번역이 함께 들어 있고
#       세 언어가 다시 정합(마커/anchor 일치)인 상태다.
#
# 이 스크립트는 그 위에 **2차 ko 변경**을 발생시켜, 이미 증분 번역을 거친
# 문서에 대한 반복 증분 번역(2세대 drift)을 검증한다:
#   1. alpha 최신화 + 1라운드 산출물 존재 확인 (전제 미충족 시 즉시 중단)
#   2. scripts/create-translate-test-pr.sh --plan round2 (2차 ko 변형 PR 생성)
#      - overview        : 1R 이 추가한 섹션 삭제 + 새 문단 추가
#      - console-guide   : heading 제목 재변경 (같은 id 로 2번째 rename)
#      - component-guide : 1R 이 추가한 문단 본문 수정
#      - public-api      : 1R 이 추가한 표 행(TEST-ROW) 삭제
#      - kernel-guide    : 1R 이 섹션을 삭제한 문서에 신규 섹션 추가
#      - feature-matrix  : 표 행 추가 + 신규 하위 섹션 삽입
#      - troubleshooting : 1R 대조군 파일 본문 수정 (신규 활성화)
#   3. ko 변경 PR 생성 확인 → alpha 로 즉시 머지 (PR head 브랜치는 유지)
#   4. dashboard /api/translate 호출 (권장 preset, 머지된 ko PR URL 대상)
#   5. 번역 PR 감지 대기 (base = ko PR head 브랜치, 머지 후에도 남아 있음)
#   6. claude CLI(fable)로 번역 PR 검증 (heading·id·표 행 수) → PR 댓글 등록
#
# Usage:
#   scripts/e2e-translate-round2.sh [--engine api|cli] [--model haiku|sonnet|opus]
#                                   [--tm-top-k N] [--chunk-workers N]
#                                   [--guidelines-variant-en aws|unified|unified-v2|default]
#                                   [--guidelines-variant-ja aws|unified|default]
#
#   --engine api|cli   translate 잡의 엔진 지정 (기본값 cli, default 로 서버 default 사용)
#   --model  haiku|sonnet|opus   Claude 모델 지정 (기본값 haiku)
#   --tm-top-k N       TM few-shot 개수 (기본값 1, default 로 잡 .env default=10)
#   --chunk-workers N  chunk 병렬도 (기본값 2, PR#192/#199)
#   --guidelines-variant-en <v>  en 가이드라인 크기 (PR#199)
#   --guidelines-variant-ja <v>  ja 가이드라인 크기 (PR#199)
#
# 의존성: git, gh (로그인), curl, python3, claude (Claude Code CLI)

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH="alpha"
# ─────────────────────────────────────────────────────────────────────

TRANSLATE_ENGINE="claude-code"            # 기본값 cli
TRANSLATE_MODEL="claude-haiku-4-5"        # 기본값 haiku
TRANSLATE_TM_TOP_K="1"                    # TM few-shot 개수 기본값 1
TRANSLATE_CHUNK_WORKERS="2"               # chunk 병렬도 (PR#192/#199)
TRANSLATE_GUIDELINES_VARIANT_EN=""        # 기본값 default
TRANSLATE_GUIDELINES_VARIANT_JA=""        # 기본값 default
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
    -h|--help) sed -n '3,37p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL 과 DASHBOARD_API_TOKEN 을 지정하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT

# ── 1) alpha 최신화 + 1라운드 산출물 존재 확인 ────────────────────────
echo "[1/6] git checkout $BASE_BRANCH + 1라운드 산출물 확인"
git fetch origin "$BASE_BRANCH"
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

precheck_fail=0
if ! grep -q 'test-added-section' ko/overview.md; then
  echo "  전제 미충족: ko/overview.md 에 1라운드 추가 섹션(test-added-section)이 없습니다." >&2
  precheck_fail=1
fi
if ! grep -q 'TEST-ROW' ko/public-api.md; then
  echo "  전제 미충족: ko/public-api.md 에 1라운드 추가 표 행(TEST-ROW)이 없습니다." >&2
  precheck_fail=1
fi
for lang in en ja; do
  if ! grep -q 'test-added-section' "$lang/overview.md"; then
    echo "  전제 미충족: $lang/overview.md 에 번역된 1라운드 섹션이 없습니다 (번역 PR 이 alpha 에 머지됐는지 확인)." >&2
    precheck_fail=1
  fi
done
if (( precheck_fail )); then
  echo "  → e2e-align-and-translate.sh 실행 후 ko 변경 PR·번역 PR 을 alpha 로 머지한 뒤 다시 실행하세요." >&2
  exit 2
fi
echo "  1라운드 산출물 확인 완료 (ko/en/ja)"

# ── 2) 2차 ko 변형 PR 생성 ────────────────────────────────────────────
echo
echo "[2/6] scripts/create-translate-test-pr.sh --plan round2"
create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh" --plan round2)"
echo "$create_out"

# ── 3) ko 변경 PR 생성 확인 ──────────────────────────────────────────
echo
echo "[3/6] ko 변경 PR 생성 확인"
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

# ── 3.5) ko 변경 PR 을 alpha 로 머지 (translate 호출 전, PR 브랜치 유지) ─
echo
echo "[3.5/6] ko 변경 PR 을 $BASE_BRANCH 로 merge (translate 호출 전, PR head 브랜치 유지)"
gh pr merge "$ko_pr_url" --repo "$REPO" --merge
git fetch origin "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated: $ko_pr_url (head 브랜치 유지)"

# ── 4) dashboard /api/translate 트리거 (권장 preset) ──────────────────
echo
echo "[4/6] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$ko_pr_url, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default}, tm_top_k=${TRANSLATE_TM_TOP_K:-default})"

engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

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

# ── 5) 번역 PR 감지 대기 (head = translate/<ko_head_ref>-*) ────────────
# ko PR 이 이미 alpha 로 머지된 상태라 translation PR 의 base 는 alpha 가 되므로
# base 필터 대신 head 브랜치 이름 패턴으로 감지한다.
echo
echo "[5/6] translate 잡이 생성하는 번역 PR 감지 대기 (최대 60분)"

ko_head_ref="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
trans_head_prefix="translate/${ko_head_ref}-"

deadline=$(( $(date +%s) + 3600 ))
trans_pr_url=""
while (( $(date +%s) < deadline )); do
  trans_pr_url="$(gh pr list --repo "$REPO" --state open \
    --json url,headRefName \
    --jq --arg p "$trans_head_prefix" '.[] | select(.headRefName | startswith($p)) | .url' \
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

# ── 6) claude CLI(fable)로 번역 PR 검증 → 결과를 PR 댓글로 등록 ────────
echo
echo "[6/6] claude CLI (fable model) 번역 PR 검증 (PR=$trans_pr_url)"

trans_head_ref="$(gh pr view "$trans_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$trans_head_ref"
trans_wt="$tmpdir/trans-check"
git worktree add "$trans_wt" "origin/$trans_head_ref" >/dev/null

trans_check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외하고 다음 네 가지가 세 언어에서 완전히 일치하는지 검사해줘.
(1) heading level 순서
(2) anchor id 순서 (<a id="..."></a> 형식과 { #id } 형식 모두)
(3) 표(table)가 있으면 표 개수와 각 표의 데이터 행(row) 개수
(4) 1라운드 테스트 산출물의 2차 변경 반영: ko/overview.md 에서 삭제된
    test-added-section 섹션이 en/ja 에도 없는지, ko/public-api.md 에서 삭제된
    TEST-ROW 행이 en/ja 표에도 없는지
파일별 결과를 OK/FAIL 표로 출력하고 (표 개수·행 수 포함), FAIL 인 파일은 어긋난 위치와 내용을 설명해줘.
마지막 줄에는 다른 텍스트 없이 전체 판정만 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" 로 출력해.'

trans_check_out="$(cd "$trans_wt" && claude -p "$trans_check_prompt" \
  --model fable \
  --allowedTools "Bash,Read,Grep,Glob")"

echo "$trans_check_out"

git worktree remove "$trans_wt" --force

if grep -q '^ALIGNMENT: OK' <<<"$trans_check_out"; then
  verdict_line="✅ 2라운드 번역 PR 자동 검증 통과 (heading·anchor-id·표 행 수·2차 변경 반영)"
else
  verdict_line="❌ 2라운드 번역 PR 자동 검증 실패 — 아래 상세 결과를 확인하세요"
fi

cat > "$tmpdir/trans_comment.md" <<EOF
## 2라운드 번역 PR 자동 검증 결과 (claude CLI, fable)

$verdict_line

- 검증 브랜치: \`$trans_head_ref\`
- 검증 항목: ko/en/ja heading level 순서 · anchor id 순서 · 표 개수/행 수 · 1라운드 산출물의 2차 변경(섹션/행 삭제) 반영

<details>
<summary>상세 결과</summary>

$trans_check_out

</details>
EOF

gh pr comment "$trans_pr_url" --repo "$REPO" --body-file "$tmpdir/trans_comment.md"
echo "  검증 결과 댓글 등록 완료: $trans_pr_url"

if ! grep -q '^ALIGNMENT: OK' <<<"$trans_check_out"; then
  echo "  2라운드 번역 PR 검증 실패 — PR 은 open 으로 남깁니다: $trans_pr_url" >&2
  exit 3
fi

echo
echo "완료."
