#!/usr/bin/env bash
#
# 표기 후처리 e2e — cloud-translate `app/notation.py` + worker 연결부 검증.
#
# 검증 대상 두 가지. 둘 다 **판단이 필요 없는** 축이라 모델이 아니라 코드가 맡는다.
#   (a) ja 라틴↔가나 공백 — 그 문서가 이미 무공백으로 쓰는 토큰에 공백을 넣지 않는다
#   (b) en/ja 산출물에 남은 한글 — 막지는 않고 기록한다
#
# ── 배경 ──────────────────────────────────────────────────────────────────
# 2026-09 번역 PR 전수 검토(52 PR · en/ja 272 파일)에서 나온 결함이 근거다.
#   · 공백 이탈 150곳 / 20 PR  (Data-Query#104 · AppGuard#442 · pipeline#327 …)
#   · 한글 잔존 8건 / 5 PR     (appguard-docs#11 `### 自体차단処理` · pipeline#327
#                              `**[배포 상세 설定]**` · Compute-Auto-Scale#29 en 의
#                              ``select `변경` `` — 전부 alpha 에 살아 있었다)
# 코퍼스 실측(ja 문서 1,362개 · 라틴↔가나 경계 70,034곳)에서 88.5%가 무공백이고
# 토큰별·문법 문맥별로 갈리지 않는 **전역 관례**다. 다만 지침(:75)은 기본을 "공백
# 있음"으로 적어 코퍼스와 뒤집혀 있으므로, 자동 수정은 **전역 관례와 그 문서가 둘 다
# 무공백일 때**로 한정한다.
#
# ── 두 부분으로 나눈 이유 ─────────────────────────────────────────────────
# Part A (결정적) — 규칙 자체를 스크래치 픽스처로 바이트 비교한다. 모델을 안 타므로
#   100% 재현된다. 픽스처를 리포에 커밋하지 않는 이유는, 한글 잔존 케이스를
#   `ja/` 에 심으면 check_docs_align.py 의 "en/ja 한글 잔류" 규칙이 정상 FAIL 을
#   내서 다른 스위트를 오염시키기 때문이다.
# Part B (실전) — 실제 번역 잡을 돌려 **연결부가 실제로 도는지** 본다. 모델이 이미
#   무공백을 내면 정규화는 발동하지 않지만, 그때도 판정("출력에 공백형이 없다")은
#   성립한다 — 이 e2e 가 지키려는 것은 기계장치가 아니라 **산출물의 성질**이다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-notation.sh                 # Part A + B
#   bash scripts/e2e-notation.sh --unit-only     # Part A 만 (모델 호출 없음)
#   bash scripts/e2e-notation.sh --keep
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-notation.sh
#
# 의존성: git, gh (로그인), python3
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-notation/$TS"
HEAD_BRANCH="translate-test-notation/$TS"
DOC="notation-sample.md"
CT_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
SCRATCH="$(mktemp -d)"
UNIT_ONLY=0; KEEP=0
for a in "$@"; do
  case "$a" in
    --unit-only) UNIT_ONLY=1 ;;
    --keep) KEEP=1 ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done

