#!/usr/bin/env bash
#
# 링크 정정(fix-links) e2e — dashboard/links/fix.py 검증.
#
# 검증 대상: `/link-check` 가 NotOK 로 매긴 링크 중 **결과가 실제로 resolve 되는
# 것만** 고쳐 PR 을 열고, 확인할 수 없는 것은 고치지 않고 PR 본문에 보고한다.
# 그리고 **링크 target 밖은 한 바이트도 바뀌지 않는다**.
#
# ── 왜 별도 e2e 인가 ──────────────────────────────────────────────────────
# 이 도구는 TOAST-DOCS 상품 repo 에 **직접 쓰는 유일한 링크 도구**이고, 번역
# 파이프라인과 코드/진입점을 전혀 공유하지 않는다 (viewer 쪽 FastAPI 코드 +
# 자체 Jenkinsfile). 깨지는 방식도 번역과 다르게 전부 결정적이라 LLM 판정이
# 필요 없다:
#   - 규칙이 멀쩡한 링크를 건드림 (대조군이 바뀜)
#   - 확인되지 않은 재작성을 커밋함 (살아있는 링크를 404 로 바꾸는 최악)
#   - 고칠 수 없는 링크를 조용히 건너뜀 → 리뷰어는 "승인된 링크" 로 읽는다
#   - 코드 펜스 안의 링크를 링크로 오인해 재작성
#   - 링크 밖 바이트가 재작성돼 diff 가 문서 전체로 번짐
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# `{ko,en,ja}/fix-links.md` (alpha 에 상주). 결정적 규칙 하나씩을 겨냥한 링크
# **6개**와, 고칠 수 없어 보고만 해야 하는 링크 2개, 그리고 절대 바뀌면 안 되는
# 대조군(정상 링크 4개 + 코드 펜스 안 링크 2개)이 들어 있다. 언어별로 같은
# 구조라 `lang-parity` 검증도 통과해야 한다.
#
#   self-link    ./fix-links/#fix-links-controls          → #fix-links-controls
#   relativize   https://github.com/…/blob/alpha/<L>/overview.md#pricing
#                                                          → ./overview.md#pricing
#   relativize   /<L>/overview.md#pricing                  → ./overview.md#pricing
#   lang-dir     ../<다른 언어>/overview.md#pricing        → ./overview.md#pricing
#   nested-frag  ./overview.md#overview/#pricing           → ./overview.md#pricing
#   heading-frag ./overview.md#keypair-legacy-slug         → ./overview.md#key-pair
#
# ── 실행 옵션은 '⭐ 권장 옵션' ────────────────────────────────────────────
# `/link-check` 페이지의 권장 옵션 버튼과 **같은 조합**으로 돌린다:
#   문서 전체(scope=all) · DRY-RUN 해제(실제 PR) · LLM 2차 처리 engine=env
#   (api 냐 claude-code 냐는 잡에 마운트된 .env 가 고른다) · 검증 두 축 모두
#   (lang-parity + cross-context).
# 픽스처만 스코프하면 이 잡을 "제대로" 돌리는 설정을 검증하지 못한다 — 특히
# lang-parity 는 문서 전체를 봐야 의미가 있고, DRY-RUN 해제는 이 도구의 유일한
# 위험 지점이라 e2e 가 반드시 지나가야 하는 경로다. 판정 대상은 픽스처 세 파일
# 뿐이므로 다른 문서가 함께 고쳐져도 무방하다 (세션 브랜치는 폐기된다).
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성 (픽스처는 이미 alpha 에 있다 — 시드 없음)
#   2) dry-run — 규칙별 정정 수 · PR 미생성                   [local 전용]
#   3) 실제 정정 (권장 옵션) → Fix PR
#   4) 판정 (아래 8개 규칙, 전부 바이트 비교)
#   5) 결과 (FIX_LINKS: OK|FAIL)
#   6) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) dry-run 이 언어당 6건 정정 · 2건 manual · PR 미생성  [local 전용, api=SKIP]
#   (2) Fix PR 생성 (head=fix-links/… · content-agent + fix-link 라벨)
#   (3) 픽스처 세 파일이 **기대 결과와 바이트 동일** — 정정 6건이 정확히
#       적용되고, 대조군·펜스·보고 대상·링크 밖 바이트는 그대로
#   (4) 규칙별 진단 — 6개 규칙이 각각 적용되었는지 개별 확인 (3 이 실패했을 때
#       무엇이 어긋났는지 바로 보이도록)
#   (5) PR 본문의 매핑 표가 규칙 이름과 이전→이후를 싣는다
#   (6) 고칠 수 없는 링크 2건이 '사람이 직접 확인' 표에 사유와 함께 오른다
#   (7) LLM 2차 처리 상태가 PR 본문에 항상 명시된다 (off 여도)
#   (8) 검증 댓글(`<!-- fix-links:verify -->`)이 달리고, 요청한 검증 축이 각자의
#       섹션으로 보고되며, 담당자 인계 블록이 함께 실림
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-fix-links.sh                    # 로컬 links/cli.py
#   bash scripts/e2e-fix-links.sh --translate api    # dashboard /api/fix-links → Jenkins
#   bash scripts/e2e-fix-links.sh --keep             # 브랜치/PR 보존 (디버깅)
#   bash scripts/e2e-fix-links.sh --engine none      # 권장 옵션 대신 결정적 규칙만
#   bash scripts/e2e-fix-links.sh --scope fixture    # 문서 전체 대신 픽스처만
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-fix-links.sh
#
# 의존성: git, gh (로그인), python3.
#   --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN (load_env.sh) 필요.
#   local 모드는 CLOUD_TRANSLATE_DIR 의 venv 에 viewer 의존성이 설치돼 있어야 한다
#   (pip install -r dashboard/viewer/requirements.txt).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-fixlinks/$TS"
DOC="fix-links.md"
LANGS="ko,en,ja"
KEEP=0
TRANSLATE_MODE="local"     # local | api
# ⭐ 권장 옵션의 기본값. --engine / --scope / --verify 로만 낮춘다.
ENGINE="env"               # none | api | claude-code | env
VERIFY="lang-parity,cross-context"
SCOPE="all"                # all | fixture
JOB_TIMEOUT="${JOB_TIMEOUT:-2400}"

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
# fix-links CLI 의 모듈 경로. 링크 도메인이 `dashboard/viewer/links_cli.py` 에서
# `dashboard/links/cli.py` 로 옮겨졌는데(cloud-translate 리팩터), 이 하네스는
# 임의 브랜치의 체크아웃을 상대로 돈다 — 머지 전 워크트리도, 아직 옛 레이아웃인
# main 도. 그래서 이름을 박지 않고 그 체크아웃에서 찾는다.
if [[ -f "$CLOUD_TRANSLATE_DIR/dashboard/links/cli.py" ]]; then
  LINKS_CLI_MODULE="links.cli"
