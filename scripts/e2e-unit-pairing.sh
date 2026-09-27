#!/usr/bin/env bash
#
# unit-pairing e2e — `replace` 런 안에서 바뀐 유닛이 **자기 기존 번역**과
# 짝지어지는가 (cloud-translate `_align_replace_run` · `_split_unit_baseline`).
#
# ── 재현하는 결함 ─────────────────────────────────────────────────────────
# block splice 는 ko 의 `replace` 런 안에서 새 유닛과 옛 유닛을 **위치로**
# 짝지었다 (`new[k] ↔ old[k]`). ko 가 유닛을 제자리에서 고칠 때는 맞지만, 고친
# 유닛 **앞에** 새 유닛을 끼우는 순간 어긋난다 — 고친 유닛의 진짜 짝은 첫 삽입
# 유닛에 넘어가 거부되고(`ko-dissimilar`), 고친 유닛 자신은 짝이 없어진다. 그러면
# unit-preserve 의 기존 번역도, heading·상자 제목 도너도 없이 새로 번역되어
# **ko 가 안 건드린 줄**이 바뀐다.
#
#   9월 번역 재생 T22 (nhn-cloud-foundry#35): 상자 앞에 문단·목록 + 상자 본문
#   한 줄 수정 → 상자 제목 `Tips` → `Tip`.
#   Gamebase aos-etc (9월 입력 재생): 두 줄 문단 사이에 문장·목록을 끼워 문단이
#   둘로 갈라짐 → 뒷줄 유닛이 짝 없이 번역, 앞 유닛은 뒷줄까지 담긴 옛 번역을
#   받아 그 줄이 **두 번** 들어갈 여지.
#
# ── 픽스처 (세션 브랜치에 생성 — alpha 상주 아님) ─────────────────────────
#   {ko,en,ja}/unit-pairing.md — pre-align 정렬본. 섹션 둘:
#     [box]   문단 + `!!! tip` 상자. en/ja 상자 제목은 모델이 스스로 고를 리 없는
#             `Good to know` / `豆知識`, 상자 둘째 줄도 고유 문구.
#             ko 편집: 상자 **앞에** 문단 + 목록 2항목, 상자 첫 줄만 수정.
#     [split] 두 줄짜리 문단 (L1, L2). en/ja 의 L2 는 고유 문구(`without
#             exception` / `例外なく`). ko 편집: L1 과 L2 **사이에** 새 문장
#             + 빈 줄 + 목록 → [L1+새 문장] [목록] [L2] 로 갈라진다.
#
# ── 판정 ─────────────────────────────────────────────────────────────────
#   [A] 결정적 층 (모델 없음) — 실제 translate_diff 에 모델 호출만 가로채
#       유닛마다 **어떤 기존 번역이 붙는지** 본다.
#       (1) 상자 유닛에 기존 상자 번역이 붙는다                     ← 결함
#       (2) 갈라진 뒷줄(L2) — ko 가 안 바꿨으니 모델로 보내지 않고 기존 번역을
#           그대로 쓴다: 에코 산출물에 L2 기존 번역이 정확히 한 번 (보냈다면
#           L2 번역**만** 붙어야 한다)                                   ← 결함
#       (3) 갈라진 앞 유닛에 L1 번역이 붙고, L2 번역은 딸려 오지 않는다 ← 결함
#       (4) 새로 끼운 유닛(문단·목록)에는 아무것도 붙지 않는다       ← 전제
#   [B] 산출물 층 — 로컬 translate_pr.py (CLI 엔진, 권장 preset) 실제 번역.
#       (5) 번역 성공 (exit 0, PARTIAL 없음)
#       (6) en/ja 상자 제목이 기존 그대로 (`Good to know` / `豆知識`) ← 결함(증상)
#           — 짝을 찾으면 `_reuse_unchanged_admonition_labels` 가 결정적으로
#           되돌리므로 모델 운이 아니다.
#       (7) L2 번역이 문서에 정확히 한 번 (복제 0)                  ← 결함(증상)
#       (8) ko 가 안 건드린 문장(상자 둘째 줄 · L2)이 바이트 그대로   ← 기능
#           (4개 중 3개 이상 PASS, 1~2 WARN — 기존 번역을 보여 줘도 모델 편차는 남는다)
#       (9) anchor id 다중집합이 ko == en == ja
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`UNIT_PAIRING: OK`) — 수정된 코드의 기대값
#   3  결함 재현 (`UNIT_PAIRING: REPRO`) — 수정 전 코드의 기대값
#   1  기능 규칙 실패 또는 픽스처가 조건을 잃음 (`UNIT_PAIRING: FAIL`)
#   2  인프라 — 번역 PR 미감지 · translate_pr.py 비정상 종료
#
# Usage:
#   source ./load_env.sh      # webhook 토글에 필요 (--dry 는 불필요)
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate/.claude/worktrees/<wt> \
#     bash scripts/e2e-unit-pairing.sh            # [A]+[B]
#   bash scripts/e2e-unit-pairing.sh --dry        # [A] 만 (모델·네트워크 없음)
#   bash scripts/e2e-unit-pairing.sh --keep       # PR·브랜치 보존
#
# 두 경로가 따로다: `CLOUD_TRANSLATE_DIR` 는 **검증할 코드**(워크트리 가능,
# `.env` 필요), `PRESET_CATALOG_DIR` 는 **운영 preset 의 출처**(`dashboard/.env`
# 의 `TRANSLATE_TRANSLATE_PRESETS` 가 있는 체크아웃, 기본 ~/works/cloud-translate).
# 워크트리에는 보통 `dashboard/.env` 가 없고 두면 viewer 테스트가 깨진다.
#
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-unitpairing/$TS"
HEAD_BRANCH="translate-test-unitpairing/$TS"
DOC="unit-pairing.md"
KEEP=0
DRY=0

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --dry)  DRY=1; shift ;;
    -h|--help) sed -n '2,70p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
