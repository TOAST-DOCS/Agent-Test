#!/usr/bin/env bash
#
# table-name-keys e2e — 첫 열이 **이름**(필드·코드·제품명)인 표가 ko 와 행 수가
# 어긋나 있을 때, 번역이 그 행만 고치고 나머지 행을 바이트 그대로 두는가
# (cloud-translate `_identifier_row_key` 완화 → table reconcile 의 keyed 경로).
#
# ── 재현하는 결함 ─────────────────────────────────────────────────────────
# table reconcile 은 번역본의 표가 ko 와 행 수가 다르면 번역 전에 표를 ko 에
# 맞춘다. 첫 열이 키로 서면 빠진 행만 번역해 넣고, 아니면 **표 전체를 다시
# 번역**한다 (문구 보존은 프롬프트 지시일 뿐이라 모델 운이다). 첫 열 키는
# `_shared_identifier_keys` 가 정하는데, 첫 셀이 식별자 정규식
# (`^[A-Za-z_$@{][A-Za-z0-9_.\[\]{}:$@/-]*$`) 을 통과해야 했다 — 그래서 ko 와
# 번역본에서 글자 그대로 같은 이름인데도 떨어지는 표가 있었다:
#
#   코퍼스 171 리포 @ alpha (2026-09-28): 표 전체 재번역 100개 중 32개가 이 모양
#     중첩 필드 `- senderKey` · 음수 코드 `-40070`       25
#     공백 든 이름 `Protocol Buffers`                      5
#     이스케이프 `NOT\_INITIALIZED`                        2
#   번역 시뮬레이션 F10 (haiku): ko 가 안 건드린 표에서 26행이 다시 쓰였다
#
# ── 픽스처 (세션 브랜치에 생성 — alpha 상주 아님) ─────────────────────────
#   {ko,en,ja}/table-name-keys.md — pre-align 정렬본. 표 여섯, 절마다 하나.
#   행은 코퍼스의 **실제 행** (출처는 각 표의 주석), 어긋남은 언어마다 다르게:
#     T1 중첩 필드 (Alimtalk friendtalk v2.0)   en: -- recipientNo 누락 · ja: -- senderKey 누락(실제)
#     T2 음수 코드 (Face-Recognition v1.0)      en: ko 에 없는 -40050 여분 · ja: -40070 누락(실제)
#     T3 공백 든 이름 (GameAnvil core-libraries) en: ko 에 없는 Quasar 여분(실제) · ja: Netty 누락
#     T4 이스케이프 (Gamebase unity-ui)          en: UI_TERMS_UNREGISTERED_SEQ 누락 + 한 행의
#                                                    이스케이프 표기가 ko 와 다름 · ja: NOT_LOGGED_IN 누락(실제)
#     C1 대조군 — 한글 첫 열 표 (번역된 첫 열)   en/ja: 한 행 누락 → **여전히 표 전체 재번역**
#     C2 대조군 — 필드 경로 표 (기존 키 경로)     en/ja: 한 행 누락 → 수정 전에도 행 단위
#   ko 편집은 **표 밖의 문장 하나**뿐이다.
#
# ── 판정 ─────────────────────────────────────────────────────────────────
#   [A] 결정적 층 (모델 없음) — 실제 `_reconcile_table_rows` 에 모델 호출만 에코로
#       가로채 **어느 경로를 타는지** 본다.
#       (1) T1~T4: 표 전체 재번역 0 · 빠진 행만 채우고 여분 행만 뗀다      ← 결함
#       (2) C1: 표 전체 재번역 (대조군 — 완화가 번역된 첫 열을 받지 않는다)
#       (3) C2: 행 단위 수리 (대조군 — 기존 경로가 그대로)
#   [B] 산출물 층 — 로컬 translate_pr.py (CLI 엔진, 권장 preset) 실제 번역.
#       (4) 번역 성공 (exit 0, PARTIAL 없음)
#       (5) T1~T4 en/ja: 기존 행이 **전부** 바이트 그대로 (뗀 행 제외)  ← 결함(증상)
#       (6) T1~T4 en/ja: 행 집합과 순서가 ko 와 같다                     ← 기능
#       (7) C1 행 수 = ko · C2 기존 행 보존 + 빠진 행 채움               ← 대조군
#       (8) ko 가 고친 표 밖 문장은 en/ja 에서 바뀌었다                    ← 전제
#
# ── before/after (`--before-dir`) ───────────────────────────────────────
#   같은 ko PR 에 수정 전 코드로 한 번 더 번역을 돌려 번역 PR 을 둘 만든다
#   (`[BEFORE]` / `[AFTER]`). 수정 전 코드는 [A] 가 REPRO 여야 한다 — 아니면
#   픽스처가 조건을 잃은 것이다.
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`TABLE_NAME_KEYS: OK`) — 수정된 코드의 기대값
#   3  결함 재현 (`TABLE_NAME_KEYS: REPRO`) — 수정 전 코드의 기대값.
#      (5) 는 모델에 달려 있어 수정 전에도 우연히 통과할 수 있다 — 수정 전
#      판정의 근거는 결정적인 (1) 이다.
#   1  기능 규칙 실패 또는 픽스처가 조건을 잃음 (`TABLE_NAME_KEYS: FAIL`)
#   2  인프라 — 번역 PR 미감지 · translate_pr.py 비정상 종료
#
# Usage:
#   source ./load_env.sh      # webhook 토글에 필요 (--dry 는 불필요)
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-table-name-keys.sh                       # [A]+[B]
#   bash scripts/e2e-table-name-keys.sh --dry                   # [A] 만
#   bash scripts/e2e-table-name-keys.sh --before-dir <main 체크아웃> --keep
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-namekeys/$TS"
HEAD_BRANCH="translate-test-namekeys/$TS"
DOC="table-name-keys.md"
KEEP=0
DRY=0
BEFORE_DIR=""

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --dry)  DRY=1; shift ;;
    --before-dir) BEFORE_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,66p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
