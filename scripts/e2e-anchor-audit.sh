#!/usr/bin/env bash
#
# anchor id 후속 검증 e2e (Agent-Test):
#   한글 검수(korean-review)가 끝난 뒤 도는 `app/anchor_audit.py` 단계가
#   "저자가 하지 말아야 할 것" 을 실제 PR 에서 잡아내는지, 그리고 **정상 편집을
#   조용히 지나가는지** 를 실제 GitHub PR 로 검증한다.
#
#   0) webhook 비활성화 (중복 트리거 방지)
#   1) alpha 로부터 세션 브랜치 e2e-anchoraudit/<ts> 생성 + 픽스처 6종 시드
#   2) head 브랜치 anchor-audit/<ts> 에 "금지 목록" 대로 픽스처를 망가뜨림
#   3) PR 생성 (base = 세션 브랜치)
#   4) korean-review 실행 — 기본은 로컬 review_pr.py (이 검사는 아직 배포 전이라
#      로컬이 기본. --review api 로 배포 잡 경유도 가능)
#   5) PR 의 마커 코멘트(`<!-- korean-review:anchor-audit -->`)를 읽어 규칙 판정
#   5b) 인라인 코멘트 판정 — 지적이 해당 줄에 달렸는지, diff 밖 지적이
#      가장 가까운 변경 줄로 옮겨 달렸는지
#   6) upsert 재실행 — 요약·인라인 어느 쪽도 쌓이지 않는지 확인
#
# 픽스처를 alpha 에 commit 하지 않고 **세션 브랜치에 시드**하는 이유: 여기서
# 필요한 것은 pre-align 산출물의 정교한 모양이 아니라 "정본 형태의 문서를 이렇게
# 고치면 어떻게 되나" 뿐이라, 시드가 실물을 잘못 흉내 낼 위험이 없다. 반대로
# alpha 에 두면 translate·link-check·todo 스캔이 매번 이 문서들을 집어 든다.
# (fix-links 픽스처가 alpha 에 사는 것은 pre-align stub 모양을 흉내 내야 해서다.)
#
# 세션 브랜치와 PR 은 debug 를 위해 남긴다 (정리 지침은 CLAUDE.md).
# alpha 는 절대 오염되지 않는다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-anchor-audit.sh
#   bash scripts/e2e-anchor-audit.sh --review api            # 배포된 ko-review 잡 경유
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-anchor-audit.sh                       # 워크트리의 코드로 검증
#   bash scripts/e2e-anchor-audit.sh --keep-review-off       # LLM 검수를 건너뛰고
#                                                            # 후속 검증만 (--dry-run 아님)
#
# 의존성: git, gh (로그인), python3
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE_BRANCH="alpha"
BASE_BRANCH=""
REVIEW_VIA="local"
SKIP_LLM_REVIEW=0
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-branch)     BASE_BRANCH="$2"; shift 2 ;;
    --base-source)     BASE_SOURCE_BRANCH="$2"; shift 2 ;;
    --review)          REVIEW_VIA="$2"; shift 2 ;;
    --keep-review-off) SKIP_LLM_REVIEW=1; shift ;;
    -h|--help)         sed -n '3,33p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

TS="$(date -u +%Y%m%d-%H%M%S)"
# marker 의 sig 는 `[a-f0-9]+` 만 허용된다 (shared/github_client._PRE_ALIGN_MARKER_RE) — 타임스탬프를 그대로 넣으면
# marker 가 있는데도 "없음" 으로 읽혀 no-align-marker 가 전 파일에 뜬다.
SIG="$(printf '%s' "$TS" | md5sum | cut -c1-16)"
[[ -n "$BASE_BRANCH" ]] || BASE_BRANCH="e2e-anchoraudit/$TS"
HEAD_BRANCH="anchor-audit/$TS"

pass=0; fail=0
check() {  # check "<rule>" <0|1>
  if [[ "$2" == "0" ]]; then echo "  PASS  $1"; pass=$((pass+1))
  else echo "  FAIL  $1"; fail=$((fail+1)); fi
}

