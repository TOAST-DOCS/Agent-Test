#!/usr/bin/env python3
"""목록 항목 안 펜스 코드 블록의 들여쓰기 판정 — TOAST-DOCS/TOAST-Cloud#434 · #436.

결함: 번호 목록 항목 본문(4칸)의 ```` ```text ```` 블록이 en/ja 번역에서 들여쓰기를
잃거나(#434: 본문 첫 줄 0칸) 얻어서(#436: 둘째 줄 · 닫는 펜스 8칸) 배포본에서 `<pre>`
가 아니라 inline code(``text\\nGET …``)로 렌더된다.

판정(모델 없음, 결정적) — 대상 절마다:
  [indent] en/ja 의 펜스 블록 줄(여는 펜스 · 본문 · 닫는 펜스) 들여쓰기 열 == ko
  [pre]    사이트 렌더(python-markdown + pymdownx.superfences)의 그 절 `<pre>` 수 == ko

모드
  ideal (기본) — 픽스처 {ko,en,ja}/list-items-sample.md 를 읽어 메모리에서 head ko 를
          만들고(두 모양 + 대조군), cloud-translate 의 `translate_diff` 를 **이상적 모델**
          로 돌린다. 이상적 모델 = 받은 줄을 그대로(들여쓰기 포함) 번역해 돌려준다.
          세 arm:
            identity — 모델 응답 그대로 (하네스 자체 점검: 늘 OK 여야 한다)
            strip    — + 모든 엔진이 응답에 거는 `_strip_code_fence` (운영과 같다)
            dedent   — + 모델이 inner 를 0칸으로 정규화해 돌려준 경우(실제 모델 일탈)
          exit 0 = strip·dedent 모두 OK, 3 = REPRO, 1 = 하네스 오류(identity FAIL 등)
  files — --ko/--en/--ja 파일(실제 번역 산출물)을 판정만. exit 0 OK / 3 REPRO
  pr    — --pr <번역 PR URL>: head SHA 의 ko/en/ja 를 gh 로 받아 files 판정

예
  CT=~/works/cloud-translate
  $CT/.venv/bin/python scripts/check_list_fence.py --cloud-translate-dir $CT
  python3 scripts/check_list_fence.py --mode pr \\
      --pr https://github.com/TOAST-DOCS/TOAST-Cloud/pull/436 \\
      --path public-api/framework-api.md --sections common-cursor-paging
"""
from __future__ import annotations

import argparse
import asyncio
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import textwrap

DOC = "list-items-sample.md"
SECTIONS = ["list-fence-edit", "list-fence-new", "list-fence-control"]

# ── head ko 편집 (ideal 모드 · --open-ko-pr 가 같은 것을 쓴다) ─────────────────
# (1) #436 모양 — 목록 안 두 번째 블록의 둘째 줄만
EDIT_FROM = '    → 목록 7건, "nextCursor": null\n'
EDIT_TO = '    → 목록 7건, nextCursor 없음\n'
# (2) 대조군 — 목록 밖 블록의 둘째 줄
CTL_FROM = '→ 목록 20건, "nextCursor": "Y3Vyc29yLWV4YW1wbGU"\n```\n'
CTL_TO = '→ 목록 20건, nextCursor 있음\n```\n'
# (3) #434 모양 — 목록 안 코드 블록이 든 새 절을 대조군 절 앞에 추가
NEW_BEFORE = '<a id="list-fence-control"></a>\n'
NEW_SECTION = '''<a id="list-fence-new"></a>
## 목록 안 코드 블록이 든 새 절

1. 토큰을 발급합니다.

    ```text
    POST /oauth2/token?grant_type=client_credentials
    → 토큰 발급, "expiresIn": 86400
    ```

2. 발급받은 토큰을 헤더에 넣어 요청합니다.

    ```text
    GET /{API 경로}
    → 조회 결과 반환
    ```

'''

