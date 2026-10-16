#!/usr/bin/env bash
#
# file-by-file e2e — 큰 ko 변경이 번역 잡 하나를 통째로 잃지 않는가.
#   (a) 파일별 번역 (cloud-translate #1261, `TRANSLATE_FILE_BY_FILE_DIFF_LINES`)
#   (b) 폴링 타임아웃의 PR 알림 (cloud-translate #1263, `translate_pr._report_timeout`)
#
# ── 재현하는 결함 (TOAST-DOCS/TOAST-Cloud#416, translate-20261008-2) ───────
# ko PR 이 두 파일을 바꿨다 — `framework-api.md` +1,172/-774 · `partner-api.md` 4줄.
# 잡 하나가 1시간 job_timeout 을 `framework-api.md` 에 다 쓰고 **아무것도 커밋하지
# 못했다** (4줄짜리 파일까지). 그리고 그 타임아웃은 GitHub 어디에도 남지 않았다 —
# 엔트리 스크립트의 폴링 루프가 포기하는 경로는 워커의 실패 보고(실패 코멘트 +
# `warning` 라벨)를 타지 않아 Log & Crash 한 줄만 남았고, `번역 대기열` 라벨을 단 채
# 같은 base 의 뒤 번역들을 조용히 막았다.
#   (a) #1261: ko diff 가 기준 이상이면 파일×언어를 하나씩, 각자 `file_timeout` 으로
#       돌린다 — 넘친 파일만 '번역 실패로 제외된 파일' 로 빠지고 나머지는 한 PR 에 커밋.
#   (b) #1263: 폴링 타임아웃도 실패한 잡처럼 source PR 에 코멘트 + `warning` 라벨.
#
# ── 픽스처 (세션 브랜치에 생성 — alpha 상주 아님) ─────────────────────────
#   {ko,en,ja}/fbf-small.md — 필드 표 하나. ko 편집은 `필수` 열 Yes/No → Y/N 뿐이라
#       언어 중립 셀 미러(M7)가 **모델 호출 0** 으로 끝낸다 (= partner-api 의 4줄).
#   {ko,en,ja}/fbf-large.md — 절 40개 × 문단. ko 편집은 문단마다 문장 하나 추가라
#       모델 호출이 수십 번 필요하다 (= framework-api).
#   이 비대칭이 시간 초과를 결정적으로 만든다: 짧은 file_timeout 안에 small 은 반드시
#   끝나고 large 는 반드시 넘친다. 모델이 실패하기를 "바라는" 픽스처가 아니다.
#
# ── 판정 ─────────────────────────────────────────────────────────────────
#   [fbf] ko PR 1 (두 파일) · `FILE_BY_FILE_DIFF_LINES=20` · `FILE_TIMEOUT=20`
#     (1) 로그 `File-by-file: ko diff N lines >= 20`
#     (2) 부분 성공 — translate_pr.py 가 non-zero 로 끝나고 `PARTIAL:` 표식
#     (3) 번역 PR 이 열렸고 en/ja fbf-small 만 담는다 (fbf-large 없음)
#     (4) PR 본문 '번역 실패로 제외된 파일' 에 fbf-large · `file timed out` · `--only ko/fbf-large.md`
#     (5) en/ja fbf-small = 기존 번역에서 필수 셀만 Y/N (바이트, 번역 헤더 주석 · pre-align 표식 제외)
#     (6) 번역 PR 에 `warning` 라벨
#   [poll] ko PR 2 (fbf-large 만) · 파일별 끔 · `JOB_TIMEOUT=30`
#     (7) 로그 `Timed out after` · translate_pr.py non-zero
#     (8) 번역 PR 이 없다 (아무것도 커밋되지 않았다)
#     (9) ko PR 에 실패 코멘트 — `timed out after` · `--only` 재시도 안내   ← #1263
#     (10) ko PR 에 `warning` 라벨                                         ← #1263
#
# ── exit code ─────────────────────────────────────────────────────────────
#   0  전부 통과 (`FILE_BY_FILE: OK`)
#   3  결함 재현 (`FILE_BY_FILE: REPRO`) — (1)(3)(4)(9)(10) 중 실패. #1261/#1263 이전
#      코드의 기대값 ((a) 는 한 잡이 시간을 다 써서 PR 이 없고, (b) 는 GitHub 에 흔적이 없다)
#   1  기능 규칙 실패 (`FILE_BY_FILE: FAIL`)
#   2  인프라 — 픽스처·PR 생성 실패
#
# Usage:
#   source ./load_env.sh
#   CLOUD_TRANSLATE_DIR=~/works/cloud-translate bash scripts/e2e-file-by-file.sh
#   bash scripts/e2e-file-by-file.sh --case fbf          # (a) 만
#   bash scripts/e2e-file-by-file.sh --case poll         # (b) 만
#   bash scripts/e2e-file-by-file.sh --keep
#
# 실패 알림의 리뷰 요청은 `TRANSLATE_PROBLEM_REVIEWERS` 로 이 e2e 의 실행자에게만
# 보낸다 (`E2E_PROBLEM_REVIEWERS`, 기본 hyunil-shin) — 기본값은 운영자 둘이다.
# e2e 는 **CLI 엔진으로 돈다** (`--engine api` 를 쓰지 않는다 — CLAUDE.md).
set -eo pipefail
set -u

