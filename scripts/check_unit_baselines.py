#!/usr/bin/env python3
"""`UNIT_PRESERVE` 가 유닛마다 **어떤 베이스라인을 붙이는지** 결정적으로 검사한다.

cloud-translate #924 의 `--unit-preserve` (`TRANSLATE_DIFF_UNIT_PRESERVE`) 는
바뀐 유닛을 재번역할 때 그 유닛의 **기존 번역**을 함께 보여 주고 "ko 가 안 바뀐
부분은 바이트 그대로 재사용하라" 고 지시한다. 효과는 크지만 전제가 하나 있다 —
**붙는 베이스라인이 그 유닛의 진짜 짝이어야 한다.** 짝이 밀리면 모델은 지시대로
남의 문장을 그대로 베끼고, 그게 그대로 커밋된다.

실제로 그 일이 일어나서 이 옵션은 지금 기본 off 다 (2026-09-18 Agent-Test round1
ON 실행: `component-guide.md` 의 en·ja 에 `<a id="nat-instance">` 가 한 줄씩 더
들어가 anchor id 가 ko 127 : 번역본 128 이 됐다).

## 왜 산출물 검사로는 부족한가

모델이 미끼를 문 **그 실행에서만** 보인다. 같은 입력이라도 다음 번에는 안 베낄 수
있어서 통과/실패가 그날 모델에 달린다. 반면 **무엇이 베이스라인으로 붙는가**는
모델을 부르기 전에 정해지는 순수 함수다. 이 스크립트는 그 자리를 본다.

## 검사 규칙 (모두 "짝이 맞는가" 한 가지를 다른 각도에서 본 것)

프롬프트가 베이스라인을 어떻게 소개하는지가 규칙의 근거다 —
`_build_unit_baseline_section` 은 "This Korean text already has a translation,
shown below" 라고 **단정** 하고 "Reuse the existing wording byte-for-byte" 를
지시한다. 짝이 틀리면 그 단정 자체가 거짓이 된다. 그래서 네 규칙은 전부
"바이트 그대로 베꼈을 때 무슨 일이 일어나는가" 로 쓰여 있다.

  (1) foreign-anchor — 베이스라인이 그 ko 유닛에 **없는** anchor id 를 갖고 있다.
      베끼면 그 anchor 가 문서에 **복제** 된다. 위 사고의 정확한 모양.
  (2) body-injected  — ko 유닛에는 산문이 없는데(heading·이미지·표 헤더뿐)
      베이스라인에는 있다. 베끼면 그 본문이 문서에 **두 번** 들어간다
      (자기 자리에 한 번, 이 유닛 자리에 또 한 번).
  (3) body-dropped   — ko 유닛에는 산문이 있는데 베이스라인에는 없다.
      베끼면 그 본문이 **사라진다**. 짧아서 `diff_unit_preserve_min_chars`(200)
      허용치를 통과하고, `replace` 라 INSERT 가드도 안 걸린다.
  (4) stub           — 베이스라인이 `<!-- TODO: translate ... -->` 채우기 스텁이다.
      베끼면 번역 자리에 스텁이 들어간다.

길이비 상한(`diff_unit_preserve_max_ratio` 4배)은 네 모양을 하나도 막지 못한다 —
밀린 짝은 대개 **비슷한 크기의 다른 문단** 이라 상한 안에 편히 들어온다.

`clean` 은 위 어디에도 안 걸린 베이스라인이다 — 이 옵션이 원래 의도한 모양.

## Usage

  # 리포의 ko↔en/ja 쌍 전수 — ko 를 합성 변경해 무엇이 붙는지 본다
  $CLOUD_TRANSLATE_PY scripts/check_unit_baselines.py --mutation add_paragraph
  $CLOUD_TRANSLATE_PY scripts/check_unit_baselines.py --mutation edit_body --verbose

  # 실제 PR 모양 — base 워크트리(변경 전 ko)와 head 워크트리(변경 후 ko)
  $CLOUD_TRANSLATE_PY scripts/check_unit_baselines.py \
      --root <head-wt> --old-root <base-wt> --files ko/unit-preserve-drift.md

`$CLOUD_TRANSLATE_PY` 는 cloud-translate 의 venv python 이어야 한다 (translator 를
import 한다). 코드 위치는 `CLOUD_TRANSLATE_DIR` (기본 ~/works/cloud-translate).

마지막 줄은 `UNIT_BASELINES: OK` / `UNIT_BASELINES: FAIL` — e2e 스크립트가
`grep -q` 로 읽는 계약이므로 바꾸지 말 것. 규칙 위반이 하나라도 있으면 FAIL.
"""

