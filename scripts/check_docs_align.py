#!/usr/bin/env python3
"""ko/en/ja 문서의 구조 정합을 결정적으로 검사한다 (fable 검증 대체).

e2e 파이프라인의 8단계(align PR)·17단계(번역 PR) 검증은 원래 `claude -p
--model fable` 에게 "heading level 순서·anchor id 순서·표 행 수·..." 를
물어보는 agentic 검사였다. 검사 내용이 100% 결정적이라 LLM 이 필요 없는데
문서 11개(최대 90KB)를 매번 훑어 plan 당 15~25분씩 소모하고, 판정이
실행마다 흔들릴 여지도 있었다. 이 스크립트가 같은 규칙을 1초 안에,
결정적으로 검사한다.

규칙 (fable 프롬프트와 1:1):
  (1) heading level 순서가 ko/en/ja 에서 일치            [align, translate]
  (2) anchor id 순서가 세 언어에서 일치                   [align, translate]
      (<a id>/<a name>/<tag id> 및 heading 의 { #id } 모두)
  (3) 표 개수와 각 표의 데이터 행 개수가 세 언어에서 일치  [translate]
      + 표에서 떨어져 나온 고아 표 행(구분선 없는 | 행 뭉치)
  (4) 언어 무관 식별자(버전/코드 토큰) 를 첫 셀로 갖는 행의  [translate]
      식별자 집합·등장 순서가 세 언어에서 일치
  (5) en/ja 본문에 한글 잔류 없음 (fence·inline code 제외)  [translate]
  (6) 한 표 안 모든 행의 셀 개수가 헤더 셀 개수와 동일      [translate]
  (7) <br>/<br/> 개수와 info string 붙은 여는 펜스 개수가   [--markup]
      ko 와 일치 (markup-churn plan 의 미러링 판정)
  (8) 표 앞/뒤의 빈 줄이 ko 와 일치                        [translate]
      표 바로 뒤 줄이 비어있지 않으면 그 줄이 표의 행으로 흡수되고
      (`<td>다음 문단</td>`), 표 바로 앞 줄이 비어있지 않으면 표가
      아예 렌더되지 않는다. 둘 다 `|` 로 시작하는 줄만 세는 규칙 (3)·(6)
      으로는 보이지 않는다 — ko 에 없는데 en/ja 에만 있으면 번역이
      만든 것이다 (cloud-translate #793).

마지막 줄은 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" — e2e 스크립트가
`grep -q '^ALIGNMENT: OK'` 로 읽는 계약이므로 바꾸지 말 것.

Usage:
  python3 scripts/check_docs_align.py --mode align       # 규칙 1,2
  python3 scripts/check_docs_align.py --mode translate   # 규칙 1~6
  python3 scripts/check_docs_align.py --mode translate --markup
  python3 scripts/check_docs_align.py --root <worktree> --files ko/overview.md
  python3 scripts/check_docs_align.py --root <wt> --mode translate \
      --files "$(bash scripts/create-translate-test-pr.sh --plan round1 --list-files | paste -sd,)"

ko/ 아래 .md 를 하위 폴더까지 재귀로 훑어 en/ja 에 같은 상대 경로가 있는 문서만
비교한다 (include 로 조립되는 하위 폴더 본문도 검사 대상).

--files 로 검사 대상을 명시하면 그 목록만 본다. ko/ 에는 plan 마다 다른 e2e
픽스처가 섞여 살기 때문에 (fill-stub-sample 처럼 채워지기 전이 정상 상태인
문서도 있다) 전수 검사는 그 실행과 무관한 문서에서 상시 FAIL 을 낸다 —
e2e 의 17단계는 plan 이 다루는 파일만 넘긴다
(create-translate-test-pr.sh --plan <name> --list-files 가 그 목록의 정본).

EXCLUDED_STEMS 에 적힌 문서는 자동 열거에서 빠지며, 무엇이 빠졌는지 실행 시
출력한다. --files 는 그 제외를 override 한다 (release-notes/<year>.md 의 드리프트를
고치면서 확인하는 길) — plan 목록을 기계적으로 넘기는 e2e 호출만
--apply-exclusions 로 override 를 끈다.
"""
from __future__ import annotations

