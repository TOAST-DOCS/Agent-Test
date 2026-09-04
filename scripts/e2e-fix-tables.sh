#!/usr/bin/env bash
#
# 깨진 표 정비(fix-tables) e2e — cloud-translate 의 translate_fix_tables.py 검증.
#
# 검증 대상: en/ja 를 ko 와 대조해 **표가 어긋난 section** 의 본문만 ko 기준으로
# 다시 만들고, **그 section 밖은 한 바이트도 건드리지 않는다**. 판정은 section
# (`<a id>`) 단위이고 두 종류뿐이다 — section 안 표 개수가 ko 와 다르거나(count),
# 짝지은 표에 ko 식별자 행이 없거나(keys).
#
# ── 왜 별도 e2e 인가 ──────────────────────────────────────────────────────
# 빈 번역 채우기(e2e-fill-stubs.sh)가 **비어 있는** section 을 채운다면 이 도구는
# **있는데 표가 깨진** section 을 잡는다 — 두 도구는 진입점도 판정도 다르다.
# 이 도구가 깨지는 방식은 번역 품질이 아니라 **판정과 범위**다:
#   - 정상 표를 "깨졌다" 고 오판해 멀쩡한 번역을 갈아엎음 (식별자 없는 표 등)
#   - 깨진 section 을 놓침 (첫 열만 덮인 표 — 행 수·열 수는 같다)
#   - 재구성이 heading·`<a id>` 를 다시 써서 pre-align 이 맞춰 둔 id 가 흔들림
#   - 재구성 결과가 ko 와 표 개수·행 수가 다른데 커밋됨 (모양 검사 누락)
#   - id 없는 하위 heading 의 표 때문에 위 section 을 엉뚱하게 다시 만듦
#   - section 밖 EOL/공백이 재작성돼 diff 가 문서 전체로 번짐
# 전부 바이트/구조 비교로 판정 가능하므로 이 e2e 는 LLM 판정을 쓰지 않는다.
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# `{ko,en,ja}/fix-tables-sample.md` (alpha 에 상주, `archive/fix-tables/` 에 원본).
# 언어당 다시 만들어야 할 section 3개 + 부정 대조군 3개:
#
#   count  #fix-tables-missing      ko 표 1 ↔ en/ja 표 0 (표가 사라짐)
#   keys   #fix-tables-shifted      행·열 수 같음, 첫 열의 식별자가 형식명으로 덮임
#   keys   #fix-tables-rows         식별자 행 하나 누락
#   (대조군) #fix-tables-untouched   정상 표 — 바이트 동일해야 한다
#   (대조군) #fix-tables-prose-keys  식별자 없는 표 + 개수 같음 — 손대면 안 된다.
#            그 아래 `### 앵커가 없는 하위 섹션` 에 식별자 행이 빠진 표가 있다:
#            anchor map 은 그 표를 위 section 소유로 보지만 재구성 단위는 그
#            heading 에서 끊기므로, 도구는 위 section 을 **다시 만들지 않고**
#            PR 본문에 '건너뜀' 으로 보고해야 한다.
#   (대조군) #fix-tables-tail        마지막 section — 바이트 동일
#
# 재구성이 성공해도 alpha 의 픽스처는 그대로다 — 세션 브랜치에서만 돌리고 브랜치를
# 폐기한다. (`scripts/restore-fix-tables-sample.sh` 는 alpha 픽스처가 손상됐을 때.)
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성
#   2) 픽스처 인벤토리 — 무엇이 깨졌는지 파일에서 **독립 구현으로** 읽는다
#   3) dry-run 탐지 (모델 호출 0 · PR 생성 없음)        [--translate local 전용]
#   4) 실제 정비 → Fix-tables PR
#   5) 판정 (아래 규칙, 전부 바이트/구조 비교)
#   6) 결과 (FIX_TABLES: OK|FAIL)
#   7) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) dry-run 이 깨진 section 3개를 언어마다 탐지하고, 앵커 없는 하위 heading 의
#       표는 skip 으로 보고하며, 브랜치/PR 을 만들지 않음   [local 전용, api=SKIP]
#   (2) 실제 실행이 Fix-tables PR 을 생성 (`Fix-tables PR:` / head=fix-tables/…)
#   (3) 다시 만든 section — 표 개수 == ko · 표마다 (열 수, 행 수) == ko ·
#       ko 식별자 첫 셀이 전부 있음 · 한글 잔류 0 (en) · 본문 비어있지 않음
#   (3b) 블록 구조(문단·표(행 수)·펜스·리스트(항목 수))가 ko 와 같음
#   (4) 다시 만든 section 의 `<a id>` 줄과 heading 줄이 base 와 **바이트 동일**
#   (5) 다시 만든 section **밖**은 base 와 바이트 동일 (대조군 셋 + 인트로, en/ja 각각)
#   (6) PR 본문이 다시 만든 id 를 사유와 함께 나열 · 앵커 없는 하위 heading 의
#       section 을 '건너뜀' 으로 보고 · section 마다 before/after Docs Preview 링크
#       (섹션 앵커 + 커밋 SHA)
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-fix-tables.sh                      # 로컬 translate_fix_tables.py
#   bash scripts/e2e-fix-tables.sh --translate api      # dashboard /api/fix-tables → Jenkins
#   bash scripts/e2e-fix-tables.sh --keep               # 브랜치/PR 보존 (디버깅)
#   bash scripts/e2e-fix-tables.sh --doc fix-tables-sample.md
#   bash scripts/e2e-fix-tables.sh --base-source e2e/my-branch   # alpha 대신 그 브랜치에서
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-fix-tables.sh
#
# 의존성: git, gh (로그인), python3, jq 불필요.
#   --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN (load_env.sh) 필요.
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-fixtables/$TS"
DOC="fix-tables-sample.md"  # alpha 상주 픽스처 (archive/fix-tables/ 에 원본)
KEEP=0
TRANSLATE_MODE="local"     # local | api
# 기본값 cli — 배포된 translate 잡의 .env 가 claude-code 이고, 대시보드
# /api/fix-tables 는 ENGINE 을 보내지 않아 그 .env 값이 이긴다 (fill-stubs e2e 와
# 같은 이유). --engine 으로만 낮춘다.
ENGINE="claude-code"       # local 모드에서만 의미 (api|cli|default)
TRANSLATE_MODEL="claude-haiku-4-5"   # local 모드에서만 의미 (--model 로 override)
JOB_TIMEOUT="${JOB_TIMEOUT:-1800}"

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    --base-source) BASE_SOURCE="$2"; SESSION_BRANCH="e2e-fixtables/$TS"; shift 2 ;;
    --translate) TRANSLATE_MODE="$2"; shift 2 ;;
    --engine)
      case "${2:-}" in
        api)         ENGINE="api" ;;
        cli)         ENGINE="claude-code" ;;
        claude-code) ENGINE="claude-code" ;;
        default)     ENGINE="" ;;
        *) echo "error: --engine 은 api|cli|default (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --model)
      case "${2:-}" in
        haiku)   TRANSLATE_MODEL="claude-haiku-4-5" ;;
        sonnet)  TRANSLATE_MODEL="claude-sonnet-4-6" ;;
        opus)    TRANSLATE_MODEL="claude-opus-4-8" ;;
        default) TRANSLATE_MODEL="" ;;
        *) echo "error: --model 은 haiku|sonnet|opus|default (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -h|--help) sed -n '1,75p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$TRANSLATE_MODE" in
  local|api) ;;
  *) echo "error: --translate 는 local|api" >&2; exit 1 ;;
