#!/usr/bin/env bash
#
# webhook 라우팅 e2e 검증 (Agent-Test 세션 브랜치):
#   0) alpha 로부터 세션 브랜치 e2e-webhook/<ts> 를 만들어 base 로 사용.
#      기본 webhook 필터의 base_branches (alpha,beta) 는 세션 브랜치를 포함하지
#      않으므로, translate/ko-review 두 필터의 base_branches 에 세션 브랜치를
#      임시로 append 한 뒤 스크립트 종료(성공/실패/신호) 시 반드시 원복 (trap).
#   1) 같은 alpha 기점에서 head 브랜치 translate-test-webhook/<ts> 생성 + ko 소폭 수정
#   2) base=e2e-webhook/<ts> 로 PR open → GitHub 이 webhook pod 으로 opened 전송
#   3) dashboard /api/jobs 에서 이 PR 을 담은 webhook Job(opened) 감지 + 그 아래
#      ko-review task 가 큐잉/실행되었는지 확인 → "PR 등록 → 한글 검수" 검증
#   4) PR merge → closed(merged=true) 전송
#   5) /api/jobs 에서 translate task 감지 → "머지 → 번역" 검증
#   5b) 그 translate task 가 받은 파라미터를 **그 시점의 프리셋과 대조** →
#      "트리거됐다" 와 "믿는 조건으로 돌았다" 는 다른 질문이다. 프리셋을
#      Jenkins 파라미터로 옮기는 코드(`dashboard/api/jenkins.py`)는 대시보드와
#      webhook **두 이미지에 사본으로** 살아서, 한쪽만 재배포되면 낡은 쪽이
#      새 플래그를 조용히 떨어뜨린다 (Jenkinsfile 기본값이 들어간다). 잡은
#      성공하고 번역 PR 도 열리므로 어디에도 실패로 남지 않는다.
#      기존 e2e 로는 원리상 안 잡힌다 — `e2e-list-items-pipeline.sh` 는
#      **대시보드 경로**의 플래그만 보고, 이 스크립트는 여태 **트리거 여부만**
#      보고 파라미터 값은 보지 않았다.
#
#      **이 판정이 묻는 것은 "그 플래그가 켜져 있어야 한다" 가 아니다.**
#      프리셋 자체가 운영에서 단계적으로 바뀌는 값이고(새 플래그는 Agent-Test
#      같은 테스트 리포에서 먼저 쓰고 실서비스 리포에는 나중에 연다), 그때그때의
#      프리셋이 정본이다. 여기서 묻는 것은 **그 시점의 프리셋과 잡이 받은
#      파라미터가 일치하는가** — 즉 매핑 사본이 프리셋을 따라잡고 있는가 하나다.
#      (2026-09-21 RDS#390 → translate #717 이 `list_items` 없이 돈 것은 이
#      의미의 drift 가 아니라 아직 실서비스에 열기 전이었던 정상 상태다.
#      /daily-webhook-review 가 한 번 결함으로 잘못 적었고 운영자가 정정했다.)
#   6) 세션 브랜치 삭제 (남아 있는 translate PR 은 base 사라짐과 함께 자동
#      closed) + 필터 base_branches 원복
#
# 이렇게 하면 alpha/beta 는 손대지 않는다. 세션 브랜치의 unique 이름 덕에
# trap 이 실패로 원복이 못 되어도 다른 delivery 에 영향을 주지 않는다.
#
# webhook 필터 (dashboard 어드민 → 🪝 Webhook 대상 repo) 는 job 별로:
#   translate  : actions=merged,                             base=alpha,beta
#   ko-review  : actions=opened,review_requested,synchronize, base=alpha,beta
# 두 필터의 base_branches 는 각각 개별 append/restore.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-webhook.sh
#   bash scripts/e2e-webhook.sh --no-merge         # 3단계까지만 (opened 만 검증)
#   bash scripts/e2e-webhook.sh --timeout 600      # 각 폴링 단계 타임아웃(초)
#   bash scripts/e2e-webhook.sh --base alpha       # 세션 브랜치 대신 alpha 를 base 로 (구 동작)
#   bash scripts/e2e-webhook.sh --no-wait-build    # task 큐잉만 확인하고 즉시 cleanup (빠른 스모크)
#   bash scripts/e2e-webhook.sh --build-timeout 1500  # 각 Jenkins 빌드 완료 대기 상한 (기본 900s)
#   bash scripts/e2e-webhook.sh --no-preset-check  # 5b) 프리셋 대조를 건너뜀
#
# 의존성: git, gh (로그인), curl, python3
set -eo pipefail
set -u

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
# e2e 산출물 PR 에 'e2e' 라벨 (사람이 만든 PR 과 구분)
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