# 이상적 모델의 번역 사전 (ko 줄 → 대상 줄). 들여쓰기는 입력의 것을 그대로 둔다.
TR = {
    "en": {
        "목록 안 코드 블록이 든 새 절": "A new section with code blocks inside a list",
        "토큰을 발급합니다.": "Issue a token.",
        "→ 토큰 발급, \"expiresIn\": 86400": "→ Token issued, \"expiresIn\": 86400",
        "발급받은 토큰을 헤더에 넣어 요청합니다.": "Send the request with the issued token in the header.",
        "GET /{API 경로}": "GET /{API path}",
        "→ 조회 결과 반환": "→ Returns the query result",
        "GET /{API 경로}?{조회 조건}&size=20&cursor=Y3Vyc29yLWV4YW1wbGU": "GET /{API path}?{query conditions}&size=20&cursor=Y3Vyc29yLWV4YW1wbGU",
        "→ 목록 7건, nextCursor 없음": "→ 7 items in the list, no nextCursor",
        "GET /{API 경로}?{조회 조건}&size=20": "GET /{API path}?{query conditions}&size=20",
        "→ 목록 20건, nextCursor 있음": "→ 20 items in the list, nextCursor present",
        "→ 목록 20건, \"nextCursor\": \"Y3Vyc29yLWV4YW1wbGU\"": "→ 20 items in the list, \"nextCursor\": \"Y3Vyc29yLWV4YW1wbGU\"",
    },
    "ja": {
        "목록 안 코드 블록이 든 새 절": "リスト内にコードブロックがある新しい節",
        "토큰을 발급합니다.": "トークンを発行します。",
        "→ 토큰 발급, \"expiresIn\": 86400": "→ トークン発行, \"expiresIn\": 86400",
        "발급받은 토큰을 헤더에 넣어 요청합니다.": "発行されたトークンをヘッダーに設定してリクエストします。",
        "GET /{API 경로}": "GET /{APIパス}",
        "→ 조회 결과 반환": "→ 照会結果を返す",
        "GET /{API 경로}?{조회 조건}&size=20&cursor=Y3Vyc29yLWV4YW1wbGU": "GET /{APIパス}?{照会条件}&size=20&cursor=Y3Vyc29yLWV4YW1wbGU",
        "→ 목록 7건, nextCursor 없음": "→ リスト7件, nextCursor なし",
        "GET /{API 경로}?{조회 조건}&size=20": "GET /{APIパス}?{照会条件}&size=20",
        "→ 목록 20건, nextCursor 있음": "→ リスト20件, nextCursor あり",
        "→ 목록 20건, \"nextCursor\": \"Y3Vyc29yLWV4YW1wbGU\"": "→ リスト20件, \"nextCursor\": \"Y3Vyc29yLWV4YW1wbGU\"",
    },
}
HAN = re.compile(r"[가-힣]+")
LIST_PREFIX = re.compile(r"^(\s*(?:[-*+]|\d{1,9}[.)])\s+|\s*#+\s+)?(.*)$")

# 운영 Jenkins 잡과 같은 플래그 (TOAST-Cloud#434/#436 의 build 1369/1373 docker -e)
PROD_ENV = {
    "TRANSLATE_DIFF_GRANULARITY": "block",
    "TRANSLATE_DIFF_TABLE_KEY_ALIGN": "false",
    "TRANSLATE_DIFF_SKIP_FULL_TABLE": "false",
    "TRANSLATE_DIFF_TABLE_ROWS": "true",
    "TRANSLATE_DIFF_UNIT_PRESERVE": "true",
    "TRANSLATE_DIFF_LIST_ITEMS": "true",
    "TRANSLATE_DIFF_ALIGN_HEADINGS": "true",
    "TRANSLATE_DIFF_LOAD_MAX_RATIO": "4",
    "TRANSLATE_DIFF_LOAD_EXCLUDE_TABLES": "true",
}


def make_head_ko(ko: str) -> str:
    for frm in (EDIT_FROM, CTL_FROM, NEW_BEFORE):
        if ko.count(frm) != 1:
            raise SystemExit(f"픽스처에서 편집 대상을 정확히 한 번 찾지 못했다: {frm!r}")
    return (ko.replace(EDIT_FROM, EDIT_TO)
              .replace(CTL_FROM, CTL_TO)
              .replace(NEW_BEFORE, NEW_SECTION + NEW_BEFORE))


# ── 판정 ──────────────────────────────────────────────────────────────────
def section(text: str, anchor: str) -> str | None:
    i = text.find(f'<a id="{anchor}"></a>')
    if i < 0:
        return None
    j = text.find("<a id=", i + 1)
    return text[i: j if j > 0 else len(text)]


