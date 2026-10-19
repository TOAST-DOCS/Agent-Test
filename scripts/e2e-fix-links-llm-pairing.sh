#!/usr/bin/env bash
#
# 링크 정정 LLM 2차 처리 — 답을 질문한 문서에 적용하는가 (cloud-translate#1325).
#
# ── 결함 ──────────────────────────────────────────────────────────────────
# fix-links 는 한 실행의 잔여 링크를 LLM 에 **한 번에** 묻고 답을 문서별로
# 되돌린다. 답을 `(줄, 원래 대상)` 으로만 짝지으면, ko/en/ja 의 같은 죽은 링크가
# 같은 줄에 있을 때 한 언어의 **후보 번호**가 다른 언어의 후보 목록에 적용된다.
# 후보 순서는 언어마다 자기 heading 텍스트로 매겨지므로 같은 번호가 다른 절이다.
# 실제 사고: TOAST-DOCS/RDS-FOR-SQLSERVER#72 (en #layout) · RCS-Bizmessage#64
# (en #show-map). 고른 앵커는 실재하므로 어떤 검사도 막지 못한다.
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# `archive/llm-pairing/{ko,en,ja}/` (alpha 에는 시드하지 않는다 — 문서 전체를
# 훑는 다른 e2e 의 수치를 바꾸지 않게, 세션 브랜치에만 심는다):
#   llm-pairing-target.md — 같은 id 의 절 6개. en 에만 문자열이 링크 문구와 더
#                           비슷한 미끼(`How to Subscribe to a Plan`)가 정답 앞에 온다
#   llm-pairing-sample.md — [A] 10행: 세 언어 같은 줄 `./llm-pairing-target/#_3`
#                                     (정답 #event-subscription — ko/ja 1번 · en 2번)
#                           [B] 대조군: 언어마다 다른 줄(15/17/19) `#_4`
#                                     (정답 #notification-group)
# 픽스처 생성기의 순위는 cloud-translate `links.fix._rank` 로 확인했다.
#
# ── BEFORE / AFTER ────────────────────────────────────────────────────────
# 같은 세션 base 에 CLOUD_TRANSLATE_DIR 만 바꿔 두 번 돌린다. 엔진은 언제나
# Claude Code CLI (`--engine claude-code`) — 프로덕션 잡과 같은 경로.
#
#   bash scripts/e2e-fix-links-llm-pairing.sh --label BEFORE \
#        --cloud-translate-dir <main 체크아웃>
#   # → "session: e2e-llmpair/<ts>" 를 출력한다
#   bash scripts/e2e-fix-links-llm-pairing.sh --label AFTER \
#        --base-branch e2e-llmpair/<ts> --cloud-translate-dir <PR 체크아웃>
#
# 각 실행은 세션 브랜치를 base 로 하는 fix-links PR 을 열고, 제목 앞에
# `[BEFORE]`/`[AFTER]` 를 붙인다. 판정은 `scripts/check_llm_pairing.py`
# (모델 없음): OK(exit 0) · REPRO(3, [A] 가 갈림/틀림) · CONTROL-FAIL(4).
# 기대: BEFORE = REPRO · AFTER = OK. 대조군은 둘 다 OK 여야 한다.
#
# PR·브랜치는 기본으로 **남긴다** (BEFORE/AFTER 를 나란히 보려고). 정리는
# `--cleanup <세션 브랜치>` — 그 base 의 fix-links PR 을 닫고 브랜치를 지운다.
#
# 의존성: git, gh, python3, .env(CLOUD_TRANSLATE_DIR 또는 --env-file) + venv(viewer 의존성),
# 로그인된 `claude` CLI.
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
LANGS="ko,en,ja"
LABEL=""
BASE_BRANCH=""
CLEANUP=""
ENV_FILE=""
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="$2"; shift 2 ;;
    --base-branch) BASE_BRANCH="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --cleanup) CLEANUP="$2"; shift 2 ;;
    --env-file) ENV_FILE="$2"; shift 2 ;;
    -h|--help) sed -n '2,45p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/e2e-label.sh"

if [[ -n "$CLEANUP" ]]; then
  gh pr list --repo "$REPO" --base "$CLEANUP" --state open --json number \
    --jq '.[].number' | while read -r n; do
      gh pr close "$n" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
    done
  git -C "$REPO_ROOT" push origin ":$CLEANUP" >/dev/null 2>&1 || true
  echo "cleaned: $CLEANUP"; exit 0
fi

[[ "$LABEL" == "BEFORE" || "$LABEL" == "AFTER" ]] || {
  echo "error: --label BEFORE|AFTER 필요" >&2; exit 2; }
