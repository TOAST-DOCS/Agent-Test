#!/usr/bin/env python3
"""term-pin 의 **고정 단계만** 떼어 재는 결정적 층 — 번역을 돌리지 않는다.

`e2e-term-pin*.sh` 는 산출물을 본다. 그것이 본질이지만 한 판에 번역 두 번(en·ja)
이 들어가서 열 번 돌릴 수 없고, 실패했을 때 **고정 단계가 틀렸는지 번역이 안 따랐
는지** 가려지지 않는다. 이 스크립트는 그 앞자리를 본다:

    build_term_table  →  propose_terms  →  validate_unregistered
    (결정적)             (모델 1회)        (결정적)

호출이 (문서 × 언어)당 **한 번**이라 같은 문서를 N판 돌려 분포를 볼 수 있고,
운영 코퍼스의 실제 문서 수십 개에 그대로 걸 수 있다.

## 네 가지를 잰다

1. **표 (ⓐ/ⓑ)** — 용어집이 이 문서에 대해 확정하는 것 · 스스로 갈린 것
   (`GLOSSARY_SPLIT`) · 문서와 어긋나는 것 (`DOC_CONFLICT`).
2. **제안의 안정성 (ⓒ)** — 같은 입력을 N판 돌렸을 때 채택 목록이 같은가.
   `translate/CLAUDE.md` 가 적어 둔 "실행 간 안정성 92%" 를 다시 재는 자리다.
   문서마다 따로 고정하므로 이 값이 낮으면 **리포 전체 일관성**이 나빠진다.
3. **기존 표기와의 합치** — 채택한 역어가 **이미 배포된 번역본이 쓰는 말**인가.
   `propose_terms` 의 첫 규칙("Prefer the rendering the existing translation
   already uses")은 프롬프트일 뿐 검증되지 않는다. 여기서 코드로 확인한다:

       matches      배포본의 표 슬롯이 쓰는 역어와 같다            ← 원하는 것
       conflicts    슬롯은 다른 말을 쓰는데 다른 말로 고정했다      ← **켜면 나빠진다**
       absent       배포본 어디에도 그 문자열이 없다 (신규 표현)    ← 판단 보류
       no-evidence  표 슬롯에 없어 대조할 수 없다                  ← 판단 보류

   `conflicts` 는 term-pin 이 **없던 결함을 만드는** 유일한 모양이다. 즉흥은
   그래도 배포본을 보고 고를 수 있지만, 고정은 모든 chunk 를 틀린 쪽으로 못 박는다.
4. **지금 갈려 있는가** — 배포된 번역본에서 이미 갈린 용어 수
   (`check_term_divergence.divergence`). term-pin 이 고치겠다는 문제의 크기다.

## Usage

    # 로컬 체크아웃의 문서 하나 (en/ja 형제를 자동으로 찾는다)
    check_term_pin.py --doc ~/works/toast-docs/Alimtalk/ko/overview.md --runs 3

    # 파일을 직접 지정
    check_term_pin.py --ko ko/a.md --en en/a.md --ja ja/a.md --repo TOAST-DOCS/X

    # 코퍼스 한 묶음 (--doc 여러 번) · 기계가 읽을 출력
    check_term_pin.py --doc A/ko/x.md --doc B/ko/y.md --runs 3 --json

코드 위치는 `CLOUD_TRANSLATE_DIR` (기본 ~/works/cloud-translate) 에서 import 한다.
`TRANSLATE_ANTHROPIC_API_KEY` 가 필요하다 (고정 단계는 CLI 잡에서도 API 를 탄다).
"""
from __future__ import annotations

import argparse
import asyncio
import collections
import importlib.util
import json
import os
import pathlib
import sys

CT_DIR = pathlib.Path(os.environ.get(
    "CLOUD_TRANSLATE_DIR", pathlib.Path.home() / "works" / "cloud-translate"))
sys.path[:0] = [str(CT_DIR / "translate"), str(CT_DIR)]

_HERE = pathlib.Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    "ctd", _HERE / "check_term_divergence.py")
ctd = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ctd)          # noqa: E402

from app.glossary import Glossary                      # noqa: E402
from app.term_table import (                           # noqa: E402
    Ambiguity, build_term_table, propose_terms, validate_unregistered,
)

LANGS = ("en", "ja")


def _repo_of(ko_path: pathlib.Path) -> str:
    """`.../<repo>/ko/foo.md` → `TOAST-DOCS/<repo>` (용어집 선택용)."""
    try:
        return "TOAST-DOCS/" + ko_path.resolve().parents[1].name
    except IndexError:
        return "TOAST-DOCS/unknown"


def _sibling(ko_path: pathlib.Path, lang: str) -> pathlib.Path:
    return ko_path.resolve().parents[1] / lang / ko_path.name


