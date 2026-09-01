#!/usr/bin/env bash
#
# 배포 docs 절대 URL 의 로케일 e2e — cloud-translate `rewrite_links` 수정 검증.
#
# 검증 대상: ko 문서가 `https://docs.nhncloud.com/ko/{slug}/ko/{stem}/#a` 형태의
# **절대** 배포 URL 을 쓸 때, 번역본은 두 로케일 자리를 **모두** 자기 언어로 옮긴
# 링크를 가져야 한다. 그리고 어떤 경우에도 두 자리가 **서로 다른** 링크를 만들어
# 내면 안 된다.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# Storage-Online-NAS#97 → 번역 PR #98 (2026-08-31 alpha 머지).
# ko 는 Secure Key Manager 링크의 **fragment 만** 고쳤다
# (`#_1` → `#create-a-key-store`). 그 문단이 재번역되면서 en/ja 가 ko 의 절대
# URL 을 그대로 복사해, en 3파일 · ja 3파일에서 12개 링크가
# `docs.nhncloud.com/ko/…/ko/…` 가 됐다 — 영어/일본어 독자가 한국어 페이지로
# 떨어진다. 페이지는 HTTP 200 이라 `/link-check` 의 status 축으로는 안 잡힌다.
#
# 원인은 `translate/app/postprocess.py :: rewrite_links` 하나이고 결함이 둘이다:
#   (A) 로케일 치환 규칙이 `http(s)` 가 든 링크를 통째로 건너뛴다 → ko 유지
#   (B) "외부 URL 복원" 패스가 docs 호스트를 예외로 두지 않아, 모델이 **올바른**
#       en URL 을 만들어 와도 뒷자리를 ko 로 되돌린다 → `/en/…/ko/…` 짝 불일치.
#       짝이 어긋나면 NHN Cloud 랜딩 페이지가 200 으로 떠서 **status code 로
#       판별 불가능한 죽은 링크**가 된다 ([[toast-docs-menu-structure]] 로케일 규칙).
# (B) 가 (A) 보다 나쁘다 — 그래서 판정 (4) 가 이 e2e 의 핵심이다.
#
# ── 왜 결함 주입이 필요 없나 ──────────────────────────────────────────────
# e2e-fence-noop-unit.sh 와 같은 이유. 수정 전 동작은 **결정적**이다: ko 절대
# URL 이 든 유닛이 재번역되기만 하면 (A) 는 100% 재현된다. 모델 변동에 기대지
# 않는다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성
#   2) **시드** — ko/en/ja 에 링크 4종을 심어 세션 base 에 커밋.
#      en/ja 의 절대 docs URL 은 **이미 올바른** en/ja 로 심는다 (실제 상태이고,
#      (B) 가 그것을 되돌리는지 보려면 정답에서 출발해야 한다)
#   3) head 브랜치에서 **ko 의 fragment 만** 변경 (+ 한글 대조군 한 문장) → PR
#   4) 로컬 translate_pr.py 실행
#   5) 판정 (아래 8개 규칙)
#   6) cleanup
#
# ── 시드하는 링크 4종 ─────────────────────────────────────────────────────
#   1. 절대 public docs URL   → 두 자리 모두 대상 언어로 (수정 대상)
#   2. 절대 **gov** docs URL  → ko 그대로 (공공 가이드는 ko 전용 — 옮기면 404)
#   3. site-root 축약형        → 언어 자리 치환 (기존 동작, 회귀 감시)
#   4. 진짜 외부 URL           → 손대지 않음 (기존 동작, 회귀 감시)
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) 번역 성공 (exit 0, PARTIAL 없음)
#   (2) en/ja 의 절대 docs URL 이 **두 자리 모두** 자기 언어  ← 결함 (A)
#   (3) ko 가 바꾼 fragment 가 en/ja 에 반영
#   (4) en/ja 문서 전체에 **짝 불일치 docs URL 이 하나도 없다**  ← 결함 (B)
#   (5) gov 호스트 URL 은 ko 그대로
#   (6) site-root 축약형은 대상 언어로 치환
#   (7) 외부 URL(yaml.org)은 그대로
#   (8) 같은 유닛의 한글 대조군이 실제로 번역됨 (수정이 번역을 삼키지 않는지)
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-docs-url-locale.sh
#   bash scripts/e2e-docs-url-locale.sh --keep
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-docs-url-locale.sh
#
# 의존성: git, gh (로그인), python3
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-docsurl/$TS"
HEAD_BRANCH="translate-test-docsurl/$TS"
DOC="overview.md"          # ko/en/ja 세 벌이 다 있는 작은 문서
KEEP=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    -h|--help) sed -n '1,70p' "$0"; exit 0 ;;
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
GOV_URL="https://docs.gov-nhncloud.com/ko/${SLUG}/ko/getting-started-gov/"
EXT_URL="https://yaml.org/"
OLD_FRAG="#e2e-old-anchor"
NEW_FRAG="#create-a-key-store"

