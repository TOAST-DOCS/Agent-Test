#!/usr/bin/env bash
#
# archive/table-parse/{ko,en,ja}/table-parse-sample.md → {ko,en,ja}/table-parse-sample.md 로 overwrite.
#
# 이 픽스처는 **일부러 깨뜨려 둔 표** 네 개를 담고 있어서, 파이프라인이 실제로
# 돌면 소진된다. 되돌려야 하는 경우는 둘이다:
#
#   * 마크업 정정(🧹 문서 정비)이 이 문서에 돌면 표 B 의 셀 안 줄바꿈(M7)을
#     고친다 — 그게 이 픽스처가 증명하려는 동작이므로 "정상" 이지만, 다음 실행을
#     위해 되돌려야 한다. 표 A(U+2028)는 렌더가 멀쩡해 M7 이 보지 못하므로
#     그대로 남는다.
#   * 번역이 이 문서에 돌면 표 A·B 의 en/ja 2·3행이 삭제되고 표 D 에 SVC-104 가
#     백필된다 (수정 전 동작). 그 결과를 확인한 뒤 되돌린다.
#
# 픽스처가 아직 의도한 모양인지는 scripts/check_table_parse.py 가 검사한다
# (마지막 줄 `TABLE-PARSE: OK`).
#
# Usage:
#   scripts/restore-table-parse-sample.sh              # 실제 복사
#   scripts/restore-table-parse-sample.sh --dry-run    # 미리보기

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/archive/table-parse"
FILE="table-parse-sample.md"
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

changed=0
for lang in "${LANGS[@]}"; do
  src="$SRC_ROOT/$lang/$FILE"
  dst="$REPO_ROOT/$lang/$FILE"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    echo "same: $lang/$FILE"
    continue
  fi
  changed=1
  if (( DRY_RUN )); then
    echo "would restore: $lang/$FILE"
  else
    cp "$src" "$dst"
    echo "restored: $lang/$FILE"
  fi
done

if (( ! changed )); then
  echo
  echo "픽스처가 그대로입니다 — 되돌릴 것이 없습니다."
fi