ko_pr_url=""; tx_prs=()

source "$SCRIPTS/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir"/base "$tmpdir"/tx-*; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( KEEP )) || (( DRY )); then
    (( DRY )) || { echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${ko_pr_url:-없음}, 번역 PR: ${tx_prs[*]:-없음})"; }
    return $rc
  fi
  echo; echo "[cleanup] PR 닫기 · 브랜치 정리"
  local p b
  for p in "${tx_prs[@]}"; do gh pr close "$p" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true; done
  [[ -n "$ko_pr_url" ]] && gh pr close "$ko_pr_url" --repo "$REPO" >/dev/null 2>&1 || true
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/translate/${HEAD_BRANCH}*" 2>/dev/null | sed 's|.*refs/heads/||')
  git push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  return $rc
}
trap cleanup EXIT

echo "=== table-name-keys e2e ==="
echo "  AFTER  코드 : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 2>/dev/null | cut -c1-60))"
[[ -n "$BEFORE_DIR" ]] && echo "  BEFORE 코드 : $BEFORE_DIR"
echo "  preset 출처 : $PRESET_CATALOG_DIR"
echo "  session     : $SESSION_BRANCH"
echo "  모드        : $( ((DRY)) && echo '[A] 결정적 층만 (--dry)' || echo '[A]+[B]' )"
echo

[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }

fails=0; repro=0
ok()    { echo "  PASS  $1"; }
bad()   { echo "  FAIL  $1"; fails=$((fails + 1)); }
defect(){ echo "  FAIL  $1  (결함 — 재현)"; repro=$((repro + 1)); }

if (( ! DRY )); then
  : "${DASHBOARD_BASE_URL:?load_env.sh 를 source 하라 (webhook 토글)}"
  : "${DASHBOARD_API_TOKEN:?load_env.sh 를 source 하라 (webhook 토글)}"
  for d in "$CLOUD_TRANSLATE_DIR" ${BEFORE_DIR:+"$BEFORE_DIR"}; do
    [[ -f "$d/.env" ]] || { echo "error: $d/.env 없음" >&2; exit 1; }
  done
  source "$SCRIPTS/e2e-webhook-toggle.sh"
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

