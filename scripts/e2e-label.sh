#!/usr/bin/env bash
#
# e2e 하네스가 만들거나 트리거한 PR 에 'e2e' 라벨을 붙인다.
#
#   source "$(dirname "$0")/e2e-label.sh"
#   e2e_label_pr "$REPO" "$pr_url" [...]
#
# 왜 필요한가 — Agent-Test 의 open PR 목록에는 사람이 만든 PR 과 e2e 산출물
# (ko 변형 PR·번역 PR·align PR·fix-heading-syntax PR) 이 섞인다. 검증 실패로
# 일부러 open 으로 남기는 PR 도 있어서 목록만 봐서는 구분이 안 된다.
# 라벨이 붙으면 `gh pr list --label e2e` / GitHub UI 필터로 한 번에 걸러진다.
#
# 두 경로가 있다:
#   1) 하네스가 직접 만드는 PR — `gh pr create --label "$E2E_LABEL"` (라벨이
#      없으면 create 가 실패하므로 e2e_ensure_label 을 먼저 호출할 것)
#   2) Jenkins 잡이 만드는 PR (번역/align/fix-heading-syntax) — 하네스는 감지만
#      하므로 감지 직후 e2e_label_pr 로 사후 부여
#
# 라벨 부여는 어떤 경우에도 실행을 실패시키지 않는다 (라벨은 부가 정보일 뿐,
# 검증 결과가 아니다). 진단 출력은 전부 stderr — 호출부가 stdout 에서 PR URL
# 을 파싱하는 곳이 여러 군데라 stdout 을 오염시키면 안 된다.

E2E_LABEL="${E2E_LABEL:-e2e}"

e2e_ensure_label() {   # $1: owner/repo
  local repo="$1"
  if gh label list --repo "$repo" --search "$E2E_LABEL" --json name --jq '.[].name' 2>/dev/null \
     | grep -Fxq "$E2E_LABEL"; then
    return 0
  fi
  gh label create "$E2E_LABEL" --repo "$repo" --color "5319e7" \
    --description "e2e 하네스가 생성/트리거한 PR (사람이 만든 PR 이 아님)" >/dev/null 2>&1 || true
}

e2e_label_pr() {       # $1: owner/repo, $2.. : PR URL 또는 번호
  local repo="$1"; shift
  local pr labeled=0
  for pr in "$@"; do
    [[ -n "$pr" ]] || continue
    if (( ! labeled )); then e2e_ensure_label "$repo"; labeled=1; fi
    if gh pr edit "$pr" --repo "$repo" --add-label "$E2E_LABEL" >/dev/null 2>&1; then
      echo "  e2e 라벨 부여: $pr" >&2
    else
      echo "  (e2e 라벨 부여 실패 — 계속 진행: $pr)" >&2
    fi
  done
}
