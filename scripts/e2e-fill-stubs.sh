#!/usr/bin/env bash
#
# 빈 번역 채우기(fill-stubs) e2e — cloud-translate 의 translate_fill_stubs.py 검증.
#
# 검증 대상: pre-align 이 남긴 번역 stub(`<!-- TODO: translate* -->`) 을 ko 의
# 같은 `<a id>` 섹션으로 채우고, **그 섹션 밖은 한 바이트도 건드리지 않는다**.
#
# ── 왜 별도 e2e 인가 ──────────────────────────────────────────────────────
# translate_fill_stubs.py 는 translate_pr.py 와 진입점도 경로도 다르다 — PR 의
# ko diff 가 아니라 **브랜치의 en/ja 전수 스캔**에서 출발하고, diff 스플라이스·
# preserve-existing 을 전혀 타지 않으며, 섹션 짝짓기 근거가 anchor id 하나다.
# 그래서 round1/table-suite 가 아무리 통과해도 이 경로는 검증되지 않는다.
# 실제로 이 도구가 깨지는 방식은 번역 품질이 아니라 **구조**다:
#   - anchor id 매칭이 어긋나 엉뚱한 ko 섹션이 들어감
#   - 채우면서 heading·anchor 줄을 다시 써서 pre-align 이 맞춰 둔 id 가 흔들림
#   - heading stub 의 레벨이 ko 와 달라짐 (`###` 가 `##` 로 승격)
#   - 섹션 밖 EOL/공백이 재작성돼 diff 가 문서 전체로 번짐 (CRLF 파일 사고)
#   - id 없는 stub 을 억지로 채워 ko 와 대응되지 않는 문장이 들어감
# 전부 바이트 비교로 판정 가능하므로 이 e2e 는 LLM 판정을 쓰지 않는다.
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# `{ko,en,ja}/fill-stub-sample.md` (alpha 에 상주, `archive/fill-stub/` 에 원본).
# 언어당 채워야 할 stub 5개 + 부정 대조군 1개:
#
#   body stub    #fill-stub-body           평문 문단
#   body stub    #fill-stub-table          표 (열 수·행 수가 보존되어야 한다)
#   body stub    #fill-stub-code           코드 펜스 (내용이 바이트 동일해야 한다)
#   heading stub #fill-stub-heading        `##`  — heading 이 아직 한국어
#   heading stub #fill-stub-heading-child  `###` — 레벨이 승격되면 안 된다
#   (대조군)     `## 앵커가 없는 섹션`     `<a id>` 없음 → 반드시 건너뛰고 보고
#
# 그 앞뒤를 이미 번역된 섹션(#fill-stub-untouched / #fill-stub-tail)이 감싸므로,
# 채우기가 stub 바깥을 건드리면 바이트 비교로 바로 드러난다.
#
# 예전에는 이 e2e 가 `overview.md` 에 stub 을 **직접 심었다**. 픽스처를 alpha 에
# 두는 쪽으로 바꾼 이유는 두 가지다: (a) 심는 코드가 pre-align 의 stub 모양을
# 흉내내야 해서, 그 흉내가 틀리면 e2e 가 조용히 다른 것을 검증한다. (b) 표·코드
# 펜스·중첩 heading 처럼 **실제로 깨지는 모양**은 자동 선별 조건("펜스·표 없는
# 섹션")에 걸려 애초에 심을 수 없었다. 픽스처가 커밋되어 있으면 그 모양을
# 사람이 고정할 수 있고, 리뷰도 diff 로 된다.
#
# 채우기가 성공하면 stub 이 소진되므로, 세션 브랜치에서만 돌리고 브랜치를
# 폐기한다 — alpha 의 픽스처는 그대로 남는다.
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성 (픽스처는 이미 alpha 에 있다 — 시드 없음)
#   2) 픽스처 인벤토리 — 어떤 stub 이 몇 개인지 파일에서 직접 읽는다
#   3) dry-run 탐지 (모델 호출 0 · PR 생성 없음)        [--translate local 전용]
#   4) 실제 채우기 → Fill PR
#   5) 판정 (아래 규칙, 전부 바이트/구조 비교)
#   6) 결과 (FILL_STUBS: OK|FAIL)
#   7) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) dry-run 이 fillable stub 5개를 전부 탐지하고 id 없는 stub 은 skip 사유와
#       함께 보고 · 브랜치/PR 을 만들지 않음                 [local 전용, api=SKIP]
#   (2) 실제 실행이 Fill PR 을 생성 (`Fill PR:` / head=fill-stubs/…)
#   (3) body stub 이 채워짐 — 마커 제거 · 한글 잔류 0 · 본문 비어있지 않음
#   (3t) 표 stub 의 열 수·데이터 행 수가 ko 와 같음 (번역이 표를 접지 않았는지)
#   (3c) 코드 stub 의 펜스 내용이 ko 와 **바이트 동일** (코드는 번역 대상이 아니다)
#   (4) body stub 의 heading/anchor 줄이 **바이트 동일** (id 가 흔들리지 않는다)
#   (5) heading stub 이 채워짐 — 마커 제거 · heading 한글 잔류 0 ·
#       heading 레벨과 `<a id>` 가 ko 와 동일 (`###` 가 `##` 로 승격되지 않음)
#   (6) 채운 섹션 **밖**은 base 와 바이트 동일 (en/ja 각각)
#   (7) id 없는 stub 은 그대로 남음 (억지로 채우지 않음)
#   (8) PR 본문이 채운 id 를 나열하고, 건너뛴 stub 을 '건너뜀' 으로 보고 ·
#       채운 섹션마다 before/after Docs Preview 링크 (섹션 앵커 + 커밋 SHA)
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-fill-stubs.sh                      # 로컬 translate_fill_stubs.py
#   bash scripts/e2e-fill-stubs.sh --translate api      # dashboard /api/fill-empty → Jenkins
#   bash scripts/e2e-fill-stubs.sh --keep               # 브랜치/PR 보존 (디버깅)
#   bash scripts/e2e-fill-stubs.sh --doc fill-stub-sample.md
#   bash scripts/e2e-fill-stubs.sh --base-source e2e/my-branch   # alpha 대신 그 브랜치에서
#
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-fill-stubs.sh
#
# 의존성: git, gh (로그인), python3, jq 불필요.
#   --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN (load_env.sh) 필요.
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-fillstubs/$TS"
DOC="fill-stub-sample.md"  # alpha 상주 픽스처 (archive/fill-stub/ 에 원본)
KEEP=0
TRANSLATE_MODE="local"     # local | api
# 기본값 cli — 배포된 translate 잡의 .env 가 claude-code 이고, 대시보드
# /api/fill-empty 는 ENGINE 을 보내지 않아 그 .env 값이 이긴다. e2e 가 api 로
# 돌면 운영이 실제로 타는 엔진을 검증하지 않는다 (align/retranslate e2e 도 같은
# 이유로 claude-code 가 기본값이다). --engine 으로만 낮춘다.
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
    --base-source) BASE_SOURCE="$2"; SESSION_BRANCH="e2e-fillstubs/$TS"; shift 2 ;;
    --translate) TRANSLATE_MODE="$2"; shift 2 ;;
    --engine)
      # 별칭은 다른 e2e 와 같은 집합. 예전에는 값을 그대로
      # TRANSLATE_TRANSLATE_ENGINE 에 넣어서 `--engine cli` 가 조용히 깨졌다 —
      # create_translator 는 api|claude-code 만 알고 'cli' 는 ValueError 다.
      case "${2:-}" in
        api)         ENGINE="api" ;;
        cli)         ENGINE="claude-code" ;;
        claude-code) ENGINE="claude-code" ;;
        default)     ENGINE="" ;;
        *) echo "error: --engine 은 api|cli|default (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --model)
      # 다른 e2e 스크립트와 같은 별칭 집합 — default 는 .env 값을 그대로 쓴다.
      case "${2:-}" in
        haiku)   TRANSLATE_MODEL="claude-haiku-4-5" ;;
        sonnet)  TRANSLATE_MODEL="claude-sonnet-4-6" ;;
        opus)    TRANSLATE_MODEL="claude-opus-4-8" ;;
        default) TRANSLATE_MODEL="" ;;
        *) echo "error: --model 은 haiku|sonnet|opus|default (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -h|--help) sed -n '1,85p' "$0"; exit 0 ;;
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
tmpdir="$(mktemp -d)"; LOG="$tmpdir/fill.log"; DRYLOG="$tmpdir/dryrun.log"

