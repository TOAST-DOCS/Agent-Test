#!/usr/bin/env bash
#
# table-open-row e2e — 닫는 `|` 없이 끝나는 표 행을 다시 번역해도 그 행과 그 아래
# 행들이 en/ja 에서 표에 남는가 (cloud-translate — TOAST-Cloud#421 재발 방지).
#
# ── 재현하는 결함 ─────────────────────────────────────────────────────────
# TOAST-DOCS/TOAST-Cloud#416 이 ko `public-api/framework-api.md` 의 `필수` 열을
# `No` → `N` 으로 바꿨는데, 그 번역 PR #421 의 en/ja `ResponseProtocol` 표에서 마지막
# 행 앞에 빈 줄이 생겨 그 행이 `| tokenFormatCode | … |` 글자 문단으로 렌더됐다
# (ko 5행 · en/ja 4행). 바로 위 ko 행이 원문부터 닫는 `|` 없이 끝난다:
#     |   tokenExpiryPeriod | Long| N | 토큰 만료 기간(초 단위)
# `_table_region` 과 python-markdown 은 이 줄을 정상 행으로 읽는데, 조립이 쓰는
# `_is_table_unit` 은 한 줄짜리 행에 닫는 `|` 를 요구해 이 행만 **문단 단위**가 됐고,
# 문단 구분용 빈 줄을 달고 붙었다. 이상적 모델로도 재현된다 (파이프라인 결함).
# 그 행이 표 **중간**이면 아래 행들까지 함께 표에서 떨어진다.
#
# ── 픽스처 (세션 브랜치에 생성 — alpha 상주 아님) ─────────────────────────
#   {ko,en,ja}/table-open-row.md — pre-align 정렬본. 세 절, 각 절에 4열 필드 표 하나.
#     #tor-last    사고 모양 — 끝에서 두 번째 ko 행이 닫는 `|` 없음.
#                  ko 편집: `필수` 열 No → N 일괄 (TOAST-Cloud#416)
#     #tor-mid     ko 의 두 번째 행(4행 중)이 닫는 `|` 없음.
#                  ko 편집: 그 행의 설명 문구 수정 → 그 행이 반드시 다시 번역된다
#     #tor-closed  대조군 — 모든 행이 `|` 로 닫힘. ko 편집: 두 번째 행 설명 수정
#   en/ja 는 편집 전 ko 의 번역이고 모든 행이 `|` 로 닫혀 있다 (운영 문서의 모양).
#
# ── 판정 ─────────────────────────────────────────────────────────────────
# 절마다 사이트와 같은 python-markdown 설정(`shared.markup_lint._converter`)으로 렌더해
# `<tr>` 수와 `|` 로 시작하는 `<p>`(표에서 샌 행) 수를 ko 와 비교한다.
#   [A] 결정적 층 (모델 없음) — 이상적 모델(받은 단위를 그대로 돌려주고 엔진과 같은
#       `_strip_code_fence` 를 거침)로 실제 `translate_diff` 를 돌린다.
#       (1) #tor-last · #tor-mid 의 en/ja 렌더가 ko 와 같다          ← 결함
#       (2) #tor-closed 의 en/ja 렌더가 ko 와 같다                    ← 대조군
#   [B] 산출물 층 — 로컬 translate_pr.py (CLI 엔진, 권장 preset) 실제 번역.
#       (3) 번역 성공 (exit 0, PARTIAL 없음)
#       (4) = (1) 을 실제 산출물에서                                  ← 결함(증상)
#       (5) = (2) 를 실제 산출물에서
#       (6) en/ja 표 행에 한글이 없다 (고친 행이 번역됐다)
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`TABLE_OPEN_ROW: OK`) — 수정 이후 코드의 기대값
#   3  결함 재현 (`TABLE_OPEN_ROW: REPRO`) — 수정 이전 코드의 기대값
#   1  기능 규칙 실패 (`TABLE_OPEN_ROW: FAIL`) — 대조군이 깨졌거나 번역 실패
#   2  인프라 — 번역 PR 미감지 · translate_pr.py 비정상 종료
#
# Usage:
#   source ./load_env.sh
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate bash scripts/e2e-table-open-row.sh
#   bash scripts/e2e-table-open-row.sh --dry            # [A] 만 (모델·네트워크·.env 없음)
#   bash scripts/e2e-table-open-row.sh --keep           # PR·브랜치 보존
#   bash scripts/e2e-table-open-row.sh --reuse <TS>     # 앞선 --keep 실행의 세션·ko PR 재사용
#                                                       #  (BEFORE/AFTER 를 같은 입력으로)
#   --label BEFORE|AFTER                                # 번역 PR 제목 앞에 [BEFORE]/[AFTER]
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
DOC="table-open-row.md"
KEEP=0
DRY=0
REUSE=""
LABEL=""

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)  KEEP=1; shift ;;
    --dry)   DRY=1; shift ;;
    --reuse) REUSE="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    -h|--help) sed -n '2,52p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$REUSE" ]] && { TS="$REUSE"; KEEP=1; }
