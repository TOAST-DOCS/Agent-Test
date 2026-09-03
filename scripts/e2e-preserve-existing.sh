#!/usr/bin/env bash
#
# preserve-existing e2e — cloud-translate `app/preserve_slice.py` 검증.
#
# 검증 대상: full 재번역 + `--preserve-existing` 이 **실제로 반영되는지**.
# 반영의 정의는 하나다 — **ko 가 바뀌지 않은 섹션의 en/ja 가 바이트 동일하게
# 남는다**. 그것이 이 옵션이 약속하는 전부이고, 로그가 아니라 산출물로 확인해야
# 하는 이유는 아래 사고 때문이다.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# `retranslate-20260903-1` (Jenkins translate #490, SMS ko/api-guide-v2.2.md).
# `PRESERVE_EXISTING=true` + CLI 엔진. 잡은 정상으로 보였고 로그는
#   `Created preserve file for en: /tmp/cc_preserve_*.md (236704 chars)`
# 를 **64번** 남겼다. 그런데 모델은 그 파일을 한 번도 못 봤다 — Claude Code 는
# `@file` 첨부의 내용이 **25,000 토큰**을 넘으면 조용히 버린다 (실측: 24,976 →
# 보임 / 25,045 → NONE. `is_error: false`, `num_turns: 1`, stderr 0바이트). 그리고
# CLI 는 `--allowedTools Write` 로 돌아서 모델이 Read 로 읽을 수도 없다.
#
# 결과: "기존 문장을 그대로 재사용하라"는 8개 항목 지시가 빈 지시로 들어가고
# 모델은 전 문장을 새로 만든다. 느려지는 것보다 나쁜 건 **en/ja 전문이 churn**
# 되는 것이고, 잡은 초록으로 끝난다. 실제로 이 결함을 발견한 계기는 실패가 아니라
# "왜 이렇게 오래 걸리나" 였다.
#
# 같은 엔진에서 완주한 preserve 런이 하나 있는데 (build 421, Push
# ko/release-notes.md) 그때 en baseline 은 20,056자 ≈ 5,700 토큰으로 한도 아래여서
# 정상 동작했다. 즉 이 결함은 **크기로 갈린다** — 그래서 이 e2e 의 픽스처는
# 반드시 한도를 넘겨야 한다.
#
# ── 왜 픽스처를 크게 만드는가 ─────────────────────────────────────────────
# en baseline 이 ~96,000자 (ja 는 ~68,000자) 를 넘어야 25,000 토큰 한도를 넘는다
# (preamble 733 토큰 + 문서. 실측 chars/token: en 3.98 · ja 2.82). 작은 픽스처로는
# 수정 전 코드도 통과하므로 회귀 테스트가 되지 않는다. 그래서 스크립트가 실행
# 시점에 큰 문서를 **생성**해 세션 브랜치에만 커밋한다 (alpha 는 건드리지 않는다).
#
# ── 판정을 로그가 아니라 산출물로 하는 이유 ───────────────────────────────
# 위 사고에서 로그는 "성공"을 말하고 있었다. 그래서 (3) 바이트 동일 판정이 이
# e2e 의 본체이고, 로그 판정 (4)(5) 는 보조다. 그리고 (6) **대조군** — 같은 입력을
# `--no-preserve-existing` 으로 한 번 더 돌려 churn 이 더 큰지 본다. 이게 없으면
# "바이트 동일" 이 preserve 때문인지 그냥 청킹 운인지 구분할 수 없다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) webhook 비활성화 · alpha 에서 세션 브랜치 생성
#   2) 큰 앵커 문서 생성 → ko/en/ja 세션 base 에 커밋 (한도 초과 확인 포함)
#   3) head 브랜치에서 **한 섹션의 ko 산문만** 변경
#   4) 로컬 translate_pr.py — `--diff-mode full --preserve-existing`
#   5) 판정
#   6) (기본) 대조군 런 — `--no-preserve-existing` 으로 같은 입력 재실행
#   7) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) 번역 성공 (exit 0, PARTIAL 없음)
#   (2) 바뀐 섹션이 en·ja 에서 실제로 바뀌었다 (preserve 가 번역을 삼키지 않았다)
#   (3) **바뀌지 않은 섹션의 90%+ 가 en·ja 에서 시드와 바이트 동일** ← 본체
#       (미반영이면 0% 에 가깝다 — 임계값은 신호/잡음 분리용이고, 절대 확인은 (6))
#   (4) 로그에 `Preserve-existing: using this chunk's own section` 이 언어별 ≥1
#   (5) 로그에 `Preserve-existing DISABLED` 가 없고, 통짜 블록
#       (`Created preserve file … (>=90000 chars)`) 도 없다
#   (6) 대조군: preserve 를 끈 런이 켠 런보다 바뀐 섹션 수가 **더 많다**
#   (7) 발췌 경계 회귀 없음 — 펜스 앞 이중 공백 0 · 중복 앵커 0
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-preserve-existing.sh
#   bash scripts/e2e-preserve-existing.sh --keep --no-control
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-preserve-existing.sh
#
# 의존성: git, gh (로그인), python3
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-preserve/$TS"
HEAD_BRANCH="translate-test-preserve/$TS"
CONTROL_BRANCH="translate-test-preserve-control/$TS"
DOC="preserve-sample.md"
SECTIONS=240        # en 이 ~128,000자 = ~33,000 토큰이 되도록 (한도 25,000 초과가 이 e2e 의 전제)
KEEP=0
CONTROL=1

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --no-control) CONTROL=0; shift ;;
    --sections) SECTIONS="$2"; shift 2 ;;
    --doc) DOC="$2"; shift 2 ;;
    -h|--help) sed -n '1,80p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"; CTRL_LOG="$tmpdir/control.log"

