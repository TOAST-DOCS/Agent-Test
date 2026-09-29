#!/usr/bin/env bash
#
# korean-review 인라인 코멘트 **줄 위치** e2e (Agent-Test):
#   1) alpha 로부터 세션 base e2e-koreview-anchors/<ts> 를 만들고 픽스처
#      ko/review-line-anchors.md 의 **before** 판을 심는다 (파일 끝 개행 없음)
#   2) 같은 내용의 head 브랜치를 LABEL 마다 하나씩 만들어 PR 을 연다
#      (기본 한 개 — `--label AFTER`. BEFORE/AFTER 대조는 두 번 부르고 --base-branch 공유)
#   3) 대시보드 /api/ko-review 로 검수 (pipeline_branch 지정 가능 — 미머지 코드 검증)
#   4) 판정 — **결정적**: 규칙 레이어의 `예)` → `예:` 확정 치환 4건만 본다 (LLM 지적은 무시)
#      [A] 리뷰(요약)가 게시됐다
#      [B] 기대 줄 4곳 각각에 인라인 코멘트가 있다 — 그 줄이 실제로 `예)` 를 담은 줄
#      [C] 각 코멘트의 suggestion 이 **그 줄 자체**의 교정본이다 (한 줄 아래 앵커 = 다른 줄 덮어쓰기)
#
# 픽스처가 담는 모양 넷 — 각각이 parse_added_lines 가 줄번호를 밀던 경로다 (cloud-translate#1049):
#   ① 표 칸 안의 U+2028      — str.splitlines() 가 그 줄을 둘로 잘랐다 (DDoS-Guard#10)
#   ② 삭제된 `--data …` 줄   — patch 에서 `---data …` 라 파일 헤더로 오인됐다 (Network-DNSPLUS#47)
#   ③ 추가된 `++ …` 줄       — `+++ …` 라 헤더로 오인돼 검수 대상에서 빠졌다
#   ④ 개행 없는 마지막 줄 교체 — `\ No newline` 마커를 줄로 셌다 → 파일 끝 너머 → 422 (Network-Firewall#138)
# 각 모양 뒤에 `예)` 줄을 하나씩 두어, 그 앞의 결함이 뒤 줄 앵커를 밀면 [B]/[C] 가 깨진다.
#
# webhook 을 끄지 않는 이유: 세션 base 가 webhook 필터의 base_branches(alpha,beta)
# 밖이라 이 PR 들은 자동 검수되지 않는다. 다른 세션의 webhook e2e 를 방해하지 않도록
# 전역 스위치를 건드리지 않는다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-korean-review-line-anchors.sh                                 # 배포본(main)
#   bash scripts/e2e-korean-review-line-anchors.sh --pipeline-branch PR-1049       # 미머지 브랜치
#   # BEFORE/AFTER 대조 — 같은 base, 같은 픽스처, 코드만 다르게:
#   bash scripts/e2e-korean-review-line-anchors.sh --label BEFORE --expect-fail
#   bash scripts/e2e-korean-review-line-anchors.sh --label AFTER --pipeline-branch PR-1049 \
#        --base-branch e2e-koreview-anchors/<ts>
#
# 의존성: git, gh (로그인), curl, python3

set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
DOC="ko/review-line-anchors.md"
BASE_BRANCH=""
BASE_SOURCE_BRANCH="alpha"
PIPELINE_BRANCH=""
LABEL="AFTER"
EXPECT_FAIL=0
JOB_TIMEOUT=1800

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-branch)     BASE_BRANCH="$2"; shift 2 ;;
    --pipeline-branch) PIPELINE_BRANCH="$2"; shift 2 ;;
    --label)           LABEL="$2"; shift 2 ;;
    --expect-fail)     EXPECT_FAIL=1; shift ;;
    --timeout)         JOB_TIMEOUT="$2"; shift 2 ;;
    -h|--help)         sed -n '3,38p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -n "${DASHBOARD_BASE_URL:-}" && -n "${DASHBOARD_API_TOKEN:-}" ]] \
  || { echo "error: source ./load_env.sh 먼저 (DASHBOARD_BASE_URL/API_TOKEN)" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmpdir="$(mktemp -d)"
# 공유 체크아웃의 HEAD 를 건드리지 않도록 전용 워크트리에서 작업한다.
wt="$tmpdir/wt"
cleanup() { git -C "$REPO_ROOT" worktree remove --force "$wt" 2>/dev/null || true; rm -rf "$tmpdir"; }
trap cleanup EXIT
git -C "$REPO_ROOT" fetch -q origin "$BASE_SOURCE_BRANCH"

