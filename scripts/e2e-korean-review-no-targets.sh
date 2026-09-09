#!/usr/bin/env bash
#
# korean-review "검수 대상 0건" e2e (Agent-Test):
#   0) webhook 비활성화 (다른 잡 중복 트리거 방지)
#   1) alpha 로부터 세션 브랜치 e2e-koreview-notargets/<ts> 생성
#   2) restore-alpha-origin (ko/en/ja 를 alpha-origin 스냅샷으로 되돌림)
#   3) create-translate-test-pr.sh --plan delete-only 로 **삭제만** 있는 ko PR 생성
#      → diff 에 `+` 줄이 0인지 먼저 검증 (plan 의 유일한 계약)
#   4) 대조군 PR 생성 — en/ 만 건드려 ko/*.md 를 **전혀** 안 건드린 PR
#   5) 케이스 A: ko PR 검수 → 리뷰는 없고 '검수 대상 없음' 코멘트 + 라벨 2개
#   6) 케이스 B: ko PR head 에 빈 커밋(= 새 SHA, diff 동일) 후 재검수 →
#      코멘트가 **쌓이지 않고 갱신**되는지 (개수 1 유지 + 본문 SHA 갱신)
#   7) 케이스 C: 대조군 PR 검수 → 코멘트도 라벨도 없어야 함
#
# 왜 이 e2e 가 따로 있나 — `e2e-korean-review.sh` 는 *리뷰가 게시되는* 정상
# 경로를 검증한다(요약 규격·인라인·suggestion). 삭제만 있는 PR 은 검수 대상이
# 0건이라 그 경로에 아예 도달하지 않으므로 검증 항목이 정반대다: "리뷰가 없는
# 것이 정상이고, 그래도 흔적(코멘트)과 라벨은 남아야 한다".
#
# 실측 근거 — TOAST-DOCS/Gamebase#419 (Unity UI 가이드 섹션 제거, ko +0 −14):
# ko-review 가 09-03 `opened` / 09-07 `review_requested` 두 번 **성공**했는데
# PR 에는 코멘트도 라벨도 없었다. 그래서 (a) 검수가 돌았는지 PR 로 알 수 없고
# (b) 번역 webhook 의 `label_require`(`content-agent` + `한글 검수`, AND)를 못
# 넘어 머지해도 번역이 실행되지 않았다.
#
# 케이스 B 가 빈 커밋을 쓰는 이유 — 같은 SHA 를 다시 검수하면 커밋 상태 dedup
# (조건 5)이 막는다. 새 SHA 면 그 게이트를 정상적으로 통과하면서 diff(=삭제만)
# 는 그대로라, "재트리거 때 코멘트가 쌓이지 않는가" 만 남는다. Jenkins 에서는
# App 에 `statuses:write` 가 없어 dedup 자체가 403 으로 죽으므로(실측) 같은 SHA
# 재검수도 실제로 일어난다 — 그 상황에서 코멘트 중복을 막는 것이 마커의 목적.
#
# 세션 브랜치와 PR 은 debug 를 위해 남긴다 (--keep 없이도; 정리는 CLAUDE.md).
# alpha 는 절대 오염되지 않는다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-korean-review-no-targets.sh                        # local 검수(기본)
#   bash scripts/e2e-korean-review-no-targets.sh --translate api        # 배포된 Jenkins 잡으로
#   bash scripts/e2e-korean-review-no-targets.sh --base-branch e2e-koreview-notargets/<ts>
#   CLOUD_TRANSLATE_DIR=<워크트리> bash scripts/e2e-korean-review-no-targets.sh
#
# 의존성: git, gh (로그인), curl, python3

set -euo pipefail

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH=""
BASE_SOURCE_BRANCH="alpha"
PLAN_NAME="delete-only"
JOB_TIMEOUT=1800
# 기본이 local 인 이유: 이 e2e 가 검증하는 동작은 아직 배포 전 브랜치에 있을 수
# 있다. api 는 머지·배포 후 회귀 확인용.
REVIEW_VIA="local"
CONTROL_DOC="en/troubleshooting-guide.md"
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-branch)   BASE_BRANCH="$2"; shift 2 ;;
    --base-source)   BASE_SOURCE_BRANCH="$2"; shift 2 ;;
    --timeout)       JOB_TIMEOUT="$2"; shift 2 ;;
    --control-doc)   CONTROL_DOC="$2"; shift 2 ;;
    --translate)
      case "${2:-}" in
        api|local) REVIEW_VIA="$2" ;;
        *) echo "error: --translate 는 api|local 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -h|--help)       sed -n '3,45p' "$0"; exit 0 ;;
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