LOG="$tmpdir/translate.log"
ko_pr_url=""; tx_pr_url=""

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/base" "$tmpdir/head" "$tmpdir/tx"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  if (( KEEP )) || (( DRY )); then
    (( DRY )) || { echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${ko_pr_url:-없음}, 번역 PR: ${tx_pr_url:-없음})"; }
    git checkout -q "$BASE_SOURCE" 2>/dev/null || true
    return $rc
  fi
  echo; echo "[cleanup] PR 닫기 · 브랜치 정리"
  [[ -n "$tx_pr_url" ]] && gh pr close "$tx_pr_url" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  [[ -n "$ko_pr_url" ]] && gh pr close "$ko_pr_url" --repo "$REPO" >/dev/null 2>&1 || true
  local b
  while read -r b; do
    [[ -n "$b" ]] && git push origin ":$b" >/dev/null 2>&1 || true
  done < <(git ls-remote --heads origin "refs/heads/translate/${HEAD_BRANCH}*" 2>/dev/null | sed 's|.*refs/heads/||')
  git push origin ":$HEAD_BRANCH"    >/dev/null 2>&1 || true
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git checkout -q "$BASE_SOURCE" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "=== unit-pairing e2e ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 2>/dev/null | cut -c1-60))"
echo "  preset 출처     : $PRESET_CATALOG_DIR"
echo "  session         : $SESSION_BRANCH"
echo "  픽스처          : {ko,en,ja}/$DOC"
echo "  모드            : $( ((DRY)) && echo '[A] 결정적 층만 (--dry)' || echo '[A]+[B]' )"
echo

[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }

fails=0; repro=0
ok()    { echo "  PASS  $1"; }
bad()   { echo "  FAIL  $1"; fails=$((fails + 1)); }
defect(){ echo "  FAIL  $1  (결함 — 재현)"; repro=$((repro + 1)); }
warn()  { echo "  WARN  $1"; }

