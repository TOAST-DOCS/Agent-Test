#!/usr/bin/env bash
#
# End-to-end 재현 스크립트 (Agent-Test alpha) — public-api.md 전체 재번역 변형:
#   scripts/e2e-align-and-translate.sh 흐름에 dashboard /api/translate/file
#   을 통한 public-api.md 전체 재번역(DIFF_MODE=full) 을 추가한 변형. 재번역
#   결과는 alpha 에 직접 커밋하지 않고 **align PR 의 head 브랜치에 append**
#   되도록 pr_number 를 사용 → align + 재번역이 한 PR 로 리뷰됨.
#
#   재번역 비용을 줄이기 위해 public-api.md 를 **런타임에** 공통 anchor 에서
#   잘라낸다 (`--cut-anchor`, 기본 `list-instances-with-details`). 세 언어를 같은
#   anchor 에서 자르므로 heading/anchor 정렬이 보존된다 — 그래서 이미 align 된
#   스냅샷(--from-aligned) 위에서도 안전하다. 기본 앵커 기준 ko 47,822 -> 14,262자
#   (29%), 표 17개·코드펜스 16개가 남아 전체 재번역 경로(2 chunk 이상)를 그대로
#   태운다.
#   이전에는 체크인된 `archive/alpha-origin-40pct/` 를 덮어썼는데, 이름과 달리
#   원본의 **81%** 를 남기는 파일이었고 (create-instance 앵커에서 절단) 아카이브가
#   갱신되면 조용히 더 커질 수 있었다. 그 의존을 없앴다.
#
#   1. alpha 브랜치로 switch
#   2. scripts/restore-alpha-origin.sh 실행 (내부에서 commit+push)
#      + public-api.md 40% 축소본 덮어쓰기 → commit+push
#   3. fix-heading-syntax (heading 문법 정정, base=alpha) — dashboard API 또는
#      local fix_fence.py + fix_heading_syntax.py
#   4. fix-heading-syntax 잡이 생성하는 PR 감지 → merge → alpha 최신화
#   5. align (= fix_headings, 권장 preset, base=alpha) — dashboard API 또는
#      local fix_headings.py
#   6. Jenkins align 잡이 새로 만든 PR 을 gh 로 감지 (base=alpha)
#   7. dashboard /api/translate/file 호출 (ko/public-api.md 전체 재번역,
#      pr_number=<align PR>) → 재번역 커밋이 align PR head 브랜치에 append,
#      job status 가 success 될 때까지 대기 후 로컬 head_ref 최신화
#   8. claude CLI(fable model)로 align PR 브랜치(재번역 포함)의
#      ko/en/ja heading·anchor-id 정렬 검사
#   9. 검증 통과 시 align PR 을 alpha 로 merge (실패 시 PR 은 open 으로 남김)
#  10. scripts/create-translate-test-pr.sh 실행 (ko 변형 → translate-test PR 생성)
#  11. ko 변경 PR 생성 확인
#  12. ko 변경 PR 대상으로 dashboard /api/translate 호출 (권장 preset)
#  13. translate 잡이 생성하는 번역 PR(base=ko PR head 브랜치) 감지 대기
#  14. claude CLI(fable)로 번역 PR 검증 (heading·id·표 행 수) → 결과를 PR 댓글로 등록
#
# 상단 두 변수(DASHBOARD_BASE_URL, DASHBOARD_API_TOKEN)를 채우고 실행.
# 아니면 같은 이름의 환경변수를 export 해도 됩니다.
#
# Usage:
#   scripts/e2e-retranslate-align-and-translate.sh [--engine api|cli] [--model haiku|sonnet|opus]
#                                                  [--tm-top-k N] [--chunk-workers N]
#                                                  [--guidelines-variant-en aws|unified|unified-v2|default]
#                                                  [--guidelines-variant-ja aws|unified|default]
#                                                  [--align-v2|--no-align-v2]
#
#   --engine api   translate 잡을 api 엔진으로 실행
#   --engine cli   translate 잡을 claude-code(CLI) 엔진으로 실행 (기본값)
#   (default 지정 시 engine 필드를 보내지 않음 → 서버 default)
#
#   --model haiku  claude-haiku-4-5 사용 (기본값)
#   --model sonnet claude-sonnet-4-6 사용
#   --model opus   claude-opus-4-8 사용
#
#   --tm-top-k N          TM few-shot 개수 (기본값 1). "default" 시 필드 미전송 (잡 .env default = 10)
#   --chunk-workers N     chunk 병렬도 (기본값 2, PR#192/#199).
#   --guidelines-variant-en <v>  en 가이드라인 크기 (aws|unified|unified-v2|default, PR#199)
#   --guidelines-variant-ja <v>  ja 가이드라인 크기 (aws|unified|default, PR#199)
#   --verify py|fable            8·14 단계 구조 검증 방식. py(기본) =
#                                scripts/check_docs_align.py (결정적·<1초),
#                                fable = 예전 claude -p agentic 검증.
#   --translate api|local        실행 방식. api(기본) = 배포된 dashboard/Jenkins
#                                (/api/fix-heading-syntax, /api/align,
#                                /api/translate/file, /api/translate). local =
#                                **네 단계 전부** $CLOUD_TRANSLATE_DIR 의 스크립트를
#                                직접 실행:
#                                  3단계 → pre-align/fix_fence.py + fix_heading_syntax.py
#                                  5단계 → pre-align/fix_headings.py
#                                  7단계 → translate/translate_file.py
#                                          (--commit-to-branch <align PR head>,
#                                           TRANSLATE_DIFF_MODE=full)
#                                  12단계 → translate/translate_pr.py
#                                local 모드의 7·12단계는 **engine=api 로 고정**된다 —
#                                그 모드에서는 dashboard 라우트를 타지 않으므로 CLI
#                                엔진의 라우트 커버리지가 0 이고, CLI 는 로컬 claude
#                                OAuth 한도(세션·fable 검증과 공유)를 써서 자주
#                                429 로 죽는다. 모델은 --model 값을 두 env
#                                (ANTHROPIC_MODEL / CLAUDE_CODE_MODEL) 로 함께 넘긴다.
#                                --engine 은 api 모드(배포 경로)에만 적용된다.
#                                local 에서도 0단계 webhook 킬 스위치는 dashboard 를
#                                호출하므로 DASHBOARD_BASE_URL/_TOKEN 은 여전히 필수.
#
#   --cut-anchor <id>            public-api.md 를 자를 공통 anchor id
#                                (기본 list-instances-with-details). ko/en/ja 모두에
#                                있어야 하며, 없으면 하드 실패한다 — 조용히 축소를
#                                건너뛰면 재번역 비용이 몇 배로 튀는데 로그만
#                                보고는 알 수 없다.
#
#   --from-aligned <branch>      이미 align 이 끝난 스냅샷에서 세션을 갈라내고
#                                2~9단계(restore·fix-heading-syntax·align·검증·
#                                merge)를 건너뛴다. 그 단계들은 픽스처가 고정이라
#                                plan 마다 같은 결과가 나오고, e2e-suite.sh 는 첫
#                                align 기반 plan 에서 한 번만 돌린다 — 이 plan 만
#                                재사용에서 빠져 있어 `all` 한 번에 align 프롤로그가
#                                **두 번** 돌았다 (Opus heading 분류 10+12회).
#                                이 모드에서는 align PR 이 없으므로 재번역 결과가
#                                세션 브랜치에 직접 커밋되고 (api 모드는 pr_number
#                                대신 branch 를 넘긴다) 9단계 merge 도 생략된다.
#
#   --align-v2 / --no-align-v2   PR#218 v2 모드 (기본 --align-v2)
#
# 의존성: git, gh (로그인), curl, python3, claude (Claude Code CLI)

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"   # 예: https://docs.internal.nhncloud.com
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}" # 대시보드 관리자에게서 발급받은 값

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH=""                                # 미지정 시 e2e-retranslate/<timestamp> 자동 생성 (alpha 미오염)
BASE_SOURCE_BRANCH="alpha"                    # 새 세션 브랜치를 갈라낼 원본
TARGET_URL="https://github.com/${REPO}"
RETRANSLATE_PATH="public-api.md"   # {source}/ 기준 상대경로
RETRANSLATE_SOURCE="ko"
# ─────────────────────────────────────────────────────────────────────