# ── 0) webhook 비활성화 ──────────────────────────────────────────────
# 자격 증명은 여기서 하드 체크한다 — e2e-webhook-toggle.sh 의 규약이다. 비어
# 있으면 토글이 조용히 no-op 이 되고, webhook 이 켜진 채로 e2e 가 PR 을 만들어
# 배포된 잡을 중복 트리거한다(이 헬퍼가 막으려는 바로 그 상황).
if [[ -z "${DASHBOARD_BASE_URL:-}" || -z "${DASHBOARD_API_TOKEN:-}" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다. load_env.sh 를 source 하세요." >&2
  exit 1
fi
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0/6] webhook 비활성화"
set_webhook_repo_enabled false

# ── 1) 세션 브랜치 + 픽스처 시드 ────────────────────────────────────
echo
echo "[1/6] 세션 브랜치 $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH) + 픽스처 시드"
git fetch -q origin "$BASE_SOURCE_BRANCH"
git checkout -q -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"

# 정본 형태 = pre-align marker + `<a id>` 단독 라인 + h2~h3 의 `{ #id }`.
seed_doc() {  # seed_doc <path> <title> <marker?>
  local path="$1" title="$2" marker="$3"
  {
    [[ "$marker" == "marker" ]] && echo "<!-- pre-align:aligned sig=$SIG -->"
    cat <<EOF
# $title

<a id="overview"></a>
## 개요 { #overview }

이 문서는 anchor id 후속 검증 e2e 픽스처입니다.

<a id="details"></a>
## 상세 정보 { #details }

두 번째 섹션의 본문입니다.
EOF
  } > "$path"
}

seed_doc ko/anchor-audit-r1.md   "Anchor Audit R1"   marker
seed_doc ko/anchor-audit-r2.md   "Anchor Audit R2"   marker
seed_doc ko/anchor-audit-r3.md   "Anchor Audit R3"   marker
seed_doc ko/anchor-audit-r4.md   "Anchor Audit R4"   nomarker
seed_doc ko/anchor-audit-good.md "Anchor Audit GOOD" marker
seed_doc ko/anchor-audit-ok.md   "Anchor Audit OK"   marker
seed_doc en/anchor-audit-r5.md   "Anchor Audit R5"   marker

git add ko/anchor-audit-*.md en/anchor-audit-*.md
git commit -qm "test(anchor-audit): e2e 픽스처 시드 ($TS)"
git push -q -u origin "$BASE_BRANCH"
echo "  E2E_BASE_BRANCH=$BASE_BRANCH"

# ── 2) head 브랜치 — 금지 목록대로 망가뜨린다 ───────────────────────
echo
echo "[2/6] head 브랜치 $HEAD_BRANCH — 금지 목록 재현"
git checkout -q -B "$HEAD_BRANCH" "$BASE_BRANCH"

# R1: `<a id>` 줄만 변경 → anchor-only 패치 → 파일이 번역 run 에서 제외.
sed -i 's|<a id="overview"></a>|<a id="intro"></a>|' ko/anchor-audit-r1.md

# R2: heading 의 `{ #id }` 만 변경 → 다음 실행에 원복.
sed -i 's|## 개요 { #overview }|## 개요 { #intro }|' ko/anchor-audit-r2.md

# R3: 미인식 표기(`<span id>`) · 앵커 없는 `{ #id }` · h1 앵커 · h4 attr.
python3 - <<'PY'
import pathlib
p = pathlib.Path("ko/anchor-audit-r3.md")
s = p.read_text()
s = s.replace("# Anchor Audit R3", '<a id="page-title"></a>\n# Anchor Audit R3', 1)
s += """
<span id="legacy-anchor"></span>
## 레거시 표기 { #legacy-anchor }

`<span id>` 로 앵커를 단 섹션입니다.

## 저자 지정 { #author-id }

`{ #id }` 만으로 id 를 지정한 섹션입니다.

#### 깊은 섹션 { #deep-attr }

h4 에 attr 을 단 섹션입니다.
"""
p.write_text(s)
PY

# R4: marker 없는 문서에 앵커 추가 + id 중복.
cat >> ko/anchor-audit-r4.md <<'EOF'

<a id="overview"></a>
## 또 다른 개요 { #overview }

같은 id 를 다시 쓴 섹션입니다.
EOF

# GOOD: 권장 경로 — `<a id>` · `{ #id }` · 본문을 함께 정합하게 수정.
sed -i -e 's|<a id="overview"></a>|<a id="intro"></a>|' \
       -e 's|## 개요 { #overview }|## 개요 { #intro }|' \
       -e 's|이 문서는 anchor id 후속 검증 e2e 픽스처입니다.|이 문서는 anchor id 후속 검증 e2e 픽스처이며 본문도 함께 고쳤습니다.|' \
       ko/anchor-audit-good.md

# OK: 대조군 — 본문만 수정(앵커 무관).
sed -i 's|두 번째 섹션의 본문입니다.|두 번째 섹션의 본문을 고쳤습니다.|' ko/anchor-audit-ok.md

# R5: 번역본(en)의 앵커 직접 수정.
sed -i 's|<a id="overview"></a>|<a id="intro"></a>|' en/anchor-audit-r5.md

git add ko/anchor-audit-*.md en/anchor-audit-*.md
git commit -qm "test(anchor-audit): 금지 목록 재현 ($TS)"
git push -q -u origin "$HEAD_BRANCH"

# ── 3) PR ───────────────────────────────────────────────────────────
echo
echo "[3/6] PR 생성"
pr_url="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$HEAD_BRANCH" \
  --title "test(anchor-audit): anchor id 금지 목록 재현 ($TS)" \
  --body "korean-review 의 anchor id 후속 검증 e2e. 각 파일이 금지 목록의 한 줄을 재현합니다.")"
