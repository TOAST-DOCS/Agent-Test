#!/usr/bin/env bash
#
# e2e-translation-lag-order.sh — 앞선 번역 PR 이 아직 미머지인 창(window) 안에서
# 다른 ko PR 이 머지될 때, 그 ko PR 의 번역 잡이 "ko 에는 있는데 번역본에 없는"
# 섹션을 다시 번역해 넣지 않는지 검증한다 (nhn-cloud-foundry#37→#38 재현,
# Dooray cloud-user-guide-agent/359).
#
# 시나리오 (실운영 순서 그대로):
#   1) ko 변경 PR B 생성 (문서 끝에 신규 섹션 추가)
#   2) ko 변경 PR A 생성 (다른 섹션 본문 수정 — B 와 무관)
#   3) B 머지 → B 번역 (local translate_pr.py) → B 번역 PR 은 **열어 둔다**
#   4) A 머지 (ko 에는 B 섹션이 있고, en/ja 에는 아직 없다)
#   5) A 번역 (local translate_pr.py)
#   6) 검증 1: A 번역 PR 의 en/ja 에 B 섹션이 **없다** — A 의 잡은 자기 diff 안에서만
#      움직여야 하고, B 섹션은 B 번역 PR 이 넣을 것이다. (수정 전: 여기서 다시
#      번역해 넣는다)
#   7) B 번역 PR 머지 → A 번역 PR 머지 (실제 사건의 #36 → #38 순서)
#   8) 검증 2: 세션 브랜치 en/ja 에 B 섹션 anchor 가 **정확히 1번** — 수정 전엔
#      3-way 머지가 두 삽입을 다른 위치의 추가로 보고 둘 다 남겨 2번이 된다.
#
# e2e-concurrent-prs.sh 의 거울상이다: 그쪽은 "앞선 번역이 이미 머지된" 순서에서
# A 의 번역이 B 의 번역을 **지우지 않는지**, 이쪽은 "앞선 번역이 아직 안 머지된"
# 순서에서 A 의 번역이 B 의 섹션을 **다시 넣지 않는지** 본다. 둘 다 통과해야
# 번역 잡이 머지 순서와 무관하다고 말할 수 있다.
#
# Exit code: 0 = 정상 (A 가 B 섹션을 넣지 않았고 최종 1회), 1 = 결함 재현
#            (A 가 다시 넣었거나 최종 2회), 2 = 하네스 오류
#
# 픽스처는 `{ko,en,ja}/fix-links.md` (--doc 로 변경) — 세 언어가 heading 마다 같은
# `<a id>` 를 갖는, 운영의 pre-align 된 문서와 같은 모양이라 A 의 번역이 자기 diff 안에서만
# 움직인다. `overview.md` 는 앵커 없는 `###`/`####` 소절 3개가 매 실행 재번역돼
# (heading 텍스트 `__line__` 키는 언어 간에 절대 안 맞는다) B·A 두 번역 PR 이 같은
# 절을 다른 문장으로 다시 써 검증 2 의 머지가 충돌한다 (2026-09-10 실측) — 그 churn 은
# 이 e2e 의 대상이 아니다.
#
# Usage:
#   bash e2e-translation-lag-order.sh [--cloud-translate-dir DIR] [--doc <stem>.md] [--keep]
#
# 의존성: git, gh(로그인), python3, DASHBOARD_* (webhook 토글). 번역은 local 실행.
set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
REPO_URL="https://github.com/${REPO}.git"
BASE_SOURCE_BRANCH="alpha"
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
KEEP=0
DOC="${DOC:-fix-links.md}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --doc) DOC="$2"; shift 2 ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: $CLOUD_TRANSLATE_PY 실행 불가" >&2; exit 2; }

TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e/lag-order-${TS}"
BR_A="translate-test/${TS}-lag-a"
BR_B="translate-test/${TS}-lag-b"
TOKEN_B_ANCHOR="lag-order-b-added"       # B 신규 섹션의 anchor id (언어 무관)
TOKEN_A_EDIT="lag-order-a-edit"          # A 본문 수정 문장에 심는 ASCII 토큰

