#!/usr/bin/env bash
#
# 공용: Agent-Test 의 webhook 대상 등록을 켜고 끄는 헬퍼.
#
# **규약: webhook e2e (`e2e-webhook.sh`) 만 활성화하고, 나머지 모든 e2e 는
# 시작 시 비활성화한다.** e2e 는 실제 PR 을 만들고 머지하므로, webhook 이 켜져
# 있으면 그 PR 들이 배포된 webhook pod → Jenkins 의 translate/ko-review 잡을
# **중복 트리거**한다. local 모드에서는 더 나쁘다 — 로컬 번역과 배포본 번역이
# 같은 PR 을 동시에 처리해 결과가 섞인다. (그래서 이 토글은 local 모드에서도
# dashboard 를 호출하는 유일한 지점이고, local 실행에도 DASHBOARD_BASE_URL /
# DASHBOARD_API_TOKEN 이 필요하다.)
#
# 예전에는 이 함수가 네 스크립트에 복붙돼 있고 (align/korean-review/retranslate/
# webhook) `concurrent`·`round2`·`fence-noop`·`file-fail-isolation` 에는 호출이
# **아예 없었다**. `all` 순서상 concurrent 가 마지막이라 앞선 8개가 껐기를 기대해
# 사고가 안 났을 뿐, 단독 실행이나 webhook e2e 가 trap 을 못 타고 죽은 직후에는
# 켜진 채로 돌 수 있었다. 그래서 여기로 모으고 누락된 곳에 호출을 넣었다.
#
# 사용법:
#   source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
#   set_webhook_repo_enabled false     # 번역/검수 e2e 시작 시
#   set_webhook_repo_enabled true      # webhook e2e 만 (종료 trap 에서 false 로)
#
# 전제: DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN / REPO 가 이미 설정돼 있어야 하고,
# 비어 있으면 **하드 실패**한다 (아래 주석 참고).
# repo 행이 없으면 비활성화는 no-op, 활성화는 신규 등록(upsert). pipeline_branch
# 등 기존 설정은 보존한다. 토글 실패는 경고만 내고 계속 진행한다 (스크립트 본체를
# 막지 않기 위해) — 그래서 자격 증명이 비어 있으면 조용히 무방비가 되므로,
# 호출하는 스크립트가 시작 시 자격 증명 유무를 하드 체크해야 한다.
set_webhook_repo_enabled() {
  local enabled="$1"   # true|false
  # 자격 증명은 **하드 체크**한다. 두 가지 실패 모드가 모두 나쁘다:
  #   - `set -u` 를 쓰는 스크립트(concurrent/round2)는 미정의 변수 확장에서
  #     `unbound variable` 로 죽는다 (아래 :- 기본값으로 회피).
  #   - `set -u` 가 없는 스크립트(fence-noop/file-fail-isolation)는 빈 값으로
  #     python 이 실패하고 `|| echo … 계속 진행` 이 그걸 삼켜서, webhook 이 켜진
  #     채로 e2e 가 PR 을 만들고 머지한다 — 이 헬퍼가 막으려는 바로 그 상황이
  #     조용히 벌어진다. 그래서 계속 진행하지 않고 멈춘다.
  local base="${DASHBOARD_BASE_URL:-}" tok="${DASHBOARD_API_TOKEN:-}"
  if [[ -z "$base" || -z "$tok" || -z "${REPO:-}" ]]; then
    echo "error: webhook 토글에 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN / REPO 가 필요합니다." >&2
    echo "       \`source ./load_env.sh\` 를 먼저 실행하세요 — 이 e2e 는 실제 PR 을" >&2
    echo "       만들고 머지하므로 webhook 을 끄지 않은 채 진행할 수 없습니다." >&2
    exit 1
  fi
  python3 - "$base" "$tok" "$REPO" "$enabled" <<'PYEOF' || \
    echo "  (webhook repo 토글 실패 — 계속 진행)" >&2
import json, sys, urllib.request
base_url, token, repo, enabled = sys.argv[1:5]
hdr = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
req = urllib.request.Request(f"{base_url}/api/webhooks/repos", headers=hdr)
with urllib.request.urlopen(req, timeout=15) as r:
    data = json.load(r)
rows = data.get("repos") or []
row = next((x for x in rows if (x.get("repo") or "").lower() == repo.lower()), None)
if row is None and enabled != "true":
    print(f"  webhook repo 미등록 — 비활성화 불필요: {repo}")
    raise SystemExit(0)
on = enabled == "true"
payload = {
    "repo": repo,
    "translate_enabled": on,
    "ko_review_enabled": on,
    "pipeline_branch": (row or {}).get("pipeline_branch") or "",
}
post = urllib.request.Request(
    f"{base_url}/api/webhooks/repos", data=json.dumps(payload).encode("utf-8"),
    method="POST", headers=hdr)
with urllib.request.urlopen(post, timeout=15) as r2:
    json.load(r2)
print(f"  webhook repo {repo}: translate/ko-review enabled={enabled}")
PYEOF
}