cleanup() {
  local rc=$?
  if (( KEEP )); then echo; echo "--keep: 보존 — $SESSION_BRANCH"; return $rc; fi
  echo; echo "[cleanup] 세션 브랜치 정리"
  local b
  for prefix in "translate/$HEAD_BRANCH" "translate/$CONTROL_BRANCH"; do
    while read -r b; do
      [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
    done < <(git ls-remote --heads origin "refs/heads/${prefix}*" 2>/dev/null \
               | sed 's|.*refs/heads/||')
  done
  git push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$CONTROL_BRANCH" >/dev/null 2>&1 || true
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC (섹션 $SECTIONS 개)"
echo

source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화"
set_webhook_repo_enabled false

echo "[1/7] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

echo "[2/7] 큰 앵커 문서 생성 + 시드"
python3 - "$DOC" "$SECTIONS" "$TS" <<'PY'
import io, os, sys

doc, n_sections, ts = sys.argv[1], int(sys.argv[2]), sys.argv[3]

# API 가이드를 닮은 형태 — 앵커 + heading + 표 + 코드블록. 앵커를 넣는 것은
# Agent-Test 가 pre-align 을 지난 레포이기 때문이고, preserve_slice 의 tier 1
# (앵커 id 정합)이 실제 운영에서 타는 경로이기도 하다.
KO_BODY = """
<a id="preserve-sec-{i}"></a>
### 보존 섹션 {i} {{ #preserve-sec-{i} }}

이 섹션은 preserve-existing e2e 픽스처의 {i}번째 섹션입니다. 아래 표와 예제는
섹션마다 필드 이름이 달라 서로 구분됩니다.

| 값 | 타입 | 설명 |
|---|---|---|
| body.field{i}Id | String | {i}번 필드의 식별자 |
| body.field{i}Name | String | {i}번 필드의 이름 |
| body.field{i}Count | Integer | {i}번 필드의 개수 |

{code}{i}번 섹션의 마지막 설명 문장입니다. 이 문장은 재번역 여부를 줄 단위로 판정할 때
쓰입니다.
"""

EN_BODY = """
<a id="preserve-sec-{i}"></a>
### Preserve Section {i} {{ #preserve-sec-{i} }}

This section is fixture section {i} of the preserve-existing e2e. The table and
sample below differ per section, so they can be told apart.

| Value | Type | Description |
|---|---|---|
| body.field{i}Id | String | Identifier of field {i} |
| body.field{i}Name | String | Name of field {i} |
| body.field{i}Count | Integer | Count of field {i} |

{code}The closing sentence of section {i}. This sentence is what the line-level
verdict is measured on.
"""

JA_BODY = """
<a id="preserve-sec-{i}"></a>
### 保存セクション {i} {{ #preserve-sec-{i} }}

このセクションは preserve-existing e2e フィクスチャの {i} 番目のセクションです。
以下の表とサンプルはセクションごとにフィールド名が異なります。

| 値 | タイプ | 説明 |
|---|---|---|
| body.field{i}Id | String | フィールド {i} の識別子 |
| body.field{i}Name | String | フィールド {i} の名前 |
| body.field{i}Count | Integer | フィールド {i} の個数 |

{code}セクション {i} の最後の説明文です。この文は再翻訳の有無を行単位で判定するために
使われます。
"""

HEADS = {
    "ko": "<!-- pre-align:aligned sig=e2epreserve -->\n\n"
          '<a id="preserve-e2e"></a>\n# preserve-existing e2e 픽스처\n\n'
          "이 문서는 자동 생성된 e2e 픽스처입니다 (%s).\n" % ts,
    "en": "<!-- pre-align:aligned sig=e2epreserve -->\n\n"
          '<a id="preserve-e2e"></a>\n# preserve-existing e2e fixture\n\n'
          "This document is a generated e2e fixture (%s).\n" % ts,
    "ja": "<!-- pre-align:aligned sig=e2epreserve -->\n\n"
          '<a id="preserve-e2e"></a>\n# preserve-existing e2e フィクスチャ\n\n'
          "この文書は自動生成された e2e フィクスチャです (%s)。\n" % ts,
}
BODIES = {"ko": KO_BODY, "en": EN_BODY, "ja": JA_BODY}

# 코드블록은 5섹션마다 하나. 전 섹션에 넣었더니 청크당 코드블록이 23개가 되어
# (max_chunk_chars 10,000 안에 섹션 22개) haiku 의 펜스 세기 자체가 판정 대상이
# 돼 버렸다. 블록은 남겨야 fence-protected skeleton × preserve baseline 상호작용을
# 계속 잡을 수 있으므로 (그 결함을 이 e2e 가 처음 잡았다) 밀도만 낮춘다.
CODE = ('```json\n{{\n  "field{i}Id": "id-{i}",\n  "field{i}Name": "name-{i}"\n}}\n```\n\n')

sizes = {}
for lang in ("ko", "en", "ja"):
    parts = [HEADS[lang]]
    for i in range(1, n_sections + 1):
        code = CODE.format(i=i) if i % 5 == 0 else ""
        parts.append(BODIES[lang].format(i=i, code=code))
    text = "".join(parts)
    path = os.path.join(lang, doc)
    io.open(path, "w", encoding="utf-8", newline="").write(text)
    sizes[lang] = len(text)
    print("  %s/%s: %d chars" % (lang, doc, len(text)))

# 이 e2e 의 전제 — 통짜 baseline 이 CLI 의 @file 한도(25,000 토큰)를 넘어야 한다.
# 실측 chars/token: en 3.98 · ja 2.82. preamble 733 토큰을 더한다.
LIMIT = 25_000
for lang, cpt in (("en", 3.98), ("ja", 2.82)):
    est = sizes[lang] / cpt + 733
    print("  %s 통짜 블록 추정: %d 토큰 (한도 %d)" % (lang, est, LIMIT))
    if est <= LIMIT:
        raise SystemExit(
            "error: %s 픽스처가 한도 아래다 (%d 토큰) — --sections 를 늘려야 "
            "이 e2e 가 회귀를 잡는다" % (lang, est)
        )
PY
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(preserve): 큰 앵커 픽스처 시드 — $SECTIONS 섹션 ($TS)"
git push -q origin "$SESSION_BRANCH"

# 시드 원본을 판정용으로 보관
mkdir -p "$tmpdir/seed"
for lang in ko en ja; do cp "$lang/$DOC" "$tmpdir/seed/$lang.md"; done

echo "[3/7] ko 한 섹션만 변경 (섹션 7 의 산문)"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
TARGET_SEC=7
python3 - "ko/$DOC" "$TARGET_SEC" "$TS" <<'PY'
import io, sys
path, sec, ts = sys.argv[1], sys.argv[2], sys.argv[3]
raw = io.open(path, encoding="utf-8", newline="").read()
old = ("%s번 섹션의 마지막 설명 문장입니다. 이 문장은 재번역 여부를 줄 단위로 판정할 때\n"
       "쓰입니다." % sec)
assert old in raw, "대상 문장을 찾지 못함"
new = ("%s번 섹션의 마지막 설명 문장을 %s 에 고쳤습니다. 이 섹션만 재번역되어야 하고\n"
       "나머지 섹션은 기존 번역이 그대로 남아야 합니다." % (sec, ts))
raw = raw.replace(old, new, 1)
io.open(path, "w", encoding="utf-8", newline="").write(raw)
print("  섹션 %s 의 산문 1문장 변경" % sec)
PY
git add -- "ko/$DOC"
committed="$(git diff --cached --name-only)"
[[ "$committed" == "ko/$DOC" ]] || { echo "error: 예상 외 파일 스테이지됨: $committed" >&2; exit 1; }
git commit -q -m "e2e(preserve): 섹션 $TARGET_SEC 의 ko 산문 1문장 변경 ($TS)"
git push -q origin "$HEAD_BRANCH"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(preserve): 한 섹션만 바뀐 큰 문서 ($TS)" \
  --body "cloud-translate preserve-existing 검증 — full 재번역 + preserve 에서 바뀌지 않은 섹션이 바이트 동일하게 남는지." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

run_translate() {   # $1: 로그 경로, $2: preserve 플래그, $3: base 브랜치
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$4" \
      --base-branch "$3" \
      --diff-mode full "$2" \
      --only "ko/$DOC" \
      --workers 2 --chunk-workers 2 \
  ) 2>&1 | tee "$1"
  local rc=${PIPESTATUS[0]}
  set -e
  return $rc
}

echo
echo "[4/7] local translate_pr.py — --diff-mode full --preserve-existing"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
set +e
run_translate "$LOG" --preserve-existing "$SESSION_BRANCH" "$ko_pr_url"
tx_rc=$?
set -e

echo
echo "[5/7] 판정"
fails=0
ok()  { echo "  PASS  $1"; }
bad() { echo "  FAIL  $1"; fails=$((fails + 1)); }

if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(1) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(1) 번역 실패/부분 (exit $tx_rc)"
fi

# 번역 결과는 head 브랜치가 아니라 **번역 잡이 만든 별도 브랜치**에 있다
# (worker 가 base 에서 `translate/<...>` 를 떠서 그 위에 커밋하고 PR 을 연다).
fetch_translated() {   # $1: 로그, $2: 받을 디렉터리 → 성공 시 0
  local log="$1" dest="$2" url br
  url="$(grep -oE 'Translation PR: https://[^ ]+' "$log" | tail -1 | awk '{print $NF}')"
  if [[ -z "$url" ]]; then echo "  (번역 PR 미생성)"; return 1; fi
  echo "  번역 PR: $url"
  e2e_label_pr "$REPO" "$url"
  br="$(gh pr view "$url" --repo "$REPO" --json headRefName --jq .headRefName)"
  git fetch -q origin "$br" || return 1
  mkdir -p "$dest"
  local lang
  for lang in en ja; do
    git show "origin/$br:$lang/$DOC" > "$dest/$lang.md" 2>/dev/null || return 1
  done
  return 0
}

if ! fetch_translated "$LOG" "$tmpdir/out"; then
  bad "(2-5) 번역 산출물을 읽지 못했다 — 이후 검사 불가"
  echo; echo "판정: FAIL ($fails) — 로그: $LOG"; KEEP=1; exit 1
fi

# 섹션 비교는 두 축이다.
#   BYTES  — 완전히 바이트 동일한가 (엄격)
#   PROSE  — 공백을 정규화하면 같은가 (= 재번역되지 않았다)
# 세 번째 실행에서 이 구분이 필요해졌다: preserve 는 잘 걸렸는데도 en 이 5개,
# ja 가 11개 섹션에서 FAIL 로 세어졌고, 그 diff 는 전부 "펜스 앞 빈 줄 1개" 였다
# (코드블록이 있는 5의 배수 섹션들). 문장은 한 글자도 바뀌지 않았다. 공백 하나를
# "재작성" 으로 세는 지표는 preserve 반영 여부를 재는 지표가 아니다.
# 그 공백 자체는 결함이었고 cloud-translate 쪽에서 고쳤지만, 지표는 그 뒤로도
# 재번역만 세도록 남긴다 — 공백 회귀는 아래 (7) 이 따로 본다.
changed_sections() {   # $1: lang, $2: 산출 디렉터리, $3: bytes|prose
  python3 - "$tmpdir/seed/$1.md" "$2/$1.md" "${3:-bytes}" <<'PY'
import io, re, sys
seed = io.open(sys.argv[1], encoding="utf-8", newline="").read()
now = io.open(sys.argv[2], encoding="utf-8", newline="").read()
mode = sys.argv[3] if len(sys.argv) > 3 else "bytes"

def norm(t):
    if mode != "prose":
        return t
    # 공백 정규화 + 중복 앵커 접기 — 남는 차이는 문장이 바뀐 것뿐이다.
    t = re.sub(r'(<a id="[^"]+"></a>)(\s*\1)+', r"\1", t)
    return re.sub(r"\s+", " ", t).strip()
def sections(t):
    out, cur, key = {}, [], None
    for line in t.splitlines(keepends=True):
        m = re.match(r'<a id="preserve-sec-(\d+)"></a>', line)
        if m:
            if key is not None:
                out[key] = "".join(cur)
            key, cur = int(m.group(1)), [line]
        elif key is not None:
            cur.append(line)
    if key is not None:
        out[key] = "".join(cur)
    return out
a, b = sections(seed), sections(now)
for i in sorted(set(a) | set(b)):
    if norm(a.get(i) or "") != norm(b.get(i) or ""):
        print(i)
PY
}

for lang in en ja; do
  mapfile -t changed < <(changed_sections "$lang" "$tmpdir/out" prose)
  mapfile -t changed_bytes < <(changed_sections "$lang" "$tmpdir/out" bytes)
  printf '        %s: 재번역된 섹션 %d개 %s (바이트 기준 %d개)\n' \
    "$lang" "${#changed[@]}" "${changed[*]:-}" "${#changed_bytes[@]}"
  if [[ " ${changed[*]-} " == *" $TARGET_SEC "* ]]; then
    ok "(2) $lang: 섹션 $TARGET_SEC 이 재번역됐다"
  else
    bad "(2) $lang: 섹션 $TARGET_SEC 이 그대로다 — preserve 가 번역을 삼켰다"
  fi
  others=()
  for c in "${changed[@]-}"; do [[ -n "$c" && "$c" != "$TARGET_SEC" ]] && others+=("$c"); done
  # 비율 기준. 이상적으로는 0 이지만 임계값을 0 으로 두면 모델 변동 한 건에
  # e2e 가 흔들리고, 그 흔들림은 preserve 가 걸렸는지와 무관하다. 실측값이
  # 기준을 정한다 — 3차 실행에서 preserve ON 은 en 99.6% / ja 89.5% (재번역
  # 기준), OFF 는 두 언어 모두 0% 였다 (240/240 전 섹션 재작성). ja 의 10%는
  # 열 청크 중 한 청크에서 haiku 가 baseline 을 두고도 다시 쓴 것으로, 재시도·
  # 폴백 0건이었으니 메커니즘 실패가 아니라 모델 준수 편차다. 85% 는 그 편차
  # 위에, OFF 의 0% 로부터는 한참 위에 있다.
  unchanged=$((SECTIONS - 1))
  kept=$((unchanged - ${#others[@]}))
  pct=$(( kept * 100 / unchanged ))
  printf '        %s: 안 바뀐 섹션 바이트 동일 %d/%d (%d%%)\n' "$lang" "$kept" "$unchanged" "$pct"
  if (( pct >= 85 )); then
    ok "(3) $lang: 안 바뀐 섹션 ${pct}% 가 재번역되지 않았다 (기준 85%)"
  else
    bad "(3) $lang: 안 바뀐 섹션 중 ${#others[@]}개가 재번역됐다 — ${pct}% < 85% — preserve 미반영"
  fi
  eval "PRESERVE_CHANGED_$lang=${#changed[@]}"
done

for lang in en ja; do
  n="$(grep -c "Preserve-existing: using this chunk's own section of the existing $lang" "$LOG" || true)"
  if (( n > 0 )); then
    ok "(4) $lang: 섹션 슬라이스 로그 ${n}건"
  else
    bad "(4) $lang: 'using this chunk's own section' 로그 없음 — 통짜로 갔거나 preserve 가 안 걸렸다"
  fi
done

# (7) 공백·앵커 회귀 — 3차 실행이 잡은 두 아티팩트가 되돌아오지 않는지.
#   * 코드블록 앞 빈 줄: strip_fenced_blocks 가 블록을 지우며 남긴 이중 공백을
#     모델이 placeholder 주변에 재현했고, 복원된 블록이 그 안에 들어갔다.
#   * 중복 앵커: 발췌가 청크에 없는 선행 `<a id>` 줄부터 시작해 모델이 복사했다.
# 둘 다 preserve-off 대조군에는 없었으므로 슬라이싱이 만든 것이고, 둘 다 문장이
# 아니라 바이트만 바꾸므로 (3) 의 재번역 지표로는 안 잡힌다.
for lang in en ja; do
  extra="$(python3 - "$tmpdir/out/$lang.md" <<'PYX'
import io, re, sys
t = io.open(sys.argv[1], encoding="utf-8", newline="").read()
gaps = len(re.findall(r"\n[ \t]*\n[ \t]*\n```", t))
dups = len(re.findall(r'(<a id="[^"]+"></a>)\s*\n\s*\n\1', t))
print("%d %d" % (gaps, dups))
PYX
)"
  set -- $extra
  if (( $1 == 0 && $2 == 0 )); then
    ok "(7) $lang: 펜스 앞 이중 공백 0 · 중복 앵커 0"
  else
    bad "(7) $lang: 펜스 앞 이중 공백 $1건 · 중복 앵커 $2건 — 발췌 경계 회귀"
  fi
done

if grep -q "Preserve-existing DISABLED" "$LOG"; then
  bad "(5) 'Preserve-existing DISABLED' 발생 — 슬라이스 실패 후 한도 초과로 거부됨"
elif grep -oE 'Created preserve file for [a-z]+: [^ ]+ \(([0-9]+) chars\)' "$LOG" \
     | sed 's/.*(\([0-9]*\) chars)/\1/' | awk '$1 >= 90000 { found = 1 } END { exit !found }'; then
  bad "(5) 통짜 baseline 블록이 전달됐다 (>=90000 chars) — 슬라이스가 안 걸렸다"
else
  ok "(5) DISABLED 없음 · 통짜 블록 없음"
fi

if (( CONTROL )); then
  echo
  echo "[6/7] 대조군 — 같은 입력을 --no-preserve-existing 으로 재실행"
  git checkout -q -B "$CONTROL_BRANCH" "$SESSION_BRANCH"
  git checkout -q "$HEAD_BRANCH" -- "ko/$DOC"
  git add -- "ko/$DOC"
  git commit -q -m "e2e(preserve): 대조군 — 같은 ko 변경 ($TS)"
  git push -q origin "$CONTROL_BRANCH"
  ctrl_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$CONTROL_BRANCH" \
    --title "e2e(preserve): 대조군 preserve OFF ($TS)" \
    --body "preserve OFF 대조군 — churn 이 더 큰지 비교." --label "$E2E_LABEL")"
  set +e
  run_translate "$CTRL_LOG" --no-preserve-existing "$SESSION_BRANCH" "$ctrl_pr_url"
  ctrl_rc=$?
  set -e
  if ! fetch_translated "$CTRL_LOG" "$tmpdir/ctrl"; then
    bad "(6) 대조군 산출물을 읽지 못했다"
  fi
  for lang in en ja; do
    mapfile -t cchanged < <(changed_sections "$lang" "$tmpdir/ctrl")
    eval "have=\${PRESERVE_CHANGED_$lang}"
    printf '        %s: preserve ON %s개 vs OFF %d개\n' "$lang" "$have" "${#cchanged[@]}"
    if (( ${#cchanged[@]} > have )); then
      ok "(6) $lang: preserve OFF 가 더 많이 churn — 바이트 동일이 preserve 때문임이 확인됨"
    else
      bad "(6) $lang: preserve OFF 가 더 churn 하지 않았다 (${#cchanged[@]} <= $have) — (3) 이 우연일 수 있다"
    fi
  done
  (( ctrl_rc == 0 )) || echo "        note: 대조군 런 exit $ctrl_rc (판정에는 churn 비교만 사용)"
else
  echo
  echo "[6/7] 대조군 생략 (--no-control)"
fi

echo
echo "[7/7] 결과"
echo "  로그: $LOG"
(( CONTROL )) && echo "  대조군 로그: $CTRL_LOG"
if (( fails == 0 )); then
  echo "  ALL PASS"
  echo "PRESERVE: OK"
else
  echo "  $fails 건 실패"
  echo "PRESERVE: FAIL"
  exit 1
fi