esac
if [[ "$TRANSLATE_MODE" == "api" && ( -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ) ]]; then
  echo "error: --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다 (load_env.sh)." >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"; LOG="$tmpdir/fix.log"; DRYLOG="$tmpdir/dryrun.log"

fix_pr_url=""
cleanup() {
  local rc=$?
  if (( KEEP )); then
    echo; echo "--keep: 보존 — 세션 $SESSION_BRANCH / PR ${fix_pr_url:-<none>}"
    echo "  정리: gh pr close <n> --repo $REPO --delete-branch; git push origin :$SESSION_BRANCH"
    return $rc
  fi
  echo; echo "[cleanup] Fix-tables PR · 브랜치 정리"
  [[ -n "$fix_pr_url" ]] && gh pr close "$fix_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/fix-tables/*" 2>/dev/null | sed 's|.*refs/heads/||')
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC (alpha 상주 픽스처)"
echo "mode    : --translate $TRANSLATE_MODE"
echo

# ── 1) 세션 브랜치 ────────────────────────────────────────────────────────
echo "[1/7] 세션 브랜치 생성 (픽스처는 alpha 상주 — 시드 없음)"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"
for f in "ko/$DOC" "en/$DOC" "ja/$DOC"; do
  [[ -f "$f" ]] || { echo "error: 픽스처 없음: $f (alpha 에 있어야 합니다)" >&2; exit 2; }
