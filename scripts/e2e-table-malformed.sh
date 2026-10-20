#!/usr/bin/env bash
#
# 표 reconcile 의 선정 가드 e2e — cloud-translate PR (D2 + 최빈값 스키마 비교) 검증.
#
# 검증 대상: **표 reconcile 이 어떤 표를 수리 대상으로 고르는가.**
#   (A) 셀 안 줄바꿈으로 끊긴 표는 수리하지 않는다 (행 수를 신뢰할 수 없으므로).
#   (B) 셀 수 이상치 행 하나 때문에 스키마가 다르다고 오판하지 않는다.
#   (C) 그러면서도 진짜로 어긋난 표는 여전히 수리한다.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# (A) DDoS-Guard ko/l7-ddos-settings-guide.md. 작성자가 `<BR>` 대신 여러 줄
#     nginx 샘플을 셀에 붙여넣어, `_table_region` 이 그 행에서 멈춘다 — ko 는
#     1행으로 보이고 en/ja 는 10·9·3행. reconcile 은 행 수 차이를 "ko 가 정본"
#     으로 해소하며 대상 행을 **삭제** 하므로, 이 문서 하나에서 en 19행 · ja
#     16행이 결정적으로, 그리고 조용히 사라질 상태였다 (완전성 backstop 은 ko
#     행이 결과에서 빠질 때만 발동하고, ko 의 유일한 가시 행은 존재한다).
# (B) OCR#177 (빌드 #370). `document-ocr-api-guide-v2.0.md` 표#21 은 ko 10행 /
#     en 10행에 실제 스키마도 같은데, en 세 행이 파이프 오류로 4셀 대신 6·3·3셀
#     이었다. `_table_ncols` 가 **최소** 셀 수라 en=3 / ko=4 로 읽혀 열 동기화
#     (header 포함 전체 재작성)가 선정 — 모델 호출 4회, en 은 검증 2회 실패로
#     미수리, ja 는 무의미한 열 동기화. 코퍼스 전수로는 이 판정 123건 중 34건이
#     오탐이고 그중 27건은 행 수까지 일치하는 표다.
#
# ── 왜 결함 주입이 필요 없나 ───────────────────────────────────────────────
# 수정 전 동작이 **결정적** 이다. (A) 는 첫 셀이 숫자라 keyed 경로를 타고 ko 에
# 없는 키의 대상 행을 그대로 drop 한다. (B) 는 선정 자체가 결정적이고 열 동기화
# 로그가 남는다. 모델 편차와 무관하게 수정 전/후가 갈리므로, 픽스처를 심고
# 결과를 바이트로 비교하면 된다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   0) webhook 비활성화   1) 세션 브랜치
#   2) **시드** — ko/en/ja 에 표 3개(A/B/C)를 세션 base 에 커밋
#   3) head 브랜치에서 **표를 건드리지 않는 ko 산문 1줄** 수정 → PR
#      (reconcile 은 splice 상류에서 문서 전체 표를 훑으므로, 표를 건드리지
#       않아도 세 표 전부가 판정 대상이 된다 — 그게 이 결함의 성립 조건이다)
#   4) 로컬 translate_pr.py (TRANSLATE_LOG_LEVEL=debug)
#   5) 판정 (아래 9개 규칙)   6) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) 번역 성공 (exit 0, PARTIAL 없음)
#   (2) [A] en/ja 표 A 의 3개 행이 **전부 남아 있다** — 수정 전엔 2행이 삭제된다
#   (3) [A] en/ja 표 A 가 시드와 **바이트 동일** (수리도, churn 도 없어야 한다)
#   (4) [E] 로그에 표 reconcile 의 끊긴 표 건너뜀 (`Table reconcile (lang=en|ja): skipped N
#       cut table(s)`, cloud-translate#1331) — en·ja 양쪽. 건너뛴 직접 증거. 예전에는 미머지
#       #697 의 `skipped 1 malformed` 를 찾았다 (#697 은 #1331 로 대체돼 닫혔고, 케이스 A 는
#       main 에서 행이 보존돼 가드가 발동할 자리가 아니다). E 를 끄면 해당 없음(PASS)
#   (5) [B] en/ja 표 B 가 시드와 **바이트 동일** (이상치 행까지 그대로)
#   (6) [B] 로그의 column-synced 가 0 — 열 동기화가 선정되지 않았다
#   (7) [C] en/ja 표 C 에 ko 의 4번째 행이 **추가** 되었다 (가드가 진짜 수리를
#       막지 않는지 — 이게 이 수정의 진짜 위험이다)
#   (8) [C] 표 C 의 기존 3행은 바이트 그대로 (keyed backfill 의 계약)
#   (9) 번역 PR 본문에 표 A 가 "수리하지 않았습니다" 로 공개된다 (#691 공지)
#
# ── (D) 대상 쪽 절단 — opt-in (`--case D` / `--with-target-cut`, 기본 꺼짐) ──
# 재현하는 사고 (2026-10-15): TOAST-DOCS/Log-Crash-Search ko PR #134 → 번역 PR
#   https://github.com/TOAST-DOCS/Log-Crash-Search/pull/137
#   ja/console-guide.md 의 이슈 상세 표가 8행 연속 → 빈 줄 1개 → 표의 마지막
#   2행이 **고아 파이프 줄**로 남아 있었다 (ko 는 10행 연속). 고아 줄은 구분 행이
#   없어 `_table_region` 이 표로 세지 않으므로 reconcile 은 ko 10 ↔ ja 8 로 읽고,
#   빠진 2행을 새로 번역해 표에 **덧붙인 뒤 고아 2줄은 그대로 둔다** → 같은 내용이
#   두 번. (A) 의 거울상(ko 쪽 절단 → 대상 행 삭제)이고, 대상 쪽 절단은 이 케이스
#   전까지 어떤 e2e 에도 없었다.
# 픽스처 D: ko 8행 연속(첫 열 한국어 라벨) · en/ja 는 같은 8행을 번역하되 마지막
#   2행을 빈 줄 하나로 표에서 떼어 둔다. 시드는 A/B/C 와 같이 세션 base 에만.
# 판정 (결정적, 모델 판단 없음 — en/ja 각각, 범위는 D 절):
#   (11) 고아 2행의 첫 셀 라벨이 파일 전체에서 **정확히 1번** (중복 없음)
#   (12) D 표의 데이터 행 수 == ko 의 행 수
#   (13) D 절의 파이프 데이터 줄 수 == ko 행 수 (표 밖 고아 줄이 남지 않았다 —
#        모델이 라벨을 고아와 다르게 번역해 (11)이 통과해도 중복을 잡는다)
#   (14) D 절에 `<todo` 마커 없음
#   요약으로 `[D] REPRO` (하나라도 실패) / `[D] OK` 를 찍는다.
# 현재 기대 결과: **[D] REPRO → RESULT: FAIL** (파이프라인 수정 전). 그래서
#   opt-in 이다 — e2e-suite.sh 의 table-malformed plan 은 인자 없이 이 스크립트를
#   부르므로 D 를 켜지 않고, A/B/C 판정은 오늘과 같다. 수정이 머지되면 [D] OK 를
#   확인한 뒤 기본값으로 올릴지 정한다.
#
# ── (E) 대상 쪽 셀 중간 줄바꿈 절단 — **기본 켜짐** (`--no-case-e` 로 끔) ────────
# 재현하는 사고 (2026-10-19): TOAST-DOCS/E-mail ko PR
#   https://github.com/TOAST-DOCS/E-mail/pull/162 → 번역 PR
#   https://github.com/TOAST-DOCS/E-mail/pull/163
#   en/dkim-record.md 의 DKIM-Signature 표(ko 10행)에서 en 의 `s` 행 설명 셀이
#   **하드 줄바꿈**으로 끊겨 있었다 — 다음 줄 `public key this ... '. |` 은 `|` 로
#   시작하지 않으므로 `_table_region` 이 거기서 표를 끝내고, `_doc_table_regions` 는
#   en 표를 3행(v, a, s)으로 읽는다. 기본 켜짐인 `_reconcile_table_rows` 가 그 3행
#   region 만 ko 10행으로 수리하고, region 밖의 옛 조각(`s` 행의 꼬리 + 옛 h, b, bh,
#   l, d, t, x 행)은 그대로 남아 배포 페이지에 같은 필드가 **두 번** 나온다.
#   이상적 모델 재생(모델이 완벽한 10행 표를 돌려줌)으로도 조각이 남으므로 모델과
#   무관한 결정적 파이프라인 결함이다. ko 는 멀쩡하고 대상 쪽만 끊긴 세 번째 모양
#   — (A) 는 ko 쪽 절단, (D) 는 대상 쪽 빈 줄 절단, (E) 는 대상 쪽 셀 안 줄바꿈 절단.
#   코퍼스 노출 (master, 대상 리포 101): en/ja 표 7개 · ko 0.
# 픽스처 E: 첫 열이 ASCII 짧은 키(v, a, s, h, b, bh, l, d, t, x)인 필드 표. ko 10행
#   연속 · en/ja 는 같은 표를 번역하되 3번째 행(`s`)의 설명 셀을 하드 줄바꿈으로
#   끊는다 (다음 줄은 텍스트로 시작해 ` |` 로 끝남). 구분 행은 헤더와 셀 수가 같아
#   절단이 유일한 결함이다. 시드 기준 `_doc_table_regions` 는 ko 10행 / en·ja 3행.
#   시드는 A/B/C/D 와 같이 세션 base 에만.
# 판정 (결정적, 모델 판단 없음 — en/ja 각각, 범위는 E 절):
#   (15) ko 표의 첫 열 키가 E 절의 표 행 첫 셀로 **각각 정확히 1번** (중복 없음 —
#        결함은 h…x 를 두 번 남긴다)
#   (16) E 절에 끊긴 셀의 꼬리 문구로 **시작하는 줄이 없다** (고아 조각이 지워졌거나
#        한 행으로 합쳐졌다)
#   (17) 사이트 렌더러(`shared.markup_lint._converter`)로 E 절을 렌더하면 `<table>`
#        정확히 1개, `<tr>` 수 == ko 행 수 + 1(헤더), 표 밖에 `| x |` 모양 텍스트 없음
#   (18) E 절에 `<todo` 마커 없음
#   요약으로 `[E] REPRO` (하나라도 실패) / `[E] OK` 를 찍는다.
# 현재 기대 결과: **[E] OK** — cloud-translate#1331 (2026-10-20 머지) 이 끊긴 표의
#   reconcile 을 건너뛰고, post-maint 의 마크업 정정(M7)이 줄을 잇는다. 실측: main(#1331
#   이전) Agent-Test#1880 `[E] REPRO` → #1331 #1882 `[E] OK` (둘 다 TRANSLATE_POST_MAINT=true).
#   그래서 기본으로 켜 회귀 판정으로 쓴다. post-maint 를 끄고 돌리면 표는 끊긴 채 남아
#   (16)(17) 이 FAIL 한다 — 중복(15)은 그래도 생기지 않아야 한다.
#
# Usage:
#   source ./load_env.sh
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     TRANSLATE_POST_MAINT=true \
#     bash scripts/e2e-table-malformed.sh [--keep] [--case D|E|D,E ...] [--with-target-cut] [--no-case-e]
#   (`--case` 는 반복하거나 쉼표로 묶을 수 있다. `--with-target-cut` = `--case D`.
#    E 는 기본 켜짐 — `--no-case-e` 로 끈다)
#
# 의존성: git, gh (로그인), python3
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-tablemal/$TS"
HEAD_BRANCH="translate-test-tablemal/$TS"
DOC="overview.md"
KEEP=0
CASE_D=0   # (D) 대상 쪽 절단 — opt-in, 기본 꺼짐 (헤더 주석 참고)
CASE_E=1   # (E) 대상 쪽 셀 중간 줄바꿈 절단 — 기본 켜짐 (#1331 머지, 헤더 주석 참고)

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    --with-target-cut) CASE_D=1; shift ;;
    --no-case-e) CASE_E=0; shift ;;
    --case)
      IFS=',' read -r -a _cases <<< "${2:-}"
      [[ ${#_cases[@]} -gt 0 ]] || { echo "unknown --case: (D, E 지원)" >&2; exit 1; }
      for _c in "${_cases[@]}"; do
        case "$_c" in
          D|d) CASE_D=1 ;;
          E|e) CASE_E=1 ;;
          *) echo "unknown --case: $_c (D, E 지원)" >&2; exit 1 ;;
        esac
      done
      shift 2 ;;
    -h|--help) sed -n '1,121p' "$0"; exit 0 ;;
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

