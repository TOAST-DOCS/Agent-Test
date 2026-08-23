#!/usr/bin/env bash
#
# e2e 전체 suite 러너 — 여러 plan 을 순차 실행하고 결과를 요약한다.
#
#   scripts/e2e-suite.sh [--translate api|local] [--engine api|cli] [--model haiku|sonnet|opus] \
#                        [--verify py|fable] [--no-reuse-align] \
#                        [--translate-pipeline-branch <jenkins-child>] \
#                        [--sleep-between <sec>] [plan ...]
#
#   --sleep-between <sec> — plan 과 plan 사이 대기 (기본 0). Jenkins agent 의
#       claude CLI (OAuth) 가 연속 실행으로 usage limit 에 걸려 align/ko-review
#       가 무더기 is_error 로 무너지는 것(2026-08-13 08:15Z 실측: align build
#       324=에러0 → 325/326=에러84)을 피하려면 3600(1시간) 권장. 마지막 plan
#       뒤에는 자지 않는다.
#
# plan 미지정 시 기본: webhook round1 table-suite markup-churn
#   webhook     — GitHub webhook 라우팅 검증. base=alpha 로 PR 을 열어
#                 pull_request/opened → Jenkins ko-review, PR merge →
#                 pull_request/closed → Jenkins translate 트리거를 dashboard
#                 /api/jobs 로 확인. 다른 plan 과 달리 e2e-align-and-translate.sh
#                 가 아니라 e2e-webhook.sh 를 실행. 기대: exit 0.
#                 ~1분. base=alpha 를 직접 쓰므로 매 실행마다 alpha 에 마커
#                 커밋 1개가 추가되지만 restore-alpha-origin 이 다음 e2e 에서
#                 정리한다.
#   korean-review — dashboard /api/ko-review 잡의 산출물(요약 리뷰 본문 규격,
#                 인라인 코멘트, ```suggestion``` 블록) 을 검증. e2e-align-and-
#                 translate.sh 가 아니라 e2e-korean-review.sh 를 실행.
#                 세션 브랜치에서 ko 변형 PR 하나만 만들고 검수 잡을 태워
#                 결과 리뷰의 구조 + fable 의미 품질을 확인 (align/translate
#                 단계는 건너뜀). 기대: exit 0. ~15~30분.
#   row-drop-repro — cloud-translate PR #283 회귀 최소 재현. version-guide.md 의
#                 en/ja 가 `1.202602.1` 행을 결여한 stale 상태를 base 브랜치에
#                 stale-ify 커밋으로 조성한 뒤, 이웃 문단만 짧게 수정해
#                 load/ko-diff 비율 cap 초과 → LLM-patch fallback 경로를 태운다.
#                 대조군으로 overview.md 에 정상 문단 추가. 결함 상태에서는
#                 en/ja 가 stale 행을 유지(FAIL), 수정 배포 후에는 backfill
#                 또는 todo-stub 으로 해소(exit 0). exit 3 도 정상 허용.
#   row-drop-repro-noreconcile
#               — 위와 같은 ko 픽스처를 **표 행 reconcile OFF** 로 돌리는 변형
#                 (--no-table-reconcile). reconcile 이 켜져 있으면 stale 행이
#                 splice 이전에 backfill 되어 부하가 cap 아래로 떨어지고
#                 **LLM-patch fallback 경로에 아예 도달하지 못한다** (2026-08-23
#                 실측: 8 plan 전체 LLM-patch 0건). 끄면 행 splice 의 1:1 가드가
#                 깨져 full 로 떨어지고 skip-full-table 가드가 그 문서를
#                 제외하려다 LLM-patch fallback 을 태운다 — 그 경로가 검증 대상.
#                 dashboard /api/translate 에 table_reconcile 필드가 없어
#                 **--translate local 전용** (api 모드와 함께 주면 하드 실패).
#                 판정: exit 0/3 허용, 단 로그에 LLM-patch fallback 이 0건이면
#                 suite 실패 — 경로를 안 태운 실행은 검증한 게 없으므로.
#   concurrent  — 같은 ko 파일을 만지는 동시 PR 시나리오 (e2e-concurrent-prs.sh).
#                 A 생성 → B 생성 → B 머지·번역·번역 머지 → A 머지 → A 번역
#                 순서에서, A 번역이 B 의 신규 섹션·표 행을 지우지 않는지
#                 검증 (merge-commit ref 결함). 다른 plan 과 달리 dashboard/
#                 Jenkins 를 쓰지 않고 **항상 로컬 translate_pr.py** 로 번역
#                 하므로 --translate api 를 줘도 로컬 실행이다 (CLOUD_TRANSLATE_DIR,
#                 기본 ~/works/cloud-translate). 기대: exit 0 (RESULT: PASS).
#                 exit 1 = B 콘텐츠 유실(버그 재현), 2 = 하네스 오류.
#   round1      — 일반 종합 (heading/anchor/섹션/문단/표 기본 변형 15항목).
#                 기대: exit 0 (전 파일 PASS).
#   table-suite — 표 변형 종합 + stale 결함 재현 (stale-ify 커밋 포함).
#                 기대: 번역 로직에 table-row reconcile(PR #290)이 있으면 exit 0,
#                 없으면 exit 3 (version-guide/release-notes FAIL).
#   markup-churn— 코스메틱 마크업 churn(펜스 info string, <br/>, 헤딩 뒤 빈 줄,
#                 Jinja 태그 whitespace 제어) + 소수 내용 변경. load guard 가
#                 정상 리뷰 PR 을 runaway 로 오판해 파일을 제외하던 것을 재현
#                 (Storage-Object-Storage#181/#185, Storage-Online-NAS#92).
#                 기대: exit 0 **이고** 로그에 load guard skip 이 0건.
#                 exit code 만으로는 판별되지 않는다 — 미러링이 없어도 일부
#                 파일은 floor 아래라 통과해 PR 이 만들어지기 때문. 그래서 이
#                 러너가 로그에서 mirrored=/guard-skips= 를 세어 verdict 에 붙이고,
#                 guard-skips 가 0 이 아니면 suite 실패로 잡는다. 단 그 두
#                 카운터는 --translate local 에서만 의미가 있다 (api 모드는
#                 번역 로그가 Jenkins 쪽) — api 모드의 실제 증거는 번역 PR
#                 본문의 "제외된 파일" 섹션이라 pr-excl= 로 따로 센다.
#                 구조적으로는 checker 규칙 (7) 이 "ko 에 맨몸 <br> 이 0 인데
#                 en/ja 에 남아있으면 FAIL" 로 미러링 미동작을 직접 잡는다.
#                 기본 plan 집합에 포함된다.
#   retranslate — public-api.md 전체 재번역 변형 (e2e-retranslate-align-and-
#                 translate.sh). /api/translate/file (DIFF_MODE=full) 경로 검증 —
#                 다른 plan 이 커버하지 않는 유일한 API. --translate local 이면
#                 그 단계도 로컬 translate_file.py (--commit-to-branch,
#                 TRANSLATE_DIFF_MODE=full) 로 실행된다. 기대: exit 0.
#   round2      — 전제 조건(직전 round1 의 ko/번역 PR 이 base 에 머지되어 있음)이
#                 필요해 suite 기본/all 에서 제외. 명시 지정 시에만 실행.
#
# 별칭:
#   all         — round2 를 제외한 실행 가능한 plan 전체
#                 = webhook korean-review round1 table-suite row-drop-repro
#                   row-drop-repro-noreconcile markup-churn retranslate concurrent
#                 round2 는 round1 후처리(수동 머지)가 필요해 제외 —
#                 필요하면 명시적으로 `scripts/e2e-suite.sh all round2` 로 이어붙임.
#
# 각 plan 은 자체 e2e 세션 브랜치(e2e/<ts>)에서 돌므로 서로 간섭하지 않지만,
# 같은 작업 트리를 쓰므로 반드시 순차 실행 (이 러너가 보장). 개별 실행 로그는
# /tmp/e2e-suite-<ts>/<plan>.log 에 남는다.
#
# --translate local 이면 **모든 단계**를 CLOUD_TRANSLATE_DIR (기본
# ~/works/cloud-translate) 의 스크립트로 실행한다 — 미머지 브랜치 검증용.
# 단계별 로컬 대응물:
#   fix-heading-syntax → pre-align/fix_fence.py + pre-align/fix_heading_syntax.py
#   align              → pre-align/fix_headings.py
#   ko-review          → korean-review/review_pr.py
#   translate          → translate/translate_pr.py
#   translate/file     → translate/translate_file.py (retranslate plan)
# **webhook plan 만 예외** — GitHub webhook → 배포된 webhook pod → Jenkins 라는
# 배포 경로 자체가 검증 대상이라 로컬 대응물이 없다. concurrent plan 은 원래부터
# 항상 로컬 translate_pr.py 다.
# 그리고 local 모드도 dashboard 를 **한 곳** 쓴다 — 각 plan 0단계의 webhook 킬
# 스위치 (POST /api/webhooks/repos). 파이프라인 단계가 아니라 배포된 파이프라인이
# 같은 ko 변형 PR 을 동시에 처리하지 않게 막는 스위치라서 local 에서 더 중요하다.
# 그래서 local 모드도 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필수다.
# 사전 준비(.env, 워크트리)는 e2e-align-and-translate.sh 헤더 및
# /verify-translate-e2e 참고.
#
# **ko-review 는 table-suite / row-drop-repro / markup-churn 에서 생략된다**
# (e2e-align-and-translate.sh 의 plan 별 기본값). 그 세 plan 의 판정 대상은 번역
# 로직이고, 검수 suggestion 이 표·마크업 픽스처를 흔들면 17단계의 결정론적 판정이
# 흐려진다. round1 은 종합 plan 이라 유지하고, korean-review plan 은 검수 자체가
# 검증 대상이다. 개별 실행 시 --ko-review 로 되돌릴 수 있다.
#
# ── 실행 시간 ────────────────────────────────────────────────────────
# align 프롤로그(2~9단계: restore → fix-heading-syntax → align → 검증 → merge)
# 는 픽스처가 고정이라 plan 마다 같은 결과가 나온다. 그래서 이 러너는 **첫
# align 기반 plan 에서만** 그 단계를 돌리고, 그 결과 스냅샷 브랜치
# (`E2E_ALIGNED_BRANCH=<session>-aligned`) 를 이후 plan 에 --from-aligned 로
# 넘겨 6~8분/plan 을 줄인다. plan 별 세션 브랜치는 여전히 따로 생성되므로
# 서로 간섭하지 않는다. --no-reuse-align 이면 plan 마다 프롤로그를 다시 돈다
# (align/fix-heading-syntax 잡 자체를 여러 번 태우고 싶을 때).
#
# --translate-pipeline-branch <name> 이면 translate 잡을 cloud-translate 의
# Jenkins multibranch child <name> (예: PR-532) 에서 돌린다 — 미머지 PR 의 번역
# 로직을 배포 없이 Jenkins 경로로 검증할 때. align/fix-heading-syntax/ko-review
# 잡과 webhook plan 은 그대로 main 에서 돈다. concurrent plan 은 로컬
# translate_pr.py 를 쓰므로 대신 CLOUD_TRANSLATE_DIR 을 그 브랜치의 워크트리로
# export 해야 같은 코드를 태운다.
#
# 구조 검증(8·17단계)은 scripts/check_docs_align.py 가 결정적으로 수행한다
# (예전 `claude -p --model fable` agentic 검사 대비 plan 당 30~40분 절감).
# --verify fable 로 예전 방식으로 되돌릴 수 있다.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PASS_ARGS=()
EM_ARGS=()   # retranslate 로 넘길 인자 (--engine/--model/--verify/--translate)
KR_ARGS=()   # korean-review 로 넘길 인자 (--translate 만 의미 있음)
PLANS=()
SLEEP_BETWEEN=0
REUSE_ALIGN=1     # align 프롤로그(2~9단계) 를 첫 plan 에서만 돌리고 재사용
ALIGNED_BRANCH="" # 그 스냅샷 브랜치 (첫 align 기반 plan 의 로그에서 파싱)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sleep-between)
      SLEEP_BETWEEN="$2"; shift 2 ;;
    --engine|--model|--verify)
      PASS_ARGS+=("$1" "$2"); EM_ARGS+=("$1" "$2"); shift 2 ;;
    --no-reuse-align)
      REUSE_ALIGN=0; shift ;;
    --translate-pipeline-branch)
      # translate 잡만 특정 cloud-translate 브랜치에서 — align/retranslate 양쪽에 전달
      PASS_ARGS+=("$1" "$2"); EM_ARGS+=("$1" "$2"); shift 2 ;;
    --translate)
      # local = 모든 단계를 로컬 실행 (webhook plan 만 예외 — 배포 경로 자체를
      # 검증하는 plan 이라 로컬 대응물이 없다). 세 스크립트에 모두 전달.
      PASS_ARGS+=("$1" "$2"); EM_ARGS+=("$1" "$2"); KR_ARGS+=("$1" "$2"); shift 2 ;;
    --tm-top-k|--chunk-workers)
      PASS_ARGS+=("$1" "$2"); shift 2 ;;
    webhook|korean-review|round1|round2|row-drop-repro|row-drop-repro-noreconcile|table-suite|markup-churn|retranslate|concurrent)
      PLANS+=("$1"); shift ;;
    all)
      # round2 는 round1 후 수동 머지가 전제라 all 에서 제외 — 필요하면
      # `scripts/e2e-suite.sh all round2` 처럼 뒤에 명시적으로 이어붙인다.
      PLANS+=(webhook korean-review round1 table-suite row-drop-repro
              row-drop-repro-noreconcile markup-churn retranslate concurrent); shift ;;
    -h|--help) sed -n '3,139p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (plan 이름/all 또는 --translate/--engine/--model...)" >&2; exit 1 ;;
  esac