# T1 — Alimtalk `ko/friendtalk-api-guide-v2.0.md` 표 21 발췌 (ko 의 탭 구분 그대로).
T1 = {
"ko": "| 이름 |\t타입|\t설명|\n|---|---|---|\n"
      "|header|\tObject|\t헤더 영역|\n|- resultCode|\tInteger|\t결과 코드|\n"
      "|- resultMessage|\tString| 결과 메시지|\n|- isSuccessful|\tBoolean| 성공 여부|\n"
      "|messageSearchResultResponse|\tObject|\t본문 영역|\n|- messages | List |\t메시지 리스트 |\n"
      "|-- requestId | String |\t요청 ID |\n|-- plusFriendId | String |\t플러스친구 ID |\n"
      "|-- senderKey | String |\t발신 키 |\n|-- recipientNo | String |\t수신 번호 |\n"
      "|-- resultCode | String |\t수신 결과 코드 |\n|- totalCount | Integer | 총개수 |\n",
# en: `-- recipientNo` 누락
"en": "| Value | Type | Description |\n| --- | --- | --- |\n"
      "| header | Object | Header area |\n| - resultCode | Integer | Result code |\n"
      "| - resultMessage | String | Result message |\n| - isSuccessful | Boolean | Successful or not |\n"
      "| messageSearchResultResponse | Object | Body area |\n| - messages | List | Message list |\n"
      "| -- requestId | String | Request ID |\n| -- plusFriendId | String | Plus Friend ID |\n"
      "| -- senderKey | String | Sender key |\n"
      "| -- resultCode | String | Receiving result code |\n| - totalCount | Integer | Total count |\n",
# ja: `-- senderKey` 누락 (ja 표 21 의 실제 모양)
"ja": "| 値                     | タイプ | 説明                                 |\n"
      "| --------------------------- | ------- | ---------------------------------------- |\n"
      "| header                      | Object  | ヘッダ領域                              |\n"
      "| - resultCode                | Integer | 結果コード                              |\n"
      "| - resultMessage             | String  | 結果メッセージ                             |\n"
      "| - isSuccessful              | Boolean | 成否                               |\n"
      "| messageSearchResultResponse | Object  | 本文領域                              |\n"
      "| - messages                  | List    | メッセージリスト                            |\n"
      "| -- requestId                | String  | リクエストID                                    |\n"
      "| -- plusFriendId             | String  | プラスフレンドID                                 |\n"
      "| -- recipientNo              | String  | 受信番号                              |\n"
      "| -- resultCode               | String  | 受信結果コード                           |\n"
      "| - totalCount                | Integer | 総個数                                    |\n",
}
# T2 — Face-Recognition `api-guide-v1.0.md` 표 6.
T2 = {
"ko": r"""| resultCode | resultMessage | 설명 |
| --- | --- | --- |
|-40000| InvalidParam | 파라미터에 오류가 있음 |
|-40010| InvalidGroupID | 그룹 아이디 오류 |
|-40020| DuplicatedGroupID | 중복된 그룹 아이디 |
|-40070| ServiceQuotaExceededException | 생성할 수 있는 최대 그룹 개수 초과 |
|-41000| UnauthorizedAppKey | 승인되지 않은 앱키 |
|-50000| InternalServerError | 서버 오류 |
""",
# en: ko 에 없는 `-40050` 여분
"en": r"""| resultCode | resultMessage | Description |
| --- | --- | --- |
|-40000| InvalidParam | The parameter contains an error |
|-40010| InvalidGroupID | Group ID error |
|-40020| DuplicatedGroupID | Duplicate group ID |
|-40050| InvalidImageFormat | Unsupported image format |
|-40070| ServiceQuotaExceededException | Exceeded the maximum number of groups you can create |
|-41000| UnauthorizedAppKey | Unauthorized Appkey |
|-50000| InternalServerError | Server error |
""",
# ja: `-40070` 누락 (실제 모양)
"ja": r"""| resultCode | resultMessage | 説明 |
| --- | --- | --- |
|-40000| InvalidParam | パラメータにエラーがある |
|-40010| InvalidGroupID | グループIDエラー |
|-40020| DuplicatedGroupID | 重複したグループID |
|-41000| UnauthorizedAppKey | 承認されていないアプリケーションキー |
|-50000| InternalServerError | サーバーエラー |
""",
}
# T3 — GameAnvil `server-basic/server-basic-05-core-libraries.md` 표 1.
T3 = {
"ko": r"""| 라이브러리       | 용도                            |
| ---------------- | ------------------------------- |
| ZeroMQ           | 서버의 IPC                      |
| Netty            | 서버-클라이언트 통신            |
| Protocol Buffers | 서버-클라이언트 메시지 직렬화   |
""",
# en: ko 에 없는 `Quasar` 여분 (실제 모양)
"en": r"""| Library       | Usage                            |
| ---------------- | ------------------------------- |
| Quasar           | Supports Fiber-based Continuation |
| ZeroMQ           | Server's IPC                      |
| Netty            | Communication between server and client            |
| Protocol Buffers | Parallelization of messages between server and client   |
""",
# ja: `Netty` 누락
"ja": r"""| ライブラリ     | 用途                          |
| ---------------- | ------------------------------- |
| ZeroMQ           | サーバーのIPC                      |
| Protocol Buffers | サーバー-クライアントメッセージのシリアライズ  |
""",
}
# T4 — Gamebase `unity-ui.md` 표 10.
T4 = {
"ko": r"""| Error | Error Code | Description |
| --- | --- | --- |
| NOT\_INITIALIZED | 1 | Gamebase가 초기화되어 있지 않습니다. |
| NOT\_LOGGED_IN | 2 | 로그인이 필요합니다. (Standalone에 한함) |
| UI\_TERMS\_UNREGISTERED\_SEQ | 6923 | 등록되지 않은 약관 Seq 값을 설정하였습니다. |
| UI\_TERMS\_ALREADY\_IN\_PROGRESS\_ERROR | 6924 | Terms API 호출이 아직 완료되지 않았습니다.<br/>잠시 후 다시 시도하세요. |
""",
# en: `UI_TERMS_UNREGISTERED_SEQ` 누락 + `NOT_LOGGED_IN` 을 ko 와 다르게 이스케이프
"en": r"""| Error | Error Code | Description |
| --- | --- | --- |
| NOT\_INITIALIZED | 1 | Gamebase not initialized. |
| NOT\_LOGGED\_IN | 2 | Login is required. (Only Standalone) |
| UI\_TERMS\_ALREADY\_IN\_PROGRESS\_ERROR | 6924 | The Terms API call has not been completed yet.<br/>Please try again later. |
""",
# ja: `NOT_LOGGED_IN` 누락 (실제 모양)
"ja": r"""| Error | Error Code | Description |
| --- | --- | --- |
| NOT\_INITIALIZED | 1 | Gamebaseが初期化されていません。 |
| UI\_TERMS\_UNREGISTERED\_SEQ | 6923 | 登録されていない約款Seq値を設定しました。 |
| UI\_TERMS\_ALREADY\_IN\_PROGRESS\_ERROR | 6924 | 以前に呼び出されたTerms APIがまだ完了していません。<br/>しばらくしてから再度試行してください。 |
""",
}
# C1 — 대조군: 첫 열이 번역되는 표. en/ja 모두 `발송 시간` 행 누락.
C1 = {
"ko": """| 항목 | 설명 |
| --- | --- |
| 알림 설정 | 알림을 받을 채널을 선택합니다. |
| 수신 대상 | 알림을 받을 멤버를 지정합니다. |
| 발송 시간 | 알림을 보낼 시간대를 설정합니다. |
| 보관 기간 | 발송 이력을 보관할 기간입니다. |
""",
"en": """| Item | Description |
| --- | --- |
| Notification settings | Select the channel to receive notifications. |
| Recipients | Specify the members who receive notifications. |
| Retention period | Period to keep the delivery history. |
""",
"ja": """| 項目 | 説明 |
| --- | --- |
| 通知設定 | 通知を受け取るチャンネルを選択します。 |
| 受信対象 | 通知を受け取るメンバーを指定します。 |
| 保管期間 | 送信履歴を保管する期間です。 |
""",
}
# C2 — 대조군: 식별자 정규식을 원래 통과하던 필드 경로 표. en/ja 모두 `templateId` 누락.
C2 = {
"ko": """| 이름 | 타입 | 설명 |
| --- | --- | --- |
| header.isSuccessful | Boolean | 성공 여부 |
| header.resultCode | Integer | 결과 코드 |
| body.data.templateId | String | 템플릿 ID |
| body.data.templateName | String | 템플릿 이름 |
""",
"en": """| Name | Type | Description |
| --- | --- | --- |
| header.isSuccessful | Boolean | Whether successful |
| header.resultCode | Integer | Result code |
| body.data.templateName | String | Template name |
""",
"ja": """| 名前 | タイプ | 説明 |
| --- | --- | --- |
| header.isSuccessful | Boolean | 成否 |
| header.resultCode | Integer | 結果コード |
| body.data.templateName | String | テンプレート名 |
""",
}
HEAD = {
"ko": ("표 첫 열 키 e2e 픽스처", "이 문서는 자동 생성된 e2e 픽스처입니다",
       "개요", "메시지 조회 API의 응답 필드와 오류 코드를 설명합니다.",
       ["중첩 필드", "오류 코드", "라이브러리", "오류 이름", "설정 항목", "템플릿 필드"]),
"en": ("Table first-column key e2e fixture", "This document is a generated e2e fixture",
       "Overview", "This document describes the response fields and error codes of the message query API.",
       ["Nested Fields", "Error Codes", "Libraries", "Error Names", "Settings", "Template Fields"]),
"ja": ("表の先頭列キー e2e フィクスチャ", "この文書は自動生成された e2e フィクスチャです",
       "概要", "メッセージ照会APIのレスポンスフィールドとエラーコードを説明します。",
       ["ネストしたフィールド", "エラーコード", "ライブラリ", "エラー名", "設定項目", "テンプレートフィールド"]),
}
IDS = ["tnk-t1", "tnk-t2", "tnk-t3", "tnk-t4", "tnk-c1", "tnk-c2"]
MARK = "<!-- pre-align:aligned sig=e2e0f1e1d01 -->\n\n"
for lang in ("ko", "en", "ja"):
    title, gen, ov, prose, heads = HEAD[lang]
    out = [MARK, '<a id="tnk"></a>\n', f"# {title}\n\n", f"{gen} ({ts}).\n\n",
           '<a id="tnk-overview"></a>\n', f"## {ov} {{ #tnk-overview }}\n\n", f"{prose}\n"]
    for aid, h, tbl in zip(IDS, heads, (T1, T2, T3, T4, C1, C2)):
        out += ["\n", f'<a id="{aid}"></a>\n', f"## {h} {{ #{aid} }}\n\n", tbl[lang]]
    io.open(os.path.join(lang, doc), "w", encoding="utf-8", newline="").write("".join(out))