# ── 픽스처 ────────────────────────────────────────────────────────────────
# 표 A: ko 의 첫 행 예시 셀에 **실제 줄바꿈**. en/ja 는 같은 내용을 `<BR>` 로
#       정상 표기 → ko 는 1행으로 보이고 en/ja 는 3행. 첫 셀이 숫자라 keyed
#       경로가 잡으므로 수정 전 동작은 "en/ja 의 2·3행 삭제" 로 결정적이다.
# 표 B: 세 언어 모두 3행 4열인데, en/ja 의 2번째 행만 파이프가 하나 빠져 3셀.
#       최소값 비교면 ko=4 / target=3 으로 읽혀 열 동기화가 선정된다.
# 표 C: 대조군 — en/ja 에 ko 의 4번째 행(`SVC-104`)이 없다. 잘 정렬된 keyed
#       표이므로 가드와 무관하게 **수리되어야** 한다.
fixture_ko() { cat <<'EOF'

<a id="e2e-table-malformed"></a>
### 표 선정 가드 픽스처

아래 표들은 e2e 픽스처입니다.

| 번호 | 항목 | 예시 |
|---|---|---|
| 1 | 요청 속도 제한 | http {
   limit_req_zone $binary_remote_addr zone=z:10m;
}
| 2 | 동시 연결 제한 | limit_conn z 10; |
| 3 | 본문 크기 제한 | client_max_body_size 1m; |

두 번째 표입니다.

| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| fileType | String | Y | 파일 확장자입니다. |
| resolution | String | N | 권장 해상도입니다. |
| idType | String | Y | 신분증 종류입니다. |

세 번째 표입니다.

| 코드 | 이름 | 설명 |
|---|---|---|
| SVC-101 | 기본 | 기본 서비스입니다. |
| SVC-102 | 표준 | 표준 서비스입니다. |
| SVC-103 | 고급 | 고급 서비스입니다. |
| SVC-104 | 전용 | 전용 서비스입니다. |
EOF
}
fixture_en() { cat <<'EOF'

<a id="e2e-table-malformed"></a>
### Table selection guard fixture

The tables below are e2e fixtures.

| Number | Item | Example |
|---|---|---|
| 1 | Request rate limit | http {<BR>   limit_req_zone $binary_remote_addr zone=z:10m;<BR>} |
| 2 | Connection limit | limit_conn z 10; |
| 3 | Request body size limit | client_max_body_size 1m; |

The second table.

| Name | Type | Required | Description |
|---|---|---|---|
| fileType | String | Y | File extension. |
| resolution | String | N  Recommended resolution. |
| idType | String | Y | ID type. |

The third table.

| Code | Name | Description |
|---|---|---|
| SVC-101 | Basic | Basic service. |
| SVC-102 | Standard | Standard service. |
| SVC-103 | Advanced | Advanced service. |
EOF
}
fixture_ja() { cat <<'EOF'

<a id="e2e-table-malformed"></a>
### テーブル選定ガードのフィクスチャ

以下のテーブルはe2eフィクスチャです。

| 番号 | 項目 | 例 |
|---|---|---|
| 1 | リクエスト速度制限 | http {<BR>   limit_req_zone $binary_remote_addr zone=z:10m;<BR>} |
| 2 | 同時接続制限 | limit_conn z 10; |
| 3 | 本文サイズ制限 | client_max_body_size 1m; |

2番目のテーブルです。

| 名前 | タイプ | 必須 | 説明 |
|---|---|---|---|
| fileType | String | Y | ファイル拡張子です。 |
| resolution | String | N  推奨解像度です。 |
| idType | String | Y | 身分証の種類です。 |

3番目のテーブルです。

| コード | 名前 | 説明 |
|---|---|---|
| SVC-101 | 基本 | 基本サービスです。 |
| SVC-102 | 標準 | 標準サービスです。 |
| SVC-103 | 高級 | 高級サービスです。 |
EOF
}

