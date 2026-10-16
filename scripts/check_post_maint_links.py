#!/usr/bin/env python3
"""번역 PR 문서 정비의 링크 정정 판정 (모델 없음) — e2e-post-maint-links.sh 가 부른다.

    check_post_maint_links.py <base_dir> <tx_dir> <doc>

* [A] 재번역된 절(#post-maint-links-ios · -android)의 en/ja 링크가 site-root
  (`/nhncloud-sdk/<lang>/…`) 인가. ko 가 운영 host 절대 URL 로 바뀌어도 사람이 고쳐 둔
  site-root 를 유지해야 한다 (Log-Crash-Search#137). 절대 URL 이면 REPRO.
* [B] 대조군 절(#post-maint-links-control) 의 en/ja 는 base 와 바이트 동일 — 그 절의 절대
  URL 은 번역이 쓴 줄이 아니므로 정비가 건드리면 안 된다 (범위가 줄이라는 증거).

exit 0 OK · 3 REPRO · 1 사용법/입력 오류
"""
import re
import sys
from pathlib import Path

LANGS = ("en", "ja")
FIXED = ("post-maint-links-ios", "post-maint-links-android")
CONTROL = "post-maint-links-control"
LINK = re.compile(r"\]\(([^)\s]+)\)")


def sections(text: str) -> dict[str, str]:
    out, cur = {}, None
    for line in text.splitlines(keepends=True):
        m = re.match(r'<a id="([^"]+)"></a>', line)
        if m:
            cur = m.group(1)
        if cur:
            out[cur] = out.get(cur, "") + line
    return out


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__)
        return 1
    base, tx, doc = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    bad = 0
    for lang in LANGS:
        b = sections((base / lang / doc).read_text())
        t = sections((tx / lang / doc).read_text())
        for sec in FIXED:
            targets = [u for u in LINK.findall(t.get(sec, "")) if "nhncloud-sdk" in u]
            ok = bool(targets) and all(u.startswith(f"/nhncloud-sdk/{lang}/") for u in targets)
            print(f"[A] {lang} #{sec}: {'OK' if ok else 'REPRO'} {targets}")
            bad += not ok
        same = b.get(CONTROL) == t.get(CONTROL)
        print(f"[B] {lang} #{CONTROL}: {'OK (base 와 동일)' if same else 'CHANGED'}")
        bad += not same
    print("POST_MAINT_LINKS:", "OK" if not bad else f"REPRO {bad}")
    return 0 if not bad else 3


if __name__ == "__main__":
    sys.exit(main())
