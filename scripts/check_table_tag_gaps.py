#!/usr/bin/env python3
"""table-tag-gaps e2e 의 판정 — cloud-translate 의 표 파서·렌더러를 그대로 쓴다.

두 하위 명령:

  replay  <old_ko> <new_ko> <existing> <lang> <out>
      이상적 모델(받은 단위를 그대로 돌려줌, 엔진과 같은 `_strip_code_fence`)로
      `translate_diff` 를 권장 preset 의 diff 설정으로 돌린다. 모델 편차 없이
      **파이프라인이 무엇을 하는지** 만 본다 — [A] 결정적 층.

  measure <ko> <result> <baseline>
      결과 문서를 ko 와 대조한 수치를 JSON 한 줄로 낸다:
        tables     `_doc_table_regions` 표 수            (= ko 여야 한다)
        tag_blank  표 행 사이 태그 줄 옆의 빈 줄 수      (= ko 여야 한다)
        todo       `<todo: translate>` 수                 (0 이어야 한다)
        leak       빌드 7종 렌더에서 표 밖으로 떨어진 행  (= ko 여야 한다)
        response   `#create-instance-response` 표가 baseline 과 바이트 동일한가

반드시 `CLOUD_TRANSLATE_DIR` 를 cwd 로, 그 venv 의 python 으로 실행한다
(`app.*` · `shared.*` 를 그 체크아웃에서 읽는다 — 검증 대상 코드가 곧 판정기다).
"""
from __future__ import annotations

import asyncio
import io
import json
import logging
import os
import re
import sys

sys.path[:0] = ["translate", "."]
logging.disable(logging.WARNING)

TAG = re.compile(r"^\s*\{%-?\s*(if|elif|else|endif)\b")


def _read(p: str) -> str:
    return io.open(p, encoding="utf-8", newline="").read()


def replay(old_ko: str, new_ko: str, existing: str, lang: str, out: str) -> None:
    from shared.config import settings as s
    import app.translator as T

    s.diff_mode = "incremental"
    s.diff_granularity = "block"
    s.diff_table_rows = True
    s.diff_table_reconcile = True
    s.diff_align_headings = True

    class Ideal(T.Translator):
        def __init__(self):
            super().__init__()
            self.calls = 0

        def model_name(self) -> str:
            return "echo"

        async def _verify_chunk_uncached(self, *a, **k):
            return ""

        async def _translate_chunk_uncached(self, content, reference=None,
                                            target_lang="en", target_dir="en"):
            self.calls += 1
            return T._strip_code_fence(content)

    async def run():
        tr = Ideal()
        report: dict = {}
        old = _read(old_ko)
        res = await tr.translate_diff(_read(existing), _read(new_ko), old, None,
                                      lang, lang, report=report,
                                      content_baseline_ko=old)
        io.open(out, "w", encoding="utf-8", newline="").write(res)
        print(json.dumps({"calls": tr.calls,
                          "stubs": report.get("table_todo_stubs") or []}))

    asyncio.run(run())


def _section_table(text: str, anchor: str) -> str:
    """`<a id="anchor">` 절의 첫 표 (머리행부터 연속된 `|` 줄)."""
    lines = text.replace("\r\n", "\n").split("\n")
    try:
        i = next(k for k, l in enumerate(lines) if l.strip() == f'<a id="{anchor}"></a>')
    except StopIteration:
        return ""
    for j in range(i + 1, len(lines)):
        if lines[j].startswith("<a id=") and j > i + 1:
            return ""
        if lines[j].lstrip().startswith("|"):
            k = j
            while k < len(lines) and lines[k].lstrip().startswith("|"):
                k += 1
            return "\n".join(lines[j:k])
    return ""


def measure(ko_p: str, res_p: str, base_p: str) -> None:
    from app.md_text import md_lines
    from app.tables import _doc_table_regions
    from shared.markup_lint import _leaked_rows, _macro_renders

    def m(t: str) -> dict:
        t = t.replace("\r\n", "\n")
        L = t.split("\n")
        tb = sum(1 for i, l in enumerate(L) if TAG.match(l) and (
            (i > 0 and not L[i - 1].strip())
            or (i + 1 < len(L) and not L[i + 1].strip())))
        renders = _macro_renders(t) or []
        return {"tables": len(_doc_table_regions(md_lines(t))), "tag_blank": tb,
                "todo": t.count("<todo: translate>"),
                "leak": sum(_leaked_rows(x) for x in renders)}

    ko, res, base = _read(ko_p), _read(res_p), _read(base_p)
    k, r = m(ko), m(res)
    want = _section_table(base, "create-instance-response")
    got = _section_table(res, "create-instance-response")
    r["response"] = bool(want) and got == want
    r["ko"] = k
    print(json.dumps(r, ensure_ascii=False))


if __name__ == "__main__":
    cmd, *args = sys.argv[1:]
    {"replay": replay, "measure": measure}[cmd](*args)