# 표 D (opt-in): 대상 쪽 절단 — Log-Crash-Search#137 의 이슈 상세 표 모양.
#       ko 8행 연속. en/ja 는 마지막 2행(`최초 발생 시각`·`최근 발생 시각`)이
#       빈 줄 하나 뒤의 고아 파이프 줄. 고아 줄에는 구분 행이 없어 표로 세지 않는다.
#       고아 라벨은 판정 (11) 이 찾으므로 아래 D_ORPHAN_LABELS 와 같아야 한다.
fixture_d_ko() { cat <<'EOF'

<a id="e2e-table-target-cut"></a>
### 대상 쪽 절단 픽스처

이슈 상세 화면의 항목입니다.

| 항목 | 설명 |
|---|---|
| 이슈 ID | 이슈를 식별하는 고유 ID입니다. |
| 로그 레벨 | 이슈가 발생한 로그의 레벨입니다. |
| 앱 키 | 로그를 전송한 프로젝트의 앱 키입니다. |
| 호스트 | 로그를 전송한 호스트입니다. |
| 플랫폼 | 이슈가 발생한 플랫폼입니다. |
| 발생 횟수 | 조회 기간 동안 이슈가 발생한 횟수입니다. |
| 최초 발생 시각 | 이슈가 처음 발생한 시각입니다. |
| 최근 발생 시각 | 이슈가 마지막으로 발생한 시각입니다. |
EOF
}
fixture_d_en() { cat <<'EOF'

<a id="e2e-table-target-cut"></a>
### Target-side cut fixture

Items on the issue details screen.

| Item | Description |
|---|---|
| Issue ID | Unique ID that identifies the issue. |
| Log Level | Level of the log where the issue occurred. |
| Appkey | Appkey of the project that sent the log. |
| Host | Host that sent the log. |
| Platform | Platform where the issue occurred. |
| Occurrences | Number of times the issue occurred during the query period. |

| First Occurred | Time when the issue first occurred. |
| Last Occurred | Time when the issue last occurred. |
EOF
}
fixture_d_ja() { cat <<'EOF'

<a id="e2e-table-target-cut"></a>
### 対象側切断のフィクスチャ

イシュー詳細画面の項目です。

| 項目 | 説明 |
|---|---|
| イシューID | イシューを識別する固有IDです。 |
| ログレベル | イシューが発生したログのレベルです。 |
| アプリキー | ログを送信したプロジェクトのアプリキーです。 |
| ホスト | ログを送信したホストです。 |
| プラットフォーム | イシューが発生したプラットフォームです。 |
| 発生回数 | 照会期間中にイシューが発生した回数です。 |

| 最初の発生日時 | イシューが最初に発生した日時です。 |
| 最近の発生日時 | イシューが最後に発生した日時です。 |
EOF
}

