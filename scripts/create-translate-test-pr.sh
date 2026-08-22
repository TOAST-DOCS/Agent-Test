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
#   console-guide.md     : 기존 heading '제목'만 변경(④, id 유지) + 문단 삭제
#   component-guide.md   : 기존 섹션에 문단 추가 + 신규 하위 섹션(###) 삽입
#   public-api.md        : 표 행 1개 내용 수정 + 표 행 추가 + 신규 API endpoint 추가
#                          (반복 `#### 요청` heading + 새 anchor id 를 가진 표
#                          — cloud-translate PR #260 회귀: heading text 기반
#                          skip-full-table 판정이 새 anchor 섹션을 pre-existing
#                          으로 오판해 파일 스킵되는 케이스)
#   kernel-guide.md      : 섹션 1개 삭제(en 엔 남아있는 extra 유발) + 코드펜스 내용 수정
#   feature-matrix.md    : 표 헤더 셀 수정 + 두 번째 표 행 삭제 + h3 제목 변경 + 목록 항목 수정
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

BRANCH=""; TITLE=""; BODY=""; DRY_RUN=0; PLAN_NAME="round1"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2 ;;
    --base-branch) BASE_BRANCH="$2"; shift 2 ;;   # 기본 alpha, e2e 세션 브랜치로 override
    --title)  TITLE="$2";  shift 2 ;;
    --body)   BODY="$2";   shift 2 ;;
    --plan)   PLAN_NAME="$2"; shift 2 ;;   # round1|round2|row-drop-repro|table-suite|markup-churn
    --dry-run|-n) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

cd "$REPO_ROOT"
# e2e 산출물 PR 에 'e2e' 라벨 (사람이 만든 PR 과 구분)
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"


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

elif mutation == "markup_fence_info":
    # 코스메틱 마크업 churn ①: 여는 코드펜스에 info string 부여 (``` -> ```bash).
    # 펜스 한 줄이 바뀌면 block granularity 에서 그 유닛 전체가 "변경됨" 이 되어
    # 번역 부하가 부풀지만, 실제로 번역할 내용은 없다.
    out_lines, opened, n = [], False, 0
    for l in lines:
        s = l.rstrip("\r")
        if re.match(r'^\s*(```|~~~)', s):
            if not opened:
                opened = True
                if re.match(r'^\s*```\s*$', s):
                    s = s.rstrip() + "bash"
                    n += 1
            else:
                opened = False
        out_lines.append(s)
    if not n:
        raise SystemExit(f"markup_fence_info: no bare opening fence in {path}")
    out = join(out_lines)

elif mutation == "markup_br_slash":
    # 코스메틱 마크업 churn ②: <br> -> <br/> 전면 치환. 표 행 안에 들어있어서
    # 한 글자 차이로 긴 행 전체가 재번역 대상이 된다 (실측 기여도 1위).
    if "<br>" not in text:
        raise SystemExit(f"markup_br_slash: no <br> in {path}")
    out = text.replace("<br>", "<br/>")

elif mutation == "markup_jinja_ws":
    # 코스메틱 마크업 churn ④: Jinja/mkdocs 템플릿 태그의 whitespace 제어를
    # 여는 쪽으로 이동 ({% if x -%} -> {%- if x %}). Storage-Online-NAS#92 형태로,
    # 변경된 28줄 중 26줄이 이 이동이었다. 태그는 제어 문법이라 번역할 내용이
    # 0인데도 유닛 전체를 "변경됨" 으로 만들어 부하를 부풀린다.
    # 태그 개수는 보존되는 in-place 수정이어야 cloud-translate 의 M4 미러링
    # 대상이 된다 (삽입/삭제는 그쪽에서 의도적으로 bail).
    n = 0
    def _move_ws(m):
        global n
        raw = m.group(0)
        inner = raw[2:-2].strip().lstrip("-").rstrip("-").strip()
        out = "{%- " + inner + " %}"
        if out != raw:
            n += 1
        return out
    out = re.sub(r"\{%.*?%\}", _move_ws, text, flags=re.DOTALL)
    if not n:
        raise SystemExit(f"markup_jinja_ws: no jinja tag to move in {path}")

elif mutation == "markup_heading_blank":
    # 코스메틱 마크업 churn ③: 헤딩 바로 뒤 빈 줄을 토글. block granularity 에서
    # 헤딩+본문 한 유닛이 두 유닛으로 쪼개지거나 합쳐져 유닛 정렬이 통째로
    # 어긋난다. 방향은 문서 상태에 맞춰 정한다 — 빈 줄이 이미 있으면 제거,
    # 없으면 삽입. (코드 펜스 안의 '#' 줄은 헤딩이 아니므로 제외.)
    def _heads(ls):
        out, fence = [], False
        for i, l in enumerate(ls):
            if re.match(r'^\s*(```|~~~)', l.rstrip("\r")):
                fence = not fence
                continue
            if not fence and re.match(r'^#{1,6} \S', l.rstrip("\r")):
                out.append(i)
        return out
    heads = _heads(lines)
    if not heads:
        raise SystemExit(f"markup_heading_blank: no heading outside fences in {path}")
    with_blank = [i for i in heads if i + 1 < len(lines) and not lines[i + 1].strip()]
    n = 0
    if with_blank:                       # 제거 방향
        for i in sorted(with_blank, reverse=True):
            del lines[i + 1]
            n += 1
    else:                                # 삽입 방향
        for i in sorted(heads, reverse=True):
            if i + 1 < len(lines) and lines[i + 1].strip():
                lines.insert(i + 1, "")
                n += 1
    if not n:
        raise SystemExit(f"markup_heading_blank: nothing to toggle in {path}")
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
    # 첫 표의 첫 데이터 행 셀 내용 수정 (없으면 실패).
    # 주의: 마지막 파이프 '뒤'에 붙이면 ko 자체가 헤더보다 셀이 많은 malformed
    # 행이 되어 step 17 검사 (6)(컬럼 정합)에 오탐으로 걸린다 — 마지막 셀 '안'에
    # 삽입해 셀 개수를 보존한다.
    changed = False
    i = 0
    while i < len(lines) - 2:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            # i=header, i+1=separator, i+2.. = data rows
            k = i + 2
            if k < len(lines) and is_table_row(lines[k]):
                row = lines[k].rstrip("\r")
                if row.rstrip().endswith("|"):
                    lines[k] = row.rstrip()[:-1].rstrip() + " (행 수정 테스트) |"
                else:
                    lines[k] = row + " (행 수정 테스트)"
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