REPO="TOAST-DOCS/Agent-Test"
BASE_SOURCE="alpha"
TS="$(date -u +%Y%m%d-%H%M%S)"
SESSION_BRANCH="e2e-filebyfile/$TS"
HEAD_FBF="translate-test-filebyfile/$TS-fbf"
HEAD_POLL="translate-test-filebyfile/$TS-poll"
SMALL="fbf-small.md"
LARGE="fbf-large.md"
CASE="all"
KEEP=0
FILE_TIMEOUT="${FBF_FILE_TIMEOUT:-20}"
JOB_TIMEOUT="${FBF_JOB_TIMEOUT:-30}"
REVIEWERS="${E2E_PROBLEM_REVIEWERS:-[\"hyunil-shin\"]}"

CLOUD_TRANSLATE_DIR="${CLOUD_TRANSLATE_DIR:-$HOME/works/cloud-translate}"
CLOUD_TRANSLATE_PY="${CLOUD_TRANSLATE_PY:-$HOME/works/cloud-translate/.venv/bin/python}"
PRESET_CATALOG_DIR="${PRESET_CATALOG_DIR:-$HOME/works/cloud-translate}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --case) CASE="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    -h|--help) sed -n '2,60p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[[ "$CASE" =~ ^(all|fbf|poll)$ ]] || { echo "error: --case 는 all|fbf|poll" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
tmpdir="$(mktemp -d)"
pr_fbf=""; pr_poll=""; tx_fbf=""

source "$(cd "$(dirname "$0")" && pwd)/e2e-label.sh"

cleanup() {
  local rc=$?
  for wt in "$tmpdir/base" "$tmpdir/tx"; do
    [[ -d "$wt" ]] && git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
  git checkout -q --detach 2>/dev/null || true
  if (( KEEP )); then
    echo; echo "--keep: 보존 — $SESSION_BRANCH (ko PR: ${pr_fbf:-} ${pr_poll:-}, 번역 PR: ${tx_fbf:-없음})"
    return $rc
  fi
  echo; echo "[cleanup] PR 닫기 · 브랜치 정리"
  [[ -n "$tx_fbf" ]] && gh pr close "$tx_fbf" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  local p b
  for p in "$pr_fbf" "$pr_poll"; do
    [[ -n "$p" ]] && gh pr close "$p" --repo "$REPO" >/dev/null 2>&1 || true
  done
  for b in "$HEAD_FBF" "$HEAD_POLL"; do
    while read -r t; do
      [[ -n "$t" ]] && git push origin ":$t" >/dev/null 2>&1 || true
    done < <(git ls-remote --heads origin "refs/heads/translate/${b}*" 2>/dev/null | sed 's|.*refs/heads/||')
    git push origin ":$b" >/dev/null 2>&1 || true
  done
  git push origin ":$SESSION_BRANCH" >/dev/null 2>&1 || true
  git branch -D -q "$SESSION_BRANCH" "$HEAD_FBF" "$HEAD_POLL" 2>/dev/null || true
  return $rc
}
trap cleanup EXIT

echo "=== file-by-file e2e (case=$CASE) ==="
echo "  cloud-translate : $CLOUD_TRANSLATE_DIR ($(git -C "$CLOUD_TRANSLATE_DIR" log --oneline -1 2>/dev/null | cut -c1-60))"
echo "  session         : $SESSION_BRANCH"
echo "  file_timeout    : ${FILE_TIMEOUT}s (fbf) · job_timeout ${JOB_TIMEOUT}s (poll)"
echo