if (( ! DRY )); then
  : "${DASHBOARD_BASE_URL:?load_env.sh 를 source 하라 (webhook 토글)}"
  : "${DASHBOARD_API_TOKEN:?load_env.sh 를 source 하라 (webhook 토글)}"
  [[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
  source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
  echo "[0] webhook 비활성화"
  set_webhook_repo_enabled false
fi

# ── 1) 세션 브랜치 + 픽스처 ────────────────────────────────────────────────
echo "[1] 세션 브랜치 생성 + 픽스처 시드"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"

python3 - "$TS" "$DOC" <<'PY'
import io, os, sys
ts, doc = sys.argv[1:3]
MARK = "<!-- pre-align:aligned sig=e2e0a1r1ng0 -->\n\n"
DOCS = {
"ko": f"""{MARK}<a id="upair"></a>
# unit-pairing e2e 픽스처

이 문서는 자동 생성된 e2e 픽스처입니다 ({ts}).

<a id="upair-box"></a>
## 상자 앞에 끼우기 {{ #upair-box }}

이 섹션은 상자 앞에 새 문단이 들어가는 모양을 재현합니다.

!!! tip "알아두기"
    데이터를 보내는 방법은 자세히 보기의 **수집 방법** 탭을 참고합니다.
    이 줄은 ko 가 건드리지 않는 상자의 둘째 줄입니다.

<a id="upair-split"></a>
## 문단 가르기 {{ #upair-split }}

설정할 수 있는 값은 세 가지입니다.
값은 반드시 아래 표에 있는 것만 사용할 수 있습니다.

| 값 | 설명 |
|---|---|
| ko | 한국어 |
| en | 영어 |
| ja | 일본어 |
""",
"en": f"""{MARK}<a id="upair"></a>
# unit-pairing e2e fixture

This document is a generated e2e fixture ({ts}).

<a id="upair-box"></a>
## Insert before a box {{ #upair-box }}

This section reproduces a new paragraph landing in front of a box.

!!! tip "Good to know"
    For how to send data, refer to the **Collection Method** tab in the details view.
    This is the box's second line, one the Korean side leaves alone, word for word.

<a id="upair-split"></a>
## Split a paragraph {{ #upair-split }}

There are three configurable values.
Only the values listed in the table below may be used, without exception.

| Value | Description |
|---|---|
| ko | Korean |
| en | English |
| ja | Japanese |
""",
"ja": f"""{MARK}<a id="upair"></a>
# unit-pairing e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです ({ts})。

<a id="upair-box"></a>
## ボックスの前に挿入 {{ #upair-box }}

このセクションは、ボックスの前に新しい段落が入る形を再現します。

!!! tip "豆知識"
    データの送信方法は、詳細表示の**収集方法**タブを参照してください。
    これはボックスの2行目で、ko が一字一句触れない行です。

<a id="upair-split"></a>
## 段落の分割 {{ #upair-split }}

設定できる値は3種類です。
値は、下の表にあるものだけを例外なく使用できます。

| 値 | 説明 |
|---|---|
| ko | 韓国語 |
| en | 英語 |
| ja | 日本語 |
""",
}
for lang, text in DOCS.items():
    io.open(os.path.join(lang, doc), "w", encoding="utf-8", newline="").write(text)
print(f"  생성: {{ko,en,ja}}/{doc}")
PY
git add -- "ko/$DOC" "en/$DOC" "ja/$DOC"
git commit -q -m "e2e(unit-pairing): 픽스처 시드 ($TS)"
session_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$SESSION_BRANCH"

# ── 2) ko 편집 ─────────────────────────────────────────────────────────────
echo "[2] ko 편집 — 상자 앞 삽입 + 상자 첫 줄 수정 · 두 줄 문단 사이 삽입"
git checkout -q -B "$HEAD_BRANCH" "$SESSION_BRANCH"
python3 - "ko/$DOC" <<'PY'
import io, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
BOX = '!!! tip "알아두기"\n    데이터를 보내는 방법은 자세히 보기의 **수집 방법** 탭을 참고합니다.\n'
NEW_BOX = ("예시로 보기 행에는 입력한 설정으로 예시 지표가 몇 개의 시리즈로 나뉘는지 표시됩니다.\n\n"
           "- **예시 보기**를 클릭하면 요청 본문 예시가 펼쳐집니다.\n"
           "- 입력을 바꾸면 즉시 다시 계산됩니다.\n\n"
           '!!! tip "알아두기"\n    데이터를 보내는 방법은 생성 완료 창, 자세히 보기의 **수집 방법** 탭을 참고합니다.\n')
L1 = "설정할 수 있는 값은 세 가지입니다.\n"
NEW_L1 = (L1 + "값의 형식은 BCP 47 언어 태그 표준을 따릅니다.\n\n"
          "- 기본 언어: 소문자 2자리 코드\n- 지역 구분: 언어-국가 조합\n\n")
for old in (BOX, L1):
    assert t.count(old) == 1, old
t = t.replace(BOX, NEW_BOX).replace(L1, NEW_L1)
io.open(p, "w", encoding="utf-8", newline="").write(t)
print(f"  {p}: 상자 앞 문단+목록, 상자 첫 줄 수정 · L1/L2 사이 문장+목록")
PY
git add -- "ko/$DOC"
git commit -q -m "e2e(unit-pairing): ko 편집 ($TS)"
head_sha="$(git rev-parse HEAD)"
(( DRY )) || git push -q origin "$HEAD_BRANCH"

# ── 3) [A] 결정적 층 ───────────────────────────────────────────────────────
echo
echo "[3] [A] 결정적 층 — 유닛마다 붙는 기존 번역 (모델 없음)"
git worktree add -q --detach "$tmpdir/base" "$session_sha"
git worktree add -q --detach "$tmpdir/head" "$head_sha"
set +e
CLOUD_TRANSLATE_DIR="$CLOUD_TRANSLATE_DIR" "$CLOUD_TRANSLATE_PY" - \
  "$REPO_ROOT/scripts" "$tmpdir/base" "$tmpdir/head" "$DOC" "$tmpdir/pairing.json" <<'PY' 2>"$tmpdir/pairing.err"
import asyncio, io, json, logging, os, sys
scripts, base, head, doc, outp = sys.argv[1:6]
sys.path.insert(0, scripts)
logging.disable(logging.WARNING)
import check_unit_baselines as cub          # translate_diff + 모델 호출 가로채기 (운영과 같은 호출 구조)

EXPECT = {   # 유닛 식별 문자열 → (붙어야 하는 표지, 붙으면 안 되는 표지)
    "en": {"box": ("Good to know", None),
           "l2":  ("without exception", "three configurable"),
           "l1":  ("three configurable", "without exception")},
    "ja": {"box": ("豆知識", None),
           "l2":  ("例外なく", "3種類"),
           "l1":  ("3種類", "例外なく")},
}
WHICH = {"box": '!!! tip "알아두기"', "l2": "값은 반드시 아래 표에",
         "l1": "설정할 수 있는 값은 세 가지"}
# 갈라진 뒷줄의 기존 번역 — ko 가 안 바꿨으니 문서에 이 문장이 그대로, 한 번 있어야 한다
L2_TEXT = {"en": "Only the values listed in the table below may be used, without exception.",
           "ja": "値は、下の表にあるものだけを例外なく使用できます。"}
INSERTED = ("예시로 보기 행에는", "- **예시 보기**", "- 입력을 바꾸면", "- 기본 언어", "- 지역 구분")

def rd(root, lang):
    return io.open(os.path.join(root, lang, doc), encoding="utf-8", newline="").read()

async def main():
    cub.settings.diff_unit_preserve = True
    cub.settings.diff_granularity = "block"
    cub.settings.diff_table_rows = True
    cub.settings.diff_list_items = True
    cub.settings.diff_align_headings = True
    cub.settings.diff_mode = "incremental"
    res = {}
    for lang in ("en", "ja"):
        out, recs, _ = await cub.collect(rd(base, "ko"), rd(head, "ko"), rd(base, lang), lang)
        r = {"units": [[u[:80], (b or "")[:160]] for u, b in recs]}
        for key, marker in WHICH.items():
            hit = [b for u, b in recs if marker in u]
            want, forbid = EXPECT[lang][key]
            bl = hit[0] if hit else None
            r[key] = dict(found=bool(hit), baseline=(bl or "")[:200],
                          ok=bool(bl) and want in bl and not (forbid and forbid in bl))
        # (2) 는 계약으로 본다: ko 가 안 바꾼 뒷줄은 산출물(에코)에 기존 번역 그대로 한 번.
        #     모델로 가지 않고 재사용되면 가장 좋고, 보냈다면 그 줄의 번역만 붙어야 한다.
        sent = [b for u, b in recs if WHICH["l2"] in u]
        n = (out or "").count(L2_TEXT[lang])
        r["l2"] = dict(found=bool(sent), ok=(n == 1) and (not sent or r["l2"]["ok"]),
                       baseline=("(모델로 안 감 — 기존 번역 재사용)" if not sent else r["l2"]["baseline"])
                                + f" · 산출물 출현 {n}회")
        r["inserted_clean"] = all(not b for u, b in recs if u.lstrip().startswith(INSERTED))
        res[lang] = r
    json.dump(res, open(outp, "w"), ensure_ascii=False, indent=2)

asyncio.run(main())
PY
prc=$?
set -e
if (( prc != 0 )); then
  echo "error: [A] 검사 실행 실패" >&2; sed 's/^/    /' "$tmpdir/pairing.err" | tail -20 >&2; KEEP=1; exit 2
fi
eval "$(python3 - "$tmpdir/pairing.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for lang in ("en", "ja"):
    for k in ("box", "l2", "l1"):
        v = d[lang][k]
        prev = v["baseline"][:90].replace("\n", "⏎").replace("'", "’") or "(없음)"
        print(f"echo '    [{lang}] {k:3s}: {'OK ' if v['ok'] else 'BAD'} 기존 번역={prev}'")
for k in ("box", "l2", "l1"):
    print(f"A_{k.upper()}={int(all(d[l][k]['ok'] for l in ('en','ja')))}")
print(f"A_INS={int(all(d[l]['inserted_clean'] for l in ('en','ja')))}")
PY
)"
(( A_BOX )) && ok "(1) 상자 유닛에 기존 상자 번역이 붙는다 (en·ja)" \
            || defect "(1) 상자 유닛에 기존 번역이 없다/틀렸다 — 짝이 밀렸다"
(( A_L2 ))  && ok "(2) 갈라진 뒷줄은 기존 번역 그대로 한 번 (ko 가 안 바꾼 줄)" \
            || defect "(2) 갈라진 뒷줄이 기존 번역을 잃었다 (새로 번역되거나 두 번 들어감)"
(( A_L1 ))  && ok "(3) 갈라진 앞 유닛에 앞줄 번역만 붙는다 (뒷줄 번역은 딸려 오지 않음)" \
            || defect "(3) 갈라진 앞 유닛에 뒷줄 번역까지 붙거나 아무것도 없다"
(( A_INS )) && ok "(4) 새로 끼운 유닛에는 기존 번역이 붙지 않는다" \
            || bad "(4) 새로 끼운 유닛에 남의 기존 번역이 붙었다"

if (( DRY )); then
  echo
  if (( fails == 0 && repro == 0 )); then echo "UNIT_PAIRING: OK"; exit 0; fi
  if (( fails == 0 )); then echo "UNIT_PAIRING: REPRO"; exit 3; fi
  echo "UNIT_PAIRING: FAIL"; exit 1
fi

# ── 4) [B] 실제 번역 ───────────────────────────────────────────────────────
echo
echo "[4] [B] 실제 번역 — 로컬 translate_pr.py (CLI 엔진, 권장 preset)"
e2e_ensure_label "$REPO"
ko_pr_url="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_BRANCH" \
  --title "e2e(unit-pairing): 상자 앞 삽입 · 문단 가르기 ($TS)" \
  --body "cloud-translate replace-run 짝짓기 검증 — ko 가 안 건드린 상자 제목·문장이 기존 번역 그대로 남아야 한다." \
  --label "$E2E_LABEL")"
