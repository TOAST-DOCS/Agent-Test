#!/usr/bin/env python3
r"""Verdict for the `jinja-mask` e2e plan — "the model never sees a template tag".

`e2e-align-and-translate.sh --plan jinja-mask` only reports ALIGNMENT, which looks
at headings, anchors and tables and never at `{% %}` / `$[ ]$`. This script is the
plan's actual judge. It reads the translation log and the translation PR and
grades four things — every one deterministic:

  (a) no `Template-tag mismatch` in the log — a unit whose tag sequence came back
      wrong even after the unprotected retry (the file is excluded from the PR).
  (b) no `falling back to unprotected` in the log — the model lost a placeholder
      and the unit was re-translated with its tags SHOWN to the model, which is
      exactly what the mask exists to prevent. Before cloud-translate#1297 this
      fired 4-5x per run on the fixture's own shapes (lone placeholder at a
      unit's edge · raw-tag unit-preserve baseline); after it, 0 is expected.
  (c) the mask was actually reached, on BOTH paths the fixture exercises — the
      `Masked N template tag(s)` debug line. `macro-shapes.md` is a full
      translation (no base en/ja), so its whole body is one masked call whose N
      equals the number of Korean-free tags in ko; `jinja-guide.md` is an
      incremental splice, whose units mask fewer. A run where neither shows up
      tested nothing — the "0 warnings" above would be vacuous (the markup-churn
      guard-skips lesson). Only visible at TRANSLATE_LOG_LEVEL=debug: without
      debug lines in the log this is reported as unmeasured, not passed, and
      `--require-debug` (local mode, where the harness sets the level) makes
      that a failure.
  (d) the translation PR's en/ja `jinja-guide.md` and `macro-shapes.md` pass
      `check_template_tags.py` against their ko at the same head — tag order,
      no Hangul in a tag, the site's Jinja (`$[ ]$`, StrictUndefined) parses and
      renders them for public/gov/ngsc, no placeholder token left. This is the
      artifact the reader gets; (a)-(c) are about how it was produced.

    python3 scripts/check_jinja_mask.py --log <translate log> --pr <translation PR url> \
        [--require-debug] [--unmeasured]

`--unmeasured` = the log is not available (api mode without Jenkins credentials):
(a)-(c) are printed as `?` and only (d) is graded.

Last line: `JINJA_MASK: OK|FAIL ...counters`. Exit code = number of failures.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_template_tags import HANGUL, tags  # noqa: E402

DOCS = ("jinja-guide.md", "macro-shapes.md")
FULL_DOC = "macro-shapes.md"
MASKED_RE = re.compile(r"Masked (\d+) template tag\(s\)")
DEBUG_RE = re.compile(r"\bapp\.translator DEBUG\b")


def gh(*args):
    return subprocess.run(["gh", *args], capture_output=True, text=True, check=True).stdout


def fetch(repo, sha, path):
    try:
        return gh("api", f"repos/{repo}/contents/{path}?ref={sha}",
                  "-H", "Accept: application/vnd.github.raw")
    except subprocess.CalledProcessError:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", help="translation log (plan log in local mode, Jenkins console in api mode)")
    ap.add_argument("--pr", required=True, help="translation PR URL")
    ap.add_argument("--require-debug", action="store_true",
                    help="missing debug lines are a failure, not 'unmeasured'")
    ap.add_argument("--unmeasured", action="store_true",
                    help="no log available — grade the artifact only")
    a = ap.parse_args()

    fails = 0

    def report(ok, label):
        nonlocal fails
        mark = {True: "PASS", False: "FAIL", None: "SKIP"}[ok]
        if ok is False:
            fails += 1
        print(f"  {mark}  {label}")

    m = re.match(r"https://github\.com/([^/]+/[^/]+)/pull/(\d+)", a.pr)
    if not m:
        print(f"error: not a PR url: {a.pr}", file=sys.stderr)
        return 2
    repo, num = m.group(1), m.group(2)
    head = gh("pr", "view", num, "--repo", repo, "--json", "headRefOid", "-q", ".headRefOid").strip()

    files = {}
    for doc in DOCS:
        for lang in ("ko", "en", "ja"):
            files[(lang, doc)] = fetch(repo, head, f"{lang}/{doc}")

    # ── (a)(b)(c) from the log ─────────────────────────────────────────────
    counters = {}
    if a.unmeasured or not a.log:
        for k in ("tag-mismatch", "unprotected-fallback", "masked-full", "masked-incr"):
            counters[k] = "?"
        report(None, "(a)(b)(c) log not available — unmeasured, artifact only")
    else:
        log = open(a.log, encoding="utf-8", errors="replace").read()
        mismatch = log.count("Template-tag mismatch")
        fallback = log.count("falling back to unprotected")
        counters["tag-mismatch"] = mismatch
        counters["unprotected-fallback"] = fallback
        report(mismatch == 0, f"(a) Template-tag mismatch = {mismatch}")
        report(fallback == 0, f"(b) falling back to unprotected = {fallback}")
        ko_full = files[("ko", FULL_DOC)]
        n_full = (sum(1 for t in tags(ko_full) if not HANGUL.search(t))
                  if ko_full is not None else None)
        masked = [int(x) for x in MASKED_RE.findall(log)]
        if not DEBUG_RE.search(log):
            counters["masked-full"] = counters["masked-incr"] = "?"
            report(False if a.require_debug else None,
                   "(c) no debug lines in the log (TRANSLATE_LOG_LEVEL=debug not in effect)"
                   + (" — required" if a.require_debug else " — unmeasured"))
        else:
            full = sum(1 for n in masked if n == n_full)
            incr = len(masked) - full
            counters["masked-full"] = full
            counters["masked-incr"] = incr
            report(full >= 1, f"(c) full path ({FULL_DOC}, {n_full} Korean-free tags) masked in "
                              f"{full} call(s)")
            report(incr >= 1, f"(c) incremental path (jinja-guide.md units) masked in {incr} call(s)")

    # ── (d) the artifact ──────────────────────────────────────────────────
    art_fail = 0
    here = os.path.dirname(os.path.abspath(__file__))
    with tempfile.TemporaryDirectory() as td:
        for doc in DOCS:
            missing = [lang for lang in ("ko", "en", "ja") if files[(lang, doc)] is None]
            if missing:
                art_fail += 1
                report(False, f"(d) {doc}: missing at PR head {head[:10]} ({', '.join(missing)})")
                continue
            paths = {}
            for lang in ("ko", "en", "ja"):
                paths[lang] = os.path.join(td, f"{lang}-{doc}")
                with open(paths[lang], "w", encoding="utf-8", newline="") as f:
                    f.write(files[(lang, doc)])
            r = subprocess.run(
                [sys.executable, os.path.join(here, "check_template_tags.py"),
                 "--ko", paths["ko"], "--tr", f"en={paths['en']}", "--tr", f"ja={paths['ja']}"],
                capture_output=True, text=True)
            bad = [ln.strip() for ln in r.stdout.splitlines() if ln.strip().startswith("FAIL")]
            art_fail += len(bad)
            report(not bad, f"(d) {doc}: check_template_tags {len(bad)} failure(s)")
            for ln in bad:
                print(f"        {ln}")
    counters["artifact-fail"] = art_fail

    tail = " ".join(f"{k}={v}" for k, v in counters.items())
    print(f"JINJA_MASK: {'OK' if fails == 0 else 'FAIL'} {tail} (PR head {head[:10]})")
    return fails


if __name__ == "__main__":
    sys.exit(main())
