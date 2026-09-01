#!/usr/bin/env bash
#
# 링크 대상 미러(M6) e2e — cloud-translate `app/link_edits.py` 수정 검증.
#
# 검증 대상: ko 가 **링크 대상만** 바꾼 줄은 재번역하지 않는다. 대상 언어가 이미
# 새 대상을 쓰고 있으면 그 줄은 **바이트 동일**로 남고, 아직 옛 대상이면 **링크
# 대상 안에서만** 치환된다. 위치를 특정할 수 없으면 오늘처럼 재번역한다.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# Container-Kubernetes#498 → 번역 PR #499 (2026-08-31 alpha 머지).
# ko PR 은 링크 정정 PR 이었고 en/ja 도 같이 고쳤다 (변경 파일 30개). 번역 잡이
# 돌 때 그 링크 18개(9줄 × en/ja)는 **이미 전부 맞는 값**이었는데, 파이프라인은
# 그 9개 유닛을 재번역했다. 얻은 링크 개선 0, 대신:
#   * `en/user-guide.md:3153` 에서 `can` 이 사라져 의미가 뒤집혔다
#     (可能 → 指示: "you can set the proxy protocol" → "you set …")
#   * `en/user-guide.md:3638` 의 링크 라벨이 대상 heading 과 어긋나게 재작성됐다
#     (`URI-based service routing` → `Diverging Service on URI`)
# 둘의 출처가 정확히 그 9줄 중 두 줄이다 (`ko/user-guide.md:3158`, `:3643`).
#
# ── 왜 결함 주입이 필요 없나 ──────────────────────────────────────────────
# e2e-fence-noop-unit.sh / e2e-docs-url-locale.sh 와 같은 이유. **수정 후** 동작이
# 결정적이다 — 미러가 걸리면 그 줄은 모델을 안 타므로 en/ja 가 바이트 동일하다.
# 수정 전에는 그 줄이 재번역되므로 (2)(4) 판정이 모델 변동에 따라 흔들리지만,
# 그 흔들림 자체가 이 e2e 가 없애려는 것이다. 판정 (6) 은 메커니즘 로그를 직접
# 보므로 수정 전에는 확정적으로 실패한다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성
#   2) **시드** — ko/en/ja 에 4개 섹션(케이스 A/B/C + 한글 대조군)을 세션 base 에
#      커밋. en/ja 의 A 는 **이미 새 대상**, B 는 **옛 대상**, C 는 **fully-qualified**
#   3) head 브랜치에서 ko 만 변경: A·B·C 는 fragment 하나씩, 대조군은 한글 한 문장
#   4) 로컬 translate_pr.py 실행 (`--base-branch <세션>` — old_ko 신호가 있어야
#      미러가 판정할 대상이 생긴다. 기본값인 head 를 쓰면 old_ko == new_ko 다)
#   5) 판정 (아래 8개 규칙)
#   6) cleanup
#
# ── 케이스와 기대 ─────────────────────────────────────────────────────────
#   A. site-root 링크, en/ja 가 **이미 새 fragment**  → 재사용: 문장 바이트 동일
#   B. site-root 링크, en/ja 가 **옛 fragment**       → 치환: fragment만 바뀌고
#                                                       나머지 바이트 동일
#   C. en/ja 가 **fully-qualified** 로 쓴 같은 링크    → 특정 실패 → 재번역
#                                                       (미러가 억지로 손대면 안 된다)
#   D. 한글 산문 한 문장 추가                          → 정상 번역
#      (미러가 번역을 삼키지 않는지 — 이 수정의 진짜 위험)
#
# 케이스마다 **자기 heading 섹션**을 준다. 한 섹션에 몰아넣으면 C 때문에 섹션이
# 재번역될 때 A·B 줄까지 함께 다시 쓰여 A·B 의 바이트 판정이 무의미해진다.
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) 번역 성공 (exit 0, PARTIAL 없음)
#   (2) A: en/ja 문장이 시드와 **바이트 동일** (재사용 — 모델을 안 탔다)
#   (3) B: en/ja 의 fragment 가 새 값 + 그 줄의 나머지 바이트가 시드와 동일
#   (4) A·B 의 링크 라벨이 재작성되지 않았다 (2·3 에 포함되나 실패 메시지 분리)
#   (5) D: 한글 대조군이 en/ja 에서 번역됨 (한글 잔류 없음)
#   (6) 로그의 `Link-target mirror` 라인이 처리 2줄 / 이미반영 1 / 치환 1 /
#       특정실패 1줄 을 보고한다 — 메커니즘 직접 확인
#   (7) C: en/ja 에 짝 불일치 docs URL 0건 + api-guide 링크 보존
#   (8) 번역 PR 본문에 `link-target mirror:` 요약 줄이 있다
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-link-target-mirror.sh
#   bash scripts/e2e-link-target-mirror.sh --keep
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-link-target-mirror.sh
#
# 의존성: git, gh (로그인), python3
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-linkmirror/$TS"
HEAD_BRANCH="translate-test-linkmirror/$TS"
DOC="overview.md"          # ko/en/ja 세 벌이 다 있는 작은 문서
KEEP=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    -h|--help) sed -n '1,80p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"; LOG="$tmpdir/translate.log"

