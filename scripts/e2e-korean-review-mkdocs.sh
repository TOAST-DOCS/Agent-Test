#!/usr/bin/env bash
#
# 한글 검수 **후속 조치 — mkdocs 문법 점검** e2e (Agent-Test):
#   0) webhook 비활성화 (다른 잡 중복 트리거 방지)
#   1) alpha 로부터 세션 브랜치 e2e-komkdocs/<ts> 생성
#   2) head 브랜치에 픽스처 5종 **신규 생성** (alpha 에는 두지 않는다 — 아래 참고)
#   3) ko PR 생성 → 검수 실행 (기본 local review_pr.py)
#   4) 후속 조치 리뷰를 **결정적으로** 판정: 검출 4건이 정확히 어느 파일 어느
#      줄에 어느 check 로 떠야 하는지, 그리고 대조군이 **침묵**하는지
#   5) 기존 한글 검수 리뷰가 **그대로** 남아 있고 후속 조치와 섞이지 않았는지
#
# 왜 이 e2e 가 따로 있나 — `e2e-korean-review.sh` 는 *검수 자체*(9차원 요약 규격·
# 인라인·suggestion)를 보고, 의미 품질은 fable 에게 물어본다. 후속 조치는 성격이
# 정반대다: **LLM 을 한 번도 부르지 않는 결정적 판정**이라 기대값을 정확히 쓸 수
# 있고, 그래서 써야 한다. "대체로 잡는다" 로는 이 점검의 존재 이유(같은 커밋이면
# 언제 돌려도 같은 답)를 검증하지 못한다.
#
# 무엇을 재현하나 — 2026-09-07 `Storage-Object-Storage` 의 `ja/acl-guide.md` 가
# 조건부 태그 한 줄을 잃어 alpha 빌드를 통째로 멈춘 사고. 배포의 macros 플러그인은
# `on_error_fail: true` 라 태그 하나가 짝을 잃으면 그 문서 한 장이 아니라 **그 언어
# 가이드 전체 빌드가 실패**한다.
#
# **픽스처를 alpha 에 두지 않는 이유 (중요)** — 이 e2e 의 픽스처는 일부러 깨진
# 템플릿이다. Agent-Test 는 alpha 가이드 nav 에 실려 빌드되므로(`Open Source/
# agent-test`), 깨진 `{% if %}` 를 alpha 에 커밋하면 **그 사고를 우리가 재현하는
# 게 아니라 우리가 일으킨다**. 그래서 픽스처는 이 스크립트가 세션 head 브랜치에서
# 만들고, 토픽 브랜치는 빌드되지 않으므로 안전하다. (`fill-stub-sample.md` 처럼
# alpha 상주 픽스처를 쓰지 않는 유일한 이유가 이것이다.)
#
# 세션 브랜치와 PR 은 debug 를 위해 남긴다 (정리 지침은 CLAUDE.md).
# alpha 는 절대 오염되지 않는다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-korean-review-mkdocs.sh                       # local 검수(기본)
#   bash scripts/e2e-korean-review-mkdocs.sh --translate api       # 배포된 Jenkins 잡으로
#   bash scripts/e2e-korean-review-mkdocs.sh --base-branch e2e-komkdocs/<ts>
#   CLOUD_TRANSLATE_DIR=<워크트리> bash scripts/e2e-korean-review-mkdocs.sh
#
# 의존성: git, gh (로그인), curl, python3

