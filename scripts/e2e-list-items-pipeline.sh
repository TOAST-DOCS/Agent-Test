#!/usr/bin/env bash
#
# 목록 항목 splice — **파이프라인** e2e. cloud-translate #924 의 `LIST_ITEMS` 가
# 실제 번역 잡(dashboard `/api/translate` → Jenkins, 또는 로컬 translate_pr.py)을
# 지나 산출물에 나타나는지 검증한다.
#
# `e2e-list-items.sh` 와의 관계: 그쪽은 모델을 태우지 않는 결정적 하네스로
# "무엇이 전송되는가" 만 본다 (마커 한 줄로 doc 경로에서 확장이 꺼지는 조건을
# 픽스처로 못 박은 것). 이 스크립트는 그 다음 층이다 — 배포된 경로로 실제
# 번역을 돌려 **산출물** 에서 판정한다. 둘은 서로를 대체하지 않는다.
#
# ── 검증 대상 ─────────────────────────────────────────────────────────────
# 불릿 하나를 고쳤을 때 **같은 목록의 형제 불릿이 바이트 그대로 남는다.**
# 사고: TOAST-DOCS/AppGuard#446 (en `Settings by Feature` → `Feature-Specific
# Settings`), TOAST-DOCS/TOAST-Cloud#415 (ja `認証方式の概要` → `認証方法の概要`).
# 두 표현이 픽스처 {ko,en,ja}/list-items-sample.md 의 「고정된 형제 불릿」 목록에
# 그대로 심겨 있다 — 노출되면 새 번역이 다른 표현을 낼 개연성이 높은 줄들이다.
#
# ── 왜 dashboard API 가 기본인가 ──────────────────────────────────────────
# 운영 프리셋(`toast-docs-presets` ConfigMap 의 recommended)에 `--list-items` 를
# 넣은 것이 2026-09-21 이다. 그런데 `/api/translate` 는 프리셋을 서버가 적용하지
# 않고 **클라이언트가 보낸 필드만** Jenkins 파라미터로 옮긴다
# (dashboard/api/jenkins.py `translate_params_from_opts`). 그래서 e2e 가 보내는
# 본문에 `"list_items": true` 가 있어야 하고, 응답의 `jenkins_params.LIST_ITEMS`
# 가 그 증거다 — 플래그가 켜졋다는 로그가 아니라 **Jenkins 가 받은 파라미터**로
# 확인한다. 이 스크립트의 본문은 운영 recommended 프리셋을 그대로 옮긴 것이다
# (max_load_ratio 4 · skip_full_table false · load_exclude_tables true).
#
# ── 흐름 ──────────────────────────────────────────────────────────────────
#   0) webhook 비활성화 (실제 PR 을 만들므로 중복 트리거 방지)
#   1) 세션 브랜치 e2e-listitems/<ts> ← origin/alpha. 픽스처 3벌·고정 줄 존재 확인
#   2) head 브랜치에서 ko/list-items-sample.md 의 **마지막 불릿 하나**만 변경 → ko PR
#   3) 번역 — api: POST /api/translate (recommended + list_items) / local: translate_pr.py --list-items
#   4) 번역 PR 감지 (head 접두 translate/<ko head>)
#   5) **대조군** — 같은 ko 편집을 LIST_ITEMS 없이 한 번 더 (`--no-control` 로 생략)
#   6) 판정 (아래) → 7) 대조군 대비 보존 → 8) 결과. 종료 시 정리 (--keep 이면 보존)
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   (1) [api] 응답 jenkins_params.LIST_ITEMS == "true"        ← 플래그가 잡까지 갔다
#   (2) en 고정 불릿 5줄 바이트 동일                              ← 본체
#   (3) ja 고정 불릿 5줄 바이트 동일                              ← 본체
#   (4) 편집한 불릿(릴리스 노트)은 en/ja 에서 실제로 바뀌었고 링크·마커 유지
#   (5) 목록이 끊기지 않았다 — 6줄이 빈 줄 없이 연속 (_append_list_unit)
#   (6) 고정 목록 블록 안에서 바뀐 줄은 편집한 불릿 하나뿐 (블록 밖 변경은 WARN)
#   (7) **대조군(LIST_ITEMS off)보다 고정 불릿 보존이 많거나 같다**  ← 플래그 기여
#
# ── 왜 대조군이 필요한가 ──────────────────────────────────────────────────
# (2)(3) 만으로는 "바이트 동일" 이 플래그 덕인지 그날 모델이 우연히 같은 표현을
# 낸 것인지 구분할 수 없다. 실제 사고에서도 **en 만 갈리고 ja 는 우연히 같은
# 표현을 냈다** (AppGuard#446) — 즉 노출된 불릿이 매번 다시 쓰이는 것은 아니다.
# 그래서 같은 ko 편집을 `list_items` 없이 한 번 더 돌려 보존 개수를 나란히 잰다
# (`e2e-unit-preserve.sh` 의 (7) 과 같은 설계). 대조군이 더 많이 보존했다면 그
# 실행에서는 플래그가 아무 일도 하지 않은 것이므로 FAIL 이다. 같은 수면 PASS —
# 노출이 곧 재작성은 아니므로 대조군이 운 좋게 살아남는 것은 정상이다.
# `--no-control` 로 끄면 (7) 은 WARN 으로 건너뛴다 (번역 잡 하나를 아낀다).
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (마지막 줄 `LIST_ITEMS: OK`)
#   1  규칙 실패 (`LIST_ITEMS: FAIL`, 브랜치 보존)
#   2  인프라 — 번역 PR 미감지·API 오류
#
# Usage:
#   bash scripts/e2e-list-items-pipeline.sh                    # --translate api (기본)
#   bash scripts/e2e-list-items-pipeline.sh --translate local  # 로컬 translate_pr.py --list-items
#   bash scripts/e2e-list-items-pipeline.sh --no-control       # 대조군 없이 (잡 1개)
#   bash scripts/e2e-list-items-pipeline.sh --keep --timeout 2400
#
#   # cloud-translate 의 특정 Jenkins 자식 잡(미머지 PR)으로 돌린다
#   bash scripts/e2e-list-items-pipeline.sh --pipeline-branch PR-997
#
# `--pipeline-branch <자식 잡>` — `/api/translate` 본문의 `pipeline_branch` 로
# 넘어가 dashboard 가 multibranch **자식 잡** `…/job/translate/job/<이름>/` 을
# 빌드한다 (`dashboard/api/jenkins.py` `multibranch_job_url`). 안 주면
# `JENKINS_JOB_DEFAULT_BRANCH`(=`main`) 이므로 **머지된 코드만** 검증된다 —
# 미머지 개선을 배포 경로로 확인하려면 그 PR 의 자식 잡 이름(`PR-<번호>`)을 준다.
# 자식 잡은 한 번도 안 빌드됐으면 파라미터가 등록돼 있지 않아 `buildWithParameters`
# 가 400 이다. 빈 `/build` 한 번으로 등록한 뒤 쓴다 (dashboard-api.md 참고).
#
# 의존성: git, gh(로그인), python3. api 모드는 load_env.sh 의 DASHBOARD_BASE_URL /
# DASHBOARD_API_TOKEN. local 모드는 $CLOUD_TRANSLATE_DIR/.env 와 claude CLI 인증.
# JENKINS_USER/JENKINS_TOKEN 이 있으면 (선택) 콘솔에서 splice 로그를 덧붙여 보여 준다.
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-listitems/$TS"
HEAD_BRANCH="translate-test-listitems/$TS"
CTRL_BRANCH="translate-test-listitems-ctl/$TS"
DOC="list-items-sample.md"
TRANSLATE_MODE="api"
KEEP=0
CONTROL=1
PIPELINE_BRANCH=""
PR_TIMEOUT=1800

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --translate) TRANSLATE_MODE="$2"; shift 2 ;;
    --keep)      KEEP=1; shift ;;
    --no-control) CONTROL=0; shift ;;
    --pipeline-branch) PIPELINE_BRANCH="$2"; shift 2 ;;
    --timeout)   PR_TIMEOUT="$2"; shift 2 ;;
    --doc)       DOC="$2"; shift 2 ;;
    -h|--help)   sed -n '2,80p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