# 표 E (opt-in): 대상 쪽 셀 중간 줄바꿈 절단 — E-mail#163 의 DKIM-Signature 표 모양.
#       ko 10행 연속. en/ja 는 3번째 행(`s`)의 설명 셀이 하드 줄바꿈으로 끊겨, 다음
#       줄(꼬리 문구 + ` |`)이 `|` 로 시작하지 않는다 → `_doc_table_regions` 는 3행.
#       꼬리 문구는 판정 (16) 이 찾으므로 아래 E_TAIL 과 같아야 한다.
fixture_e_ko() { cat <<'EOF'

<a id="e2e-table-target-hardbreak"></a>
### 대상 쪽 셀 줄바꿈 절단 픽스처

서명 헤더의 필드입니다.

| 필드 | 필수 여부 | 값 | 설명 |
|---|---|---|---|
| v | 필수 | 1 | 버전입니다. |
| a | 필수 | rsa-sha256 | 서명 알고리즘입니다. |
| s | 필수 | - | 지정자입니다. 수신 서버에 어떤 공개 키로 검증할지 알려 줍니다. |
| h | 필수 | - | 서명할 헤더입니다. |
| b | 필수 | - | 헤더를 서명한 값입니다. |
| bh | 필수 | - | 본문을 서명한 값입니다. |
| l | 선택 | - | 서명에 사용한 본문의 길이입니다. |
| d | 필수 | - | 도메인입니다. |
| t | 선택 | - | 서명 생성 일시입니다. |
| x | 선택 | - | 서명 만료 일시입니다. |
EOF
}
fixture_e_en() { cat <<'EOF'

<a id="e2e-table-target-hardbreak"></a>
### Target-side cell hard break fixture

Fields of the signature header.

| Field | Required | Value | Description |
|---|---|---|---|
| v | Required | 1 | Version. |
| a | Required | rsa-sha256 | Signature algorithm. |
| s | Required | - | Selector. Tells the receiving server
which public key to use for verification. |
| h | Required | - | Headers to sign. |
| b | Required | - | Signed value of the headers. |
| bh | Required | - | Signed value of the body. |
| l | Optional | - | Length of the body used for the signature. |
| d | Required | - | Domain. |
| t | Optional | - | Time the signature was created. |
| x | Optional | - | Time the signature expires. |
EOF
}
fixture_e_ja() { cat <<'EOF'

<a id="e2e-table-target-hardbreak"></a>
### 対象側セル改行切断のフィクスチャ

署名ヘッダーのフィールドです。

| フィールド | 必須かどうか | 値 | 説明 |
|---|---|---|---|
| v | 必須 | 1 | バージョンです。 |
| a | 必須 | rsa-sha256 | 署名アルゴリズムです。 |
| s | 必須 | - | セレクタです。受信サーバーに
検証に使う公開鍵を知らせます。 |
| h | 必須 | - | 署名するヘッダーです。 |
| b | 必須 | - | ヘッダーを署名した値です。 |
| bh | 必須 | - | 本文を署名した値です。 |
| l | 任意 | - | 署名に使った本文の長さです。 |
| d | 必須 | - | ドメインです。 |
| t | 任意 | - | 署名の生成日時です。 |
| x | 任意 | - | 署名の有効期限です。 |
EOF
}

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC"
echo "case D  : $( (( CASE_D )) && echo 'on (대상 쪽 절단 — 현재 REPRO 기대)' || echo off )"
echo "case E  : $( (( CASE_E )) && echo 'on (대상 쪽 셀 줄바꿈 절단 — OK 기대, #1331)' || echo off )"
echo "translate: $CLOUD_TRANSLATE_DIR"
echo

