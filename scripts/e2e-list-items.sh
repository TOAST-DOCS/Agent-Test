#!/usr/bin/env bash
#
# 목록 항목 splice e2e — cloud-translate #924 의 `LIST_ITEMS` 가 실제 파일에서
# 켜지는지 검증.
#
# 검증 대상: 불릿 하나를 고쳤을 때 **같은 목록의 형제 불릿이 모델에 전송되지
# 않는다**. `--list-items` (`TRANSLATE_DIFF_LIST_ITEMS`) 가 약속하는 것이 그것이고,
# 플래그가 켜졌다는 로그가 아니라 **무엇이 전송되었는가**로 확인해야 하는 이유는
# 아래 사고 때문이다.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# TOAST-DOCS/TOAST-Cloud#415 (2026-09-18 머지, alpha 배포됨).
# ko PR #414 는 「Public API 시작하기」 목록에서 **불릿 하나의 후행 공백**만
# 지웠는데, ja 번역이 같은 목록의 형제 불릿 4개를 함께 다시 썼다:
#     - `[認証方式の概要]`     -> `[認証方法の概要]`
#     - `[認証方式サポート状況]` -> `[認証方法サポート状況]`
#   두 링크가 도착하는 문서의 제목은 `認証方式概要` · `認証方式のサポート状況` 라,
#   라벨만 대상 제목과 어긋났다. 같은 페이지 본문은 `認証方式` 를 9번 쓴다.
# 같은 모양의 선례가 TOAST-DOCS/AppGuard#446 (2026-09-11) 이고, #924 는 바로 그
# 사고를 막으려고 들어왔다.
#
# ── 그런데 #924 가 이 파일에서는 안 걸린다 ────────────────────────────────
# `LIST_ITEMS=on/off` 의 결과가 **바이트 단위로 같다** (실측: 둘 다 목록 6줄
# 228자 전송). 원인은 `_maybe_expand_lists` 의 채택 조건이 문서 전체 유닛 개수의
# **엄격 일치**(`len(fine_old) != len(fine_en)` -> 거절)인데, 번역본 첫 줄
# `<!-- machine_translated: true -->` 가 ko 에는 없어 개수가 1 어긋나기 때문이다.
# 목록 자체는 6<->6 으로 완벽히 정렬된다.
#
# 거친(coarse) 경로는 같은 불일치를 `_structural_alignment`
# (`diff_structural_fallback`) 로 견딘다. 목록 확장만 못 견딘다.
#
# 코퍼스 실측 (2026-09-21, 171 리포 · ko<->en/ja 파일쌍 2,702 · test/depre 및
# region variant 제외):
#     채택 1,795 (66.4%) · 거절 907 (33.6%)
#       그중 **마커 한 줄만 빼면 채택됐을 것 140건** (전체의 5.2%)
# 그 140건이 곧 최근 기계 번역된 파일 — 마커는 번역기가 찍는 것이므로,
# `LIST_ITEMS` 가 가장 자주 필요한 모집단이 정확히 그 사각지대다.
#
# ── 왜 리포 상주 픽스처인가 ───────────────────────────────────────────────
# 조건이 **파일 사이의 비대칭**이라 한 파일만 봐서는 보이지 않는다. ko 에는 없고
# en/ja 첫 줄에만 있는 그 한 줄이 나란히 놓여야 한다. 그리고 alpha 의 기존 en/ja
# 픽스처는 **한 장도 마커를 갖고 있지 않아서**(2026-09-21 실측 en 0/19 · ja 0/16)
# 지금까지 어떤 e2e 도 이 조건을 만들지 못했다 — round1 이 만드는 번역본은 마커를
# 달지만 round1 의 *입력* 이 되는 시드에는 없고, 마커 달린 번역본을 입력으로 받는
# round2 는 `e2e-suite.sh all` 에서 빠져 있다.
#
# ── 왜 모델을 태우지 않는가 ───────────────────────────────────────────────
# 판정이 **결정적**이기 때문이다. `_maybe_expand_lists` 는 순수 함수이고, 무엇이
# 전송되는가는 모델을 부르기 **전에** 정해진다. 모델을 태우면 오히려 판정이
# 흐려진다 — 노출된 불릿이 *매번* 다시 쓰이는 것은 아니라서(실제로 그 사고에서도
# en 만 갈리고 ja 는 우연히 같은 표현을 냈다) 통과/실패가 그날 모델에 달린다.
# 그래서 이 e2e 는 전송 내용만 보고, 네트워크도 git 브랜치도 쓰지 않는다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) 리포 워킹 트리에서 ko/en/ja list-items-sample.md 를 읽는다
#   2) 메모리에서 ko 의 **마지막 불릿 하나만** 바꾼다 (head ko)
#   3) `Translator._section_diff_splice` 를 mock 번역기로 돌려 전송분을 수집
#   4) 같은 것을 **대조군**(en/ja 첫 줄 마커만 제거)으로 한 번 더
#   5) 판정
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) 픽스처가 조건을 유지하고 있다 — en/ja 첫 줄이 마커, ko 첫 줄은 아니다
#   (2) LIST_ITEMS=on 에서 `_maybe_expand_lists` 가 **채택**한다      <- 본체
#   (3) LIST_ITEMS=on 에서 고정 형제 불릿이 **전송되지 않는다**       <- 본체
#   (4) 대조군(마커 제거)에서는 (2)(3) 이 성립한다 — 원인 격리
#   (5) LIST_ITEMS=off 에서는 전송된다 (플래그가 실제로 일을 하는지)
#
# **(2)(3) 은 지금 FAIL 이 정상이다.** 파이프라인이 고쳐지기 전에는 이 e2e 가
# 빨간 것이 "아직 안 닫혔다" 의 기계 판독 신호다. 그래서 `e2e-suite.sh` 의 `all`
# 목록에 넣지 않는다 (llm-patch · preserve 가 같은 이유로 빠져 있다).
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  결함이 닫혔다 — (1)~(5) 전부 통과
#   3  결함이 재현됐다 — (2)(3) 만 실패하고 대조군 (4) 는 통과 (현행 기대값)
#   1  스크립트/환경 오류, 또는 대조군까지 실패 (픽스처가 깨졌다는 뜻)
#
# Usage:
#   bash scripts/e2e-list-items.sh
#   bash scripts/e2e-list-items.sh --verbose
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-list-items.sh
#
# 의존성: python3 (cloud-translate 의 .venv), cloud-translate 체크아웃. 네트워크 불필요.
set -eo pipefail
set -u

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$CLOUD_TRANSLATE_DIR/.venv/bin/python}"
DOC="list-items-sample.md"
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose|-v) VERBOSE=1; shift ;;
    --doc) DOC="$2"; shift 2 ;;
    -h|--help) sed -n '1,80p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }
