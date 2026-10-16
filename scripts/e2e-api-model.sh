# 공용: --all-haiku(scripts/all-haiku.env.sh) 일 때 대시보드 API 요청 본문에 모델을 싣는다.
#
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/e2e-api-model.sh"
#   curl … -d "$(e2e_api_body "$body")" "$DASHBOARD_BASE_URL/api/ko-review"
#
# api 모드에서 검수·align 은 배포된 Jenkins 잡에서 돌아 로컬 env 가 닿지 않는다. 그래서
# 요청 본문의 `model` 로 넘긴다 (cloud-translate 가 /api/ko-review · /api/align 에 받는
# 필드 — Jenkins MODEL 파라미터 → 잡 안의 TRANSLATE_CLAUDE_CODE_MODEL 등). 본문에 이미
# `model` 이 있으면 그대로 둔다 (호출부가 고른 값이 이긴다). E2E_ALL_HAIKU 가 없으면 본문을
# 바이트 그대로 돌려준다 — 기본 실행은 지금과 같다.
e2e_api_body() {  # $1 = JSON 본문
  if [[ -z "${E2E_ALL_HAIKU:-}" || -z "${E2E_HAIKU_MODEL:-}" ]]; then
    printf '%s' "$1"; return 0
  fi
  python3 -c '
import json, os, sys
b = json.loads(sys.argv[1])
b.setdefault("model", os.environ["E2E_HAIKU_MODEL"])
print(json.dumps(b, ensure_ascii=False))' "$1"
}
