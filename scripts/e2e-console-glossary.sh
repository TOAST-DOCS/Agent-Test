#!/usr/bin/env bash
#
# 콘솔 용어집 e2e (cloud-translate — Dooray cloud-user-guide-agent/584).
# 리포의 `.docs-workflow` 에 `console_glossary` 를 적으면, 번역이 ko 문서가 **굵게** 쓴
# 콘솔 라벨을 콘솔 자신의 문자열로 옮기는지 — 사용자 가이드 용어집보다 앞서서.
#
# 픽스처 archive/console-glossary/:
#   console/messages.json          다국어 DB 카탈로그 모양 ({type: {id: {koKr, enUs, jaJp}}}).
#                                  Cloud-Scheduler#51 에서 작성자가 다시 요청한 실제 문자열 넷,
#                                  같은 ko 에 en 이 둘(`발송 기준`), 필수 용어집과 충돌하는
#                                  `상세 정보`, 문서가 굵게 쓰지 않는 `설정`.
#   console/{ko,en,ja}_lang.ts     서비스가 직접 관리하는 언어별 파일 (Data-Flow epsilon 모양 —
#                                  따옴표 없는 키 · 템플릿 리터럴 · 문자열 + 연결). `지연 허용 시간`.
#   ko-after/console-glossary-sample.md    ko PR 이 **새로 더하는** 문서 (신규 파일 경로)
#   {ko,en,ja}/console-glossary-existing.md + ko-after/…  기존 문서에 절 하나 추가 (증분 경로)
#
# 세션 base 에 console/ 를 `console-glossary/` 로 심고, 그 커밋 SHA 로 고정한 blob URL 을
# `.docs-workflow` 에 적는다 (`messages:` 하나 + `ko/en/ja:` 하나 — 두 소스 모양 모두).
#
# 판정 scripts/check_console_glossary.py (모델 없음) — [A] 프롬프트 선택 · [B] 번역 산출물.
# exit 0 OK · 3 REPRO.
#
# BEFORE/AFTER 는 같은 입력에 코드만 바꿔 두 번 돈다:
#   scripts/e2e-console-glossary.sh --label BEFORE --cloud-translate-dir <main 체크아웃>
#     → 출력의 SESSION/KO_PR 을 그대로 넘겨
#   scripts/e2e-console-glossary.sh --label AFTER --cloud-translate-dir <PR 체크아웃> \
#       --base-branch <SESSION> --ko-pr <KO_PR>
#
# --run-dir: translate_pr.py 를 돌릴 cwd (`.env` · 용어집 · 가이드라인을 읽는 자리, 기본 =
#   --cloud-translate-dir). 워크트리처럼 `.env` 가 없는 체크아웃의 **코드**를 돌릴 때 메인
#   체크아웃을 주면 된다 — BEFORE/AFTER 가 같은 run-dir 를 쓰면 코드만 다르다.
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

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"
RUN_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)               LABEL="$2"; shift 2 ;;
    --base-branch)         SESSION_BRANCH="$2"; shift 2 ;;
    --ko-pr)               KO_PR="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --run-dir)             RUN_DIR="$2"; shift 2 ;;
    --cleanup)             CLEANUP=1; shift ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

RUN_DIR="${RUN_DIR:-$CLOUD_TRANSLATE_DIR}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
FIX="$REPO_ROOT/archive/console-glossary"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"
source "$SCRIPTS/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/seed" "$tmpdir/head" "$tmpdir/base" "$tmpdir/tx" "$tmpdir/ko"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( CLEANUP )); then
    [[ -n "${tx_pr_url:-}" ]] && gh pr close "$tx_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  fi
  return $rc
}
trap cleanup EXIT

echo "=== console-glossary e2e [$LABEL] ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 | cut -c1-70))"
echo "  run-dir         : $RUN_DIR"

