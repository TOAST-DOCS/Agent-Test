#!/usr/bin/env bash
#
# 릴리스 노트 날짜 헤딩 · `버전 (날짜)` 헤딩 e2e (cloud-translate#1301,
# Dooray cloud-user-guide-agent/546 — TOAST-DOCS/Gamebase#434 에서 en 헤딩
# `### 2.83.0 (2026. 10. 13.)` 이 `### October 13, 2026` 으로 나와 버전이 사라졌다).
#
# 픽스처 archive/date-headings/ — 세 실제 릴리스 노트의 앞부분 (base 그대로):
#   gamebase   Gamebase ko/en/ja release-notes-unity.md @ #433 의 base (2f25985c).
#              ko 변경 = #433 의 2.83.0 절 그대로 (사고 입력 재생). en 기존 헤딩은 점 형식.
#   cloudtrail CloudTrail release-notes.md — 날짜만 있는 헤딩, en 기존 헤딩도 점 형식.
#              ko 변경 = 새 날짜 절 `### 2026. 10. 14.`
#   sdk        NHNCloud-SDK release-notes-ios.md — ko 는 `1.10.0(2026. 09. 15.)` 처럼
#              괄호 앞을 붙여 쓰고 en 은 `1.10.0 (September 15, 2026)`.
#              ko 변경 = 새 버전 절 `## 1.11.0(2026. 10. 14.)`
#   대조군     세 문서 모두 기존 절의 **본문만** 한 줄 고친다 — 그 절의 헤딩(및 모든
#              기존 헤딩)은 en/ja 가 base 와 바이트 동일해야 한다.
#
# 판정 scripts/check_date_headings.py (모델 없음) — exit 0 OK · 3 REPRO.
#
# BEFORE/AFTER 는 같은 입력에 코드만 바꿔 두 번 돈다:
#   scripts/e2e-date-headings.sh --label BEFORE --cloud-translate-dir <main 체크아웃>
#     → 출력의 SESSION/KO_PR 을 그대로 넘겨
#   scripts/e2e-date-headings.sh --label AFTER --cloud-translate-dir <PR 체크아웃> \
#       --base-branch <SESSION> --ko-pr <KO_PR>
#
# 엔진은 언제나 Claude Code CLI (권장 preset + e2e 비용 override, 다른 e2e 와 같다).
# 공유 체크아웃의 HEAD 는 건드리지 않는다 — 커밋은 임시 worktree 에서만 한다.
# 산출물(PR·브랜치)은 증거라 기본으로 남긴다 (--cleanup 으로 정리).
#
# exit: 0 OK · 3 REPRO · 2 인프라 · 1 사용법
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
TS="$(date -u +%Y%m%d-%H%M%S)"
LABEL="AFTER"
SESSION_BRANCH=""
KO_PR=""
CLEANUP=0
DOCS=(gamebase cloudtrail sdk)

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
    -h|--help) sed -n '2,33p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
FIX="$REPO_ROOT/archive/date-headings"
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

echo "=== date-headings e2e [$LABEL] ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 | cut -c1-70))"

# ── 1) 세션 base — 픽스처를 alpha 위에 심는다 ─────────────────────────────
if [[ -z "$SESSION_BRANCH" ]]; then
  SESSION_BRANCH="e2e-dateheading/$TS"
  git fetch -q origin alpha
  git worktree add -q -b "$SESSION_BRANCH" "$tmpdir/seed" origin/alpha
  for d in "${DOCS[@]}"; do
    for l in ko en ja; do cp "$FIX/$l/$d.md" "$tmpdir/seed/$l/date-headings-$d.md"; done
  done
  git -C "$tmpdir/seed" add ko en ja
  git -C "$tmpdir/seed" commit -q -m "e2e(date-headings): 픽스처 시드 ($TS)"
  git -C "$tmpdir/seed" push -q origin "$SESSION_BRANCH"
  git worktree remove --force "$tmpdir/seed"; git branch -D -q "$SESSION_BRANCH"
fi
echo "  SESSION=$SESSION_BRANCH"

# ── 2) ko PR — 새 날짜 절 + 대조군 본문 수정 ──────────────────────────────
if [[ -z "$KO_PR" ]]; then
  HEAD_BRANCH="translate-test-dateheading/$TS"
  git fetch -q origin "$SESSION_BRANCH"
  git worktree add -q -b "$HEAD_BRANCH" "$tmpdir/head" "origin/$SESSION_BRANCH"
  for d in "${DOCS[@]}"; do cp "$FIX/ko-after/$d.md" "$tmpdir/head/ko/date-headings-$d.md"; done
  git -C "$tmpdir/head" add ko
  git -C "$tmpdir/head" commit -q -m "e2e(date-headings): 새 릴리스 절 + 대조군 본문 수정 ($TS)"
  git -C "$tmpdir/head" push -q origin "$HEAD_BRANCH"
  git worktree remove --force "$tmpdir/head"; git branch -D -q "$HEAD_BRANCH"
  e2e_ensure_label "$REPO"
  KO_PR="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
    --title "e2e(date-headings): 릴리스 노트 날짜·버전 헤딩 ($TS)" \
    --body "cloud-translate#1301 검증 입력. Gamebase#433 의 2.83.0 절 그대로 + 날짜만 있는 절 + 괄호 붙은 버전 절, 대조군으로 기존 절 본문 한 줄씩 수정." \
    --label "$E2E_LABEL")"
fi
echo "  KO_PR=$KO_PR"

# ── 3) 번역 — 로컬 translate_pr.py, CLI 엔진, 권장 preset ──────────────────
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
docs=(); for d in "${DOCS[@]}"; do docs+=("date-headings-$d.md"); done
set +e
python3 "$SCRIPTS/check_date_headings.py" "$tmpdir/base" "$tmpdir/tx" "${docs[@]}"
rc=$?
set -e
echo "  SESSION=$SESSION_BRANCH KO_PR=$KO_PR TX_PR=$tx_pr_url"
exit $rc