echo "  ko PR: $ko_pr_url"
preset_eval="$(python3 "$(dirname "$0")/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 1
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"
set +e
(cd "$CLOUD_TRANSLATE_DIR" && \
  "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$ko_pr_url" \
    --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") 2>&1 | tee "$LOG" | grep -E "Per-unit|Section-diff|anchor splice|Translation PR|PARTIAL|ERROR" | sed 's/^/    /'
tx_rc=${PIPESTATUS[0]}
set -e
if (( tx_rc == 0 )) && ! grep -qE '^[[:space:]]*PARTIAL:' "$LOG"; then
  ok "(5) 번역 성공 (exit 0, PARTIAL 없음)"
else
  bad "(5) 번역 실패/부분 (exit $tx_rc)"
fi
grep -o 'engine=[a-z-]*' "$LOG" | sort | uniq -c | sed 's/^/    /' || true
tx_pr_url="$(grep -oE 'Translation PR: https://[^ ]+' "$LOG" | tail -1 | awk '{print $NF}')"
[[ -n "$tx_pr_url" ]] || { echo "error: 번역 PR 미감지 — 로그 $LOG" >&2; KEEP=1; exit 2; }
echo "  번역 PR: $tx_pr_url"
e2e_label_pr "$REPO" "$tx_pr_url" || true
tx_head="$(gh pr view "$tx_pr_url" --repo "$REPO" --json headRefName --jq .headRefName)"
git fetch -q origin "$tx_head"
git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"

echo
echo "[5] 산출물 판정"
eval "$(python3 - "$tmpdir/head" "$tmpdir/tx" "$DOC" <<'PY'
import io, os, re, sys
head, tx, doc = sys.argv[1:4]
ANCHOR = re.compile(r'<[a-zA-Z][\w]*\b[^>]*?\bid\s*=\s*"([^"]+)"|\{\s*#([\w.:-]+)\s*\}')
def rd(root, lang):
    try:
        return io.open(os.path.join(root, lang, doc), encoding="utf-8", newline="").read()
    except OSError:
        return None
LABEL = {"en": '!!! tip "Good to know"', "ja": '!!! tip "豆知識"'}
L2 = {"en": "Only the values listed in the table below may be used, without exception.",
      "ja": "値は、下の表にあるものだけを例外なく使用できます。"}
BOX2 = {"en": "This is the box's second line, one the Korean side leaves alone, word for word.",
        "ja": "これはボックスの2行目で、ko が一字一句触れない行です。"}
ko_ids = sorted(a or b for a, b in ANCHOR.findall(rd(head, "ko")))
label = dup = keep = anchor = missing = 0
for lang in ("en", "ja"):
    t = rd(tx, lang)
    if t is None:
        missing += 1; continue
    got = re.findall(r'^!!! tip "[^"]*"', t, re.M)
    print(f"echo '    [{lang}] 상자 제목: {got}'")
    label += LABEL[lang] in t
    n = " ".join(t.split()).count(" ".join(L2[lang].split()))
    print(f"echo '    [{lang}] L2 문장 출현 {n}회 · 상자 둘째 줄 보존 {BOX2[lang] in t}'")
    dup += n > 1
    keep += (n >= 1) + (BOX2[lang] in t)
    anchor += sorted(a or b for a, b in ANCHOR.findall(t)) == ko_ids
print(f"B_LABEL={label}; B_DUP={dup}; B_KEEP={keep}; B_ANCHOR={anchor}; B_MISSING={missing}")
PY
)"
if (( B_MISSING )); then
  bad "(6) 번역 PR 에 픽스처 문서가 없다 ($B_MISSING 개)"