: "${DASHBOARD_BASE_URL:?load_env.sh 를 source 하라 (webhook 토글)}"
: "${DASHBOARD_API_TOKEN:?load_env.sh 를 source 하라 (webhook 토글)}"
[[ -x "$CLOUD_TRANSLATE_PY" ]] || { echo "error: python 없음: $CLOUD_TRANSLATE_PY" >&2; exit 1; }
[[ -f "$CLOUD_TRANSLATE_DIR/.env" ]] || { echo "error: $CLOUD_TRANSLATE_DIR/.env 없음" >&2; exit 1; }
source "$(cd "$(dirname "$0")" && pwd)/e2e-webhook-toggle.sh"
echo "[0] webhook 비활성화"
set_webhook_repo_enabled false

fails=0; repro=0
ok()    { echo "  PASS  $1"; }
bad()   { echo "  FAIL  $1"; fails=$((fails + 1)); }
defect(){ echo "  FAIL  $1  (결함 — 재현)"; repro=$((repro + 1)); }

# ── 1) 세션 브랜치 + 픽스처 ────────────────────────────────────────────────
echo "[1] 세션 브랜치 생성 + 픽스처 시드"
git fetch -q origin "$BASE_SOURCE"
git checkout -q -B "$SESSION_BRANCH" "origin/$BASE_SOURCE"
python3 - "$TS" "$SMALL" "$LARGE" <<'PY'
import io, os, sys
ts, small, large = sys.argv[1:4]
L = {"ko": 0, "en": 1, "ja": 2}
ROWS = [("appKey", "String", "Yes", "앱키", "Appkey", "アプリケーションキー"),
        ("serviceId", "String", "Yes", "서비스 ID", "Service ID", "サービスID"),
        ("pageNum", "Integer", "No", "페이지 번호", "Page number", "ページ番号"),
        ("pageSize", "Integer", "No", "페이지 크기", "Page size", "ページサイズ")]
HDR = {"ko": "| 이름 | 타입 | 필수 | 설명 |", "en": "| Name | Type | Required | Description |",
       "ja": "| 名前 | タイプ | 必須 | 説明 |"}
SMALL_T = {"ko": ("fbf-small e2e 픽스처", "요청 파라미터"), "en": ("fbf-small e2e fixture", "Request Parameters"),
           "ja": ("fbf-small e2e フィクスチャ", "リクエストパラメータ")}
# 큰 문서 — 절 40개. 절마다 다른 문장이라 번역 캐시·dedup 이 서로를 덮지 않는다.
TOPICS = ["인스턴스", "볼륨", "스냅샷", "이미지", "보안 그룹", "키페어", "로드 밸런서", "서브넷",
          "라우팅 테이블", "인터넷 게이트웨이", "플로팅 IP", "네트워크 인터페이스", "백업", "모니터링",
          "알림", "오토 스케일", "템플릿", "태그", "프로젝트", "멤버"]
TOPICS_EN = ["instance", "volume", "snapshot", "image", "security group", "key pair", "load balancer",
             "subnet", "routing table", "internet gateway", "floating IP", "network interface", "backup",
             "monitoring", "notification", "auto scale", "template", "tag", "project", "member"]
TOPICS_JA = ["インスタンス", "ボリューム", "スナップショット", "イメージ", "セキュリティグループ", "キーペア",
             "ロードバランサー", "サブネット", "ルーティングテーブル", "インターネットゲートウェイ", "Floating IP",
             "ネットワークインターフェース", "バックアップ", "モニタリング", "通知", "オートスケール", "テンプレート",
             "タグ", "プロジェクト", "メンバー"]