import argparse
import asyncio
import io
import json
import os
import pathlib
import re
import sys

CT_DIR = pathlib.Path(
    os.environ.get("CLOUD_TRANSLATE_DIR", str(pathlib.Path.home() / "works/cloud-translate"))
)
sys.path[:0] = [str(CT_DIR / "translate"), str(CT_DIR)]

try:
    from app.translator import Translator, _unit_baseline_ctx, _usable_unit_baseline
    from shared.config import settings
    from shared.github_client import pre_align_marker
except Exception as exc:  # pragma: no cover
    print(f"error: cloud-translate 를 import 하지 못했습니다 ({CT_DIR}): {exc}", file=sys.stderr)
    print("  CLOUD_TRANSLATE_DIR 와 venv python 을 확인하세요.", file=sys.stderr)
    raise SystemExit(1)

LANGS = ("en", "ja")

# anchor id — `<a id="x">` / `<tag id="x">` / heading 의 `{ #x }` 셋 다.
_ANCHOR_RE = re.compile(r'<[a-zA-Z][\w]*\b[^>]*?\bid\s*=\s*"([^"]+)"|\{\s*#([\w.:-]+)\s*\}')
# "마크업뿐" 으로 세는 줄 — anchor 태그, HTML 주석, heading, 빈 줄.
_MARKUP_LINE_RE = re.compile(
    r'^\s*(?:<a\b[^>]*>(?:</a>)?|<!--.*?-->|#{1,6}\s.*|<br\s*/?>)\s*$'
)
_STUB_RE = re.compile(r'<!--\s*TODO:\s*translate', re.I)


def anchor_ids(text: str) -> set[str]:
    return {m.group(1) or m.group(2) for m in _ANCHOR_RE.finditer(text)}


def is_markup_only(text: str) -> bool:
    lines = [l for l in text.splitlines() if l.strip()]
    return bool(lines) and all(_MARKUP_LINE_RE.match(l) for l in lines)


def prose_chars(text: str) -> int:
    """마크업 줄을 뺀 본문 글자 수 — '제목 한 줄뿐' 을 판별한다."""
    return sum(len(l.strip()) for l in text.splitlines()
               if l.strip() and not _MARKUP_LINE_RE.match(l))


# 산문 40자 — 한 문장의 하한. 그 아래는 제목 꼬리표·캡션과 구분이 안 된다.
PROSE_MIN = 40


def classify(unit: str, baseline: str) -> list[str]:
    """이 (유닛, 베이스라인) 짝이 어긴 규칙들. 빈 목록이면 정상 짝."""
    bad = []
    if anchor_ids(baseline) - anchor_ids(unit):
        bad.append("foreign-anchor")
    if prose_chars(unit) == 0 and prose_chars(baseline) >= PROSE_MIN:
        bad.append("body-injected")
    if prose_chars(unit) >= PROSE_MIN and prose_chars(baseline) == 0:
        bad.append("body-dropped")
    if _STUB_RE.search(baseline):
        bad.append("stub")
    return bad


# ── ko 합성 변경 (create-translate-test-pr.sh 의 같은 이름 mutation 과 동형) ──

_HEADING_RE = re.compile(r'^#{1,6}[ \t]')


def mutate(text: str, kind: str) -> str | None:
    lines = text.split("\n")
    if kind == "add_paragraph":
        for i, l in enumerate(lines):
            if _HEADING_RE.match(l.rstrip("\r")):
                lines[i + 1:i + 1] = [
                    "",
                    "이 문단은 기존 섹션에 추가된 테스트 문단입니다. 기존 heading 은 그대로 유지되어야 합니다.",
                    "",
                ]
                return "\n".join(lines)
        return None
    if kind == "edit_body":
        # 표·펜스·목록·앵커가 아닌 산문 줄 하나의 끝에 문장을 덧붙인다 —
        # 이 옵션이 노리는 바로 그 모양(한 문단 안 한 문장만 변경).
        infence = False
        for i, l in enumerate(lines):
            s = l.strip()
            if s.startswith("```"):
                infence = not infence
                continue
            if infence or not s or len(s) < 40:
                continue
            if s.startswith(("#", "|", ">", "<", "*", "-", "!", "{")):
                continue
            lines[i] = l.rstrip("\r") + " 이 문장은 e2e 가 덧붙인 변경입니다."
            return "\n".join(lines)
        return None
    raise SystemExit(f"unknown mutation: {kind}")


