#!/usr/bin/env bash
#
# archive/fix-tables/{ko,en,ja}/fix-tables-sample.md → {ko,en,ja}/fix-tables-sample.md 로 overwrite.
#
# 깨진 표 정비(translate/translate_fix_tables.py) e2e 는 세션 브랜치에서만 돌아
# alpha 의 픽스처는 그대로 남지만, 누군가 alpha 의 픽스처를 손대거나 pre-align 을
# 이 문서에 돌려 대조군(앵커 없는 하위 heading)이 사라졌을 때 이 스크립트로 되돌린다.
#
# Usage:
#   scripts/restore-fix-tables-sample.sh              # 실제 복사
#   scripts/restore-fix-tables-sample.sh --dry-run    # 미리보기

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/archive/fix-tables"
FILE="fix-tables-sample.md"
LANGS=(ko en ja)

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
