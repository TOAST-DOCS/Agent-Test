#!/usr/bin/env bash
#
# 번역 PR 문서 정비(post_maint, cloud-translate#1282) e2e — **webhook 경로, 배포본**.
#
# 리포 override `post_maint=true` 인 리포의 ko PR 이 머지되면, 번역 잡이 PR 을
# 열기 전에 **이번 번역이 쓴 파일에만** 마크업 정정 · 빈 번역 채우기 · 깨진 표
# 정비를 돌려 같은 브랜치에 커밋하고 Jinja 문법 오류를 보고(warning 라벨)하는지.
# 결과는 번역 PR 의 새 댓글 `## 문서 정비 (번역 PR)` (cloud-translate#1294 부터 —
# 그 전에는 PR 본문 절이었다): 도구 × 파일 실행 이력 표 + 수정 · 보류 · 오류.
#
# ── 픽스처 ────────────────────────────────────────────────────────────────
# alpha 상주 `{ko,en,ja}/fill-stub-sample.md` (빈 번역 stub) 와
# `{ko,en,ja}/fix-tables-sample.md` (깨진 표) 를 그대로 쓰고, 세션 base 에만 셋을
# 더 심는다:
#   M9  — 세 언어 fill-stub-sample.md 끝에 문단에 붙은 표 (python-markdown 이
#         표로 안 만든다). ko 에도 심는 이유: 마크업 정정은 ko 원문도 고치고,
#         en/ja 에만 심으면 정정 뒤 표 수가 ko 와 달라져 표 정비가 그 절을 지운다.
#   Jinja — ja/fix-tables-sample.md 끝에 닫히지 않은 `{% if %}` (보고만, 수정 안 함)
#   대조군 — en/fix-links.md 끝에 같은 M9. 이 PR 의 파일이 아니므로 그대로여야 한다.
# ko PR 은 두 문서의 첫 절 문단에 한 문장씩 더한다 (번역이 그 두 파일을 쓰게).
#
# ── 판정 (전부 결정적) ────────────────────────────────────────────────────
#   [1] 번역 PR 에 '문서 정비 (번역 PR)' 댓글 1개, 본문에는 그 절이 없다
#       (= POST_MAINT 가 잡에 닿았다) + 실행 이력 표에 PR 파일 6개의 행
#   [2] 커밋 post-maint(fix-markup|fill-empty|fix-tables) 셋 다
#   [3] Jinja 보고: 댓글 🚫 줄(ja/fix-tables-sample.md) + `warning` 라벨
#   [4] PR 파일 ⊆ 두 픽스처 × ko/en/ja, 대조군 en/fix-links.md 는 base 와 바이트 동일
#   [5] M9 정정: 세 언어 fill-stub-sample.md 의 표 앞에 빈 줄
#   [6] 빈 번역: en/ja fill-stub-sample.md 의 id 있는 stub 절 5개가 채워졌거나,
#       남았으면 댓글 '보류' 에 그 절이 적혀 있다 (채우기 도구의 블록 구조 가드는
#       모델 결과에 따라 보류한다 — 보류 자체는 정상, 보고 누락이 결함. #1557)
#   [7] 깨진 표: en/ja fix-tables-sample.md 의 절별 표 수 == ko
#   [8] 정상 절 보존: en/ja `#fix-tables-untouched` 가 base 와 바이트 동일
#   [9] Jinja 줄은 고치지 않았다 (ja 에 미닫힘 `{% if` 그대로)
#   [10] before/after 스크린샷 (cloud-translate#1362): 정비 댓글의 '스크린샷' 절에 before ·
#       after 이미지 짝, pr-attach-screenshot 키 모양(<owner>__<repo>/PR-<n>/), URL 이 200
#       PNG, 찍은 절의 파일 ⊆ PR 파일, 커밋한 렌더 도구(마크업 · 채우기 · 표)가 전부 찍혔다,
#       preview 링크 ref 가 이 PR 의 커밋 SHA
#
# Usage:
#   source ./load_env.sh
#   bash scripts/e2e-post-maint.sh [--timeout 3600] [--pipeline-branch PR-1294]
#
# --pipeline-branch: 번역 잡을 그 Jenkins multibranch 잡으로 돌린다 (미머지 코드 검증).
#   그 잡이 있고 빌드가 1회 이상이어야 한다 (파라미터 등록).
#
# webhook repo 등록(번역만 켜고 한글 검수는 끈다 — 이 e2e 의 판정 밖이다)·pipeline
# 브랜치·override 는 세션 동안만 바꾸고 trap 에서 원래 값으로 되돌린다. 세션 브랜치·PR 은
# 검토용으로 남긴다 (정리: README 의 세션 브랜치 정리 절).
set -eo pipefail
set -u

