#!/usr/bin/env bash
#
# 템플릿 태그 e2e — mkdocs-macros / Jinja 태그가 번역을 거친 뒤에도 빌드되고,
# 태그 **안의 한글 문자열**은 번역되는지. cloud-translate #891 검증.
#
# ── 배경 ──────────────────────────────────────────────────────────────────
# #856 은 태그를 플레이스홀더로 가리고 바이트 그대로 복원한다 — 태그의 구조에는
# 맞고, 저자가 독자에게 보이려고 태그 안에 넣은 문자열에는 틀리다:
#     $[ " 또는 복제 대상 컨테이너로" if replication else "로" ]$   (Storage-Object-Storage)
#     {%- set region_names = "한국(판교) 리전" -%}                  (Private-DNS)
#     $[ interface_response_table('interface.', '생성된 ') ]$       (Storage-Online-NAS)
#     {{ 칼럼 이름 }}                                                (nhn-cloud-foundry; Jinja 아님)
# 복원하면 en/ja 페이지에 한글이 남고, 태그만 있는 유닛은 모델 호출 없이 ko 가
# 복사됐다. #891 은 한글이 든 태그를 가리지 않고 모델이 문장째 보게 한 뒤,
# 구조 비교 + 재시도 + 한글 잔류 게이트로 빌드를 지킨다. 리터럴만 따로 번역하는
# 방식(#865)은 `"로"` 가 `"Replace with"` 로 돌아와 택하지 않았다 — 모델이 문장을
# 봐야 하는 이유가 곧 이 e2e 가 **실제 모델**로 돌아야 하는 이유다.
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# `{ko,en,ja}/template-tags.md` — 위 네 모양에 더해 `{% if/elif/else %}` 다중
# 분기·`-` 공백 제어·`{% macro %}` 표 본문·`{# 주석 #}`·표 안 `$[ var ]$`·
# `{{executionTime}}`·문단을 감싼 조건부·한 줄 조건부·코드 블록 안 태그.
# 세 언어가 같은 heading outline 을 가져 aligned sig 가 같고, ko/en/ja 모두
# 사이트의 Jinja 설정(`$[ ]$` 변수 구분자)으로 public/gov/ngsc 렌더가 통과한다.
# `archive/alpha-origin/` 에도 있어 restore 를 살아남는다.
#
# ── 흐름 (라운드마다) ─────────────────────────────────────────────────────
#   splice 경로: alpha 에서 세션 브랜치 → ko 변형 5곳(변수 리터럴 · 조건부 문장 ·
#                admonition 조사 문장 · 매크로 인자 · UI 자리 표시자 행 · 감싼 문단)
#                → PR → 로컬 translate_pr.py → 판정 (기존 en/ja 대비)
#   full 경로  : 세션에서 en/ja 를 지운 브랜치 → 같은 ko 변형 → PR → 번역 → 판정
#   판정은 scripts/check_template_tags.py (규칙 8개, 결정적) + 로그 규칙.
#
# ── 로그 규칙 ─────────────────────────────────────────────────────────────
#   (L1) 번역 exit 0, PARTIAL 없음
#   (L2) 'Left N template tag(s) with source-language text' — 한글 태그가 모델에
#        갔다는 직접 증거 (debug 로그)
#   (L3) 'Template-tag mismatch' / 'Source-language text left' 는 **재시도로
#        흡수**된 건수만 허용 — 최종 실패면 (L1) 이 잡는다. 건수는 verdict 에 남긴다.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-template-tags.sh                 # 3 라운드 × (splice + full)
#   bash scripts/e2e-template-tags.sh --rounds 1 --path splice --keep
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-template-tags.sh --rounds 5
#
# 의존성: git, gh (로그인), python3 (+jinja2), claude CLI
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
DOC="template-tags.md"
ROUNDS=3
PATHS="splice full"
MODEL="claude-sonnet-4-6"       # 프로덕션 .env 와 같은 모델 — 태그 구조 충실도는 모델 의존
KEEP=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rounds) ROUNDS="$2"; shift 2 ;;
    --path)   case "$2" in splice|full) PATHS="$2" ;; both) PATHS="splice full" ;; *) echo "bad --path" >&2; exit 1 ;; esac; shift 2 ;;
    --model)  MODEL="$2"; shift 2 ;;
    --keep)   KEEP=1; shift ;;
    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
OUT="${E2E_OUT:-$(mktemp -d /tmp/e2e-tpltags-XXXX)}"
CHECK="$REPO_ROOT/scripts/check_template_tags.py"
declare -a BRANCHES=()
declare -a RESULTS=()