import argparse
import os
import re
import sys

LANGS = ("ko", "en", "ja")
SOURCE = "ko"
TARGETS = ("en", "ja")

FENCE_RE = re.compile(r"^\s*(```|~~~)")
HEAD_RE = re.compile(r"^(#{1,6})[ \t]+(\S.*)$")
HEAD_ID_RE = re.compile(r"\{\s*#([^}\s]+)\s*\}")
# 임의 HTML 태그의 id 속성 + 레거시 <a name>
TAG_ID_RE = re.compile(r"<[a-zA-Z][a-zA-Z0-9]*\b[^>]*?\bid\s*=\s*\"([^\"]+)\"")
TAG_NAME_RE = re.compile(r"<a\b[^>]*?\bname\s*=\s*\"([^\"]+)\"")
TABLE_LINE_RE = re.compile(r"^\s*\|")
SEP_RE = re.compile(r"^\s*\|[\s\-:|]+\|\s*$")
CELL_SPLIT_RE = re.compile(r"(?<!\\)\|")
HANGUL_RE = re.compile(r"[가-힣ᄀ-ᇿ㄰-㆏]")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
HTML_COMMENT_RE = re.compile(r"<!--.*?-->", re.DOTALL)
BR_RE = re.compile(r"<br\s*/?>", re.IGNORECASE)
BARE_BR_RE = re.compile(r"<br\s*>", re.IGNORECASE)
FENCE_INFO_RE = re.compile(r"^\s*(?:```|~~~)\s*([A-Za-z0-9_+-]+)\s*$")
CJK_RE = re.compile(r"[぀-ヿ㐀-䶿一-鿿가-힣]")
IDENT_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+\-]*$")
VERSIONISH_RE = re.compile(r"^v?\d+(\.\d+)+$")

# region variant (ko 전용) — 비교 대상이 아니다. shared/github_client.is_excluded_doc 와 동일.
VARIANT_SUFFIXES = ("gov", "ncgn", "ngcc", "ppp", "ngoic", "ngovc", "ngsc", "ninc")


def is_variant(name: str) -> bool:
    stem = name[:-3] if name.endswith(".md") else name
    parts = stem.split("-")
    return len(parts) > 1 and any(p in VARIANT_SUFFIXES for p in parts[1:])


# 자동 열거에서 뺄 문서 — 픽스처의 en/ja 가 애초에 ko 와 정렬돼 있지 않아
# (release-notes 는 stale fixture 로 들어왔다) 게이트에 신호 대신 상시 FAIL 만
# 준다. stem 하나가 같은 이름의 하위 폴더까지 덮는다:
#   'release-notes' → release-notes.md + release-notes/<year>.md 전부
# --files 로 직접 지목하면 그대로 검사한다 (드리프트를 손볼 때 쓰라고 남겨둔다).
EXCLUDED_STEMS = ("release-notes",)


def is_excluded(rel: str) -> bool:
    head = rel.split("/", 1)[0]
    return (head[:-3] if head.endswith(".md") else head) in EXCLUDED_STEMS


def outside_fences(lines: list[str]):
    """(index, line) 을 fenced code block 밖에서만 순회."""
    fence = False
    for i, raw in enumerate(lines):
        line = raw.rstrip("\r\n")
        if FENCE_RE.match(line):
            fence = not fence
            continue
        if fence:
            continue
        yield i, line


def heading_levels(lines: list[str]) -> list[int]:
    out = []
    for _, line in outside_fences(lines):
        m = HEAD_RE.match(line)
        if m:
            out.append(len(m.group(1)))
    return out


