#!/usr/bin/env bash
#
# term-pin — **증분(splice) 경로**. 운영에서 번역이 실제로 도는 자리다.
#
# ── 왜 따로 있나 ──────────────────────────────────────────────────────────
# `e2e-term-pin.sh` 와 `e2e-term-pin-existing.sh` 는 둘 다 **전문 재번역**
# (`translate_file.py`) 이다. 그 경로는 하루에 몇 번 돌지 않는다 — webhook 이
# 부르는 번역은 거의 전부 **ko PR 의 변경분만** 번역하는 splice 다. 그리고
# cloud-user-guide-agent#417 (TOAST-DOCS/Network-Load-Balancer#141) 이
# **미해결**로 남은 이유가 바로 splice 의 모양이다:
#
#   ko 가 안내 상자 하나를 **순수 삽입**(+3/-0) → `baseline_by_j[j] = None`
#   → 그 유닛에는 붙여 줄 기존 번역이 없다 → 모델이 즉흥으로 제목을 고른다
#   → 문서는 `ポイント` 를 12번 쓰는데 새 상자만 `ヒント` 가 된다.
#
# `--unit-preserve` 도 `--list-items` 도 이 자리를 못 본다 (붙일 짝이 아예 없다).
# **기존 번역본 전체를 읽고 표기를 정하는 장치는 term-pin 뿐이다.** 그래서
# "term-pin 을 켜도 되는가" 의 답은 이 스크립트가 낸다.
#
# ── 축이 둘이다: 이득과 무해 ──────────────────────────────────────────────
#   (가) 이득 — **삽입된** 상자의 제목이 이 문서가 이미 쓰는 말인가.
#               ON 의 계약. 모든 판에서 성립해야 한다.
#   (나) 무해 — ko 가 건드리지 않은 유닛이 **바이트 그대로** 남는가.
#               term-pin 은 프롬프트를 바꾸므로, 켜서 splice 가 더 많은 줄을
#               다시 쓰면 한 결함을 다른 결함과 바꾼 것이다. 대조군(OFF)과
#               **변경 줄 수**를 비교한다.
#
# (나) 가 없으면 (가) 는 의미가 없다 — 문서를 통째로 다시 써서 제목을 맞추는
# 것은 이 파이프라인이 하지 않기로 한 일이다.
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# 세션 브랜치에 만든다 (alpha 상주 아님 — 다른 정비 e2e 가 조용히 고쳐 버린다).
#
#   ko/en/ja term-pin-splice.md — 절 16개, 절마다 `!!! tip "알아두기"` 상자.
#       en/ja 는 **완전히 정렬된** 기존 번역본이고 상자 제목은 문서 관례로
#       고정돼 있다 (`Good to know` / `ポイント`). NLB 와 같은 조건 —
#       `Agent-Test_glossary.md` 에 `알아두기` 가 없다 (실측 2026-09-21).
#   두 번째 커밋(팔마다) — ko 에 **절 17 을 통째로 삽입**하고(순수 삽입),
#       절 5 의 문장 하나를 고친다(변경 유닛도 하나 있어야 splice 가 실제로
#       돌고, "안 건드린 줄" 의 대조가 생긴다).
#
# splice 는 `translate_file.py --diff` 로 돈다 — `app/baseline.py` 가 번역본을
# 만든 마지막 커밋(=첫 커밋)의 ko 를 old_ko 로 되찾아 그 자리에서 splice 한다.
# 실제 PR 경로와 같은 `_translate_modified` 를 탄다. splice 가 정렬에 실패해
# 전문 재번역으로 떨어지면 `preserve_existing` 이 기본 ON 이라 모델이 기존
# 번역본을 보게 되고, 그러면 두 팔의 차이가 term-pin 의 몫이 아니게 된다 —
# 그래서 로그에서 `Diff-based translation` 을 확인하고 없으면 INFRA 로 끊는다.
#
# Usage:
#   bash scripts/e2e-term-pin-splice.sh [--rounds N] [--arms off,on] [--keep]
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-term-pin-splice.sh
#
# exit: 0 ON 이 (가)(나) 를 모든 판에서 지켰다 / 1 못 지켰다 / 2 인프라
# e2e 는 **CLI 엔진으로 돈다**. 고정 단계만 API 를 탄다 (llm-patch judge 와 같다).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e-termpinsp-$TS"      # 슬래시 금지 — translate_file.py 의 blob URL 파싱
DOC="term-pin-splice.md"
TERM="알아두기"
JA_CONV="ポイント"
EN_CONV="Good to know"
SECTIONS=16
CT_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
SCRATCH="$(mktemp -d)"
KEEP=0
ROUNDS=1
ARMS="off,on"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)   KEEP=1; shift ;;
    --rounds) ROUNDS="$2"; shift 2 ;;
    --arms)   ARMS="$2"; shift 2 ;;
    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done

