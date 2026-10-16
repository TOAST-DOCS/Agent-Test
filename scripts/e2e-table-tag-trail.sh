#!/usr/bin/env bash
#
# table-tag-trail e2e — 표 마지막 행 **바로 아래**(빈 줄 없이)에 템플릿 태그가 붙을 때,
# en/ja 의 그 행도 태그에 붙는가 (cloud-translate #1258, Compute-Image#114 → #115).
#
# ── 재현하는 결함 ─────────────────────────────────────────────────────────
# ko 가 표의 마지막 행 아래에 빈 줄 없이 `{% else %}` / `{% endif %}` 를 두면, 기존
# 번역에서 그 행은 태그 없이 표를 끝내며 **빈 줄을 달고** 있었다. 재사용
# (`_mirror_table_trail` 은 빈 줄을 더하기만 한다)이든 재번역(위치 기반 spacing)이든
# 행 덧붙임(`_append_table_unit` 이 앞 행의 빈 줄을 새 행 뒤로 옮김)이든 그 빈 줄이
# 행과 태그 사이에 남았다. Compute-Image#114 `member_status` 에서 `{% if %}` 가 짝
# 태그와 다른 블록으로 갈려 마크업 정정(M11)이 판정하지 못했다 (#115 에서 손으로 고침).
#
# ── 픽스처 (세션 브랜치에 생성 — alpha 상주 아님) ─────────────────────────
#   {ko,en,ja}/table-tag-trail.md — pre-align 정렬본. 다섯 절, 각 절에 표 하나.
#   ko 편집 후 모양 (모두 사이트의 Jinja 로 public/gov 렌더가 통과하는 문법):
#     #ttt-reuse   마지막 행(그대로)을 `{%- if public %}` … `{% else %}{% endif %}` 로 감쌈
#                  → 재사용 경로                                     (#1258 테스트 1)
#     #ttt-retx    마지막 행 문구 수정 + 바로 아래 `{% if gov %}{% endif %}`
#                  → 재번역 경로                                     (#1258 테스트 2)
#     #ttt-append  옛 마지막 행 아래에 행 2개 덧붙임 + 바로 아래 `{% endif %}`
#                  (표 위에 `{%- if public %}`) → 삽입 경로          (#1258 테스트 4)
#     #ttt-blank   대조군 — ko 가 마지막 행과 `{% if gov %}` 사이에 **빈 줄을 둠**
#                  → 빈 줄이 남아야 한다 (Storage-Online-NAS 모양)
#     #ttt-plain   대조군 — 태그 없음, 첫 행만 수정 → 표 끝 빈 줄 그대로 (#1258 테스트 3)
#   en/ja 는 편집 전 ko 의 번역 (태그 없음, 각 표가 빈 줄로 끝남).
#
# ── 판정 ─────────────────────────────────────────────────────────────────
# 불변식은 하나다: **en/ja 의 태그 줄 i 앞뒤 빈 줄 유무 = ko 의 태그 줄 i 앞뒤** (fence
# 밖 `{% … %}` 줄, 문서 순서로 짝). 여기에 태그 시퀀스 동일 · 절별 표 행 수 동일.
#   [A] 결정적 층 (모델 없음) — 이상적 모델(받은 단위를 그대로 돌려주고 엔진과 같은
#       `_strip_code_fence` 를 거침)로 실제 `translate_diff` 를 돌린다.
#       (1) en/ja 태그 줄 앞뒤 빈 줄이 ko 와 같다                   ← 결함
#       (2) 태그 시퀀스 · 절별 표 행 수가 ko 와 같다
#   [B] 산출물 층 — 로컬 translate_pr.py (CLI 엔진, 권장 preset) 실제 번역.
#       (3) 번역 성공 (exit 0, PARTIAL 없음)
#       (4) = (1) 을 실제 산출물에서                                 ← 결함(증상)
#       (5) = (2) 를 실제 산출물에서
#       (6) en/ja 표 행에 한글이 없다 (덧붙인 행·고친 행이 번역됐다)
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`TABLE_TAG_TRAIL: OK`) — #1258 이후 코드의 기대값
#   3  결함 재현 (`TABLE_TAG_TRAIL: REPRO`) — #1258 이전 코드의 기대값
#      (`CLOUD_TRANSLATE_DIR=<46a0a17f^ 체크아웃> … --dry` 로 확인한다)
#   1  기능 규칙 실패 (`TABLE_TAG_TRAIL: FAIL`)
#   2  인프라 — 번역 PR 미감지 · translate_pr.py 비정상 종료
#
# Usage:
#   source ./load_env.sh
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate bash scripts/e2e-table-tag-trail.sh
#   bash scripts/e2e-table-tag-trail.sh --dry      # [A] 만 (모델·네트워크·.env 없음)
#   bash scripts/e2e-table-tag-trail.sh --keep
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-tagtrail/$TS"
HEAD_BRANCH="translate-test-tagtrail/$TS"
DOC="table-tag-trail.md"
KEEP=0
DRY=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --dry)  DRY=1; shift ;;
    -h|--help) sed -n '2,52p' "$0"; exit 0 ;;
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

