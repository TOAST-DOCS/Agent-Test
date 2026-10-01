#!/usr/bin/env bash
#
# e2e-translate-queue-ordinary.sh — 번역 큐를 켜도 **일반 흐름은 기존과 바이트 단위로
# 같은지** 엄격히 검증한다 (cloud-translate #1048, shared/translate_queue.py).
#
# 일반 흐름 = ko 변경 → 번역 → 번역 머지 → ko 변경 → 번역 → … (앞 번역이 늘 다음
# ko 머지 전에 끝난다). 이때 큐는 라벨만 달았다 떼고 번역은 지금과 같은 경로
# (en/ja 를 머지 커밋에서 읽기 · 머지 커밋에서 브랜치)를 타야 한다.
#
# 라운드마다 같은 ko PR 을 두 번 번역한다:
#   ON  — 큐 켬 (TRANSLATE_TRANSLATE_QUEUE_REPOS=이 레포)  → 모델 응답을 카세트에 기록
#   OFF — 큐 끔 (지금 동작)                              → 같은 카세트를 재생
# 카세트 키는 모델 입력 전부(원문·참조·글로서리·언어 …)의 해시라, OFF 가 **새로
# 기록한 항목 0 · 모델 호출 0** 이면 두 실행이 모델에 똑같은 입력을 보냈다는 증명이다.
# 그 위에서 결과를 바이트로 비교한다:
#   (a) 번역 브랜치의 ko/en/ja 트리가 동일 (git diff 0)
#   (b) 두 브랜치의 기점(merge-base) 동일 = 소스 PR 머지 커밋
#   (c) Files changed 의 파일·추가·삭제 수 동일
#   (d) PR 본문이 PR 번호·브랜치 이름·잡 id·시각을 지운 뒤 동일, ON 본문에 'Translation queue:' 없음
#   (e) ON 로그: 'en/ja unchanged since the merge' · DEFERRED/QUEUED 없음
#   (f) 라벨 수명: ON 번역 뒤 소스 PR 에 '번역 대기열' → 번역 PR 머지 → 제거 · 줄이 빈다
# 라운드는 변경 모양을 바꿔 가며 넷: 본문 수정 · 섹션 추가 · anchor 이름 변경 · 본문 수정.
#
# 번역은 로컬 translate_pr.py, 엔진은 Claude Code CLI (권장 preset) — ON 실행의 카세트
# 기록이 실제 모델 호출이다. webhook 처리는 queue_wake.complete_source + next_to_run.
#
# Exit code: 0 = 전부 동일, 1 = 차이 발견, 2 = 하네스 오류
#
# Usage:
#   bash e2e-translate-queue-ordinary.sh [--cloud-translate-dir DIR] [--doc <stem>.md] [--keep]

set -euo pipefail

REPO="TOAST-DOCS/Agent-Test"
REPO_URL="https://github.com/${REPO}.git"
BASE_SOURCE_BRANCH="alpha"
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
# 검증할 코드(CLOUD_TRANSLATE_DIR — 워크트리일 수 있다)와 운영 preset 출처는 따로다.
# preset 정본은 dashboard/.env 의 TRANSLATE_TRANSLATE_PRESETS 라 워크트리에는 없다.
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"
KEEP=0
DOC="${DOC:-fix-links.md}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud-translate-dir) CLOUD_TRANSLATE_DIR="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --doc) DOC="$2"; shift 2 ;;
    -h|--help) sed -n '2,45p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: $CLOUD_TRANSLATE_PY 실행 불가" >&2; exit 2; }
[[ -f "$CLOUD_TRANSLATE_DIR/shared/translate_queue.py" ]] \
  || { echo "error: $CLOUD_TRANSLATE_DIR 에 번역 큐 코드가 없음 (shared/translate_queue.py)" >&2; exit 2; }

TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e/translate-queue-ordinary-${TS}"
QUEUE_LABEL="번역 대기열"

WORK="$(mktemp -d /tmp/e2e-translate-queue-ordinary-XXXXXX)"
CASS="$WORK/cassettes"; mkdir -p "$CASS"
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화 (배포된 번역 잡이 이 e2e 의 머지를 중복 처리하지 않도록)"
set_webhook_repo_enabled false

LOGDIR="$WORK/logs"; mkdir -p "$LOGDIR"
echo "workdir: $WORK"
cleanup() { if (( ! KEEP )); then rm -rf "$WORK"; fi; }
trap cleanup EXIT

