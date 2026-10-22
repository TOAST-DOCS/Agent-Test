#!/usr/bin/env bash
#
# korean-review **section id 전처리** e2e (cloud-user-guide-agent/601, Data-Flow#235 → #236):
#   1) alpha 로부터 세션 base e2e-anchorpre/<ts>
#   2) head 브랜치: ko/fix-links.md 끝에 h2/h3/h4 절 셋을 **id 없이** 추가 + 기존 절
#      본문 한 줄 수정(대조군 — 기존 <a id> 가 그대로여야 한다) → ko PR
#   3) 로컬 review_pr.py (TRANSLATE_REVIEW_ASSIGN_ANCHORS=true|false, --label 에 따라)
#   4) 판정 A (check_anchor_preassign.py --phase review): head 에 봇 커밋 1개 ·
#      새 heading 마다 <a id> · h2/h3 는 { #id } 같은 값 · h4 는 상위 h3 id 접두 ·
#      기존 anchor 순서 불변 · marker sig = outline · 인라인 코멘트 commit_id = 새 head
#   5) ko PR 머지 → 로컬 translate_pr.py (권장 preset, CLI 엔진)
#   6) 판정 B (--phase translate): 번역 PR 이 ko 를 **안 건드리고** en/ja 의 <a id>
#      순서가 ko 와 같다
#
# --label BEFORE 는 전처리를 끄고 돌려 오늘 동작을 REPRO 로 잡는다 — review 단계에서
# head 가 그대로, translate 단계에서 번역 PR 에 `Assign id anchors to new sections in ko/`
# 커밋이 생긴다. 같은 base 를 `--base-branch` 로 재사용하면 BEFORE/AFTER 가 같은 픽스처다.
#
# 601 모양(순차 큐 × 머지 순서) 자체는 여기서 재현하지 않는다 — 그건 Agent-Test#1889
# 의 몫이고, 이 e2e 는 그 모양의 **전제**(번역 PR 이 ko 에 id 를 커밋한다)를 없앴는지만
# 잰다. 판정은 전부 결정적(모델 없음), 슬러그 글자만 LLM 이라 값은 비교하지 않는다.
#
# Usage:
#   source ./load_env.sh          # webhook 토글용 (DASHBOARD_BASE_URL / _API_TOKEN)
#   CLOUD_TRANSLATE_DIR=<체크아웃> bash scripts/e2e-korean-review-anchor-preassign.sh [--label AFTER|BEFORE]
#       [--base-branch e2e-anchorpre/<ts>] [--skip-translate] [--keep] [--preset-dir <메인 체크아웃>]
#       [--resume-translate <ko PR URL>]   # 이미 검수·머지된 PR 로 번역·판정 B 만
#
# 의존성: git, gh (로그인), python3, $CLOUD_TRANSLATE_DIR/.env