source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0/6] webhook 비활성화"
set_webhook_repo_enabled false

echo "[1/6] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

echo "[2/6] 시드 — ko/en/ja 에 표 A(끊김)·B(이상치 행)·C(진짜 stale) 추가"
for lang in ko en ja; do
  [[ -f "$lang/$DOC" ]] || { echo "error: $lang/$DOC 없음" >&2; exit 1; }
  "fixture_$lang" >> "$lang/$DOC"
  if (( CASE_D )); then "fixture_d_$lang" >> "$lang/$DOC"; fi
  if (( CASE_E )); then "fixture_e_$lang" >> "$lang/$DOC"; fi
  echo "  시드: $lang/$DOC$( (( CASE_D )) && echo ' (+표 D)' )$( (( CASE_E )) && echo ' (+표 E)' )"
done
cp "en/$DOC" "$tmpdir/en.seed"; cp "ja/$DOC" "$tmpdir/ja.seed"
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(table-malformed): 표 선정 가드 픽스처 시드 ($TS)"
git push -q origin "$SESSION_BRANCH"

echo "[3/6] ko 변경 — 표를 건드리지 않는 산문 1줄"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" "$TS" <<'PY'
import io, sys
path, ts = sys.argv[1:3]
raw = io.open(path, encoding="utf-8", newline="").read()
eol = "\r\n" if "\r\n" in raw else "\n"
lines = raw.split(eol)
target = "아래 표들은 e2e 픽스처입니다."
i = lines.index(target)
lines[i] = f"{target} 선정 가드 검증용입니다 ({ts})."
io.open(path, "w", encoding="utf-8", newline="").write(eol.join(lines))
print(f"  변경: {path} (산문 1줄, 표 무변경)")
PY
git add -- "ko/$DOC"
committed="$(git diff --cached --name-only)"
[[ "$committed" == "ko/$DOC" ]] || { echo "error: 예상 외 파일: $committed" >&2; exit 1; }
git commit -q -m "e2e(table-malformed): 표 밖 산문 1줄 수정 ($TS)"
git push -q origin "$HEAD_BRANCH"

e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(table-malformed): 표 선정 가드 ($TS)" \
  --body "표 reconcile 의 선정 가드 검증 — 끊긴 표 skip · 최빈값 스키마 비교 · 진짜 stale 표는 여전히 수리." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

echo
echo "[4/6] local translate_pr.py (TRANSLATE_LOG_LEVEL=debug)"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_TRANSLATE_ENGINE=claude-code \
  TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
  TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
  TRANSLATE_LOG_LEVEL=debug \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --diff-granularity block --glossary-mode service \
    --workers 2 --chunk-workers 2 --tm-top-k 1 \
) 2>&1 | tee "$LOG"
tx_rc=${PIPESTATUS[0]}
set -e

