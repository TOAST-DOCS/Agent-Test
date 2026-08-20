#!/usr/bin/env bash
#
# e2e-concurrent-prs.sh — 같은 ko 파일을 만지는 동시 PR 시나리오 재현/검증.
#
# 시나리오 (실운영에서 가끔 발생하는 순서):
#   1) ko 변경 PR A 생성 (섹션 본문 수정)
#   2) ko 변경 PR B 생성 (신규 섹션 추가 + 표 행 추가) — A 와 같은 파일
#   3) B 머지 → B 번역 (local translate_pr.py) → B 번역 PR 머지
#   4) A 머지 (git 3-way 머지로 ko 는 A+B 모두 반영됨)
#   5) A 번역 (local translate_pr.py)
#   6) 검증: A 번역 PR 의 head 에서 en/ja 가 B 의 콘텐츠(신규 섹션 anchor,
#      표 행)를 **보존**하는지 확인.
#
# 버그 (merge-commit ref 수정 전): A 번역 잡이 new_ko 를 A 의 head 브랜치
# (B 없음), old_ko 를 A 생성 시점 base.sha (B 없음) 에서 읽고 en/ja baseline
# 만 최신이므로, "ko 에 없는 en 섹션 → drop" 경로가 B 의 번역을 지운다.
#
# Exit code: 0 = B 콘텐츠 보존(정상), 1 = B 콘텐츠 유실(버그 재현), 2 = 하네스 오류
#
# Usage:
#   bash e2e-concurrent-prs.sh [--cloud-translate-dir DIR] [--keep]
#
# 의존성: git, gh(로그인), python3. DASHBOARD_* 불필요 (번역은 local 실행).
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
REPO_URL="https://github.com/${REPO}.git"
BASE_SOURCE_BRANCH="alpha"
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY=""
KEEP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: $CLOUD_TRANSLATE_PY 실행 불가" >&2; exit 2; }

TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e/concurrent-${TS}"
BR_A="translate-test/${TS}-conc-a"
BR_B="translate-test/${TS}-conc-b"
TOKEN_B_ANCHOR="concurrent-b-added"          # B 신규 섹션의 anchor id (언어 무관)
TOKEN_B_ROW="x9c"                            # B 신규 표 행의 key 셀 (한글 없음 → 그대로 복사됨)
TOKEN_A_EDIT="concurrent-a-edit"             # A 본문 수정 문장에 심는 ASCII 토큰

WORK="$(mktemp -d /tmp/e2e-concurrent-XXXXXX)"
# e2e 산출물 PR 에 'e2e' 라벨 (사람이 만든 PR 과 구분)
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

LOGDIR="$WORK/logs"; mkdir -p "$LOGDIR"
echo "workdir: $WORK"
cleanup() {
  if (( ! KEEP )); then rm -rf "$WORK"; fi
}
trap cleanup EXIT