cleanup() {
  local rc=$?
  if (( KEEP )); then echo; echo "--keep: 보존 — $SESSION_BRANCH"; return $rc; fi
  echo; echo "[cleanup] 세션 브랜치 정리"
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/translate/$HEAD_BRANCH*" 2>/dev/null \
             | sed 's|.*refs/heads/||')
  git push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

SLUG="Security/Secure%20Key%20Manager"
OLD_A="#e2e-mirror-old-a"; NEW_A="#e2e-mirror-new-a"
OLD_B="#e2e-mirror-old-b"; NEW_B="#e2e-mirror-new-b"
OLD_C="#e2e-mirror-old-c"; NEW_C="#e2e-mirror-new-c"

# 판정에서 **문자열 그대로** 비교할 문장들. 한 줄씩 유지한다 (줄 단위 판정이라
# 여러 줄로 쪼개면 무엇이 바뀌었는지 가려진다).
A_EN="To create an encrypted volume, first [create a key store](/${SLUG}/en/getting-started/${NEW_A}) in the console."
A_JA="暗号化ボリュームを作成するには、まずコンソールで[キーストアを作成](/${SLUG}/ja/getting-started/${NEW_A})します。"
B_EN="For console usage, see the [console guide](/${SLUG}/en/console-guide/${OLD_B})."
B_JA="コンソールの使い方は[コンソールガイド](/${SLUG}/ja/console-guide/${OLD_B})を参照してください。"
C_EN="For the API, see the [API guide](https://docs.nhncloud.com/en/${SLUG}/en/api-guide/${OLD_C})."
C_JA="APIは[APIガイド](https://docs.nhncloud.com/ja/${SLUG}/ja/api-guide/${OLD_C})を参照してください。"

fixture_ko() {  # $1,$2,$3: A/B/C fragment
  cat <<EOF

<a id="e2e-mirror-reuse"></a>
### 미러 케이스 A 재사용

암호화 볼륨을 만들려면 먼저 콘솔에서 [키 저장소를 생성](/${SLUG}/ko/getting-started/$1)합니다.

<a id="e2e-mirror-substitute"></a>
### 미러 케이스 B 치환

콘솔 사용법은 [콘솔 가이드](/${SLUG}/ko/console-guide/$2)를 참고합니다.

<a id="e2e-mirror-giveup"></a>
### 미러 케이스 C 특정 실패

API는 [API 가이드](/${SLUG}/ko/api-guide/$3)를 참고합니다.

<a id="e2e-mirror-control"></a>
### 미러 대조군

이 섹션은 링크가 없는 산문 대조군입니다.
EOF
}

fixture_en() {
  cat <<EOF

<a id="e2e-mirror-reuse"></a>
### Mirror Case A Reuse

${A_EN}

<a id="e2e-mirror-substitute"></a>
### Mirror Case B Substitution

${B_EN}

<a id="e2e-mirror-giveup"></a>
### Mirror Case C Unlocatable

${C_EN}

<a id="e2e-mirror-control"></a>
### Mirror Control

This section is a link-free prose control.
EOF
}

fixture_ja() {
  cat <<EOF

<a id="e2e-mirror-reuse"></a>
### ミラーケースA 再利用

${A_JA}

<a id="e2e-mirror-substitute"></a>
### ミラーケースB 置換

${B_JA}

<a id="e2e-mirror-giveup"></a>
### ミラーケースC 特定失敗

${C_JA}

<a id="e2e-mirror-control"></a>
### ミラー対照群

このセクションはリンクのない散文の対照群です。
EOF
}

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC"
echo

# ── 0) webhook 비활성화 ───────────────────────────────────────────────────
# 실제 PR 을 만들므로 배포된 webhook pod 가 같은 PR 로 Jenkins 잡을 중복
# 트리거하지 않게 끈다 (e2e-docs-url-locale.sh 와 같은 이유).
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화"
set_webhook_repo_enabled false

echo "[1/6] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

echo "[2/6] 시드 — A(이미 새 대상) · B(옛 대상) · C(fully-qualified) · 대조군"
for lang in ko en ja; do
  [[ -f "$lang/$DOC" ]] || { echo "error: $lang/$DOC 없음" >&2; exit 1; }
done
# ko 는 세 케이스 모두 **옛** fragment 로 시작한다. A 의 en/ja 만 새 값으로
# 심는 것이 #498 의 상태 재현이다 (ko PR 이 en/ja 를 먼저 고쳐 둔 모양).
fixture_ko "$OLD_A" "$OLD_B" "$OLD_C" >> "ko/$DOC"
fixture_en >> "en/$DOC"
fixture_ja >> "ja/$DOC"
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(link-mirror): ko/en/ja 에 링크 대상 미러 픽스처 시드 ($TS)"
git push -q origin "$SESSION_BRANCH"

echo "[3/6] ko 변경 — A·B·C 는 fragment 만, 대조군은 한글 한 문장"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" "$OLD_A" "$NEW_A" "$OLD_B" "$NEW_B" "$OLD_C" "$NEW_C" "$TS" <<'PY'
import io, sys
path, old_a, new_a, old_b, new_b, old_c, new_c, ts = sys.argv[1:9]
raw = io.open(path, encoding="utf-8", newline="").read()
for old, new in ((old_a, new_a), (old_b, new_b), (old_c, new_c)):
    assert old in raw, f"시드된 fragment 를 찾지 못함: {old}"
    raw = raw.replace(f"/{old})", f"/{new})")
    assert new in raw
# 대조군: 링크가 없는 섹션에 한글 한 문장. 미러가 번역을 삼키면 여기서 잡힌다.
marker = f"\n\n이 문장은 번역 대조군입니다 ({ts})."
i = raw.rindex("이 섹션은 링크가 없는 산문 대조군입니다.") + len(
    "이 섹션은 링크가 없는 산문 대조군입니다.")
raw = raw[:i] + marker + raw[i:]
io.open(path, "w", encoding="utf-8", newline="").write(raw)
print("  변경: fragment 3개 + 대조군 1문장")
PY
git add -- "ko/$DOC"
committed="$(git diff --cached --name-only)"
[[ "$committed" == "ko/$DOC" ]] || { echo "error: 예상 외 파일 스테이지됨: $committed" >&2; exit 1; }
git commit -q -m "e2e(link-mirror): 링크 fragment 3개 변경 + 산문 대조군 ($TS)"
git push -q origin "$HEAD_BRANCH"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(link-mirror): 링크 대상만 바뀐 줄 ($TS)" \
  --body "cloud-translate link-target 미러(M6) 검증 — 링크 대상만 바뀐 ko 줄이 재번역되지 않고, 이미 맞는 대상은 그대로, 옛 대상은 링크 대상 안에서만 치환되는지." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

echo
echo "[4/6] local translate_pr.py (--base-branch $SESSION_BRANCH)"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_TRANSLATE_ENGINE=claude-code \
  TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
  TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --base-branch "$SESSION_BRANCH" \
    --diff-granularity block --glossary-mode service \
    --workers 2 --chunk-workers 2 --tm-top-k 1 \
) 2>&1 | tee "$LOG"
tx_rc=${PIPESTATUS[0]}
set -e