def fence_lines(sec: str) -> list[tuple[int, str]]:
    """(들여쓰기 열, 줄) — 펜스 블록에 속한 줄 전부. 블록 경계는 ko 와 같은 규칙:
    ```로 시작하는 줄이 열고, 같은 마커로 시작하는 다음 줄이 닫는다 (들여쓰기 무관)."""
    out, inside = [], False
    for ln in sec.splitlines():
        st = ln.strip()
        if st.startswith("```"):
            out.append((len(ln) - len(ln.lstrip(" ")), st))
            inside = not inside
        elif inside:
            out.append((len(ln) - len(ln.lstrip(" ")), st))
    return out


def render_pre(sec: str) -> tuple[int, int]:
    import markdown
    html = markdown.markdown(sec, extensions=[
        "admonition", "attr_list", "toc", "tables",
        "pymdownx.superfences", "pymdownx.highlight"])
    inline = len(re.findall(r"<code>text\s", html))   # 깨진 블록의 증상
    return html.count("<pre"), inline


def judge(ko: str, tr: dict[str, str], sections: list[str], label: str) -> list[str]:
    fails: list[str] = []
    for anchor in sections:
        k = section(ko, anchor)
        if k is None:
            fails.append(f"{anchor}: ko 에 절이 없다")
            continue
        k_lines = fence_lines(k)
        k_pre, _ = render_pre(k)
        for lang, text in tr.items():
            s = section(text, anchor)
            if s is None:
                fails.append(f"{lang} #{anchor}: 절이 없다")
                print(f"    {label} {lang:2} #{anchor:20} FAIL 절 없음")
                continue
            t_lines = fence_lines(s)
            ki = [w for w, _ in k_lines]
            ti = [w for w, _ in t_lines]
            t_pre, t_inline = render_pre(s)
            ok_i = ki == ti
            ok_p = t_pre == k_pre
            verdict = "OK  " if ok_i and ok_p else "FAIL"
            print(f"    {label} {lang:2} #{anchor:20} {verdict} indent ko={ki} {lang}={ti}"
                  f" · <pre> ko={k_pre} {lang}={t_pre} (inline `text` code {t_inline})")
            if not ok_i:
                fails.append(f"{lang} #{anchor}: 펜스 블록 들여쓰기 {ti} != ko {ki}")
            if not ok_p:
                fails.append(f"{lang} #{anchor}: <pre> {t_pre} != ko {k_pre}")
    return fails


# ── ideal 모드 ────────────────────────────────────────────────────────────
def ideal_line(line: str, lang: str) -> str:
    body = line.rstrip("\n")
    ind = body[: len(body) - len(body.lstrip(" \t"))]
    m = LIST_PREFIX.match(body[len(ind):])
    prefix, rest = (m.group(1) or ""), m.group(2)
    hit = TR[lang].get(rest.strip())
    if hit is None and HAN.search(rest):
        hit = HAN.sub(lang.upper(), rest)
    out = ind + prefix + (hit if hit is not None else rest)
    return out + ("\n" if line.endswith("\n") else "")


