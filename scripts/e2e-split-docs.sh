#!/usr/bin/env bash
#
# 릴리스 노트 연도별 분리(split-docs) e2e — split_docs_by_year.py 검증.
#
# 검증 대상: 날짜가 쌓이는 `<lang>/release-notes.md` 를 `<lang>/release-notes/
# <year>.md` 로 자르고, 원래 경로에는 header + mkdocs `include-markdown` 지시자만
# 남긴다. **배포되는 페이지는 한 글자도 달라지지 않아야 한다.**
#
# ── 왜 별도 e2e 인가 ──────────────────────────────────────────────────────
# 이 도구는 번역이 아니라 **리팩터**다 — 모델을 전혀 부르지 않고 문서를 자기
# 자신으로 다시 쓴다. 그래서 번역 plan(round1/table-suite)이 아무리 통과해도
# 이 경로는 검증되지 않고, 반대로 이 도구가 깨지는 방식은 전부 결정적이라
# **바이트 비교로 판정 가능하다** (LLM 판정 없음). 실제로 깨지는 모양:
#   - 날짜 heading 위의 `<a id>` 가 header 에 남아 그 날짜로 가는 링크가 전부 죽음
#   - 섹션이 유실/중복/재정렬되어 include 를 펼치면 원본과 달라짐
#   - 한 언어만 잘리고 나머지는 monolithic 으로 남음 (green PR 이 그걸 숨김)
#   - 연도 파일에 붙는 pre-align marker 가 자기 outline 이 아닌 값으로 스탬프됨
#   - 부모의 stale marker 를 그대로 물려받아 영원히 drift 로 보고됨
#
# ── 왜 결함 주입이 아니라 실제 문서인가 ───────────────────────────────────
# Agent-Test 의 `ko/en/ja/release-notes.md` 는 이미 91개 날짜 섹션 × 11개 연도
# (2016~2026) 를 가진 **진짜 date-stacked 문서**다. 픽스처를 따로 만들면 실제
# 코퍼스가 가진 모양(연도 경계에 걸친 `<a id>`, 날짜 heading 에 `{ #id }` 가
# 있는 것과 없는 것이 섞임, 언어별 줄 수 차이)을 잃는다. 그래서 이 e2e 는
# **alpha 의 release-notes.md 를 그대로** 세션 브랜치에서 자른다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성 (문서는 손대지 않는다 — 원본 그대로 자른다)
#   2) dry-run — 왕복 검증 통과 · 연도 파일 수 · PR 미생성        [local 전용]
#   3) 실제 분리 → Split PR
#   4) 판정 (아래 8개 규칙, 전부 바이트/구조 비교)
#   5) 결과 (SPLIT_DOCS: OK|FAIL)
#   6) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) dry-run 이 ko/en/ja 각각 왕복 검증 OK · 연도 파일 2개 이상 · PR 미생성
#                                                          [local 전용, api=SKIP]
#   (2) Split PR 생성 (head=split-docs/… · content-agent + split-docs 라벨)
#   (3) ko/en/ja **전부** 분리됨 (all-or-nothing — 한 언어만 잘리면 실패)
#   (4) 부모가 header + include 지시자만 남음 (날짜 heading 0개)
#   (5) **왕복**: 부모의 include 를 순서대로 펼치면 원본과 내용 동일
#       (빈 줄 무시) — 유실·중복·재정렬을 한 번에 잡는다
#   (6) 원본의 모든 `<a id>`/`<a name>` anchor 가 **순서까지 같게** 보존
#       (연도 경계에 걸린 anchor 가 header 에 남지 않았는지)
#   (7) 연도 파일마다 자기 outline 으로 계산된 유효한 pre-align marker,
#       부모도 재스탬프 (분리로 outline 이 title 하나로 줄었으므로)
#   (8) PR 본문이 include-markdown 선례 건수를 보고 (플러그인은 mkdocs 부모
#       repo 설정이라, 선례 0 이면 지시자가 raw text 로 배포된다)
#   (9) 분리 후 **렌더 검증** 댓글(`<!-- split-docs:verify -->`)이 달리고,
#       비교한 부모 문서마다 '동일' 판정이 실린다. 이 검증은 왕복 검증이
#       볼 수 없는 축이다 — 왕복은 잘라낸 본문이 원본과 같은지를 보고,
#       렌더 검증은 include 가 그 본문을 도로 조립해 같은 페이지를
#       만들어 내는지를 본다. PR 본문의 '렌더 비교' 딥링크도 함께 확인한다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-split-docs.sh                    # 로컬 split_docs_by_year.py
#   bash scripts/e2e-split-docs.sh --translate api    # dashboard /api/split-docs → Jenkins
#   bash scripts/e2e-split-docs.sh --keep             # 브랜치/PR 보존 (디버깅)
#   bash scripts/e2e-split-docs.sh --doc release-notes.md
#   bash scripts/e2e-split-docs.sh --base-source e2e/my-branch
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-split-docs.sh
#
# 의존성: git, gh (로그인), python3.
#   --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN (load_env.sh) 필요.
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-splitdocs/$TS"
DOC="release-notes.md"
LANGS="ko,en,ja"
KEEP=0
TRANSLATE_MODE="local"     # local | api
JOB_TIMEOUT="${JOB_TIMEOUT:-1800}"

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

