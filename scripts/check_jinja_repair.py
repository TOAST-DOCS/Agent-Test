#!/usr/bin/env python3
"""Jinja 문법 오류 복원 e2e — 결함 심기(seed)와 판정(verify). 모델 없음.

    python3 scripts/check_jinja_repair.py seed <repo-root>
    python3 scripts/check_jinja_repair.py verify --log <cli log> [--label AFTER]

픽스처 archive/jinja-repair/{ko,en,ja}/ 는 **정상** 문서 둘이다 (sample · control).
seed 가 세션 브랜치에 넷을 만든다 — 결함마다 자기 문서라 서로 가리지 않는다:

  jinja-repair-sample.md   en: `{% endif %}` 유실(표 뒤)       ja: `{% end if %}` 띄어 씀
                           → ko 대조로 증명되는 **확실한 수정** (결정적 PR)
  jinja-repair-opener.md   en: `{% if "gov" not in build_flags %}` 유실
                           → ko 의 여는 태그를 되넣는 수정 (어느 PR 이든 정답과 같아야 한다)
  jinja-repair-author.md   ko·en·ja: `{% if release_2026_11 %}` 의 `{% endif %}` 유실
                           (저자 실수가 번역에 그대로 복사된 모양) → 대조할 정답이 없어
                           **개발자 검토 PR**. ko 는 후보 중 모델이 고르고 en/ja 는 그 ko 를 따른다
  jinja-repair-control.md  정상 (대조군) — 어느 PR 에도 들어가면 안 된다

verify 는 cli 로그의 `PR opened:` 줄에서 PR 둘을 찾아 GitHub 에서 파일을 읽고 판정한다.
exit: 0 OK · 3 FAIL · 2 인프라 · 1 사용법
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = "TOAST-DOCS/Agent-Test"
FIX = "archive/jinja-repair"
DOCS = ("jinja-repair-sample.md", "jinja-repair-opener.md", "jinja-repair-author.md",
        "jinja-repair-control.md")


def _drop_first(text: str, line: str, after: str) -> str:
    """``after`` 가 처음 나온 뒤의 첫 ``line`` 한 줄을 지운다."""
    i = text.index(after)
    j = text.index(line + "\n", i)
    return text[:j] + text[j + len(line) + 1:]


def seed(root: Path) -> None:
    for lang in ("ko", "en", "ja"):
        sample = (root / FIX / lang / "jinja-repair-sample.md").read_text(encoding="utf-8")
        control = (root / FIX / lang / "jinja-repair-control.md").read_text(encoding="utf-8")
        s, o, a = sample, sample, sample
        if lang == "en":
            s = _drop_first(s, "{% endif %}", "kr1-api.gov-nhncloudservice.com")
            o = _drop_first(o, '{% if "gov" not in build_flags %}', "jinja-repair-opener")
        if lang == "ja":
            k = s.index("jinja-repair-typo")
            s = s[:k] + s[k:].replace("{% endif %}", "{% end if %}", 1)
        a = _drop_first(a, "{% endif %}", "release_2026_11")
        out = root / lang
        (out / "jinja-repair-sample.md").write_text(s, encoding="utf-8")
        (out / "jinja-repair-opener.md").write_text(o, encoding="utf-8")
        (out / "jinja-repair-author.md").write_text(a, encoding="utf-8")
        (out / "jinja-repair-control.md").write_text(control, encoding="utf-8")
    print("seeded:", ", ".join(f"{l}/{d}" for l in ("ko", "en", "ja") for d in DOCS))


# ── verify ──────────────────────────────────────────────────────────────────
def gh(*args: str) -> str:
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout


def pr_files(num: int) -> list[str]:
    return [f["filename"] for f in json.loads(gh("api", f"repos/{REPO}/pulls/{num}/files"))]


def file_at(path: str, ref: str) -> str:
    import base64
    j = json.loads(gh("api", f"repos/{REPO}/contents/{path}?ref={ref}"))
    return base64.b64decode(j["content"]).decode("utf-8")


def tagless(text: str) -> list[str]:
    return [ln for ln in text.split("\n") if "{%" not in ln]


def verify(log: Path, label: str, root: Path) -> int:
    text = log.read_text(encoding="utf-8", errors="replace")
    urls = re.findall(r"PR opened: (https://github\.com/\S+/pull/(\d+))", text)
    fails: list[str] = []
    ok: list[str] = []

    def check(cond: bool, msg: str) -> None:
        (ok if cond else fails).append(msg)

    check("❌ jinja 문법 오류" in text, "판정: 결함 문서가 있으면 잡이 실패를 말한다 (exit 1 줄)")
    if label == "BEFORE":
        check(not urls, "BEFORE: 수정 PR 을 열지 않는다 (판정만)")
        return _report(label, ok, fails)

    check(len(urls) == 2, f"PR 두 개가 열린다 (실제 {len(urls)})")
    if len(urls) != 2:
        return _report(label, ok, fails)
    det_url, det_n = urls[0]
    rev_url, rev_n = urls[1]
    det = json.loads(gh("api", f"repos/{REPO}/pulls/{det_n}"))
    rev = json.loads(gh("api", f"repos/{REPO}/pulls/{rev_n}"))
    det_files, rev_files = set(pr_files(int(det_n))), set(pr_files(int(rev_n)))
    det_labels = {l["name"] for l in det["labels"]}
    rev_labels = {l["name"] for l in rev["labels"]}
    print(f"결정적 PR: {det_url}\n검토 PR  : {rev_url}")
    print(f"  결정적 파일: {sorted(det_files)}\n  검토 파일  : {sorted(rev_files)}")

    check({"en/jinja-repair-sample.md", "ja/jinja-repair-sample.md"} <= det_files,
          "[확실] en 닫는 태그 유실 · ja 띄어 쓴 태그 → 결정적 PR")
    check(not any(p.startswith("ko/") for p in det_files), "[확실] 결정적 PR 에 ko 없음 (ko 는 대조 기준)")
    check({"ko/jinja-repair-author.md", "en/jinja-repair-author.md",
           "ja/jinja-repair-author.md"} <= rev_files,
          "[검토] 저자 실수 ko·en·ja → 개발자 검토 PR")
    check(not (det_files & rev_files), "두 PR 이 같은 파일을 건드리지 않는다")
    check(all("jinja-repair-control" not in p for p in det_files | rev_files),
          "[대조군] control 문서는 어느 PR 에도 없다")
    check("jinja-fix" in det_labels and "사람 확인 필요" not in det_labels,
          f"결정적 PR 라벨 = jinja-fix (실제 {sorted(det_labels)})")
    check({"jinja-fix", "사람 확인 필요"} <= rev_labels,
          f"검토 PR 라벨 = jinja-fix + 사람 확인 필요 (실제 {sorted(rev_labels)})")

    head_d, head_r = det["head"]["sha"], rev["head"]["sha"]
    base = det["base"]["sha"]
    for lang in ("en", "ja"):
        want = (root / FIX / lang / "jinja-repair-sample.md").read_text(encoding="utf-8")
        got = file_at(f"{lang}/jinja-repair-sample.md", head_d)
        check(got == want, f"[확실] {lang}/jinja-repair-sample.md = 정상 픽스처와 바이트 동일")
    opener_pr = head_d if "en/jinja-repair-opener.md" in det_files else head_r
    want = (root / FIX / "en" / "jinja-repair-sample.md").read_text(encoding="utf-8")
    got = file_at("en/jinja-repair-opener.md", opener_pr)
    check(got == want, "[여는 태그] en/jinja-repair-opener.md = 정상 픽스처 (ko 의 여는 태그를 되넣음)"
          f" — {'결정적' if opener_pr == head_d else '검토'} PR")

    # 저자 실수: 본문 줄은 그대로, 태그는 ko 와 en/ja 가 같은 자리.
    positions = {}
    for lang in ("ko", "en", "ja"):
        before = file_at(f"{lang}/jinja-repair-author.md", base)
        after = file_at(f"{lang}/jinja-repair-author.md", head_r)
        check(tagless(after) == tagless(before), f"[검토] {lang} 본문 줄 불변 (태그 줄만 바뀜)")
        lines = after.split("\n")
        idx = [i for i, ln in enumerate(lines) if ln.strip() == "{% endif %}"]
        # release 블록의 닫는 태그 = release_2026_11 뒤 첫 endif — 앞에 있는 본문 줄 수
        start = next(i for i, ln in enumerate(lines) if "release_2026_11" in ln)
        close = next(i for i in idx if i > start)
        positions[lang] = sum(1 for ln in lines[start:close] if ln.strip() and "{%" not in ln)
        intended = (root / FIX / lang / "jinja-repair-sample.md").read_text(encoding="utf-8")
        print(f"  [info] {lang} 모델/규칙이 고른 자리 = 의도한 자리: {after == intended}")
    check(len(set(positions.values())) == 1,
          f"[검토] en/ja 가 ko 와 같은 자리에서 닫는다 (본문 줄 수 {positions})")

    comments = json.loads(gh("api", f"repos/{REPO}/pulls/{rev_n}/comments?per_page=100"))
    check(len(comments) >= 3, f"[검토] 바뀐 줄 인라인 코멘트 ≥ 3 (실제 {len(comments)})")
    body = rev["body"] or ""
    check("블록이 감싸는 내용" in body and "문법이 통과한다고 맞는 수정은 아닙니다" in body,
          "[검토] 본문에 블록이 감싸는 내용 · 위험 문구")
    return _report(label, ok, fails)


def _report(label: str, ok: list[str], fails: list[str]) -> int:
    for m in ok:
        print(f"  ✅ {m}")
    for m in fails:
        print(f"  ❌ {m}")
    print(f"JINJA_REPAIR[{label}]: {'OK' if not fails else 'FAIL'} "
          f"({len(ok)} ok · {len(fails)} fail)")
    return 0 if not fails else 3


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("seed")
    s.add_argument("root")
    v = sub.add_parser("verify")
    v.add_argument("--log", required=True)
    v.add_argument("--label", default="AFTER")
    v.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    a = ap.parse_args()
    if a.cmd == "seed":
        seed(Path(a.root))
        return 0
    return verify(Path(a.log), a.label, Path(a.root))


if __name__ == "__main__":
    sys.exit(main())