elif mutation == "remove_paragraph":
    # 첫 heading 뒤 첫 산문 문단(연속 비공백 블록)을 통째로 삭제 — 문단 감소
    hi = first_heading_idx(lines)
    j = (hi + 1) if hi is not None else 0
    start = None
    while j < len(lines):
        s = lines[j].strip()
        if s and not HEAD.match(lines[j].rstrip("\r")) and not is_anchor(lines[j]) \
           and not is_table_row(lines[j]) and not s.startswith(("{", "<!--", "```", "|", "-", "*", ">", "!")):
            start = j
            break
        j += 1
    if start is None:
        raise SystemExit(f"remove_paragraph: no prose paragraph found in {path}")
    end = start
    while end < len(lines) and lines[end].strip():
        end += 1
    # 뒤따르는 빈 줄 하나까지 제거해 이중 공백 방지
    if end < len(lines) and lines[end].strip() == "":
        end += 1
    del lines[start:end]
    out = join(lines)

elif mutation == "add_subsection":
    # 두 번째 h2 직전에 신규 h3(anchor + { #id } + 본문) 삽입 — 첫 섹션의 하위로 들어감
    h2s = [i for i, l in enumerate(lines) if re.match(r'^##[ \t]', l.rstrip("\r"))]
    if len(h2s) < 2:
        raise SystemExit(f"add_subsection: needs >=2 h2 in {path}")
    at = h2s[1]
    # heading 바로 위 anchor 라인이 있으면 그 앞에 삽입
    if at - 1 >= 0 and is_anchor(lines[at-1]):
        at -= 1
    ins = [
        '<a id="test-added-subsection"></a>',
        "### 테스트용 하위 섹션 { #test-added-subsection }",
        "",
        "이 하위 섹션은 번역 파이프라인 테스트를 위해 추가됐습니다. "
        "신규 h3 가 번역되고 세 언어에 동일한 anchor id 가 부여되는지 확인합니다.",
        "",
    ]
    lines[at:at] = ins
    out = join(lines)

elif mutation == "add_section_no_id":
    # 문서 끝에 anchor id 없는 신규 h2 추가 — 번역 잡이 세 언어에 anchor id 를 자동 할당해야 함
    block = [
        "",
        "## 자동 ID 할당 검증용 신규 섹션",
        "",
        "이 섹션은 번역 파이프라인의 anchor-id 자동 할당을 검증하기 위한 신규 섹션입니다. "
        "ko 변경 시 anchor id 를 붙이지 않았고, 번역 잡이 ko/en/ja 세 언어에 동일한 id 를 부여해야 합니다.",
        "",
    ]
    if not text.endswith("\n"):
        lines.append("")
    lines += block
    out = join(lines)

elif mutation == "add_subsection_no_id":
    # 두 번째 h2 직전에 anchor id 없는 신규 h3 삽입 — 번역 잡이 세 언어에 anchor id 를 자동 할당해야 함
    h2s = [i for i, l in enumerate(lines) if re.match(r'^##[ \t]', l.rstrip("\r"))]
    if len(h2s) < 2:
        raise SystemExit(f"add_subsection_no_id: needs >=2 h2 in {path}")
    at = h2s[1]
    if at - 1 >= 0 and is_anchor(lines[at-1]):
        at -= 1
    ins = [
        "### 자동 ID 할당 검증용 신규 하위 섹션",
        "",
        "이 하위 섹션은 번역 파이프라인의 anchor-id 자동 할당을 검증하기 위한 신규 h3 입니다. "
        "ko 변경 시 anchor id 를 붙이지 않았고, 번역 잡이 ko/en/ja 세 언어에 동일한 id 를 부여해야 합니다.",
        "",
    ]
    lines[at:at] = ins
    out = join(lines)

elif mutation == "add_table_row":
    # 첫 표의 마지막 데이터 행 뒤에 새 행 추가 — 컬럼 수는 헤더에 맞춤
    changed = False
    i = 0
    while i < len(lines) - 2:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            ncol = lines[i].strip().strip('|').count('|') + 1
            k = i + 2
            while k < len(lines) and is_table_row(lines[k]):
                k += 1
            cells = ["TEST-ROW"] + ["(신규 행 테스트)"] * (ncol - 1)
            lines[k:k] = ["| " + " | ".join(cells) + " |"]
            changed = True
            break
        i += 1
    if not changed:
        raise SystemExit(f"add_table_row: no table found in {path}")
    out = join(lines)

elif mutation == "edit_code_block":
    # 첫 fenced code block 안에 줄 추가 — 코드는 번역 없이 그대로 복사되어야 함
    changed = False
    for i, l in enumerate(lines):
        if l.strip().startswith("```"):
            lines[i+1:i+1] = ["# code-edit-test: this line must be copied verbatim"]
            changed = True
            break
    if not changed:
        raise SystemExit(f"edit_code_block: no fenced code block in {path}")
    out = join(lines)

elif mutation == "edit_table_header":
    # 첫 표 헤더의 마지막 셀 텍스트 수정 (separator/데이터 행은 유지)
    changed = False
    i = 0
    while i < len(lines) - 1:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
            cells[-1] = cells[-1] + " (수정)"
            lines[i] = "| " + " | ".join(cells) + " |"
            changed = True
            break
        i += 1
    if not changed:
        raise SystemExit(f"edit_table_header: no table found in {path}")
    out = join(lines)

elif mutation == "remove_table_row":
    # 두 번째 표의 마지막 데이터 행 삭제 (표가 1개면 첫 표에서)
    tables = []
    i = 0
    while i < len(lines) - 2:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            k = i + 2
            while k < len(lines) and is_table_row(lines[k]):
                k += 1
            if k > i + 2:
                tables.append((i, k))     # (header idx, end-exclusive)
            i = k
        else:
            i += 1
    if not tables:
        raise SystemExit(f"remove_table_row: no table with data rows in {path}")
    _, end = tables[1] if len(tables) > 1 else tables[0]
    del lines[end-1]
    out = join(lines)

