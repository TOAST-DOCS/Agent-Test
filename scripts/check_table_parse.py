#!/usr/bin/env python3
"""표의 행 수를 세는 세 주체가 갈리는 자리를 픽스처에서 결정적으로 보여준다.

`{ko,en,ja}/table-parse-sample.md` 는 "표 하나의 행 수" 에 대해 **사이트
렌더러 · 번역 파이프라인 · 마크업 정정(M7)** 이 서로 다른 답을 내는 네 모양을
담고 있다. 이 스크립트는 그 셋을 각각 실제 구현으로 재어 한 표에 늘어놓고,
픽스처가 아직 그 모양인지 검사한다.

세는 주체와 이 스크립트가 쓰는 정본:

  렌더러       python-markdown + 사이트 확장셋 → `<tr>` 개수
               (독자가 보는 행 수. 판정의 기준점)
  파이프라인   `app.tables._doc_table_regions` → 데이터 행 개수
               (표 수리가 "ko 가 몇 행인가" 를 묻는 자리)
  마크업 정정  `shared.markup_lint.scan_markup` 의 M7
               ("렌더가 원문보다 행이 많다" → 셀 안 줄바꿈으로 판정)

네 모양과 기대 판정:

  A  U+2028    렌더 3행 · 파서 1행 · M7 0건
               → 문서는 정상인데 파이프라인만 1행으로 읽는다. reconcile 이
                 ko 를 정본으로 삼아 en/ja 의 2·3행을 삭제한다. 렌더가
                 멀쩡하므로 마크업 정정은 원리상 이 표에 닿지 않는다.
  B  실제 \n   렌더 4행 · 파서 1행 · M7 1건
               → 파이프라인에게는 A 와 같은 모양이지만, 렌더도 깨지므로
                 마크업 정정이 고친다. 정비가 재고를 줄여 주는 쪽.
  C  파이프 누락 ko·en·ja 모두 3행, 열 수는 최빈값으로 4 인데 en/ja 의 한 행이
               3셀이라 `_table_ncols`(최소값)가 3으로 읽는다 → 행 수가 이미
               일치하는 표가 "스키마 불일치" 로 전체 재작성에 선정된다.
  D  대조군    en/ja 에 ko 의 `SVC-104` 가 없다 → A·C 의 가드와 무관하게
               여전히 수리되어야 하는 진짜 결함.

마지막 줄은 ``TABLE-PARSE: OK`` 또는 ``TABLE-PARSE: FAIL`` 이다. FAIL 은 보통
"누군가 픽스처를 고쳤다" 는 뜻이다 — 특히 B 는 alpha 에 마크업 정정이 돌면
실제로 고쳐지므로, 그때는 `scripts/restore-table-parse-sample.sh` 로 되돌린다.

Usage:
  $CLOUD_TRANSLATE_PY scripts/check_table_parse.py
  $CLOUD_TRANSLATE_PY scripts/check_table_parse.py --root <worktree>
  $CLOUD_TRANSLATE_PY scripts/check_table_parse.py --doc ko/table-parse-sample.md --verbose

`$CLOUD_TRANSLATE_PY` 는 cloud-translate 의 venv python 이어야 한다
(`app.tables`·`shared.markup_lint`·`markdown` 을 import 한다). 코드 위치는
`CLOUD_TRANSLATE_DIR` (기본 ~/works/cloud-translate).
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

DOC = "table-parse-sample.md"
LANGS = ("ko", "en", "ja")

# 표 인덱스는 문서 안 등장 순서 (1 = 머리말의 '세는 주체' 표)
CASES = (
    # (표 index, 라벨, ko 렌더행, ko 파서행, ko M7, 대상 파서행, 대상 min열,
    #  대상 최빈열, 수정 전 reconcile 이 그 표에 하는 일)
    (2, "A U+2028",      3, 1, 0, 3, 3, 3, "delete"),
    (3, "B 실제 개행",    4, 1, 1, 3, 3, 3, "delete"),
    (4, "C 파이프 누락",  3, 3, 0, 3, 3, 4, "colsync"),
    (5, "D 대조군",       4, 4, 0, 3, 2, 2, "backfill"),
)


def load_deps():
    ct = Path(os.environ.get("CLOUD_TRANSLATE_DIR", Path.home() / "works/cloud-translate"))
    for p in (str(ct), str(ct / "translate")):
        if p not in sys.path:
            sys.path.insert(0, p)
    try:
        from app.llm_patch import _row_key
        from app.tables import (_doc_table_regions, _paired_table_regions,
                                _row_cells, _table_ncols)
        from shared.markup_lint import scan_markup
        import markdown
    except ImportError as exc:                                    # pragma: no cover
        print(f"error: cloud-translate 를 import 하지 못했습니다 ({exc}).", file=sys.stderr)
        print(f"       CLOUD_TRANSLATE_DIR={ct} · venv python 으로 실행했는지 확인하세요.",
              file=sys.stderr)
        raise SystemExit(2)
    return (_doc_table_regions, _paired_table_regions, _row_key,
            _row_cells, _table_ncols, scan_markup, markdown)


_TABLE_RE = re.compile(r"<table>.*?</table>", re.S)
_TR_RE = re.compile(r"<tr>")


def rendered_rows(md, text: str) -> list[int]:
    """각 표의 **렌더된** 데이터 행 수 (헤더 행 제외) — 독자가 보는 값."""
    html = md.markdown(text, extensions=["toc", "tables", "fenced_code",
                                         "admonition", "attr_list"])
    return [len(_TR_RE.findall(t)) - 1 for t in _TABLE_RE.findall(html)]


def ncols_mode(cells_of, rows: list[str]) -> int:
    """행들의 셀 수 최빈값. 동점은 작은 쪽 (순서 무관 결정성)."""
    counts: dict[int, int] = {}
    for r in rows:
        n = len(cells_of(r))
        counts[n] = counts.get(n, 0) + 1
    return min(counts, key=lambda n: (-counts[n], n)) if counts else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=None, help="검사할 워크트리 (기본: 이 레포)")
    ap.add_argument("--doc", default=DOC,
                    help="언어 폴더 아래의 문서 이름 (기본: %s)" % DOC)
    args = ap.parse_args()

    (regions, paired, row_key, row_cells, table_ncols,
     scan_markup, md) = load_deps()
    root = Path(args.root) if args.root else Path(__file__).resolve().parent.parent
    rel = args.doc
    stem = Path(rel).name

    texts: dict[str, str] = {}
    for lang in LANGS:
        p = root / lang / rel
        if not p.is_file():
            print(f"error: not found: {p}", file=sys.stderr)
            return 2
        texts[lang] = p.read_text(encoding="utf-8")

    lines = {l: texts[l].splitlines(keepends=True) for l in LANGS}
    regs = {l: regions(lines[l]) for l in LANGS}
    rend = {l: rendered_rows(md, texts[l]) for l in LANGS}
    m7 = {}
    for l in LANGS:
        _, findings = scan_markup(texts[l], f"{l}/{stem}")
        m7[l] = findings

    def m7_by_table(lang: str) -> dict[int, int]:
        """M7 적발을 표 번호로 귀속. 린터는 finding 을 **블록의 첫 줄** 에 앵커하는데
        그 블록은 표 바로 앞 문단까지 포함할 수 있어, 줄 범위가 아니라 '그 줄
        이후 첫 표' 로 붙인다."""
        heads = [h + 1 for h, _ in regs[lang]]
        hits: dict[int, int] = {}
        for f in m7[lang]:
            if "M7" not in f.rules:
                continue
            for i, head in enumerate(heads, 1):
                if head >= f.line:
                    hits[i] = hits.get(i, 0) + 1
                    break
        return hits

    ko_m7_by_table = m7_by_table("ko")

    print(f"문서: {{ko,en,ja}}/{rel}")
    print()
    print(f"{'표':<14} {'ko 렌더':>7} {'ko 파서':>7} {'ko M7':>6} "
          f"{'en 파서':>7} {'ja 파서':>7} {'en 최소열':>9} {'en 최빈열':>9}  판정")
    print("-" * 92)

    failures: list[str] = []
    missing = [f"{lang} 에 표가 {len(regs[lang])}개뿐입니다 (필요 {CASES[-1][0]}개)"
               for lang in LANGS if len(regs[lang]) < CASES[-1][0]]
    if missing:
        for m in missing:
            print(f"  FAIL  {m}")
        print()
        print("픽스처가 바뀌었습니다 — scripts/restore-table-parse-sample.sh 로 되돌리세요.")
        print("TABLE-PARSE: FAIL")
        return 1

    for idx, label, e_rend, e_parse, e_m7, e_tgt, e_min, e_mode, _v in CASES:
        kh, ke = regs["ko"][idx - 1]
        ko_parse = ke - kh - 2
        ko_rend = rend["ko"][idx - 1] if len(rend["ko"]) >= idx else -1
        ko_m7 = ko_m7_by_table.get(idx, 0)
        got = {}
        for lang in ("en", "ja"):
            h, e = regs[lang][idx - 1]
            rows = lines[lang][h + 2:e]
            got[lang] = (e - h - 2, table_ncols(rows), ncols_mode(row_cells, rows))

        ok = (ko_rend == e_rend and ko_parse == e_parse and ko_m7 == e_m7
              and got["en"][0] == e_tgt and got["ja"][0] == e_tgt
              and got["en"][1] == e_min and got["en"][2] == e_mode)
        if not ok:
            failures.append(
                f"{label}: 기대 렌더{e_rend}/파서{e_parse}/M7 {e_m7}/대상{e_tgt}행"
                f"/최소{e_min}/최빈{e_mode} ≠ 실측 렌더{ko_rend}/파서{ko_parse}"
                f"/M7 {ko_m7}/대상 en {got['en'][0]}·ja {got['ja'][0]}행"
                f"/최소{got['en'][1]}/최빈{got['en'][2]}")
        print(f"{label:<14} {ko_rend:>7} {ko_parse:>7} {ko_m7:>6} "
              f"{got['en'][0]:>7} {got['ja'][0]:>7} {got['en'][1]:>9} "
              f"{got['en'][2]:>9}  {'OK' if ok else 'FAIL'}")

    print()
    print("수정 전 표 reconcile 이 각 표에 하는 일 (모델 호출 없이 선정 로직만 재현)")
    print(f"{'표':<14} {'lang':<5} {'선정':<12} 내용")
    print("-" * 92)
    for lang in ("en", "ja"):
        pairs = paired(texts["ko"], texts[lang])
        if pairs is None:
            failures.append(f"{lang}: 표를 anchor 로 짝지을 수 없습니다")
            continue
        for idx, label, *_rest in CASES:
            expect = _rest[-1]
            pair = pairs[idx - 1] if len(pairs) >= idx else None
            if pair is None:
                failures.append(f"{label}/{lang}: 짝이 없습니다")
                continue
            (kh, ke), (th, te) = pair
            ko_rows = lines["ko"][kh + 2:ke]
            tg_rows = lines[lang][th + 2:te]
            kk = [row_key(r) for r in ko_rows]
            tk = [row_key(r) for r in tg_rows]
            keyed = (all(kk) and all(tk) and len(set(kk)) == len(kk)
                     and len(set(tk)) == len(tk)
                     and table_ncols(ko_rows) == table_ncols(tg_rows))
            if keyed:
                extras = [k for k in tk if k not in set(kk)]
                miss = [k for k in kk if k not in set(tk)]
                got = "delete" if extras else ("backfill" if miss else "noop")
                detail = (f"ko 에 없는 행 {extras} 삭제" if extras
                          else (f"ko 의 {miss} 백필" if miss else "변경 없음"))
            else:
                diverged = table_ncols(ko_rows) != table_ncols(tg_rows)
                got = "colsync" if diverged else "noop"
                detail = (f"열 {table_ncols(ko_rows)}↔{table_ncols(tg_rows)} 로 읽혀 "
                          f"header 포함 전체 재작성" if diverged else "변경 없음")
            mark = "OK" if got == expect else "FAIL"
            if mark == "FAIL":
                failures.append(f"{label}/{lang}: 기대 {expect} ≠ 실측 {got}")
            print(f"{label:<14} {lang:<5} {got:<12} {detail}  [{mark}]")

    print()
    print("읽는 법")
    print("  A  렌더 3 ≠ 파서 1 인데 M7 0 — 문서는 정상이고 파이프라인만 1행으로 읽는다.")
    print("     reconcile 이 ko 를 정본으로 삼아 en/ja 의 2·3행을 삭제한다.")
    print("     렌더가 멀쩡하므로 마크업 정정은 원리상 이 표에 닿지 않는다.")
    print("  B  같은 파서 1행인데 M7 이 적발한다 — 렌더도 깨지기 때문. 정비가 고쳐 준다.")
    print("  C  세 언어 모두 3행으로 행 수가 이미 같은데, en/ja 의 최소열(3) ≠ 최빈열(4) 때문에")
    print("     스키마 불일치로 읽혀 header 포함 전체 재작성이 선정된다.")
    print("  D  대조군 — en/ja 에 ko 의 SVC-104 가 없다. 여전히 수리되어야 하는 진짜 결함.")

    if failures:
        print()
        for f in failures:
            print(f"  FAIL  {f}")
        print()
        print("픽스처가 바뀌었습니다 — scripts/restore-table-parse-sample.sh 로 되돌리세요.")
        print("TABLE-PARSE: FAIL")
        return 1
    print()
    print("TABLE-PARSE: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