def anchor_ids(lines: list[str]) -> list[str]:
    out = []
    for _, line in outside_fences(lines):
        m = HEAD_RE.match(line)
        if m:
            for hid in HEAD_ID_RE.findall(m.group(2)):
                out.append(hid)
            continue
        for aid in TAG_ID_RE.findall(line):
            out.append(aid)
        for aid in TAG_NAME_RE.findall(line):
            out.append(aid)
    return out


def split_cells(line: str) -> list[str]:
    body = line.strip()
    parts = CELL_SPLIT_RE.split(body)
    if parts and not parts[0].strip():
        parts = parts[1:]
    if parts and not parts[-1].strip():
        parts = parts[:-1]
    return [p.strip() for p in parts]


class Table:
    def __init__(self, header: str, sep: str, rows: list[str], line_no: int,
                 end_line: int = 0):
        self.header = header
        self.sep = sep
        self.rows = rows
        self.line_no = line_no
        # 표의 마지막 줄(구분선만 있으면 그 줄)의 1-based line 번호. 규칙 (8) 이
        # 표 바로 앞/뒤 줄을 보는 데 쓴다.
        self.end_line = end_line or line_no

    @property
    def ncols(self) -> int:
        return len(split_cells(self.header))

    def first_cells(self) -> list[str]:
        return [split_cells(r)[0] if split_cells(r) else "" for r in self.rows]


def parse_tables(lines: list[str]) -> tuple[list[Table], list[int]]:
    """(표 목록, 고아 표 행의 1-based line 번호) — fence 밖에서만."""
    kept = list(outside_fences(lines))
    tables: list[Table] = []
    orphans: list[int] = []
    run: list[tuple[int, str]] = []
    prev_idx = None

    def flush(run):
        if not run:
            return
        if len(run) >= 3 and SEP_RE.match(run[1][1]):
            tables.append(Table(run[0][1], run[1][1], [l for _, l in run[2:]],
                                run[0][0] + 1, run[-1][0] + 1))
        elif len(run) == 2 and SEP_RE.match(run[1][1]):
            tables.append(Table(run[0][1], run[1][1], [],
                                run[0][0] + 1, run[-1][0] + 1))
        else:
            orphans.extend(i + 1 for i, _ in run)

    for idx, line in kept:
        if TABLE_LINE_RE.match(line):
            if prev_idx is not None and idx != prev_idx + 1 and run:
                flush(run)
                run = []
            run.append((idx, line))
            prev_idx = idx
        else:
            flush(run)
            run = []
            prev_idx = None
    flush(run)
    return tables, orphans


def is_identifier(cell: str) -> bool:
    """언어 무관 식별자(버전/코드 토큰) 인가."""
    c = cell.strip().strip("`*_ ")
    if not c or len(c) < 2 or CJK_RE.search(c) or not IDENT_RE.match(c):
        return False
    has_digit = any(ch.isdigit() for ch in c)
    upper_code = c.isupper() and ("-" in c or "_" in c)
    return has_digit or upper_code


def strip_code_and_comments(text: str) -> str:
    text = HTML_COMMENT_RE.sub(" ", text)
    return INLINE_CODE_RE.sub(" ", text)


def hangul_leaks(lines: list[str], known: tuple[str, ...] = ()) -> tuple[list, list]:
    """(진짜 잔류, 알려진 픽스처 잔류) — known 리터럴에 걸친 매치는 후자로 분류."""
    real, tolerated = [], []
    for idx, line in outside_fences(lines):
        clean = strip_code_and_comments(line)
        spans = []
        for lit in known:
            start = 0
            while True:
                at = clean.find(lit, start)
                if at < 0:
                    break
                spans.append((at, at + len(lit)))
                start = at + len(lit)
        for m in HANGUL_RE.finditer(clean):
            s, e = m.span()
            if any(s < re_ and rs < e for rs, re_ in spans):
                tolerated.append((idx + 1, line.strip()[:90]))
            else:
                real.append((idx + 1, line.strip()[:90]))
                break
    return real, tolerated