SESSION_BRANCH="e2e-openrow/$TS"
HEAD_BRANCH="translate-test-openrow/$TS"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"
ko_pr_url=""; tx_pr_url=""

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/base" "$tmpdir/tx"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  git checkout -q --detach 2>/dev/null || true
  if (( DRY )); then
    [[ -n "$REUSE" ]] || git branch -D -q "$SESSION_BRANCH" "$HEAD_BRANCH" 2>/dev/null || true
    return $rc
  fi
  if (( KEEP )); then
    echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${ko_pr_url:-없음}, 번역 PR: ${tx_pr_url:-없음})"
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
  git branch -D -q "$SESSION_BRANCH" "$HEAD_BRANCH" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "=== table-open-row e2e ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 2>/dev/null | cut -c1-60))"
echo "  session         : $SESSION_BRANCH $( [[ -n "$REUSE" ]] && echo '(재사용)' )"
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

if [[ -n "$REUSE" ]]; then
  # ── 1-2) 재사용 — 앞선 실행이 남긴 세션·ko PR ─────────────────────────────
  echo "[1] 세션 재사용: $SESSION_BRANCH ← $HEAD_BRANCH"
  git fetch -q origin "$SESSION_BRANCH" "$HEAD_BRANCH"
  session_sha="$(git rev-parse "origin/$SESSION_BRANCH")"
  git show "origin/$HEAD_BRANCH:ko/$DOC" > "$tmpdir/new_ko.md"
  if (( ! DRY )); then
    ko_pr_url="$(gh pr list --repo "$REPO" --head "$HEAD_BRANCH" --state open --json url --jq '.[0].url')"
    [[ -n "$ko_pr_url" ]] || { echo "error: $HEAD_BRANCH 의 열린 ko PR 이 없다" >&2; exit 2; }
    echo "  ko PR: $ko_pr_url"
  fi
else
  # ── 1) 세션 브랜치 + 픽스처 ──────────────────────────────────────────────
  echo "[1] 세션 브랜치 생성 + 픽스처 시드 (편집 전 ko 와 그 번역)"
  git fetch -q origin "$BASE_SOURCE"
  git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"
  python3 - "$TS" "$DOC" <<'PY'
import io, os, sys
ts, doc = sys.argv[1:3]
L = {"ko": 0, "en": 1, "ja": 2}
HDR = {"ko": "| 이름 | 타입 | 필수 | 설명 |", "en": "| Name | Type | Required | Description |",
       "ja": "| 名前 | タイプ | 必須 | 説明 |"}