echo
echo "[5/6] 판정"
fails=0
ok()  { echo "  PASS  $1"; }
bad() { echo "  FAIL  $1"; fails=$((fails + 1)); }

if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(1) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(1) 번역 실패/부분 (exit $tx_rc)"
fi

# (6) 메커니즘 로그 — 수정 전에는 이 라인이 아예 없다.
#     measure 모드 dry-run 에서도 한 번 나오므로 언어별 ≥1 건이 정상.
for lang in en ja; do
  line="$(grep -oE "Link-target mirror \($lang\): [0-9]+ ko line\(s\)[^|]*" "$LOG" | tail -1)"
  if [[ -z "$line" ]]; then
    bad "(6) $lang: 'Link-target mirror' 로그 없음 — 미러가 걸리지 않았다"
    continue
  fi
  echo "        $line"
  if [[ "$line" == *"2 ko line(s)"* && "$line" == *"1 link(s) already correct"* \
        && "$line" == *"1 substituted"* && "$line" == *"1 line(s) left to the splice"* ]]; then
    ok "(6) $lang: 처리 2줄 · 이미반영 1 · 치환 1 · 특정실패 1줄"
  else
    bad "(6) $lang: 미러 집계가 기대와 다름 (A 재사용 1 / B 치환 1 / C 포기 1)"
  fi