for lang, i in L.items():
    out = ["<!-- pre-align:aligned sig=e2ef1b5a11 -->", "", '<a id="fbf-small"></a>', f"# {SMALL_T[lang][0]}", "",
           '<a id="fbf-small-params"></a>', f"## {SMALL_T[lang][1]} {{ #fbf-small-params }}", "",
           HDR[lang], "| --- | --- | --- | --- |"]
    out += [f"| {n} | {t} | {r} | {d[i]} |" for n, t, r, *d in ROWS]
    io.open(os.path.join(lang, small), "w", encoding="utf-8", newline="").write("\n".join(out) + "\n")
    title = {"ko": "fbf-large e2e 픽스처", "en": "fbf-large e2e fixture", "ja": "fbf-large e2e フィクスチャ"}[lang]
    out = ["<!-- pre-align:aligned sig=e2ef1b5a12 -->", "", '<a id="fbf-large"></a>', f"# {title}", ""]
    for k in range(40):
        ko_t, en_t, ja_t = TOPICS[k % 20], TOPICS_EN[k % 20], TOPICS_JA[k % 20]
        n = k // 20 + 1
        head = {"ko": f"{ko_t} 관리 {n}", "en": f"Managing {en_t} {n}", "ja": f"{ja_t}の管理 {n}"}[lang]
        body = {"ko": f"{ko_t}을(를) 생성하고 관리하는 방법을 설명합니다. 이 절은 {n}번째 안내입니다.",
                "en": f"Describes how to create and manage {en_t}. This section is guide number {n}.",
                "ja": f"{ja_t}を作成して管理する方法を説明します。この節は{n}番目の案内です。"}[lang]
        out += [f'<a id="fbf-large-{k}"></a>', f"## {head} {{ #fbf-large-{k} }}", "", body, ""]
    io.open(os.path.join(lang, large), "w", encoding="utf-8", newline="").write("\n".join(out))
print(f"  생성: {{ko,en,ja}}/{small} (필드 표) · {{ko,en,ja}}/{large} (절 40)")
PY
git add -- {ko,en,ja}/"$SMALL" {ko,en,ja}/"$LARGE"
git commit -q -m "e2e(file-by-file): 픽스처 시드 ($TS)"
session_sha="$(git rev-parse HEAD)"
git push -q origin "$SESSION_BRANCH"
git worktree add -q --detach "$tmpdir/base" "$session_sha"

edit_small() {
  python3 - "ko/$SMALL" <<'PY'
import io, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
assert t.count("| Yes |") == 2 and t.count("| No |") == 2
io.open(p, "w", encoding="utf-8", newline="").write(t.replace("| Yes |", "| Y |").replace("| No |", "| N |"))
PY
}
edit_large() {
  python3 - "ko/$LARGE" <<'PY'
import io, re, sys
p = sys.argv[1]
t = io.open(p, encoding="utf-8", newline="").read()
t, n = re.subn(r"(이 절은 (\d+)번째 안내입니다\.)",
               r"\1 변경 사항은 콘솔에 즉시 반영되며, 반영된 설정은 다음 요청부터 적용됩니다.", t)
assert n == 40, n
io.open(p, "w", encoding="utf-8", newline="").write(t)
PY
}

preset_eval="$(python3 "$(dirname "$0")/preset_options.py" \
  --catalog-dir "$PRESET_CATALOG_DIR" --mode local \
  --engine claude-code --model claude-haiku-4-5 \
  --tm-top-k 1 --chunk-workers 2 --workers 2)" || exit 1
eval "$preset_eval"
echo "  translate argv: ${PRESET_ARGS[*]}"
e2e_ensure_label "$REPO"

run_translate() {  # $1 ko PR url, $2 log, env 는 호출자가 앞에 붙인다
  set +e
  (cd "$CLOUD_TRANSLATE_DIR" && \
    "$CLOUD_TRANSLATE_PY" translate/translate_pr.py "$1" \
      --base-branch "$SESSION_BRANCH" "${PRESET_ARGS[@]}") > "$2" 2>&1
  local rc=$?
  set -e
  return $rc
}