echo "[0/7] webhook 비활성화"
set_webhook_repo_enabled false

# ── 1) 세션 브랜치 ──────────────────────────────────────────────────
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-koreview-notargets/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/7] 세션 브랜치 생성: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  git push -u origin "$BASE_BRANCH"
else
  echo "[1/7] 기존 세션 브랜치 재사용: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
fi
echo "  E2E_BASE_BRANCH=$BASE_BRANCH"

# ── 2) restore-alpha-origin ─────────────────────────────────────────
echo
echo "[2/7] scripts/restore-alpha-origin.sh"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add ko en ja
  git commit -m "restore: alpha-origin (korean-review no-targets e2e session)"
  git push origin "$BASE_BRANCH"
fi

# ── 3) 삭제만 있는 ko PR ────────────────────────────────────────────
echo
echo "[3/7] create-translate-test-pr.sh --plan $PLAN_NAME --base-branch $BASE_BRANCH"
create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh" \
  --base-branch "$BASE_BRANCH" --plan "$PLAN_NAME")"
echo "$create_out"
ko_pr_url="$(grep -oE 'https://github.com/[^ ]+/pull/[0-9]+' <<<"$create_out" | tail -n1 || true)"
[[ -n "$ko_pr_url" ]] || { echo "  error: PR URL 파싱 실패" >&2; exit 2; }
ko_pr_number="${ko_pr_url##*/}"
ko_head_ref="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
echo "  ko PR: $ko_pr_url (head=$ko_head_ref)"

# 이 plan 의 계약 = ko diff 에 `+` 줄이 0. 여기서 먼저 깨뜨려 두면 뒤의 판정이
# "대상 0건" 이 아니라 다른 이유로 흔들리므로, 계약 위반은 이 지점에서 실패시킨다.
gh api "repos/$REPO/pulls/$ko_pr_number/files" --paginate > "$tmpdir/ko_files.json"
FILES_FILE="$tmpdir/ko_files.json" python3 - <<'PYEOF'
import json, os, sys
files = json.load(open(os.environ["FILES_FILE"]))
bad, ko = [], []
for f in files:
    name = f.get("filename", "")
    if not name.startswith("ko/"):
        continue
    ko.append(name)
    added = sum(1 for l in (f.get("patch") or "").splitlines()
                if l.startswith("+") and not l.startswith("+++"))
    print(f"  {name}: +{f.get('additions')} -{f.get('deletions')} (patch 의 '+' 줄 {added})")
    if added or f.get("additions"):
        bad.append(name)
if not ko:
    print("  FAIL: ko/*.md 변경이 없다 — plan 이 ko 를 건드리지 않았다", file=sys.stderr)
    sys.exit(3)
if bad:
    print(f"  FAIL: 추가된 줄이 있는 ko 파일: {bad} — delete-only plan 계약 위반", file=sys.stderr)
    sys.exit(3)
print(f"  OK: ko {len(ko)}개 파일 전부 삭제만 (추가 줄 0)")
PYEOF

# ── 4) 대조군 PR (ko 미변경) ────────────────────────────────────────
echo
echo "[4/7] 대조군 PR 생성 — $CONTROL_DOC 만 변경 (ko/*.md 무변경)"
ctl_branch="translate-test-notargets-ctl/$(date -u +%Y%m%d-%H%M%S)"
git checkout -B "$ctl_branch" "$BASE_BRANCH"
[[ -f "$CONTROL_DOC" ]] || { echo "  error: $CONTROL_DOC 없음" >&2; exit 2; }
printf '\n<!-- e2e no-targets control: en-only change, no ko/*.md touched -->\n' >> "$CONTROL_DOC"
git add "$CONTROL_DOC"
git commit -q -m "e2e(no-targets) control: touch $CONTROL_DOC only (no ko changes)"
git push -q -u origin "$ctl_branch"
e2e_ensure_label "$REPO"
ctl_pr_url="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$ctl_branch" \
  --title "e2e(no-targets) control: en-only change" \
  --body "대조군 — ko/*.md 를 전혀 건드리지 않는 PR. 한글 검수는 코멘트도 라벨도 남기지 않아야 한다." \
  --label "$E2E_LABEL")"