done

tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
if [[ -z "$tx_pr_url" ]]; then
  bad "(2-8) 번역 PR 미생성 — 이후 검사 불가"
  echo; echo "판정: FAIL ($fails) — 로그: $LOG"; KEEP=1; exit 1
fi
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url"

tx_branch="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_branch"
for lang in en ja; do
  git show "origin/$tx_branch:$lang/$DOC" > "$tmpdir/$lang.md" 2>/dev/null \
    || bad "(2) $lang/$DOC 를 번역 브랜치에서 못 읽음"
done

A_EN="$A_EN" A_JA="$A_JA" B_EN="$B_EN" B_JA="$B_JA" \
OLD_B="$OLD_B" NEW_B="$NEW_B" OLD_C="$OLD_C" \
python3 - "$tmpdir" <<'PY' || fails=$((fails + 1))
import io, os, re, sys, pathlib
tmp = sys.argv[1]
DOCS = re.compile(r'https?://docs\.[a-z0-9.-]*nhncloud\.com/[^\s)"\'<>\]]*')
seeds = {
    "en": (os.environ["A_EN"], os.environ["B_EN"]),
    "ja": (os.environ["A_JA"], os.environ["B_JA"]),
}
old_b, new_b, old_c = os.environ["OLD_B"], os.environ["NEW_B"], os.environ["OLD_C"]
rc = 0
for lang, (a_seed, b_seed) in seeds.items():
    p = pathlib.Path(f"{tmp}/{lang}.md")
    if not p.exists():
        continue
    t = io.open(p, encoding="utf-8", newline="").read()

    # (2) A — 이미 맞는 대상이므로 문장이 바이트 동일해야 한다 (모델 미경유).
    if a_seed in t:
        print(f"  PASS  (2) {lang} 케이스 A 문장 바이트 동일 (재사용)")
    else:
        print(f"  FAIL  (2) {lang} 케이스 A 문장이 다시 쓰였다")
        print("        기대:", a_seed)
        for ln in t.splitlines():
            if "getting-started" in ln:
                print("        실제:", ln.strip())
        rc = 1

    # (3) B — fragment 만 새 값으로, 나머지는 시드 그대로.
    want_b = b_seed.replace(old_b, new_b)
    if want_b in t:
        print(f"  PASS  (3) {lang} 케이스 B fragment 치환 + 나머지 바이트 동일")
    else:
        print(f"  FAIL  (3) {lang} 케이스 B 가 치환이 아니라 재작성됐다")
        print("        기대:", want_b)
        for ln in t.splitlines():
            if "console-guide" in ln:
                print("        실제:", ln.strip())
        rc = 1

    # (4) 라벨 보존 — (2)(3) 에 포함되지만 실패 원인을 분리해 보여준다.
    missing = [lbl for lbl in
               (re.search(r'\[([^\]]+)\]\(', s).group(1) for s in (a_seed, want_b))
               if lbl not in t]
    if missing:
        for lbl in missing:
            print(f"  FAIL  (4) {lang} 링크 라벨이 재작성됐다 — 기대 '{lbl}'")
        rc = 1
    else:
        print(f"  PASS  (4) {lang} A·B 링크 라벨 보존")

    # (7) C — 미러가 포기한 줄이다. 억지로 손대 짝 불일치를 만들면 안 되고,
    #     링크 자체는 남아 있어야 한다.
    mismatched = []
    for m in DOCS.finditer(t):
        url = m.group(0)
        path = url.split(".com", 1)[1].split("#")[0].split("?")[0]
        locales = [s for s in path.split("/") if s in ("ko", "en", "ja")]
        if len(set(locales)) > 1:
            mismatched.append(url)
    if mismatched:
        print(f"  FAIL  (7) {lang} 짝 불일치 docs URL {len(mismatched)}건")
        for u in mismatched[:3]:
            print("        ", u)
        rc = 1
    elif "api-guide" not in t:
        print(f"  FAIL  (7) {lang} 케이스 C 의 api-guide 링크가 사라졌다"); rc = 1
    else:
        print(f"  PASS  (7) {lang} 케이스 C 짝 불일치 0건 · 링크 보존")
