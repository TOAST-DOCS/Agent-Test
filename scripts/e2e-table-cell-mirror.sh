#!/usr/bin/env bash
#
# table-cell-mirror e2e — 표 행에서 **언어 중립 셀**만 바뀐 ko 편집이 모델을 거치지
# 않고 en/ja 의 그 셀에만 반영되는가 (cloud-translate #1261 M7, `app/table_cells.py`).
#
# ── 재현하는 결함 ─────────────────────────────────────────────────────────
# TOAST-DOCS/TOAST-Cloud#416 은 `ko/public-api/framework-api.md` 필드 표의 `필수` 열을
# `Yes`/`No` → `Y`/`N` 으로 일괄 변경했다. 바뀐 표 행 771개 중 717개가 그 셀 하나만
# 바뀌었고 en/ja 의 그 셀은 ko 의 옛 값과 바이트 같았는데, 행마다 `changed` 로
# 분류돼 전부 모델로 갔다 — 번역 잡은 1시간 job_timeout 에 걸려 PR 없이 죽었다
# (translate-20261008-2). M7 은 대상 언어의 그 셀이 ko 의 옛 값(또는 새 값)과 바이트
# 같으면 셀 안에서만 치환하고 old_ko 를 패치해 splice 가 그 행을 보지 않게 한다.
#
# ── 픽스처 (세션 브랜치에 생성 — alpha 상주 아님) ─────────────────────────
#   {ko,en,ja}/table-cell-mirror.md — pre-align 정렬본. 네 절:
#     #tcm-response  `필수` 열이 Yes/No 인 필드 표 6행        ko: 필수 셀만 Y/N   → 미러
#     #tcm-request   `구분` 열이 앞에 붙은 5열 표 4행         ko: 필수 셀만 Y/N   → 미러
#     #tcm-partial   2행 — labelKey 는 필수 셀 + **설명 문장**도 수정 (부분 행),
#                    labelValue 는 필수 셀만                  → 부분 행은 재번역, 셀은 Y
#     #tcm-control   `필수 여부` 열이 한국어(필수/선택)라 en/ja 가 번역해 둔 표 —
#                    ko 가 zone 의 `선택` → `필수`              → 중립 아님 → 재번역
#   en/ja 의 Yes/No 셀은 ko 와 바이트 같다 (운영 문서의 모양 그대로).
#
# ── 판정 ─────────────────────────────────────────────────────────────────
#   [A] 결정적 층 (모델 없음) — 실제 `translate_diff` 에 모델 호출만 기록용 에코로
#       가로채 **무엇이 모델로 가는지** 본다 (권장 preset 의 block + table rows).
#       (1) 중립 셀만 바뀐 행 11개(en·ja 각각)가 모델 payload 에 하나도 없다  ← 결함
#       (2) 부분 행(labelKey)·대조군 행(zone)은 모델로 간다                ← 대조군
#       (3) response/request 표가 기존 번역에서 필수 셀만 Y/N 으로 바뀐 바이트다
#   [B] 산출물 층 — 로컬 translate_pr.py (CLI 엔진, 권장 preset) 실제 번역.
#       (4) 번역 성공 (exit 0, PARTIAL 없음)
#       (5) 로그 `Neutral-cell mirror (en|ja)` 의 수치가 [A] 의 보고와 같다
#           (같은 입력이므로 같아야 한다 — 경로를 실제로 탔다는 증거)
#       (6) en/ja response/request 표 = 기존 번역에서 필수 셀만 바뀐 바이트
#       (7) 부분 행: 필수 셀 `Y` · 설명은 ko 의 새 문장(64)을 반영
#       (8) 대조군 행: zone 의 필수 여부 셀이 region 행과 같은 값 (번역됨, 한글 없음)
#       (9) 표 밖 줄은 바이트 그대로 (번역 헤더 주석 · pre-align 표식 제외)
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`TABLE_CELL_MIRROR: OK`) — #1261 이후 코드의 기대값
#   3  결함 재현 (`TABLE_CELL_MIRROR: REPRO`) — (1)(3)(5) 가 실패. `--no-mirror`
#      (kill switch `--no-table-cell-mirror`) 로 돌리면 이것이 기대값이다
#   1  기능 규칙 실패 또는 픽스처가 조건을 잃음 (`TABLE_CELL_MIRROR: FAIL`)
#   2  인프라 — 번역 PR 미감지 · translate_pr.py 비정상 종료
#
# Usage:
#   source ./load_env.sh      # webhook 토글에 필요 (--dry 는 불필요)
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate bash scripts/e2e-table-cell-mirror.sh
#   bash scripts/e2e-table-cell-mirror.sh --dry        # [A] 만 (모델·네트워크 없음)
#   bash scripts/e2e-table-cell-mirror.sh --no-mirror  # BEFORE 대조 — exit 3 이 기대값
#   bash scripts/e2e-table-cell-mirror.sh --keep       # PR·브랜치 보존
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-cellmirror/$TS"
HEAD_BRANCH="translate-test-cellmirror/$TS"
DOC="table-cell-mirror.md"
KEEP=0
DRY=0
NO_MIRROR=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)      KEEP=1; shift ;;
    --dry)       DRY=1; shift ;;
    --no-mirror) NO_MIRROR=1; shift ;;
    -h|--help) sed -n '2,56p' "$0"; exit 0 ;;
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
  for wt in "$tmpdir/base" "$tmpdir/tx"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  git checkout -q --detach 2>/dev/null || true
  if (( DRY )); then
    git branch -D -q "$SESSION_BRANCH" "$HEAD_BRANCH" 2>/dev/null || true
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

