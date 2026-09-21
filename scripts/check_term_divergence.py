#!/usr/bin/env python3
"""용어 갈림 측정 — 한 번역본 안에서 같은 ko 문자열이 몇 가지 역어를 갖는가.

cloud-user-guide-agent#418 (코퍼스 743건 · 50 리포) 의 축을 **모델 없이** 잰다.
`app/notation.py` 가 보는 두 축(ja 공백 · 한글 잔존) 어디에도 없는 세 번째 축이고,
지금 파이프라인에 이것을 보는 장치가 없으므로 e2e 가 스스로 잰다.

## 재는 방법 — 표의 칸을 슬롯으로 쓴다

ko 문서와 번역본에서 **표를 등장 순서로 짝짓고**, 같은 (표, 행, 열) 자리의 ko 셀과
역어 셀을 하나의 슬롯으로 본다. 슬롯은 언어와 무관하게 위치로만 정해지므로 형태소
분석도 정렬 모델도 필요 없다. 같은 ko 셀이 여러 슬롯에 나오면 그 역어들이 한 가지인지
센다 — 그것이 곧 "한 문서 안에서 이 용어가 갈렸는가" 다.

산문 축은 표에서 확정된 역어의 **출현 수**로 본다 (#418 §4(b)): ko 가 N 번 쓴 말의
역어가 번역본에 N 번보다 적게 나오면 나머지 자리는 다른 표기다.

## 반드시 거르는 것 — 행 밀림 (#418 §6)

표의 행이 밀리면 엉뚱한 칸끼리 짝지어져 용어 갈림처럼 보인다. 역방향 맵을 만들어
**그 역어가 다른 ko 셀의 역어이기도 하면** 그 ko 는 `shifted` 로 빼고 센다 — 코퍼스
실측에서 이 필터가 913건을 743건으로 줄였다 (170건이 오탐).

행 수가 다른 표는 짝짓지 않는다 (`row-count`).

Usage:
    check_term_divergence.py --ko ko/a.md --target en/a.md [--lang en]
    check_term_divergence.py --ko ko/a.md --target ja/a.md --terms '용어1,용어2'
    check_term_divergence.py ... --json
"""
from __future__ import annotations

import argparse
import collections
import json
import pathlib
import re
import sys

MIN_TERM_LEN = 2          # 1음절 한글은 형태소라 의미가 없다 (term_table 과 같은 값)
HANGUL = re.compile(r'[가-힣]')
FENCE = re.compile(r'^\s*(```|~~~)')


def _table_blocks(text: str) -> list[list[str]]:
    """문서의 표를 등장 순서대로. 코드 펜스 안은 표가 아니다."""
    out, cur, in_fence = [], [], False
    for line in text.splitlines():
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if line.lstrip().startswith('|'):
            cur.append(line)
            continue
        if cur:
            out.append(cur)
            cur = []
    if cur:
        out.append(cur)
    return [t for t in out if len(t) >= 3]


def _cells(line: str) -> list[str]:
    body = line.strip()
    if body.startswith('|'):
        body = body[1:]
    if body.endswith('|'):
        body = body[:-1]
    return [c.strip() for c in body.split('|')]


def _is_sep(line: str) -> bool:
    return all(re.fullmatch(r':?-{2,}:?', c or '-') for c in _cells(line))


def _rows(table: list[str]) -> list[list[str]]:
    """구분선을 빼고 헤더 포함 모든 행. 인덱스가 곧 슬롯 좌표다."""
    return [_cells(l) for l in table if not _is_sep(l)]