echo "=== table-tag-trail e2e ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 2>/dev/null | cut -c1-60))"
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
echo "[1] 세션 브랜치 생성 + 픽스처 시드 (편집 전 ko 와 그 번역)"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

# 절: (anchor, ko/en/ja heading, ko/en/ja 문장, 행 [(key, ko, en, ja)])
FIXTURE_PY='
SECTIONS = [
  ("ttt-reuse", ("정렬 파라미터", "Sorting Parameters", "ソートパラメータ"),
   ("목록을 정렬할 때 사용합니다.", "Used to sort the list.", "リストをソートするときに使用します。"),
   [("sort_dir", "정렬 방향", "Sort direction", "ソート方向"),
    ("member_status", "멤버 상태", "Member status", "メンバーの状態")]),
  ("ttt-retx", ("페이지 파라미터", "Paging Parameters", "ページングパラメータ"),
   ("목록을 나눠 조회할 때 사용합니다.", "Used to retrieve the list in pages.", "リストを分けて照会するときに使用します。"),
   [("limit", "한 번에 조회할 개수", "Number of items to retrieve at once", "一度に照会する件数"),
    ("offset", "조회 시작 위치", "Start position of the query", "照会開始位置")]),
  ("ttt-append", ("필터 파라미터", "Filter Parameters", "フィルタパラメータ"),
   ("목록을 걸러 낼 때 사용합니다.", "Used to filter the list.", "リストを絞り込むときに使用します。"),
   [("name", "이름 필터", "Name filter", "名前フィルタ"),
    ("status", "상태 필터", "Status filter", "状態フィルタ")]),
  ("ttt-blank", ("검색 파라미터", "Search Parameters", "検索パラメータ"),
   ("목록을 검색할 때 사용합니다.", "Used to search the list.", "リストを検索するときに使用します。"),
   [("keyword", "검색어", "Search keyword", "検索キーワード"),
    ("scope", "검색 범위", "Search scope", "検索範囲")]),
  ("ttt-plain", ("응답 필드", "Response Fields", "レスポンスフィールド"),
   ("응답 본문의 필드입니다.", "Fields of the response body.", "レスポンス本文のフィールドです。"),
   [("totalCount", "전체 개수", "Total count", "全体件数"),
    ("items", "항목 목록", "List of items", "項目リスト")]),
]
'
python3 - "$TS" "$DOC" "$FIXTURE_PY" <<'PY'
import io, os, sys
ts, doc, fx = sys.argv[1:4]
exec(fx)
L = {"ko": 0, "en": 1, "ja": 2}
HDR = {"ko": "| 이름 | 설명 |", "en": "| Name | Description |", "ja": "| 名前 | 説明 |"}
TITLE = {"ko": "table-tag-trail e2e 픽스처", "en": "table-tag-trail e2e fixture", "ja": "table-tag-trail e2e フィクスチャ"}
INTRO = {"ko": f"이 문서는 자동 생성된 e2e 픽스처입니다 ({ts}).",
         "en": f"This document is a generated e2e fixture ({ts}).",
         "ja": f"この文書は自動生成された e2e フィクスチャです ({ts})。"}
for lang, i in L.items():
    out = ["<!-- pre-align:aligned sig=e2e7a97a11 -->", "", '<a id="ttt"></a>', f"# {TITLE[lang]}", "", INTRO[lang], ""]
    for anchor, heads, prose, rows in SECTIONS:
        out += [f'<a id="{anchor}"></a>', f"## {heads[i]} {{ #{anchor} }}", "",
                HDR[lang], "| --- | --- |"]
        out += [f"| {k} | {r[i]} |" for k, *r in rows]
        out += ["", prose[i], ""]
    io.open(os.path.join(lang, doc), "w", encoding="utf-8", newline="").write("\n".join(out))
print(f"  생성: {{ko,en,ja}}/{doc}  (절 5개, 각 표 2행 · 태그 없음)")
PY
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(table-tag-trail): 픽스처 시드 ($TS)"
session_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$SESSION_BRANCH"