echo "=== table-cell-mirror e2e ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 2>/dev/null | cut -c1-60))"
echo "  preset 출처     : $PRESET_CATALOG_DIR"
echo "  session         : $SESSION_BRANCH"
echo "  픽스처          : {ko,en,ja}/$DOC"
echo "  모드            : $( ((DRY)) && echo '[A] 결정적 층만 (--dry)' || echo '[A]+[B]' )$( ((NO_MIRROR)) && echo ' · --no-mirror (BEFORE)' || true)"
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
MARK = "<!-- pre-align:aligned sig=e2e0c3117a1 -->\n\n"
# 표 행: (이름, 타입, 필수, ko 설명, en 설명, ja 설명)
RESPONSE = [
    ("header.isSuccessful", "Boolean", "Yes", "성공 여부", "Whether successful", "成功したかどうか"),
    ("header.resultCode", "Integer", "Yes", "결과 코드", "Result code", "結果コード"),
    ("header.resultMessage", "String", "Yes", "결과 메시지", "Result message", "結果メッセージ"),
    ("body.id", "String", "No", "리소스 ID", "Resource ID", "リソースID"),
    ("body.name", "String", "No", "리소스 이름", "Resource name", "リソース名"),
    ("body.createdAt", "DateTime", "No", "생성 일시", "Created date and time", "作成日時"),
]
REQUEST = [
    ("Header", "X-Auth-Token", "String", "Yes", "발급받은 토큰", "Issued token", "発行されたトークン"),
    ("Path", "appKey", "String", "Yes", "앱키", "Appkey", "アプリケーションキー"),
    ("Query", "pageNum", "Integer", "No", "페이지 번호", "Page number", "ページ番号"),
    ("Query", "pageSize", "Integer", "No", "페이지 크기", "Page size", "ページサイズ"),
]
PARTIAL = [
    ("labelKey", "String", "Yes", "라벨 키", "Label key", "ラベルキー"),
    ("labelValue", "String", "No", "라벨 값", "Label value", "ラベル値"),
]
CONTROL = [  # (이름, ko 필수 여부, en, ja, ko 설명, en, ja)
    ("region", "필수", "Required", "必須", "리전 코드", "Region code", "リージョンコード"),
    ("zone", "선택", "Optional", "任意", "가용성 영역", "Availability zone", "アベイラビリティゾーン"),
]
L = {"ko": 0, "en": 1, "ja": 2}
HDR = {
    "ko": ("| 이름 | 타입 | 필수 | 설명 |", "| 구분 | 이름 | 타입 | 필수 | 설명 |", "| 이름 | 필수 여부 | 설명 |"),
    "en": ("| Name | Type | Required | Description |", "| In | Name | Type | Required | Description |", "| Name | Required | Description |"),
    "ja": ("| 名前 | タイプ | 必須 | 説明 |", "| 区分 | 名前 | タイプ | 必須 | 説明 |", "| 名前 | 必須かどうか | 説明 |"),
}
def t4(lang, rows):
    h = HDR[lang][0]
    out = [h, "| --- | --- | --- | --- |"]
    out += [f"| {n} | {t} | {r} | {d[L[lang]]} |" for n, t, r, *d in rows]
    return "\n".join(out)
