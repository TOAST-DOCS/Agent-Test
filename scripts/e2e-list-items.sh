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
# ── 닫혔다 (cloud-translate, 2026-09-21) ──────────────────────────────────
# `_maybe_expand_lists` 가 **마커 한 줄만큼의 오프셋**을 허용한다 — 개수도
# landmark 열도 그 한 줄을 뺀 채로 비교하고, 그 경로에서만 `_structural_alignment`
# 가 받아 주는지 한 번 더 확인한다. 코퍼스 채택 1,728 → 1,858 / 2,702
# (64.0% → 68.8%), 재사용을 잃은 쌍 0. 그래서 이 e2e 의 기대값은 **exit 0** 이다.
# 아래 서사는 무엇이 닫혔는지 남겨 둔 것이다.
#
# ── 무엇이 걸려 있었나 ────────────────────────────────────────────────────
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
#   3) **운영 경로** — `translate_diff` (anchor splice 포함) 를 probe 번역기로
#      돌려 전송분을 수집. 플래그 on/off × 마커 유/무 = 2×2
#   4) **폴백 경로** — `_section_diff_splice` 를 문서 통째로 직접. 같은 2×2
#   5) 판정 (아래 7개)
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) 픽스처가 조건을 유지하고 있다 — en/ja 첫 줄이 마커, ko 첫 줄은 아니다
#   (2) **폴백 경로**에서 `_maybe_expand_lists` 가 **채택**한다       <- 목록 단위 채택
#   (3) **운영 경로**·on 에서 고정 형제 불릿이 **전송되지 않는다**    <- 본체
#   (4) 대조군(마커 제거)에서는 (2)(3) 이 성립한다 — 원인 격리
#   (5) off 에서는 **두 경로 모두** 전송된다 (플래그가 실제로 일을 하는지)
#   (6) 운영 경로는 **편집한 유닛 하나만** 전송한다 (마커 유무 무관)
#   (7) 폴백 경로의 **잔여**(편집 외 유닛 전송)가 예산을 넘지 않는다
#
# **(2)(3) 이 다시 FAIL 이면 회귀다.** 마커 오프셋 허용이 사라졌거나, 판정이
# `_maybe_expand_lists` 가 아닌 사본을 보고 있다는 뜻이다 — 실제로 이 스크립트가
# 한 번 그랬다: 규칙을 `k == t` 로 베껴 적어 두어, 파이프라인이 고쳐지고 전송량이
# 줄어든 뒤에도 "거절" 이라고 계속 답했다. 판정은 반드시 그 함수에게 묻는다.
#
# ── 경로가 둘이고, 둘을 섞으면 안 된다 ────────────────────────────────────
# 이 스크립트는 처음에 `_section_diff_splice` 를 **문서 통째로** 직접 불렀다.
# 그런데 번역 잡은 `translate_diff` 로 들어가고, 거기서 **anchor splice**
# (`_splice_by_anchors`) 가 먼저 돌아 `_section_diff_splice` 를 anchor 섹션
# **안에서** 다시 부른다 (`--align-headings` 가 권장 프리셋에 있으므로 anchor
# splice 는 늘 먼저 시도된다). 그래서 두 경로의 전송량이 다르다 — 실측
# 2026-09-21, `_marker_offset` 수정 후:
#
#                 마커  플래그  en 전송        ja 전송
#   운영 경로     있음  on      1콜   36자     1콜   36자   <- 편집한 불릿 하나
#   (translate_   있음  off     1콜  229자     1콜  229자   <- 목록 블록 통째
#    diff)        없음  on/off  같음           같음         <- 마커 무관
#   폴백 경로     있음  on      5콜  696자     3콜  353자
#   (_section_    있음  off     5콜  889자     3콜  546자
#    diff_splice) 없음  on      1콜   36자     1콜   36자
#
# 운영 경로가 정본이고, 그 값이 배포 실측과 맞는다 — 같은 픽스처의 Jenkins
# 로그가 `Section-diff (block): re-translated 1 of 14 units` 다. 플래그의 효과는
# 두 경로에서 모두 확인된다 (229->36 · 889->696 · 546->353, 고정 불릿 누출 2->0).
#
# **폴백 경로에는 잔여가 있다** — 편집과 무관한 산문 문단까지 전송된다 (en 4개
# 660자 · ja 2개 317자). 원인은 플래그가 아니라 그 경로의 정렬이다: 마커 한 줄
# 때문에 유닛 개수가 21:22 로 어긋나 위치 짝짓기 대신 `_structural_alignment` 로
# 떨어지고, 그 시그니처가 `volume_aware` 에서 **content 줄 수**를 포함하므로
# ko 3줄 ↔ en 4줄처럼 **줄바꿈만 다른** 문단이 `replace`(=donor) 로 분류돼
# 재번역된다. 마커를 지우면 21:21 이라 그 검사를 아예 지나지 않아 잔여가 0 이다.
#
# 즉 목록 단위 채택이 사는 곳은 폴백 경로다 — 그 경로의 정렬 자체는 여전히
# structural fallback 이므로 잔여가 남는다. (7) 의 **예산**으로 현 상태를 못 박는다
# — 줄어들면 예산을 내리고, 늘어나면 FAIL 이다.
#
# (이 픽스처의 목록은 부분 수가 양쪽 같아(d=0) 개수 델타 제약을 통과하므로 tier 2
# 에서 채택된다. 문서 전체가 항목 단위로 정렬된 문서라면 tier 1 이 먼저 잡아
# 전부 펼치고 위치 짝짓기를 쓴다 — 그쪽이 잔여 0 이다.)
#
# **코퍼스 수치를 읽을 때 주의** — 목록 확장의 채택 판정은 `_section_diff_splice`
# 에 들어온 시퀀스 안에서만 이뤄지므로, 파일쌍 단위로 부른 코퍼스 측정은 **폴백
# 경로의 모집단**이다. anchor splice 가 정렬을 찾는 문서는 anchor 섹션 안에서 다시
# 쪼개지므로 문서 선두의 마커가 그 비교에 들어오지 않는다. 즉 코퍼스에서 채택이
# 63.6% -> 95.1% 로 올랐다는 것이 곧 "운영 번역이 그만큼 좋아진다" 는 아니다.
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  (1)~(7) 전부 통과 — **현행 기대값**
#   3  결함이 재현됐다 — (2)(3) 만 실패하고 대조군 (4) 는 통과 (수정 전 기대값)
#   1  스크립트/환경 오류, 또는 대조군까지 실패 (픽스처가 깨졌다는 뜻),
#      또는 폴백 경로 잔여 예산 초과 (7)
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
    -h|--help) sed -n '2,134p' "$0"; exit 0 ;;
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
                            _expand_table_blocks, _maybe_expand_lists,
                            _split_paragraphs, _split_paragraphs_raw)
