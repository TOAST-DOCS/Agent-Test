#!/usr/bin/env python3
r"""Deterministic verifier for the template-tags fixture (`e2e-template-tags.sh`).

Compares a ko document with its en/ja translations and grades eight rules that
together say "the page still builds, and the Korean the author put INSIDE a tag
was translated". No model is involved.

    python3 scripts/check_template_tags.py --ko ko.md --tr en=en.md --tr ja=ja.md \
        [--base en=base_en.md --base ja=base_ja.md --changed _head,tt-inline-literal,...]

Rules (each printed as PASS/FAIL per language; exit code = number of failures):

  (1) tag parity — same number of unfenced tags in the same order. A ko tag with
      Korean in it is compared by STRUCTURE (same string literals in the same
      places, any text inside; quote style and whitespace ignored; `-`/`+`
      whitespace-control markers exact — or, for a tag with no literal, the same
      delimiters). Every other tag must be byte-identical.
  (2) no Hangul inside any tag of the translation (outside fences).
  (3) every fenced code block byte-identical to ko's, in order.
  (4) the translation parses AND renders with the site's Jinja config
      (`$[ ]$` variable delimiters, StrictUndefined) for build_flags public / gov /
      ngsc; no placeholder token (`XTPLTAG`, `XCODEBLOCK`) survives; no `\_`
      escape inside a tag.
  (5) every ko tag that carries Korean came back DIFFERENT — i.e. it was
      translated, not copied.
  (6) no Hangul anywhere in the translation outside fences.
  (7) [with --base] sections NOT listed in --changed are byte-identical to the
      base translation; sections listed are different (the edit reached them).
      Sections are split at `<a id="…">` lines; text before the first anchor is
      the section `_head`.
  (8) [with --base] Korean-literal tags inside changed sections differ from the
      base translation's tag at the same position (the literal edit reached the
      translated literal, not only the prose around it).

The structure comparison is a deliberately independent re-implementation of
`translate/app/md_text.py::_tags_same_structure` — a second opinion, so a drift
between the two shows up here as a finding instead of being hidden.
"""
import argparse
import io
import re
import sys

TAG_RE = re.compile(
    r"\{%(?:(?!\{%).)*?%\}|\{\{(?:(?!\{\{).)*?\}\}|\$\[(?:(?!\$\[).)*?\]\$", re.DOTALL
)
LIT_RE = re.compile(r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'', re.DOTALL)
HANGUL = re.compile(r"[가-힣]")
ANCHOR_LINE = re.compile(r'^<a id="([^"]+)"></a>\s*$', re.M)
PLACEHOLDER = re.compile(r"XTPLTAG\d+X|XCODEBLOCK\d+X")


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


def fenced_flags(text):
    """Per-char True inside a fenced block (``` or ~~~, CommonMark run rules)."""
    flags = bytearray(len(text))
    pos = 0
    open_ch, open_len = None, 0
    for line in text.splitlines(keepends=True):
        s = line.strip()
        inside = open_ch is not None
        if open_ch is None:
            for ch in ("`", "~"):
                if s.startswith(ch * 3):
                    open_ch, open_len = ch, len(s) - len(s.lstrip(ch))
                    inside = True
                    break
        else:
            if len(s) >= open_len and s == open_ch * len(s):
                open_ch = None
        if inside:
            flags[pos:pos + len(line)] = b"\x01" * len(line)
        pos += len(line)
    return flags


def fenced_blocks(text):
    out, cur = [], []
    open_ch, open_len = None, 0
    for line in text.splitlines(keepends=True):
        s = line.strip()
        if open_ch is None:
            for ch in ("`", "~"):
                if s.startswith(ch * 3):
                    open_ch, open_len = ch, len(s) - len(s.lstrip(ch))
                    cur = [line]
                    break
        else:
            cur.append(line)
            if len(s) >= open_len and s == open_ch * len(s):
                out.append("".join(cur)); open_ch = None; cur = []
    return out


