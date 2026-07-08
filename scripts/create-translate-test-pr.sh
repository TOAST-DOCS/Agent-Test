#!/usr/bin/env bash
#
# 번역 파이프라인(특히 heading 보존 / anchor-id 브리지) 테스트용 PR 생성기.
#
# 기존 방식은 archive/translate/{ko,en,ja}/ 스냅샷을 통째로 복사했지만, 이제는
# **ko/ 문서만** 여러 형태로 프로그램적으로 변형합니다 (en/ja 는 alpha 그대로
# 두어 "ko 가 앞서고 en/ja 가 뒤처진" drift 상태를 만듦 → anchor-id 브리지가
# 기존 en/ja heading 을 보존하는지 검증할 수 있는 데이터).
#
# 파일별로 서로 다른 변경 유형을 적용해 한 PR 에 다양한 케이스를 담습니다:
#   overview.md          : 신규 섹션 추가(③) + 기존 섹션 본문 수정(heading 유지)
#   console-guide.md     : 기존 heading '제목'만 변경(④, id 유지)
#   component-guide.md   : 기존 섹션에 문단 추가(heading 유지, 본문 증가)
#   public-api.md        : 표(table) 행 1개 내용 수정
#   kernel-guide.md      : 섹션 1개 삭제(en 엔 남아있는 extra 유발)
#   troubleshooting-guide.md : 변경 없음(대조군 — en/ja 무변경이어야 정상)
#
# 각 변형은 `<a id>` 와 `{ #id }` 를 보존/부여해, "기존 id 는 그대로, 신규만
# 부여" 규칙을 검증할 수 있게 합니다.
#
# 흐름:
#   1) alpha 최신화 → 새 브랜치(translate-test/YYYYMMDD-HHMMSS, --branch override)
#   2) ko/ 문서들에 변형 적용
#   3) commit → push → gh pr create (base: alpha)
#
# Usage:
#   scripts/create-translate-test-pr.sh
#   scripts/create-translate-test-pr.sh --branch translate-test/my-name
#   scripts/create-translate-test-pr.sh --dry-run        # 변형 diff 만 보고 종료(브랜치/PR 없음)
#   scripts/create-translate-test-pr.sh --title "..." --body "..."
#
# 의존성: git, gh(로그인), python3
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_BRANCH="alpha"

BRANCH=""; TITLE=""; BODY=""; DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2 ;;
    --title)  TITLE="$2";  shift 2 ;;
    --body)   BODY="$2";   shift 2 ;;
    --dry-run|-n) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

cd "$REPO_ROOT"

# ── ko/ 변형기 (파이썬) ────────────────────────────────────────────────────
# 인자: <mutation> <ko-file-path>. 파일을 in-place 로 수정.
mutate_ko() {
  local mutation="$1" path="$2"
  python3 - "$mutation" "$path" <<'PY'
import re, sys
mutation, path = sys.argv[1], sys.argv[2]
_raw = open(path, "rb").read()
_crlf = _raw.count(b"\r\n"); _lf = _raw.count(b"\n") - _crlf
_uniform_crlf = _crlf > 0 and _lf == 0     # 파일이 균일 CRLF 인지
text = _raw.decode("utf-8").replace("\r\n", "\n")   # LF 로 정규화해 처리

HEAD = re.compile(r'^(#{2,4})[ \t]+(.*)$')
def is_anchor(l): return bool(re.match(r'^\s*<a\s+id=', l))
def is_table_row(l): return l.lstrip().startswith('|')

lines = text.split("\n")
# strip a trailing '' from split if text ended with newline
def join(ls): return "\n".join(ls)

def first_heading_idx(ls):
    for i, l in enumerate(ls):
        if HEAD.match(l.rstrip("\r")):
            return i
    return None

if mutation == "add_section":
    # 문서 끝에 신규 섹션(anchor + { #id } + 본문) 추가 — 규칙 ③
    block = [
        "",
        '<a id="test-added-section"></a>',
        "## 테스트용 추가 섹션 { #test-added-section }",
        "",
        "이 섹션은 번역 파이프라인 테스트를 위해 새로 추가한 섹션입니다. "
        "신규 섹션이 번역되고 ko/en/ja 에 동일한 anchor id 가 부여되는지 확인합니다.",
        "",
    ]
    if not text.endswith("\n"):
        lines.append("")
    lines += block
    out = join(lines)

elif mutation == "edit_body":
    # 첫 번째 heading '뒤' 첫 산문 문단에 문장 추가 — heading 유지, 본문만 변경
    hi = first_heading_idx(lines)
    done = False
    j = (hi + 1) if hi is not None else 0
    while j < len(lines):
        s = lines[j].strip()
        if s and not HEAD.match(lines[j].rstrip("\r")) and not is_anchor(lines[j]) \
           and not is_table_row(lines[j]) and not s.startswith(("{", "<!--", "```", "|", "-", "*", ">")):
            lines[j] = lines[j].rstrip("\r") + " (본문 수정 테스트: 이 문장은 번역 재실행 시 반영되어야 합니다.)"
            done = True
            break
        j += 1
    if not done:
        raise SystemExit(f"edit_body: no prose paragraph found in {path}")
    out = join(lines)

elif mutation == "rename_heading":
    # 첫 h2 제목만 변경, `{ #id }` 와 <a id> 는 그대로 — 규칙 ④
    changed = False
    for i, l in enumerate(lines):
        m = re.match(r'^(##)[ \t]+(.*)$', l.rstrip("\r"))
        if m:
            body = m.group(2)
            attr = ""
            am = re.search(r'(\s*\{\s*#[^}]+\})\s*$', body)
            if am:
                attr = am.group(1); body = body[:am.start()].rstrip()
            lines[i] = f"## {body} 상세 안내{attr}"   # 제목 텍스트만 변경
            changed = True
            break
    if not changed:
        raise SystemExit(f"rename_heading: no h2 found in {path}")
    out = join(lines)

elif mutation == "add_paragraph":
    # 첫 섹션 heading 바로 아래에 새 문단 삽입 — 본문 블록 증가
    hi = first_heading_idx(lines)
    if hi is None:
        raise SystemExit(f"add_paragraph: no heading in {path}")
    ins = ["", "이 문단은 기존 섹션에 추가된 테스트 문단입니다. 기존 heading 은 그대로 유지되어야 합니다.", ""]
    lines[hi+1:hi+1] = ins
    out = join(lines)

elif mutation == "change_table_row":
    # 첫 표의 첫 데이터 행 셀 내용 수정 (없으면 실패)
    changed = False
    i = 0
    while i < len(lines) - 2:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            # i=header, i+1=separator, i+2.. = data rows
            k = i + 2
            if k < len(lines) and is_table_row(lines[k]):
                lines[k] = lines[k].rstrip("\r") + " (행 수정 테스트)"
                changed = True
                break
        i += 1
    if not changed:
        raise SystemExit(f"change_table_row: no table with a data row in {path}")
    out = join(lines)

elif mutation == "remove_section":
    # 마지막에서 두 번째 heading 섹션 하나 제거(anchor 라인 포함) — extra_in_target 유발
    heads = [i for i, l in enumerate(lines) if HEAD.match(l.rstrip("\r"))]
    if len(heads) < 3:
        raise SystemExit(f"remove_section: not enough sections in {path}")
    start = heads[-2]
    # anchor 라인이 heading 바로 위면 함께 제거
    s = start
    if s - 2 >= 0 and is_anchor(lines[s-1]) is False and is_anchor(lines[s-2]):
        s = s - 2
    elif s - 1 >= 0 and is_anchor(lines[s-1]):
        s = s - 1
    end = heads[-1]
    # heading 바로 위 anchor 라인 앞까지 제거
    e = end
    if e - 1 >= 0 and is_anchor(lines[e-1]):
        e = e - 1
        if e - 1 >= 0 and lines[e-1].strip() == "":
            e = e - 1
    del lines[s:e]
    out = join(lines)

elif mutation == "noop":
    out = text
else:
    raise SystemExit(f"unknown mutation: {mutation}")

if out != text:
    if _uniform_crlf:                       # 원본 EOL(CRLF) 복원 → 전체 파일 EOL 뒤집힘 방지
        out = out.replace("\n", "\r\n")
    open(path, "wb").write(out.encode("utf-8"))
    print(f"  [mutated:{mutation}] {path}")
else:
    print(f"  [noop:{mutation}] {path}")
PY
}