def _read(p: pathlib.Path | None) -> str:
    if p is None or not p.exists():
        return ""
    return p.read_text(encoding="utf-8", errors="replace")


def _agreement(ko_doc: str, existing: str, accepted: dict[str, str]) -> dict:
    """채택한 역어 ↔ 배포본이 실제로 쓰는 역어."""
    if not existing:
        return {"verdicts": {}, "counts": {}}
    pairs, _notes = ctd.slot_map(ko_doc, existing)
    verdicts: dict[str, dict] = {}
    for ko, tgt in accepted.items():
        # 표 슬롯은 셀 **전체** 가 키다. 용어가 셀 안에 섞여 있을 수 있으므로
        # 셀 전체 일치와 부분 포함을 함께 본다.
        forms: collections.Counter = collections.Counter()
        for cell, cell_forms in pairs.items():
            if cell == ko:
                forms.update(cell_forms)
        if forms:
            deployed = [f for f, _ in forms.most_common()]
            low = [d.lower() for d in deployed]
            if tgt.lower() in low or any(tgt.lower() in d for d in low):
                v = "matches"
            else:
                v = "conflicts"
            verdicts[ko] = {"verdict": v, "target": tgt, "deployed": deployed}
        elif tgt.lower() in existing.lower():
            verdicts[ko] = {"verdict": "matches-prose", "target": tgt,
                            "deployed": []}
        elif ko in ko_doc and existing:
            verdicts[ko] = {"verdict": "absent", "target": tgt, "deployed": []}
        else:
            verdicts[ko] = {"verdict": "no-evidence", "target": tgt,
                            "deployed": []}
    counts = collections.Counter(v["verdict"] for v in verdicts.values())
    return {"verdicts": verdicts, "counts": dict(counts)}


async def probe_one(ko_doc: str, existing: str, lang: str, glossary,
                    runs: int, model: str | None) -> dict:
    table = build_term_table(ko_doc, glossary, lang, existing)
    known = list(table.confirmed) + list(table.ambiguous)

    run_rows = []
    for _ in range(runs):
        proposed = await propose_terms(ko_doc, existing, lang, known, model=model)
        accepted, rejected = validate_unregistered(
            proposed, ko_doc, table, existing, lang)
        run_rows.append({"proposed": proposed, "accepted": accepted,
                         "rejected": rejected})

    # 안정성 — 용어별로 판마다 어떤 역어를 골랐는가.
    per_term: dict[str, collections.Counter] = collections.defaultdict(
        collections.Counter)
    for row in run_rows:
        for ko, tgt in row["accepted"].items():
            per_term[ko][tgt] += 1
    always = {ko for ko, c in per_term.items() if sum(c.values()) == runs}
    one_form = {ko for ko in always if len(per_term[ko]) == 1}
    identical_runs = len({
        json.dumps(r["accepted"], sort_keys=True, ensure_ascii=False)
        for r in run_rows
    }) == 1

    # 합치 — 판마다의 채택을 합쳐 다수형으로 본다.
    majority = {ko: c.most_common(1)[0][0] for ko, c in per_term.items()}
    agree = _agreement(ko_doc, existing, majority)

    base_div = ctd.divergence(ko_doc, existing) if existing else {
        "terms": {}, "diverged_terms": []}

    reasons: collections.Counter = collections.Counter()
    for row in run_rows:
        for why in row["rejected"].values():
            reasons[why.split(" —")[0]] += 1

    return {
        "lang": lang,
        "table": {
            "confirmed": len(table.confirmed),
            "glossary_split": sorted(
                k for k, v in table.ambiguous.items()
                if v[0] is Ambiguity.GLOSSARY_SPLIT),
            "doc_conflict": sorted(
                k for k, v in table.ambiguous.items()
                if v[0] is Ambiguity.DOC_CONFLICT),
        },
        "runs": runs,
        "identical_across_runs": identical_runs,
        "terms_seen": len(per_term),
        "terms_every_run": len(always),
        "terms_every_run_one_form": len(one_form),
        "unstable_terms": sorted(
            {ko: dict(c) for ko, c in per_term.items() if len(c) > 1}.items()),
        "majority": majority,
        "agreement": agree,
        "reject_reasons": dict(reasons),
        "existing_diverged_terms": base_div["diverged_terms"],
        "run_rows": run_rows,
    }


