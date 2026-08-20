#!/usr/bin/env bash
#
# 번역할 게 없는 코드블록 유닛 e2e — cloud-translate PR #595 검증.
#
# 검증 대상: 코드블록 뒤에 마크업 한 줄이 빈 줄 없이 붙은 유닛(= 번역할 문자 0)
# 은 모델을 거치지 않고 바이트 그대로 복사된다.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# Storage-Object-Storage#182. mkdocs 마이그레이션 PR 이 코드블록 **안의** URL 을
# 템플릿 변수로 바꿨다:
#     -https://api-identity-infrastructure.nhncloudservice.com/v2.0/tokens \
#     +$[ identity_url ]$/v2.0/tokens \
# 그 유닛은 한글이 0자고 코드 밖 텍스트는 `</details>` 뿐이라 번역할 게 없는데,
# translate() 의 두 verbatim 지름길 사이로 빠져(코드 본문이 있어 markup-only 가
# 아니고, 뒤에 태그가 붙어 단일 펜스 블록도 아님) 모델을 두 번 호출했다.
# 두 번째 호출에서 모델이 여는 ``` 를 떨구면 펜스 패리티 가드가 결과를 거부한다
# — 실제로 8개 파일 번역이 통째로 날아갔다.
#
# ── 왜 이 e2e 는 결함 주입이 필요 없나 ─────────────────────────────────────
# e2e-file-fail-isolation.sh 와 대조적으로, 여기서 검증하는 것은 **결정적** 이다.
# 수정 전 동작(모델 호출 → 확률적 펜스 유실)은 재현이 안 되지만, 수정 후 동작
# ("모델을 아예 안 부르고 바이트 복사")은 100% 관측 가능하다. 그래서 실제 픽스처를
# 심고 결과가 바이트 동일한지만 보면 된다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성
#   2) **시드** — ko/en/ja 에 동일한 <details> 코드블록을 붙여 세션 base 에 커밋
#      (기존 번역이 이미 그 블록을 갖고 있는 #182 상태를 만든다)
#   3) head 브랜치에서 **ko 블록 안의 URL 만** 변경 → PR
#   4) 로컬 translate_pr.py 실행 (TRANSLATE_LOG_LEVEL=debug)
#   5) 판정 (아래 6개 규칙)
#   6) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) 번역 성공 (exit 0, PARTIAL 없음)
#   (2) 로그에 "skipping the model call" — 모델을 안 불렀다는 직접 증거
#   (3) en/ja 코드블록이 ko 와 **바이트 동일** (= 변경된 URL 이 그대로 반영)
#   (4) 펜스 마커 수 보존
#   (5) `</details>` 보존
#   (6) 같은 파일의 한글 산문 변경은 **정상 번역** (가드가 과하게 걸려 번역을
#       삼키지 않는지 — 이게 이 수정의 진짜 위험이다)
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-fence-noop-unit.sh
#   bash scripts/e2e-fence-noop-unit.sh --keep
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-fence-noop-unit.sh
#
# 의존성: git, gh (로그인), python3
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-fencenoop/$TS"
HEAD_BRANCH="translate-test-fencenoop/$TS"
DOC="overview.md"          # ko/en/ja 세 벌이 다 있는 작은 문서
KEEP=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    -h|--help) sed -n '1,50p' "$0"; exit 0 ;;
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

OLD_URL="https://api-identity-infrastructure.nhncloudservice.com"
NEW_URL='$[ identity_url ]$'

