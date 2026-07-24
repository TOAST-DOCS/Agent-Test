#!/usr/bin/env bash
#
# e2e 전체 suite 러너 — 여러 plan 을 순차 실행하고 결과를 요약한다.
#
#   scripts/e2e-suite.sh [--translate api|local] [--engine api|cli] [--model haiku|sonnet|opus] [plan ...]
#
# plan 미지정 시 기본: round1 table-suite
#   round1      — 일반 종합 (heading/anchor/섹션/문단/표 기본 변형 15항목).
#                 기대: exit 0 (전 파일 PASS).
#   table-suite — 표 변형 종합 + stale 결함 재현 (stale-ify 커밋 포함).
#                 기대: 번역 로직에 table-row reconcile(PR #290)이 있으면 exit 0,
#                 없으면 exit 3 (version-guide/release-notes FAIL).
#   round2      — 전제 조건(직전 round1 의 ko/번역 PR 이 base 에 머지되어 있음)이
#                 필요해 suite 기본에서 제외. 명시 지정 시에만 실행.
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
PLANS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --translate|--engine|--model|--tm-top-k|--chunk-workers)
      PASS_ARGS+=("$1" "$2"); shift 2 ;;
    round1|round2|row-drop-repro|table-suite)
      PLANS+=("$1"); shift ;;
    -h|--help) sed -n '3,24p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (plan 이름 또는 --translate/--engine/--model...)" >&2; exit 1 ;;
  esac
done
(( ${#PLANS[@]} )) || PLANS=(round1 table-suite)

ts="$(date +%Y%m%d-%H%M%S)"
outdir="/tmp/e2e-suite-$ts"
mkdir -p "$outdir"

declare -a RESULTS=()
overall=0
for plan in "${PLANS[@]}"; do
  log="$outdir/$plan.log"
  echo "=== [$plan] 시작 → $log"
  bash "$REPO_ROOT/scripts/e2e-align-and-translate.sh" \
    --plan "$plan" "${PASS_ARGS[@]}" > "$log" 2>&1
  ec=$?
  verdict="$(grep -oE '^ALIGNMENT: (OK|FAIL)' "$log" | tail -n1 || true)"
  trans_pr="$(grep -oE 'detected translation PR: https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
  RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  echo "=== [$plan] 종료: exit=$ec ${verdict:-}"
  # round1 은 전부 통과가 기대값 — 실패면 suite 실패
  # table-suite 는 번역 로직에 따라 기대값이 다르므로 exit code 를 그대로 전달만 한다
  if [[ "$plan" == "round1" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" != "round1" && $ec -ne 0 && $ec -ne 3 ]]; then overall=1; fi
done

echo
echo "===== e2e suite 요약 ($outdir) ====="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "  (table-suite: reconcile 포함 로직이면 exit 0 이 기대값, 미포함이면 exit 3 이 정상)"
exit $overall