ctl_pr_number="${ctl_pr_url##*/}"
echo "  대조군 PR: $ctl_pr_url"

# ── 검수 실행 헬퍼 ──────────────────────────────────────────────────
run_review() {   # $1: PR URL
  local pr="$1"
  if [[ "$REVIEW_VIA" == "local" ]]; then
    echo "  local review_pr.py (dir=$CLOUD_TRANSLATE_DIR, PR=$pr)"
    set +e
    (cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" korean-review/review_pr.py "$pr") \
      2>&1 | sed 's/^/    /'
    local rc=${PIPESTATUS[0]}
    set -e
    (( rc == 0 )) || { echo "  review_pr.py 실패 (exit $rc)" >&2; return 2; }
    return 0
  fi
  local resp job_id status deadline
  resp="$(curl -sS -X POST -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" -d "{\"pr_url\": \"$pr\"}" \
    "$DASHBOARD_BASE_URL/api/ko-review")"
  job_id="$(printf '%s' "$resp" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("job_id") or "")')"
  [[ -n "$job_id" ]] || { echo "  error: job_id 없음: $resp" >&2; return 2; }
  echo "  ko-review job: $job_id (timeout=${JOB_TIMEOUT}s)"
  deadline=$(( $(date +%s) + JOB_TIMEOUT ))
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
  [[ "$status" == "success" ]] || { echo "  ko-review 실패 (status=$status)" >&2; return 2; }
  return 0
}

# 검증용 스냅샷 수집 — issue 코멘트 · 리뷰 · 인라인 코멘트 · 라벨
snapshot() {   # $1: PR 번호, $2: 출력 prefix
  gh api "repos/$REPO/issues/$1/comments" --paginate > "$tmpdir/$2-issue.json"
  gh api "repos/$REPO/pulls/$1/reviews"   --paginate > "$tmpdir/$2-reviews.json"
  gh api "repos/$REPO/pulls/$1/comments"  --paginate > "$tmpdir/$2-inline.json"
  gh pr view "$1" --repo "$REPO" --json labels --jq '[.labels[].name]' > "$tmpdir/$2-labels.json"
}

# ── 5) 케이스 A ─────────────────────────────────────────────────────
echo
echo "[5/7] 케이스 A — 삭제만 있는 ko PR 검수"
run_review "$ko_pr_url"
ko_sha_a="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefOid --jq .headRefOid)"
snapshot "$ko_pr_number" "a"

# ── 6) 케이스 B ─────────────────────────────────────────────────────
echo
echo "[6/7] 케이스 B — head 에 빈 커밋(새 SHA, diff 동일) 후 재검수"
git fetch origin "$ko_head_ref"
git checkout "$ko_head_ref"
git pull --ff-only origin "$ko_head_ref"
git commit -q --allow-empty -m "e2e(no-targets): empty commit — new head SHA, identical diff"
git push -q origin "$ko_head_ref"
pushed_sha="$(git rev-parse HEAD)"
# push 직후 GitHub 이 PR 객체의 head 를 갱신하기까지 지연이 있다 (실측: 곧바로
# 조회하면 옛 SHA 를 돌려줘 "빈 커밋 후에도 SHA 가 같다" 로 오판했다). 검수가
# 새 SHA 를 보도록 PR 의 head 가 방금 push 한 커밋과 일치할 때까지 기다린다.
ko_sha_b=""
for _ in $(seq 30); do
  ko_sha_b="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefOid --jq .headRefOid)"
  [[ "$ko_sha_b" == "$pushed_sha" ]] && break
  sleep 2
done
echo "  head SHA: ${ko_sha_a:0:7} → ${ko_sha_b:0:7} (pushed ${pushed_sha:0:7})"
if [[ "$ko_sha_b" != "$pushed_sha" ]]; then
  echo "  error: PR head 가 push 한 커밋(${pushed_sha:0:7})으로 갱신되지 않았다 (60s 대기)" >&2
  exit 2
fi
run_review "$ko_pr_url"
snapshot "$ko_pr_number" "b"

# ── 7) 케이스 C ─────────────────────────────────────────────────────
echo
echo "[7/7] 케이스 C — 대조군(ko 미변경) PR 검수"
run_review "$ctl_pr_url"
snapshot "$ctl_pr_number" "c"