else
  LINKS_CLI_MODULE="viewer.links_cli"
fi
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --doc)  DOC="$2"; shift 2 ;;
    --langs) LANGS="$2"; shift 2 ;;
    --engine) ENGINE="$2"; shift 2 ;;
    --verify) VERIFY="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --base-source) BASE_SOURCE="$2"; shift 2 ;;
    --translate) TRANSLATE_MODE="$2"; shift 2 ;;
    -h|--help) sed -n '1,82p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$TRANSLATE_MODE" in local|api) ;; *) echo "error: --translate 는 local|api" >&2; exit 1 ;; esac
case "$ENGINE" in none|api|claude-code|env) ;; *) echo "error: --engine 은 none|api|claude-code|env" >&2; exit 1 ;; esac
case "$SCOPE" in all|fixture) ;; *) echo "error: --scope 는 all|fixture" >&2; exit 1 ;; esac
# cross-context 는 판정에 모델이 필요하다 — 대시보드 라우트도 같은 이유로 거부한다.
if [[ ",$VERIFY," == *",cross-context,"* && "$ENGINE" == "none" ]]; then
  echo "error: --verify cross-context 는 --engine 이 none 이 아니어야 합니다." >&2
  exit 1
fi
if [[ "$TRANSLATE_MODE" == "api" && ( -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ) ]]; then
  echo "error: --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다 (load_env.sh)." >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"; LOG="$tmpdir/fix.log"; DRYLOG="$tmpdir/dryrun.log"

