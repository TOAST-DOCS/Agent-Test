#!/usr/bin/env bash
#
# End-to-end 재현 스크립트 (Agent-Test alpha):
#   1. alpha 브랜치로 switch
#   2. scripts/restore-alpha-origin.sh 실행 (내부에서 commit+push)
#   3. fix-heading-syntax (heading 문법 정정, base=alpha) — dashboard API 또는
#      local fix_fence.py + fix_heading_syntax.py
#   4. fix-heading-syntax 잡이 생성하는 PR 감지 → merge → alpha 최신화
#   5. scripts/restore-aligned-public-api.sh 실행 후 commit+push
#   6. align (= fix_headings, 권장 preset, base=alpha) — dashboard API 또는
#      local fix_headings.py
#   7. Jenkins align 잡이 새로 만든 PR 을 gh 로 감지
#   8. align PR 브랜치의 ko/en/ja heading·anchor-id 정렬 검사
#      (scripts/check_docs_align.py — 결정적, <1초. --verify fable 로 예전
#       claude -p 검사로 되돌릴 수 있다)
#   9. 검증 통과 시 align PR 을 alpha 로 merge (실패 시 PR 은 open 으로 남김)
#  10. scripts/create-translate-test-pr.sh 실행 (ko 변형 → translate-test PR 생성)
#  11. ko 변경 PR 생성 확인
#  12. ko-review 트리거 (ko 변경 PR 대상 한글 검수) — dashboard /api/ko-review
#      또는 local review_pr.py. table-suite/row-drop-repro/markup-churn 은 기본
#      생략 (--ko-review 로 강제)
#  13. ko-review 잡 완료 대기 (Jobs 상태 polling; local 은 동기라 불필요)
#  14. ko 변경 PR 의 suggestion 검증 (1개 이상 존재해야 함) → 전체 accept 후
#      ko 변경 PR head 브랜치로 commit + push (12 생략 시 함께 생략)
#  15. ko 변경 PR (suggestion 반영본) 대상으로 dashboard /api/translate 호출
#  16. translate 잡이 생성하는 번역 PR(base=ko PR head 브랜치) 감지 대기
#  17. 번역 PR 검증 (heading·id·표 행 수·셀 수·한글 잔류·식별자 행) → 결과를
#      PR 댓글로 등록. 같은 checker 의 --mode translate (markup-churn 은 +--markup)
#
# 상단 두 변수(DASHBOARD_BASE_URL, DASHBOARD_API_TOKEN)를 채우고 실행.
# 아니면 같은 이름의 환경변수를 export 해도 됩니다.
#
# Usage:
#   scripts/e2e-align-and-translate.sh [--engine api|cli] [--model haiku|sonnet|opus]
#                                      [--tm-top-k N] [--chunk-workers N]
#                                      [--guidelines-variant-en aws|unified|unified-v2|default]
#                                      [--guidelines-variant-ja aws|unified|default]
#                                      [--align-v2|--no-align-v2]
#                                      [--plan round1|round2|row-drop-repro|table-suite|markup-churn]
#                                      [--translate api|local]
#                                      [--ko-review|--no-ko-review]
#                                      [--verify py|fable]
#                                      [--from-aligned <branch>]
#
#   --engine api   translate 잡을 api 엔진으로 실행
#   --engine cli   translate 잡을 claude-code(CLI) 엔진으로 실행 (기본값)
#   (default 지정 시 engine 필드를 보내지 않음 → 서버 default)
#
#   --model haiku  claude-haiku-4-5 사용 (기본값)
#   --model sonnet claude-sonnet-4-6 사용
#   --model opus   claude-opus-4-8 사용
#
#   --tm-top-k N          TM few-shot 개수 (기본값 1). "default" 지정 시 필드 미전송 (잡 .env default = 10)
#   --chunk-workers N     chunk 병렬도 (기본값 2). PR#192/#199 의 chunk 병렬화 exercise.
#                         "default" 시 잡 .env default (api=4, cli=2).
#   --guidelines-variant-en <v>  en 가이드라인 크기 (aws|unified|unified-v2|default).
#                                기본값 default (잡 .env default = unified-v2).
#   --guidelines-variant-ja <v>  ja 가이드라인 크기 (aws|unified|default).
#                                기본값 default (잡 .env default = unified).
#   --align-v2 / --no-align-v2   PR#218 ko-source-of-truth 모드로 align 실행 여부.
#                                기본값 --align-v2 (opinionated defaults: demote-extras +
#                                translate-headings 자동 활성; ancestor subtree 재번역 포함
#                                zero-residual sweep). fix_headings.py 는 --auto-align-v2-below
#                                (기본 5) 를 자동으로 사용하므로, --align-v2 가 꺼져 있어도
#                                잔여 diff 1..5 인 (doc, lang) 은 자동 escalation 됨.
#
#   --plan <name>                create-translate-test-pr.sh 에 전달할 ko 변형 plan.
#                                round1(기본) / round2 / row-drop-repro / table-suite /
#                                markup-churn.
#                                row-drop-repro: cloud-translate PR #283 회귀 재현용.
#                                version-guide.md 의 en/ja stale(행 1개 결여) 상태는
#                                create-translate-test-pr.sh 가 base 브랜치에 stale-ify
#                                커밋으로 조성 (archive 는 일관 유지 — round1/round2 의
#                                step 17 전-파일 검사가 픽스처 때문에 깨지지 않도록).
#                                첫 문단만 짧게 수정 → load/ko-diff 비율 cap 초과 →
#                                LLM-patch fallback 활성. 결함 상태에서는 en/ja 가 stale
#                                행을 유지하고, fix 배포 후에는 backfill 또는 todo-stub.
#                                table-suite: 결함 재현 2케이스 + 정상 표 변형들
#                                markup-churn: 코스메틱 마크업 churn(펜스 info string,
#                                  <br/>, 헤딩 뒤 빈 줄) + 소수 내용 변경. load guard 가
#                                  정상 리뷰 PR 을 runaway 로 오판해 파일을 제외하던 것을
#                                  재현 (Storage-Object-Storage#181/#185). PASS 판정은
#                                  load guard/LLM 패치 폴백 미발동 + PR 본문 제외 섹션
#                                  없음 + en/ja 의 <br/>·```lang 개수가 ko 와 일치.
#                                (중간 행 삽입·헤더 수정·행 삭제·행 수정·행 추가·신규 표)
#                                의 종합 검증.
#                                - version-guide: CK 인시던트 동형 (LLM-patch 경로).
#                                  PR #283 미배포 = FAIL(행 유실), 배포 후 = 해소 기대.
#                                - release-notes: row-splice positional 손상 (#283 범위 밖
#                                  별개 결함). #283 만 배포된 상태에서는 FAIL 이 정상.
#                                  cloud-translate PR #290 (table-row reconcile, #283 위
#                                  stacked) 배포 후에는 A·B 둘 다 PASS 가 기대값이다.
#                                - spec-guide: 컬럼 drift 혼재 (결함 D — notification-hub
#                                  PR #209 지적 4번 동형). en/ja 표는 stale-ify 로 'Not
#                                  Null' 컬럼이 제거된 3컬럼, ko 행 하나의 설명 셀만 수정.
#                                  ncols 불일치 가드 미배포 = FAIL(4셀 행이 3컬럼 표에
#                                  혼재, step 17 검사 6), 가드 배포 후 = PASS 기대.
#                                - 그 외 파일의 FAIL 은 새로운 회귀를 의미한다.
#
#   --translate api|local        실행 방식. api(기본) = 배포된 dashboard/Jenkins 잡
#                                (/api/fix-heading-syntax, /api/align, /api/ko-review,
#                                /api/translate). local = **네 단계 전부**
#                                $CLOUD_TRANSLATE_DIR 의 스크립트를 직접 실행 —
#                                미배포 브랜치의 로직을 배포 없이 검증한다:
#                                  3단계 → pre-align/fix_fence.py + fix_heading_syntax.py
#                                  6단계 → pre-align/fix_headings.py
#                                  12단계 → korean-review/review_pr.py
#                                  15단계 → translate/translate_pr.py
#                                각 단계의 인자는 dashboard 핸들러 + Jenkinsfile 이
#                                조립하는 것과 1:1 로 맞춰져 있다 (한쪽만 바뀌면 local
#                                과 api 판정이 갈리므로 함께 고칠 것). 동기 실행이라
#                                잡 완료 폴링이 없어지고 PR 감지 폴링은 1분으로 줄어든다.
#                                **예외 한 곳**: 0단계의 webhook 킬 스위치
#                                (POST /api/webhooks/repos) 는 local 에서도 호출한다 —
#                                파이프라인 단계가 아니라 배포된 파이프라인이 같은 PR 을
#                                동시에 처리하지 않게 막는 스위치라서, 끄지 않으면 local
#                                번역과 배포본 번역이 섞인다. 그래서 local 모드도
#                                DASHBOARD_BASE_URL/_TOKEN 이 필수다.
#                                번역의 engine/model 은 api+haiku 로 고정(기존 run 과
#                                동일 조건), align/ko-review 는 api 모드에서도 잡
#                                파라미터를 default 로 보내므로 여기서도 미전송
#                                ($CLOUD_TRANSLATE_DIR/.env 기본값).
#
#   --no-table-reconcile         translate_pr.py 에 --no-table-reconcile 을 전달해 표 행
#                                reconcile 을 끈다 (기본은 ON = translate_pr.py 기본값).
#                                stale 표가 splice 이전에 복구되지 않으므로 행 splice 의
#                                1:1 가드가 깨져 full 로 떨어지고, skip-full-table 가드가
#                                그 문서를 제외하려다 **LLM-patch fallback** 을 태운다 —
#                                reconcile 이 켜진 기본 실행에서는 도달 불가한 경로다
#                                (2026-08-23 실측: 8 plan 전체에서 LLM-patch 0건, 원인은
#                                row-drop-repro 의 stale 행이 reconcile 단계에서 backfill
#                                되어 부하가 cap 아래로 떨어지기 때문). dashboard
#                                /api/translate 에는 이 필드가 없어 **--translate local
#                                전용**이며, api 모드와 함께 주면 하드 실패한다 (조용히
#                                reconcile ON 으로 돌아 통과하는 것이 최악이므로).
#
#   --ko-review / --no-ko-review 12~14단계(한글 검수 + suggestion accept) 실행 여부.
#                                기본값은 plan 별로 갈린다 — table-suite /
#                                row-drop-repro / markup-churn 은 **생략**, 그 외
#                                (round1/round2) 는 실행. 그 세 plan 의 판정 대상은
#                                번역 로직이고, 검수 suggestion 이 표·마크업 픽스처를
#                                흔들면 17단계의 결정론적 판정이 흐려진다.
#
#   --verify py                  8·17 단계 구조 검증을 scripts/check_docs_align.py
#                                (기본). 규칙은 예전 fable 프롬프트와 1:1 이고
#                                판정 계약(마지막 줄 "ALIGNMENT: OK|FAIL")도 동일
#                                하지만 11개 문서 검사가 20분 -> 0.05초가 된다.
#   --verify fable               예전 `claude -p --model fable` agentic 검증.
#                                프롬프트를 바꿔 시맨틱 검사를 추가할 때만 사용.
#
#   --translate-pipeline-branch <name>
#                                translate 잡을 cloud-translate 의 Jenkins
#                                multibranch child <name> (예: PR-532) 에서
#                                실행한다. 미머지 PR 의 번역 로직을 배포 없이
#                                **Jenkins 경로로** 검증할 때 사용 (--translate
#                                local 은 로컬 프로세스로 도는 별개 경로).
#                                align/fix-heading-syntax/ko-review 잡은 그대로
#                                main 에서 돈다 — 번역 외 잡까지 바꾸려면 각
#                                잡의 pipeline_branch 를 따로 손봐야 한다.
#                                child job 은 첫 빌드 전 파라미터가 등록돼
#                                있지 않아 400 이 난다 — 빈 /build 한 번으로
#                                등록한 뒤 쓸 것.
#
#   --from-aligned <branch>      restore/fix-heading-syntax/align/검증/merge
#                                (2~9단계) 를 건너뛰고, 이미 align 이 끝난
#                                <branch> 에서 새 세션 브랜치를 갈라낸다.
#                                픽스처가 고정이라 plan 마다 같은 align 결과가
#                                나오므로, suite 는 첫 plan 에서만 2~9단계를
#                                돌리고 그 스냅샷(`<session>-aligned`) 을 이후
#                                plan 에 넘긴다 (plan 당 6~8분 절감).
#                                9단계 직후 `E2E_ALIGNED_BRANCH=<branch>` 를
#                                출력하므로 wrapper 가 그 값을 파싱해 쓴다.
#
# 의존성: git, gh (로그인), curl, python3 (--verify fable 일 때만 claude CLI)