print(f"  생성: {{ko,en,ja}}/{doc}  (표 6: T1~T4 이름 키 · C1 한글 첫 열 · C2 필드 경로)")
PY
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(table-name-keys): 픽스처 시드 ($TS)"
session_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$SESSION_BRANCH"

# ── 2) ko 편집 — 표 밖의 문장 하나 ────────────────────────────────────────
echo "[2] ko 편집 — 표 밖의 문장 하나만"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" <<'PY'
import io, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
OLD = "메시지 조회 API의 응답 필드와 오류 코드를 설명합니다."
NEW = "메시지 조회 API가 돌려주는 응답 필드와, 요청이 실패했을 때의 오류 코드를 설명합니다."
assert t.count(OLD) == 1
io.open(p, "w", encoding="utf-8", newline="").write(t.replace(OLD, NEW))
print(f"  {p}: 개요 문장 1개 수정 (표는 그대로)")
PY
git add -- "ko/$DOC"
git commit -q -m "e2e(table-name-keys): ko 편집 — 표 밖 문장 ($TS)"
(( DRY )) || git push -q origin "$HEAD_BRANCH"
git worktree add -q --detach "$tmpdir/base" "$session_sha"

# ── 3) [A] 결정적 층 ───────────────────────────────────────────────────────
# $1 = 코드 디렉터리, 출력: A_T=1(T1~T4 행 단위) A_C1=1 A_C2=1 A_REWRITE=<T 중 재작성 수>
run_A() {
  local dir="$1" out="$tmpdir/reconcile-$2.json"
  set +e
  (cd "$dir" && "$CLOUD_TRANSLATE_PY" - "$tmpdir/base" "$DOC" "$out" <<'PY') 2>"$out.err"
import asyncio, io, json, logging, os, sys
sys.path[:0] = ["translate", "."]
logging.disable(logging.WARNING)
from app.translator import Translator
base, doc, outp = sys.argv[1:4]

class Echo(Translator):
    """진짜 Translator — 모델 호출 한 겹만 에코로 가로챈다."""
    def __init__(self):
        super().__init__(glossary=None)
    async def translate(self, content, reference=None, target_lang="en", target_dir="en", *a, **k):
        return content
    async def _translate_chunk_uncached(self, content, *a, **k):
        return content
    async def _verify_chunk_uncached(self, *a, **k):
        return ""

rd = lambda lang: io.open(os.path.join(base, lang, doc), encoding="utf-8", newline="").read()

async def main():
    res = {}
    for lang in ("en", "ja"):
        rep = {}
        await Echo()._reconcile_table_rows(rd(lang), rd("ko"), None, lang, lang, report=rep)
        r = rep.get("table_reconcile", {})
        res[lang] = dict(backfilled=sorted(r.get("backfilled_rows", [])),
                         dropped=sorted(r.get("dropped_rows", [])),
                         rewritten_tables=sorted(d["table"] for d in r.get("rewrite_detail", [])))
    json.dump(res, open(outp, "w"), ensure_ascii=False, indent=2)
asyncio.run(main())
PY
  local prc=$?
  set -e
  if (( prc != 0 )); then echo "error: [A] 검사 실행 실패 ($dir)" >&2; tail -20 "$out.err" >&2; KEEP=1; exit 2; fi
  sed 's/^/    /' "$out"; echo
  eval "$(python3 - "$out" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
# 표 번호 = 문서 안 위치: 1..4 = T1~T4, 5 = C1, 6 = C2
EXP = {"en": dict(backfilled=["-- recipientNo", "UI_TERMS_UNREGISTERED_SEQ", "body.data.templateId"],
                  dropped=["-40050", "Quasar"]),
       "ja": dict(backfilled=["-- senderKey", "-40070", "NOT_LOGGED_IN", "Netty", "body.data.templateId"],
                  dropped=[])}
t_ok = all(set(d[l]["rewritten_tables"]) == {5} and d[l]["backfilled"] == sorted(EXP[l]["backfilled"])
           and d[l]["dropped"] == sorted(EXP[l]["dropped"]) for l in ("en", "ja"))
c1 = all(5 in d[l]["rewritten_tables"] for l in ("en", "ja"))
c2 = all("body.data.templateId" in d[l]["backfilled"] for l in ("en", "ja"))
rw = sum(len({1, 2, 3, 4} & set(d[l]["rewritten_tables"])) for l in ("en", "ja"))
print(f"A_T={int(t_ok)}; A_C1={int(c1)}; A_C2={int(c2)}; A_REWRITE={rw}")
PY
)"
}

