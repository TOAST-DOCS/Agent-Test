#!/usr/bin/env bash
#
# `.docs-workflow` ignore 게이트 e2e — **webhook 자동 트리거 경로** (Agent-Test).
#
# 무엇이 다른가 — 이 기능의 기존 실측은 전부 Jenkins PR-잡을 파라미터로 **직접**
# 빌드해서 한 것이고 리포도 translate-test 였다. 그 경로는 "잡이 돌면 제외가
# 먹는가" 만 답한다. 운영에서 잡을 돌리는 것은 webhook 이고, 거기엔 잡 안에서는
# 볼 수 없는 층이 하나 더 있다:
#
#   * **webhook 은 `.docs-workflow` 를 보지 않는다.** 필터(base_branches ·
#     actions · label_require)가 잡을 돌릴지 정하고, 무엇을 볼지는 잡 안의
#     게이트가 정한다. 그래서 제외 문서만 바꾼 PR 도 ko-review 는 **정상
#     트리거되어야** 하고, 그 뒤에 아무것도 게시하지 않아야 한다.
#   * **검수 라벨이 안 붙는 연쇄.** `collect.py` 의 ignore 분기는 `_note_skip`
#     을 부르지 않으므로 제외 문서만 바꾼 PR 은 skips 가 비고 →
#     `post_no_targets_notice` 가 안 돌고 → `한글 검수`/`content-agent` 라벨이
#     안 붙는다. 머지해도 translate 필터의 `label_require`(AND)를 못 넘으므로
#     번역도 안 돈다. 번역할 것이 없으니 맞는 결과지만, **webhook 을 태워야만
#     관측되는** 연쇄라 직접 빌드로는 확인된 적이 없다.
#
# 케이스 둘:
#
#   A. **섞인 PR** — 제외 문서 + 대조군을 함께 바꾼다.
#      opened → ko-review 트리거 → 대조군만 검수(제외 문서엔 코멘트 0) →
#      merge → closed → translate 트리거 → 번역 PR 에 대조군 en/ja 만.
#   B. **제외 문서만 바꾼 PR** — opened → ko-review 는 **돌고**,
#      리뷰·인라인·코멘트·검수 라벨이 전부 0. (머지는 하지 않는다. 아래 참고)
#
# 케이스 B 를 머지하지 않는 이유 — 그 뒤의 검증은 "translate task 가 나타나지
# 않는다" 는 부정 확인이라 타임아웃만큼 기다려야 하고, 기다린 시간이 짧으면
# 거짓 통과가 된다. 라벨이 0건이라는 것(=`label_require` 를 못 넘는다)까지가
# 이 스크립트의 결정적 판정이고, 그 다음 한 칸은 webhook 필터의 계약이라
# `e2e-webhook.sh` 가 이미 지킨다.
#
# 픽스처는 **세션 브랜치에서 만들고 버린다** (alpha 에 상주시키지 않는다):
# `.docs-workflow` 와 ko 문서 둘 다 세션 base 에 커밋되므로 alpha 는 무오염이고
# restore 스크립트도 필요 없다. `.docs-workflow` 를 **base** 에 두는 것은
# 의도다 — 게이트가 PR head 에서 읽으므로 base 에서 상속된 설정도 먹는지가
# 함께 확인된다.
#
# 판정은 전부 결정적이다. 검수기는 LLM 이라 "대조군에서 위반 N건" 은 보장할 수
# 없지만, **제외 문서에 코멘트가 0건** 인 것은 그 파일을 아예 읽지 않았다는
# 뜻이라 모델과 무관하다. 대조군이 대상으로 잡혔다는 증거는 '검수 대상 없음'
# 코멘트가 **없다**는 것으로 본다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-workflow-ignore.sh
#   bash scripts/e2e-workflow-ignore.sh --no-merge      # 케이스 A 의 merge 이후 생략
#   bash scripts/e2e-workflow-ignore.sh --timeout 900   # webhook task 폴링 상한
#   bash scripts/e2e-workflow-ignore.sh --keep          # 세션 브랜치·PR 유지
#   bash scripts/e2e-workflow-ignore.sh --pipeline-branch PR-844
#
# `--pipeline-branch` — webhook 이 트리거할 Jenkins multibranch **자식 잡** 이름
# (`content_deploy/{ko-review,translate}/job/<이름>/`). 미머지 브랜치의 게이트를
# 검증하려면 반드시 준다: 빈 값이면 기본 브랜치(= main) 코드로 돌아 "게이트가
# 아직 없다" 를 측정하게 되고, 그 실패는 회귀와 구분되지 않는다. webhook 대상
# repo 행의 `pipeline_branch` 를 임시로 바꿨다가 trap 에서 원복한다.
#
# 엔진: 지정하지 않는다 — webhook 이 recommended preset 으로 트리거하므로 운영과
# 같은 Claude Code CLI 로 돈다 (CLAUDE.md 「e2e 는 api 엔진으로 실행하지 않는다」).
#
# 의존성: git, gh (로그인), curl, python3