elif (( B_LABEL == 2 )); then
  ok "(6) en/ja 상자 제목이 기존 그대로 (Good to know / 豆知識)"
else
  defect "(6) 상자 제목이 바뀌었다 ($B_LABEL/2 보존) — ko 는 제목을 안 건드렸다"
fi
(( B_DUP == 0 )) && ok "(7) L2 번역이 문서에 한 번씩만 있다" \
                 || defect "(7) L2 번역이 복제됐다 ($B_DUP 개 언어) — 옆 유닛의 번역이 딸려 왔다"
if (( B_KEEP >= 3 )); then ok "(8) ko 가 안 건드린 문장 $B_KEEP/4 바이트 보존"
elif (( B_KEEP >= 1 )); then warn "(8) ko 가 안 건드린 문장 $B_KEEP/4 만 보존 (모델 편차)"
else defect "(8) ko 가 안 건드린 문장이 하나도 보존되지 않았다"; fi
(( B_ANCHOR == 2 )) && ok "(9) anchor id 다중집합 ko == en == ja" \
                    || bad "(9) anchor id 가 ko 와 다르다 ($B_ANCHOR/2 일치)"

echo
echo "[6] 결과"
echo "  ko PR: $ko_pr_url"
echo "  번역 PR: $tx_pr_url"
if (( fails == 0 && repro == 0 )); then echo "UNIT_PAIRING: OK"; exit 0; fi
KEEP=1
if (( fails == 0 )); then echo "UNIT_PAIRING: REPRO"; exit 3; fi
echo "UNIT_PAIRING: FAIL"; exit 1
