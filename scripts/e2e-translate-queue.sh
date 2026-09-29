#!/usr/bin/env bash
#
# e2e-translate-queue.sh — repo × base 순차 번역 큐 검증 (cloud-translate
# shared/translate_queue.py · translate/translate_pr.py · webhook/queue_wake.py).
#
# 사건 원형: TOAST-DOCS/RDS-FOR-POSTGRESQL #89 → #90. #89(A)는 anchor id 101개의
# 이름을 바꾸고 섹션을 더했는데 그 번역(TA)이 실패했고, 그 사이 #90(B, 표 셀 2개)이
# 머지됐다. B 의 번역(#91)은 B 의 머지 커밋에 고정된 en — A 가 빠진 번역 — 을 기준으로
# 돌아 옛 id 섹션을 지우고(-101 removed) 새 섹션은 건너뛰었다(left 136) — en -704줄.
#
# 큐가 켜진 리포는 머지된 ko PR 을 **머지 순서대로 하나씩** 번역한다. 먼저 머지된
# PR 의 번역이 머지되기 전에는 (실패·리뷰 중·닫힘 모두) 뒤 PR 은 기다리고, 차례가
# 되면 base 끝의 en/ja 위에 **자기 변경만** 번역한다 (여러 PR 을 한 번역에 접지
# 않는다). 한 세션 브랜치 위에서 네 장면을 만든다. 판정은 전부 결정적이다 (anchor id
# 순서 대조 · ASCII 토큰 · 로그 마커 · 라벨 · 번역 diff 줄 수).
#
#   S1 대기 → 차례 (#89 → #90 모양)
#      A1 = anchor 이름 변경 + 섹션 추가 → 머지 → TA1 (열어 둠)
#      B1 = 다른 섹션 본문 수정 → 머지
#      [BEFORE] 큐 끔으로 B1 번역 → 옛 id 섹션 삭제 재현 (기대: 결함) → 닫음
#      [AFTER]  큐 켬으로 B1 번역 → DEFERRED, 번역 PR 없음
#      TA1 머지 → webhook 처리(A1 라벨 삭제 + 다음 차례 = B1) → B1 번역 → TB1 :
#      en/ja anchor 순서 == ko, A1 의 id 보존, B1 토큰, diff 는 B1 문장만 (좁다)
#   S2 번역 PR 닫힘은 완료가 아니다
#      A2 = 섹션 추가 → 머지 → TA2 · B2 = 본문 수정 → 머지 → DEFERRED
#      TA2 닫음 → A2 는 줄에 남고 B2 는 여전히 DEFERRED
#      A2 재번역 → TA2' 머지 → 다음 차례 = B2 → TB2 는 B2 문장만, A2 섹션 보존
#   S3 앞 번역 실패 (#913 모양) — TRANSLATE_FAULT_INJECT_PATHS 로 A3 번역을 실패시킨다
#      A3 = 섹션 추가 → 머지 → 번역 실패 (라벨 남음) · B3 = 본문 수정 → 머지 → DEFERRED
#      [BEFORE] 큐 끔 → A3 섹션이 stale skip 으로 빠진다 (기대: 결함) → 닫음
#      A3 재번역(성공) → TA3 머지 → 다음 차례 = B3 → TB3 는 B3 문장만, A3 섹션 보존
#   S4 대조군 — 앞선 PR 이 없는 평범한 PR
#      C = 본문 수정 → 머지 → 차례 즉시, 번역 diff 좁음, TC 머지 → 줄이 빈다
#
# webhook 의 처리는 webhook pod 대신 같은 함수를 로컬에서 부른다 — 번역 PR 이
# 머지되면 `queue_wake.complete_source` 가 소스 PR 의 라벨을 떼고
# `queue_wake.next_to_run` 이 다음 차례를 고른다. webhook 은 그 PR 로 Jenkins 번역
# 잡을 건다. 여기서는 로컬 translate_pr.py 로 돌린다. dispatch 배선은 cloud-translate 의
# webhook/tests/test_queue_wake.py 가 본다.
#
# 번역은 로컬 translate_pr.py (프로덕션과 같은 Claude Code CLI 엔진, 옵션은 권장
# preset). 큐는 TRANSLATE_TRANSLATE_QUEUE_REPOS 로 이 레포만 켠다 — 배포본과 무관.
#
# Exit code: 0 = 전부 기대대로, 1 = 판정 실패, 2 = 하네스 오류
#
# Usage:
#   bash e2e-translate-queue.sh [--cloud-translate-dir DIR] [--doc <stem>.md] [--keep]
#
# 의존성: git, gh(로그인), python3, DASHBOARD_* (webhook 토글). 번역은 local 실행.

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
    -h|--help) sed -n '2,50p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 2; }
