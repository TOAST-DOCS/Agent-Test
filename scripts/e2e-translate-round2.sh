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
#   3. ko 변경 PR 생성 확인
#   4. dashboard /api/translate 호출 (권장 preset)
#   5. 번역 PR 감지 대기 (base = ko PR head 브랜치)
#   6. claude CLI(fable)로 번역 PR 검증 (heading·id·표 행 수) → PR 댓글 등록
#
# Usage:
#   scripts/e2e-translate-round2.sh [--engine api|cli] [--model haiku|sonnet|opus]
#
#   --engine api|cli   translate 잡의 엔진 지정 (생략 시 서버 default)
#   --model  haiku|sonnet|opus   Claude 모델 지정 (기본값 sonnet)
#
# 의존성: git, gh (로그인), curl, python3, claude (Claude Code CLI)

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH="alpha"
# ─────────────────────────────────────────────────────────────────────

TRANSLATE_ENGINE=""
TRANSLATE_MODEL="claude-sonnet-4-6"       # 기본값 sonnet — haiku/opus/default 로 override 가능
while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      case "${2:-}" in
        api) TRANSLATE_ENGINE="api" ;;
        cli) TRANSLATE_ENGINE="claude-code" ;;
        *) echo "error: --engine 은 api 또는 cli 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
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
    -h|--help) sed -n '3,31p' "$0"; exit 0 ;;
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

# ── 4) dashboard /api/translate 트리거 (권장 preset) ──────────────────
echo
echo "[4/6] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$ko_pr_url, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default})"

engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

translate_body=$(cat <<JSON
{
  "pr_url": "$ko_pr_url",
  $engine_json
  $model_json
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

# ── 5) 번역 PR 감지 대기 (base = ko PR head 브랜치) ───────────────────
echo
echo "[5/6] translate 잡이 생성하는 번역 PR 감지 대기 (최대 60분)"

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
