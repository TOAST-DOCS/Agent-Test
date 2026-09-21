#!/usr/bin/env bash
#
# unit-preserve e2e — cloud-translate #924 의 `UNIT_PRESERVE` 검증.
#
# 검증 대상은 둘이고, **둘을 따로 판정한다.**
#
#   (가) 기능이 약속한 일을 하는가 — 한 문단에서 한 문장만 바뀌었을 때, 안 바뀐
#        문장이 en/ja 에서 **바이트 그대로** 남는가. 이게 이 옵션의 존재 이유다
#        (`diff_list_items` 는 무엇이 **전송되는가**를 줄이고, 이쪽은 보낸 것으로
#        **무엇을 하라고 하는가**를 바꾼다 — 빈 줄로 둘러싸인 산문 문단은 어떤
#        granularity 로도 더 쪼개지지 않아 그쪽이 닿지 못하는 잔여다).
#
#   (나) 붙는 베이스라인이 **그 유닛의 진짜 짝인가.** 프롬프트는
#        "This Korean text already has a translation, shown below" 라고 단정하고
#        "Reuse the existing wording byte-for-byte" 를 지시한다. 짝이 밀리면
#        모델은 지시대로 남의 문장을 베끼고, 그게 그대로 커밋된다.
#
# ── 재현하는 사고 ─────────────────────────────────────────────────────────
# 2026-09-18 Agent-Test round1 을 UNIT_PRESERVE ON 으로 돌렸을 때
# `component-guide.md` 의 **en 과 ja 양쪽**에 `<a id="nat-instance">` 가 한 줄씩
# 더 들어갔다 (anchor id ko 127 : 번역본 128). 번역본에 본문이 없는 섹션에 ko 가
# 내용을 넣으면 SequenceMatcher 가 `replace` 를 내고, 새 문단이 **위치로** 다음
# 섹션의 `<a id>` 줄과 짝지어져 그게 베이스라인이 된다. 27자라
# `diff_unit_preserve_min_chars`(200) 허용치를 통과하고, `replace` 는 `insert` 가
# 아니라 all-or-nothing 가드도 안 걸린다. 워커의 verify-alignment 는 heading
# 개요만 보므로 통과하고 커밋된다. 그래서 이 옵션은 지금 **기본 off** 다.
#
# ── 층이 둘인 이유 ────────────────────────────────────────────────────────
# 산출물만 보면 **모델이 미끼를 문 실행에서만** 보인다. 같은 입력이라도 다음 번엔
# 안 베낄 수 있어 통과/실패가 그날 모델에 달린다. 반면 **무엇이 베이스라인으로
# 붙는가**는 모델을 부르기 전에 정해지는 순수 함수다. 그래서
#
#   [A] 결정적 층 — `scripts/check_unit_baselines.py` 가 (유닛, 베이스라인) 짝을
#       전수로 보고 네 규칙(foreign-anchor · body-injected · body-dropped · stub)
#       으로 판정한다. 모델도 네트워크도 쓰지 않는다.
#   [B] 산출물 층 — 실제 ko PR 을 로컬 `translate_pr.py --unit-preserve` 로 돌려
#       anchor 복제·본문 복제를 실측하고, 안 바뀐 문장의 바이트 보존을 **플래그를
#       끈 대조군**과 비교한다 (대조군이 없으면 "바이트 동일" 이 preserve 덕인지
#       그냥 모델 운인지 구분할 수 없다).
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# 세션 브랜치에 **생성**한다 (alpha 상주 아님). 조건이 "번역본이 ko 와 어긋나
# 있다" 라서 alpha 에 두면 fill-stubs·align 같은 다른 정비 e2e 가 조용히 고쳐
# 버리고, 그러면 이 e2e 는 아무것도 재현하지 못한 채 초록이 된다.
#
#   ko/en/ja unit-preserve-aligned.md — 세 언어가 유닛 단위로 완전 정렬.
#       -> 베이스라인이 진짜 짝이다. (가) 를 여기서 본다.
#   ko/en/ja unit-preserve-drift.md   — **섹션 2 에 본문이 없다 (세 언어 모두)**.
#       ko 편집이 거기에 문단 하나와 신규 하위 섹션(`### ` + 자기 anchor)을 넣는다
#       — round1 의 `add_paragraph` + `add_subsection` 이 component-guide 에 한
#       것과 같은 모양이다. anchor splice 는 섹션을 **heading 줄에서** 자르므로
#       "다음 섹션의 `<a id>` 줄" 이 앞 섹션의 마지막 유닛이다. 그래서
#         old ko [heading][<a id="up-drift-3">]
#         new ko [heading][새 문단][<a id="up-drift-2-sub">]
#       가 되어 마지막 유닛이 서로 달라지고 → `insert` 가 아니라 `replace` →
#       새 문단이 **위치로** 옛 마지막 유닛과 짝지어져 `<a id="up-drift-3"></a>`
#       (23자) 가 그 문단의 베이스라인이 된다. 사고의 `<a id="nat-instance"></a>`
#       (25자) 와 같은 자리다. 베끼면 anchor `up-drift-3` 이 복제된다.
#       ([A] 가 매 실행 이 짝을 증명한다 — 모델이 물든 안 물든.)
#
# ── 판정 규칙 ─────────────────────────────────────────────────────────────
#   [A] (1) 결정적: 정렬 문서는 베이스라인이 전부 정상 짝               ← 전제
#       (2) 결정적: drift 문서에 규칙 위반 베이스라인이 없다            ← 결함
#   [B] (3) 번역 성공 (exit 0, PARTIAL 없음)
#       (4) anchor id 다중집합이 ko == en == ja — 복제 0              ← 결함(증상)
#       (5) 베이스라인으로 붙었던 남의 heading 이 본문에 나타나지 않는다  ← 결함(증상)
#       (6) aligned: ko 가 안 건드린 문장 2개가 en/ja 에서 바이트 동일   ← 기능
#           (4개 중 2개 이상이면 WARN — 모델 편차를 허용한다. 절대 판정은 (7))
#       (7) 대조군(플래그 off)보다 (6) 의 보존이 많거나 같다            ← 기능
#
# ── 결함은 닫혔다 (cloud-translate, 2026-09-21) ────────────────────────────
# 두 가지가 들어갔고, 이 e2e 는 그 둘을 각각 본다.
#   * `_unit_baseline_refusal` — 밀린 짝을 베이스라인으로 내주지 않는다.
#     (2) 가 그것을 본다. 이 실행의 로그에 `Per-unit baseline: refused 1
#     implausible pairing(s) (markup-shape 1)` 이 en·ja 에 하나씩 찍힌다.
#   * `anchor_dup_gate` — 그래도 중복이 나오면 커밋 전에 파일 단위로 막는다.
#     (4) 가 그것을 본다 (게이트가 막았으면 그 언어가 산출물에 없다).
# 실측 (2026-09-21, 수정 후): (1)~(5)(7) 통과, (6) 3/4 (대조군 0/4).
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`UNIT_PRESERVE: OK`) — **현행 기대값**
#   3  결함 재현 — (2) 가 실패하고 기능 규칙 (6) 은 통과 (`UNIT_PRESERVE: REPRO`).
#      수정 전의 기대값이었다. 다시 이 값이 나오면 짝 가드가 회귀한 것이다.
#   1  기능 규칙 실패 또는 픽스처가 조건을 잃음 (`UNIT_PRESERVE: FAIL`)
#   2  인프라 — 번역 PR 미감지 · translate_pr.py 비정상 종료
#
# Usage:
#   source ./load_env.sh          # webhook 토글에만 필요
#   bash scripts/e2e-unit-preserve.sh                       # [A]+[B], 대조군 포함
#   bash scripts/e2e-unit-preserve.sh --dry                 # [A] 만 (모델·네트워크 없음)
#   bash scripts/e2e-unit-preserve.sh --no-control --keep
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-unit-preserve.sh
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
# 의존성: git, gh(로그인), python3, cloud-translate 체크아웃(+ .env, venv).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-unitpreserve/$TS"
HEAD_BRANCH="translate-test-unitpreserve/$TS"
CTRL_BRANCH="translate-test-unitpreserve-ctl/$TS"
ALIGNED="unit-preserve-aligned.md"
DRIFT="unit-preserve-drift.md"
KEEP=0
CONTROL=1
DRY=0
PR_TIMEOUT=1800

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)       KEEP=1; shift ;;
    --no-control) CONTROL=0; shift ;;
    --dry)        DRY=1; shift ;;
    --timeout)    PR_TIMEOUT="$2"; shift 2 ;;
    -h|--help)    sed -n '2,84p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"; CTRL_LOG="$tmpdir/control.log"