set -eo pipefail
set -u

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
POLL_TIMEOUT=900
POLL_INTERVAL=5
BUILD_TIMEOUT=1800
DO_MERGE=1
KEEP=0
# webhook 이 트리거할 Jenkins multibranch 자식 잡 (= 어느 코드로 도는가).
# 빈 값이면 dashboard 기본 브랜치. **미머지 기능을 검증하려면 반드시 준다** —
# 안 주면 main 코드로 돌아 "게이트가 없다" 를 측정하게 된다.
PIPELINE_BRANCH=""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/e2e-label.sh"
source "$SCRIPT_DIR/e2e-webhook-toggle.sh"

# `find_webhook_task` / `wait_for_build_finish` 를 다시 구현하지 않는다 —
# webhook 딜리버리를 task 로 되짚는 규칙은 한 벌이어야 한다 (라벨 모양이 잡마다
# 다르고, 그 예외 목록이 둘로 갈리면 한쪽만 낡는다).
source "$SCRIPT_DIR/e2e-webhook-task.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-merge)      DO_MERGE=0; shift ;;
    --timeout)       POLL_TIMEOUT="$2"; shift 2 ;;
    --build-timeout) BUILD_TIMEOUT="$2"; shift 2 ;;
    --keep)          KEEP=1; shift ;;
    --pipeline-branch) PIPELINE_BRANCH="$2"; shift 2 ;;
    -h|--help)       sed -n '2,58p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다. load_env.sh 를 source 하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ts="$(date -u +%Y%m%d-%H%M%S)"
BASE_BRANCH="e2e-wfignore/${ts}"
HEAD_A="translate-test-wfignore/${ts}"
HEAD_B="translate-test-wfignore-only/${ts}"

EXCLUDED_DOC="ko/wfi-excluded.md"
CONTROL_DOC="ko/wfi-control.md"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# 검수기가 잡는 스타일가이드 위반 — 두 문서에 **같은** 문장을 넣는다. 대조군에만
# 지적이 붙고 제외 문서엔 안 붙는 것이 게이트의 증거다 (같은 입력, 다른 결과).
read -r -d '' DEFECT_BODY <<'EOF' || true

## 인스턴스 생성 예시

예) 콘솔에서 **인스턴스 생성** 버튼을 클릭한다.
예) 이름을 입력 후 다음 단계로 이동 합니다.
EOF

declare -A ORIG_BASE_BRANCHES=()
FILTER_EXTENDED=0

_get_filters() {
  curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/webhooks/repos"
}