set -euo pipefail

# ── 사용자 입력 ───────────────────────────────────────────────────────
DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"   # 예: https://docs.internal.nhncloud.com
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}" # 대시보드 관리자에게서 발급받은 값

REPO="TOAST-DOCS/Agent-Test"
BASE_BRANCH=""                                # 미지정 시 e2e/<timestamp> 자동 생성 (alpha 미오염)
BASE_SOURCE_BRANCH="alpha"                    # 새 e2e 브랜치를 갈라낼 원본
TARGET_URL="https://github.com/${REPO}"
# ─────────────────────────────────────────────────────────────────────

# ── 실행 옵션 ─────────────────────────────────────────────────────────
TRANSLATE_ENGINE="claude-code"            # 기본값 cli — api/default 로 override 가능
TRANSLATE_MODEL="claude-haiku-4-5"        # 기본값 haiku — sonnet/opus/default 로 override 가능
TRANSLATE_TM_TOP_K="1"                    # TM few-shot 개수 기본값 1 (잡 .env default 10 → 절감)
TRANSLATE_CHUNK_WORKERS="2"               # chunk 병렬도 (PR#192/#199). "default" → 필드 미전송
TRANSLATE_GUIDELINES_VARIANT_EN=""        # 기본값 default (잡 .env: unified-v2)
TRANSLATE_GUIDELINES_VARIANT_JA=""        # 기본값 default (잡 .env: unified)
ALIGN_V2=1                                # PR#218 v2 모드 (기본 활성)
PLAN_NAME="round1"                        # create-translate-test-pr.sh --plan 값. round1|round2|row-drop-repro|table-suite|markup-churn
TRANSLATE_VIA="api"                       # api = dashboard /api/translate (기본) | local = 모든 단계를 로컬 실행
# ko-review (12~14단계) 실행 여부. plan 별 기본값은 아래 arg 파싱 후 결정 —
# table-suite/row-drop-repro/markup-churn 은 표·마크업 픽스처를 정확히 보존해야
# 하고 (검수 suggestion 이 픽스처를 흔들면 판정이 흐려진다) 검증 대상도 번역
# 로직이라 ko-review 를 태울 이유가 없다. round1 은 종합 plan 이라 유지.
KO_REVIEW_MODE="auto"                     # auto = plan 기본값 | on | off
# 표 행 reconcile (--table-reconcile / --no-table-reconcile 로 translate_pr.py 에
# 전달). 기본 1 = translate_pr.py 기본값(ON) 그대로. 0 으로 끄면 stale 표가
# splice 이전에 복구되지 않아 LLM-patch fallback 경로가 열린다 — row-drop-repro
# 의 reconcile-off 변형이 그 경로를 검증한다. dashboard /api/translate 에는 이
# 필드가 없으므로 **local 모드 전용**이다.
TABLE_RECONCILE=1
VERIFY_MODE="py"                          # py = check_docs_align.py (기본, 결정적·<1초) | fable = 예전 claude -p 검증
TRANSLATE_PIPELINE_BRANCH=""              # translate 잡을 돌릴 cloud-translate multibranch child (빈 값=main)
FROM_ALIGNED=""                            # 이미 align 이 끝난 브랜치에서 세션을 갈라내고 2~9단계를 건너뛴다
# --translate local 이 사용할 cloud-translate 체크아웃/venv. 워크트리를 가리키면
# 미배포 브랜치(예: PR #290 fix/table-sync-repair)의 번역 로직을 그대로 검증할 수 있다.
# 전제: $CLOUD_TRANSLATE_DIR/.env 에 TRANSLATE_GITHUB_TOKEN + TRANSLATE_ANTHROPIC_API_KEY.
CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
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
    --align-v2)      ALIGN_V2=1; shift ;;
    --no-align-v2)   ALIGN_V2=0; shift ;;
    --plan)
      case "${2:-}" in
        round1|round2|row-drop-repro|table-suite|markup-churn) PLAN_NAME="$2" ;;
        *) echo "error: --plan 은 round1|round2|row-drop-repro|table-suite|markup-churn 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --translate)
      case "${2:-}" in
        api|local) TRANSLATE_VIA="$2" ;;
        *) echo "error: --translate 는 api|local 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --verify)
      case "${2:-}" in
        py|fable) VERIFY_MODE="$2" ;;
        *) echo "error: --verify 는 py|fable 만 지원합니다 (got: ${2:-})" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --translate-pipeline-branch)
      TRANSLATE_PIPELINE_BRANCH="$2"; shift 2 ;;   # /api/translate 를 이 cloud-translate 브랜치로 실행
    --table-reconcile)    TABLE_RECONCILE=1; shift ;;   # (기본) 표 행 reconcile 켜기
    --no-table-reconcile) TABLE_RECONCILE=0; shift ;;   # reconcile 끄기 → LLM-patch 경로 노출 (local 전용)
    --ko-review)     KO_REVIEW_MODE="on"; shift ;;       # plan 기본값을 무시하고 ko-review 실행
    --no-ko-review)  KO_REVIEW_MODE="off"; shift ;;      # plan 기본값을 무시하고 ko-review 생략
    --from-aligned)  FROM_ALIGNED="$2"; shift 2 ;;       # align 완료 스냅샷 브랜치 재사용 (2~9단계 skip)
    --base-branch)   BASE_BRANCH="$2"; shift 2 ;;        # 기존 e2e 세션 브랜치 재사용
    --base-source)   BASE_SOURCE_BRANCH="$2"; shift 2 ;; # 새 e2e 브랜치를 갈라낼 원본 (기본 alpha)
    -h|--help) sed -n '3,180p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── ko-review 실행 여부 (plan 기본값) ────────────────────────────────
