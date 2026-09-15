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
# 언어당 고쳐야 할 section 4개 + 부정 대조군 2개. **수리 단위가 둘이고, 어느
# 쪽이 되는지는 "어느 표가 어느 ko 표의 번역인지 확정할 수 있는가" 로 갈린다** —
# 확정되면 그 표만(표 수리), 확정할 수 없으면 section 본문 전체(재구성):
#
#   재구성 #fix-tables-missing      ko 표 1 ↔ en/ja 표 0 — 짝지을 표가 없다
#   표수리 #fix-tables-shifted      행·열 수 같음, 첫 열의 식별자가 형식명으로 덮임
#   표수리 #fix-tables-rows         식별자 행 하나 누락 → 그 행만 삽입
#   표수리 #fix-tables-prose-keys   section 자신의 표는 식별자가 없고 개수도 같아
#            손대면 안 된다. 그 아래 `### 앵커가 없는 하위 섹션` 의 표에 식별자
#            행 하나가 빠져 있고, 그 표는 **식별자 키로 짝이 확정되므로** 도구가
#            그 행만 삽입한다 — 위 section 을 다시 만들지 않고 PR 본문에
#            '행 삽입' 으로 공개해야 한다.
#   (대조군) #fix-tables-untouched   정상 표 — 바이트 동일해야 한다
#   (대조군) #fix-tables-tail        마지막 section — 바이트 동일
#
# 2026-09-15 까지 이 픽스처는 prose-keys 를 "건너뛰고 보고해야 하는 대조군" 으로
# 기대했다. 그때는 수리 단위가 재구성 하나뿐이라, 재구성 단위가 앵커 없는 하위
# heading 에서 끊기면 도구가 손을 뗄 수밖에 없었기 때문이다. cloud-translate
# #851(빠진 행만 넣는 행 단위 수리)/#870(캡션·키 짝짓기) 이 들어오면서 그 표는
# **고칠 수 있는 표**가 됐고, 기대치를 그에 맞춰 옮겼다. 그래서 skip 경로
# (`skipped_child` · PR 본문의 '확정할 수 없음') 는 이 픽스처로 더 이상 밟히지
# 않는다 — 그 경로를 검증하려면 식별자 열이 아예 없는 표를 가진 하위 heading
# 픽스처가 따로 필요하다.
#
# 재구성이 성공해도 alpha 의 픽스처는 그대로다 — 세션 브랜치에서만 돌리고 브랜치를
# 폐기한다. (`scripts/restore-fix-tables-sample.sh` 는 alpha 픽스처가 손상됐을 때.)
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성
#   2) 픽스처 인벤토리 — 무엇이 깨졌는지 파일에서 **독립 구현으로** 읽는다
#   3) dry-run 리허설 — 수리는 실제로 돌고 PR 은 sandbox 리포로 [local 전용]
#   4) 실제 정비 → Fix-tables PR
#   5) 판정 (아래 규칙, 전부 바이트/구조 비교)
#   6) 결과 (FIX_TABLES: OK|FAIL)
#   7) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) dry-run 이 깨진 section 4개를 언어마다 **수리 단위(표/section)까지 맞게**
#       탐지하고, 대상 리포에는 한 바이트도 쓰지 않으며 PR 을 sandbox 리포
#       (`TRANSLATE_FIXTABLES_DRYRUN_REPO`, 기본 `TOAST-DOCS/translate-test`) 에
#       연다. dry-run 은 2026-08 (#838) 부터 탐지-only 가 아니라 **리허설**이다 —
#       수리가 실제로 돌아야 "수리가 맞는가" 에 답할 수 있기 때문  [local 전용]
#   (2) 실제 실행이 Fix-tables PR 을 생성 (`Fix-tables PR:` / head=fix-tables/…)
#   (3) 고친 section — 표 개수 == ko · 표마다 (열 수, 행 수) == ko ·
#       ko 식별자 첫 셀이 전부 있음 · 한글 잔류 0 (en) · 본문 비어있지 않음
#   (3b) 블록 구조(문단·표(행 수)·펜스·리스트(항목 수))가 ko 와 같음
#   (4) 고친 section 의 `<a id>` 줄과 heading 줄이 base 와 **바이트 동일**
#   (5a) 고친 section **밖**은 base 와 바이트 동일 (대조군 + 인트로, en/ja 각각)
#   (5b) **표 수리 section 은 바뀐 곳이 표 안에 머문다** — 표 밖 바이트 동일 ·
#        표 개수 유지 · 행 삭제 0 · 식별자 없는 표는 바이트 동일.
#        수리 단위가 둘이 된 뒤로 "section 밖" 만으로는 범위를 못 재는다
#   (6) PR 본문이 고친 id 를 사유와 함께 나열 · 하위 heading 표의 '행 삽입' 을
#       공개 · section 마다 ko↔변경 전/후 Docs Preview 링크 (앵커 + 커밋 SHA)
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
    -h|--help) sed -n '1,90p' "$0"; exit 0 ;;
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
dry_pr_url=""            # dry-run 리허설 PR — sandbox 리포에 열린다
dry_target_branches=0    # dry-run 직후 대상 리포의 fix-tables/* 브랜치 수 (기대 0)