# (anchor, heading, 문장, 행 [(key, type, ko, en, ja)], 닫는 | 를 뺄 ko 행 번호)
SECTIONS = [
  ("tor-last", ("인증 응답", "Authentication Response", "認証レスポンス"),
   ("인증 정보 등록 응답의 필드입니다.", "Fields of the authentication registration response.",
    "認証情報登録レスポンスのフィールドです。"),
   [("authId", "String", "내부적으로 관리하는 인증 수단 아이디", "Internally managed authentication method ID", "内部で管理する認証手段ID"),
    ("userAccessKeyID", "String", "User Access Key ID", "User Access Key ID", "User Access Key ID"),
    ("secretAccessKey", "String", "비밀 키", "Secret key", "秘密鍵"),
    ("tokenExpiryPeriod", "Long", "토큰 만료 기간(초 단위)", "Token expiration period (in seconds)", "トークン有効期限(秒単位)"),
    ("tokenFormatCode", "String", "토큰 포맷 코드(OPAQUE, JWT)", "Token format code (OPAQUE, JWT)", "トークンフォーマットコード(OPAQUE、JWT)")],
   3),
  ("tor-mid", ("프로젝트 응답", "Project Response", "プロジェクトレスポンス"),
   ("프로젝트 조회 응답의 필드입니다.", "Fields of the project query response.",
    "プロジェクト照会レスポンスのフィールドです。"),
   [("projectId", "String", "프로젝트 아이디", "Project ID", "プロジェクトID"),
    ("projectName", "String", "프로젝트 이름", "Project name", "プロジェクト名"),
    ("ownerUuid", "String", "프로젝트 소유자 UUID", "Project owner UUID", "プロジェクトオーナーUUID"),
    ("regDatetime", "Date", "생성 일시", "Date and time of creation", "作成日時")],
   1),
  ("tor-closed", ("멤버 응답", "Member Response", "メンバーレスポンス"),
   ("멤버 조회 응답의 필드입니다.", "Fields of the member query response.",
    "メンバー照会レスポンスのフィールドです。"),
   [("uuid", "String", "멤버 UUID", "Member UUID", "メンバーUUID"),
    ("name", "String", "이름", "Name", "名前"),
    ("emailAddress", "String", "멤버 이메일 주소", "Member email address", "メンバーのメールアドレス"),
    ("joinYmdt", "Date", "가입 일시", "Date and time of joining", "加入日時")],
   None),
]
TITLE = {"ko": "table-open-row e2e 픽스처", "en": "table-open-row e2e fixture", "ja": "table-open-row e2e フィクスチャ"}
INTRO = {"ko": f"이 문서는 자동 생성된 e2e 픽스처입니다 ({ts}).",
         "en": f"This document is a generated e2e fixture ({ts}).",
         "ja": f"この文書は自動生成された e2e フィクスチャです ({ts})。"}
REQ = {"ko": "No", "en": "No", "ja": "No"}
for lang, i in L.items():
    out = ["<!-- pre-align:aligned sig=e2e09e4r0w -->", "", '<a id="tor"></a>', f"# {TITLE[lang]}", "", INTRO[lang], ""]
    for anchor, heads, prose, rows, open_row in SECTIONS:
        out += [f'<a id="{anchor}"></a>', f"## {heads[i]} {{ #{anchor} }}", "", prose[i], "",
                HDR[lang], "|------------ | ------------- | ----- | ------------ |"]
        for n, (k, typ, *desc) in enumerate(rows):
            row = f"|   {k} | {typ}| {REQ[lang]} | {desc[i]}"
            # 닫는 | 를 빼는 것은 ko 뿐 — 사고 문서의 모양 (en/ja 는 닫혀 있었다)
            out.append(row if (lang == "ko" and n == open_row) else row + " |")
        out += ["", ""]
    io.open(os.path.join(lang, doc), "w", encoding="utf-8", newline="").write("\n".join(out))
print(f"  생성: {{ko,en,ja}}/{doc}  (절 3개 · ko 의 닫는 | 없는 행 2개)")
PY
  git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
  git commit -q -m "e2e(table-open-row): 픽스처 시드 ($TS)"
  session_sha="$(git rev-parse HEAD)"
  (( DRY )) || git push -q origin "$SESSION_BRANCH"

  # ── 2) ko 편집 ──────────────────────────────────────────────────────────
  echo "[2] ko 편집 — #tor-last 필수 열 No→N · #tor-mid/#tor-closed 두 번째 행 설명 수정"
  git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
  python3 - "ko/$DOC" <<'PY'
import io, re, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
head, rest = t.split('<a id="tor-mid"></a>', 1)
head = head.replace("| No |", "| N |")          # #tor-last — TOAST-Cloud#416 의 Y/N 일괄 변경
t = head + '<a id="tor-mid"></a>' + rest
EDITS = [
  ("| 프로젝트 이름\n", "| 콘솔에 표시되는 프로젝트 이름\n"),       # #tor-mid — 닫는 | 없는 행
  ("| 이름 |\n", "| 멤버 이름 |\n"),                                # #tor-closed — 대조군
]
for old, new in EDITS:
    assert t.count(old) == 1, old
    t = t.replace(old, new)