REPO_LOWER="toast-docs/agent-test"
BASE_BRANCH=""       # 미지정 → 세션 브랜치 e2e-webhook/<ts> 자동 생성. --base 로 override.
BASE_SOURCE="alpha"  # 세션 브랜치를 갈라낼 원본
POLL_TIMEOUT=600     # 초. opened → ko-review task 등장까지 / merged → translate task 등장까지 각각.
POLL_INTERVAL=5      # 초.
DO_MERGE=1
# task 큐잉 확인 후, 실제 Jenkins 빌드가 끝날 때까지 폴링. 기본 ON — 세션
# 브랜치 cleanup 이 빌드 실행 전에 base 를 지워 빌드가 404 로 죽는 race 를
# 방지 (실측: translate-20260803-2, Jenkins #223). --no-wait-build 로 opt-out.
WAIT_BUILD=1
BUILD_TIMEOUT=900    # 초. 각 빌드 (ko-review · translate) 완료 대기 상한.
# 5b) translate task 가 받은 파라미터 ↔ 운영 프리셋 대조. 기본 ON.
PRESET_CHECK=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-merge)      DO_MERGE=0; shift ;;
    --timeout)       POLL_TIMEOUT="$2"; shift 2 ;;
    --base)          BASE_BRANCH="$2"; shift 2 ;;   # ex) --base alpha  (필터 수정 없이 alpha 직접 사용)
    --no-wait-build) WAIT_BUILD=0; shift ;;
    --build-timeout) BUILD_TIMEOUT="$2"; shift 2 ;;
    --no-preset-check) PRESET_CHECK=0; shift ;;
    -h|--help)  sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다. load_env.sh 를 source 하세요." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ts="$(date -u +%Y%m%d-%H%M%S)"
HEAD_BRANCH="translate-test-webhook/${ts}"
KO_FILE="ko/overview.md"

if [[ ! -f "$KO_FILE" ]]; then
  echo "error: $KO_FILE 이(가) 없습니다. Agent-Test 레포 안에서 실행하세요." >&2
  exit 1
fi

# ── webhook 딜리버리 → task 되짚기 (공용 helper) ─────────────────────
# `find_webhook_task` / `wait_for_webhook_task` / `task_present` /
# `task_field` / `wait_for_build_finish`. label 모양이 잡마다 다르고 그 예외
# 목록이 스크립트마다 복사되면 한쪽만 낡는데, 낡은 쪽은 "트리거 안 됨" 이라는
# 거짓 실패로 나타난다 — 그래서 한 벌만 둔다.
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-task.sh"

# ── webhook 대상 repo 활성화 토글 ──────────────────────────────────
# webhook e2e 는 시작 시 Agent-Test 를 webhook 대상으로 활성화하고, 종료 시
# 비활성화한다 (번역 e2e 들은 자체적으로 시작 시 비활성화 — 평상시 off 가
# 기본 상태). pipeline_branch 등 기존 설정은 보존.
# webhook 대상 repo 토글 — 공용 헬퍼 (규약: webhook e2e 만 활성화)
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"

# 종료 상태 요약용
OPENED_RESULT="-"
MERGED_RESULT="-"
PRESET_RESULT="-"

# ── filter 확장/원복 helper ───────────────────────────────────────
# webhook 필터의 base_branches 는 dashboard 관리자가 job(translate/ko-review) 별
# 로 설정 (기본 alpha,beta). 세션 브랜치를 base 로 쓰려면 두 job 각각의
# base_branches 에 세션 브랜치 이름을 append 하고, 스크립트 종료 시 append 만
# 걷어내 원본으로 돌린다 (다른 세팅은 그대로).
declare -A ORIG_BASE_BRANCHES=()
FILTER_EXTENDED=0

_get_filters() {
  curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/webhooks/repos"
}