FAIL=0
ok()   { echo "  ✓ $*"; }
bad()  { echo "  ✗ $*"; FAIL=1; }

echo "[setup] clone + 세션 브랜치 ${SESSION} + fixture 복원 (doc=${DOC})"
git clone --quiet "$REPO_URL" "$WORK/repo"
cd "$WORK/repo"
git checkout --quiet -b "$SESSION" "origin/${BASE_SOURCE_BRANCH}"
bash scripts/restore-alpha-origin.sh >/dev/null
sed -i -E 's/^(#{1,6})([^ #])/\1 \2/' ko/*.md en/*.md ja/*.md
# machine_translated 헤더를 미리 둔다 — 두 번역 PR 이 같은 자리에 같은 줄을 넣어
# 생기는 가짜 충돌을 피한다 (e2e-translation-lag-order.sh 와 같은 이유).
for lang in en ja; do
  if ! head -1 "$lang/$DOC" | grep -q "machine_translated"; then
    printf '<!-- machine_translated: true -->\n\n%s' "$(cat "$lang/$DOC")" > "$lang/$DOC"
    echo >> "$lang/$DOC"
  fi
done
git add ko en ja
git commit --quiet -m "e2e(translate-queue-ordinary): session fixture" || true
git push --quiet origin "$SESSION"

# ── ko 변경 ─────────────────────────────────────────────────────────────
mutate() {  # $1 = rename:<old>:<new> | add:<id> | body:<token>
  python3 - "$1" "ko/$DOC" <<'PY'
import re, sys
op, path = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
kind, *args = op.split(":")
if kind == "rename":
    old, new = args
    assert f'<a id="{old}"></a>' in text, old
    text = text.replace(f'<a id="{old}"></a>', f'<a id="{new}"></a>').replace(f"{{ #{old} }}", f"{{ #{new} }}")
elif kind == "add":
    (aid,) = args
    if not text.endswith("\n"):
        text += "\n"
    text += (f'\n<a id="{aid}"></a>\n## 번역 큐 테스트 섹션 {aid} {{ #{aid} }}\n\n'
             f"이 섹션은 번역 큐 e2e 가 추가했습니다 ({aid}). 번역본에 정확히 한 번 있어야 합니다.\n")
elif kind == "body":
    (tok,) = args
    lines = text.split("\n")
    # 첫 h2 아래 첫 산문 문단 끝에 문장 추가
    seen, hit = False, None
    for i, l in enumerate(lines):
        if l.startswith("## "):
            seen = True; continue
        s = l.strip()
        if seen and s and not s.startswith(("#", "<", "{", "|", "-", "*", ">", "`", "!")):
            hit = i; break
    assert hit is not None
    lines[hit] += f" (번역 큐 테스트: 이 문장은 {tok} 확인용입니다.)"
    text = "\n".join(lines)
else:
    raise SystemExit(f"bad op {op}")
open(path, "w", encoding="utf-8").write(text)
PY
}

make_pr() {  # $1 branch · $2.. mutate ops (마지막 인자 = 제목) → PR URL
  local br="$1"; shift
  local title="${!#}"
  git checkout --quiet -b "$br" "origin/$SESSION"
  local n=$(( $# - 1 )) i
  for (( i=1; i<=n; i++ )); do mutate "${!i}"; done
  git add "ko/$DOC"
  git commit --quiet -m "$title"
  git push --quiet origin "$br"
  gh pr create --repo "$REPO" --base "$SESSION" --head "$br" \
    --title "$title" --body "translate-queue e2e" --label "$E2E_LABEL" 2>/dev/null | tail -1
  git checkout --quiet "$SESSION"
}
merge_pr() { gh pr merge "$1" --repo "$REPO" --merge >/dev/null; git fetch --quiet origin "$SESSION"; }
close_pr() { gh pr close "$1" --repo "$REPO" >/dev/null; }
retitle()  { local t; t="$(gh pr view "$1" --repo "$REPO" --json title -q .title)"; gh pr edit "$1" --repo "$REPO" --title "$2 $t" >/dev/null; }

# ── 번역 (권장 preset, CLI 엔진) ─────────────────────────────────────────
preset_eval="$(python3 "$(dirname "$0")/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 2
eval "$preset_eval"
echo "translate argv: ${PRESET_ARGS[*]}  (preset 출처: $PRESET_CATALOG_DIR · 코드: $CLOUD_TRANSLATE_DIR)"

translate() {  # $1 PR URL · $2 log name · $3 queue(on|off) · [$4 fault paths] → log path
  local log="$LOGDIR/$2.log" q="" rc=0
  [[ "$3" == "on" ]] && q="$REPO"
  (cd "$CLOUD_TRANSLATE_DIR" && TRANSLATE_TRANSLATE_QUEUE_REPOS="$q" \
    TRANSLATE_FAULT_INJECT_PATHS="${4:-}" \
    TRANSLATE_DRY_RUN=true TRANSLATE_DRY_RUN_CASSETTE_DIR="$CASS" \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$1" "${PRESET_ARGS[@]}") >"$log" 2>&1 || rc=$?
  if (( rc != 0 )) && [[ -z "${4:-}" ]]; then
    echo "error: translate_pr.py 실패 — $log" >&2; tail -30 "$log" >&2; exit 2
  fi
  echo "$log"
}
pr_of() { grep -oE 'Translation PR: https://[^ ]+' "$1" | tail -1 | sed 's/Translation PR: //'; }

# webhook 이 번역 PR 머지 delivery 에 하는 일 — 소스 PR 을 줄에서 빼고 다음 차례를
# 고른다. 출력: 다음 차례 PR 번호 (없으면 빈 줄) · 판정 이유는 stderr.
webhook_merged() {  # $1 번역 PR URL
  (cd "$CLOUD_TRANSLATE_DIR" && GITHUB_TOKEN="$(gh auth token)" "$CLOUD_TRANSLATE_PY" - "$REPO" "${1##*/}" <<'PY'
