#!/usr/bin/env python3
"""릴리스 노트 날짜 헤딩 · `버전 (날짜)` 헤딩 판정 — 모델 없이, 결정적으로.

usage: check_date_headings.py <base-tree> <tx-tree> <doc> [<doc> ...]
  base-tree : 세션 base 체크아웃 (ko/en/ja 픽스처, 번역 전)
  tx-tree   : 번역 PR head 체크아웃 (ko 는 ko PR 이 바꾼 것)
  doc       : 문서 경로 (예: date-headings-gamebase.md)

판정 (heading `{ #id }` 로 짝짓는다):
  [new]     ko 에 새로 생긴 날짜 헤딩 — en 은 `Month D, YYYY` (버전이 있으면
            `버전 (Month D, YYYY)`, 괄호 앞 공백 하나), ja 는 ko 줄 그대로.
  [kept]    ko 가 바꾸지 않은 날짜 헤딩 — en/ja 가 base 의 줄과 바이트 동일.
  [hangul]  새 절의 en/ja 본문에 한글이 남지 않았다 (번역이 실제로 돌았다).

기대값 계산은 cloud-translate 를 import 하지 않고 여기서 따로 한다 — 판정기가
판정 대상 코드를 빌려 쓰면 같은 버그를 같이 갖는다.

exit 0 = DATE_HEADINGS: OK · 3 = REPRO (결함 재현) · 1 = 판정 불가
"""
import re
import sys
from pathlib import Path

MONTHS = ["January", "February", "March", "April", "May", "June", "July",
          "August", "September", "October", "November", "December"]
HEAD = re.compile(
    r"^(?P<h>#{1,6}[ \t]+)"
    r"(?:(?P<ver>v?\d+(?:\.\d+)+(?:-[0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)?)[ \t]*\()?"
    r"(?P<y>\d{4})\.[ \t]?(?P<m>\d{1,2})\.[ \t]?(?P<d>\d{1,2})\.?(?P<c>\))?"
    r"(?P<attr>[ \t]*\{[^{}]*\})?[ \t]*$")
ATTR_ID = re.compile(r"\{[^{}]*#([^\s}]+)[^{}]*\}\s*$")
HANGUL = re.compile(r"[가-힣]")


def date_heading(line):
    m = HEAD.match(line)
    if not m or bool(m.group("ver")) != bool(m.group("c")):
        return None
    return m


def expected(line, lang):
    if lang == "ja":
        return line
    m = date_heading(line)
    date = f"{MONTHS[int(m.group('m')) - 1]} {int(m.group('d'))}, {m.group('y')}"
    if m.group("ver"):
        date = f"{m.group('ver')} ({date})"
    return f"{m.group('h')}{date}{m.group('attr') or ''}"


def headings(text):
    out = {}
    for ln in text.splitlines():
        if ln.startswith("#"):
            m = ATTR_ID.search(ln)
            if m:
                out.setdefault(m.group(1), ln)
    return out


def section_lines(text, hid):
    """Lines from the heading with id `hid` up to the next heading of the same
    or higher level."""
    lines = text.splitlines()
    for i, ln in enumerate(lines):
        m = ATTR_ID.search(ln) if ln.startswith("#") else None
        if m and m.group(1) == hid:
            lvl = len(ln) - len(ln.lstrip("#"))
            out = []
            for nxt in lines[i + 1:]:
                if nxt.startswith("#") and len(nxt) - len(nxt.lstrip("#")) <= lvl:
                    break
                out.append(nxt)
            return out
    return []


def main():
    base, tx, docs = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3:]
    fails = 0
    for doc in docs:
        ko_old = headings((base / "ko" / doc).read_text())
        ko_new_text = (tx / "ko" / doc).read_text()
        ko_new = headings(ko_new_text)
        print(f"== {doc}")
        for lang in ("en", "ja"):
            tgt_old = headings((base / lang / doc).read_text())
            tgt_text = (tx / lang / doc).read_text()
            tgt_new = headings(tgt_text)
            for hid, line in ko_new.items():
                if not date_heading(line):
                    continue
                got = tgt_new.get(hid)
                if ko_old.get(hid) == line:
                    want, tag = tgt_old.get(hid), "kept"
                else:
                    want, tag = expected(line, lang), "new"
                ok = got == want
                fails += not ok
                print(f"  {'PASS' if ok else 'FAIL'}  [{tag}] {lang} #{hid}")
                if not ok:
                    print(f"          want: {want!r}\n          got : {got!r}")
                if tag == "new":
                    left = [ln for ln in section_lines(tgt_text, hid)
                            if HANGUL.search(ln)]
                    fails += bool(left)
                    print(f"  {'PASS' if not left else 'FAIL'}  [hangul] {lang} "
                          f"#{hid} 본문 한글 잔존 {len(left)}줄")
    print()
    if fails:
        print(f"DATE_HEADINGS: REPRO ({fails} 건)")
        return 3
    print("DATE_HEADINGS: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
