#!/usr/bin/env bash
#
# table-field-rows e2e — API 필드 표가 ko 와 한 행 어긋나 있을 때, 번역이 **그
# 행만** 고치고 나머지 행을 바이트 그대로 두는가 (cloud-translate
# `_shared_identifier_keys` → table reconcile 의 keyed 경로).
#
# ── 재현하는 결함 ─────────────────────────────────────────────────────────
# table reconcile 은 번역본의 표가 ko 와 행 수가 다르면 번역 전에 표를 ko 에
# 맞춘다. 첫 열이 키로 서면 빠진 행만 번역해 넣고(나머지 바이트 보존), 아니면
# **표 전체를 다시 번역**한다. 키는 `llm_patch._row_key` 가 정하는데 숫자가 든
# 첫 셀만 인정해서, `domain` · `origins[0].origin` 같은 API 필드 표는 전부 표 전체
# 재번역으로 떨어졌다 — **ko PR 이 그 표를 건드리지 않았는데도.**
#
#   9월 번역 재생 T07 (CDN#102 → #103): ko 는 링크 두 줄만 바꿨는데 ja
#   `api-guide-v2.0.md` 표 #14 (ko 38 · ja 37, `useOrigin` 한 행 누락) 가
#   **1행 보존 / 36행 재작성**. golden 은 같은 경로에서 36행을 보존했다 —
#   행 수만 검증하는 경로라 결과가 모델 운이다.
#
# ── 픽스처 (세션 브랜치에 생성 — alpha 상주 아님) ─────────────────────────
#   {ko,en,ja}/table-field-rows.md — pre-align 정렬본. 표는 T07 의 **실제 행**
#   15개 (CDN `api-guide-v2.0.md` 표 #14 발췌, 4열 → 6열 그대로).
#     en: `useOrigin` 행 누락                          → 채워 넣기
#     ja: ko 에 없는 `createTime` 행 하나 더 (T07 `api-guide-v1.5.md` 모양) → 떼기
#   ko 편집은 **표 밖의 문장 하나**뿐이다. 표는 ko 가 안 건드린 자리다.
#
# ── 판정 ─────────────────────────────────────────────────────────────────
#   [A] 결정적 층 (모델 없음) — 실제 `_reconcile_table_rows` 에 모델 호출만
#       에코로 가로채 **어느 경로를 타는지** 본다.
#       (1) en: 표 전체 재번역 0 · `useOrigin` 한 행 채움            ← 결함
#       (2) ja: 표 전체 재번역 0 · `createTime` 만 뗌 (모델 호출 0)  ← 결함
#   [B] 산출물 층 — 로컬 translate_pr.py (CLI 엔진, 권장 preset) 실제 번역.
#       (3) 번역 성공 (exit 0, PARTIAL 없음)
#       (4) en/ja: 기존 행이 **전부** 바이트 그대로 (ja 는 createTime 제외) ← 결함(증상)
#       (5) en/ja: `useOrigin` 행이 생겼고 행 순서가 ko 와 같다       ← 기능
#       (6) ja: `createTime` 행이 없다                               ← 기능
#       (7) ko 가 고친 표 밖의 문장은 en/ja 에서 바뀌었다              ← 전제
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`TABLE_FIELD_ROWS: OK`) — 수정된 코드의 기대값
#   3  결함 재현 (`TABLE_FIELD_ROWS: REPRO`) — 수정 전 코드의 기대값.
#      (4) 는 모델에 달려 있어 수정 전에도 우연히 통과할 수 있다 — 수정 전
#      판정의 근거는 결정적인 (1)(2) 다.
#   1  기능 규칙 실패 또는 픽스처가 조건을 잃음 (`TABLE_FIELD_ROWS: FAIL`)
#   2  인프라 — 번역 PR 미감지 · translate_pr.py 비정상 종료
#
# Usage:
#   source ./load_env.sh      # webhook 토글에 필요 (--dry 는 불필요)
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-table-field-rows.sh          # [A]+[B]
#   bash scripts/e2e-table-field-rows.sh --dry      # [A] 만 (모델·네트워크 없음)
#   bash scripts/e2e-table-field-rows.sh --keep     # PR·브랜치 보존
#
# `CLOUD_TRANSLATE_DIR` (검증할 코드) 와 `PRESET_CATALOG_DIR` (운영 preset 출처)
# 가 따로인 이유는 `e2e-unit-pairing.sh` 헤더 참고.
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-fieldrows/$TS"
HEAD_BRANCH="translate-test-fieldrows/$TS"
DOC="table-field-rows.md"
KEEP=0
DRY=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --dry)  DRY=1; shift ;;
    -h|--help) sed -n '2,62p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"