def load_known_leftovers(path: str | None) -> tuple[str, ...]:
    """번역되지 않고 남는 것이 정상인 한글 리터럴 목록 (없으면 빈 튜플)."""
    if path is None:
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "known_korean_leftovers.txt")
    if not os.path.isfile(path):
        return ()
    out = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.split("#", 1)[0].strip()
            if line:
                out.append(line)
    return tuple(out)


def markup_counts(lines: list[str]) -> tuple[int, int, int]:
    """(<br> 계열 총 개수, 슬래시 없는 <br> 개수, info string 붙은 여는 펜스 개수)."""
    br = bare = 0
    for raw in lines:
        br += len(BR_RE.findall(raw))
        bare += len(BARE_BR_RE.findall(raw))
    fence_info, opened = 0, False
    for raw in lines:
        line = raw.rstrip("\r\n")
        if FENCE_RE.match(line):
            if not opened:
                opened = True
                if FENCE_INFO_RE.match(line):
                    fence_info += 1
            else:
                opened = False
    return br, bare, fence_info


def normalize_rel(spec: str) -> str:
    """'ko/release-notes/2016.md' → 'release-notes/2016.md' (언어 디렉터리만 떼낸다)."""
    parts = [p for p in spec.strip().replace("\\", "/").split("/") if p not in ("", ".")]
    if parts and parts[0] in LANGS:
        parts = parts[1:]
    return "/".join(parts)


def collect_docs(root: str) -> tuple[list[str], list[str]]:
    """ko/ 아래 .md 를 하위 폴더까지 재귀로 모아 (검사 대상, 제외된 것) 을 반환.

    include 로 조립되는 문서(ko/release-notes.md → ko/release-notes/<year>.md)는
    본문이 하위 폴더에 있으므로 최상위만 훑으면 구조 검사가 통째로 비어버린다.
    en/ja 에 같은 상대 경로가 없는 문서와 EXCLUDED_STEMS 는 대상에서 뺀다.
    """
    ko_dir = os.path.join(root, SOURCE)
    rels: list[str] = []
    skipped: list[str] = []
    for dirpath, dirnames, filenames in os.walk(ko_dir):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in filenames:
            if not name.endswith(".md") or is_variant(name):
                continue
            rel = os.path.relpath(os.path.join(dirpath, name), ko_dir).replace(os.sep, "/")
            if not all(os.path.isfile(os.path.join(root, lang, rel)) for lang in TARGETS):
                continue
            (skipped if is_excluded(rel) else rels).append(rel)
    return sorted(rels), sorted(skipped)


def read(path: str) -> list[str]:
    with open(path, "r", encoding="utf-8") as f:
        return f.read().splitlines()


def order_of(seq: list[str], keys: set[str]) -> list[str]:
    return [s for s in seq if s in keys]