_set_filter() {   # $1=job(translate|ko-review) $2=base_branches
  python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$1" "$2" <<'PY'
import json, sys, urllib.request
base_url, token, job, base_branches = sys.argv[1:5]
req = urllib.request.Request(f"{base_url}/api/webhooks/repos",
                             headers={"Authorization": f"Bearer {token}"})
with urllib.request.urlopen(req, timeout=15) as resp:
    data = json.load(resp)
cur = ((data.get("filters") or {}).get(job) or {})
payload = {
    "job": job,
    "actions": cur.get("actions") or "",
    "base_branches": base_branches,
    "author_skip": cur.get("author_skip") or "",
    "label_require": cur.get("label_require") or "",
    "label_skip": cur.get("label_skip") or "",
    "preset": cur.get("preset") or "",
}
put = urllib.request.Request(
    f"{base_url}/api/webhooks/filters", data=json.dumps(payload).encode(),
    method="POST",
    headers={"Authorization": f"Bearer {token}",
             "Content-Type": "application/json"})
with urllib.request.urlopen(put, timeout=15) as r2:
    print(json.dumps(json.load(r2)))
PY
}

ORIG_PIPELINE_BRANCH=""
PIPELINE_BRANCH_SET=0

_set_pipeline_branch() {   # $1 = 자식 잡 이름 ("" = 기본 브랜치)
  python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$REPO" "$1" <<'PYBR'
import json, sys, urllib.request
base_url, token, repo, branch = sys.argv[1:5]
hdr = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
req = urllib.request.Request(f"{base_url}/api/webhooks/repos", headers=hdr)
with urllib.request.urlopen(req, timeout=15) as r:
    rows = (json.load(r).get("repos") or [])
row = next((x for x in rows if (x.get("repo") or "").lower() == repo.lower()), {})
payload = {
    "repo": repo,
    # 현재 on/off 상태는 보존한다 — 이 헬퍼의 책임은 브랜치뿐이다.
    "translate_enabled": bool(row.get("translate_enabled")),
    "ko_review_enabled": bool(row.get("ko_review_enabled")),
    "pipeline_branch": branch,
}
post = urllib.request.Request(
    f"{base_url}/api/webhooks/repos", data=json.dumps(payload).encode(),
    method="POST", headers=hdr)
with urllib.request.urlopen(post, timeout=15) as r2:
    json.load(r2)
print(f"  webhook repo {repo}: pipeline_branch = '{branch or '(기본)'}'")
PYBR
}

_read_pipeline_branch() {
  curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/webhooks/repos" \
    | python3 -c "
import json, sys
rows = (json.load(sys.stdin).get('repos') or [])
row = next((x for x in rows if (x.get('repo') or '').lower() == '$REPO'.lower()), {})
print(row.get('pipeline_branch') or '')"
}

restore_pipeline_branch() {
  (( PIPELINE_BRANCH_SET )) || return 0
  echo "  [cleanup] restoring pipeline_branch = '${ORIG_PIPELINE_BRANCH:-(기본)}'"
  _set_pipeline_branch "$ORIG_PIPELINE_BRANCH" >/dev/null || \
    echo "  [cleanup] WARN: pipeline_branch 원복 실패 — 어드민에서 수동 확인" >&2
  PIPELINE_BRANCH_SET=0
}

restore_filters() {
  (( FILTER_EXTENDED )) || return 0
  for job in translate ko-review; do
    if [[ -n "${ORIG_BASE_BRANCHES[$job]:-}" ]]; then
      echo "  [cleanup] restoring filter[$job].base_branches = '${ORIG_BASE_BRANCHES[$job]}'"
      _set_filter "$job" "${ORIG_BASE_BRANCHES[$job]}" >/dev/null || \
        echo "  [cleanup] WARN: 필터 원복 실패 ($job) — 어드민에서 수동 확인" >&2
    fi
  done
  FILTER_EXTENDED=0
}

cleanup_branches() {
  (( KEEP )) && { echo "  [cleanup] --keep — 세션 브랜치/PR 유지: $BASE_BRANCH"; return 0; }
  echo "  [cleanup] deleting session branches (남은 PR 은 base 삭제와 함께 close)"
  for br in "$HEAD_A" "$HEAD_B" "$BASE_BRANCH"; do
    git push -q origin ":$br" 2>/dev/null || true
  done
}

