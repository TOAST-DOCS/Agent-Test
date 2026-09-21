#!/usr/bin/env bash
#
# 미등록 용어 고정(term-pin) A/B — cloud-translate `app/term_table.py` ⓒ 경로.
#
# ── 무엇을 재나 ───────────────────────────────────────────────────────────
# 용어집에 **없는** 용어는 chunk 마다 즉흥이라 **한 문서 안에서도** 갈린다.
# 실증: `nhn-cloud-foundry` 의 `단변량 시계열 이상탐지` 가 alpha 의 네 문서
# 각각의 안에서 `time series` / `time-series` 로 갈렸다 (#375). 같은 축의 코퍼스
# 실측이 cloud-user-guide-agent#418 — 743건 · 50 리포.
#
# `term_pin` 은 구현돼 있으나 **기본 꺼짐**이다. 켜도 되는지는 한 번 돌려서
# 알 수 없다 — 모델 호출이 둘 다(제안 단계도, 번역도) 비결정적이라 한 판의
# 통과는 운일 수 있다. 그래서 이 e2e 는 **같은 픽스처를 두 팔로 N 판** 돌리고
# 판마다가 아니라 **분포**로 판정한다.
#
#   OFF  대조군 — 갈릴 수 있는 상황인지, 얼마나 자주 갈리는지
#   ON   판정   — 문서 안 갈림이 **모든 판에서 0** 이어야 한다
#
# 축이 둘인 것이 중요하다. term-pin 이 약속하는 것은 **문서 안** 일관성뿐이다:
#
#   (가) 문서 안 갈림   — 한 산출물 안에서 같은 ko 용어가 여러 역어를 갖는가.
#                        ON 의 계약. 0 이 아니면 켤 수 없다.
#   (나) 판 사이 흔들림 — 같은 입력을 다시 돌렸을 때 **다른 역어**로 고정하는가.
#                        term-pin 이 고치겠다고 한 적 없는 축이지만, 문서마다
#                        따로 고정하므로 **리포 전체 일관성**은 여기에 달렸다.
#                        ON 이 OFF 보다 나쁘면 한 결함을 다른 결함과 바꾼 것이다.
#
# ── 측정은 표의 칸으로 한다 ───────────────────────────────────────────────
# 픽스처의 절마다 같은 세 ko 용어를 첫 칸에 둔 표를 심는다. 표는 위치로 짝지어
# 지므로 (표#, 행, 열) 자리의 ko 셀 ↔ 역어 셀이 **정렬 모델 없이** 확정된다 —
# `scripts/check_term_divergence.py` 가 그 슬롯을 세고, 행이 밀린 표는 역방향
# 맵으로 걸러낸다 (#418 §6). 문구를 미리 박아 두고 grep 하는 방식은 모델이 어떤
# 말로 옮길지 모르기 때문에 "갈리지 않았다" 와 "못 찾았다" 를 구별하지 못한다.
#
# ── 픽스처가 커야 하는 이유, 그리고 크기는 **글자**로 잰다 ────────────────
# 갈림은 **chunk 경계**에서 생긴다. `_split_into_chunks` 의 `max_chars` 는
# 10,000 **자**이고, 그 아래면 문서 전체가 한 번의 모델 호출로 끝나 갈릴 자리가
# 아예 없다.
#
# 그래서 `wc -c` 로 재면 안 된다. 한글은 UTF-8 에서 3바이트라 14,546**바이트**
# 문서가 6,656**자** 다 — 옛 판본이 정확히 그것을 "10000 초과" 로 통과시켰고,
# 로그에는 `Translating chunk (6656 chars …)` 가 언어당 한 줄씩만 찍혔다.
# 대조군이 갈리지 않은 것은 term-pin 이 필요 없어서가 아니라 **한 번에 번역돼서**
# 였다. 지금은 python 으로 글자 수를 세고, 최소 두 chunk 가 되게 절 수를 잡는다.
#
# ── 픽스처에 기존 번역본이 없다 (의도) ────────────────────────────────────
# 새 파일이라 en/ja 가 없고, 그래서 `propose_terms` 는 "기존 표기를 따르라" 는
# 가장 강한 근거 없이 역어를 **지어낸다.** 운영에서 대부분의 파일은 번역본이
# 있어 그쪽이 더 쉬운 조건이므로, 이 측정은 **보수적**이다 — 여기서 (나) 가
# 흔들리면 운영에서는 그보다 덜 흔들린다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-term-pin.sh                    # 2판 × 2팔 = 번역 4회
#   bash scripts/e2e-term-pin.sh --rounds 3
#   bash scripts/e2e-term-pin.sh --rounds 1 --keep
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-term-pin.sh
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  ON 의 계약이 모든 판에서 성립 (`TERM_PIN: OK`) — 켜도 된다는 신호
#   1  ON 에서 문서 안 갈림이 나왔다 (`TERM_PIN: FAIL`) — 켜면 안 된다
#   2  인프라 (번역 실패 · 한도 소진 · 픽스처 조건 상실)
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
# 제안 단계만은 API 를 타므로 `TRANSLATE_ANTHROPIC_API_KEY` 가 필요하다
# (llm-patch judge 와 같다).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
# 브랜치 이름에 **슬래시를 쓰지 않는다.** translate_file.py 는 blob URL
# `…/blob/<ref>/<path>` 에서 첫 세그먼트를 ref 로 끊으므로, `e2e-termpin/<ts>` 는
# ref=`e2e-termpin` · path=`<ts>/ko/…` 로 잘려 404 가 난다 (다른 e2e 는 PR 을
# 쓰기 때문에 이 제약이 없다).
SESSION="e2e-termpin-$TS"
DOC="term-pin-sample.md"
# 측정 대상 — 세 개 모두 `_common_glossary.md`·`Agent-Test_glossary.md` 어디에도
# 없다 (실측 2026-09-21). 등재돼 있으면 ⓐ 확정 경로로 고정되므로 ⓒ 를 못 잰다.
T1="단변량 시계열 이상탐지"
T2="예측 오차 정상 범위"
T3="재학습 자동 조정"
TERMS="$T1,$T2,$T3"
CT_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
SCRATCH="$(mktemp -d)"
KEEP=0
ROUNDS=2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)   KEEP=1; shift ;;
    --rounds) ROUNDS="$2"; shift 2 ;;
    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIVERGE="$REPO_ROOT/scripts/check_term_divergence.py"