ko_pr_url=""; ctl_pr_url=""; tx_pr_url=""; tx_ctl_url=""

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/base" "$tmpdir/head" "$tmpdir/tx" "$tmpdir/txctl"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( KEEP )); then
    echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${ko_pr_url:-없음}, 번역 PR: ${tx_pr_url:-없음})"
    return $rc
  fi
  echo; echo "[cleanup] PR 닫기 · 브랜치 정리"
  for u in "$tx_pr_url" "$tx_ctl_url"; do
    [[ -n "$u" ]] && gh pr close "$u" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  done
  for u in "$ko_pr_url" "$ctl_pr_url"; do
    [[ -n "$u" ]] && gh pr close "$u" --repo "$REPO" >/dev/null 2>&1 || true
  done
  local b
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

echo "=== unit-preserve e2e ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR"
echo "  session         : $SESSION_BRANCH"
echo "  픽스처          : {ko,en,ja}/$ALIGNED · {ko,en,ja}/$DRIFT"
echo "  모드            : $( ((DRY)) && echo '[A] 결정적 층만 (--dry)' || echo "[A]+[B] (대조군 $( ((CONTROL)) && echo 포함 || echo 제외 ))" )"
echo

[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }

fails=0; repro=0
ok()    { echo "  PASS  $1"; }
bad()   { echo "  FAIL  $1"; fails=$((fails + 1)); }
defect(){ echo "  FAIL  $1  (결함 — 재현)"; repro=$((repro + 1)); }
warn()  { echo "  WARN  $1"; }

