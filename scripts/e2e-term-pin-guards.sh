#!/usr/bin/env bash
#
# term-pin — **안전 축**. "켜서 좋아지는가" 가 아니라 "켜서 나빠지지 않는가".
#
# `e2e-term-pin.sh` 와 `e2e-term-pin-existing.sh` 는 이득을 잰다. 기본 꺼짐을
# 푸는 결정은 이득만으로 나지 않는다 — 이 장치는 **모든 chunk 의 system prompt**
# 를 바꾸므로, 잘못 고정하면 잘 되던 자리까지 한 번에 틀어진다. 여기서는 네
# 가지를 본다. 전부 대조군(OFF)과 나란히 재고, 판정은 결정적이다.
#
#   (G1) 용어집이 이긴다 — 등재된 용어(`인스턴스`)의 역어를 고정이 덮지 않는다.
#        `validate_unregistered` 의 `용어집이 이미 덮음` 이 코드로는 보장하지만,
#        프롬프트에 두 지시가 함께 실려 모델이 흔들릴 수는 있다. 산출물로 본다.
#   (G2) 겹침 — `시계열` ⊂ `시계열 이상탐지`. 둘의 표기가 어긋나면 같은 말에
#        두 지시를 내린 꼴이다 (`nhn-cloud-foundry` 가 등재 후에도 갈린 원인).
#        짧은 쪽 역어가 긴 쪽 역어 안에 들어 있어야 한다.
#   (G3) fail-open — 고정 단계는 CLI 잡에서도 **API** 를 탄다
#        (`TRANSLATE_ANTHROPIC_API_KEY`). 키가 없거나 호출이 실패하면 번역이
#        **그대로 끝나야** 한다. 부가 정책이 본 작업을 죽이면 안 된다.
#   (G4) 문서 사이 일관성 — 고정은 **문서마다 따로** 정해진다. 같은 리포의 두
#        문서가 같은 미등록 용어를 다르게 고정하면, 문서 안 갈림을 고치면서
#        리포 갈림을 만든 것이다. term-pin 이 약속한 적 없는 축이라 **보고**가
#        기본이고, ON 이 대조군보다 나쁠 때만 FAIL 이다.
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# 세션 브랜치에 ko 문서 둘. 번역본은 만들지 않는다 (ⓒ 미등록 경로를 재는 중이고,
# 기존 표기 축은 `e2e-term-pin-existing.sh`·`e2e-term-pin-splice.sh` 의 몫이다).
#   A `ko/term-pin-guard-a.md` — 등재어 `인스턴스` · 겹침쌍 · 공유어
#   B `ko/term-pin-guard-b.md` — 공유어 (A 와 다른 문맥)
# 둘 다 10,000자를 넘겨 최소 두 chunk 로 갈라야 한다 — 한 번에 번역되면 갈릴
# 자리가 없어 대조군이 늘 초록이 된다 (`e2e-term-pin.sh` 가 바이트로 재서 겪은 일).
#
# Usage:
#   bash scripts/e2e-term-pin-guards.sh [--keep] [--skip-nokey]
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-term-pin-guards.sh
#
# exit: 0 ON 이 네 축을 지켰다 / 1 지키지 못했다 / 2 인프라
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e-termpingd-$TS"      # 슬래시 금지 — translate_file.py 의 blob URL 파싱
DOC_A="term-pin-guard-a.md"
DOC_B="term-pin-guard-b.md"
GLOSSED="인스턴스"               # Agent-Test_glossary.md 등재 (en Instance / ja インスタンス)
GLOSSED_EN="Instance"
GLOSSED_JA="インスタンス"
SHORT="시계열"
LONG="시계열 이상탐지"
SHARED="예측 오차 정상 범위"
CT_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
SCRATCH="$(mktemp -d)"
KEEP=0
SKIP_NOKEY=0
RUN_TIMEOUT="${TERM_PIN_RUN_TIMEOUT:-1500}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)        KEEP=1; shift ;;
    --skip-nokey)  SKIP_NOKEY=1; shift ;;
    -h|--help)     sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done

PY=""
for c in "$CT_DIR/.venv/bin/python" "$HOME/works/cloud-translate/.venv/bin/python" "$(command -v python3)"; do
  [ -x "$c" ] && PY="$c" && break