done
# 사용자가 all + 특정 plan 을 같이 준 경우 중복 제거 (첫 등장 순서 유지).
if (( ${#PLANS[@]} )); then
  _dedup=(); declare -A _seen=()
  for p in "${PLANS[@]}"; do
    [[ -n "${_seen[$p]:-}" ]] && continue
    _seen[$p]=1; _dedup+=("$p")
  done
  PLANS=("${_dedup[@]}")
fi
(( ${#PLANS[@]} )) || PLANS=(webhook round1 table-suite markup-churn)

ts="$(date +%Y%m%d-%H%M%S)"
outdir="/tmp/e2e-suite-$ts"
mkdir -p "$outdir"

declare -a RESULTS=()
overall=0
first_plan=1
for plan in "${PLANS[@]}"; do
  if (( first_plan )); then
    first_plan=0
  elif (( SLEEP_BETWEEN > 0 )); then
    echo "=== ${SLEEP_BETWEEN}s 대기 (--sleep-between; claude CLI usage limit 회복) — $(date '+%H:%M:%S') 부터"
    sleep "$SLEEP_BETWEEN"
  fi
  log="$outdir/$plan.log"
  echo "=== [$plan] 시작 → $log"
  if [[ "$plan" == "retranslate" ]]; then
    # 전체 재번역 변형 — 자체 스크립트. dashboard API 전용이라 --translate
    # 등은 전달하지 않고 --engine/--model 만 넘긴다.
    bash "$REPO_ROOT/scripts/e2e-retranslate-align-and-translate.sh" \
      "${EM_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^ALIGNMENT: (OK|FAIL)' "$log" | tail -n1 || true)"
    trans_pr="$(grep -oE 'detected translation PR: https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  elif [[ "$plan" == "webhook" ]]; then
    # webhook plan 은 별도 스크립트 — --plan 이 아니라 자체 args. PASS_ARGS 는
    # translate/engine/model 계열이라 webhook 에는 의미 없어 전달하지 않음.
    bash "$REPO_ROOT/scripts/e2e-webhook.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '(opened → ko-review triggered.*|merged → translate triggered.*)$' "$log" | tr '\n' ';' | sed 's/;$//' || true)"
    trans_pr="$(grep -oE '^\s*PR\s+:\s+https://[^ ]+' "$log" | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  elif [[ "$plan" == "concurrent" ]]; then
    # 동시 PR 시나리오 — dashboard 를 쓰지 않고 로컬 translate_pr.py 로만
    # 번역하므로 translate/engine/model 계열 인자는 의미가 없다.
    bash "$REPO_ROOT/scripts/e2e-concurrent-prs.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^RESULT: (PASS|FAIL).*' "$log" | tail -n1 || true)"
    trans_pr="$(grep -oE '^  A 번역 PR:\s+https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  elif [[ "$plan" == "korean-review" ]]; then
    # korean-review plan 은 별도 스크립트 — /api/ko-review 잡을 태우고
    # 결과 리뷰 규격 + fable 의미 검증. --engine/--model 은 korean-review
    # 잡의 파라미터가 아니라 전달하지 않는다.
    bash "$REPO_ROOT/scripts/e2e-korean-review.sh" "${KR_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^KO_REVIEW: (OK|FAIL)' "$log" | tail -n1 || true)"
    ko_pr="$(grep -oE '  ko PR         : https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${ko_pr:-<no-pr>}")
  else
    # align 프롤로그 재사용: 앞선 plan 이 남긴 스냅샷이 있으면 2~9단계를 건너뛴다.
    reuse_args=()
    if (( REUSE_ALIGN )) && [[ -n "$ALIGNED_BRANCH" ]]; then
      reuse_args+=(--from-aligned "$ALIGNED_BRANCH")
      echo "    (align 프롤로그 재사용: --from-aligned $ALIGNED_BRANCH)"
    fi
    # row-drop-repro-noreconcile 은 같은 ko 픽스처를 reconcile OFF 로 돌리는
    # 변형이다 — 별도 plan 이름이지만 create-translate-test-pr.sh 에는
    # row-drop-repro 로 넘어간다.
    plan_arg="$plan"
    variant_args=()
    if [[ "$plan" == "row-drop-repro-noreconcile" ]]; then
      plan_arg="row-drop-repro"
      variant_args+=(--no-table-reconcile)
    fi
    bash "$REPO_ROOT/scripts/e2e-align-and-translate.sh" \
      --plan "$plan_arg" "${PASS_ARGS[@]}" "${reuse_args[@]}" \
      "${variant_args[@]}" > "$log" 2>&1
    ec=$?
    if (( REUSE_ALIGN )) && [[ -z "$ALIGNED_BRANCH" ]]; then
      ALIGNED_BRANCH="$(grep -oE 'E2E_ALIGNED_BRANCH=[^ ]+' "$log" | tail -n1 | cut -d= -f2 || true)"
      [[ -n "$ALIGNED_BRANCH" ]] && echo "    (align 스냅샷 확보: $ALIGNED_BRANCH — 이후 plan 이 재사용)"
    fi
    verdict="$(grep -oE '^ALIGNMENT: (OK|FAIL)' "$log" | tail -n1 || true)"
    trans_pr="$(grep -oE 'detected translation PR: https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    if [[ "$plan" == "row-drop-repro-noreconcile" ]]; then
      # 이 변형의 존재 이유는 **LLM-patch fallback 경로를 실제로 태우는 것**이다.
      # exit code 만으로는 그걸 알 수 없다 — reconcile 이 어쩌다 켜져 있거나
      # 픽스처가 부하 임계에 못 미치면 경로를 안 타고도 통과한다 (markup-churn 의
      # guard-skips 가 정확히 그 함정에 빠졌던 전례).  그래서 로그에서 직접 센다.
      rd_patch="$(grep -c 'LLM-patch fallback' "$log" 2>/dev/null || true)"
      rd_skipfull="$(grep -c 'skip-full-table: .*skipped —' "$log" 2>/dev/null || true)"
      rd_stub="$(grep -cE 'table todo-stub|<todo: translate>' "$log" 2>/dev/null || true)"
      verdict="${verdict:-<no-verdict>} llm-patch=${rd_patch:-0} skip-full-table=${rd_skipfull:-0} todo-stub=${rd_stub:-0}"
    fi
    if [[ "$plan" == "markup-churn" ]]; then
      # ALIGNMENT 만으로는 이 plan 의 핵심(가드 미발동)을 알 수 없다 — 미러링이
      # 없어도 정렬은 OK 로 나온다. 로그에서 직접 센다.
      mc_mirrored="$(grep -c 'Cosmetic markup mirrored' "$log" 2>/dev/null || true)"
      # 'load guard: … skipped —' 는 **더 이상 존재하지 않는 문구**다 — 부하
      # 가드는 파일을 제외하지 않고 'load signal:' / 'load routing:' 으로만
      # 알린다 (worker.py: skipped-load 는 legacy). 그래서 이 grep 은 항상 0 을
      # 돌려주며 guard-skips=0 이 공허하게 통과했다 (2026-08-23 발견). 지금 실제로
      # 파일을 제외하는 가드는 skip-full-table 뿐이므로 그것을 센다.
      mc_guard="$(grep -c 'skip-full-table: .*skipped —' "$log" 2>/dev/null || true)"
      # --translate api (jenkins) 모드에서는 번역 로그가 Jenkins 쪽에만 있어서
      # 위 두 카운터가 항상 0 이 된다 — 즉 "guard-skips=0" 이 공허하게 통과한다
      # (2026-08-19 실측). 그 모드의 실제 증거는 번역 PR 본문의 제외 섹션이다.
      mc_excl=0
      if [[ -n "$trans_pr" && "$trans_pr" != "<no-pr>" ]]; then
        mc_excl="$(gh pr view "$trans_pr" --json body --jq .body 2>/dev/null \
          | grep -cE '^### (번역 부하 가드로|구조 불일치로) 제외된' || true)"
      fi
      verdict="${verdict:-<no-verdict>} mirrored=${mc_mirrored:-0} guard-skips=${mc_guard:-0} pr-excl=${mc_excl:-0}"
    fi
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  fi
  echo "=== [$plan] 종료: exit=$ec ${verdict:-}"
  # webhook / korean-review / round1 은 전부 통과(exit 0)가 기대값 — 실패면 suite 실패
  # table-suite 는 번역 로직에 따라 기대값이 다르므로 exit 3 도 정상 허용
  if [[ "$plan" == "webhook" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "korean-review" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "round1" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "concurrent" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" != "round1" && "$plan" != "webhook" && "$plan" != "korean-review" \
        && "$plan" != "concurrent" && $ec -ne 0 && $ec -ne 3 ]]; then overall=1; fi
  # markup-churn 은 exit 0 만으로는 부족하다 — 가드가 한 번이라도 걸렸다면
  # 마크업 미러링이 동작하지 않은 것이므로 suite 실패로 잡는다.
  # row-drop-repro-noreconcile: exit 0/3 은 둘 다 허용 (todo-stub 으로 해소되면
  # 구조 검사가 표 개수 불일치로 FAIL 을 낼 수 있고, 그건 회귀가 아니라 완전성
  # 검사가 유실을 가시화한 것). 대신 **LLM-patch fallback 이 0건이면 실패** —
  # 그 경로를 태우지 못한 실행은 이 변형이 검증하려던 것을 검증하지 않았다.
  if [[ "$plan" == "row-drop-repro-noreconcile" ]] && [[ "$verdict" == *"llm-patch=0"* ]]; then
    echo "    ! LLM-patch fallback 미발동 — 이 변형은 그 경로 검증이 목적이므로 실패로 집계" >&2
    overall=1
  fi
  if [[ "$plan" == "markup-churn" ]]; then
    if (( ec != 0 )) || [[ "$verdict" != *"guard-skips=0"* ]] \
       || [[ "$verdict" != *"pr-excl=0"* ]]; then overall=1; fi
  fi
done

echo
echo "===== e2e suite 요약 ($outdir) ====="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "  (table-suite: reconcile 포함 로직이면 exit 0 이 기대값, 미포함이면 exit 3 이 정상)"
echo "  (markup-churn: exit 0 + guard-skips=0 + pr-excl=0 이 PASS. api 모드에서는 pr-excl 이 실질 지표)"
echo "  (concurrent: exit 0 = B 콘텐츠 보존. exit 1 = 유실(버그 재현), 2 = 하네스 오류)"
echo "  (row-drop-repro-noreconcile: exit 0/3 허용, 단 llm-patch=0 이면 실패 — 그 경로를 안 태운 실행)"
[[ -n "$ALIGNED_BRANCH" ]] && echo "  (align 스냅샷: $ALIGNED_BRANCH — 재현/디버그용, 정리는 수동)"
exit $overall