# ── 1) 세션 브랜치 + 픽스처 생성 ───────────────────────────────────────────
if (( ! DRY )); then
  source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
  echo "[0] webhook 비활성화"
  set_webhook_repo_enabled false
fi

echo "[1] 세션 브랜치 생성 + 픽스처 시드"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

python3 - "$TS" "$ALIGNED" "$DRIFT" <<'PY'
import io, os, sys
ts, aligned_doc, drift_doc = sys.argv[1:4]

# 한 문단 = 세 문장. 가운데 문장만 ko 가 바꾸고, 앞뒤 두 문장은 바이트 그대로
# 남아야 한다 — 빈 줄로 둘러싸여 있어 어떤 granularity 로도 더 쪼개지지 않는,
# `diff_unit_preserve` 가 정확히 노리는 모양이다.
KO_SEC = """
<a id="up-{tag}-{i}"></a>
## 섹션 {i} {{ #up-{tag}-{i} }}

{i}번 섹션의 첫 문장입니다. 이 문장은 ko 가 건드리지 않습니다. {i}번 섹션의 두 번째 문장으로,
인스턴스 {i}번의 동작을 설명합니다. {i}번 섹션의 세 번째 문장이며 마지막입니다.
"""
EN_SEC = """
<a id="up-{tag}-{i}"></a>
## Section {i} {{ #up-{tag}-{i} }}

This is the first sentence of section {i}. The Korean side never touches it. This is the second
sentence of section {i}, describing how instance {i} behaves. This is the third and last sentence of section {i}.
"""
JA_SEC = """
<a id="up-{tag}-{i}"></a>
## セクション {i} {{ #up-{tag}-{i} }}

セクション {i} の最初の文です。この文は ko が触れません。セクション {i} の 2 番目の文で、
インスタンス {i} の動作を説明します。セクション {i} の 3 番目で最後の文です。
"""
HEAD = {
    "ko": '<!-- pre-align:aligned sig=e2e00ba5e11 -->\n\n<a id="up-{tag}"></a>\n'
          '# unit-preserve e2e 픽스처 ({tag})\n\n이 문서는 자동 생성된 e2e 픽스처입니다 (%s).\n' % ts,
    "en": '<!-- pre-align:aligned sig=e2e00ba5e11 -->\n\n<a id="up-{tag}"></a>\n'
          '# unit-preserve e2e fixture ({tag})\n\nThis document is a generated e2e fixture (%s).\n' % ts,
    "ja": '<!-- pre-align:aligned sig=e2e00ba5e11 -->\n\n<a id="up-{tag}"></a>\n'
          '# unit-preserve e2e フィクスチャ ({tag})\n\nこの文書は自動生成された e2e フィクスチャです (%s)。\n' % ts,
}
SEC = {"ko": KO_SEC, "en": EN_SEC, "ja": JA_SEC}
N = 6

