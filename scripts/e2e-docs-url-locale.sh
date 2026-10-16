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
#   5) 판정 (아래 10개 규칙)
#   6) cleanup
#
# ── 시드하는 링크 6종 ─────────────────────────────────────────────────────
#   1. 절대 public docs URL   → 두 자리 모두 대상 언어로 (수정 대상)
#   2. 절대 **gov** docs URL  → ko 그대로 (공공 가이드는 ko 전용 — 옮기면 404)
#   3. site-root 축약형        → 언어 자리 치환 (기존 동작, 회귀 감시)
#   4. 진짜 외부 URL           → 손대지 않음 (기존 동작, 회귀 감시)
#   5. **외부 URL 이 공백 없이 바로 앞에 붙은** 가이드 URL
#      (`[https://external…/docs](https://docs…/ko/…/ko/…/)`) → 가이드 URL 만 이동
#   6. **URL 안의 URL** (리디렉터 `?u=<가이드 URL>`) → 어느 쪽도 손대지 않음
#   7. **ko 원문이 이미 대상 언어 세그먼트를 쓴 비가이드 절대 URL**
#      (`dev.mysql.com/…/8.0/en/` · `docs.toast.com/en/…/en/` · `docs.python.org/ja/`)
#      → ko 원문과 바이트 동일 (아래 "케이스 restore-ext")
#
# 5·6 은 규칙끼리 서로의 토큰을 침범하지 않는지 보는 모양이다. "외부 URL 복원"
# 을 호스트 negative lookahead 로만 막으면 매치 **시작 위치** 만 검사하게 되어,
# 5 는 greedy prefix 가 `](` 를 건너 뒷자리를 ko 로 되돌리고 (`/en/…/ko/…`),
# 6 은 바깥 호스트가 외부라 같은 일이 안쪽 URL 에 일어난다 — 둘 다 (B) 와 **같은
# 죽은 링크**이고, 규칙을 URL 토큰 단위 배타 분기로 돌려야 닫힌다. 코퍼스 실측
# 0건이라 사고는 아니지만, 계약이 그것을 금지한다고 적혀 있다.
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
#   (9) 인접 외부 URL 뒤의 가이드 URL 이 두 자리 모두 자기 언어
#  (10) URL 안의 URL 이 짝 불일치가 아니다
#  (11) [restore-ext] en/ja 의 비가이드 절대 URL 이 ko 원문 URL 과 바이트 동일
#  (S)  [restore-ext] 정적 체크 — 모델 없이 `rewrite_links` 를 ko 픽스처 문단에
#       직접 돌려 같은 판정. 번역 전에 돈다 (`--static-only` 면 이것만 돌고 끝)
#
# ── 케이스 restore-ext — 비가이드 절대 URL 의 "외부 URL 복원" ──────────────
# 실제 사고: TOAST-DOCS/Gamebase#433 → 번역 PR #434 (2026-10-12 머지,
# https://github.com/TOAST-DOCS/Gamebase/pull/434). ko 원문 코드 블록의
# `<see href="https://docs.toast.com/en/Game/Gamebase/en/api-guide/#purchase-iap">`
# (ko 가 이미 `/en/` 을 썼다) 가 en 결과에서 `…/en/Game/Gamebase/ko/…` 가 됐다.
# 원인은 결정적이다: `_rewrite_url_tokens` → `_restore_external_url` 이 가이드
# 호스트(docs.*nhncloud.com)가 아닌 절대 URL 의 **마지막 `/{target}/`** 을 무조건
# `/ko/` 로 되돌린다 — "모델이 외부 URL 의 언어를 번역했다" 고 가정할 뿐, ko 원문이
# 처음부터 그 세그먼트를 썼는지는 보지 않는다. en 은 `/en/` 을, ja 는 `/ja/` 를
# 가진 URL 이 깨진다 (ko 코퍼스의 비가이드 URL 중 `/en/` 113개).
#
# 기존 케이스(1~10)가 못 잡은 이유: 외부 URL 대조군(yaml.org)에 로케일 세그먼트가
# 없어 복원 패스가 손댈 자리가 아예 없었다.
#
# 이 케이스는 **수정 전에는 FAIL 이 정상**이다. 이 스크립트는 `e2e-suite.sh` 의
# plan 에 없어 all 을 빨갛게 만들지 않는다. 원래 계약(1~10)만 보려면
# `--skip-restore-ext`.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-docs-url-locale.sh
#   bash scripts/e2e-docs-url-locale.sh --keep
#   bash scripts/e2e-docs-url-locale.sh --static-only       # 모델·PR 없이 (S) 만
#   bash scripts/e2e-docs-url-locale.sh --skip-restore-ext  # (11)·(S) 제외
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
RESTORE_EXT=1
STATIC_ONLY=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    --skip-restore-ext) RESTORE_EXT=0; shift ;;
    --static-only) STATIC_ONLY=1; shift ;;
    -h|--help) sed -n '1,100p' "$0"; exit 0 ;;
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
# 인접/포함 모양 — 규칙끼리 서로의 토큰을 침범하지 않는지 본다. `console-guide`
# stem 을 쓰는 이유는 (2) 의 `getting-started` 판정과 섞이지 않게 하기 위해서다.
EXT_LABEL_URL="https://external.example.com/docs"
# 리디렉터 URL 의 **안쪽** 은 ko 그대로가 정답이다 — URL 안의 URL 은 어느 쪽
# 기준으로도 안전하게 판정할 수 없어 후처리가 손대지 않는다. 그래서 en/ja
# 시드도 ko 를 품은 채로 심는다 (이것이 "이미 올바른 상태" 다).
RED_URL="https://link.example.com/r?u=https://docs.nhncloud.com/ko/${SLUG}/ko/console-guide/"
OLD_FRAG="#e2e-old-anchor"
# 케이스 restore-ext — ko 원문이 이미 대상 언어 세그먼트를 쓴 비가이드 절대 URL.
# en/ja 모두 ko 와 **같은 바이트**가 정답이다 (원문이 정한 링크다).
#   GB : Gamebase#434 사고 그대로 (`/en/` 두 자리, 마지막 것이 되돌려졌다) → en 결함
#   SQL: 코퍼스 최다 모양 (dev.mysql.com/doc/refman/8.0/en/)               → en 결함
#   PY : `/ja/` 세그먼트                                                   → ja 결함
EXT_GB_URL="https://docs.toast.com/en/Game/Gamebase/en/api-guide/#purchase-iap"
EXT_SQL_URL="https://dev.mysql.com/doc/refman/8.0/en/replication.html"
EXT_PY_URL="https://docs.python.org/ja/3/library/re.html"
NEW_FRAG="#create-a-key-store"

