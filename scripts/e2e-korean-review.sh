#!/usr/bin/env bash
#
# korean-review e2e (Agent-Test):
#   0) webhook 비활성화 (다른 잡 중복 트리거 방지)
#   1) alpha 로부터 세션 브랜치 e2e-koreview/<ts> 생성
#   2) restore-alpha-origin (ko/en/ja 를 alpha-origin 스냅샷으로 되돌림)
#   3) create-translate-test-pr.sh --plan round1 로 ko 변형 PR 생성
#      (base = 세션 브랜치) — 다양한 종류의 문장/heading/표 변형이 들어가므로
#      한글 검수기가 잡을 만한 위반이 자연히 섞인다.
#   4) 검수 실행 — dashboard /api/ko-review 트리거, 또는 --translate local 이면
#      $CLOUD_TRANSLATE_DIR 의 korean-review/review_pr.py 직접 실행
#   5) 잡 상태 폴링 (최대 30분; local 은 동기 실행이라 생략)
#   6) PR reviews · review comments 를 gh api 로 조회
#      → 구조 검증: format_summary() 규격 요약 리뷰 본문 · 인라인 코멘트
#      존재 · `` `suggestion `` 블록 존재
#   7) claude CLI (fable model) 로 검수 결과의 의미 품질 검증 —
#      검출 항목이 실제로 위반을 짚었는지, 요약 표가 형식을 지켰는지.
#      마지막 줄에 KO_REVIEW: OK 또는 KO_REVIEW: FAIL 만 출력.
#      (다른 plan 의 fable check 과 동일한 last-line 계약.)
#
# 세션 브랜치와 ko PR 은 debug 를 위해 남긴다 (수동 정리 지침은 CLAUDE.md).
# alpha 는 절대 오염되지 않는다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-korean-review.sh
#   bash scripts/e2e-korean-review.sh --base-branch e2e-koreview/<ts>   # 기존 세션 재사용
#   bash scripts/e2e-korean-review.sh --plan round2                     # 변형 plan 변경
#   bash scripts/e2e-korean-review.sh --timeout 3600                    # 잡 완료 폴링 timeout(초)
#   bash scripts/e2e-korean-review.sh --skip-fable                      # 구조 검증까지만 (fable check 생략)
#   bash scripts/e2e-korean-review.sh --translate local                 # 검수를 로컬 review_pr.py 로 실행
#
# 의존성: git, gh (로그인), curl, python3, claude (Claude Code CLI)

set -euo pipefail

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
TARGET_URL="https://github.com/${REPO}"
BASE_BRANCH=""
BASE_SOURCE_BRANCH="alpha"
PLAN_NAME="round1"
JOB_TIMEOUT=1800    # 초. ko-review job 완료까지.
SKIP_FABLE=0
# api = dashboard /api/ko-review (배포된 Jenkins 잡) | local = $CLOUD_TRANSLATE_DIR 의
# korean-review/review_pr.py 직접 실행 (미배포 브랜치의 검수 로직 검증).
REVIEW_VIA="api"
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-branch)   BASE_BRANCH="$2"; shift 2 ;;
    --base-source)   BASE_SOURCE_BRANCH="$2"; shift 2 ;;
    --plan)          PLAN_NAME="$2"; shift 2 ;;
    --timeout)       JOB_TIMEOUT="$2"; shift 2 ;;
    --skip-fable)    SKIP_FABLE=1; shift ;;
    --translate)
      case "${2:-}" in
        api|local) REVIEW_VIA="$2" ;;
        *) echo "error: --translate 는 api|local 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -h|--help)       sed -n '3,36p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

# ko-review 잡 id — api 경로에서만 채워진다. local 경로에는 잡이 없으므로
# 미리 선언해 둔다 (set -u 아래에서 마지막 요약/PR 댓글 블록이 이 값을
# 참조하는데, 2026-08-23 실측: 판정을 다 내고 KO_REVIEW: OK 를 출력한 뒤
# `koreview_job_id: unbound variable` 로 exit 1 → suite 가 실패로 집계).
koreview_job_id="(local — Jenkins 잡 없음)"

