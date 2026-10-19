#!/usr/bin/env python3
"""fix-links LLM 2차 답 짝짓기 판정 (모델 없음, 결정적).

    python3 scripts/check_llm_pairing.py <dir>    # <dir>/{ko,en,ja}/llm-pairing-sample.md

픽스처 `archive/llm-pairing/` 의 두 절을 본다:

  [A] 같은 줄 — ko/en/ja 가 **같은 줄**에 같은 죽은 링크 `./llm-pairing-target/#_3` 를
      가진다. 정답(`#event-subscription`)의 후보 번호는 ko/ja 1번 · en 2번이다
      (en 에만 문자열이 더 비슷한 미끼 `How to Subscribe to a Plan` 이 앞선다).
      답을 `(줄, 대상)` 으로만 짝지으면 한 언어의 번호가 다른 언어 목록에 적용돼
      어느 한쪽이 `#plan-subscription` 으로 간다 (cloud-translate#1325 이전).
  [B] 대조군 — `./llm-pairing-target/#_4` 가 언어마다 다른 줄(15/17/19)에 있다.
      키가 겹치지 않으므로 수정 전후 모두 `#notification-group` 이어야 한다.

exit 0 = LLM_PAIRING: OK · 3 = LLM_PAIRING: REPRO ([A] 가 갈렸거나 틀림) ·
4 = 대조군 실패 (모델이 틀렸거나 판정 전제가 깨짐 — 수정 여부와 무관) · 2 = 입력 오류.
"""
import re
import sys
from pathlib import Path

LANGS = ("ko", "en", "ja")
DOC = "llm-pairing-sample.md"
LINK_RE = re.compile(r"\]\((\./llm-pairing-target/#[^)\s]*)\)")
EXPECT = {"A": "./llm-pairing-target/#event-subscription",
          "B": "./llm-pairing-target/#notification-group"}


def targets(text: str) -> dict[str, tuple[int, str]]:
    found = [(n, m.group(1)) for n, line in enumerate(text.splitlines(), 1)
             for m in LINK_RE.finditer(line)]
    if len(found) != 2:
        raise ValueError(f"링크가 2개가 아닙니다: {found}")
    return {"A": found[0], "B": found[1]}


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    root = Path(sys.argv[1])
    got: dict[str, dict[str, tuple[int, str]]] = {}
    for lang in LANGS:
        p = root / lang / DOC
        try:
            got[lang] = targets(p.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            print(f"error: {p}: {exc}", file=sys.stderr)
            return 2
    ok = {}
    for case, title in (("A", "같은 줄"), ("B", "대조군 (다른 줄)")):
        row = {lang: got[lang][case] for lang in LANGS}
        same = len({t for _, t in row.values()}) == 1
        right = all(t == EXPECT[case] for _, t in row.values())
        verdict = "OK" if (same and right) else ("갈림" if not same else "틀림")
        print(f"[{case}] {title}: {verdict}")
        for lang in LANGS:
            line, t = row[lang]
            mark = "✓" if t == EXPECT[case] else "✗"
            print(f"    {mark} {lang}:L{line}  {t}")
        ok[case] = verdict == "OK"
    # 대조군이 깨지면 [A] 의 결과도 읽을 수 없다 — 모델이 틀렸거나 전제가 깨졌다.
    if not ok["B"]:
        print("LLM_PAIRING: CONTROL-FAIL")
        return 4
    print("LLM_PAIRING: " + ("OK" if ok["A"] else "REPRO"))
    return 0 if ok["A"] else 3


if __name__ == "__main__":
    sys.exit(main())