def t5(lang):
    out = [HDR[lang][1], "| --- | --- | --- | --- | --- |"]
    out += [f"| {i} | {n} | {t} | {r} | {d[L[lang]]} |" for i, n, t, r, *d in REQUEST]
    return "\n".join(out)
def tc(lang):
    out = [HDR[lang][2], "| --- | --- | --- |"]
    out += [f"| {n} | {(rk, re_, rj)[L[lang]]} | {(dk, de, dj)[L[lang]]} |"
            for n, rk, re_, rj, dk, de, dj in CONTROL]
    return "\n".join(out)
TEXT = {
    "ko": ("table-cell-mirror e2e 픽스처", f"이 문서는 자동 생성된 e2e 픽스처입니다 ({ts}).",
           "응답", "요청", "부분 수정", "대조군",
           "API 응답 본문의 필드입니다.", "요청 헤더와 파라미터입니다.",
           "라벨을 지정하는 필드입니다.", "리소스의 위치를 지정합니다."),
    "en": ("table-cell-mirror e2e fixture", f"This document is a generated e2e fixture ({ts}).",
           "Response", "Request", "Partial Edit", "Control",
           "Fields of the API response body.", "Request headers and parameters.",
           "Fields that specify a label.", "Specifies the location of the resource."),
    "ja": ("table-cell-mirror e2e フィクスチャ", f"この文書は自動生成された e2e フィクスチャです ({ts})。",
           "レスポンス", "リクエスト", "部分修正", "対照群",
           "APIレスポンス本文のフィールドです。", "リクエストヘッダーとパラメータです。",
           "ラベルを指定するフィールドです。", "リソースの位置を指定します。"),
}
for lang in ("ko", "en", "ja"):
    T = TEXT[lang]
    doc_text = f"""{MARK}<a id="tcm"></a>
# {T[0]}

{T[1]}

<a id="tcm-response"></a>
## {T[2]} {{ #tcm-response }}

{T[6]}

{t4(lang, RESPONSE)}

<a id="tcm-request"></a>
## {T[3]} {{ #tcm-request }}

{T[7]}

{t5(lang)}

<a id="tcm-partial"></a>
## {T[4]} {{ #tcm-partial }}

{T[8]}

{t4(lang, PARTIAL)}

<a id="tcm-control"></a>
## {T[5]} {{ #tcm-control }}

{T[9]}

{tc(lang)}
"""
    io.open(os.path.join(lang, doc), "w", encoding="utf-8", newline="").write(doc_text)
print(f"  생성: {{ko,en,ja}}/{doc}  (필드 표 3 · 한국어 열 대조군 표 1)")
PY
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(table-cell-mirror): 픽스처 시드 ($TS)"
session_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$SESSION_BRANCH"

# ── 2) ko 편집 — TOAST-Cloud#416 모양 ─────────────────────────────────────
echo "[2] ko 편집 — 필수 열 Yes/No → Y/N · 부분 행 설명 1개 · 대조군 셀 1개"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" <<'PY'
import io, re, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
n = len(re.findall(r"\| (Yes|No) \|", t))
assert n == 12, n
t = t.replace("| Yes |", "| Y |").replace("| No |", "| N |")
OLD, NEW = "| Y | 라벨 키 |", "| Y | 라벨 키(최대 64자, 영문·숫자만 허용) |"
assert t.count(OLD) == 1
t = t.replace(OLD, NEW)
OLD, NEW = "| zone | 선택 |", "| zone | 필수 |"
assert t.count(OLD) == 1
t = t.replace(OLD, NEW)
io.open(p, "w", encoding="utf-8", newline="").write(t)
print(f"  {p}: 필수 셀 {n}개 Y/N · labelKey 설명 · zone 필수 여부")
PY
git add -- "ko/$DOC"
git commit -q -m "e2e(table-cell-mirror): ko 편집 — 필수 열 Y/N ($TS)"
(( DRY )) || git push -q origin "$HEAD_BRANCH"