echo
echo "[5/6] 판정"
# 이 구간이 `set -e` 로 죽으면 판정 표가 한 줄도 안 찍힌 채 trap cleanup 으로
# 넘어가 "왜 실패했는지" 가 사라진다 — 첫 실행에서 실제로 그랬다. 그래서
# 결과물을 GitHub API 로 직접 받는다: 로컬 worktree/브랜치 상태에 의존하지
# 않으므로 cleanup 타이밍과도 무관하고, 실패 지점마다 이유를 찍는다.
tx_pr_url="$(grep -oE 'Created translation PR #[0-9]+ for job [^ ]+ (https://[^ ]+)' "$LOG" \
             | grep -oE 'https://[^ ]+' | head -1)"
if [[ -z "$tx_pr_url" ]]; then
  echo "FAIL: 로그에서 번역 PR URL 을 찾지 못했습니다 (grep 'Created translation PR' $LOG)" >&2
  exit 1
fi
echo "  번역 PR: $tx_pr_url"
tx_num="${tx_pr_url##*/}"
tx_sha="$(gh api "repos/$REPO/pulls/$tx_num" --jq .head.sha)"
base_sha="$(gh api "repos/$REPO/pulls/$tx_num" --jq .base.sha)"
[[ -n "$tx_sha" && -n "$base_sha" ]] || { echo "FAIL: PR #$tx_num sha 조회 실패" >&2; exit 1; }
echo "  head=$tx_sha  base=$base_sha"
for l in ko en ja; do
  for side in head base; do
    ref="$tx_sha"; [[ "$side" == base ]] && ref="$base_sha"
    gh api "repos/$REPO/contents/$l/$DOC?ref=$ref" --jq .content | base64 -d > "$tmpdir/$l.$side.md" \
      || { echo "FAIL: $l/$DOC@$side 조회 실패" >&2; exit 1; }
  done
done

set +e
python3 - "$LOG" "$tmpdir" "$tx_rc" "$tx_pr_url" "$REPO" "$CASE_D" "$CASE_E" \
  "$CLOUD_TRANSLATE_DIR" "$CLOUD_TRANSLATE_PY" <<'PY'
import json, re, subprocess, sys
log_p, tmp, rc, pr_url, repo, case_d, case_e, ct_dir, ct_py = sys.argv[1:10]
log = open(log_p, encoding="utf-8", errors="replace").read()
def rd(lang, side):
    return open(f"{tmp}/{lang}.{side}.md", encoding="utf-8", newline="").read()

results = []
def rule(n, desc, ok, detail=""):
    results.append((n, desc, bool(ok), detail))

def row_flags(text, keys):
    """물리적으로 존재하는 표 데이터 행 — 파서 없이 행 머리로만 찾는다.

    표를 region 으로 파싱하면 ko 의 malformed 행이 표를 끊어 `1행` 으로 세는데,
    그건 **내용이 아니라 파서** 를 측정하는 것이다. 첫 실행에서 이 착각으로
    '행 유실' 오탐이 났다 — 실제로는 세 행 모두 보존되어 있었다.
    """
    ls = text.split("\n")
    return {k: any(l.startswith(k) for l in ls) for k in keys}

A_KEYS = ("| 1 |", "| 2 |", "| 3 |")

rule(1, "번역 성공 (exit 0, PARTIAL 없음)",
     rc == "0" and "PARTIAL:" not in log, f"rc={rc}")

for lang in ("en", "ja"):
    cur, base, ko_cur = rd(lang, "head"), rd(lang, "base"), rd("ko", "head")

    # [A] 끊긴 표 — 세 행의 내용이 살아 있어야 한다. ko 가 정본이므로 ko 의
    #     깨진 모양이 함께 미러링되는 것은 정상이고, 그래서 시드와의 바이트
    #     비교는 성립하지 않는다 (시드 en 은 well-formed 였다).
    present = row_flags(cur, A_KEYS)
    rule(2, f"[A/{lang}] 끊긴 표의 3개 행이 전부 남아 있다",
         all(present.values()),
         ", ".join(f"{k}={'O' if v else 'X'}" for k, v in present.items()))
    ko_n = sum(row_flags(ko_cur, A_KEYS).values())
    cur_n = sum(present.values())
    rule(3, f"[A/{lang}] 행 수가 ko 와 일치 (축소 없음)",
         cur_n == ko_n, f"{lang}={cur_n} ko={ko_n}")

    # [B] 이상치 행 표 — 손대지 않아야 하므로 base 와 바이트 동일.
    def tbl_b(text):
        ls = text.split("\n")
        i = next(k for k, l in enumerate(ls) if l.startswith("| fileType |"))
        return ls[i - 2:i + 3]
    same_b = tbl_b(cur) == tbl_b(base)
    rule(5, f"[B/{lang}] 이상치 행 표가 base 와 바이트 동일", same_b,
         "" if same_b else "열 동기화/재작성되었습니다")

    # [C] 대조군 — 진짜 stale 표는 여전히 수리되어야 한다.
    c_cur = [l for l in cur.split("\n") if l.startswith("| SVC-")]
    c_base = [l for l in base.split("\n") if l.startswith("| SVC-")]
    rule(7, f"[C/{lang}] 진짜 stale 표에 SVC-104 가 추가되었다",
         any(l.startswith("| SVC-104 |") for l in c_cur),
         f"{len(c_base)}행 -> {len(c_cur)}행")
    kept = all(l in c_cur for l in c_base)
    rule(8, f"[C/{lang}] 표 C 의 기존 3행은 바이트 그대로", kept,
         "" if kept else "기존 행이 재작성되었습니다")