DASHBOARD_BASE_URL="${DASHBOARD_BASE_URL:-}"
DASHBOARD_API_TOKEN="${DASHBOARD_API_TOKEN:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/e2e-repo.sh"
source "$SCRIPT_DIR/e2e-label.sh"

TIMEOUT=3600
PIPELINE_BRANCH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --pipeline-branch) PIPELINE_BRANCH="$2"; shift 2 ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$DASHBOARD_BASE_URL" && -n "$DASHBOARD_API_TOKEN" ]] || {
  echo "error: source ./load_env.sh 먼저" >&2; exit 2; }

TS="$(date -u +%Y%m%d%H%M%S)"
BASE="e2e-postmaint/$TS"
HEAD="translate-test-postmaint/$TS"
WT="$(mktemp -d)"
ORIG_PM="__unset__"
WEBHOOK_ROW=""   # 실행 전 webhook 대상 repo 행 (JSON) — cleanup 이 그대로 되돌린다

_override() {  # $1 = overrides JSON
  python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$REPO" "$1" <<'PY'
import json, sys, urllib.request
base, tok, repo, ov = sys.argv[1:5]
req = urllib.request.Request(f"{base}/api/webhooks/repos/override",
    data=json.dumps({"repo": repo, "job": "translate", "overrides": json.loads(ov)}).encode(),
    method="POST", headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"})
urllib.request.urlopen(req, timeout=15).read()
PY
}

_webhook_row() {   # 현재 행 → {translate_enabled, ko_review_enabled, pipeline_branch} JSON
  curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" "$DASHBOARD_BASE_URL/api/webhooks/repos" \
  | python3 -c "
import json,sys
w=sys.argv[1].lower()
row=next((x for x in json.load(sys.stdin).get('repos') or []
          if (x.get('repo') or '').lower()==w or (x.get('repo') or '').lower().endswith('/'+w)), None)
print(json.dumps({k:(row or {}).get(k) or d for k,d in
      (('translate_enabled',False),('ko_review_enabled',False),('pipeline_branch',''))}))" "$REPO"
}

_set_webhook_row() {   # $1 = {translate_enabled, ko_review_enabled, pipeline_branch} JSON
  python3 - "$DASHBOARD_BASE_URL" "$DASHBOARD_API_TOKEN" "$REPO" "$1" <<'PY'
import json, sys, urllib.request
base, tok, repo, row = sys.argv[1:5]
req = urllib.request.Request(f"{base}/api/webhooks/repos",
    data=json.dumps({"repo": repo, **json.loads(row)}).encode(), method="POST",
    headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"})
urllib.request.urlopen(req, timeout=15).read()
print(f"  webhook repo {repo}: {row}")
PY
}

_read_pm() {
  curl -sS -H "Authorization: Bearer $DASHBOARD_API_TOKEN" "$DASHBOARD_BASE_URL/api/webhooks/repos" \
  | python3 -c "
import json,sys
d=json.load(sys.stdin); want=sys.argv[1].lower()
for k,v in (d.get('repo_overrides') or {}).items():
    if k.lower().endswith(want):
        t=(v.get('translate') or {})
        print(json.dumps(t['post_maint']) if 'post_maint' in t else 'null'); break
else: print('null')" "$REPO"
}

cleanup() {
  local rc=$?
  trap - EXIT INT TERM
  if [[ -n "$WEBHOOK_ROW" ]]; then
    echo "  [cleanup] webhook repo 원복"
    _set_webhook_row "$WEBHOOK_ROW" || echo "  [cleanup] WARN: webhook repo 원복 실패 — 수동 확인" >&2
  fi
  if [[ "$ORIG_PM" != "__unset__" ]]; then
    echo "  [cleanup] override post_maint 원복 → $ORIG_PM"
    _override "{\"post_maint\": $ORIG_PM}" || echo "  [cleanup] WARN: 원복 실패 — 수동 확인" >&2
  fi
  git -C "$REPO_DIR" worktree remove --force "$WT" >/dev/null 2>&1 || true
  exit $rc
}
trap cleanup EXIT INT TERM

echo "== [0] webhook repo 켜기 + override post_maint 켜기 ($REPO)"
# webhook e2e 규약 (e2e-webhook-toggle.sh): 실행 중에만 켜고 끝나면 원래 행으로 되돌린다.
WEBHOOK_ROW="$(_webhook_row)"
echo "  webhook repo 원래 행: $WEBHOOK_ROW"
_set_webhook_row "$(python3 -c "
import json,sys; r=json.loads(sys.argv[1])
print(json.dumps({'translate_enabled': True, 'ko_review_enabled': False,
                  'pipeline_branch': sys.argv[2] or r['pipeline_branch']}))" "$WEBHOOK_ROW" "$PIPELINE_BRANCH")"
ORIG_PM="$(_read_pm)"
echo "  원래 값: $ORIG_PM"
_override '{"post_maint": true}'
[[ "$(_read_pm)" == "true" ]] || { echo "FAIL: override 가 켜지지 않았다" >&2; exit 1; }

echo "== [1] 세션 base $BASE (alpha + 결함 시드)"
git -C "$REPO_DIR" fetch -q origin +refs/heads/alpha:refs/remotes/origin/alpha
git -C "$REPO_DIR" worktree add -q --detach "$WT" origin/alpha
python3 - "$WT" <<'PY'
import sys, pathlib
wt = pathlib.Path(sys.argv[1])
m9 = {
    "ko": "옵션은 아래와 같습니다.\n| 옵션 | 값 |\n| --- | --- |\n| mode | fast |\n",
    "en": "The options are listed below.\n| Option | Value |\n| --- | --- |\n| mode | fast |\n",
    "ja": "オプションは以下のとおりです。\n| オプション | 値 |\n| --- | --- |\n| mode | fast |\n",
}
def append(rel, block):
    p = wt / rel
    p.write_text(p.read_text().rstrip("\n") + "\n\n" + block)
for lang, block in m9.items():
    append(f"{lang}/fill-stub-sample.md", block)
append("ja/fix-tables-sample.md", '{% if "gov" in build_flags %}\nこの行は gov ビルドにのみ表示されます。\n')
append("en/fix-links.md", m9["en"])
PY
git -C "$WT" add -A
git -C "$WT" commit -q -m "e2e(post-maint): 결함 시드 — M9 · 미닫힘 {% if %} · 대조군"
git -C "$WT" push -q origin "HEAD:refs/heads/$BASE"
BASE_SHA="$(git -C "$WT" rev-parse HEAD)"

echo "== [2] ko PR ($HEAD → $BASE)"
python3 - "$WT" <<'PY'
import sys, pathlib
wt = pathlib.Path(sys.argv[1])
anchor = "이 문서는 사용자 가이드 메뉴(`ko/nav.yml`) 에 등록하지 않습니다."
for f in ("fill-stub-sample.md", "fix-tables-sample.md"):
    p = wt / "ko" / f
    t = p.read_text()
    assert anchor in t, f
    line = next(l for l in t.splitlines() if l.startswith(anchor))
    p.write_text(t.replace(line, line + " 문서 정비 e2e 가 이 문장을 추가했습니다.", 1))
PY
git -C "$WT" commit -q -am "e2e(post-maint): ko 첫 절에 한 문장 추가"
git -C "$WT" push -q origin "HEAD:refs/heads/$HEAD"
for lb in content-agent "한글 검수"; do
  gh label create "$lb" --repo "$REPO" >/dev/null 2>&1 || true
done
KO_PR_URL="$(gh pr create --repo "$REPO" --base "$BASE" --head "$HEAD" \
  --title "[e2e post-maint $TS] ko 두 문서에 한 문장" \
  --body "번역 PR 문서 정비(post_maint) e2e — scripts/e2e-post-maint.sh" \
  --label content-agent --label "한글 검수")"
e2e_label_pr "$REPO" "$KO_PR_URL"
echo "  ko PR: $KO_PR_URL"
sleep 10
gh pr merge "$KO_PR_URL" --repo "$REPO" --merge >/dev/null
echo "  merged"

echo "== [3] 번역 PR 대기 (최대 ${TIMEOUT}s)"
TX_PR=""
deadline=$(( $(date +%s) + TIMEOUT ))
while (( $(date +%s) < deadline )); do
  TX_PR="$(gh pr list --repo "$REPO" --base "$BASE" --state all --json number,headRefName \
    --jq '[.[] | select(.headRefName | startswith("translate/"))][0].number // empty')"
  [[ -n "$TX_PR" ]] && break
  sleep 30
done
[[ -n "$TX_PR" ]] || { echo "FAIL: 번역 PR 이 ${TIMEOUT}s 안에 열리지 않았다" >&2; exit 1; }
# 라벨(flag_problem_pr)·정비 댓글은 PR 생성 직후 붙는다 — 정비 댓글이 보일 때까지 (최대 5분)
for _ in $(seq 1 30); do
  gh api "repos/$REPO/issues/$TX_PR/comments" --jq '.[].body' 2>/dev/null \
    | grep -q '^## 문서 정비 (번역 PR)' && break
  sleep 10
done
e2e_label_pr "$REPO" "$TX_PR"
echo "  번역 PR: #$TX_PR"

echo "== [4] 판정"
python3 - "$REPO" "$TX_PR" "$BASE_SHA" <<'PY'
import json, re, subprocess, sys
repo, num, base_sha = sys.argv[1:4]

def gh(*a):
    return subprocess.run(["gh", *a], check=True, capture_output=True, text=True).stdout

pr = json.loads(gh("pr", "view", num, "--repo", repo, "--json",
                   "body,labels,files,commits,headRefOid,url"))
head = pr["headRefOid"]
body = pr["body"]
labels = {l["name"] for l in pr["labels"]}
files = {f["path"] for f in pr["files"]}
msgs = [c["messageHeadline"] for c in pr["commits"]]
comments = json.loads(gh("api", f"repos/{repo}/issues/{num}/comments", "--paginate"))
pm = [c["body"] for c in comments if c["body"].startswith("## 문서 정비 (번역 PR)")]
note = pm[0] if pm else ""

def raw(path, ref):
    out = subprocess.run(["gh", "api", f"repos/{repo}/contents/{path}?ref={ref}",
                          "-H", "Accept: application/vnd.github.raw"],
                         capture_output=True, text=True)
    return out.stdout if out.returncode == 0 else None

def sections(text):
    out, cur = {}, None
    for line in text.splitlines():
        m = re.match(r'<a id="([^"]+)"></a>', line)
        if m:
            cur = m.group(1); out[cur] = []
        elif cur:
            out[cur].append(line)
    return {k: "\n".join(v) for k, v in out.items()}

def n_tables(s):
    return len(re.findall(r"^\s*\|?\s*:?-{3,}", s, re.M))

res = []
def check(name, ok, detail=""):
    res.append(ok)
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))

