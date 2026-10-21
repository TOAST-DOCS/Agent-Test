#!/usr/bin/env bash
#
# 목록 항목 안 펜스 코드 블록의 들여쓰기 e2e — TOAST-DOCS/TOAST-Cloud#434 · #436.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# ko `public-api/framework-api.md` `#common-cursor-paging` (TOAST-Cloud#433, 2026-10-21
# 머지) 의 번호 목록 항목 본문에 4칸 ```` ```text ```` 블록 둘이 있다.
#   #434 (새 절 추가)        en/ja: 여는 펜스 4 · GET **0** · → 4 · 닫는 펜스 4 (두 블록)
#   #436 (블록 한 줄 수정)    en/ja: 여는 펜스 4 · GET 4 · → **8** · 닫는 펜스 **8**
# 둘 다 배포본에서 `<pre>` 가 아니라 inline code(`text GET …`)로 렌더된다.
#
# 원인(cloud-translate, 이상적 모델 재생으로 확정): 한글이 든 단일 코드 블록은
# "rewrap" 경로(`translate()` · `_translate_fence_protected`)가 펜스를 떼고 inner 만
# 모델에 보내는데, 모든 엔진이 응답에 거는 `_strip_code_fence` 의 `.strip()` 이 inner
# **첫 줄**의 선행 공백을 지운다 → #434 모양(0칸). 블록이 단위로 재번역되는 splice
# 경로는 그 뒤 `_reuse_ko_leading_indent` 가 "첫 줄 뒤 최소 들여쓰기가 ko 보다 얕다"
# 를 보고 **나머지 줄 전부**(ko 바이트 그대로인 닫는 펜스 포함)에 4칸을 더한다 →
# #436 모양(4·8·8).
#
# ── 판정 (scripts/check_list_fence.py) ────────────────────────────────────
#   대상 절(#list-fence-edit · #list-fence-new · #list-fence-control) 마다
#     [indent] en/ja 펜스 블록 줄의 들여쓰기 열 == ko
#     [pre]    superfences 렌더의 그 절 `<pre>` 수 == ko
#   #list-fence-edit    — 기존 절, ko 가 두 번째 블록의 둘째 줄만 고친다 (#436 모양)
#   #list-fence-new     — ko 가 목록 안 코드 블록 둘이 든 새 절을 추가한다 (#434 모양)
#   #list-fence-control — 대조군. 목록 밖(0칸) 블록의 둘째 줄을 고친다. 늘 OK
#
# ── 모드 ──────────────────────────────────────────────────────────────────
#   (기본) [A] 이상적 모델 재생 — 모델·네트워크 없음. `translate_diff` 를 운영 플래그로
#        돌리고 모델만 "받은 줄을 그대로 번역" 으로 바꾼다 (arm identity/strip/dedent).
#        exit 0 OK · 3 REPRO · 1 하네스 오류
#   --judge-pr <번역 PR URL>   [B] 실제 번역 산출물 판정 (head SHA 의 ko/en/ja)
#   --open-ko-pr               ko 편집 PR 을 연다 (base = --base-branch, 픽스처가 있는 브랜치)
#                              번역은 이 스크립트가 걸지 않는다 — 로컬 translate_pr.py
#                              (CLI 엔진) 로 번역한 뒤 --judge-pr 로 판정한다
#
# Usage:
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate bash scripts/e2e-list-fence.sh
#   bash scripts/e2e-list-fence.sh --ref origin/e2e-listfence/<ts>
#   bash scripts/e2e-list-fence.sh --open-ko-pr --base-branch e2e-listfence/<ts>
#   bash scripts/e2e-list-fence.sh --judge-pr https://github.com/TOAST-DOCS/Agent-Test/pull/<n>
#
# 의존성: python3 (cloud-translate .venv — markdown · pymdownx), git, gh
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
DOC="list-items-sample.md"
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$CLOUD_TRANSLATE_DIR/.venv/bin/python}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$REPO_ROOT/scripts/check_list_fence.py"
FIXTURE_REF=""
JUDGE_PR=""
OPEN_PR=0
BASE_BRANCH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) FIXTURE_REF="$2"; shift 2 ;;
    --judge-pr) JUDGE_PR="$2"; shift 2 ;;
    --open-ko-pr) OPEN_PR=1; shift ;;
    --base-branch) BASE_BRANCH="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,48p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }

if [[ -n "$JUDGE_PR" ]]; then
  exec "$CLOUD_TRANSLATE_PY" "$CHECK" --mode pr --pr "$JUDGE_PR" --path "$DOC"
fi

if [[ "$OPEN_PR" == 1 ]]; then
  [[ -n "$BASE_BRANCH" ]] || { echo "--open-ko-pr 는 --base-branch 가 필요하다 (alpha 금지)" >&2; exit 1; }
  [[ "$BASE_BRANCH" != "alpha" ]] || { echo "alpha 를 base 로 쓰지 않는다" >&2; exit 1; }
  TS="$(date -u +%Y%m%d-%H%M%S)"
  HEAD_BRANCH="translate-test-listfence/$TS"
  wt="$(mktemp -d)/wt"
  git -C "$REPO_ROOT" fetch -q origin "+refs/heads/$BASE_BRANCH:refs/remotes/origin/$BASE_BRANCH"
  git -C "$REPO_ROOT" worktree add -q -b "$HEAD_BRANCH" "$wt" "origin/$BASE_BRANCH"
  trap 'git -C "$REPO_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || true' EXIT
  "$CLOUD_TRANSLATE_PY" - "$CHECK" "$wt/ko/$DOC" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("clf", sys.argv[1]); m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
p = sys.argv[2]; s = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(m.make_head_ko(s))
PY
  git -C "$wt" commit -q -am "test(e2e): list-fence ko 편집 — 블록 한 줄 수정 · 새 절 · 대조군"
  git -C "$wt" push -q origin "$HEAD_BRANCH"
  for lb in content-agent; do
    gh label list --repo "$REPO" --search "$lb" --json name -q '.[].name' | grep -qx "$lb" \
      || gh label create "$lb" --repo "$REPO" >/dev/null
  done
  gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --label content-agent \
    --title "[e2e list-fence] 목록 안 코드 블록 들여쓰기 — ko 입력 ($TS)" \
    --body "e2e-list-fence.sh 의 ko 입력. 번역 후 \`bash scripts/e2e-list-fence.sh --judge-pr <번역 PR>\` 로 판정한다. 결함: TOAST-DOCS/TOAST-Cloud#434 · #436. 머지하지 않는다."
  exit 0
fi

ROOT="$REPO_ROOT"
if [[ -n "$FIXTURE_REF" ]]; then
  ROOT="$(mktemp -d)"
  for l in ko en ja; do
    mkdir -p "$ROOT/$l"
    git -C "$REPO_ROOT" show "$FIXTURE_REF:$l/$DOC" > "$ROOT/$l/$DOC" \
      || { echo "픽스처 없음: $FIXTURE_REF:$l/$DOC" >&2; exit 1; }
  done
fi
echo "  픽스처          : {ko,en,ja}/$DOC @ ${FIXTURE_REF:-워킹 트리}"
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" rev-parse --short HEAD 2>/dev/null || echo '?'))"
set +e
"$CLOUD_TRANSLATE_PY" "$CHECK" --mode ideal --root "$ROOT" --cloud-translate-dir "$CLOUD_TRANSLATE_DIR"
rc=$?
set -e
exit "$rc"