# ── 2) ko 편집 ────────────────────────────────────────────────────────────
echo "[2] ko 편집 — 표 마지막 행 바로 아래에 태그 (재사용·재번역·덧붙임) + 대조군 둘"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" <<'PY'
import io, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
EDITS = [
  # 재사용 — 행은 그대로, 태그로 감싼다 (Compute-Image#114 member_status)
  ("| member_status | 멤버 상태 |\n",
   '{%- if "public" in build_flags %}\n| member_status | 멤버 상태 |\n{% else %}\n{% endif %}\n'),
  # 재번역 — 마지막 행 문구 수정 + 바로 아래 (빈) 공공 분기
  ("| offset | 조회 시작 위치 |\n",
   '| offset | 조회를 시작할 위치(0부터) |\n{% if "gov" in build_flags %}\n{% endif %}\n'),
  # 덧붙임 — 표 전체를 public 분기로 감싸고 옛 마지막 행 아래에 두 행 추가
  ("| 이름 | 설명 |\n| --- | --- |\n| name | 이름 필터 |\n| status | 상태 필터 |\n",
   '{%- if "public" in build_flags %}\n| 이름 | 설명 |\n| --- | --- |\n| name | 이름 필터 |\n| status | 상태 필터 |\n'
   '| createdFrom | 생성 일시 시작 |\n| createdTo | 생성 일시 끝 |\n{% endif %}\n'),
  # 대조군 — ko 가 행과 태그 사이에 빈 줄을 둔다
  ("| scope | 검색 범위 |\n\n목록을 검색할 때 사용합니다.\n",
   '| scope | 검색할 범위 |\n\n{% if "gov" in build_flags %}\n공공 환경에서는 검색 범위가 제한됩니다.\n{% endif %}\n\n목록을 검색할 때 사용합니다.\n'),
  # 대조군 — 태그 없음, 첫 행만 수정
  ("| totalCount | 전체 개수 |\n", "| totalCount | 조건에 맞는 전체 개수 |\n"),
]
for old, new in EDITS:
    assert t.count(old) == 1, old
    t = t.replace(old, new)
io.open(p, "w", encoding="utf-8", newline="").write(t)
print(f"  {p}: 편집 {len(EDITS)}곳")
PY
git add -- "ko/$DOC"
git commit -q -m "e2e(table-tag-trail): ko 편집 — 표 마지막 행 아래 태그 ($TS)"
(( DRY )) || git push -q origin "$HEAD_BRANCH"
git show "$HEAD_BRANCH:ko/$DOC" > "$tmpdir/new_ko.md"

# 판정기 — 파일 둘(ko, 대상)을 받아 불변식 위반을 출력한다.
cat > "$tmpdir/judge.py" <<'PY'
import io, re, sys
TAG = re.compile(r"^\s*\{%-?\s*(if|elif|else|endif)\b")
FENCE = re.compile(r"^\s*(```|~~~)")
def tags(text):
    lines, out, fenced = text.split("\n"), [], False
    for i, l in enumerate(lines):
        if FENCE.match(l):
            fenced = not fenced
            continue
        if not fenced and TAG.match(l):
            blank_before = i > 0 and lines[i - 1].strip() == ""
            blank_after = i + 1 < len(lines) and lines[i + 1].strip() == ""
            out.append((l.strip(), blank_before, blank_after))
    return out
def rows_by_section(text):
    res, cur = {}, None
    for l in text.split("\n"):
        m = re.search(r"\{ #(ttt-[a-z]+) \}", l)
        if m:
            cur = m.group(1); res[cur] = 0
        elif cur and l.startswith("|") and not l.startswith("| ---"):
            res[cur] += 1
    return res
def judge(ko, tgt):
    """(빈 줄 위반 목록, 구조 위반 목록)"""
    tk, tt = tags(ko), tags(tgt)
    struct = []
    if [t[0] for t in tk] != [t[0] for t in tt]:
        struct.append(f"태그 시퀀스 ko {len(tk)} ↔ {len(tt)}")
    if rows_by_section(ko) != rows_by_section(tgt):
        struct.append(f"표 행 수 ko {rows_by_section(ko)} ↔ {rows_by_section(tgt)}")
    blank = [f"{a[0]} (ko 앞빈줄={a[1]} 뒤빈줄={a[2]} ↔ 앞빈줄={b[1]} 뒤빈줄={b[2]})"
             for a, b in zip(tk, tt) if a[1:] != b[1:]]
    return blank, struct