PY=""
for c in "$CT_DIR/.venv/bin/python" "$HOME/works/cloud-translate/.venv/bin/python" "$(command -v python3)"; do
  [ -x "$c" ] && PY="$c" && break
done
[ -n "$PY" ] || { echo "python 없음" >&2; exit 2; }
[ -f "$CT_DIR/.env" ] || { echo "error: $CT_DIR/.env 없음" >&2; exit 2; }

PASS=0; FAIL=0; INFRA=0
ok(){   echo "  PASS  $*"; PASS=$((PASS+1)); }
bad(){  echo "  FAIL  $*"; FAIL=$((FAIL+1)); }
info(){ echo "        $*"; }

cleanup() {
  [ "$KEEP" = "1" ] && { echo "브랜치 유지: $SESSION (+ 팔 브랜치)"; return; }
  for b in "$SESSION" $(cat "$SCRATCH/branches" 2>/dev/null); do
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

ko_section() {   # $1=번호  $2=본문 변형 (빈 문자열이면 기본)
  local i="$1" extra="${2:-}"
  echo "<a id=\"tps-$i\"></a>"
  echo
  echo "## $i. 리스너 설정 $i"
  echo
  echo "리스너 $i 은 클라이언트의 연결을 받아 대상 그룹으로 전달합니다.${extra} 프로토콜과 포트를 지정하고, 필요하면 인증서를 연결합니다. 상태 검사에 연속으로 실패한 대상은 자동으로 제외되고, 다시 정상이 되면 복귀합니다."
  echo
  echo "!!! tip \"$TERM\""
  echo
  echo "    한 연결에서 동시에 처리할 수 있는 요청은 최대 100개이며, 이 값은 변경할 수 없습니다. 이를 초과하는 요청은 클라이언트 측에서 대기 후 처리되므로 오류는 발생하지 않습니다."
  echo
  echo "| 항목 | 설정 $i |"
  echo "|---|---|"
  echo "| 프로토콜 | 리스너 $i 이 받는 프로토콜입니다. |"
  echo "| 상태 검사 주기 | 대상의 상태를 확인하는 간격입니다. |"
  echo
}

gen_ko() {   # $1=출력 경로  $2=절 수  $3=절5 변형
  {
    echo "# 리스너 가이드 { #tps-root }"
    echo
    echo "이 문서는 로드 밸런서의 리스너 동작을 설명하고, 절마다 $TERM 상자로 주의할 점을 덧붙입니다."
    echo
    for i in $(seq 1 "$2"); do
      if [ "$i" = 5 ]; then ko_section "$i" "$3"; else ko_section "$i" ""; fi
    done
  } > "$1"
}

gen_target() {   # $1=lang $2=상자 제목
  local lang="$1" conv="$2"
  {
    echo "<!-- machine_translated: true -->"
    echo
    if [ "$lang" = ja ]; then
      echo "# リスナーガイド { #tps-root }"
      echo
      echo "この文書はロードバランサーのリスナー動作を説明し、節ごとに$conv枠で注意点を補足します。"
    else
      echo "# Listener guide { #tps-root }"
      echo
      echo "This document explains how load balancer listeners work and adds a $conv box in each section."
    fi
    echo
    for i in $(seq 1 "$SECTIONS"); do
      echo "<a id=\"tps-$i\"></a>"
      echo
      if [ "$lang" = ja ]; then
        echo "## $i. リスナー設定 $i"
        echo
        echo "リスナー$i はクライアントの接続を受け取り、ターゲットグループに転送します。プロトコルとポートを指定し、必要であれば証明書を接続します。ヘルスチェックに連続で失敗したターゲットは自動的に除外され、再び正常になると復帰します。"
      else
        echo "## $i. Listener settings $i"
        echo
        echo "Listener $i accepts client connections and forwards them to the target group. Specify the protocol and port, and attach a certificate if needed. A target that fails the health check repeatedly is removed automatically and returns once it is healthy again."
      fi
      echo
      echo "!!! tip \"$conv\""
      echo
      if [ "$lang" = ja ]; then
        echo "    1つの接続で同時に処理できるリクエストは最大100件であり、この値は変更できません。これを超えるリクエストはクライアント側で待機してから処理されるため、エラーは発生しません。"
        echo
        echo "| 項目 | 設定 $i |"
        echo "|---|---|"
        echo "| プロトコル | リスナー$i が受け取るプロトコルです。 |"
        echo "| ヘルスチェック周期 | ターゲットの状態を確認する間隔です。 |"
      else
        echo "    A single connection can handle up to 100 simultaneous requests, and this value cannot be changed. Requests beyond that are queued on the client side before being processed, so no errors occur."
        echo
        echo "| Item | Setting $i |"
        echo "|---|---|"
        echo "| Protocol | The protocol listener $i accepts. |"
        echo "| Health check interval | How often the target's state is checked. |"
      fi
      echo
    done
  } > "$lang/$DOC"
}

gen_ko "ko/$DOC" "$SECTIONS" ""
gen_target en "$EN_CONV"
gen_target ja "$JA_CONV"
CHARS=$("$PY" -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()))" "ko/$DOC")
echo "  ko/$DOC ${CHARS}자 · 절 $SECTIONS · 상자 제목 관례 ja='$JA_CONV' en='$EN_CONV'"
git add "ko/$DOC" "en/$DOC" "ja/$DOC"
git -c user.email=e2e@local -c user.name=e2e commit -q -m "e2e(term-pin/splice): 정렬된 기존 번역본"
git push -q origin "$SESSION"
BASE_EN="$(git show "HEAD:en/$DOC")"; BASE_JA="$(git show "HEAD:ja/$DOC")"
printf '%s' "$BASE_EN" > "$SCRATCH/base-en.md"
printf '%s' "$BASE_JA" > "$SCRATCH/base-ja.md"

