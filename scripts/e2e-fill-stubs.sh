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
#   - 섹션 밖 EOL/공백이 재작성돼 diff 가 문서 전체로 번짐 (CRLF 파일 사고)
#   - id 없는 stub 을 억지로 채워 ko 와 대응되지 않는 문장이 들어감
# 전부 바이트 비교로 판정 가능하므로 이 e2e 는 LLM 판정을 쓰지 않는다.
#
# ── 왜 결함 주입이 아니라 픽스처 시드인가 ─────────────────────────────────
# stub 은 pre-align 이 "ko 에는 있고 target 에는 없는 섹션" 을 만났을 때만
# 생긴다. Agent-Test 의 ko/en/ja 는 이미 정렬돼 있어 자연 발생을 기다릴 수
# 없으므로, pre-align 이 만드는 것과 **같은 모양**을 직접 심는다
# (align_headings._make_stub / align_apply 참고):
#     body stub  : <a id>/heading 은 그대로 두고 본문만 `<!-- TODO: translate body -->`
#     heading stub: <a id> + **ko heading 줄 그대로** + `<!-- TODO: translate -->`
# 여기에 **음성 대조군**으로 id 없는 stub 하나를 더 심는다 — 이건 반드시
# 건너뛰어야 하고, 건너뛴 사실이 PR 본문에 남아야 한다. (자동 채우기는 anchor
# id 로 ko 섹션을 찾으므로 id 가 없으면 원리적으로 대응 ko 를 알 수 없다.)
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   1) alpha 에서 세션 브랜치 생성
#   2) 픽스처 시드 — en=body stub, ja=heading stub, en=id 없는 stub → 커밋/푸시
#   3) dry-run 탐지 (모델 호출 0 · PR 생성 없음)        [--translate local 전용]
#   4) 실제 채우기 → Fill PR
#   5) 판정 (아래 8개 규칙, 전부 바이트/구조 비교)
#   6) 결과 (FILL_STUBS: OK|FAIL)
#   7) cleanup
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) dry-run 이 body/heading stub 을 fillable 로 탐지하고 id 없는 stub 은
#       skip 사유와 함께 보고 · 브랜치/PR 을 만들지 않음      [local 전용, api=SKIP]
#   (2) 실제 실행이 Fill PR 을 생성 (`Fill PR:` / head=fill-stubs/…)
#   (3) body stub 이 채워짐 — 마커 제거 · 한글 잔류 0 · 본문 비어있지 않음
#   (4) body stub 의 heading/anchor 줄이 **바이트 동일** (id 가 흔들리지 않음)
#   (5) heading stub 이 채워짐 — 마커 제거 · heading 에 한글 잔류 0 ·
#       heading 레벨과 `<a id>` 는 보존
#   (6) 채운 섹션 **밖**은 base 와 바이트 동일 (en/ja 각각)
#   (7) id 없는 stub 은 그대로 남음 (억지로 채우지 않음)
#   (8) PR 본문이 채운 id 를 나열하고, 건너뛴 stub 을 '건너뜀' 으로 보고
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-fill-stubs.sh                      # 로컬 translate_fill_stubs.py
#   bash scripts/e2e-fill-stubs.sh --translate api      # dashboard /api/fill-empty → Jenkins
#   bash scripts/e2e-fill-stubs.sh --keep               # 브랜치/PR 보존 (디버깅)
#   bash scripts/e2e-fill-stubs.sh --doc console-guide.md
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
DOC="overview.md"          # ko/en/ja 세 벌이 다 있는 작은 문서
KEEP=0
TRANSLATE_MODE="local"     # local | api
ENGINE="api"               # local 모드에서만 의미 (api|cli)
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
    --translate) TRANSLATE_MODE="$2"; shift 2 ;;
    --engine) ENGINE="$2"; shift 2 ;;
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
    -h|--help) sed -n '1,62p' "$0"; exit 0 ;;
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
  done < <(git ls-remote --heads origin "refs/heads/fill-stubs/*$TS*" 2>/dev/null | sed 's|.*refs/heads/||')
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "repo    : $REPO"
echo "session : $SESSION_BRANCH"
echo "doc     : $DOC"
echo "mode    : --translate $TRANSLATE_MODE"
echo

# ── 1) 세션 브랜치 ────────────────────────────────────────────────────────
echo "[1/7] 세션 브랜치 생성"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