def build(doc, tag, empty_section):
    for lang in ("ko", "en", "ja"):
        parts = [HEAD[lang].format(tag=tag)]
        for i in range(1, N + 1):
            s = SEC[lang].format(i=i, tag=tag)
            if i == empty_section:
                # 본문이 없는 섹션 — 세 언어 모두. pre-align 이 heading 만
                # 맞춰 두고 본문은 아직 안 채워진, 실제로 흔한 상태다.
                s = "\n".join(s.split("\n")[:4]) + "\n"
            parts.append(s)
        path = os.path.join(lang, doc)
        io.open(path, "w", encoding="utf-8", newline="").write("".join(parts))

build(aligned_doc, "aligned", None)
build(drift_doc, "drift", 2)
print("  생성: {ko,en,ja}/%s (완전 정렬) · {ko,en,ja}/%s (섹션 2 본문 없음)"
      % (aligned_doc, drift_doc))
PY

git add -- "ko/$ALIGNED" "en/$ALIGNED" "ja/$ALIGNED" "ko/$DRIFT" "en/$DRIFT" "ja/$DRIFT"
git commit -q -m "e2e(unit-preserve): 픽스처 시드 — 정렬본 + drift 본 ($TS)"
session_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$SESSION_BRANCH"

# ── 2) ko 편집 — 두 문서 모두 문단 가운데 문장 하나만 ──────────────────────
echo "[2] ko 편집 — 정렬본은 문장 하나, drift 본은 빈 섹션에 문단+하위 섹션"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$ALIGNED" "ko/$DRIFT" <<'PY'
import io, sys
aligned_path, drift_path = sys.argv[1:3]

# (가) 정렬본 — 한 문단 세 문장 중 **가운데 하나만**. 앞뒤 두 문장이 바이트
#      그대로 남는 것이 이 옵션의 약속이다.
OLD = "4번 섹션의 두 번째 문장으로,\n인스턴스 4번의 동작을 설명합니다."
NEW = "4번 섹션의 두 번째 문장을 고쳤습니다.\n인스턴스 4번의 새 동작을 설명합니다."
raw = io.open(aligned_path, encoding="utf-8", newline="").read()
assert raw.count(OLD) == 1, f"{aligned_path}: 편집 대상이 정확히 1회여야 함"
io.open(aligned_path, "w", encoding="utf-8", newline="").write(raw.replace(OLD, NEW))
print(f"  {aligned_path}: 문단 가운데 문장 1개 변경 (앞뒤 문장 2개는 그대로)")

# (나) drift 본 — 본문이 없던 섹션에 문단 + 신규 하위 섹션. 이 조합이어야
#      섹션의 마지막 유닛(다음 섹션의 anchor 줄)이 바뀌어 `replace` 가 되고,
#      새 문단이 그 anchor 줄과 위치로 짝지어진다.
HEADING = "## 섹션 2 { #up-drift-2 }\n"
INSERT = (
    HEADING
    + "\n2번 섹션에 새로 넣은 문단입니다. 번역본에는 이 섹션의 본문이 없었습니다. "
      "이 문장이 세 번째입니다.\n"
    + '\n<a id="up-drift-2-sub"></a>\n'
    + "### 새로 넣은 하위 섹션 { #up-drift-2-sub }\n"
    + "\n이 하위 섹션은 ko 가 새로 추가했습니다. 번역본에는 아직 없습니다.\n"
)
raw = io.open(drift_path, encoding="utf-8", newline="").read()
assert raw.count(HEADING) == 1, f"{drift_path}: 섹션 2 heading 이 정확히 1회여야 함"
io.open(drift_path, "w", encoding="utf-8", newline="").write(raw.replace(HEADING, INSERT))
print(f"  {drift_path}: 빈 섹션에 문단 1 + 하위 섹션 1 추가")
PY
git add -- "ko/$ALIGNED" "ko/$DRIFT"
committed="$(git diff --cached --name-only | paste -sd, -)"
[[ "$committed" == "ko/$ALIGNED,ko/$DRIFT" ]] \
  || { echo "error: 예상 외 파일 스테이지됨: $committed" >&2; exit 1; }
git commit -q -m "e2e(unit-preserve): 문단 가운데 문장 하나만 변경 ($TS)"
head_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$HEAD_BRANCH"

