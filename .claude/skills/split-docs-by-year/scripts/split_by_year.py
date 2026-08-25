#!/usr/bin/env python3
"""긴 마크다운 문서를 연도별 파일로 쪼개고 include 지시자로 다시 조립한다.

대상은 릴리스 노트처럼 "날짜 heading 이 최신순으로 쌓이기만 하는" 문서다.
`<lang>/<stem>.md` 를 `<lang>/<stem>/<year>.md` 로 나누고, 원본 자리에는
헤더(첫 날짜 heading 이전 부분) + include 지시자만 남긴다.

  <a id="compute-release-notes"></a>
  ## Compute > 릴리스 노트

  {% include-markdown './release-notes/2026.md' %}

  {% include-markdown './release-notes/2025.md' %}

분리 기준은 지정한 레벨(기본 `##`)의 heading 중 4자리 연도를 담은 것이다.
heading 바로 위에 붙은 `<a id>`/`<a name>` 앵커 줄은 그 섹션과 함께 옮겨진다 —
앵커가 헤더에 남으면 문서 안 링크가 전부 깨진다.

안전장치 두 개가 있고, 둘 중 하나라도 걸리면 아무것도 쓰지 않는다:

  (1) 연도 연속성 — 한 연도가 문서 안에서 떨어진 두 구간에 나타나면 중단한다.
      대개 원문 날짜 오타(예: 2020.01.21 을 2019.01.21 로 적음)의 신호이고,
      그대로 쪼개면 파일 하나가 두 번 만들어지거나 순서가 뒤집힌다.
  (2) 왕복 검증 — 헤더 + 연도 파일들을 도로 이어붙인 결과가 원본과 내용 기준
      (공백 줄 제외) 완전히 같아야 한다. 섹션을 연속된 줄 범위로만 잘라내므로
      블록 내부는 손대지 않는다. 따라서 이 비교로 유실·중복·순서 뒤바뀜을 잡는다.

사용법:
  python3 split_by_year.py --root <repo> --doc release-notes.md            # dry-run
  python3 split_by_year.py --root <repo> --doc release-notes.md --apply
  python3 split_by_year.py --root <repo> --doc release-notes.md --check HEAD~1
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys

YEAR_RE = re.compile(r"(?:19|20)\d{2}")
ANCHOR_RE = re.compile(r"^\s*<a\s+(?:id|name)\s*=", re.IGNORECASE)
FENCE_RE = re.compile(r"^\s*(?:```|~~~)")
DEFAULT_INCLUDE = "{% include-markdown './{path}' %}"


def content_lines(text: str) -> list[str]:
    """비교용 정규화 — 공백 줄과 줄 끝 공백만 무시한다."""
    return [l.rstrip() for l in text.split("\n") if l.strip()]


def find_boundaries(lines: list[str], level: int) -> list[tuple[int, int]]:
    """(섹션 시작 줄, heading 줄) 목록. 앵커 줄까지 끌어올린 시작점을 돌려준다."""
    prefix = "#" * level + " "
    out: list[tuple[int, int]] = []
    fence = False
    for i, line in enumerate(lines):
        if FENCE_RE.match(line):
            fence = not fence
            continue
        if fence or not line.startswith(prefix) or not YEAR_RE.search(line):
            continue
        start = i
        while start - 1 >= 0 and ANCHOR_RE.match(lines[start - 1]):
            start -= 1
        out.append((start, i))
    return out


def split_doc(text: str, level: int) -> tuple[list[str], list[tuple[str, list[str]]]]:
    """(헤더 줄, [(연도, 섹션 줄)]) 로 나눈다."""
    lines = text.split("\n")
    bounds = find_boundaries(lines, level)
    if not bounds:
        raise SystemExit(
            f"error: 레벨 {level} heading 중 연도를 담은 것이 없다. "
            f"--level 을 확인하거나 (문서가 '### 2024. 01. 01.' 로 시작할 수 있다) "
            f"이 문서가 연도별 분리 대상이 맞는지 확인하라."
        )
    header = lines[:bounds[0][0]]
    sections = []
    for k, (start, head_i) in enumerate(bounds):
        end = bounds[k + 1][0] if k + 1 < len(bounds) else len(lines)
        year = YEAR_RE.search(lines[head_i]).group(0)
        sections.append((year, lines[start:end]))
    return header, sections


def group_by_year(sections: list[tuple[str, list[str]]]) -> list[tuple[str, list[str]]]:
    """문서 순서를 유지한 채 연도별로 묶는다. 연도가 흩어져 있으면 중단."""
    groups: list[tuple[str, list[str]]] = []
    for year, body in sections:
        if groups and groups[-1][0] == year:
            groups[-1][1].extend(body)
            continue
        prior = next((g for g in groups if g[0] == year), None)
        if prior is not None:
            raise SystemExit(
                f"error: {year} 가 문서 안에서 떨어진 두 구간에 나타난다 — 그대로 쪼개면\n"
                f"       {year}.md 가 두 번 만들어지거나 섹션 순서가 뒤집힌다.\n"
                f"       원문 날짜 오타일 가능성이 높다. 해당 heading 을 찾아 고친 뒤 다시 실행하라:\n"
                f"       grep -n '^#\\+ .*{year}' <파일>"
            )
        groups.append((year, list(body)))
    return groups


def render_year_file(body: list[str]) -> str:
    return "\n".join(body).strip("\n") + "\n"


def render_parent(header: list[str], years: list[str], stem: str, tpl: str) -> str:
    head = "\n".join(header).rstrip("\n")
    directives = "\n\n".join(
        tpl.replace("{path}", f"{stem}/{y}.md") for y in years
    )
    return (head + "\n\n" if head else "") + directives + "\n"


def plan_lang(root: str, lang: str, doc: str, level: int, tpl: str):
    """한 언어에 대한 분리 계획. (파일 목록, 부모 본문, 원본 텍스트) 반환."""
    path = os.path.join(root, lang, doc)
    with open(path, encoding="utf-8") as f:
        src = f.read()

    header, sections = split_doc(src, level)
    groups = group_by_year(sections)
    stem = doc[:-3] if doc.endswith(".md") else doc
    files = [(y, render_year_file(b)) for y, b in groups]
    parent = render_parent(header, [y for y, _ in files], stem, tpl)

    rebuilt = "\n".join(header).rstrip("\n") + "\n\n" + "\n\n".join(
        t.rstrip("\n") for _, t in files) + "\n"
    if content_lines(rebuilt) != content_lines(src):
        a, b = content_lines(rebuilt), content_lines(src)
        detail = f"줄 수 {len(a)} vs 원본 {len(b)}"
        for n, (x, y) in enumerate(zip(a, b)):
            if x != y:
                detail = f"내용 {n}번째 줄부터 어긋남\n  분리본: {x!r}\n  원본  : {y!r}"
                break
        raise SystemExit(f"error: {lang}/{doc} 왕복 검증 실패 — 쓰지 않고 중단한다.\n{detail}")

    return path, stem, files, parent, len(sections)


def do_check(root: str, lang: str, doc: str, rev: str, tpl: str) -> bool:
    """현재 부모의 include 를 전개해 git <rev> 시점 원본과 같은지 본다."""
    path = os.path.join(root, lang, doc)
    with open(path, encoding="utf-8") as f:
        parent = f.read()

    pattern = re.escape(tpl).replace(re.escape("{path}"), r"([^'\"]+)")
    seen: list[str] = []

    def expand(m):
        rel = m.group(1).lstrip("./")
        seen.append(rel)
        with open(os.path.join(root, lang, rel), encoding="utf-8") as f:
            return f.read()

    expanded = re.sub(pattern, expand, parent)
    orig = subprocess.run(
        ["git", "-C", root, "show", f"{rev}:{lang}/{doc}"],
        capture_output=True, text=True)
    if orig.returncode != 0:
        print(f"{lang}: git show {rev}:{lang}/{doc} 실패 — {orig.stderr.strip()}")
        return False
    ok = content_lines(expanded) == content_lines(orig.stdout)
    mark = "OK" if ok else "MISMATCH"
    print(f"{lang}: include {len(seen)}개 전개 → {rev} 대비 {mark} "
          f"({len(content_lines(expanded))} vs {len(content_lines(orig.stdout))} 줄)")
    return ok


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="저장소 루트 (기본: cwd)")
    ap.add_argument("--langs", default="ko,en,ja", help="언어 디렉터리 (쉼표 구분)")
    ap.add_argument("--doc", default="release-notes.md", help="분리할 문서 이름")
    ap.add_argument("--level", type=int, default=2, help="섹션 경계로 볼 heading 레벨")
    ap.add_argument("--include-format", default=DEFAULT_INCLUDE,
                    help="include 지시자 템플릿 ({path} 자리에 상대 경로가 들어간다)")
    ap.add_argument("--apply", action="store_true", help="실제로 파일을 쓴다 (기본은 dry-run)")
    ap.add_argument("--check", metavar="REV",
                    help="분리 후 검증: include 를 전개해 git REV 시점 원본과 비교")
    args = ap.parse_args()

    langs = [l.strip() for l in args.langs.split(",") if l.strip()]
    tpl = args.include_format

    if args.check:
        ok = all([do_check(args.root, l, args.doc, args.check, tpl) for l in langs])
        print("CHECK: " + ("OK" if ok else "MISMATCH"))
        return 0 if ok else 1

    failed = False
    for lang in langs:
        path = os.path.join(args.root, lang, args.doc)
        if not os.path.isfile(path):
            print(f"--- {lang}: {path} 없음 — 건너뛴다")
            failed = True
            continue

        path, stem, files, parent, n_sections = plan_lang(
            args.root, lang, args.doc, args.level, tpl)
        print(f"--- {lang}: 섹션 {n_sections}개 → 연도 파일 {len(files)}개  (왕복 검증 OK)")
        for year, text in files:
            print(f"      {stem}/{year}.md  {len(text.splitlines())} 줄")

        if not args.apply:
            continue
        outdir = os.path.join(args.root, lang, stem)
        os.makedirs(outdir, exist_ok=True)
        for year, text in files:
            with open(os.path.join(outdir, f"{year}.md"), "w", encoding="utf-8") as f:
                f.write(text)
        with open(path, "w", encoding="utf-8") as f:
            f.write(parent)
        print(f"      → {outdir}/ 에 {len(files)}개, {path} 는 include 로 교체")

    if not args.apply:
        print("\n(dry-run — 아무것도 쓰지 않았다. 위 계획이 맞으면 --apply 를 붙여 다시 실행하라)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
