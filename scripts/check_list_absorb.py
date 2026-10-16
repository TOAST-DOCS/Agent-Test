#!/usr/bin/env python3
"""목록 흡수 판정 — 저자가 쓴 목록 표지·번호와 독자가 보는 표지·번호가 다른 항목을 센다.

python-markdown 은 목록 뒤 빈 줄 너머의 목록 항목을 종류가 달라도 앞 목록에 이어 붙인다
(글머리 `- 메모` 가 `8.` 로, 번호 `2. 단계` 가 `•` 로 보인다). GitHub 미리보기(CommonMark)는
새 목록을 시작하므로 소스로는 안 보인다. 그래서 판정은 **사이트와 같은 렌더러**로 한다 —
NHN-Cloud-Document-PUBLIC 의 mkdocs.<lang>.yml 과 같은 확장(admonition · attr_list · toc ·
pymdownx.superfences + mermaid · pymdownx.tabbed alternate_style), pymdown-extensions 11.0.1.

방법: 최상위(0~3칸) 목록 항목마다 고유 토큰을 심고 렌더해, 토큰이 든 <li> 의 부모가
<ul> 인지 <ol> 인지, <ol> 이면 몇 번째인지 읽는다. 텍스트 짝짓기가 아니라 토큰이라 결정적이다.

판정(절 = `## … { #id }` 단위):
  * 글머리로 쓴 항목이 <ol> 안에 있다 → 결함 (번호로 보임)
  * 번호로 쓴 항목이 <ul> 안에 있다   → 결함 (글머리로 보임)
  번호가 몇으로 보이는지는 세지 않는다 — `1.` 만 반복해 쓰는 관행이 있어 이 축의 판정이 아니다.

종료 코드: 0 = C 절 결함 0 · K(대조군) 절 결함 0 / 3 = C 절에 결함이 남음(REPRO) / 1 = 대조군이 깨짐.
--before PATH 를 주면 K 절의 소스가 PATH 와 바이트 같은지, 모든 절의 보이는 글자가 같은지도 본다
(수리가 대조군을 건드리거나 글자를 바꾸면 1).

Usage:
  python3 scripts/check_list_absorb.py ko/list-absorb-sample.md
  python3 scripts/check_list_absorb.py --before archive/list-absorb/ko/list-absorb-sample.md \
      archive/list-absorb/proposed/ko/list-absorb-sample.md
"""
from __future__ import annotations

import argparse
import re
import sys

import markdown
from bs4 import BeautifulSoup
from pymdownx.superfences import fence_div_format

EXT = ["admonition", "attr_list", "toc", "pymdownx.superfences", "pymdownx.tabbed"]
CFG = {"pymdownx.superfences": {"custom_fences": [
           {"name": "mermaid", "class": "mermaid", "format": fence_div_format}]},
       "pymdownx.tabbed": {"alternate_style": True}}
LI = re.compile(r"^(?P<ind> {0,3})(?P<mk>[-*+]|\d+\.)\s+(?P<rest>.*)")
HR = re.compile(r"^ {0,3}([-*_])(?:[ \t]*\1){2,}\s*$")
FENCE = re.compile(r"^\s*(```|~~~)")
SEC = re.compile(r"^## .*\{ #(?P<id>[^ }]+) \}\s*$")


def render(text: str) -> str:
    return markdown.Markdown(extensions=EXT, extension_configs=CFG).convert(text)


def items(lines):
    out, fence = [], False
    for i, ln in enumerate(lines):
        if FENCE.match(ln):
            fence = not fence
            continue
        if not fence and LI.match(ln) and not HR.match(ln):
            out.append(i)
    return out


def shown(lines):
    idx = items(lines)
    marked = list(lines)
    for i in idx:
        m = LI.match(marked[i])
        marked[i] = marked[i][:m.start("rest")] + f"QQ{i}QQ " + marked[i][m.start("rest"):]
    soup = BeautifulSoup(render("\n".join(marked)), "html.parser")
    res = {i: None for i in idx}
    for li in soup.find_all("li"):
        own = "".join(t for t in li.find_all(string=True) if t.find_parent("li") is li)
        for tok in re.findall(r"QQ(\d+)QQ", own):
            par = li.parent
            if par.name == "ol":
                pos = par.find_all("li", recursive=False).index(li)
                res[int(tok)] = f"ol#{int(par.get('start', 1)) + pos}"
            else:
                res[int(tok)] = par.name
    return res


def section_of(lines):
    cur, out = "_", []
    for ln in lines:
        m = SEC.match(ln)
        if m:
            cur = m.group("id")
        out.append(cur)
    return out


def visible_by_section(lines):
    sec = section_of(lines)
    out = {}
    for s in dict.fromkeys(sec):
        body = "\n".join(ln for ln, x in zip(lines, sec) if x == s)
        text = BeautifulSoup(render(body), "html.parser").get_text(" ")
        out[s] = re.sub(r"\s+", " ", text).strip()
    return out


def sections(lines):
    sec = section_of(lines)
    out = {}
    for s in dict.fromkeys(sec):
        out[s] = [ln for ln, x in zip(lines, sec) if x == s]
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--before")
    a = ap.parse_args()
    lines = open(a.path, encoding="utf-8").read().split("\n")
    sec = section_of(lines)
    bad: dict[str, list[str]] = {}
    for i, v in shown(lines).items():
        k = "ol" if LI.match(lines[i]).group("mk")[0].isdigit() else "ul"
        if v is None:
            continue
        if (k == "ul" and v != "ul") or (k == "ol" and v == "ul"):
            what = "번호로 보임" if k == "ul" else "글머리로 보임"
            bad.setdefault(sec[i], []).append(f"L{i + 1} {lines[i].strip()[:50]!r} → {v} ({what})")
    ids = [s for s in dict.fromkeys(sec) if s != "_"]
    rc = 0
    for s in ids:
        n = len(bad.get(s, []))
        ctl = s.startswith("k")
        tag = "OK" if n == 0 else ("CONTROL-BROKEN" if ctl else "REPRO")
        print(f"[{tag}] #{s}: 표지가 바뀐 항목 {n}")
        for b in bad.get(s, []):
            print("    " + b)
        if n and ctl:
            rc = 1
        elif n and rc == 0:
            rc = 3
    if a.before:
        bl = open(a.before, encoding="utf-8").read().split("\n")
        bs, ns = sections(bl), sections(lines)
        bv, nv = visible_by_section(bl), visible_by_section(lines)
        for s in ids:
            if s.startswith("k") and bs.get(s) != ns.get(s):
                print(f"[CONTROL-CHANGED] #{s}: 대조군 소스가 바뀌었다")
                rc = 1
            if bv.get(s) != nv.get(s):
                print(f"[TEXT-CHANGED] #{s}: 보이는 글자가 바뀌었다")
                rc = 1
    print("LIST_ABSORB:", {0: "OK", 3: "REPRO", 1: "FAIL"}[rc])
    return rc


if __name__ == "__main__":
    sys.exit(main())