# 도구 경로는 두 레이아웃을 모두 받아들인다. 2026-08 에
# `pre-align/split_docs_by_year.py` → `pre-align/tools/splice/split_docs_by_year.py`
# 로 옮겼는데, 이 e2e 는 **아직 그 이동이 없는 체크아웃**(main, 다른 워크트리)
# 에도 그대로 걸려야 한다 — 하드코딩하면 검증하려는 브랜치가 아니라 스크립트가
# 먼저 깨진다.
_split_tool() {
  local d
  for d in "pre-align/tools/splice" "pre-align"; do
    [[ -f "$CLOUD_TRANSLATE_DIR/$d/split_docs_by_year.py" ]] && {
      printf '%s/split_docs_by_year.py' "$d"; return 0; }
  done
  echo "error: split_docs_by_year.py 를 $CLOUD_TRANSLATE_DIR 에서 찾지 못함" >&2
  return 1
}
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    --langs) LANGS="$2"; shift 2 ;;
    --base-source) BASE_SOURCE="$2"; shift 2 ;;
    --translate) TRANSLATE_MODE="$2"; shift 2 ;;
    -h|--help) sed -n '1,70p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$TRANSLATE_MODE" in
  local|api) ;;
  *) echo "error: --translate 는 local|api" >&2; exit 1 ;;
esac
if [[ "$TRANSLATE_MODE" == "api" && ( -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ) ]]; then
  echo "error: --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다 (load_env.sh)." >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
# api 모드는 Jenkins 안에서 도구를 돌리므로 로컬 체크아웃이 없어도 된다 —
# 그 경우까지 여기서 죽이면 안 된다.
SPLIT_TOOL=""
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  SPLIT_TOOL="$(_split_tool)" || exit 2
  echo "  도구: $CLOUD_TRANSLATE_DIR/$SPLIT_TOOL"
fi
tmpdir="$(mktemp -d)"; LOG="$tmpdir/split.log"; DRYLOG="$tmpdir/dryrun.log"

# 판정 heredoc 은 marker 검증에 pre-align 의 alignment_signature 를 **그대로**
# 쓴다 — 서명 알고리즘(fence 인식 · 앵커가 heading 위로 붙는 규칙 · h1 제외)을
# 여기서 다시 구현하면 원본이 바뀔 때 조용히 어긋나 오탐/누락이 된다. 그런데
# align_headings 는 httpx 를 import 하므로 **시스템 python3 로는 import 가
# 실패**하고, 그러면 그 규칙이 SKIP 으로 사라진다 (실측: 첫 실행에서 (7)이
# 세 언어 모두 SKIP). 그래서 판정도 도구와 같은 venv 인터프리터로 돌린다.
JUDGE_PY="$CLOUD_TRANSLATE_PY"
[[ -x "$JUDGE_PY" ]] || JUDGE_PY="python3"

split_pr_url=""
cleanup() {
  local rc=$?
  if (( KEEP )); then
    echo; echo "--keep: 보존 — 세션 $SESSION_BRANCH / PR ${split_pr_url:-<none>}"
    echo "  정리: gh pr close <n> --repo $REPO --delete-branch; git push origin :$SESSION_BRANCH"
    return $rc
  fi
  echo; echo "[cleanup] Split PR · 브랜치 정리"
  [[ -n "$split_pr_url" ]] && gh pr close "$split_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/split-docs/*" 2>/dev/null | sed 's|.*refs/heads/||')
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC (langs=$LANGS)"
echo "mode    : --translate $TRANSLATE_MODE"
echo