set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
DOC="ko/fix-links.md"
LABEL="AFTER"
BASE_BRANCH=""
SKIP_TRANSLATE=0
KEEP=0
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
# 번역 preset 의 정본(dashboard/.env 의 TRANSLATE_TRANSLATE_PRESETS)은 메인 체크아웃에만 있다 —
# 워크트리로 코드를 돌릴 때도 옵션은 여기서 읽는다.
PRESET_DIR="${PRESET_DIR:-$HOME/works/cloud-translate}"
RESUME_KO_PR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)          LABEL="$2"; shift 2 ;;
    --base-branch)    BASE_BRANCH="$2"; shift 2 ;;
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --preset-dir)     PRESET_DIR="$2"; shift 2 ;;
    --resume-translate) RESUME_KO_PR="$2"; shift 2 ;;   # 이미 검수·머지된 ko PR 로 5·6 단계만
    --skip-translate) SKIP_TRANSLATE=1; shift ;;
    --keep)           KEEP=1; shift ;;
    -h|--help)        sed -n '3,30p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ "$LABEL" == "AFTER" || "$LABEL" == "BEFORE" ]] || { echo "--label 은 AFTER|BEFORE" >&2; exit 1; }
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
if [[ -z "${DASHBOARD_BASE_URL:-}" || -z "${DASHBOARD_API_TOKEN:-}" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 필요 (load_env.sh)" >&2; exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/e2e-webhook-toggle.sh"
source "$REPO_ROOT/scripts/e2e-label.sh"
TS="$(date -u +%Y%m%d-%H%M%S)"
LOGDIR="${E2E_LOGDIR:-/tmp/e2e-anchorpre-$TS}"; mkdir -p "$LOGDIR"
# 판정기는 세션 브랜치(alpha 기반)에 없을 수 있다 — 체크아웃을 바꾸기 전에 복사해 둔다.
cp "$REPO_ROOT/scripts/check_anchor_preassign.py" "$LOGDIR/check_anchor_preassign.py"
CHECK="$LOGDIR/check_anchor_preassign.py"
ASSIGN="true"; [[ "$LABEL" == "BEFORE" ]] && ASSIGN="false"
echo "[$LABEL] 전처리=$ASSIGN · cloud-translate=$CLOUD_TRANSLATE_DIR · log=$LOGDIR"

echo "[0/6] webhook 비활성화 (Jenkins 검수가 같은 PR 에 겹치지 않게)"
set_webhook_repo_enabled false
trap 'set_webhook_repo_enabled true || true' EXIT

# ── 1) 세션 base ──────────────────────────────────────────────────────
RC_A=0
if [[ -n "$RESUME_KO_PR" ]]; then
  KO_PR_URL="$RESUME_KO_PR"; KO_PR="${KO_PR_URL##*/}"
  BASE_BRANCH="$(gh pr view "$KO_PR_URL" --repo "$REPO" --json baseRefName --jq .baseRefName)"
  echo "[1/6]..[4/6] 건너뜀 — $KO_PR_URL (base $BASE_BRANCH) 로 번역 단계부터"
elif [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-anchorpre/$TS"
  echo "[1/6] 세션 base 생성: $BASE_BRANCH (from origin/alpha)"
  git fetch -q origin alpha
  git checkout -q -B "$BASE_BRANCH" origin/alpha
  git push -q -u origin "$BASE_BRANCH"
else
  echo "[1/6] 세션 base 재사용: $BASE_BRANCH"
  git fetch -q origin "$BASE_BRANCH"
  git checkout -q "$BASE_BRANCH"; git pull -q --ff-only origin "$BASE_BRANCH"
fi

# ── 2) 픽스처 head + ko PR ────────────────────────────────────────────
if [[ -z "$RESUME_KO_PR" ]]; then
HEAD_BRANCH="translate-test-anchorpre/$TS-$(tr '[:upper:]' '[:lower:]' <<<"$LABEL")"
echo "[2/6] 픽스처 PR: $HEAD_BRANCH → $BASE_BRANCH"
git checkout -q -B "$HEAD_BRANCH" "$BASE_BRANCH"
grep -q '^<a id="fix-links-controls"></a>$' "$DOC" || { echo "error: $DOC 모양이 기대와 다름" >&2; exit 2; }
# 대조군: 기존 절(fix-links-controls)의 본문에 한 줄 — 기존 <a id> 는 그대로여야 한다.
python3 - "$DOC" "$TS" <<'PYEOF'
import sys
p, ts = sys.argv[1], sys.argv[2]
s = open(p, encoding="utf-8").read()
marker = "## 정상 링크 모음 { #fix-links-controls }\n"
assert s.count(marker) == 1, "control heading not found"
s = s.replace(marker, marker + f"\n(e2e anchor-preassign 대조군 — 기존 절 본문 수정 {ts})\n", 1)
if not s.endswith("\n"):
    s += "\n"
s += (
    "\n## 전처리 검증 절\n\n"
    "이 절은 e2e 가 id 없이 추가한 h2 입니다. 전처리가 `<a id>` 와 `{ #id }` 를 함께 붙여야 합니다.\n\n"
    "### 하위 절 하나\n\n"
    "h3 — 역시 id 없이 추가됐습니다.\n\n"
    "#### 세부 항목\n\n"
    "h4 — `<a id>` 만, 상위 h3 id 를 접두로 받아야 합니다.\n"
)
open(p, "w", encoding="utf-8").write(s)
PYEOF
git add "$DOC"
git commit -q -m "e2e(anchor-preassign) [$LABEL]: id 없는 h2/h3/h4 추가 + 기존 절 본문 수정 ($TS)"
git push -q -u origin "$HEAD_BRANCH"
e2e_ensure_label "$REPO"
KO_PR_URL="$(gh pr create --repo "$REPO" --base "$BASE_BRANCH" --head "$HEAD_BRANCH" \
  --title "[$LABEL] e2e anchor-preassign — id 없는 새 절 셋 ($TS)" \
  --body "한글 검수 **section id 전처리** e2e 픽스처 (cloud-user-guide-agent/601).

- \`$DOC\` 끝에 h2/h3/h4 절을 **id 없이** 추가, 기존 절(\`#fix-links-controls\`) 본문 한 줄 수정(대조군)
- [$LABEL] 전처리=$ASSIGN — AFTER 면 검수가 이 head 에 id 커밋을 얹고, 머지 뒤 번역 PR 은 ko 를 건드리지 않아야 한다" \
  --label "$E2E_LABEL")"
KO_PR="${KO_PR_URL##*/}"
HEAD_BEFORE="$(git rev-parse HEAD)"
echo "  ko PR: $KO_PR_URL (head $HEAD_BEFORE)"

# ── 3) 로컬 검수 ──────────────────────────────────────────────────────
echo "[3/6] review_pr.py (TRANSLATE_REVIEW_ASSIGN_ANCHORS=$ASSIGN)"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && TRANSLATE_REVIEW_ASSIGN_ANCHORS="$ASSIGN" \
   "$CLOUD_TRANSLATE_PY" korean-review/review_pr.py "$KO_PR_URL") >"$LOGDIR/review.log" 2>&1
rc=$?
set -e
grep -aE "^(Preassign|Review)" "$LOGDIR/review.log" | sed 's/^/  /' || true
(( rc == 0 )) || { echo "  review_pr.py 실패 (exit $rc) — $LOGDIR/review.log" >&2; tail -20 "$LOGDIR/review.log" >&2; exit 2; }

# ── 4) 판정 A ─────────────────────────────────────────────────────────
echo "[4/6] 판정 A — 전처리 커밋 모양"
set +e
"$CLOUD_TRANSLATE_PY" "$CHECK" --phase review --repo "$REPO" \
  --ko-pr "$KO_PR" --head-before "$HEAD_BEFORE" --doc "$DOC" --label "$LABEL" \
  --cloud-translate-dir "$CLOUD_TRANSLATE_DIR" \
  --new-heading "전처리 검증 절" --new-heading "하위 절 하나" --new-heading "세부 항목" \
  | tee "$LOGDIR/check-review.txt"
RC_A=${PIPESTATUS[0]}
set -e
if (( SKIP_TRANSLATE )); then
  echo "[5/6][6/6] --skip-translate"
  echo "ANCHOR_PREASSIGN: $([[ $RC_A -eq 0 ]] && echo OK || echo "REPRO (review)")"
  exit "$RC_A"
fi
fi   # RESUME_KO_PR

# ── 5) 머지 → 번역 ────────────────────────────────────────────────────
echo "[5/6] ko PR 머지 → 로컬 translate_pr.py"
if [[ "$(gh pr view "$KO_PR_URL" --repo "$REPO" --json state --jq .state)" != "MERGED" ]]; then
  gh pr merge "$KO_PR_URL" --repo "$REPO" --merge >/dev/null
fi
set +e
preset_eval="$(python3 "$REPO_ROOT/scripts/preset_options.py" \
  --catalog-dir "$PRESET_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)"
rc=$?
set -e
(( rc == 0 )) || { echo "  preset_options.py 실패 (exit $rc) — PRESET_DIR=$PRESET_DIR" >&2; exit 2; }
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"
(cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$KO_PR_URL" "${PRESET_ARGS[@]}") \
  >"$LOGDIR/translate.log" 2>&1 || { echo "  translate_pr.py 실패 — $LOGDIR/translate.log" >&2; tail -30 "$LOGDIR/translate.log" >&2; exit 2; }
TRANS_URL="$(grep -aoE 'Translation PR: https://[^ ]+' "$LOGDIR/translate.log" | tail -1 | sed 's/Translation PR: //')"
[[ -n "$TRANS_URL" ]] || { echo "  번역 PR URL 파싱 실패 — $LOGDIR/translate.log" >&2; exit 2; }
e2e_label_pr "$REPO" "$TRANS_URL" || true
gh pr edit "$TRANS_URL" --repo "$REPO" --title "[$LABEL] $(gh pr view "$TRANS_URL" --repo "$REPO" --json title --jq .title)" >/dev/null || true
echo "  번역 PR: $TRANS_URL"

# ── 6) 판정 B ─────────────────────────────────────────────────────────
echo "[6/6] 판정 B — 번역 PR 이 ko 를 안 건드리고 en/ja 가 ko 의 id 를 받았나"
set +e
"$CLOUD_TRANSLATE_PY" "$CHECK" --phase translate --repo "$REPO" \
  --ko-pr "$KO_PR" --translation-pr "${TRANS_URL##*/}" --doc "$DOC" --label "$LABEL" \
  | tee "$LOGDIR/check-translate.txt"
RC_B=${PIPESTATUS[0]}
set -e

echo
echo "요약 [$LABEL] base=$BASE_BRANCH · ko PR $KO_PR_URL · 번역 PR $TRANS_URL · log $LOGDIR"
if (( RC_A == 0 && RC_B == 0 )); then echo "ANCHOR_PREASSIGN: OK"; exit 0; fi
echo "ANCHOR_PREASSIGN: REPRO (review=$RC_A translate=$RC_B)"; exit 3
