#!/usr/bin/env bash
#
# 한글 검수 **후속 조치 — 링크 점검** e2e (Agent-Test):
#   0) webhook 비활성화 (다른 잡 중복 트리거 방지)
#   1) alpha 로부터 세션 브랜치 e2e-kolinks/<ts> 생성 + **base 에 기존 결함 문서 커밋**
#   2) head 브랜치에 픽스처 3종 신규 생성 + 기존 결함 문서의 *다른* 줄만 수정
#   3) ko PR 생성 → 검수 실행 (기본 local review_pr.py)
#   4) 후속 조치 리뷰를 **결정적으로** 판정: 검출 8건이 정확히 어느 파일 어느 줄에
#      어느 거리(in-file/in-repo/cross-repo)로 떠야 하는지, 대조군이 **침묵**하는지,
#      그리고 **PR 이 안 건드린 줄의 기존 결함이 침묵**하는지(diff 스코프)
#   5) 기존 한글 검수 리뷰가 **그대로** 남아 있고 후속 조치와 섞이지 않았는지
#
# 왜 이 e2e 가 따로 있나 — 링크 점검은 `/link-check` 와 **같은 판정기**를 부르고 LLM 을
# 한 번도 쓰지 않는 결정적 판정이라 기대값을 정확히 쓸 수 있고, 그래서 써야 한다
# (markup lint · mkdocs 문법 e2e 와 같은 이유).
#
# **경계가 이 안건의 핵심이라 대조군이 크다.** 살아 있는데 표기만 다른 링크
# (`self-path`) · 다른 리포 문서 안의 anchor · 이미지 · 코드 펜스 안 링크는 전부
# 침묵해야 한다 — 그것들을 지적하면 개발팀 PR 이 🧹 문서 정비의 재고로 뒤덮인다.
# 그리고 `ko/link-followup-existing.md` 는 **base 브랜치에** 결함(L4)을 든 채 커밋되고
# head 는 그 파일의 *다른* 줄(L6)만 고친다 — 기대는 그 파일에 대한 **침묵**.
#
# 픽스처는 세션 head 브랜치에서 만든다(alpha 는 절대 오염되지 않는다).
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-korean-review-links.sh                       # local 검수(기본)
#   bash scripts/e2e-korean-review-links.sh --translate api       # 배포된 Jenkins 잡으로
#   CLOUD_TRANSLATE_DIR=<워크트리> bash scripts/e2e-korean-review-links.sh
#
# 의존성: git, gh (로그인), curl, python3

set -euo pipefail

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH=""
BASE_SOURCE_BRANCH="alpha"
JOB_TIMEOUT=1800
REVIEW_VIA="local"
# 후속 조치는 LLM 을 안 쓰므로 멀티패스와 무관하다 — 1패스 (markup/mkdocs e2e 와 같은 규약).
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
    -h|--help)       sed -n '3,33p' "$0"; exit 0 ;;
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