# ── 1) 세션 브랜치 ────────────────────────────────────────────────────────
# 문서는 변형하지 않는다 — alpha 의 release-notes.md 를 그대로 자르는 것이
# 이 e2e 의 요점이다. 브랜치를 따로 파는 이유는 alpha 를 clean 하게 두기 위함.
echo "[1/6] 세션 브랜치 생성 (문서 변형 없음)"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"
git push -q -f origin "$SESSION_BRANCH"
base_sha="$(git rev-parse HEAD)"
echo "  세션 base: $base_sha"

# ── 2) dry-run ───────────────────────────────────────────────────────────
dry_skipped=0
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  echo
  echo "[2/6] dry-run (PR 생성 없음)"
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    "$CLOUD_TRANSLATE_PY" "$SPLIT_TOOL" "$REPO" \
      --base "$SESSION_BRANCH" --doc "$DOC" --langs "$LANGS" --dry-run \
      --out "$tmpdir/dryout" \
  ) > "$DRYLOG" 2>&1
  set -e
  grep -E '^---|왕복|dry-run' "$DRYLOG" | sed 's/^/  /' || true
else
  echo
  echo "[2/6] dry-run — SKIP (--translate api)"
  dry_skipped=1
fi

# ── 3) 실제 분리 ─────────────────────────────────────────────────────────
echo
echo "[3/6] 연도별 분리 실행"
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    "$CLOUD_TRANSLATE_PY" "$SPLIT_TOOL" "$REPO" \
      --base "$SESSION_BRANCH" --doc "$DOC" --langs "$LANGS" \
  ) 2>&1 | tee "$LOG"
  split_rc=${PIPESTATUS[0]}
  set -e
  split_pr_url="$(grep -oE 'PR opened: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
else
  # dashboard 경로 — Repos 탭 행 ⋯ 메뉴 '연도별 분리' 와 동일한 API.
  # dry_run 은 이 라우트에서 **기본 true** 라 반드시 명시적으로 꺼야 한다.
  resp="$(curl -sS -X POST \
    -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"target\": \"https://github.com/$REPO\", \"base_ref\": \"$SESSION_BRANCH\",
         \"doc\": \"$DOC\", \"langs\": \"$LANGS\", \"dry_run\": false}" \
    "$DASHBOARD_BASE_URL/api/split-docs")"
  echo "$resp" | python3 -m json.tool | sed 's/^/  /'
  job_id="$(printf '%s' "$resp" | python3 -c 'import json,sys; print((json.load(sys.stdin) or {}).get("job_id") or "")')"
  [[ -n "$job_id" ]] || { echo "error: /api/split-docs 응답에 job_id 없음" >&2; exit 2; }
  echo "  잡 완료 대기 (job_id=$job_id, timeout=${JOB_TIMEOUT}s)"
  deadline=$(( $(date +%s) + JOB_TIMEOUT )); status=""
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
    sleep 15
  done
  echo "  잡 status=$status"
  split_rc=0; [[ "$status" == "success" ]] || split_rc=1
  split_pr_url="$(gh pr list --repo "$REPO" --base "$SESSION_BRANCH" --state all \
    --json url,headRefName --jq '[.[] | select(.headRefName | startswith("split-docs/")) | .url] | last // ""')"
fi

# ── 4) 판정 ──────────────────────────────────────────────────────────────
echo
echo "[4/6] 판정"
fails=0
ok()   { echo "  PASS  $1"; }
bad()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
skip() { echo "  SKIP  $1"; }

# (1) dry-run
if (( dry_skipped )); then
  skip "(1) dry-run — api 모드"