LOCAL_MODE=0
if [[ "$REVIEW_VIA" == "local" ]]; then
  LOCAL_MODE=1
  if [[ ! -f "$CLOUD_TRANSLATE_DIR/.env" ]]; then
    echo "error: $CLOUD_TRANSLATE_DIR/.env 가 없습니다 (TRANSLATE_GITHUB_TOKEN / TRANSLATE_ANTHROPIC_API_KEY 필요)" >&2
    exit 1
  fi
fi

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다. load_env.sh 를 source 하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── webhook repo 토글 (다른 e2e 스크립트와 동일 헬퍼) ─────────────────
# webhook 대상 repo 토글 — 공용 헬퍼 (규약: webhook e2e 만 활성화)
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"

echo "[0/7] webhook 비활성화 (korean-review e2e 는 webhook 경유 중복 트리거 방지)"
set_webhook_repo_enabled false

# ── 1) 세션 브랜치 준비 ──────────────────────────────────────────────
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-koreview/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/7] Creating fresh e2e session branch: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  git push -u origin "$BASE_BRANCH"
  echo "  E2E_BASE_BRANCH=$BASE_BRANCH"
else
  echo "[1/7] Reusing existing base branch: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
fi

# ── 2) restore-alpha-origin ──────────────────────────────────────────
echo
echo "[2/7] scripts/restore-alpha-origin.sh"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"

# restore-alpha-origin 은 내부에서 commit/push 를 하지 않는다. e2e-align 은
# align 단계가 이어지지만 여기서는 곧바로 ko 변형 PR 을 만들어야 하므로,
# 변경이 있으면 세션 브랜치에 반영해서 create-translate-test-pr.sh 의
# `git diff --quiet` 사전 체크를 통과시킨다.
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add ko en ja
  git commit -m "restore: alpha-origin (korean-review e2e session)"
  git push origin "$BASE_BRANCH"
fi

# ── 3) ko 변형 PR 생성 ──────────────────────────────────────────────
echo
echo "[3/7] scripts/create-translate-test-pr.sh --plan $PLAN_NAME --base-branch $BASE_BRANCH"
create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh" --base-branch "$BASE_BRANCH" --plan "$PLAN_NAME")"
echo "$create_out"

ko_pr_url="$(grep -oE 'https://github.com/[^ ]+/pull/[0-9]+' <<<"$create_out" | tail -n1 || true)"
if [[ -z "$ko_pr_url" ]]; then
  echo "  error: create-translate-test-pr.sh 출력에서 PR URL 을 찾지 못했습니다." >&2
  exit 2
fi
ko_pr_number="${ko_pr_url##*/}"
ko_pr_state="$(gh pr view "$ko_pr_url" --repo "$REPO" --json state --jq .state)"
if [[ "$ko_pr_state" != "OPEN" ]]; then
  echo "  error: ko 변형 PR 이 open 상태가 아닙니다 (state=$ko_pr_state): $ko_pr_url" >&2
  exit 2
fi
echo "  ko 변형 PR: $ko_pr_url (state=$ko_pr_state)"

# ── 4~5) ko-review 실행 ─────────────────────────────────────────────
if (( LOCAL_MODE )); then
  # korean-review/Jenkinsfile 의 PR 모드는 `python korean-review/review_pr.py
  # <PR URL>` 한 줄이 전부다 (잡 파라미터가 default 면 옵션 미전송). 동기
  # 실행이므로 5단계의 Jobs 폴링이 불필요.
  echo
  echo "[4/7] local review_pr.py (dir=$CLOUD_TRANSLATE_DIR, PR=$ko_pr_url)"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" korean-review/review_pr.py "$ko_pr_url") 2>&1 | sed 's/^/    /'
  koreview_rc=${PIPESTATUS[0]}
  set -e
  if (( koreview_rc != 0 )); then
    echo "  local review_pr.py 실패 (exit $koreview_rc)" >&2
    exit 2
  fi
  echo
  echo "[5/7] (local 실행이라 잡 완료 폴링 불필요)"
