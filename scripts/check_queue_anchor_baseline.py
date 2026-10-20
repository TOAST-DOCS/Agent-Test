#!/usr/bin/env python3
"""순차 번역 큐 차례(queue-next) 잡이 앞선 번역 PR 이 ko 에 찍은 `<a id>` 를 지우는가 — 모델 없이, 결정적으로.

사고 원형 (2026-10-20 분석): https://github.com/TOAST-DOCS/Data-Flow/pull/236
  * 앞선 ko PR(#228)이 `#### 실행 목록/상세/메트릭` 을 id 없이 더했다.
  * 그 번역 PR(#234)이 assign-anchors 로 ko/en/ja 에 `<a id="execution-history-execution-*">`
    셋을 찍었다 — **ko 도 번역 PR 이 바꾼다**.
  * 그 사이 뒤 ko PR(#235, 그 절들의 줄 몇 개 수정)이 먼저 머지돼 큐에서 기다렸다가,
    #234 머지 뒤 차례가 되어 번역됐다(#236). 큐 head 는 en/ja 를 base 끝(#234 반영)에서,
    ko 는 자기 머지 커밋(id 없음)에서 읽는다 → anchor splice 가 ko 의 id 없는 절과
    en/ja 의 id 있는 절을 짝짓지 못해 en/ja 의 세 절을 통째로 버리고 다시 번역했다
    (ko 는 안 바뀐 `실행 메트릭` 절까지). en/ja 에서 id 세 줄이 사라지고 ko 에는 남았다.

이 판정기는 cloud-translate 의 실제 함수를 탄다 — `worker._source_ref` 로 ko 를 읽는 ref 를
고르고 `TranslationWorker._translate_modified` 로 기존 en/ja 를 읽어 `translate_diff` 를
돌린다. GitHub 는 `archive/queue-anchor/<ref>/` 를 읽는 가짜로, 모델은 받은 단위를 그대로
돌려주는 이상적 모델(엔진과 같은 `_strip_code_fence`)로 바꾼다. 그래서 결과는 **파이프라인이
무엇을 하는가** 만 보여 준다.

ref 셋 (= archive/queue-anchor/ 의 디렉터리):
  base   소스 ko PR 머지 직전 base 끝 (pr_merge_base_sha) — ko 에 id 없음
  merge  소스 ko PR 머지 커밋 (pr_merge_sha) — ko 에 id 없음 + 이 PR 의 변경
  tip    앞선 번역 PR 머지 뒤 base 끝 (job.existing_ref) — ko/en/ja 에 id 셋, en/ja 는 이 PR 변경 전 번역

케이스:
  repro    위 그대로 (사고 모양)
  control  대조군 — 같은 입력에서 ko 의 id 를 base·merge 에도 미리 넣는다 (앞선 번역 PR 이
           ko 를 바꾸지 않은 평범한 큐 차례). 지금 코드에서도 통과해야 한다.

판정 (en/ja 각각):
  [anchors]   결과의 `<a id>` 순서 == tip ko 의 `<a id>` 순서
              (번역 브랜치는 tip 에서 갈라지므로 ko 는 id 를 갖고 있다)
  [untouched] ko 가 바꾸지 않은 `#### 실행 메트릭` 절 — tip 의 en/ja 와 바이트 동일
  [scope]     모델에 보낸 단위에 그 절의 ko 문장이 없다

usage (CLOUD_TRANSLATE_DIR 를 cwd 로, 그 venv 의 python 으로):
  cd "$CLOUD_TRANSLATE_DIR" && .venv/bin/python <agent-test>/scripts/check_queue_anchor_baseline.py \
      <agent-test>/archive/queue-anchor [--case repro|control|all] [--list-items]

exit 0 = QUEUE_ANCHOR: OK · 3 = REPRO (결함 재현) · 1 = 판정 불가
"""
from __future__ import annotations

import argparse
import asyncio
import io
import logging
import os
import re
import sys

sys.path[:0] = ["translate", "."]
os.environ.setdefault("TRANSLATE_GITHUB_TOKEN", "dummy-not-used")
logging.disable(logging.WARNING)

DOC = "queue-anchor-sample.md"
REPO = "TOAST-DOCS/Agent-Test"
ANCHOR = re.compile(r'<a id="([^"]+)"></a>')
UNTOUCHED = "execution-history-execution-metrics"
UNTOUCHED_KO = "선택한 실행의 그래프와 메트릭 차트를 모달 창에 표시합니다."
ANCHOR_LINE = {
    "execution-history-execution-list": "#### 실행 목록",
    "execution-history-execution-details": "#### 실행 상세",
    "execution-history-execution-metrics": "#### 실행 메트릭",
}


def _read(p: str) -> str:
    return io.open(p, encoding="utf-8", newline="").read()


def _with_ko_anchors(ko: str) -> str:
    """control: 앞선 번역 PR 이 찍은 id 를 base·merge 의 ko 에도 미리 넣는다."""
    out = []
    for line in ko.splitlines(keepends=True):
        for aid, head in ANCHOR_LINE.items():
            if line.rstrip("\n") == head:
                out.append(f'<a id="{aid}"></a>\n')
        out.append(line.replace("sig=aaaaaaaaaaaa", "sig=bbbbbbbbbbbb"))
    return "".join(out)


def _section(text: str, aid: str, heading: str) -> str | None:
    """`<a id=aid>` 부터 다음 `<a id` 직전까지. id 가 없으면 heading 줄부터."""
    lines = text.replace("\r\n", "\n").split("\n")
    start = next((i for i, l in enumerate(lines) if l.strip() == f'<a id="{aid}"></a>'), None)
    if start is None:
        start = next((i for i, l in enumerate(lines) if l.strip() == heading), None)
        if start is None:
            return None
    end = next((j for j in range(start + 1, len(lines)) if lines[j].startswith("<a id=")), len(lines))
    return "\n".join(lines[start:end])


