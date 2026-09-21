#!/usr/bin/env bash
#
# term-pin — **기존 번역본의 표기를 따라가는가** (미등록 용어 ⓒ 경로의 두 번째 축).
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# cloud-user-guide-agent#417 / TOAST-DOCS/Network-Load-Balancer#141.
# ko 가 `!!! tip "알아두기"` 안내 상자 하나를 더했는데, ja 번역이 그 제목을
# `ヒント` 로 썼다 — 같은 문서는 `ポイント` 를 12번 쓰고 있었다. 머지하면 한
# 페이지에서 같은 성격의 상자가 두 이름으로 보인다.
#
# 이 자리에는 **답이 셋** 있었다.
#   * 통합 가이드라인 `guidelines-unified_ja.md:120` — `팁 → ヒント`
#   * `_common_glossary.md` — `알아두기 → 注意`
#   * 그 문서·그 리포가 실제로 쓰는 말 — `ポイント` (ja/ 전체 28 : 1)
# 그리고 `Network-Load-Balancer_glossary.md` 에는 `알아두기` 가 **없다.**
# `glossary_mode=service` 는 전용 용어집이 있으면 `_common` 으로 폴백하지 않으므로
# 그 리포에서 이 낱말은 **미등록**이고, 정하는 사람이 아무도 없어 모델이 chunk 마다
# 즉흥으로 고른다. 그게 term-pin ⓒ 가 맡기로 한 자리다 — `propose_terms` 의 첫
# 규칙이 "Prefer the rendering the existing translation already uses. Consistency
# with what is deployed beats a better-but-different word." 다.
#
# `Agent-Test_glossary.md` 에도 `알아두기` 가 없어(실측 2026-09-21) 픽스처가 NLB 와
# 같은 조건이 된다.
#
# ── 왜 전문 재번역인가 (PR 을 만들지 않는다) ──────────────────────────────
# 전문 재번역은 `preserve_existing` 이 기본 꺼짐이라 **모델이 기존 번역본을 아예
# 보지 못한다.** 기존 번역본을 읽는 것은 term-pin 뿐이다. 그래서 두 팔의 차이가
# 오롯이 이 장치의 몫이 된다 — splice 로 재면 "안 바뀐 유닛을 그대로 가져왔다" 와
# "표기를 따랐다" 가 섞여 구분되지 않는다.
#
# ── 판정 ──────────────────────────────────────────────────────────────────
#   (1) 산출물 안에서 상자 제목이 **한 가지**       ← 문서 안 일관성
#   (2) 그 한 가지가 **기존 번역본이 쓰던 말**      ← 이 e2e 의 본체
#   ON 이 둘 다, 모든 판에서 만족해야 한다. OFF 는 대조군이다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-term-pin-existing.sh [--rounds N] [--keep]
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-term-pin-existing.sh
#
# exit: 0 ON 이 계약을 지켰다 / 1 지키지 못했다 / 2 인프라
# e2e 는 **CLI 엔진으로 돈다**. 제안 단계만 API 를 탄다 (llm-patch judge 와 같다).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e-termpinex-$TS"      # 슬래시 금지 — translate_file.py 의 blob URL 파싱
DOC="term-pin-existing.md"
TERM="알아두기"
JA_CONV="ポイント"               # 문서가 쓰는 말 (가이드라인의 ヒント 가 아니다)
EN_CONV="Good to know"           # en 쪽 같은 축
CT_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
SCRATCH="$(mktemp -d)"
KEEP=0
ROUNDS=2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)   KEEP=1; shift ;;
    --rounds) ROUNDS="$2"; shift 2 ;;
    -h|--help) sed -n '1,46p' "$0"; exit 0 ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done

PY=""
for c in "$CT_DIR/.venv/bin/python" "$HOME/works/cloud-translate/.venv/bin/python" "$(command -v python3)"; do
  [ -x "$c" ] && PY="$c" && break
done
[ -n "$PY" ] || { echo "python 없음" >&2; exit 2; }

PASS=0; FAIL=0; INFRA=0
ok(){   echo "  PASS  $*"; PASS=$((PASS+1)); }
bad(){  echo "  FAIL  $*"; FAIL=$((FAIL+1)); }