set -euo pipefail

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH=""
BASE_SOURCE_BRANCH="alpha"
JOB_TIMEOUT=1800
# 기본이 local 인 이유: 이 e2e 가 검증하는 동작은 아직 배포 전 브랜치에 있을 수
# 있다. api 는 머지·배포 후 회귀 확인용 (no-targets e2e 와 같은 규약).
REVIEW_VIA="local"
# 후속 조치는 LLM 을 안 쓰므로 멀티패스와 무관하다. 이 e2e 의 주제가 아닌 LLM
# 검수에 시간·한도를 두 배로 쓸 이유가 없어 1패스로 돈다(검수 리뷰의 *규격* 은
# 패스 수와 무관하게 같다 — 5단계가 보는 것이 그 규격이다).
REVIEW_PASSES=1
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-branch)   BASE_BRANCH="$2"; shift 2 ;;
    --base-source)   BASE_SOURCE_BRANCH="$2"; shift 2 ;;
    --timeout)       JOB_TIMEOUT="$2"; shift 2 ;;
    --passes)        REVIEW_PASSES="$2"; shift 2 ;;
    --translate)
      case "${2:-}" in
        api|local) REVIEW_VIA="$2" ;;
        *) echo "error: --translate 는 api|local 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -h|--help)       sed -n '3,42p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ "$REVIEW_VIA" == "local" && ! -f "$CLOUD_TRANSLATE_DIR/.env" ]]; then
  echo "error: $CLOUD_TRANSLATE_DIR/.env 가 없습니다 (TRANSLATE_GITHUB_TOKEN 필요)" >&2
  exit 1
fi
if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다. load_env.sh 를 source 하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
TS="$(date -u +%Y%m%d-%H%M%S)"

echo "[0/6] webhook 비활성화"
set_webhook_repo_enabled false

# ── 1) 세션 브랜치 ──────────────────────────────────────────────────
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-komkdocs/$TS"
  echo "[1/6] 세션 브랜치 생성: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  git push -u origin "$BASE_BRANCH"
else
  echo "[1/6] 기존 세션 브랜치 재사용: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
fi
echo "  E2E_BASE_BRANCH=$BASE_BRANCH"

# ── 2) 픽스처 5종 ───────────────────────────────────────────────────
#
# 기대 검출은 아래 파일들의 줄번호에 **그대로 박혀 있다** (판정 python 의
# EXPECTED). 파일을 편집하면 그 표도 같이 고쳐야 한다 — 픽스처와 기대값이
# 어긋나면 이 e2e 는 실패로 알려 준다(조용히 통과하지 않는다).
head_branch="translate-test-komkdocs/$TS"
echo
echo "[2/6] 픽스처 생성 → $head_branch"
git checkout -B "$head_branch" "$BASE_BRANCH"

# (a) include 대상 — 변수를 정의만 한다. 지적 0건이어야 한다.
cat > ko/mkdocs-followup-vars.md <<'EOF'
{%- set portal_url = "https://console.nhncloud.com" -%}
{%- set api_base = portal_url + "/v2" -%}
EOF

# (b) syntax — 닫는 {% endif %} 가 없다. L6 에 1건. (Object Storage 사고의 모양)
cat > ko/mkdocs-followup-syntax.md <<'EOF'
<a id="mkdocs-followup-syntax"></a>
## Sample > 짝을 잃은 조건부 { #mkdocs-followup-syntax }

이 문서는 조건부 태그의 닫는 짝이 사라진 경우를 재현합니다.

{% if "gov" not in build_flags %}
공용 환경에서는 콘솔에서 곧바로 설정할 수 있습니다.

닫는 태그가 없어 이 문서 한 장이 아니라 가이드 전체 빌드가 멈춥니다.
EOF

# (c) include — 대상이 이 브랜치에 없다. L4 에 1건.
cat > ko/mkdocs-followup-include.md <<'EOF'
<a id="mkdocs-followup-include"></a>
## Sample > 없는 include 대상 { #mkdocs-followup-include }

{% include-markdown './mkdocs-followup-nowhere.md' %}

위 include 대상은 이 브랜치에 존재하지 않습니다.
EOF

# (d) undefined-var(L8) + delimiter(L10). 나머지 중괄호는 전부 **침묵**해야 한다 —
#     코드 펜스 안(L15)·셸 표기 ${{ }}(L18)·{% raw %} 시연(L21).
cat > ko/mkdocs-followup-vars-use.md <<'EOF'
<a id="mkdocs-followup-vars-use"></a>
## Sample > 변수 사용 { #mkdocs-followup-vars-use }

{% include-markdown './mkdocs-followup-vars.md' %}

