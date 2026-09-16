#!/usr/bin/env bash
#
# webhook 딜리버리 → dashboard task 되짚기 (공용 헬퍼).
#
# `e2e-webhook.sh` 안에 있던 것을 그대로 꺼냈다. 꺼낸 이유는 규칙이 자명하지
# 않기 때문이다 — 같은 딜리버리라도 job 타입에 따라 label 모양이 세 가지고
# (`X#N (opened)` / `한글 검수 (webhook): X#N (opened)` / 순수 PR URL), task
# 매칭도 `result_url` 과 `params.webhook_*` 를 함께 봐야 확정된다. 이 예외
# 목록이 스크립트마다 복사되면 한쪽만 낡고, 낡은 쪽은 "트리거 안 됨" 이라는
# **거짓 실패**로 나타난다 (진짜 결함과 구분이 안 된다).
#
# 쓰는 쪽에서 필요한 전역: `REPO` · `DASHBOARD_BASE_URL` · `DASHBOARD_API_TOKEN`.
#
#   source "$(dirname "$0")/e2e-webhook-task.sh"
#   tj="$(wait_for_webhook_task "$pr_url" "$pr_num" opened ko-review 600 5)"
#   [[ "$(task_present "$tj")" == y ]] && \
#     wait_for_build_finish "$(task_field "$tj" job_id)" "$(task_field "$tj" task_id)"

# stdout: JSON — {"job_id": "...", "task": {...}} 또는 빈 dict {}
#
# 라벨 패턴이 여러 가지라 세 가지 신호 중 하나라도 걸리는 job 후보를 모으고
# task 상세로 확정한다.
#   신호 A: label 에 "#<PR> (<action>)" 포함
#   신호 B: label 에 우리 PR URL 포함 (translate 처럼 URL 만 있는 케이스)
# 각 후보 job 의 tasks 중 label 이 "<kind>:" 로 시작하고 result_url 이 우리 PR
# URL 이면 hit. webhook 이 붙인 params (webhook_action / webhook_pr_number) 도
# 있으면 함께 활용 (신·구 파이프라인 양쪽 대응).
find_webhook_task() {
  # args: $1=pr_url $2=pr_number $3=action('opened'|'closed') $4=kind('ko-review'|'translate')
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

# task_json 에 task 가 들어 있는지 — "y" / "n"
task_present() {
  printf '%s' "${1:-{\}}" | python3 -c \
    'import json,sys
try:
    print("y" if (json.load(sys.stdin) or {}).get("task") else "n")
except Exception:
    print("n")' 2>/dev/null || echo n
}

# task_json 에서 job_id / task_id 뽑기
task_field() {   # $1=json $2=job_id|task_id
  printf '%s' "$1" | python3 -c "
import json, sys
d = json.load(sys.stdin) or {}
print(d.get('job_id','') if '$2' == 'job_id' else (d.get('task') or {}).get('id',''))
" 2>/dev/null || echo ""
}

# task 가 나타날 때까지 폴링. stdout 은 마지막 task_json (없으면 '{}').
# 감지하면 0, 타임아웃이면 1.
wait_for_webhook_task() {
  # args: $1=pr_url $2=pr_number $3=action $4=kind $5=timeout_s $6=interval_s
  local pr_url="$1" pr_number="$2" action="$3" kind="$4"
  local timeout="${5:-600}" interval="${6:-5}"
  local deadline=$(( $(date +%s) + timeout )) tj="{}"
  while (( $(date +%s) < deadline )); do
    # || true — 폴링 중 서브셸(python)이 예외로 죽어도 loop 는 계속 (일시적
    # 네트워크 오류가 스크립트 전체를 죽이지 않도록).
    tj="$(find_webhook_task "$pr_url" "$pr_number" "$action" "$kind" || echo '{}')"
    if [[ "$(task_present "$tj")" == "y" ]]; then
      printf '%s' "$tj"
      return 0
    fi
    sleep "$interval"
  done
  printf '%s' "$tj"
  return 1
}

# task 큐잉 확인 후 실제 Jenkins 빌드가 성공/실패/취소 등 terminal 상태로 굳을
# 때까지 폴링. task 큐잉 성공만 확인하고 곧바로 cleanup 하면 세션 브랜치가
# 지워진 뒤 Jenkins 가 빌드를 시작해 base ref 404 로 죽는다 (실측:
# translate-20260803-2, Jenkins #223). 이 헬퍼가 그 race 를 없앤다.
#
# args: $1=job_id $2=task_id [$3=timeout_s]
# returns: 0 (완료), 1 (timeout)
wait_for_build_finish() {
  local job_id="$1" task_id="$2"
  local timeout="${3:-${BUILD_TIMEOUT:-900}}"
  [[ -n "$job_id" && -n "$task_id" ]] || return 0
  local deadline=$(( $(date +%s) + timeout ))
  echo "  waiting for Jenkins build to reach terminal state (jobs/${job_id}, task=${task_id}, max ${timeout}s)"
  local status="" build_url=""
  while (( $(date +%s) < deadline )); do
    local snapshot
    snapshot="$(curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
      "$DASHBOARD_BASE_URL/api/jobs/$job_id" 2>/dev/null || echo '{}')"
    read -r status build_url < <(printf '%s' "$snapshot" | python3 -c "
import json, sys
d = json.load(sys.stdin)
tasks = (d.get('job') or {}).get('tasks', [])
t = next((x for x in tasks if x.get('id') == '$task_id'), None) or {}
print(t.get('status', '') or '-', t.get('build_url', '') or '-')
" 2>/dev/null || echo "- -")
    case "$status" in
      success|failure|cancelled|aborted|partial)
        echo "  build finished: status=$status  build_url=$build_url"
        return 0
        ;;
    esac
    sleep 5
  done
  echo "  WARN: build did not finish within ${timeout}s (last status=$status build_url=$build_url) — cleanup may race" >&2
  return 1
}
