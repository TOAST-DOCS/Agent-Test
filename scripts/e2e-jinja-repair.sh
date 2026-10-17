#!/usr/bin/env bash
#
# Jinja 문법 오류 복원 e2e (cloud-translate — `jinja_check.cli --fix`, Dooray
# cloud-user-guide-agent/573: 정비에서 확실한 것은 PR 에, 확실하지 않은 것은 별도
# 검토 PR 로).
#
# 픽스처 archive/jinja-repair/{ko,en,ja}/ — 정상 문서 둘(sample · control). 세션 브랜치에
# scripts/check_jinja_repair.py seed 가 결함을 심은 네 문서를 만든다:
#   sample   en 닫는 태그 유실 · ja `{% end if %}`   → 확실한 수정 (결정적 PR)
#   opener   en 여는 태그 유실                      → ko 의 여는 태그를 되넣는다
#   author   ko·en·ja 닫는 태그 유실 (저자 실수 복사) → 개발자 검토 PR (ko 는 모델이 고르고
#            en/ja 는 그 ko 를 따른다)
#   control  정상 (대조군) — 어느 PR 에도 들어가면 안 된다
#
# 판정 scripts/check_jinja_repair.py verify (모델 없음): PR 둘의 파일 · 라벨 · 바이트 ·
# 본문 줄 불변 · en/ja 자리 = ko 자리 · 인라인 코멘트.
#
# BEFORE/AFTER 는 같은 세션 브랜치에 코드만 바꿔 두 번:
#   scripts/e2e-jinja-repair.sh --label BEFORE --cloud-translate-dir <main 체크아웃>
#   scripts/e2e-jinja-repair.sh --label AFTER  --cloud-translate-dir <PR 체크아웃> --base-branch <SESSION>
# BEFORE 코드에는 --fix 가 없으므로 판정만 돌린다 (수정 PR 0 개가 기대값).
#
# 엔진은 언제나 Claude Code CLI. 리뷰어 자동 요청은 끈다 (TRANSLATE_PR_REVIEWERS_FROM_STORE=false).
# 공유 체크아웃의 HEAD 는 건드리지 않는다 — 커밋은 임시 worktree 에서만 한다.
#
# exit: 0 OK · 3 FAIL · 2 인프라 · 1 사용법
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
TS="$(date -u +%Y%m%d-%H%M%S)"
LABEL="AFTER"
SESSION_BRANCH=""
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="$2"; shift 2 ;;
    --base-branch) SESSION_BRANCH="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[[ "$LABEL" == BEFORE || "$LABEL" == AFTER ]] || { echo "--label BEFORE|AFTER" >&2; exit 1; }
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
tmpdir="$(mktemp -d)"
cleanup() {
  for wt in "$tmpdir/seed"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  rm -rf "$tmpdir"
}
trap cleanup EXIT

echo "== e2e jinja-repair [$LABEL] =="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 | cut -c1-70))"
git fetch -q origin alpha
if [[ -z "$SESSION_BRANCH" ]]; then
  SESSION_BRANCH="e2e-jinjarepair/$TS"
  git worktree add -q -b "$SESSION_BRANCH" "$tmpdir/seed" origin/alpha
  # 픽스처는 이 스크립트와 같은 커밋에서 온다 (alpha 에 아직 없을 수 있다).
  cp -r "$ROOT/archive/jinja-repair" "$tmpdir/seed/archive/" 2>/dev/null || true
  python3 scripts/check_jinja_repair.py seed "$tmpdir/seed" >/dev/null
  git -C "$tmpdir/seed" add ko en ja archive/jinja-repair
  git -C "$tmpdir/seed" commit -q -m "e2e(jinja-repair): 결함 시드 ($TS)"
  git -C "$tmpdir/seed" push -q origin "$SESSION_BRANCH"
  git worktree remove --force "$tmpdir/seed"; git branch -D -q "$SESSION_BRANCH"
  echo "  세션 브랜치     : $SESSION_BRANCH (새로 만듦)"
else
  echo "  세션 브랜치     : $SESSION_BRANCH (재사용)"
fi

PATHS=""
for l in ko en ja; do
  for d in sample opener author control; do
    PATHS+="${PATHS:+,}$l/jinja-repair-$d.md"
  done
done

LOG="$tmpdir/cli.log"
OUT="${E2E_OUT_DIR:-$HOME/works/temp/e2e-jinja-repair-$TS-$LABEL}"
mkdir -p "$OUT"
ARGS=("https://github.com/$REPO" --base "$SESSION_BRANCH" --paths "$PATHS" --out "$OUT")
if [[ "$LABEL" == AFTER ]]; then
  ARGS+=(--fix --engine claude-code --branch "jinja-fix-e2e-$TS")
fi
set +e
( cd "$CLOUD_TRANSLATE_DIR" && \
  TRANSLATE_PR_REVIEWERS_FROM_STORE=false TRANSLATE_TRANSLATE_ENGINE=claude-code \
  PYTHONPATH="$CLOUD_TRANSLATE_DIR/dashboard:$CLOUD_TRANSLATE_DIR" \
  "$CLOUD_TRANSLATE_PY" -m jinja_check.cli "${ARGS[@]}" ) 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
set -e
cp "$LOG" "$OUT/cli.log"
echo "  cli exit        : $rc (결함이 남아 있으면 1 이 정상)"
echo "  보고서          : $OUT/REPORT.md"

python3 scripts/check_jinja_repair.py verify --log "$LOG" --label "$LABEL" --root "$ROOT"