done
[ -n "$PY" ] || { echo "python 없음" >&2; exit 2; }
[ -f "$CT_DIR/.env" ] || { echo "error: $CT_DIR/.env 없음" >&2; exit 2; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIVERGE="$REPO_ROOT/scripts/check_term_divergence.py"
[ -f "$DIVERGE" ] || { echo "측정기 없음: $DIVERGE" >&2; exit 2; }

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

echo "=== 1단계 픽스처 ==="
WORK="$SCRATCH/repo"
git clone -q --depth 1 --branch "$BASE_SOURCE" "https://github.com/$REPO.git" "$WORK"
cd "$WORK"; git checkout -q -b "$SESSION"
: > "$SCRATCH/branches"

# 절 수는 **10,000자를 넘기려고** 정한 값이다 (A 423자/절 · B 290자/절, 실측).
# 그 아래면 문서가 한 번의 모델 호출로 끝나 갈릴 자리가 아예 없고, 대조군이 늘
# 초록이 되어 ON 판정이 무의미해진다.
SECTIONS_A=26
SECTIONS_B=36

gen_a() {
  {
    echo "# 이상 탐지 앱 가이드 { #tpg-a }"
    echo
    echo "이 문서는 $LONG 기능과 $GLOSSED 운영을 설명합니다."
    echo
    for i in $(seq 1 "$SECTIONS_A"); do
      echo "<a id=\"tpg-a-$i\"></a>"
      echo
      echo "## $i. 앱 설정 $i"
      echo
      echo "$LONG 앱은 $GLOSSED 한 대에서 동작합니다. $SHORT 데이터를 모아 학습한 뒤, $SHARED 를 벗어난 지점을 이상으로 기록합니다. $GLOSSED 사양이 작으면 학습이 느려집니다."
      echo
      echo "1. 콘솔에서 **$LONG** 탭으로 이동합니다."
      echo "2. $GLOSSED 를 고르고 $SHORT 지표를 선택합니다."
      echo "3. $SHARED 를 설정합니다. 폭이 좁을수록 더 많은 지점이 이상으로 기록됩니다."
      echo
      echo "| 항목 | 설정 $i |"
      echo "|---|---|"
      echo "| $LONG | 이 절에서는 지표 $i 개를 다룹니다. |"
      echo "| $SHORT | 학습에 쓰는 원본 데이터입니다. |"
      echo "| $SHARED | 설정 $i 에서는 기본 폭의 $i 배입니다. |"
      echo "| $GLOSSED | 앱이 도는 서버 자원입니다. |"
      echo
    done
  } > "ko/$DOC_A"
}

gen_b() {
  {
    echo "# 경보 연동 가이드 { #tpg-b }"
    echo
    echo "이 문서는 탐지 결과를 경보로 내보내는 방법을 설명합니다."
    echo
    for i in $(seq 1 "$SECTIONS_B"); do
      echo "<a id=\"tpg-b-$i\"></a>"
      echo
      echo "## $i. 경보 규칙 $i"
      echo
      echo "규칙 $i 은 탐지 결과를 받아 경보를 보냅니다. $SHARED 를 벗어난 지점이 연속으로 나오면 규칙이 동작합니다. 수신자는 규칙마다 따로 지정합니다."
      echo
      echo "1. 규칙 이름을 입력합니다."
      echo "2. $SHARED 를 확인하고 임계치를 정합니다."
      echo "3. 수신 채널을 고릅니다."
      echo
      echo "| 항목 | 규칙 $i |"
      echo "|---|---|"
      echo "| $SHARED | 규칙 $i 이 기준으로 삼는 폭입니다. |"
      echo "| 수신 채널 | 경보를 받을 채널입니다. |"
      echo
    done
  } > "ko/$DOC_B"
}

gen_a; gen_b
for d in "$DOC_A" "$DOC_B"; do
  n=$("$PY" -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()))" "ko/$d")
  echo "  ko/$d — ${n}자"
  [ "$n" -gt 10000 ] || { bad "픽스처가 너무 작다 (${n}자) — 한 chunk 로 끝나 갈릴 자리가 없다"; INFRA=1; }
done
git add "ko/$DOC_A" "ko/$DOC_B"
git -c user.email=e2e@local -c user.name=e2e commit -q -m "e2e(term-pin/guards): 픽스처"
git push -q origin "$SESSION"