pr_number="${pr_url##*/}"
echo "  PR: $pr_url"

# ── 4) korean-review 실행 ───────────────────────────────────────────
echo
echo "[4/6] korean-review 실행 (via=$REVIEW_VIA, dir=$CLOUD_TRANSLATE_DIR)"
if [[ "$REVIEW_VIA" == "local" ]]; then
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || {
    echo "error: $CLOUD_TRANSLATE_DIR/.env 가 없습니다" >&2; exit 2; }
  set +e
  ( cd "$CLOUD_TRANSLATE_DIR" && \
    if (( SKIP_LLM_REVIEW )); then
      # 후속 검증만 — 검수 단계를 건너뛰되 게시는 실제로 한다.
      "$CLOUD_TRANSLATE_PY" - "$pr_url" <<'PY'
import asyncio, sys
sys.path[:0] = ["korean-review", "."]
from shared.github_client import GitHubClient
from app import anchor_audit
url = sys.argv[1]
repo = url.split("/pull/")[0].split("github.com/")[1]
num = int(url.rsplit("/", 1)[1])

async def main():
    c = GitHubClient()
    info = await c.get_pr_info(repo, num)
    await anchor_audit.run_stage(c, repo, num, info["head"]["sha"], dry_run=False)
asyncio.run(main())
PY
    else
      "$CLOUD_TRANSLATE_PY" korean-review/review_pr.py "$pr_url"
    fi ) 2>&1 | sed 's/^/    /'
  rc=${PIPESTATUS[0]}
  set -e
  echo "  review_pr.py exit=$rc"
else
  curl -sS -X POST -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"pr_url\":\"$pr_url\"}" "$DASHBOARD_BASE_URL/api/ko-review" | sed 's/^/    /'
  echo "  (api 경로: 잡 완료를 기다린 뒤 5단계를 수동 재실행하세요)"
  sleep 240
fi

# ── 5) 판정 ─────────────────────────────────────────────────────────
echo
echo "[5/6] 마커 코멘트 판정"
comments_json="$(gh api "repos/$REPO/issues/$pr_number/comments" --paginate)"
reviews_json="$(gh api "repos/$REPO/pulls/$pr_number/reviews" --paginate)"

audit_count="$(python3 -c "
import json,sys
cs=json.loads(sys.stdin.read())
print(sum(1 for c in cs if '<!-- korean-review:anchor-audit -->' in (c.get('body') or '')))
" <<<"$comments_json")"
check "(1) 마커 코멘트가 정확히 1개 (있다: $audit_count)" \
      "$([[ "$audit_count" == "1" ]] && echo 0 || echo 1)"
[[ "$audit_count" == "1" ]] || { echo "  마커 코멘트가 없어 이후 판정 불가"; exit 1; }

body="$(python3 -c "
import json,sys
cs=json.loads(sys.stdin.read())
print(next(c['body'] for c in cs if '<!-- korean-review:anchor-audit -->' in (c.get('body') or '')))
" <<<"$comments_json")"
echo "─── 코멘트 본문 ───"; echo "$body"; echo "───────────────────"

has() { grep -Fq "$1" <<<"$body"; }

# 섹션 판정기 — 코멘트를 `### ` 소제목으로 쪼개, 헤더 조각이 맞는 섹션 **안에**
# 대상 문자열이 있는지 본다. "본문 어딘가에 있다" 로 판정하면 엉뚱한 섹션의
# 파일명이 통과한다 (파일 하나가 여러 code 에 걸리는 것이 정상이므로).
SECT_PY="$(mktemp)"; BODY_F="$(mktemp)"
trap 'rm -f "$SECT_PY" "$BODY_F"' EXIT
cat > "$SECT_PY" <<'SECTPY'
import sys
head, needle, path = sys.argv[1], sys.argv[2], sys.argv[3]
body = open(path, encoding="utf-8").read()
for b in body.split("\n### ")[1:]:
    if head in b.splitlines()[0]:
        sys.exit(0 if needle in b else 1)