# ── 1) 세션 브랜치 + base 의 기존 결함 문서 ─────────────────────────────
# 기존 결함 문서 — L4 의 깨진 앵커는 base 부터 있던 것. head 는 L6 만 고친다.
# 판정 python 의 SILENT 에 이 파일이 들어가는 이유가 이 배치다.
write_existing() {   # $1 = L6 문장
  cat > ko/link-followup-existing.md <<EOF
<a id="link-followup-existing"></a>
## Sample > 기존 결함이 있는 문서 { #link-followup-existing }

이 줄의 [없는 앵커](#link-no-such-old)는 base 부터 있었습니다.

$1
EOF
}

if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-kolinks/$TS"
  echo "[1/6] 세션 브랜치 생성: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH) + 기존 결함 문서"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  write_existing "이 줄은 base 시점의 문장입니다."
  git add ko/link-followup-existing.md
  git commit -q -m "e2e(ko-review 후속 조치): base 에 기존 링크 결함 문서

링크 점검의 diff 스코프 판정용 — head 가 이 파일의 다른 줄만 고치면
L4 의 깨진 앵커는 침묵해야 한다."
  git push -u origin "$BASE_BRANCH"
else
  echo "[1/6] 기존 세션 브랜치 재사용: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
  [[ -f ko/link-followup-existing.md ]] || {
    echo "error: 재사용한 base 에 ko/link-followup-existing.md 가 없습니다" >&2; exit 1; }
fi
echo "  E2E_BASE_BRANCH=$BASE_BRANCH"

# ── 2) 픽스처 ─────────────────────────────────────────────────────────
#
# 기대 검출은 아래 파일들의 줄번호에 **그대로 박혀 있다** (판정 python 의 EXPECTED).
# 파일을 편집하면 그 표도 같이 고쳐야 한다 — 어긋나면 이 e2e 는 실패로 알려 준다.
head_branch="translate-test-kolinks/$TS"
echo
echo "[2/6] 픽스처 생성 → $head_branch"
git checkout -B "$head_branch" "$BASE_BRANCH"

# (a) 도착하지 못하는 링크 — 두 거리 × 두 모양. L4 없는 앵커 · L6 빈 fragment ·
#     L8 없는 파일 · L10 대상 파일은 있으나 그 앵커가 없음.
cat > ko/link-followup-broken.md <<'EOF'
<a id="link-followup-broken"></a>
## Sample > 깨진 링크 { #link-followup-broken }

같은 문서 안의 [없는 앵커](#no-such-anchor)를 가리키는 링크입니다.

수신 거부 [링크](#)는 fragment 가 비어 있습니다.

같은 리포의 [없는 파일](./no-such-doc.md)을 가리킵니다.

같은 리포 문서의 [없는 앵커](./overview.md#no-such-anchor)를 가리킵니다.
EOF

# (b) 다른 리포 링크 — 표기 2종(L4 fully-qualified · L6 alpha host)과
#     로케일 2종(L8 레거시 jp · L10 짝 불일치). 전부 순수 구문 판정이다.
cat > ko/link-followup-cross.md <<'EOF'
<a id="link-followup-cross"></a>
## Sample > 다른 리포 링크 { #link-followup-cross }

자세한 내용은 [VPC 개요](https://docs.nhncloud.com/ko/Network/VPC/ko/overview/)를 참고합니다.

[alpha 호스트 링크](https://docs.alpha-nhncloud.com/ko/Network/VPC/ko/overview/)입니다.

[레거시 jp 링크](https://docs.nhncloud.com/jp/Network/VPC/jp/overview/)입니다.

[로케일 짝 불일치](https://docs.nhncloud.com/ko/Network/VPC/en/overview/)입니다.
EOF

# (c) 대조군 — 정상 링크 셋 + **일부러 참는 것** 넷. 어느 거리에도 걸리면 안 된다:
#     정상 in-file · 정상 in-repo · 다른 리포 site-root(문서 안 anchor 는 판정 대상이
#     아니라 일부러 없는 것을 가리킨다) · self-path(살아 있고 표기만 다름) ·
#     외부 URL · 없는 이미지(이미지는 이 안건의 거리가 아니다) · 코드 펜스 안 링크.
cat > ko/link-followup-control.md <<'EOF'
<a id="link-followup-control"></a>
## Sample > 정상 링크 { #link-followup-control }

같은 문서의 [정상 앵커](#link-followup-control)를 가리킵니다.

같은 리포의 [정상 링크](./overview.md#components)를 가리킵니다.

다른 리포의 [site-root 링크](/Network/VPC/ko/overview/#no-such-anchor)를 가리킵니다.

자기 문서를 [배포 URL 모양](./link-followup-control/#link-followup-control)으로 가리킵니다.

외부 [사이트](https://example.com/docs)를 가리킵니다.

없는 이미지 참조입니다: ![없는 이미지](./no-such-image.png)

```markdown
[코드 펜스 안의 깨진 링크](#no-such-anchor)
```
EOF

# (d) 기존 결함 문서 — L6 만 고친다. L4 의 결함은 이 PR 이 안 건드렸으니 침묵.
write_existing "이 줄은 이 PR 이 고친 문장입니다 — 링크가 없습니다."

git add ko/link-followup-*.md
git commit -q -m "e2e(ko-review 후속 조치): 링크 점검 픽스처

in-file 2 · in-repo 2 · cross-repo 4 + 대조군(정상·self-path·이미지·코드 펜스)
+ 기존 결함 문서의 다른 줄 수정."
git push -q -u origin "$head_branch"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$head_branch" \
  --title "e2e(후속 조치): 링크 점검 픽스처" \
  --body "한글 검수 **후속 조치**(링크 점검) e2e 픽스처입니다.

기대: 후속 조치 리뷰에 **8건**(전부 확인 필요), 대조군 \`ko/link-followup-control.md\` 와
다른 줄만 고친 \`ko/link-followup-existing.md\` 는 **침묵**." \
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
BROKEN = "ko/link-followup-broken.md"
CROSS = "ko/link-followup-cross.md"
EXPECTED = {
    (BROKEN, "문서 안 앵커", 4),      # 없는 앵커
    (BROKEN, "문서 안 앵커", 6),      # 빈 fragment
    (BROKEN, "같은 리포 링크", 8),     # 없는 파일
    (BROKEN, "같은 리포 링크", 10),    # 대상은 있고 앵커가 없음
    (CROSS, "다른 리포 링크", 4),      # abs-docs-cross
    (CROSS, "다른 리포 링크", 6),      # abs-docs-env
    (CROSS, "다른 리포 링크", 8),      # legacy-jp
    (CROSS, "다른 리포 링크", 10),     # locale pair
}
# 침묵해야 하는 문서 — 대조군, 그리고 **PR 이 안 건드린 줄에만 결함이 있는 문서**.
SILENT = {"ko/link-followup-control.md", "ko/link-followup-existing.md"}

followup = [r for r in reviews if MARKER in (r.get("body") or "")]
print("후속 조치 리뷰")
check(len(followup) == 1, "후속 조치 리뷰가 정확히 1건", f"{len(followup)}건")
body = (followup[0].get("body") or "") if followup else ""

check("## 🧩 한글 검수 후속 조치 — 8건" in body, "헤더의 총 건수가 8건",
      (re.search(r"후속 조치 — \S+", body) or [""])[0] if body else "(본문 없음)")
check("차단 항목은 없고, **8건**이 확인 대상입니다" in body,
      "차단 항목 없음 — 죽은 링크는 빌드를 멈추지 않는다")

item_re = re.compile(
    r"^- `(?P<file>[^`]+)` L(?P<line>\d+) `\[(?P<label>[^\]]+)\]`.*?"
    r"\((?P<tag>빌드 실패|확인 필요|확정)\)\s*$", re.M)
items = {(m.group("file"), m.group("label"), int(m.group("line")))
         for m in item_re.finditer(body)}
tag_of = {(m.group("file"), int(m.group("line"))): m.group("tag")
          for m in item_re.finditer(body)}
msg_of = {(m.group("file"), int(m.group("line"))): m.group(0)
          for m in item_re.finditer(body)}

for want in sorted(EXPECTED):
    check(want in items, f"검출: {want[0]} L{want[2]} [{want[1]}]")
extra = items - EXPECTED
check(not extra, "기대 밖 검출 없음", ", ".join(map(str, sorted(extra))) or "없음")

# 꼬리표 — 이 안건은 클릭형 치환을 내지 않으므로 전부 '확인 필요'.
check(set(tag_of.values()) == {"확인 필요"}, "꼬리표가 전부 '확인 필요'",
      ", ".join(sorted(set(tag_of.values()))) or "없음")

# 메시지 — 무엇이 왜 잘못됐는지 판정기의 말로 옮긴다.
print()
print("메시지")
check("fragment 이 비어 있습니다" in msg_of.get((BROKEN, 6), ""),
      "L6 은 '앵커 없음' 이 아니라 '빈 fragment' 로 설명")
check("ko/no-such-doc.md" in msg_of.get((BROKEN, 8), ""),
      "L8 메시지가 해석된 대상 경로를 인용")
check("ko/overview.md" in msg_of.get((BROKEN, 10), "")
      and "#no-such-anchor" in msg_of.get((BROKEN, 10), ""),
      "L10 메시지가 대상 파일과 없는 anchor 를 함께 인용")
check("site-root" in msg_of.get((CROSS, 4), ""),
      "L4 는 fully-qualified 대신 site-root 표기를 안내")
check("alpha/beta" in msg_of.get((CROSS, 6), ""), "L6 은 비운영 host 를 짚음")
check("`ja`" in msg_of.get((CROSS, 8), ""), "L8 은 레거시 jp → ja 를 짚음")
check("soft-404" in msg_of.get((CROSS, 10), ""),
      "L10 은 로케일 짝 불일치가 soft-404 임을 짚음")

print()
print("침묵 (경계)")
for doc in sorted(SILENT):
    check(doc not in body, f"침묵: {doc} 가 후속 조치 리뷰에 없음")

for label in ("문서 안 앵커", "같은 리포 링크", "다른 리포 링크"):
    check(bool(re.search(rf"^\|\s*{re.escape(label)}\s*\|", body, re.M)),
          f"점검 표에 '{label}' 행")

print()
print("인라인 앵커")
followup_ids = {r.get("id") for r in followup}
fu_inline = [c for c in inline if c.get("pull_request_review_id") in followup_ids]
anchored = {(c.get("path"), c.get("line") or c.get("original_line")) for c in fu_inline}
for f, label, line in sorted(EXPECTED):
    check((f, line) in anchored, f"인라인 앵커: {f} L{line} [{label}]")
check(all(p not in SILENT for p, _ in anchored), "침묵 문서에 인라인 없음",
      ", ".join(sorted({p for p, _ in anchored})))
check(all("```suggestion" not in (c.get("body") or "") for c in fu_inline),
      "클릭형 suggestion 없음 — anchor 수정은 그 줄 하나로 끝나지 않는다")

print()
print("기존 검수 무간섭")
ko_reviews = [r for r in reviews
              if re.search(r"##\s*🔍\s*한글 검수 결과", r.get("body") or "")]
check(len(ko_reviews) >= 1, "기존 한글 검수 요약 리뷰가 여전히 게시됨",
      f"{len(ko_reviews)}건")
check(all(MARKER not in (r.get("body") or "") for r in ko_reviews),
      "검수 요약에 후속 조치 마커가 섞이지 않음")
check(all("| 다른 리포 링크 |" not in (r.get("body") or "") for r in ko_reviews),
      "검수 9차원 표에 링크 점검 행이 끼지 않음")
check("🔍 한글 검수 결과" not in body, "후속 조치 리뷰가 검수 요약을 되풀이하지 않음")

print()
if problems:
    print(f"KO_REVIEW_LINKS: FAIL ({len(problems)}건)")
    sys.exit(3)
print("KO_REVIEW_LINKS: OK")
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
