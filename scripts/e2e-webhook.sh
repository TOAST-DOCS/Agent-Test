#!/usr/bin/env bash
#
# webhook 라우팅 e2e 검증 (Agent-Test alpha):
#   1) alpha 를 기반으로 세션 브랜치를 만들고 ko 파일 하나를 소폭 수정
#   2) base=alpha 로 PR 을 open → GitHub 이 webhook pod 으로 pull_request/opened 전송
#   3) dashboard /api/jobs 에서 이 PR 을 라벨로 담은 webhook Job(opened) 을 감지하고
#      그 아래 ko-review task 가 큐잉/실행/성공했는지 확인
#      → "ko 변경 PR 등록 시 한글 검수가 실행되는가" 검증
#   4) PR 을 merge → GitHub 이 pull_request/closed(merged=true) 전송
#   5) dashboard /api/jobs 에서 webhook Job(closed) 을 감지하고 그 아래
#      translate task 가 큐잉/실행/성공했는지 확인
#      → "머지 시 번역이 실행되는가" 검증
#
# webhook 필터 (dashboard 어드민 → 🪝 Webhook 대상 repo) 현행 (2026-07-28):
#   translate  : actions=merged,                    base=alpha,beta
#   ko-review  : actions=opened,review_requested,synchronize, base=alpha,beta
# 이 필터에 부합하도록 이 스크립트는 반드시 base=alpha 로 PR 을 연다.
#
# 다른 e2e 스크립트가 세션 브랜치(e2e/<ts>) 를 쓰는 것과 달리, webhook 필터의
# base_branches 는 alpha/beta 로 잠겨 있어 세션 브랜치를 base 로 쓰면 필터에서
# skip 되므로 여기서는 target=alpha 를 그대로 사용한다. head 브랜치만
# translate-test-webhook/<ts> 로 격리하고, merge 이후 남는 아티팩트(alpha 의
# 작은 마커 커밋, translate 잡이 열 번역 PR)는 정기 restore-alpha-origin.sh /
# 수동 정리에 맡긴다 — 이는 기존 e2e-align-and-translate.sh 와 동일한 관례.
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-webhook.sh
#   bash scripts/e2e-webhook.sh --no-merge         # 3단계까지만 (opened 만 검증)
#   bash scripts/e2e-webhook.sh --timeout 600      # 각 폴링 단계 타임아웃(초)
#
# 의존성: git, gh (로그인), curl, python3
set -eo pipefail
set -u

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"

REPO="TOAST-DOCS/Agent-Test"
REPO_LOWER="toast-docs/agent-test"
BASE_BRANCH="alpha"
POLL_TIMEOUT=600     # 초. opened → ko-review task 등장까지 / merged → translate task 등장까지 각각.
POLL_INTERVAL=5      # 초.
DO_MERGE=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-merge) DO_MERGE=0; shift ;;
    --timeout)  POLL_TIMEOUT="$2"; shift 2 ;;
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