# 원복 순서 주의: `set_webhook_repo_enabled false` 는 **현재** pipeline_branch 를
# 보존하므로, 그 앞에서 되돌리지 않으면 PR 브랜치 값이 남은 채 꺼진다.
trap 'ec=$?; rm -rf "$tmpdir"; restore_filters; restore_pipeline_branch; set_webhook_repo_enabled false; cleanup_branches; exit $ec' EXIT INT TERM

echo "==================================================================="
echo "  .docs-workflow ignore × webhook e2e — Agent-Test"
echo "  session base : $BASE_BRANCH"
echo "  pipeline     : ${PIPELINE_BRANCH:-(dashboard 기본 브랜치)}"
echo "  excluded     : $EXCLUDED_DOC"
echo "  control      : $CONTROL_DOC"
echo "==================================================================="

# ── 0) webhook 활성화 ────────────────────────────────────────────────
echo
echo "[0/8] webhook 대상 활성화: $REPO"
set_webhook_repo_enabled true
ORIG_PIPELINE_BRANCH="$(_read_pipeline_branch)"
if [[ "$PIPELINE_BRANCH" != "$ORIG_PIPELINE_BRANCH" ]]; then
  echo "  pipeline_branch: '${ORIG_PIPELINE_BRANCH:-(기본)}' → '${PIPELINE_BRANCH:-(기본)}'"
  _set_pipeline_branch "$PIPELINE_BRANCH"
  PIPELINE_BRANCH_SET=1
fi
if [[ -z "$PIPELINE_BRANCH" ]]; then
  echo "  NOTE: --pipeline-branch 미지정 — 기본 브랜치 코드로 돕니다."
  echo "        미머지 게이트를 검증하려면 PR 의 자식 잡 이름을 주세요 (예: PR-844)."
fi

# ── 1) 세션 base 브랜치 + 픽스처 (`.docs-workflow` 포함) ─────────────
echo
echo "[1/8] 세션 base 브랜치 + 픽스처 커밋"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$BASE_BRANCH" "origin/$BASE_SOURCE"

cat > .docs-workflow <<EOF
# .docs-workflow — e2e 픽스처 (scripts/e2e-workflow-ignore.sh, $ts)
# 이 세션 브랜치에서만 존재한다. alpha 에는 없다.
ignore:
  - $EXCLUDED_DOC
EOF

for doc in "$EXCLUDED_DOC" "$CONTROL_DOC"; do
  cat > "$doc" <<EOF
## 개요

