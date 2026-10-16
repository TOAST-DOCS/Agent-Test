#!/usr/bin/env bash
#
# 번역 PR 문서 정비(post-maint)의 링크 정정 e2e (cloud-translate#1306,
# Dooray cloud-user-guide-agent — TOAST-DOCS/Log-Crash-Search#134→#137: 개발자가
# en/ja 에 site-root 로 고쳐 둔 SDK 가이드 링크를, ko 원문이 운영 host 절대 URL 이라
# 번역이 `https://docs.nhncloud.com/<lang>/…` 로 되돌렸다).
#
# 픽스처 archive/post-maint-links/ — {ko,en,ja}/sample.md (base), ko-after/sample.md:
#   #post-maint-links-ios · -android   ko 만 site-root → 절대 URL + `십시오`→`세요`
#                                      (#134 그대로). en/ja 는 site-root 로 남아 있다.
#   #post-maint-links-control (대조군)  en/ja 에 기존 절대 URL — ko 가 안 건드린 절이다.
#
# 판정 scripts/check_post_maint_links.py (모델 없음):
#   [A] 재번역 절의 en/ja 링크가 site-root 인가   [B] 대조군 절이 base 와 바이트 동일한가
# 그리고 AFTER 는 번역 PR 에 `post-maint(fix-links)` 커밋과 '링크 정정' 이 든 정비 댓글이
# 있어야 한다 (BEFORE 코드는 그 단계가 없다).
#
# BEFORE/AFTER 는 같은 입력에 코드만 바꿔 두 번 돈다 (둘 다 TRANSLATE_POST_MAINT=true):
#   scripts/e2e-post-maint-links.sh --label BEFORE --cloud-translate-dir <main 체크아웃>
#   scripts/e2e-post-maint-links.sh --label AFTER --cloud-translate-dir <PR 체크아웃> \
#       --base-branch <SESSION> --ko-pr <KO_PR>
#
# 엔진은 언제나 Claude Code CLI (권장 preset + e2e 비용 override, 다른 e2e 와 같다).
# 공유 체크아웃의 HEAD 는 건드리지 않는다 — 커밋은 임시 worktree 에서만 한다.
#
# exit: 0 OK · 3 REPRO · 2 인프라 · 1 사용법
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
TS="$(date -u +%Y%m%d-%H%M%S)"
LABEL="AFTER"
SESSION_BRANCH=""
KO_PR=""
CLEANUP=0
DOC="post-maint-links-sample.md"

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)               LABEL="$2"; shift 2 ;;
    --base-branch)         SESSION_BRANCH="$2"; shift 2 ;;
    --ko-pr)               KO_PR="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --cleanup)             CLEANUP=1; shift ;;
    -h|--help) sed -n '2,29p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
FIX="$REPO_ROOT/archive/post-maint-links"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"
source "$SCRIPTS/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/seed" "$tmpdir/head" "$tmpdir/base" "$tmpdir/tx"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( CLEANUP )); then
    [[ -n "${tx_pr_url:-}" ]] && gh pr close "$tx_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  fi
  return $rc
}
trap cleanup EXIT

echo "=== post-maint links e2e [$LABEL] ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 | cut -c1-70))"

# ── 1) 세션 base — 픽스처를 alpha 위에 심는다 ─────────────────────────────
if [[ -z "$SESSION_BRANCH" ]]; then
  SESSION_BRANCH="e2e-postmaintlinks/$TS"
  git fetch -q origin alpha
  git worktree add -q -b "$SESSION_BRANCH" "$tmpdir/seed" origin/alpha
  for l in ko en ja; do cp "$FIX/$l/sample.md" "$tmpdir/seed/$l/$DOC"; done
  git -C "$tmpdir/seed" add ko en ja
  git -C "$tmpdir/seed" commit -q -m "e2e(post-maint-links): 픽스처 시드 ($TS)"
  git -C "$tmpdir/seed" push -q origin "$SESSION_BRANCH"
  git worktree remove --force "$tmpdir/seed"; git branch -D -q "$SESSION_BRANCH"
fi
echo "  SESSION=$SESSION_BRANCH"

# ── 2) ko PR — #134 모양: ko 의 site-root → 운영 host 절대 URL ─────────────
if [[ -z "$KO_PR" ]]; then
  HEAD_BRANCH="translate-test-postmaintlinks/$TS"
  git fetch -q origin "$SESSION_BRANCH"
  git worktree add -q -b "$HEAD_BRANCH" "$tmpdir/head" "origin/$SESSION_BRANCH"
  cp "$FIX/ko-after/sample.md" "$tmpdir/head/ko/$DOC"
  git -C "$tmpdir/head" add ko
  git -C "$tmpdir/head" commit -q -m "e2e(post-maint-links): ko SDK 가이드 링크를 운영 host 절대 URL 로 ($TS)"
  git -C "$tmpdir/head" push -q origin "$HEAD_BRANCH"
  git worktree remove --force "$tmpdir/head"; git branch -D -q "$HEAD_BRANCH"
  e2e_ensure_label "$REPO"
  KO_PR="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
    --title "e2e(post-maint-links): ko 링크를 절대 URL 로 — Log-Crash-Search#134 모양 ($TS)" \
    --body "cloud-translate#1306 검증 입력. ko 의 SDK 가이드 링크 두 줄을 site-root → https://docs.nhncloud.com/ko/… 로 (+ 십시오→세요). en/ja 는 site-root 그대로." \
    --label "$E2E_LABEL")"
fi
echo "  KO_PR=$KO_PR"

# ── 3) 번역 — 로컬 translate_pr.py, CLI 엔진, 권장 preset, post-maint 켬 ─────
preset_eval="$(python3 "$SCRIPTS/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 2
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_POST_MAINT=true \
  TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$KO_PR" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") > "$LOG" 2>&1
tx_rc=$?
set -e
echo "  translate exit=$tx_rc · 로그 $LOG"
echo "  엔진: CLI 호출 $(grep -c 'with Claude Code CLI' "$LOG" || true) · api.anthropic.com $(grep -c 'api.anthropic.com' "$LOG" || true)"
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지"; tail -30 "$LOG"; exit 2; }
echo "  번역 PR: $tx_pr_url"
title="$(gh pr view "$tx_pr_url" --repo "$REPO" --json title --jq .title)"
[[ "$title" == "[$LABEL]"* ]] || gh pr edit "$tx_pr_url" --repo "$REPO" --title "[$LABEL] $title" >/dev/null
e2e_label_pr "$REPO" "$tx_pr_url" || true

# ── 4) 판정 ──────────────────────────────────────────────────────────────
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head" "$SESSION_BRANCH"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"
git worktree add -q --detach "$tmpdir/base" "origin/$SESSION_BRANCH"
echo
set +e
python3 "$SCRIPTS/check_post_maint_links.py" "$tmpdir/base" "$tmpdir/tx" "$DOC"
rc=$?
set -e
n_commit="$(git -C "$tmpdir/tx" log --oneline "origin/$SESSION_BRANCH..HEAD" | grep -c 'post-maint(fix-links)' || true)"
n_comment="$(gh pr view "$tx_pr_url" --repo "$REPO" --json comments \
  --jq '[.comments[].body | select(startswith("## 문서 정비 (번역 PR)")) | select(contains("링크 정정"))] | length')"
echo "  post-maint(fix-links) 커밋 $n_commit · '링크 정정' 이 든 정비 댓글 $n_comment"
echo "  SESSION=$SESSION_BRANCH KO_PR=$KO_PR TX_PR=$tx_pr_url"
exit $rc
