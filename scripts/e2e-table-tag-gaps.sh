#!/usr/bin/env bash
#
# table-tag-gaps e2e — ko 가 표 행 사이 템플릿 태그를 `{%` → `{%-` 로만 고쳤을 때
# en/ja 가 ko 를 따라 표를 되살리는가, 그리고 ko 가 건드리지 않은 표를 지우지 않는가
# (cloud-translate `_mirror_table_tag_gaps` · `_stub_incomplete_tables`).
#
# ── 재현하는 결함 (TOAST-DOCS/Compute-Instance#335 → 번역 PR #338) ──────────
# ko 템플릿화 PR 이 표 행 사이에 `{% if %}`/`{% else %}`/`{% endif %}` 를 넣었고,
# #1255 이전 번역이 그 태그 앞뒤에 빈 줄을 박았다 (public-api 10 → 39곳). 빈 줄은
# 빌드에서 표를 끊는다. 그 상태에서:
#   (가) ko 를 마크업 정정(M11, `{%` → `{%-`)으로 고쳐도 재번역 단위는 태그 줄뿐이라
#        en/ja 의 빈 줄은 "바뀌지 않은 기존 번역" 으로 그대로 남는다 → 계속 깨짐.
#   (나) 빈 줄 때문에 en/ja 의 표가 ko 보다 하나 적게 세어지고, 완성도 백스톱이 표를
#        **순번**으로 짝지어 한 칸 밀린 채 비교한다 → ko "인스턴스 생성 › 요청" 표의
#        키를 en "인스턴스 생성 › 응답" 표에서 찾다가 **멀쩡한 응답 표를 지운다**.
#
# ── 픽스처 (archive/table-tag-gaps/ — 실제 Compute-Instance `public-api.md` 발췌) ──
#   ko-broken.md  #335 머지 후 ko (M11: 표 행 사이 `{%`)           → 세션 base 의 ko
#   ko-fixed.md   그 태그만 `{%-` 로 바꾼 ko (마크업 정정 결과)     → ko PR 의 head
#   en.md/ja.md   #338 head 의 en/ja, 단 응답 표는 지워지기 전 모양 → 세션 base 의 en/ja
#   절: 문서 첫머리(엔드포인트 표) · 인스턴스 생성(요청·응답) · 수정 · 삭제 · 블록
#   스토리지 연결 4종 · 정지/종료 인스턴스 시작 — 결함이 드러나는 데 필요한 표만 남겼다.
#
# ── 판정 (전부 결정적 — 모델 표현과 무관) ────────────────────────────────────
#   [A] 결정적 층 — 이상적 모델(입력 그대로 반환)로 같은 입력을 `translate_diff` 에 태움
#       (1) en/ja 표 수 = ko · 태그 옆 빈 줄 = ko · 표 밖으로 새는 행 = ko   ← 결함 (가)
#       (2) en/ja `<todo: translate>` 0 · 응답 표가 기존 번역과 바이트 동일  ← 결함 (나)
#   [B] 산출물 층 — 로컬 translate_pr.py (CLI 엔진, 권장 preset) 실제 번역
#       (3) 번역 성공 (exit 0, PARTIAL 없음)
#       (4) = (1) 을 번역 PR 의 en/ja 에서                                   ← 결함 (가)
#       (5) = (2) 를 번역 PR 의 en/ja 에서                                   ← 결함 (나)
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`TABLE_TAG_GAPS: OK`)    — 수정된 코드의 기대값
#   3  결함 재현 (`TABLE_TAG_GAPS: REPRO`) — 수정 전 코드의 기대값
#   1  기능 규칙 실패 (`TABLE_TAG_GAPS: FAIL`)
#   2  인프라 — 번역 PR 미감지 등
#
# Usage:
#   source ./load_env.sh
#   CLOUD_TRANSLATE_DIR=<검증할 cloud-translate 체크아웃> \
#     bash scripts/e2e-table-tag-gaps.sh [--label BEFORE|AFTER] [--keep] [--dry]
#
# `--label` 은 ko PR·번역 PR 제목 앞에 `[BEFORE]`/`[AFTER]` 를 붙인다 — 같은 픽스처로
# 코드만 바꿔 두 번 돌려 서로 링크하는 before/after 대조용.
#
# ko 변경이 언어 중립인 태그 줄뿐이라 **모델 호출은 0회**가 정상이다 (실측: BEFORE·AFTER
# 모두 API 0 · CLI 0). 그래도 `translate_pr.py` 는 설정을 끝까지 읽으므로, 검증할
# 체크아웃이 모르는 가이드라인 변형을 `.env` 가 지정하면 잡이 시작도 못 한다
# (`Unknown guidelines variant`) — 그때는 운영 기본값으로 맞춰 돌린다:
#   TRANSLATE_GUIDELINES_VARIANT_EN=unified-v2 TRANSLATE_GUIDELINES_VARIANT_JA=unified
#
# 공유 체크아웃의 HEAD 는 건드리지 않는다 — 커밋은 전부 임시 git worktree 에서 한다.
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-tagtablegaps/$TS"
HEAD_BRANCH="translate-test-tagtablegaps/$TS"
DOC="table-tag-gaps.md"
KEEP=0
DRY=0
LABEL=""

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)  KEEP=1; shift ;;
    --dry)   DRY=1; shift ;;
    --label) LABEL="$2"; shift 2 ;;
    -h|--help) sed -n '2,54p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