elif mutation == "rename_h3":
    # 첫 h3 제목 텍스트만 변경, `{ #id }` 와 <a id> 는 그대로
    changed = False
    for i, l in enumerate(lines):
        m = re.match(r'^(###)[ \t]+(.*)$', l.rstrip("\r"))
        if m and not l.rstrip("\r").startswith("####"):
            body = m.group(2)
            attr = ""
            am = re.search(r'(\s*\{\s*#[^}]+\})\s*$', body)
            if am:
                attr = am.group(1); body = body[:am.start()].rstrip()
            lines[i] = f"### {body} 및 상세{attr}"
            changed = True
            break
    if not changed:
        raise SystemExit(f"rename_h3: no h3 found in {path}")
    out = join(lines)

elif mutation == "edit_list_item":
    # 첫 bullet list 의 첫 항목 텍스트 수정
    changed = False
    for i, l in enumerate(lines):
        if re.match(r'^\s*-\s+\S', l.rstrip("\r")):
            lines[i] = lines[i].rstrip("\r") + " (목록 수정 테스트)"
            changed = True
            break
    if not changed:
        raise SystemExit(f"edit_list_item: no bullet list in {path}")
    out = join(lines)

elif mutation == "remove_added_table_row":
    # 1라운드 add_table_row 가 추가한 "TEST-ROW" 행을 삭제 — 추가된 행의 회수 케이스
    changed = False
    for i, l in enumerate(lines):
        if is_table_row(l) and "TEST-ROW" in l:
            del lines[i]
            changed = True
            break
    if not changed:
        raise SystemExit(f"remove_added_table_row: 'TEST-ROW' row not found in {path} "
                         f"(1라운드 PR 이 alpha 에 머지되어 있어야 합니다)")
    out = join(lines)

elif mutation == "remove_added_section":
    # 1라운드가 추가한 `test-added-section` 섹션(anchor+heading+본문)을 삭제 —
    # "이전 증분 번역이 만든 섹션을 다음 라운드가 지우는" 2세대 drift 케이스
    aid = "test-added-section"
    anchor_i = None
    for i, l in enumerate(lines):
        if f'id="{aid}"' in l:                      # <a id="..."> 라인
            anchor_i = i
            break
    if anchor_i is None:                            # attr 만 있는 경우 heading 으로 탐색
        for i, l in enumerate(lines):
            if HEAD.match(l.rstrip("\r")) and f'#{aid}' in l:
                anchor_i = i
                break
    if anchor_i is None:
        raise SystemExit(f"remove_added_section: '{aid}' not found in {path} "
                         f"(1라운드 PR 이 alpha 에 머지되어 있어야 합니다)")
    start = anchor_i
    if start > 0 and lines[start-1].strip() == "":  # 앞 빈 줄도 함께 제거
        start -= 1
    end = anchor_i + 1
    if end < len(lines) and HEAD.match(lines[end].rstrip("\r")):
        end += 1                                    # 자기 heading 스킵
    while end < len(lines):                         # 본문: 다음 heading/anchor 직전까지
        if HEAD.match(lines[end].rstrip("\r")) or is_anchor(lines[end]):
            break
        end += 1
    del lines[start:end]
    out = join(lines)

elif mutation == "add_repeated_heading_with_table":
    # 문서 끝에 새 API endpoint 를 append: ### 신규 API + #### 요청 + 표 +
    # #### 응답 + 표. `#### 요청`/`#### 응답` heading text 는 문서 내에서 이미
    # 수십 번 반복되지만 anchor id 는 새로 부여 (test-added-request/response).
    # PR #260 회귀: 반복 heading 오탐 방지 — base_table_heads (heading text set)
    # 은 `#### 요청` 을 이미 담고 있어서 새 anchor id 를 가진 이 새 섹션의 표를
    # pre-existing 표로 오판 → skip-full-table 가드가 파일을 스킵.
    # base_table_by_anchor (anchor 기반) 는 새 anchor 를 못 찾으므로 correctly
    # 새 섹션으로 인식 → 번역 진행. 결과적으로 en/ja 에도 이 새 섹션 + 표가
    # 나타나야 한다.
    block = [
        "",
        '<a id="test-added-endpoint"></a>',
        "### 테스트용 신규 엔드포인트 { #test-added-endpoint }",
        "",
        "```",
        "POST /v2/{tenantId}/test-added-endpoint",
        "X-Auth-Token: {tokenId}",
        "```",
        "",
        '<a id="test-added-request"></a>',
        "#### 요청 { #test-added-request }",
        "",
        "| 이름 | 종류 | 형식 | 필수 | 설명 |",
        "|---|---|---|---|---|",
        "| tenantId | URL | String | O | 테넌트 ID |",
        "| tokenId | Header | String | O | 토큰 ID |",
        "| name | Body | String | O | 엔드포인트 이름 |",
        "",
        '<a id="test-added-response"></a>',
        "#### 응답 { #test-added-response }",
        "",
        "| 이름 | 종류 | 형식 | 설명 |",
        "|---|---|---|---|",
        "| endpoint | Body | Object | 생성된 엔드포인트 객체 |",
        "| endpoint.id | Body | String | 엔드포인트 ID |",
        "| endpoint.name | Body | String | 엔드포인트 이름 |",
        "",
    ]
    if not text.endswith("\n"):
        lines.append("")
    lines += block
    out = join(lines)

elif mutation == "bump_row_date":
    # 첫 표의 '두 번째' 데이터 행에서 날짜(YYYY-MM-DD)를 하루 뒤로 — cosmetic 수정.
    # release-notes.md 픽스처에서 두 번째 행(2.4.1)은 en/ja 에 없는 stale 행이므로,
    # "en/ja 가 결여한 행을 ko diff 는 '수정' 으로만 보는" CK 인시던트(cloud-translate
    # PR #283) 원형을 재현한다.
    import datetime as _dt
    changed = False
    i = 0
    while i < len(lines) - 3:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            k = i + 3          # header, separator, 1행 다음 = 두 번째 데이터 행
            if k < len(lines) and is_table_row(lines[k]):
                m = re.search(r'\d{4}-\d{2}-\d{2}', lines[k])
                if m:
                    d = _dt.date.fromisoformat(m.group(0)) + _dt.timedelta(days=1)
                    lines[k] = lines[k][:m.start()] + d.isoformat() + lines[k][m.end():]
                    changed = True
            break
        i += 1
    if not changed:
        raise SystemExit(f"bump_row_date: no date in 2nd data row of first table in {path}")
    out = join(lines)

