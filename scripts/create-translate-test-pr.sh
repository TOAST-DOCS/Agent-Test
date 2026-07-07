#!/usr/bin/env bash
#
# archive/translate/{ko,en,ja}/ 의 파일을 실제 ko/, en/, ja/ 에 반영하고,
# 새 브랜치를 만들어 alpha 로 PR 을 생성합니다. (번역 테스트용)
#
# 흐름:
#   1) alpha 를 최신화한 뒤 새 브랜치 생성
#      (branch 이름: translate-test/YYYYMMDD-HHMMSS, --branch 로 override)
#   2) archive/translate/{lang}/<file>  →  <lang>/<file>  복사
#   3) commit → push → gh pr create (base: alpha)
#
# Usage:
#   scripts/create-translate-test-pr.sh
#   scripts/create-translate-test-pr.sh --branch translate-test/my-name
#   scripts/create-translate-test-pr.sh --dry-run
#   scripts/create-translate-test-pr.sh --title "..." --body "..."
#
# 의존성: git, gh (로그인 완료 상태)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/archive/translate"
BASE_BRANCH="alpha"
LANGS=(ko en ja)

BRANCH=""
TITLE=""
BODY=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)  BRANCH="$2"; shift 2 ;;
    --title)   TITLE="$2";  shift 2 ;;
    --body)    BODY="$2";   shift 2 ;;
    --dry-run|-n) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

cd "$REPO_ROOT"

# ── 사전 검증 ────────────────────────────────────────────────────────────
if [[ ! -d "$SRC_ROOT" ]]; then
  echo "error: $SRC_ROOT not found" >&2
  exit 1
fi

# 복사할 파일 수집
files_to_copy=()
for lang in "${LANGS[@]}"; do
  src_dir="$SRC_ROOT/$lang"
  [[ -d "$src_dir" ]] || continue
  while IFS= read -r -d '' f; do
    rel="${f#$src_dir/}"
    files_to_copy+=("$lang|$rel")
  done < <(find "$src_dir" -type f -print0)
done

if [[ ${#files_to_copy[@]} -eq 0 ]]; then
  echo "error: no files under $SRC_ROOT/{ko,en,ja}/" >&2
  exit 1
fi

echo "복사할 파일 (${#files_to_copy[@]}개):"
for entry in "${files_to_copy[@]}"; do
  echo "  archive/translate/${entry//|/\/}  →  ${entry//|/\/}"
done

# tracked-file 변경사항 체크 (untracked 는 checkout 후에도 유지되므로 허용)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: tracked 파일에 커밋되지 않은 변경사항이 있습니다. commit/stash 후 다시 실행하세요." >&2
  git status --short >&2
  exit 1
fi

# 브랜치 이름
if [[ -z "$BRANCH" ]]; then
  BRANCH="translate-test/$(date +%Y%m%d-%H%M%S)"
fi
echo
echo "base branch : $BASE_BRANCH"
echo "new branch  : $BRANCH"

if (( DRY_RUN )); then
  echo
  echo "(dry-run) 여기서 종료. 실제 실행하려면 --dry-run 을 빼세요."
  exit 0
fi

# ── 실제 작업 ────────────────────────────────────────────────────────────
git fetch origin "$BASE_BRANCH"
git checkout -B "$BRANCH" "origin/$BASE_BRANCH"

for entry in "${files_to_copy[@]}"; do
  lang="${entry%%|*}"
  rel="${entry#*|}"
  src="$SRC_ROOT/$lang/$rel"
  dst="$REPO_ROOT/$lang/$rel"
  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  git add "$lang/$rel"
done

if git diff --cached --quiet; then
  echo "변경사항 없음. 종료."
  exit 0
fi

: "${TITLE:=Translate test: apply archive/translate snapshot}"
: "${BODY:=archive/translate/{ko,en,ja}/ 파일들을 실제 언어 폴더에 반영해 번역 파이프라인을 테스트하기 위한 PR입니다.}"

git commit -m "$TITLE"
git push -u origin "$BRANCH"

gh pr create \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "$TITLE" \
  --body  "$BODY"