# 픽스처 경로 CSV — --scope fixture 일 때 PATHS 로 넘어간다.
fixture_paths=""
for lang in ${LANGS//,/ }; do
  fixture_paths+="${fixture_paths:+,}$lang/$DOC"
done

fix_pr_url=""
cleanup() {
  local rc=$?
  if (( KEEP )); then
    echo; echo "--keep: 보존 — 세션 $SESSION_BRANCH / PR ${fix_pr_url:-<none>}"
    echo "  정리: gh pr close <n> --repo $REPO --delete-branch; git push origin :$SESSION_BRANCH"
    return $rc
  fi
  echo; echo "[cleanup] Fix PR · 브랜치 정리"
  [[ -n "$fix_pr_url" ]] && gh pr close "$fix_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/fix-links/*" 2>/dev/null | sed 's|.*refs/heads/||')
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC (langs=$LANGS)"
echo "mode    : --translate $TRANSLATE_MODE"
echo "옵션    : scope=$SCOPE engine=$ENGINE verify=$VERIFY dry-run=off  (⭐ 권장 옵션)"
echo

# ── 1) 세션 브랜치 ────────────────────────────────────────────────────────
# 픽스처는 alpha 에 상주하므로 시드가 없다 — 브랜치만 판다.
echo "[1/6] 세션 브랜치 생성 (픽스처는 alpha 상주 — 시드 없음)"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"
for lang in ${LANGS//,/ }; do
  [[ -f "$lang/$DOC" ]] || { echo "error: 픽스처 없음: $lang/$DOC (alpha 에 있어야 합니다)" >&2; exit 2; }
done
git push -q -f origin "$SESSION_BRANCH"
base_sha="$(git rev-parse HEAD)"
echo "  세션 base: $base_sha"

# ── 2) dry-run ───────────────────────────────────────────────────────────
dry_skipped=0
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  echo
  echo "[2/6] dry-run (PR 생성 없음 · 결정적 규칙만)"
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && PYTHONPATH=".:dashboard" \
    "$CLOUD_TRANSLATE_PY" -m "$LINKS_CLI_MODULE" fix-links \
      --repo "$REPO" --ref "$SESSION_BRANCH" --langs "$LANGS" \
      --paths "$fixture_paths" --dry-run --out "$tmpdir/dryout" \
  ) > "$DRYLOG" 2>&1
  set -e
  grep -E '^(scanned|notok|repaired|left|  MANUAL|  [a-z]{2}/)' "$DRYLOG" | sed 's/^/  /' || true
else
  echo
  echo "[2/6] dry-run — SKIP (--translate api)"
  dry_skipped=1
fi

# ── 3) 실제 정정 ─────────────────────────────────────────────────────────
echo
echo "[3/6] 링크 정정 실행 (⭐ 권장 옵션)"
paths_arg=""
[[ "$SCOPE" == "fixture" ]] && paths_arg="$fixture_paths"
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && PYTHONPATH=".:dashboard" \
    "$CLOUD_TRANSLATE_PY" -m "$LINKS_CLI_MODULE" fix-links \
      --repo "$REPO" --ref "$SESSION_BRANCH" --langs "$LANGS" \
      --paths "$paths_arg" --engine "$ENGINE" --verify "$VERIFY" \
      --out "$tmpdir/fixout" \
  ) 2>&1 | tee "$LOG"
  fix_rc=${PIPESTATUS[0]}
  set -e
  fix_pr_url="$(grep -oE 'PR opened: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
  [[ -n "$fix_pr_url" ]] || fix_pr_url="$(grep -oE 'https://github\.com/[^ ]+/pull/[0-9]+' "$LOG" | tail -1)"
else
  # dashboard 경로 — /link-check 페이지의 '링크 정정 PR' 버튼과 동일한 API.
  # dry_run 은 이 라우트에서 **기본 true** 라 반드시 명시적으로 꺼야 한다
  # (그것이 권장 옵션이 하는 일이고, 이 도구의 유일한 위험 지점이다).
  resp="$(curl -sS -X POST \
    -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"target\": \"https://github.com/$REPO\", \"ref\": \"$SESSION_BRANCH\",
         \"langs\": \"$LANGS\", \"paths\": \"$paths_arg\",
         \"engine\": \"$ENGINE\", \"verify\": \"$VERIFY\", \"dry_run\": false}" \
    "$DASHBOARD_BASE_URL/api/fix-links")"
  echo "$resp" | python3 -m json.tool | sed 's/^/  /'
  job_id="$(printf '%s' "$resp" | python3 -c 'import json,sys; print((json.load(sys.stdin) or {}).get("job_id") or "")')"
  [[ -n "$job_id" ]] || { echo "error: /api/fix-links 응답에 job_id 없음" >&2; exit 2; }
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
    --json url,headRefName --jq '[.[] | select(.headRefName | startswith("fix-links/")) | .url] | last // ""')"