def check_doc(root: str, rel: str, mode: str, markup: bool,
              known: tuple[str, ...] = ()) -> tuple[list[str], list[str]]:
    """rel = 'overview.md'. 반환 = (실패 사유, 참고 경고) 목록."""
    docs = {lang: read(os.path.join(root, lang, rel)) for lang in LANGS}
    fails: list[str] = []
    warns: list[str] = []

    # (1) heading level 순서
    base_levels = heading_levels(docs[SOURCE])
    for lang in TARGETS:
        lv = heading_levels(docs[lang])
        if lv != base_levels:
            fails.append(f"(1) heading levels {lang}={len(lv)} vs ko={len(base_levels)}: "
                         + describe_seq_diff([str(x) for x in base_levels], [str(x) for x in lv]))

    # (2) anchor id 순서
    base_ids = anchor_ids(docs[SOURCE])
    for lang in TARGETS:
        ids = anchor_ids(docs[lang])
        if ids != base_ids:
            fails.append(f"(2) anchor ids {lang}={len(ids)} vs ko={len(base_ids)}: "
                         + describe_seq_diff(base_ids, ids))

    if mode == "align" and not markup:
        return fails, warns

    parsed = {lang: parse_tables(docs[lang]) for lang in LANGS}
    base_tables, base_orphans = parsed[SOURCE]

    # (3) 표 개수·행 수 + 고아 행
    for lang in LANGS:
        tables, orphans = parsed[lang]
        if orphans:
            fails.append(f"(3) {lang}: 고아 표 행 (구분선 없는 | 뭉치) line {orphans[:5]}")
    for lang in TARGETS:
        tables, _ = parsed[lang]
        if len(tables) != len(base_tables):
            fails.append(f"(3) {lang}: 표 개수 {len(tables)} vs ko={len(base_tables)}")
            continue
        for n, (bt, tt) in enumerate(zip(base_tables, tables), 1):
            if len(bt.rows) != len(tt.rows):
                fails.append(f"(3) {lang}: 표#{n}(line {tt.line_no}) 데이터 행 "
                             f"{len(tt.rows)} vs ko={len(bt.rows)}(line {bt.line_no})")

    # (4) 식별자 행 집합·순서
    for lang in TARGETS:
        tables, _ = parsed[lang]
        if len(tables) != len(base_tables):
            continue
        for n, (bt, tt) in enumerate(zip(base_tables, tables), 1):
            base_keys = [c for c in bt.first_cells() if is_identifier(c)]
            tgt_first = tt.first_cells()
            tgt_keys = [c for c in tgt_first if is_identifier(c)]
            missing = [k for k in base_keys if k not in tgt_keys]
            extra = [k for k in tgt_keys if k not in base_keys and VERSIONISH_RE.match(k)]
            if missing:
                fails.append(f"(4) {lang}: 표#{n}(line {tt.line_no}) 식별자 행 유실 {missing[:5]}")
            if extra:
                fails.append(f"(4) {lang}: 표#{n}(line {tt.line_no}) ko 에 없는 식별자 행 {extra[:5]}")
            if not missing and not extra:
                bk = set(base_keys)
                if order_of(tgt_keys, bk) != order_of(base_keys, bk):
                    fails.append(f"(4) {lang}: 표#{n}(line {tt.line_no}) 식별자 행 순서 불일치 "
                                 f"{order_of(tgt_keys, bk)[:6]} vs ko={order_of(base_keys, bk)[:6]}")

    # (5) 한글 잔류 (en/ja)
    for lang in TARGETS:
        leaks, tolerated = hangul_leaks(docs[lang], known)
        if leaks:
            shown = "; ".join(f"line {ln}: {tx}" for ln, tx in leaks[:3])
            fails.append(f"(5) {lang}: 한글 잔류 {len(leaks)}건 — {shown}")
        if tolerated:
            warns.append(f"(5) {lang}: 알려진 픽스처 한글 리터럴 {len(tolerated)}건 (판정 제외) "
                         f"— line {[ln for ln, _ in tolerated][:5]}")

    # (6) 표 내부 셀 수 일관성
    for lang in LANGS:
        tables, _ = parsed[lang]
        for n, t in enumerate(tables, 1):
            ncols = t.ncols
            bad = []
            for off, row in enumerate(t.rows):
                got = len(split_cells(row))
                if got != ncols:
                    bad.append(f"line {t.line_no + 2 + off}({got}셀)")
            if len(split_cells(t.sep)) != ncols:
                bad.append(f"구분선({len(split_cells(t.sep))}셀)")
            if bad:
                fails.append(f"(6) {lang}: 표#{n}(line {t.line_no}, 헤더 {ncols}셀) "
                             f"셀 수 불일치 {bad[:4]}")

    # (8) 표 앞/뒤의 빈 줄 — ko 와 대조
    #
    # 규칙 (3)·(6) 은 `|` 로 시작하는 줄만 표로 본다. 그래서 표 바로 뒤에
    # 빈 줄 없이 문단이 오는 상태를 "표 밖의 문단" 으로 읽고 통과시킨다 —
    # 그러나 mkdocs(python-markdown tables) 는 그 줄을 표의 데이터 행으로
    # 흡수한다(`<td>다음 문단</td>`). 반대로 표 바로 '앞' 줄이 비어있지
    # 않으면(heading 은 예외) 표가 통째로 렌더되지 않고 파이프가 그대로
    # 보인다. 둘 다 배포 화면에서만 드러나는 조용한 손상이다.
    #
    # ko 원문에도 같은 모양이 흔히 있으므로(작성 관례) 개수를 절대값으로
    # 보지 않고 **같은 순번의 ko 표와 대조**해, ko 에 없는데 번역본에만
    # 생긴 경우만 FAIL 로 잡는다 (cloud-translate #793).
    def _boundary(lines_: list[str], t: Table) -> tuple[bool, bool]:
        """(앞줄이 표를 막는가, 뒷줄이 표에 흡수되는가)."""
        before_i, after_i = t.line_no - 2, t.end_line        # 0-based
        def blocking(i: int) -> bool:
            if i < 0 or i >= len(lines_):
                return False
            ln = lines_[i]
            if not ln.strip() or TABLE_LINE_RE.match(ln):
                return False
            return True
        prev_blocks = blocking(before_i) and not lines_[before_i].lstrip().startswith("#")
        return prev_blocks, blocking(after_i)

    if len(base_tables) == len(parsed[SOURCE][0]):
        for lang in LANGS:
            if lang == SOURCE:
                continue
            tables, _ = parsed[lang]
            if len(tables) != len(base_tables):
                continue                      # (3) 이 이미 FAIL 로 잡는다
            for n, (bt, tt) in enumerate(zip(base_tables, tables), 1):
                ko_pre, ko_post = _boundary(docs[SOURCE], bt)
                pre, post = _boundary(docs[lang], tt)
                if post and not ko_post:
                    fails.append(
                        f"(8) {lang}: 표#{n}(line {tt.line_no}) 바로 뒤 줄에 빈 줄이 없다 "
                        f"— 렌더 시 표의 행으로 흡수됨 (line {tt.end_line + 1}: "
                        f"{docs[lang][tt.end_line].strip()[:40]!r}), ko 는 정상")
                if pre and not ko_pre:
                    fails.append(
                        f"(8) {lang}: 표#{n}(line {tt.line_no}) 바로 앞 줄에 빈 줄이 없다 "
                        f"— 표가 렌더되지 않음 (line {tt.line_no - 1}: "
                        f"{docs[lang][tt.line_no - 2].strip()[:40]!r}), ko 는 정상")

    # (7) 마크업 미러링 (--markup)
    #
    # 개수 '일치' 를 요구하지 않는다 — 픽스처 baseline 자체가 언어별로 조금
    # 다르다 (component-guide ko 12 vs en 11 <br>, alpha-origin public-api
    # ko 98 / en 99 / ja 100). 대신 "ko 가 전부 <br/> 로 바뀌었는데 target 에
    # 아직 맨몸 <br> 이 남아있다" = 미러링 미동작만 FAIL 로 잡고, 개수는
    # 참고용으로 찍는다.
    if markup:
        b_br, b_bare, b_fi = markup_counts(docs[SOURCE])
        for lang in TARGETS:
            br, bare, fi = markup_counts(docs[lang])
            if b_bare == 0 and bare > 0:
                fails.append(f"(7) {lang}: 맨몸 <br> {bare}개 잔존 — ko 는 0개 "
                             f"(코스메틱 마크업 미러링 미동작)")
            warns.append(f"(7) {lang}: <br> {br}(맨몸 {bare}) vs ko {b_br}(맨몸 {b_bare}), "
                         f"info 펜스 {fi} vs ko {b_fi}")

    return fails, warns