# restore-ext 문장 — 같은 문단(= ko 가 바꿔 재번역되는 유닛) 끝에 붙는다. URL 은
# 세 언어 모두 ko 원문과 같은 바이트로 심는다 (그것이 "이미 올바른 상태" 다).
ext_sentence() {  # $1: lang
  (( RESTORE_EXT )) || return 0
  case "$1" in
    ko) printf ' 결제 콜백은 `<see href="%s">` 를, 복제는 [MySQL 문서](%s)를, 정규식은 [Python 문서](%s)를 참고합니다.' "$EXT_GB_URL" "$EXT_SQL_URL" "$EXT_PY_URL" ;;
    en) printf ' For the payment callback, see `<see href="%s">`; for replication, see the [MySQL documentation](%s); for regular expressions, see the [Python documentation](%s).' "$EXT_GB_URL" "$EXT_SQL_URL" "$EXT_PY_URL" ;;
    ja) printf ' 決済コールバックは `<see href="%s">` を、レプリケーションは [MySQL ドキュメント](%s)を、正規表現は [Python ドキュメント](%s)を参照してください。' "$EXT_GB_URL" "$EXT_SQL_URL" "$EXT_PY_URL" ;;
  esac
}

# 픽스처 — ko 는 원문, en/ja 는 **이미 올바른** 번역 상태.
# 링크 4종이 한 문단 안에 있다 (block granularity 에서 한 유닛 = 한 번의 재번역).
fixture_ko() {  # $1: fragment
  cat <<EOF

<a id="e2e-docs-url-locale"></a>
### 암호화 키 저장소 설정

암호화 볼륨을 만들려면 미리 [키 저장소를 생성](https://docs.nhncloud.com/ko/${SLUG}/ko/getting-started/$1)해야 합니다. 공공 환경은 [공공 가이드](${GOV_URL})를 참고합니다. 오브젝트 스토리지 인증은 [인증 및 권한](/Storage/Object%20Storage/ko/api-guide/#auth)을, YAML 형식은 [Yaml 홈페이지](${EXT_URL})를 참고합니다. 콘솔 사용법은 [${EXT_LABEL_URL}](https://docs.nhncloud.com/ko/${SLUG}/ko/console-guide/)에서, 리디렉터를 거치는 주소는 ${RED_URL} 에서 확인합니다.$(ext_sentence ko)
EOF
}

fixture_en() {  # $1: fragment
  cat <<EOF

<a id="e2e-docs-url-locale"></a>
### Encryption Key Store Settings

To create an encrypted volume, you must first [create a key store](https://docs.nhncloud.com/en/${SLUG}/en/getting-started/$1). For the public sector environment, see the [public sector guide](${GOV_URL}). For Object Storage authentication, see [Authentication and Authorization](/Storage/Object%20Storage/en/api-guide/#auth), and for the YAML format, see the [Yaml homepage](${EXT_URL}). For console usage, see [${EXT_LABEL_URL}](https://docs.nhncloud.com/en/${SLUG}/en/console-guide/), and see ${RED_URL} for the redirector form.$(ext_sentence en)
EOF
}

fixture_ja() {  # $1: fragment
  cat <<EOF

<a id="e2e-docs-url-locale"></a>
### 暗号化キーストア設定

暗号化ボリュームを作成するには、あらかじめ[キーストアを作成](https://docs.nhncloud.com/ja/${SLUG}/ja/getting-started/$1)する必要があります。公共環境は[公共ガイド](${GOV_URL})を参照してください。オブジェクトストレージの認証は[認証および権限](/Storage/Object%20Storage/ja/api-guide/#auth)を、YAML 形式は [Yaml ホームページ](${EXT_URL})を参照してください。コンソールの使い方は [${EXT_LABEL_URL}](https://docs.nhncloud.com/ja/${SLUG}/ja/console-guide/) を、リダイレクタ経由のアドレスは ${RED_URL} を参照してください。$(ext_sentence ja)
EOF
}

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC"
echo

# ── S) 정적 체크 (restore-ext) — 모델·PR 없이 결정적 판정 ──────────────────
# 번역 후처리 `rewrite_links` 를 ko 픽스처 문단에 직접 돌린다. 모델이 URL 을
# 바이트 그대로 복사해 와도(= 이상적 모델) 후처리가 깨뜨리는지를 본다.
static_rc=0
if (( RESTORE_EXT )); then
  echo "[S] 정적 체크 — rewrite_links(ko 픽스처 문단, en|ja) 의 비가이드 URL 보존"
  echo "    ($CLOUD_TRANSLATE_DIR/translate/app/postprocess.py)"
  static_py="$tmpdir/static_restore_ext.py"
  cat > "$static_py" <<'PY'
import re, sys
sys.path[:0] = [sys.argv[1], sys.argv[1] + "/.."]
from app.postprocess import rewrite_links
urls = sys.argv[2:]
ko = sys.stdin.read()
for u in urls:
    assert u in ko, f"픽스처에 {u} 없음"
rc = 0
for lang in ("en", "ja"):
    out = rewrite_links(ko, lang)
    for u in urls:
        if u in out:
            print(f"  PASS  (S) {lang} {u}")
            continue
        rc = 1
        host = u.split("/")[2]
        got = re.findall(r'https?://' + re.escape(host) + r"[^\s)\"'<>`]*", out)
        print(f"  FAIL  (S) {lang} {u}")
        for g in got:
            print(f"              → {g}")
raise SystemExit(rc)
PY
  set +e
  fixture_ko "$NEW_FRAG" | "$CLOUD_TRANSLATE_PY" "$static_py" \
    "$CLOUD_TRANSLATE_DIR/translate" "$EXT_GB_URL" "$EXT_SQL_URL" "$EXT_PY_URL"
  static_rc=$?
  set -e
  if (( static_rc == 0 )); then
    echo "  (S) PASS"
  else
    echo "  (S) FAIL — 후처리가 ko 원문의 비가이드 URL 을 바꾼다 (Gamebase#434 결함 재현)"
  fi
  echo
fi
if (( STATIC_ONLY )); then
  trap - EXIT
  exit $static_rc
fi

# ── 0) webhook 비활성화 ───────────────────────────────────────────────────
# 실제 PR 을 만들므로 배포된 webhook pod 가 같은 PR 로 Jenkins 잡을 중복
# 트리거하지 않게 끈다 (e2e-fence-noop-unit.sh 와 같은 이유).
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화"
set_webhook_repo_enabled false

echo "[1/6] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

echo "[2/6] 시드 — ko/en/ja 에 링크 6종 (en/ja 는 이미 올바른 상태)"
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

python3 - "$tmpdir" "$SLUG" "$NEW_FRAG" "$GOV_URL" "$EXT_URL" "$EXT_LABEL_URL" \
  "$RESTORE_EXT" "$EXT_GB_URL" "$EXT_SQL_URL" "$EXT_PY_URL" <<'PY' || fails=$((fails + 1))
import io, re, sys, pathlib
tmp, slug, frag, gov_url, ext_url, ext_label_url = sys.argv[1:7]
restore_ext = sys.argv[7] == "1"
ext_loc_urls = sys.argv[8:11]
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

    # (9) 외부 URL 이 **공백 없이 바로 앞에 붙은** 가이드 URL.
    #     "외부 URL 복원" 을 호스트 lookahead 로만 막으면 매치 시작 위치만
    #     검사하게 되어, greedy prefix 가 `](` 를 건너 뒤 가이드 URL 의 뒷자리를
    #     ko 로 되돌린다. 규칙을 URL 토큰 단위 배타 분기로 돌린 뒤에야 닫힌다.
    adj = f"[{ext_label_url}](https://docs.nhncloud.com/{lang}/{slug}/{lang}/console-guide/)"
    if adj in t:
        print(f"  PASS  (9) {lang} 인접 외부 URL 뒤의 가이드 URL 두 자리 모두 /{lang}/")
    else:
        print(f"  FAIL  (9) {lang} 인접 외부 URL 뒤의 가이드 URL 이 어긋남")
        for m in DOCS.finditer(t):
            if "console-guide" in m.group(0):
                print("        실제:", m.group(0))
        rc = 1

    # (10) URL 안의 URL (리디렉터). 후처리는 어느 쪽도 손대지 않는 것이 정답이라
    #      안쪽은 ko 그대로여야 하고, 무엇보다 **한 자리만** 밀려 짝이 어긋나면
    #      안 된다 — 수정 전에는 바깥 호스트가 외부라 복원 패스가 뒷자리를 ko 로
    #      되돌려 `/en/…/ko/…` 를 만들었다.
    red = re.search(r'https?://link\.example\.com/r\?u=(https?://docs\.[^\s)"\'<>\]]*)', t)
    if red is None:
        print(f"  FAIL  (10) {lang} 리디렉터 URL 이 사라짐"); rc = 1
    else:
        inner = red.group(1)
        path = inner.split(".com", 1)[1].split("#")[0].split("?")[0]
        slots = [s for s in path.split("/") if s in ("ko", "en", "ja")]
        if len(set(slots)) <= 1:
            print(f"  PASS  (10) {lang} URL 안의 URL 이 짝 불일치가 아님")
        else:
            print(f"  FAIL  (10) {lang} URL 안의 URL 이 짝 불일치 — {inner}"); rc = 1

    # (11) [restore-ext] ko 원문이 이미 대상 언어 세그먼트를 쓴 비가이드 절대 URL 은
    #      ko 와 바이트 동일. 수정 전에는 `_restore_external_url` 이 마지막
    #      `/{lang}/` 을 `/ko/` 로 되돌린다 (Gamebase#434).
    if restore_ext:
        for u in ext_loc_urls:
            if u in t:
                print(f"  PASS  (11) {lang} 비가이드 URL 보존 {u}")
                continue
            host = u.split("/")[2]
            got = re.findall(r'https?://' + re.escape(host) + r"""[^\s)"'<>`]*""", t)
            print(f"  FAIL  (11) {lang} 비가이드 URL 이 바뀜 {u}")
            for g in got:
                print(f"              → {g}")
            rc = 1
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

# (S) 정적 체크 결과도 최종 판정에 넣는다
if (( RESTORE_EXT && static_rc != 0 )); then
  bad "(S) 정적 체크 — rewrite_links 가 비가이드 URL 을 바꾼다"
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