# ── 3) [A] 결정적 층 — 무엇이 베이스라인으로 붙는가 ────────────────────────
echo
echo "[3] [A] 결정적 층 — 베이스라인 짝 검사 (모델 없음)"
git worktree add -q --detach "$tmpdir/base" "$session_sha"
git worktree add -q --detach "$tmpdir/head" "$head_sha"
set +e
CLOUD_TRANSLATE_DIR="$CLOUD_TRANSLATE_DIR" "$CLOUD_TRANSLATE_PY" \
  "$REPO_ROOT/scripts/check_unit_baselines.py" \
  --root "$tmpdir/head" --old-root "$tmpdir/base" \
  --files "ko/$ALIGNED,ko/$DRIFT" --verbose \
  > "$tmpdir/baselines.txt" 2>"$tmpdir/baselines.err"
set -e
sed 's/^/    /' "$tmpdir/baselines.txt"

aligned_clean=$(grep -cE "^  ko/$ALIGNED .*clean$" "$tmpdir/baselines.txt" || true)
if (( aligned_clean == 2 )); then
  ok "(1) 정렬 문서의 베이스라인은 전부 정상 짝 (en·ja)"
else
  bad "(1) 정렬 문서에서 정상 짝이 아니다 — 픽스처가 조건을 잃었다"
fi
drift_bad=$(grep -E "^  ko/$DRIFT " "$tmpdir/baselines.txt" | grep -cv "clean$" || true)
if (( drift_bad == 0 )); then
  ok "(2) drift 문서에도 규칙 위반 베이스라인이 없다"
else
  defect "(2) drift 문서에서 규칙 위반 베이스라인 ${drift_bad}건 (en·ja) — 짝이 밀렸다"
fi
# 베이스라인으로 붙은 '남의 heading' 을 뽑아 [B] 의 (5) 에서 본문 대조에 쓴다
python3 - "$tmpdir/baselines.txt" "$tmpdir/leak.txt" <<'PY'
import io, re, sys
txt = io.open(sys.argv[1], encoding="utf-8").read()
ids = sorted(set(re.findall(r'BASELINE : .*?<a id="([^"]+)"', txt)))
io.open(sys.argv[2], "w", encoding="utf-8").write("\n".join(ids) + ("\n" if ids else ""))
print("  베이스라인에 실린 남의 anchor id: " + (", ".join(ids) or "없음"))
PY

if (( DRY )); then
  echo
  echo "[4] --dry: 산출물 층 건너뜀"
  if (( fails == 0 && repro == 0 )); then echo "UNIT_PRESERVE: OK"; exit 0; fi
  if (( fails == 0 )); then
    echo "  REPRO — 베이스라인 짝이 밀린다 (모델이 베끼면 anchor·본문이 복제된다)"
    echo "UNIT_PRESERVE: REPRO"; KEEP=1; exit 3
  fi
  echo "UNIT_PRESERVE: FAIL"; KEEP=1; exit 1
fi

# ── 4) [B] 산출물 층 — 실제 번역 ───────────────────────────────────────────
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(unit-preserve): 문단 가운데 문장 하나 변경 ($TS)" \
  --body "cloud-translate UNIT_PRESERVE 검증 — 안 바뀐 문장은 바이트 그대로 남고, 남의 유닛 베이스라인이 복제되지 않아야 한다." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"

run_translate() {   # $1=로그 $2=PR URL $3...=추가 플래그
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
      --table-rows --skip-anchor-only --assign-anchors --align-headings \
      --list-items "$@" \
  ) 2>&1 | tee "$log"
  local rc=${PIPESTATUS[0]}
  set -e
  return $rc
}

echo
echo "[4] local translate_pr.py --unit-preserve (engine=claude-code, model=haiku)"
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
set +e
run_translate "$LOG" "$ko_pr_url" --unit-preserve
tx_rc=$?
set -e

if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(3) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(3) 번역 실패/부분 (exit $tx_rc)"
fi
grep -c "Existing .* translation" "$LOG" >/dev/null 2>&1 || true

echo
echo "[5] 번역 PR 감지"
# 로그의 `Translation PR:` 줄에서 읽는다. `gh pr list --base <ko head>` 로
# 폴링하면 안 된다 — `--base-branch <세션>` 으로 돌리면 번역 PR 의 base 는 ko
# head 가 아니라 **세션 브랜치**다 (worker 가 base 에서 가지를 뜬다).
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미생성 (로그: $LOG)" >&2; exit 2; }
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url" || true
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"