# ── 실행 옵션 ─────────────────────────────────────────────────────────
TRANSLATE_ENGINE="claude-code"            # 기본값 cli — api/default 로 override 가능
TRANSLATE_MODEL="claude-haiku-4-5"        # 기본값 haiku — sonnet/opus/default 로 override 가능
TRANSLATE_TM_TOP_K="1"                    # TM few-shot 개수 기본값 1
TRANSLATE_CHUNK_WORKERS="2"               # chunk 병렬도 (PR#192/#199)
TRANSLATE_GUIDELINES_VARIANT_EN=""        # 기본값 default (잡 .env: unified-v2)
TRANSLATE_GUIDELINES_VARIANT_JA=""        # 기본값 default (잡 .env: unified)
VERIFY_MODE="py"                          # py = check_docs_align.py (기본) | fable = 예전 claude -p 검증
# api = 배포된 dashboard/Jenkins 잡 (기본) | local = $CLOUD_TRANSLATE_DIR 의
# 스크립트를 직접 실행 (fix-heading-syntax / align / translate-file / translate
# 네 단계 전부). 미배포 브랜치를 배포 없이 검증할 때.
# public-api.md 를 자를 공통 anchor id. ko/en/ja 모두에 존재해야 한다.
# 기본값 list-instances-with-details = ko 문자수의 ~29% 를 남긴다 (표 17개,
# 코드펜스 16개, 2 chunk 이상 → 전체 재번역 경로를 그대로 태운다). 이전
# 절단점(create-instance)은 81% 를 남겨 재번역 비용이 4배였다.
CUT_ANCHOR="list-instances-with-details"
# align 프롤로그(2~9단계)를 이미 끝난 스냅샷에서 이어받아 건너뛴다.
# 절단은 구조를 보존하므로 이미 align 된 스냅샷 위에서도 안전하다.
FROM_ALIGNED=""
TRANSLATE_VIA="api"
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
TRANSLATE_PIPELINE_BRANCH=""              # translate/translate-file 잡의 multibranch child (빈 값=main)
ALIGN_V2=1                                # PR#218 v2 모드 (기본 활성)
ALIGN_PIPELINE_BRANCH=""                  # cloud-translate 의 Jenkins multibranch child (기본: 미지정 → main)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      case "${2:-}" in
        api)     TRANSLATE_ENGINE="api" ;;
        cli)     TRANSLATE_ENGINE="claude-code" ;;
        default) TRANSLATE_ENGINE="" ;;
        *) echo "error: --engine 은 api|cli|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --model)
      case "${2:-}" in
        haiku)   TRANSLATE_MODEL="claude-haiku-4-5" ;;
        sonnet)  TRANSLATE_MODEL="claude-sonnet-4-6" ;;
        opus)    TRANSLATE_MODEL="claude-opus-4-8" ;;
        default) TRANSLATE_MODEL="" ;;
        *) echo "error: --model 은 haiku|sonnet|opus|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --tm-top-k)
      case "${2:-}" in
        default) TRANSLATE_TM_TOP_K="" ;;
        ''|*[!0-9]*) echo "error: --tm-top-k 는 양의 정수 또는 default (got: ${2:-})" >&2; exit 1 ;;
        *) TRANSLATE_TM_TOP_K="$2" ;;
      esac
      shift 2 ;;
    --chunk-workers)
      case "${2:-}" in
        default) TRANSLATE_CHUNK_WORKERS="" ;;
        ''|*[!0-9]*) echo "error: --chunk-workers 는 양의 정수 또는 default (got: ${2:-})" >&2; exit 1 ;;
        *) TRANSLATE_CHUNK_WORKERS="$2" ;;
      esac
      shift 2 ;;
    --guidelines-variant-en)
      case "${2:-}" in
        aws|unified|unified-v2) TRANSLATE_GUIDELINES_VARIANT_EN="$2" ;;
        default) TRANSLATE_GUIDELINES_VARIANT_EN="" ;;
        *) echo "error: --guidelines-variant-en 은 aws|unified|unified-v2|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --guidelines-variant-ja)
      case "${2:-}" in
        aws|unified) TRANSLATE_GUIDELINES_VARIANT_JA="$2" ;;
        default) TRANSLATE_GUIDELINES_VARIANT_JA="" ;;
        *) echo "error: --guidelines-variant-ja 은 aws|unified|default 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --verify)
      case "${2:-}" in
        py|fable) VERIFY_MODE="$2" ;;
        *) echo "error: --verify 는 py|fable 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --translate)
      case "${2:-}" in
        api|local) TRANSLATE_VIA="$2" ;;
        *) echo "error: --translate 는 api|local 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --cut-anchor)    CUT_ANCHOR="$2"; shift 2 ;;    # public-api.md 절단 앵커
    --from-aligned)  FROM_ALIGNED="$2"; shift 2 ;;   # align 스냅샷 재사용 (2~9단계 skip)
    --align-v2)      ALIGN_V2=1; shift ;;
    --no-align-v2)   ALIGN_V2=0; shift ;;
    --base-branch)   BASE_BRANCH="$2"; shift 2 ;;        # 기존 세션 브랜치 재사용
    --base-source)   BASE_SOURCE_BRANCH="$2"; shift 2 ;; # 새 세션 브랜치를 갈라낼 원본 (기본 alpha)
    --translate-pipeline-branch)
      TRANSLATE_PIPELINE_BRANCH="$2"; shift 2 ;;   # /api/translate·/api/translate/file 을 이 브랜치로
    --pipeline-branch|--align-pipeline-branch)
      ALIGN_PIPELINE_BRANCH="$2"; shift 2 ;;            # /api/align 을 이 cloud-translate 브랜치로 실행
    -h|--help) sed -n '3,102p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL 과 DASHBOARD_API_TOKEN 을 스크립트 상단(또는 env)으로 지정하세요." >&2
  exit 1