# dry-run 리허설이 sandbox 리포에 남긴 PR·브랜치를 지운다. 리허설은 base 브랜치
# (수리 전 상태) 와 head 브랜치 두 개를 만들므로 PR 닫기만으로는 base 가 남는다.
cleanup_dry_run() {
  [[ -n "$dry_pr_url" ]] || return 0
  local repo="${dry_pr_url#https://github.com/}"; repo="${repo%%/pull/*}"
  local base
  base="$(gh pr view "$dry_pr_url" --repo "$repo" --json baseRefName --jq .baseRefName 2>/dev/null || true)"
  gh pr close "$dry_pr_url" --repo "$repo" --delete-branch >/dev/null 2>&1 || true
  [[ "$base" == fix-tables-dryrun/* ]] && \
    gh api -X DELETE "repos/$repo/git/refs/heads/$base" >/dev/null 2>&1 || true
}

cleanup() {
  local rc=$?
  if (( KEEP )); then
    echo; echo "--keep: 보존 — 세션 $SESSION_BRANCH / PR ${fix_pr_url:-<none>}"
    echo "  dry-run 리허설 PR (sandbox): ${dry_pr_url:-<none>}"
    echo "  정리: gh pr close <n> --repo $REPO --delete-branch; git push origin :$SESSION_BRANCH"
    return $rc
  fi
  echo; echo "[cleanup] Fix-tables PR · 브랜치 · dry-run sandbox 정리"
  cleanup_dry_run
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
    rebuild, repair, child = [], [], []
    for aid, kraw in ko.items():
        if aid == "__pre__" or aid not in tg:
            continue
        kt, tt = tables(kraw), tables(tg[aid])
        if not kt:
            continue
        count_differs = len(kt) != len(tt)
        broken = count_differs
        if not broken:
            for (kh, krows), (th, trows) in zip(kt, tt):
                keys = [r[0] for r in krows if r and is_key(r[0])]
                cells = {c for r in trows for c in r}
                if any(k not in cells for k in keys):
                    broken = True
        if not broken:
            continue
        # 수리 단위는 "짝을 확정할 수 있는가" 로 갈린다 — 표 개수가 같으면 그 표만
        # 고치고(표 수리), 다르면 짝지을 표가 없어 section 본문을 다시 만든다(재구성).
        (rebuild if count_differs else repair).append(aid)
        if not count_differs and has_anchorless_heading(kraw):
            child.append(aid)
    expect[lang] = (rebuild, repair, child)

if expect["en"] != expect["ja"]:
    raise SystemExit(f"error: en/ja 의 깨진 section 이 다르다: {expect}")
rebuild, repair, child = expect["en"]
if not rebuild or not repair or not child:
    raise SystemExit(
        f"error: 픽스처에서 기대한 세 갈래(재구성/표수리/하위heading)를 찾지 못함: {expect}")
print("REBUILD_IDS=" + ",".join(rebuild))
print("REPAIR_IDS=" + ",".join(repair))
print("CHILD_IDS=" + ",".join(child))
PY
)" || { echo "error: 픽스처 인벤토리 실패" >&2; exit 2; }
echo "$inv" | sed 's/^/  /'
REBUILD_IDS="$(sed -n 's/^REBUILD_IDS=//p' <<<"$inv")"
REPAIR_IDS="$(sed -n 's/^REPAIR_IDS=//p' <<<"$inv")"
CHILD_IDS="$(sed -n 's/^CHILD_IDS=//p' <<<"$inv")"
FIXED_IDS="$REBUILD_IDS,$REPAIR_IDS"
n_fixed=$(awk -F, '{print NF}' <<<"$FIXED_IDS")

# ── 3) dry-run 탐지 ──────────────────────────────────────────────────────
dry_skipped=0
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  echo
  echo "[3/7] dry-run 리허설 (수리는 실제로 돌고 PR 은 sandbox 리포로)"
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
  # 다른 실행이 --keep 으로 남긴 fix-tables/* 가 있을 수 있으므로 절대 개수가
  # 아니라 dry-run 전후의 **증가분**을 센다.
  dry_branches_before="$(git ls-remote --heads origin 'refs/heads/fix-tables/*' 2>/dev/null | wc -l)"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    "$CLOUD_TRANSLATE_PY" translate/translate_fix_tables.py "$REPO" "$SESSION_BRANCH" \
      --only "en/$DOC,ja/$DOC" --dry-run \
  ) > "$DRYLOG" 2>&1
  set -e
  grep -E '^  (en|ja)/|^      \[|^DRY-RUN:|Fix-tables PR:' "$DRYLOG" | sed 's/^/  /' || true
  dry_pr_url="$(sed -n 's|^  Fix-tables PR: *||p' "$DRYLOG" | tail -n1)"
  # 대상 리포에 브랜치를 만들지 않았는지는 **실제 실행 전에** 세어야 한다
  # (4단계가 fix-tables/… 를 만들고 나면 구별할 수 없다).
  dry_branches_after="$(git ls-remote --heads origin 'refs/heads/fix-tables/*' 2>/dev/null | wc -l)"
  dry_target_branches=$(( dry_branches_after - dry_branches_before ))
else
  echo
  echo "[3/7] dry-run 리허설 — SKIP (--translate api)"
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

# (1) dry-run — 리허설: 수리는 실제로 돌지만 대상 리포에는 쓰지 않는다
if (( dry_skipped )); then
  skip "(1) dry-run 리허설 — api 모드"
else
  d_ok=1
  for id in ${REBUILD_IDS//,/ }; do
    (( $(grep -c "^      \[section\] #$id " "$DRYLOG") >= 2 )) \
      || { d_ok=0; echo "        dry-run 이 #$id 를 en/ja 양쪽에서 '재구성' 으로 잡지 않음"; }
  done
  for id in ${REPAIR_IDS//,/ }; do
    (( $(grep -c "^      \[표\] #$id " "$DRYLOG") >= 2 )) \
      || { d_ok=0; echo "        dry-run 이 #$id 를 en/ja 양쪽에서 '표 수리' 로 잡지 않음"; }
  done
  grep -q "^DRY-RUN: .*Nothing is written to $REPO" "$DRYLOG" \
    || { d_ok=0; echo "        dry-run 배너(대상 리포에 쓰지 않음)가 없음"; }
  if [[ -z "$dry_pr_url" ]]; then
    d_ok=0; echo "        dry-run 이 sandbox PR 을 열지 않았다 (리허설은 리뷰 가능한 diff 가 목적)"
  elif [[ "$dry_pr_url" == *"/$REPO/"* ]]; then
    d_ok=0; echo "        dry-run PR 이 대상 리포에 열렸다: $dry_pr_url"
  fi
  (( dry_target_branches == 0 )) \
    || { d_ok=0; echo "        dry-run 이 대상 리포에 fix-tables/* 브랜치를 ${dry_target_branches}개 늘렸다"; }
  (( d_ok )) && ok "(1) dry-run 이 section ${n_fixed}개×2언어를 수리 단위까지 맞게 탐지 · 대상 리포 무기록 · sandbox PR ($dry_pr_url)" \
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
python3 - "$tmpdir" "$REBUILD_IDS" "$REPAIR_IDS" "$CHILD_IDS" <<'PY' || fails=$((fails + 1))
import io, re, sys

tmp, rebuild_csv, repair_csv, child_csv = sys.argv[1:5]
rebuild_ids = [s for s in rebuild_csv.split(",") if s]   # section 본문 재구성
repair_ids = [s for s in repair_csv.split(",") if s]     # 표만 수리
child_ids = [s for s in child_csv.split(",") if s]       # 그중 하위 heading 표
fixed_ids = rebuild_ids + repair_ids

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

# (3) 고친 section — 표 모양 · 식별자 · 한글 · 비어있지 않음
#     수리 단위(표/section)와 무관하게 결과는 ko 와 같은 모양이어야 한다.
for lang, (base, new) in langs.items():
    for aid in fixed_ids:
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
    drift = [aid for aid in fixed_ids
             if head_lines(base.get(aid, "")) != head_lines(new.get(aid, ""))]
    if drift:
        bad(f"(4) {lang} 의 고친 section heading/anchor 가 변경됨: {', '.join(drift)}",
            *[f"{a}: {head_lines(base.get(a,''))!r} → {head_lines(new.get(a,''))!r}"
              for a in drift[:2]])
    else:
        ok(f"(4) {lang} 고친 section {len(fixed_ids)}개의 <a id>/heading 바이트 보존")

def table_spans(raw):
    """[(start, end)] — 표(헤더+구분줄+행)가 차지하는 줄 구간, end 는 배타."""
    lines = raw.splitlines()
    out, i = [], 0
    while i < len(lines) - 1:
        if lines[i].strip().startswith("|") and TBL_SEP.match(lines[i + 1]):
            j = i + 2
            while j < len(lines) and lines[j].strip().startswith("|"):
                j += 1
            out.append((i, j))
            i = j
        else:
            i += 1
    return out


def outside_tables(raw):
    """표 구간을 자리표시자로 접은 나머지 — '표 밖' 이 그대로인지 재는 축."""
    lines, keep, prev = raw.splitlines(), [], 0
    for st, en in table_spans(raw):
        keep.extend(lines[prev:st]); keep.append("<<TABLE>>"); prev = en
    keep.extend(lines[prev:])
    return keep


def first_cells(raw, span):
    out = []
    for ln in raw.splitlines()[span[0] + 2:span[1]]:
        cells = [c.strip().replace("**", "").replace("`", "")
                 for c in ln.strip().strip("|").split("|")]
        if cells:
            out.append(cells[0])
    return out


# (5a) 고친 section 밖은 바이트 동일 (대조군 + 인트로)
# (5b) 표 수리 section 은 바뀐 곳이 표 안에 머문다
#      — 수리 단위가 둘이 된 뒤로 (5a) 만으로는 범위를 재지 못한다. 표 수리라고
#        하고서 section 을 통째로 다시 쓰면 (5a) 는 통과해 버린다.
for lang, (base, new) in langs.items():
    diffs = [k for k in set(base) | set(new)
             if k not in fixed_ids and base.get(k) != new.get(k)]
    if diffs:
        bad(f"(5a) {lang} 의 손대지 않아야 할 section 이 변경됨: "
            f"{', '.join(sorted(map(str, diffs))[:5])}",
            "정비는 고친 section 밖을 한 바이트도 건드리면 안 된다 — "
            "대조군(정상 표 · 마지막 section · 인트로)이 여기 든다")
    else:
        ok(f"(5a) {lang} 는 고친 section 밖이 base 와 바이트 동일 ({len(base)}개 구간)")

    for aid in repair_ids:
        b, n = base.get(aid, ""), new.get(aid, "")
        ob, on = outside_tables(b), outside_tables(n)
        bt, nt2 = table_spans(b), table_spans(n)
        tail = " (하위 heading 의 표)" if aid in child_ids else ""
        if ob != on:
            i = next((i for i, (x, y) in enumerate(zip(ob, on)) if x != y), min(len(ob), len(on)))
            bad(f"(5b) {lang} #{aid} 는 표 수리인데 표 **밖**이 바뀌었다{tail}",
                f"base: {(ob[i] if i < len(ob) else '<없음>')!r}",
                f"new : {(on[i] if i < len(on) else '<없음>')!r}")
            continue
        if len(bt) != len(nt2):
            bad(f"(5b) {lang} #{aid} 표 개수가 base {len(bt)} → new {len(nt2)} 로 바뀌었다")
            continue
        shrunk = [i for i, ((s0, e0), (s1, e1)) in enumerate(zip(bt, nt2), 1)
                  if (e1 - s1) < (e0 - s0)]
        if shrunk:
            bad(f"(5b) {lang} #{aid} 표 {shrunk} 의 줄 수가 줄었다 — 행이 사라졌다")
            continue
        # 식별자가 없는 표는 짝을 확정할 근거가 없다 — 그대로여야 한다.
        # 기준은 **ko** 다. 대상의 base 로 재면 안 된다 — #fix-tables-shifted 는
        # 첫 열이 형식명으로 덮여 base 에 식별자가 없는 것이 결함 그 자체라,
        # base 로 재면 수리해야 할 표를 '손대면 안 되는 표' 로 오판한다.
        kt_spans = table_spans(ko.get(aid, ""))
        bl, nl = b.splitlines(), n.splitlines()
        moved = [i + 1 for i, span in enumerate(bt)
                 if i < len(kt_spans)
                 and not any(is_key(c) for c in first_cells(ko.get(aid, ""), kt_spans[i]))
                 and bl[span[0]:span[1]] != nl[nt2[i][0]:nt2[i][1]]]
        if moved:
            bad(f"(5b) {lang} #{aid} 식별자 없는 표 {moved} 가 변경됨 — "
                "짝을 확정할 근거가 없는 표다")
        else:
            ok(f"(5b) {lang} #{aid} 수리가 표 안에 머물렀다{tail} "
               f"(표 {len(bt)}개 · 표 밖 {len(ob)}줄 바이트 동일)")

# (6) PR 본문
pr_body = read(f"{tmp}/pr_body.md")
missing = [i for i in fixed_ids if f"`#{i}`" not in pr_body]
if missing:
    bad(f"(6a) PR 본문에 고친 id 가 없음: {', '.join(missing)}")
else:
    ok(f"(6a) PR 본문이 고친 section id {len(fixed_ids)}개를 나열")
if "표 개수 ko" in pr_body and "식별자" in pr_body:
    ok("(6a) PR 본문이 사유(표 개수 / 식별자 누락)를 함께 적음")
else:
    bad("(6a) PR 본문에 재구성 사유가 없음")
if "행 삽입" in pr_body and all(f"`#{c}`" in pr_body for c in child_ids):
    ok("(6b) PR 본문이 하위 heading 표의 '행 삽입' 을 공개 "
       f"({', '.join('#' + c for c in child_ids)})")
else:
    bad("(6b) PR 본문에 하위 heading 표의 '행 삽입' 공개가 없음 — 조용히 고치면 아무도 모른다",
        "앵커가 없는 하위 heading 아래 표라도 식별자 키로 짝이 확정되면 그 행만 "
        "삽입한다 (cloud-translate #851). 그 사실이 본문에 남아야 리뷰어가 "
        "section 밖으로 번진 diff 를 설명할 수 있다")

links = {}
for anchor in fixed_ids:
    # 링크는 2026-08 (#843) 부터 단일 언어 `/view` before/after 가 아니라
    # ko 를 왼쪽에 둔 `/compare` 두 장이다 — 리뷰 질문이 "이전과 무엇이 다른가"
    # 가 아니라 "ko 를 정본으로 볼 때 맞는가" 이기 때문.
    pat = (r"\[ko↔변경 후\]\((?P<a>[^)]*?/compare\?[^)]*?#" + re.escape(anchor) + r")\)"
           r"[^\n]*?\[ko↔변경 전\]\((?P<b>[^)]*?/compare\?[^)]*?#" + re.escape(anchor) + r")\)")
    m = re.search(pat, pr_body)
    links[anchor] = m
    if not m:
        bad(f"(6c) #{anchor} 의 ko↔변경 전/후 프리뷰 링크가 PR 본문에 없음")
if all(links.values()):
    sha40 = re.compile(r"tx_ref=[0-9a-f]{40}")
    bad_ref = [a for a, m in links.items()
               if not (sha40.search(m.group("b")) and sha40.search(m.group("a")))]
    if bad_ref:
        bad("(6c) 프리뷰 링크가 커밋 SHA 가 아님: " + ", ".join(bad_ref))
    elif any(m.group("b") == m.group("a") for m in links.values()):
        bad("(6c) 변경 전/후 링크가 동일 — 두 상태를 가리키지 못한다")
    else:
        ok(f"(6c) 고친 section {len(links)}개에 ko↔변경 전/후 프리뷰 링크 (앵커 + 커밋 SHA)")

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