import json, subprocess, sys
sys.path.insert(0, ".")
from webhook import queue_wake
repo, n = sys.argv[1], sys.argv[2]
pr = json.loads(subprocess.run(["gh", "api", f"repos/{repo}/pulls/{n}"],
                               capture_output=True, text=True, check=True).stdout)
assert pr.get("merged"), f"#{n} is not merged"
done = queue_wake.complete_source(repo, pr)
# webhook/handler.py 와 같이 방금 뗀 소스 PR 은 후보에서 뺀다 (목록이 라벨 제거를
# 늦게 반영한다)
head, why = queue_wake.next_to_run(repo, pr["base"]["ref"],
                                   exclude=(done.get("source_pr"),))
print(f"complete={done} next: {why}", file=sys.stderr)
print(head["number"] if head else "")
PY
  )
}
has_label() { gh pr view "$1" --repo "$REPO" --json labels -q '.labels[].name' | grep -qx "$QUEUE_LABEL"; }
# 번역 PR 의 en/ja 변경 줄 수 (차례가 된 잡은 자기 변경만 번역해야 한다)
tx_lines() { gh pr view "$1" --repo "$REPO" --json files -q '[.files[] | select(.path|test("^(en|ja)/")) | .additions + .deletions] | add'; }
narrow() {  # $1 번역 PR URL · $2 label
  local n; n="$(tx_lines "$1")"
  [[ "${n:-0}" -le 12 ]] && ok "[$2] 번역 diff ${n}줄 — 이 PR 의 변경만" || bad "[$2] 번역 diff ${n}줄 — 이 PR 이 안 바꾼 것까지 번역했다"
}
next_is() {  # $1 기대 PR URL · $2 webhook_merged 출력
  [[ "$2" == "${1##*/}" ]] && ok "다음 차례 = #${1##*/}" || bad "다음 차례가 #${1##*/} 가 아니다 (${2:-없음})"
}

# ref 의 ko/en/ja 에서 <a id> 순서를 비교한다. 추가 인자: 있어야 할 id · ASCII 토큰
check_ref() {  # $1 ref · $2 label · "$@" id:<x> | tok:<x> | noid:<x>
  local ref="$1" label="$2"; shift 2
  git fetch --quiet origin "$ref"
  python3 - "$label" "$DOC" "$@" <<'PY'
import re, subprocess, sys
label, doc, *checks = sys.argv[1:]
def show(lang):
    return subprocess.run(["git", "show", f"FETCH_HEAD:{lang}/{doc}"], capture_output=True, text=True).stdout
ids = {l: re.findall(r'<a id="([^"]+)"', show(l)) for l in ("ko", "en", "ja")}
bad = 0
for l in ("en", "ja"):
    if ids[l] == ids["ko"]:
        print(f"  ✓ [{label}] {l} <a id> 순서 == ko ({len(ids['ko'])}개)")
    else:
        miss = [x for x in ids["ko"] if x not in ids[l]]; extra = [x for x in ids[l] if x not in ids["ko"]]
        print(f"  ✗ [{label}] {l} <a id> ≠ ko — 누락 {miss[:5]} · 여분 {extra[:5]}"); bad = 1
for c in checks:
    kind, val = c.split(":", 1)
    for l in ("en", "ja"):
        text = show(l)
        if kind == "id":
            n = text.count(f'<a id="{val}"></a>')
            ok = n == 1
            print(f"  {'✓' if ok else '✗'} [{label}] {l} id {val} ×{n}")
        elif kind == "noid":
            ok = f'"{val}"' not in text
            print(f"  {'✓' if ok else '✗'} [{label}] {l} 옛 id {val} 없음")
        else:
            ok = val.lower() in text.lower()
            print(f"  {'✓' if ok else '✗'} [{label}] {l} 토큰 {val}")
        bad |= (not ok)
sys.exit(bad)
PY
}