ko_pr_url=""; tx_pr_url=""

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/base" "$tmpdir/head" "$tmpdir/tx"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( KEEP )) || (( DRY )); then
    (( DRY )) || { echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${ko_pr_url:-없음}, 번역 PR: ${tx_pr_url:-없음})"; }
    git checkout -q "$BASE_SOURCE" 2>/dev/null || true
    return $rc
  fi
  echo; echo "[cleanup] PR 닫기 · 브랜치 정리"
  [[ -n "$tx_pr_url" ]] && gh pr close "$tx_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  [[ -n "$ko_pr_url" ]] && gh pr close "$ko_pr_url" --repo "$REPO" >/dev/null 2>&1 || true
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/translate/${HEAD_BRANCH}*" 2>/dev/null | sed 's|.*refs/heads/||')
  git push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "=== table-field-rows e2e ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 2>/dev/null | cut -c1-60))"
echo "  preset 출처     : $PRESET_CATALOG_DIR"
echo "  session         : $SESSION_BRANCH"
echo "  픽스처          : {ko,en,ja}/$DOC"
echo "  모드            : $( ((DRY)) && echo '[A] 결정적 층만 (--dry)' || echo '[A]+[B]' )"
echo

[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }

fails=0; repro=0
ok()    { echo "  PASS  $1"; }
bad()   { echo "  FAIL  $1"; fails=$((fails + 1)); }
defect(){ echo "  FAIL  $1  (결함 — 재현)"; repro=$((repro + 1)); }

if (( ! DRY )); then
  : "${DASHBOARD_BASE_URL:?load_env.sh 를 source 하라 (webhook 토글)}"
  : "${DASHBOARD_API_TOKEN:?load_env.sh 를 source 하라 (webhook 토글)}"
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
  source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
  echo "[0] webhook 비활성화"
  set_webhook_repo_enabled false
fi

# ── 1) 세션 브랜치 + 픽스처 ────────────────────────────────────────────────
echo "[1] 세션 브랜치 생성 + 픽스처 시드"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