# ── 3) [A] 결정적 층 ───────────────────────────────────────────────────────
echo
echo "[3] [A] 결정적 층 — 무엇이 모델로 가는가 (모델 없음)"
git worktree add -q --detach "$tmpdir/base" "$session_sha"
git show "$HEAD_BRANCH:ko/$DOC" > "$tmpdir/new_ko.md"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" - "$tmpdir/base" "$DOC" "$tmpdir/new_ko.md" "$tmpdir/a.json" "$NO_MIRROR" <<'PY') 2>"$tmpdir/a.err"
import asyncio, io, json, logging, os, sys
sys.path[:0] = ["translate", "."]
logging.disable(logging.WARNING)
from shared.config import settings
from app.translator import Translator, _strip_code_fence
base, doc, new_ko_p, outp, no_mirror = sys.argv[1:6]
settings.diff_granularity = "block"
settings.diff_table_rows = True
settings.diff_table_neutral_cells = no_mirror != "1"

class Rec(Translator):
    """진짜 Translator — 모델 호출 한 겹만 기록용 에코로 가로챈다."""
    def __init__(self):
        super().__init__()
        self.sent = []
    def model_name(self):
        return "echo"
    async def _verify_chunk_uncached(self, *a, **k):
        return ""
    async def _translate_chunk_uncached(self, content, *a, **k):
        self.sent.append(content)
        return _strip_code_fence(content)

rd = lambda p: io.open(p, encoding="utf-8", newline="").read()
old_ko = rd(os.path.join(base, "ko", doc))
new_ko = rd(new_ko_p)
res = {}
async def main():
    for lang in ("en", "ja"):
        tr, rep = Rec(), {}
        out = await tr.translate_diff(
            rd(os.path.join(base, lang, doc)), new_ko, old_ko, None, lang, lang,
            report=rep, prealigned=True, content_baseline_ko=old_ko)
        res[lang] = {"sent": "\n".join(tr.sent), "calls": len(tr.sent),
                     "mirror": rep.get("table_cell_mirror"), "out": out}
asyncio.run(main())
json.dump(res, open(outp, "w"), ensure_ascii=False, indent=2)
PY
prc=$?
set -e
if (( prc != 0 )); then
  echo "error: [A] 검사 실행 실패" >&2; tail -20 "$tmpdir/a.err" >&2; KEEP=1; exit 2
fi
eval "$(python3 - "$tmpdir/a.json" "$tmpdir/base" "$DOC" <<'PY'
import io, json, os, sys
d = json.load(open(sys.argv[1])); base, doc = sys.argv[2:4]
NEUTRAL = ["header.isSuccessful", "header.resultCode", "header.resultMessage", "body.id",
           "body.name", "body.createdAt", "X-Auth-Token", "appKey", "pageNum", "pageSize",
           "labelValue"]
def section(text, anchor):
    """`{ #anchor }` heading 부터 다음 `<a id` 줄 전까지."""
    lines = text.split("\n")
    s = next(i for i, l in enumerate(lines) if "{ #%s }" % anchor in l)
    e = next((i for i in range(s + 1, len(lines)) if lines[i].startswith("<a id=")), len(lines))
    return "\n".join(lines[s:e])
a1 = a2 = a3 = 0
for lang in ("en", "ja"):
    r = d[lang]
    leaked = [k for k in NEUTRAL if f"| {k} |" in r["sent"]]
    print(f"echo '    [{lang}] 모델 호출 {r['calls']} · 미러 보고 {r['mirror']} · 중립 행 중 모델로 간 것 {len(leaked)}: {leaked[:4]}'")
    a1 += not leaked
    a2 += ("| labelKey |" in r["sent"]) and ("| zone |" in r["sent"])
    before = io.open(os.path.join(base, lang, doc), encoding="utf-8").read()
    ok = all(section(r["out"], a) == section(before, a).replace("| Yes |", "| Y |").replace("| No |", "| N |")
             for a in ("tcm-response", "tcm-request"))
    a3 += ok
    m = r["mirror"] or {}
    print(f"A_MIRROR_{lang.upper()}='{m.get('rows', 0)} ko table row(s) — {m.get('rewritten', 0)} cell(s) substituted, {m.get('reused', 0)} already correct, {m.get('partial', 0)} row(s) with a prose edit still re-translated, {m.get('skipped', 0)} row(s)'")
