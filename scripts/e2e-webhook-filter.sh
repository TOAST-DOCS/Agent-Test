#!/usr/bin/env bash
#
# webhook 필터의 base_branches 를 세션 브랜치로 임시 확장/원복 (공용 헬퍼).
#
# `e2e-webhook.sh` 안에 있던 것을 그대로 꺼냈다 — `e2e-webhook-concurrent.sh`
# 도 같은 일을 해야 하고, 원복 로직이 두 벌이면 한쪽만 낡아 필터가 세션
# 브랜치를 단 채 남는다.
#
# webhook 필터 (dashboard 어드민 → 🪝 Webhook 대상 repo) 는 job(translate /
# ko-review) 별로 base_branches 를 가진다. 세션 브랜치를 base 로 쓰려면 두
# job 각각에 세션 브랜치 이름을 append 하고, 종료 시 append 전 값으로 되돌린다
# (다른 필드는 그대로). 필터 POST 는 전체 필드를 요구하는 완전 치환 API 라
# 현재값을 읽어 base_branches 만 바꿔 다시 보낸다.
#
# 쓰는 쪽에서 필요한 전역: `DASHBOARD_BASE_URL` · `DASHBOARD_API_TOKEN`.
#
#   source "$(dirname "$0")/e2e-webhook-filter.sh"
#   trap 'restore_filters' EXIT
#   extend_filters_for_branch "$SESSION"

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

# 필터 갱신은 "읽고 → 고치고 → 쓰는" 완전 치환이라, 같은 머신에서 두 e2e 가 겹치면
# 한쪽의 갱신이 다른 쪽 것을 덮는다. 그래서 갱신 구간을 flock 으로 감싸고, 원복은
# "시작 시점 값으로 되돌리기" 가 아니라 **내가 넣은 브랜치만 빼기** 로 한다.
# 예전 방식(ORIG 값 복원)은 병렬 실행에서 먼저 끝난 쪽이 아직 도는 쪽의 세션
# 브랜치까지 지웠다 — suite 가 webhook-lag-order 의 케이스 넷을 동시에 돌리면서
# 생긴 요구다. 단독 실행에서는 두 방식의 결과가 같다 (빈 값 '' = 모든 base 허용도
# 그대로 '' 로 돌아온다).
E2E_FILTER_LOCK="${E2E_FILTER_LOCK:-/tmp/e2e-webhook-filter.lock}"
FILTER_BRANCH=""
declare -A FILTER_ADDED=()   # job → 1 (이 프로세스가 실제로 append 한 job)

# $1=job $2=add|remove $3=branch — 잠금 안에서 현재값을 읽어 브랜치 하나만 더하거나 뺀다.
_edit_filter_branch() {
  local job="$1" op="$2" br="$3" cur new
  cur="$(_get_filters | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(((d.get('filters') or {}).get('$job') or {}).get('base_branches') or '')
")" || return 1
  if [[ "$op" == add ]]; then
    if [[ ",$cur," == *",$br,"* ]]; then echo "    $job: '$cur' (이미 포함)"; return 2; fi
    new="${cur:+$cur,}$br"
  else
    new="$(python3 -c "import sys; print(','.join(x for x in sys.argv[1].split(',') if x.strip() and x.strip() != sys.argv[2]))" "$cur" "$br")"
    [[ "$new" == "$cur" ]] && return 0
  fi
  echo "    $job: '$cur' → '$new'"
  _set_filter "$job" "$new" >/dev/null
}

# $1 = 세션 브랜치. translate + ko-review 두 필터의 base_branches 에 append.
extend_filters_for_branch() {
  local br="$1" job rc
  FILTER_BRANCH="$br"
  echo "  [filter] appending '$br' to filter.base_branches (translate + ko-review)"
  for job in translate ko-review; do
    ( flock -w 60 9 || { echo "  [filter] WARN: 잠금 대기 초과 — 잠금 없이 진행" >&2; }
      _edit_filter_branch "$job" add "$br" ) 9>"$E2E_FILTER_LOCK"
    rc=$?
    (( rc == 0 )) && FILTER_ADDED[$job]=1
  done
  FILTER_EXTENDED=1
}

restore_filters() {
  # trap 에서 호출. 이미 원복돼 있으면 no-op. 내가 넣은 브랜치만 뺀다.
  (( FILTER_EXTENDED )) || return 0
  local job
  for job in translate ko-review; do
    [[ -n "${FILTER_ADDED[$job]:-}" ]] || continue
    echo "  [cleanup] removing '$FILTER_BRANCH' from filter[$job].base_branches"
    ( flock -w 60 9 || echo "  [cleanup] WARN: 잠금 대기 초과 — 잠금 없이 진행" >&2
      _edit_filter_branch "$job" remove "$FILTER_BRANCH" ) 9>"$E2E_FILTER_LOCK" || \
      echo "  [cleanup] WARN: 필터 원복 실패 ($job) — dashboard 어드민에서 수동 확인 필요" >&2
  done
  FILTER_ADDED=()
  FILTER_EXTENDED=0
}

