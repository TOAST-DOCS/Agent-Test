#!/usr/bin/env bash
#
# 콘솔 용어집 — 정비 도구 · 한글 검수 e2e (cloud-user-guide-agent/584 후속).
# 번역(e2e-console-glossary.sh) 밖의 네 도구가 리포의 `.docs-workflow` console_glossary 를
# 따르는지:
#
#   fill    빈 번역 채우기 (translate_fill_stubs.py) — 굵게가 없는 절을 채워도, 문서가 굵게
#           쓴 콘솔 낱말이면 콘솔 문자열로 (도구가 ko 문서 전체를 판정 근거로 넘긴다)
#   hangul  한글 잔존 (translate_fix_hangul.py) — 남은 `**실패 사유 포함**` 을 콘솔 문자열로
#   tables  깨진 표 정비 (translate_fix_tables.py) — 빠진 행의 설명 칸을 콘솔 문자열로
#   review  한글 검수 (korean-review/review_pr.py --dry-run) — 콘솔 라벨을 고치라는 지적
#           (564 모양: 규칙 레이어의 `Log&Crash` → `Log & Crash Search`)이 사라지고, 대조군
#           줄은 그대로 지적된다
#
# 픽스처 archive/console-glossary/tools/ + 콘솔 문자열 archive/console-glossary/console/.
# 세션 base 에 콘솔 파일 → 그 SHA 로 고정한 `.docs-workflow` → 세 도구의 ko/en/ja 문서를
# 심는다. review 는 ko PR(`ko/console-glossary-review.md` 추가)을 하나 연다.
# 판정 scripts/check_console_glossary_tools.py (모델 없음).
#
# BEFORE/AFTER 는 같은 세션에 코드만 바꿔 두 번:
#   scripts/e2e-console-glossary-tools.sh --label BEFORE --cloud-translate-dir <main> --run-dir <.env 체크아웃>
#     → 출력의 SESSION/KO_PR 을 넘겨
#   scripts/e2e-console-glossary-tools.sh --label AFTER --cloud-translate-dir <PR> --run-dir <…> \
#       --base-branch <SESSION> --ko-pr <KO_PR>
#
# 엔진은 언제나 Claude Code CLI (haiku). 정비 도구는 세션 base 로 PR 을 연다 — 제목에
# [BEFORE]/[AFTER] 를 붙인다. 커밋은 임시 worktree 에서만 한다.
#
# 판정은 두 층 — [A] 프롬프트(결정적) · [B] 산출물(굵게인 자리 hard, 아닌 자리 WARN). 이유는
# check_console_glossary_tools.py 머리말.
#
# exit: 0 전부 OK · 3 하나라도 REPRO · 2 인프라 · 1 사용법
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
TS="$(date -u +%Y%m%d-%H%M%S)"
LABEL="AFTER"
SESSION_BRANCH=""
KO_PR=""
TOOLS="fill hangul tables review"
MODEL="claude-haiku-4-5"

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
RUN_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)               LABEL="$2"; shift 2 ;;
    --base-branch)         SESSION_BRANCH="$2"; shift 2 ;;
    --ko-pr)               KO_PR="$2"; shift 2 ;;
    --tools)               TOOLS="${2//,/ }"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --run-dir)             RUN_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,31p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

RUN_DIR="${RUN_DIR:-$CLOUD_TRANSLATE_DIR}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
CON="$REPO_ROOT/archive/console-glossary/console"
FIX="$REPO_ROOT/archive/console-glossary/tools"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
source "$SCRIPTS/e2e-label.sh"
DOCS=(fill hangul tables)

cleanup() {
  local rc=$?
  for wt in "$tmpdir"/wt-*; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  return $rc
}
trap cleanup EXIT

echo "=== console-glossary tools e2e [$LABEL] ($TOOLS) ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 | cut -c1-70))"
echo "  run-dir         : $RUN_DIR"