run_one() {   # $1=on|off|nokey  $2=doc
  local arm="$1" doc="$2"
  local br="e2e-termpingd-$arm-${doc%.md}-$TS" log="$SCRATCH/$arm-$doc.log"
  local pin=on
  if [ "$arm" = off ]; then pin=off; fi
  echo "$br" >> "$SCRATCH/branches"
  git push -q origin "$SESSION:$br"
  local key_env=()
  [ "$arm" = nokey ] && key_env=(TRANSLATE_ANTHROPIC_API_KEY=)
  local t0=$SECONDS
  ( cd "$CT_DIR" && \
    env "${key_env[@]}" \
    TRANSLATE_TERM_PIN="$pin" \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    TRANSLATE_LOG_LEVEL=info \
    timeout "$RUN_TIMEOUT" \
    "$PY" translate/translate_file.py \
      "https://github.com/$REPO/blob/$br/ko/$doc" --commit-to-branch "$br" \
  ) > "$log" 2>&1 || {
    if grep -qi "usage limit\|사용량 한도\|HTTP 429" "$log"; then
      echo "  한도 소진 (429) — 리셋 후 CLI 로 다시 돌린다 (api 로 우회하지 않는다)"
      INFRA=2
    fi
    bad "번역 실패 ($arm $doc)"; tail -12 "$log"; return 1
  }
  git fetch -q origin "$br"
  local d="$SCRATCH/out/$arm-$doc"; mkdir -p "$d"
  git show "FETCH_HEAD:ko/$doc" > "$d/ko.md" 2>/dev/null || true
  for lang in en ja; do
    git show "FETCH_HEAD:$lang/$doc" > "$d/$lang.md" 2>/dev/null \
      || { bad "$lang 산출물이 없다 ($arm $doc)"; return 1; }
  done
  echo "  $arm · $doc · $((SECONDS - t0))초" >> "$SCRATCH/timing"
  return 0
}

echo
echo "=== 2단계 번역 ==="
for arm in off on; do
  for doc in "$DOC_A" "$DOC_B"; do
    echo "  --- $arm · $doc ---"
    run_one "$arm" "$doc" || true
  done
done
if [ "$SKIP_NOKEY" = "0" ]; then
  echo "  --- nokey (G3 fail-open) · $DOC_A ---"
  run_one nokey "$DOC_A" || true
fi

echo
echo "=== 3단계 판정 ==="

# ── G3 fail-open ──────────────────────────────────────────────────────────
if [ "$SKIP_NOKEY" = "0" ]; then
  L="$SCRATCH/nokey-$DOC_A.log"
  if [ -f "$SCRATCH/out/nokey-$DOC_A/en.md" ] && [ -f "$SCRATCH/out/nokey-$DOC_A/ja.md" ]; then
    if grep -q "term-pin skipped — no ANTHROPIC_API_KEY" "$L"; then
      ok "(G3) 키가 없으면 고정 단계만 건너뛰고 번역은 그대로 끝난다"
    else
      bad "(G3) 키 없이 돌렸는데 'term-pin skipped' 로그가 없다 — 어디서 막혔는지 확인"
      grep -i "term-pin" "$L" | head -3
    fi
  else
    bad "(G3) 키가 없을 때 번역이 산출물을 내지 못했다 — fail-open 이 아니다"
  fi
fi

# ── G1 · G2 · G4 — 슬롯 측정기로 ──────────────────────────────────────────
TERMS="$GLOSSED,$SHORT,$LONG,$SHARED" OUT="$SCRATCH/out" DIVERGE="$DIVERGE" \
  DOC_A="$DOC_A" DOC_B="$DOC_B" \
  GLOSSED="$GLOSSED" GLOSSED_EN="$GLOSSED_EN" GLOSSED_JA="$GLOSSED_JA" \
  SHORT="$SHORT" LONG="$LONG" SHARED="$SHARED" \
  "$PY" - <<'PY' > "$SCRATCH/verdict.txt" 2>&1 || true
import importlib.util, json, os, pathlib

spec = importlib.util.spec_from_file_location("ctd", os.environ["DIVERGE"])
ctd = importlib.util.module_from_spec(spec); spec.loader.exec_module(ctd)

out = pathlib.Path(os.environ["OUT"])
DOC_A, DOC_B = os.environ["DOC_A"], os.environ["DOC_B"]
GLOSSED, SHORT, LONG, SHARED = (os.environ[k] for k in
                                ("GLOSSED", "SHORT", "LONG", "SHARED"))
EXPECT = {"en": os.environ["GLOSSED_EN"], "ja": os.environ["GLOSSED_JA"]}
terms = os.environ["TERMS"].split(",")

res = {}
for arm in ("off", "on"):
    for doc in (DOC_A, DOC_B):
        d = out / f"{arm}-{doc}"
        if not (d / "ko.md").exists():
            continue
        ko = (d / "ko.md").read_text(encoding="utf-8", errors="replace")
        for lang in ("en", "ja"):
            f = d / f"{lang}.md"
            if not f.exists():
                continue
            res[(arm, doc, lang)] = ctd.divergence(
                ko, f.read_text(encoding="utf-8", errors="replace"), terms)

