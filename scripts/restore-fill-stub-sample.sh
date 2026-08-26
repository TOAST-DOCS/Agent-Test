#!/usr/bin/env bash
#
# archive/fill-stub/{ko,en,ja}/fill-stub-sample.md → {ko,en,ja}/fill-stub-sample.md 로 overwrite.
#
# 빈 번역 채우기(translate/translate_fill_stubs.py) 실행이 성공하면 en/ja 의
# stub 이 채워져 사라진다. 다음 회차를 돌리기 전에 이 스크립트로 stub 상태를
# 되돌린다.
#
# Usage:
#   scripts/restore-fill-stub-sample.sh              # 실제 복사
#   scripts/restore-fill-stub-sample.sh --dry-run    # 미리보기

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/archive/fill-stub"
FILE="fill-stub-sample.md"
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