# ── 번역을 돌려 (모델이 받는 유닛, 그때 렌더되는 베이스라인) 쌍을 수집 ──────

class _Probe(Translator):
    """진짜 Translator — 모델 호출 한 겹만 가로챈다.

    `translate_diff` 를 통째로 태우는 것이 중요하다. pre-align 마커가 있는
    문서는 워커가 **anchor splice**(`_splice_by_anchors`)를 태우고, 그쪽은
    `_section_diff_splice` 를 anchor 섹션 **안에서** 다시 부른다 —
    `_section_diff_splice` 만 직접 부르면 운영과 다른 짝을 보게 된다.
    (그리고 그 anchor 섹션이 heading 에서 잘리기 때문에 **다음 섹션의
    `<a id>` 줄이 앞 섹션의 마지막 유닛**이 된다. 사고의 27자 베이스라인이
    바로 그것이다.)

    돌려주는 값은 받은 내용 그대로다 — 배치 split-back 이 성공해야 운영과 같은
    호출 구조가 유지된다(실패하면 per-unit 폴백으로 갈라져 호출이 달라진다).
    """

    def __init__(self):
        super().__init__(glossary=None)
        self.recs: list[tuple[str, str | None]] = []

    async def translate(self, content, reference=None, target_lang="en",
                        target_dir="en", *a, **k):
        # `_usable_unit_baseline` 은 프롬프트 빌더와 카세트 키가 쓰는 바로 그
        # 순수 함수다 — 여기서 부르면 "실제로 렌더됐을 값" 과 정의상 같다.
        self.recs.append((content, _usable_unit_baseline(content)))
        return content

    async def _translate_chunk_uncached(self, content, *a, **k):  # 도달하지 않음
        return content

    async def _verify_chunk_uncached(self, *a, **k):              # 도달하지 않음
        return ""


async def collect(old_ko: str, new_ko: str, existing: str, lang: str):
    probe = _Probe()
    # 워커와 같은 판단 (`worker._translate_one` 참고): ko 와 대상의 pre-align
    # 마커가 같으면 `prealigned`, 그리고 anchor splice 가 도는 경우
    # (`prealigned` 이거나 `--align-headings`) 에는 **변경 판정의 기준이 되는
    # 실제 base ko** 를 함께 넘겨야 한다. 안 넘기면 anchor 가 맞는 섹션은 전부
    # "안 바뀜" 으로 읽혀 한 유닛도 재번역되지 않는다.
    ko_sig = pre_align_marker(new_ko)
    prealigned = bool(ko_sig) and ko_sig == pre_align_marker(existing)
    use_anchor = prealigned or bool(settings.diff_align_headings)
    out = await probe.translate_diff(
        existing, new_ko, old_ko, None, lang, lang,
        prealigned=prealigned,
        content_baseline_ko=old_ko if use_anchor else None,
    )
    return out, probe.recs, prealigned


def read(path: pathlib.Path) -> str | None:
    try:
        return io.open(path, encoding="utf-8", newline="").read()
    except OSError:
        return None