async def run_ideal(root: pathlib.Path, ct_dir: pathlib.Path) -> int:
    for k, v in PROD_ENV.items():
        os.environ.setdefault(k, v)
    sys.path[:0] = [str(ct_dir / "translate"), str(ct_dir)]
    os.chdir(tempfile.mkdtemp())          # .env 를 읽지 않는다 (cwd 에 없음)
    from app.translator import Translator, _strip_code_fence
    from app import worker as W

    ko = (root / "ko" / DOC).read_text(encoding="utf-8")
    base = {l: (root / l / DOC).read_text(encoding="utf-8") for l in ("en", "ja")}
    head = make_head_ko(ko)

    def mock_cls(arm: str):
        class Ideal(Translator):
            sent: list[str] = []

            async def _translate_chunk_uncached(self, content, reference=None,
                                                target_lang="en", target_dir="en"):
                Ideal.sent.append(content)
                lines = content.splitlines(keepends=True)
                out = "".join(ideal_line(ln, target_lang) for ln in lines)
                if arm == "dedent":
                    out = textwrap.dedent(out)
                if arm in ("strip", "dedent"):
                    out = _strip_code_fence(out)   # 모든 엔진의 마지막 줄과 같다
                return out

            async def _verify_chunk_uncached(self, *a, **k):
                return ""

            def model_name(self):
                return f"ideal-{arm}"
        return Ideal

    marker = getattr(W, "_pre_align_marker", None)
    print(f"[A] 이상적 모델 재생 — cloud-translate {ct_dir}")
    print(f"    flags: " + " ".join(f"{k[10:]}={os.environ[k]}" for k in PROD_ENV))
    results: dict[str, list[str]] = {}
    for arm in ("identity", "strip", "dedent"):
        cls = mock_cls(arm)
        out: dict[str, str] = {}
        for lang in ("en", "ja"):
            pre = bool(marker and marker(head) and marker(head) == marker(base[lang]))
            out[lang] = await cls().translate_diff(
                base[lang], head, ko, None, lang, lang,
                report={}, prealigned=pre, content_baseline_ko=ko)
        fence_sent = sum(1 for c in cls.sent if "GET" in c or "POST" in c)
        print(f"  arm={arm}: 모델 호출 {len(cls.sent)} (코드 블록 본문이 든 호출 {fence_sent})")
        results[arm] = judge(head, out, SECTIONS, f"[{arm:8}]")
    if results["identity"]:
        print("\nRESULT: ERROR — identity arm 이 실패했다 (하네스/픽스처 점검)")
        for f in results["identity"]:
            print(f"   - {f}")
        return 1
    bad = results["strip"] + results["dedent"]
    if bad:
        print(f"\nRESULT: REPRO {len(bad)} — 완벽한 모델로도 목록 안 코드 블록의 들여쓰기가 ko 와 다르다")
        for arm in ("strip", "dedent"):
            for f in results[arm]:
                print(f"   - [{arm}] {f}")
        return 3
    print("\nRESULT: OK — 세 arm 모두 목록 안 코드 블록 들여쓰기·<pre> 수가 ko 와 같다")
    return 0


# ── files / pr 모드 ───────────────────────────────────────────────────────
def gh_raw(repo: str, path: str, ref: str) -> str:
    return subprocess.run(
        ["gh", "api", f"repos/{repo}/contents/{path}?ref={ref}",
         "-H", "Accept: application/vnd.github.raw"],
        check=True, capture_output=True, text=True).stdout


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--mode", choices=("ideal", "files", "pr"), default="ideal")
    ap.add_argument("--root", default=str(pathlib.Path(__file__).resolve().parent.parent),
                    help="ideal: {ko,en,ja}/%s 가 있는 디렉터리" % DOC)
    ap.add_argument("--cloud-translate-dir",
                    default=os.environ.get("CLOUD_TRANSLATE_DIR",
                                           str(pathlib.Path.home() / "works/cloud-translate")))
    ap.add_argument("--ko"); ap.add_argument("--en"); ap.add_argument("--ja")
    ap.add_argument("--pr", help="pr: 번역 PR URL (head SHA 의 ko/en/ja 를 읽는다)")
    ap.add_argument("--path", default=DOC, help="pr: 언어 폴더 아래 문서 경로")
    ap.add_argument("--sections", default=",".join(SECTIONS))
    a = ap.parse_args()
    sections = [s for s in a.sections.split(",") if s]

    if a.mode == "ideal":
        return asyncio.run(run_ideal(pathlib.Path(a.root).resolve(),
                                     pathlib.Path(a.cloud_translate_dir).resolve()))
    if a.mode == "pr":
        m = re.match(r"https://github\.com/([^/]+/[^/]+)/pull/(\d+)", a.pr or "")
        if not m:
            raise SystemExit("--pr https://github.com/<org>/<repo>/pull/<n>")
        repo, num = m.group(1), m.group(2)
        sha = subprocess.run(["gh", "pr", "view", num, "--repo", repo, "--json",
                              "headRefOid", "-q", ".headRefOid"],
                             check=True, capture_output=True, text=True).stdout.strip()
        print(f"[B] {a.pr} @ {sha}")
        ko = gh_raw(repo, f"ko/{a.path}", sha)
        tr = {l: gh_raw(repo, f"{l}/{a.path}", sha) for l in ("en", "ja")}
    else:
        ko = pathlib.Path(a.ko).read_text(encoding="utf-8")
        tr = {l: pathlib.Path(getattr(a, l)).read_text(encoding="utf-8") for l in ("en", "ja")}
    fails = judge(ko, tr, sections, "[files]")
    if fails:
        print(f"\nRESULT: REPRO {len(fails)}")
        for f in fails:
            print(f"   - {f}")
        return 3
    print("\nRESULT: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