# 설정은 체크아웃의 .env 를 읽는다. 워크트리에는 .env 가 없으므로 --env-file 로
# 메인 체크아웃의 .env 를 가리키면 그 값을 **프로세스 환경 변수로만** 싣는다
# (워크트리에 파일을 만들지 않는다 — 심볼릭 링크를 남기면 translate 테스트가 깨진다).
[[ -n "$ENV_FILE" ]] || ENV_FILE="$CLOUD_TRANSLATE_DIR/.env"
[[ -f "$ENV_FILE" ]] || {
  echo "error: $ENV_FILE 없음 (워크트리면 --env-file <메인 체크아웃>/.env)" >&2; exit 2; }
[[ -f "$CLOUD_TRANSLATE_DIR/dashboard/links/cli.py" ]] || {
  echo "error: $CLOUD_TRANSLATE_DIR 에 dashboard/links/cli.py 없음" >&2; exit 2; }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
ct_rev="$(git -C "$CLOUD_TRANSLATE_DIR" rev-parse --short HEAD)"

# ── 1) 세션 브랜치 (공유 체크아웃의 HEAD 는 건드리지 않는다) ───────────────
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-llmpair/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/4] 세션 브랜치 생성: $BASE_BRANCH"
  git -C "$REPO_ROOT" fetch -q origin "+refs/heads/$BASE_SOURCE:refs/remotes/origin/$BASE_SOURCE"
  git -C "$REPO_ROOT" worktree add -q --detach "$tmpdir/seed" "origin/$BASE_SOURCE"
  for lang in ${LANGS//,/ }; do
    cp "$REPO_ROOT/archive/llm-pairing/$lang/"*.md "$tmpdir/seed/$lang/"
  done
  git -C "$tmpdir/seed" add -A
  git -C "$tmpdir/seed" commit -q -m "e2e(llm-pairing): 픽스처 시드 — 같은 줄 #_3 · 대조군 #_4"
  git -C "$tmpdir/seed" push -q origin "HEAD:refs/heads/$BASE_BRANCH"
  git -C "$REPO_ROOT" worktree remove --force "$tmpdir/seed"
else
  echo "[1/4] 세션 브랜치 재사용: $BASE_BRANCH"
fi
echo "session: $BASE_BRANCH"

# ── 2) 링크 정정 (CLI 엔진 · 실제 PR) ────────────────────────────────────
paths=""
for lang in ${LANGS//,/ }; do paths+="${paths:+,}$lang/llm-pairing-sample.md"; done
echo "[2/4] fix-links ($LABEL · cloud-translate $ct_rev · engine=claude-code)"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && PYTHONPATH=".:dashboard" ENV_FILE="$ENV_FILE" \
  "$CLOUD_TRANSLATE_PY" -c '
import os, runpy, sys
from dotenv import dotenv_values
for k, v in dotenv_values(os.environ["ENV_FILE"]).items():
    if v is not None:
        os.environ.setdefault(k, v)
sys.argv = ["links.cli"] + sys.argv[1:]
runpy.run_module("links.cli", run_name="__main__", alter_sys=True)
' fix-links \
    --repo "$REPO" --ref "$BASE_BRANCH" --langs "$LANGS" --paths "$paths" \
    --engine claude-code --verify lang-parity --out "$tmpdir/out") \
  > "$tmpdir/fix.log" 2>&1
fix_rc=$?
set -e
grep -E '^(scanned|notok|repaired|left|llm|engine)|LLM|PR opened' "$tmpdir/fix.log" | sed 's/^/  /' || true
pr_url="$(grep -oE 'https://github\.com/[^ ]+/pull/[0-9]+' "$tmpdir/fix.log" | tail -1 || true)"
[[ -n "$pr_url" ]] || { echo "error: PR 이 열리지 않았다 (rc=$fix_rc)"; tail -30 "$tmpdir/fix.log"; exit 1; }
echo "  PR: $pr_url"

# ── 3) 제목 · 라벨 ───────────────────────────────────────────────────────
title="$(gh pr view "$pr_url" --json title -q .title)"
gh pr edit "$pr_url" --title "[$LABEL] $title" >/dev/null
e2e_label_pr "$REPO" "$pr_url"

# ── 4) 판정 ──────────────────────────────────────────────────────────────
echo "[4/4] 판정 (PR head 의 세 파일)"
head_sha="$(gh pr view "$pr_url" --json headRefOid -q .headRefOid)"
for lang in ${LANGS//,/ }; do
  mkdir -p "$tmpdir/judge/$lang"
  gh api "repos/$REPO/contents/$lang/llm-pairing-sample.md?ref=$head_sha" -q .content \
    | base64 -d > "$tmpdir/judge/$lang/llm-pairing-sample.md"
done
set +e
python3 "$REPO_ROOT/scripts/check_llm_pairing.py" "$tmpdir/judge"
rc=$?
set -e
echo
echo "label=$LABEL  cloud-translate=$ct_rev  session=$BASE_BRANCH"
echo "pr=$pr_url  head=$head_sha"
exit $rc