sys.exit(1)
SECTPY
printf '%s' "$body" > "$BODY_F"
sect() { python3 "$SECT_PY" "$1" "$2" "$BODY_F"; }

rc=0; sect "번역 run 에서 제외" "anchor-audit-r1.md" || rc=$?; check "(2) anchor-only-skip ← ko/anchor-audit-r1.md" $rc
rc=0; sect "원복됩니다" "anchor-audit-r1.md" || rc=$?; check "(3) attr-anchor-mismatch ← r1 (앵커만 고쳐 attr 이 어긋남)" $rc
rc=0; sect "원복됩니다" "anchor-audit-r2.md" || rc=$?; check "(4) attr-anchor-mismatch ← r2 (attr 만 고침)" $rc
rc=0; sect "자동 슬러그" "anchor-audit-r3.md" || rc=$?; check "(5) attr-only-id ← r3" $rc
rc=0; sect "관리하지 않는" "anchor-audit-r3.md" || rc=$?; check "(6) unmanaged-anchor-form ← r3 (span id)" $rc
rc=0; sect "관리 범위 밖" "anchor-audit-r3.md" || rc=$?; check "(7) out-of-scope-level ← r3 (h1 앵커 · h4 attr)" $rc
rc=0; sect "id 가 중복" "anchor-audit-r4.md" || rc=$?; check "(8) duplicate-id ← r4" $rc
rc=0; sect "marker 가 없어" "anchor-audit-r4.md" || rc=$?; check "(9) no-align-marker ← r4" $rc
rc=0; sect "ko 기준으로" "anchor-audit-r5.md" || rc=$?; check "(10) target-lang-anchor-edit ← en/r5" $rc
rc=0; sect "배포된 id" "anchor-audit-good.md" || rc=$?; check "(11) id-value-change ← good (정합 변경도 링크 확인은 안내)" $rc

# 대조군: 본문만 고친 파일은 어느 섹션에도 등장하지 않는다.
rc=0; has "anchor-audit-ok.md" && rc=1; check "(12) 대조군 ko/anchor-audit-ok.md 는 지적 없음" $rc

# 권장 경로(good)는 '오류' 3종에 걸리지 않는다.
not_in_error_sections=0
for h in "번역 run 에서 제외" "원복됩니다" "자동 슬러그"; do
  if sect "$h" "anchor-audit-good.md"; then not_in_error_sections=1; fi
done
check "(13) 권장 경로(good)는 skip·원복·슬러그 어디에도 안 걸림" "$not_in_error_sections"

# 순서: 한글 검수 리뷰가 후속 검증 코멘트보다 **먼저** 게시됐는가.
if (( SKIP_LLM_REVIEW )); then
  echo "  SKIP  (14) 게시 순서 — --keep-review-off 라 검수 리뷰가 없음"
else
  rv_f="$(mktemp)"; cm_f="$(mktemp)"
  printf '%s' "$reviews_json" > "$rv_f"; printf '%s' "$comments_json" > "$cm_f"
  rc=0
  python3 - "$rv_f" "$cm_f" <<'ORDERPY' || rc=$?
import json, sys
reviews = json.load(open(sys.argv[1], encoding="utf-8"))
comments = json.load(open(sys.argv[2], encoding="utf-8"))
subs = [r["submitted_at"] for r in reviews if r.get("submitted_at")]
audit = [c["created_at"] for c in comments
         if "<!-- korean-review:anchor-audit -->" in (c.get("body") or "")]
# 같은 초에 걸리면 통과(<=) — 작은 PR 은 검수 게시와 후속 검증이 1초 안에 끝나고,
# 그때 초 해상도로 순서를 강제하면 참인 실행이 FAIL 이 된다.
sys.exit(0 if subs and audit and min(subs) <= min(audit) else 1)
ORDERPY
  rm -f "$rv_f" "$cm_f"
  check "(14) 한글 검수 리뷰가 후속 검증 코멘트보다 먼저 게시됨" $rc
fi

# ── 5b) 인라인 코멘트 판정 ──────────────────────────────────────────
echo
echo "[5b/6] 인라인 코멘트 판정"
inline_json="$(gh api "repos/$REPO/pulls/$pr_number/comments" --paginate)"
IN_F="$(mktemp)"; printf '%s' "$inline_json" > "$IN_F"
INLINE_PY="$(mktemp)"
cat > "$INLINE_PY" <<'INLINEPY'
import json, sys
mode, path = sys.argv[1], sys.argv[2]
cs = [c for c in json.load(open(path, encoding="utf-8"))
      if "korean-review:anchor-audit:" in (c.get("body") or "")]