# ── 5) 대조군 — 같은 편집을 플래그 없이 ────────────────────────────────────
ctl_wt=""
if (( CONTROL )); then
  echo
  echo "[6] 대조군 — 같은 편집을 --unit-preserve 없이"
  git checkout -q -B "$CTRL_BRANCH" "$SESSION_BRANCH"
  git checkout -q "$HEAD_BRANCH" -- "ko/$ALIGNED" "ko/$DRIFT"
  git commit -q -m "e2e(unit-preserve): 대조군 — 같은 ko 편집 ($TS)"
  git push -q origin "$CTRL_BRANCH"
  ctl_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$CTRL_BRANCH" \
    --title "e2e(unit-preserve): 대조군 — 플래그 없이 ($TS)" \
    --body "UNIT_PRESERVE 대조군." --label "$E2E_LABEL")"
  set +e
  run_translate "$CTRL_LOG" "$ctl_pr_url"
  ctl_rc=$?
  set -e
  tx_ctl_url="$(grep -oE 'Translation PR: https://[^ ]+' "$CTRL_LOG" | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$tx_ctl_url" ]]; then
    ctl_head="$(gh pr view "$tx_ctl_url" --repo "$REPO" --json headRefName --jq .headRefName)"
    git fetch -q origin "$ctl_head"
    git worktree add -q --detach "$tmpdir/txctl" "origin/$ctl_head"
    ctl_wt="$tmpdir/txctl"
    e2e_label_pr "$REPO" "$tx_ctl_url" || true
    echo "  대조군 번역 PR: $tx_ctl_url"
  else
    warn "대조군 번역 PR 미감지 (exit $ctl_rc) — (7) 은 생략된다"
  fi
fi

# ── 6) 산출물 판정 ─────────────────────────────────────────────────────────
echo
echo "[7] 산출물 판정"
python3 - "$tmpdir/base" "$tmpdir/head" "$tmpdir/tx" "${ctl_wt:-}" \
         "$ALIGNED" "$DRIFT" "$tmpdir/leak.txt" "$tmpdir/verdict.json" <<'PY'
import io, json, os, re, sys
base, head, tx, ctl, aligned, drift, leakfile, outfile = sys.argv[1:9]
ANCHOR = re.compile(r'<[a-zA-Z][\w]*\b[^>]*?\bid\s*=\s*"([^"]+)"|\{\s*#([\w.:-]+)\s*\}')

def read(root, lang, doc):
    p = os.path.join(root, lang, doc)
    try:
        return io.open(p, encoding="utf-8", newline="").read()
    except OSError:
        return None

def ids(t):
    out = []
    for m in ANCHOR.finditer(t or ""):
        out.append(m.group(1) or m.group(2))
    return out

# ko 가 건드리지 않은 두 문장 — 바이트 그대로 남아야 한다. **줄** 이 아니라
# **문장** 으로 찾는다: 가운데 문장이 길어지면 줄바꿈 위치는 정당하게 바뀌고,
# 이 옵션이 약속한 것은 줄 나눔이 아니라 표현이다.
KEEP = {
    "en": ["This is the first sentence of section 4. The Korean side never touches it.",
           "This is the third and last sentence of section 4."],
    "ja": ["セクション 4 の最初の文です。この文は ko が触れません。",
           "セクション 4 の 3 番目で最後の文です。"],
}
leaked_ids = [l.strip() for l in io.open(leakfile, encoding="utf-8").read().split("\n") if l.strip()]

out = {"anchor": {}, "leak": {}, "keep": {}, "keep_ctl": {}}
for doc in (aligned, drift):
    ko_ids = ids(read(head, "ko", doc))
    for lang in ("en", "ja"):
        new = read(tx, lang, doc)
        key = f"{doc}:{lang}"
        if new is None:
            out["anchor"][key] = "missing"
            continue
        n_ids = ids(new)
        dup = sorted({i for i in n_ids if n_ids.count(i) > ko_ids.count(i)})
        out["anchor"][key] = dict(ko=len(ko_ids), tgt=len(n_ids), dup=dup)
        # 남의 heading 본문이 통째로 실려 왔는가 — 베이스라인에 있던 anchor id 가
        # 이 문서에서 ko 보다 많이 나오면 그게 증거다.
        out["leak"][key] = sorted({i for i in leaked_ids
                                   if n_ids.count(i) > ko_ids.count(i)})