콘솔 주소는 `$[ portal_url ]$` 입니다.

리전 코드는 `$[ region_code ]$` 입니다.

잘못된 구분자로 쓴 {{ portal_url }} 은 치환되지 않습니다.

아래 코드 예시의 중괄호는 남의 문법이라 정상입니다.

```bash
curl {{ portal_url }}/v2/tokens
```

워크플로 표기 ${{ portal_url }} 도 이 문법과 무관합니다.

{% raw %}
변수는 `$[ portal_url ]$` 로 씁니다.
{% endraw %}
EOF

# (e) 대조군 — 전부 올바른 매크로. 어느 check 에도 걸리면 안 된다.
cat > ko/mkdocs-followup-control.md <<'EOF'
<a id="mkdocs-followup-control"></a>
## Sample > 정상 매크로 { #mkdocs-followup-control }

{% include-markdown './mkdocs-followup-vars.md' %}

{% if "gov" in build_flags %}
정부망 환경에서는 담당자에게 발급 절차를 문의합니다.
{% else %}
공용 환경에서는 콘솔 `$[ portal_url ]$` 에서 설정합니다.
{% endif %}

| 구분 | 주소 |
| --- | --- |
| 콘솔 | `$[ portal_url ]$` |
| API | `$[ api_base ]$` |
EOF

git add ko/mkdocs-followup-*.md
git commit -q -m "e2e(ko-review 후속 조치): mkdocs 문법 픽스처 5종

syntax(짝 없는 {% if %}) · include(없는 대상) · undefined-var · delimiter
각 1건 + 대조군. 깨진 템플릿이라 alpha 에는 두지 않는다(빌드가 멈춘다)."
git push -q -u origin "$head_branch"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$head_branch" \
  --title "e2e(후속 조치): mkdocs 문법 픽스처" \
  --body "한글 검수 **후속 조치**(mkdocs 문법 점검) e2e 픽스처입니다.