# ── 리포별 override (webhook_repo_filter_override) ───────────────────
# 전역 필터만 넓혀서는 부족한 리포가 있다 — 리포 override 는 dim 별로 전역을
# **덮어쓴다** (webhook/store.merge_job_filter). 실측 (2026-10-09,
# cloud-docs/Internal-Agent-Test): override `base_branches=alpha` 가 세션 브랜치를
# 막고, override 에 author_skip 이 없어 전역 skip 목록(e2e PR 작성자 포함)을
# 물려받았다. Agent-Test 는 override 가 `base_branches=""`(전부 허용) ·
# `author_skip=anytime-modify` 라 우연히 통과하던 것이다.
#
# 그래서 세션 동안만 그 리포의 override 를 고친다: base_branches override 가
# 세션 브랜치를 막으면 덧붙이고, 실효 author_skip 에 e2e 작성자가 있으면 그
# 작성자만 뺀다. 원래 없던 dim 은 null 로 되돌린다(= 전역 상속).
declare -A ORIG_REPO_OVERRIDE=()   # "<job>|<dim>" → JSON 값 (null = override 없음)
REPO_OVERRIDE_EXTENDED=0

_set_repo_override() {
  # $1=job $2=overrides JSON
  python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$REPO" "$1" "$2" <<'PY'
import json, sys, urllib.request
base_url, token, repo, job, ov = sys.argv[1:6]
body = json.dumps({"repo": repo, "job": job, "overrides": json.loads(ov)}).encode()
req = urllib.request.Request(f"{base_url}/api/webhooks/repos/override", data=body,
    method="POST", headers={"Authorization": f"Bearer {token}",
                            "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=15) as r:
    json.load(r)
PY
}

extend_repo_override_for_session() {
  # $1=session base branch  $2=e2e PR author login
  local br="$1" author="$2" plan job
  plan="$(python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$REPO" "$br" "$author" <<'PY'
import json, sys, urllib.request
base_url, token, repo, br, author = sys.argv[1:6]
req = urllib.request.Request(f"{base_url}/api/webhooks/repos",
                             headers={"Authorization": f"Bearer {token}"})
with urllib.request.urlopen(req, timeout=15) as r:
    d = json.load(r)
want = repo.lower()
key = next((k for k in (d.get("repo_overrides") or {})
            if k == want or k.endswith("/" + want)), None)
ovs = (d.get("repo_overrides") or {}).get(key) or {}
out = {}
for job in ("translate", "ko-review"):
    ov = ovs.get(job) or {}
    glob = (d.get("filters") or {}).get(job) or {}
    new, orig = {}, {}
    bb = ov.get("base_branches")
    if bb:                      # override 가 있고 비어 있지 않음 → 세션 브랜치가 막힌다
        items = [x.strip() for x in bb.split(",") if x.strip()]
        if br not in items:
            orig["base_branches"] = bb
            new["base_branches"] = ",".join(items + [br])
    eff = ov["author_skip"] if "author_skip" in ov else (glob.get("author_skip") or "")
    skip = [x.strip() for x in eff.split(",") if x.strip()]
    if author and author.lower() in [x.lower() for x in skip]:
        orig["author_skip"] = ov["author_skip"] if "author_skip" in ov else None
        new["author_skip"] = ",".join(x for x in skip if x.lower() != author.lower())
    out[job] = {"new": new, "orig": orig}
print(json.dumps(out))
PY
)" || { echo "  [override] WARN: 리포 override 를 읽지 못했습니다 — 그대로 진행" >&2; return 0; }
  for job in translate ko-review; do
    local new orig
    new="$(printf '%s' "$plan" | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin)['$job']['new']))")"
    orig="$(printf '%s' "$plan" | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin)['$job']['orig']))")"
    [[ "$new" == "{}" ]] && continue
    echo "  [override] $REPO $job: $new (원래: $orig)"
    ORIG_REPO_OVERRIDE[$job]="$orig"
    _set_repo_override "$job" "$new"
    REPO_OVERRIDE_EXTENDED=1
  done
}

restore_repo_override() {
  (( REPO_OVERRIDE_EXTENDED )) || return 0
  local job
  for job in translate ko-review; do
    [[ -n "${ORIG_REPO_OVERRIDE[$job]+set}" ]] || continue
    echo "  [cleanup] restoring override[$REPO][$job] = ${ORIG_REPO_OVERRIDE[$job]}"
    _set_repo_override "$job" "${ORIG_REPO_OVERRIDE[$job]}" || \
      echo "  [cleanup] WARN: override 원복 실패 ($job) — 어드민 ▸ Webhook 설정에서 확인" >&2
  done
  REPO_OVERRIDE_EXTENDED=0
}