raise SystemExit(rc)
PY

# (5) 대조군 — 한글이 남아 있으면 미러가 번역을 삼킨 것이다.
for lang in en ja; do
  if grep -q '대조군' "$tmpdir/$lang.md" 2>/dev/null; then
    bad "(5) $lang 에 한글 '대조군' 잔류 — 산문이 번역되지 않았다"
    grep -n '대조군' "$tmpdir/$lang.md" | head -3 | sed 's/^/        /'
  else
    ok "(5) $lang 대조군 산문이 번역됨 (한글 잔류 없음)"
  fi
done

# (8) 요약 코멘트 — 리뷰어가 "왜 이 줄은 재번역되지 않았나" 를 볼 수 있어야 한다.
#     **본문(body)이 아니라 코멘트다.** 본문의 '이 PR 의 ko 변경분과 무관한 표
#     수리' 섹션은 리뷰어(=ko PR 작성자)의 diff 밖에서 일어난 변경을 알리는
#     자리인데, 미러는 정의상 리뷰어 자신의 ko 줄에 대응하는 링크 대상만
#     건드리므로 그 기준에 해당하지 않는다. 유닛별 내역(재번역 N/M)과 같은
#     자리에 두는 것이 맞다 — `_build_summary_comment` 의 'Translated
#     sections/blocks' 아래.
pr_num="${tx_pr_url##*/}"
if gh api "repos/$REPO/issues/$pr_num/comments" --jq '.[].body' \
     | grep -q 'link-target mirror:'; then
  n_lang="$(gh api "repos/$REPO/issues/$pr_num/comments" --jq '.[].body' \
              | grep -c 'link-target mirror:')"
  if (( n_lang >= 2 )); then
    ok "(8) 요약 코멘트에 link-target mirror 줄 ${n_lang}건 (en·ja)"
  else
    bad "(8) 요약 코멘트의 link-target mirror 줄이 ${n_lang}건 — en·ja 둘 다 필요"
  fi
else
  bad "(8) 요약 코멘트에 link-target mirror 요약 줄 없음"
fi

echo
echo "[6/6] 결과"
if (( fails == 0 )); then
  echo "  PASS — 링크 대상만 바뀐 줄이 재번역되지 않았고, 치환은 대상 안에서만 일어났다 (로그: $LOG)"
  exit 0
fi
echo "  FAIL — $fails 개 규칙 실패 (로그: $LOG)"
KEEP=1
exit 1