if __name__ == "__main__":
    ko = io.open(sys.argv[1], encoding="utf-8").read()
    tgt = io.open(sys.argv[2], encoding="utf-8").read()
    blank, struct = judge(ko, tgt)
    for b in blank:
        print("BLANK " + b)
    for s in struct:
        print("STRUCT " + s)
PY

judge_pair() {  # $1 label, $2 ko, $3 target → stdout 위반, 반환: 빈줄위반수 구조위반수
  local out; out="$(python3 "$tmpdir/judge.py" "$2" "$3")"
  [[ -n "$out" ]] && echo "$out" | sed "s/^/    [$1] /"
  JB=$(grep -c '^BLANK' <<<"$out" || true); JS=$(grep -c '^STRUCT' <<<"$out" || true)
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
a_blank=0; a_struct=0
for lang in en ja; do
  judge_pair "$lang" "$tmpdir/new_ko.md" "$tmpdir/a_$lang.md"
  a_blank=$((a_blank + JB)); a_struct=$((a_struct + JS))
done
(( a_blank == 0 )) && ok "(1) en/ja 태그 줄 앞뒤 빈 줄이 ko 와 같다" \
                   || defect "(1) 태그 줄 앞뒤 빈 줄이 ko 와 다르다 ($a_blank 곳, en+ja)"
(( a_struct == 0 )) && ok "(2) 태그 시퀀스 · 절별 표 행 수가 ko 와 같다" \
                    || bad "(2) 태그 시퀀스/표 행 수 불일치 ($a_struct 건)"

if (( DRY )); then
  echo
  if (( fails == 0 && repro == 0 )); then echo "TABLE_TAG_TRAIL: OK"; exit 0; fi
  if (( fails == 0 )); then echo "TABLE_TAG_TRAIL: REPRO"; exit 3; fi
  echo "TABLE_TAG_TRAIL: FAIL"; exit 1
fi

# ── 4) [B] 실제 번역 ───────────────────────────────────────────────────────
echo
echo "[4] [B] 실제 번역 — 로컬 translate_pr.py (CLI 엔진, 권장 preset)"
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(table-tag-trail): 표 마지막 행 바로 아래 태그 ($TS)" \
  --body "cloud-translate #1258 검증 — ko 가 표 마지막 행 아래에 빈 줄 없이 둔 태그는 en/ja 에서도 빈 줄 없이 붙어야 한다 (Compute-Image#114 → #115 모양)." \
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
  TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") 2>&1 | tee "$LOG" \
  | grep -E "Section-diff|anchor splice|Table reconcile|Template-tag|Translation PR|PARTIAL|ERROR" | sed 's/^/    /'
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
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"

echo
echo "[5] 산출물 판정"
b_blank=0; b_struct=0; b_hangul=0
for lang in en ja; do
  f="$tmpdir/tx/$lang/$DOC"
  if [[ ! -f "$f" ]]; then bad "번역 PR 에 $lang/$DOC 가 없다"; continue; fi
  judge_pair "$lang" "$tmpdir/new_ko.md" "$f"
  b_blank=$((b_blank + JB)); b_struct=$((b_struct + JS))
  h=$(grep -E '^\|' "$f" | grep -cP '[\x{AC00}-\x{D7A3}]' || true)
  (( h )) && grep -E '^\|' "$f" | grep -P '[\x{AC00}-\x{D7A3}]' | sed "s/^/    [$lang] 한글 행: /"
  b_hangul=$((b_hangul + h))
done
(( b_blank == 0 )) && ok "(4) en/ja 태그 줄 앞뒤 빈 줄이 ko 와 같다 (실제 산출물)" \
                   || defect "(4) 태그 줄 앞뒤 빈 줄이 ko 와 다르다 ($b_blank 곳, en+ja)"
(( b_struct == 0 )) && ok "(5) 태그 시퀀스 · 절별 표 행 수가 ko 와 같다 (실제 산출물)" \
                    || bad "(5) 태그 시퀀스/표 행 수 불일치 ($b_struct 건)"
(( b_hangul == 0 )) && ok "(6) en/ja 표 행에 한글이 없다" \
                    || bad "(6) en/ja 표 행에 한글이 남았다 ($b_hangul 행)"

echo
echo "[6] 결과"
echo "  ko PR: $ko_pr_url"
echo "  번역 PR: $tx_pr_url"
if (( fails == 0 && repro == 0 )); then echo "TABLE_TAG_TRAIL: OK"; exit 0; fi
KEEP=1
if (( fails == 0 )); then echo "TABLE_TAG_TRAIL: REPRO"; exit 3; fi
echo "TABLE_TAG_TRAIL: FAIL"; exit 1
