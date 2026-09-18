#!/usr/bin/env bash
#
# archive/markup-lint/ko/markup-lint-sample.md → ko/markup-lint-sample.md 로 overwrite.
#
# 마크업 정정(pre-align/fix_markup.py) 실행이 성공하면 이 픽스처의 결함이
# 수리되어 사라진다 (M2 5건 · M4 2건 · M5 2건 · M6 1건). 다음 회차를 돌리기
# 전에 이 스크립트로 깨진 상태를 되돌린다.
#
# 보고만 하는 절(17~19)은 수리되지 않으므로 복원 없이도 남아 있지만, 파일
# 전체를 되돌리는 편이 "이 픽스처의 정본은 archive" 라는 규칙과 어긋나지 않는다.
#
# Usage:
#   scripts/restore-markup-lint-sample.sh              # 실제 복사
#   scripts/restore-markup-lint-sample.sh --dry-run    # 미리보기

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/archive/markup-lint"
FILE="markup-lint-sample.md"
LANGS=(ko)

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=1
fi

cd "$REPO_ROOT"

missing=0
for lang in "${LANGS[@]}"; do
  src="$SRC_ROOT/$lang/$FILE"
  if [[ ! -f "$src" ]]; then
    echo "error: source not found: $src" >&2
    missing=1
  fi
done
(( missing )) && exit 1

for lang in "${LANGS[@]}"; do
  src="$SRC_ROOT/$lang/$FILE"
  dst="$REPO_ROOT/$lang/$FILE"

  if (( DRY_RUN )); then
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
      echo "unchanged : $lang/$FILE"
    else
      echo "overwrite : $lang/$FILE"
    fi
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  echo "copied    : $lang/$FILE"
done

if (( DRY_RUN )); then
  echo
  echo "(dry-run) 실제로 복사하려면 --dry-run 없이 다시 실행하세요."
fi