saves() { grep -c "cassette SAVE" "$1" || true; }
hits()  { grep -c "cassette HIT" "$1" || true; }
calls() { grep -c "with Claude Code CLI" "$1" || true; }
norm_body() {  # $1 PR URL → 정규화한 본문 (PR 번호·브랜치·잡 id·시각·sha 제거)
  gh pr view "$1" --repo "$REPO" --json body -q .body | python3 -c '
import re, sys
t = sys.stdin.read()
t = re.sub(r"translate/[^\s)`\"]+", "<BRANCH>", t)
t = re.sub(r"/pull/\d+", "/pull/<N>", t)
t = re.sub(r"#\d+", "#<N>", t)
t = re.sub(r"\b[0-9a-f]{7,40}\b", "<SHA>", t)
t = re.sub(r"\d{4}-\d\d-\d\d[T ][\d:.]+Z?", "<TS>", t)
t = re.sub(r"\b\d+(\.\d+)?s\b", "<DUR>", t)
t = re.sub(r"(tx_ref|ref|ko_ref|tx_pr|ko_pr)=[^&)\s]+", r"\1=<X>", t)
print(t)'
}
files_sig() { gh pr view "$1" --repo "$REPO" --json files -q '[.files[] | "\(.path) +\(.additions) -\(.deletions)"] | sort | join(",")'; }

head_ref() { gh api "repos/${REPO}/pulls/${1##*/}" -q .head.ref; }

e2e_ensure_label "$REPO"