check("1a '문서 정비 (번역 PR)' 댓글 1개", len(pm) == 1, f"{len(pm)}개")
check("1b PR 본문에는 그 절이 없다", "문서 정비 (번역 PR)" not in body)
rows = re.findall(r"^\| `([^`]+)` \|", note, re.M)
check("1c 실행 이력 표 = PR 파일", set(rows) == files, f"{len(rows)}행")
for tool in ("fix-markup", "fill-empty", "fix-tables"):
    n = sum(1 for m in msgs if m.startswith(f"post-maint({tool})"))
    check(f"2 커밋 post-maint({tool})", n > 0, f"{n}건")
check("3a Jinja 🚫 줄 (ja/fix-tables-sample.md)",
      bool(re.search(r"🚫 Jinja 문법 검사 — `ja/fix-tables-sample\.md`", note)))
check("3b warning 라벨", "warning" in labels, ",".join(sorted(labels)))
allowed = {f"{l}/{d}.md" for l in ("ko", "en", "ja") for d in ("fill-stub-sample", "fix-tables-sample")}
check("4a PR 파일 ⊆ 두 픽스처", files <= allowed, ", ".join(sorted(files - allowed)) or f"{len(files)}개")
check("4b 대조군 en/fix-links.md 바이트 동일", raw("en/fix-links.md", head) == raw("en/fix-links.md", base_sha))
lead = {"ko": "옵션은 아래와 같습니다.", "en": "The options are listed below.", "ja": "オプションは以下のとおりです。"}
for l, s in lead.items():
    t = raw(f"{l}/fill-stub-sample.md", head) or ""
    check(f"5 M9 정정 {l}", f"{s}\n\n|" in t)
