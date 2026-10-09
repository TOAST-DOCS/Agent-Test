# e2e 대상 리포 — 이 체크아웃의 origin (공용 helper; `source` 해서 쓴다).
#
# 같은 e2e 스크립트를 github.com 의 TOAST-DOCS/Agent-Test 와 사내 GHE 사본
# cloud-docs/Internal-Agent-Test 에서 그대로 돌린다 (cloud-user-guide-agent/518).
# 정하는 전역:
#   REPO       github.com 이면 `owner/name` (예전 그대로), 그 밖이면 `host/owner/name`
#              — gh 는 `--repo HOST/OWNER/REPO` 를 받고 대시보드는 어느 표기든 그 사본으로 푼다
#   REPO_HOST  github.com / github.nhnent.com
#   REPO_WEB   https://<host>/<owner>/<name> — 대시보드 API 의 target 등 URL 로 넘길 때
# origin 을 못 읽으면 기본 리포로 떨어지지 않고 멈춘다 — 엉뚱한 리포에 PR 을 열게 된다.
_e2e_origin="$(git -C "${E2E_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}" remote get-url origin 2>/dev/null || true)"
_e2e_origin="${_e2e_origin%.git}"
if [[ "$_e2e_origin" =~ ^(https?://|git@)([^/:]+)[/:]([^/]+)/([^/]+)$ ]]; then
  REPO_HOST="${BASH_REMATCH[2]##*@}"
  _e2e_full="${BASH_REMATCH[3]}/${BASH_REMATCH[4]}"
  REPO_WEB="https://$REPO_HOST/$_e2e_full"
  if [[ "$REPO_HOST" == "github.com" ]]; then REPO="$_e2e_full"; else REPO="$REPO_HOST/$_e2e_full"; fi
else
  echo "error: origin URL 에서 리포를 알 수 없습니다: '${_e2e_origin}'" >&2
  exit 1
fi
unset _e2e_origin _e2e_full