titles() { grep -oE '^!!! tip "[^"]*"' "$1" 2>/dev/null | sed 's/^!!! tip "//; s/"$//' || true; }

# ── 2. 한 팔 ──────────────────────────────────────────────────────────────
run_one() {   # $1=on|off $2=round
  # `local a=.. b=$a` 는 bash 가 **한 번에** 확장하므로 `$a` 가 아직 없다
  # (`set -u` 에서 `unbound variable`). 그래서 두 문장으로 나눈다.
  local pin="$1" round="$2"
  local br="e2e-termpinsp-$pin-$round-$TS" log="$SCRATCH/$pin-$round.log"
  echo "$br" >> "$SCRATCH/branches"
  git push -q origin "$SESSION:$br"
  git checkout -q -B "arm-$pin-$round" "$SESSION"
  # ko 만 바꾼 두 번째 커밋 — 절 17 순수 삽입 + 절 5 문장 하나 수정.
  gen_ko "ko/$DOC" "$SECTIONS" " 연결은 대상 그룹의 상태에 따라 분산됩니다."
  ko_section "$((SECTIONS + 1))" "" >> "ko/$DOC"
  git add "ko/$DOC"
  git -c user.email=e2e@local -c user.name=e2e commit -q -m "e2e(term-pin/splice): ko 절 삽입 + 문장 수정"
  git push -q -f origin "arm-$pin-$round:$br"
  local t0=$SECONDS
  ( cd "$CT_DIR" && \
    TRANSLATE_TERM_PIN="$pin" \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    TRANSLATE_LOG_LEVEL=info \
    "$PY" translate/translate_file.py \
      "https://github.com/$REPO/blob/$br/ko/$DOC" --diff --commit-to-branch "$br" \
  ) > "$log" 2>&1 || {
    if grep -qi "usage limit\|사용량 한도\|HTTP 429" "$log"; then
      echo "  한도 소진 (429) — 리셋 후 CLI 로 다시 돌린다 (api 로 우회하지 않는다)"
      INFRA=2
    fi
    bad "번역 실패 (term_pin=$pin round=$round)"; tail -12 "$log"; return 1
  }
  if ! grep -q "Diff-based translation" "$log"; then
    bad "splice 가 안 돌았다 (전문 재번역으로 떨어짐) — 두 팔의 차이가 term-pin 의 몫이 아니게 된다"
    INFRA=2; return 1
  fi
  if [ "$pin" = on ]; then
    local pinline
    pinline="$(grep -o 'term-pin .*제안 [0-9]* → 채택 [0-9]* (기각 [0-9]*)' "$log" | head -2 | tr '\n' ' ')"
    [ -n "$pinline" ] && info "고정 단계: $pinline" \
      || { bad "고정 단계 로그가 없다 — TRANSLATE_ANTHROPIC_API_KEY 확인"; }
  fi
  git fetch -q origin "$br"
  local d="$SCRATCH/out/$pin-$round"; mkdir -p "$d"
  for lang in en ja; do
    git show "FETCH_HEAD:$lang/$DOC" > "$d/$lang.md" 2>/dev/null \
      || { bad "$lang 산출물이 없다 ($pin round=$round)"; return 1; }
  done
  echo "  round $round · term_pin=$pin · $((SECONDS - t0))초" >> "$SCRATCH/timing"
  git checkout -q "$SESSION"
  return 0
}

echo
IFS=',' read -r -a ARM_LIST <<< "$ARMS"
for r in $(seq 1 "$ROUNDS"); do
  echo "=== 2단계 splice 번역 · round $r/$ROUNDS ==="
  for arm in "${ARM_LIST[@]}"; do
    echo "  --- term_pin=$arm ---"
    run_one "$arm" "$r" || true
  done