# ── 픽스처 두 판 (printf — 파일 끝 개행을 정확히 통제하려고 heredoc 을 쓰지 않는다) ──
LS=$' '
write_before() {
  printf '%s\n' \
    "# 검수 줄 위치 픽스처" \
    "" \
    "이 문서는 한글 검수 인라인 코멘트가 올바른 줄에 달리는지 검증하는 픽스처입니다." \
    "" \
    "| 항목 | 설명 |" \
    "|---|---|" \
    "| 줄 구분 문자 | 이 칸에는 줄 구분 문자가${LS}들어 있습니다. |" \
    "" \
    "A 줄: 기존 문장입니다." \
    "" \
    '```bash' \
    'curl -X POST https://example.com \' \
    "--data '{\"a\": 1}'" \
    '```' \
    "" \
    "B 줄: 기존 문장입니다." \
    "" \
    "C 줄: 기존 문장입니다." \
    ""
  printf '%s' "마지막 줄: 기존 문장입니다."          # 파일 끝 개행 없음
}
write_after() {
  printf '%s\n' \
    "# 검수 줄 위치 픽스처" \
    "" \
    "이 문서는 한글 검수 인라인 코멘트가 올바른 줄에 달리는지 검증하는 픽스처입니다." \
    "" \
    "| 항목 | 설명 |" \
    "|---|---|" \
    "| 줄 구분 문자 | 이 칸에는 줄 구분 문자가${LS}들어 있습니다. |" \
    "" \
    "A 줄: 리전을 고릅니다. 예) 한국(판교) 리전" \
    "" \
    '```bash' \
    'curl -X POST https://example.com \' \
    "--data '{\"a\": 2}'" \
    '```' \
    "" \
    "B 줄: 리전을 고릅니다. 예) 한국(평촌) 리전" \
    "" \
    "++ 기호는 증가를 뜻합니다. 예) 카운터 증가" \
    "C 줄: 기존 문장입니다." \
    ""
  printf '%s' "마지막 줄: 리전을 고릅니다. 예) 일본(도쿄) 리전"   # 파일 끝 개행 없음
}

# ── 1) 세션 base ────────────────────────────────────────────────────
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-koreview-anchors/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/4] 세션 base 생성: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git -C "$REPO_ROOT" worktree add -q --detach "$wt" "origin/$BASE_SOURCE_BRANCH"
  write_before > "$wt/$DOC"
  git -C "$wt" add "$DOC"
  git -C "$wt" commit -q -m "fixture: $DOC before (korean-review line-anchor e2e)"
  git -C "$wt" push -q origin "HEAD:refs/heads/$BASE_BRANCH"
else
  echo "[1/4] 기존 세션 base 재사용: $BASE_BRANCH"
  git -C "$REPO_ROOT" fetch -q origin "$BASE_BRANCH"
  git -C "$REPO_ROOT" worktree add -q --detach "$wt" "origin/$BASE_BRANCH"
fi
echo "  E2E_BASE_BRANCH=$BASE_BRANCH"

# 계약: base 판은 파일 끝 개행이 없어야 ④ 가 성립한다.
[[ "$(tail -c1 "$wt/$DOC" | od -An -c | tr -d ' ')" != '\n' ]] \
  || { echo "  error: base 픽스처가 개행으로 끝난다 — ④ 불성립" >&2; exit 2; }

# ── 2) head + PR ────────────────────────────────────────────────────
head_branch="translate-test-anchors/$(date -u +%Y%m%d-%H%M%S)-$(tr 'A-Z' 'a-z' <<<"$LABEL")"
echo "[2/4] head $head_branch"
write_after > "$wt/$DOC"
git -C "$wt" add "$DOC"
git -C "$wt" commit -q -m "fixture: $DOC after [$LABEL]"
git -C "$wt" push -q origin "HEAD:refs/heads/$head_branch"
pr_url="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$head_branch" \
  --title "[$LABEL] korean-review 줄 위치 e2e — $DOC" \
  --body "korean-review 인라인 코멘트 줄 위치 e2e (\`scripts/e2e-korean-review-line-anchors.sh\`). pipeline_branch=\`${PIPELINE_BRANCH:-main}\`. 픽스처 모양: U+2028 · 삭제된 \`--data\` · 추가된 \`++\` · 개행 없는 마지막 줄.")"
pr_number="${pr_url##*/}"
echo "  PR: $pr_url"

# 계약: patch 가 네 모양을 실제로 담았는지 (안 담으면 판정이 공허해진다)
gh api "repos/$REPO/pulls/$pr_number/files" --jq ".[]|select(.filename==\"$DOC\")|.patch" > "$tmpdir/patch"
python3 - "$tmpdir/patch" <<'PY'
import sys
p=open(sys.argv[1],encoding="utf-8").read(); L=p.split("\n")
checks={"① U+2028":" " in p, "② ---data":any(l.startswith("---data") for l in L),
        "③ +++ 줄":any(l.startswith("+++ ") or l.startswith("+++") and "기호" in l for l in L),
        "④ \\ No newline 가 - 뒤":any(a.startswith("-") and b.startswith("\\") for a,b in zip(L,L[1:]))}
for k,v in checks.items(): print(f"  patch {k}: {'OK' if v else 'MISSING'}")
sys.exit(0 if all(checks.values()) else 2)
PY