python3 - "$TS" "$DOC" <<'PY'
import io, os, sys
ts, doc = sys.argv[1:3]
# 표는 T07 (CDN `api-guide-v2.0.md` 표 #14, ko merge sha 75e30fa4) 의 실제 행 발췌.
TABLE_KO = r'''
| 이름                  | 타입    | 필수 여부 | 기본값 | 유효 범위                                                    | 설명                                                         |
| --------------------- | ------- | --------- | ------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| domain                | String  | 필수      |        | 최대 255자                                                   | 수정할 도메인(서비스 이름)                                   |
| useOriginCacheControl | Boolean | 선택      |        | true/false                                                        | 캐시 만료 설정(true: 원본 서버 설정 사용, false: 사용자 설정 사용). useOriginCacheControl이나 cacheType 중 하나는 반드시 입력해야 합니다.      |
| cacheType             | String  | 선택      |        | BYPASS, NO_STORE            | 캐시 타입 설정. useOriginCacheControl이나 cacheType 중 하나는 반드시 입력해야 합니다.                                          |
| referrerType          | String  | 필수      |        | BLACKLIST/WHITELIST                                          | 리퍼러 접근 관리("BLACKLIST": 블랙리스트, "WHITELIST": 화이트리스트) |
| referrers             | List    | 선택      |        |                                                              | 정규 표현식 형태의 리퍼러 헤더 목록 |
| isAllowWhenEmptyReferrer | Boolean | 선택      | true      | true/false             | 리퍼러 헤더가 없는 경우 콘텐츠 접근 허용(true)/거부(false) 여부             |
| description           | String  | 선택      |        | 최대 255자                                                   | 설명                                                         |
| domainAlias           | List    | 선택      |        | 최대 255자                                                   | 도메인 별칭(개인 또는 회사가 소유한 도메인 사용) |
| defaultMaxAge         | Integer | 선택      | 0      | 0~2,147,483,647                                            | 캐시 만료 시간(초), 기본값 0은 604,800초입니다.              |
| origins               | List    | 필수      |        |                                                              | 원본 서버                                                    |
| origins[0].origin     | String  | 필수      |        | 최대 255자                                                   | 원본 서버(도메인 또는 IP)                                      |
| origins[0].originPath | String  | 선택      |        | 최대 8192자                                                  | 원본 서버 하위 경로                                          |
| forwardHostHeader     | String  | 필수      |        | ORIGIN_HOSTNAME<br/>REQUEST_HOST_HEADER   | CDN 서버가 원본 서버로 콘텐츠 요청 시 전달할 호스트 헤더 설정("ORIGIN_HOSTNAME": 원본 서버의 호스트 이름으로 설정, "REQUEST_HOST_HEADER": 클라이언트 요청의 호스트 헤더로 설정)|
| useOrigin             | String  | 필수      |        | Y/N                                                          | 캐시 만료 설정(Y: 원본 설정 사용, "N":사용자 설정 사용)      |
| rootPathAccessControl  | Object  | 선택 |  |  | CDN 서비스의 루트 경로에 대한 접근 제어 설정 | 
'''
TABLE_EN = r'''
| Name                  | Type    | Required | Default | Valid Range                                                    | Description                                                         |
| --------------------- | ------- | --------- | ------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| domain                | String  | Required      |        | Up to 255 characters                                                   | Domain (service name) to modify                                   |
| useOriginCacheControl | Boolean | Optional      |        | true/false                                                        | Set cache expiration (true: use origin server settings, false: use user settings). One of useOriginCacheControl or cacheType must be entered.      |
| cacheType             | String  | Optional      |        | BYPASS, NO_STORE            | Set cache type. One of useOriginCacheControl or cacheType must be entered.                                          |
| referrerType          | String  | Required      |        | BLACKLIST/WHITELIST                                          | Referrer access management ("BLACKLIST": Blacklist, "WHITELIST": Whitelist) |
| referrers             | List    | Optional      |        |                                                              | List of regex referrer headers |
| isAllowWhenEmptyReferrer | Boolean | Optional      | true      | true/false             | Whether to allow (true) or deny (false) access to content when there is no referer header             |
| description           | String  | Optional      |        | Up to 255 characters                                                   | Description                                                         |
| domainAlias           | List    | Optional      |        | Up to 255 characters                                                   | Domain alias (using a domain owned by individuals or companies) |
| defaultMaxAge         | Integer | Optional      | 0      | 0~2,147,483,647                                            | Cache expiration time (seconds), the default value 0 is 604,800 seconds.              |
| origins               | List    | Required      |        |                                                              | Origin server                                                    |
| origins[0].origin     | String  | Required      |        | Up to 255 characters                                                   | Origin server (domain or IP)                                      |
| origins[0].originPath | String  | Optional      |        | Up to 8192 characters                                                  | Sub-path of origin server                                          |
| forwardHostHeader     | String  | Required      |        | ORIGIN_HOSTNAME<br/>REQUEST_HOST_HEADER   | Set the host header to be forwarded by the CDN server when requesting content to the origin server ("ORIGIN_HOSTNAME": Set to the host name of the origin server, "REQUEST_HOST_HEADER": Set to the host header of the client request)|
| rootPathAccessControl  | Object  | Optional |  |  | Set the access control for the CDN service root path | 
'''
TABLE_JA = r'''
| 名前          | タイプ | 必須か | デフォルト値 | 有効範囲                                            | 説明                                                 |
| --------------------- | ------- | --------- | ------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| domain                | String  | 必須  |        | 最大255文字                                            | 修正するドメイン(サービス名)                                   |
| useOriginCacheControl | Boolean | 選択   |        | true/false                                                        | キャッシュ期限設定(true：オリジンサーバー設定を使用、 false：ユーザー設定を使用). useOriginCacheControlまたはcacheTypeのいずれかを必ず入力する必要があります。      |
| cacheType             | String  | 選択   |        | BYPASS, NO_STORE            | キャッシュタイプ設定。 useOriginCacheControlまたはcacheTypeのいずれかを必ず入力する必要があります。                                          |
| referrerType          | String  | 必須  |        | BLACKLIST/WHITELIST                                          | リファラーアクセス管理("BLACKLIST"：ブラックリスト、"WHITELIST"：ホワイトリスト) |
| referrers             | List    | 任意 |        |                                                              | 正規表現形式のリファラーヘッダリスト |
| isAllowWhenEmptyReferrer | Boolean | 任意     | true      | true/false             | リファラーヘッダがない場合、コンテンツアクセス許可(true)/拒否(false)             |
| description           | String  | 任意  |        | 最大255文字                                            | 説明                                                 |
| domainAlias           | List    | 任意 |        | 最大255文字                                              | ドメインエイリアス(個人または会社が所有しているドメインを使用) |
| createTime            | String  | 任意 |        |                                                              | 作成日時 |
| defaultMaxAge         | Integer | 任意 | 0      | 0～2,147,483,647                                            | キャッシュ満了時間(秒)、デフォルト値0は604,800秒です。              |
| origins               | List    | 必須  |        |                                                              | オリジンサーバー                                            |
| origins[0].origin     | String  | 必須  |        | 最大255文字                                            | オリジンサーバー(ドメインまたはIP)                                      |
| origins[0].originPath | String  | 任意  |        | 最大8192文字                                           | オリジンサーバーの下層パス                                  |
| forwardHostHeader     | String  | 必須 |        | ORIGIN_HOSTNAME<br/>REQUEST_HOST_HEADER   | CDNサーバーがオリジンサーバーにコンテンツをリクエストする時、伝達するホストヘッダ設定("ORIGIN_HOSTNAME"：オリジンサーバーのホスト名で設定、"REQUEST_HOST_HEADER"：クライアントリクエストのホストヘッダで設定 |
| useOrigin             | String  | 必須  |        | Y/N                                                          | キャッシュ期限設定(Y：オリジン設定の使用、"N"：ユーザー設定の使用)      |
| rootPathAccessControl  | Object  | 任意 |  |  | CDNサービスのルートパスに対するアクセス制御設定 | 
'''
MARK = "<!-- pre-align:aligned sig=e2e0f1e1d00 -->\n\n"
DOCS = {
"ko": f"""{MARK}<a id="tfr"></a>
# table-field-rows e2e 픽스처

이 문서는 자동 생성된 e2e 픽스처입니다 ({ts}).

<a id="tfr-overview"></a>
## 개요 {{ #tfr-overview }}

서비스 설정을 수정하는 API입니다. 요청 본문에는 수정할 필드만 넣습니다.

<a id="tfr-fields"></a>
## 요청 본문 {{ #tfr-fields }}

[필드]
{TABLE_KO}
- `forwardHostHeader`의 기본값은 `domainAlias`를 설정한 경우 `REQUEST_HOST_HEADER`입니다.
""",
"en": f"""{MARK}<a id="tfr"></a>
# table-field-rows e2e fixture

This document is a generated e2e fixture ({ts}).

<a id="tfr-overview"></a>
## Overview {{ #tfr-overview }}

This API modifies service settings. Put only the fields to modify in the request body.

<a id="tfr-fields"></a>
## Request Body {{ #tfr-fields }}

[Field]
{TABLE_EN}
- The default value of `forwardHostHeader` is `REQUEST_HOST_HEADER` when `domainAlias` is set.
""",
"ja": f"""{MARK}<a id="tfr"></a>
# table-field-rows e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです ({ts})。

<a id="tfr-overview"></a>
## 概要 {{ #tfr-overview }}

サービス設定を修正するAPIです。リクエスト本文には修正するフィールドのみを入れます。

<a id="tfr-fields"></a>
## リクエスト本文 {{ #tfr-fields }}

[フィールド]
{TABLE_JA}
- `forwardHostHeader`の既定値は、`domainAlias`を設定した場合は`REQUEST_HOST_HEADER`です。
""",
}
for lang, text in DOCS.items():
    io.open(os.path.join(lang, doc), "w", encoding="utf-8", newline="").write(text)
