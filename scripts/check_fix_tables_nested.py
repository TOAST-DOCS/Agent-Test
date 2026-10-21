#!/usr/bin/env python3
"""깨진 표 정비가 목록 안 표의 들여쓰기를 지키는지 판정한다 (모델 없음, 결정적).

cloud-translate#<PR> · TOAST-DOCS/EasyMaker#239 — 표 전체 수리가 목록 항목 안에
4칸 들여쓴 표의 **머리행만** 0칸으로 돌려 놓았다. 소스 파서는 그것도 표 하나로
세지만 사이트 렌더러는 머리행에서 목록을 끊어 표가 목록 밖으로 빠진다.

판정 (언어마다, 절(`<a id>`)마다):
  [A] 고친 절의 표 — 줄마다 들여쓰기 == ko 같은 순번 표의 머리행 들여쓰기,
      ko 첫 열 식별자가 전부 있다
  [B] 사이트 렌더(python-markdown, cloud-translate `shared.markup_lint`) —
      `<li>` 안 표 수 · 목록(`<ul>`/`<ol>`) 수 == ko
  [C] 대조군 — 고치지 않을 절(`fix-tables-nested-sample`, `…-untouched`)이 base 와 바이트 동일

usage: check_fix_tables_nested.py --ko KO --base-en F --base-ja F --en F --ja F
                                  --cloud-translate-dir DIR
exit: 0 = FIX_TABLES_NESTED: OK · 3 = REPRO ([A]/[B] 실패) · 1 = 대조군 등 그 밖의 실패
"""
import argparse
import re
import sys

REPAIRED = ("fix-tables-nested-list", "fix-tables-nested-deep", "fix-tables-nested-top")
CONTROLS = ("fix-tables-nested-sample", "fix-tables-nested-untouched")
ANCHOR_RE = re.compile(r'^<a id="([^"]+)"></a>\s*$')


def sections(text):
    out, cur, buf = {}, None, []
    for ln in text.splitlines(keepends=True):
        m = ANCHOR_RE.match(ln)
        if m:
            if cur:
                out[cur] = "".join(buf)
            cur, buf = m.group(1), []
        buf.append(ln)
    if cur:
        out[cur] = "".join(buf)
    return out


def tables(text):
    """[(header_indent, [line indents], [first-cell keys])] — `|` 로 시작하는 연속 줄."""
    res, cur = [], []
    for ln in text.splitlines() + [""]:
        if ln.lstrip().startswith("|"):
            cur.append(ln)
            continue
        if len(cur) >= 2:
            ind = [len(l) - len(l.lstrip(" ")) for l in cur]
            keys = [l.strip().strip("|").split("|")[0].strip() for l in cur[2:]]
            res.append((ind[0], ind, keys))
        cur = []
    return res


def render_counts(conv, text):
    conv.reset()
    html = conv.convert(text)
    in_li = sum(1 for li in re.findall(r"<li>.*?</li>", html, re.S) if "<table>" in li)
    return in_li, html.count("<ul>") + html.count("<ol>"), html.count("<table>")


def main():
    ap = argparse.ArgumentParser()
    for k in ("ko", "base-en", "base-ja", "en", "ja", "cloud-translate-dir"):
        ap.add_argument(f"--{k}", required=True)
    a = ap.parse_args()
    sys.path.insert(0, a.cloud_translate_dir)
    from shared.markup_lint import _converter
    conv = _converter()

    read = lambda p: open(p, encoding="utf-8").read()
    ko = sections(read(a.ko))
    repro = other = 0
    for lang, base_p, out_p in (("en", a.base_en, a.en), ("ja", a.base_ja, a.ja)):
        base, out = sections(read(base_p)), sections(read(out_p))
        for sid in REPAIRED:
            kt, ot = tables(ko[sid]), tables(out.get(sid, ""))
            if len(kt) != len(ot):
                print(f"  ✗ [A] {lang} #{sid}: 표 {len(ot)} ≠ ko {len(kt)}"); repro += 1; continue
            for i, ((kh, _ki, kk), (_oh, oi, ok)) in enumerate(zip(kt, ot), 1):
                bad = [n for n, w in enumerate(oi) if w != kh]
                if bad:
                    print(f"  ✗ [A] {lang} #{sid} 표{i}: 들여쓰기 {oi} ≠ ko {kh}칸"
                          f" (어긋난 줄 {bad})"); repro += 1
                miss = [k for k in kk if k not in ok]
                if miss:
                    print(f"  ✗ [A] {lang} #{sid} 표{i}: ko 식별자 없음 {miss}"); repro += 1
            kr, orr = render_counts(conv, ko[sid]), render_counts(conv, out.get(sid, ""))
            if kr[:2] != orr[:2]:
                print(f"  ✗ [B] {lang} #{sid}: 렌더 (li 안 표, 목록 수) {orr[:2]} ≠ ko {kr[:2]}")
                repro += 1
            else:
                print(f"  ✓ [B] {lang} #{sid}: 렌더 (li 안 표, 목록 수) {orr[:2]} == ko")
        for sid in CONTROLS:
            if out.get(sid) != base.get(sid):
                print(f"  ✗ [C] {lang} #{sid}: 대조군이 바뀌었다"); other += 1
            else:
                print(f"  ✓ [C] {lang} #{sid}: 바이트 동일")
    if repro:
        print(f"FIX_TABLES_NESTED: REPRO {repro}")
        return 3
    if other:
        print(f"FIX_TABLES_NESTED: FAIL {other}")
        return 1
    print("FIX_TABLES_NESTED: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