elif mutation == "insert_table_row_middle":
    # 첫 표의 첫 데이터 행 '뒤'에 신규 행 삽입 — 끝 추가(add_table_row)와 구분되는
    # 중간 삽입 케이스. 컬럼 수는 헤더에 맞춤.
    changed = False
    i = 0
    while i < len(lines) - 2:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            ncol = lines[i].strip().strip('|').count('|') + 1
            k = i + 2
            if k < len(lines) and is_table_row(lines[k]):
                cells = ["중간 삽입 테스트"] + ["신규 중간 행입니다. 번역되어야 합니다."] * (ncol - 1)
                lines[k+1:k+1] = ["| " + " | ".join(cells) + " |"]
                changed = True
            break
        i += 1
    if not changed:
        raise SystemExit(f"insert_table_row_middle: no table with a data row in {path}")
    out = join(lines)

elif mutation == "insert_keyed_table_row":
    # 첫 표의 3번째 데이터 행 '뒤'(행이 3개 미만이면 마지막 행 뒤)에 식별자
    # 첫 셀(숫자 포함 단일 토큰 = cloud-translate `_row_key` 형태)을 가진 신규
    # 행을 삽입 — keyed 표의 중간 삽입 케이스. stale 표(version-guide)에
    # 적용하면 "결여 행 backfill + 신규 행 삽입" 복합 시나리오가 된다.
    changed = False
    i = 0
    while i < len(lines) - 2:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            ncol = lines[i].strip().strip('|').count('|') + 1
            k = i + 2
            rows = 0
            while k < len(lines) and is_table_row(lines[k]) and rows < 3:
                rows += 1
                k += 1
            cells = ["1.202603.9", "2026-03-28",
                     "중간에 삽입된 신규 버전입니다. 번역되어야 합니다."]
            cells = (cells + ["(신규)"] * ncol)[:ncol]
            lines[k:k] = ["| " + " | ".join(cells) + " |"]
            changed = True
            break
        i += 1
    if not changed:
        raise SystemExit(f"insert_keyed_table_row: no table found in {path}")
    out = join(lines)

elif mutation == "swap_table_rows":
    # 첫 표의 마지막 두 데이터 행의 순서를 서로 교환 — 행 순서 변경이 en/ja 에
    # 그대로 반영되는지 검증 (내용 변경 없음, 순서만).
    changed = False
    i = 0
    while i < len(lines) - 3:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            k = i + 2
            while k < len(lines) and is_table_row(lines[k]):
                k += 1
            if k - (i + 2) >= 2:
                lines[k-2], lines[k-1] = lines[k-1], lines[k-2]
                changed = True
            break
        i += 1
    if not changed:
        raise SystemExit(f"swap_table_rows: first table needs >=2 data rows in {path}")
    out = join(lines)

elif mutation == "add_new_table":
    # 문서 끝에 신규 섹션 + 신규 표 추가 — "표 자체가 새로 생기는" 케이스
    # (kernel-guide 처럼 표가 없던 문서라면 표 개수 0→1 검증까지 겸함).
    block = [
        "",
        '<a id="test-added-table"></a>',
        "## 테스트용 신규 표 섹션 { #test-added-table }",
        "",
        "이 섹션은 표 번역 검증을 위해 새로 추가됐습니다. 아래 표의 머리글과 셀 텍스트가 모두 번역되어야 합니다.",
        "",
        "| 항목 | 설명 | 기본값 |",
        "|---|---|---|",
        "| 최대 노드 수 | 하나의 노드 풀에 생성할 수 있는 노드의 최대 개수입니다. | 10 |",
        "| 자동 확장 | 부하에 따라 노드 수를 자동으로 조정합니다. | 사용 안 함 |",
        "| 점검 주기 | 노드 상태를 점검하는 주기입니다. | 5분 |",
        "",
    ]
    if not text.endswith("\n"):
        lines.append("")
    lines += block
    out = join(lines)

elif mutation == "edit_row_desc_cell":
    # 첫 표의 '두 번째' 데이터 행 마지막 셀(설명) 안에 문장 추가 — 셀 개수 불변.
    # spec-guide.md 픽스처(결함 D): en/ja 는 stale-ify 로 'Not Null' 컬럼이 제거된
    # 3컬럼 상태이므로, 이 행의 재번역이 ko 스키마(4셀)로 emit 되면 3컬럼 표에
    # 4셀 행이 섞이는 컬럼 혼재(notification-hub PR #209 지적 4번)가 재현된다.
    changed = False
    i = 0
    while i < len(lines) - 3:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            k = i + 3          # header, separator, 1행 다음 = 두 번째 데이터 행
            if k < len(lines) and is_table_row(lines[k]) and lines[k].rstrip().endswith("|"):
                body = lines[k].rstrip()[:-1].rstrip()
                lines[k] = body + " 이름은 프로젝트 안에서 고유해야 합니다. |"
                changed = True
            break
        i += 1
    if not changed:
        raise SystemExit(f"edit_row_desc_cell: no 2nd data row in first table of {path}")
    out = join(lines)