fi

LOCAL_MODE=0
if [[ "$TRANSLATE_VIA" == "local" ]]; then
  LOCAL_MODE=1
  if [[ ! -f "$CLOUD_TRANSLATE_DIR/.env" ]]; then
    echo "error: $CLOUD_TRANSLATE_DIR/.env 가 없습니다 (TRANSLATE_GITHUB_TOKEN / TRANSLATE_ANTHROPIC_API_KEY 필요)" >&2
    exit 1
  fi
fi

# local 단계 실행 헬퍼 — cloud-translate 체크아웃에서 python 스크립트를 돌린다.
run_local_step() {
  local script="$1"; shift
  echo "    \$ $script $*"
  (cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" "$script" "$@") 2>&1 | sed 's/^/    /'
  return "${PIPESTATUS[0]}"
}

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
# e2e 산출물 PR 에 'e2e' 라벨 (사람이 만든 PR 과 구분)
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"


# ── 1) e2e 세션 브랜치 준비 (기본: 새로 생성; --base-branch 로 override 가능) ─

# ── webhook 대상 repo 토글 ─────────────────────────────────────────
# e2e 실행 중 이 레포의 PR open/merge 이벤트가 webhook 을 타고 Jenkins
# ko-review/translate 잡을 중복 트리거하지 않도록, 번역 e2e 는 시작 시
# Agent-Test 의 webhook 을 비활성화한다 (webhook e2e 만 활성화 — CI Claude
# 사용량/잡 큐 낭비 방지). repo 행이 없으면 비활성화는 no-op, 활성화는
# 신규 등록(upsert). pipeline_branch 등 기존 설정은 보존한다.
set_webhook_repo_enabled() {
  local enabled="$1"   # true|false
  python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$REPO" "$enabled" <<'PYEOF' || \
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

echo "[0/14] webhook 비활성화 (번역 e2e 는 webhook 경유 잡 중복 트리거 방지)"
set_webhook_repo_enabled false

# --from-aligned 가 주어지면 세션 브랜치를 그 스냅샷에서 갈라낸다.
if [[ -n "$FROM_ALIGNED" ]]; then BASE_SOURCE_BRANCH="$FROM_ALIGNED"; fi

if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e-retranslate/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/14] Creating fresh e2e session branch: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  git push -u origin "$BASE_BRANCH"
  echo "  E2E_BASE_BRANCH=$BASE_BRANCH"     # wrapper 가 파싱하는 마커
else
  echo "[1/14] Reusing existing base branch: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
fi

# ── public-api.md 축소 (재번역 비용 절감) ─────────────────────────────
# 전에는 체크인된 `archive/alpha-origin-40pct/` 를 덮어썼는데, 그 이름이 실제와
# 어긋나 있었다 — 원본 ko 문자수의 **81%** 를 남기는 파일이어서 "40% 축소" 가
# 아니었고, 아카이브가 갱신될 때 조용히 더 커질 수 있는 구조였다. 이제 공통
# 앵커에서 **런타임에 잘라낸다**: ko/en/ja 를 같은 anchor id 에서 자르므로
# heading/anchor 정렬이 그대로 유지되고 (그래서 이미 align 된 스냅샷에서도 안전),
# 분량이 코드로 못박힌다.
truncate_public_api() {
  local anchor="$1"
  python3 - "$REPO_ROOT" "$anchor" <<'PYCUT'
import pathlib, re, sys
root, anchor = pathlib.Path(sys.argv[1]), sys.argv[2]
pat = re.compile(r'<a id="%s"></a>' % re.escape(anchor))
targets = []
for lang in ("ko", "en", "ja"):
    path = root / lang / "public-api.md"
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    idx = next((i for i, l in enumerate(lines) if pat.search(l)), None)
    if idx is None:
        # 조용히 축소를 건너뛰면 비용이 4배로 튀는데 로그만 보고는 모른다.
        raise SystemExit(f"  error: {lang}/public-api.md 에 <a id=\"{anchor}\"> 가 없습니다 "
                         f"— 절단 앵커를 다시 고르세요 (--cut-anchor)")
    targets.append((path, lines, idx))
for path, lines, idx in targets:
    before = sum(len(l) for l in lines)
    kept = "".join(lines[:idx])
    path.write_text(kept, encoding="utf-8")
    print(f"  truncated: {path.name} in {path.parent.name}/ — "
          f"{len(lines)} -> {idx} lines, {before} -> {len(kept)} chars "
          f"({len(kept) * 100 // before}%)")
PYCUT
}

SKIP_PROLOGUE=0
if [[ -n "$FROM_ALIGNED" ]]; then
  # 이미 align 이 끝난 스냅샷에서 출발하므로 restore·fix-heading-syntax·align·
  # 검증·merge(2~9단계)를 건너뛴다. 그 단계들은 픽스처가 고정이라 plan 마다 같은
  # 결과가 나오고, suite 는 첫 align 기반 plan 에서 한 번만 돌린다 — 이 plan 만
  # 그 재사용에서 빠져 있어 `all` 한 번에 align 프롤로그가 **두 번** 돌았다
  # (Opus heading 분류 12회 포함).
  SKIP_PROLOGUE=1
fi

if (( SKIP_PROLOGUE )); then
  echo
  echo "[2-9/14] skip — 이미 align 된 스냅샷에서 시작 ($FROM_ALIGNED)"
  # 스냅샷은 원본 크기의 public-api.md 를 담고 있으므로 절단은 여기서 한다.
  # 같은 앵커에서 세 언어를 자르므로 스냅샷의 정렬 상태가 유지된다.
  truncate_public_api "$CUT_ANCHOR"
  if git diff --quiet -- ko/public-api.md en/public-api.md ja/public-api.md; then
    echo "  (public-api.md 변경 없음 — 이미 절단됨)"
  else
    git add ko/public-api.md en/public-api.md ja/public-api.md
    git commit -m "test: truncate public-api.md at <a id=$CUT_ANCHOR> for retranslate e2e"
    git push origin "$BASE_BRANCH"
  fi
  # 재번역 결과를 붙일 브랜치 = 세션 브랜치 자체 (align PR 이 없다).
  head_ref="$BASE_BRANCH"
  align_pr_url=""
else
# ── 2) restore-alpha-origin (내부에서 commit+push) ────────────────────
echo
echo "[2/14] scripts/restore-alpha-origin.sh + public-api.md 절단 (@$CUT_ANCHOR)"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"
truncate_public_api "$CUT_ANCHOR"

if git diff --quiet -- ko/public-api.md en/public-api.md ja/public-api.md \
   && git diff --cached --quiet -- ko/public-api.md en/public-api.md ja/public-api.md; then
  echo "  (public-api.md 변경 없음, commit/push 건너뜀)"
else
  git add ko/public-api.md en/public-api.md ja/public-api.md
  git commit -m "test: truncate public-api.md at <a id=$CUT_ANCHOR> for retranslate e2e"
  git push origin "$BASE_BRANCH"
fi

# ── 3) fix-heading-syntax (heading 문법 정정) ─────────────────────────
# 트리거 직전 open PR 목록을 baseline 으로 저장 (step 4 의 신규 PR 감지용)
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
  --jq '.[].url' | sort -u > "$tmpdir/fix_before"

if (( LOCAL_MODE )); then
  # 배포 잡과 동일하게 두 pass 를 순서대로 (fix_fence.py → fix_heading_syntax.py).
  echo
  echo "[3/14] local fix_fence.py + fix_heading_syntax.py (dir=$CLOUD_TRANSLATE_DIR, base=$BASE_BRANCH)"
  set +e
  run_local_step pre-align/fix_fence.py "$TARGET_URL" --langs ko,en,ja --base "$BASE_BRANCH"
  fence_rc=$?
  run_local_step pre-align/fix_heading_syntax.py "$TARGET_URL" --langs ko,en,ja --base "$BASE_BRANCH"
  fixsyn_rc=$?
  set -e
  if (( fence_rc != 0 || fixsyn_rc != 0 )); then
    echo "  local fix-heading-syntax 실패 (fix_fence=$fence_rc fix_heading_syntax=$fixsyn_rc)" >&2
    exit 2
  fi
else
echo
echo "[3/14] POST $DASHBOARD_BASE_URL/api/fix-heading-syntax (base=$BASE_BRANCH)"

fix_body=$(cat <<JSON
{
  "target": "$TARGET_URL",
  "base_ref": "$BASE_BRANCH"
}
JSON
)

fix_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$fix_body" \
  "$DASHBOARD_BASE_URL/api/fix-heading-syntax")"

echo "$fix_resp" | python3 -m json.tool

fix_build_url=$(printf '%s' "$fix_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("build_url") or "")')
if [[ -n "$fix_build_url" ]]; then
  echo "  fix-heading-syntax build: $fix_build_url"
fi
fi

# ── 4) fix-heading-syntax PR 감지 대기 ────────────────────────────────
echo
if (( LOCAL_MODE )); then
  echo "[4/14] local fix_heading_syntax.py 가 만든 PR 감지 (최대 1분 — 이미 생성됨)"
else
  echo "[4/14] fix-heading-syntax 잡이 생성하는 PR 감지 대기 (최대 30분)"
fi

poll_left=180  # 1800s 상당 (10s x 180) — 반복 횟수 기반 폴링: suspend 로 wall clock 이 지나가도 타임아웃 오판하지 않는다 (2026-08-15~16 spurious exit-2 실측)
# local 모드는 위 단계가 동기 실행이라 반환 시점에 PR 이 이미 존재한다 —
# GitHub API 반영 지연만 흡수하면 되므로 폴링을 1분으로 줄인다.
if (( LOCAL_MODE )); then poll_left=6; fi
fix_pr_url=""
while (( poll_left-- > 0 )); do
  gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open \
    --json url,headRefName \
    --jq '.[] | select(.headRefName | startswith("pre-align/fix-heading-syntax-")) | .url' \
    | sort -u > "$tmpdir/fix_now"
  fix_pr_url="$(comm -13 "$tmpdir/fix_before" "$tmpdir/fix_now" | head -n1 || true)"
  if [[ -n "$fix_pr_url" ]]; then
    echo "  detected fix-heading-syntax PR: $fix_pr_url"
    e2e_label_pr "$REPO" "$fix_pr_url"
    break
  fi
  sleep 10
done

if [[ -z "$fix_pr_url" ]]; then
  echo "  timeout: 30분 내 fix-heading-syntax PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# 감지한 PR 을 merge 하고 로컬 alpha 를 최신화
echo "  merging: $fix_pr_url"
gh pr merge "$fix_pr_url" --repo "$REPO" --merge --delete-branch
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated"

# ── 5) align 트리거 (권장 preset) ────────────────────────────────────
# 트리거 직전 시점 open PR 목록을 baseline 으로 저장 (step 6 신규 PR 감지용)
gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
  --jq '.[].url' | sort -u > "$tmpdir/before"

if (( LOCAL_MODE )); then
  echo
  echo "[5/14] local fix_headings.py (dir=$CLOUD_TRANSLATE_DIR, base=$BASE_BRANCH, align_v2=$( ((ALIGN_V2)) && echo true || echo false ))"
  align_opts=(--source ko --langs en,ja --base "$BASE_BRANCH"
              --aligned-marker --demote-extras --translate-headings
              --reconcile-unmatched)
  if (( ALIGN_V2 )); then align_opts+=(--align-v2); fi
  set +e
  run_local_step pre-align/fix_headings.py "$TARGET_URL" "${align_opts[@]}"
  align_rc=$?
  set -e
  if (( align_rc != 0 )); then
    echo "  local fix_headings.py 실패 (exit $align_rc)" >&2
    exit 2
  fi
else
echo
echo "[5/14] POST $DASHBOARD_BASE_URL/api/align (권장 preset, base=$BASE_BRANCH)"

# 권장 preset flags: --aligned-marker --demote-extras --translate-headings --reconcile-unmatched
# PR#218 개선: --align-v2 (opinionated defaults + ancestor subtree 재번역).
# Jenkins 는 fix_headings.py 를 그대로 호출하므로 --auto-align-v2-below (기본 5)
# 자동 escalation 도 항상 동작.
align_v2_json="false"
if (( ALIGN_V2 )); then align_v2_json="true"; fi

# cloud-translate 의 Jenkins multibranch 특정 브랜치에서 잡을 실행하고 싶을 때만 pipeline_branch 필드 포함
align_pipeline_branch_json=""
if [[ -n "$ALIGN_PIPELINE_BRANCH" ]]; then
  align_pipeline_branch_json="\"pipeline_branch\": \"$ALIGN_PIPELINE_BRANCH\","
  echo "  align pipeline_branch: $ALIGN_PIPELINE_BRANCH"
fi

align_body=$(cat <<JSON
{
  "target": "$TARGET_URL",
  "base_ref": "$BASE_BRANCH",
  $align_pipeline_branch_json
  "aligned_marker": true,
  "demote_extras": true,
  "translate_headings": true,
  "reconcile_unmatched": true,
  "align_v2": $align_v2_json
}
JSON
)

align_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$align_body" \
  "$DASHBOARD_BASE_URL/api/align")"

echo "$align_resp" | python3 -m json.tool

align_build_url=$(printf '%s' "$align_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("build_url") or "")')
if [[ -n "$align_build_url" ]]; then
  echo "  align build: $align_build_url"
fi
fi

# ── 6) align PR 감지 (base=alpha 로 새로 open 된 PR) ─────────────────
echo
if (( LOCAL_MODE )); then
  echo "[6/14] local fix_headings.py 가 만든 PR 감지 (최대 1분 — 이미 생성됨)"
else
  echo "[6/14] Jenkins align 잡이 생성하는 PR 감지 대기 (최대 30분)"
fi

poll_left=180  # 1800s 상당 (10s x 180) — 반복 횟수 기반 폴링: suspend 로 wall clock 이 지나가도 타임아웃 오판하지 않는다 (2026-08-15~16 spurious exit-2 실측)
# local 모드는 위 단계가 동기 실행이라 반환 시점에 PR 이 이미 존재한다 —
# GitHub API 반영 지연만 흡수하면 되므로 폴링을 1분으로 줄인다.
if (( LOCAL_MODE )); then poll_left=6; fi
align_pr_url=""
while (( poll_left-- > 0 )); do
  gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
    --jq '.[].url' | sort -u > "$tmpdir/now"
  align_pr_url="$(comm -13 "$tmpdir/before" "$tmpdir/now" | head -n1 || true)"
  if [[ -n "$align_pr_url" ]]; then
    echo "  detected new PR: $align_pr_url"
    e2e_label_pr "$REPO" "$align_pr_url"
    break
  fi
  sleep 10
done

if [[ -z "$align_pr_url" ]]; then
  echo "  timeout: 30분 내 새 PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# align PR 의 head 브랜치 (재번역 커밋을 이 브랜치에 append)
align_pr_number="$(gh pr view "$align_pr_url" --repo "$REPO" --json number --jq .number)"
head_ref="$(gh pr view "$align_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
fi   # ← SKIP_PROLOGUE (2~6단계). 7·8단계는 두 경로 모두 실행한다.

# ── 7) public-api.md 전체 재번역 → align PR head 브랜치에 커밋 ────────
if (( LOCAL_MODE )); then
  # /api/translate/file 핸들러가 하는 조립을 그대로: pr_number → head_ref 를
  # commit_to_branch 로 쓰고 file_url = blob/<head_ref>/<source>/<path>,
  # DIFF_MODE=full (전체 재번역). engine/model/tm_top_k/chunk_workers 는
  # translate_file.py 에 CLI 플래그가 없어 Jenkinsfile 과 동일하게 env 로 준다.
  retx_file_url="https://github.com/$REPO/blob/$head_ref/$RETRANSLATE_SOURCE/$RETRANSLATE_PATH"
  echo
  echo "[7/14] local translate_file.py (dir=$CLOUD_TRANSLATE_DIR, file=$retx_file_url, commit-to-branch=$head_ref, DIFF_MODE=full, engine=api(local 고정), model=${TRANSLATE_MODEL:-default})"
  # local 모드는 engine 을 **api 로 고정**한다. 이유 두 가지:
  #   (1) 커버리지가 없다 — 이 plan 의 검증 대상은 `/api/translate/file`
  #       (DIFF_MODE=full) **경로**이고, local 모드에서는 그 라우트를 아예 타지
  #       않고 translate_file.py 를 직접 부른다. 그러니 CLI 엔진을 태워서 얻는
  #       라우트 커버리지가 0 이다 (배포 경로 검증은 --translate api 가 한다).
  #   (2) CLI 엔진은 로컬 `claude` OAuth 한도를 쓰는데 그 한도는 이 세션·fable
  #       검증과 같은 풀이라 자주 소진된다 — 2026-08-24 실측으로 이 plan 이 두 번
  #       429 로 죽었다 (`Claude 사용량 한도 소진 (HTTP 429)`). api 엔진은 별도
  #       한도라 영향이 없다.
  # 다른 모든 plan 의 local 경로도 api+haiku 로 고정되어 있어 조건도 일치한다.
  retx_env=(TRANSLATE_DIFF_MODE=full TRANSLATE_TRANSLATE_ENGINE=api)
  # 모델은 **두 env 모두** 세팅해야 한다. ClaudeCodeTranslator 는
  # settings.claude_code_model 을 쓰고 (translator.py:3918) anthropic_model 은
  # 보지 않으므로, engine=claude-code 에서 ANTHROPIC_MODEL 만 주면 조용히 무시되고
  # .env 의 TRANSLATE_CLAUDE_CODE_MODEL 이 그대로 쓰인다 (2026-08-24 실측: 이
  # plan 이 haiku 로 로그를 찍으면서 실제로는 sonnet-4-6 으로 돌아 번역 PR 하나가
  # 6.07M 토큰 = suite 전체의 80% 를 먹었다). translate/Jenkinsfile 의 MODEL_ENV 가
  # 두 env 를 함께 세팅하는 것과 같은 이유다 ("takes effect regardless of ENGINE").
  [[ -n "$TRANSLATE_MODEL" ]]          && retx_env+=("TRANSLATE_ANTHROPIC_MODEL=$TRANSLATE_MODEL"
                                                     "TRANSLATE_CLAUDE_CODE_MODEL=$TRANSLATE_MODEL")
  [[ -n "$TRANSLATE_TM_TOP_K" ]]       && retx_env+=("TRANSLATE_TM_TOP_K=$TRANSLATE_TM_TOP_K")
  [[ -n "$TRANSLATE_CHUNK_WORKERS" ]]  && retx_env+=("TRANSLATE_CHUNK_WORKERS=$TRANSLATE_CHUNK_WORKERS")
  [[ -n "$TRANSLATE_GUIDELINES_VARIANT_EN" ]] && retx_env+=("TRANSLATE_GUIDELINES_VARIANT_EN=$TRANSLATE_GUIDELINES_VARIANT_EN")
  [[ -n "$TRANSLATE_GUIDELINES_VARIANT_JA" ]] && retx_env+=("TRANSLATE_GUIDELINES_VARIANT_JA=$TRANSLATE_GUIDELINES_VARIANT_JA")
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && env "${retx_env[@]}" \
     "$CLOUD_TRANSLATE_PY" translate/translate_file.py "$retx_file_url" \
     --commit-to-branch "$head_ref") 2>&1 | sed 's/^/    /'
  retx_rc=${PIPESTATUS[0]}
  set -e
  if (( retx_rc != 0 )); then
    echo "  local translate_file.py 실패 (exit $retx_rc)" >&2
    exit 2
  fi
  git fetch --quiet origin "$head_ref"
  echo "  retranslate 완료 & align PR head branch ($head_ref) 최신화"
else
echo
echo "[7/14] POST $DASHBOARD_BASE_URL/api/translate/file ($RETRANSLATE_SOURCE/$RETRANSLATE_PATH 전체 재번역, pr_number=$align_pr_number, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default}, tm_top_k=${TRANSLATE_TM_TOP_K:-default})"

# pr_number 지정 시 서버가 GH 에서 head.ref 조회 → commit_to_branch=head_ref
retx_engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  retx_engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

retx_model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  retx_model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

retx_tm_top_k_json=""
if [[ -n "$TRANSLATE_TM_TOP_K" ]]; then
  retx_tm_top_k_json="\"tm_top_k\": \"$TRANSLATE_TM_TOP_K\","
fi

# PR#192/#199 개선: chunk_workers + guidelines_variant 를 /api/translate/file 에도 forward
retx_chunk_workers_json=""
if [[ -n "$TRANSLATE_CHUNK_WORKERS" ]]; then
  retx_chunk_workers_json="\"chunk_workers\": \"$TRANSLATE_CHUNK_WORKERS\","
fi
retx_gv_en_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_EN" ]]; then
  retx_gv_en_json="\"guidelines_variant_en\": \"$TRANSLATE_GUIDELINES_VARIANT_EN\","
fi
retx_gv_ja_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_JA" ]]; then
  retx_gv_ja_json="\"guidelines_variant_ja\": \"$TRANSLATE_GUIDELINES_VARIANT_JA\","
fi

retx_pipeline_branch_json=""
if [[ -n "$TRANSLATE_PIPELINE_BRANCH" ]]; then
  retx_pipeline_branch_json="\"pipeline_branch\": \"$TRANSLATE_PIPELINE_BRANCH\","
  echo "  translate/file pipeline_branch: $TRANSLATE_PIPELINE_BRANCH"
fi

# 대상 지정: align PR 이 있으면 pr_number (서버가 head.ref 를 조회), 스냅샷
# 재사용 모드에서는 align PR 이 없으므로 세션 브랜치를 직접 준다.
if [[ -n "$align_pr_url" ]]; then
  retx_target_json="\"pr_number\": $align_pr_number,"
else
  retx_target_json="\"branch\": \"$head_ref\","
fi

retx_body=$(cat <<JSON
{
  "repo": "$REPO",
  $retx_pipeline_branch_json
  $retx_target_json
  "source": "$RETRANSLATE_SOURCE",
  "path": "$RETRANSLATE_PATH",
  $retx_engine_json
  $retx_model_json
  $retx_tm_top_k_json
  $retx_chunk_workers_json
  $retx_gv_en_json
  $retx_gv_ja_json
  "path_prefix": ""
}
JSON
)

retx_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$retx_body" \
  "$DASHBOARD_BASE_URL/api/translate/file")"

echo "$retx_resp" | python3 -m json.tool

retx_job_id=$(printf '%s' "$retx_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("job_id") or "")')
retx_build_url=$(printf '%s' "$retx_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("build_url") or "")')

if [[ -z "$retx_job_id" ]]; then
  echo "  error: /api/translate/file 응답에서 job_id 를 찾지 못했습니다." >&2
  exit 2
fi
if [[ -n "$retx_build_url" ]]; then
  echo "  retranslate build: $retx_build_url"
fi

# 잡 상태가 success 가 될 때까지 대기 (전체 재번역이라 최대 90분)
echo "  retranslate 완료 대기: job_id=$retx_job_id (최대 90분)"
poll_left=540  # 5400s 상당 (10s x 540) — 반복 횟수 기반 폴링: suspend 로 wall clock 이 지나가도 타임아웃 오판하지 않는다 (2026-08-15~16 spurious exit-2 실측)
retx_status=""
while (( poll_left-- > 0 )); do
  retx_status="$(curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$retx_job_id" \
    | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  tasks=(d.get("job") or {}).get("tasks") or []
  print(tasks[0].get("status") if tasks else "")
except Exception:
  print("")')"
  case "$retx_status" in
    success|failure|cancelled|partial) break ;;
  esac
  sleep 10
done

if [[ "$retx_status" != "success" ]]; then
  echo "  retranslate 실패 (status=$retx_status, job_id=$retx_job_id)" >&2
  exit 2
fi

# align PR head 브랜치를 fetch 해서 재번역 커밋을 로컬로 가져옴
git fetch --quiet origin "$head_ref"
echo "  retranslate 완료 & align PR head branch ($head_ref) 최신화"
fi

# ── 8) claude CLI(fable)로 align PR (재번역 포함) heading·anchor-id 정렬 검사 ─
echo
echo "[8/14] claude CLI (fable model) heading/anchor-id 정렬 검사 (PR=$align_pr_url, 재번역 포함)"

check_wt="$tmpdir/pr-check"
git worktree add "$check_wt" "origin/$head_ref" >/dev/null

check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외한 (1) heading level 순서와 (2) anchor id 순서
(<a id="..."></a> 형식과 { #id } 형식 모두)가 세 언어에서 완전히 일치하는지 검사해줘.
파일별 결과를 OK/FAIL 표로 출력하고, FAIL 인 파일은 어긋난 위치와 내용을 설명해줘.
마지막 줄에는 다른 텍스트 없이 전체 판정만 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" 로 출력해.'

if [[ "$VERIFY_MODE" == "py" ]]; then
  set +e
  check_out="$(python3 "$REPO_ROOT/scripts/check_docs_align.py" --root "$check_wt" --mode align)"
  set -e
else
  check_out="$(cd "$check_wt" && claude -p "$check_prompt" \
    --model fable \
    --allowedTools "Bash,Read,Grep,Glob")"
fi

echo "$check_out"

git worktree remove "$check_wt" --force

if ! grep -q '^ALIGNMENT: OK' <<<"$check_out"; then
  echo "  heading/anchor-id 정렬 검사 실패 — PR 을 merge 하지 않고 open 으로 남깁니다: $align_pr_url" >&2
  exit 3
fi

# ── 9) 검증 통과 → align PR 을 alpha 로 merge ─────────────────────────
echo
if [[ -z "$align_pr_url" ]]; then
  echo "[9/14] skip — align PR 이 없다 (스냅샷 재사용 모드: 재번역이 세션 브랜치에 직접 커밋됨)"
else
  echo "[9/14] 검증 통과 — align PR 을 $BASE_BRANCH 로 merge"
  gh pr merge "$align_pr_url" --repo "$REPO" --merge --delete-branch
  git pull --ff-only origin "$BASE_BRANCH"
  echo "  merged & local $BASE_BRANCH updated: $align_pr_url"
fi

# ── 10) create-translate-test-pr (ko 변형 → translate-test PR 생성) ───
echo
echo "[10/14] scripts/create-translate-test-pr.sh"

create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh" --base-branch "$BASE_BRANCH")"
echo "$create_out"

# ── 11) ko 변경 PR 생성 확인 ──────────────────────────────────────────
echo
echo "[11/14] ko 변경 PR 생성 확인"

# gh pr create 는 마지막 줄에 PR URL 을 출력
ko_pr_url="$(grep -oE 'https://github.com/[^ ]+/pull/[0-9]+' <<<"$create_out" | tail -n1 || true)"
if [[ -z "$ko_pr_url" ]]; then
  echo "  error: create-translate-test-pr.sh 출력에서 PR URL 을 찾지 못했습니다." >&2
  exit 2
fi

ko_pr_state="$(gh pr view "$ko_pr_url" --repo "$REPO" --json state --jq .state)"
if [[ "$ko_pr_state" != "OPEN" ]]; then
  echo "  error: ko 변경 PR 이 open 상태가 아닙니다 (state=$ko_pr_state): $ko_pr_url" >&2
  exit 2
fi
echo "  ko 변경 PR 확인: $ko_pr_url (state=$ko_pr_state)"

# ── 12) ko 변경 PR 번역 (권장 preset) ─────────────────────────────────
if (( LOCAL_MODE )); then
  # 로컬 translate_pr.py — 플래그는 아래 api body 의 권장 preset 과 동일하고,
  # e2e-align-and-translate.sh 의 local 경로와도 같은 집합을 쓴다 (local run
  # 끼리 번역 조건이 갈리지 않게). engine/model 은 이 plan 의 --engine/--model
  # 설정을 env 로 전달 — step 7 의 translate_file.py 와 같은 엔진을 태워야
  # 한 plan 안에서 조건이 어긋나지 않는다.
  echo
  echo "[12/14] local translate_pr.py (dir=$CLOUD_TRANSLATE_DIR, PR=$ko_pr_url, engine=api(local 고정), model=${TRANSLATE_MODEL:-default})"
  # engine=api 고정 — 7단계 주석의 두 이유가 그대로 적용된다.
  tx_env=(TRANSLATE_TRANSLATE_ENGINE=api)
  # ANTHROPIC_MODEL 단독으로는 CLI 엔진에 안 먹는다 — 위 7단계 주석 참고.
  [[ -n "$TRANSLATE_MODEL" ]]         && tx_env+=("TRANSLATE_ANTHROPIC_MODEL=$TRANSLATE_MODEL"
                                                  "TRANSLATE_CLAUDE_CODE_MODEL=$TRANSLATE_MODEL")
  [[ -n "$TRANSLATE_GUIDELINES_VARIANT_EN" ]] && tx_env+=("TRANSLATE_GUIDELINES_VARIANT_EN=$TRANSLATE_GUIDELINES_VARIANT_EN")
  [[ -n "$TRANSLATE_GUIDELINES_VARIANT_JA" ]] && tx_env+=("TRANSLATE_GUIDELINES_VARIANT_JA=$TRANSLATE_GUIDELINES_VARIANT_JA")
  tx_opts=(--diff-granularity block --glossary-mode service --max-load-ratio 2
           --workers 2 --table-rows --skip-full-table --skip-anchor-only
           --assign-anchors --align-headings --llm-patch-fallback
           --fix-korean-leftover)
  [[ -n "$TRANSLATE_CHUNK_WORKERS" ]] && tx_opts+=(--chunk-workers "$TRANSLATE_CHUNK_WORKERS")
  [[ -n "$TRANSLATE_TM_TOP_K" ]]      && tx_opts+=(--tm-top-k "$TRANSLATE_TM_TOP_K")
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && env "${tx_env[@]}" \
     "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" "${tx_opts[@]}") 2>&1 | sed 's/^/    /'
  tx_rc=${PIPESTATUS[0]}
  set -e
  if (( tx_rc != 0 )); then
    echo "  local translate_pr.py 실패 (exit $tx_rc)" >&2
    exit 2
  fi
  # 번역 PR 은 이미 생성된 상태 — step 13 의 gh 폴링이 즉시 감지한다.
else
echo
echo "[12/14] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$ko_pr_url, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default}, tm_top_k=${TRANSLATE_TM_TOP_K:-default})"

# --engine 옵션이 지정된 경우에만 engine 필드 포함
engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

# --model 값이 설정된 경우에만 model 필드 포함
model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

# --tm-top-k 값이 설정된 경우에만 tm_top_k 필드 포함
tm_top_k_json=""
if [[ -n "$TRANSLATE_TM_TOP_K" ]]; then
  tm_top_k_json="\"tm_top_k\": \"$TRANSLATE_TM_TOP_K\","
fi

# PR#192/#199 개선: chunk_workers + guidelines_variant
chunk_workers_json=""
if [[ -n "$TRANSLATE_CHUNK_WORKERS" ]]; then
  chunk_workers_json="\"chunk_workers\": \"$TRANSLATE_CHUNK_WORKERS\","
fi
gv_en_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_EN" ]]; then
  gv_en_json="\"guidelines_variant_en\": \"$TRANSLATE_GUIDELINES_VARIANT_EN\","
fi
gv_ja_json=""
if [[ -n "$TRANSLATE_GUIDELINES_VARIANT_JA" ]]; then
  gv_ja_json="\"guidelines_variant_ja\": \"$TRANSLATE_GUIDELINES_VARIANT_JA\","
fi

# 권장 preset flags:
#   --diff-granularity block --glossary-mode service --max-load-ratio 2
#   --workers 2 --table-rows --skip-full-table --skip-anchor-only
#   --assign-anchors --align-headings
# PR#207/#211 (within/cross-opcode batching) 은 자동 활성.
# --translate-pipeline-branch: translate 잡을 cloud-translate 의 특정 Jenkins
# multibranch child (예: PR-532) 에서 실행 — 미머지 브랜치의 번역 로직을
# 배포 없이 Jenkins 경로로 검증할 때. 빈 값이면 필드 미전송(=main).
translate_pipeline_branch_json=""
if [[ -n "$TRANSLATE_PIPELINE_BRANCH" ]]; then
  translate_pipeline_branch_json="\"pipeline_branch\": \"$TRANSLATE_PIPELINE_BRANCH\","
  echo "  translate pipeline_branch: $TRANSLATE_PIPELINE_BRANCH"
fi

translate_body=$(cat <<JSON
{
  "pr_url": "$ko_pr_url",
  $translate_pipeline_branch_json
  $engine_json
  $model_json
  $tm_top_k_json
  $chunk_workers_json
  $gv_en_json
  $gv_ja_json
  "diff_granularity": "block",
  "glossary_mode": "service",
  "max_load_ratio": "2",
  "workers": "2",
  "table_rows": true,
  "skip_full_table": true,
  "skip_anchor_only": true,
  "assign_anchors": true,
  "align_headings": true
}
JSON
)

translate_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$translate_body" \
  "$DASHBOARD_BASE_URL/api/translate")"

echo "$translate_resp" | python3 -m json.tool
fi

# ── 13) 번역 PR 감지 대기 (base = ko PR head 브랜치) ──────────────────
echo
echo "[13/14] translate 잡이 생성하는 번역 PR 감지 대기 (최대 60분)"

ko_head_ref="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"

poll_left=180  # 3600s 상당 (20s x 180) — 반복 횟수 기반 폴링: suspend 로 wall clock 이 지나가도 타임아웃 오판하지 않는다 (2026-08-15~16 spurious exit-2 실측)
trans_pr_url=""
while (( poll_left-- > 0 )); do
  trans_pr_url="$(gh pr list --repo "$REPO" --base "$ko_head_ref" --state open \
    --json url,headRefName \
    --jq '.[] | select(.headRefName | startswith("translate/")) | .url' \
    | sort -u | head -n1 || true)"
  if [[ -n "$trans_pr_url" ]]; then
    echo "  detected translation PR: $trans_pr_url"
    e2e_label_pr "$REPO" "$trans_pr_url"
    break
  fi
  sleep 20
done

if [[ -z "$trans_pr_url" ]]; then
  echo "  timeout: 60분 내 번역 PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# ── 14) claude CLI(fable)로 번역 PR 검증 → 결과를 PR 댓글로 등록 ───────
echo
echo "[14/14] claude CLI (fable model) 번역 PR 검증 (PR=$trans_pr_url)"

trans_head_ref="$(gh pr view "$trans_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$trans_head_ref"
trans_wt="$tmpdir/trans-check"
git worktree add "$trans_wt" "origin/$trans_head_ref" >/dev/null

trans_check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외하고 다음 세 가지가 세 언어에서 완전히 일치하는지 검사해줘.
(1) heading level 순서
(2) anchor id 순서 (<a id="..."></a> 형식과 { #id } 형식 모두)
(3) 표(table)가 있으면 표 개수와 각 표의 데이터 행(row) 개수
파일별 결과를 OK/FAIL 표로 출력하고 (표 개수·행 수 포함), FAIL 인 파일은 어긋난 위치와 내용을 설명해줘.
마지막 줄에는 다른 텍스트 없이 전체 판정만 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" 로 출력해.'

if [[ "$VERIFY_MODE" == "py" ]]; then
  set +e
  trans_check_out="$(python3 "$REPO_ROOT/scripts/check_docs_align.py" --root "$trans_wt" --mode translate)"
  set -e
else
  trans_check_out="$(cd "$trans_wt" && claude -p "$trans_check_prompt" \
    --model fable \
    --allowedTools "Bash,Read,Grep,Glob")"
fi

echo "$trans_check_out"

git worktree remove "$trans_wt" --force

# 검증 결과를 번역 PR 댓글로 등록
if grep -q '^ALIGNMENT: OK' <<<"$trans_check_out"; then
  verdict_line="✅ 번역 PR 자동 검증 통과 (heading·anchor-id·표 행 수 일치)"
else
  verdict_line="❌ 번역 PR 자동 검증 실패 — 아래 상세 결과를 확인하세요"
fi

cat > "$tmpdir/trans_comment.md" <<EOF
## 번역 PR 자동 검증 결과 (claude CLI, fable)

$verdict_line

- 검증 브랜치: \`$trans_head_ref\`
- 검증 항목: ko/en/ja heading level 순서 · anchor id 순서 · 표 개수/행 수

<details>
<summary>상세 결과</summary>

$trans_check_out

</details>
EOF

gh pr comment "$trans_pr_url" --repo "$REPO" --body-file "$tmpdir/trans_comment.md"
echo "  검증 결과 댓글 등록 완료: $trans_pr_url"

if ! grep -q '^ALIGNMENT: OK' <<<"$trans_check_out"; then
  echo "  번역 PR 검증 실패 — PR 은 open 으로 남깁니다: $trans_pr_url" >&2
  exit 3
fi

echo
echo "완료."