async def main_async(args) -> int:
    docs: list[tuple[pathlib.Path, pathlib.Path | None, pathlib.Path | None, str]] = []
    if args.ko:
        docs.append((pathlib.Path(args.ko),
                     pathlib.Path(args.en) if args.en else None,
                     pathlib.Path(args.ja) if args.ja else None,
                     args.repo or _repo_of(pathlib.Path(args.ko))))
    for d in args.doc:
        p = pathlib.Path(d)
        docs.append((p, _sibling(p, "en"), _sibling(p, "ja"),
                     args.repo or _repo_of(p)))
    if not docs:
        print("대상이 없다 — --doc 또는 --ko", file=sys.stderr)
        return 2

    langs = [l for l in LANGS if l in args.langs.split(",")]
    out = {"docs": [], "runs": args.runs, "model": args.model or "(default)"}
    for ko_p, en_p, ja_p, repo in docs:
        ko_doc = _read(ko_p)
        if not ko_doc:
            print(f"  (건너뜀 — ko 없음) {ko_p}", file=sys.stderr)
            continue
        glossary = Glossary.for_repo(repo)
        entry = {"ko": str(ko_p), "repo": repo,
                 "glossary": glossary.key, "langs": {}}
        for lang in langs:
            existing = _read({"en": en_p, "ja": ja_p}[lang])
            entry["langs"][lang] = await probe_one(
                ko_doc, existing, lang, glossary, args.runs, args.model)
        out["docs"].append(entry)
        if not args.json:
            _print_doc(entry)
    if args.json:
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        _print_totals(out)
    return 0


def _print_doc(entry: dict) -> None:
    print(f"\n## {entry['ko']}  (용어집 {entry['glossary']})")
    for lang, r in entry["langs"].items():
        t = r["table"]
        print(f"  [{lang}] 용어집 확정 {t['confirmed']}"
              f" · 갈린 용어집 {len(t['glossary_split'])}"
              f" · 문서와 어긋남 {len(t['doc_conflict'])}"
              f" | 배포본에 이미 갈린 용어 {len(r['existing_diverged_terms'])}")
        print(f"       미등록 채택: 연 {r['terms_seen']}개 ·"
              f" 매 판 {r['terms_every_run']}개 ·"
              f" 매 판 같은 역어 {r['terms_every_run_one_form']}개"
              f" · 판 전체 동일 {'예' if r['identical_across_runs'] else '아니오'}")
        if r["agreement"]["counts"]:
            bits = " ".join(f"{k}={v}" for k, v in
                            sorted(r["agreement"]["counts"].items()))
            print(f"       기존 표기 합치: {bits}")
        for ko, info in r["agreement"]["verdicts"].items():
            if info["verdict"] == "conflicts":
                print(f"         ✗ {ko} → '{info['target']}'"
                      f"  (배포본: {', '.join(info['deployed'][:3])})")
        for ko, forms in r["unstable_terms"]:
            print(f"         ~ {ko}: " +
                  " / ".join(f'"{k}"x{v}' for k, v in forms.items()))


def _print_totals(out: dict) -> None:
    tot = collections.Counter()
    langs_seen = 0
    for d in out["docs"]:
        for r in d["langs"].values():
            langs_seen += 1
            tot["terms"] += r["terms_seen"]
            tot["every_run"] += r["terms_every_run"]
            tot["every_run_one_form"] += r["terms_every_run_one_form"]
            tot["identical"] += 1 if r["identical_across_runs"] else 0
            for k, v in r["agreement"]["counts"].items():
                tot[k] += v
            tot["existing_diverged"] += len(r["existing_diverged_terms"])
    print(f"\n=== 합계 ({len(out['docs'])}문서 × {langs_seen//max(1,len(out['docs']))}언어"
          f" · {out['runs']}판) ===")
    print(f"  채택된 미등록 용어      {tot['terms']}")
    print(f"    매 판 등장            {tot['every_run']}")
    print(f"    매 판 같은 역어       {tot['every_run_one_form']}")
    print(f"  판 전체가 같은 (문서×언어)  {tot['identical']}/{langs_seen}")
    print(f"  기존 표기 합치: matches={tot['matches']}"
          f" matches-prose={tot['matches-prose']}"
          f" conflicts={tot['conflicts']}"
          f" absent={tot['absent']} no-evidence={tot['no-evidence']}")
    print(f"  배포본에 이미 갈려 있던 용어 {tot['existing_diverged']}")


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--doc", action="append", default=[],
                    help="ko 문서 경로 (en/ja 형제를 자동으로 찾는다). 여러 번 가능")
    ap.add_argument("--ko")
    ap.add_argument("--en")
    ap.add_argument("--ja")
    ap.add_argument("--repo", help="용어집 선택용 repo full name")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--langs", default="en,ja")
    ap.add_argument("--model", default=os.environ.get("TERM_PIN_PROBE_MODEL", ""))
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    a.model = a.model or None
    return asyncio.run(main_async(a))


if __name__ == "__main__":
    sys.exit(main())