fi

# ── 4) 판정 ──────────────────────────────────────────────────────────────
echo
echo "[4/6] 판정"
fails=0
ok()   { echo "  PASS  $1"; }
bad()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
skip() { echo "  SKIP  $1"; }

nlang="$(awk -F, '{print NF}' <<<"$LANGS")"
# (1) dry-run — 언어당 정정 6건 · manual 2건.
if (( dry_skipped )); then
  skip "(1) dry-run — api 모드"
else
  d_ok=1
  want_rep=$(( nlang * 6 )); want_manual=$(( nlang * 2 ))
  grep -qE "^repaired  : $want_rep in $nlang file\(s\)" "$DRYLOG" \
    || { d_ok=0; echo "        dry-run 정정 건수가 $want_rep 이 아님"; }
  grep -qE "^left      : $want_manual for manual review" "$DRYLOG" \
    || { d_ok=0; echo "        dry-run manual 건수가 $want_manual 이 아님"; }
  if grep -q "PR opened:" "$DRYLOG"; then d_ok=0; echo "        dry-run 이 PR 을 만들었다"; fi
  (( d_ok )) && ok "(1) dry-run 이 정정 $want_rep 건 · manual $want_manual 건 · PR 미생성" \
              || bad "(1) dry-run 결과가 기대와 다름 (로그: $DRYLOG)"
fi

# (2) Fix PR
if (( fix_rc == 0 )) && [[ -n "$fix_pr_url" ]]; then
  ok "(2a) Fix PR 생성 — $fix_pr_url"
  e2e_label_pr "$REPO" "$fix_pr_url"
else
  bad "(2a) Fix PR 미생성 (exit=$fix_rc) — 이후 검사 불가 (로그: $LOG)"
  echo; echo "FIX_LINKS: FAIL"; KEEP=1; exit 1
fi

pr_labels="$(gh pr view "$fix_pr_url" --repo "$REPO" --json labels --jq '[.labels[].name] | join(",")')"
if [[ ",$pr_labels," == *",content-agent,"* && ",$pr_labels," == *",fix-link,"* ]]; then
  ok "(2b) PR 라벨 content-agent + fix-link ($pr_labels)"
else
  bad "(2b) PR 라벨 누락 — 어느 도구가 연 PR 인지 목록에서 구분되지 않는다 (labels=$pr_labels)"
fi

