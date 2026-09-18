#!/usr/bin/env bash
#
# 미등록 용어 고정 효과 측정 — cloud-translate `app/term_table.py` ⓒ 경로.
#
# ── 무엇을 재나 ───────────────────────────────────────────────────────────
# 용어집에 **없는** 용어는 chunk 마다 즉흥이라 **한 문서 안에서도** 갈린다.
# 실증: `nhn-cloud-foundry` 의 `단변량 시계열 이상탐지` 가 alpha 의 네 문서
# 각각의 안에서 `time series` / `time-series` 로 갈렸다 (#375).
#
# 이 e2e 는 같은 ko 문서를 **두 번** 번역한다 — `term_pin` 만 바꾸고 나머지는
# 고정. 산출물에서 그 용어의 표기가 몇 가지로 나오는지 센다.
#
#   OFF  대조군. 갈릴 수 있는 상황인지 보여 준다 (갈리지 않을 수도 있다)
#   ON   판정. **반드시 한 가지** 여야 한다
#
# 대조군이 우연히 한 가지로 나와도 ON 의 판정은 유효하다 — 이 장치가 지키는 것은
# "모델이 운 좋게 일관됐다" 가 아니라 "표기가 하나로 고정된다" 이기 때문이다.
#
# ── 픽스처가 커야 하는 이유 ───────────────────────────────────────────────
# 갈림은 **chunk 경계**에서 생긴다. 10,000자를 넘겨야 `_translate_by_sections`
# 로 쪼개지므로 픽스처를 그 위로 만든다. 작은 문서로 재면 한 번의 모델 호출로
# 끝나 갈릴 자리가 없다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-term-pin.sh
#   bash scripts/e2e-term-pin.sh --keep
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-term-pin.sh
#
# 의존성: git, gh (로그인), python3, ANTHROPIC_API_KEY (제안 단계는 API 를 탄다 —
# llm-patch judge 와 같다)
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
BR_OFF="e2e-termpin-off-$TS"
BR_ON="e2e-termpin-on-$TS"
DOC="term-pin-sample.md"
TERM="단변량 시계열 이상탐지"
CT_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
SCRATCH="$(mktemp -d)"
KEEP=0
for a in "$@"; do case "$a" in --keep) KEEP=1 ;; *) echo "unknown: $a" >&2; exit 2 ;; esac; done

PY=""
for c in "$CT_DIR/.venv/bin/python" "$HOME/works/cloud-translate/.venv/bin/python" "$(command -v python3)"; do
  [ -x "$c" ] && PY="$c" && break
done
[ -n "$PY" ] || { echo "python 없음" >&2; exit 2; }