# ── 판정 ────────────────────────────────────────────────────────────
echo
echo "==================================================================="
echo "  판정"
echo "==================================================================="
# 판정 python 은 FAIL 이면 exit 3 — set -e 아래에서 그대로 죽으면 아래 요약
# (PR 링크·세션 브랜치)이 안 찍혀 debug 가 어렵다. rc 를 받아 요약 후 종료.
set +e
TMPDIR_PATH="$tmpdir" SHA_A="$ko_sha_a" SHA_B="$ko_sha_b" python3 - <<'PYEOF'
import json, os, re, sys

d = os.environ["TMPDIR_PATH"]
sha_a, sha_b = os.environ["SHA_A"], os.environ["SHA_B"]
MARKER = "<!-- korean-review:no-targets -->"
REVIEW_LABELS = {"한글 검수", "content-agent"}


def load(p):
    return json.load(open(os.path.join(d, p)))


def marker_comments(prefix):
    return [c for c in load(f"{prefix}-issue.json") if MARKER in (c.get("body") or "")]


def summary_reviews(prefix):
    return [r for r in load(f"{prefix}-reviews.json")
            if re.search(r"##\s*🔍\s*한글 검수 결과", r.get("body") or "")]


problems = []


def check(ok, label, detail=""):
    print(f"  {'PASS' if ok else 'FAIL'}  {label}" + (f" — {detail}" if detail else ""))
    if not ok:
        problems.append(label)


# 케이스 A — 리뷰는 없고 알림 코멘트 + 라벨
a_marker = marker_comments("a")
a_body = (a_marker[0].get("body") or "") if a_marker else ""
a_labels = set(load("a-labels.json"))
print("케이스 A (삭제만 있는 ko PR)")
check(len(a_marker) == 1, "'검수 대상 없음' 코멘트가 정확히 1건", f"{len(a_marker)}건")
check("검수 대상 없음" in a_body, "코멘트 헤더가 '검수 대상 없음'")
check("위반 없음" not in a_body, "'위반 없음'(= 전 차원 통과)으로 오표기하지 않음")
check(bool(re.search(r"\|\s*`ko/\S+\.md`\s*\|", a_body)), "건너뛴 ko 파일이 표에 명시")
check("추가된 줄 없음" in a_body, "사유가 '추가된 줄 없음'")
check(sha_a[:7] in a_body, "본문에 검수한 head SHA", sha_a[:7])
check(len(summary_reviews("a")) == 0, "요약 리뷰는 게시되지 않음",
      f"{len(summary_reviews('a'))}건")
check(len(load("a-inline.json")) == 0, "인라인 코멘트 0건",
      f"{len(load('a-inline.json'))}건")
check(REVIEW_LABELS <= a_labels, "라벨 '한글 검수'·'content-agent' 부착",
      ", ".join(sorted(a_labels)) or "(없음)")

# 케이스 B — 재검수 시 코멘트가 쌓이지 않고 갱신
b_marker = marker_comments("b")
b_body = (b_marker[0].get("body") or "") if b_marker else ""
print()
print("케이스 B (새 SHA 로 재검수)")
check(len(b_marker) == 1, "코멘트가 여전히 1건 (중복 게시 없음)", f"{len(b_marker)}건")
check(bool(a_marker) and bool(b_marker) and a_marker[0]["id"] == b_marker[0]["id"],
      "같은 코멘트를 갱신 (id 동일)")
check(sha_b[:7] in b_body, "본문 SHA 가 새 head 로 갱신", sha_b[:7])
check(sha_a[:7] not in b_body, "옛 SHA 는 남지 않음", sha_a[:7])

# 케이스 C — ko 미변경 PR 은 침묵
c_labels = set(load("c-labels.json"))
print()
print("케이스 C (대조군 — ko 미변경)")
check(len(marker_comments("c")) == 0, "알림 코멘트 없음", f"{len(marker_comments('c'))}건")
check(not (REVIEW_LABELS & c_labels), "검수 라벨 미부착",
      ", ".join(sorted(c_labels)) or "(없음)")

print()
if problems:
    print(f"KO_REVIEW_NO_TARGETS: FAIL ({len(problems)}건)")
    sys.exit(3)
print("KO_REVIEW_NO_TARGETS: OK")
PYEOF
verdict_rc=$?
set -e

echo "==================================================================="
echo "  ko PR (삭제만) : $ko_pr_url"
echo "  대조군 PR      : $ctl_pr_url"
echo "  세션 브랜치    : $BASE_BRANCH"
echo "  검수 경로      : $REVIEW_VIA"
echo "==================================================================="
exit $verdict_rc
