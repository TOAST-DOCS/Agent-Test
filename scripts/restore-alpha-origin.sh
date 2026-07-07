#!/usr/bin/env bash
#
# archive/alpha-origin/{ko,en,ja}/ 의 파일들로 ko/, en/, ja/ 를 덮어씁니다.
# archive 에 없는 파일(예: en/heading-lint-*.md)은 target 에 그대로 남습니다.
#
# Usage:
#   scripts/restore-alpha-origin.sh              # 실제 복사
#   scripts/restore-alpha-origin.sh --dry-run    # 무엇이 덮어써질지 미리 보기

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/archive/alpha-origin"
LANGS=(ko en ja)

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=1
fi

if [[ ! -d "$SRC_ROOT" ]]; then
  echo "error: source not found: $SRC_ROOT" >&2
  exit 1
fi

for lang in "${LANGS[@]}"; do
  src="$SRC_ROOT/$lang"
  dst="$REPO_ROOT/$lang"

  if [[ ! -d "$src" ]]; then
    echo "skip: $src (missing)"
    continue
  fi
  mkdir -p "$dst"

  count=0
  while IFS= read -r -d '' file; do
    rel="${file#$src/}"
    target="$dst/$rel"
    if (( DRY_RUN )); then
      echo "would overwrite: $lang/$rel"
    else
      mkdir -p "$(dirname "$target")"
      cp -f "$file" "$target"
    fi
    count=$((count + 1))
  done < <(find "$src" -type f -print0)

  if (( DRY_RUN )); then
    echo "  $lang/: $count file(s) would be copied"
  else
    echo "  $lang/: $count file(s) copied"
  fi
done

if (( DRY_RUN )); then
  echo
  echo "(dry-run) 실제로 복사하려면 --dry-run 없이 다시 실행하세요."
fi