def slot_map(ko_text: str, tgt_text: str) -> tuple[dict, list[str]]:
    """``{ko셀: Counter(역어셀)}`` 과 짝짓지 못한 사유."""
    ko_tables, tgt_tables = _table_blocks(ko_text), _table_blocks(tgt_text)
    notes: list[str] = []
    if len(ko_tables) != len(tgt_tables):
        notes.append(f'table-count ko={len(ko_tables)} tgt={len(tgt_tables)}')
    pairs: dict[str, collections.Counter] = collections.defaultdict(collections.Counter)
    for n, (kt, tt) in enumerate(zip(ko_tables, tgt_tables)):
        kr, tr = _rows(kt), _rows(tt)
        if len(kr) != len(tr):
            notes.append(f'row-count table#{n} ko={len(kr)} tgt={len(tr)}')
            continue
        for krow, trow in zip(kr, tr):
            if len(krow) != len(trow):
                notes.append(f'col-count table#{n}')
                continue
            for kc, tc in zip(krow, trow):
                if (len(kc) >= MIN_TERM_LEN and HANGUL.search(kc)
                        and tc and not HANGUL.search(tc)):
                    pairs[kc][tc] += 1
    return pairs, notes


def divergence(ko_text: str, tgt_text: str, terms: list[str] | None = None) -> dict:
    pairs, notes = slot_map(ko_text, tgt_text)

    # 행 밀림 필터 — 한 역어가 둘 이상의 ko 셀에 걸리면 그 ko 는 판정하지 않는다.
    back: dict[str, set[str]] = collections.defaultdict(set)
    for ko, forms in pairs.items():
        for form in forms:
            back[form].add(ko)
    shifted = {ko for ko, forms in pairs.items()
               if any(len(back[f]) > 1 for f in forms)}

    result = {'terms': {}, 'notes': notes, 'shifted': sorted(shifted)}
    wanted = [t for t in (terms or sorted(pairs)) if t in pairs and t not in shifted]
    for ko in wanted:
        forms = pairs[ko]
        major = forms.most_common(1)[0][0]
        ko_hits = ko_text.count(ko)
        # 산문 축: 확정 역어가 ko 출현 수만큼 나오는가 (#418 §4(b)).
        tgt_hits = sum(tgt_text.count(f) for f in forms)
        result['terms'][ko] = {
            'forms': dict(forms.most_common()),
            'form_count': len(forms),
            'major': major,
            'ko_occurrences': ko_hits,
            'target_occurrences_of_known_forms': tgt_hits,
            'prose_gap': max(0, ko_hits - tgt_hits),
            'diverged': len(forms) > 1,
        }
    result['diverged_terms'] = sorted(k for k, v in result['terms'].items() if v['diverged'])
    result['slot_terms'] = len(result['terms'])
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--ko', required=True)
    ap.add_argument('--target', required=True)
    ap.add_argument('--lang', default='')
    ap.add_argument('--terms', default='', help='쉼표로 구분한 ko 용어 (기본: 표에서 발견한 전부)')
    ap.add_argument('--json', action='store_true')
    a = ap.parse_args()

    ko = pathlib.Path(a.ko).read_text(encoding='utf-8', errors='replace')
    tgt = pathlib.Path(a.target).read_text(encoding='utf-8', errors='replace')
    terms = [t.strip() for t in a.terms.split(',') if t.strip()] or None
    out = divergence(ko, tgt, terms)
    out['lang'] = a.lang
    if a.json:
        print(json.dumps(out, ensure_ascii=False, indent=2))
        return 0
    print(f"  슬롯에서 짝지은 ko 용어 {out['slot_terms']}개"
          f" · 갈린 용어 {len(out['diverged_terms'])}개"
          + (f" · 행 밀림 제외 {len(out['shifted'])}개" if out['shifted'] else ''))
    for note in out['notes']:
        print(f"    note: {note}")
    for ko_term, info in sorted(out['terms'].items(),
                                key=lambda kv: (-kv[1]['form_count'], kv[0])):
        mark = '갈림' if info['diverged'] else '고정'
        forms = ' / '.join(f'"{k}"x{v}' for k, v in info['forms'].items())
        print(f"    [{mark}] {ko_term} -> {forms}")
        if info['prose_gap']:
            print(f"           산문 미스: ko {info['ko_occurrences']}회 vs 역어"
                  f" {info['target_occurrences_of_known_forms']}회"
                  f" (차 {info['prose_gap']})")
    return 0


if __name__ == '__main__':
    sys.exit(main())
