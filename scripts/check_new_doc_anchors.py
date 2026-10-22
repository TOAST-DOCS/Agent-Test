#!/usr/bin/env python3
"""new-doc-anchors e2e 의 판정 — 번역 PR head 에서 heading id 를 잰다 (모델 없음).

재현하는 사고 (Dooray cloud-user-guide-agent, 2026-10-20 · 10-22):
  ko PR 이 **새 문서**(release-notes.md)를 추가하면 번역 잡이 en/ja 를 통째로
  번역하고 세 언어에 pre-align marker 를 찍는데, 앵커 부여(`_assign_anchors`)는
  건너뛴다 — h2~h4 heading 전부에 id 가 없다. 세 언어 모두 id 가 없으니 잡의
  outline 대조는 "✅ 모두 일치" 로 적고, marker 가 유효해서 pre-align 도 다시 보지
  않는다. TOAST-DOCS/VPN-Gateway#15 → #16 (보정 커밋 f39e6fd),
  TOAST-DOCS/Network-ACL#14 → #15 (보정 커밋 5056547). 수정: cloud-translate#1364.

판정은 cloud-translate 의 `dashboard/tools/merged_review.heading_id_verdict` 와
같다 — outline 은 `pre-align/align_headings.parse_units` 를 그대로 import 해 잰다
(`CLOUD_TRANSLATE_DIR`, 기본 ~/works/cloud-translate. httpx 가 있는 venv 로 돌릴 것).

  새 문서 (--new)
    [A] head 에 ko/en/ja 가 모두 있다
    [B] 언어마다 h2~h{MAX_ID_LEVEL} heading 중 id 없는 것 0          ← 사고 모양
    [C] (level, id) outline 이 ko == en == ja
    [D] ko heading 텍스트 수열이 ko PR 의 입력(--ko-src)과 같다 (heading 을 건드리지 않았다)
    [i] marker 유무는 정보로만 출력한다
  대조군 (--control) — 이미 정렬된 기존 문서, ko PR 은 본문 한 줄만 고쳤다
    [E] 언어마다 head 의 (level, id) outline == 세션 base 의 outline (id 바이트 보존)

exit: 0 OK · 3 REPRO · 2 인프라(파일 없음 · import 실패)

Usage:
  CLOUD_TRANSLATE_DIR=<cloud-translate> <venv>/bin/python scripts/check_new_doc_anchors.py \\
      --base <세션 base 체크아웃> --head <번역 PR head 체크아웃> \\
      --new new-doc-anchors.md --ko-src archive/new-doc-anchors/ko-new/new-doc-anchors.md \\
      --control new-doc-anchors-control.md
"""
from __future__ import annotations

import argparse
import os
import pathlib
import sys

LANGS = ("ko", "en", "ja")
MARKER = "pre-align:aligned"


def _load_parse_units():
    ct = pathlib.Path(os.environ.get(
        "CLOUD_TRANSLATE_DIR", pathlib.Path.home() / "works" / "cloud-translate"))
    sys.path[:0] = [str(ct), str(ct / "pre-align")]
    import align_headings  # type: ignore  (httpx 가 있는 venv 필요)
    return align_headings.parse_units, align_headings.MAX_ID_LEVEL


def outline(text, parse_units):
    """``[(level, anchor_id|None, heading_text)]`` — merged_review.heading_outline 과 같다."""
    return [(u.level, u.anchor_id, u.heading_text) for u in parse_units(text or "")[1]]