# ── 1) 세션 base — 콘솔 파일 → 그 SHA 로 .docs-workflow ─────────────────────
if [[ -z "$SESSION_BRANCH" ]]; then
  SESSION_BRANCH="e2e-consolegloss/$TS"
  git fetch -q origin alpha
  git worktree add -q -b "$SESSION_BRANCH" "$tmpdir/seed" origin/alpha
  mkdir -p "$tmpdir/seed/console-glossary"
  cp "$FIX"/console/* "$tmpdir/seed/console-glossary/"
  for l in ko en ja; do cp "$FIX/$l/console-glossary-existing.md" "$tmpdir/seed/$l/"; done
  git -C "$tmpdir/seed" add console-glossary ko en ja
  git -C "$tmpdir/seed" commit -q -m "e2e(console-glossary): 콘솔 문자열 + 기존 문서 시드 ($TS)"
  sha="$(git -C "$tmpdir/seed" rev-parse HEAD)"
  u="https://github.com/$REPO/blob/$sha/console-glossary"
  cat > "$tmpdir/seed/.docs-workflow" <<EOF
# e2e(console-glossary) — 세션 브랜치에만 있다. URL 은 시드 커밋 SHA 로 고정.
console_glossary:
  - messages: $u/messages.json
  - ko: $u/ko_lang.ts
    en: $u/en_lang.ts
    ja: $u/ja_lang.ts
EOF
  git -C "$tmpdir/seed" add .docs-workflow
  git -C "$tmpdir/seed" commit -q -m "e2e(console-glossary): .docs-workflow console_glossary ($TS)"
  git -C "$tmpdir/seed" push -q origin "$SESSION_BRANCH"
  git worktree remove --force "$tmpdir/seed"; git branch -D -q "$SESSION_BRANCH"
fi
echo "  SESSION=$SESSION_BRANCH"

# ── 2) ko PR — 새 문서 + 기존 문서에 절 하나 ────────────────────────────────
if [[ -z "$KO_PR" ]]; then
  HEAD_BRANCH="translate-test-consolegloss/$TS"
  git fetch -q origin "$SESSION_BRANCH"
  git worktree add -q -b "$HEAD_BRANCH" "$tmpdir/head" "origin/$SESSION_BRANCH"
  cp "$FIX"/ko-after/*.md "$tmpdir/head/ko/"
  git -C "$tmpdir/head" add ko
  git -C "$tmpdir/head" commit -q -m "e2e(console-glossary): 콘솔 라벨을 굵게 쓴 문서 · 절 ($TS)"
  git -C "$tmpdir/head" push -q origin "$HEAD_BRANCH"
  git worktree remove --force "$tmpdir/head"; git branch -D -q "$HEAD_BRANCH"
  e2e_ensure_label "$REPO"
  KO_PR="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
    --title "e2e(console-glossary): 콘솔 라벨 번역 ($TS)" \
    --body "cloud-user-guide-agent/584 검증 입력. 굵게 쓴 콘솔 라벨(값 하나 · 둘 · 필수 용어집 충돌), 굵게 한 번 + 표·산문, 대조군(산문 '다음 중'), 기존 문서의 새 절." \
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
(cd "$RUN_DIR" && \
  TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
  "$CLOUD_TRANSLATE_PY" "$CLOUD_TRANSLATE_DIR/translate/translate_pr.py" "$KO_PR" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") > "$LOG" 2>&1
tx_rc=$?
set -e
echo "  translate exit=$tx_rc · 로그 $LOG"
echo "  엔진: CLI 호출 $(grep -c 'with Claude Code CLI' "$LOG" || true) · api.anthropic.com $(grep -c 'api.anthropic.com' "$LOG" || true)"
echo "  $(grep -m1 'Console glossary:' "$LOG" || echo 'Console glossary: (로그 없음 — 이 코드는 읽지 않는다)')"
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
ko_head="$(gh pr view "$KO_PR" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$ko_head"
git worktree add -q --detach "$tmpdir/ko" "origin/$ko_head"
echo
set +e
"$CLOUD_TRANSLATE_PY" "$SCRIPTS/check_console_glossary.py" "$tmpdir/base" "$tmpdir/tx" \
  --ko-dir "$tmpdir/ko" --ct-dir "$CLOUD_TRANSLATE_DIR"
rc=$?
set -e
echo "  SESSION=$SESSION_BRANCH KO_PR=$KO_PR TX_PR=$tx_pr_url"
exit $rc