case "$TRANSLATE_MODE" in api|local) ;; *) echo "error: --translate 는 api|local" >&2; exit 1 ;; esac
if [[ "$TRANSLATE_MODE" == "api" && ( -z "${DASHBOARD_BASE_URL:-}" || -z "${DASHBOARD_API_TOKEN:-}" ) ]]; then
  echo "error: --translate api 는 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필요합니다 (source ./load_env.sh)." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"; LOG="$tmpdir/translate.log"

ko_pr_url=""; tx_pr_url=""; ctl_pr_url=""; tx_ctl_url=""
cleanup() {
  local rc=$?
  local wt
  for wt in "$tmpdir/tx" "$tmpdir/txctl"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( KEEP )); then echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${ko_pr_url:-없음}, 번역 PR: ${tx_pr_url:-없음}, 대조군: ${tx_ctl_url:-없음})"; return $rc; fi
  echo; echo "[cleanup] PR 닫기 · 브랜치 정리"
  local u
  for u in "$tx_pr_url" "$tx_ctl_url"; do
    [[ -n "$u" ]] && gh pr close "$u" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  done
  for u in "$ko_pr_url" "$ctl_pr_url"; do
    [[ -n "$u" ]] && gh pr close "$u" --repo "$REPO" >/dev/null 2>&1 || true
  done
  local b prefix
  for prefix in "translate/$HEAD_BRANCH" "translate/$CTRL_BRANCH"; do
    while read -r b; do
      [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
    done < <(git ls-remote --heads origin "refs/heads/${prefix}*" 2>/dev/null | sed 's|.*refs/heads/||')
  done
  git push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$CTRL_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

# 픽스처가 못 박은 줄 (e2e-list-items.sh 와 같은 편집·같은 고정 표현)
EDIT_FROM="* [릴리스 노트](./release-notes/)"
EDIT_TO="* [릴리스 노트 및 변경 이력](./release-notes/)"
PINNED_EN=(
  "* [Authentication Overview](./auth-method-overview/)"
  "* [Supported Authentication Methods](./supported-authentication-methods/)"
  "* [Settings by Feature](./feature-settings/)"
  "    * [DEX Encryption Target Specification](./dex-encryption/)"
  "* [Service API](./service-api/)"
)
PINNED_JA=(
  "* [認証方式の概要](./auth-method-overview/)"
  "* [認証方式サポート状況](./supported-authentication-methods/)"
  "* [機能別設定](./feature-settings/)"
  "    * [DEX暗号化対象の指定](./dex-encryption/)"
  "* [サービスAPI](./service-api/)"
)
TARGET_EN="* [Release Notes](./release-notes/)"
TARGET_JA="* [リリースノート](./release-notes/)"

echo "=== 목록 항목 splice — 파이프라인 e2e ==="
echo "  mode    : --translate $TRANSLATE_MODE (대조군 $( ((CONTROL)) && echo 포함 || echo 제외 ))"
echo "  잡 브랜치: ${PIPELINE_BRANCH:-<dashboard 기본 = main>}"
echo "  session : $SESSION_BRANCH"
echo "  doc     : $DOC"
echo

source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0/8] webhook 비활성화"
set_webhook_repo_enabled false

