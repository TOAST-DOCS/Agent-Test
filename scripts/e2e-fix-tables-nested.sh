#!/usr/bin/env bash
#
# 깨진 표 정비 — 목록 안 표의 들여쓰기 (TOAST-DOCS/EasyMaker#239, cloud-translate 수정 PR).
#
# 표 전체 수리는 고칠 표를 `translator.translate()` 로 다시 번역하는데, 엔진 응답이
# `_strip_code_fence` 의 `.strip()` 을 지나며 **첫 줄(=머리행)** 의 앞 공백을 잃는다.
# 목록 항목 안에 4칸 들여쓴 표면 머리행만 0칸이 되고, 사이트 렌더러는 그 줄에서 목록을
# 끊어 표를 목록 밖으로 뺀다 (소스 파서는 그래도 표 하나로 센다 — 도구의 검사가 못 본 이유).
#
# 픽스처 `archive/fix-tables-nested/` — 세션 base 에만 심는다 (alpha 에는 없다):
#   #fix-tables-nested-list      4칸 표 셋 중 둘째의 첫 열이 다른 표 것 (사고 모양)
#   #fix-tables-nested-deep      번호 목록 > 글머리 목록 안 8칸 표, 첫 열이 형식명으로 덮임
#   #fix-tables-nested-top       (대조군) 0칸 표 — 고쳐지되 0칸 그대로여야 한다
#   #fix-tables-nested-untouched (대조군) 정상인 목록 안 표 — 바이트 동일
# 판정은 scripts/check_fix_tables_nested.py (모델 없음): [A] 표 줄 들여쓰기 == ko ·
# ko 식별자 · [B] 사이트 렌더의 `<li>` 안 표 수 · 목록 수 == ko · [C] 대조군 바이트 동일.
#
# BEFORE/AFTER 는 같은 --base-branch 에 코드만 바꿔 두 번 부른다:
#   bash scripts/e2e-fix-tables-nested.sh --label BEFORE --cloud-translate-dir <main 체크아웃>
#   bash scripts/e2e-fix-tables-nested.sh --label AFTER  --cloud-translate-dir <수정 워크트리> \
#        --base-branch e2e-fixtables-nested/<ts>
#
# 로컬 translate_fix_tables.py 전용. `--run-dir` 은 `.env` 가 있는 cwd (기본: 메인 체크아웃) —
# 워크트리 코드를 `.env` 링크 없이 돌린다 (스크립트가 자기 경로를 sys.path 앞에 둔다).
# 엔진은 .env 의 claude-code 그대로 (api 로 돌리지 않는다).
#
# exit: 0 OK · 3 REPRO · 1 그 밖의 실패 · 2 사용법
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
DOC="fix-tables-nested-sample.md"
TS="$(date -u +%Y%m%d-%H%M%S)"
LABEL=""
BASE_BRANCH=""
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
RUN_DIR="$HOME/works/cloud-translate"
PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
CLEANUP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="$2"; shift 2 ;;
    --base-branch) BASE_BRANCH="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --run-dir) RUN_DIR="$2"; shift 2 ;;
    --cleanup) CLEANUP=1; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[[ -f "$RUN_DIR/.env" ]] || { echo "error: $RUN_DIR/.env 없음" >&2; exit 2; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/e2e-label.sh"
OUT="/tmp/e2e-fixtables-nested-$TS"; mkdir -p "$OUT"
WT="$OUT/wt"

if [[ "$CLEANUP" == 1 && -n "$BASE_BRANCH" ]]; then
  for n in $(gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json number --jq '.[].number'); do
    gh pr close "$n" --repo "$REPO" --delete-branch >/dev/null || true
  done
  git -C "$ROOT" push -q origin ":$BASE_BRANCH" || true
  echo "cleaned $BASE_BRANCH"; exit 0
fi

# ── 1) 세션 base ──────────────────────────────────────────────────────────
git -C "$ROOT" fetch -q origin alpha
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-fixtables-nested/$TS"
  git -C "$ROOT" worktree add -q --detach "$WT" origin/alpha
  for l in ko en ja; do
    cp "$ROOT/archive/fix-tables-nested/$l/$DOC" "$WT/$l/$DOC"
  done
  git -C "$WT" add ko en ja
  git -C "$WT" commit -q -m "e2e: fix-tables nested-table fixture ($TS)"
  git -C "$WT" push -q origin "HEAD:refs/heads/$BASE_BRANCH"
  git -C "$ROOT" worktree remove --force "$WT"
  echo "[1/3] 세션 base 생성: $BASE_BRANCH"
else
  echo "[1/3] 세션 base 재사용: $BASE_BRANCH"
fi
git -C "$ROOT" fetch -q origin "+refs/heads/$BASE_BRANCH:refs/remotes/origin/$BASE_BRANCH"
for l in ko en ja; do
  git -C "$ROOT" show "origin/$BASE_BRANCH:$l/$DOC" > "$OUT/base-$l.md"
done

# ── 2) 정비 실행 ──────────────────────────────────────────────────────────
echo "[2/3] translate_fix_tables.py — code=$CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" rev-parse --short HEAD))"
set +e
(cd "$RUN_DIR" && "$PY" "$CLOUD_TRANSLATE_DIR/translate/translate_fix_tables.py" \
   "$REPO" "$BASE_BRANCH" --only "en/$DOC,ja/$DOC") > "$OUT/run.log" 2>&1
rc=$?
set -e
grep -aE '^  (en|ja)/|^      \[|Fix-tables PR:' "$OUT/run.log" | sed 's/^/  /' || true
grep -aoE 'engine=[a-z-]+|with Claude Code CLI' "$OUT/run.log" | sort | uniq -c | sed 's/^/  /' || true
pr_url="$(grep -aoE 'Fix-tables PR: https://[^ ]+' "$OUT/run.log" | tail -1 | awk '{print $NF}')"
if [[ -z "$pr_url" ]]; then
  echo "error: Fix-tables PR 없음 (exit=$rc, 로그 $OUT/run.log)"; exit 1
fi
e2e_label_pr "$REPO" "$pr_url"
if [[ -n "$LABEL" ]]; then
  title="$(gh pr view "$pr_url" --json title --jq .title)"
  gh pr edit "$pr_url" --title "[$LABEL] $title" >/dev/null
fi
head="$(gh pr view "$pr_url" --json headRefName --jq .headRefName)"
git -C "$ROOT" fetch -q origin "+refs/heads/$head:refs/remotes/origin/$head"
for l in en ja; do git -C "$ROOT" show "origin/$head:$l/$DOC" > "$OUT/out-$l.md"; done

# ── 3) 판정 ───────────────────────────────────────────────────────────────
echo "[3/3] 판정 — PR $pr_url (head $(git -C "$ROOT" rev-parse --short "origin/$head"))"
set +e
"$PY" "$ROOT/scripts/check_fix_tables_nested.py" --ko "$OUT/base-ko.md" \
  --base-en "$OUT/base-en.md" --base-ja "$OUT/base-ja.md" \
  --en "$OUT/out-en.md" --ja "$OUT/out-ja.md" --cloud-translate-dir "$CLOUD_TRANSLATE_DIR"
v=$?
set -e
echo "base=$BASE_BRANCH pr=$pr_url label=${LABEL:-—} log=$OUT/run.log"
exit $v