else
echo
echo "[4/7] POST $DASHBOARD_BASE_URL/api/ko-review (PR=$ko_pr_url)"

koreview_body="{\"pr_url\": \"$ko_pr_url\"}"
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

# ── 5) ko-review 잡 완료 폴링 ────────────────────────────────────────
echo
echo "[5/7] ko-review 완료 대기 (job_id=$koreview_job_id, timeout=${JOB_TIMEOUT}s)"

deadline=$(( $(date +%s) + JOB_TIMEOUT ))
koreview_status=""
while (( $(date +%s) < deadline )); do
  # e2e-align-and-translate.sh 와 동일 패턴 — 폴링 curl 의 일시 오류를 흡수.
  koreview_status="$(curl -sS --retry 3 --retry-delay 5 \
    -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$koreview_job_id" 2>/dev/null \
    | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  tasks=(d.get("job") or {}).get("tasks") or []
  print(tasks[0].get("status") if tasks else "")
except Exception:
  print("")' || true)"
  case "$koreview_status" in
    success|failure|cancelled|partial) break ;;
  esac
  sleep 10
done

if [[ "$koreview_status" != "success" ]]; then
  echo "  ko-review 실패 (status=$koreview_status, job_id=$koreview_job_id)" >&2
  exit 2
fi
echo "  ko-review 완료 (status=success)"
fi

# ── 6) PR reviews · review comments 조회 → 구조 검증 ─────────────────
echo
echo "[6/7] PR reviews · review comments 구조 검증"

tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT

# submitted review 본문들 (요약 헤더가 여기에 있음)
gh api "repos/$REPO/pulls/$ko_pr_number/reviews" --paginate > "$tmpdir/reviews.json"
# inline review comments (파일·줄에 앵커된 개별 지적)
gh api "repos/$REPO/pulls/$ko_pr_number/comments" --paginate > "$tmpdir/comments.json"

REVIEWS_FILE="$tmpdir/reviews.json" COMMENTS_FILE="$tmpdir/comments.json" python3 - <<'PYEOF'
import json, os, re, sys

reviews = json.load(open(os.environ["REVIEWS_FILE"]))
comments = json.load(open(os.environ["COMMENTS_FILE"]))

summary_bodies = [(r.get("body") or "") for r in reviews if (r.get("body") or "").strip()]
has_summary_header = any(re.search(r"##\s*🔍\s*한글 검수 결과", b) for b in summary_bodies)
# '검출 항목' 은 CLAUDE.md 상 `### 검출 항목` 이 규격이지만, 실제 app/output.py
# format_summary() 는 collapsible `<details><summary>...검출 항목 N건...</summary>`
# 로 감싼다. 둘 다 허용.
has_detected_items = any(
    "### 검출 항목" in b
    or re.search(r"<details>\s*<summary>[^<]*검출 항목", b)
    for b in summary_bodies
)
# '차원별 점검' 은 `### 차원별 점검` heading 또는 그 표만(heading 없이) 나올 수
# 있는데 표 자체는 항상 `| 차원 | 결과 |` 로 시작한다.
has_dimension_table = any(
    "### 차원별 점검" in b or "| 차원 | 결과 |" in b
    for b in summary_bodies
)
# 위반 0건 케이스는 "위반 없음 ✅ — 점검 차원 전부 통과" 형식으로 요약이 나올 수 있음.
has_no_violation_notice = any("위반 없음" in b for b in summary_bodies)

n_inline_comments = len(comments)
n_suggestions = sum(1 for c in comments if re.search(r"```suggestion", c.get("body") or ""))

print(f"  submitted reviews (with body)     : {len(summary_bodies)}")
print(f"  summary header 존재 ('한글 검수') : {'yes' if has_summary_header else 'no'}")
print(f"  '### 검출 항목' 섹션              : {'yes' if has_detected_items else 'no'}")
print(f"  '### 차원별 점검' 표              : {'yes' if has_dimension_table else 'no'}")
print(f"  '위반 없음' notice                : {'yes' if has_no_violation_notice else 'no'}")
print(f"  inline review comments (총)       : {n_inline_comments}")
print(f"  ```suggestion 블록 포함 코멘트     : {n_suggestions}")