WORK="$(mktemp -d /tmp/e2e-lag-order-XXXXXX)"
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

# webhook 이 켜져 있으면 이 e2e 의 머지가 배포된 translate 잡을 중복 트리거해
# 로컬 번역과 섞인다 (e2e-concurrent-prs.sh 와 같은 이유).
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화"
set_webhook_repo_enabled false

LOGDIR="$WORK/logs"; mkdir -p "$LOGDIR"
echo "workdir: $WORK"
cleanup() { if (( ! KEEP )); then rm -rf "$WORK"; fi; }
trap cleanup EXIT

echo "[1/9] clone ${REPO} + 세션 브랜치 ${SESSION} + fixture 복원 (doc=${DOC})"
git clone --quiet "$REPO_URL" "$WORK/repo"
cd "$WORK/repo"
git checkout --quiet -b "$SESSION" "origin/${BASE_SOURCE_BRANCH}"
git push --quiet origin "$SESSION"
bash scripts/restore-alpha-origin.sh >/dev/null
# concurrent e2e 와 같은 정규화 — 스냅샷 ko 의 `###제목`(공백 없음) 이 splice 경계로
# 안 잡혀 표가 이웃 유닛에 흡수되는 것을 막는다.
sed -i -E 's/^(#{1,6})([^ #])/\1 \2/' ko/*.md en/*.md ja/*.md
# en/ja 에 `<!-- machine_translated: true -->` 헤더를 미리 둔다 — 사건의 문서
# (nhn-cloud-foundry en/api-guide.md) 가 그 모양이다. 없으면 B·A 두 번역 PR 이 모두
# 맨 위에 그 줄을 새로 넣고 B 는 바로 아래 pre-align 마커의 sig 까지 갱신하므로,
# 내용은 같아도 같은 자리를 건드린 두 hunk 로 git 이 충돌을 낸다 (2026-09-10 실측).
# 그 충돌은 "헤더 없는 문서의 첫 번역이 창 안에서 겹친" 별건이고 사람이 푸는 것이라
# 이 e2e 의 대상이 아니다.
for lang in en ja; do
  if ! head -1 "$lang/$DOC" | grep -q "machine_translated"; then
    printf '<!-- machine_translated: true -->\n\n%s' "$(cat "$lang/$DOC")" > "$lang/$DOC"
    echo >> "$lang/$DOC"
  fi
done
if ! git diff --quiet; then
  git add ko en ja
  git commit --quiet -m "e2e(lag-order): normalize heading syntax + machine_translated header after restore"
  git push --quiet origin "$SESSION"
fi

mutate() {  # $1: a|b
  python3 - "$1" "ko/$DOC" <<PY
import sys
which, path = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
if which == "a":
    # 첫 h2 아래 첫 산문 문단 끝에 문장 추가 (B 와 다른 섹션)
    lines = text.split("\n")
    hit = None; seen_h2 = False
    for i, l in enumerate(lines):
        if l.startswith("## "):
            seen_h2 = True; continue
        s = l.strip()
        if seen_h2 and s and not s.startswith(("#", "<", "{", "|", "-", "*", ">", "\`")):
            hit = i; break
    assert hit is not None, "no prose paragraph found"
    lines[hit] = lines[hit] + " (순서 테스트 A: 이 문장은 ${TOKEN_A_EDIT} 검증용입니다.)"
    text = "\n".join(lines)
elif which == "b":
    if not text.endswith("\n"):
        text += "\n"
    text += (
        "\n"
        '<a id="${TOKEN_B_ANCHOR}"></a>\n'
        "## 번역 지연 순서 테스트 섹션 { #${TOKEN_B_ANCHOR} }\n"
        "\n"
        "이 섹션은 PR B 가 추가했습니다. PR A 의 번역 잡은 이 섹션을 건드리지 않아야 하고, "
        "B 의 번역 PR 이 머지되면 en/ja 에 한 번만 있어야 합니다.\n"
    )
open(path, "w", encoding="utf-8").write(text)
PY
}

make_pr() {  # $1: branch  $2: a|b  $3: title  → PR URL
  git checkout --quiet -b "$1" "$SESSION"
  mutate "$2"
  git add "ko/$DOC"
  git commit --quiet -m "$3"
  git push --quiet origin "$1"
  gh pr create --repo "$REPO" --base "$SESSION" --head "$1" \
    --title "$3" --body "translation-lag-order e2e ($2)" --label "$E2E_LABEL" 2>/dev/null | tail -1
  git checkout --quiet "$SESSION"
}
merge_pr() { gh pr merge "$1" --repo "$REPO" --merge >/dev/null; }

run_translate() {  # $1: PR URL  $2: 로그 이름 → 번역 PR URL
  local log="$LOGDIR/$2.log"
  # e2e 는 CLI 엔진으로 돈다 (프로덕션과 같은 경로). 모델은 두 env 모두 세팅 —
  # 이유는 e2e-concurrent-prs.sh 의 같은 자리 주석 참고.
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$1" \
      --diff-granularity block --glossary-mode service --max-load-ratio 2 \
      --workers 2 --chunk-workers 2 --tm-top-k 1 \
      --table-rows --skip-full-table --skip-anchor-only \
      --assign-anchors --align-headings --llm-patch-fallback \
      --fix-korean-leftover \
  ) >"$log" 2>&1 || { echo "error: translate_pr.py 실패 — $log" >&2; tail -30 "$log" >&2; exit 2; }
  grep -oE 'Translation PR: https://[^ ]+' "$log" | tail -1 | sed 's/Translation PR: //'
}

e2e_ensure_label "$REPO"

echo "[2/9] PR B 생성 (신규 섹션)"
PR_B_URL="$(make_pr "$BR_B" b "[e2e] lag-order PR B — new section (${TS})")"
echo "  B: $PR_B_URL"
echo "[3/9] PR A 생성 (다른 섹션 본문 수정)"
PR_A_URL="$(make_pr "$BR_A" a "[e2e] lag-order PR A — body edit (${TS})")"
echo "  A: $PR_A_URL"

echo "[4/9] B 머지 → B 번역 (번역 PR 은 열어 둠)"
merge_pr "$PR_B_URL"
TRANS_B_URL="$(run_translate "$PR_B_URL" translate-b)"
[[ -n "$TRANS_B_URL" ]] || { echo "error: B 번역 PR URL 파싱 실패 — $LOGDIR/translate-b.log" >&2; exit 2; }
echo "  B 번역 PR: $TRANS_B_URL (미머지)"
e2e_label_pr "$REPO" "$TRANS_B_URL"
# 하네스 전제: B 번역 PR 이 en/ja 에 B 섹션을 실제로 넣었는가
TRANS_B_NUM="${TRANS_B_URL##*/}"
TRANS_B_REF="$(gh api "repos/${REPO}/pulls/${TRANS_B_NUM}" -q .head.ref)"
git fetch --quiet origin "$TRANS_B_REF"
for lang in en ja; do
  if ! git show "FETCH_HEAD:${lang}/$DOC" | grep -q "$TOKEN_B_ANCHOR"; then
    echo "error: B 번역 PR 의 ${lang} 에 B 섹션이 없음 (하네스 전제 실패)" >&2; exit 2
  fi
