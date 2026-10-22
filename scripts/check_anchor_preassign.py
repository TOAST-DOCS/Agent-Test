#!/usr/bin/env python3
"""section id 전처리 e2e 판정기 (모델 없음, `gh` 만).

두 단계를 따로 판정한다 — `--phase review` (검수가 head 에 id 를 커밋했나) ·
`--phase translate` (머지 뒤 번역 PR 이 ko 를 안 건드리고 en/ja 가 ko 의 id 를
그대로 받았나). `--label BEFORE` 는 기대를 뒤집는다 (전처리 off = 오늘 동작):
review 단계에서 head 가 그대로이고, translate 단계에서 번역 PR 에 ko 커밋이
생기는 것이 REPRO 다.

exit 0 = OK · 3 = REPRO (기대와 다름) · 2 = 판정 불가.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ANCHOR_RE = re.compile(r'^<a id="([^"]+)"></a>$', re.M)
HEADING_RE = re.compile(r"^(#{2,6}) (.*?)(?: \{ #([^}]+) \})?\s*$", re.M)
MARKER_RE = re.compile(r"<!--\s*pre-align:aligned\s+sig=([0-9a-f]+)\s*-->")
COMMIT_MSG = "Assign section ids to new headings in "
TRANSLATE_KO_MSG = "Assign id anchors to new sections in ko/"


def gh(*args: str):
    out = subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout
    return json.loads(out) if out.strip().startswith(("{", "[")) else out


def file_at(repo: str, path: str, ref: str) -> str:
    return subprocess.run(
        ["gh", "api", f"repos/{repo}/contents/{path}?ref={ref}", "-H", "Accept: application/vnd.github.raw"],
        check=True, capture_output=True, text=True).stdout


def anchors(text: str) -> list[str]:
    return ANCHOR_RE.findall(text)


def phase_review(a) -> list[str]:
    fails: list[str] = []
    pr = gh("api", f"repos/{a.repo}/pulls/{a.ko_pr}")
    head = pr["head"]["sha"]
    moved = head != a.head_before
    print(f"  head: {a.head_before[:8]} -> {head[:8]} ({'moved' if moved else 'same'})")
    if a.label == "BEFORE":
        if moved:
            fails.append("BEFORE 인데 head 가 바뀌었다 (전처리가 꺼져 있어야 한다)")
        text = file_at(a.repo, a.doc, head)
        new = [h for h in HEADING_RE.findall(text) if h[1].strip() in a.new_headings]
        for lvl, title, attr in new:
            if attr:
                fails.append(f"BEFORE 인데 `{title}` 에 {{ #id }} 가 있다")
        print(f"  BEFORE: 새 heading {len(new)}개, id 없음 — {'OK' if not fails else 'FAIL'}")
        return fails
    if not moved:
        fails.append("head 가 그대로다 — 전처리 커밋이 없다")
        return fails
    commits = gh("api", f"repos/{a.repo}/pulls/{a.ko_pr}/commits")
    last = commits[-1]
    if last["sha"] != head:
        fails.append(f"PR 마지막 커밋 {last['sha'][:8]} ≠ head {head[:8]}")
    msg = last["commit"]["message"].splitlines()[0]
    if not msg.startswith(COMMIT_MSG):
        fails.append(f"마지막 커밋 메시지가 전처리 모양이 아님: {msg!r}")
    else:
        print(f"  commit: {msg}")
    before = file_at(a.repo, a.doc, a.head_before)
    after = file_at(a.repo, a.doc, head)
    ab, aa = anchors(before), anchors(after)
    if aa[:len(ab)] != ab:
        fails.append("기존 `<a id>` 순서·값이 바뀌었다")
    added = aa[len(ab):]
    print(f"  anchors: {len(ab)} -> {len(aa)} (+{len(added)}: {added})")
    heads = {t.strip(): (len(l), attr) for l, t, attr in HEADING_RE.findall(after)}
    # 새 heading 마다: 바로 위에 <a id>, h2/h3 는 { #id } 가 같은 값, h4 는 attr 없음.
    lines = after.splitlines()
    prev_id: dict[str, str] = {}
    for i, ln in enumerate(lines):
        m = HEADING_RE.match(ln)
        if not m or m.group(2).strip() not in a.new_headings:
            continue
        title = m.group(2).strip()
        level = len(m.group(1))
        above = ANCHOR_RE.match(lines[i - 1]) if i else None
        if not above:
            fails.append(f"`{title}` 바로 위에 <a id> 가 없다")
            continue
        aid = above.group(1)
        prev_id[title] = aid
        attr = m.group(3)
        if level <= 3 and attr != aid:
            fails.append(f"`{title}` (h{level}) 의 {{ #id }} 가 {attr!r} ≠ <a id> {aid!r}")
        if level >= 4 and attr:
            fails.append(f"`{title}` (h{level}) 에 {{ #id }} 가 있다 — h4 는 <a id> 만")
        print(f"  h{level} `{title}` -> {aid}" + (f" {{ #{attr} }}" if attr else ""))
    if len(prev_id) != len(a.new_headings):
        fails.append(f"새 heading {len(a.new_headings)}개 중 {len(prev_id)}개만 id 를 받았다")
    # h4 는 상위 h3 id 접두.
    h3 = [t for t in a.new_headings if heads.get(t, (0, None))[0] == 3]
    h4 = [t for t in a.new_headings if heads.get(t, (0, None))[0] == 4]
    for t in h4:
        if h3 and prev_id.get(t, "") and not prev_id[t].startswith(prev_id.get(h3[0], "") + "-"):
            fails.append(f"h4 `{t}` id {prev_id[t]!r} 가 상위 h3 id {prev_id.get(h3[0])!r} 로 시작하지 않는다")
    if len(set(aa)) != len(aa):
        fails.append("문서 안에 중복 id 가 있다")
    # marker sig 갱신.
    mm = MARKER_RE.search(after)
    if mm:
        sys.path.insert(0, str(Path(a.cloud_translate_dir) / "pre-align"))
        sys.path.insert(0, str(Path(a.cloud_translate_dir)))
        from align_apply import alignment_signature  # noqa: E402
        sig = alignment_signature(after)
        print(f"  marker: {mm.group(1)} (outline {sig})")
        if mm.group(1) != sig:
            fails.append(f"marker sig {mm.group(1)} ≠ outline {sig} — 번역 잡이 marker 를 다시 커밋한다")
    # 인라인 코멘트가 있으면 전부 새 head 에 앵커돼야 한다.
    inline = gh("api", f"repos/{a.repo}/pulls/{a.ko_pr}/comments", "--paginate")
    stale = [c["id"] for c in inline if c.get("commit_id") != head]
    print(f"  inline comments: {len(inline)} (stale commit_id: {len(stale)})")
    if stale:
        fails.append(f"인라인 코멘트 {len(stale)}건이 옛 head 에 앵커됐다")
    return fails


def phase_translate(a) -> list[str]:
    fails: list[str] = []
    files = gh("api", f"repos/{a.repo}/pulls/{a.translation_pr}/files", "--paginate")
    ko_files = [f["filename"] for f in files if f["filename"].startswith("ko/")]
    commits = gh("api", f"repos/{a.repo}/pulls/{a.translation_pr}/commits", "--paginate")
    ko_anchor_commits = [c["commit"]["message"].splitlines()[0] for c in commits
                         if TRANSLATE_KO_MSG in c["commit"]["message"]]
    print(f"  translation PR files: {len(files)} (ko: {ko_files})")
    print(f"  'Assign id anchors … ko' commits: {len(ko_anchor_commits)}")
    tpr = gh("api", f"repos/{a.repo}/pulls/{a.translation_pr}")
    head = tpr["head"]["sha"]
    ko = anchors(file_at(a.repo, a.doc, head))
    rel = a.doc.split("/", 1)[1]
    for lang in ("en", "ja"):
        tx = anchors(file_at(a.repo, f"{lang}/{rel}", head))
        same = tx == ko
        print(f"  {lang} anchors == ko: {same} ({len(tx)} vs {len(ko)})")
        if not same:
            fails.append(f"{lang}/{rel} 의 <a id> 순서가 ko 와 다르다")
    if a.label == "BEFORE":
        if not ko_files or not ko_anchor_commits:
            fails.append("BEFORE 인데 번역 PR 이 ko 를 안 건드렸다 (오늘 동작은 머지 뒤 ko 에 id 를 찍는다)")
        return fails
    if ko_files:
        fails.append(f"번역 PR 이 ko 를 건드렸다: {ko_files}")
    if ko_anchor_commits:
        fails.append(f"번역 PR 에 ko anchor 커밋이 있다: {ko_anchor_commits}")
    return fails


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", choices=["review", "translate"], required=True)
    ap.add_argument("--repo", default="TOAST-DOCS/Agent-Test")
    ap.add_argument("--ko-pr", type=int, required=True)
    ap.add_argument("--translation-pr", type=int)
    ap.add_argument("--head-before", default="")
    ap.add_argument("--doc", default="ko/fix-links.md")
    ap.add_argument("--new-heading", action="append", default=[], dest="new_headings")
    ap.add_argument("--label", choices=["BEFORE", "AFTER"], default="AFTER")
    ap.add_argument("--cloud-translate-dir", default=str(Path.home() / "works/cloud-translate"))
    a = ap.parse_args()
    if a.phase == "review" and not a.head_before:
        print("--head-before 필요", file=sys.stderr)
        return 2
    if a.phase == "translate" and not a.translation_pr:
        print("--translation-pr 필요", file=sys.stderr)
        return 2
    print(f"[{a.label}] phase={a.phase} {a.repo}#{a.ko_pr}")
    fails = phase_review(a) if a.phase == "review" else phase_translate(a)
    for f in fails:
        print(f"  FAIL: {f}")
    print(f"ANCHOR_PREASSIGN[{a.phase}]: " + ("OK" if not fails else f"REPRO {len(fails)}"))
    return 0 if not fails else 3


if __name__ == "__main__":
    sys.exit(main())