fill_pr_url=""
cleanup() {
  local rc=$?
  if (( KEEP )); then
    echo; echo "--keep: 보존 — 세션 $SESSION_BRANCH / PR ${fill_pr_url:-<none>}"
    echo "  정리: gh pr close <n> --repo $REPO --delete-branch; git push origin :$SESSION_BRANCH"
    return $rc
  fi
  echo; echo "[cleanup] Fill PR · 브랜치 정리"
  [[ -n "$fill_pr_url" ]] && gh pr close "$fill_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/fill-stubs/*" 2>/dev/null | sed 's|.*refs/heads/||')
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
# 무엇을 채워야 하는지는 픽스처 파일이 정본이다 — 스크립트에 id 를 박아 두면
# 픽스처를 고쳤을 때 e2e 가 조용히 다른 것을 검사한다.
echo
echo "[2/7] 픽스처 인벤토리"
inv="$(python3 - "$DOC" <<'PY'
import io, re, sys

doc = sys.argv[1]
BODY_MARK = "<!-- TODO: translate body -->"
HEAD_MARK = "<!-- TODO: translate -->"
ANCHOR = re.compile(r'^<a id="([^"]+)"></a>\s*$')
HEADING = re.compile(r"^(#{2,6})\s+(.*)$")


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


def sections(text):
    """[(anchor_id|None, heading_text, raw)] — <a id> 또는 heading 에서 자른다."""
    lines = text.splitlines(keepends=True)
    out, cur_id, cur_h, buf, pending = [], None, "", [], None
    for ln in lines:
        s = ln.rstrip("\r\n")
        m = ANCHOR.match(s)
        if m:
            out.append((cur_id, cur_h, "".join(buf)))
            cur_id, cur_h, buf, pending = m.group(1), "", [ln], m.group(1)
            continue
        h = HEADING.match(s)
        if h:
            if pending is None:                # 앵커 없는 heading = 새 섹션
                out.append((cur_id, cur_h, "".join(buf)))
                cur_id, cur_h, buf = None, h.group(2).strip(), [ln]
                continue
            cur_h = h.group(2).strip()
            pending = None
        buf.append(ln)
    out.append((cur_id, cur_h, "".join(buf)))
    return [t for t in out if t[2]]