# (4) 끊긴 표 건너뜀의 직접 증거 — cloud-translate#1331 의 reconcile 로그 (E 의 표).
cut_langs = sorted(set(re.findall(
    r"Table reconcile \(lang=(en|ja)\): skipped \d+ cut table\(s\)", log)))
if case_e == "1":
    rule(4, "[E] 로그에 끊긴 표 건너뜀 (#1331, en·ja 양쪽)",
         cut_langs == ["en", "ja"], f"langs={cut_langs or '(없음)'}")
else:
    rule(4, "[E] 로그에 끊긴 표 건너뜀 — E 꺼짐, 해당 없음", True, "n/a")
m = re.findall(r"\((\d+) column-synced to ko schema\)", log)
rule(6, "열 동기화가 선정되지 않았다 (column-synced = 0)",
     bool(m) and all(x == "0" for x in m), f"관측값={m or ['(없음)']}")
n_bf = len(re.findall(r"backfilled 1 row\(s\) \(SVC-104\)", log))
rule(9, "대조군 표 C 가 두 언어 모두 backfill (가드가 진짜 수리를 막지 않음)",
     n_bf >= 2, f"{n_bf}회")

# ── [D] 대상 쪽 절단 (opt-in) ─────────────────────────────────────────────
# 고아 2행의 첫 셀 라벨 — fixture_d_en/ja 의 마지막 두 줄과 같아야 한다.
D_ORPHAN_LABELS = {
    "en": ("First Occurred", "Last Occurred"),
    "ja": ("最初の発生日時", "最近の発生日時"),
}
D_ANCHOR = '<a id="e2e-table-target-cut"></a>'

def d_section(text):
    """D 절 — 앵커부터 다음 heading(앵커 다음의 자기 heading 제외) 또는 EOF 까지."""
    ls = text.split("\n")
    try:
        i = next(k for k, l in enumerate(ls) if l.strip() == D_ANCHOR)
    except StopIteration:
        return None
    j = i + 2
    while j < len(ls) and not ls[j].startswith("#"):
        j += 1
    return ls[i:j]

def is_sep(l):
    return bool(re.fullmatch(r"\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*", l))

def d_table_rows(sec):
    """D 표(헤더+구분 행 아래 **연속된** 파이프 줄)의 데이터 행 수."""
    for k in range(len(sec) - 1):
        if sec[k].strip().startswith("|") and is_sep(sec[k + 1]):
            n, e = 0, k + 2
            while e < len(sec) and sec[e].strip().startswith("|"):
                n += 1; e += 1
            return n
    return None

def d_pipe_data_lines(sec):
    """D 절의 파이프 줄 중 헤더·구분 행을 뺀 수 — 표 밖 고아 줄까지 센다."""
    pipes = [l for l in sec if l.strip().startswith("|")]
    return len([l for l in pipes if not is_sep(l)]) - 1  # -1 = 헤더

d_fail = []
if case_d == "1":
    ko_sec = d_section(rd("ko", "head"))
    ko_n = d_table_rows(ko_sec) if ko_sec else None
    for lang in ("en", "ja"):
        cur = rd(lang, "head")
        sec = d_section(cur)
        if sec is None or ko_n is None:
            rule(11, f"[D/{lang}] D 절을 찾았다", False,
                 f"앵커 없음 (ko={'O' if ko_sec else 'X'}, {lang}={'O' if sec else 'X'})")
            d_fail.append(lang); continue
        firsts = [c.split("|")[1].strip() for c in cur.split("\n")
                  if c.strip().startswith("|") and c.count("|") >= 2]
        counts = {lab: sum(1 for f in firsts if f == lab) for lab in D_ORPHAN_LABELS[lang]}
        once = all(v == 1 for v in counts.values())
        rule(11, f"[D/{lang}] 고아 2행의 첫 셀 라벨이 파일에 정확히 1번", once,
             ", ".join(f"{k}={v}" for k, v in counts.items()))
        n_tbl = d_table_rows(sec)
        rule(12, f"[D/{lang}] D 표 데이터 행 수 == ko", n_tbl == ko_n,
             f"{lang}={n_tbl} ko={ko_n}")
        n_pipe = d_pipe_data_lines(sec)
        rule(13, f"[D/{lang}] D 절 파이프 데이터 줄 수 == ko (표 밖 고아 줄 없음)",
             n_pipe == ko_n, f"{lang}={n_pipe} ko={ko_n}")
        has_todo = any("<todo" in l for l in sec)
        rule(14, f"[D/{lang}] D 절에 <todo 마커 없음", not has_todo,
             "<todo 있음" if has_todo else "")
        if not (once and n_tbl == ko_n and n_pipe == ko_n and not has_todo):
            d_fail.append(lang)

# ── [E] 대상 쪽 셀 중간 줄바꿈 절단 (opt-in) ───────────────────────────────
# 끊긴 셀의 꼬리 문구 — fixture_e_en/ja 의 `s` 행 다음 줄 머리와 같아야 한다.
E_TAIL = {"en": "which public key to use", "ja": "検証に使う公開鍵"}
E_ANCHOR = '<a id="e2e-table-target-hardbreak"></a>'