[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: $CLOUD_TRANSLATE_PY 실행 불가" >&2; exit 2; }
[[ -f "$CLOUD_TRANSLATE_DIR/shared/translate_queue.py" ]] \
  || { echo "error: $CLOUD_TRANSLATE_DIR 에 번역 큐 코드가 없음 (shared/translate_queue.py)" >&2; exit 2; }

TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION="e2e/translate-queue-${TS}"
QUEUE_LABEL="번역 대기열"

WORK="$(mktemp -d /tmp/e2e-translate-queue-XXXXXX)"
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
git commit --quiet -m "e2e(translate-queue): session fixture" || true
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
head, why = queue_wake.next_to_run(repo, pr["base"]["ref"])
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
# BEFORE 는 결함이 재현돼야 정상이다 (반전 판정)
expect_defect() {  # $1 ref · $2 label · rest = check args
  if check_ref "$@" >"$LOGDIR/before-$2.txt"; then
    sed 's/^/    /' "$LOGDIR/before-$2.txt"
    bad "[$2] BEFORE 가 결함을 재현하지 못함 — 장면이 사건 모양이 아니다"
  else
    sed 's/^/    /' "$LOGDIR/before-$2.txt"
    ok "[$2] BEFORE 는 결함 재현 (큐 없이 번역하면 깨진다)"
  fi
}
head_ref() { gh api "repos/${REPO}/pulls/${1##*/}" -q .head.ref; }

e2e_ensure_label "$REPO"

# ═══ S1 대기 → 차례 ═════════════════════════════════════════════════════
echo; echo "═══ S1 대기 → 차례 (#89 → #90 모양)"
A1="$(make_pr "translate-test/${TS}-q-a1" rename:fix-links-self:fix-links-self-renamed add:queue-a1 \
      "[e2e] queue S1 A — rename anchor + add section (${TS})")"; echo "  A1: $A1"
merge_pr "$A1"
L="$(translate "$A1" s1-ta on)"; TA1="$(pr_of "$L")"
[[ -n "$TA1" ]] || { echo "error: TA1 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TA1"; echo "  TA1: $TA1 (열어 둠)"
grep -q "is next on" "$L" && ok "A1 은 곧바로 차례 (앞선 PR 없음)" || bad "A1 로그에 큐 판정 없음 — $L"
has_label "$A1" && ok "A1 이 줄에 섰다 ('$QUEUE_LABEL')" || bad "A1 에 라벨 없음"

B1="$(make_pr "translate-test/${TS}-q-b1" body:QUEUE-S1-B-TOKEN "[e2e] queue S1 B — body edit (${TS})")"; echo "  B1: $B1"
merge_pr "$B1"

echo "  [BEFORE] 큐 끔"
L="$(translate "$B1" s1-before off)"; TB1_BEFORE="$(pr_of "$L")"
if [[ -n "$TB1_BEFORE" ]]; then
  e2e_label_pr "$REPO" "$TB1_BEFORE"; retitle "$TB1_BEFORE" "[BEFORE]"
  expect_defect "$(head_ref "$TB1_BEFORE")" s1 id:fix-links-self-renamed noid:fix-links-self
  close_pr "$TB1_BEFORE"; echo "  BEFORE PR: $TB1_BEFORE (닫음)"
else
  bad "[s1] BEFORE 번역 PR 이 없다 — $L"
fi

echo "  [AFTER] 큐 켬 — A1 의 번역이 아직 머지되지 않았으므로 대기"
L="$(translate "$B1" s1-defer on)"
grep -q "DEFERRED:" "$L" && ok "DEFERRED 출력" || bad "DEFERRED 없음 — $L"
grep -q "translation PR #${TA1##*/} open" "$L" && ok "대기 사유: TA1 리뷰 중" || bad "대기 사유에 TA1 없음 — $L"
[[ -z "$(pr_of "$L")" ]] && ok "번역 PR 을 만들지 않음" || bad "대기인데 번역 PR 이 생김"

echo "  TA1 머지 → webhook 처리"
merge_pr "$TA1"
N="$(webhook_merged "$TA1")"; next_is "$B1" "$N"
has_label "$A1" && bad "A1 라벨이 남아 있음" || ok "A1 완료 (라벨 떨어짐)"
L="$(translate "$B1" s1-next on)"; TB1="$(pr_of "$L")"
grep -q "is next on" "$L" && ok "B1 차례 — base 끝의 en/ja 위에 번역" || bad "B1 이 차례가 아님 — $L"
[[ -n "$TB1" ]] || { echo "error: TB1 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TB1"; retitle "$TB1" "[AFTER]"; echo "  TB1: $TB1"
check_ref "$(head_ref "$TB1")" s1-after id:fix-links-self-renamed id:queue-a1 noid:fix-links-self tok:QUEUE-S1-B-TOKEN || FAIL=1
narrow "$TB1" s1-after
merge_pr "$TB1"
N="$(webhook_merged "$TB1")"; [[ -z "$N" ]] && ok "줄이 비었다" || bad "줄에 #$N 가 남음"
check_ref "$SESSION" s1-final id:fix-links-self-renamed id:queue-a1 tok:QUEUE-S1-B-TOKEN || FAIL=1

# ═══ S2 번역 PR 닫힘은 완료가 아니다 ═════════════════════════════════════
echo; echo "═══ S2 번역 PR 닫힘 ≠ 완료"
A2="$(make_pr "translate-test/${TS}-q-a2" add:queue-a2 "[e2e] queue S2 A — add section (${TS})")"; echo "  A2: $A2"
merge_pr "$A2"
L="$(translate "$A2" s2-ta on)"; TA2="$(pr_of "$L")"
[[ -n "$TA2" ]] || { echo "error: TA2 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TA2"; echo "  TA2: $TA2"
B2="$(make_pr "translate-test/${TS}-q-b2" body:QUEUE-S2-B-TOKEN "[e2e] queue S2 B — body edit (${TS})")"; echo "  B2: $B2"
merge_pr "$B2"
L="$(translate "$B2" s2-defer on)"
grep -q "DEFERRED:" "$L" && ok "B2 DEFERRED" || bad "B2 가 대기하지 않음 — $L"
close_pr "$TA2"; echo "  TA2 닫음 (미머지) — webhook 은 아무것도 하지 않는다"
has_label "$A2" && ok "A2 는 줄에 남음" || bad "A2 라벨이 떨어짐"
L="$(translate "$B2" s2-still on)"
grep -q "DEFERRED:" "$L" && grep -q "failed or closed" "$L" \
  && ok "B2 는 여전히 대기 (사유: A2 번역 없음)" || bad "TA2 닫힘 뒤 B2 가 대기하지 않음 — $L"
echo "  A2 재번역"
L="$(translate "$A2" s2-ta2 on)"; TA2B="$(pr_of "$L")"
[[ -n "$TA2B" ]] || { echo "error: TA2' 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TA2B"; echo "  TA2': $TA2B"
merge_pr "$TA2B"
N="$(webhook_merged "$TA2B")"; next_is "$B2" "$N"
L="$(translate "$B2" s2-next on)"; TB2="$(pr_of "$L")"
[[ -n "$TB2" ]] || { echo "error: TB2 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TB2"; echo "  TB2: $TB2"
check_ref "$(head_ref "$TB2")" s2-after id:queue-a2 tok:QUEUE-S2-B-TOKEN || FAIL=1
narrow "$TB2" s2-after
merge_pr "$TB2"; webhook_merged "$TB2" >/dev/null

# ═══ S3 앞 번역 실패 ═════════════════════════════════════════════════════
echo; echo "═══ S3 앞 번역 실패 (#913 모양)"
A3="$(make_pr "translate-test/${TS}-q-a3" add:queue-a3 "[e2e] queue S3 A — add section, translation fails (${TS})")"; echo "  A3: $A3"
merge_pr "$A3"
L="$(translate "$A3" s3-ta-fail on "ko/$DOC")"
grep -q "FAILED" "$L" && [[ -z "$(pr_of "$L")" ]] && ok "A3 번역 실패 (주입), 번역 PR 없음" || bad "A3 번역이 실패하지 않음 — $L"
has_label "$A3" && ok "실패한 A3 는 줄에 남음" || bad "실패한 A3 의 라벨이 떨어짐"
B3="$(make_pr "translate-test/${TS}-q-b3" body:QUEUE-S3-B-TOKEN "[e2e] queue S3 B — body edit (${TS})")"; echo "  B3: $B3"
merge_pr "$B3"
L="$(translate "$B3" s3-defer on)"
grep -q "DEFERRED:" "$L" && grep -q "failed or closed" "$L" \
  && ok "B3 DEFERRED (사유: A3 번역 없음)" || bad "B3 가 대기하지 않음 — $L"
echo "  [BEFORE] 큐 끔"
L="$(translate "$B3" s3-before off)"; TB3_BEFORE="$(pr_of "$L")"
if [[ -n "$TB3_BEFORE" ]]; then
  e2e_label_pr "$REPO" "$TB3_BEFORE"; retitle "$TB3_BEFORE" "[BEFORE]"
  expect_defect "$(head_ref "$TB3_BEFORE")" s3 id:queue-a3
  close_pr "$TB3_BEFORE"; echo "  BEFORE PR: $TB3_BEFORE (닫음)"
else
  bad "[s3] BEFORE 번역 PR 이 없다 — $L"
fi
echo "  A3 재번역 (고친 뒤)"
L="$(translate "$A3" s3-ta on)"; TA3="$(pr_of "$L")"
[[ -n "$TA3" ]] || { echo "error: TA3 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TA3"; echo "  TA3: $TA3"
merge_pr "$TA3"
N="$(webhook_merged "$TA3")"; next_is "$B3" "$N"
L="$(translate "$B3" s3-next on)"; TB3="$(pr_of "$L")"
[[ -n "$TB3" ]] || { echo "error: TB3 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TB3"; retitle "$TB3" "[AFTER]"; echo "  TB3: $TB3"
check_ref "$(head_ref "$TB3")" s3-after id:queue-a3 tok:QUEUE-S3-B-TOKEN || FAIL=1
narrow "$TB3" s3-after
merge_pr "$TB3"; webhook_merged "$TB3" >/dev/null

# ═══ S4 대조군 ═══════════════════════════════════════════════════════════
echo; echo "═══ S4 대조군 — 앞선 PR 이 없는 평범한 PR"
C="$(make_pr "translate-test/${TS}-q-c" body:QUEUE-S4-C-TOKEN "[e2e] queue S4 control — body edit (${TS})")"; echo "  C: $C"
merge_pr "$C"
L="$(translate "$C" s4 on)"; TC="$(pr_of "$L")"
grep -q "is next on" "$L" && ok "큐 판정: 곧바로 차례" || bad "대조군이 차례가 아님 — $L"
grep -q "DEFERRED:" "$L" && bad "대조군이 대기함" || ok "대기 없음"
[[ -n "$TC" ]] || { echo "error: TC 없음 — $L" >&2; exit 2; }
e2e_label_pr "$REPO" "$TC"; echo "  TC: $TC"
check_ref "$(head_ref "$TC")" s4 tok:QUEUE-S4-C-TOKEN || FAIL=1
narrow "$TC" s4
merge_pr "$TC"
N="$(webhook_merged "$TC")"; [[ -z "$N" ]] && ok "TC 머지 → 줄이 빈다" || bad "줄에 #$N 가 남음"
has_label "$C" && bad "C 라벨이 남아 있음" || ok "C 완료"

echo
echo "결과"
echo "  session: $SESSION"
echo "  S1: A1 $A1 · TA1 $TA1 · B1 $B1 · [BEFORE] ${TB1_BEFORE:-–} · [AFTER] ${TB1:-–}"
echo "  S2: A2 $A2 · TA2 $TA2 (닫음) · TA2' ${TA2B:-–} · B2 $B2 · TB2 ${TB2:-–}"
echo "  S3: A3 $A3 (실패) · TA3 ${TA3:-–} · B3 $B3 · [BEFORE] ${TB3_BEFORE:-–} · [AFTER] ${TB3:-–}"
echo "  S4: C $C · TC ${TC:-–}"
echo "  logs: $LOGDIR"
if (( FAIL )); then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS — 머지 순서대로 하나씩, 앞 번역이 끝나기 전엔 대기, 차례의 번역은 자기 변경만 · en/ja anchor 순서 == ko"