기대: 후속 조치 리뷰에 **4건**(빌드 실패 2 · 확인 필요 2), 대조군
\`ko/mkdocs-followup-control.md\` 와 include 대상 \`ko/mkdocs-followup-vars.md\` 는 **침묵**." \
  --label "$E2E_LABEL")"
ko_pr_number="${ko_pr_url##*/}"
echo "  ko PR: $ko_pr_url"

# ── 3) 검수 실행 ────────────────────────────────────────────────────
echo
echo "[3/6] 한글 검수 실행 (경로=$REVIEW_VIA, passes=$REVIEW_PASSES)"
if [[ "$REVIEW_VIA" == "local" ]]; then
  echo "  local review_pr.py (dir=$CLOUD_TRANSLATE_DIR)"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && TRANSLATE_REVIEW_PASSES="$REVIEW_PASSES" \
     "$CLOUD_TRANSLATE_PY" korean-review/review_pr.py "$ko_pr_url") 2>&1 \
     | tee "$tmpdir/review.out" | sed 's/^/    /'
  review_rc=${PIPESTATUS[0]}
  set -e
  (( review_rc == 0 )) || { echo "  review_pr.py 실패 (exit $review_rc)" >&2; exit 2; }
  # 결과 줄 — 후속 조치가 아예 안 돌았으면 여기서 바로 드러난다.
  grep -E '^(Review posted|Followup):' "$tmpdir/review.out" | sed 's/^/  /' || true
  if ! grep -q '^Followup:' "$tmpdir/review.out"; then
    echo "  FAIL: 'Followup:' 결과 줄이 없다 — 후속 조치가 실행되지 않았다" >&2
    echo "        (TRANSLATE_REVIEW_FOLLOWUPS 가 꺼져 있거나 배선이 빠졌다)" >&2
    exit 3
  fi
else
  resp="$(curl -sS -X POST -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" -d "{\"pr_url\": \"$ko_pr_url\"}" \
    "$DASHBOARD_BASE_URL/api/ko-review")"
  job_id="$(printf '%s' "$resp" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("job_id") or "")')"
  [[ -n "$job_id" ]] || { echo "  error: job_id 없음: $resp" >&2; exit 2; }
  echo "  ko-review job: $job_id (timeout=${JOB_TIMEOUT}s)"
  deadline=$(( $(date +%s) + JOB_TIMEOUT ))
  status=""
  while (( $(date +%s) < deadline )); do
    status="$(curl -sS --retry 3 --retry-delay 5 \
      -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
      "$DASHBOARD_BASE_URL/api/jobs/$job_id" 2>/dev/null \
      | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin); t=(d.get("job") or {}).get("tasks") or []
  print(t[0].get("status") if t else "")
except Exception:
  print("")' || true)"
    case "$status" in success|failure|cancelled|partial) break ;; esac
    sleep 10
  done
  [[ "$status" == "success" ]] || { echo "  ko-review 실패 (status=$status)" >&2; exit 2; }
fi

# ── 4) 스냅샷 ───────────────────────────────────────────────────────
echo
echo "[4/6] 리뷰·인라인 코멘트 조회"
gh api "repos/$REPO/pulls/$ko_pr_number/reviews"  --paginate > "$tmpdir/reviews.json"
gh api "repos/$REPO/pulls/$ko_pr_number/comments" --paginate > "$tmpdir/inline.json"
echo "  reviews=$(python3 -c 'import json,sys;print(len(json.load(open(sys.argv[1]))))' "$tmpdir/reviews.json")" \
     "inline=$(python3 -c 'import json,sys;print(len(json.load(open(sys.argv[1]))))' "$tmpdir/inline.json")"

# ── 5~6) 판정 ───────────────────────────────────────────────────────
echo
echo "[5/6] 후속 조치 리뷰 판정 · [6/6] 기존 검수 리뷰 무간섭 판정"
echo "==================================================================="
set +e
TMPDIR_PATH="$tmpdir" python3 - <<'PYEOF'
import json, os, re, sys

d = os.environ["TMPDIR_PATH"]
MARKER = "<!-- korean-review:followup -->"

reviews = json.load(open(os.path.join(d, "reviews.json")))
inline = json.load(open(os.path.join(d, "inline.json")))

problems = []


def check(ok, label, detail=""):
    print(f"  {'PASS' if ok else 'FAIL'}  {label}" + (f" — {detail}" if detail else ""))
    if not ok:
        problems.append(label)


# 기대 검출 — 픽스처의 줄번호에 박혀 있다 (스크립트 [2/6] 의 heredoc 참고).
# (파일, 점검 라벨, 줄번호). 이 넷이 전부여야 하고, 하나라도 더/덜 나오면 실패.
EXPECTED = {
    ("ko/mkdocs-followup-syntax.md", "Jinja 문법", 6),
    ("ko/mkdocs-followup-include.md", "include 대상", 4),
    ("ko/mkdocs-followup-vars-use.md", "미정의 변수", 8),
    ("ko/mkdocs-followup-vars-use.md", "변수 구분자", 10),
}
# 침묵해야 하는 문서 — 대조군과 include 대상.
SILENT = {"ko/mkdocs-followup-control.md", "ko/mkdocs-followup-vars.md"}

followup = [r for r in reviews if MARKER in (r.get("body") or "")]
print("후속 조치 리뷰")
check(len(followup) == 1, "후속 조치 리뷰가 정확히 1건", f"{len(followup)}건")
body = (followup[0].get("body") or "") if followup else ""

check("## 🧩 한글 검수 후속 조치 — 4건" in body, "헤더의 총 건수가 4건",
      (re.search(r"후속 조치 — \S+", body) or [""])[0] if body else "(본문 없음)")
check("**2건은 그대로 머지되면 가이드 빌드가 실패**" in body,
      "빌드를 멈추는 2건을 따로 셈")

# 검출 항목 — `- `ko/x.md` L6 `[Jinja 문법]` … (빌드 실패|확인 필요)`
item_re = re.compile(
    r"^- `(?P<file>[^`]+)` L(?P<line>\d+) `\[(?P<label>[^\]]+)\]`.*?"
    r"\((?P<tag>빌드 실패|확인 필요)\)\s*$", re.M)
items = {(m.group("file"), m.group("label"), int(m.group("line")))
         for m in item_re.finditer(body)}
tags = {(m.group("file"), m.group("label")): m.group("tag")
        for m in item_re.finditer(body)}

for want in sorted(EXPECTED):
    check(want in items, f"검출: {want[0]} L{want[2]} [{want[1]}]")
extra = items - EXPECTED
check(not extra, "기대 밖 검출 없음", ", ".join(map(str, sorted(extra))) or "없음")

check(tags.get(("ko/mkdocs-followup-syntax.md", "Jinja 문법")) == "빌드 실패",
      "Jinja 문법은 '빌드 실패' 로 라벨링")
check(tags.get(("ko/mkdocs-followup-include.md", "include 대상")) == "빌드 실패",
      "include 대상은 '빌드 실패' 로 라벨링")
check(tags.get(("ko/mkdocs-followup-vars-use.md", "미정의 변수")) == "확인 필요",
      "미정의 변수는 '확인 필요' 로 라벨링")
check(tags.get(("ko/mkdocs-followup-vars-use.md", "변수 구분자")) == "확인 필요",
      "변수 구분자는 '확인 필요' 로 라벨링")

for doc in sorted(SILENT):
    check(doc not in body, f"침묵: {doc} 가 후속 조치 리뷰에 없음")

# 점검 표 — 네 행이 모두 있어야 한다(통과한 점검도 행으로 남는 것이 계약).
for label in ("Jinja 문법", "include 대상", "미정의 변수", "변수 구분자"):
    check(bool(re.search(rf"^\|\s*{re.escape(label)}\s*\|", body, re.M)),
          f"점검 표에 '{label}' 행")

# 인라인 — 픽스처가 전부 신규 파일이라 모든 줄이 diff 의 추가 줄이다.
# 따라서 기대 4건 전부 그 줄에 앵커돼야 한다.
print()
print("인라인 앵커")
followup_ids = {r.get("id") for r in followup}
fu_inline = [c for c in inline if c.get("pull_request_review_id") in followup_ids]
anchored = {(c.get("path"), c.get("line") or c.get("original_line")) for c in fu_inline}
for f, label, line in sorted(EXPECTED):
    check((f, line) in anchored, f"인라인 앵커: {f} L{line} [{label}]")
check(all(p not in SILENT for p, _ in anchored), "침묵 문서에 인라인 없음",
      ", ".join(sorted({p for p, _ in anchored})))

# 기존 검수 리뷰는 그대로 — 후속 조치와 섞이지 않았는지.
print()
print("기존 검수 무간섭")
ko_reviews = [r for r in reviews
              if re.search(r"##\s*🔍\s*한글 검수 결과", r.get("body") or "")]
check(len(ko_reviews) >= 1, "기존 한글 검수 요약 리뷰가 여전히 게시됨",
      f"{len(ko_reviews)}건")
check(all(MARKER not in (r.get("body") or "") for r in ko_reviews),
      "검수 요약에 후속 조치 마커가 섞이지 않음")
check(all("| Jinja 문법 |" not in (r.get("body") or "") for r in ko_reviews),
      "검수 9차원 표에 mkdocs 점검 행이 끼지 않음")
check("🔍 한글 검수 결과" not in body, "후속 조치 리뷰가 검수 요약을 되풀이하지 않음")

print()
if problems:
    print(f"KO_REVIEW_MKDOCS: FAIL ({len(problems)}건)")
    sys.exit(3)
print("KO_REVIEW_MKDOCS: OK")
PYEOF
verdict_rc=$?
set -e

echo "==================================================================="
echo "  ko PR        : $ko_pr_url"
echo "  세션 브랜치  : $BASE_BRANCH"
echo "  head 브랜치  : $head_branch"
echo "  검수 경로    : $REVIEW_VIA (passes=$REVIEW_PASSES)"
echo "==================================================================="
exit $verdict_rc