io.open(p, "w", encoding="utf-8", newline="").write(t)
print(f"  {p}: #tor-last 필수 열 {head.count('| N |')}행 · 설명 {len(EDITS)}곳")
PY
  git add -- "ko/$DOC"
  git commit -q -m "e2e(table-open-row): ko 편집 — 닫는 | 없는 행이 다시 번역되게 ($TS)"
  (( DRY )) || git push -q origin "$HEAD_BRANCH"
  git show "$HEAD_BRANCH:ko/$DOC" > "$tmpdir/new_ko.md"
fi

# 판정기 — ko 와 대상 파일을 절별로 렌더해 (<tr>, 샌 행 <p>) 를 비교한다.
cat > "$tmpdir/judge.py" <<'PY'
import io, re, sys
sys.path[:0] = ["translate", "."]
from shared.markup_lint import _converter
def sections(text):
    parts = re.split(r'(?m)^<a id="(tor-[a-z]+)"></a>\n', text)
    return {parts[i]: parts[i + 1] for i in range(1, len(parts) - 1, 2)}
def shape(src):
    html = _converter().reset().convert(src)
    return (len(re.findall(r"<tr>", html)), len(re.findall(r"<p>\s*\|", html)))
ko = sections(io.open(sys.argv[1], encoding="utf-8").read())
tgt = sections(io.open(sys.argv[2], encoding="utf-8").read())
for anchor in ("tor-last", "tor-mid", "tor-closed"):
    k, t = shape(ko.get(anchor, "")), shape(tgt.get(anchor, ""))
    print(f"{anchor} {'OK' if k == t else 'BAD'} ko<tr>={k[0]} ko<p|>={k[1]} tgt<tr>={t[0]} tgt<p|>={t[1]}")
PY

judge_pair() {  # $1 lang, $2 ko, $3 target → 절별 결과를 BAD_<anchor> 변수에 누적
  local out; out="$(cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" "$tmpdir/judge.py" "$2" "$3")"
  echo "$out" | sed "s/^/    [$1] /"
  grep -q '^tor-last BAD'   <<<"$out" && JL=$((JL + 1)) || true
  grep -q '^tor-mid BAD'    <<<"$out" && JM=$((JM + 1)) || true
  grep -q '^tor-closed BAD' <<<"$out" && JC=$((JC + 1)) || true
}

# ── 3) [A] 결정적 층 ───────────────────────────────────────────────────────
echo
echo "[3] [A] 결정적 층 — 이상적 모델로 translate_diff (모델 없음)"
git worktree add -q --detach "$tmpdir/base" "$session_sha"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" - "$tmpdir/base" "$DOC" "$tmpdir/new_ko.md" "$tmpdir" <<'PY') 2>"$tmpdir/a.err"
import asyncio, io, logging, os, sys
sys.path[:0] = ["translate", "."]
logging.disable(logging.WARNING)
from shared.config import settings
from app.translator import Translator, _strip_code_fence
base, doc, new_ko_p, outdir = sys.argv[1:5]
settings.diff_granularity = "block"
settings.diff_table_rows = True

class Echo(Translator):
    """이상적 모델 — 받은 단위를 그대로 돌려주고 엔진과 같은 `_strip_code_fence` 를 거친다."""
    def model_name(self):
        return "echo"
    async def _verify_chunk_uncached(self, *a, **k):
        return ""
    async def _translate_chunk_uncached(self, content, *a, **k):
        return _strip_code_fence(content)

rd = lambda p: io.open(p, encoding="utf-8", newline="").read()
old_ko, new_ko = rd(os.path.join(base, "ko", doc)), rd(new_ko_p)
async def main():
    for lang in ("en", "ja"):
        out = await Echo().translate_diff(
            rd(os.path.join(base, lang, doc)), new_ko, old_ko, None, lang, lang,
            report={}, prealigned=True, content_baseline_ko=old_ko)
        io.open(os.path.join(outdir, f"a_{lang}.md"), "w", encoding="utf-8", newline="").write(out)
asyncio.run(main())
PY
prc=$?
set -e
if (( prc != 0 )); then
  echo "error: [A] 검사 실행 실패" >&2; tail -20 "$tmpdir/a.err" >&2; KEEP=1; exit 2
fi
JL=0; JM=0; JC=0
for lang in en ja; do judge_pair "$lang" "$tmpdir/new_ko.md" "$tmpdir/a_$lang.md"; done
(( JL + JM == 0 )) && ok "(1) #tor-last · #tor-mid 의 en/ja 렌더가 ko 와 같다" \
                   || defect "(1) 닫는 | 없는 행의 표가 en/ja 에서 깨졌다 (last $JL · mid $JM, en+ja)"