if [[ "$KO_REVIEW_MODE" == "auto" ]]; then
  case "$PLAN_NAME" in
    table-suite|row-drop-repro|markup-churn) KO_REVIEW_MODE="off" ;;
    *)                                       KO_REVIEW_MODE="on" ;;
  esac
fi

# ── 로컬 실행 모드 (--translate local) ───────────────────────────────
# local 이면 fix-heading-syntax / align / ko-review / translate 네 단계 모두
# $CLOUD_TRANSLATE_DIR 의 스크립트를 직접 실행한다 (dashboard·Jenkins 미사용).
# 각 단계의 인자는 dashboard 핸들러 + Jenkinsfile 이 조립하는 것과 1:1 로
# 맞춰 두었다 — 한쪽만 바뀌면 local 과 api 판정이 갈리므로 함께 고칠 것.
LOCAL_MODE=0
if [[ "$TRANSLATE_VIA" == "local" ]]; then
  LOCAL_MODE=1
  if [[ ! -f "$CLOUD_TRANSLATE_DIR/.env" ]]; then
    echo "error: $CLOUD_TRANSLATE_DIR/.env 가 없습니다 (TRANSLATE_GITHUB_TOKEN / TRANSLATE_ANTHROPIC_API_KEY 필요)" >&2
    exit 1
  fi
  if [[ ! -x "$CLOUD_TRANSLATE_PY" ]]; then
    echo "error: CLOUD_TRANSLATE_PY 가 실행 가능하지 않습니다: $CLOUD_TRANSLATE_PY" >&2
    exit 1
  fi