cleanup() {
  [ "$KEEP" = "1" ] && { echo "브랜치 유지: $SESSION"; return; }
  for b in "$SESSION" $(cat "$SCRATCH/branches" 2>/dev/null); do
    git -C "$SCRATCH/repo" push -q origin ":$b" >/dev/null 2>&1 || true
  done
  rm -rf "$SCRATCH"
}
trap cleanup EXIT

echo "=== 1단계 픽스처 ==="
WORK="$SCRATCH/repo"
git clone -q --depth 1 --branch "$BASE_SOURCE" "https://github.com/$REPO.git" "$WORK"
cd "$WORK"; git checkout -q -b "$SESSION"
: > "$SCRATCH/branches"

# ko — 안내 상자 7개. 제목은 전부 같은 ko 낱말.
{
  echo "# 안내 상자 표기 픽스처 { #tpe-root }"
  echo
  echo "이 문서는 로드 밸런서의 동작을 설명하고, 절마다 $TERM 상자로 주의할 점을 덧붙입니다."
  echo
  for i in $(seq 1 16); do
    echo "<a id=\"tpe-$i\"></a>"
    echo
    echo "## $i. 리스너 설정 $i"
    echo
    echo "리스너 $i 은 클라이언트의 연결을 받아 대상 그룹으로 전달합니다. 프로토콜과 포트를 지정하고, 필요하면 인증서를 연결합니다. 연결 수가 많아지면 대상 그룹의 상태 검사 주기를 짧게 잡아 장애를 빨리 감지하는 편이 좋습니다. 상태 검사에 연속으로 실패한 대상은 자동으로 제외되고, 다시 정상이 되면 복귀합니다."
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
  done
} > "ko/$DOC"