print(f"  생성: {{ko,en,ja}}/{doc}  (en: useOrigin 누락 · ja: ko 에 없는 createTime 여분)")
PY
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(table-field-rows): 픽스처 시드 ($TS)"
session_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$SESSION_BRANCH"

# ── 2) ko 편집 — 표 밖의 문장 하나 ────────────────────────────────────────
echo "[2] ko 편집 — 표 밖의 문장 하나만"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" <<'PY'
import io, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
OLD = "요청 본문에는 수정할 필드만 넣습니다."
NEW = "요청 본문에는 수정할 필드만 넣고, 넣지 않은 필드는 기존 값을 유지합니다."
assert t.count(OLD) == 1
io.open(p, "w", encoding="utf-8", newline="").write(t.replace(OLD, NEW))
print(f"  {p}: 개요 문장 1개 수정 (표는 그대로)")
PY
git add -- "ko/$DOC"
git commit -q -m "e2e(table-field-rows): ko 편집 — 표 밖 문장 ($TS)"
head_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$HEAD_BRANCH"

# ── 3) [A] 결정적 층 ───────────────────────────────────────────────────────
echo
echo "[3] [A] 결정적 층 — table reconcile 이 타는 경로 (모델 없음)"
git worktree add -q --detach "$tmpdir/base" "$session_sha"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" - "$tmpdir/base" "$DOC" "$tmpdir/reconcile.json" <<'PY') 2>"$tmpdir/reconcile.err"
import asyncio, io, json, logging, os, sys
sys.path[:0] = ["translate", "."]
logging.disable(logging.WARNING)
from app.translator import Translator
base, doc, outp = sys.argv[1:4]

