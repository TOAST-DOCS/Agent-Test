#!/usr/bin/env bash
#
# e2e-queue-anchor-baseline.sh — 순차 번역 큐 차례(queue-next) 잡이 **앞선 번역 PR 이 ko 에
# 찍은 `<a id>`** 를 en/ja 에서 지우고 그 절을 통째로 다시 번역하는가 (결정적, 모델 0).
#
# 사고 원형: https://github.com/TOAST-DOCS/Data-Flow/pull/236 (2026-10-16 생성, 2026-10-20 분석)
#   ko PR #235 가 먼저 머지돼 큐에서 기다리는 동안 앞선 번역 PR #234 가 assign-anchors 로
#   ko/en/ja 에 `<a id="execution-history-execution-*">` 셋을 찍고 머지됐다. #235 의 차례
#   번역은 en/ja 를 base 끝(#234 반영)에서, ko 를 자기 머지 커밋(id 없음)에서 읽어 anchor
#   splice 가 세 절을 짝짓지 못했다 → en/ja 에서 id 세 줄 유실, ko 가 안 바꾼 절까지 재번역.
#
# 기존 큐 e2e(e2e-translate-queue.sh · e2e-webhook-lag-order.sh)가 못 본 이유: 그 e2e 들의
# 앞선 ko PR 은 섹션을 **id 와 함께** 더한다 — 앞선 번역 PR 이 ko 를 바꾸지 않으므로 차례 잡의
# ko(머지 커밋)와 base 끝의 ko 가 같다. 이 e2e 는 앞선 ko PR 이 id 없이 절을 더해 그 번역 PR
# 이 ko 에 id 를 찍는 모양만 잰다.
#
# 무대는 GitHub 가 아니라 픽스처 디렉터리다 (archive/queue-anchor/{base,merge,tip}/).
# 판정기 scripts/check_queue_anchor_baseline.py 가 cloud-translate 의 `worker._source_ref` ·
# `TranslationWorker._translate_modified` 를 가짜 GitHub + 이상적 모델로 돌린다 — 판정 규칙은
# 그 파일 머리말. 대조군(control)은 앞선 번역 PR 이 ko 를 바꾸지 않은 평범한 차례.
#
# Exit code: 0 = OK, 3 = 결함 재현 (수정 전 코드의 기대값), 1 = 판정 불가 · 대조군 실패
#
# Usage:
#   bash scripts/e2e-queue-anchor-baseline.sh [--cloud-translate-dir DIR] [--label BEFORE|AFTER] [--list-items]
#
# 의존성: python3 (cloud-translate 의 .venv). .env · GitHub · 모델 호출 없음.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CT="${CLOUD_TRANSLATE_DIR:-/home/irteam/works/cloud-translate}"
LABEL=""
EXTRA=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud-translate-dir) CT="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --list-items) EXTRA+=(--list-items); shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

PY="$CT/.venv/bin/python"
[[ -x "$PY" ]] || PY="$(cd "$CT/../../.." 2>/dev/null && pwd)/.venv/bin/python"   # 워크트리면 메인 체크아웃의 venv
[[ -x "$PY" ]] || PY=python3

echo "[queue-anchor${LABEL:+ $LABEL}] cloud-translate=$CT ($(git -C "$CT" rev-parse --short HEAD 2>/dev/null || echo '?'))"
set +e
( cd "$CT" && "$PY" "$ROOT/scripts/check_queue_anchor_baseline.py" "$ROOT/archive/queue-anchor" "${EXTRA[@]}" )
rc=$?
set -e
exit $rc