[ -f "$DIVERGE" ] || { echo "측정기 없음: $DIVERGE" >&2; exit 2; }

PY=""
for c in "$CT_DIR/.venv/bin/python" "$HOME/works/cloud-translate/.venv/bin/python" "$(command -v python3)"; do
  [ -x "$c" ] && PY="$c" && break
done
[ -n "$PY" ] || { echo "python 없음" >&2; exit 2; }

PASS=0; FAIL=0; INFRA=0
ok(){   echo "  PASS  $*"; PASS=$((PASS+1)); }
bad(){  echo "  FAIL  $*"; FAIL=$((FAIL+1)); }
info(){ echo "        $*"; }

cleanup() {
  [ "$KEEP" = "1" ] && { echo "브랜치 유지: $SESSION (+ 판별 브랜치)"; return; }
  git -C "$SCRATCH/repo" push -q origin ":$SESSION" >/dev/null 2>&1 || true
  for b in $(cat "$SCRATCH/branches" 2>/dev/null); do
    git -C "$SCRATCH/repo" push -q origin ":$b" >/dev/null 2>&1 || true
  done
  rm -rf "$SCRATCH"
}
trap cleanup EXIT

# ── 1. 픽스처 ─────────────────────────────────────────────────────────────
echo "=== 1단계 픽스처 ==="
WORK="$SCRATCH/repo"
git clone -q --depth 1 --branch "$BASE_SOURCE" "https://github.com/$REPO.git" "$WORK"
cd "$WORK"; git checkout -q -b "$SESSION"
: > "$SCRATCH/branches"