PASS=0; FAIL=0
ok()   { echo "  PASS  $*"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL  $*"; FAIL=$((FAIL+1)); }
step() { echo; echo "=== $* ==="; }

CHECK="$CT_DIR/translate/tools/notation_check.py"
# 워크트리에는 .venv 가 없다 (본 체크아웃 것을 쓴다). 순서대로 찾는다.
PY=""
for cand in "$CT_DIR/.venv/bin/python" "$HOME/works/cloud-translate/.venv/bin/python" "$(command -v python3)"; do
  [ -x "$cand" ] && PY="$cand" && break
done
[ -n "$PY" ] || { echo "python 을 찾지 못했다" >&2; exit 2; }
"$PY" -c 'import pydantic_settings' 2>/dev/null || \
  echo "  주의: $PY 에 pydantic_settings 가 없다 — Part B 는 실패한다"
[ -f "$CHECK" ] || { echo "notation_check.py 없음: $CHECK" >&2; exit 2; }

# ─────────────────────────────────────────────────────────────────────────
step "Part A — 규칙 (결정적, 모델 없음)"
mkdir -p "$SCRATCH/ja" "$SCRATCH/en"

# ja 픽스처. 앞 3줄이 `NotationSample` 의 무공백 관례를 세우고(근거 3회),
# 4번째 줄이 공백을 넣은 결함이다. 그 아래는 전부 **고치면 안 되는** 대조군.
cat > "$SCRATCH/ja/notation.md" <<'EOF'
NotationSampleサービスを使用します。
NotationSampleサービスの設定を確認します。
NotationSampleサービスの一覧を表示します。
この NotationSample サービスは対象です。
`NotationSample サービス` はコードなので保護されます。
[リンク](../ja/NotationSample サービス.md) もパスなので保護されます。
![画像](../static/images/이상탐지앱정보.png)
ConflictToken を使います。
ConflictToken を設定します。
ConflictToken を確認します。
NoEvidenceToken を作成します。
A が正しい場合に選択します。
EOF
# 기대값: 4번째 줄의 공백 하나만 사라진다. 나머지 바이트는 동일.
sed '4s/NotationSample サービス/NotationSampleサービス/' \
    "$SCRATCH/ja/notation.md" > "$SCRATCH/expected-ja.md"

cp "$SCRATCH/ja/notation.md" "$SCRATCH/ja/work.md"
"$PY" "$CHECK" "$SCRATCH/ja/work.md" --fix >/dev/null 2>&1 || true
if diff -q "$SCRATCH/ja/work.md" "$SCRATCH/expected-ja.md" >/dev/null; then
  ok "ja 공백 정규화가 기대 결과와 바이트 동일"
else
  bad "ja 공백 정규화 결과가 기대와 다르다"; diff "$SCRATCH/expected-ja.md" "$SCRATCH/ja/work.md" | head -12
fi

# 대조군을 개별로도 못 박는다 (위 diff 가 통과해도 이유를 남긴다).
grep -q '`NotationSample サービス` はコード' "$SCRATCH/ja/work.md" \
  && ok "인라인 코드 안 공백 보존" || bad "인라인 코드를 건드렸다"
grep -q 'NotationSample サービス.md' "$SCRATCH/ja/work.md" \
  && ok "링크 경로 안 공백 보존" || bad "링크 경로를 건드렸다"
grep -c 'ConflictToken を' "$SCRATCH/ja/work.md" | grep -q '^3$' \
  && ok "CONFLICT (문서가 공백 우세) 는 고치지 않는다" || bad "CONFLICT 를 고쳤다"
grep -q 'NoEvidenceToken を作成' "$SCRATCH/ja/work.md" \
  && ok "WEAK (문서 근거 없음) 은 고치지 않는다" || bad "WEAK 를 고쳤다"
grep -q 'A が正しい' "$SCRATCH/ja/work.md" \
  && ok "1글자 열거 기호는 대상이 아니다" || bad "1글자 토큰을 건드렸다"

# 멱등 — 한 번 더 돌려도 변화 없음
cp "$SCRATCH/ja/work.md" "$SCRATCH/ja/again.md"
"$PY" "$CHECK" "$SCRATCH/ja/again.md" --fix >/dev/null 2>&1 || true
diff -q "$SCRATCH/ja/work.md" "$SCRATCH/ja/again.md" >/dev/null \
  && ok "정규화는 멱등" || bad "두 번째 실행이 또 바꿨다"

# 한글 잔존 — 결함 3종과 정상 3종
cat > "$SCRATCH/en/hangul.md" <<'EOF'
On the details screen, select `변경` to change the value.
### 自体차단処理 { #custom-block-processing }
**[배포 상세 설定]**では、条件を追加できます。
![app](../static/images/quick-start/이상탐지앱정보.png)
[guide](../sdk/java.md#라이브러리-가져오기)
<!-- machine_translated: true 한글 -->
EOF
# notation_check 는 결함을 찾으면 exit 1 이라 pipefail 에 걸린다 — 출력만 쓴다.
"$PY" "$CHECK" "$SCRATCH/en/hangul.md" --json > "$SCRATCH/hangul.json" 2>/dev/null || true
RES="$("$PY" -c 'import json,sys; print(len(json.load(open(sys.argv[1]))[0]["hangul_residue"]))' "$SCRATCH/hangul.json")"
[ "$RES" = "3" ] && ok "한글 잔존 3건 검출 · 경로/주석 3건 제외 (검출=$RES)" \
                 || bad "한글 잔존 검출 수가 3이 아니다 (=$RES)"

if [ "$UNIT_ONLY" = "1" ]; then
  echo; echo "Part A 결과: PASS=$PASS FAIL=$FAIL"
  [ "$FAIL" = 0 ] && echo "NOTATION: OK" || echo "NOTATION: FAIL"
  rm -rf "$SCRATCH"; [ "$FAIL" = 0 ]; exit $?
fi

# ─────────────────────────────────────────────────────────────────────────
step "Part B — 실제 번역 잡 (연결부가 도는가)"
WORK="$SCRATCH/repo"
git clone -q --depth 1 --branch "$BASE_SOURCE" \
  "https://github.com/$REPO.git" "$WORK" 2>/dev/null || {
    echo "clone 실패" >&2; exit 2; }
cd "$WORK"
git checkout -q -b "$SESSION_BRANCH"

# 시드 — ja 가 `NotationSample` 을 무공백으로 쓰는 문서를 세션 base 에 심는다.
cat > "ko/$DOC" <<'EOF'
## NotationSample 개요 { #notation-sample-overview }

NotationSample 서비스를 사용합니다.
NotationSample 서비스의 설정을 확인합니다.
NotationSample 서비스의 목록을 표시합니다.
EOF
cat > "ja/$DOC" <<'EOF'
## NotationSample概要 { #notation-sample-overview }

NotationSampleサービスを使用します。
NotationSampleサービスの設定を確認します。
NotationSampleサービスの一覧を表示します。
EOF
cat > "en/$DOC" <<'EOF'
## NotationSample Overview { #notation-sample-overview }

Use the NotationSample service.
Check the NotationSample service settings.
Display the NotationSample service list.
EOF
git add "ko/$DOC" "ja/$DOC" "en/$DOC"
git -c user.email=e2e@local -c user.name=e2e commit -q -m "e2e(notation): 세션 시드"
git push -q origin "$SESSION_BRANCH"

# head — ko 에 문장 하나를 더해 그 유닛이 재번역되게 한다.
git checkout -q -b "$HEAD_BRANCH"
printf 'NotationSample 서비스의 상태를 새로 조회합니다.\n' >> "ko/$DOC"
git add "ko/$DOC"
git -c user.email=e2e@local -c user.name=e2e commit -q -m "test(notation): ko 문장 추가"
git push -q origin "$HEAD_BRANCH"
PR_URL="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "[e2e-notation $TS] ko 문장 추가" --body "e2e-notation.sh 자동 생성")"
echo "  ko PR: $PR_URL"

cd "$CT_DIR"
LOG="$SCRATCH/translate.log"
set +e
# e2e 는 CLI 엔진으로 돈다 — 배포 잡과 같은 엔진이어야 의미가 있다.
# 모델은 두 env 를 함께 준다: CLI 번역은 claude_code_model 을, llm-patch·표
# reconcile 은 anthropic_model 을 읽는다 (e2e-fence-noop-unit.sh 의 주석 참고).
TRANSLATE_TRANSLATE_ENGINE=claude-code \
TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
TRANSLATE_LOG_LEVEL=info \
  "$PY" translate/translate_pr.py "$PR_URL" \
    --diff-granularity block --glossary-mode service \
    --workers 2 --chunk-workers 2 --tm-top-k 1 > "$LOG" 2>&1
RC=$?
set -e
[ "$RC" = "0" ] && ok "번역 잡 성공 (exit 0)" || { bad "번역 잡 실패 (exit $RC)"; tail -25 "$LOG"; }
grep -q 'api\.anthropic\.com' "$LOG" && bad "api 엔진으로 돌았다 (CLI 여야 한다)" \
                                     || ok "CLI 엔진으로 실행됨"

TR_PR="$(gh pr list --repo "$REPO" --search "base:$HEAD_BRANCH" --state open \
          --json url -q '.[0].url' 2>/dev/null)"
if [ -n "$TR_PR" ]; then
  echo "  번역 PR: $TR_PR"
  OUT="$SCRATCH/out.md"
  gh pr diff "$TR_PR" --repo "$REPO" 2>/dev/null \
    | grep '^+' | grep -v '^+++' | sed 's/^+//' > "$OUT"
  # 가나·한글 범위는 grep 로케일에 따라 "Invalid collation character" 로 죽는다
  # (그러면 판정이 에러로 통과해 **절대 실패하지 않는 테스트**가 된다). 유니코드
  # 범위 판정은 python 으로 한다.
  SPACED="$("$PY" - "$OUT" <<'EOF'
import re, sys
t = open(sys.argv[1], encoding="utf-8", errors="replace").read()
hits = re.findall(r"NotationSample[ \t]+[\u3041-\u30fa\u4e00-\u9fff]", t)
print(len(hits))
EOF
)"
  if [ "$SPACED" = "0" ]; then
    ok "번역 산출물에 공백형이 없다 (문서 관례 유지)"
  else
    bad "번역 산출물에 공백형 'NotationSample <가나>' 가 $SPACED곳 남았다"
  fi
  HAN="$("$PY" - "$OUT" <<'EOF'
import re, sys
t = open(sys.argv[1], encoding="utf-8", errors="replace").read()
print(len(re.findall(r"[\uac00-\ud7a3]", t)))
EOF
)"
  [ "$HAN" = "0" ] && ok "산출물에 한글 잔존 없음" || bad "산출물에 한글이 $HAN자 남았다"
  if grep -q 'notation: ja 라틴↔가나 공백' "$LOG"; then
    echo "  (정규화가 실제로 발동: $(grep -c 'notation: ja' "$LOG")회 — 모델이 공백을 넣었다)"
  else
    echo "  (정규화 미발동 — 모델이 이미 무공백을 냈다. 판정은 산출물 성질이므로 유효)"
  fi
else
  bad "번역 PR 을 찾지 못했다"
fi

# ─────────────────────────────────────────────────────────────────────────
if [ "$KEEP" = "0" ]; then
  step "cleanup"
  [ -n "${TR_PR:-}" ] && gh pr close "$TR_PR" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  gh pr close "$PR_URL" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  git -C "$WORK" push -q origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  rm -rf "$SCRATCH"
fi

echo; echo "결과: PASS=$PASS FAIL=$FAIL"
# e2e-suite.sh 가 잡아가는 기계 판독 줄
[ "$FAIL" = 0 ] && echo "NOTATION: OK" || echo "NOTATION: FAIL"
[ "$FAIL" = 0 ]
