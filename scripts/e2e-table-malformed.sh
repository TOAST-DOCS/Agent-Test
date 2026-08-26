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
#   (4) [A] 로그에 "skipped ... malformed" — 건너뛴 직접 증거
#   (5) [B] en/ja 표 B 가 시드와 **바이트 동일** (이상치 행까지 그대로)
#   (6) [B] 로그의 column-synced 가 0 — 열 동기화가 선정되지 않았다
#   (7) [C] en/ja 표 C 에 ko 의 4번째 행이 **추가** 되었다 (가드가 진짜 수리를
#       막지 않는지 — 이게 이 수정의 진짜 위험이다)
#   (8) [C] 표 C 의 기존 3행은 바이트 그대로 (keyed backfill 의 계약)
#   (9) 번역 PR 본문에 표 A 가 "수리하지 않았습니다" 로 공개된다 (#691 공지)
#
# Usage:
#   source ./load_env.sh
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-table-malformed.sh [--keep]
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

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC"
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
  echo "  시드: $lang/$DOC"
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
python3 - "$LOG" "$tmpdir" "$tx_rc" "$tx_pr_url" "$REPO" <<'PY'
import re, subprocess, sys
log_p, tmp, rc, pr_url, repo = sys.argv[1:6]
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

n_skip = len(re.findall(r"skipped 1 malformed", log))
n_warn = len(re.findall(r"truncated by a malformed row", log))
rule(4, "로그에 malformed skip 증거 (en·ja 양쪽)",
     n_skip >= 2 and n_warn >= 2, f"skip={n_skip} warn={n_warn}")
m = re.findall(r"\((\d+) column-synced to ko schema\)", log)
rule(6, "열 동기화가 선정되지 않았다 (column-synced = 0)",
     bool(m) and all(x == "0" for x in m), f"관측값={m or ['(없음)']}")
n_bf = len(re.findall(r"backfilled 1 row\(s\) \(SVC-104\)", log))
rule(9, "대조군 표 C 가 두 언어 모두 backfill (가드가 진짜 수리를 막지 않음)",
     n_bf >= 2, f"{n_bf}회")

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
print(f"TABLE-MALFORMED: {ok}/{len(results)} rules passed")
print("RESULT: OK" if ok == len(results) else "RESULT: FAIL")
sys.exit(0 if ok == len(results) else 1)
PY
judge_rc=$?

echo
echo "[6/6] 완료 (판정 rc=$judge_rc)"
echo "  로그: $LOG"
exit $judge_rc