from shared.config import settings
from shared.github_client import pre_align_marker
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
print("[1/5] 픽스처 조건")
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


def counts(ko_text, tgt_text, list_items):
    """유닛 수와 **실제 채택 여부**.

    채택 규칙을 여기에 베껴 적지 않는다 — 옛 판본이 `k == t` 로 베껴 적고 있었고,
    파이프라인이 마커 오프셋을 허용하도록 고쳐진 뒤에도 이 e2e 만 옛 규칙으로
    "거절" 이라고 계속 답했다 (전송량은 이미 줄어 있었는데도). 규칙은 한 군데,
    `_maybe_expand_lists` 에만 있어야 한다.
    """
    ko_u = _expand_table_blocks(_split_paragraphs(ko_text))
    tgt_u = _expand_table_blocks(_split_paragraphs_raw(tgt_text), raw=True)
    # 플래그는 호출자(`_section_diff_splice`)가 본다 — 끈 팔에서 함수만 부르면
    # "채택" 이라고 답해 표가 거짓말을 한다.
    adopted = list_items and _maybe_expand_lists(
        ko_u, ko_u, tgt_u, ko_u, volume_aware=True)[4]
    k = _expand_list_blocks(ko_u)
    t = _expand_list_blocks(tgt_u, raw=True)
    return len(k), len(t), adopted


def _apply_settings(list_items):
    """운영 recommended 프리셋의 관련 스위치 — 두 경로가 같은 값을 본다."""
    settings.diff_list_items = list_items
    settings.diff_table_rows = True
    settings.diff_granularity = "block"
    settings.diff_align_headings = True
    settings.diff_mode = "incremental"


async def sent_units_fallback(existing, lang, list_items):
    """**폴백 경로** — `_section_diff_splice` 를 문서 통째로 직접 부른다.

    운영에서 여기에 도달하는 것은 anchor splice 가 정렬을 찾지 못한 문서다
    (`--align-headings` 가 권장 프리셋에 있으므로 anchor splice 는 늘 먼저
    시도된다). `_maybe_expand_lists` 가 **문서 전체**의 유닛 수를 비교하는
    자리이므로, `_marker_offset` 이 실제로 무는 곳도 여기다.
    """
    _apply_settings(list_items)
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