# 판정 — round1 은 다양한 변형이 있어 결정적 규칙(외래어·값·리터럴 코드·조사
# 띄어쓰기 등) 이 최소 1건은 확정으로 잡는다. 반환코드는 아래 판정에 따라.
problems = []
if not summary_bodies:
    problems.append("submitted review 가 하나도 없음 (요약 리뷰 미게시)")
elif not has_summary_header and not has_no_violation_notice:
    problems.append("요약 리뷰 본문에 '## 🔍 한글 검수 결과' 헤더도 '위반 없음' 문구도 없음")
elif has_summary_header:
    if not has_detected_items:
        problems.append("요약 리뷰에 '### 검출 항목' 섹션이 없음")
    if not has_dimension_table:
        problems.append("요약 리뷰에 '### 차원별 점검' 표가 없음")
if n_inline_comments == 0 and not has_no_violation_notice:
    problems.append("인라인 review comment 가 0건인데 요약도 '위반 없음' 이 아님")

if problems:
    print()
    print("STRUCT_CHECK: FAIL")
    for p in problems:
        print(f"  - {p}")
    sys.exit(3)
else:
    print()
    print("STRUCT_CHECK: PASS")
PYEOF

# ── 7) claude CLI (fable) 로 의미 품질 검증 ──────────────────────────
if (( SKIP_FABLE )); then
  echo
  echo "[7/7] --skip-fable — fable 의미 검증 건너뜀"
  echo
  echo "==================================================================="
  echo "  결과 요약"
  echo "==================================================================="
  echo "  ko PR         : $ko_pr_url"
  echo "  ko-review job : $koreview_job_id"
  echo "  구조 검증     : PASS"
  echo "  fable 검증    : skipped"
  echo "==================================================================="
  exit 0
fi

echo
echo "[7/7] claude CLI (fable) 로 검수 결과 의미 품질 검증 (PR=$ko_pr_url)"

# fable 워크트리에 넣을 컨텍스트: (a) 요약 리뷰 본문들 (b) 인라인 코멘트들
# JSON.  파일/줄 매핑을 사람이 읽기 좋게 정돈.
REVIEWS_FILE="$tmpdir/reviews.json" COMMENTS_FILE="$tmpdir/comments.json" \
CONTEXT_FILE="$tmpdir/review_context.md" python3 - <<'PYEOF'
import json, os, re
reviews = json.load(open(os.environ["REVIEWS_FILE"]))
comments = json.load(open(os.environ["COMMENTS_FILE"]))
out = ["# ko-review 결과 컨텍스트", ""]

out.append("## Submitted reviews (요약 본문)")
out.append("")
for i, r in enumerate(reviews):
    body = (r.get("body") or "").strip()
    if not body:
        continue
    out.append(f"### review #{i+1} (state={r.get('state')})")
    out.append("")
    out.append(body)
    out.append("")

out.append("## Inline review comments")
out.append("")
for c in comments:
    path = c.get("path") or "?"
    line = c.get("line") or c.get("original_line") or "?"
    body = (c.get("body") or "").strip()
    out.append(f"### `{path}` L{line}")
    out.append("")
    out.append(body)
    out.append("")

open(os.environ["CONTEXT_FILE"], "w").write("\n".join(out))
print(f"  context written: {os.environ['CONTEXT_FILE']} ({sum(1 for r in reviews if (r.get('body') or '').strip())} review body, {len(comments)} inline)")
PYEOF

# ko PR head 를 fable 워크트리로 체크아웃 → fable 이 ko/*.md 실제 내용과
# review 지적을 대조.
ko_head_ref="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$ko_head_ref"
check_wt="$tmpdir/koreview-check"
git worktree add "$check_wt" "origin/$ko_head_ref" >/dev/null

# review 컨텍스트를 워크트리에 복사 (claude 프롬프트가 상대 경로로 참조 가능하게).
cp "$tmpdir/review_context.md" "$check_wt/.ko-review-context.md"