_set_filter() {
  # $1=job(translate|ko-review) $2=base_branches
  # 다른 필드는 현재값 그대로 유지 (POST 는 전체 dict 를 요구)
  local job="$1" base_branches="$2"
  python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$job" "$base_branches" <<'PY'
import json, sys, urllib.request
base_url, token, job, base_branches = sys.argv[1:5]
req = urllib.request.Request(
    f"{base_url}/api/webhooks/repos",
    headers={"Authorization": f"Bearer {token}"},
)
with urllib.request.urlopen(req, timeout=15) as resp:
    data = json.load(resp)
cur = ((data.get("filters") or {}).get(job) or {})
payload = {
    "job": job,
    "actions": cur.get("actions") or "",
    "base_branches": base_branches,
    "author_skip": cur.get("author_skip") or "",
    "label_require": cur.get("label_require") or "",
    "label_skip": cur.get("label_skip") or "",
    "preset": cur.get("preset") or "",
}
body = json.dumps(payload).encode("utf-8")
put = urllib.request.Request(
    f"{base_url}/api/webhooks/filters",
    data=body, method="POST",
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    },
)
with urllib.request.urlopen(put, timeout=15) as r2:
    result = json.load(r2)
print(json.dumps(result))
PY
}

restore_filters() {
  # trap 에서 호출. 이미 원복돼 있으면 no-op.
  (( FILTER_EXTENDED )) || return 0
  for job in translate ko-review; do
    if [[ -n "${ORIG_BASE_BRANCHES[$job]:-}" ]]; then
      echo "  [cleanup] restoring filter[$job].base_branches = '${ORIG_BASE_BRANCHES[$job]}'"
      _set_filter "$job" "${ORIG_BASE_BRANCHES[$job]}" >/dev/null || \
        echo "  [cleanup] WARN: 필터 원복 실패 ($job) — dashboard 어드민에서 수동 확인 필요" >&2
    fi
  done
  FILTER_EXTENDED=0
}

cleanup_session_branch() {
  local br="$1"
  [[ -n "$br" ]] || return 0
  echo "  [cleanup] deleting session branch origin/$br (남아있는 PR 은 자동 close)"
  git push origin ":$br" 2>/dev/null || \
    echo "  [cleanup] WARN: 세션 브랜치 삭제 실패 (이미 없거나 권한 문제)" >&2
}

# ── 세션 브랜치 결정 (미지정 시 자동 생성) + 필터 확장 ────────────────
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-webhook/${ts}"
  USE_SESSION_BRANCH=1
else
  USE_SESSION_BRANCH=0
fi

# 스크립트 종료 시 필터 원복 + (세션 모드면) 브랜치 삭제. cleanup 은 idempotent.
trap 'ec=$?; restore_filters; set_webhook_repo_enabled false; if (( USE_SESSION_BRANCH )); then cleanup_session_branch "$BASE_BRANCH"; fi; exit $ec' EXIT INT TERM

echo "==================================================================="
echo "  webhook e2e — Agent-Test"
echo "  head branch : $HEAD_BRANCH"
echo "  base branch : $BASE_BRANCH$( ((USE_SESSION_BRANCH)) && echo ' (세션, 종료 시 삭제)' )"
echo "  timeout(s)  : $POLL_TIMEOUT"
echo "==================================================================="

# ── 0) Agent-Test 를 webhook 대상으로 활성화 (종료 trap 에서 비활성화) ──
echo
echo "[0/6] webhook 활성화: $REPO"
set_webhook_repo_enabled true

# ── 1) 세션 브랜치 준비 (base 부터, 그 뒤 head) ───────────────────────
echo
echo "[1/6] $BASE_SOURCE 최신화 + $( ((USE_SESSION_BRANCH)) && echo '세션 base + ' )head 브랜치 생성"
git fetch origin "$BASE_SOURCE"

if (( USE_SESSION_BRANCH )); then
  # 세션 base 브랜치: alpha 시점 그대로 origin 에 push (PR 을 걸 대상이 있어야 하므로).
  git branch -f "$BASE_BRANCH" "origin/$BASE_SOURCE"
  git push -u origin "$BASE_BRANCH"

  # 필터의 base_branches 를 세션 브랜치 포함으로 임시 확장.
  echo "  [filter] appending '$BASE_BRANCH' to filter.base_branches (translate + ko-review)"
  _filters_json="$(_get_filters)"
  for job in translate ko-review; do
    cur="$(printf '%s' "$_filters_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
f = (d.get('filters') or {}).get('$job') or {}
print(f.get('base_branches') or '')
")"
    ORIG_BASE_BRANCHES[$job]="$cur"
    if [[ ",$cur," == *",$BASE_BRANCH,"* ]]; then
      new="$cur"
    else
      new="${cur:+$cur,}$BASE_BRANCH"
    fi
    echo "    $job: '$cur' → '$new'"
    _set_filter "$job" "$new" >/dev/null
  done
  FILTER_EXTENDED=1