# ── 2) 픽스처 시드 ────────────────────────────────────────────────────────
# 섹션은 하드코딩하지 않는다 — ko/en/ja 가 공유하는 anchor id 중에서 조건
# (한글 본문 있음 · 코드펜스/표/이미지 없음 · 적당한 길이) 을 만족하는 것을
# 고른다. 픽스처가 restore 스크립트로 갈아끼워져도 이 e2e 는 계속 동작한다.
echo "[2/7] 픽스처 시드 — en=body stub · ja=heading stub · en=id 없는 stub"
fixture_out="$(python3 - "$DOC" "$TS" <<'PY'
import io, re, sys

doc, ts = sys.argv[1], sys.argv[2]
BODY_MARK = "<!-- TODO: translate body -->"
HEAD_MARK = "<!-- TODO: translate -->"
HANGUL = re.compile(r"[가-힣]")
ANCHOR = re.compile(r'^<a id="([^"]+)"></a>\s*$')


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


def split_sections(text):
    """[(anchor_id|None, raw)] — <a id> 줄에서 자른다. 첫 앵커 앞은 (None, …)."""
    lines = text.splitlines(keepends=True)
    out, cur_id, buf = [], None, []
    for ln in lines:
        m = ANCHOR.match(ln.rstrip("\r\n"))
        if m:
            out.append((cur_id, "".join(buf)))
            cur_id, buf = m.group(1), [ln]
        else:
            buf.append(ln)
    out.append((cur_id, "".join(buf)))
    return [(i, r) for i, r in out if r]


def heading_and_body(raw):
    """(heading 줄, 본문) — raw 는 <a id> 줄로 시작한다고 가정."""
    lines = raw.splitlines(keepends=True)
    for i, ln in enumerate(lines[1:], start=1):
        if ln.lstrip().startswith("#"):
            return ln.rstrip("\r\n"), "".join(lines[i + 1:])
    return None, ""


def suitable(ko_raw):
    """모델 호출을 짧고 결정적으로 유지하기 위한 섹션 조건."""
    h, body = heading_and_body(ko_raw)
    if h is None:
        return False
    if any(t in ko_raw for t in ("```", "|", "![", "<img")):
        return False
    if not HANGUL.search(body):
        return False
    return 60 <= len(body.strip()) <= 900


ko = read(f"ko/{doc}")
ko_secs = split_sections(ko)
ko_by_id = {i: r for i, r in ko_secs if i}

picks = {}
for lang in ("en", "ja"):
    secs = split_sections(read(f"{lang}/{doc}"))
    ids = [i for i, r in secs
           if i and i in ko_by_id and suitable(ko_by_id[i])
           and BODY_MARK not in r and HEAD_MARK not in r
           and i not in picks.values()]
    if not ids:
        raise SystemExit(f"error: {lang}/{doc} 에 조건을 만족하는 섹션이 없음")
    picks[lang] = ids[0]

eol_of = lambda t: "\r\n" if "\r\n" in t else "\n"

# (a) en — body stub: <a id>/heading 은 그대로 두고 본문만 마커로.
en_text = read(f"en/{doc}")
eol = eol_of(en_text)
out = []
for i, raw in split_sections(en_text):
    if i == picks["en"]:
        h, _ = heading_and_body(raw)
        lines = raw.splitlines(keepends=True)
        anchor_line = lines[0]
        raw = anchor_line + h + eol + eol + BODY_MARK + eol + eol
    out.append(raw)
en_new = "".join(out)

# (c) en — 음성 대조군: <a id> 없는 stub. 반드시 건너뛰어야 한다.
noid_heading = f"E2E no-id stub ({ts})"
en_new += (f"{eol}## {noid_heading}{eol}{eol}{BODY_MARK}{eol}")
io.open(f"en/{doc}", "w", encoding="utf-8", newline="").write(en_new)

# (b) ja — heading stub: <a id> + **ko heading 줄 그대로** + 마커.
#     pre-align 의 _make_stub 이 만드는 모양과 동일 (heading 도 아직 한국어).
ja_text = read(f"ja/{doc}")
eol = eol_of(ja_text)
out = []
for i, raw in split_sections(ja_text):
    if i == picks["ja"]:
        ko_h, _ = heading_and_body(ko_by_id[i])
        lines = raw.splitlines(keepends=True)
        raw = lines[0] + ko_h + eol + eol + HEAD_MARK + eol + eol
    out.append(raw)
io.open(f"ja/{doc}", "w", encoding="utf-8", newline="").write("".join(out))