done

echo "[5/9] A 머지 (ko 에 B 섹션 있음 · en/ja 에는 아직 없음)"
merge_pr "$PR_A_URL"
git fetch --quiet origin "$SESSION"
git show "origin/${SESSION}:ko/$DOC" | grep -q "$TOKEN_B_ANCHOR" \
  || { echo "error: A 머지 후 ko 에 B 섹션이 없음" >&2; exit 2; }
if git show "origin/${SESSION}:en/$DOC" | grep -q "$TOKEN_B_ANCHOR"; then
  echo "error: en 에 B 섹션이 이미 있음 — 창(window) 재현 실패" >&2; exit 2
fi

echo "[6/9] A 번역"
TRANS_A_URL="$(run_translate "$PR_A_URL" translate-a)"
[[ -n "$TRANS_A_URL" ]] || { echo "error: A 번역 PR URL 파싱 실패 — $LOGDIR/translate-a.log" >&2; exit 2; }
echo "  A 번역 PR: $TRANS_A_URL"
e2e_label_pr "$REPO" "$TRANS_A_URL"

echo "[7/9] 검증 1: A 번역 PR 의 en/ja 는 B 섹션을 넣지 않았는가"
TRANS_A_NUM="${TRANS_A_URL##*/}"
TRANS_A_REF="$(gh api "repos/${REPO}/pulls/${TRANS_A_NUM}" -q .head.ref)"
git fetch --quiet origin "$TRANS_A_REF"
fail=0
for lang in en ja; do
  content="$(git show "FETCH_HEAD:${lang}/$DOC" 2>/dev/null || true)"
  if [[ -z "$content" ]]; then echo "  [$lang] $DOC 없음/미변경"; continue; fi
  if grep -q "$TOKEN_B_ANCHOR" <<<"$content"; then
    echo "  [$lang] B 섹션: PRESENT ✗  ← A 의 잡이 자기 diff 밖의 섹션을 다시 번역해 넣었다"
    fail=1
  else
    echo "  [$lang] B 섹션: ABSENT ✓ (B 번역 PR 의 몫으로 남김)"
  fi
  if grep -qi "$TOKEN_A_EDIT" <<<"$content"; then
    echo "  [$lang] A 편집 토큰: PRESENT ✓"
  else
    echo "  [$lang] A 편집 토큰: MISSING (sanity — 비치명, 모델이 토큰을 번역했을 수 있음)"
  fi