fi

# 이제 head 브랜치 생성 (base 로부터 갈라짐).
git fetch origin "$BASE_BRANCH"
git checkout -B "$HEAD_BRANCH" "origin/$BASE_BRANCH"

# ── 2) ko 파일 소폭 수정 ─────────────────────────────────────────────
echo
echo "[2/6] $KO_FILE 에 webhook e2e 마커 섹션 추가"
marker_id="webhook-e2e-${ts}"
cat >> "$KO_FILE" <<EOF

<a id="${marker_id}"></a>
## webhook e2e marker ($ts) { #${marker_id} }

이 섹션은 scripts/e2e-webhook.sh 가 삽입한 임시 마커입니다.
webhook 이 이 PR 을 ko-review / translate 잡으로 라우팅하는지 검증한 뒤
마커는 정기 restore-alpha-origin 으로 정리됩니다.
EOF

git add "$KO_FILE"
git commit -m "test(webhook-e2e): add marker section to ${KO_FILE} (${ts})"
git push -u origin "$HEAD_BRANCH"

# ── 3) PR 생성 (base=alpha) ──────────────────────────────────────────
echo
echo "[3/6] PR open (base=$BASE_BRANCH) — GitHub 이 pull_request/opened 발화"
# translate 필터의 label_require (`content-agent,한글 검수`) 를 통과하도록 라벨 부착.
# 두 라벨 모두 없으면 먼저 만든 뒤 PR 에 붙인다 (dashboard 에서 필터가 라벨을
# 요구하는데 Agent-Test 레포에는 라벨이 없어 스킵되던 실측 케이스 대응).
for lbl in "content-agent" "한글 검수" "$E2E_LABEL"; do
  if ! gh label list --repo "$REPO" --search "$lbl" --json name --jq '.[].name' 2>/dev/null | grep -Fxq "$lbl"; then
    gh label create "$lbl" --repo "$REPO" --color "1d76db" --description "webhook filter label" 2>/dev/null || true
  fi
done
pr_url="$(gh pr create --repo "$REPO" \
  --base "$BASE_BRANCH" --head "$HEAD_BRANCH" \
  --label "content-agent" --label "한글 검수" --label "$E2E_LABEL" \
  --title "test(webhook-e2e): $HEAD_BRANCH" \
  --body "webhook e2e 검증용 임시 PR — scripts/e2e-webhook.sh 가 open/merge 흐름을 통해 ko-review 와 translate 트리거를 확인한다.")"
echo "  PR: $pr_url"
pr_number="${pr_url##*/}"

# ── 4) opened → ko-review task 대기 ────────────────────────────────
echo
echo "[4/6] webhook Job(opened) + ko-review task 등장 대기 (최대 ${POLL_TIMEOUT}s)"
deadline=$(( $(date +%s) + POLL_TIMEOUT ))
task_json=""
while (( $(date +%s) < deadline )); do
  # || true — 폴링 중 서브셸(python) 이 예외로 죽어도 loop 는 계속 (일시적
  # 네트워크 오류가 스크립트 전체를 죽이지 않도록).
  task_json="$(find_webhook_task "$pr_url" "$pr_number" "opened" "ko-review" || echo '{}')"
  if [[ "$task_json" != "{}" ]]; then
    task_present="$(printf '%s' "$task_json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("y" if d.get("task") else "n")' 2>/dev/null || echo n)"
    if [[ "$task_present" == "y" ]]; then
      break
    fi
  fi
  sleep "$POLL_INTERVAL"
done