for lang in ("en", "ja"):
    for root, slot in ((tx, "keep"), (ctl, "keep_ctl")):
        if not root:
            continue
        new = read(root, lang, aligned)
        if new is None:
            continue
        flat = " ".join(new.split())   # 줄바꿈만 다른 경우를 흡수
        out[slot][lang] = [s for s in KEEP[lang] if " ".join(s.split()) in flat]
io.open(outfile, "w", encoding="utf-8").write(json.dumps(out, ensure_ascii=False, indent=2))
PY
sed 's/^/    /' "$tmpdir/verdict.json"; echo

eval "$(python3 - "$tmpdir/verdict.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
dup = sum(len(v["dup"]) for v in d["anchor"].values() if isinstance(v, dict))
missing = sum(1 for v in d["anchor"].values() if v == "missing")
leak = sum(len(v) for v in d["leak"].values())
keep = sum(len(v) for v in d["keep"].values())
keep_ctl = sum(len(v) for v in d["keep_ctl"].values())
have_ctl = 1 if d["keep_ctl"] else 0
# 이름 주의: `KEEP` 은 --keep 플래그 변수다. eval 이 그걸 덮으면
# cleanup 이 브랜치를 남긴다 — 그래서 N_ 접두사를 쓴다.
print(f"DUP={dup}; MISSING={missing}; LEAK={leak}; N_KEEP={keep}; N_KEEP_CTL={keep_ctl}; HAVE_CTL={have_ctl}")
PY
)"

if (( MISSING > 0 )); then
  bad "(4) 번역 PR 에 픽스처 문서가 없다 ($MISSING 개)"
elif (( DUP == 0 )); then
  ok "(4) anchor id 복제 0 — ko 다중집합과 일치"
else
  defect "(4) anchor id 가 복제됐다 ($DUP 건) — 베이스라인을 그대로 베꼈다"
fi
if (( LEAK == 0 )); then
  ok "(5) 베이스라인에 실렸던 남의 anchor 가 본문에 나타나지 않는다"
else
  defect "(5) 베이스라인의 남의 anchor 가 본문에 실려 왔다 ($LEAK 건)"
fi
if (( N_KEEP == 4 )); then
  ok "(6) 안 바뀐 문장 4개(en 2 · ja 2)가 바이트 동일 — 기능이 약속대로 동작"
elif (( N_KEEP >= 2 )); then
  warn "(6) 안 바뀐 문장 $N_KEEP/4 만 바이트 동일 (모델 편차)"
else
  bad "(6) 안 바뀐 문장이 $N_KEEP/4 만 보존됐다 — 기능이 동작하지 않는다"
fi
if (( HAVE_CTL )); then
  if (( N_KEEP >= N_KEEP_CTL )); then
    ok "(7) 대조군(플래그 off) 보존 $N_KEEP_CTL/4 ≤ ON $N_KEEP/4 — 플래그가 실제로 일한다"
  else
    bad "(7) 대조군이 더 많이 보존했다 (off $N_KEEP_CTL/4 > on $N_KEEP/4)"
  fi
else
  warn "(7) 대조군 없음 — 건너뜀"
fi

echo
echo "[8] 결과"
echo "  ko PR: $ko_pr_url"
echo "  번역 PR: $tx_pr_url${tx_ctl_url:+  · 대조군: $tx_ctl_url}"
if (( fails == 0 && repro == 0 )); then
  echo "  PASS — 베이스라인 짝이 맞고 산출물도 깨끗하다."
  echo "UNIT_PRESERVE: OK"
  exit 0
fi
KEEP=1
if (( fails == 0 )); then
  echo "  REPRO — 기능은 동작하지만 베이스라인 짝이 밀린다 (결함 $repro 건)."
  echo '          고칠 자리: cloud-translate `_section_diff_splice` 의 baseline_by_j'
  echo '          (`_en_paired` 는 heading 도너용 느슨한 짝이다) 와'
  echo '          워커 게이트의 anchor id 시퀀스 검사.'
  echo "UNIT_PRESERVE: REPRO"
  exit 3
fi
echo "  FAIL — 기능 규칙 $fails 건 실패 (결함 재현 $repro 건)"
echo "UNIT_PRESERVE: FAIL"
exit 1