def describe_seq_diff(a: list[str], b: list[str]) -> str:
    """첫 divergence 를 사람이 읽을 수 있게 (개수만 알려주면 정보량 0)."""
    for i, (x, y) in enumerate(zip(a, b)):
        if x != y:
            return f"첫 불일치 #{i + 1} ko={x!r} vs {y!r}"
    if len(a) != len(b):
        longer, shorter = (a, b) if len(a) > len(b) else (b, a)
        who = "ko" if len(a) > len(b) else "target"
        return f"{who} 에만 있는 꼬리 {longer[len(shorter):][:5]}"
    return "동일"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", help="ko/en/ja 가 있는 디렉터리 (기본: cwd)")
    ap.add_argument("--mode", choices=("align", "translate"), default="translate")
    ap.add_argument("--markup", action="store_true", help="규칙 (7) 마크업 미러링 검사 추가")
    ap.add_argument("--known-leftovers", default=None,
                    help="번역되지 않고 남는 것이 정상인 한글 리터럴 목록 파일 "
                         "(기본: scripts/known_korean_leftovers.txt)")
    ap.add_argument("--files", default="", help="검사 대상 제한 (쉼표 구분, ko/foo.md · foo.md · release-notes/2016.md 모두 허용). 기본적으로 EXCLUDED_STEMS 를 override 한다")
    ap.add_argument("--apply-exclusions", action="store_true",
                    help="--files 로 넘어온 목록에도 EXCLUDED_STEMS 를 적용 (e2e 자동 호출용)")
    args = ap.parse_args()

    root = args.root
    ko_dir = os.path.join(root, SOURCE)
    if not os.path.isdir(ko_dir):
        print(f"error: {ko_dir} 없음", file=sys.stderr)
        print("ALIGNMENT: FAIL")
        return 2

    if args.files:
        # --files 는 기본적으로 EXCLUDED_STEMS 를 override 한다 (release-notes/<year>.md
        # 의 드리프트를 고치면서 확인하는 길). e2e 처럼 plan 파일 목록을 기계적으로
        # 넘기는 호출은 --apply-exclusions 로 그 override 를 끈다 — 그 목록에는
        # 제외 대상이 섞여 들어올 수 있고, 자동 게이트에 상시 FAIL 을 넣는 건
        # 목록을 좁힌 목적과 정반대이기 때문.
        asked = [r for r in (normalize_rel(f) for f in args.files.split(",")) if r]
        if args.apply_exclusions:
            rels = [r for r in asked if not is_excluded(r)]
            skipped = [r for r in asked if is_excluded(r)]
        else:
            rels, skipped = asked, []
    else:
        rels, skipped = collect_docs(root)

    if not rels:
        print("error: ko/en/ja 에 공통으로 존재하는 .md 문서가 없습니다", file=sys.stderr)
        print("ALIGNMENT: FAIL")
        return 2

    known = load_known_leftovers(args.known_leftovers)
    rules = "1,2" if (args.mode == "align" and not args.markup) else "1-6,8"
    if args.markup:
        rules += ",7"
    print(f"검사 대상 {len(rels)} 파일, 규칙 {rules} (mode={args.mode}, root={root})")
    if skipped:
        print(f"제외 {len(skipped)} 파일 (EXCLUDED_STEMS={list(EXCLUDED_STEMS)}): "
              f"{', '.join(skipped[:4])}{' ...' if len(skipped) > 4 else ''}")
    if known:
        print(f"알려진 한글 리터럴 {len(known)}개는 규칙 (5) 판정에서 제외: {list(known)[:6]}")
    print()
    width = max(len(r) for r in rels) + 2
    n_fail = 0
    for rel in rels:
        try:
            fails, warns = check_doc(root, rel, args.mode, args.markup, known)
        except Exception as exc:  # 파싱 실패도 FAIL 로 보고 (조용히 넘기지 않는다)
            fails, warns = [f"검사 오류: {type(exc).__name__}: {exc}"], []
        if fails:
            n_fail += 1
            print(f"{rel:<{width}} FAIL")
        else:
            print(f"{rel:<{width}} OK")
        for f in fails:
            print(f"{'':<{width}}   - {f}")
        for w in warns:
            print(f"{'':<{width}}   ~ {w}")
    print()
    print(f"총 {len(rels)} 파일: OK {len(rels) - n_fail}, FAIL {n_fail}")
    print("ALIGNMENT: " + ("FAIL" if n_fail else "OK"))
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