body_ids, head_ids, noid = [], [], []
for lang in ("en", "ja"):
    for aid, htext, raw in sections(read(f"{lang}/{doc}")):
        if BODY_MARK not in raw and HEAD_MARK not in raw:
            continue
        if aid is None:
            noid.append(re.sub(r"\s*\{\s*#.*?\}\s*$", "", htext))
        elif BODY_MARK in raw:
            body_ids.append(aid)
        else:
            head_ids.append(aid)

# 언어 간 동일해야 한다 — 다르면 픽스처가 깨진 것이므로 여기서 멈춘다.
half = len(body_ids) // 2
if body_ids[:half] != body_ids[half:] or not body_ids:
    raise SystemExit(f"error: en/ja 의 body stub 이 다르다: {body_ids}")
half_h = len(head_ids) // 2
if head_ids[:half_h] != head_ids[half_h:] or not head_ids:
    raise SystemExit(f"error: en/ja 의 heading stub 이 다르다: {head_ids}")

print("BODY_IDS=" + ",".join(body_ids[:half]))
print("HEAD_IDS=" + ",".join(head_ids[:half_h]))
print("NOID_HEADING=" + (noid[0] if noid else ""))
PY
)" || { echo "error: 픽스처 인벤토리 실패" >&2; exit 2; }
echo "$inv" | sed 's/^/  /'
BODY_IDS="$(sed -n 's/^BODY_IDS=//p' <<<"$inv")"
HEAD_IDS="$(sed -n 's/^HEAD_IDS=//p' <<<"$inv")"
NOID_HEADING="$(sed -n 's/^NOID_HEADING=//p' <<<"$inv")"
[[ -n "$BODY_IDS" && -n "$HEAD_IDS" && -n "$NOID_HEADING" ]] \
  || { echo "error: 픽스처에서 stub 을 찾지 못함" >&2; exit 2; }