print(f"A1={a1}; A2={a2}; A3={a3}")
PY
)"
(( A1 == 2 )) && ok "(1) en/ja: 중립 셀만 바뀐 행 11개가 모델로 가지 않는다" \
              || defect "(1) 중립 셀만 바뀐 행이 모델로 간다 ($((2 - A1))/2 언어)"
(( A2 == 2 )) && ok "(2) en/ja: 부분 행(labelKey)·대조군 행(zone)은 모델로 간다" \
              || bad "(2) 부분 행/대조군 행이 모델로 가지 않았다 — 미러가 실제 작업을 삼켰다 ($A2/2)"
(( A3 == 2 )) && ok "(3) en/ja: response/request 표 = 기존 번역에서 필수 셀만 Y/N" \
              || defect "(3) response/request 표가 기존 번역 + 셀 치환과 다르다 ($A3/2)"
echo "    [A] 미러 보고 — en: ${A_MIRROR_EN}"
echo "    [A] 미러 보고 — ja: ${A_MIRROR_JA}"

if (( DRY )); then
  echo
  if (( fails == 0 && repro == 0 )); then echo "TABLE_CELL_MIRROR: OK"; exit 0; fi
  if (( fails == 0 )); then echo "TABLE_CELL_MIRROR: REPRO"; exit 3; fi
  echo "TABLE_CELL_MIRROR: FAIL"; exit 1
fi

# ── 4) [B] 실제 번역 ───────────────────────────────────────────────────────
echo
echo "[4] [B] 실제 번역 — 로컬 translate_pr.py (CLI 엔진, 권장 preset)"
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(table-cell-mirror): 필수 열 Y/N — 언어 중립 셀 미러 ($TS)" \
  --body "cloud-translate #1261 (M7) 검증 — 필수 셀만 바뀐 표 행은 모델 없이 en/ja 의 그 셀만 바뀌어야 한다 (TOAST-DOCS/TOAST-Cloud#416 모양)." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"
preset_eval="$(python3 "$(dirname "$0")/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 1
eval "$preset_eval"
(( NO_MIRROR )) && PRESET_ARGS+=(--no-table-cell-mirror)
echo "  translate argv: ${PRESET_ARGS[*]}"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") 2>&1 | tee "$LOG" \
  | grep -E "Neutral-cell mirror|Section-diff|anchor splice|Translation PR|PARTIAL|ERROR" | sed 's/^/    /'
tx_rc=${PIPESTATUS[0]}
set -e
if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(4) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(4) 번역 실패/부분 (exit $tx_rc)"
fi
echo "    엔진: CLI 호출 $(grep -c 'with Claude Code CLI' "$LOG" || true) · api.anthropic.com $(grep -c 'api.anthropic.com' "$LOG" || true) (0 이어야 한다)"
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지 — 로그 $LOG" >&2; KEEP=1; exit 2; }
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url" || true

b5=0
for lang in en ja; do
  want="$( [[ $lang == en ]] && echo "$A_MIRROR_EN" || echo "$A_MIRROR_JA" )"
  got="$(grep -oE "Neutral-cell mirror \($lang\): .* row\(s\)" "$LOG" | head -1 | sed -E "s/^Neutral-cell mirror \($lang\): //; s/ left to the splice//" || true)"
  echo "    [$lang] 로그: ${got:-<없음>}"
  [[ -n "$got" && "$got" == "$want" ]] && b5=$((b5 + 1))
done
(( b5 == 2 )) && ok "(5) 로그의 미러 수치가 [A] 와 같다 (en/ja)" \
              || defect "(5) 미러 로그가 없거나 [A] 와 다르다 ($b5/2)"

tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"

