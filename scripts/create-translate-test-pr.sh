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
    --plan)   PLAN_NAME="$2"; shift 2 ;;   # round1(기본) | round2
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
#   전제: version-guide.md 는 alpha 초기 상태부터 en/ja 가 stale
#         (ko 만 `1.202602.1` 행을 가진 5-row 표, en/ja 는 4-row).
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
# table-suite: 표 번역 검증 종합 plan — row-drop-repro 의 두 결함 재현 케이스에
# 정상 경로 표 변형들을 더해 한 번의 잡으로 "결함은 재현되고 정상 케이스는 깨지지
# 않는지" 를 함께 확인한다.
#   version-guide.md  : (결함 A) stale 표 이웃 문단 수정 → LLM-patch → 행 유실 노출
#   release-notes.md  : (결함 B, CK 인시던트 원형) en/ja 가 결여한 stale 행(2.4.1)
#                       자체의 날짜만 하루 bump → ko diff 상 '수정' 으로만 보임
#                       → 행 개수 불일치로 row-splice 1:1 불가 → fallback → 행 유실
#   feature-matrix.md : 표 중간 행 삽입 + 헤더 셀 수정 + (둘째 표) 마지막 행 삭제
#   public-api.md     : 기존 행 셀 수정 + 행 추가 (round1 과 동일한 정상 케이스)
#   kernel-guide.md   : 표가 없던 문서에 신규 섹션+표 추가 (표 0→1)
#   troubleshooting   : 대조군 (변경 없음 — en/ja 무변경이어야 정상)
declare -a PLAN_TABLE_SUITE=(
  "edit_body|ko/version-guide.md"
  "bump_row_date|ko/release-notes.md"
  "insert_table_row_middle|ko/feature-matrix.md"
  "edit_table_header|ko/feature-matrix.md"
  "remove_table_row|ko/feature-matrix.md"
  "change_table_row|ko/public-api.md"
  "add_table_row|ko/public-api.md"
  "add_new_table|ko/kernel-guide.md"
  "noop|ko/troubleshooting-guide.md"
)
case "$PLAN_NAME" in
  round1) PLAN=("${PLAN_ROUND1[@]}") ;;
  round2) PLAN=("${PLAN_ROUND2[@]}") ;;
  row-drop-repro) PLAN=("${PLAN_ROW_DROP_REPRO[@]}") ;;
  table-suite) PLAN=("${PLAN_TABLE_SUITE[@]}") ;;
  *) echo "unknown --plan: $PLAN_NAME (round1|round2|row-drop-repro|table-suite)" >&2; exit 1 ;;
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
gh pr create --base "$BASE_BRANCH" --head "$BRANCH" --title "$TITLE" --body "$BODY"