PASS=0; FAIL=0
ok(){ echo "  PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "  FAIL  $*"; FAIL=$((FAIL+1)); }

echo "=== 1/4 픽스처 ==="
WORK="$SCRATCH/repo"
git clone -q --depth 1 --branch "$BASE_SOURCE" "https://github.com/$REPO.git" "$WORK"
cd "$WORK"; git checkout -q -b "$SESSION"

# 10 절 × 여러 번 언급. chunk 경계를 넘도록 충분히 길게.
{
  echo "## 단변량 시계열 이상탐지 개요 { #term-pin-overview }"
  echo
  echo "이 문서는 $TERM 기능을 설명합니다."
  echo
  for i in $(seq 1 10); do
    echo "### $i. $TERM 설정 $i { #term-pin-$i }"
    echo
    echo "$TERM 앱을 생성하려면 먼저 데이터 소스를 준비합니다. $TERM 은 지표의 과거 패턴을 학습해 이상 구간을 찾습니다."
    echo
    echo "1. 콘솔에서 **$TERM** 탭으로 이동합니다. 이 탭에서 $TERM 앱 목록을 확인할 수 있습니다."
    echo "2. 학습 주기와 추론 주기를 지정합니다. 주기가 짧을수록 $TERM 의 반응이 빨라지지만 비용이 늘어납니다."
    echo "3. 임계값을 설정합니다. $TERM 은 점수가 임계값을 넘으면 이상으로 판단합니다."
    echo "4. 생성 버튼을 클릭하면 $TERM 앱이 만들어지고 학습이 시작됩니다."
    echo
    echo "> 참고: $TERM 앱은 프로젝트당 최대 10개까지 만들 수 있습니다. 자세한 내용은 $TERM 사용 가이드를 참고합니다."
    echo
  done
} > "ko/$DOC"
CHARS=$(wc -c < "ko/$DOC")
echo "  ko/$DOC — ${CHARS}바이트 · '$TERM' $(grep -o "$TERM" "ko/$DOC" | wc -l)회"
[ "$CHARS" -gt 10000 ] && ok "픽스처가 chunk 경계를 넘는다 (${CHARS} > 10000)" \
                       || bad "픽스처가 너무 작다 (${CHARS}) — 갈릴 자리가 없다"
git add "ko/$DOC"
git -c user.email=e2e@local -c user.name=e2e commit -q -m "e2e(term-pin): 픽스처"
git push -q origin "$SESSION"
git push -q origin "$SESSION:$BR_OFF"
git push -q origin "$SESSION:$BR_ON"

BLOB="https://github.com/$REPO/blob/$SESSION/ko/$DOC"

run_one() {   # $1=on|off  $2=branch
  local pin="$1" br="$2" log="$SCRATCH/$1.log"
  echo "=== $( [ "$pin" = on ] && echo '3' || echo '2' )/4 번역 (term_pin=$pin) ==="
  ( cd "$CT_DIR" && \
    TRANSLATE_TERM_PIN="$pin" \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    TRANSLATE_LOG_LEVEL=info \
    "$PY" translate/translate_file.py "$BLOB" --commit-to-branch "$br" \
  ) > "$log" 2>&1 || { bad "번역 실패 (term_pin=$pin)"; tail -20 "$log"; return 1; }
  ok "번역 성공 (term_pin=$pin)"
  if [ "$pin" = on ]; then
    if grep -q 'term-pin .*제안' "$log"; then
      ok "고정 단계가 실제로 돌았다: $(grep -o 'term-pin .*제안 [0-9]* → 채택 [0-9]*' "$log" | head -1)"
    else
      bad "고정 단계 로그가 없다 — ANTHROPIC_API_KEY 확인"
    fi
  fi
}

# 표기를 세는 규칙을 **한 문구로 박지 않는다.** 모델이 어떤 말로 옮길지는 모르고,
# 못 맞히면 0건이 나와 "갈리지 않았다" 와 "못 찾았다" 가 구별되지 않는다 (첫 실행이
# 정확히 그랬다). `anomaly detection` 을 끝으로 하는 명사구를 **전부** 모아 대소문자·
# 하이픈만 접어 같은 말끼리 묶고, 그 묶음 안의 표기 가짓수를 센다.
count_forms() {   # $1=branch → stdout: "표기수 | 상세"
  git fetch -q origin "$1" 2>/dev/null
  git show "origin/$1:en/$DOC" 2>/dev/null > "$SCRATCH/$1.en.md" || { echo "- | (브랜치 없음)"; return; }
  "$PY" - "$SCRATCH/$1.en.md" <<'EOF'
import re, sys, collections
t = open(sys.argv[1], encoding='utf-8', errors='replace').read()
surf = collections.Counter(
    m.group(0) for m in re.finditer(
        r'\b(?:[A-Za-z]+[- ]){1,4}[Aa]nomaly [Dd]etection\b', t))
if not surf:
    print('- | (anomaly detection 을 포함한 구가 없다 — 모델이 전혀 다른 말로 옮겼다)')
    print('    본문 표본:', ' / '.join(l.strip()[:70] for l in t.splitlines() if l.strip())[:200])
    raise SystemExit
groups = collections.defaultdict(collections.Counter)
for s, n in surf.items():
    groups[re.sub(r'[- ]+', ' ', s.lower())][s] += n
key, forms = max(groups.items(), key=lambda kv: sum(kv[1].values()))
print(len(forms), '|', ' / '.join(f'"{k}"x{v}' for k, v in forms.most_common()))
if len(groups) > 1:
    print('    다른 구:', ' / '.join(k for k in groups if k != key))
EOF
}

run_one off "$BR_OFF" || true
run_one on  "$BR_ON"  || true

echo "=== 4/4 판정 ==="
OFF="$(count_forms "$BR_OFF")"; ON="$(count_forms "$BR_ON")"
echo "  term_pin=off : $OFF"
echo "  term_pin=on  : $ON"
NOFF="${OFF%% *}"; NON="${ON%% *}"
[ "$NON" = "1" ] && ok "ON: 표기가 하나로 고정됐다" || bad "ON: 표기가 ${NON}가지 (1이어야 한다)"
if [ "$NOFF" -gt 1 ] 2>/dev/null; then
  echo "  (대조군이 ${NOFF}가지로 갈렸다 — 이 픽스처는 갈릴 수 있는 상황이다)"
else
  echo "  (대조군도 한 가지였다 — 이번 실행에서는 갈리지 않았다. ON 판정은 그대로 유효)"
fi

if [ "$KEEP" = "0" ]; then
  for b in "$SESSION" "$BR_OFF" "$BR_ON"; do git push -q origin ":$b" >/dev/null 2>&1 || true; done
  rm -rf "$SCRATCH"
fi
echo; echo "결과: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = 0 ] && echo "TERM_PIN: OK" || echo "TERM_PIN: FAIL"
[ "$FAIL" = 0 ]
