#!/usr/bin/env bash
#
# 새 문서 heading id e2e (cloud-translate#1364). ko PR 이 **새 문서**를 추가하면
# 번역 잡이 en/ja 를 통째로 번역하고 세 언어에 pre-align marker 를 찍는데 앵커
# 부여(`_assign_anchors`)는 건너뛴다 — h2~h4 heading 전부에 id 가 없는 채 "aligned"
# 로 남는다. 세 언어가 모두 id 없음으로 "일치" 해 번역 PR 본문은 "✅ 모두 일치",
# marker 가 유효해서 pre-align 도 다시 보지 않는다.
#   TOAST-DOCS/VPN-Gateway#15 → #16 (2026-10-20, 보정 커밋 f39e6fd)
#   TOAST-DOCS/Network-ACL#14 → #15 (2026-10-22 리뷰, 보정 커밋 5056547)
#
# 픽스처 archive/new-doc-anchors/:
#   ko-new/new-doc-anchors.md  ko PR 이 새로 추가하는 문서 — Network-ACL#14 의
#                              release-notes.md 와 같은 모양 (h2 1 · h3 3 · h4 3, id 없음)
#   {ko,en,ja}/control.md      대조군 — 이미 정렬된 기존 문서 (pre-align 이 id 와 marker 를
#                              찍은 상태). 세션 base 에 new-doc-anchors-control.md 로 심는다
#   ko-after/control.md        대조군의 ko 변경 — 본문 한 줄만. heading id 는 base 그대로여야 한다
#
# 판정 scripts/check_new_doc_anchors.py (모델 없음, cloud-translate 의
# merged_review.heading_id_verdict 와 같은 판정 — align_headings.parse_units 를 import):
#   [B] 새 문서의 ko/en/ja h2~h4 전부 id 있음 · [C] (level, id) outline ko == en == ja ·
#   [D] ko heading 텍스트 불변 · [E] 대조군 outline 이 base 와 같음
# 기대: #1364 이전 코드 → REPRO (exit 3, [B] 세 언어 7/7 id 없음) · 이후 → OK (exit 0).
#
# BEFORE/AFTER 는 같은 입력에 코드만 바꿔 두 번 돈다:
#   scripts/e2e-new-doc-anchors.sh --label BEFORE --cloud-translate-dir <main 체크아웃>
#     → 출력의 SESSION/KO_PR 을 그대로 넘겨
#   scripts/e2e-new-doc-anchors.sh --label AFTER --cloud-translate-dir <#1364 체크아웃> \
#       --base-branch <SESSION> --ko-pr <KO_PR>
# 번역 없이 이미 있는 번역 PR 만 다시 판정: --base-branch <SESSION> --tx-pr <URL>
#
# 엔진은 언제나 Claude Code CLI (권장 preset + e2e 비용 override, 다른 e2e 와 같다).
# 공유 체크아웃의 HEAD 는 건드리지 않는다 — 커밋은 임시 worktree 에서만 한다.
# 산출물(PR·브랜치)은 증거라 기본으로 남긴다 (--cleanup 으로 정리).
# 지금 파이프라인이 못 잡는 결함을 심은 것이라 #1364 머지 전에는 REPRO 가 정상 —
# e2e-suite.sh 의 all 에는 넣지 않는다.
#
# exit: 0 OK · 3 REPRO · 2 인프라 · 1 사용법
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
TS="$(date -u +%Y%m%d-%H%M%S)"
LABEL="AFTER"
SESSION_BRANCH=""
KO_PR=""
TX_PR=""
CLEANUP=0
NEW_DOC="new-doc-anchors.md"
CONTROL_DOC="new-doc-anchors-control.md"

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)               LABEL="$2"; shift 2 ;;
    --base-branch)         SESSION_BRANCH="$2"; shift 2 ;;
    --ko-pr)               KO_PR="$2"; shift 2 ;;
    --tx-pr)               TX_PR="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --cleanup)             CLEANUP=1; shift ;;
    -h|--help) sed -n '2,41p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
if [[ -n "$TX_PR" && -z "$SESSION_BRANCH" ]]; then
  echo "error: --tx-pr 는 --base-branch 와 함께 쓴다" >&2; exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
FIX="$REPO_ROOT/archive/new-doc-anchors"
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

echo "=== new-doc-anchors e2e [$LABEL] ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 | cut -c1-70))"