class Echo(Translator):
    """진짜 Translator — 모델 호출 한 겹만 에코로 가로챈다."""
    def __init__(self):
        super().__init__(glossary=None)
        self.calls = []
    async def translate(self, content, reference=None, target_lang="en", target_dir="en", *a, **k):
        self.calls.append(content)
        return content
    async def _translate_chunk_uncached(self, content, *a, **k):
        return content
    async def _verify_chunk_uncached(self, *a, **k):
        return ""

def rd(lang):
    return io.open(os.path.join(base, lang, doc), encoding="utf-8", newline="").read()

async def main():
    res = {}
    for lang in ("en", "ja"):
        tr, rep = Echo(), {}
        await tr._reconcile_table_rows(rd(lang), rd("ko"), None, lang, lang, report=rep)
        r = rep.get("table_reconcile", {})
        res[lang] = dict(backfilled=r.get("backfilled_rows", []), dropped=r.get("dropped_rows", []),
                         retranslated=r.get("retranslated_tables", 0),
                         whole_table_calls=sum(1 for c in tr.calls if c.count("\n") > 2))
    json.dump(res, open(outp, "w"), ensure_ascii=False, indent=2)

asyncio.run(main())
PY
prc=$?
set -e
if (( prc != 0 )); then
  echo "error: [A] 검사 실행 실패" >&2; tail -20 "$tmpdir/reconcile.err" >&2; KEEP=1; exit 2
fi
sed 's/^/    /' "$tmpdir/reconcile.json"; echo
eval "$(python3 - "$tmpdir/reconcile.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
en, ja = d["en"], d["ja"]
ok_en = en["retranslated"] == 0 and en["backfilled"] == ["useOrigin"] and not en["dropped"]
ok_ja = ja["retranslated"] == 0 and not ja["backfilled"] and ja["dropped"] == ["createTime"]
print(f"A_EN={int(ok_en)}; A_JA={int(ok_ja)}; A_WHOLE={en['retranslated'] + ja['retranslated']}")
PY
)"
(( A_EN )) && ok "(1) en: 표 전체 재번역 0 · useOrigin 한 행 채움" \
           || defect "(1) en: 표를 통째로 다시 번역한다 (전체 재번역 표 $A_WHOLE 개, en+ja)"
(( A_JA )) && ok "(2) ja: 표 전체 재번역 0 · createTime 한 행만 뗌 (모델 호출 없이)" \
           || defect "(2) ja: 표를 통째로 다시 번역한다"

if (( DRY )); then
  echo
  if (( fails == 0 && repro == 0 )); then echo "TABLE_FIELD_ROWS: OK"; exit 0; fi
  if (( fails == 0 )); then echo "TABLE_FIELD_ROWS: REPRO"; exit 3; fi
  echo "TABLE_FIELD_ROWS: FAIL"; exit 1
fi

# ── 4) [B] 실제 번역 ───────────────────────────────────────────────────────
echo
echo "[4] [B] 실제 번역 — 로컬 translate_pr.py (CLI 엔진, 권장 preset)"
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(table-field-rows): 표 밖 문장 수정 — 어긋난 필드 표 ($TS)" \
  --body "cloud-translate table reconcile 검증 — ko 가 안 건드린 필드 표는 빠진 행만 채우고 나머지 행을 바이트 그대로 두어야 한다." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"