fi

# --no-table-reconcile 은 dashboard /api/translate 가 노출하지 않는 플래그다.
# api 모드에서 조용히 reconcile ON 으로 도는 것이 최악 — 변형이 검증하려던
# LLM-patch 경로를 안 태우고도 통과해 "검증했다" 는 오판을 남긴다 (markup-churn
# 의 guard-skips 카운터가 같은 함정에 빠진 전례가 있다). 그래서 하드 실패.
if (( ! TABLE_RECONCILE )) && (( ! LOCAL_MODE )); then
  echo "error: --no-table-reconcile 은 --translate local 에서만 지원됩니다." >&2
  echo "       (dashboard /api/translate 에 table_reconcile 필드가 없어 api 모드로는 끌 수 없습니다)" >&2
  exit 1
fi

# local 단계 실행 헬퍼 — cloud-translate 체크아웃에서 python 스크립트를 돌린다.
# 로그는 stdout 으로 흘려 e2e 로그에 인라인으로 남는다 (api 모드의 Jenkins
# 콘솔 대응물). 실패하면 호출자가 exit code 로 처리.
run_local_step() {
  local script="$1"; shift
  echo "    \$ $script $*"
  (cd "$CLOUD_TRANSLATE_DIR" && "$CLOUD_TRANSLATE_PY" "$script" "$@") 2>&1 | sed 's/^/    /'
  return "${PIPESTATUS[0]}"
}

# local 모드에서도 dashboard 자격은 필수다 — 0단계의 webhook 킬 스위치
# (POST /api/webhooks/repos) 는 파이프라인 단계가 아니라 **배포된 파이프라인을
# 억제하는 스위치**라서 local 에서도 반드시 호출해야 한다. 안 끄면 e2e 가 여는
# ko 변형 PR 이 webhook 을 타고 배포 Jenkins 의 ko-review/translate 를 중복
# 트리거하고, local 번역과 배포본 번역이 같은 PR 을 동시에 처리해 결과가 섞인다.
# 토글 실패는 `|| echo ... 계속 진행` 으로 흡수되므로 자격이 없으면 조용히
# 무방비가 된다 — 그래서 여기서 하드 실패시킨다.
if [[ -z "$DASHBOARD_BASE_URL" || -z "$DASHBOARD_API_TOKEN" ]]; then
  echo "error: DASHBOARD_BASE_URL 과 DASHBOARD_API_TOKEN 을 스크립트 상단(또는 env)으로 지정하세요." >&2
  echo "       (--translate local 도 0단계 webhook 비활성화에 dashboard 를 씁니다)" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
# e2e 산출물 PR 에 'e2e' 라벨 (사람이 만든 PR 과 구분)
source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"


tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT

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

echo "[0/17] webhook 비활성화 (번역 e2e 는 webhook 경유 잡 중복 트리거 방지)"
set_webhook_repo_enabled false

SKIP_PROLOGUE=0
if [[ -n "$FROM_ALIGNED" ]]; then
  # align 이 이미 끝난 스냅샷에서 세션을 갈라낸다 — 2~9단계(restore·
  # fix-heading-syntax·align·검증·merge)는 픽스처가 고정이라 plan 마다 결과가
  # 같으므로 suite 안에서 한 번만 돌리면 충분하다 (plan 당 6~8분 절감).
  SKIP_PROLOGUE=1
  BASE_SOURCE_BRANCH="$FROM_ALIGNED"
fi

if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="e2e/$(date -u +%Y%m%d-%H%M%S)"
  echo "[1/17] Creating fresh e2e session branch: $BASE_BRANCH (from origin/$BASE_SOURCE_BRANCH)"
  git fetch origin "$BASE_SOURCE_BRANCH"
  git checkout -B "$BASE_BRANCH" "origin/$BASE_SOURCE_BRANCH"
  git push -u origin "$BASE_BRANCH"
  echo "  E2E_BASE_BRANCH=$BASE_BRANCH"     # wrapper 가 파싱하는 마커
else
  echo "[1/17] Reusing existing base branch: $BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
fi

if (( SKIP_PROLOGUE )); then
  echo
  echo "[2-9/17] skip — 이미 align 된 스냅샷에서 시작 (--from-aligned $FROM_ALIGNED)"
  echo "  E2E_ALIGNED_BRANCH=$FROM_ALIGNED"   # suite 가 다음 plan 에 그대로 넘긴다
else
# ── 2) restore-alpha-origin (내부에서 commit+push) ────────────────────
echo
echo "[2/17] scripts/restore-alpha-origin.sh"
bash "$REPO_ROOT/scripts/restore-alpha-origin.sh"

# ── 3) fix-heading-syntax (heading 문법 정정) ─────────────────────────
# 트리거 직전 open PR 목록을 baseline 으로 저장 (step 4 의 신규 PR 감지용)
gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
  --jq '.[].url' | sort -u > "$tmpdir/fix_before"