for l in ko en ja; do
  [[ -f "$l/$DOC" ]] || { echo "픽스처 없음: $l/$DOC" >&2; exit 1; }
done

echo "=== 목록 항목 splice e2e ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR"
echo "  픽스처          : {ko,en,ja}/$DOC"
echo

CT_DIR="$CLOUD_TRANSLATE_DIR" DOCNAME="$DOC" VERBOSE="$VERBOSE" \
  "$CLOUD_TRANSLATE_PY" - "$REPO_ROOT" <<'PY'
import asyncio, os, pathlib, re, sys
from unittest.mock import AsyncMock

CT = pathlib.Path(os.environ["CT_DIR"])
sys.path[:0] = [str(CT / "translate"), str(CT)]

from app.translator import (Translator, _expand_list_blocks,
                            _expand_table_blocks, _split_paragraphs,
                            _split_paragraphs_raw)
from shared.config import settings
from tests.test_translator import _splice_mock

REPO = pathlib.Path(sys.argv[1])
DOC = os.environ["DOCNAME"]
VERBOSE = os.environ.get("VERBOSE") == "1"
MARK = "<!-- machine_translated: true -->"

ko = (REPO / "ko" / DOC).read_text(encoding="utf-8")
en = (REPO / "en" / DOC).read_text(encoding="utf-8")
ja = (REPO / "ja" / DOC).read_text(encoding="utf-8")

# 고정 형제 불릿 — 전송되면 안 되는 줄. ko 쪽 텍스트로 찾는다.
PINNED = ["[인증 방식 개요]", "[기능별 설정]"]
# 변경 대상 — 목록의 마지막 항목 하나만 바꾼다.
EDIT_FROM = "* [릴리스 노트](./release-notes/)"
EDIT_TO = "* [릴리스 노트 및 변경 이력](./release-notes/)"

fail = []


def check(num, ok, desc, detail=""):
    print(f"  ({num}) {'OK  ' if ok else 'FAIL'}  {desc}")
    if detail:
        print(f"           {detail}")
    if not ok:
        fail.append(num)
    return ok


# ── (1) 픽스처가 조건을 유지하고 있는가 ──────────────────────────────────
print("[1/4] 픽스처 조건")
cond = en.startswith(MARK) and ja.startswith(MARK) and not ko.startswith(MARK)
check(1, cond, "en/ja 첫 줄이 machine_translated 마커 · ko 는 아님",
      f"ko={ko.splitlines()[0][:40]!r}")