check_prompt='이 저장소는 NHN Cloud 사용자 가이드 픽스처입니다. 방금 우리 한글 검수
봇(korean-review)이 이 PR 의 ko/*.md 변경분을 검수하고 결과를 남겼습니다.
검수 결과 전문(요약 리뷰 본문 + 인라인 코멘트)은 `.ko-review-context.md`
에 있습니다.

당신의 임무는 이 검수 결과의 **의미 품질** 을 검증하는 것입니다:

(1) `.ko-review-context.md` 를 먼저 읽으세요. 요약 본문에 다음 형태가 있어야
    합니다 (위반이 있는 경우):
      - `## 🔍 한글 검수 결과 — 위반 N건` 헤더
      - `### 검출 항목` 아래 `L{line} \`[{차원}]\` {메시지} (확정|판단/확인)` 리스트
      - `### 차원별 점검` 마크다운 표 (차원 | 결과 열)
    위반이 없다면 "위반 없음 ✅ — 점검 차원 전부 통과" 형식이면 됩니다.
    형식이 이 규격에서 벗어난 부분이 있으면 지적하세요.

(2) 인라인 코멘트마다 그 파일의 그 줄 (`gh` 없이 저장소 트리를 직접 Read/
    Grep 으로 확인) 이 실제로 그 지적 사유에 해당하는지 스팟체크 하세요.
    3~5건을 골라 실제 문맥과 대조.  **확정** 라벨의 suggestion 이 원문을
    올바르게 대체하는지도 확인. 명백한 오탐 (원문과 지적이 무관) 이 있는지
    특히 주의.

(3) 요약과 인라인 코멘트의 정합성 — 요약 헤더의 "위반 N건" 숫자와 인라인
    코멘트 수 (같은 줄에 여러 지적이 합쳐질 수 있음) 가 대략 일치해야 합니다
    (정확 일치 요구 X, 대략적으로 관련만 확인).

파일별·항목별 판정을 표 또는 리스트로 출력한 뒤 마지막 줄에는 **다른 텍스트
없이** 전체 판정만 `KO_REVIEW: OK` 또는 `KO_REVIEW: FAIL` 로 출력하세요.
KO_REVIEW: FAIL 인 경우 그 근거를 판정 표에 명확히 남기세요.'

koreview_check_out="$(cd "$check_wt" && claude -p "$check_prompt" \
  --model fable \
  --allowedTools "Bash,Read,Grep,Glob")"

echo "$koreview_check_out"

git worktree remove "$check_wt" --force

# 결과를 ko PR 댓글로 등록
if grep -q '^KO_REVIEW: OK' <<<"$koreview_check_out"; then
  verdict_line="✅ ko-review 자동 검증 통과 (요약 규격 · 인라인 코멘트 스팟체크 · 정합성)"
  overall_rc=0
else
  verdict_line="❌ ko-review 자동 검증 실패 — 아래 상세 결과를 확인하세요"
  overall_rc=3
fi

cat > "$tmpdir/koreview_comment.md" <<EOF
## ko-review e2e 자동 검증 결과 (claude CLI, fable)

$verdict_line

- 검수 잡 job_id: \`$koreview_job_id\`
- 검증 대상 브랜치: \`$ko_head_ref\`
- 검증 항목: 요약 리뷰 규격 · 인라인 코멘트 스팟체크 · 요약/인라인 정합성

<details>
<summary>상세 결과</summary>

$koreview_check_out

</details>
EOF

gh pr comment "$ko_pr_url" --repo "$REPO" --body-file "$tmpdir/koreview_comment.md"
echo "  검증 결과 댓글 등록 완료: $ko_pr_url"

echo
echo "==================================================================="
echo "  결과 요약"
echo "==================================================================="
echo "  ko PR         : $ko_pr_url"
echo "  ko-review job : $koreview_job_id"
echo "  구조 검증     : PASS"
echo "  fable 판정    : $(grep -oE '^KO_REVIEW: (OK|FAIL)' <<<"$koreview_check_out" | tail -n1)"
echo "==================================================================="

exit $overall_rc