if (( LOCAL_MODE )); then
  # 배포된 fix-heading-syntax 잡은 한 빌드에서 두 pass 를 순서대로 돈다
  # (fix_fence.py → fix_heading_syntax.py, 각각 자기 PR 을 연다). 인자는
  # pre-align/Jenkinsfile-fix-heading-syntax 의 조립과 동일: --langs ko,en,ja
  # + --base <세션 브랜치>. LLM 없는 결정론적 regex pass 라 로컬에서도 결과가
  # 같다.
  echo
  echo "[3/17] local fix_fence.py + fix_heading_syntax.py (dir=$CLOUD_TRANSLATE_DIR, base=$BASE_BRANCH)"
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
echo "[3/17] POST $DASHBOARD_BASE_URL/api/fix-heading-syntax (base=$BASE_BRANCH)"

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
  echo "[4/17] local fix_heading_syntax.py 가 만든 PR 감지 (최대 1분 — 이미 생성됨)"
else
  echo "[4/17] fix-heading-syntax 잡이 생성하는 PR 감지 대기 (최대 30분)"
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

# ── 5) restore-aligned-public-api + commit+push ──────────────────────
echo
echo "[5/17] scripts/restore-aligned-public-api.sh"
bash "$REPO_ROOT/scripts/restore-aligned-public-api.sh"

if git diff --quiet && git diff --cached --quiet; then
  echo "  (변경 없음, commit/push 건너뜀)"
else
  git add ko en ja
  git commit -m "restore: aligned public-api.md"
  git push origin "$BASE_BRANCH"
fi

# ── 6) align 트리거 (권장 preset + PR#218 align_v2) ──────────────────
# 트리거 직전 시점 open PR 목록을 baseline 으로 저장 (step 7 의 신규 PR 감지용).
# local 모드는 fix_headings.py 가 동기 실행이라 반환 시점에 PR 이 이미 있으므로
# baseline 을 트리거 **전에** 떠 두어야 한다.
gh pr list --repo "$REPO" --base "$BASE_BRANCH" --state open --json url \
  --jq '.[].url' | sort -u > "$tmpdir/before"

if (( LOCAL_MODE )); then
  # 인자는 /api/align 핸들러가 만드는 params + pre-align/Jenkinsfile 의 opts
  # 조립과 1:1: source=ko, langs=en,ja, base=<세션 브랜치>, 권장 preset
  # (--aligned-marker --demote-extras --translate-headings
  #  --reconcile-unmatched) + --align-v2. engine 은 api 모드에서도 미전송이라
  # (engine="default") 여기서도 넘기지 않는다 → fix_headings.py 기본 엔진.
  echo
  echo "[6/17] local fix_headings.py (dir=$CLOUD_TRANSLATE_DIR, base=$BASE_BRANCH, align_v2=$( ((ALIGN_V2)) && echo true || echo false ))"
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
echo "[6/17] POST $DASHBOARD_BASE_URL/api/align (권장 preset, base=$BASE_BRANCH, align_v2=$( ((ALIGN_V2)) && echo true || echo false ))"

# 권장 preset flags: --aligned-marker --demote-extras --translate-headings --reconcile-unmatched
# PR#218 개선사항:
#   - --align-v2 (opinionated defaults 로 demote-extras/translate-headings 자동 활성,
#     ancestor subtree 재번역 + zero-residual sweep)
#   - --auto-align-v2-below N (기본 5) — Jenkins 잡이 fix_headings.py 를 그대로 호출
#     하므로 명시 파라미터 없이도 자동 escalation 이 동작함
align_v2_json="false"
if (( ALIGN_V2 )); then align_v2_json="true"; fi