# ── 3) 검수 ─────────────────────────────────────────────────────────
echo "[3/4] /api/ko-review (pipeline_branch=${PIPELINE_BRANCH:-<default>})"
body="$(python3 -c 'import json,sys; print(json.dumps({"pr_url":sys.argv[1],"pipeline_branch":sys.argv[2],
  "opts":{"apply":"suggest","review_passes":"2","engine":"default"},
  "label":f"한글 검수 e2e 줄 위치 [{sys.argv[3]}]: {sys.argv[1]}"}))' "$pr_url" "$PIPELINE_BRANCH" "$LABEL")"
resp="$(curl -sS -X POST -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" -d "$body" "$DASHBOARD_BASE_URL/api/ko-review")"
job_id="$(printf '%s' "$resp" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("job_id") or "")')"
[[ -n "$job_id" ]] || { echo "  error: job_id 없음: $resp" >&2; exit 2; }
echo "  job: $job_id"
deadline=$(( $(date +%s) + JOB_TIMEOUT )); status=""; build_url=""
while (( $(date +%s) < deadline )); do
  read -r status build_url < <(curl -sS --retry 3 -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$job_id" | python3 -c 'import json,sys
t=(json.load(sys.stdin).get("job") or {}).get("tasks") or [{}]
print(t[0].get("status") or "-", t[0].get("build_url") or "-")' || echo "- -")
  case "$status" in success|failure|failed|cancelled|partial) break ;; esac
  sleep 10
done
echo "  status=$status build=$build_url"
[[ "$status" == "success" ]] || { echo "  error: 검수 잡 실패 (status=$status)" >&2; exit 2; }

# ── 4) 판정 ─────────────────────────────────────────────────────────
echo "[4/4] 판정"
head_sha="$(gh pr view "$pr_url" --json headRefOid --jq .headRefOid)"
gh api "repos/$REPO/contents/$DOC?ref=$head_sha" --jq .content | base64 -d > "$tmpdir/head.md"
gh api --paginate "repos/$REPO/pulls/$pr_number/reviews" > "$tmpdir/reviews.json"
gh api --paginate "repos/$REPO/pulls/$pr_number/comments" > "$tmpdir/comments.json"
set +e
python3 - "$tmpdir" <<'PY'
import json,sys,re
d=sys.argv[1]
L=open(f"{d}/head.md",encoding="utf-8").read().split("\n")
load=lambda f: json.loads(open(f"{d}/{f}").read().replace("][",","))
reviews=[r for r in load("reviews.json") if r["user"]["login"].endswith("[bot]") and "한글 검수 결과" in (r["body"] or "")]
comments=[c for c in load("comments.json") if c["user"]["login"].endswith("[bot]")]
expected={i+1:l for i,l in enumerate(L) if "예)" in l}
ok=True
def verdict(name,cond,detail=""):
    global ok; ok&=cond; print(f"  [{'PASS' if cond else 'FAIL'}] {name}{(' — '+detail) if detail else ''}")
verdict("A 요약 리뷰 게시", len(reviews)>=1, f"{len(reviews)}건")
by_line={}
for c in comments: by_line.setdefault(c.get("line") or c.get("original_line"),[]).append(c)
print(f"  기대 줄 {sorted(expected)} · 인라인 줄 {sorted(k for k in by_line if k)}")
for ln,text in sorted(expected.items()):
    cs=by_line.get(ln,[])
    verdict(f"B L{ln} 에 코멘트", bool(cs), text[:30])
    sugg=[m.group(1) for c in cs for m in [re.search(r"```suggestion\n(.*?)\n?```",c["body"],re.S)] if m]
    want=text.replace("예)","예:")
    # 같은 줄의 다른 지적이 한 suggestion 으로 합쳐질 수 있으므로 바이트 일치 대신
    # "그 줄의 머리말(`예)` 앞부분)을 담고 `예:` 로 고쳤다" 로 본다 — 한 줄 아래에
    # 앵커되면 머리말이 다른 줄의 것이라 여기서 갈린다.
    key=text.split("예)")[0].strip()
    verdict(f"C L{ln} suggestion = 그 줄의 교정본",
            any(s.split("\n")[0]==want or (key in s.split("\n")[0] and "예:" in s) for s in sugg),
            f"got {[s[:30] for s in sugg]}" if sugg else "suggestion 없음")
    # 한 줄 아래에 이 줄의 교정본이 달렸는지 (off-by-one 신호)
    below=by_line.get(ln+1,[])
    if any(want in c["body"] for c in below): print(f"    ! L{ln+1} 에 L{ln} 의 교정본이 달림 (한 줄 아래 앵커)")
sys.exit(0 if ok else 1)
PY
rc=$?
set -e
echo
echo "  PR=$pr_url  job=$job_id  build=$build_url  base=$BASE_BRANCH"
if (( EXPECT_FAIL )); then
  (( rc != 0 )) && { echo "RESULT: FAIL as expected ([$LABEL] — 수정 전 동작 재현)"; exit 0; }
  echo "RESULT: unexpected PASS ([$LABEL] --expect-fail)"; exit 1
fi
(( rc == 0 )) && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit $rc