# ── helper: dashboard /api/jobs 스캔 ─────────────────────────────────
# stdout: JSON — {"job_id": "...", "task": {...}} 또는 빈 dict {}
#
# 라벨 패턴이 여러 가지 (parent job type=webhook 이면 "X#N (opened)",
# type=ko-review 면 "한글 검수 (webhook): X#N (opened)", type=translate 면
# "번역: <pr_url>") 이므로 세 가지 신호 중 하나라도 걸리는 job 후보를 모으고
# task 상세로 확정한다.
#   신호 A: label 에 "#<PR> (<action>)" 포함
#   신호 B: label 에 우리 PR URL 포함 (translate 처럼 URL 만 있는 케이스)
# 각 후보 job 의 tasks 중 label 이 "<kind>:" 로 시작하고 result_url 이
# 우리 PR URL 이면 hit. webhook 이 붙인 params (webhook_action / webhook_pr_number)
# 도 있으면 함께 활용 (신·구 파이프라인 양쪽 대응).
find_webhook_task() {
  # args:
  #   $1 = pr_url
  #   $2 = pr_number
  #   $3 = action label ('opened' | 'closed'/'merged')
  #   $4 = task kind ('ko-review' | 'translate')
  local pr_url="$1" pr_number="$2" action="$3" kind="$4"
  # 주의: `curl | python3 - args <<'PY'` 형태로 하면 heredoc 이 stdin 을 덮어써
  # curl 출력이 python 에 도달하지 못한다 (실측: JSONDecodeError). HTTP 호출을
  # python 안에서 urllib 로 직접 수행한다.
  python3 - "$REPO" "$pr_url" "$pr_number" "$action" "$kind" \
             "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" <<'PY'
import json, sys, urllib.request

repo, pr_url, pr_number, action, kind, base_url, token = sys.argv[1:8]

def _get(path):
    # 폴링 중 dashboard LB 가 idle keep-alive 를 잠깐 닫는 등 일시적 네트워크
    # 에러가 발생할 수 있음 (실측: RemoteDisconnected). 스크립트 전체가
    # 죽으면 leftover PR 만 남으므로 소규모 재시도.
    import time
    last_err = None
    for _ in range(3):
        try:
            req = urllib.request.Request(
                f"{base_url}{path}",
                headers={"Authorization": f"Bearer {token}"},
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                return json.load(resp)
        except Exception as e:
            last_err = e
            time.sleep(1)
    raise last_err

_data = _get("/api/jobs?limit=200")

action_needle = f"#{pr_number} ({action})"
cand = []
for j in _data.get("jobs", []):
    label = j.get("label") or ""
    if action_needle in label or pr_url in label:
        cand.append(j)

if not cand:
    print(json.dumps({}))
    raise SystemExit(0)

# 가장 최근 (created_at 큰) job 부터 확인 — 같은 PR 에 대해 여러 delivery /
# retry 가 있을 수 있음. task 매칭이 걸리는 첫 job 을 채택.
cand.sort(key=lambda x: x.get("created_at") or 0, reverse=True)

def _parse_params(raw):
    if isinstance(raw, dict):
        return raw
    try:
        return json.loads(raw or "{}")
    except Exception:
        return {}

hit = None
for job in cand:
    detail = _get(f"/api/jobs/{job['id']}")
    tasks = (detail.get("job") or {}).get("tasks") or []
    for t in tasks:
        lab = (t.get("label") or "").lower()
        if not lab.startswith(f"{kind}:") and not lab.startswith(kind + " "):
            # translate 잡의 task label 은 순수 PR URL 만 (kind prefix 없음) —
            # result_url 로 매칭 가능한지 아래서 다시 본다.
            if kind == "translate" and (t.get("result_url") or "") == pr_url:
                pass
            else:
                continue
        # 우리 PR 이 맞는지 재확인 — result_url 또는 params 의 webhook_pr_url
        result_url = (t.get("result_url") or "").rstrip("/")
        params = _parse_params(t.get("params"))
        pr_match = (
            result_url == pr_url.rstrip("/")
            or params.get("webhook_pr_url", "").rstrip("/") == pr_url.rstrip("/")
            or str(params.get("webhook_pr_number") or "") == str(pr_number)
        )
        if not pr_match:
            continue
        # action 도 params 가 있으면 재확인 (신 파이프라인)
        wa = str(params.get("webhook_action") or "").lower()
        if wa and wa != action.lower():
            # merged 를 closed 로도 표기하므로 완만하게 허용
            if not (action == "closed" and wa == "merged"):
                continue
        hit = {"job_id": job["id"], "task": t}
        break
    if hit:
        break

print(json.dumps(hit or {}))
PY
}

# 종료 상태 요약용
OPENED_RESULT="-"
MERGED_RESULT="-"

echo "==================================================================="
echo "  webhook e2e — Agent-Test"
echo "  head branch : $HEAD_BRANCH"
echo "  base branch : $BASE_BRANCH"
echo "  timeout(s)  : $POLL_TIMEOUT"
echo "==================================================================="

# ── 1) 세션 브랜치 준비 ──────────────────────────────────────────────
echo
echo "[1/6] alpha 최신화 + head 브랜치 생성"
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
for lbl in "content-agent" "한글 검수"; do
  if ! gh label list --repo "$REPO" --search "$lbl" --json name --jq '.[].name' 2>/dev/null | grep -Fxq "$lbl"; then
    gh label create "$lbl" --repo "$REPO" --color "1d76db" --description "webhook filter label" 2>/dev/null || true
  fi
done
pr_url="$(gh pr create --repo "$REPO" \
  --base "$BASE_BRANCH" --head "$HEAD_BRANCH" \
  --label "content-agent" --label "한글 검수" \
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
fi

# 실패해도 merge 단계는 시도 (--no-merge 로 요청받은 게 아니라면).
if [[ "$OPENED_RESULT" != "PASS" && "$DO_MERGE" == "1" ]]; then
  echo "  (참고) opened 단계 실패지만 --no-merge 가 아니므로 merge 단계도 시도합니다."
fi

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
  fi
fi

echo
echo "==================================================================="
echo "  결과 요약"
echo "==================================================================="
echo "  PR                              : $pr_url"
echo "  opened → ko-review triggered    : $OPENED_RESULT"
echo "  merged → translate triggered    : $MERGED_RESULT"
echo "==================================================================="

if [[ "$OPENED_RESULT" != "PASS" ]]; then exit 2; fi
if [[ "$DO_MERGE" == "1" && "$MERGED_RESULT" != "PASS" ]]; then exit 3; fi
exit 0