print("## 슬롯에서 읽은 역어")
for (arm, doc, lang), r in sorted(res.items()):
    for t in terms:
        i = r["terms"].get(t)
        if i is None:
            continue
        forms = " / ".join(f'"{k}"x{v}' for k, v in i["forms"].items())
        flag = "갈림" if i["diverged"] else "고정"
        print(f"  {arm:3} {doc[-12:]:12} {lang} [{flag}] {t} -> {forms}")

verdict = {}

# G1 — 등재어는 용어집 역어여야 한다.
for arm in ("off", "on"):
    bad_ = []
    for (a, doc, lang), r in res.items():
        if a != arm:
            continue
        i = r["terms"].get(GLOSSED)
        if i is None:
            continue
        for form in i["forms"]:
            if EXPECT[lang].lower() not in form.lower():
                bad_.append(f"{doc}/{lang}:{form}")
    verdict.setdefault("g1", {})[arm] = bad_

# G2 — 짧은 쪽 역어가 긴 쪽 역어 안에 있어야 한다.
for arm in ("off", "on"):
    bad_ = []
    for (a, doc, lang), r in res.items():
        if a != arm:
            continue
        s, l = r["terms"].get(SHORT), r["terms"].get(LONG)
        if not s or not l:
            continue
        def norm(x):
            return x.lower().replace("-", " ").replace("　", " ")
        if norm(s["major"]) not in norm(l["major"]):
            bad_.append(f"{doc}/{lang}:{s['major']}⊄{l['major']}")
    verdict.setdefault("g2", {})[arm] = bad_

# G4 — 두 문서가 공유어를 같은 말로 옮겼는가.
for arm in ("off", "on"):
    bad_ = []
    for lang in ("en", "ja"):
        a = res.get((arm, DOC_A, lang), {}).get("terms", {}).get(SHARED)
        b = res.get((arm, DOC_B, lang), {}).get("terms", {}).get(SHARED)
        if not a or not b:
            continue
        if a["major"].lower() != b["major"].lower():
            bad_.append(f"{lang}:{a['major']} vs {b['major']}")
    verdict.setdefault("g4", {})[arm] = bad_

print()
print("VERDICT_JSON " + json.dumps(verdict, ensure_ascii=False))
PY
cat "$SCRATCH/verdict.txt"

VJ="$(grep '^VERDICT_JSON ' "$SCRATCH/verdict.txt" | head -1 | cut -d' ' -f2-)"
if [ -z "$VJ" ]; then
  bad "판정기가 결과를 내지 못했다"; INFRA=2
else
  judge() {   # $1=key $2=제목 $3=strict(1)|비교(0)
    local key="$1" title="$2" strict="$3"
    local on off
    on="$(echo "$VJ" | "$PY" -c "import json,sys;d=json.load(sys.stdin).get('$key',{});print(len(d.get('on',[])))")"
    off="$(echo "$VJ" | "$PY" -c "import json,sys;d=json.load(sys.stdin).get('$key',{});print(len(d.get('off',[])))")"
    local detail
    detail="$(echo "$VJ" | "$PY" -c "import json,sys;d=json.load(sys.stdin).get('$key',{});print(' | '.join(d.get('on',[])))")"
    if [ "$strict" = "1" ]; then
      if [ "$on" = "0" ]; then ok "$title (ON 0건 · 대조군 $off건)"
      else bad "$title — ON $on건: $detail"; fi
    else
      if [ "$on" -le "$off" ] 2>/dev/null; then ok "$title (ON $on ≤ 대조군 $off)"
      else bad "$title — ON $on > 대조군 $off: $detail"; fi
    fi
  }
  judge g1 "(G1) 등재 용어는 용어집 역어 그대로" 1
  judge g2 "(G2) 겹침쌍의 표기가 어긋나지 않았다" 1
  judge g4 "(G4) 문서 사이 공유어 표기" 0
fi

echo
[ -f "$SCRATCH/timing" ] && { echo "=== 소요 ==="; cat "$SCRATCH/timing"; }
echo "결과: PASS=$PASS FAIL=$FAIL"
[ "$INFRA" != "0" ] && { echo "TERM_PIN_GUARDS: INFRA"; exit 2; }
[ "$FAIL" = "0" ] && { echo "TERM_PIN_GUARDS: OK"; exit 0; }
echo "TERM_PIN_GUARDS: FAIL"; exit 1