class _Probe(Translator):
    """진짜 Translator — 모델 호출 한 겹만 가로챈다.

    `check_unit_baselines.py` 의 `_Probe` 와 같은 이유로 있다: 운영은
    `translate_diff` 로 들어가고, 거기서 **anchor splice**(`_splice_by_anchors`)
    가 먼저 돌아 `_section_diff_splice` 를 anchor 섹션 **안에서** 다시 부른다.
    `_section_diff_splice` 만 직접 부르면 운영과 다른 짝·다른 전송량을 보게 된다
    (실측: 이 픽스처에서 폴백 경로는 en 5콜 696자, 운영 경로는 1콜 36자).
    """

    def __init__(self):
        super().__init__(glossary=None)
        self.recs = []

    async def translate(self, content, reference=None, target_lang="en",
                        target_dir="en", *a, **k):
        self.recs.append(content)
        return content

    async def _translate_chunk_uncached(self, content, *a, **k):
        return content

    async def _verify_chunk_uncached(self, *a, **k):
        return ""


async def sent_units_real(existing, lang, list_items):
    """**운영 경로** — 번역 잡이 실제로 지나는 `translate_diff`.

    워커와 같은 판단 (`worker._translate_one`): ko 와 대상의 pre-align 마커가
    같으면 `prealigned`, 그리고 anchor splice 가 도는 경우에는 변경 판정의
    기준이 되는 base ko 를 `content_baseline_ko` 로 함께 넘긴다 — 안 넘기면
    anchor 가 맞는 섹션이 전부 "안 바뀜" 으로 읽혀 한 유닛도 재번역되지 않는다.
    """
    _apply_settings(list_items)
    probe = _Probe()
    sig = pre_align_marker(ko_head)
    prealigned = bool(sig) and sig == pre_align_marker(existing)
    use_anchor = prealigned or bool(settings.diff_align_headings)
    await probe.translate_diff(
        existing, ko_head, ko, None, lang, lang,
        prealigned=prealigned,
        content_baseline_ko=ko if use_anchor else None,
    )
    return probe.recs


def leaked(units):
    return sorted({p for p in PINNED for u in units if p in u})


# 편집한 유닛 외에 전송된 것 = 잔여. 헤더의 (6)(7) 설명 참고 — 원인은 플래그가
# 아니라 마커 한 줄이 강제하는 structural fallback 이다.
def residual(units):
    return [u for u in units if EDIT_TO not in u]


# 마커 arm 의 잔여 예산 (실측 2026-09-21, `_marker_offset` 수정 후). 줄어들면
# 이 값을 내리고, **늘어나면 FAIL** — 정렬 경로가 더 나빠졌다는 뜻이다.
RESIDUAL_BUDGET = {"en": (4, 660), "ja": (2, 317)}


async def arm(tag, en_t, ja_t, list_items, collect=None):
    collect = collect or sent_units_real
    rows = {}
    for lang, tgt in (("en", en_t), ("ja", ja_t)):
        k, t, adopt = counts(ko, tgt, list_items)
        units = await collect(tgt, lang, list_items)
        res = residual(units)
        rows[lang] = dict(ko_units=k, tgt_units=t, adopt=adopt,
                          calls=len(units), chars=sum(len(u) for u in units),
                          leak=leaked(units), units=units,
                          res_units=len(res), res_chars=sum(len(u) for u in res))
    for lang, r in rows.items():
        print(f"      {tag} {lang}: 유닛 ko={r['ko_units']} 대상={r['tgt_units']}"
              f" -> 채택={'예' if r['adopt'] else '아니오'}"
              f" · 전송 {r['calls']}콜 {r['chars']}자"
              f" · 편집 외 잔여 {r['res_units']}개 {r['res_chars']}자"
              f" · 고정 불릿 누출={r['leak'] or '없음'}")
        if VERBOSE:
            for u in r["units"]:
                head = (u.splitlines() or [""])[0]
                tick = "EDIT" if EDIT_TO in u else "res "
                print(f"          - {tick} {len(u):4}자  {head[:70]}")
    return rows