echo "[1/8] clone ${REPO} + 세션 브랜치 ${SESSION} + fixture 복원"
git clone --quiet "$REPO_URL" "$WORK/repo"
cd "$WORK/repo"
git checkout --quiet -b "$SESSION" "origin/${BASE_SOURCE_BRANCH}"
git push --quiet origin "$SESSION"
# alpha 의 ko/en/ja 는 다른 작업으로 드리프트할 수 있다 (실측: ko/overview.md
# 만 섹션 2개 앞서가 anchor splice 가 드리프트까지 번역 대상으로 잡아 load
# guard 4.5x 로 스킵). main e2e 의 step 2 처럼 세션 브랜치를 canonical
# 스냅샷(archive/alpha-origin/)으로 복원해 재현을 결정적으로 만든다.
bash scripts/restore-alpha-origin.sh >/dev/null
# 스냅샷의 ko 는 fix-heading-syntax 이전 상태(`###인스턴스 타입` — # 뒤 공백
# 없음)라 splice 가 그 heading 을 경계로 안 보고 flavor 표를 '### 이미지'
# 유닛에 흡수한다 → B 의 표 행 추가가 "표 전체 재번역" 판정 → skip-full-table
# 발화 → LLM-patch fallback 의존 (apply-failed 면 그 언어가 통째로 빠져 FAIL
# 오귀속). main e2e 는 fix-heading-syntax 잡이 정규화하지만 이 스크립트는
# Jenkins 없이 돌므로 로컬로 동등 정규화한다.
sed -i -E 's/^(#{1,6})([^ #])/\1 \2/' ko/*.md en/*.md ja/*.md
if ! git diff --quiet; then
  git add ko en ja
  git commit --quiet -m "e2e(concurrent): normalize heading syntax after restore"
  git push --quiet origin "$SESSION"
fi

# ── ko/overview.md 변형기 ──────────────────────────────────────────────
mutate() {  # $1: a|b
  python3 - "$1" ko/overview.md <<PY
import re, sys
which, path = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()

if which == "a":
    # 기존 섹션 본문 수정: 첫 h2 아래 첫 산문 문단 끝에 문장 추가
    lines = text.split("\n")
    hit = None
    seen_h2 = False
    for i, l in enumerate(lines):
        if l.startswith("## "):
            seen_h2 = True
            continue
        s = l.strip()
        if seen_h2 and s and not s.startswith(("#", "<", "{", "|", "-", "*", ">", "\`")):
            hit = i
            break
    assert hit is not None, "no prose paragraph found"
    lines[hit] = lines[hit] + " (동시 PR 테스트 A: 이 문장은 ${TOKEN_A_EDIT} 검증용입니다.)"
    text = "\n".join(lines)
elif which == "b":
    # (1) 첫 표의 마지막 행 뒤에 신규 행 추가
    lines = text.split("\n")
    last_row = None
    in_table = False
    for i, l in enumerate(lines):
        if l.lstrip().startswith("|"):
            in_table = True
            last_row = i
        elif in_table:
            break
    assert last_row is not None, "no table found"
    lines.insert(last_row + 1, "| ${TOKEN_B_ROW} | 동시 PR 테스트용으로 추가한 타입입니다. 실제 서비스에는 존재하지 않습니다. |")
    text = "\n".join(lines)
    # (2) 문서 끝에 신규 섹션 추가 (anchor + { #id })
    if not text.endswith("\n"):
        text += "\n"
    text += (
        "\n"
        '<a id="${TOKEN_B_ANCHOR}"></a>\n'
        "## 동시 PR 테스트 추가 섹션 { #${TOKEN_B_ANCHOR} }\n"
        "\n"
        "이 섹션은 동시 PR 시나리오 검증을 위해 PR B 가 추가한 섹션입니다. "
        "PR A 의 번역이 이 섹션의 번역을 지우면 안 됩니다.\n"
    )
open(path, "w", encoding="utf-8").write(text)
PY
}

make_pr() {  # $1: branch  $2: a|b  $3: title  → PR URL 출력
  git checkout --quiet -b "$1" "$SESSION"
  mutate "$2"
  git add ko/overview.md
  git commit --quiet -m "$3"
  git push --quiet origin "$1"
  gh pr create --repo "$REPO" --base "$SESSION" --head "$1" \
    --title "$3" --body "concurrent-PR e2e ($2)" --label "$E2E_LABEL" 2>/dev/null | tail -1
  git checkout --quiet "$SESSION"
}

e2e_ensure_label "$REPO"

echo "[2/8] PR A 생성 (본문 수정)"
PR_A_URL="$(make_pr "$BR_A" a "[e2e] concurrent PR A — body edit (${TS})")"
echo "  A: $PR_A_URL"

echo "[3/8] PR B 생성 (신규 섹션 + 표 행)"
PR_B_URL="$(make_pr "$BR_B" b "[e2e] concurrent PR B — new section + table row (${TS})")"
echo "  B: $PR_B_URL"

merge_pr() {  # $1: PR URL
  gh pr merge "$1" --repo "$REPO" --merge >/dev/null
}

run_translate() {  # $1: PR URL  $2: 로그 이름  → 번역 PR URL 출력
  local log="$LOGDIR/$2.log"
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_TRANSLATE_ENGINE=api \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$1" \
      --diff-granularity block --glossary-mode service --max-load-ratio 2 \
      --workers 2 --chunk-workers 2 --tm-top-k 1 \
      --table-rows --skip-full-table --skip-anchor-only \
      --assign-anchors --align-headings --llm-patch-fallback \
      --fix-korean-leftover \
  ) >"$log" 2>&1 || { echo "error: translate_pr.py 실패 — $log" >&2; tail -30 "$log" >&2; exit 2; }
  grep -oE 'Translation PR: https://[^ ]+' "$log" | tail -1 | sed 's/Translation PR: //'
}

echo "[4/8] B 머지 → B 번역 → B 번역 PR 머지"
merge_pr "$PR_B_URL"
TRANS_B_URL="$(run_translate "$PR_B_URL" translate-b)"
[[ -n "$TRANS_B_URL" ]] || { echo "error: B 번역 PR URL 파싱 실패 — $LOGDIR/translate-b.log" >&2; exit 2; }
echo "  B 번역 PR: $TRANS_B_URL"
e2e_label_pr "$REPO" "$TRANS_B_URL"
merge_pr "$TRANS_B_URL"
echo "  B 번역 PR 머지 완료"

# sanity: 세션 브랜치 en/ja 양쪽에 B 콘텐츠가 실제로 들어갔는지 — 여기서
# 빠진 언어는 A 가 지운 게 아니라 B 번역이 스킵된 것이므로 exit 2 (하네스
# 전제 실패)로 구분한다. 실측: skip-full-table→LLM-patch apply-failed 로 ja 가
# B 번역 PR 에서 통째로 빠져 step 7 이 FAIL 을 오귀속한 적 있음.
git fetch --quiet origin "$SESSION"
for lang in en ja; do
  for tok in "$TOKEN_B_ANCHOR" "$TOKEN_B_ROW"; do
    if ! git show "origin/${SESSION}:${lang}/overview.md" | grep -q "$tok"; then
      echo "error: B 번역이 세션 브랜치 ${lang} 에 반영되지 않음 (token=${tok} — 하네스 전제 실패)" >&2
      exit 2
    fi
  done
done

echo "[5/8] A 머지"
merge_pr "$PR_A_URL"
git fetch --quiet origin "$SESSION"
if ! git show "origin/${SESSION}:ko/overview.md" | grep -q "$TOKEN_B_ANCHOR"; then
  echo "error: A 머지 후 ko 에서 B 섹션이 사라짐 — git 머지 자체가 예상과 다름" >&2
  exit 2
fi

echo "[6/8] A 번역"
TRANS_A_URL="$(run_translate "$PR_A_URL" translate-a)"
[[ -n "$TRANS_A_URL" ]] || { echo "error: A 번역 PR URL 파싱 실패 — $LOGDIR/translate-a.log" >&2; exit 2; }
echo "  A 번역 PR: $TRANS_A_URL"
e2e_label_pr "$REPO" "$TRANS_A_URL"

echo "[7/8] 검증: A 번역 PR head 의 en/ja 가 B 콘텐츠를 보존하는가"
TRANS_A_NUM="${TRANS_A_URL##*/}"
TRANS_A_REF="$(gh api "repos/${REPO}/pulls/${TRANS_A_NUM}" -q .head.ref)"
git fetch --quiet origin "$TRANS_A_REF"
TRANS_A_HEAD="FETCH_HEAD"