{
  echo "# 이상 탐지 앱 사용 가이드 { #tp-root }"
  echo
  echo "이 문서는 $T1 기능과 그 운영 방법을 설명합니다."
  echo
  echo '<a id="tp-terms"></a>'
  echo
  echo "## 용어"
  echo
  echo "| 항목 | 설명 |"
  echo "|---|---|"
  echo "| $T1 | 지표 하나의 과거 패턴을 학습해 이상 구간을 찾는 기능입니다. |"
  echo "| $T2 | 예측값과 실제값의 차이가 머무르는 폭입니다. |"
  echo "| $T3 | 오차가 커지면 학습 일정을 스스로 바꾸는 동작입니다. |"
  echo
  for i in $(seq 1 24); do
    echo "<a id=\"tp-$i\"></a>"
    echo
    echo "## $i. 앱 설정 $i"
    echo
    echo "$T1 앱을 만들려면 먼저 데이터 소스를 준비합니다. $T1 은 지표의 과거 패턴을 학습해 이상 구간을 찾습니다. 학습이 끝나면 $T2 가 계산되고, 그 폭을 벗어난 지점이 이상으로 기록됩니다."
    echo
    echo "1. 콘솔에서 **$T1** 탭으로 이동합니다. 이 탭에서 앱 목록을 확인할 수 있습니다."
    echo "2. 학습 주기와 추론 주기를 지정합니다. 주기가 짧을수록 반응이 빨라지지만 비용이 늘어납니다."
    echo "3. $T2 를 설정합니다. 폭이 좁을수록 더 많은 지점이 이상으로 기록됩니다."
    echo "4. $T3 을 켜면 오차가 커질 때 학습이 다시 실행됩니다."
    echo
    echo "| 항목 | 설정 $i 에서의 의미 |"
    echo "|---|---|"
    echo "| $T1 | 이 절에서는 지표 $i 개를 한 번에 다루는 방법을 설명합니다. |"
    echo "| $T2 | 설정 $i 에서는 기본 폭을 $i 배로 넓혀 두었습니다. |"
    echo "| $T3 | 설정 $i 에서는 오차가 $i 회 연속 커질 때 동작합니다. |"
    echo
    echo "> 참고: $T1 앱은 프로젝트당 최대 10개까지 만들 수 있습니다. $T3 을 켠 앱은 이 수에 포함됩니다."
    echo
  done
} > "ko/$DOC"

CHARS=$("$PY" -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()))" "ko/$DOC")
echo "  ko/$DOC — ${CHARS}자 · 표 25개 · 측정 용어 3개"
if [ "$CHARS" -gt 10000 ]; then
  ok "픽스처가 chunk 경계를 넘는다 (${CHARS}자 > 10000자)"
else
  bad "픽스처가 너무 작다 (${CHARS}자) — 한 번에 번역돼 갈릴 자리가 없다"; INFRA=1
fi
git add "ko/$DOC"
git -c user.email=e2e@local -c user.name=e2e commit -q -m "e2e(term-pin): 픽스처"
git push -q origin "$SESSION"

BLOB="https://github.com/$REPO/blob/$SESSION/ko/$DOC"