elif mutation == "add_table_column":
    # 첫 표의 모든 라인(헤더·구분선·데이터) 끝에 셀 1개 추가 — "ko PR 자체가
    # 표 컬럼을 추가" 하는 케이스 (cloud-translate --table-column-ops 검증).
    # 값은 언어 무관(O)과 번역 대상(한글)을 섞어 미러링의 복사/번역 두 경로를
    # 모두 exercise 한다. 기대: en/ja 는 기존 셀 byte 보존 + 새 컬럼만 추가.
    changed = False
    i = 0
    while i < len(lines) - 2:
        if is_table_row(lines[i]) and re.match(r'^\s*\|[\s\-:|]+\|\s*$', lines[i+1]):
            j = i
            row_idx = 0
            while j < len(lines) and is_table_row(lines[j]):
                s2 = lines[j].rstrip("\r")
                if not s2.rstrip().endswith("|"):
                    raise SystemExit(f"add_table_column: row without trailing pipe in {path}")
                if j == i:
                    cell = "지원 여부"
                elif j == i + 1:
                    cell = "---"
                else:
                    cell = "O" if row_idx % 2 == 0 else "부분 지원"
                    row_idx += 1
                lines[j] = s2 + f" {cell} |"
                changed = True
                j += 1
            break
        i += 1
    if not changed:
        raise SystemExit(f"add_table_column: no table in {path}")
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
#
# round1: 정렬 직후의 alpha 에 적용하는 1차 변형 (기본)
# round2: round1 의 ko 변경·번역 PR 이 alpha 에 머지된 "2세대" 상태에 적용.
#         1라운드 산출물을 다시 수정/삭제해 증분 번역의 반복 실행을 검증:
#           overview        : 1R 이 추가한 섹션 삭제 + 새 문단 추가
#           console-guide   : heading 제목 재변경 (같은 id 로 2번째 rename)
#           component-guide : 1R 이 추가한 문단(첫 문단) 본문 수정
#           public-api      : 1R 이 추가한 표 행(마지막 행) 삭제
#           kernel-guide    : 1R 이 섹션을 삭제한 문서에 anchor id 없는 신규 섹션 추가
#                             (번역 잡이 ko/en/ja 에 동일 id 자동 부여하는지 검증용)
#           feature-matrix  : 표 행 추가 + anchor id 없는 신규 하위 섹션 삽입 (동일 검증용)
#           troubleshooting : 1R 대조군이던 파일 본문 수정 (신규 활성화)
declare -a PLAN_ROUND1=(
  "add_section|ko/overview.md"
  "edit_body|ko/overview.md"
  "rename_heading|ko/console-guide.md"
  "remove_paragraph|ko/console-guide.md"
  "add_paragraph|ko/component-guide.md"
  "add_subsection|ko/component-guide.md"
  "change_table_row|ko/public-api.md"
  "add_table_row|ko/public-api.md"
  "add_repeated_heading_with_table|ko/public-api.md"
  "remove_section|ko/kernel-guide.md"
  "edit_code_block|ko/kernel-guide.md"
  "edit_table_header|ko/feature-matrix.md"
  "remove_table_row|ko/feature-matrix.md"
  "rename_h3|ko/feature-matrix.md"
  "edit_list_item|ko/feature-matrix.md"
  "noop|ko/troubleshooting-guide.md"
)
declare -a PLAN_ROUND2=(
  "remove_added_section|ko/overview.md"
  "add_paragraph|ko/overview.md"
  "rename_heading|ko/console-guide.md"
  "edit_body|ko/component-guide.md"
  "remove_added_table_row|ko/public-api.md"
  "add_section_no_id|ko/kernel-guide.md"
  "add_table_row|ko/feature-matrix.md"
  "add_subsection_no_id|ko/feature-matrix.md"
  "edit_body|ko/troubleshooting-guide.md"
)
# row-drop-repro: cloud-translate PR #283 회귀 재현.
#   전제: version-guide.md 의 en/ja 가 `1.202602.1` 행을 결여한 stale 상태 —
#         archive 는 일관 상태를 유지하고, 이 stale 은 plan 실행 시 base
#         브랜치에 stale-ify 커밋으로 조성된다 (아래 STALE_ROWS).
#   변형: 첫 문단(≈500+ 자) 안 한 문장에만 짧은 수정 → ko diff 는 작지만
#         splice 재번역 대상 unit 이 그 큰 문단이라 load_chars/ko_diff_chars 비율이
#         `max_load_ratio=2` 를 초과 → row-safe splice 폐기 → LLM-patch fallback.
#         fallback 프롬프트는 ko diff (문단만) + 기존 en/ja 전체 를 받으므로
#         "표에서 빠진 1.202602.1 행" 은 diff 에도 en/ja 에도 등장하지 않음
#         → 모델이 그 행 삽입 patch 를 만들지 않고 조용히 커밋 → 결함 재현.
#   비교군: overview.md 는 정상 정렬 상태 그대로 `add_paragraph` 만 적용해
#           같은 잡 안에서 정상 경로도 함께 동작하는지 확인.
declare -a PLAN_ROW_DROP_REPRO=(
  "edit_body|ko/version-guide.md"
  "add_paragraph|ko/overview.md"
)
# table-suite: 표 번역 검증 종합 plan — 결함 재현 2케이스에 정상 경로 표 변형들을
# 더해 한 번의 잡으로 "결함은 재현되고 정상 케이스는 깨지지 않는지" 를 함께 확인한다.
#   ※ stale 상태(en/ja 의 특정 행 결여)는 archive 가 아니라 plan 실행 시
#     base 브랜치에 stale-ify 커밋으로 조성된다 (아래 STALE_ROWS) — archive
#     는 일관 상태를 유지해 round1/round2 의 step 17 전-파일 검사가 안 깨진다.
#   version-guide.md  : (결함 A — CK 인시던트 완전 동형, cloud-translate PR #283 대상)
#                       stale 표(en/ja 에 1.202602.1 행 없음)의 이웃 문단 수정
#                       + 그 stale 행 자체의 날짜 bump. 두 changed unit 합계 load
#                       (≈798자) ≥ floor 500, ratio ≈19x ≫ cap 2 → LLM-patch fallback.
#                       diff 에 행이 '수정' 으로 등장하지만 en/ja 엔 행 자체가 없어
#                       삽입 판단이 모델 몫 → pre-#283 은 모델 편차로 언어별 결과가
#                       갈린다 (2026-07-23 run 실측: en 은 apply-failed → 파일 제외로
#                       행 유실 지속, ja 는 삽입 성공 — 원본 CK 인시던트의 "ja 엔 있고
#                       en 엔 없음" 비대칭과 동일). 한 언어라도 유실이면 FAIL.
#                       post-#283 은 결정적 삽입 or raise 로 해소되어야 한다.
#   release-notes.md  : (결함 B — row-splice positional 손상; #283 범위 밖 별개 결함)
#                       stale 행(2.4.1)의 날짜만 bump. changed load 107자 < floor 500
#                       → load guard 미작동 → anchor-path row-splice 가 stale 표(4행)에
#                       positional 매핑되어 2.4.1 번역이 2.4.0 행을 덮어쓰고 고아
#                       중복 행이 생기는 조용한 손상을 노출한다 (2026-07-23 run 실측).
#   pricing-guide.md  : (결함 B', 산문형 표 변형) 같은 문서에 산문형 stale 표가
#                       둘 있고, 문단만 수정한다 → cloud-translate PR #290 의
#                       reconcile 이 참조 주입 whole-table 재번역으로 행을
#                       복구해야 한다. 첫 셀이 번역되는 텍스트라 row key 가 없어
#                       (`_table_key_column` → None) 키 백필이 아닌 재번역 경로다.
#                         (1) '요금제별 한도' 표 (ko 167자): en/ja 에 '고급 요금제'
#                             행 없음.
#                         (2) '스냅샷 기본 정책' 표 (ko 125자 — **300자 하한 미만**):
#                             en/ja 에 '복원 방식' 행 없음.
#                       (2) 는 `diff_full_preserve_min_chunk_chars`(=300) 의 표 예외
#                       (`_table_preserve_ctx`) 전용 픽스처다. 그 하한은 preserve
#                       베이스라인이 청크를 압도할 때의 문서 재현 폭주를 막는
#                       가드인데, 표 reconcile 의 베이스라인은 재작성 대상 표
#                       자신이라 그 실패 형태가 성립하지 않는다. 예외 없이 하한을
#                       적용하면 참조가 사라져 **기존 행 문구가 새로 번역된다** —
#                       행 수·열 수 검사는 그대로 통과하므로 조용한 churn 이다.
#                       판정은 두 층으로 나눈다.
#                        * 결정적 (이걸로 PASS/FAIL 을 가른다): 번역 로그에
#                          "Preserve-existing skipped for this chunk" 가 **없어야**
#                          하고, 그 문서의 재번역 청크가 125자/167자로 찍히면서
#                          "retranslated 2 table(s)" 가 나와야 한다. 예외가 빠지면
#                          두 청크 모두 skip 라인이 뜬다 — 모델과 무관한 신호다.
#                        * 관찰값 (모델 의존 — **en 만** 보고, FAIL 로 쓰지 말 것):
#                          남아있던 두 행이 diff 에 나타나지 않는 것(바이트 보존).
#                          베이스라인은 프롬프트 규칙이라 강제가 아니다.
#                       실측 (2026-08-22, haiku-4-5, 실 API, reconcile 직접 호출 3회씩):
#                         en 125자 표 : 예외 ON 6/6 셀 보존, OFF 0/6      ← 완전 분리
#                         en 167자 표 : 예외 ON 3/3 회 보존, OFF 1/3      (churn 예:
#                                       `Basic plan`→`Basic Plan`, `1TB`→`1 TB`)
#                         ja 125자 표 : 예외 ON 0/6, OFF 0/6              ← 신호 없음
#                       **ja 는 이 픽스처에서 판정에 쓰지 말 것.** haiku 는 125자
#                       표의 기존 행을 베이스라인 유무와 무관하게 매번 다시 쓴다
#                       (ko 가 능동형이라 수동형 기존 문구를 능동형으로 맞춰 버린다).
#                       ja diff 에 그 두 행이 보이는 것은 회귀가 아니다.
#                       주의: 픽스처의 en/ja 문구는 ko 의 **충실한** 번역이어야
#                       한다. 처음 넣은 ja 는 생성→取得 로 어긋나 있었고, 모델이
#                       그것을 정당하게 고쳐 쓰는 바람에 churn 과 구분되지 않았다.
#   spec-guide.md     : (결함 D — 컬럼 drift 혼재; notification-hub PR #209 지적
#                       4번 동형) ko 는 4컬럼 표(경로|타입|Not Null|설명), en/ja 는
#                       stale-ify 로 'Not Null' 컬럼(3번째)이 제거된 3컬럼 표
#                       (아래 STALE_DROP_COLS). 데이터 행 하나의 설명 셀만 수정 →
#                       행 단위 재번역이 ko 스키마(4셀) 행을 3컬럼 표에 그대로
#                       삽입하면 컬럼 혼재 — mkdocs 는 헤더 초과 셀을 버리므로
#                       설명 셀이 배포 화면에서 통째로 소실된다. 행 수는 세 언어
#                       동일하므로 표 개수/행 수 검사는 통과하고, step 17 의
#                       "표 내부 셀 수 일관성" 검사(6)만이 이 결함을 잡는다.
#                       ncols 불일치 가드(표 전체 재번역 or target 스키마 emit)
#                       도입 전엔 FAIL(재현), 도입 후 PASS 가 기대값.
#   component-guide.md: (케이스 1 — ko PR 자체가 표 컬럼을 추가; cloud-translate
#                       --table-column-ops 대상) 첫 표(MySQL 설정, escaped 문자
#                       포함 8행)의 모든 라인 끝에 셀 추가. 최적화 배포 전 =
#                       전 행 재번역(기존 셀 wording 도 diff 에 등장, 정합성은
#                       유지되어 PASS), 배포 후 = 기존 셀 byte 보존 + 새 컬럼만
#                       diff (번역 로그에 'Table column-op' 라인). 정합성 자체는
#                       양쪽 다 PASS 라 diff/로그로 최적화 동작을 판별한다.
#   feature-matrix.md : 표 중간 행 삽입 + 헤더 셀 수정 + 마지막 두 행 순서 교환
#                       + (둘째 표) 마지막 행 삭제
#   public-api.md     : 기존 행 셀 수정 + 행 추가 (round1 과 동일한 정상 케이스)
#   kernel-guide.md   : 표가 없던 문서에 신규 섹션+표 추가 (표 0→1)
#   troubleshooting   : 대조군 (변경 없음 — en/ja 무변경이어야 정상)
declare -a PLAN_TABLE_SUITE=(
  "edit_body|ko/version-guide.md"
  "bump_row_date|ko/version-guide.md"
  "insert_keyed_table_row|ko/version-guide.md"
  "bump_row_date|ko/release-notes.md"
  "edit_body|ko/pricing-guide.md"
  "edit_row_desc_cell|ko/spec-guide.md"
  "add_table_column|ko/component-guide.md"
  "insert_table_row_middle|ko/feature-matrix.md"
  "edit_table_header|ko/feature-matrix.md"
  "swap_table_rows|ko/feature-matrix.md"
  "remove_table_row|ko/feature-matrix.md"
  "change_table_row|ko/public-api.md"
  "add_table_row|ko/public-api.md"
  "add_new_table|ko/kernel-guide.md"
  "noop|ko/troubleshooting-guide.md"
)
# --plan markup-churn : 코스메틱 마크업 churn + 소수의 실제 내용 변경.
#   Storage-Object-Storage#181 재현 — ko "가이드 리뷰 반영" PR 이 문서 전반에
#   ``` -> ```bash (41곳), <br/> <-> <br> (64곳), 헤딩 뒤 빈 줄 (28곳) 을 뿌리면서
#   실제 내용 변경은 20여 줄뿐이었다. block granularity 에서 이 한 글자들이 각
#   유닛을 통째로 "변경됨" 으로 만들어 번역 부하가 폭증하는 반면 문자 단위 ko diff
#   는 거의 안 움직이므로, load guard 가 정상 리뷰 PR 을 runaway 로 오판해 파일을
#   제외한다 (#185 는 8개 파일x언어 전부 제외, 최대 97x). 제외된 파일은 취약한
#   LLM 패치 폴백으로 넘어갔고 ja/cli-guide.md 는 번역이 통째로 누락됐다.
#
#   기대값 — cloud-translate 의 코스메틱 마크업 미러링
#   (TRANSLATE_DIFF_COSMETIC_MARKUP, 기본 on) 배포 전/후:
#     * 배포 전 = 번역 로그에 "load guard: ... skipped" + 번역 PR 본문에 제외 섹션
#       (FAIL / 재현)
#     * 배포 후 = "Cosmetic markup mirrored (br, fence, heading_blank)" 로그,
#       load guard 미발동, en/ja 에 마크업이 그대로 미러링되고 실제 내용 변경만
#       번역됨 (PASS)
#   실측(#181 ko/cli-guide.md, ja): load 2992자 -> 1012자, ratio 5.3x -> 1.8x.
#
#   파일별 기대값:
#
#   component-guide.md: 세 규칙 모두 + 내용 변경 1건. 펜스 105 + <br> 9 + 헤딩 91.
#   public-api.md     : M2(<br> 98개, 표 행 안) + M3 + 내용 변경 1건.
#   overview.md       : 세 규칙 중 M1/M2 + 내용 변경 1건 (작은 문서).
#   jinja-guide.md    : Jinja/mkdocs 템플릿 태그(M4). ko/en/ja 가 동일한 태그 7개를
#                       갖도록 만든 픽스처로, whitespace 제어를 여는 쪽으로 이동
#                       ({% if x -%} -> {%- if x %}) + 내용 변경 1건.
#                       Storage-Online-NAS#92 형태 — 그 PR 은 변경 28줄 중 26줄이
#                       이 이동이었다. 태그는 번역할 내용이 0인데도 유닛 전체를
#                       "변경됨" 으로 만들어 부하를 부풀린다.
#                       주의: M4 는 ko 와 대상의 태그가 1:1 이어야 동작한다. 실제
#                       Storage-Online-NAS 는 en/ja 에 태그가 0개라(번역이 템플릿화
#                       이전) 그 레포에서는 안전한 no-op 이다 — 이 픽스처는 en/ja 도
#                       태그를 갖게 된 "이후" 상태를 재현한다.
#   troubleshooting   : 대조군 (변경 없음 — en/ja 무변경, 번역 PR 미포함이어야 정상)
#
#   PASS 판정은 "load guard 미발동 + LLM 패치 폴백 미발동 + PR 본문에 제외 섹션
#   없음 + en/ja 의 <br/>·```lang 개수가 ko 와 일치" 다. 특정 load/ratio 수치를
#   기대값으로 박아두지 말 것 — ko-review 가 accept 하는 suggestion 개수에 따라
#   ko diff 가 매 실행 달라지므로 수치는 실행마다 변한다.
#
#   2026-08-19 실측 (--translate local, 미배포 워크트리):
#     * 세 파일 모두 load guard 미발동. 미러링 후 부하가 component-guide 174자,
#       overview 150자까지 떨어져 diff_load_min_chars(500) floor 아래로 내려가
#       ratio 검사 자체가 생략됐다.
#     * en/ja 에서 모델이 만진 것은 파일당 본문 1줄 + machine_translated 마커뿐.
#       <br/> 71/8/1개, ```lang 51/2개는 전부 결정적으로 미러링됐다.
#     * 17단계 검증 11파일 x 6규칙 전부 OK, LLM 패치 폴백 0회.
#
#   ratio 경로(부하가 floor 위인데 cap 아래)를 직접 태운 실측은 이 플랜이 아니라
#   원 사고 데이터다 — Storage-Object-Storage#181 ko/cli-guide.md:
#   load 2992자 5.3x -> 1012자 1.8x (measure probe, 빌드 311 로그와 일치).
#
#   알려진 잡음 (이 플랜과 무관, 판정에 넣지 말 것): 14단계 ko-review suggestion
#   accept 가 ko/public-api.md 의 EOL 을 CRLF -> LF 로 정규화해 ko PR 에 4000줄대
#   허위 diff 가 생긴다. 마크업 변형 자체는 CRLF 를 보존한다(변형 커밋 시점
#   CRLF 1984 유지 확인). 번역 결과에는 영향 없음 — en/ja 는 원래 LF.
declare -a PLAN_MARKUP_CHURN=(
  "markup_fence_info|ko/component-guide.md"
  "markup_br_slash|ko/component-guide.md"
  "markup_heading_blank|ko/component-guide.md"
  "edit_body|ko/component-guide.md"
  "markup_br_slash|ko/public-api.md"
  "markup_heading_blank|ko/public-api.md"
  "edit_body|ko/public-api.md"
  "markup_fence_info|ko/overview.md"
  "markup_br_slash|ko/overview.md"
  "edit_body|ko/overview.md"
  "markup_jinja_ws|ko/jinja-guide.md"
  "edit_body|ko/jinja-guide.md"
  "noop|ko/troubleshooting-guide.md"
)
case "$PLAN_NAME" in
  round1) PLAN=("${PLAN_ROUND1[@]}") ;;
  round2) PLAN=("${PLAN_ROUND2[@]}") ;;
  row-drop-repro) PLAN=("${PLAN_ROW_DROP_REPRO[@]}") ;;
  table-suite) PLAN=("${PLAN_TABLE_SUITE[@]}") ;;
  markup-churn) PLAN=("${PLAN_MARKUP_CHURN[@]}") ;;
  *) echo "unknown --plan: $PLAN_NAME (round1|round2|row-drop-repro|table-suite|markup-churn)" >&2; exit 1 ;;