stub_ids = ("fill-stub-body", "fill-stub-table", "fill-stub-code", "fill-stub-heading", "fill-stub-heading-child")
for l in ("en", "ja"):
    secs = sections(raw(f"{l}/fill-stub-sample.md", head) or "")
    left = [i for i in stub_ids if "TODO: translate" in secs.get(i, "TODO: translate")]
    held = re.findall(rf"^- ⚠ 빈 번역 채우기 — `{l}/fill-stub-sample\.md`: (.*)$", note, re.M)
    unreported = [i for i in left if not any(i in h for h in held)]
    check(f"6 빈 번역 {l}", not unreported,
          f"미보고 {','.join(unreported)}" if unreported else
          (f"{5 - len(left)}/5 채움 · 보류 보고 {','.join(left)}" if left else "5/5 채움"))
ko_secs = sections(raw("ko/fix-tables-sample.md", head) or "")
for l in ("en", "ja"):
    t = raw(f"{l}/fix-tables-sample.md", head) or ""
    secs = sections(t)
    bad = [i for i in ko_secs if n_tables(ko_secs[i]) != n_tables(secs.get(i, ""))]
    check(f"7 표 수 == ko {l}", not bad, ",".join(bad) or f"{len(ko_secs)} 절")
    base_secs = sections(raw(f"{l}/fix-tables-sample.md", base_sha) or "")
    check(f"8 #fix-tables-untouched 보존 {l}",
          secs.get("fix-tables-untouched") == base_secs.get("fix-tables-untouched"))