# ── 1) 세션 base ─────────────────────────────────────────────────────────
if [[ -z "$SESSION_BRANCH" ]]; then
  SESSION_BRANCH="e2e-consolegloss-tools/$TS"
  git fetch -q origin alpha
  git worktree add -q -b "$SESSION_BRANCH" "$tmpdir/wt-seed" origin/alpha
  mkdir -p "$tmpdir/wt-seed/console-glossary"
  cp "$CON"/* "$tmpdir/wt-seed/console-glossary/"
  git -C "$tmpdir/wt-seed" add console-glossary
  git -C "$tmpdir/wt-seed" commit -q -m "e2e(console-glossary-tools): 콘솔 문자열 시드 ($TS)"
  sha="$(git -C "$tmpdir/wt-seed" rev-parse HEAD)"
  u="https://github.com/$REPO/blob/$sha/console-glossary"
  cat > "$tmpdir/wt-seed/.docs-workflow" <<EOF
# e2e(console-glossary-tools) — 세션 브랜치에만 있다. URL 은 시드 커밋 SHA 로 고정.
console_glossary:
  - messages: $u/messages.json
  - ko: $u/ko_lang.ts
    en: $u/en_lang.ts
    ja: $u/ja_lang.ts
EOF
  for d in "${DOCS[@]}"; do
    for l in ko en ja; do cp "$FIX/$l/console-glossary-$d.md" "$tmpdir/wt-seed/$l/"; done
  done
  git -C "$tmpdir/wt-seed" add .docs-workflow ko en ja
  git -C "$tmpdir/wt-seed" commit -q -m "e2e(console-glossary-tools): .docs-workflow + 도구 픽스처 ($TS)"
  git -C "$tmpdir/wt-seed" push -q origin "$SESSION_BRANCH"
  git worktree remove --force "$tmpdir/wt-seed"; git branch -D -q "$SESSION_BRANCH"
fi
echo "  SESSION=$SESSION_BRANCH"
git fetch -q origin "$SESSION_BRANCH"
git worktree add -q --detach "$tmpdir/wt-base" "origin/$SESSION_BRANCH"

run_ct() {   # $1 log, rest: script + args — CLI 엔진 · haiku
  local log="$1"; shift
  set +e
  (cd "$RUN_DIR" && TRANSLATE_TRANSLATE_ENGINE=claude-code \
     TRANSLATE_CLAUDE_CODE_MODEL="$MODEL" TRANSLATE_PROBLEM_REVIEWERS='["hyunil-shin"]' \
     "$CLOUD_TRANSLATE_PY" "$@") > "$log" 2>&1
  local rc=$?
  set -e
  echo "    exit=$rc · 로그 $log · api.anthropic.com $(grep -c 'api.anthropic.com' "$log" || true)"
  echo "    $(grep -m1 -E 'Console glossary|console labels \(' "$log" || echo 'Console glossary: (로그 없음 — 이 코드는 읽지 않는다)')"
}

overall=0
declare -A VERDICT

for tool in $TOOLS; do
  echo
  echo "── $tool"
  if [[ "$tool" == "review" ]]; then
    if [[ -z "$KO_PR" ]]; then
      HEAD_BRANCH="translate-test-consolegloss-review/$TS"
      git worktree add -q -b "$HEAD_BRANCH" "$tmpdir/wt-head" "origin/$SESSION_BRANCH"
      cp "$FIX/ko-review/console-glossary-review.md" "$tmpdir/wt-head/ko/"
      git -C "$tmpdir/wt-head" add ko
      git -C "$tmpdir/wt-head" commit -q -m "e2e(console-glossary-tools): 콘솔 라벨을 굵게 쓴 문서 ($TS)"
      git -C "$tmpdir/wt-head" push -q origin "$HEAD_BRANCH"
      git worktree remove --force "$tmpdir/wt-head"; git branch -D -q "$HEAD_BRANCH"
      e2e_ensure_label "$REPO"
      KO_PR="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
        --title "e2e(console-glossary-tools): 한글 검수 입력 ($TS)" \
        --body "cloud-user-guide-agent/584 검증 입력 — 굵게 쓴 콘솔 라벨 \`(NHN Cloud) Log&Crash Search\` · \`최대재시도횟수\` + 대조군 줄 둘." \
        --label "$E2E_LABEL")"
    fi
    echo "  KO_PR=$KO_PR"
    log="$tmpdir/review.log"
    run_ct "$log" "$CLOUD_TRANSLATE_DIR/korean-review/review_pr.py" "$KO_PR" --dry-run
    set +e
    python3 "$SCRIPTS/check_console_glossary_tools.py" review "$log"
    rc=$?
    set -e
  else
    case "$tool" in
      fill)   script=translate/translate_fill_stubs.py ;;
      hangul) script=translate/translate_fix_hangul.py ;;
      tables) script=translate/translate_fix_tables.py ;;
      *) echo "unknown tool: $tool" >&2; exit 1 ;;
    esac
    only="en/console-glossary-$tool.md,ja/console-glossary-$tool.md"
    log="$tmpdir/$tool.log"
    # [A] 증거 — CLI 엔진은 조각마다 용어집을 run-dir 의 glossary_*.md 로 쓴다. 이 실행이
    # 쓴 것만 모은다 (gitignore 대상 · 다른 실행의 파일은 marker 보다 오래됐다).
    marker="$tmpdir/$tool.start"; touch "$marker"; sleep 1
    run_ct "$log" "$CLOUD_TRANSLATE_DIR/$script" "$REPO" "$SESSION_BRANCH" --only "$only" --workers 2
    mkdir -p "$tmpdir/prompts-$tool"
    find "$RUN_DIR" -maxdepth 1 -name 'glossary_*.md' -newer "$marker" \
      -exec cp {} "$tmpdir/prompts-$tool/" \;
    pr_url="$(grep -oE "https://github.com/$REPO/pull/[0-9]+" "$log" | tail -1 || true)"
    if [[ -z "$pr_url" ]]; then
      echo "  error: $tool PR 미감지"; tail -20 "$log"; VERDICT[$tool]="infra"; overall=2; continue
    fi
    echo "  PR: $pr_url"
    title="$(gh pr view "$pr_url" --repo "$REPO" --json title --jq .title)"
    [[ "$title" == "[$LABEL]"* ]] || gh pr edit "$pr_url" --repo "$REPO" --title "[$LABEL] $title" >/dev/null
    e2e_label_pr "$REPO" "$pr_url" || true
    head="$(gh pr view "$pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
    git fetch -q origin "$head"
    git worktree add -q --detach "$tmpdir/wt-$tool" "origin/$head"
    set +e
    python3 "$SCRIPTS/check_console_glossary_tools.py" "$tool" "$tmpdir/wt-base" "$tmpdir/wt-$tool" \
      "$tmpdir/prompts-$tool"
    rc=$?
    set -e
    VERDICT[${tool}_pr]="$pr_url"
  fi
  case $rc in
    0) VERDICT[$tool]="OK" ;;
    3) VERDICT[$tool]="REPRO"; (( overall == 2 )) || overall=3 ;;
    *) VERDICT[$tool]="infra($rc)"; overall=2 ;;
  esac
done

echo
echo "=== 요약 [$LABEL] ==="
for tool in $TOOLS; do
  echo "  $tool: ${VERDICT[$tool]:-?} ${VERDICT[${tool}_pr]:-}"
done
echo "  SESSION=$SESSION_BRANCH KO_PR=${KO_PR:-}"
exit $overall