(( JC == 0 )) && ok "(2) 대조군 #tor-closed 의 en/ja 렌더가 ko 와 같다" \
              || bad "(2) 대조군 #tor-closed 가 깨졌다 ($JC)"

if (( DRY )); then
  echo
  if (( fails == 0 && repro == 0 )); then echo "TABLE_OPEN_ROW: OK"; exit 0; fi
  if (( fails == 0 )); then echo "TABLE_OPEN_ROW: REPRO"; exit 3; fi
  echo "TABLE_OPEN_ROW: FAIL"; exit 1
fi

# ── 4) [B] 실제 번역 ───────────────────────────────────────────────────────
echo
echo "[4] [B] 실제 번역 — 로컬 translate_pr.py (CLI 엔진, 권장 preset)"
e2e_ensure_label "$REPO"
if [[ -z "$ko_pr_url" ]]; then
  ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
    --title "e2e(table-open-row): 닫는 | 없는 표 행 ($TS)" \
    --body "TOAST-Cloud#421 재발 방지 검증 — ko 표 행이 닫는 \`|\` 없이 끝나도, 그 행을 다시 번역한 en/ja 에서 그 행과 아래 행이 표에 남아야 한다." \
    --label "$E2E_LABEL")"
  echo "  ko PR: $ko_pr_url"
fi
preset_eval="$(python3 "$(dirname "$0")/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 1
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") 2>&1 | tee "$LOG" \
  | grep -E "Section-diff|anchor splice|Table reconcile|Neutral-cell|Translation PR|PARTIAL|ERROR" | sed 's/^/    /'
tx_rc=${PIPESTATUS[0]}
set -e
if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(3) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(3) 번역 실패/부분 (exit $tx_rc)"
fi
echo "    엔진: CLI 호출 $(grep -c 'with Claude Code CLI' "$LOG" || true) · api.anthropic.com $(grep -c 'api.anthropic.com' "$LOG" || true) (0 이어야 한다)"
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지 — 로그 $LOG" >&2; KEEP=1; exit 2; }
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url" || true
if [[ -n "$LABEL" ]]; then
  old_title="$(gh pr view "$tx_pr_url" --repo "$REPO" --json title --jq .title)"
  gh pr edit "$tx_pr_url" --repo "$REPO" --title "[$LABEL] $old_title" >/dev/null || true
fi
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"

echo
echo "[5] 산출물 판정"
JL=0; JM=0; JC=0; b_hangul=0
for lang in en ja; do
  f="$tmpdir/tx/$lang/$DOC"
  if [[ ! -f "$f" ]]; then bad "번역 PR 에 $lang/$DOC 가 없다"; continue; fi
  judge_pair "$lang" "$tmpdir/new_ko.md" "$f"
  h=$(grep -E '^\|' "$f" | grep -cP '[\x{AC00}-\x{D7A3}]' || true)
  (( h )) && grep -E '^\|' "$f" | grep -P '[\x{AC00}-\x{D7A3}]' | sed "s/^/    [$lang] 한글 행: /"
  b_hangul=$((b_hangul + h))
done
(( JL + JM == 0 )) && ok "(4) #tor-last · #tor-mid 의 en/ja 렌더가 ko 와 같다 (실제 산출물)" \
                   || defect "(4) 닫는 | 없는 행의 표가 en/ja 에서 깨졌다 (last $JL · mid $JM, en+ja)"
(( JC == 0 )) && ok "(5) 대조군 #tor-closed 의 en/ja 렌더가 ko 와 같다 (실제 산출물)" \
              || bad "(5) 대조군 #tor-closed 가 깨졌다 ($JC)"
(( b_hangul == 0 )) && ok "(6) en/ja 표 행에 한글이 없다" \
                    || bad "(6) en/ja 표 행에 한글이 남았다 ($b_hangul 행)"

echo
echo "[6] 결과"
echo "  ko PR: $ko_pr_url"
echo "  번역 PR: $tx_pr_url"
if (( fails == 0 && repro == 0 )); then echo "TABLE_OPEN_ROW: OK"; exit 0; fi
KEEP=1
if (( fails == 0 )); then echo "TABLE_OPEN_ROW: REPRO"; exit 3; fi
echo "TABLE_OPEN_ROW: FAIL"; exit 1
