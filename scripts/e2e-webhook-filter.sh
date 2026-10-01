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

# $1 = 세션 브랜치. translate + ko-review 두 필터의 base_branches 에 append.
extend_filters_for_branch() {
  local br="$1" filters_json cur new job
  echo "  [filter] appending '$br' to filter.base_branches (translate + ko-review)"
  filters_json="$(_get_filters)"
  for job in translate ko-review; do
    cur="$(printf '%s' "$filters_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
f = (d.get('filters') or {}).get('$job') or {}
print(f.get('base_branches') or '')
")"
    ORIG_BASE_BRANCHES[$job]="$cur"
    if [[ ",$cur," == *",$br,"* ]]; then
      new="$cur"
    else
      new="${cur:+$cur,}$br"
    fi
    echo "    $job: '$cur' → '$new'"
    _set_filter "$job" "$new" >/dev/null
  done
  FILTER_EXTENDED=1
}

restore_filters() {
  # trap 에서 호출. 이미 원복돼 있으면 no-op.
  (( FILTER_EXTENDED )) || return 0
  local job
  for job in translate ko-review; do
    # `+set` — 원래 값이 빈 문자열(= 모든 base 허용)이어도 되돌린다. `-n` 으로
    # 보면 그 경우 세션 브랜치 하나만 남아 운영 delivery 가 전부 막힌다.
    if [[ -n "${ORIG_BASE_BRANCHES[$job]+set}" ]]; then
      echo "  [cleanup] restoring filter[$job].base_branches = '${ORIG_BASE_BRANCHES[$job]}'"
      _set_filter "$job" "${ORIG_BASE_BRANCHES[$job]}" >/dev/null || \
        echo "  [cleanup] WARN: 필터 원복 실패 ($job) — dashboard 어드민에서 수동 확인 필요" >&2
    fi
  done
  FILTER_EXTENDED=0
}