def _read(root: pathlib.Path, lang: str, doc: str):
    p = root / lang / doc
    return p.read_text(encoding="utf-8") if p.is_file() else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True, type=pathlib.Path)
    ap.add_argument("--head", required=True, type=pathlib.Path)
    ap.add_argument("--new", required=True, help="새 문서의 언어-상대 경로")
    ap.add_argument("--ko-src", required=True, type=pathlib.Path, help="ko PR 이 추가한 ko 원문")
    ap.add_argument("--control", default="", help="대조군 문서의 언어-상대 경로")
    a = ap.parse_args()

    try:
        parse_units, max_lv = _load_parse_units()
    except Exception as e:  # noqa: BLE001
        print(f"error: pre-align/align_headings 를 못 읽음 ({type(e).__name__}: {e}) — "
              "CLOUD_TRANSLATE_DIR 와 venv 를 확인")
        return 2

    fails: list[str] = []
    print(f"── 새 문서 {a.new}")
    texts = {l: _read(a.head, l, a.new) for l in LANGS}
    missing_files = [l for l, t in texts.items() if t is None]
    if missing_files:
        print(f"  [A] ✗ head 에 없음: {', '.join(f'{l}/{a.new}' for l in missing_files)}")
        return 2
    print("  [A] ✓ ko/en/ja 모두 있음")

    ols = {l: outline(texts[l], parse_units) for l in LANGS}
    for l in LANGS:
        need = [h for h in ols[l] if h[0] <= max_lv]
        no_id = [h for h in need if not h[1]]
        mark = "marker 있음" if MARKER in texts[l] else "marker 없음"
        if no_id:
            fails.append(f"[B] {l}: h2~h{max_lv} {len(need)}개 중 {len(no_id)}개 id 없음")
            print(f"  [B] ✗ {l}: h2~h{max_lv} {len(need)}개 중 {len(no_id)}개에 id 가 없다 ({mark}) "
                  f"— 예: {'#' * no_id[0][0]} {no_id[0][2][:40]}")
        else:
            print(f"  [B] ✓ {l}: h2~h{max_lv} {len(need)}개 전부 id 있음 ({mark})")

    ko_ol = [(lv, aid) for lv, aid, _ in ols["ko"]]
    for l in LANGS[1:]:
        t_ol = [(lv, aid) for lv, aid, _ in ols[l]]
        if t_ol == ko_ol:
            print(f"  [C] ✓ {l}: (level, id) outline == ko ({len(ko_ol)}개)")
            continue
        i = next((k for k in range(min(len(ko_ol), len(t_ol))) if ko_ol[k] != t_ol[k]),
                 min(len(ko_ol), len(t_ol)))
        fails.append(f"[C] {l}: outline 이 ko 와 다름 ({i + 1}번째)")
        print(f"  [C] ✗ {l}: outline 이 ko 와 다르다 — ko {len(ko_ol)} · {l} {len(t_ol)}, "
              f"{i + 1}번째 ko {ko_ol[i] if i < len(ko_ol) else '(없음)'} ↔ "
              f"{l} {t_ol[i] if i < len(t_ol) else '(없음)'}")

    if not a.ko_src.is_file():
        print(f"error: --ko-src 없음: {a.ko_src}")
        return 2
    src_texts = [h[2] for h in outline(a.ko_src.read_text(encoding="utf-8"), parse_units)]
    head_texts = [h[2] for h in ols["ko"]]
    if src_texts == head_texts:
        print(f"  [D] ✓ ko heading 텍스트 {len(src_texts)}개가 입력과 같다")
    else:
        fails.append("[D] ko heading 텍스트가 입력과 다름")
        print(f"  [D] ✗ ko heading 텍스트가 입력과 다르다 — 입력 {src_texts} · head {head_texts}")

    if a.control:
        print(f"── 대조군 {a.control} (기존 정렬 문서, ko 본문 한 줄 수정)")
        for l in LANGS:
            b, h = _read(a.base, l, a.control), _read(a.head, l, a.control)
            if b is None or h is None:
                print(f"  [E] ✗ {l}: base/head 에 파일 없음")
                return 2
            bo = [(lv, aid) for lv, aid, _ in outline(b, parse_units)]
            ho = [(lv, aid) for lv, aid, _ in outline(h, parse_units)]
            if bo == ho and all(aid for lv, aid in ho if lv <= max_lv):
                print(f"  [E] ✓ {l}: (level, id) outline 이 base 와 같다 ({len(ho)}개)")
            else:
                fails.append(f"[E] {l}: 대조군 outline 이 base 와 다름")
                print(f"  [E] ✗ {l}: outline 이 base 와 다르다 — base {bo} · head {ho}")

    print()
    if fails:
        for f in fails:
            print(f"  - {f}")
        print("NEW_DOC_ANCHORS: REPRO")
        return 3
    print("NEW_DOC_ANCHORS: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