esac

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

git switch "$BASE_BRANCH"
git pull

# ── table-suite 전용: en/ja stale 상태를 BASE 브랜치에 조성 ────────────────
# archive/alpha-origin 은 ko/en/ja 가 일관된 상태를 유지한다 — round1/round2
# 등 다른 plan 의 step 17 전-파일 검사가 픽스처 때문에 깨지지 않도록.
# 결함 재현에 필요한 "en/ja 가 특정 행을 결여한 stale 표" 는 이 plan 이
# 실행될 때만, 번역 baseline 이 되는 base 브랜치에 커밋으로 만든다.
declare -a STALE_ROWS=()
declare -a STALE_DROP_COLS=()
case "$PLAN_NAME" in
  table-suite)
    STALE_ROWS=(
      "en/version-guide.md|1.202602.1"
      "ja/version-guide.md|1.202602.1"
      "en/release-notes.md|2.4.1"
      "ja/release-notes.md|2.4.1"
      "en/pricing-guide.md|Premium plan"
      "ja/pricing-guide.md|プレミアムプラン"
      "en/pricing-guide.md|Restore method"
      "ja/pricing-guide.md|復元方法"
    )
    # 결함 D (컬럼 drift): en/ja 표에서 N번째 컬럼을 통째로 제거해 "ko 는 4컬럼,
    # target 은 3컬럼" 상태를 조성 — notification-hub 의 'Not Null' 컬럼 미반영
    # 상태와 동형. 행은 그대로라 행 수 검사에는 걸리지 않는다.
    STALE_DROP_COLS=(
      "en/spec-guide.md|3"
      "ja/spec-guide.md|3"
    ) ;;
  row-drop-repro)   # 최소 재현: version-guide 만 stale
    STALE_ROWS=(
      "en/version-guide.md|1.202602.1"
      "ja/version-guide.md|1.202602.1"
    ) ;;