round() {  # $1 이름 · $2.. mutate ops (마지막 = 제목)
  local name="$1"; shift
  echo; echo "═══ ${name}"
  local K; K="$(make_pr "translate-test/${TS}-o-${name}" "$@")"; echo "  ko PR: $K"
  merge_pr "$K"
  local merge_sha; merge_sha="$(gh api "repos/${REPO}/pulls/${K##*/}" -q .merge_commit_sha)"

  local LON LOFF TON TOFF
  LON="$(translate "$K" "${name}-on" on)";  TON="$(pr_of "$LON")"
  LOFF="$(translate "$K" "${name}-off" off)"; TOFF="$(pr_of "$LOFF")"
  [[ -n "$TON" && -n "$TOFF" ]] || { echo "error: 번역 PR 없음 — $LON / $LOFF" >&2; exit 2; }
  e2e_label_pr "$REPO" "$TON"; e2e_label_pr "$REPO" "$TOFF"
  retitle "$TON" "[QUEUE-ON]"; retitle "$TOFF" "[QUEUE-OFF]"
  echo "  ON  $TON   (cassette SAVE $(saves "$LON") · HIT $(hits "$LON") · 모델 호출 $(calls "$LON"))"
  echo "  OFF $TOFF  (cassette SAVE $(saves "$LOFF") · HIT $(hits "$LOFF") · 모델 호출 $(calls "$LOFF"))"

  # 모델 입력 동일성
  [[ "$(saves "$LOFF")" == 0 && "$(calls "$LOFF")" == 0 ]] \
    && ok "OFF 는 새 기록 0 · 모델 호출 0 — 두 실행이 모델에 같은 입력을 보냈다" \
    || bad "OFF 가 카세트에 없는 입력을 만들었다 (SAVE $(saves "$LOFF"), 호출 $(calls "$LOFF")) — 입력이 다르다"
  [[ "$(hits "$LOFF")" == "$(( $(saves "$LON") + $(hits "$LON") ))" ]] \
    && ok "OFF 의 재생 수 == ON 의 모델 호출 수 ($(hits "$LOFF"))" \
    || bad "호출 수가 다르다 — ON $(( $(saves "$LON") + $(hits "$LON") )) · OFF $(hits "$LOFF")"

  # (e) 큐 판정
  grep -q "en/ja unchanged since the merge" "$LON" && ok "ON 큐 판정: 차례 · 머지 커밋 기준 (기존 경로)" \
    || bad "ON 이 기존 경로가 아니다 — $(grep -m1 'Queue:' "$LON")"
  grep -qE "DEFERRED:|QUEUED:|en/ja moved since" "$LON" && bad "ON 에 대기/중복/base 끝 판정" || ok "대기·중복·base 끝 없음"

  # (a)(b) 트리·기점
  local hon hoff; hon="$(head_ref "$TON")"; hoff="$(head_ref "$TOFF")"
  git fetch --quiet origin "$hon" "$hoff"
  if git diff --quiet "origin/$hon" "origin/$hoff" -- ko en ja; then
    ok "(a) ko/en/ja 트리 바이트 동일"
  else
    bad "(a) 트리가 다르다:"; git diff --stat "origin/$hon" "origin/$hoff" -- ko en ja | sed 's/^/      /'
  fi
  local bon boff; bon="$(git merge-base "origin/$hon" "origin/$SESSION")"; boff="$(git merge-base "origin/$hoff" "origin/$SESSION")"
  [[ "$bon" == "$boff" && "$bon" == "$merge_sha" ]] && ok "(b) 브랜치 기점 동일 = 소스 PR 머지 커밋 ${merge_sha:0:7}" \
    || bad "(b) 기점이 다르다 — ON ${bon:0:7} · OFF ${boff:0:7} · merge ${merge_sha:0:7}"

  # (c)(d) PR
  [[ "$(files_sig "$TON")" == "$(files_sig "$TOFF")" ]] && ok "(c) Files changed 동일 ($(files_sig "$TON"))" \
    || bad "(c) Files changed 가 다르다 — ON $(files_sig "$TON") · OFF $(files_sig "$TOFF")"
  if diff <(norm_body "$TON") <(norm_body "$TOFF") >"$LOGDIR/${name}-body.diff"; then
    ok "(d) PR 본문 동일 (번호·브랜치·sha·시각 정규화)"
  else
    bad "(d) PR 본문이 다르다:"; sed 's/^/      /' "$LOGDIR/${name}-body.diff" | head -20
  fi
  gh pr view "$TON" --repo "$REPO" --json body -q .body | grep -q "Translation queue:" \
    && bad "(d) ON 본문에 'Translation queue:' 줄" || ok "(d) ON 본문에 큐 안내 없음"

  # (f) 라벨 수명 · 다음 판에 ON 결과를 남긴다
  has_label "$K" && ok "(f) 번역 뒤 소스 PR 에 '$QUEUE_LABEL'" || bad "(f) 라벨 없음"
  close_pr "$TOFF"
  merge_pr "$TON"
  local N; N="$(webhook_merged "$TON")"
  has_label "$K" && bad "(f) 번역 머지 뒤에도 라벨이 남음" || ok "(f) 번역 머지 → 라벨 제거"
  [[ -z "$N" ]] && ok "(f) 줄이 빈다" || bad "(f) 줄에 #$N 가 남음"
  RESULTS+=("${name}: ko $K · ON $TON · OFF $TOFF (닫음)")
}

RESULTS=()
round r1-body  body:QUEUE-ORD-R1 "[e2e] queue-ordinary R1 — body edit (${TS})"
round r2-add   add:queue-ord-r2 "[e2e] queue-ordinary R2 — add section (${TS})"
round r3-rename rename:fix-links-self:fix-links-self-ord "[e2e] queue-ordinary R3 — rename anchor (${TS})"
round r4-body  body:QUEUE-ORD-R4 "[e2e] queue-ordinary R4 — body edit after three rounds (${TS})"

echo; echo "최종 base — ko 와 en/ja anchor 순서"
check_ref "$SESSION" final id:queue-ord-r2 id:fix-links-self-ord noid:fix-links-self tok:QUEUE-ORD-R1 tok:QUEUE-ORD-R4 || FAIL=1

echo
echo "결과"
echo "  session: $SESSION"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "  logs: $LOGDIR"
if (( FAIL )); then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS — 일반 흐름 4라운드에서 큐 켬 == 큐 끔 (모델 입력·트리·기점·Files changed·본문)"