if not cond:
    print("\n픽스처가 조건을 잃었다 — 이 e2e 는 의미가 없다.")
    sys.exit(1)
if EDIT_FROM not in ko:
    print(f"\n변경 대상 불릿을 찾지 못했다: {EDIT_FROM!r}")
    sys.exit(1)

ko_head = ko.replace(EDIT_FROM, EDIT_TO)
strip = lambda t: re.sub(r"\A" + re.escape(MARK) + r"\n+", "", t)


def counts(ko_text, tgt_text):
    """`_maybe_expand_lists` 가 비교하는 바로 그 두 숫자."""
    k = _expand_list_blocks(_expand_table_blocks(_split_paragraphs(ko_text)))
    t = _expand_list_blocks(
        _expand_table_blocks(_split_paragraphs_raw(tgt_text), raw=True), raw=True)
    return len(k), len(t)


async def sent_units(existing, lang, list_items):
    settings.diff_list_items = list_items
    settings.diff_table_rows = True
    settings.diff_granularity = "block"
    out = []
    mock = _splice_mock()

    async def _tr(content, *a, **k):
        out.append(content)
        lines = content.splitlines()
        return "[T]" + (lines[0] if lines else "")

    mock.translate = AsyncMock(side_effect=_tr)
    mock._splice_changed_table_rows = AsyncMock(return_value=None)
    await Translator._section_diff_splice(
        mock, existing, ko_head, ko, None, lang, lang)
    return out


def leaked(units):
    return sorted({p for p in PINNED for u in units if p in u})


async def arm(tag, en_t, ja_t, list_items):
    rows = {}
    for lang, tgt in (("en", en_t), ("ja", ja_t)):
        k, t = counts(ko, tgt)
        units = await sent_units(tgt, lang, list_items)
        rows[lang] = dict(ko_units=k, tgt_units=t, adopt=k == t,
                          calls=len(units), chars=sum(len(u) for u in units),
                          leak=leaked(units), units=units)
    for lang, r in rows.items():
        print(f"      {tag} {lang}: 유닛 ko={r['ko_units']} 대상={r['tgt_units']}"
              f" -> 채택={'예' if r['adopt'] else '아니오'}"
              f" · 전송 {r['calls']}콜 {r['chars']}자"
              f" · 고정 불릿 누출={r['leak'] or '없음'}")
        if VERBOSE:
            for u in r["units"]:
                head = (u.splitlines() or [""])[0]
                print(f"          - {len(u):4}자  {head[:76]}")
    return rows


async def main():
    print("\n[2/4] 실측 — 픽스처 그대로 (마커 있음)")
    on = await arm("on ", en, ja, True)
    off = await arm("off", en, ja, False)

    print("\n[3/4] 대조군 — 마커 한 줄만 제거")
    con_on = await arm("on ", strip(en), strip(ja), True)

    print("\n[4/4] 판정")
    check(2, all(r["adopt"] for r in on.values()),
          "LIST_ITEMS=on 에서 _maybe_expand_lists 가 채택한다",
          "거절되면 목록 확장이 통째로 꺼진다")
    check(3, not any(r["leak"] for r in on.values()),
          "LIST_ITEMS=on 에서 고정 형제 불릿이 전송되지 않는다",
          "누출: " + str({l: r["leak"] for l, r in on.items() if r["leak"]}))
    ctl = (all(r["adopt"] for r in con_on.values())
           and not any(r["leak"] for r in con_on.values()))
    check(4, ctl, "대조군(마커 제거)에서는 (2)(3) 이 성립한다 — 원인 격리")
    check(5, any(r["leak"] for r in off.values()),
          "LIST_ITEMS=off 에서는 전송된다 (플래그가 실제로 일을 한다)")

    print()
    if not fail:
        print("RESULT: OK — 결함이 닫혔다. e2e-suite.sh 의 all 목록에 넣을 때다.")
        sys.exit(0)
    if set(fail) <= {2, 3} and ctl:
        print("RESULT: REPRO — 결함이 재현됐다 (파이프라인 미수정 상태의 기대값).")
        print("        마커 한 줄 때문에 LIST_ITEMS 가 이 파일에서 꺼진다.")
        print("        고칠 자리: cloud-translate `_maybe_expand_lists` 의 개수 엄격 일치 조건.")
        sys.exit(3)
    print(f"RESULT: BROKEN — 실패한 규칙 {sorted(fail)} (대조군까지 깨졌다면 픽스처 문제)")
    sys.exit(1)


asyncio.run(main())
PY