# 픽스처 — #182 의 모양 그대로: <summary> 뒤 빈 줄, 닫는 펜스 뒤 `</details>` 는
# 빈 줄 **없이** 붙는다. 한글은 0자.
fixture() {   # $1: URL
  cat <<EOF

<a id="e2e-fence-noop"></a>
### Token issuance sample

<details>
<summary>cURL</summary>

\`\`\`
\$ curl -X POST -H 'Content-Type: application/json' \\
$1/v2.0/tokens \\
-d '{"auth": {"tenantId": "6dbc368b", "passwordCredentials": {"username": "*****"}}}'

{
  "access": {
    "token": { "id": "b587ae461278419da6ecd21a2344c8aa" }
  }
}
\`\`\`
</details>
EOF
}

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC"
echo

# ── 1) 세션 브랜치 ────────────────────────────────────────────────────────
echo "[1/6] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

# ── 2) 시드: ko/en/ja 에 동일 블록 ────────────────────────────────────────
echo "[2/6] 시드 — ko/en/ja 에 동일한 <details> 블록 추가 (#182 상태 조성)"
for lang in ko en ja; do
  [[ -f "$lang/$DOC" ]] || { echo "error: $lang/$DOC 없음" >&2; exit 1; }
  fixture "$OLD_URL" >> "$lang/$DOC"
  echo "  시드: $lang/$DOC"
done
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(fence-noop): ko/en/ja 에 동일한 <details> 코드블록 시드 ($TS)"
git push -q origin "$SESSION_BRANCH"

# ── 3) ko 변경: 코드블록 안 URL + 한글 산문 1줄 ───────────────────────────
echo "[3/6] ko 변경 — 코드블록 안 URL + (대조군) 한글 산문 1줄"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" "$OLD_URL" "$NEW_URL" "$TS" <<'PY'
import io, sys
path, old, new, ts = sys.argv[1:5]
raw = io.open(path, encoding="utf-8", newline="").read()
assert old in raw, "시드된 URL 을 찾지 못함"
raw = raw.replace(old, new)          # 코드블록 **안** 변경 — 번역 대상 0
# 대조군: 코드블록 밖 한글 산문 한 줄. 가드가 과하게 걸려 번역을 삼키면 여기서 잡힌다.
eol = "\r\n" if "\r\n" in raw else "\n"
lines = raw.split(eol)
for i, ln in enumerate(lines):
    s = ln.strip()
    if s and not s.startswith(("#", "<", "|", "```", "!!!", "-", "*", ">", "$")):
        lines[i] = ln.rstrip() + f" (fence-noop 대조군 {ts})"
        break
else:
    raise SystemExit("prose line not found")
io.open(path, "w", encoding="utf-8", newline="").write(eol.join(lines))
print(f"  변경: {path} (코드블록 내 URL + 산문 1줄)")
PY
git add -- "ko/$DOC"
committed="$(git diff --cached --name-only)"
[[ "$committed" == "ko/$DOC" ]] || { echo "error: 예상 외 파일 스테이지됨: $committed" >&2; exit 1; }
git commit -q -m "e2e(fence-noop): 코드블록 안 URL 을 템플릿 변수로 ($TS)"
git push -q origin "$HEAD_BRANCH"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(fence-noop): 코드블록 안 URL 변경 ($TS)" \
  --body "cloud-translate #595 검증 — 번역할 게 없는 코드블록 유닛이 모델을 거치지 않고 바이트 복사되는지." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

# ── 4) 번역 (debug 로그) ──────────────────────────────────────────────────
echo
echo "[4/6] local translate_pr.py (TRANSLATE_LOG_LEVEL=debug)"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_TRANSLATE_ENGINE=api \
  TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
  TRANSLATE_LOG_LEVEL=debug \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --diff-granularity block --glossary-mode service \
    --workers 2 --chunk-workers 2 --tm-top-k 1 \
) 2>&1 | tee "$LOG"
tx_rc=${PIPESTATUS[0]}
set -e

# ── 5) 판정 ───────────────────────────────────────────────────────────────
echo
echo "[5/6] 판정"
fails=0
ok()  { echo "  PASS  $1"; }
bad() { echo "  FAIL  $1"; fails=$((fails + 1)); }

if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(1) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(1) 번역 실패/부분 (exit $tx_rc) — 수정 전 동작 재현"
fi

if grep -q "skipping the model call" "$LOG"; then
  n="$(grep -c "skipping the model call" "$LOG")"
  ok "(2) 모델 호출 생략 로그 ${n}건"
else
  bad "(2) 'skipping the model call' 로그 없음 — 유닛이 모델을 거쳤다"