print(f"BODY_ID={picks['en']}")
print(f"HEAD_ID={picks['ja']}")
print(f"NOID_HEADING={noid_heading}")
PY
)"
echo "$fixture_out" | sed 's/^/  /'
BODY_ID="$(sed -n 's/^BODY_ID=//p' <<<"$fixture_out")"
HEAD_ID="$(sed -n 's/^HEAD_ID=//p' <<<"$fixture_out")"
NOID_HEADING="$(sed -n 's/^NOID_HEADING=//p' <<<"$fixture_out")"
[[ -n "$BODY_ID" && -n "$HEAD_ID" ]] || { echo "error: 픽스처 시드 실패" >&2; exit 2; }

git add -- "en/$DOC" "ja/$DOC"
staged="$(git diff --cached --name-only | sort | tr '\n' ' ')"
[[ "$staged" == "en/$DOC ja/$DOC " ]] || { echo "error: 예상 외 파일 스테이지됨: $staged" >&2; exit 2; }
git commit -q -m "e2e(fill-stubs): en=body stub($BODY_ID) · ja=heading stub($HEAD_ID) · id 없는 stub 시드 ($TS)"
git push -q origin "$SESSION_BRANCH"
base_sha="$(git rev-parse HEAD)"
echo "  세션 base: $base_sha"

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
  echo "  engine=$ENGINE model=${TRANSLATE_MODEL:-<.env 기본>}"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    env TRANSLATE_TRANSLATE_ENGINE="$ENGINE" \
        ${TRANSLATE_MODEL:+TRANSLATE_ANTHROPIC_MODEL="$TRANSLATE_MODEL"} \
      "$CLOUD_TRANSLATE_PY" translate/translate_fill_stubs.py "$REPO" "$SESSION_BRANCH" \
        --only "en/$DOC,ja/$DOC" \
  ) 2>&1 | tee "$LOG"
  fill_rc=${PIPESTATUS[0]}
  set -e
  fill_pr_url="$(grep -oE 'Fill PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
else
  # dashboard 경로 — 대시보드 TODO 현황 탭의 '빈 번역 채우기' 와 동일한 API.
  # --only 가 없으므로 세션 브랜치의 다른 stub 도 함께 채워질 수 있다
  # (판정은 이 e2e 가 심은 두 섹션만 보므로 무방).
  resp="$(curl -sS -X POST \
    -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"target\": \"https://github.com/$REPO\", \"branch\": \"$SESSION_BRANCH\", \"langs\": \"en,ja\"}" \
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
  grep -q "#$BODY_ID" "$DRYLOG" || { d_ok=0; echo "        dry-run 에 #$BODY_ID 없음"; }
  grep -q "#$HEAD_ID" "$DRYLOG" || { d_ok=0; echo "        dry-run 에 #$HEAD_ID 없음"; }
  grep -q "skip (id 없음)" "$DRYLOG" || { d_ok=0; echo "        id 없는 stub 의 skip 보고 없음"; }
  grep -q "탐지만 수행" "$DRYLOG" || { d_ok=0; echo "        dry-run 종료 문구 없음"; }
  if grep -q "Fill PR:" "$DRYLOG"; then d_ok=0; echo "        dry-run 이 PR 을 만들었다"; fi
  (( d_ok )) && ok "(1) dry-run 이 stub 2개 탐지 · id 없는 stub skip · PR 미생성" \
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

# (3)~(7) 구조/바이트 검사 — LLM 판정 없음.
python3 - "$tmpdir" "$BODY_ID" "$HEAD_ID" "$NOID_HEADING" <<'PY' || fails=$((fails + 1))
import io, re, sys

tmp, body_id, head_id, noid_heading = sys.argv[1:5]
HANGUL = re.compile(r"[가-힣]")
ANCHOR = re.compile(r'^<a id="([^"]+)"></a>\s*$')
BODY_MARK = "<!-- TODO: translate body -->"
HEAD_MARK = "<!-- TODO: translate -->"
rc = 0


def read(p):
    return io.open(p, encoding="utf-8", newline="").read()


def sections(text):
    lines, out, cur, buf = text.splitlines(keepends=True), {}, "__pre__", []
    for ln in lines:
        m = ANCHOR.match(ln.rstrip("\r\n"))
        if m:
            out[cur] = out.get(cur, "") + "".join(buf)
            cur, buf = m.group(1), [ln]
        else:
            buf.append(ln)
    out[cur] = out.get(cur, "") + "".join(buf)
    return out


def heading_line(raw):
    for ln in raw.splitlines()[1:]:
        if ln.lstrip().startswith("#"):
            return ln
    return None


def ok(msg):
    print(f"  PASS  {msg}")


def bad(msg, *extra):
    global rc
    print(f"  FAIL  {msg}")
    for e in extra:
        print(f"        {e}")
    rc = 1