PFX="${LABEL:+[$LABEL] }"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIX="$REPO_ROOT/archive/table-tag-gaps"
CHECK="$SCRIPT_DIR/check_table_tag_gaps.py"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"
ko_pr_url=""; tx_pr_url=""

source "$SCRIPT_DIR/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/seed" "$tmpdir/tx"; do
    [[ -d "$wt" ]] && git -C "$REPO_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( KEEP )) || (( DRY )); then
    (( DRY )) || { echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${ko_pr_url:-없음}, 번역 PR: ${tx_pr_url:-없음})"; }
    return $rc
  fi
  echo; echo "[cleanup] PR 닫기 · 브랜치 정리"
  [[ -n "$tx_pr_url" ]] && gh pr close "$tx_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  [[ -n "$ko_pr_url" ]] && gh pr close "$ko_pr_url" --repo "$REPO" >/dev/null 2>&1 || true
  git -C "$REPO_ROOT" push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git -C "$REPO_ROOT" push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  return $rc
}
trap cleanup EXIT

echo "=== table-tag-gaps e2e ${LABEL:+($LABEL)} ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR"
echo "  session         : $SESSION_BRANCH"
echo "  픽스처          : $FIX → {ko,en,ja}/$DOC"
echo

[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }
for f in ko-broken.md ko-fixed.md en.md ja.md; do
  [[ -f "$FIX/$f" ]] || { echo "error: 픽스처 없음: $FIX/$f" >&2; exit 1; }
done

fails=0; repro=0
ok()    { echo "  PASS  $1"; }
bad()   { echo "  FAIL  $1"; fails=$((fails + 1)); }
defect(){ echo "  FAIL  $1  (결함 — 재현)"; repro=$((repro + 1)); }