done

# ── 3. 판정 ───────────────────────────────────────────────────────────────
echo
echo "=== 3단계 판정 ==="
declare -A ONBAD=()
declare -A CHANGED=()
# 측정한 (팔×언어) 수. **0 인데 통과시키면 안 된다** — `ONBAD` 는 "위반을 찾았다"
# 를 담으므로 산출물이 하나도 없으면 비어 있고, 그대로 두면 판정이 공허하게
# 초록이 된다. 2026-09-21 실측: 한도 소진(429)으로 네 산출물이 전부 없는데
# "(가) ON: 삽입된 상자가 문서 관례를 따랐다 — PASS" 가 찍혔다 (그 실행은
# INFRA 가 따로 서서 exit 2 였지만, 산출물이 다른 이유로 비면 exit 0 이 된다).
ON_MEASURED=0
for r in $(seq 1 "$ROUNDS"); do
  for arm in "${ARM_LIST[@]}"; do
    for lang in en ja; do
      f="$SCRATCH/out/$arm-$r/$lang.md"
      [ -f "$f" ] || { echo "  $arm r$r $lang: (산출물 없음)"; continue; }
      conv="$JA_CONV"; [ "$lang" = en ] && conv="$EN_CONV"
      list="$(titles "$f")"
      n_all=$(echo "$list" | grep -c . || true)
      n_conv=$(echo "$list" | grep -cxF "$conv" || true)
      # 삽입된 절의 상자 = 마지막 상자.
      last="$(echo "$list" | tail -1)"
      # 무해 축 — 기존 번역본 대비 바뀐 줄 수. 삽입된 절만큼은 당연히 늘어난다.
      ch=$(diff <(cat "$SCRATCH/base-$lang.md") "$f" | grep -c '^[<>]' || true)
      CHANGED[$arm-$lang-$r]=$ch
      echo "  $arm r$r $lang: 상자 ${n_all}개 · 관례 ${n_conv}/${n_all} · 삽입된 상자='$last' · 변경 줄 $ch"
      if [ "$arm" = on ]; then
        ON_MEASURED=$((ON_MEASURED + 1))
        [ "$last" = "$conv" ] || ONBAD[insert]=1
        [ "$n_conv" = "$n_all" ] || ONBAD[all]=1
      fi
    done
  done
done

if [ "$ON_MEASURED" = "0" ]; then
  bad "ON 산출물이 하나도 없다 — 판정할 것이 없으므로 통과가 아니다"
  INFRA=2
else
  if [ "${ONBAD[insert]:-0}" = "0" ]; then
    ok "(가) ON: 삽입된 상자가 문서 관례를 따랐다 — #417 이 splice 경로에서 닫힌다 (측정 $ON_MEASURED)"
  else
    bad "(가) ON: 삽입된 상자가 문서 관례와 다르다 — #417 이 그대로다"
  fi
  if [ "${ONBAD[all]:-0}" = "0" ]; then
    ok "(가') ON: 문서의 모든 상자 제목이 한 가지"
  else
    bad "(가') ON: 문서 안에서 상자 제목이 갈렸다"
  fi
fi

# (나) 무해 — ON 이 대조군보다 더 많은 줄을 다시 쓰지 않았는가.
HARM=0
for r in $(seq 1 "$ROUNDS"); do
  for lang in en ja; do
    on="${CHANGED[on-$lang-$r]:-}"; off="${CHANGED[off-$lang-$r]:-}"
    [ -n "$on" ] && [ -n "$off" ] || continue
    if [ "$on" -gt "$off" ]; then
      HARM=1; info "r$r $lang: ON 변경 $on 줄 > OFF $off 줄"
    fi
  done
done
if [ -n "${CHANGED[on-en-1]:-}" ] && [ -n "${CHANGED[off-en-1]:-}" ]; then
  [ "$HARM" = "0" ] && ok "(나) ON 이 대조군보다 더 많은 줄을 다시 쓰지 않았다" \
                    || bad "(나) ON 이 ko 가 안 건드린 줄까지 다시 썼다"
else
  info "(나) 대조군이 없어 무해 축은 판정하지 않는다 (--arms 로 한 팔만 돌렸다)"
fi

echo
[ -f "$SCRATCH/timing" ] && { echo "=== 소요 ==="; cat "$SCRATCH/timing"; }
echo "결과: PASS=$PASS FAIL=$FAIL"
[ "$INFRA" != "0" ] && { echo "TERM_PIN_SPLICE: INFRA"; exit 2; }
[ "$FAIL" = "0" ] && { echo "TERM_PIN_SPLICE: OK"; exit 0; }
echo "TERM_PIN_SPLICE: FAIL"; exit 1