align_body=$(cat <<JSON
{
  "target": "$TARGET_URL",
  "base_ref": "$BASE_BRANCH",
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

# ── 7) align PR 감지 (base=alpha 로 새로 open 된 PR) ─────────────────
echo
if (( LOCAL_MODE )); then
  echo "[7/17] local fix_headings.py 가 만든 PR 감지 (최대 1분 — 이미 생성됨)"
else
  echo "[7/17] Jenkins align 잡이 생성하는 PR 감지 대기 (최대 30분)"
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

# ── 8) claude CLI(fable)로 align PR heading·anchor-id 정렬 검사 ───────
echo
echo "[8/17] claude CLI (fable model) heading/anchor-id 정렬 검사 (PR=$align_pr_url)"

head_ref="$(gh pr view "$align_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$head_ref"
check_wt="$tmpdir/pr-check"
git worktree add "$check_wt" "origin/$head_ref" >/dev/null

check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외한 (1) heading level 순서와 (2) anchor id 순서
(<a id="..."></a> 형식과 { #id } 형식 모두)가 세 언어에서 완전히 일치하는지 검사해줘.
파일별 결과를 OK/FAIL 표로 출력하고, FAIL 인 파일은 어긋난 위치와 내용을 설명해줘.
마지막 줄에는 다른 텍스트 없이 전체 판정만 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" 로 출력해.'

if [[ "$VERIFY_MODE" == "py" ]]; then
  # 결정적 검사 (규칙 1·2) — fable agentic 검사와 판정 계약(마지막 줄)이 동일.
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
echo "[9/17] 검증 통과 — align PR 을 $BASE_BRANCH 로 merge"
gh pr merge "$align_pr_url" --repo "$REPO" --merge --delete-branch
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated: $align_pr_url"

# align 이 끝난 상태를 스냅샷 브랜치로 남긴다 — 뒤따르는 plan 들이
# --from-aligned 로 재사용해 2~9단계를 건너뛴다. 세션 브랜치 자체는 이후
# ko 변형·번역 PR 이 머지되며 오염되므로 별도 ref 로 고정해야 한다.
aligned_snapshot="${BASE_BRANCH}-aligned"
git push -f origin "HEAD:refs/heads/$aligned_snapshot"
echo "  E2E_ALIGNED_BRANCH=$aligned_snapshot"
fi

# ── 10) create-translate-test-pr (ko 변형 → translate-test PR 생성) ───
echo
echo "[10/17] scripts/create-translate-test-pr.sh"

create_out="$(bash "$REPO_ROOT/scripts/create-translate-test-pr.sh" --base-branch "$BASE_BRANCH" --plan "$PLAN_NAME")"
echo "$create_out"

# ── 11) ko 변경 PR 생성 확인 ──────────────────────────────────────────
echo
echo "[11/17] ko 변경 PR 생성 확인"

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

# ── 12~14) ko-review (ko 변경 PR 대상 한글 검수 + suggestion accept) ──
# plan 별 기본값: table-suite / row-drop-repro / markup-churn 은 생략.
# 그 세 plan 의 판정 대상은 번역 로직이고, 검수 suggestion 이 표·마크업
# 픽스처를 흔들면 step 17 의 결정론적 판정이 흐려진다. --ko-review 로 강제
# 실행 가능.
if [[ "$KO_REVIEW_MODE" == "off" ]]; then
  echo
  echo "[12-14/17] ko-review 생략 (plan=$PLAN_NAME, KO_REVIEW_MODE=off) — suggestion accept 도 함께 건너뜀"
elif (( LOCAL_MODE )); then
  # 로컬 review_pr.py 직접 실행 — korean-review/Jenkinsfile 의 PR 모드는
  # `python korean-review/review_pr.py <PR URL>` 한 줄이 전부다 (옵션은 잡
  # 파라미터가 default 일 때 미전송). 동기 실행이라 13단계 폴링이 불필요.
  echo
  echo "[12/17] local review_pr.py (dir=$CLOUD_TRANSLATE_DIR, PR=$ko_pr_url)"
  set +e
  run_local_step korean-review/review_pr.py "$ko_pr_url"
  koreview_rc=$?
  set -e
  if (( koreview_rc != 0 )); then
    echo "  local review_pr.py 실패 (exit $koreview_rc)" >&2
    exit 2
  fi
  echo
  echo "[13/17] (local 실행이라 잡 완료 폴링 불필요)"
else
echo
echo "[12/17] POST $DASHBOARD_BASE_URL/api/ko-review (PR=$ko_pr_url)"

koreview_body=$(cat <<JSON
{
  "pr_url": "$ko_pr_url"
}
JSON
)

koreview_resp="$(curl -sS -X POST \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$koreview_body" \
  "$DASHBOARD_BASE_URL/api/ko-review")"

echo "$koreview_resp" | python3 -m json.tool

koreview_job_id=$(printf '%s' "$koreview_resp" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("job_id") or "")')

if [[ -z "$koreview_job_id" ]]; then
  echo "  error: /api/ko-review 응답에서 job_id 를 찾지 못했습니다." >&2
  exit 2
fi

# ── 13) ko-review 완료 대기 ──────────────────────────────────────────
echo
echo "[13/17] ko-review 완료 대기 (job_id=$koreview_job_id, 최대 30분)"

poll_left=180  # 1800s 상당 (10s x 180) — 반복 횟수 기반 폴링: suspend 로 wall clock 이 지나가도 타임아웃 오판하지 않는다 (2026-08-15~16 spurious exit-2 실측)
koreview_status=""
while (( poll_left-- > 0 )); do
  # 주의: set -eo pipefail 아래라 폴링 curl 의 일시 오류(empty reply 등)가
  # 스크립트 전체를 죽인다 (2026-07-29 run 실측: curl 52 로 step 13 중단) —
  # 재시도 + `|| true` 로 흡수하고, 빈 응답은 status="" 로 계속 폴링한다.
  koreview_status="$(curl -sS --retry 3 --retry-delay 5 \
    -H "Authorization: Bearer $DASHBOARD_API_TOKEN" \
    "$DASHBOARD_BASE_URL/api/jobs/$koreview_job_id" 2>/dev/null \
    | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  tasks=(d.get("job") or {}).get("tasks") or []
  print(tasks[0].get("status") if tasks else "")
except Exception:
  print("")' || true)"
  case "$koreview_status" in
    success|failure|cancelled|partial) break ;;
  esac
  sleep 10
done

if [[ "$koreview_status" != "success" ]]; then
  echo "  ko-review 실패 (status=$koreview_status, job_id=$koreview_job_id)" >&2
  exit 2
fi
echo "  ko-review 완료"
fi

# ── 14) ko 변경 PR suggestion 검증 및 전체 accept ─────────────────────
if [[ "$KO_REVIEW_MODE" != "off" ]]; then
echo
echo "[14/17] ko 변경 PR suggestion 검증 및 accept (PR=$ko_pr_url)"

ko_pr_number="$(gh pr view "$ko_pr_url" --repo "$REPO" --json number --jq .number)"
ko_head_ref_for_suggest="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"

# 리뷰 코멘트 (inline) 를 모두 조회 → ```suggestion 블록 개수 확인
gh api "repos/$REPO/pulls/$ko_pr_number/comments" --paginate > "$tmpdir/pr_comments.json"

n_suggestions=$(PR_COMMENTS_FILE="$tmpdir/pr_comments.json" python3 -c '
import json, os, re
cs=json.load(open(os.environ["PR_COMMENTS_FILE"]))
print(sum(1 for c in cs if re.search(r"```suggestion", c.get("body") or "")))
')

if (( n_suggestions == 0 )); then
  echo "  error: ko-review 가 suggestion 을 남기지 않았습니다 (1개 이상 예상)" >&2
  exit 3
fi
echo "  detected suggestions: $n_suggestions"

# ko PR head 브랜치를 detached worktree 로 체크아웃 → 파일별 line 역순 정렬 적용 → commit + push
# (메인 워크트리가 같은 브랜치를 이미 checkout 한 상태라 -B 로는 충돌; detach 로 회피)
git fetch --quiet origin "$ko_head_ref_for_suggest"
apply_wt="$tmpdir/apply-suggestions"
git worktree add --detach "$apply_wt" "origin/$ko_head_ref_for_suggest" >/dev/null

PR_COMMENTS_FILE="$tmpdir/pr_comments.json" APPLY_WT="$apply_wt" python3 - <<'PYEOF'
import json, os, re
from collections import defaultdict

cs = json.load(open(os.environ["PR_COMMENTS_FILE"]))
by_file = defaultdict(list)
for c in cs:
    body = c.get("body") or ""
    m = re.search(r"```suggestion\n(.*?)```", body, flags=re.DOTALL)
    if not m:
        continue
    path = c.get("path")
    line = c.get("line") or c.get("original_line")
    start = c.get("start_line") or c.get("original_start_line") or line
    if not (path and line and start):
        continue
    by_file[path].append({"start": start, "end": line, "content": m.group(1)})

wt = os.environ["APPLY_WT"]
applied = 0
for path, items in by_file.items():
    fpath = os.path.join(wt, path)
    if not os.path.isfile(fpath):
        print(f"  skip (no such file): {path}")
        continue
    items.sort(key=lambda x: x["start"], reverse=True)
    with open(fpath, "r", encoding="utf-8") as f:
        lines = f.readlines()
    for it in items:
        s = it["start"] - 1
        e = it["end"]
        new = it["content"]
        if not new.endswith("\n"):
            new += "\n"
        new_lines = new.splitlines(keepends=True)
        lines[s:e] = new_lines
        applied += 1
    with open(fpath, "w", encoding="utf-8") as f:
        f.writelines(lines)
print(f"  applied files: {len(by_file)}, suggestions applied: {applied}")
PYEOF

pushd "$apply_wt" >/dev/null
git add -A
if git diff --cached --quiet; then
  echo "  변경 없음 (suggestion diff 매칭 실패 또는 이미 적용됨)"
else
  git commit -m "ko-review: accept $n_suggestions suggestion(s)"
  # detached HEAD → 원격 브랜치로 직접 push
  git push origin "HEAD:refs/heads/$ko_head_ref_for_suggest"
  echo "  suggestions committed & pushed to $ko_head_ref_for_suggest"
fi
popd >/dev/null
git worktree remove "$apply_wt" --force

# 메인 워크트리도 suggestion 반영본으로 최신화 (step 15 translate 트리거 전)
git fetch --quiet origin "$ko_head_ref_for_suggest"
git reset --hard "origin/$ko_head_ref_for_suggest"
fi

# ── 15) ko 변경 PR (suggestion 반영본) 번역 실행 ─────────────────────
trans_pr_url=""
if [[ "$TRANSLATE_VIA" == "local" ]]; then
  # 로컬 cloud-translate 체크아웃의 translate_pr.py 를 직접 실행 — 배포된
  # dashboard/Jenkins 잡 대신 로컬 브랜치(예: PR #290)의 번역 로직을 검증.
  # 플래그는 dashboard 권장 preset 과 동일; engine/model 은 CLI 플래그가
  # 없으므로 env 로 고정 (api + haiku = 기존 e2e run 과 동일 조건).
  echo
  echo "[15/17] local translate_pr.py (dir=$CLOUD_TRANSLATE_DIR, PR=$ko_pr_url, engine=api, model=claude-haiku-4-5, table_reconcile=$( ((TABLE_RECONCILE)) && echo on || echo off ))"
  if [[ ! -f "$CLOUD_TRANSLATE_DIR/.env" ]]; then
    echo "error: $CLOUD_TRANSLATE_DIR/.env 가 없습니다 (TRANSLATE_GITHUB_TOKEN / TRANSLATE_ANTHROPIC_API_KEY 필요)" >&2
    exit 1
  fi
  local_log="$tmpdir/local_translate.log"
  # reconcile-off 변형: stale 표를 splice 이전에 복구하지 않으므로 행 splice 의
  # 1:1 가드가 깨지고 full 로 떨어지며, skip-full-table 가드가 그 문서를 제외
  # 하려다 LLM-patch fallback 을 태운다 — 그 경로가 이 변형의 검증 대상이다.
  reconcile_opt=()
  if (( ! TABLE_RECONCILE )); then reconcile_opt=(--no-table-reconcile); fi
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    TRANSLATE_TRANSLATE_ENGINE=api \
    TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5 \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
      --diff-granularity block --glossary-mode service --max-load-ratio 2 \
      --workers 2 --chunk-workers 2 --tm-top-k 1 \
      --table-rows --skip-full-table --skip-anchor-only \
      --assign-anchors --align-headings --llm-patch-fallback \
      --fix-korean-leftover "${reconcile_opt[@]}" \
  ) 2>&1 | tee "$local_log"
  # ↑ --fix-korean-leftover: 표 헤더/짧은 조각 재번역 시 간헐적으로 남는 한글
  #   잔류(결함 C — 예: ja 헤더 `판교`)를 커밋 전에 스캔·수정. step 17 의
  #   rule (5) 한글 잔류 검사와 짝. dashboard API 는 이 옵션을 아직 노출하지
  #   않으므로 --translate api 실행은 결함 C 로 rule (5) FAIL 이 날 수 있다.
  local_rc=${PIPESTATUS[0]}
  set -e
  if (( local_rc != 0 )); then
    echo "  local translate_pr.py 실패 (exit $local_rc) — 로그: $local_log" >&2
    exit 2
  fi
  # 번역 PR 은 이미 생성된 상태 — step 16 의 gh 폴링이 즉시 감지한다.
else
echo
echo "[15/17] POST $DASHBOARD_BASE_URL/api/translate (권장 preset, PR=$ko_pr_url, engine=${TRANSLATE_ENGINE:-default}, model=${TRANSLATE_MODEL:-default}, tm_top_k=${TRANSLATE_TM_TOP_K:-default}, chunk_workers=${TRANSLATE_CHUNK_WORKERS:-default}, gv_en=${TRANSLATE_GUIDELINES_VARIANT_EN:-default}, gv_ja=${TRANSLATE_GUIDELINES_VARIANT_JA:-default})"

# --engine 옵션이 지정된 경우에만 engine 필드 포함
engine_json=""
if [[ -n "$TRANSLATE_ENGINE" ]]; then
  engine_json="\"engine\": \"$TRANSLATE_ENGINE\","
fi

# --model 값이 설정된 경우에만 model 필드 포함 (default 는 서버가 결정)
model_json=""
if [[ -n "$TRANSLATE_MODEL" ]]; then
  model_json="\"model\": \"$TRANSLATE_MODEL\","
fi

# --tm-top-k 값이 설정된 경우에만 tm_top_k 필드 포함
tm_top_k_json=""
if [[ -n "$TRANSLATE_TM_TOP_K" ]]; then
  tm_top_k_json="\"tm_top_k\": \"$TRANSLATE_TM_TOP_K\","
fi

# PR#192/#199 개선: chunk_workers 로 한 파일 안 chunk 병렬 API 호출 exercise
chunk_workers_json=""
if [[ -n "$TRANSLATE_CHUNK_WORKERS" ]]; then
  chunk_workers_json="\"chunk_workers\": \"$TRANSLATE_CHUNK_WORKERS\","
fi

# PR#199 개선: guidelines_variant 로 en/ja 가이드라인 크기 조절 (input 토큰 절감)
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
# PR#207/#211 (within/cross-opcode batching) 은 자동 활성 — 별도 설정 없음.
# PR#220 (api-guide dedup) 은 파일명 substring 매치 (기본 "api-guide"). Agent-Test
# 는 "public-api.md" 라 자동 미매치 — 대시보드에 dedup path override API 는 없음.
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

# ── 16) 번역 PR 감지 대기 (base = ko PR head 브랜치) ──────────────────
ko_head_ref="$(gh pr view "$ko_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"

if [[ -z "$trans_pr_url" ]]; then
  echo
  echo "[16/17] translate 잡이 생성하는 번역 PR 감지 대기 (최대 60분)"

  poll_left=180  # 3600s 상당 (20s x 180) — 반복 횟수 기반 폴링: suspend 로 wall clock 이 지나가도 타임아웃 오판하지 않는다 (2026-08-15~16 spurious exit-2 실측)
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
else
  echo
  echo "[16/17] 번역 PR 확인 (local 실행 출력에서 획득): $trans_pr_url"
fi

if [[ -z "$trans_pr_url" ]]; then
  echo "  timeout: 60분 내 번역 PR 을 감지하지 못했습니다." >&2
  exit 2
fi

# ── 17) claude CLI(fable)로 번역 PR 검증 → 결과를 PR 댓글로 등록 ───────
echo
echo "[17/17] claude CLI (fable model) 번역 PR 검증 (PR=$trans_pr_url)"

trans_head_ref="$(gh pr view "$trans_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch origin "$trans_head_ref"
trans_wt="$tmpdir/trans-check"
git worktree add "$trans_wt" "origin/$trans_head_ref" >/dev/null

trans_check_prompt='ko/, en/, ja/ 세 폴더에 공통으로 존재하는 .md 문서 각각에 대해,
fenced code block(```)을 제외하고 다음 여섯 가지를 검사해줘.
(1) heading level 순서가 세 언어에서 일치
(2) anchor id 순서가 세 언어에서 일치 (<a id="..."></a> 형식과 { #id } 형식 모두)
(3) 표(table)가 있으면 표 개수와 각 표의 데이터 행(row) 개수가 세 언어에서 일치
    — 표 직후에 빈 줄로 분리된 고아 표 행(| ... | 형태)이 있으면 그것도 FAIL 로 보고
(4) 표의 데이터 행 중 첫 셀이 언어 무관 식별자인 행들의 식별자 집합과 등장 순서가
    세 언어에서 일치. 식별자 = 공백 없이 라틴 문자/숫자/._+- 로만 구성된 버전/코드
    토큰 (예: 1.202602.1, 2.4.1, v1.35, INST-CREATE). CJK 문자(한글·한자·가나)가
    섞인 셀은 번역된 텍스트이므로 식별자가 아니다 (예: u2タイプ, 기본). 식별자는
    번역되지 않으므로 세 언어에서 동일해야 하고, 한 언어에서만 빠졌으면 행 유실,
    한 언어에서만 순서가 다르면 행 순서 불일치다.
(5) en/, ja/ 문서 본문에 한글 음절이 남아 있으면 안 된다 (fenced code block 과
    inline code(`...`) 안은 제외) — 남아 있으면 미번역 잔류(leak)로 FAIL.
(6) 각 언어 문서 안에서, 표의 모든 행(헤더·구분선·데이터)의 셀 개수가 그 표의
    헤더 셀 개수와 동일해야 한다 — 헤더보다 셀이 많거나 적은 데이터 행이 하나라도
    있으면 컬럼 혼재로 FAIL (렌더러가 헤더 초과 셀을 버려 그 셀 내용이 배포
    화면에서 소실된다). 단, 같은 표의 컬럼 수가 세 언어 사이에서 서로 다른 것
    자체는 FAIL 이 아니다 — 컬럼 스키마가 다른 target 표를 target 스키마대로
    유지·번역하는 것은 정상 동작이다.
파일별 결과를 OK/FAIL 표로 출력하고 (표 개수·행 수 포함), FAIL 인 파일은 어긋난 위치와 내용을 설명해줘.
마지막 줄에는 다른 텍스트 없이 전체 판정만 "ALIGNMENT: OK" 또는 "ALIGNMENT: FAIL" 로 출력해.'

if [[ "$VERIFY_MODE" == "py" ]]; then
  # 결정적 검사 (규칙 1~6, markup-churn 은 +7) — 위 fable 프롬프트와 1:1.
  py_verify_args=(--root "$trans_wt" --mode translate)
  [[ "$PLAN_NAME" == "markup-churn" ]] && py_verify_args+=(--markup)
  set +e
  trans_check_out="$(python3 "$REPO_ROOT/scripts/check_docs_align.py" "${py_verify_args[@]}")"
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
  verdict_line="✅ 번역 PR 자동 검증 통과 (heading·anchor-id·표 행 수·표 셀 수 일치)"
else
  verdict_line="❌ 번역 PR 자동 검증 실패 — 아래 상세 결과를 확인하세요"
fi

cat > "$tmpdir/trans_comment.md" <<EOF
## 번역 PR 자동 검증 결과 (claude CLI, fable)

$verdict_line

- 검증 브랜치: \`$trans_head_ref\`
- 검증 항목: ko/en/ja heading level 순서 · anchor id 순서 · 표 개수/행 수 · 표 내부 셀 수 일관성

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

# 검증 통과 → 번역 PR 을 ko PR head 브랜치로 merge → ko PR 을 alpha 로 merge
echo
echo "검증 통과 — 번역 PR merge: $trans_pr_url (base=$ko_head_ref)"
gh pr merge "$trans_pr_url" --repo "$REPO" --merge --delete-branch
echo "  merged: $trans_pr_url"

echo
echo "ko 변경 PR merge: $ko_pr_url (base=$BASE_BRANCH)"
gh pr merge "$ko_pr_url" --repo "$REPO" --merge --delete-branch
git fetch origin "$BASE_BRANCH"
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"
echo "  merged & local $BASE_BRANCH updated: $ko_pr_url"

echo
echo "완료."