echo
echo "[3] [A] 결정적 층 — table reconcile 이 타는 경로 (모델 없음)"
if [[ -n "$BEFORE_DIR" ]]; then
  echo "  --- BEFORE ($BEFORE_DIR)"
  run_A "$BEFORE_DIR" before
  if (( A_T == 0 && A_REWRITE == 8 && A_C1 && A_C2 )); then
    echo "  BEFORE: T1~T4 를 en/ja 모두 표 전체 재번역 (8/8) — 결함 재현 (기대대로)"
  else
    bad "BEFORE: 수정 전 코드가 결함을 재현하지 않는다 — 픽스처가 조건을 잃었다 (A_REWRITE=$A_REWRITE/8)"
  fi
  echo "  --- AFTER ($CLOUD_TRANSLATE_DIR)"
fi
run_A "$CLOUD_TRANSLATE_DIR" after
(( A_T ))  && ok "(1) T1~T4: 표 전체 재번역 0 · 빠진 행만 채우고 여분 행만 뗀다" \
           || defect "(1) T1~T4: 표를 통째로 다시 번역한다 (en+ja $A_REWRITE/8 개)"
(( A_C1 )) && ok "(2) C1 (한글 첫 열): 여전히 표 전체 재번역" \
           || bad "(2) C1: 번역된 첫 열 표가 키 경로로 들어갔다 — 완화가 너무 넓다"
