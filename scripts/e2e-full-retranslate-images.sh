#!/usr/bin/env bash
#
# 전체 재번역의 이미지 링크 유지 e2e — cloud-translate translate_file.py 검증.
#
# 결함 (Dooray cloud-user-guide-agent/536): 대시보드 '전체 재번역'
# (translate_file.py, --diff 없음)은 문서의 이미지 줄 전부를 모델에 보내고 모델은
# ko 의 URL 을 그대로 옮겨 온다. 번역본이 쓰던 언어별 스크린샷(`_EN.png`, `…/en/…`)
# 이나 따로 고른 이미지가 전부 ko 이미지로 덮인다 (TOAST-Cloud#393: region-guide
# `_EN`/`_JP` → `_KR`). 이 경로는 translate_diff 를 거치지 않아 M7 도 돌지 않았다.
# 수정: cloud-translate#1281 (keep_existing_image_refs).
#
# 픽스처: archive/image-locale/ (README 표가 기대값) — 세션 브랜치에만 심는다.
# 판정:   scripts/check_image_locale.py (모델 없음, 이미지 대상만)
#
# 실행 (suite plan `full-retranslate-images`):
#   scripts/e2e-full-retranslate-images.sh
#
# BEFORE/AFTER: 같은 세션 브랜치에 코드만 바꿔 두 번 돌린다.
#   CLOUD_TRANSLATE_DIR=<main 체크아웃> scripts/e2e-full-retranslate-images.sh --label BEFORE
#   CLOUD_TRANSLATE_DIR=<수정 워크트리> scripts/e2e-full-retranslate-images.sh --label AFTER \
#       --base-branch <첫 실행이 만든 e2e-fullimg/<ts>>
#   (--cloud-translate-dir <경로> 도 같은 뜻. 워크트리에는 .env 심볼릭 링크가 필요하다)
#
# 엔진은 언제나 claude-code (CLI). 옵션은 대시보드 전체 재번역 기본값과 같다
# (PRESERVE_EXISTING=false, --source-ref <세션 브랜치>).
#
# exit 0 = 기대대로 · 3 = 판정 실패 · 1 = 실행 실패
set -euo pipefail

REPO=TOAST-DOCS/Agent-Test
DOC=image-locale-sample.md
CT="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"; LABEL=""; BASE=""
PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
while [ $# -gt 0 ]; do
  case "$1" in
    --cloud-translate-dir) CT=$2; shift 2;;
    --label) LABEL=$2; shift 2;;
    --base-branch) BASE=$2; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done
[ -f "$CT/translate/translate_file.py" ] || { echo "error: $CT 에 translate/translate_file.py 없음 (CLOUD_TRANSLATE_DIR / --cloud-translate-dir)" >&2; exit 1; }
[ -x "$PY" ] || { echo "error: python 없음: $PY (CLOUD_TRANSLATE_PY)" >&2; exit 1; }
[ -e "$CT/.env" ] || { echo "error: $CT/.env 없음 (워크트리면 심볼릭 링크)" >&2; exit 1; }
HERE=$(cd "$(dirname "$0")/.." && pwd)
TS=$(date -u +%Y%m%d-%H%M%S)
LOG=/tmp/e2e-fullimg-${LABEL:-run}-$TS.log

# 1) 세션 브랜치 (없으면 alpha 에서 만들고 픽스처를 심는다)
if [ -z "$BASE" ]; then
  BASE=e2e-fullimg/$TS
  TMP=$(mktemp -d)
  git -C "$HERE" fetch -q origin +refs/heads/alpha:refs/remotes/origin/alpha
  git -C "$HERE" worktree add -q --detach "$TMP/wt" origin/alpha
  for l in ko en ja; do cp "$HERE/archive/image-locale/$l/$DOC" "$TMP/wt/$l/$DOC"; done
  git -C "$TMP/wt" add ko/$DOC en/$DOC ja/$DOC
  git -C "$TMP/wt" commit -q -m "e2e(full-retranslate-images): 픽스처 시드 ($TS)"
  git -C "$TMP/wt" push -q origin "HEAD:refs/heads/$BASE"
  git -C "$HERE" worktree remove --force "$TMP/wt"; rm -rf "$TMP"
  echo "[1/4] 세션 브랜치 $BASE (픽스처 시드)"
else
  echo "[1/4] 세션 브랜치 $BASE (재사용)"
fi
SEED=$(gh api "repos/$REPO/branches/$BASE" -q .commit.sha)

# 2) 시작 상태 — 세션 브랜치 자체는 기대값과 같아야 한다 (en 의 끼어든 _KR 줄만 다르다)
echo "[2/4] 시드 상태 판정 (en #region 의 _KR 중복은 FAIL 이 정상)"
"$PY" "$HERE/scripts/check_image_locale.py" "$REPO" "$SEED" || true

# 3) 전체 재번역 (대시보드와 같은 진입점)
echo "[3/4] translate_file.py ($CT @ $(git -C "$CT" rev-parse --short HEAD)) → $LOG"
( cd "$CT" && TRANSLATE_TRANSLATE_ENGINE=claude-code TRANSLATE_DIFF_FULL_PRESERVE_EXISTING=false \
    "$PY" translate/translate_file.py \
    "https://github.com/$REPO/blob/$BASE/ko/$DOC" --source-ref "$BASE" ) 2>&1 | tee "$LOG"
PR_URL=$(grep -o 'Translation PR: https://[^ ]*' "$LOG" | tail -1 | cut -d' ' -f3)
[ -n "$PR_URL" ] || { echo "error: 번역 PR 없음" >&2; exit 1; }
grep -q "with Claude Code CLI\|engine=claude-code" "$LOG" || echo "WARN: 로그에서 CLI 엔진을 확인하지 못했다"
HEAD_SHA=$(gh pr view "$PR_URL" --json headRefOid -q .headRefOid)
if [ -n "$LABEL" ]; then
  T=$(gh pr view "$PR_URL" --json title -q .title)
  gh pr edit "$PR_URL" --title "[$LABEL] $T" >/dev/null
fi

# 4) 판정
echo "[4/4] 판정 — $PR_URL @ ${HEAD_SHA:0:8}"
set +e
"$PY" "$HERE/scripts/check_image_locale.py" "$REPO" "$HEAD_SHA"
RC=$?
set -e
echo "RESULT label=${LABEL:-} base=$BASE pr=$PR_URL head=$HEAD_SHA rc=$RC log=$LOG"
exit $RC