async def main() -> int:
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--root", default=".", help="head 워크트리 (ko 변경 후 + 기존 en/ja)")
    ap.add_argument("--old-root", default=None,
                    help="base 워크트리 (변경 전 ko). 없으면 --mutation 으로 합성")
    ap.add_argument("--files", default="", help="검사할 ko 경로 콤마 목록 (기본: ko/**.md 전수)")
    ap.add_argument("--mutation", default="add_paragraph",
                    choices=("add_paragraph", "edit_body"))
    ap.add_argument("--granularity", default="block", choices=("block", "section"))
    ap.add_argument("--allow-empty", action="store_true",
                    help="베이스라인이 하나도 안 붙어도 OK (코퍼스 전수 스윕용 — "
                         "삽입만 있는 변경은 짝이 없어 정상적으로 0 이다)")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--json", dest="json_out", default=None, help="상세를 JSON 으로 저장")
    ap.add_argument("-h", "--help", action="store_true")
    args = ap.parse_args()
    if args.help:
        print(__doc__)
        return 0

    root = pathlib.Path(args.root).resolve()
    old_root = pathlib.Path(args.old_root).resolve() if args.old_root else None

    if args.files.strip():
        ko_files = [f.strip() for f in args.files.split(",") if f.strip()]
    else:
        ko_files = sorted(
            str(p.relative_to(root)) for p in (root / "ko").rglob("*.md")
        )

    # 운영 recommended 와 같은 조합 (+ 이 옵션 ON)
    settings.diff_unit_preserve = True
    settings.diff_granularity = args.granularity
    settings.diff_table_rows = True
    settings.diff_list_items = True
    settings.diff_align_headings = True
    settings.diff_mode = "incremental"

    totals = dict(pairs=0, calls=0, baselines=0, clean=0)
    by_rule: dict[str, int] = {}
    rows = []
    detail = []

    for ko_rel in ko_files:
        ko_new = read(root / ko_rel)
        if ko_new is None:
            print(f"  (없음) {ko_rel}", file=sys.stderr)
            continue
        if old_root is not None:
            ko_old = read(old_root / ko_rel)
            if ko_old is None:
                continue
            if ko_old == ko_new:
                continue
        else:
            ko_old = ko_new
            m = mutate(ko_new, args.mutation)
            if m is None:
                continue
            ko_new = m
        rel = ko_rel[3:] if ko_rel.startswith("ko/") else ko_rel
        for lang in LANGS:
            existing = read(root / lang / rel)
            if not existing:
                continue
            try:
                out, recs, prealigned = await collect(ko_old, ko_new, existing, lang)
            except Exception as exc:               # 픽스처가 아니라 코드 문제
                rows.append((ko_rel, lang, f"error: {exc}", 0, 0, {}))
                continue
            if out is None:
                rows.append((ko_rel, lang, "splice bail (검사 대상 아님)", 0, 0, {}))
                continue
            totals["pairs"] += 1
            totals["calls"] += len(recs)
            flags: dict[str, int] = {}
            nbl = 0
            for unit, bl in recs:
                if not bl:
                    continue
                nbl += 1
                totals["baselines"] += 1
                bad = classify(unit, bl)
                if not bad:
                    totals["clean"] += 1
                for b in bad:
                    flags[b] = flags.get(b, 0) + 1
                    by_rule[b] = by_rule.get(b, 0) + 1
                if bad:
                    detail.append(dict(file=ko_rel, lang=lang, rules=bad,
                                       unit=unit[:300], baseline=bl[:300]))
            rows.append((ko_rel, lang, "ok", len(recs), nbl, flags))

    print(f"== UNIT_PRESERVE 베이스라인 짝 검사 (granularity={args.granularity}, "
          f"{'실제 diff' if old_root else 'mutation=' + args.mutation}) ==")
    for ko_rel, lang, state, calls, nbl, flags in rows:
        if state != "ok":
            print(f"  {ko_rel:38s} {lang}  {state}")
            continue
        tag = " ".join(f"{k}={v}" for k, v in sorted(flags.items())) or "clean"
        print(f"  {ko_rel:38s} {lang}  유닛 {calls:3d}  베이스라인 {nbl:3d}  {tag}")

    bad_total = sum(by_rule.values())
    print()
    print(f"  파일×언어 {totals['pairs']} · 재번역 유닛 {totals['calls']} · "
          f"베이스라인 {totals['baselines']} (정상 {totals['clean']})")
    if by_rule:
        print("  위반: " + ", ".join(f"{k} {v}" for k, v in sorted(by_rule.items())))

    if args.verbose:
        for d in detail:
            print()
            print(f"  --- {d['file']} [{d['lang']}] {'+'.join(d['rules'])}")
            print(f"      UNIT     : {d['unit']!r}")
            print(f"      BASELINE : {d['baseline']!r}")
    if args.json_out:
        pathlib.Path(args.json_out).write_text(
            json.dumps(dict(totals=totals, by_rule=by_rule, detail=detail),
                       ensure_ascii=False, indent=2), encoding="utf-8")

    print()
    if totals["baselines"] == 0 and not args.allow_empty:
        # 특정 모양을 노리고 부를 때는 이게 곧 "픽스처가 조건을 잃었다" 다.
        # 코퍼스 전수 스윕에서는 정상일 수 있으므로 --allow-empty 로 허용한다.
        print("  베이스라인이 하나도 붙지 않았다 — 검사 대상이 없다 (픽스처/플래그 확인)")
        print("UNIT_BASELINES: FAIL")
        return 1
    if bad_total:
        print(f"UNIT_BASELINES: FAIL")
        return 1
    print("UNIT_BASELINES: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