esac
if (( ${#STALE_ROWS[@]} + ${#STALE_DROP_COLS[@]} )); then
  echo "$PLAN_NAME: base 브랜치($BASE_BRANCH)에 en/ja stale-ify 커밋 생성 (행 제거·컬럼 제거)"
  for s in "${STALE_ROWS[@]}"; do
    rel="${s%%|*}"; marker="${s#*|}"
    [[ -f "$rel" ]] || { echo "  (skip, missing: $rel)"; continue; }
    python3 - "$rel" "$marker" <<'PY'
import sys
path, marker = sys.argv[1], sys.argv[2]
lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
out = [l for l in lines
       if not (l.lstrip().startswith("|") and marker in l)]
if len(out) == len(lines):
    print(f"  (noop, row not found: {path} :: {marker})")
else:
    open(path, "w", encoding="utf-8").write("".join(out))
    print(f"  [stale-ified] {path} (removed row: {marker})")
PY
    git add "$rel"
  done
  # 컬럼 제거 (결함 D): 파일 안 모든 표 행에서 col번째 셀을 삭제 — 헤더/구분선/
  # 데이터 행이 함께 줄어들어 표 자체는 (컬럼 수만 다른) 정상 표로 유지된다.
  for s in "${STALE_DROP_COLS[@]}"; do
    rel="${s%%|*}"; col="${s#*|}"
    [[ -f "$rel" ]] || { echo "  (skip, missing: $rel)"; continue; }
    python3 - "$rel" "$col" <<'PY'
import sys
path, col = sys.argv[1], int(sys.argv[2])   # col: 1-based 셀 인덱스
lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
out, dropped = [], 0
for l in lines:
    s = l.rstrip("\r\n")
    eol = l[len(s):]
    st = s.strip()
    if st.startswith("|") and st.endswith("|"):
        cells = [c.strip() for c in st[1:-1].split("|")]
        if len(cells) >= col:
            del cells[col - 1]
            out.append("| " + " | ".join(cells) + " |" + eol)
            dropped += 1
            continue
    out.append(l)
if dropped == 0:
    print(f"  (noop, no table row with >= {col} cells: {path})")
else:
    open(path, "w", encoding="utf-8").write("".join(out))
    print(f"  [stale-ified] {path} (dropped column {col} from {dropped} table line(s))")
PY
    git add "$rel"
  done
  if git diff --cached --quiet; then
    echo "  (변경 없음 — 이미 stale 상태)"
  else
    git commit -m "table-suite: en/ja stale-ify — 행 제거·컬럼 제거 (표 결함 재현용, archive 는 일관 유지)"
    git push origin "$BASE_BRANCH"
  fi
fi

git checkout -B "$BRANCH"

for p in "${PLAN[@]}"; do
  mut="${p%%|*}"; rel="${p#*|}"
  [[ -f "$rel" ]] || { echo "  (skip, missing: $rel)"; continue; }
  mutate_ko "$mut" "$rel"
  git add "$rel"
done

if git diff --cached --quiet; then
  echo "변경사항 없음. 종료."; exit 0
fi

if [[ "$PLAN_NAME" == "round2" ]]; then
  : "${TITLE:=Translate test round2: mutations on already-translated alpha}"
  : "${BODY:=1라운드 ko 변경·번역 PR 이 alpha 에 머지된 상태에서 2차 ko 변경을 적용한 테스트 PR. 이전 라운드 산출물(추가 섹션·추가 표 행)의 수정/삭제와 신규 변경이 증분 번역으로 반영되는지 검증합니다.}"
fi
: "${TITLE:=Translate test: varied ko/ mutations (heading-preserve/anchor-id)}"
: "${BODY:=ko/ 문서를 신규 섹션 추가·본문 수정·heading 제목 변경·문단 추가·표 행 수정·섹션 삭제 등 다양한 형태로 변경한 번역 테스트 PR. en/ja 는 alpha 그대로(=drift) 두어 anchor-id 브리지의 기존 heading 보존을 검증합니다.}"

git commit -m "$TITLE"
git push -u origin "$BRANCH"
# 라벨은 create 시점에 붙인다 — 사후 `gh pr edit` 는 stdout 에 URL 을 한 줄 더
# 찍어 호출부의 `grep -oE 'https://…/pull/[0-9]+' | tail -n1` 파싱을 깨뜨린다.
e2e_ensure_label "${REPO:-TOAST-DOCS/Agent-Test}"
gh pr create --base "$BASE_BRANCH" --head "$BRANCH" --title "$TITLE" --body "$BODY" \
  --label "$E2E_LABEL"
