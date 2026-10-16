#!/usr/bin/env bash
#
# 목록 흡수 e2e — 빈 줄 너머(또는 같은 블록 안)의 **다른 종류 목록 항목**을 python-markdown 이
# 앞 목록에 이어 붙여, 저자가 쓴 `2. 단계` 가 글머리로 · `- 메모` 가 `8.` 로 보이는 결함.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# cloud-translate#1310 검토(2026-10-16) 중 alpha 전수에서 찾았다. 배포 alpha 기준
# 29 리포 · 97 문서 · 405 항목 (대상 101 리포, ko/en/ja 3,032 문서, zh·variant 제외).
# 대표: PrivateCA `cert-manager-guide.md` 의 `2. Certificate 상태 확인` 이 글머리,
# NHNBastion·Network-Load-Balancer 의 하위 글머리가 번호 단계(4.·5.)로 보인다.
# GitHub 미리보기(CommonMark)는 종류가 바뀌면 새 목록을 시작하므로 소스 리뷰로는 안 보인다.
#
# ── 무엇을 재나 (모델 호출 없음, 전부 결정적) ────────────────────────────
#   [A] 픽스처 archive/list-absorb/<lang>/ 를 사이트 렌더러로 판정 → C1~C6 결함, K1~K3 정상
#   [B] cloud-translate 의 마크업 정정(shared/markup_lint.scan_markup)을 픽스처에 돌린 출력을
#       같은 판정에 넣는다 → 지금은 결함이 그대로다(도구가 이 모양을 모른다)
#   [C] 검토 중인 수리안 archive/list-absorb/proposed/<lang>/ → 결함 0 · 대조군 바이트 동일 ·
#       보이는 글자 동일
# 종료 코드: 0 = [B] 가 결함을 모두 없앰(룰이 들어온 뒤의 기대값) / 3 = [B] 에 결함이 남음(REPRO,
# 지금의 기대값) / 1 = 픽스처·대조군·수리안 자체가 기대와 다름.
#
# Usage:
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate scripts/e2e-list-absorb.sh [--label BEFORE|AFTER]
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CT="${CLOUD_TRANSLATE_DIR:-/home/irteam/works/cloud-translate}"
PY="${PYTHON:-$CT/.venv/bin/python}"
LABEL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="$2"; shift 2 ;;
    --cloud-translate-dir) CT="$2"; PY="${PYTHON:-$CT/.venv/bin/python}"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
CHECK="$REPO_ROOT/scripts/check_list_absorb.py"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
rc=0; tool_rc=0
echo "[list-absorb] ${LABEL:+label=$LABEL }cloud-translate=$CT @ $(git -C "$CT" rev-parse --short HEAD 2>/dev/null)"
for lang in ko en ja; do
  src="$REPO_ROOT/archive/list-absorb/$lang/list-absorb-sample.md"
  prop="$REPO_ROOT/archive/list-absorb/proposed/$lang/list-absorb-sample.md"
  echo "== [$lang][A] 픽스처"
  "$PY" "$CHECK" "$src" | sed 's/^/   /'; a=${PIPESTATUS[0]}
  [[ $a -eq 3 ]] || { echo "   ✗ 픽스처는 REPRO(3) 여야 한다 (got $a)"; rc=1; }
  echo "== [$lang][B] 마크업 정정 출력"
  PYTHONPATH="$CT" "$PY" - "$src" "$TMP/$lang.md" <<'PY' | sed 's/^/   /'
import sys
from shared.markup_lint import scan_markup
text = open(sys.argv[1], encoding="utf-8").read()
out, findings = scan_markup(text, "x/list-absorb-sample.md")
open(sys.argv[2], "w", encoding="utf-8").write(out)
rules = sorted({r for f in findings for r in f.rules})
print(f"findings={len(findings)} rules={rules} changed={out != text}")
PY
  "$PY" "$CHECK" --before "$src" "$TMP/$lang.md" | sed 's/^/   /'; b=${PIPESTATUS[0]}
  case $b in 0) ;; 3) tool_rc=3 ;; *) echo "   ✗ 마크업 정정이 대조군·글자를 바꿨다"; rc=1 ;; esac
  echo "== [$lang][C] 수리안"
  "$PY" "$CHECK" --before "$src" "$prop" | sed 's/^/   /'; c=${PIPESTATUS[0]}
  [[ $c -eq 0 ]] || { echo "   ✗ 수리안은 OK(0) 여야 한다 (got $c)"; rc=1; }
done
if [[ $rc -ne 0 ]]; then echo "LIST_ABSORB_E2E: FAIL"; exit 1; fi
if [[ $tool_rc -eq 3 ]]; then echo "LIST_ABSORB_E2E: REPRO (마크업 정정이 이 모양을 고치지 않는다)"; exit 3; fi
echo "LIST_ABSORB_E2E: OK"; exit 0