preset_eval="$(python3 "$(dirname "$0")/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 1
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") 2>&1 | tee "$LOG" | grep -E "Table reconcile|Section-diff|anchor splice|Translation PR|PARTIAL|ERROR" | sed 's/^/    /'
tx_rc=${PIPESTATUS[0]}
set -e
if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(3) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(3) 번역 실패/부분 (exit $tx_rc)"
fi
grep -o 'engine=[a-z-]*' "$LOG" | sort | uniq -c | sed 's/^/    /' || true
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지 — 로그 $LOG" >&2; KEEP=1; exit 2; }
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url" || true
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"

echo
echo "[5] 산출물 판정"
eval "$(python3 - "$tmpdir/base" "$tmpdir/tx" "$DOC" <<'PY'
import io, os, sys
base, tx, doc = sys.argv[1:4]
def rd(root, lang):
    try:
        return io.open(os.path.join(root, lang, doc), encoding="utf-8", newline="").read()
    except OSError:
        return None
def rows(t):
    """[필드] 표의 데이터 행 (첫 셀이 필드명인 행)."""
    out, on = [], False
    for l in t.split("\n"):
        if l.startswith("|") and ("---" in l):
            on = True; continue
        if on and l.startswith("|"):
            out.append(l)
        elif on and out:
            break
    return out
key = lambda r: r.split("|")[1].strip()
ko_keys = [key(r) for r in rows(rd(base, "ko"))]
keep = order = added = gone = changed_prose = 0; missing = 0
for lang in ("en", "ja"):
    before, after = rd(base, lang), rd(tx, lang)
    if after is None:
        missing += 1; continue
    br, ar = rows(before), rows(after)
    lost = [key(r) for r in br if r not in ar and key(r) != "createTime"]
    print(f"echo '    [{lang}] 기존 행 {len(br)} → 결과 {len(ar)} · 바이트가 바뀐 기존 행 {len(lost)}: {lost[:6]}'")
    keep += not lost
    order += [key(r) for r in ar] == ko_keys
    added += "useOrigin" in [key(r) for r in ar]
    gone += "createTime" not in [key(r) for r in ar]
    lines = before.split("\n")                                  # 개요 문단 = heading 다음 첫 문단
    h = next(i for i, l in enumerate(lines) if "{ #tfr-overview }" in l)
    prose = next(l for l in lines[h + 1:] if l.strip())
    changed_prose += prose not in after.split("\n")   # 줄 단위 — 새 번역이 옛 문장을 앞에 품을 수 있다
print(f"B_KEEP={keep}; B_ORDER={order}; B_ADDED={added}; B_GONE={gone}; B_PROSE={changed_prose}; B_MISSING={missing}")
PY
)"
if (( B_MISSING )); then
  bad "(4) 번역 PR 에 픽스처 문서가 없다 ($B_MISSING 개)"
elif (( B_KEEP == 2 )); then
  ok "(4) en/ja 기존 행이 전부 바이트 그대로"
else
  defect "(4) ko 가 안 건드린 표의 기존 행이 다시 쓰였다 ($((2 - B_KEEP))/2 언어)"
fi
(( B_ADDED == 2 && B_ORDER == 2 )) && ok "(5) en/ja 에 useOrigin 행이 생기고 행 순서가 ko 와 같다" \
                                  || bad "(5) useOrigin 행 채우기/순서 불일치 (추가 $B_ADDED/2 · 순서 $B_ORDER/2)"
(( B_GONE == 2 )) && ok "(6) ja 의 createTime 행이 없다 (ko 가 정본)" \
                  || bad "(6) createTime 행이 남았다"
(( B_PROSE == 2 )) && ok "(7) ko 가 고친 표 밖 문장은 en/ja 에서 다시 번역됐다" \
                   || bad "(7) ko 가 고친 문장이 en/ja 에 반영되지 않았다 ($B_PROSE/2)"

echo
echo "[6] 결과"
echo "  ko PR: $ko_pr_url"
echo "  번역 PR: $tx_pr_url"
if (( fails == 0 && repro == 0 )); then echo "TABLE_FIELD_ROWS: OK"; exit 0; fi
KEEP=1
if (( fails == 0 )); then echo "TABLE_FIELD_ROWS: REPRO"; exit 3; fi
echo "TABLE_FIELD_ROWS: FAIL"; exit 1