echo
echo "[5] 산출물 판정"
eval "$(python3 - "$tmpdir/base" "$tmpdir/tx" "$DOC" <<'PY'
import io, os, re, sys
base, tx, doc = sys.argv[1:4]
HANGUL = re.compile(r"[가-힣]")
def rd(root, lang):
    try:
        return io.open(os.path.join(root, lang, doc), encoding="utf-8", newline="").read()
    except OSError:
        return None
def section(text, anchor):
    lines = text.split("\n")
    s = next(i for i, l in enumerate(lines) if "{ #%s }" % anchor in l)
    e = next((i for i in range(s + 1, len(lines)) if lines[i].startswith("<a id=")), len(lines))
    return lines[s:e]
def row(lines, key):
    return next((l for l in lines if l.startswith(f"| {key} |")), None)
cells = lambda l: [c.strip() for c in l.strip().strip("|").split("|")]
b6 = b7 = b8 = b9 = 0; missing = 0
for lang in ("en", "ja"):
    before, after = rd(base, lang), rd(tx, lang)
    if after is None:
        missing += 1; continue
    exp = lambda a: [l.replace("| Yes |", "| Y |").replace("| No |", "| N |") for l in section(before, a)]
    b6 += all(section(after, a) == exp(a) for a in ("tcm-response", "tcm-request"))
    part_b, part_a = section(before, "tcm-partial"), section(after, "tcm-partial")
    lk_b, lk_a, lv_a = row(part_b, "labelKey"), row(part_a, "labelKey"), row(part_a, "labelValue")
    ok7 = (lk_a is not None and cells(lk_a)[2] == "Y" and "64" in lk_a and not HANGUL.search(lk_a)
           and lv_a == row(part_b, "labelValue").replace("| No |", "| N |"))
    b7 += ok7
    ctl = section(after, "tcm-control")
    z, r = row(ctl, "zone"), row(ctl, "region")
    ok8 = z is not None and r is not None and cells(z)[1] == cells(r)[1] and not HANGUL.search(z)
    b8 += ok8
    # (9) 표 밖 줄 — 표 행(`|` 로 시작) · 번역 헤더 주석 · pre-align 표식(번역 잡이 sig 를
    #     다시 찍는다)을 뺀 나머지가 바이트 같다
    strip = lambda t: [l for l in t.split("\n") if not l.startswith("|")
                       and "machine_translated" not in l and "pre-align:aligned" not in l]
    norm = lambda ls: "\n".join(ls).strip("\n")
    b9 += norm(strip(before)) == norm(strip(after))
    print(f"echo '    [{lang}] labelKey: {lk_a}'")
    print(f"echo '    [{lang}] zone    : {z}  (region: {r})'")
print(f"B6={b6}; B7={b7}; B8={b8}; B9={b9}; B_MISSING={missing}")
PY
)"
if (( B_MISSING )); then
  bad "(6) 번역 PR 에 픽스처 문서가 없다 ($B_MISSING 개)"
else
  (( B6 == 2 )) && ok "(6) en/ja response/request 표 = 기존 번역에서 필수 셀만 Y/N" \
                || defect "(6) 중립 셀만 바뀐 표가 다시 쓰였다 ($((2 - B6))/2 언어)"
fi
(( B7 == 2 )) && ok "(7) 부분 행: 필수 셀 Y · 설명은 ko 의 새 문장 반영 · labelValue 는 셀만" \
              || bad "(7) 부분 행 처리 불일치 ($B7/2)"
(( B8 == 2 )) && ok "(8) 대조군: zone 의 필수 여부가 region 과 같은 번역값 (한글 없음)" \
              || bad "(8) 대조군 행이 재번역되지 않았거나 값이 다르다 ($B8/2)"
(( B9 == 2 )) && ok "(9) 표 밖 줄은 바이트 그대로" \
              || bad "(9) 표 밖 줄이 바뀌었다 ($((2 - B9))/2 언어)"

echo
echo "[6] 결과"
echo "  ko PR: $ko_pr_url"
echo "  번역 PR: $tx_pr_url"
if (( fails == 0 && repro == 0 )); then echo "TABLE_CELL_MIRROR: OK"; exit 0; fi
KEEP=1
if (( fails == 0 )); then echo "TABLE_CELL_MIRROR: REPRO"; exit 3; fi
echo "TABLE_CELL_MIRROR: FAIL"; exit 1