ct() { (cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" "$CHECK" "$@"); }

# judge <lang> <result> <baseline> — (가)·(나) 두 축을 한 번에. 수치는 stderr 로,
# `GA=… NA=…` 만 stdout 으로 (호출부가 eval). `tee /dev/stderr` 를 쓰면 안 된다 —
# stderr 가 파일로 리다이렉트돼 있으면 /dev/stderr 를 다시 열면서 로그를 처음부터 덮는다.
judge() {
  local lang="$1" res="$2" base="$3" j
  j="$(ct measure "$FIX/ko-fixed.md" "$res" "$base")"
  echo "    [$lang] $j" >&2
  python3 - "$j" <<'PY'
import json, sys
r = json.loads(sys.argv[1]); k = r["ko"]
a = all(r[x] == k[x] for x in ("tables", "tag_blank", "leak"))
b = r["todo"] == 0 and r["response"]
print(f"GA={int(a)} NA={int(b)}")
PY
}

# ── [A] 결정적 층 ──────────────────────────────────────────────────────────
echo "[A] 결정적 층 — 이상적 모델로 translate_diff (모델 편차 없음)"
A_GA=0; A_NA=0
for lang in en ja; do
  echo "  $(ct replay "$FIX/ko-broken.md" "$FIX/ko-fixed.md" "$FIX/$lang.md" "$lang" "$tmpdir/a_$lang.md")" | sed "s/^/  [$lang] replay /"
  eval "$(judge "$lang" "$tmpdir/a_$lang.md" "$FIX/$lang.md")"
  A_GA=$((A_GA + GA)); A_NA=$((A_NA + NA))
done
(( A_GA == 2 )) && ok "(1) en/ja 표 수 · 태그 옆 빈 줄 · 새는 행이 ko 와 같다" \
                || defect "(1) en/ja 의 태그 옆 빈 줄이 남아 표가 끊긴다 ($A_GA/2 언어 정상)"
(( A_NA == 2 )) && ok "(2) <todo: translate> 0 · 응답 표가 기존 번역 그대로" \
                || defect "(2) ko 가 안 건드린 응답 표가 지워졌다 ($A_NA/2 언어 정상)"

if (( DRY )); then
  echo
  if (( fails == 0 && repro == 0 )); then echo "TABLE_TAG_GAPS: OK"; exit 0; fi
  if (( fails == 0 )); then echo "TABLE_TAG_GAPS: REPRO"; exit 3; fi
  echo "TABLE_TAG_GAPS: FAIL"; exit 1
fi

: "${DASHBOARD_BASE_URL:?load_env.sh 를 source 하라 (webhook 토글 · preset)}"
: "${DASHBOARD_API_TOKEN:?load_env.sh 를 source 하라 (webhook 토글 · preset)}"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
source "$SCRIPT_DIR/e2e-webhook-toggle.sh"
echo
echo "[0] webhook 비활성화"
set_webhook_repo_enabled false

# ── 1) 세션 브랜치 + ko PR (임시 worktree 에서 — 공유 HEAD 를 건드리지 않는다) ──
echo "[1] 세션 브랜치 · ko PR"
git -C "$REPO_ROOT" fetch -q origin "$BASE_SOURCE"
git -C "$REPO_ROOT" worktree add -q --detach "$tmpdir/seed" "origin/$BASE_SOURCE"
(
  cd "$tmpdir/seed"
  cp "$FIX/ko-broken.md" "ko/$DOC"; cp "$FIX/en.md" "en/$DOC"; cp "$FIX/ja.md" "ja/$DOC"
  git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
  git commit -q -m "e2e(table-tag-gaps): 픽스처 시드 — #338 모양 ($TS)"
  git push -q origin "HEAD:refs/heads/$SESSION_BRANCH"
  cp "$FIX/ko-fixed.md" "ko/$DOC"
  git add -- "ko/$DOC"
  git commit -q -m "e2e(table-tag-gaps): ko 표 행 사이 태그 {% → {%- (마크업 정정 M11) ($TS)"
  git push -q origin "HEAD:refs/heads/$HEAD_BRANCH"
)
base_sha="$(git -C "$REPO_ROOT" ls-remote origin "refs/heads/$SESSION_BRANCH" | cut -f1)"
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "${PFX}e2e(table-tag-gaps): ko 표 행 사이 태그 {% → {%- — Compute-Instance#338 재현 ($TS)" \
  --body "ko 는 태그 줄만 바꾼다 (\`{%\` → \`{%-\`). en/ja 는 표를 되살리고, ko 가 건드리지 않은 \`#create-instance-response\` 표를 그대로 둬야 한다 (cloud-translate \`_mirror_table_tag_gaps\` · \`_stub_incomplete_tables\`)." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

# ── 2) [B] 실제 번역 ───────────────────────────────────────────────────────
echo
echo "[2] [B] 실제 번역 — 로컬 translate_pr.py (CLI 엔진, 권장 preset)"
preset_eval="$(python3 "$SCRIPT_DIR/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 1
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") 2>&1 | tee "$LOG" \
  | grep -E "table completeness|todo|Translation PR|PARTIAL|ERROR" | sed 's/^/    /'
tx_rc=${PIPESTATUS[0]}
set -e
if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(3) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(3) 번역 실패/부분 (exit $tx_rc)"
fi
grep -o 'engine=[a-z-]*' "$LOG" | sort | uniq -c | sed 's/^/    /' || true
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지 — 로그 $LOG" >&2; KEEP=1; exit 2; }
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url" || true
if [[ -n "$PFX" ]]; then
  t="$(gh pr view "$tx_pr_url" --repo "$REPO" --json title --jq .title)"
  gh pr edit "$tx_pr_url" --repo "$REPO" --title "${PFX}$t" >/dev/null 2>&1 || true
fi
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git -C "$REPO_ROOT" fetch -q origin "$tx_head"
git -C "$REPO_ROOT" worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"

echo
echo "[3] 산출물 판정"
B_GA=0; B_NA=0
for lang in en ja; do
  eval "$(judge "$lang" "$tmpdir/tx/$lang/$DOC" "$FIX/$lang.md")"
  B_GA=$((B_GA + GA)); B_NA=$((B_NA + NA))
done
(( B_GA == 2 )) && ok "(4) 번역 PR en/ja 의 표 수 · 태그 옆 빈 줄 · 새는 행이 ko 와 같다" \
                || defect "(4) 번역 PR 의 en/ja 표가 태그 옆 빈 줄로 끊겨 있다 ($B_GA/2 언어 정상)"
(( B_NA == 2 )) && ok "(5) 번역 PR 에 <todo: translate> 없음 · 응답 표가 기존 번역 그대로" \
                || defect "(5) 번역 PR 이 ko 가 안 건드린 응답 표를 지웠다 ($B_NA/2 언어 정상)"
labels="$(gh pr view "$tx_pr_url" --repo "$REPO" --json labels --jq '[.labels[].name]|join(",")')"
echo "    번역 PR 라벨: $labels"

echo
echo "[4] 결과"
echo "  ko PR: $ko_pr_url"
echo "  번역 PR: $tx_pr_url"
echo "  세션 base: $SESSION_BRANCH @ ${base_sha:0:10}"
KEEP=1   # before/after 대조와 스크린샷을 위해 PR 은 남긴다 — 정리는 수동
if (( fails == 0 && repro == 0 )); then echo "TABLE_TAG_GAPS: OK"; exit 0; fi
if (( fails == 0 )); then echo "TABLE_TAG_GAPS: REPRO"; exit 3; fi
echo "TABLE_TAG_GAPS: FAIL"; exit 1