n_fillable=$(( $(awk -F, '{print NF}' <<<"$BODY_IDS") + $(awk -F, '{print NF}' <<<"$HEAD_IDS") ))

# ── 3) dry-run 탐지 ──────────────────────────────────────────────────────
# 모델을 부르지 않고 "무엇이 비어 있는지" 만 세는 경로. 대시보드의 '미리보기'
# 체크박스와 같은 경로이고, 여기서 id 없는 stub 의 skip 사유도 확인한다.
# api 모드에서는 빌드 로그를 봐야 하므로 이 규칙은 SKIP.
dry_skipped=0
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  echo
  echo "[3/7] dry-run 탐지 (모델 호출 0)"
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    "$CLOUD_TRANSLATE_PY" translate/translate_fill_stubs.py "$REPO" "$SESSION_BRANCH" \
      --only "en/$DOC,ja/$DOC" --dry-run \
  ) > "$DRYLOG" 2>&1
  set -e
  grep -E '^  (en|ja)/|^      #|skip \(' "$DRYLOG" | sed 's/^/  /' || true
else
  echo
  echo "[3/7] dry-run 탐지 — SKIP (--translate api)"
  dry_skipped=1
fi

# ── 4) 실제 채우기 ───────────────────────────────────────────────────────
echo
echo "[4/7] 빈 번역 채우기 실행"
if [[ "$TRANSLATE_MODE" == "local" ]]; then
  # env 로 전달 — `${VAR:+NAME=v} cmd` 는 셸이 대입으로 인식하지 않는다 (대입
  # 판정이 확장보다 먼저라 그냥 명령어 워드가 된다). env 는 확장 결과를 받는다.
  echo "  engine=${ENGINE:-<.env 기본>} model=${TRANSLATE_MODEL:-<.env 기본>}"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    env ${ENGINE:+TRANSLATE_TRANSLATE_ENGINE="$ENGINE"} \
        ${TRANSLATE_MODEL:+TRANSLATE_ANTHROPIC_MODEL="$TRANSLATE_MODEL"} \
        ${TRANSLATE_MODEL:+TRANSLATE_CLAUDE_CODE_MODEL="$TRANSLATE_MODEL"} \
      "$CLOUD_TRANSLATE_PY" translate/translate_fill_stubs.py "$REPO" "$SESSION_BRANCH" \
        --only "en/$DOC,ja/$DOC" \
  ) 2>&1 | tee "$LOG"
  fill_rc=${PIPESTATUS[0]}
  set -e
  fill_pr_url="$(grep -oE 'Fill PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