# 픽스처 — ko 는 원문, en/ja 는 **이미 올바른** 번역 상태.
# 링크 4종이 한 문단 안에 있다 (block granularity 에서 한 유닛 = 한 번의 재번역).
fixture_ko() {  # $1: fragment
  cat <<EOF

<a id="e2e-docs-url-locale"></a>
### 암호화 키 저장소 설정

암호화 볼륨을 만들려면 미리 [키 저장소를 생성](https://docs.nhncloud.com/ko/${SLUG}/ko/getting-started/$1)해야 합니다. 공공 환경은 [공공 가이드](${GOV_URL})를 참고합니다. 오브젝트 스토리지 인증은 [인증 및 권한](/Storage/Object%20Storage/ko/api-guide/#auth)을, YAML 형식은 [Yaml 홈페이지](${EXT_URL})를 참고합니다.
EOF
}

fixture_en() {  # $1: fragment
  cat <<EOF

<a id="e2e-docs-url-locale"></a>
### Encryption Key Store Settings

To create an encrypted volume, you must first [create a key store](https://docs.nhncloud.com/en/${SLUG}/en/getting-started/$1). For the public sector environment, see the [public sector guide](${GOV_URL}). For Object Storage authentication, see [Authentication and Authorization](/Storage/Object%20Storage/en/api-guide/#auth), and for the YAML format, see the [Yaml homepage](${EXT_URL}).
EOF
}

fixture_ja() {  # $1: fragment
  cat <<EOF

<a id="e2e-docs-url-locale"></a>
### 暗号化キーストア設定

暗号化ボリュームを作成するには、あらかじめ[キーストアを作成](https://docs.nhncloud.com/ja/${SLUG}/ja/getting-started/$1)する必要があります。公共環境は[公共ガイド](${GOV_URL})を参照してください。オブジェクトストレージの認証は[認証および権限](/Storage/Object%20Storage/ja/api-guide/#auth)を、YAML 形式は [Yaml ホームページ](${EXT_URL})を参照してください。
EOF
}

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC"
echo

# ── 0) webhook 비활성화 ───────────────────────────────────────────────────
# 실제 PR 을 만들므로 배포된 webhook pod 가 같은 PR 로 Jenkins 잡을 중복
# 트리거하지 않게 끈다 (e2e-fence-noop-unit.sh 와 같은 이유).
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화"
set_webhook_repo_enabled false

echo "[1/6] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

echo "[2/6] 시드 — ko/en/ja 에 링크 4종 (en/ja 는 이미 올바른 상태)"
for lang in ko en ja; do
  [[ -f "$lang/$DOC" ]] || { echo "error: $lang/$DOC 없음" >&2; exit 1; }
done
fixture_ko "$OLD_FRAG" >> "ko/$DOC"
fixture_en "$OLD_FRAG" >> "en/$DOC"
fixture_ja "$OLD_FRAG" >> "ja/$DOC"
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(docs-url): ko/en/ja 에 배포 docs URL 픽스처 시드 ($TS)"
git push -q origin "$SESSION_BRANCH"

echo "[3/6] ko 변경 — 절대 docs URL 의 fragment 만 (+ 한글 대조군)"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" "$OLD_FRAG" "$NEW_FRAG" "$TS" <<'PY'
import io, sys
path, old, new, ts = sys.argv[1:5]
raw = io.open(path, encoding="utf-8", newline="").read()
assert old in raw, "시드된 fragment 를 찾지 못함"
# ko 가 바꾸는 것은 fragment 하나뿐 — Online-NAS#97 과 같은 모양.
raw = raw.replace(f"/getting-started/{old})", f"/getting-started/{new})")
# 대조군: 같은 문단 끝에 한글 한 문장. 수정이 번역을 삼키면 여기서 잡힌다.
marker = f" 이 문장은 번역 대조군입니다 ({ts})."
i = raw.rindex("참고합니다.") + len("참고합니다.")
raw = raw[:i] + marker + raw[i:]
io.open(path, "w", encoding="utf-8", newline="").write(raw)
print(f"  변경: {path} (fragment {old} → {new} + 대조군 1문장)")
PY
git add -- "ko/$DOC"
committed="$(git diff --cached --name-only)"
[[ "$committed" == "ko/$DOC" ]] || { echo "error: 예상 외 파일 스테이지됨: $committed" >&2; exit 1; }
git commit -q -m "e2e(docs-url): 절대 docs URL 의 fragment 변경 ($TS)"
git push -q origin "$HEAD_BRANCH"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(docs-url): 배포 docs 절대 URL 로케일 ($TS)" \
  --body "cloud-translate rewrite_links 검증 — 재번역된 유닛의 절대 docs URL 이 두 로케일 자리를 모두 대상 언어로 옮기는지, 그리고 짝 불일치를 만들지 않는지." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

echo
echo "[4/6] local translate_pr.py"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_TRANSLATE_ENGINE=claude-code \
  TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
  TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
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

python3 - "$tmpdir" "$SLUG" "$NEW_FRAG" "$GOV_URL" "$EXT_URL" <<'PY' || fails=$((fails + 1))
import io, re, sys, pathlib
tmp, slug, frag, gov_url, ext_url = sys.argv[1:6]
DOCS = re.compile(r'https?://docs\.[a-z0-9.-]*nhncloud\.com/[^\s)"\'<>\]]*')
rc = 0
for lang in ("en", "ja"):
    p = pathlib.Path(f"{tmp}/{lang}.md")
    if not p.exists():
        continue
    t = io.open(p, encoding="utf-8", newline="").read()

    # (2) 절대 public docs URL 이 두 자리 모두 대상 언어
    want = f"https://docs.nhncloud.com/{lang}/{slug}/{lang}/getting-started/{frag}"
    if want in t:
        print(f"  PASS  (2) {lang} 절대 docs URL 두 자리 모두 /{lang}/")
    else:
        print(f"  FAIL  (2) {lang} 절대 docs URL 이 /{lang}/…/{lang}/ 이 아님")
        for m in DOCS.finditer(t):
            if "getting-started" in m.group(0):
                print("        실제:", m.group(0))
        rc = 1

    # (3) ko 가 바꾼 fragment 반영
    if frag in t:
        print(f"  PASS  (3) {lang} 에 변경된 fragment 반영")
    else:
        print(f"  FAIL  (3) {lang} 에 변경된 fragment 없음"); rc = 1

    # (4) 짝 불일치 docs URL 이 문서 전체에 하나도 없어야 한다
    mismatched = []
    for m in DOCS.finditer(t):
        url = m.group(0)
        path = url.split(".com", 1)[1].split("#")[0].split("?")[0]
        locales = [s for s in path.split("/") if s in ("ko", "en", "ja")]
        if len(set(locales)) > 1:
            mismatched.append(url)
    if not mismatched:
        print(f"  PASS  (4) {lang} 짝 불일치 docs URL 0건")
    else:
        print(f"  FAIL  (4) {lang} 짝 불일치 docs URL {len(mismatched)}건 (soft-404)")
        for u in mismatched[:4]:
            print("        ", u)
        rc = 1

    # (5) gov 호스트는 ko 그대로 (공공 가이드는 ko 전용)
    if gov_url in t:
        print(f"  PASS  (5) {lang} gov 호스트 URL 이 ko 그대로")
    else:
        print(f"  FAIL  (5) {lang} gov 호스트 URL 이 바뀜 — 공공 가이드에 없는 언어")
        for m in DOCS.finditer(t):
            if "gov-nhncloud" in m.group(0):
                print("        실제:", m.group(0))
        rc = 1

    # (6) site-root 축약형은 대상 언어로
    if f"/Storage/Object%20Storage/{lang}/api-guide/#auth" in t:
        print(f"  PASS  (6) {lang} site-root 축약형이 /{lang}/ 로 치환")
    else:
        print(f"  FAIL  (6) {lang} site-root 축약형 치환 실패"); rc = 1

    # (7) 외부 URL 은 그대로
    if ext_url in t:
        print(f"  PASS  (7) {lang} 외부 URL({ext_url}) 보존")
    else:
        print(f"  FAIL  (7) {lang} 외부 URL 이 바뀜"); rc = 1
raise SystemExit(rc)
PY

# (8) 대조군 — 한글이 남아 있으면 이 수정이 번역을 삼킨 것이다.
#     '대조군' 이라는 한글 자체를 본다 (앵커 슬러그에는 안 들어 있다).
if grep -q '대조군' "$tmpdir/en.md" 2>/dev/null; then
  bad "(8) en 에 한글 '대조군' 잔류 — 산문이 번역되지 않았다"
  grep -n '대조군' "$tmpdir/en.md" | head -3 | sed 's/^/        /'
else
  ok "(8) 대조군 산문이 en 에서 번역됨 (한글 잔류 없음)"
fi

echo
echo "[6/6] 결과"
if (( fails == 0 )); then
  echo "  PASS — 절대 docs URL 의 두 로케일 자리가 함께 이동하고, 짝 불일치가 없다 (로그: $LOG)"
  exit 0
fi
echo "  FAIL — $fails 개 규칙 실패 (로그: $LOG)"
KEEP=1
exit 1