async def main():
    print("\n[2/5] 운영 경로 (translate_diff → anchor splice) — 2×2 (마커 × 플래그)")
    on = await arm("on ", en, ja, True)
    off = await arm("off", en, ja, False)

    print("\n[3/5] 운영 경로 · 대조군 — 마커 한 줄만 제거")
    con_on = await arm("on ", strip(en), strip(ja), True)
    con_off = await arm("off", strip(en), strip(ja), False)

    print("\n[4/5] 폴백 경로 (_section_diff_splice 직접) — anchor 정렬 실패 시 도달")
    fb_on = await arm("on ", en, ja, True, sent_units_fallback)
    fb_off = await arm("off", en, ja, False, sent_units_fallback)
    fb_con_on = await arm("on ", strip(en), strip(ja), True, sent_units_fallback)

    print("\n[5/5] 판정")
    # (2) 는 **폴백 경로**의 규칙이다 — `_maybe_expand_lists` 가 문서 전체의 유닛
    #     수를 비교하는 곳이 거기고, 마커 오프셋이 무는 곳도 거기다. 운영 경로는
    #     anchor 섹션 안에서 다시 쪼개므로 마커가 애초에 같은 비교에 안 들어온다.
    check(2, all(r["adopt"] for r in fb_on.values()),
          "폴백 경로에서 _maybe_expand_lists 가 채택한다 (목록 단위)",
          "거절되면 그 문서의 목록 확장이 통째로 꺼진다")
    check(3, not any(r["leak"] for r in on.values()),
          "운영 경로 · LIST_ITEMS=on 에서 고정 형제 불릿이 전송되지 않는다",
          "누출: " + str({l: r["leak"] for l, r in on.items() if r["leak"]}))
    ctl = (all(r["adopt"] for r in fb_con_on.values())
           and not any(r["leak"] for r in con_on.values()))
    check(4, ctl, "대조군(마커 제거)에서는 (2)(3) 이 성립한다 — 원인 격리")
    check(5, any(r["leak"] for r in off.values())
             and any(r["leak"] for r in fb_off.values()),
          "LIST_ITEMS=off 에서는 두 경로 모두 전송된다 (플래그가 실제로 일을 한다)",
          "off 누출: " + str({l: r["leak"] for l, r in off.items() if r["leak"]}))

    # (6) 운영 경로의 약속 그 자체 — **편집한 유닛 하나만** 나간다. 마커가 있든
    #     없든 같아야 한다 (anchor splice 가 마커 어긋남을 흡수하므로).
    floor = {"마커": on, "대조군": con_on}
    floor_ok = all(r["res_units"] == 0 and r["calls"] == 1
                   for rows in floor.values() for r in rows.values())
    check(6, floor_ok,
          "운영 경로는 편집한 유닛 하나만 전송한다 (마커 유무 무관, 잔여 0)",
          " · ".join(f"{tag} {l}: on {r['calls']}콜 {r['chars']}자"
                     for tag, rows in floor.items() for l, r in rows.items()))

    # (7) 폴백 경로의 **잔여 예산**. 마커가 있으면 유닛 수가 21:22 로 어긋나
    #     위치 짝짓기 대신 `_structural_alignment` 로 떨어지고, 그 시그니처가
    #     content 줄 수를 포함하므로 줄바꿈만 다른 산문 문단이 donor 로 분류돼
    #     재번역된다. 플래그와 독립이라(off arm 도 같은 유닛을 보낸다) 여기서는
    #     현 상태를 못 박고 **악화만** 잡는다.
    over = []
    for lang, r in fb_on.items():
        mu, mc = RESIDUAL_BUDGET[lang]
        if r["res_units"] > mu or r["res_chars"] > mc:
            over.append(f"{lang} {r['res_units']}개 {r['res_chars']}자 > 예산 {mu}개 {mc}자")
    check(7, not over,
          "폴백 경로의 잔여가 예산 이내 (그 경로 정렬이 더 나빠지지 않았다)",
          "; ".join(over) if over
          else " · ".join(f"{l}: 잔여 {r['res_units']}개 {r['res_chars']}자"
                          f" (마커 제거 시 {fb_con_on[l]['res_units']}개"
                          f" {fb_con_on[l]['res_chars']}자)"
                          for l, r in fb_on.items()))

    print()
    if not fail:
        print("RESULT: OK — 목록이 항목 단위로 splice 된다.")
        print("        운영 경로 전송: "
              + " · ".join(f"{l} on {r['calls']}콜 {r['chars']}자"
                           f" / off {off[l]['calls']}콜 {off[l]['chars']}자"
                           for l, r in on.items()))
        print("        폴백 경로 잔여: "
              + " · ".join(f"{l} {r['res_units']}개 {r['res_chars']}자"
                           for l, r in fb_on.items())
              + "  <- 마커 제거 시 0. 헤더 (6)(7) 참고.")
        sys.exit(0)
    if set(fail) <= {2, 3} and ctl:
        print("RESULT: REPRO — 마커 오프셋 허용이 회귀했다.")
        print("        마커 한 줄 때문에 LIST_ITEMS 가 이 파일에서 꺼진다.")
        print("        볼 자리: cloud-translate `_maybe_expand_lists` 의 `_marker_offset`.")
        sys.exit(3)
    print(f"RESULT: BROKEN — 실패한 규칙 {sorted(fail)} (대조군까지 깨졌다면 픽스처 문제)")
    sys.exit(1)


asyncio.run(main())
PY