else
  # dashboard 경로 — 대시보드 TODO 현황 탭의 '빈 번역 채우기' 와 동일한 API.
  # ONLY 로 픽스처만 스코프한다 — 세션 브랜치에는 다른 문서의 stub 도 있을 수
  # 있고(ja/component-guide.md), 그것까지 채우면 잡이 느려질 뿐 판정에는
  # 보탬이 없다.
  resp="$(curl -sS -X POST \
    -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"target\": \"https://github.com/$REPO\", \"branch\": \"$SESSION_BRANCH\",
         \"langs\": \"en,ja\", \"only\": \"en/$DOC,ja/$DOC\"}" \
    "$DASHBOARD_BASE_URL/api/fill-empty")"
  echo "$resp" | python3 -m json.tool | sed 's/^/  /'
  job_id="$(printf '%s' "$resp" | python3 -c 'import json,sys; print((json.load(sys.stdin) or {}).get("job_id") or "")')"
  [[ -n "$job_id" ]] || { echo "error: /api/fill-empty 응답에 job_id 없음" >&2; exit 2; }
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
  fill_rc=0; [[ "$status" == "success" ]] || fill_rc=1
  # PR 은 head 브랜치 prefix 로 찾는다 (translate_fill_stubs 의 명명 규칙).
  fill_pr_url="$(gh pr list --repo "$REPO" --base "$SESSION_BRANCH" --state all \
    --json url,headRefName --jq '[.[] | select(.headRefName | startswith("fill-stubs/")) | .url] | last // ""')"
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
  for id in ${BODY_IDS//,/ } ${HEAD_IDS//,/ }; do
    grep -q "#$id" "$DRYLOG" || { d_ok=0; echo "        dry-run 에 #$id 없음"; }
  done
  grep -q "skip (id 없음)" "$DRYLOG" || { d_ok=0; echo "        id 없는 stub 의 skip 보고 없음"; }
  grep -q "탐지만 수행" "$DRYLOG" || { d_ok=0; echo "        dry-run 종료 문구 없음"; }
  if grep -q "Fill PR:" "$DRYLOG"; then d_ok=0; echo "        dry-run 이 PR 을 만들었다"; fi
  (( d_ok )) && ok "(1) dry-run 이 stub ${n_fillable}개 탐지 · id 없는 stub skip · PR 미생성" \
              || bad "(1) dry-run 결과가 기대와 다름 (로그: $DRYLOG)"
fi

# (2) Fill PR
if (( fill_rc == 0 )) && [[ -n "$fill_pr_url" ]]; then
  ok "(2) Fill PR 생성 — $fill_pr_url"
  e2e_label_pr "$REPO" "$fill_pr_url"
else
  bad "(2) Fill PR 미생성 (exit=$fill_rc) — 이후 검사 불가 (로그: $LOG)"
  echo; echo "FILL_STUBS: FAIL"; KEEP=1; exit 1
fi

fill_branch="$(gh pr view "$fill_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$fill_branch"
for lang in en ja; do
  git show "origin/$fill_branch:$lang/$DOC" > "$tmpdir/$lang.filled.md" 2>/dev/null || \
    echo "(missing)" > "$tmpdir/$lang.filled.md"
  git show "$base_sha:$lang/$DOC" > "$tmpdir/$lang.base.md"
done
git show "$base_sha:ko/$DOC" > "$tmpdir/ko.md"
gh pr view "$fill_pr_url" --repo "$REPO" --json body --jq .body > "$tmpdir/pr_body.md"

# (3)~(8) 구조/바이트 검사 — LLM 판정 없음.
python3 - "$tmpdir" "$BODY_IDS" "$HEAD_IDS" "$NOID_HEADING" <<'PY' || fails=$((fails + 1))
import io, re, sys

tmp, body_csv, head_csv, noid_heading = sys.argv[1:5]
body_ids = [s for s in body_csv.split(",") if s]
head_ids = [s for s in head_csv.split(",") if s]
filled_ids = body_ids + head_ids

HANGUL = re.compile(r"[가-힣]")
ANCHOR = re.compile(r'^<a id="([^"]+)"></a>\s*$')
BODY_MARK = "<!-- TODO: translate body -->"
HEAD_MARK = "<!-- TODO: translate -->"
FENCE = re.compile(r"^\s*(```+|~~~+)")
rc = 0


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


HEADING = re.compile(r"^(#{2,6})\s+(.*)$")


def sections(text):
    """{key: raw} — `<a id>` 로도, 앵커 없는 heading 으로도 자른다.

    앵커에서만 자르면 **앵커 없는 섹션이 바로 앞 섹션에 흡수된다**. 이 픽스처의
    부정 대조군이 정확히 그 모양(`## 앵커가 없는 섹션`, 한국어 stub)이라,
    흡수되면 앞 섹션의 "한글 잔류 0" 검사가 대조군 때문에 실패한다 — 도구는
    멀쩡한데 e2e 가 빨개진다. 앵커 없는 섹션은 등장 순서로 키를 붙여 별도
    구간으로 둔다 (순서가 같으면 base ↔ new 비교도 성립한다).
    """
    lines, out, cur, buf, pending, n = text.splitlines(keepends=True), {}, "__pre__", [], None, 0
    for ln in lines:
        s = ln.rstrip("\r\n")
        m = ANCHOR.match(s)
        if m:
            out[cur] = out.get(cur, "") + "".join(buf)
            cur, buf, pending = m.group(1), [ln], m.group(1)
            continue
        if HEADING.match(s):
            if pending is None:                # 앵커 없는 heading = 새 구간
                out[cur] = out.get(cur, "") + "".join(buf)
                cur, buf = f"__noid_{n}__", [ln]
                n += 1
                continue
            pending = None
        buf.append(ln)
    out[cur] = out.get(cur, "") + "".join(buf)
    return out


def heading_line(raw):
    for ln in raw.splitlines()[1:]:
        if ln.lstrip().startswith("#"):
            return ln
    return None


def body_of(raw):
    h = heading_line(raw)
    return raw.split(h, 1)[1] if h else raw


def table_shape(raw):
    """(열 수, 데이터 행 수) — 표가 없으면 None."""
    rows = [ln.strip() for ln in raw.splitlines()
            if ln.strip().startswith("|") and ln.strip().endswith("|")]
    if len(rows) < 3:
        return None
    sep = next((i for i, r in enumerate(rows)
                if re.fullmatch(r"\|[\s:\-|]+\|", r)), None)
    if sep is None:
        return None
    ncol = rows[sep].count("|") - 1
    return ncol, len(rows) - sep - 1


def fence_body(raw):
    """펜스 안 줄들 — 코드는 번역 대상이 아니므로 ko 와 바이트 동일해야 한다."""
    out, inside = [], False
    for ln in raw.splitlines():
        if FENCE.match(ln):
            inside = not inside
            continue
        if inside:
            out.append(ln)
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
langs = {}
for lang in ("en", "ja"):
    langs[lang] = (sections(read(f"{tmp}/{lang}.base.md")),
                   sections(read(f"{tmp}/{lang}.filled.md")))

# (3) body stub 이 채워졌는가 (+ 표/코드 보존)
for lang, (base, new) in langs.items():
    for bid in body_ids:
        sec = new.get(bid, "")
        if BODY_MARK in sec:
            bad(f"(3) {lang} #{bid} 에 stub 마커가 남아 있음")
            continue
        if HANGUL.search(sec):
            bad(f"(3) {lang} #{bid} 에 한글 잔류 — 번역되지 않은 채 ko 가 복사됨",
                *[l for l in sec.splitlines() if HANGUL.search(l)][:3])
            continue
        if len(body_of(sec).strip()) < 20:
            bad(f"(3) {lang} #{bid} 본문이 비어 있음 ({len(body_of(sec).strip())}자)")
            continue
        ok(f"(3) {lang} #{bid} 본문이 번역되어 채워짐 ({len(body_of(sec).strip())}자)")

        # (3t) 표 모양 보존
        ko_tbl = table_shape(ko.get(bid, ""))
        if ko_tbl:
            new_tbl = table_shape(sec)
            if new_tbl == ko_tbl:
                ok(f"(3t) {lang} #{bid} 표가 ko 와 같은 모양 ({ko_tbl[0]}열 × {ko_tbl[1]}행)")
            else:
                bad(f"(3t) {lang} #{bid} 표 모양이 ko({ko_tbl}) 와 다름({new_tbl})",
                    "열이 줄면 렌더러가 셀을 조용히 버린다 — 배포 페이지에서 설명이 사라진다")

        # (3c) 코드 펜스 내용 보존
        ko_code = fence_body(ko.get(bid, ""))
        if ko_code:
            new_code = fence_body(sec)
            if new_code == ko_code:
                ok(f"(3c) {lang} #{bid} 코드 펜스 {len(ko_code)}줄이 ko 와 바이트 동일")
            else:
                bad(f"(3c) {lang} #{bid} 코드 펜스가 변경됨 "
                    f"(ko {len(ko_code)}줄 / 결과 {len(new_code)}줄)",
                    *[f"ko : {a!r}" for a in ko_code[:2]],
                    *[f"new: {a!r}" for a in new_code[:2]])

# (4) body stub 의 heading/anchor 는 바이트 동일 (id 가 흔들리지 않는다)
for lang, (base, new) in langs.items():
    drift = [bid for bid in body_ids
             if heading_line(base.get(bid, "")) != heading_line(new.get(bid, ""))]
    if drift:
        bad(f"(4) {lang} 의 body stub heading 이 변경됨: {', '.join(drift)}",
            *[f"{bid}: {heading_line(base.get(bid,''))!r} → "
              f"{heading_line(new.get(bid,''))!r}" for bid in drift[:2]])
    else:
        ok(f"(4) {lang} body stub {len(body_ids)}개의 heading/anchor 바이트 보존")

# (5) heading stub — 마커 제거 + heading 번역 + 레벨/anchor 보존
for lang, (base, new) in langs.items():
    for hid in head_ids:
        sec = new.get(hid, "")
        ko_head = heading_line(ko.get(hid, "")) or ""
        new_head = heading_line(sec) or ""
        if HEAD_MARK in sec:
            bad(f"(5) {lang} #{hid} 에 stub 마커가 남아 있음")
        elif HANGUL.search(new_head):
            bad(f"(5) {lang} #{hid} heading 에 한글 잔류 — 번역되지 않음",
                f"heading: {new_head!r}")
        elif not sec.startswith(f'<a id="{hid}"></a>'):
            bad(f"(5) {lang} #{hid} 의 <a id> 줄이 유실/이동됨",
                f"head: {sec.splitlines()[:1]}")
        else:
            lvl_ko = len(ko_head) - len(ko_head.lstrip("#"))
            lvl_new = len(new_head) - len(new_head.lstrip("#"))
            if lvl_ko != lvl_new:
                bad(f"(5) {lang} #{hid} heading 레벨이 ko({lvl_ko}) 와 다름({lvl_new})",
                    "레벨은 ko 가 정본이다 — 승격되면 문서 구조가 달라진다")
            elif HANGUL.search(sec):
                bad(f"(5) {lang} #{hid} 본문에 한글 잔류",
                    *[l for l in sec.splitlines() if HANGUL.search(l)][:3])
            else:
                ok(f"(5) {lang} #{hid} heading+본문 번역 · anchor/레벨(h{lvl_ko}) 보존")

# (6) 채운 섹션 밖은 바이트 동일
for lang, (base, new) in langs.items():
    diffs = [k for k in set(base) | set(new)
             if k not in filled_ids and base.get(k) != new.get(k)]
    if diffs:
        bad(f"(6) {lang} 의 다른 섹션이 변경됨: {', '.join(sorted(map(str, diffs))[:5])}",
            "채우기는 stub 섹션 밖을 한 바이트도 건드리면 안 된다")
    else:
        ok(f"(6) {lang} 는 채운 섹션 밖이 base 와 바이트 동일 ({len(base)}개 구간)")

# (7) id 없는 stub 은 건드리지 않는다
for lang, (base, new) in langs.items():
    whole = read(f"{tmp}/{lang}.filled.md")
    if noid_heading in whole and (BODY_MARK in whole or HEAD_MARK in whole):
        ok(f"(7) {lang} 의 id 없는 stub 은 채우지 않고 그대로 남김")
    else:
        bad(f"(7) {lang} 의 id 없는 stub 이 사라짐/채워짐 — anchor 없이 ko 를 추정한 것",
            f"heading 존재={noid_heading in whole}, "
            f"마커 존재={BODY_MARK in whole or HEAD_MARK in whole}")

# (8) PR 본문 보고
pr_body = read(f"{tmp}/pr_body.md")
missing = [i for i in filled_ids if f"#{i}" not in pr_body]
if missing:
    bad(f"(8a) PR 본문에 채운 id 가 없음: {', '.join(missing)}")
else:
    ok(f"(8a) PR 본문이 채운 섹션 id {len(filled_ids)}개를 나열")
if "건너뜀" in pr_body:
    ok("(8b) PR 본문이 건너뛴 stub 을 '건너뜀' 으로 보고")
else:
    bad("(8b) PR 본문에 건너뜀 보고가 없음 — 조용히 빠지면 아무도 모른다")

# (8c) before/after 프리뷰 링크 — 섹션 앵커까지. 채우기 PR 의 리뷰는 raw diff
# 가 아니라 렌더된 페이지에서 이뤄지므로 이 링크가 산출물의 일부다.
# 링크가 브랜치 ref 를 가리키면 머지 후 before 가 after 와 같은 화면이 되어
# 되짚을 수 없게 되므로, **커밋 SHA** 인지까지 본다.
links = {}
for anchor in filled_ids:
    pat = (r"\[before\]\((?P<b>[^)]*?/view\?[^)]*?#" + re.escape(anchor) + r")\)"
           r"[^\n]*?\[after\]\((?P<a>[^)]*?/view\?[^)]*?#" + re.escape(anchor) + r")\)")
    m = re.search(pat, pr_body)
    links[anchor] = m
    if not m:
        bad(f"(8c) #{anchor} 의 before/after 프리뷰 링크가 PR 본문에 없음")
if all(links.values()):
    sha40 = re.compile(r"tx_ref=[0-9a-f]{40}")
    bad_ref = [a for a, m in links.items()
               if not (sha40.search(m.group("b")) and sha40.search(m.group("a")))]
    if bad_ref:
        bad("(8c) 프리뷰 링크가 커밋 SHA 가 아님 (머지 후 before 가 after 로 재해석됨): "
            + ", ".join(bad_ref))
    elif any(m.group("b") == m.group("a") for m in links.values()):
        bad("(8c) before 와 after 링크가 동일 — 두 상태를 가리키지 못한다")
    else:
        ok(f"(8c) 채운 섹션 {len(links)}개에 before/after 프리뷰 링크 (앵커 + 커밋 SHA)")

raise SystemExit(rc)
PY

# ── 6) 결과 ───────────────────────────────────────────────────────────────
echo
echo "[6/7] 결과"
if (( fails == 0 )); then
  echo "FILL_STUBS: OK"
  echo "  빈 번역 채우기가 stub 섹션만 채우고 나머지는 바이트 보존 (PR: $fill_pr_url)"
  echo
  echo "[7/7] cleanup"
  exit 0
fi
echo "FILL_STUBS: FAIL"
echo "  $fails 개 규칙 실패 — 로그: $LOG / dry-run: $DRYLOG"
echo "  PR 은 보존합니다: $fill_pr_url"
KEEP=1
exit 1