# 파일 → 변형 매핑 (다양한 케이스)
declare -a PLAN=(
  "add_section|ko/overview.md"
  "edit_body|ko/overview.md"
  "rename_heading|ko/console-guide.md"
  "add_paragraph|ko/component-guide.md"
  "change_table_row|ko/public-api.md"
  "remove_section|ko/kernel-guide.md"
  "noop|ko/troubleshooting-guide.md"
)

if [[ -z "$BRANCH" ]]; then
  BRANCH="translate-test/$(date +%Y%m%d-%H%M%S)"
fi
echo "base branch : $BASE_BRANCH"
echo "new branch  : $BRANCH"
echo "변형 계획:"
for p in "${PLAN[@]}"; do echo "  ${p%%|*}  →  ${p#*|}"; done
echo

if (( DRY_RUN )); then
  # 임시로 alpha 원본을 받아 변형 diff 만 보여줌 (작업 트리 건드리지 않음)
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  git fetch -q origin "$BASE_BRANCH"
  for p in "${PLAN[@]}"; do
    mut="${p%%|*}"; rel="${p#*|}"
    git show "origin/$BASE_BRANCH:$rel" > "$tmp/orig" 2>/dev/null || { echo "  (skip, not on alpha: $rel)"; continue; }
    cp "$tmp/orig" "$tmp/new"
    mutate_ko "$mut" "$tmp/new" >/dev/null
    echo "===== $rel ($mut) ====="
    diff -u "$tmp/orig" "$tmp/new" | sed -n '1,40p' || true
  done
  echo; echo "(dry-run) 종료."
  exit 0
fi

# tracked 변경 있으면 중단
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: tracked 파일에 커밋되지 않은 변경사항이 있습니다." >&2
  git status --short >&2; exit 1
fi

git fetch origin "$BASE_BRANCH"
git checkout -B "$BRANCH" "origin/$BASE_BRANCH"

for p in "${PLAN[@]}"; do
  mut="${p%%|*}"; rel="${p#*|}"
  [[ -f "$rel" ]] || { echo "  (skip, missing: $rel)"; continue; }
  mutate_ko "$mut" "$rel"
  git add "$rel"
done

if git diff --cached --quiet; then
  echo "변경사항 없음. 종료."; exit 0
fi

: "${TITLE:=Translate test: varied ko/ mutations (heading-preserve/anchor-id)}"
: "${BODY:=ko/ 문서를 신규 섹션 추가·본문 수정·heading 제목 변경·문단 추가·표 행 수정·섹션 삭제 등 다양한 형태로 변경한 번역 테스트 PR. en/ja 는 alpha 그대로(=drift) 두어 anchor-id 브리지의 기존 heading 보존을 검증합니다.}"

git commit -m "$TITLE"
git push -u origin "$BRANCH"
gh pr create --base "$BASE_BRANCH" --head "$BRANCH" --title "$TITLE" --body "$BODY"