fail=0
for lang in en ja; do
  content="$(git show "${TRANS_A_HEAD}:${lang}/overview.md" 2>/dev/null || true)"
  if [[ -z "$content" ]]; then
    echo "  [$lang] overview.md 없음/미변경 — PR 파일 목록 확인 필요"
    continue
  fi
  for tok in "$TOKEN_B_ANCHOR" "$TOKEN_B_ROW"; do
    if grep -q "$tok" <<<"$content"; then
      echo "  [$lang] B 토큰 '$tok': PRESENT ✓"
    else
      echo "  [$lang] B 토큰 '$tok': MISSING ✗  ← B 콘텐츠 유실"
      fail=1
    fi
  done
  if grep -qi "$TOKEN_A_EDIT" <<<"$content"; then
    echo "  [$lang] A 편집 토큰: PRESENT ✓"
  else
    echo "  [$lang] A 편집 토큰: MISSING (sanity — 비치명, 모델이 토큰을 번역했을 수 있음)"
  fi
done

echo "[8/8] 결과"
echo "  session:      $SESSION"
echo "  PR A:         $PR_A_URL"
echo "  PR B:         $PR_B_URL"
echo "  B 번역 PR:    $TRANS_B_URL (머지됨)"
echo "  A 번역 PR:    $TRANS_A_URL"
if (( fail )); then
  echo "RESULT: FAIL — A 번역 PR 이 B 의 en/ja 콘텐츠를 유실 (버그 재현)"
  exit 1
fi
echo "RESULT: PASS — B 콘텐츠 보존"