done
git push -q -f origin "$SESSION_BRANCH"
base_sha="$(git rev-parse HEAD)"
echo "  세션 base: $base_sha"

# ── 2) 픽스처 인벤토리 ────────────────────────────────────────────────────
# 무엇이 깨졌는지는 픽스처 파일이 정본이다. 도구와 **같은 원리로 따로 구현**한다 —
# 판정이 판정 대상을 import 하면 아무것도 검증하지 못한다.
echo
echo "[2/7] 픽스처 인벤토리"
inv="$(python3 - "$DOC" <<'PY'
import io, re, sys

doc = sys.argv[1]
ANCHOR = re.compile(r'^<a id="([^"]+)"></a>\s*$')
HEADING = re.compile(r"^(#{2,6})\s+(.*)$")
TBL_SEP = re.compile(r"^\s*\|[\s:\-|]+\|\s*$")
IDENT = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+-]*$")
CAMEL = re.compile(r"[a-z][A-Z]")


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


def sections(text):
    """{anchor_id: raw} — `<a id>` 에서만 자른다. 앵커 없는 heading 은 앞 section 에
    흡수된다 (도구의 anchor map 이 표를 귀속시키는 방식과 같다)."""
    out, cur, buf = {}, "__pre__", []
    for ln in text.splitlines(keepends=True):
        m = ANCHOR.match(ln.rstrip("\r\n"))
        if m:
            out[cur] = "".join(buf)
            cur, buf = m.group(1), [ln]
            continue
        buf.append(ln)
    out[cur] = "".join(buf)
    return out


def tables(raw):
    """[(header_cells, [row_cells, …]), …]"""
    lines = raw.splitlines()
    out, i = [], 0
    while i < len(lines) - 1:
        if lines[i].strip().startswith("|") and TBL_SEP.match(lines[i + 1]):
            head = [c.strip() for c in lines[i].strip().strip("|").split("|")]
            rows, j = [], i + 2
            while j < len(lines) and lines[j].strip().startswith("|"):
                rows.append([c.strip().replace("**", "").replace("`", "")
                             for c in lines[j].strip().strip("|").split("|")])
                j += 1
            out.append((head, rows))
            i = j
        else:
            i += 1
    return out


def is_key(cell):
    return bool(IDENT.match(cell)) and (any(ch.isdigit() for ch in cell)
                                        or "_" in cell or "." in cell
                                        or bool(CAMEL.search(cell)))


def has_anchorless_heading(raw):
    lines = raw.splitlines()
    return any(HEADING.match(l) for l in lines[2:])   # [0]=<a id>, [1]=heading


ko = sections(read(f"ko/{doc}"))
expect = {}
for lang in ("en", "ja"):
    tg = sections(read(f"{lang}/{doc}"))
    rebuild, skip = [], []
    for aid, kraw in ko.items():
        if aid == "__pre__" or aid not in tg:
            continue
        kt, tt = tables(kraw), tables(tg[aid])
        if not kt:
            continue
        broken = len(kt) != len(tt)
        if not broken:
            for (kh, krows), (th, trows) in zip(kt, tt):
                keys = [r[0] for r in krows if r and is_key(r[0])]
                cells = {c for r in trows for c in r}
                if any(k not in cells for k in keys):
                    broken = True
        if not broken:
            continue
        (skip if has_anchorless_heading(kraw) else rebuild).append(aid)
    expect[lang] = (rebuild, skip)

if expect["en"] != expect["ja"]:
    raise SystemExit(f"error: en/ja 의 깨진 section 이 다르다: {expect}")
rebuild, skip = expect["en"]
if not rebuild or not skip:
    raise SystemExit(f"error: 픽스처에서 깨진 section/대조군을 찾지 못함: {expect}")
print("REBUILD_IDS=" + ",".join(rebuild))
print("SKIP_IDS=" + ",".join(skip))
PY
)" || { echo "error: 픽스처 인벤토리 실패" >&2; exit 2; }
echo "$inv" | sed 's/^/  /'
REBUILD_IDS="$(sed -n 's/^REBUILD_IDS=//p' <<<"$inv")"
SKIP_IDS="$(sed -n 's/^SKIP_IDS=//p' <<<"$inv")"
n_rebuild=$(awk -F, '{print NF}' <<<"$REBUILD_IDS")