# en/ja — **문서의 관례**로 상자 제목이 고정된 기존 번역본.
gen_target() {   # $1=lang  $2=상자 제목  $3=본문 언어 표식
  local lang="$1" conv="$2"
  {
    echo "<!-- machine_translated: true -->"
    echo
    if [ "$lang" = ja ]; then
      echo "# ガイド枠表記フィクスチャ { #tpe-root }"
      echo
      echo "この文書はロードバランサーの動作を説明し、節ごとに$conv枠で注意点を補足します。"
    else
      echo "# Admonition title fixture { #tpe-root }"
      echo
      echo "This document explains how the load balancer works and adds a $conv box in each section."
    fi
    echo
    for i in $(seq 1 16); do
      echo "<a id=\"tpe-$i\"></a>"
      echo
      if [ "$lang" = ja ]; then
        echo "## $i. リスナー設定 $i"
        echo
        echo "リスナー$i はクライアントの接続を受け取り、ターゲットグループに転送します。プロトコルとポートを指定し、必要であれば証明書を接続します。接続数が多くなる場合は、ターゲットグループのヘルスチェック周期を短く設定して障害を早く検知する方がよいです。ヘルスチェックに連続で失敗したターゲットは自動的に除外され、再び正常になると復帰します。"
      else
        echo "## $i. Listener settings $i"
        echo
        echo "Listener $i accepts client connections and forwards them to the target group. Specify the protocol and port, and attach a certificate if needed. When the number of connections grows, set a shorter health check interval on the target group to detect failures sooner. A target that fails the health check repeatedly is removed automatically and returns once it is healthy again."
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
gen_target en "$EN_CONV"
gen_target ja "$JA_CONV"

# 크기는 **글자**로 잰다 — `_split_into_chunks` 의 max_chars 가 10,000자이고,
# 한글은 UTF-8 3바이트라 `wc -c` 로 재면 3배로 부풀어 한 chunk 짜리 문서를
# "경계를 넘었다" 로 통과시킨다 (e2e-term-pin.sh 가 그 실수를 했다).
CHARS=$("$PY" -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()))" "ko/$DOC")
echo "  ko/$DOC ${CHARS}자 · 상자 16개 · ja 관례='$JA_CONV' · en 관례='$EN_CONV'"
[ "$CHARS" -gt 10000 ] && ok "픽스처가 chunk 경계를 넘는다 (${CHARS}자 > 10000자)" \
                       || { bad "픽스처가 너무 작다 (${CHARS}자)"; INFRA=1; }
git add "ko/$DOC" "en/$DOC" "ja/$DOC"
git -c user.email=e2e@local -c user.name=e2e commit -q -m "e2e(term-pin): 기존 표기 픽스처"
git push -q origin "$SESSION"
BLOB="https://github.com/$REPO/blob/$SESSION/ko/$DOC"

titles() {   # $1=파일 → 상자 제목들
  grep -oE '^!!! tip "[^"]*"' "$1" 2>/dev/null | sed 's/^!!! tip "//; s/"$//' || true
}

run_one() {   # $1=on|off $2=round
  local pin="$1" round="$2" br="e2e-termpinex-$pin-$round-$TS" log="$SCRATCH/$pin-$round.log"
  echo "$br" >> "$SCRATCH/branches"
  git push -q origin "$SESSION:$br"
  ( cd "$CT_DIR" && \
    TRANSLATE_TERM_PIN="$pin" \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    TRANSLATE_LOG_LEVEL=info \
    "$PY" translate/translate_file.py "$BLOB" --commit-to-branch "$br" \
  ) > "$log" 2>&1 || {
    grep -qi "usage limit\|사용량 한도\|HTTP 429" "$log" && {
      echo "  한도 소진 (429) — 리셋 후 CLI 로 다시 돌린다"; INFRA=2; }
    bad "번역 실패 (term_pin=$pin round=$round)"; tail -12 "$log"; return 1
  }
  [ "$pin" = on ] && grep -o 'term-pin .*제안 [0-9]* → 채택 [0-9]*' "$log" | head -2 \
    | sed 's/^/        /'
  git fetch -q origin "$br"
  local d="$SCRATCH/out/$pin-$round"; mkdir -p "$d"
  for lang in en ja; do
    git show "FETCH_HEAD:$lang/$DOC" > "$d/$lang.md" 2>/dev/null \
      || { bad "$lang 산출물이 없다 ($pin round=$round)"; return 1; }
  done
}

for r in $(seq 1 "$ROUNDS"); do
  echo "=== 2단계 번역 · round $r/$ROUNDS ==="
  for arm in off on; do
    echo "  --- term_pin=$arm ---"
    run_one "$arm" "$r" || true
  done
done

echo
echo "=== 3단계 판정 ==="
declare -A ONBAD=()
for r in $(seq 1 "$ROUNDS"); do
  for arm in off on; do
    for lang in en ja; do
      f="$SCRATCH/out/$arm-$r/$lang.md"
      [ -f "$f" ] || { echo "  $arm r$r $lang: (산출물 없음)"; continue; }
      conv="$JA_CONV"; [ "$lang" = en ] && conv="$EN_CONV"
      list="$(titles "$f")"
      n_forms=$(echo "$list" | sort -u | grep -c . || true)
      n_conv=$(echo "$list" | grep -cxF "$conv" || true)
      n_all=$(echo "$list" | grep -c . || true)
      forms="$(echo "$list" | sort | uniq -c | tr '\n' ' ')"
      echo "  $arm r$r $lang: 표기 ${n_forms}가지 · 관례 '$conv' ${n_conv}/${n_all} · $forms"
      if [ "$arm" = on ]; then
        [ "$n_forms" = "1" ] || ONBAD[forms]=1
        [ "$n_conv" = "$n_all" ] && [ "$n_all" != "0" ] || ONBAD[conv]=1
      fi
    done
  done
done

if [ "${ONBAD[forms]:-0}" = "0" ]; then
  ok "(1) ON: 모든 판에서 상자 제목이 한 가지"
else
  bad "(1) ON: 한 문서 안에서 상자 제목이 갈렸다"
fi
if [ "${ONBAD[conv]:-0}" = "0" ]; then
  ok "(2) ON: 그 한 가지가 기존 번역본이 쓰던 말이다 — #417 이 닫힌다"
else
  bad "(2) ON: 기존 번역본의 표기를 따르지 않았다 — #417 이 닫히지 않는다"
fi

echo
echo "결과: PASS=$PASS FAIL=$FAIL"
[ "$INFRA" != "0" ] && { echo "TERM_PIN_EXISTING: INFRA"; exit 2; }
[ "$FAIL" = "0" ] && { echo "TERM_PIN_EXISTING: OK"; exit 0; }
echo "TERM_PIN_EXISTING: FAIL"; exit 1
