#!/usr/bin/env python3
"""사내 GHE 다국어 DB 콘솔 용어집 e2e 판정 (모델 없음).

e2e-console-glossary-ghe.sh 가 부른다. 사내 GHE 리포(cloud-docs/Internal-Agent-Test)의
`.docs-workflow` 가 `console_glossary: - i18n: [...]` 로 **사내 다국어 DB**
(TOASTCloud/console-i18n-translate — 문서 리포와 다른 조직) 를 가리킬 때:

  [A] 번역 잡이 그 카탈로그를 실제로 읽었나 — 잡 로그의
      `Console glossary: N ko strings from i18n:…` (N > 0) 와 번역 PR 본문의
      `Console glossary:` 줄. GitHub App 은 조직마다 installation 이 따로라, 문서 리포
      조직(cloud-docs)의 토큰으로는 TOASTCloud 카탈로그가 404 다 (cloud-translate#1341).
      못 읽으면 로더가 fail-open 으로 경고만 남기고 콘솔 용어집 없이 번역한다.
  [B] en/ja 산출물 — ko 가 **굵게** 쓴 콘솔 라벨이 굵게 자리에 카탈로그 문자열(후보 중
      하나)로 나왔나. hard.
  [W] 굵게가 아닌 자리(표 칸) · 산문 대조군(`다음 중 하나` 는 Next 가 아니다) — 모델
      판단이라 WARN 만.

exit 0 OK · 3 REPRO · 2 입력 오류
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BOLD_RE = re.compile(r"\*\*(.+?)\*\*")


def _norm(lang: str, s: str) -> str:
    s = re.sub(r"\s+", " ", s).strip()
    return s.lower() if lang == "en" else s


def _hit(lang: str, spans: list[str], candidates: list[str]) -> str | None:
    for span in spans:
        n = _norm(lang, span)
        for c in candidates:
            if _norm(lang, c) in n:
                return span
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--expected", required=True)
    ap.add_argument("--log", required=True)
    ap.add_argument("--pr-body", required=True)
    ap.add_argument("--en", required=True)
    ap.add_argument("--ja", required=True)
    a = ap.parse_args()

    exp = json.loads(Path(a.expected).read_text(encoding="utf-8"))
    log = Path(a.log).read_text(encoding="utf-8", errors="replace")
    body = Path(a.pr_body).read_text(encoding="utf-8", errors="replace")
    fail, warn = [], []

    # [A] 카탈로그를 읽었나
    cats = ", ".join(f"i18n:{c}" for c in exp["categories"])
    m = re.search(r"Console glossary: (\d+) ko strings from (.+)", log)
    if not m or int(m.group(1)) == 0 or m.group(2).strip() != cats:
        unread = sorted(set(re.findall(r"console glossary: could not read ([^\s(]+)", log)))
        fail.append(f"[A] 잡 로그에 `Console glossary: N ko strings from {cats}` 가 없다"
                    + (f" — 못 읽은 소스: {', '.join(unread)}" if unread else ""))
    else:
        print(f"  [A] 잡 로그: {m.group(0).strip()}")
    if "Console glossary:" not in body:
        fail.append("[A] 번역 PR 본문 Glossary 절에 `Console glossary:` 줄이 없다")
    else:
        print("  [A] 번역 PR 본문: Console glossary 줄 있음")

    # [B] 굵게 자리 · [W] 굵게 아닌 자리 · 대조군
    for lang, path in (("en", a.en), ("ja", a.ja)):
        text = Path(path).read_text(encoding="utf-8")
        spans = BOLD_RE.findall(text)
        hits = 0
        for ko, want in exp["bold"].items():
            got = _hit(lang, spans, want[lang])
            if got is None:
                fail.append(f"[B] {lang} **{ko}** → {' | '.join(want[lang])} 가 굵게 자리에 없다")
            else:
                hits += 1
        print(f"  [B] {lang}: 굵게 라벨 {hits}/{len(exp['bold'])} 이 카탈로그 문자열")
        for ko, want in exp["not_bold"].items():
            if not any(_norm(lang, c) in _norm(lang, text) for c in want[lang]):
                warn.append(f"[W] {lang} 표 칸 `{ko}` → {' | '.join(want[lang])} 아님 (모델 판단)")
        # 산문 대조군: 안내 상자 본문의 `다음 중 하나` 는 버튼이 아니다
        box = re.search(r"^!!! \w+.*\n((?:    .*\n|\s*\n)+)", text, re.M)
        if box and re.search(r"\bNext\b|次へ", box.group(1)):
            warn.append(f"[W] {lang} 안내 상자의 `다음 중 하나` 에 버튼 문자열(Next/次へ)이 들어갔다")

    for w in warn:
        print("  WARN " + w)
    if fail:
        for f in fail:
            print("  FAIL " + f)
        print(f"CONSOLE_GLOSSARY_GHE: REPRO ({len(fail)})")
        return 3
    print("CONSOLE_GLOSSARY_GHE: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