if [[ "$task_json" == "{}" || -z "$task_json" ]] \
   || [[ "$(printf '%s' "$task_json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("y" if d.get("task") else "n")')" != "y" ]]; then
  echo "  FAIL: ${POLL_TIMEOUT}s 내에 opened → ko-review task 를 감지하지 못했습니다." >&2
  OPENED_RESULT="FAIL (timeout)"
else
  echo "$task_json" | python3 -m json.tool
  OPENED_RESULT="PASS"
  if (( WAIT_BUILD )); then
    ko_review_job_id="$(printf '%s' "$task_json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("job_id",""))')"
    ko_review_task_id="$(printf '%s' "$task_json" | python3 -c 'import json,sys; print((json.load(sys.stdin).get("task") or {}).get("id",""))')"
    if [[ -n "$ko_review_job_id" && -n "$ko_review_task_id" ]]; then
      wait_for_build_finish "$ko_review_job_id" "$ko_review_task_id" || true
    fi
  fi
fi

# 실패해도 merge 단계는 시도 (--no-merge 로 요청받은 게 아니라면).
if [[ "$OPENED_RESULT" != "PASS" && "$DO_MERGE" == "1" ]]; then
  echo "  (참고) opened 단계 실패지만 --no-merge 가 아니므로 merge 단계도 시도합니다."
fi

# ── 5b) 프리셋 대조 ───────────────────────────────────────────────────
# "돌았는가" 와 "무슨 조건으로 돌았는가" 는 다른 질문이다. webhook 은 프리셋
# (`/api/translate/presets` 의 recommended, 운영은 ConfigMap `toast-docs-presets`)
# 을 자기 이미지 안의 `dashboard/api/jenkins.py` 사본으로 파라미터에 옮긴다.
# 그 사본이 낡으면 **새 플래그만 조용히 사라진다** — 잡은 성공하고 PR 도 열리므로
# 어디에도 실패로 남지 않는다. 그래서 여기서 바이트로 대조한다.
#
# 기준은 **지금 이 순간의 프리셋**이지 "어떤 플래그가 켜져 있어야 한다" 가 아니다.
# 프리셋은 운영에서 단계적으로 열리는 값이라, 켜지지 않은 플래그가 파라미터에
# 없는 것은 정상이다 — 프리셋이 켜라고 했는데 빠진 것만 결함이다.
#
# 대조는 dashboard job 의 task.params 로 한다 (Jenkins 자격증명이 필요 없다).
# webhook 이 Jenkins 로 넘긴 opts 가 그대로 들어 있어, 키가 없으면 그 플래그는
# Jenkinsfile 기본값으로 떨어진 것이다.
#
# 판정: 프리셋이 **켜라고 한** 값(true / 비어있지 않은 문자열)만 본다. 끄라고 한
# 값(false)은 webhook 이 키 자체를 생략하기도 해서 (`--no-skip-full-table`)
# 있고 없음이 같은 뜻이라 대조 대상이 아니다.
preset_check() {   # $1 = translate task 의 params JSON 문자열 → 0 OK / 1 drift
  local task_params="$1"
  local presets
  presets="$(curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
               "$DASHBOARD_BASE_URL/api/translate/presets" 2>/dev/null || echo '')"
  if [[ -z "$presets" ]]; then
    echo "  WARN: /api/translate/presets 를 읽지 못해 프리셋 대조를 건너뜁니다." >&2
    return 2
  fi
  PRESET_PARAMS="$presets" TASK_PARAMS="$task_params" python3 <<'PY'
import json, os, sys

# 프리셋 patch 의 UI id → webhook 이 Jenkins 로 넘기는 opts 키.
# (cloud-translate `dashboard/api/jenkins.py` 의 매핑과 짝이다.)
UI_TO_OPT = {
    "tx-granularity":         "diff_granularity",
    "tx-glossary":            "glossary_mode",
    "tx-max-load-ratio":      "max_load_ratio",
    "tx-table-rows":          "table_rows",
    "tx-skip-anchor-only":    "skip_anchor_only",
    "tx-assign-anchors":      "assign_anchors",
    "tx-align-headings":      "align_headings",
    "tx-skip-full-table":     "skip_full_table",
    "tx-load-exclude-tables": "load_exclude_tables",
    "tx-list-items":          "list_items",
    "tx-unit-preserve":       "unit_preserve",
    "tx-table-key-align":     "table_key_align",
    "tx-preserve-existing":   "preserve_existing",
    "tx-skip-unaligned":      "skip_unaligned",
    "tx-only-unaligned":      "only_unaligned",
}

presets = json.loads(os.environ["PRESET_PARAMS"])
rows = presets.get("presets") if isinstance(presets, dict) else presets
patch = {}
for p in rows or []:
    if p.get("name") in (None, "recommended"):
        patch = p.get("patch") or {}
        break

try:
    task = json.loads(os.environ["TASK_PARAMS"] or "{}")
except Exception:
    task = {}

unknown, drift, ok = [], [], []
for ui, want in (patch or {}).items():
    opt = UI_TO_OPT.get(ui)
    if opt is None:
        unknown.append(ui)
        continue
    if want is False or want == "" or want is None:
        continue                      # 끄라고 한 값은 생략과 구분되지 않는다
    got = task.get(opt, "<없음>")
    if want is True:
        good = got is True
    else:
        good = str(got) == str(want)
    (ok if good else drift).append((opt, want, got))

for opt, want, got in sorted(ok):
    print("    ok   %-20s = %s" % (opt, want))
for opt, want, got in sorted(drift):
    print("    DRIFT %-20s 프리셋=%s  잡이 받은 값=%s" % (opt, want, got))
if unknown:
    print("    (주의) 이 스크립트가 모르는 프리셋 키: %s — UI_TO_OPT 에 추가하세요"
          % ", ".join(sorted(unknown)))
sys.exit(1 if drift else 0)
PY
}