if mode == "count":
    print(len(cs)); sys.exit(0)
if mode == "has":            # has <file> <code>
    f, code = sys.argv[3], sys.argv[4]
    sys.exit(0 if any(c["path"].endswith(f) and f":{code}:" in c["body"]
                      for c in cs) else 1)
if mode == "line":           # line <file> <code> <expected diff line>
    f, code, want = sys.argv[3], sys.argv[4], int(sys.argv[5])
    sys.exit(0 if any(c["path"].endswith(f) and f":{code}:" in c["body"]
                      and c.get("line") == want for c in cs) else 1)
if mode == "nosuggestion":
    sys.exit(1 if any("```suggestion" in c["body"] for c in cs) else 0)
sys.exit(2)
INLINEPY
# mode 다음이 데이터 파일, 그 뒤가 mode 별 인자.
inl() { local m="$1"; shift; python3 "$INLINE_PY" "$m" "$IN_F" "$@"; }

n_inline="$(inl count)"
echo "  anchor-audit 인라인 코멘트: ${n_inline}건"
rc=0; [[ "${n_inline:-0}" -ge 10 ]] || rc=1
check "(15) 지적이 인라인 코멘트로도 달림 (${n_inline}건)" $rc

rc=0; inl has "anchor-audit-r3.md" "unmanaged-anchor-form" || rc=$?
check "(16) 인라인 ← ko/…-r3.md unmanaged-anchor-form" $rc
rc=0; inl has "anchor-audit-r5.md" "target-lang-anchor-edit" || rc=$?
check "(17) 인라인 ← en/…-r5.md (번역본에도 달린다)" $rc

# 핵심: diff 밖 지적의 재배치. r1 의 mismatch 는 heading(L5) 이야기지만 이 PR 이
# 바꾼 줄은 앵커(L4) 뿐이라, L5 에 그대로 달면 GitHub 이 422 로 거절한다.
rc=0; inl line "anchor-audit-r1.md" "attr-anchor-mismatch" 4 || rc=$?
check "(18) diff 밖 지적(r1 L5)이 가장 가까운 변경 줄 L4 로 옮겨 달림" $rc

rc=0; inl nosuggestion || rc=$?
check "(19) 인라인에 클릭형 suggestion 블록이 없다" $rc

rm -f "$IN_F" "$INLINE_PY"

# ── 6) upsert — 다시 돌려도 코멘트가 쌓이지 않는다 ──────────────────
echo
echo "[6/6] 후속 검증 재실행 (upsert 확인)"
( cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" - "$pr_url" <<'PY'
import asyncio, sys
sys.path[:0] = ["korean-review", "."]
from shared.github_client import GitHubClient
from app import anchor_audit
url = sys.argv[1]
repo = url.split("/pull/")[0].split("github.com/")[1]
num = int(url.rsplit("/", 1)[1])

async def main():
    c = GitHubClient()
    info = await c.get_pr_info(repo, num)
    await anchor_audit.run_stage(c, repo, num, info["head"]["sha"], dry_run=False)
asyncio.run(main())
PY
) 2>&1 | sed 's/^/    /'
again="$(gh api "repos/$REPO/issues/$pr_number/comments" --paginate | python3 -c "
import json,sys
print(sum(1 for c in json.load(sys.stdin) if '<!-- korean-review:anchor-audit -->' in (c.get('body') or '')))
")"
check "(20) 재실행 후에도 요약 코멘트는 1개 (있다: $again)" \
      "$([[ "$again" == "1" ]] && echo 0 || echo 1)"

# 인라인에는 upsert 가 없다 — 마커 dedup 이 안 먹으면 재실행마다 사본이 쌓인다.
again_inline="$(gh api "repos/$REPO/pulls/$pr_number/comments" --paginate | python3 -c "
import json,sys
print(sum(1 for c in json.load(sys.stdin) if 'korean-review:anchor-audit:' in (c.get('body') or '')))
")"
check "(21) 재실행 후에도 인라인은 ${n_inline}건 그대로 (있다: $again_inline)" \
      "$([[ "$again_inline" == "$n_inline" ]] && echo 0 || echo 1)"

echo
echo "===================================================================="
echo "  PR:   $pr_url"
echo "  결과: $pass PASS / $fail FAIL"
echo "===================================================================="
if (( fail )); then echo "ANCHOR_AUDIT: FAIL"; exit 1; fi
echo "ANCHOR_AUDIT: OK"