이 문서는 \`.docs-workflow\` ignore 게이트 e2e 픽스처입니다 ($ts).
세션 브랜치에서만 존재하며 종료 시 브랜치와 함께 사라집니다.
EOF
done

git add .docs-workflow "$EXCLUDED_DOC" "$CONTROL_DOC"
git commit -q -m "test(wfignore-e2e): fixtures + .docs-workflow on session base ($ts)"
git push -q -u origin "$BASE_BRANCH"
echo "  base pushed: $BASE_BRANCH (.docs-workflow → ignore: $EXCLUDED_DOC)"

# ── 2) 필터 base_branches 임시 확장 ─────────────────────────────────
echo
echo "[2/8] webhook 필터의 base_branches 에 세션 브랜치 append (trap 에서 원복)"
_filters_json="$(_get_filters)"
for job in translate ko-review; do
  cur="$(printf '%s' "$_filters_json" | python3 -c "
import json, sys
print(((json.load(sys.stdin).get('filters') or {}).get('$job') or {}).get('base_branches') or '')")"
  ORIG_BASE_BRANCHES[$job]="$cur"
  if [[ ",$cur," == *",$BASE_BRANCH,"* ]]; then new="$cur"; else new="${cur:+$cur,}$BASE_BRANCH"; fi
  echo "    $job: '$cur' → '$new'"
  _set_filter "$job" "$new" >/dev/null
done
FILTER_EXTENDED=1

# ── 3) 케이스 A: 섞인 PR ────────────────────────────────────────────
echo
echo "[3/8] 케이스 A — 제외 문서 + 대조군을 함께 바꾼 PR"
git checkout -q -B "$HEAD_A" "$BASE_BRANCH"
for doc in "$EXCLUDED_DOC" "$CONTROL_DOC"; do
  printf '%s\n' "$DEFECT_BODY" >> "$doc"
done
git add "$EXCLUDED_DOC" "$CONTROL_DOC"
git commit -q -m "test(wfignore-e2e): same defect in excluded + control ($ts)"
git push -q -u origin "$HEAD_A"

e2e_ensure_label "$REPO"
# translate 필터의 label_require(`content-agent,한글 검수`, AND)를 넘기려고 미리
# 붙인다 — 케이스 A 가 보려는 것은 merge 이후의 **번역 게이트**이지 라벨 부착이
# 아니다. 라벨이 붙지 않는 쪽은 케이스 B 가 본다.
for lbl in "content-agent" "한글 검수"; do
  gh label list --repo "$REPO" --search "$lbl" --json name --jq '.[].name' 2>/dev/null \
    | grep -Fxq "$lbl" \
    || gh label create "$lbl" --repo "$REPO" --color "1d76db" \
         --description "webhook filter label" 2>/dev/null || true
done
pr_a="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$HEAD_A" \
  --label "content-agent" --label "한글 검수" --label "$E2E_LABEL" \
  --title "e2e(wfignore) A: excluded + control" \
  --body "\`.docs-workflow\` ignore 게이트 e2e (webhook 경로). \`$EXCLUDED_DOC\` 는 제외 대상, \`$CONTROL_DOC\` 는 대조군 — 같은 위반이 들어 있다.")"
pr_a_num="${pr_a##*/}"
echo "  PR A: $pr_a"

# ── 4) opened → ko-review (webhook) ─────────────────────────────────
echo
echo "[4/8] A: webhook opened → ko-review task 대기 (최대 ${POLL_TIMEOUT}s)"
A_TRIGGER="FAIL"
task_json="$(wait_for_webhook_task "$pr_a" "$pr_a_num" "opened" "ko-review" \
             "$POLL_TIMEOUT" "$POLL_INTERVAL" || true)"
if [[ "$(task_present "$task_json")" == "y" ]]; then
  A_TRIGGER="PASS"
  wait_for_build_finish "$(task_field "$task_json" job_id)" \
                        "$(task_field "$task_json" task_id)" "$BUILD_TIMEOUT" || true
else
  echo "  FAIL: opened → ko-review task 미감지" >&2
fi

snapshot() {   # $1=PR 번호 $2=prefix
  gh api "repos/$REPO/issues/$1/comments" --paginate > "$tmpdir/$2-issue.json"
  gh api "repos/$REPO/pulls/$1/reviews"   --paginate > "$tmpdir/$2-reviews.json"
  gh api "repos/$REPO/pulls/$1/comments"  --paginate > "$tmpdir/$2-inline.json"
  gh pr view "$1" --repo "$REPO" --json labels --jq '[.labels[].name]' > "$tmpdir/$2-labels.json"
}
snapshot "$pr_a_num" "a"

# ── 5) 케이스 B: 제외 문서만 바꾼 PR ────────────────────────────────
echo
echo "[5/8] 케이스 B — 제외 문서만 바꾼 PR (라벨은 e2e 하나만)"
git checkout -q -B "$HEAD_B" "$BASE_BRANCH"
printf '%s\n' "$DEFECT_BODY" >> "$EXCLUDED_DOC"
git add "$EXCLUDED_DOC"
git commit -q -m "test(wfignore-e2e): excluded doc only ($ts)"
git push -q -u origin "$HEAD_B"
pr_b="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$HEAD_B" \
  --label "$E2E_LABEL" \
  --title "e2e(wfignore) B: excluded only" \
  --body "제외 문서만 바꾼 PR — ko-review 는 트리거되지만 리뷰·코멘트·검수 라벨이 하나도 남지 않아야 한다.")"
pr_b_num="${pr_b##*/}"
echo "  PR B: $pr_b"

echo
echo "[6/8] B: webhook opened → ko-review task 대기 (최대 ${POLL_TIMEOUT}s)"
B_TRIGGER="FAIL"
task_json="$(wait_for_webhook_task "$pr_b" "$pr_b_num" "opened" "ko-review" \
             "$POLL_TIMEOUT" "$POLL_INTERVAL" || true)"
if [[ "$(task_present "$task_json")" == "y" ]]; then
  B_TRIGGER="PASS"
  wait_for_build_finish "$(task_field "$task_json" job_id)" \
                        "$(task_field "$task_json" task_id)" "$BUILD_TIMEOUT" || true
else
  echo "  FAIL: opened → ko-review task 미감지 (webhook 은 ignore 를 보지 않으므로 돌아야 한다)" >&2
fi
snapshot "$pr_b_num" "b"

# ── 7) 케이스 A merge → translate ───────────────────────────────────
A_MERGE="skipped"
TRANSLATE_PR=""
if (( DO_MERGE )); then
  echo
  echo "[7/8] A: PR merge → webhook closed → translate task 대기"
  gh pr merge "$pr_a" --repo "$REPO" --merge --delete-branch
  task_json="$(wait_for_webhook_task "$pr_a" "$pr_a_num" "closed" "translate" \
               "$POLL_TIMEOUT" "$POLL_INTERVAL" || true)"
  if [[ "$(task_present "$task_json")" == "y" ]]; then
    A_MERGE="PASS"
    wait_for_build_finish "$(task_field "$task_json" job_id)" \
                          "$(task_field "$task_json" task_id)" "$BUILD_TIMEOUT" || true
    # 번역 PR 은 base=세션 브랜치, head=translate/... 로 열린다.
    TRANSLATE_PR="$(gh pr list --repo "$REPO" --state all --base "$BASE_BRANCH" \
      --search "translate in:title" --json url,headRefName,number \
      --jq '[.[] | select(.headRefName | startswith("translate/"))][0].url' 2>/dev/null || true)"
    if [[ -n "$TRANSLATE_PR" && "$TRANSLATE_PR" != "null" ]]; then
      echo "  번역 PR: $TRANSLATE_PR"
      gh api "repos/$REPO/pulls/${TRANSLATE_PR##*/}/files" --paginate \
        --jq '[.[].filename]' > "$tmpdir/translate-files.json"
    else
      echo '[]' > "$tmpdir/translate-files.json"
      echo "  WARN: 번역 PR 을 찾지 못했습니다" >&2
    fi
  else
    echo "  FAIL: closed → translate task 미감지" >&2
    echo '[]' > "$tmpdir/translate-files.json"
  fi
else
  echo
  echo "[7/8] --no-merge — merge 이후 생략"
  echo '[]' > "$tmpdir/translate-files.json"
fi

# ── 8) 판정 ─────────────────────────────────────────────────────────
echo
echo "[8/8] 판정"
echo "==================================================================="
set +e
python3 - "$tmpdir" "$EXCLUDED_DOC" "$CONTROL_DOC" "$A_TRIGGER" "$B_TRIGGER" \
          "$A_MERGE" <<'PY'
import json, os, sys

tmpdir, excluded, control, a_trigger, b_trigger, a_merge = sys.argv[1:7]

def load(name):
    with open(os.path.join(tmpdir, name), encoding="utf-8") as fh:
        return json.load(fh)

problems = []

def check(ok, label, detail=""):
    print(f"  {'PASS' if ok else 'FAIL'}  {label}" + (f" — {detail}" if detail else ""))
    if not ok:
        problems.append(label)

REVIEW_LABELS = {"한글 검수", "content-agent"}
NO_TARGETS = "검수 대상"

def inline_paths(prefix):
    return [c.get("path") or "" for c in load(f"{prefix}-inline.json")]

def bodies(prefix, kind):
    return [(c.get("body") or "") for c in load(f"{prefix}-{kind}.json")]

# ── 케이스 A — 섞인 PR ────────────────────────────────────────────
print("케이스 A — 제외 문서 + 대조군")
check(a_trigger == "PASS", "webhook opened → ko-review 트리거", a_trigger)

a_paths = inline_paths("a")
check(excluded not in a_paths, f"제외 문서에 인라인 코멘트 0건",
      f"{a_paths.count(excluded)}건 / 전체 {len(a_paths)}건")

# 요약 리뷰 본문에도 제외 문서 경로가 등장하면 안 된다 (검출 항목 목록 포함).
a_review_hits = [b for b in bodies("a", "reviews") if excluded in b]
check(not a_review_hits, "요약 리뷰 본문에 제외 문서 경로 없음",
      f"{len(a_review_hits)}건")

# 대조군이 대상으로 잡혔다는 증거 — '검수 대상 없음' 알림이 없어야 한다.
a_no_targets = [b for b in bodies("a", "issue") if NO_TARGETS in b]
check(not a_no_targets, "대조군이 검수 대상으로 잡힘 ('검수 대상 없음' 알림 없음)",
      f"{len(a_no_targets)}건")

# ── 케이스 B — 제외 문서만 ────────────────────────────────────────
print("\n케이스 B — 제외 문서만 바꾼 PR")
check(b_trigger == "PASS",
      "webhook opened → ko-review 트리거 (webhook 은 ignore 를 보지 않는다)", b_trigger)
check(len(load("b-reviews.json")) == 0, "리뷰 0건",
      f"{len(load('b-reviews.json'))}건")
check(len(load("b-inline.json")) == 0, "인라인 코멘트 0건",
      f"{len(load('b-inline.json'))}건")
check(len(load("b-issue.json")) == 0, "PR 코멘트 0건",
      f"{len(load('b-issue.json'))}건")
b_labels = set(load("b-labels.json"))
check(not (REVIEW_LABELS & b_labels),
      "검수 라벨 미부착 (→ 머지해도 translate 의 label_require 를 못 넘는다)",
      ", ".join(sorted(b_labels)) or "(없음)")

# ── 번역 게이트 (케이스 A merge) ──────────────────────────────────
if a_merge != "skipped":
    print("\n케이스 A — merge → translate")
    check(a_merge == "PASS", "webhook closed → translate 트리거", a_merge)
    files = load("translate-files.json")
    stem_ex = excluded.split("/", 1)[1]
    stem_ct = control.split("/", 1)[1]
    bad = [f for f in files if f.endswith(stem_ex)]
    good = [f for f in files if f.endswith(stem_ct)]
    check(not bad, "번역 PR 에 제외 문서의 en/ja 없음",
          ", ".join(bad) or f"파일 {len(files)}건")
    check(len(good) >= 1, "번역 PR 에 대조군의 en/ja 있음",
          ", ".join(good) or "(없음)")

print()
if problems:
    print(f"WORKFLOW_IGNORE_WEBHOOK: FAIL ({len(problems)}건)")
    for p in problems:
        print(f"  - {p}")
    raise SystemExit(3)
print("WORKFLOW_IGNORE_WEBHOOK: PASS")
PY
verdict=$?
set -e

echo "==================================================================="
echo "  PR A (섞인 PR)        : $pr_a"
echo "  PR B (제외 문서만)    : $pr_b"
[[ -n "$TRANSLATE_PR" ]] && echo "  번역 PR               : $TRANSLATE_PR"
echo "  pipeline_branch       : ${PIPELINE_BRANCH:-(기본)}"
echo "  세션 base             : $BASE_BRANCH$( ((KEEP)) && echo ' (--keep — 수동 정리 필요)' )"
echo "==================================================================="
exit $verdict