# ── (a) 파일별 번역 ────────────────────────────────────────────────────────
if [[ "$CASE" == all || "$CASE" == fbf ]]; then
  echo
  echo "[2] (a) 파일별 번역 — ko PR 1: $SMALL (Y/N 만) + $LARGE (문단 40개)"
  git checkout -q -B "$HEAD_FBF" "$SESSION_BRANCH"
  edit_small; edit_large
  git add -- "ko/$SMALL" "ko/$LARGE"
  git commit -q -m "e2e(file-by-file): ko 편집 — small Y/N · large 문단 40 ($TS)"
  git push -q origin "$HEAD_FBF"
  pr_fbf="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_FBF" \
    --title "e2e(file-by-file): 큰 ko 변경 — 파일별 번역 ($TS)" \
    --body "cloud-translate #1261 검증 — 큰 ko 변경에서 시간이 넘친 파일만 빠지고 나머지는 한 PR 에 커밋돼야 한다 (TOAST-DOCS/TOAST-Cloud#416 모양)." \
    --label "$E2E_LABEL")"
  echo "  ko PR: $pr_fbf"
  log="$tmpdir/fbf.log"
  rc=0
  TRANSLATE_FILE_BY_FILE_DIFF_LINES=20 TRANSLATE_FILE_TIMEOUT="$FILE_TIMEOUT" \
  TRANSLATE_FILE_BY_FILE_BUDGET=900 TRANSLATE_PROBLEM_REVIEWERS="$REVIEWERS" \
    run_translate "$pr_fbf" "$log" || rc=$?
  grep -E "File-by-file|Neutral-cell mirror|timed out|PARTIAL|Translation PR|ERROR" "$log" | cut -c1-200 | sed 's/^/    /' || true
  echo "    엔진: CLI 호출 $(grep -c 'with Claude Code CLI' "$log" || true) · api.anthropic.com $(grep -c 'api.anthropic.com' "$log" || true) (0 이어야 한다)"

  grep -qE 'File-by-file: ko diff [0-9]+ lines >= 20' "$log" \
    && ok "(1) 파일별 모드로 돌았다 ($(grep -oE 'ko diff [0-9]+ lines' "$log" | head -1))" \
    || defect "(1) 파일별 모드 로그가 없다"
  if (( rc != 0 )) && grep -qE '^[[:space:]]*PARTIAL:' "$log"; then
    ok "(2) 부분 성공 — exit $rc + PARTIAL 표식"
  else
    bad "(2) 부분 성공이 아니다 (exit $rc, PARTIAL $(grep -cE '^[[:space:]]*PARTIAL:' "$log" || true))"
  fi
  tx_fbf="$(grep -oE 'Translation PR: https://[^ ]+' "$log" | tail -1 | awk '{print $NF}' || true)"
  if [[ -z "$tx_fbf" ]]; then
    defect "(3) 번역 PR 이 열리지 않았다 — 한 파일의 시간 초과가 잡 전체를 잃게 했다"
    defect "(4) 제외 파일 안내를 볼 PR 이 없다"
  else
    echo "  번역 PR: $tx_fbf"
    e2e_label_pr "$REPO" "$tx_fbf" || true
    files="$(gh pr view "$tx_fbf" --repo "$REPO" --json files --jq '[.files[].path] | join(" ")')"
    if [[ " $files " == *" en/$SMALL "* && " $files " == *" ja/$SMALL "* && "$files" != *"$LARGE"* ]]; then
      ok "(3) 번역 PR 은 en/ja $SMALL 만 담는다"
    else
      defect "(3) 번역 PR 파일이 기대와 다르다: $files"
    fi
    body="$(gh pr view "$tx_fbf" --repo "$REPO" --json body --jq .body)"
    if grep -q '번역 실패로 제외된 파일' <<<"$body" && grep -q "ko/$LARGE" <<<"$body" \
       && grep -q 'file timed out' <<<"$body" && grep -q -- "--only ko/$LARGE" <<<"$body"; then
      ok "(4) PR 본문이 $LARGE 를 시간 초과로 제외했다고 알린다 (--only 안내 포함)"
    else
      defect "(4) PR 본문에 제외 안내가 없거나 불완전하다"
      grep -n -A6 '번역 실패로 제외된 파일' <<<"$body" | head -12 | sed 's/^/      /' || true
    fi
    tx_head="$(gh pr view "$tx_fbf" --repo "$REPO" --json headRefName --jq .headRefName)"
    git fetch -q origin "$tx_head"
    git worktree add -q --detach "$tmpdir/tx" "origin/$tx_head"
    b5=0
    for lang in en ja; do
      if python3 - "$tmpdir/base/$lang/$SMALL" "$tmpdir/tx/$lang/$SMALL" <<'PY'
import io, sys
# 번역 헤더 주석 · pre-align 표식(번역 잡이 sig 를 다시 찍는다)은 비교에서 뺀다
strip = lambda t: "\n".join(l for l in t.split("\n")
                            if "machine_translated" not in l and "pre-align:aligned" not in l).strip("\n")