cleanup() {
  local rc=$?
  if (( KEEP )); then echo; echo "--keep: 브랜치 보존 — ${BRANCHES[*]:-}"; return $rc; fi
  echo; echo "[cleanup] 세션/헤드/번역 브랜치 정리"
  local b
  for b in "${BRANCHES[@]}"; do
    while read -r tb; do
      [[ -n "$tb" ]] && git push origin ":$tb" >/dev/null 2>&1 || true
    done < <(git ls-remote --heads origin "refs/heads/translate/$b*" 2>/dev/null | sed 's|.*refs/heads/||')
    git push origin ":$b" >/dev/null 2>&1 || true
  done
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음 (ln -s ~/works/cloud-translate/.env 로 링크)" >&2; exit 1; }
python3 -c "import jinja2" 2>/dev/null || { echo "error: python3 에 jinja2 필요" >&2; exit 1; }

source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화 (로컬 번역과 배포본 번역이 같은 PR 을 겹쳐 처리하지 않도록)"
set_webhook_repo_enabled false

echo "repo    : $REPO"
echo "doc     : $DOC"
echo "rounds  : $ROUNDS  paths: $PATHS  model: $MODEL"
echo "translate: $CLOUD_TRANSLATE_DIR"
echo "out     : $OUT"

# ── ko 변형 — 다섯 절 + head 의 리터럴. 각 변형은 자기 절 안에만 머문다. ──────
CHANGED="_head,tt-inline-literal,tt-macro-arg,tt-ui-placeholder,tt-wrapped"
mutate_ko() {   # $1: path, $2: ts
  python3 - "$1" "$2" <<'PY'
import io, sys
path, ts = sys.argv[1:3]
raw = io.open(path, encoding="utf-8", newline="").read()
edits = [
  # M1 head — `{% set %}` 안 한글 리터럴 자체를 바꾼다 (Private-DNS 모양)
  ('"한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전"',
   '"한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>한국(부산) 리전"'),
  # M2 tt-inline-literal — 조건부 리터럴을 품은 문장의 산문
  ("접근 정책과 정적 웹사이트 설정을 변경할 수 있습니다.",
   "접근 정책과 정적 웹사이트 설정을 변경할 수 있습니다. 변경 내용은 즉시 반영됩니다."),
  # M2b — admonition 안 조사 리터럴 문장
  ("지정할 수 없습니다.\n", "지정할 수 없습니다. 이 제한은 해제할 수 없습니다.\n"),
  # M3 tt-macro-arg — 매크로 인자 리터럴 (Storage-Online-NAS 모양)
  ("'생성된 '", "'새로 생성된 '"),
  # M4 tt-ui-placeholder — `{{ 칼럼 이름 }}` 이 든 표 행의 설명
  ("결합 구분자보다 우선 적용됩니다.", "결합 구분자보다 우선 적용됩니다. 칼럼 이름은 대소문자를 구분합니다."),
  # M5 tt-wrapped — 감싼 문단의 산문 (#200 모양)
  ("태그와 한 유닛이 됩니다.\n{% endif %}", "태그와 한 유닛이 됩니다. 설정은 저장 즉시 적용됩니다.\n{% endif %}"),
]
for old, new in edits:
    assert raw.count(old) == 1, f"anchor text not unique/found: {old[:40]!r} ({raw.count(old)})"
    raw = raw.replace(old, new)
io.open(path, "w", encoding="utf-8", newline="").write(raw)
print(f"  변형 {len(edits)}건: {path}")
PY
}

grade_log() {   # $1: log → echoes "rc-ok|left|mismatch|leftover|retries"
  local log="$1"
  local left mm lo rt
  left="$(grep -c 'Left [0-9]* template tag(s) with source-language text' "$log" || true)"
  mm="$(grep -c 'Template-tag mismatch' "$log" || true)"
  lo="$(grep -c 'Source-language text left inside template tag' "$log" || true)"
  rt="$(grep -c 'retrying the unit' "$log" || true)"
  echo "${left:-0}|${mm:-0}|${lo:-0}|${rt:-0}"
}

run_translate() {   # $1: ko PR url, $2: log path
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL="$MODEL" \
    TRANSLATE_CLAUDE_CODE_MODEL="$MODEL" \
    TRANSLATE_LOG_LEVEL=debug \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$1" \
      --diff-granularity block --glossary-mode service --max-load-ratio 2 \
      --workers 2 --chunk-workers 2 --tm-top-k 1 \
      --table-rows --skip-full-table --skip-anchor-only \
      --assign-anchors --align-headings \
  ) > "$2" 2>&1
  local rc=$?
  set -e
  return $rc
}

overall=0
for (( r = 1; r <= ROUNDS; r++ )); do
  TS="$(date -u +%Y%m%d-%H%M%S)"
  SESSION="e2e-tpltags/$TS"
  echo; echo "═══ round $r/$ROUNDS — session $SESSION"
  git fetch -q origin "$BASE_SOURCE"
  git checkout -q -B "$SESSION" "origin/$BASE_SOURCE"
  for lang in ko en ja; do [[ -f "$lang/$DOC" ]] || { echo "error: $lang/$DOC 없음 (픽스처 미커밋?)" >&2; exit 1; }; done
  git push -q origin "$SESSION"
  BRANCHES+=("$SESSION")
  git show "origin/$SESSION:en/$DOC" > "$OUT/r$r.base.en.md"
  git show "origin/$SESSION:ja/$DOC" > "$OUT/r$r.base.ja.md"

  for path in $PATHS; do
    HEAD="translate-test-tpltags-$path/$TS"
    BRANCHES+=("$HEAD")
    echo; echo "── [$r/$path] ko 변형 PR"
    if [[ "$path" == "full" ]]; then
      # en/ja 가 없는 상태에서 시작 → 기존 번역이 없으니 full 번역으로 떨어진다
      FULL_BASE="e2e-tpltags-fullbase/$TS"; BRANCHES+=("$FULL_BASE")
      git checkout -q -B "$FULL_BASE" "$SESSION"
      git rm -q "en/$DOC" "ja/$DOC"
      git commit -q -m "e2e(template-tags): en/ja 제거 — full 번역 경로 조성 ($TS)"
      git push -q origin "$FULL_BASE"
      base_branch="$FULL_BASE"
    else
      base_branch="$SESSION"
    fi
    git checkout -q -B "$HEAD" "$base_branch"
    mutate_ko "ko/$DOC" "$TS"
    git add -- "ko/$DOC"
    git commit -q -m "e2e(template-tags/$path): 태그 안 리터럴·태그 주변 산문 변형 ($TS)"
    git push -q origin "$HEAD"
    e2e_ensure_label "$REPO"
    ko_pr="$(gh pr create --repo "$REPO" --base "$base_branch" --head "$HEAD" \
      --title "e2e(template-tags/$path): 템플릿 태그 리터럴 변형 ($TS)" \
      --body "cloud-translate #891 검증 — 한글이 든 mkdocs 템플릿 태그가 문장째 번역되고 구조가 보존되는지 ($path 경로, round $r)." \
      --label "$E2E_LABEL")"
    echo "  ko PR: $ko_pr"

    LOG="$OUT/r$r.$path.translate.log"
    echo "── [$r/$path] local translate_pr.py → $LOG"
    tx_rc=0; run_translate "$ko_pr" "$LOG" || tx_rc=$?
    IFS='|' read -r n_left n_mm n_lo n_rt <<< "$(grade_log "$LOG")"
    echo "  exit=$tx_rc  left-in-prose=$n_left  mismatch=$n_mm  leftover=$n_lo  retries=$n_rt"

    fails=0
    if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
      echo "  PASS  (L1) 번역 성공"
    else
      echo "  FAIL  (L1) 번역 실패/부분 (exit $tx_rc)"; fails=$((fails+1))
      grep -E 'Template-tag mismatch|Source-language text left|ERROR|Traceback' "$LOG" | head -5 | sed 's/^/        /'
    fi
    if (( n_left > 0 )); then echo "  PASS  (L2) 한글 태그가 모델에 갔다 (${n_left}건)"; else echo "  FAIL  (L2) 'Left … source-language text' 로그 없음"; fails=$((fails+1)); fi
    echo "  INFO  (L3) mismatch=$n_mm leftover=$n_lo → 재시도 $n_rt 회로 흡수"

    tx_pr="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
    if [[ -n "$tx_pr" ]]; then
      echo "  번역 PR: $tx_pr"; e2e_label_pr "$REPO" "$tx_pr"
      tx_branch="$(gh pr view "$tx_pr" --repo "$REPO" --json headRefName --jq .headRefName)"
      git fetch -q origin "$tx_branch"
      git show "origin/$HEAD:ko/$DOC" > "$OUT/r$r.$path.ko.md"
      got=1
      for lang in en ja; do
        git show "origin/$tx_branch:$lang/$DOC" > "$OUT/r$r.$path.$lang.md" 2>/dev/null || { echo "  FAIL  $lang/$DOC 번역 브랜치에 없음"; fails=$((fails+1)); got=0; }
      done
      if (( got )); then
        args=(--ko "$OUT/r$r.$path.ko.md" --tr "en=$OUT/r$r.$path.en.md" --tr "ja=$OUT/r$r.$path.ja.md")
        [[ "$path" == "splice" ]] && args+=(--base "en=$OUT/r$r.base.en.md" --base "ja=$OUT/r$r.base.ja.md" --changed "$CHANGED")
        set +e; python3 "$CHECK" "${args[@]}" | tee "$OUT/r$r.$path.check.txt"; crc=${PIPESTATUS[0]}; set -e
        fails=$((fails + crc))
      fi
    else
      echo "  FAIL  번역 PR 미생성 — 파일 검사 불가"; fails=$((fails+1))
    fi
    verdict=$([[ $fails -eq 0 ]] && echo PASS || echo "FAIL($fails)")
    RESULTS+=("round $r | $path | exit=$tx_rc | $verdict | left=$n_left mismatch=$n_mm leftover=$n_lo retries=$n_rt | ${tx_pr:-<no-pr>}")
    (( fails == 0 )) || overall=1
  done
done

echo; echo "═══ 결과 ($ROUNDS 라운드 × $PATHS)"
for line in "${RESULTS[@]}"; do echo "  $line"; done
echo "  산출물: $OUT"
if (( overall )); then KEEP=1; echo "  → FAIL (브랜치 보존)"; exit 1; fi
echo "  → PASS"
