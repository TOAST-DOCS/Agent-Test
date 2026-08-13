#!/usr/bin/env bash
#
# e2e 전체 suite 러너 — 여러 plan 을 순차 실행하고 결과를 요약한다.
#
#   scripts/e2e-suite.sh [--translate api|local] [--engine api|cli] [--model haiku|sonnet|opus] \
#                        [--sleep-between <sec>] [plan ...]
#
#   --sleep-between <sec> — plan 과 plan 사이 대기 (기본 0). Jenkins agent 의
#       claude CLI (OAuth) 가 연속 실행으로 usage limit 에 걸려 align/ko-review
#       가 무더기 is_error 로 무너지는 것(2026-08-13 08:15Z 실측: align build
#       324=에러0 → 325/326=에러84)을 피하려면 3600(1시간) 권장. 마지막 plan
#       뒤에는 자지 않는다.
#
# plan 미지정 시 기본: webhook round1 table-suite
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
#   round1      — 일반 종합 (heading/anchor/섹션/문단/표 기본 변형 15항목).
#                 기대: exit 0 (전 파일 PASS).
#   table-suite — 표 변형 종합 + stale 결함 재현 (stale-ify 커밋 포함).
#                 기대: 번역 로직에 table-row reconcile(PR #290)이 있으면 exit 0,
#                 없으면 exit 3 (version-guide/release-notes FAIL).
#   retranslate — public-api.md 전체 재번역 변형 (e2e-retranslate-align-and-
#                 translate.sh). dashboard /api/translate/file (DIFF_MODE=full)
#                 경로 검증 — 다른 plan 이 커버하지 않는 유일한 API. dashboard
#                 API 전용이라 --translate local 은 적용되지 않는다 (--engine/
#                 --model 만 전달). 기대: exit 0.
#   round2      — 전제 조건(직전 round1 의 ko/번역 PR 이 base 에 머지되어 있음)이
#                 필요해 suite 기본/all 에서 제외. 명시 지정 시에만 실행.
#
# 별칭:
#   all         — round2 를 제외한 실행 가능한 plan 전체
#                 = webhook korean-review round1 table-suite row-drop-repro retranslate
#                 round2 는 round1 후처리(수동 머지)가 필요해 제외 —
#                 필요하면 명시적으로 `scripts/e2e-suite.sh all round2` 로 이어붙임.
#
# 각 plan 은 자체 e2e 세션 브랜치(e2e/<ts>)에서 돌므로 서로 간섭하지 않지만,
# 같은 작업 트리를 쓰므로 반드시 순차 실행 (이 러너가 보장). 개별 실행 로그는
# /tmp/e2e-suite-<ts>/<plan>.log 에 남는다.
#
# --translate local 이면 CLOUD_TRANSLATE_DIR (기본 ~/works/cloud-translate) 의
# translate_pr.py 로 번역을 실행한다 — 미머지 브랜치 검증용. 사전 준비(.env,
# 워크트리)는 e2e-align-and-translate.sh 헤더 및 /verify-translate-e2e 참고.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PASS_ARGS=()
EM_ARGS=()   # --engine/--model 만 — retranslate 스크립트는 --translate 계열 미지원
PLANS=()
SLEEP_BETWEEN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sleep-between)
      SLEEP_BETWEEN="$2"; shift 2 ;;
    --engine|--model)
      PASS_ARGS+=("$1" "$2"); EM_ARGS+=("$1" "$2"); shift 2 ;;
    --translate|--tm-top-k|--chunk-workers)
      PASS_ARGS+=("$1" "$2"); shift 2 ;;
    webhook|korean-review|round1|round2|row-drop-repro|table-suite|retranslate)
      PLANS+=("$1"); shift ;;
    all)
      # round2 는 round1 후 수동 머지가 전제라 all 에서 제외 — 필요하면
      # `scripts/e2e-suite.sh all round2` 처럼 뒤에 명시적으로 이어붙인다.
      PLANS+=(webhook korean-review round1 table-suite row-drop-repro retranslate); shift ;;
    -h|--help) sed -n '3,31p' "$0"; exit 0 ;;
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
(( ${#PLANS[@]} )) || PLANS=(webhook round1 table-suite)

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
  elif [[ "$plan" == "korean-review" ]]; then
    # korean-review plan 은 별도 스크립트 — /api/ko-review 잡을 태우고
    # 결과 리뷰 규격 + fable 의미 검증. --engine/--model 은 korean-review
    # 잡의 파라미터가 아니라 전달하지 않는다.
    bash "$REPO_ROOT/scripts/e2e-korean-review.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^KO_REVIEW: (OK|FAIL)' "$log" | tail -n1 || true)"
    ko_pr="$(grep -oE '  ko PR         : https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${ko_pr:-<no-pr>}")
  else
    bash "$REPO_ROOT/scripts/e2e-align-and-translate.sh" \
      --plan "$plan" "${PASS_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^ALIGNMENT: (OK|FAIL)' "$log" | tail -n1 || true)"
    trans_pr="$(grep -oE 'detected translation PR: https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  fi
  echo "=== [$plan] 종료: exit=$ec ${verdict:-}"
  # webhook / korean-review / round1 은 전부 통과(exit 0)가 기대값 — 실패면 suite 실패
  # table-suite 는 번역 로직에 따라 기대값이 다르므로 exit 3 도 정상 허용
  if [[ "$plan" == "webhook" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "korean-review" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "round1" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" != "round1" && "$plan" != "webhook" && "$plan" != "korean-review" && $ec -ne 0 && $ec -ne 3 ]]; then overall=1; fi
done

echo
echo "===== e2e suite 요약 ($outdir) ====="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "  (table-suite: reconcile 포함 로직이면 exit 0 이 기대값, 미포함이면 exit 3 이 정상)"
exit $overall