# ── 3) dry-run 탐지 ──────────────────────────────────────────────────────
dry_skipped=0
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  echo
  echo "[3/7] dry-run 탐지 (모델 호출 0)"
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    "$CLOUD_TRANSLATE_PY" translate/translate_fix_tables.py "$REPO" "$SESSION_BRANCH" \
      --only "en/$DOC,ja/$DOC" --dry-run \
  ) > "$DRYLOG" 2>&1
  set -e
  grep -E '^  (en|ja)/|^      #|탐지만' "$DRYLOG" | sed 's/^/  /' || true
else
  echo
  echo "[3/7] dry-run 탐지 — SKIP (--translate api)"
  dry_skipped=1
fi

# ── 4) 실제 정비 ─────────────────────────────────────────────────────────
echo
echo "[4/7] 깨진 표 정비 실행"
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  echo "  engine=${ENGINE:-<.env 기본>} model=${TRANSLATE_MODEL:-<.env 기본>}"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    env ${ENGINE:+TRANSLATE_TRANSLATE_ENGINE="$ENGINE"} \
        ${TRANSLATE_MODEL:+TRANSLATE_ANTHROPIC_MODEL="$TRANSLATE_MODEL"} \
        ${TRANSLATE_MODEL:+TRANSLATE_CLAUDE_CODE_MODEL="$TRANSLATE_MODEL"} \
      "$CLOUD_TRANSLATE_PY" translate/translate_fix_tables.py "$REPO" "$SESSION_BRANCH" \
        --only "en/$DOC,ja/$DOC" \
  ) 2>&1 | tee "$LOG"
  fix_rc=${PIPESTATUS[0]}
  set -e
  fix_pr_url="$(grep -oE 'Fix-tables PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
else
  # dashboard 경로 — 🧹 문서 정비 '깨진 표 정비' 카드와 동일한 단일 라우트.
  resp="$(curl -sS -X POST \
    -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"target\": \"https://github.com/$REPO\", \"branch\": \"$SESSION_BRANCH\",
         \"langs\": \"en,ja\", \"only\": \"en/$DOC,ja/$DOC\"}" \
    "$DASHBOARD_BASE_URL/api/fix-tables")"
  echo "$resp" | python3 -m json.tool | sed 's/^/  /'
  job_id="$(printf '%s' "$resp" | python3 -c 'import json,sys; print((json.load(sys.stdin) or {}).get("job_id") or "")')"
  [[ -n "$job_id" ]] || { echo "error: /api/fix-tables 응답에 job_id 없음" >&2; exit 2; }
  echo "  잡 완료 대기 (job_id=$job_id, timeout=${JOB_TIMEOUT}s)"
  deadline=$(( $(date +%s) + JOB_TIMEOUT )); status=""
  while (( $(date +%s) < deadline )); do
    status="$(curl -sS --retry 3 --retry-delay 5 \
      -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
      "$DASHBOARD_BASE_URL/api/jobs/$job_id" 2>/dev/null \
      | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin); t=(d.get("job") or {}).get("tasks") or []
  print(t[0].get("status") if t else "")
except Exception:
  print("")' || true)"
    case "$status" in success|failure|cancelled|partial) break ;; esac
    sleep 15
  done
  echo "  잡 status=$status"
  fix_rc=0; [[ "$status" == "success" ]] || fix_rc=1
  fix_pr_url="$(gh pr list --repo "$REPO" --base "$SESSION_BRANCH" --state all \
    --json url,headRefName --jq '[.[] | select(.headRefName | startswith("fix-tables/")) | .url] | last // ""')"
fi

# ── 5) 판정 ───────────────────────────────────────────────────────────────
echo
echo "[5/7] 판정"
fails=0
ok()   { echo "  PASS  $1"; }
bad()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
skip() { echo "  SKIP  $1"; }

# (1) dry-run
if (( dry_skipped )); then
  skip "(1) dry-run 탐지 — api 모드"