# ── 2. 한 판 ──────────────────────────────────────────────────────────────
run_one() {   # $1=on|off  $2=round  → stdout 없음, 파일로 남긴다
  local pin="$1" round="$2"
  local br="e2e-termpin-$pin-$round-$TS" log="$SCRATCH/$pin-$round.log"
  echo "$br" >> "$SCRATCH/branches"
  git push -q origin "$SESSION:$br"
  local t0=$SECONDS
  ( cd "$CT_DIR" && \
    TRANSLATE_TERM_PIN="$pin" \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    TRANSLATE_LOG_LEVEL=info \
    "$PY" translate/translate_file.py "$BLOB" --commit-to-branch "$br" \
  ) > "$log" 2>&1 || {
    if grep -qi "usage limit\|사용량 한도\|HTTP 429" "$log"; then
      echo "  한도 소진 (429) — 리셋 후 CLI 로 다시 돌린다 (api 로 우회하지 않는다)"
      INFRA=2
    fi
    bad "번역 실패 (term_pin=$pin, round=$round)"; tail -12 "$log"; return 1
  }
  local nchunk
  nchunk="$(grep -c 'Translating chunk' "$log" || true)"
  echo "  round $round · term_pin=$pin · $((SECONDS - t0))초 · 모델 호출 ${nchunk}회" \
    >> "$SCRATCH/timing"
  [ "${nchunk:-0}" -ge 4 ] || bad "모델 호출이 ${nchunk}회뿐 — 언어당 chunk 가 하나면 갈릴 자리가 없다"
  if [ "$pin" = on ]; then
    local pinline
    pinline="$(grep -o 'term-pin .*제안 [0-9]* → 채택 [0-9]* (기각 [0-9]*)' "$log" | head -2 | tr '\n' ' ')"
    if [ -n "$pinline" ]; then
      info "고정 단계: $pinline"
    else
      bad "고정 단계 로그가 없다 — TRANSLATE_ANTHROPIC_API_KEY 확인"
      grep -i "term-pin" "$log" | head -3
    fi
  fi
  # 산출물을 받아 둔다. **`origin/<br>` 이 아니라 `FETCH_HEAD` 로 읽는다** —
  # 이 클론은 `--depth 1 --branch alpha` 라 refspec 이
  # `+refs/heads/alpha:refs/remotes/origin/alpha` 하나뿐이고, `git fetch origin
  # <br>` 는 원격 추적 ref 를 만들지 않는다. 옛 판본이 `origin/<br>` 를 읽고
  # 실패를 `2>/dev/null` 로 삼켜 "(브랜치 없음)" 한 줄만 남기는 바람에, 측정이
  # 한 번도 산출물을 보지 못한 채 초록이었다.
  git fetch -q origin "$br"
  local d="$SCRATCH/out/$pin-$round"; mkdir -p "$d"
  git show "FETCH_HEAD:ko/$DOC" > "$d/ko.md" 2>/dev/null || true
  for lang in en ja; do
    if ! git show "FETCH_HEAD:$lang/$DOC" > "$d/$lang.md" 2>/dev/null; then
      bad "$lang 산출물이 없다 (term_pin=$pin, round=$round)"
      rm -f "$d/$lang.md"; return 1
    fi
  done
  return 0
}

echo
for r in $(seq 1 "$ROUNDS"); do
  echo "=== 2단계 번역 · round $r/$ROUNDS ==="
  for arm in off on; do
    echo "  --- term_pin=$arm ---"
    run_one "$arm" "$r" || true
  done
done

# ── 3. 판정 ───────────────────────────────────────────────────────────────
echo
echo "=== 3단계 판정 ==="
TERMS="$TERMS" ROUNDS="$ROUNDS" OUT="$SCRATCH/out" DIVERGE="$DIVERGE" \
  "$PY" - <<'PY' > "$SCRATCH/verdict.txt" 2>&1 || true
import collections, importlib.util, json, os, pathlib, sys

spec = importlib.util.spec_from_file_location("ctd", os.environ["DIVERGE"])
ctd = importlib.util.module_from_spec(spec); spec.loader.exec_module(ctd)

terms = os.environ["TERMS"].split(",")
rounds = int(os.environ["ROUNDS"])
out = pathlib.Path(os.environ["OUT"])

# arm -> lang -> term -> [ (round, forms dict) ]
data = collections.defaultdict(lambda: collections.defaultdict(
    lambda: collections.defaultdict(list)))
missing = []
for arm in ("off", "on"):
    for r in range(1, rounds + 1):
        d = out / f"{arm}-{r}"
        if not (d / "ko.md").exists():
            missing.append(f"{arm}-{r}")
            continue
        ko = (d / "ko.md").read_text(encoding="utf-8", errors="replace")
        for lang in ("en", "ja"):
            f = d / f"{lang}.md"
            if not f.exists():
                missing.append(f"{arm}-{r}/{lang}")
                continue
            res = ctd.divergence(ko, f.read_text(encoding="utf-8", errors="replace"), terms)
            for t in terms:
                info = res["terms"].get(t)
                data[arm][lang][t].append((r, info, res["notes"]))

