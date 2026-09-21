#!/usr/bin/env bash
#
# archive/list-items/{ko,en,ja}/list-items-sample.md → {ko,en,ja}/ 로 overwrite.
#
# 이 픽스처의 정본은 archive 쪽이다. 세 판본이 **한 벌로만 의미가 있기** 때문에
# 셋을 함께 되돌린다:
#
#   * en/ja 첫 줄의 `<!-- machine_translated: true -->` 와 ko 에 그것이 없다는
#     것이 재현 조건 그 자체다 (scripts/e2e-list-items.sh 판정 (1)).
#   * 고정된 형제 불릿(en `Settings by Feature` · ja `認証方式の概要`)이
#     판정 (3) 의 눈금이다. 번역 잡이 이 파일을 한 번이라도 돌면 그 눈금이
#     새 표현으로 덮여 다음 회차의 판정이 무의미해진다.
#
# 번역·검수 잡을 이 문서에 돌린 뒤에는 반드시 실행한다.
#
# Usage:
#   scripts/restore-list-items-sample.sh              # 실제 복사
#   scripts/restore-list-items-sample.sh --dry-run    # 미리보기

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/archive/list-items"
FILE="list-items-sample.md"
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