else
  d_ok=1
  for id in ${REBUILD_IDS//,/ }; do
    (( $(grep -c "#$id " "$DRYLOG") >= 2 )) || { d_ok=0; echo "        dry-run 에 #$id 가 en/ja 양쪽에 없음"; }
  done
  for id in ${SKIP_IDS//,/ }; do
    grep -q "skip: #$id" "$DRYLOG" || { d_ok=0; echo "        앵커 없는 하위 heading 의 skip 보고 없음 (#$id)"; }
    grep -q "^      #$id " "$DRYLOG" && { d_ok=0; echo "        대조군 #$id 가 재구성 대상으로 잡힘"; }
  done
  grep -q "탐지만 수행" "$DRYLOG" || { d_ok=0; echo "        dry-run 종료 문구 없음"; }
  if grep -q "Fix-tables PR:" "$DRYLOG"; then d_ok=0; echo "        dry-run 이 PR 을 만들었다"; fi
  (( d_ok )) && ok "(1) dry-run 이 section ${n_rebuild}개×2언어 탐지 · 앵커 없는 하위 heading skip · PR 미생성" \
              || bad "(1) dry-run 결과가 기대와 다름 (로그: $DRYLOG)"
fi

# (2) Fix-tables PR
if (( fix_rc == 0 )) && [[ -n "$fix_pr_url" ]]; then
  ok "(2) Fix-tables PR 생성 — $fix_pr_url"
  e2e_label_pr "$REPO" "$fix_pr_url"
else
  bad "(2) Fix-tables PR 미생성 (exit=$fix_rc) — 이후 검사 불가 (로그: $LOG)"
  echo; echo "FIX_TABLES: FAIL"; KEEP=1; exit 1
fi

fix_branch="$(gh pr view "$fix_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$fix_branch"
for lang in en ja; do
  git show "origin/$fix_branch:$lang/$DOC" > "$tmpdir/$lang.fixed.md" 2>/dev/null || \
    echo "(missing)" > "$tmpdir/$lang.fixed.md"
  git show "$base_sha:$lang/$DOC" > "$tmpdir/$lang.base.md"
done
git show "$base_sha:ko/$DOC" > "$tmpdir/ko.md"
gh pr view "$fix_pr_url" --repo "$REPO" --json body --jq .body > "$tmpdir/pr_body.md"

# (3)~(6) 구조/바이트 검사 — LLM 판정 없음.
python3 - "$tmpdir" "$REBUILD_IDS" "$SKIP_IDS" <<'PY' || fails=$((fails + 1))
import io, re, sys

tmp, rebuild_csv, skip_csv = sys.argv[1:4]
rebuild_ids = [s for s in rebuild_csv.split(",") if s]
skip_ids = [s for s in skip_csv.split(",") if s]

HANGUL = re.compile(r"[가-힣]")
ANCHOR = re.compile(r'^<a id="([^"]+)"></a>\s*$')
FENCE = re.compile(r"^\s*(```+|~~~+)")
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")
TBL_SEP = re.compile(r"^\s*\|[\s:\-|]+\|\s*$")
IDENT = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+-]*$")
CAMEL = re.compile(r"[a-z][A-Z]")
rc = 0


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


def sections(text):
    out, cur, buf = {}, "__pre__", []
    for ln in text.splitlines(keepends=True):
        m = ANCHOR.match(ln.rstrip("\r\n"))
        if m:
            out[cur] = "".join(buf)
            cur, buf = m.group(1), [ln]
            continue
        buf.append(ln)
    out[cur] = "".join(buf)
    return out


def head_lines(raw):
    """(<a id> 줄, heading 줄) — 재구성이 건드리면 안 되는 두 줄."""
    ls = raw.splitlines()
    return (ls[0] if ls else "", ls[1] if len(ls) > 1 else "")


def body_of(raw):
    return "\n".join(raw.splitlines()[2:])


def tables(raw):
    lines = raw.splitlines()
    out, i = [], 0
    while i < len(lines) - 1:
        if lines[i].strip().startswith("|") and TBL_SEP.match(lines[i + 1]):
            head = [c.strip() for c in lines[i].strip().strip("|").split("|")]
            rows, j = [], i + 2
            while j < len(lines) and lines[j].strip().startswith("|"):
                rows.append([c.strip().replace("**", "").replace("`", "")
                             for c in lines[j].strip().strip("|").split("|")])
                j += 1
            out.append((head, rows))
            i = j
        else:
            i += 1
    return out


def is_key(cell):
    return bool(IDENT.match(cell)) and (any(ch.isdigit() for ch in cell)
                                        or "_" in cell or "." in cell
                                        or bool(CAMEL.search(cell)))


def block_shape(text):
    """도구(`_block_shape`)와 같은 원리로 따로 구현 — e2e-fill-stubs.sh 와 동일."""
    lines = text.splitlines()
    out, prose = [], False

    def flush():
        nonlocal prose
        if prose:
            out.append("text")
            prose = False

    i, n = 0, len(lines)
    while i < n:
        stripped = lines[i].strip()
        if not stripped:
            flush(); i += 1; continue
        m = FENCE.match(lines[i])
        if m:
            flush()
            close = m.group(1)[0] * 3
            i += 1
            while i < n and not lines[i].strip().startswith(close):
                i += 1
            i += 1
            out.append("fence"); continue
        if stripped.startswith("|") and i + 1 < n and TBL_SEP.match(lines[i + 1]):
            flush()
            i += 2
            rows = 0
            while i < n and lines[i].strip().startswith("|"):
                rows += 1; i += 1
            out.append(f"table({rows})"); continue
        if LIST_ITEM.match(lines[i]):
            flush()
            items = 0
            while i < n:
                cur = lines[i]
                if LIST_ITEM.match(cur):
                    items += 1; i += 1; continue
                if cur.strip() and cur[:1] in (" ", "\t"):
                    i += 1; continue
                if not cur.strip():
                    j = i + 1
                    while j < n and not lines[j].strip():
                        j += 1
                    if j < n and (LIST_ITEM.match(lines[j]) or lines[j][:1] in (" ", "\t")):
                        i = j; continue
                break
            out.append(f"list({items})"); continue
        prose = True
        i += 1
    flush()
    return out


def ok(msg):
    print(f"  PASS  {msg}")


def bad(msg, *extra):
    global rc
    print(f"  FAIL  {msg}")
    for e in extra:
        print(f"        {e}")
    rc = 1


ko = sections(read(f"{tmp}/ko.md"))
langs = {lang: (sections(read(f"{tmp}/{lang}.base.md")),
                sections(read(f"{tmp}/{lang}.fixed.md")))
         for lang in ("en", "ja")}

# (3) 다시 만든 section — 표 모양 · 식별자 · 한글 · 비어있지 않음
for lang, (base, new) in langs.items():
    for aid in rebuild_ids:
        sec = new.get(aid, "")
        kt, nt = tables(ko.get(aid, "")), tables(sec)
        if not sec.strip():
            bad(f"(3) {lang} #{aid} section 이 사라짐"); continue
        if len(nt) != len(kt):
            bad(f"(3) {lang} #{aid} 표 개수가 ko({len(kt)}) 와 다름({len(nt)})",
                "표 개수가 다른 채로 커밋되면 모양 검사가 빠진 것이다"); continue
        shape_bad = [(i, (len(kh), len(kr)), (len(th), len(tr)))
                     for i, ((kh, kr), (th, tr)) in enumerate(zip(kt, nt), 1)
                     if (len(kh), len(kr)) != (len(th), len(tr))]
        if shape_bad:
            bad(f"(3) {lang} #{aid} 표 (열, 행) 이 ko 와 다름: {shape_bad}",
                "열이 줄면 렌더러가 셀을 조용히 버린다"); continue
        keys = [r[0] for _, rows in kt for r in rows if r and is_key(r[0])]
        cells = {c for _, rows in nt for r in rows for c in r}
        miss = [k for k in keys if k not in cells]
        if miss:
            bad(f"(3) {lang} #{aid} 에 ko 식별자 행이 여전히 없음: {miss}"); continue
        if lang == "en" and HANGUL.search(sec):
            bad(f"(3) {lang} #{aid} 에 한글 잔류 — 번역되지 않은 채 ko 가 복사됨",
                *[l for l in sec.splitlines() if HANGUL.search(l)][:3]); continue
        if len(body_of(sec).strip()) < 20:
            bad(f"(3) {lang} #{aid} 본문이 비어 있음"); continue
        ok(f"(3) {lang} #{aid} 표 {len(nt)}개 · ko 식별자 {len(keys)}개 복원 · 모양 일치")
        # (3b) 블록 구조
        ks, ns = block_shape(body_of(ko.get(aid, ""))), block_shape(body_of(sec))
        if ks == ns:
            ok(f"(3b) {lang} #{aid} 블록 구조가 ko 와 동일 {ks}")
        else:
            bad(f"(3b) {lang} #{aid} 블록 구조가 ko 와 다름", f"ko : {ks}", f"new: {ns}")

# (4) 다시 만든 section 의 <a id>/heading 줄은 바이트 동일
for lang, (base, new) in langs.items():
    drift = [aid for aid in rebuild_ids
             if head_lines(base.get(aid, "")) != head_lines(new.get(aid, ""))]
    if drift:
        bad(f"(4) {lang} 의 재구성 section heading/anchor 가 변경됨: {', '.join(drift)}",
            *[f"{a}: {head_lines(base.get(a,''))!r} → {head_lines(new.get(a,''))!r}"
              for a in drift[:2]])
    else:
        ok(f"(4) {lang} 재구성 section {len(rebuild_ids)}개의 <a id>/heading 바이트 보존")

# (5) 재구성 section 밖은 바이트 동일 (대조군 셋 + 인트로 + 앵커 없는 하위 섹션)
for lang, (base, new) in langs.items():
    diffs = [k for k in set(base) | set(new)
             if k not in rebuild_ids and base.get(k) != new.get(k)]
    if diffs:
        bad(f"(5) {lang} 의 다른 section 이 변경됨: {', '.join(sorted(map(str, diffs))[:5])}",
            "정비는 깨진 section 밖을 한 바이트도 건드리면 안 된다 — "
            "대조군(정상 표 · 식별자 없는 표 · 앵커 없는 하위 섹션)이 여기 든다")
    else:
        ok(f"(5) {lang} 는 재구성 section 밖이 base 와 바이트 동일 ({len(base)}개 구간, "
           f"대조군 {', '.join('#' + s for s in skip_ids)} 포함)")

# (6) PR 본문
pr_body = read(f"{tmp}/pr_body.md")
missing = [i for i in rebuild_ids if f"`#{i}`" not in pr_body]
if missing:
    bad(f"(6a) PR 본문에 다시 만든 id 가 없음: {', '.join(missing)}")
else:
    ok(f"(6a) PR 본문이 다시 만든 section id {len(rebuild_ids)}개를 나열")
if "표 개수 ko" in pr_body and "식별자" in pr_body:
    ok("(6a) PR 본문이 사유(표 개수 / 식별자 누락)를 함께 적음")
else:
    bad("(6a) PR 본문에 재구성 사유가 없음")
if "건너뜀" in pr_body and all(f"`#{s}`" in pr_body for s in skip_ids):
    ok(f"(6b) PR 본문이 앵커 없는 하위 heading 의 section 을 '건너뜀' 으로 보고 ({', '.join(skip_ids)})")
else:
    bad("(6b) PR 본문에 앵커 없는 하위 heading 의 건너뜀 보고가 없음 — 조용히 빠지면 아무도 모른다")

links = {}
for anchor in rebuild_ids:
    pat = (r"\[before\]\((?P<b>[^)]*?/view\?[^)]*?#" + re.escape(anchor) + r")\)"
           r"[^\n]*?\[after\]\((?P<a>[^)]*?/view\?[^)]*?#" + re.escape(anchor) + r")\)")
    m = re.search(pat, pr_body)
    links[anchor] = m
    if not m:
        bad(f"(6c) #{anchor} 의 before/after 프리뷰 링크가 PR 본문에 없음")
if all(links.values()):
    sha40 = re.compile(r"tx_ref=[0-9a-f]{40}")
    bad_ref = [a for a, m in links.items()
               if not (sha40.search(m.group("b")) and sha40.search(m.group("a")))]
    if bad_ref:
        bad("(6c) 프리뷰 링크가 커밋 SHA 가 아님: " + ", ".join(bad_ref))
    elif any(m.group("b") == m.group("a") for m in links.values()):
        bad("(6c) before 와 after 링크가 동일 — 두 상태를 가리키지 못한다")
    else:
        ok(f"(6c) 재구성 section {len(links)}개에 before/after 프리뷰 링크 (앵커 + 커밋 SHA)")

raise SystemExit(rc)
PY

# ── 6) 결과 ───────────────────────────────────────────────────────────────
echo
echo "[6/7] 결과"
if (( fails == 0 )); then
  echo "FIX_TABLES: OK"
  echo "  깨진 표 정비가 어긋난 section 만 ko 로 다시 만들고 나머지는 바이트 보존 (PR: $fix_pr_url)"
  echo
  echo "[7/7] cleanup"
  exit 0
fi
echo "FIX_TABLES: FAIL"
echo "  $fails 개 규칙 실패 — 로그: $LOG / dry-run: $DRYLOG"
echo "  PR 은 보존합니다: $fix_pr_url"
KEEP=1
exit 1