async def run_case(case: str, root: str, list_items: bool) -> list[str]:
    from shared.config import settings as s
    from shared.models import TranslationFile, TranslationJob
    import app.translator as T
    import app.worker as Wk

    s.diff_mode = "incremental"
    s.diff_granularity = "block"
    s.diff_table_rows = True
    s.diff_align_headings = True     # 권장 preset --align-headings
    if hasattr(s, "diff_list_items"):
        s.diff_list_items = list_items
    for flag in ("term_pin", "diff_term_pin"):
        if hasattr(s, flag):
            setattr(s, flag, False)

    files: dict[str, dict[str, str]] = {}
    for ref in ("base", "merge", "tip"):
        files[ref] = {}
        for lang in ("ko", "en", "ja"):
            p = os.path.join(root, ref, lang, DOC)
            if os.path.exists(p):
                files[ref][f"{lang}/{DOC}"] = _read(p)
    if case == "control":
        for ref in ("base", "merge"):
            files[ref][f"ko/{DOC}"] = _with_ko_anchors(files[ref][f"ko/{DOC}"])

    class FakeGH:
        async def get_file_content_or_none(self, repo, path, ref):
            return files.get(ref, {}).get(path)

        async def get_file_content(self, repo, path, ref):
            v = files.get(ref, {}).get(path)
            if v is None:
                raise FileNotFoundError(f"{ref}:{path}")
            return v

    sent: list[str] = []

    class Ideal(T.Translator):
        def model_name(self) -> str:
            return "echo"

        async def _verify_chunk_uncached(self, *a, **k):
            return ""

        async def _translate_chunk_uncached(self, content, reference=None,
                                            target_lang="en", target_dir="en"):
            sent.append(content)
            return T._strip_code_fence(content)

    worker = Wk.TranslationWorker.__new__(Wk.TranslationWorker)
    worker.github = FakeGH()
    worker.translator = Ideal()
    worker.jobs = {}
    job = TranslationJob(
        id="queue-anchor", repo_full_name=REPO, pr_number=1, pr_title="queue anchor",
        pr_url=f"https://github.com/{REPO}/pull/1", source_branch="translate-test/queue-anchor",
        base_branch="e2e-queueanchor/session",
        pr_base_sha="base", pr_merge_sha="merge", pr_merge_base_sha="base",
        existing_ref="tip",
        files=[TranslationFile(source_path=f"ko/{DOC}", target_path=f"{l}/{DOC}", status="modified")
               for l in ("en", "ja")],
    )
    # 프로덕션과 같은 함수로 ko 를 읽는 ref 를 고른다 (worker.py 의 _source_ref).
    new_ko = await worker.github.get_file_content_or_none(REPO, f"ko/{DOC}", Wk._source_ref(job))
    tip_ko = files["tip"][f"ko/{DOC}"]
    want = ANCHOR.findall(tip_ko)
    fails: list[str] = []
    for lang in ("en", "ja"):
        sent.clear()
        tf = TranslationFile(source_path=f"ko/{DOC}", target_path=f"{lang}/{DOC}", status="modified")
        out, method, _rep = await worker._translate_modified(REPO, job, tf, new_ko, None, lang, lang)
        got = ANCHOR.findall(out)
        tip_t = files["tip"][f"{lang}/{DOC}"]
        heading = _section(tip_t, UNTOUCHED, "").split("\n")[1]
        sec_tip = _section(tip_t, UNTOUCHED, heading)
        sec_out = _section(out, UNTOUCHED, heading)
        leaked = any(UNTOUCHED_KO in c for c in sent)
        ok_a, ok_u, ok_s = got == want, sec_out == sec_tip, not leaked
        print(f"[{case}] {lang}: method={method} calls={len(sent)} chars={sum(map(len, sent))}")
        print(f"  [anchors]   {'OK ' if ok_a else 'FAIL'} want={want} got={got}")
        print(f"  [untouched] {'OK ' if ok_u else 'FAIL'} #{UNTOUCHED} "
              + ("byte-identical to tip" if ok_u else
                 ("missing in output" if sec_out is None else "rewritten")))
        print(f"  [scope]     {'OK ' if ok_s else 'FAIL'} untouched section ko "
              + ("not sent" if ok_s else "SENT to the model"))
        for name, ok in (("anchors", ok_a), ("untouched", ok_u), ("scope", ok_s)):
            if not ok:
                fails.append(f"{case}/{lang}/{name}")
    return fails


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("fixture", help="archive/queue-anchor")
    ap.add_argument("--case", choices=("repro", "control", "all"), default="all")
    ap.add_argument("--list-items", action="store_true", help="diff_list_items=True 로도")
    a = ap.parse_args()
    if not os.path.isdir("translate/app"):
        print("cwd 가 cloud-translate 체크아웃이 아니다 (translate/app 없음)", file=sys.stderr)
        return 1
    cases = ("repro", "control") if a.case == "all" else (a.case,)
    fails: list[str] = []
    try:
        for c in cases:
            fails += asyncio.run(run_case(c, os.path.abspath(a.fixture), a.list_items))
    except Exception as e:  # noqa: BLE001 — 하네스 오류는 판정 불가
        print(f"harness error: {type(e).__name__}: {e}", file=sys.stderr)
        return 1
    if any(f.startswith("control/") for f in fails):
        print(f"QUEUE_ANCHOR: CONTROL FAILED {fails}")
        return 1
    if fails:
        print(f"QUEUE_ANCHOR: REPRO {len(fails)} {fails}")
        return 3
    print("QUEUE_ANCHOR: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