(( A_C2 )) && ok "(3) C2 (필드 경로): 빠진 행만 채운다" \
           || bad "(3) C2: 기존 키 경로가 달라졌다"

if (( DRY )); then
  echo
  if (( fails == 0 && repro == 0 )); then echo "TABLE_NAME_KEYS: OK"; exit 0; fi
  if (( fails == 0 )); then echo "TABLE_NAME_KEYS: REPRO"; exit 3; fi
  echo "TABLE_NAME_KEYS: FAIL"; exit 1
fi

# ── 4) [B] 실제 번역 ───────────────────────────────────────────────────────
echo
echo "[4] [B] 실제 번역 — 로컬 translate_pr.py (CLI 엔진, 권장 preset)"
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(table-name-keys): 표 밖 문장 수정 — 첫 열이 이름인 어긋난 표 ($TS)" \
  --body "cloud-translate table reconcile 검증 — 첫 열이 이름(필드·코드·제품명)인 표는 ko 가 안 건드렸을 때 빠진 행만 채우고 나머지 행을 바이트 그대로 두어야 한다." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"
preset_eval="$(python3 "$SCRIPTS/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 1
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"

# $1 = 코드 디렉터리, $2 = before|after
run_B() {
  local dir="$1" tag="$2" log="$tmpdir/translate-$2.log" tx_pr tx_head
  echo
  echo "  --- [$tag] $dir"
  set +e
  (cd "$dir" && "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
      --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") 2>&1 | tee "$log" \
    | grep -E "Table reconcile|Section-diff|anchor splice|Translation PR|PARTIAL|ERROR" | sed 's/^/    /'
  local tx_rc=${PIPESTATUS[0]}
  set -e
  if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$log"; then
    ok "(4) [$tag] 번역 성공 (exit 0, PARTIAL 없음)"
  else
    bad "(4) [$tag] 번역 실패/부분 (exit $tx_rc)"
  fi
  grep -o 'engine=[a-z-]*' "$log" | sort | uniq -c | sed 's/^/    /' || true
  tx_pr="$(grep -oE 'Translation PR: https://[^ ]+' "$log" | tail -1 | awk '{print $NF}')"
  [[ -n "$tx_pr" ]] || { echo "error: [$tag] 번역 PR 미감지 — 로그 $log" >&2; KEEP=1; exit 2; }
  tx_prs+=("$tx_pr")
  echo "  [$tag] 번역 PR: $tx_pr"
  e2e_label_pr "$REPO" "$tx_pr" || true
  if [[ -n "$BEFORE_DIR" ]]; then
    local T; T="$(echo "$tag" | tr a-z A-Z)"
    gh pr edit "$tx_pr" --repo "$REPO" --title "[$T] table-name-keys 대조 — $( [[ $tag == before ]] && echo '수정 전 코드(main)' || echo '첫 열 키 완화 적용') ($TS)" >/dev/null || true
  fi
  tx_head="$(gh pr view "$tx_pr" --repo "$REPO" --json headRefName --jq .headRefName)"
  git fetch -q origin "$tx_head"
  git worktree add -q --detach "$tmpdir/tx-$tag" "origin/$tx_head"

  eval "$(python3 - "$tmpdir/base" "$tmpdir/tx-$tag" "$DOC" <<'PY'
import io, os, re, sys
base, tx, doc = sys.argv[1:4]
def rd(root, lang):
    try:
        return io.open(os.path.join(root, lang, doc), encoding="utf-8", newline="").read()
    except OSError:
        return None
def table(text, aid):
    """`{ #aid }` 절의 첫 표 데이터 행."""
    lines = text.split("\n")
    i = next(k for k, l in enumerate(lines) if "{ #%s }" % aid in l)
    out, on = [], False
    for l in lines[i + 1:]:
        if l.startswith("#"): break
        if l.startswith("|") and re.match(r"^\|[\s:|-]+\|?\s*$", l): on = True; continue
        if on and l.startswith("|"): out.append(l)
        elif on and out: break
    return out
def key(r):   # cloud-translate `_identifier_row_key` 와 같은 정규화
    c = r.strip().strip("|").split("|")[0].replace("**", "").replace("`", "")
    c = re.sub(r"\\([!-/:-@\[-`{-~])", r"\1", c).replace("\xa0", " ")
    c = re.sub(r"\s+", " ", c).strip()
    return re.sub(r"^(-+) ?(?=[A-Za-z])", r"\1 ", c)
DROP = {"en": {"-40050", "Quasar"}, "ja": set()}
ko = rd(base, "ko")
keep = order = missing = 0; lost_all = []
for lang in ("en", "ja"):
    before, after = rd(base, lang), rd(tx, lang)
    if after is None:
        missing += 1; continue
    lang_keep = lang_order = True
    for aid in ("tnk-t1", "tnk-t2", "tnk-t3", "tnk-t4"):
        br, ar = table(before, aid), table(after, aid)
        lost = [key(r) for r in br if r not in ar and key(r) not in DROP[lang]]
        if lost: lang_keep = False; lost_all.append(f"{lang}:{aid}:{len(lost)}")
        if [key(r) for r in ar] != [key(r) for r in table(ko, aid)]: lang_order = False
    keep += lang_keep; order += lang_order
c1 = sum(len(table(rd(tx, l), "tnk-c1")) == len(table(ko, "tnk-c1")) for l in ("en", "ja") if rd(tx, l))
c2 = sum(all(r in table(rd(tx, l), "tnk-c2") for r in table(rd(base, l), "tnk-c2"))
         and "body.data.templateId" in [key(r) for r in table(rd(tx, l), "tnk-c2")]
         for l in ("en", "ja") if rd(tx, l))
prose = 0
for lang in ("en", "ja"):
    after = rd(tx, lang)
    if after is None: continue
    lines = rd(base, lang).split("\n")
    h = next(i for i, l in enumerate(lines) if "{ #tnk-overview }" in l)
    p = next(l for l in lines[h + 1:] if l.strip())
    prose += p not in after.split("\n")
print(f"B_KEEP={keep}; B_ORDER={order}; B_C1={c1}; B_C2={c2}; B_PROSE={prose}; B_MISSING={missing}; B_LOST='{' '.join(lost_all)}'")
PY
)"
  if (( B_MISSING )); then
    bad "(5) [$tag] 번역 PR 에 픽스처 문서가 없다 ($B_MISSING 개)"
  elif (( B_KEEP == 2 )); then
    ok "(5) [$tag] T1~T4 en/ja 기존 행이 전부 바이트 그대로"
  else
    defect "(5) [$tag] ko 가 안 건드린 표의 기존 행이 다시 쓰였다 (${B_LOST})"
  fi
  (( B_ORDER == 2 )) && ok "(6) [$tag] T1~T4 행 집합·순서가 ko 와 같다" \
                     || bad "(6) [$tag] T1~T4 행 집합/순서가 ko 와 다르다 ($B_ORDER/2)"
  (( B_C1 == 2 && B_C2 == 2 )) && ok "(7) [$tag] 대조군: C1 행 수 = ko · C2 기존 행 보존 + templateId 채움" \
                               || bad "(7) [$tag] 대조군 실패 (C1 $B_C1/2 · C2 $B_C2/2)"
  (( B_PROSE == 2 )) && ok "(8) [$tag] ko 가 고친 표 밖 문장은 en/ja 에서 다시 번역됐다" \
                     || bad "(8) [$tag] ko 가 고친 문장이 en/ja 에 반영되지 않았다 ($B_PROSE/2)"
}

if [[ -n "$BEFORE_DIR" ]]; then
  # BEFORE 의 결과는 판정 합계에 넣지 않는다 — 결함 재현이 기대값이다.
  f0=$fails r0=$repro
  run_B "$BEFORE_DIR" before
  before_fails=$((fails - f0)) before_repro=$((repro - r0))
  fails=$f0 repro=$r0
fi
run_B "$CLOUD_TRANSLATE_DIR" after

echo
echo "[6] 결과"
echo "  ko PR   : $ko_pr_url"
echo "  번역 PR : ${tx_prs[*]}"
[[ -n "$BEFORE_DIR" ]] && echo "  BEFORE  : 기능 실패 $before_fails · 결함 재현 $before_repro (합계에서 제외)"
if (( fails == 0 && repro == 0 )); then echo "TABLE_NAME_KEYS: OK"; exit 0; fi
KEEP=1
if (( fails == 0 )); then echo "TABLE_NAME_KEYS: REPRO"; exit 3; fi
echo "TABLE_NAME_KEYS: FAIL"; exit 1