# ── 5) merge (--no-merge 면 skip) ─────────────────────────────────────
if [[ "$DO_MERGE" != "1" ]]; then
  echo
  echo "[5/6] --no-merge — merge 단계 건너뜀"
  MERGED_RESULT="skipped"
else
  echo
  echo "[5/6] PR merge — GitHub 이 pull_request/closed (merged=true) 발화"
  gh pr merge "$pr_url" --repo "$REPO" --merge --delete-branch

  # ── 6) merged → translate task 대기 ─────────────────────────────
  echo
  echo "[6/6] webhook Job(closed) + translate task 등장 대기 (최대 ${POLL_TIMEOUT}s)"
  deadline=$(( $(date +%s) + POLL_TIMEOUT ))
  task_json=""
  while (( $(date +%s) < deadline )); do
    task_json="$(find_webhook_task "$pr_url" "$pr_number" "closed" "translate" || echo '{}')"
    if [[ "$task_json" != "{}" ]]; then
      task_present="$(printf '%s' "$task_json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("y" if d.get("task") else "n")' 2>/dev/null || echo n)"
      if [[ "$task_present" == "y" ]]; then
        break
      fi
    fi
    sleep "$POLL_INTERVAL"
  done

  if [[ "$task_json" == "{}" || -z "$task_json" ]] \
     || [[ "$(printf '%s' "$task_json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("y" if d.get("task") else "n")')" != "y" ]]; then
    echo "  FAIL: ${POLL_TIMEOUT}s 내에 closed → translate task 를 감지하지 못했습니다." >&2
    MERGED_RESULT="FAIL (timeout)"
  else
    echo "$task_json" | python3 -m json.tool
    MERGED_RESULT="PASS"

    # 5b) 이 잡이 **어떤 조건으로** 돌았는지 — 프리셋과 대조
    if (( PRESET_CHECK )); then
      echo
      echo "[5b] translate task 파라미터 ↔ 운영 프리셋 대조"
      translate_params="$(printf '%s' "$task_json" \
        | python3 -c 'import json,sys; print((json.load(sys.stdin).get("task") or {}).get("params") or "{}")')"
      if preset_check "$translate_params"; then
        PRESET_RESULT="PASS"
      else
        rc=$?
        if (( rc == 2 )); then
          PRESET_RESULT="skipped (프리셋을 읽지 못함)"
        else
          PRESET_RESULT="FAIL (preset drift)"
          echo "  FAIL: webhook 이 넘긴 파라미터가 운영 프리셋과 다릅니다." >&2
          echo "        webhook 이미지의 dashboard/api/jenkins.py 사본이 낡았을 수 있습니다 —" >&2
          echo "        이미지 태그의 커밋 해시를 origin/main 의 그 파일 마지막 변경과 대조하세요." >&2
        fi
      fi
    fi
    if (( WAIT_BUILD )); then
      translate_job_id="$(printf '%s' "$task_json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("job_id",""))')"
      translate_task_id="$(printf '%s' "$task_json" | python3 -c 'import json,sys; print((json.load(sys.stdin).get("task") or {}).get("id",""))')"
      if [[ -n "$translate_job_id" && -n "$translate_task_id" ]]; then
        wait_for_build_finish "$translate_job_id" "$translate_task_id" || true
      fi
    fi
  fi
fi

echo
echo "==================================================================="
echo "  결과 요약"
echo "==================================================================="
echo "  PR                              : $pr_url"
echo "  opened → ko-review triggered    : $OPENED_RESULT"
echo "  merged → translate triggered    : $MERGED_RESULT"
echo "  translate params ↔ preset       : $PRESET_RESULT"
echo "==================================================================="

if [[ "$OPENED_RESULT" != "PASS" ]]; then exit 2; fi
if [[ "$DO_MERGE" == "1" && "$MERGED_RESULT" != "PASS" ]]; then exit 3; fi
if [[ "$PRESET_RESULT" == FAIL* ]]; then exit 4; fi
exit 0