echo "[1/8] 세션 브랜치 생성 + 픽스처 확인"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"
for lang in ko en ja; do
  [[ -f "$lang/$DOC" ]] || { echo "error: $lang/$DOC 없음 — 픽스처가 alpha 에 없다" >&2; exit 1; }
done
grep -qxF -- "$EDIT_FROM" "ko/$DOC" || { echo "error: ko 변경 대상 불릿을 찾지 못함: $EDIT_FROM" >&2; exit 1; }
for l in "${PINNED_EN[@]}" "$TARGET_EN"; do grep -qxF -- "$l" "en/$DOC" || { echo "error: en 고정 줄 없음: $l" >&2; exit 1; }; done
for l in "${PINNED_JA[@]}" "$TARGET_JA"; do grep -qxF -- "$l" "ja/$DOC" || { echo "error: ja 고정 줄 없음: $l" >&2; exit 1; }; done
git push -q origin "$SESSION_BRANCH"
echo "  픽스처 3벌 · 고정 줄 en 6 / ja 6 확인"

echo "[2/8] ko 변경 — 마지막 불릿 하나"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" "$EDIT_FROM" "$EDIT_TO" <<'PY'
import io, sys
path, old, new = sys.argv[1:4]
raw = io.open(path, encoding="utf-8", newline="").read()
assert raw.count(old) == 1, f"변경 대상이 정확히 1회여야 함: {raw.count(old)}"
io.open(path, "w", encoding="utf-8", newline="").write(raw.replace(old, new))
PY
git add -- "ko/$DOC"
committed="$(git diff --cached --name-only)"
[[ "$committed" == "ko/$DOC" ]] || { echo "error: 예상 외 파일 스테이지됨: $committed" >&2; exit 1; }
git commit -q -m "e2e(list-items): 고정 목록의 마지막 불릿 하나만 변경 ($TS)"
git push -q origin "$HEAD_BRANCH"
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(list-items): 불릿 하나 변경 — 형제 불릿은 그대로여야 한다 ($TS)" \
  --body "cloud-translate LIST_ITEMS 파이프라인 검증 — ko 가 건드리지 않은 형제 불릿(en \`Settings by Feature\` · ja \`認証方式の概要\`)이 번역 PR 에서 바이트 그대로 남는지." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

fails=0
ok()  { echo "  PASS  $1"; }
bad() { echo "  FAIL  $1"; fails=$((fails + 1)); }
warn(){ echo "  WARN  $1"; }

# `/api/translate` 는 프리셋을 서버에서 적용하지 않고 **클라이언트가 보낸 필드만**
# Jenkins 파라미터로 옮긴다 (dashboard/api/jenkins.py `translate_params_from_opts`).
# 그래서 본문은 운영 recommended 프리셋을 그대로 옮긴 것이어야 하고, 플래그가
# 실제로 잡에 갔는지는 응답의 `jenkins_params.LIST_ITEMS` 로만 확인할 수 있다.
# `pipeline_branch` 는 값이 있을 때만 넣는다 — 빈 문자열로 넘기면 dashboard 가
# 기본 브랜치로 폴백하지만, 키를 생략해 "지정 안 함" 이 파라미터에도 드러나게 한다.
api_translate() {   # $1=PR URL  $2=true|false (list_items)  → stdout: LIST_ITEMS 파라미터 값
  local pr="$1" li="$2" body resp pb=""
  [[ -n "$PIPELINE_BRANCH" ]] && pb="  \"pipeline_branch\": \"$PIPELINE_BRANCH\","
  body="$(cat <<JSON
{
  "pr_url": "$pr",
  "base_branch": "$SESSION_BRANCH",
$pb
  "diff_granularity": "block",
  "glossary_mode": "service",
  "max_load_ratio": "4",
  "table_rows": true,
  "skip_full_table": false,
  "skip_anchor_only": true,
  "assign_anchors": true,
  "align_headings": true,
  "load_exclude_tables": true,
  "list_items": $li
}
JSON
)"
  resp="$(curl -sS -X POST -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    -H "Content-Type: application/json" -d "$body" "$DASHBOARD_BASE_URL/api/translate")"
  echo "$resp" | python3 -m json.tool 2>/dev/null | sed 's/^/    /' | head -30 >&2
  printf '%s' "$resp" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("queued") else 1)' 2>/dev/null \
    || { echo "error: /api/translate 가 큐에 넣지 못함" >&2; return 2; }
  # list_items=false 는 Jenkins 파라미터를 아예 안 보낸다 (기본 false) — 그래서
  # 대조군의 기대값은 "true 가 아님" 이고, 빈 문자열이 정상이다.
  printf '%s' "$resp" | python3 -c 'import json,sys; d=json.load(sys.stdin); print((d.get("jenkins_params") or {}).get("LIST_ITEMS",""))' 2>/dev/null || true
}

run_translate_local() {   # $1=로그 $2=PR URL $3...=추가 플래그
  local log="$1" pr="$2"; shift 2
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_TRANSLATE_ENGINE=claude-code \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5 \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$pr" \
      --base-branch "$SESSION_BRANCH" \
      --diff-granularity block --glossary-mode service --max-load-ratio 4 \
      --workers 2 --chunk-workers 2 --tm-top-k 1 \
      --table-rows --no-skip-full-table --skip-anchor-only \
      --assign-anchors --align-headings --load-exclude-tables \
      "$@" \
  ) 2>&1 | tee "$log"
  local rc=${PIPESTATUS[0]}
  set -e
  return $rc
}

# 번역 PR 은 **head 접두**로 찾는다 — `--base-branch <세션>` 을 넘기면 번역 PR 의
# base 는 ko head 가 아니라 세션 브랜치라, base 로 거르면 영영 못 찾는다. 번역기는
# `translate/<ko head>-<sha>-<ts>` 로 연다.
poll_tx_pr() {   # $1=ko head 브랜치 → stdout: 번역 PR URL (없으면 빈 문자열)
  local head="$1" left=$(( PR_TIMEOUT / 20 )) url=""
  while (( left-- > 0 )); do
    url="$(gh pr list --repo "$REPO" --state open --limit 50 --json url,headRefName \
      --jq ".[] | select(.headRefName | startswith(\"translate/$head\")) | .url" | sort -u | head -n1 || true)"
    [[ -n "$url" ]] && break
    sleep 20
  done
  printf '%s' "$url"
}

echo "[3/8] 번역 실행 ($TRANSLATE_MODE${PIPELINE_BRANCH:+, pipeline_branch=$PIPELINE_BRANCH})"
if [[ "$TRANSLATE_MODE" == "api" ]]; then
  li_param="$(api_translate "$ko_pr_url" true)" \
    || { echo "error: 큐 실패" >&2; KEEP=1; exit 2; }
else
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
  set +e
  run_translate_local "$LOG" "$ko_pr_url" --list-items
  tx_rc=$?
  set -e
  (( tx_rc == 0 )) || { echo "error: translate_pr.py 실패 (exit $tx_rc)" >&2; exit 2; }
  li_param="local"
fi

echo "[4/8] 번역 PR 감지 (최대 ${PR_TIMEOUT}s)"
tx_pr_url="$(poll_tx_pr "$HEAD_BRANCH")"
[[ -n "$tx_pr_url" ]] || { echo "error: ${PR_TIMEOUT}s 내 번역 PR 미감지 — 브랜치·PR 은 보존한다 (조사용)" >&2; KEEP=1; exit 2; }
echo "  detected translation PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url" || true

# ── 대조군 — 같은 ko 편집을 LIST_ITEMS 없이 ───────────────────────────────
echo "[5/8] 대조군 (LIST_ITEMS off)"
ctl_wt=""
if (( CONTROL )); then
  git checkout -q -B "$CTRL_BRANCH" "$SESSION_BRANCH"
  git checkout -q "$HEAD_BRANCH" -- "ko/$DOC"
  git commit -q -m "e2e(list-items): 대조군 — 같은 ko 편집, 플래그 없이 ($TS)"
  git push -q origin "$CTRL_BRANCH"
  ctl_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$CTRL_BRANCH" \
    --title "e2e(list-items): 대조군 — LIST_ITEMS 없이 ($TS)" \
    --body "LIST_ITEMS 대조군 — 같은 불릿 하나 편집을 플래그 없이 번역한다. 형제 불릿 보존 개수를 ON arm 과 나란히 잰다." \
    --label "$E2E_LABEL")"
  echo "  대조군 ko PR: $ctl_pr_url"
  ctl_li=""
  if [[ "$TRANSLATE_MODE" == "api" ]]; then
    ctl_li="$(api_translate "$ctl_pr_url" false)" || warn "대조군 큐 실패"
    echo "  대조군 jenkins_params.LIST_ITEMS='$ctl_li' (기대: 빈 문자열)"
  else
    run_translate_local "$tmpdir/control.log" "$ctl_pr_url" || warn "대조군 translate_pr.py 실패"
  fi
  tx_ctl_url="$(poll_tx_pr "$CTRL_BRANCH")"
  if [[ -n "$tx_ctl_url" ]]; then
    echo "  대조군 번역 PR: $tx_ctl_url"
    e2e_label_pr "$REPO" "$tx_ctl_url" || true
    ctl_head="$(gh pr view "$tx_ctl_url" --repo "$REPO" --json headRefName --jq .headRefName)"
    git fetch -q origin "$ctl_head"
    git worktree add -q --detach "$tmpdir/txctl" "origin/$ctl_head"
    ctl_wt="$tmpdir/txctl"
  else
    warn "대조군 번역 PR 미감지 — (7) 은 건너뛴다"
  fi
else
  echo "  --no-control: 건너뜀"
fi

echo "[6/8] 판정"
if [[ "$TRANSLATE_MODE" == "api" ]]; then
  if [[ "$li_param" == "true" ]]; then ok "(1) /api/translate → Jenkins 파라미터 LIST_ITEMS=true"
  else bad "(1) jenkins_params.LIST_ITEMS='$li_param' — 플래그가 잡에 가지 않았다"; fi
else
  ok "(1) local: --list-items 명시 전달"
fi

tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head" "$SESSION_BRANCH"
tx_wt="$tmpdir/tx"; git worktree add -q "$tx_wt" "origin/$tx_head"

verdict_json="$(python3 - "$tx_wt" "$SESSION_BRANCH" "$DOC" "$TARGET_EN" "$TARGET_JA" "${#PINNED_EN[@]}" "${PINNED_EN[@]}" "${PINNED_JA[@]}" <<'PY'
import io, json, subprocess, sys, difflib
wt, session, doc, target_en, target_ja, n = sys.argv[1:7]
n = int(n); pinned = {"en": sys.argv[7:7+n], "ja": sys.argv[7+n:7+2*n]}
target = {"en": target_en, "ja": target_ja}
out = {}
for lang in ("en", "ja"):
    base = subprocess.run(["git", "show", f"origin/{session}:{lang}/{doc}"],
                          capture_output=True, text=True, check=True).stdout
    new = io.open(f"{wt}/{lang}/{doc}", encoding="utf-8", newline="").read()
    b_lines, n_lines = base.split("\n"), new.split("\n")
    r = {}
    # (2)(3) 고정 줄 바이트 동일 — 정확히 한 번씩 그대로 존재
    r["pinned_missing"] = [p for p in pinned[lang] if n_lines.count(p) != 1]
    # (4) 편집한 불릿: 옛 줄은 사라지고, 같은 링크를 가진 새 불릿이 한 줄 있다
    cand = [l for l in n_lines if l.startswith("* [") and l.rstrip().endswith("](./release-notes/)")]
    r["target_old_present"] = target[lang] in n_lines
    r["target_new"] = cand[0] if len(cand) == 1 else None
    r["target_count"] = len(cand)
    # (5) 목록 연속: 첫 고정 줄부터 6줄이 전부 목록 줄 (빈 줄 없음)
    try:
        i = n_lines.index(pinned[lang][0])
        block = n_lines[i:i+6]
        r["contiguous"] = all(l.startswith(("* ", "    * ")) for l in block) and len(block) == 6
        r["block"] = block
    except ValueError:
        r["contiguous"] = False; r["block"] = []
    # (6) 변경 범위: 고정 목록 블록(base 기준 6줄) 안에서 바뀐 줄
    try:
        bi = b_lines.index(pinned[lang][0]); bblock = set(b_lines[bi:bi+6])
    except ValueError:
        bblock = set()
    changed = [l for l in difflib.unified_diff(b_lines, n_lines, lineterm="", n=0)
               if l[:1] in "+-" and not l.startswith(("+++", "---"))]
    r["changed_in_block"] = [l for l in changed if l[1:] in bblock or l[1:] in set(r["block"])]
    r["changed_outside"] = [l for l in changed if l not in r["changed_in_block"]]
    out[lang] = r
print(json.dumps(out, ensure_ascii=False))
PY
)"
printf '%s' "$verdict_json" > "$tmpdir/verdict.json"

judge() {  # $1=lang
  local lang="$1"
  python3 - "$lang" "$tmpdir/verdict.json" <<'PY'
import json, sys
lang, path = sys.argv[1:3]
r = json.load(open(path))[lang]
rule_no = {"en": ("2", "en"), "ja": ("3", "ja")}[lang]
def ok(m): print(f"  PASS  {m}")
def bad(m): print(f"  FAIL  {m}"); print("__FAIL__")
def warn(m): print(f"  WARN  {m}")
if r["pinned_missing"]: bad(f"({rule_no[0]}) {lang} 고정 불릿이 바뀌었거나 사라짐: {r['pinned_missing']}")
else: ok(f"({rule_no[0]}) {lang} 고정 불릿 5줄 바이트 동일")
if r["target_new"] and not r["target_old_present"] and r["target_new"].startswith("* ["):
    ok(f"(4) {lang} 편집한 불릿만 새 번역: {r['target_new']}")
else:
    bad(f"(4) {lang} 편집한 불릿 판정 실패 — old_present={r['target_old_present']} candidates={r['target_count']}")
if r["contiguous"]: ok(f"(5) {lang} 목록 6줄 연속 (빈 줄로 갈리지 않음)")
else: bad(f"(5) {lang} 목록이 끊겼다: {r['block']}")
extra = [l for l in r["changed_in_block"] if "release-notes" not in l]
if extra: bad(f"(6) {lang} 고정 블록 안에서 편집 대상 외 줄이 바뀜: {extra}")
else: ok(f"(6) {lang} 고정 블록 안 변경은 편집한 불릿 하나뿐")
if r["changed_outside"]: warn(f"{lang} 블록 밖 변경 {len(r['changed_outside'])}줄 (참고): {r['changed_outside'][:4]}")
PY
}
for lang in en ja; do
  jout="$(judge "$lang")"
  printf '%s\n' "$jout" | grep -v '^__FAIL__$'
  fails=$(( fails + $(printf '%s\n' "$jout" | grep -c '^__FAIL__$' || true) ))
done

# ── (7) 대조군 대비 — "바이트 동일" 이 플래그 덕인지 모델 운인지 가른다 ─────
echo
echo "[7/8] 대조군 대비 — 고정 불릿 보존"
if [[ -n "$ctl_wt" ]]; then
  keep_counts="$(python3 - "$tx_wt" "$ctl_wt" "$DOC" "${#PINNED_EN[@]}" "${PINNED_EN[@]}" "${PINNED_JA[@]}" <<'KEEPPY'
import io, os, sys
on_wt, ctl_wt, doc, n = sys.argv[1:5]
n = int(n)
pinned = {"en": sys.argv[5:5 + n], "ja": sys.argv[5 + n:5 + 2 * n]}


def kept(root, lang):
    """고정 불릿 중 **정확히 한 번** 그대로 남은 줄 수 (없는 파일은 0)."""
    try:
        lines = io.open(os.path.join(root, lang, doc),
                        encoding="utf-8", newline="").read().split("\n")
    except OSError:
        return 0
    return sum(1 for l in pinned[lang] if lines.count(l) == 1)


vals = {tag: {lang: kept(root, lang) for lang in ("en", "ja")}
        for tag, root in (("on", on_wt), ("ctl", ctl_wt))}
tot = {tag: sum(v.values()) for tag, v in vals.items()}
print(tot["on"], tot["ctl"], n * 2,
      "en %d/%d ja %d/%d" % (vals["on"]["en"], vals["ctl"]["en"],
                             vals["on"]["ja"], vals["ctl"]["ja"]))
KEEPPY
)"
  read -r n_on n_ctl n_tot detail <<<"$keep_counts"
  echo "  보존 — ON $n_on/$n_tot · 대조군 $n_ctl/$n_tot  (on/off 쌍: $detail)"
  if (( n_on >= n_ctl )); then
    if (( n_ctl < n_tot )); then
      ok "(7) 대조군이 $(( n_tot - n_ctl ))줄을 잃었고 ON 은 $(( n_tot - n_on ))줄 — 플래그가 실제로 일한다"
    else
      ok "(7) 양쪽 다 보존 ($n_on/$n_tot) — 노출이 곧 재작성은 아니므로 정상. 전송 여부는 e2e-list-items.sh 가 결정적으로 본다"
    fi
  else
    bad "(7) 대조군이 더 많이 보존했다 (off $n_ctl/$n_tot > on $n_on/$n_tot) — 이 실행에서 플래그가 한 일이 없다"
  fi
else
  warn "(7) 대조군 없음 — 건너뜀 (--no-control 또는 대조군 PR 미감지)"
fi

# (선택) Jenkins 콘솔의 splice 로그 — 증거 보강용, 판정에는 안 쓴다
if [[ -n "${JENKINS_USER:-}" && -n "${JENKINS_TOKEN:-}" ]]; then
  burl="$(gh pr view "$tx_pr_url" --repo "$REPO" --json body --jq .body 2>/dev/null \
          | grep -oE 'https?://[^ )*]*/job/[^ )*]*/[0-9]+/' | tail -n1 || true)"
  if [[ -n "$burl" ]]; then
    echo "  Jenkins: $burl"
    curl -sS --max-time 120 -u "$JENKINS_USER:$JENKINS_TOKEN" "${burl}consoleText" 2>/dev/null \
      | grep -E "Section-diff|anchor splice|LIST_ITEMS|list-items" | sed 's/^/    /' | head -12 || true
  fi
fi

echo
echo "[8/8] 결과"
if (( fails == 0 )); then
  echo "  PASS — 형제 불릿은 바이트 그대로, 편집한 불릿만 새로 번역됐다"
  echo "         번역 PR: $tx_pr_url${tx_ctl_url:+  · 대조군: $tx_ctl_url}"
  echo "LIST_ITEMS: OK"
  exit 0
fi
echo "  FAIL — $fails 개 규칙 실패"
echo "         번역 PR: $tx_pr_url${tx_ctl_url:+  · 대조군: $tx_ctl_url}"
echo "LIST_ITEMS: FAIL"
KEEP=1
exit 1