ko = sections(read(f"{tmp}/ko.md"))
en_base, en_new = sections(read(f"{tmp}/en.base.md")), sections(read(f"{tmp}/en.filled.md"))
ja_base, ja_new = sections(read(f"{tmp}/ja.base.md")), sections(read(f"{tmp}/ja.filled.md"))

# (3) body stub 이 채워졌는가
sec = en_new.get(body_id, "")
if BODY_MARK in sec:
    bad(f"(3) en #{body_id} 에 stub 마커가 남아 있음")
elif HANGUL.search(sec):
    bad(f"(3) en #{body_id} 에 한글 잔류 — 번역되지 않은 채 ko 가 복사됨",
        *[l for l in sec.splitlines() if HANGUL.search(l)][:3])
else:
    h = heading_line(sec)
    body = sec.split(h, 1)[1].strip() if h else ""
    if len(body) < 20:
        bad(f"(3) en #{body_id} 본문이 비어 있음 ({len(body)}자)")
    else:
        ok(f"(3) en #{body_id} 본문이 번역되어 채워짐 ({len(body)}자)")

# (4) body stub 의 heading/anchor 는 바이트 동일 (id 가 흔들리지 않는다)
base_head, new_head = heading_line(en_base.get(body_id, "")), heading_line(sec)
if base_head is not None and base_head == new_head:
    ok(f"(4) en #{body_id} heading/anchor 바이트 보존")
else:
    bad(f"(4) en #{body_id} heading 이 변경됨", f"base: {base_head!r}", f"new : {new_head!r}")

# (5) heading stub — 마커 제거 + heading 번역 + 레벨/anchor 보존
sec = ja_new.get(head_id, "")
ko_head = heading_line(ko.get(head_id, "")) or ""
new_head = heading_line(sec) or ""
if HEAD_MARK in sec:
    bad(f"(5) ja #{head_id} 에 stub 마커가 남아 있음")
elif HANGUL.search(new_head):
    bad(f"(5) ja #{head_id} heading 에 한글 잔류 — 번역되지 않음", f"heading: {new_head!r}")
elif not sec.startswith(f'<a id="{head_id}"></a>'):
    bad(f"(5) ja #{head_id} 의 <a id> 줄이 유실/이동됨", f"head: {sec.splitlines()[:1]}")
else:
    lvl_ko = len(ko_head) - len(ko_head.lstrip("#"))
    lvl_new = len(new_head) - len(new_head.lstrip("#"))
    if lvl_ko != lvl_new:
        bad(f"(5) ja #{head_id} heading 레벨이 ko({lvl_ko}) 와 다름({lvl_new})")
    elif HANGUL.search(sec):
        bad(f"(5) ja #{head_id} 본문에 한글 잔류",
            *[l for l in sec.splitlines() if HANGUL.search(l)][:3])
    else:
        ok(f"(5) ja #{head_id} heading+본문이 번역되고 anchor/레벨 보존")

# (6) 채운 섹션 밖은 바이트 동일
for lang, base, new, filled_id in (("en", en_base, en_new, body_id),
                                   ("ja", ja_base, ja_new, head_id)):
    diffs = [k for k in set(base) | set(new)
             if k != filled_id and base.get(k) != new.get(k)]
    if diffs:
        bad(f"(6) {lang} 의 다른 섹션이 변경됨: {', '.join(sorted(map(str, diffs))[:5])}")
    else:
        ok(f"(6) {lang} 는 채운 섹션 밖이 base 와 바이트 동일 ({len(base)}개 구간)")

# (7) id 없는 stub 은 건드리지 않는다
whole = read(f"{tmp}/en.filled.md")
if noid_heading in whole and BODY_MARK in whole:
    ok("(7) id 없는 stub 은 채우지 않고 그대로 남김")
else:
    bad("(7) id 없는 stub 이 사라짐/채워짐 — anchor 없이 ko 를 추정한 것",
        f"heading 존재={noid_heading in whole}, 마커 존재={BODY_MARK in whole}")

# (8) PR 본문 보고
pr_body = read(f"{tmp}/pr_body.md")
if f"#{body_id}" in pr_body and f"#{head_id}" in pr_body:
    ok("(8a) PR 본문이 채운 섹션 id 를 나열")
else:
    bad("(8a) PR 본문에 채운 id 가 없음")
if "건너뜀" in pr_body and "id 없는 stub" in pr_body:
    ok("(8b) PR 본문이 id 없는 stub 을 '건너뜀' 으로 보고")
else:
    bad("(8b) PR 본문에 건너뜀 보고가 없음 — 조용히 빠지면 아무도 모른다")

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