fi

tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
if [[ -z "$tx_pr_url" ]]; then
  bad "(3-6) 번역 PR 미생성 — 이후 검사 불가"
  echo; echo "판정: FAIL ($fails) — 로그: $LOG"; KEEP=1; exit 1
fi
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url"

tx_branch="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_branch"
for lang in en ja; do
  git show "origin/$tx_branch:$lang/$DOC" > "$tmpdir/$lang.md" 2>/dev/null || {
    bad "(3) $lang/$DOC 를 번역 브랜치에서 못 읽음"; continue; }
done
git show "origin/$HEAD_BRANCH:ko/$DOC" > "$tmpdir/ko.md"

python3 - "$tmpdir" "$NEW_URL" <<'PY' || fails=$((fails + 1))
import io, re, sys, pathlib
tmp, new_url = sys.argv[1], sys.argv[2]
def block(p):
    t = io.open(p, encoding="utf-8", newline="").read()
    m = re.search(r"<summary>cURL</summary>\n\n(```.*?```\n</details>)", t, re.S)
    return m.group(1) if m else None
ko = block(f"{tmp}/ko.md")
if ko is None:
    print("  FAIL  (3) ko 에서 픽스처 블록을 못 찾음"); raise SystemExit(1)
rc = 0
for lang in ("en", "ja"):
    p = pathlib.Path(f"{tmp}/{lang}.md")
    if not p.exists():
        continue
    b = block(p)
    if b is None:
        print(f"  FAIL  (3) {lang} 에서 픽스처 블록을 못 찾음"); rc = 1; continue
    if b == ko:
        print(f"  PASS  (3) {lang} 코드블록이 ko 와 바이트 동일")
    else:
        print(f"  FAIL  (3) {lang} 코드블록이 ko 와 다름")
        import difflib
        for l in list(difflib.unified_diff(ko.splitlines(), b.splitlines(),
                                           "ko", lang, lineterm=""))[:14]:
            print("        " + l)
        rc = 1
    if new_url in b:
        print(f"  PASS  (3b) {lang} 에 변경된 URL 반영")
    else:
        print(f"  FAIL  (3b) {lang} 에 변경된 URL 없음"); rc = 1
    if b.count("```") == ko.count("```") == 2:
        print(f"  PASS  (4) {lang} 펜스 마커 2개 보존")
    else:
        print(f"  FAIL  (4) {lang} 펜스 마커 {b.count('```')}개"); rc = 1
    if "</details>" in b:
        print(f"  PASS  (5) {lang} </details> 보존")
    else:
        print(f"  FAIL  (5) {lang} </details> 유실"); rc = 1
raise SystemExit(rc)
PY

# (6) 대조군 — 한글 산문 변경이 실제로 번역됐는지. 가드가 과하게 걸려 번역을
#     삼키는 것이 이 수정의 진짜 위험이므로 반드시 확인한다.
# 마커의 **한글** 부분("대조군")만 본다. 슬러그 `fence-noop` 으로 찾으면 안 된다 —
# 그건 세 언어에 다 시드한 앵커 id(`<a id="e2e-fence-noop">`) 에도 들어 있어서
# 번역이 잘 됐어도 항상 걸린다 (초판에서 실제로 오탐).
if grep -q '대조군' "$tmpdir/en.md" 2>/dev/null; then
  bad "(6) en 에 한글 '대조군' 잔류 — 산문이 번역되지 않았다"
  grep -n '대조군' "$tmpdir/en.md" | head -3 | sed 's/^/        /'
else
  ok "(6) 대조군 산문이 en 에서 번역됨 (한글 잔류 없음)"
fi

echo
echo "[6/6] 결과"
if (( fails == 0 )); then
  echo "  PASS — 번역할 게 없는 코드블록 유닛이 모델 없이 바이트 복사됨 (로그: $LOG)"
  exit 0
fi
echo "  FAIL — $fails 개 규칙 실패 (로그: $LOG)"
KEEP=1
exit 1