print("## 판마다의 역어 (표 슬롯)")
for arm in ("off", "on"):
    for lang in ("en", "ja"):
        for t in terms:
            for r, info, notes in data[arm][lang][t]:
                if info is None:
                    print(f"  {arm:3} r{r} {lang} {t}: (슬롯 없음 — 표가 어긋났다 {notes[:2]})")
                    continue
                forms = " / ".join(f'"{k}"x{v}' for k, v in info["forms"].items())
                flag = "갈림" if info["diverged"] else "고정"
                gap = f" · 산문차 {info['prose_gap']}" if info["prose_gap"] else ""
                print(f"  {arm:3} r{r} {lang} [{flag}] {t} -> {forms}{gap}")

summary = {}
for arm in ("off", "on"):
    diverged = stable_break = measured = 0
    for lang in ("en", "ja"):
        for t in terms:
            majors = set()
            for r, info, _ in data[arm][lang][t]:
                if info is None:
                    continue
                measured += 1
                if info["diverged"]:
                    diverged += 1
                majors.add(info["major"])
            if len(majors) > 1:
                stable_break += 1
    summary[arm] = dict(measured=measured, diverged=diverged,
                        cross_run_unstable=stable_break)

print()
print("## 집계")
print(f"  {'팔':4} {'측정':>4} {'문서안 갈림':>10} {'판 사이 흔들림(용어×언어)':>24}")
for arm in ("off", "on"):
    s = summary[arm]
    print(f"  {arm:4} {s['measured']:>4} {s['diverged']:>10} {s['cross_run_unstable']:>24}")
print()
print("VERDICT_JSON " + json.dumps({"summary": summary, "missing": missing},
                                   ensure_ascii=False))
PY
cat "$SCRATCH/verdict.txt"

VJ="$(grep '^VERDICT_JSON ' "$SCRATCH/verdict.txt" | head -1 | cut -d' ' -f2-)"
if [ -z "$VJ" ]; then
  bad "판정기가 결과를 내지 못했다"; INFRA=2
else
  ON_DIV="$(echo "$VJ"   | "$PY" -c 'import json,sys;print(json.load(sys.stdin)["summary"]["on"]["diverged"])')"
  OFF_DIV="$(echo "$VJ"  | "$PY" -c 'import json,sys;print(json.load(sys.stdin)["summary"]["off"]["diverged"])')"
  ON_MEAS="$(echo "$VJ"  | "$PY" -c 'import json,sys;print(json.load(sys.stdin)["summary"]["on"]["measured"])')"
  ON_UNS="$(echo "$VJ"   | "$PY" -c 'import json,sys;print(json.load(sys.stdin)["summary"]["on"]["cross_run_unstable"])')"
  OFF_UNS="$(echo "$VJ"  | "$PY" -c 'import json,sys;print(json.load(sys.stdin)["summary"]["off"]["cross_run_unstable"])')"
  if [ "$ON_MEAS" = "0" ]; then
    bad "ON 에서 측정된 슬롯이 없다 — 픽스처나 산출물이 깨졌다"; INFRA=2
  elif [ "$ON_DIV" = "0" ]; then
    ok "(가) ON: 문서 안 갈림 0 (측정 $ON_MEAS · 대조군 $OFF_DIV)"
  else
    bad "(가) ON: 문서 안 갈림 $ON_DIV 건 — 계약 위반이므로 켜면 안 된다"
  fi
  if [ "$ON_UNS" -le "$OFF_UNS" ] 2>/dev/null; then
    ok "(나) ON 의 판 사이 흔들림이 대조군 이하 ($ON_UNS ≤ $OFF_UNS)"
  else
    bad "(나) ON 이 판마다 다른 역어로 고정한다 ($ON_UNS > $OFF_UNS) — 리포 전체 일관성은 나빠진다"
  fi
fi

echo
[ -f "$SCRATCH/timing" ] && { echo "=== 소요 ==="; cat "$SCRATCH/timing"; }
echo
echo "결과: PASS=$PASS FAIL=$FAIL"
if [ "$INFRA" != "0" ]; then echo "TERM_PIN: INFRA"; exit 2; fi
if [ "$FAIL" = "0" ]; then echo "TERM_PIN: OK"; exit 0; fi
echo "TERM_PIN: FAIL"; exit 1