def anchored_section(text, anchor):
    """앵커부터 다음 heading(앵커 다음의 자기 heading 제외) 또는 EOF 까지."""
    ls = text.split("\n")
    try:
        i = next(k for k, l in enumerate(ls) if l.strip() == anchor)
    except StopIteration:
        return None
    j = i + 2
    while j < len(ls) and not ls[j].startswith("#"):
        j += 1
    return ls[i:j]

def first_cells(sec):
    return [l.split("|")[1].strip() for l in sec
            if l.strip().startswith("|") and l.count("|") >= 2 and not is_sep(l)]

# 사이트 렌더러(python-markdown + 사이트 확장)는 cloud-translate 쪽에 있으므로 그
# 인터프리터로 E 절만 렌더해 구조 수치를 받는다.
RENDER = r"""
import json, re, sys
sys.path[:0] = [sys.argv[1], sys.argv[1] + "/translate"]
from shared.markup_lint import _converter
html = _converter().convert(sys.stdin.read())
outside = re.sub(r"<table>.*?</table>", "", html, flags=re.S)
stray = re.findall(r"\|[^|\n<]*\|", outside)
print(json.dumps({"tables": html.count("<table"), "trs": html.count("<tr"),
                  "stray": stray[:3], "n_stray": len(stray)}))
"""

def render_stats(sec):
    p = subprocess.run([ct_py, "-c", RENDER, ct_dir], input="\n".join(sec),
                       capture_output=True, text=True)
    if p.returncode != 0:
        return {"error": (p.stderr.strip().splitlines() or ["?"])[-1]}
    return json.loads(p.stdout)

e_fail = []
if case_e == "1":
    ko_sec = anchored_section(rd("ko", "head"), E_ANCHOR)
    ko_keys = first_cells(ko_sec)[1:] if ko_sec else []   # [0] = 헤더
    for lang in ("en", "ja"):
        sec = anchored_section(rd(lang, "head"), E_ANCHOR)
        if sec is None or not ko_keys:
            rule(15, f"[E/{lang}] E 절을 찾았다", False,
                 f"앵커/표 없음 (ko={'O' if ko_keys else 'X'}, {lang}={'O' if sec else 'X'})")
            e_fail.append(lang); continue
        cells = first_cells(sec)
        counts = {k: cells.count(k) for k in ko_keys}
        bad = {k: v for k, v in counts.items() if v != 1}
        r15 = not bad
        rule(15, f"[E/{lang}] ko 키 {len(ko_keys)}개가 E 절 표 행 첫 셀로 각각 정확히 1번", r15,
             "" if r15 else "어긋남 " + ", ".join(f"{k}={v}" for k, v in bad.items()))
        orphan = [l for l in sec if l.lstrip().startswith(E_TAIL[lang])]
        r16 = not orphan
        rule(16, f"[E/{lang}] 끊긴 셀의 꼬리 문구로 시작하는 고아 줄 없음", r16,
             "" if r16 else f"{len(orphan)}줄: {orphan[0][:50]!r}")
        st = render_stats(sec)
        want_tr = len(ko_keys) + 1
        r17 = ("error" not in st and st["tables"] == 1 and st["trs"] == want_tr
               and st["n_stray"] == 0)
        rule(17, f"[E/{lang}] 렌더: <table> 1개 · <tr> == ko+1 · 표 밖 `| x |` 없음", r17,
             st.get("error") or f"table={st['tables']} tr={st['trs']} (기대 {want_tr}) "
             f"stray={st['n_stray']}")
        has_todo = any("<todo" in l for l in sec)
        rule(18, f"[E/{lang}] E 절에 <todo 마커 없음", not has_todo,
             "<todo 있음" if has_todo else "")
        if not (r15 and r16 and r17 and not has_todo):
            e_fail.append(lang)

body = subprocess.run(["gh", "pr", "view", pr_url, "--repo", repo, "--json", "body",
                       "--jq", ".body"], capture_output=True, text=True).stdout
rule(10, "번역 PR 본문에 '수리하지 않았습니다' 공개",
     "수리하지 않았습니다" in body, "" if body else "PR 본문을 읽지 못했습니다")

print()
ok = 0
for n, desc, good, detail in sorted(results):
    ok += good
    print(f"  ({n}) {'PASS' if good else 'FAIL'}  {desc}" + (f"  - {detail}" if detail else ""))
print()
if case_d == "1":
    print(f"[D] REPRO  대상 쪽 절단 — 고아 행 중복/잔존 ({', '.join(d_fail)})" if d_fail
          else "[D] OK     대상 쪽 절단 — 고아 행이 표로 합쳐지고 중복 없음")
    print()
if case_e == "1":
    print(f"[E] REPRO  대상 쪽 셀 줄바꿈 절단 — 옛 조각 중복/잔존 ({', '.join(e_fail)})" if e_fail
          else "[E] OK     대상 쪽 셀 줄바꿈 절단 — 한 표로 수리되고 중복 없음")
    print()
print(f"TABLE-MALFORMED: {ok}/{len(results)} rules passed")
print("RESULT: OK" if ok == len(results) else "RESULT: FAIL")
sys.exit(0 if ok == len(results) else 1)
PY
judge_rc=$?

echo
echo "[6/6] 완료 (판정 rc=$judge_rc)"
echo "  로그: $LOG"
exit $judge_rc