fix_branch="$(gh pr view "$fix_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$fix_branch"
mkdir -p "$tmpdir/base" "$tmpdir/new"
for lang in ${LANGS//,/ }; do
  git show "$base_sha:$lang/$DOC"          > "$tmpdir/base/$lang.md"
  git show "origin/$fix_branch:$lang/$DOC" > "$tmpdir/new/$lang.md" 2>/dev/null \
    || cp "$tmpdir/base/$lang.md" "$tmpdir/new/$lang.md"
done
gh pr view "$fix_pr_url" --repo "$REPO" --json body --jq .body > "$tmpdir/pr_body.md"
gh pr view "$fix_pr_url" --repo "$REPO" --json comments \
  --jq '[.comments[].body] | join("\n\n---\n\n")' > "$tmpdir/pr_comments.md" 2>/dev/null || : > "$tmpdir/pr_comments.md"

python3 - "$tmpdir" "$LANGS" "$VERIFY" <<'PY' || fails=$((fails + 1))
import io, re, sys

tmp, langs_csv, verify_csv = sys.argv[1:4]
langs = [s for s in langs_csv.split(",") if s]
rc = 0
FENCE = re.compile(r"^\s*(```+|~~~+)")


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


def ok(msg):
    print(f"  PASS  {msg}")


def bad(msg, *extra):
    global rc
    print(f"  FAIL  {msg}")
    for e in extra:
        print(f"        {e}")
    rc = 1


def expected_repairs(lang):
    """(규칙, 이전 target, 이후 target) — 픽스처가 심은 6건."""
    other = "en" if lang == "ko" else "ko"
    return [
        ("self-link",
         "./fix-links/#fix-links-controls", "#fix-links-controls"),
        ("relativize(abs-github)",
         f"https://github.com/TOAST-DOCS/Agent-Test/blob/alpha/{lang}/overview.md#pricing",
         "./overview.md#pricing"),
        ("relativize(repo-rooted)",
         f"/{lang}/overview.md#pricing", "./overview.md#pricing"),
        ("lang-dir",
         f"../{other}/overview.md#pricing", "./overview.md#pricing"),
        ("nested-frag",
         "./overview.md#overview/#pricing", "./overview.md#pricing"),
        ("heading-frag",
         "./overview.md#keypair-legacy-slug", "./overview.md#key-pair"),
    ]


def apply_expected(base, lang):
    """기대 결과를 base 에서 만들어 낸다 — **펜스 밖 첫 등장만** 치환.

    펜스 안에도 같은 target 이 일부러 들어 있다 (대조군). 전역 치환을 쓰면
    그 대조군까지 바꿔 버려 "펜스를 건드리지 않았다" 를 검증하지 못한다.
    """
    out, in_fence, done = [], False, set()
    for ln in base.splitlines(keepends=True):
        if FENCE.match(ln):
            in_fence = not in_fence
            out.append(ln)
            continue
        if not in_fence:
            for rule, old, new in expected_repairs(lang):
                token = f"]({old})"
                if rule not in done and token in ln:
                    ln = ln.replace(token, f"]({new})", 1)
                    done.add(rule)
        out.append(ln)
    return "".join(out), done


# (3) 기대 결과와 바이트 동일 — 정정·대조군·펜스·링크 밖 바이트를 한 번에.
per_lang_missing = {}
for lang in langs:
    base, new = read(f"{tmp}/base/{lang}.md"), read(f"{tmp}/new/{lang}.md")
    want, applied = apply_expected(base, lang)
    per_lang_missing[lang] = applied
    if new == want:
        ok(f"(3) {lang}/fix-links.md 가 기대 결과와 바이트 동일 (정정 6건 · 그 외 보존)")
        continue
    wl, nl = want.splitlines(), new.splitlines()
    diffs = [(i + 1, w, n) for i, (w, n) in enumerate(zip(wl, nl)) if w != n]
    bad(f"(3) {lang}/fix-links.md 가 기대 결과와 다름 "
        f"(기대 {len(wl)}줄 / 실제 {len(nl)}줄, 불일치 {len(diffs)}줄)",
        *[f"L{i}\n          기대: {w!r}\n          실제: {n!r}" for i, w, n in diffs[:4]])

# (4) 규칙별 진단 — (3) 이 실패했을 때 어느 규칙이 어긋났는지 바로 보이도록.
for lang in langs:
    new = read(f"{tmp}/new/{lang}.md")
    outside = []
    in_fence = False
    for ln in new.splitlines():
        if FENCE.match(ln):
            in_fence = not in_fence
            continue
        if not in_fence:
            outside.append(ln)
    body = "\n".join(outside)
    missed = [rule for rule, old, _ in expected_repairs(lang) if f"]({old})" in body]
    if missed:
        bad(f"(4) {lang} 에서 적용되지 않은 규칙: {', '.join(missed)}",
            "정정되지 않은 채 남았다 = /link-check 는 계속 NotOK 로 보고한다")
    else:
        ok(f"(4) {lang} 6개 규칙이 모두 적용됨")

pr_body = read(f"{tmp}/pr_body.md")

# (5) 매핑 표 — 규칙 이름과 이전→이후
missing_rules = [r for r in ("self-link", "relativize", "lang-dir",
                             "nested-frag", "heading-frag")
                 if f"`{r}`" not in pr_body]
if missing_rules:
    bad(f"(5) PR 본문 매핑 표에 규칙이 없음: {', '.join(missing_rules)}",
        "규칙 이름이 없으면 리뷰어가 '왜 이 줄이 바뀌었는지' 를 diff 로 되짚어야 한다")
else:
    ok("(5) PR 본문 매핑 표가 규칙 이름을 싣는다")

# (6) 고칠 수 없는 링크는 고치지 말고 보고 — 파일에 그대로 남고 PR 본문에 사유.
kept_all, reported_all = True, True
for lang in langs:
    new = read(f"{tmp}/new/{lang}.md")
    for target in ("./no-such-doc-e2e.md#nowhere",
                   "./overview.md#anchor-that-does-not-exist-e2e"):
        if f"]({target})" not in new:
            kept_all = False
            bad(f"(6) {lang} 에서 확인 불가 링크가 사라짐/바뀜: {target}",
                "resolve 되는지 확인할 수 없는 재작성은 살아있는 링크를 404 로 만든다")
for target in ("no-such-doc-e2e", "anchor-that-does-not-exist-e2e"):
    if target not in pr_body:
        reported_all = False
        bad(f"(6) PR 본문에 '{target}' 보고가 없음",
            "조용히 건너뛴 링크는 리뷰어에게 '승인된 링크' 로 읽힌다")
if kept_all and reported_all:
    ok("(6) 확인 불가 링크 2건 × 언어를 고치지 않고 PR 본문에 보고")

# (7) LLM 2차 처리 상태는 항상 명시 — 'off' 도 사실이다.
if "LLM 2차 처리" in pr_body:
    ok("(7) PR 본문이 LLM 2차 처리 상태를 명시")
else:
    bad("(7) PR 본문에 LLM 2차 처리 상태가 없음",
        "'물어봤는데 못 골랐다' 와 '아예 안 돌았다' 는 리뷰어에게 다른 사실이다")

# (8) 검증 댓글 — 요청한 축이 모두 보고되어야 한다.
# 댓글은 축 id 가 아니라 **사람이 읽는 한국어 섹션 제목**으로 축을 구분한다
# (`### 1. ko/en/ja 링크 일치` / `### 2. cross-repo 링크가 문맥에 맞는가`).
# 처음엔 여기서 "lang-parity"/"cross-context" 문자열을 찾다가 오탐으로 실패했다 —
# 판정은 도구의 출력 규격을 따라야지, 요청 파라미터의 철자를 따라선 안 된다.
AXIS_HEADING = {
    "lang-parity": "ko/en/ja 링크 일치",
    "cross-context": "cross-repo 링크가 문맥에 맞는가",
}
comments = read(f"{tmp}/pr_comments.md")
wanted_axes = [a for a in verify_csv.split(",") if a.strip()]
if "<!-- fix-links:verify -->" not in comments:
    bad("(8a) 검증 댓글(fix-links:verify)이 PR 에 없음")
else:
    missing_axes = [a for a in wanted_axes
                    if AXIS_HEADING.get(a, a) not in comments]
    if missing_axes:
        bad(f"(8a) 검증 댓글에 빠진 축: {', '.join(missing_axes)}",
            *[f"기대한 섹션 제목: {AXIS_HEADING.get(a, a)!r}" for a in missing_axes])
    else:
        ok(f"(8a) 검증 댓글이 요청한 축 {len(wanted_axes)}개를 모두 보고 "
           f"({', '.join(wanted_axes)})")
    # 이 두 검증은 아무것도 고치지 않으므로, 담당자가 다음 걸음을 뗄 수 있게
    # 하는 인계 블록이 산출물의 일부다 (없으면 발견 목록만 남는다).
    if "담당자용" in comments:
        ok("(8b) 검증 댓글이 담당자 인계 블록을 싣는다")
    else:
        bad("(8b) 검증 댓글에 담당자 인계 블록이 없음",
            "이 검증은 고치지 않는 검증이라, 목록만 남기면 다음 걸음이 없다")

raise SystemExit(rc)
PY

# ── 5) 결과 ──────────────────────────────────────────────────────────────
echo
echo "[5/6] 결과"
if (( fails == 0 )); then
  echo "FIX_LINKS: OK"
  echo "  링크 정정이 확인 가능한 6개 규칙만 적용하고 나머지는 보존/보고 (PR: $fix_pr_url)"
  echo
  echo "[6/6] cleanup"
  exit 0
fi
echo "FIX_LINKS: FAIL"
echo "  $fails 개 규칙 실패 — 로그: $LOG / dry-run: $DRYLOG"
echo "  PR 은 보존합니다: $fix_pr_url"
KEEP=1
exit 1