ja_ft = raw("ja/fix-tables-sample.md", head) or ""
check("9 Jinja 줄 미수정 (ja)", '{% if "gov" in build_flags %}' in ja_ft and "{% endif" not in ja_ft)

# [10] before/after 스크린샷 (cloud-translate#1362) — 렌더를 바꾼 절마다 before · after (+ 대조군)
import urllib.request
shot_part = note.split("### 스크린샷 — 정비 before / after", 1)
check("10a 정비 댓글에 스크린샷 절", len(shot_part) == 2)
shot_note = shot_part[1] if len(shot_part) == 2 else ""
imgs = re.findall(r"!\[(before|after|대조군)\]\((https?://[^)\s]+)\)", shot_note)
nb = sum(1 for k, _ in imgs if k == "before")
na = sum(1 for k, _ in imgs if k == "after")
check("10b before·after 이미지 짝", nb >= 1 and nb == na, f"before {nb} · after {na} · 대조군 {len(imgs) - nb - na}")
scope = f"{repo.replace('/', '__')}/PR-{num}/"
check("10c pr-attach-screenshot 키 모양", bool(imgs) and all(scope in u for _, u in imgs), scope)
bad = []
for _, u in imgs:
    try:
        with urllib.request.urlopen(urllib.request.Request(u, method="GET"), timeout=30) as r:
            if r.status != 200 or not r.headers.get("Content-Type", "").startswith("image/png") \
                    or not r.read(8).startswith(b"\x89PNG"):
                bad.append(u)
    except Exception:  # noqa: BLE001
        bad.append(u)
check("10d 이미지 URL 200 · PNG", bool(imgs) and not bad, ", ".join(bad[:3]) or f"{len(imgs)}장")
sec_paths = set(re.findall(r"^#### `([^`]+)`", shot_note, re.M))
check("10e 찍은 절의 파일 ⊆ PR 파일", bool(sec_paths) and sec_paths <= files, ", ".join(sorted(sec_paths)))
shot_tools = set(re.findall(r"^#### `[^`]+`.* — (.+)$", shot_note, re.M))
shot_tools = {t.strip() for line in shot_tools for t in line.split("·")}
want = {lbl for tool, lbl in (("fix-markup", "마크업 정정"), ("fill-empty", "빈 번역 채우기"),
                              ("fix-tables", "깨진 표 정비"))
        if any(m.startswith(f"post-maint({tool})") for m in msgs)}
check("10g 커밋한 렌더 도구가 전부 스크린샷에", want <= shot_tools,
      "누락 " + ", ".join(sorted(want - shot_tools)) if want - shot_tools else ", ".join(sorted(shot_tools)))
shas = set(re.findall(r"(?:tx|ko)_ref=([0-9a-f]{40})", shot_note))
pr_shas = {c["oid"] for c in pr["commits"]}
check("10f preview 링크 ref = 이 PR 의 커밋 SHA", bool(shas) and shas <= pr_shas | {base_sha},
      ", ".join(s[:7] for s in sorted(shas)))

print(f"\n  번역 PR: {pr['url']}")
print("POST_MAINT:", "OK" if all(res) else f"FAIL ({res.count(False)}/{len(res)})")
sys.exit(0 if all(res) else 3)
PY