# ── 1) 세션 base — 대조군(정렬된 기존 문서)만 alpha 위에 심는다 ────────────
if [[ -z "$SESSION_BRANCH" ]]; then
  SESSION_BRANCH="e2e-newdocanchor/$TS"
  git fetch -q origin alpha
  git worktree add -q -b "$SESSION_BRANCH" "$tmpdir/seed" origin/alpha
  for l in ko en ja; do cp "$FIX/$l/control.md" "$tmpdir/seed/$l/$CONTROL_DOC"; done
  git -C "$tmpdir/seed" add ko en ja
  git -C "$tmpdir/seed" commit -q -m "e2e(new-doc-anchors): 대조군 시드 ($TS)"
  git -C "$tmpdir/seed" push -q origin "$SESSION_BRANCH"
  git worktree remove --force "$tmpdir/seed"; git branch -D -q "$SESSION_BRANCH"
fi
echo "  SESSION=$SESSION_BRANCH"

if [[ -z "$TX_PR" ]]; then
  # ── 2) ko PR — 새 문서 추가 + 대조군 본문 한 줄 ─────────────────────────
  if [[ -z "$KO_PR" ]]; then
    HEAD_BRANCH="translate-test-newdocanchor/$TS"
    git fetch -q origin "$SESSION_BRANCH"
    git worktree add -q -b "$HEAD_BRANCH" "$tmpdir/head" "origin/$SESSION_BRANCH"
    cp "$FIX/ko-new/$NEW_DOC" "$tmpdir/head/ko/$NEW_DOC"
    cp "$FIX/ko-after/control.md" "$tmpdir/head/ko/$CONTROL_DOC"
    git -C "$tmpdir/head" add ko
    git -C "$tmpdir/head" commit -q -m "e2e(new-doc-anchors): 새 문서 추가 + 대조군 본문 수정 ($TS)"
    git -C "$tmpdir/head" push -q origin "$HEAD_BRANCH"
    git worktree remove --force "$tmpdir/head"; git branch -D -q "$HEAD_BRANCH"
    e2e_ensure_label "$REPO"
    KO_PR="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
      --title "e2e(new-doc-anchors): 새 문서 heading id ($TS)" \
      --body "cloud-translate#1364 검증 입력. 새 문서 ko/$NEW_DOC (Network-ACL#14 의 release-notes.md 모양, heading id 없음) + 대조군 ko/$CONTROL_DOC 본문 한 줄 수정." \
      --label "$E2E_LABEL")"
  fi
  echo "  KO_PR=$KO_PR"

  # ── 3) 번역 — 로컬 translate_pr.py, CLI 엔진, 권장 preset ────────────────
  preset_eval="$(python3 "$SCRIPTS/preset_options.py" \
    --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
    --engine claude-code --model claude-haiku-4-5 \
    --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 2
  eval "$preset_eval"
  echo "  translate argv: ${PRESET_ARGS[*]}"
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$KO_PR" \
      --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") > "$LOG" 2>&1
  tx_rc=$?
  set -e
  echo "  translate exit=$tx_rc · 로그 $LOG"
  echo "  엔진: CLI 호출 $(grep -c 'with Claude Code CLI' "$LOG" || true) · api.anthropic.com $(grep -c 'api.anthropic.com' "$LOG" || true)"
  tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
  [[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지"; tail -30 "$LOG"; exit 2; }
  title="$(gh pr view "$tx_pr_url" --repo "$REPO" --json title --jq .title)"
  [[ "$title" == "[$LABEL]"* ]] || gh pr edit "$tx_pr_url" --repo "$REPO" --title "[$LABEL] $title" >/dev/null
  e2e_label_pr "$REPO" "$tx_pr_url" || true
else
  tx_pr_url="$TX_PR"
fi
echo "  번역 PR: $tx_pr_url"

# ── 4) 판정 ──────────────────────────────────────────────────────────────
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head" "$SESSION_BRANCH"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"
git worktree add -q --detach "$tmpdir/base" "origin/$SESSION_BRANCH"
echo
set +e
CLOUD_TRANSLATE_DIR="$CLOUD_TRANSLATE_DIR" "$CLOUD_TRANSLATE_PY" "$SCRIPTS/check_new_doc_anchors.py" \
  --base "$tmpdir/base" --head "$tmpdir/tx" \
  --new "$NEW_DOC" --ko-src "$FIX/ko-new/$NEW_DOC" --control "$CONTROL_DOC"
rc=$?
set -e
echo "  SESSION=$SESSION_BRANCH KO_PR=$KO_PR TX_PR=$tx_pr_url"
exit $rc