def tags(text):
    f = fenced_flags(text)
    return [m.group(0) for m in TAG_RE.finditer(text) if not any(f[i] for i in range(m.start(), m.end()))]


def skeleton(tag):
    return LIT_RE.sub(lambda m: m.group(0)[0] * 2, tag)


def structure_key(tag):
    if LIT_RE.search(tag):
        return ("skeleton", re.sub(r"\s+", "", skeleton(tag)).replace("'", '"'))
    return ("delims", tag[:2], tag[-2:])


def same_structure(src, got):
    return structure_key(src) == structure_key(got)


def sections(text):
    """{anchor_id: body} with `_head` for the text before the first anchor."""
    out, last_id, last = {}, "_head", 0
    for m in ANCHOR_LINE.finditer(text):
        out[last_id] = text[last:m.start()]
        last_id, last = m.group(1), m.start()
    out[last_id] = text[last:]
    return out


def outside_fences(text):
    f = fenced_flags(text)
    return "".join(ch for i, ch in enumerate(text) if not f[i])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ko", required=True)
    ap.add_argument("--tr", action="append", default=[], help="lang=path")
    ap.add_argument("--base", action="append", default=[], help="lang=path (pre-run translation)")
    ap.add_argument("--changed", default="", help="comma list of section ids the ko edit touched")
    a = ap.parse_args()

    ko = read(a.ko)
    ko_tags = tags(ko)
    ko_fences = fenced_blocks(ko)
    ko_kor = [i for i, t in enumerate(ko_tags) if HANGUL.search(t)]
    changed = {s for s in a.changed.split(",") if s}
    bases = dict(kv.split("=", 1) for kv in a.base)
    fails = 0

    def ok(lang, msg):
        print(f"  PASS  [{lang}] {msg}")

    def bad(lang, msg):
        nonlocal fails
        fails += 1
        print(f"  FAIL  [{lang}] {msg}")

    print(f"  ko: {len(ko_tags)} tags, {len(ko_kor)} carry Korean, {len(ko_fences)} fenced block(s)")

    for kv in a.tr:
        lang, path = kv.split("=", 1)
        tr = read(path)
        tr_tags = tags(tr)

        # (1) parity
        if len(tr_tags) != len(ko_tags):
            bad(lang, f"(1) tag count {len(tr_tags)} != ko {len(ko_tags)}")
        else:
            problems = []
            for i, (w, g) in enumerate(zip(ko_tags, tr_tags)):
                if HANGUL.search(w):
                    if not same_structure(w, g):
                        problems.append(f"#{i} structure: {w[:50]!r} -> {g[:50]!r}")
                elif w != g:
                    problems.append(f"#{i} bytes: {w[:50]!r} -> {g[:50]!r}")
            if problems:
                bad(lang, f"(1) tag parity — {len(problems)} tag(s) off")
                for p in problems[:6]:
                    print("          " + p)
            else:
                ok(lang, f"(1) tag parity — {len(ko_tags)} tags, {len(ko_kor)} by structure, rest byte-identical")

        # (2) Hangul inside tags
        hk = [t for t in tr_tags if HANGUL.search(t)]
        if hk:
            bad(lang, f"(2) Hangul inside {len(hk)} tag(s): {hk[:3]}")
        else:
            ok(lang, "(2) no Hangul inside any tag")

        # (3) fences byte-identical
        tf = fenced_blocks(tr)
        if tf == ko_fences:
            ok(lang, f"(3) {len(tf)} fenced block(s) byte-identical to ko")
        else:
            bad(lang, f"(3) fenced blocks differ from ko ({len(tf)} vs {len(ko_fences)})")

        # (4) Jinja render + no placeholders + no escaped underscore in tags
        try:
            import jinja2
            env = jinja2.Environment(variable_start_string="$[", variable_end_string="]$",
                                     undefined=jinja2.StrictUndefined)
            tpl = env.from_string(tr)
            for flags in (["public"], ["gov"], ["ngsc"]):
                tpl.render(build_flags=flags)
            ok(lang, "(4a) Jinja parses and renders for public/gov/ngsc")
        except Exception as e:  # noqa: BLE001
            bad(lang, f"(4a) Jinja: {type(e).__name__}: {str(e)[:120]}")
        if PLACEHOLDER.search(tr):
            bad(lang, f"(4b) placeholder token survived: {PLACEHOLDER.findall(tr)[:3]}")
        else:
            ok(lang, "(4b) no placeholder token survived")
        esc = [t for t in tr_tags if "\\_" in t]
        if esc:
            bad(lang, f"(4c) escaped underscore inside tag(s): {esc[:3]}")
        else:
            ok(lang, "(4c) no `\\_` inside tags")

        # (5) Korean tags translated (not copied)
        if len(tr_tags) == len(ko_tags):
            copied = [ko_tags[i] for i in ko_kor if tr_tags[i] == ko_tags[i]]
            if copied:
                bad(lang, f"(5) {len(copied)} Korean tag(s) copied verbatim: {copied[:3]}")
            else:
                ok(lang, f"(5) all {len(ko_kor)} Korean tags came back changed")

        # (6) no Hangul outside fences
        left = HANGUL.findall(outside_fences(tr))
        if left:
            lines = [ln for ln in outside_fences(tr).splitlines() if HANGUL.search(ln)]
            bad(lang, f"(6) Hangul left outside fences on {len(lines)} line(s): {lines[0][:80]!r}")
        else:
            ok(lang, "(6) no Hangul outside fences")

        # (7)/(8) splice: unchanged sections byte-identical to base, changed ones differ
        if lang in bases:
            base = read(bases[lang])
            bs, ts = sections(base), sections(tr)
            if set(bs) != set(ts):
                bad(lang, f"(7) section set differs from base: {sorted(set(bs) ^ set(ts))}")
            else:
                same_bad = [s for s in bs if s not in changed and bs[s] != ts[s]]
                diff_bad = [s for s in bs if s in changed and bs[s] == ts[s]]
                if same_bad:
                    bad(lang, f"(7a) unchanged section(s) drifted from base: {same_bad}")
                else:
                    ok(lang, f"(7a) {len(bs) - len(changed & set(bs))} unchanged section(s) byte-identical to base")
                if diff_bad:
                    bad(lang, f"(7b) changed section(s) identical to base (edit not reflected): {diff_bad}")
                else:
                    ok(lang, f"(7b) {len(changed & set(bs))} changed section(s) differ from base")
            base_tags = tags(base)
            if len(base_tags) == len(tr_tags) == len(ko_tags):
                # Korean-literal tags whose SECTION changed must have moved too.
                moved, stuck = [], []
                for i in ko_kor:
                    # locate the section of this tag in ko
                    pos = ko.find(ko_tags[i])
                    sec = "_head"
                    for m in ANCHOR_LINE.finditer(ko):
                        if m.start() <= pos:
                            sec = m.group(1)
                    if sec in changed:
                        (moved if base_tags[i] != tr_tags[i] else stuck).append((sec, ko_tags[i][:40]))
                # Only the head's literal edit (M1) is REQUIRED to move the tag:
                # the other changed sections edit prose next to a tag, whose
                # translated literal may legitimately stay as it was.
                if "_head" in changed and not any(s == "_head" for s, _ in moved):
                    bad(lang, f"(8) head literal edit did not reach the translated tag ({stuck[:2]})")
                else:
                    ok(lang, f"(8) Korean-literal tags in changed sections: {len(moved)} moved, {len(stuck)} kept")

    print(f"  → {fails} failure(s)")
    return min(fails, 100)


if __name__ == "__main__":
    sys.exit(main())