else
  d_ok=1
  for lang in ${LANGS//,/ }; do
    grep -qE -- "--- $lang/$DOC: 섹션 [0-9]+개 → 연도 파일 [0-9]+개  \(왕복 검증 OK\)" "$DRYLOG" \
      || { d_ok=0; echo "        dry-run 에 $lang 의 왕복 검증 OK 줄이 없음"; }
  done
  if grep -q "PR opened:" "$DRYLOG"; then d_ok=0; echo "        dry-run 이 PR 을 만들었다"; fi
  grep -q "PR 생성 안 함" "$DRYLOG" || { d_ok=0; echo "        dry-run 종료 문구 없음"; }
  (( d_ok )) && ok "(1) dry-run 이 언어별 왕복 검증 OK · PR 미생성" \
              || bad "(1) dry-run 결과가 기대와 다름 (로그: $DRYLOG)"
fi

# (2) Split PR
if (( split_rc == 0 )) && [[ -n "$split_pr_url" ]]; then
  ok "(2a) Split PR 생성 — $split_pr_url"
  e2e_label_pr "$REPO" "$split_pr_url"
else
  bad "(2a) Split PR 미생성 (exit=$split_rc) — 이후 검사 불가 (로그: $LOG)"
  echo; echo "SPLIT_DOCS: FAIL"; KEEP=1; exit 1
fi

pr_labels="$(gh pr view "$split_pr_url" --repo "$REPO" --json labels --jq '[.labels[].name] | join(",")')"
if [[ ",$pr_labels," == *",content-agent,"* && ",$pr_labels," == *",split-docs,"* ]]; then
  ok "(2b) PR 라벨 content-agent + split-docs ($pr_labels)"
else
  bad "(2b) PR 라벨 누락 — 사람이 연 PR 과 구분되지 않는다 (labels=$pr_labels)"
fi

split_branch="$(gh pr view "$split_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$split_branch"
gh pr view "$split_pr_url" --repo "$REPO" --json body --jq .body > "$tmpdir/pr_body.md"
gh pr view "$split_pr_url" --repo "$REPO" --json comments \
  --jq '[.comments[].body] | join("\n\n---\n\n")' > "$tmpdir/pr_comments.md" 2>/dev/null || : > "$tmpdir/pr_comments.md"

# base(원본) 와 분리 결과를 파일로 떨군다 — 판정은 전부 파이썬에서 바이트 비교.
stem="${DOC%.md}"
mkdir -p "$tmpdir/base" "$tmpdir/new"
for lang in ${LANGS//,/ }; do
  git show "$base_sha:$lang/$DOC" > "$tmpdir/base/$lang.md" 2>/dev/null || : > "$tmpdir/base/$lang.md"
  git show "origin/$split_branch:$lang/$DOC" > "$tmpdir/new/$lang.md" 2>/dev/null || : > "$tmpdir/new/$lang.md"
  mkdir -p "$tmpdir/new/$lang"
  while read -r f; do
    [[ -n "$f" ]] || continue
    git show "origin/$split_branch:$f" > "$tmpdir/new/$lang/$(basename "$f")" 2>/dev/null || true
  done < <(git ls-tree -r --name-only "origin/$split_branch" "$lang/$stem/" 2>/dev/null)
done

"$JUDGE_PY" - "$tmpdir" "$LANGS" "$stem" "$CLOUD_TRANSLATE_DIR" <<'PY' || fails=$((fails + 1))
import io, os, re, sys

tmp, langs_csv, stem, ct_dir = sys.argv[1:5]
langs = [s for s in langs_csv.split(",") if s]
rc = 0

sys.path.insert(0, os.path.join(ct_dir, "pre-align"))
try:
    from align_apply import aligned_marker_status
except Exception as exc:                                   # pragma: no cover
    aligned_marker_status = None
    print(f"  WARN  (7) marker 검사를 건너뜁니다 — pre-align import 실패: {exc}")
    print(f"        CLOUD_TRANSLATE_PY 를 venv 인터프리터로 지정하면 검사됩니다 "
          f"(현재: {sys.executable})")

INCLUDE_RE = re.compile(r"\{%-?\s*include-markdown\s+'([^']+)'\s*-?%\}")
DATE_HEAD_RE = re.compile(r"^#{2,4}\s+\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.")
ANCHOR_RE = re.compile(r'<(?:a|span)\b[^>]*?\b(?:id|name)\s*=\s*"([^"]+)"')
MARKER_RE = re.compile(r"<!--\s*pre-align:aligned\s+sig=[0-9a-f]+\s*-->")


def read(p):
    try:
        return io.open(p, encoding="utf-8", newline="").read()
    except FileNotFoundError:
        return ""


def ok(msg):
    print(f"  PASS  {msg}")


def bad(msg, *extra):
    global rc
    print(f"  FAIL  {msg}")
    for e in extra:
        print(f"        {e}")
    rc = 1


def content_lines(text):
    """빈 줄과 marker 줄을 뺀 내용 줄 — 왕복 비교의 단위."""
    out = []
    for ln in text.splitlines():
        s = ln.strip()
        if not s or MARKER_RE.fullmatch(s):
            continue
        out.append(s)
    return out


# (3) 모든 언어가 분리되었는가 (all-or-nothing)
split_langs, unsplit = [], []
for lang in langs:
    parent = read(f"{tmp}/new/{lang}.md")
    years = sorted(f for f in os.listdir(f"{tmp}/new/{lang}")
                   if f.endswith(".md")) if os.path.isdir(f"{tmp}/new/{lang}") else []
    (split_langs if (INCLUDE_RE.search(parent) and len(years) >= 2) else unsplit).append(lang)
if unsplit:
    bad(f"(3) 분리되지 않은 언어: {', '.join(unsplit)} — all-or-nothing 이 깨졌다",
        "한 언어만 monolithic 으로 남으면 green PR 이 그 사실을 숨긴다")
else:
    ok(f"(3) {', '.join(split_langs)} 전부 분리됨")

for lang in split_langs:
    base = read(f"{tmp}/base/{lang}.md")
    parent = read(f"{tmp}/new/{lang}.md")
    ydir = f"{tmp}/new/{lang}"
    includes = INCLUDE_RE.findall(parent)

    # (4) 부모는 header + include 만
    stray = [ln for ln in parent.splitlines() if DATE_HEAD_RE.match(ln.strip())]
    if stray:
        bad(f"(4) {lang} 부모에 날짜 heading 이 남음 ({len(stray)}개)", *stray[:3])
    elif len(includes) < 2:
        bad(f"(4) {lang} 부모의 include 지시자가 {len(includes)}개 (2개 미만)")
    else:
        ok(f"(4) {lang} 부모 = header + include {len(includes)}개 (날짜 heading 0)")

    # (5) 왕복 — include 를 순서대로 펼치면 원본과 내용 동일
    # 부모에서 include 지시자만 지운 나머지 = header. 그 뒤에 연도 파일을
    # include 순서대로 이어 붙인 것이 "펼친 문서" 다.
    head_txt = INCLUDE_RE.sub("", parent)
    expanded = content_lines(head_txt)
    missing_files = []
    for rel in includes:
        name = os.path.basename(rel)
        p = os.path.join(ydir, name)
        if not os.path.isfile(p):
            missing_files.append(rel)
            continue
        expanded += content_lines(read(p))
    if missing_files:
        bad(f"(5) {lang} include 가 가리키는 연도 파일이 없음: {', '.join(missing_files)}")
    else:
        orig = content_lines(base)
        if expanded == orig:
            ok(f"(5) {lang} 왕복 검증 — include 펼침 == 원본 ({len(orig)}줄)")
        else:
            first = next((i for i, (a, b) in enumerate(zip(orig, expanded)) if a != b),
                         min(len(orig), len(expanded)))
            bad(f"(5) {lang} 왕복 검증 실패 — 원본 {len(orig)}줄 vs 펼침 {len(expanded)}줄",
                f"첫 불일치 #{first}:",
                f"  원본: {orig[first] if first < len(orig) else '<없음>'!r}",
                f"  펼침: {expanded[first] if first < len(expanded) else '<없음>'!r}")

    # (6) anchor 순서까지 보존 — 연도 경계에 걸린 <a id> 가 header 에 남으면
    #     그 날짜로 가는 링크가 전부 죽는다. 개수만 세면 잡히지 않는다.
    base_anchors = ANCHOR_RE.findall(base)
    new_anchors = ANCHOR_RE.findall(head_txt)
    for rel in includes:
        new_anchors += ANCHOR_RE.findall(read(os.path.join(ydir, os.path.basename(rel))))
    if base_anchors == new_anchors:
        ok(f"(6) {lang} anchor {len(base_anchors)}개가 순서까지 동일")
    else:
        lost = [a for a in base_anchors if a not in new_anchors]
        bad(f"(6) {lang} anchor 가 달라짐 (원본 {len(base_anchors)} → {len(new_anchors)})",
            f"유실: {', '.join(lost[:5]) or '<없음>'}")

    # (7) marker — 연도 파일은 자기 outline 으로, 부모는 재스탬프
    if aligned_marker_status is None:
        print(f"  SKIP  (7) {lang} marker 검사 (pre-align import 실패)")
        continue
    bad_marker = []
    for rel in includes:
        name = os.path.basename(rel)
        st, cur, got = aligned_marker_status(read(os.path.join(ydir, name)))
        if st != "present":
            bad_marker.append(f"{lang}/{stem}/{name}={st}")
    st, cur, got = aligned_marker_status(parent)
    if st != "present":
        bad_marker.append(f"{lang}/{stem}.md(부모)={st}")
    if bad_marker:
        bad(f"(7) {lang} pre-align marker 가 자기 outline 과 맞지 않음",
            *bad_marker[:5],
            "연도 파일에 유효한 marker 를 찍는 것은 'pre-align 이 이 구조를 "
            "검증했다' 는 주장이다 — 부모가 stale 이면 그 주장이 거짓이 된다")
    else:
        ok(f"(7) {lang} 연도 파일 {len(includes)}개 + 부모 marker 전부 유효")

# (8) include-markdown 선례 보고
body = read(f"{tmp}/pr_body.md")
if "include-markdown" in body and re.search(r"선례", body):
    ok("(8) PR 본문이 include-markdown 선례를 보고")
else:
    bad("(8) PR 본문에 include-markdown 선례 보고가 없음",
        "플러그인은 mkdocs 부모 repo 설정이라, 선례 0 이면 지시자가 raw text 로 배포된다")

# (9) 렌더 검증 댓글 — 왕복 검증이 볼 수 없는 축.
comments = read(f"{tmp}/pr_comments.md")
if "<!-- split-docs:verify -->" not in comments:
    bad("(9a) 렌더 검증 댓글(split-docs:verify)이 PR 에 없음",
        "include 가 실제로 본문을 조립하는지는 소스 왕복 검증이 볼 수 없다")
elif "렌더 결과가 분리 전과 동일합니다" not in comments:
    # '차이' 나 '확인 실패' 로 끝난 경우 — 어느 쪽이든 사람이 봐야 한다.
    bad("(9a) 렌더 검증이 '동일' 로 끝나지 않음",
        *[l for l in comments.splitlines()
          if l.startswith("⚠️") or l.startswith("❌") or "| ❌" in l or "| ⚠️" in l][:4])
else:
    # 비교한 페이지가 언어 수만큼 있어야 한다 — 0개를 비교하고 초록으로
    # 끝나는 것이 이 검증의 유일한 조용한 실패 모드다.
    n_ok = len(re.findall(r"\| ✅ 동일 \|", comments))
    if n_ok >= len(langs):
        ok(f"(9a) 렌더 검증 댓글: 부모 문서 {n_ok}개가 분리 전과 동일")
    else:
        bad(f"(9a) 렌더 검증이 {n_ok}개만 비교함 (언어 {len(langs)}개 기대)",
            "0개를 비교하고 초록으로 끝나는 것이 이 검증의 유일한 조용한 실패 모드다")

if "/pr-validation/new?" in body and "site_a=" in body and "site_b=" in body:
    ok("(9b) PR 본문에 렌더 비교(PR 검증) 딥링크 — base↔head 프리필")
else:
    bad("(9b) PR 본문에 렌더 비교 딥링크가 없음",
        "링크가 없으면 리뷰어가 두 URL 을 직접 타이핑해야 한다")

raise SystemExit(rc)
PY

# ── 5) 결과 ──────────────────────────────────────────────────────────────
echo
echo "[5/6] 결과"
if (( fails == 0 )); then
  echo "SPLIT_DOCS: OK"
  echo "  연도별 분리가 내용/anchor 를 보존하고 부모를 include 로 대체 (PR: $split_pr_url)"
  echo
  echo "[6/6] cleanup"
  exit 0
fi
echo "SPLIT_DOCS: FAIL"
echo "  $fails 개 규칙 실패 — 로그: $LOG / dry-run: $DRYLOG"
echo "  PR 은 보존합니다: $split_pr_url"
KEEP=1
exit 1