done
if grep -q "left [0-9]* pre-existing ko section(s) untranslated" "$LOGDIR/translate-a.log"; then
  echo "  로그: 'left N pre-existing ko section(s) untranslated' ✓"
else
  echo "  로그: 건너뜀 메시지 없음 (경로가 anchor splice 가 아니었을 수 있음 — 아래 참고)"
  grep -E "anchor splice|full translation|fallback|reconcile" "$LOGDIR/translate-a.log" | head -5 | sed 's/^/    /'
fi

echo "[8/9] B 번역 PR 머지 → A 번역 PR 머지 (#36 → #38 순서)"
merge_pr "$TRANS_B_URL"
if ! merge_pr "$TRANS_A_URL"; then
  echo "error: A 번역 PR 머지 실패 (충돌?) — $TRANS_A_URL" >&2; exit 2
fi
git fetch --quiet origin "$SESSION"

echo "[9/9] 검증 2: 세션 브랜치 en/ja 에 B 섹션 anchor 가 정확히 1번인가"
for lang in ko en ja; do
  n="$(git show "origin/${SESSION}:${lang}/$DOC" | grep -c "<a id=\"${TOKEN_B_ANCHOR}\"></a>" || true)"
  h="$(git show "origin/${SESSION}:${lang}/$DOC" | grep -c "{ #${TOKEN_B_ANCHOR} }" || true)"
  if [[ "$n" == "1" && "$h" == "1" ]]; then
    echo "  [$lang] anchor ×$n · heading ×$h ✓"
  else
    echo "  [$lang] anchor ×$n · heading ×$h ✗  ← 사본 중복 (또는 유실)"
    [[ "$lang" == "ko" ]] || fail=1
  fi
done

echo "결과"
echo "  session:      $SESSION"
echo "  PR A:         $PR_A_URL"
echo "  PR B:         $PR_B_URL"
echo "  B 번역 PR:    $TRANS_B_URL (머지됨)"
echo "  A 번역 PR:    $TRANS_A_URL (머지됨)"
if (( fail )); then
  echo "RESULT: FAIL — A 의 번역이 B 섹션을 다시 넣었거나 최종 사본이 1개가 아님 (결함 재현)"
  exit 1
fi
echo "RESULT: PASS — 번역 잡이 자기 PR 의 diff 안에서만 움직였고 최종 사본 1개"