b = io.open(sys.argv[1], encoding="utf-8").read().replace("| Yes |", "| Y |").replace("| No |", "| N |")
a = io.open(sys.argv[2], encoding="utf-8").read()
sys.exit(0 if strip(a) == strip(b) else 1)
PY
      then b5=$((b5 + 1)); else echo "    [$lang] $SMALL 차이:"; diff "$tmpdir/base/$lang/$SMALL" "$tmpdir/tx/$lang/$SMALL" | head -10 | sed 's/^/      /' || true; fi
    done
    (( b5 == 2 )) && ok "(5) en/ja $SMALL = 기존 번역에서 필수 셀만 Y/N" \
                  || bad "(5) en/ja $SMALL 이 기대와 다르다 ($b5/2)"
    labels="$(gh pr view "$tx_fbf" --repo "$REPO" --json labels --jq '[.labels[].name] | join(",")')"
    [[ ",$labels," == *",warning,"* ]] && ok "(6) 번역 PR 에 warning 라벨" \
                                      || bad "(6) 번역 PR 에 warning 라벨이 없다 ($labels)"
  fi
fi

# ── (b) 폴링 타임아웃 알림 ────────────────────────────────────────────────
if [[ "$CASE" == all || "$CASE" == poll ]]; then
  echo
  echo "[3] (b) 폴링 타임아웃 — ko PR 2: $LARGE 만 · 파일별 끔 · job_timeout ${JOB_TIMEOUT}s"
  git checkout -q -B "$HEAD_POLL" "$SESSION_BRANCH"
  edit_large
  git add -- "ko/$LARGE"
  git commit -q -m "e2e(file-by-file): ko 편집 — large 문단 40 ($TS, poll)"
  git push -q origin "$HEAD_POLL"
  pr_poll="$(gh pr create --repo "$REPO" --base "$SESSION_BRANCH" --head "$HEAD_POLL" \
    --title "e2e(file-by-file): 폴링 타임아웃 알림 ($TS)" \
    --body "cloud-translate #1263 검증 — 번역 잡이 시간 초과로 끝나면 이 PR 에 실패 코멘트와 warning 라벨이 남아야 한다." \
    --label "$E2E_LABEL")"
  echo "  ko PR: $pr_poll"
  log="$tmpdir/poll.log"
  rc=0
  TRANSLATE_FILE_BY_FILE_DIFF_LINES=0 TRANSLATE_JOB_TIMEOUT="$JOB_TIMEOUT" \
  TRANSLATE_PROBLEM_REVIEWERS="$REVIEWERS" \
    run_translate "$pr_poll" "$log" || rc=$?
  grep -E "Timed out|timeout|Translation PR|WARNING: could not|ERROR" "$log" | cut -c1-200 | sed 's/^/    /' || true
  if (( rc != 0 )) && grep -q 'Timed out after' "$log"; then
    ok "(7) 폴링 타임아웃으로 끝났다 (exit $rc)"
  else
    bad "(7) 폴링 타임아웃이 아니다 (exit $rc) — job_timeout 안에 끝났다면 픽스처가 너무 작다"
  fi
  if grep -qE 'Translation PR: https://' "$log"; then
    bad "(8) 번역 PR 이 열렸다 — 타임아웃 시나리오가 성립하지 않았다"
  else
    ok "(8) 번역 PR 이 없다 (아무것도 커밋되지 않았다)"
  fi
  sleep 3
  comments="$(gh pr view "$pr_poll" --repo "$REPO" --json comments --jq '[.comments[].body] | join("\n----\n")')"
  if grep -q 'timed out after' <<<"$comments" && grep -q -- '--only' <<<"$comments"; then
    ok "(9) ko PR 에 실패 코멘트 — timed out · --only 재시도 안내"
  else
    defect "(9) ko PR 에 타임아웃 코멘트가 없다 (코멘트 $(gh pr view "$pr_poll" --repo "$REPO" --json comments --jq '.comments | length')개)"
  fi
  labels="$(gh pr view "$pr_poll" --repo "$REPO" --json labels --jq '[.labels[].name] | join(",")')"
  [[ ",$labels," == *",warning,"* ]] && ok "(10) ko PR 에 warning 라벨" \
                                    || defect "(10) ko PR 에 warning 라벨이 없다 ($labels)"
fi

echo
echo "[4] 결과"
[[ -n "$pr_fbf" ]]  && echo "  (a) ko PR: $pr_fbf · 번역 PR: ${tx_fbf:-없음}"
[[ -n "$pr_poll" ]] && echo "  (b) ko PR: $pr_poll"
if (( fails == 0 && repro == 0 )); then echo "FILE_BY_FILE: OK"; exit 0; fi
KEEP=1
if (( fails == 0 )); then echo "FILE_BY_FILE: REPRO"; exit 3; fi
echo "FILE_BY_FILE: FAIL"; exit 1
