#!/usr/bin/env python3
"""콘솔 용어집 e2e 판정 (cloud-translate — Dooray cloud-user-guide-agent/584). 모델 없음.

    check_console_glossary.py <base_dir> <tx_dir> [--ko-dir <ko PR head>] [--ct-dir <cloud-translate>]

<base_dir> 는 세션 base 체크아웃 (`.docs-workflow` · console/ · 기존 en/ja),
<tx_dir> 는 번역 PR head 체크아웃 (번역된 en/ja), <ko_dir> 는 ko PR head 체크아웃 — 번역 PR 은
세션 base 에서 갈라지므로 ko 변경은 거기 없다 (기본값 tx_dir).

[A] 프롬프트 — ``--ct-dir`` 의 코드로 `.docs-workflow` 의 콘솔 용어집을 GitHub 에서 읽어
    (`gh api`, 번역 잡과 같은 파서) 두 ko 문서의 용어집 절을 만든다. 콘솔 절에 실리는 키가
    정확히 "문서가 굵게 쓴 콘솔 낱말" 인지, 필수 용어집의 같은 키 줄이 빠지는지 본다.
    그 코드에 콘솔 용어집이 없으면 (BEFORE) [A] 는 SKIP 이다.
[B] 산출물 — 번역 PR 의 en/ja 가 절마다 콘솔 문자열을 썼는지:
    cg-notify        굵게 라벨 넷 — 값이 둘인 `발송 기준` 은 둘 중 하나면 된다
    cg-window        굵게 한 번 (`지연 허용 시간`)
    cg-window-fields 같은 낱말이 **굵게 없이** 표 셀 · 산문에 — 문서 전체 규칙
    cg-detail        필수 용어집(`상세 정보 → Details`)과 충돌 — 콘솔(`Detailed Info`)이 이긴다
    cg-prose         대조군: `**다음**` 버튼은 Next, 산문 `다음 중 하나` 는 Next 가 아니다
    cg-new           기존 문서에 ko 가 더한 절 (증분 번역 경로)
    cg-old           대조군: ko 가 안 바꾼 절은 base 와 바이트 동일 (일괄 수렴하지 않는다)

exit 0 OK · 3 REPRO · 2 인프라
"""
from __future__ import annotations

import argparse
import asyncio
import os
import re
import subprocess
import sys

REPO = "TOAST-DOCS/Agent-Test"
DOCS = ("console-glossary-sample.md", "console-glossary-existing.md")
ANCHOR_RE = re.compile(r'<a id="([^"]+)"></a>')

# 절 → 언어 → [후보 묶음 …]. 묶음 하나는 "이 중 하나가 절에 있어야 한다".
EXPECT = {
    "cg-notify": {
        "en": [["Notification sent"], ["Send Criteria", "Send Trigger"],
               ["On failure"], ["Reason for failure included"]],
        "ja": [["通知送信"], ["送信基準"], ["失敗時"], ["失敗の理由を含める"]],
    },
    "cg-window": {"en": [["Allowed lateness"]], "ja": [["遅延許可時間"]]},
    "cg-detail": {"en": [["Detailed Info"]], "ja": [["詳細内容"]]},
    "cg-new": {"en": [["Notification sent"], ["Reason for failure included"]],
               "ja": [["通知送信"], ["失敗の理由を含める"]]},
}
# 굵게 없이도 문서 전체에서 콘솔 용어 — 표 셀 + 산문 두 자리
DOCWIDE = {"cg-window-fields": {"en": ("Allowed lateness", 2), "ja": ("遅延許可時間", 2)}}
# 대조군 — 본문에서 굵게 버튼 한 번만 콘솔 값, 산문 '다음 중' 은 아니다 (제목 줄 제외)
PROSE = {"cg-prose": {"en": r"\bNext\b", "ja": r"次へ"}}
FORBIDDEN = {"en": [r"Allowed Latency", r"\bDetails\b tab"], "ja": []}

PROMPT_KEYS = {
    "console-glossary-sample.md": {"알림 전송", "발송 기준", "실패 시", "실패 사유 포함",
                                   "지연 허용 시간", "상세 정보", "다음"},
    "console-glossary-existing.md": {"알림 전송", "실패 사유 포함"},
}


def sections(text):
    out, cur, buf = {}, "", []
    for ln in text.split("\n"):
        m = ANCHOR_RE.search(ln)
        if m:
            out[cur] = "\n".join(buf)
            cur, buf = m.group(1), []
        buf.append(ln)
    out[cur] = "\n".join(buf)
    return out


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return None


# ── [A] 프롬프트 ─────────────────────────────────────────────────────

def gh_raw(blob):
    cmd = ["gh", "api", "-H", "Accept: application/vnd.github.raw",
           f"repos/{blob.repo}/contents/{blob.path}?ref={blob.ref}"]
    if blob.host != "github.com":
        cmd += ["--hostname", blob.host]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return out.stdout if out.returncode == 0 else None


def check_prompt(base_dir, ko_dir, ct_dir):
    sys.path[:0] = [ct_dir, os.path.join(ct_dir, "translate")]
    try:
        from shared import console_glossary as CG
    except ImportError:
        print("[A] SKIP — 이 cloud-translate 에는 콘솔 용어집이 없다 (BEFORE)")
        return [], True
    cwd = os.getcwd()
    os.chdir(ct_dir)  # 용어집 경로가 레포 루트 기준이다
    try:
        from app.glossary import Glossary
        spec = CG.parse_console_spec(read(os.path.join(base_dir, ".docs-workflow")))
        if not spec:
            return ["[A] .docs-workflow 에 console_glossary 가 없다"], False

        async def fetch(blob):
            return gh_raw(blob)

        cg = asyncio.run(CG.load_console_glossary(spec, fetch))
        print(f"[A] 콘솔 용어집: {len(cg.entries)} ko · 소스 {cg.sources}")
        fails = []
        if len(cg.sources) != len(spec):
            fails.append(f"[A] 읽은 소스 {cg.sources} ≠ 선언 {len(spec)}개")
        g = Glossary.for_repo(REPO).with_console(cg)
        for doc, want in PROMPT_KEYS.items():
            ko = read(os.path.join(ko_dir, "ko", doc))
            for lang in ("en", "ja"):
                text = g.build_prompt_section(lang, ko)
                head, _, rest = text.partition("### Console UI labels")
                console = rest.split("\n### ", 1)[0]
                got = {m.group(1) for m in re.finditer(r"^- (.+?) → ", console, re.M)}
                ok = got == want
                print(f"  [A] {doc} {lang}: 콘솔 키 {sorted(got)} {'OK' if ok else 'FAIL'}")
                if not ok:
                    fails.append(f"[A] {doc} {lang}: 콘솔 키 {sorted(got)} ≠ 기대 {sorted(want)}")
                if "- 설정 →" in console:
                    fails.append(f"[A] {doc} {lang}: 굵게가 아닌 '설정' 이 콘솔 절에 실렸다")
                if doc == DOCS[0]:
                    if "- 상세 정보 → Details" in text:
                        fails.append(f"[A] {lang}: 필수 용어집 '상세 정보 → Details' 가 남았다 (콘솔이 이겨야 한다)")
                    if lang == "en" and "- 발송 기준 → Send Criteria | Send Trigger" not in console:
                        fails.append("[A] en: '발송 기준' 의 두 후보가 함께 실리지 않았다")
        return fails, False
    finally:
        os.chdir(cwd)


# ── [B] 산출물 ──────────────────────────────────────────────────────

def has(section, cand, lang):
    if lang == "en":
        return cand.lower() in section.lower()
    return cand in section


def check_output(base_dir, tx_dir):
    fails, n = [], 0
    for lang in ("en", "ja"):
        secs = {}
        for doc in DOCS:
            text = read(os.path.join(tx_dir, lang, doc))
            if text is None:
                fails.append(f"[B] {lang}/{doc} 가 번역 PR 에 없다")
                continue
            secs.update(sections(text))
            for pat in FORBIDDEN[lang]:
                if re.search(pat, text, re.I if lang == "en" else 0):
                    fails.append(f"[B] {lang}/{doc}: 콘솔과 다른 표기 /{pat}/")
        for anchor, by_lang in EXPECT.items():
            body = secs.get(anchor, "")
            for group in by_lang[lang]:
                n += 1
                ok = any(has(body, c, lang) for c in group)
                print(f"  [B] {lang} #{anchor}: {' | '.join(group)} {'OK' if ok else 'MISS'}")
                if not ok:
                    fails.append(f"[B] {lang} #{anchor}: '{' | '.join(group)}' 없음")
        for anchor, spec in DOCWIDE.items():
            word, need = spec[lang]
            body = secs.get(anchor, "")
            got = body.lower().count(word.lower()) if lang == "en" else body.count(word)
            n += 1
            print(f"  [B] {lang} #{anchor}: '{word}' ×{got} (굵게 없이 표·산문 ≥{need}) "
                  f"{'OK' if got >= need else 'MISS'}")
            if got < need:
                fails.append(f"[B] {lang} #{anchor}: '{word}' ×{got} < {need} — 굵게 없는 자리에 콘솔 용어가 안 쓰였다")
        for anchor, by_lang in PROSE.items():
            pat = by_lang[lang]
            # 제목(`## Next Steps` ← `다음 단계`)은 산문이라 맞는 번역이다 — 본문 줄만 센다.
            body = "\n".join(ln for ln in secs.get(anchor, "").split("\n")
                             if not ln.lstrip().startswith("#"))
            got = len(re.findall(pat, body))
            n += 1
            print(f"  [B] {lang} #{anchor}: /{pat}/ ×{got} (버튼 1번만) {'OK' if got == 1 else 'FAIL'}")
            if got != 1:
                fails.append(f"[B] {lang} #{anchor}: /{pat}/ ×{got} — 버튼 1번이어야 한다 (산문 '다음 중' 에 새면 안 된다)")
        base_old = sections(read(os.path.join(base_dir, lang, DOCS[1])) or "").get("cg-old")
        tx_old = secs.get("cg-old")
        n += 1
        same = base_old is not None and tx_old is not None and \
            base_old.rstrip("\n") == tx_old.rstrip("\n")
        print(f"  [B] {lang} #cg-old: base 와 바이트 동일 {'OK' if same else 'FAIL'}")
        if not same:
            fails.append(f"[B] {lang} #cg-old: ko 가 안 바꾼 절이 바뀌었다")
    return fails, n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("base_dir")
    ap.add_argument("tx_dir")
    ap.add_argument("--ko-dir", help="ko PR head 체크아웃 (기본: tx_dir)")
    ap.add_argument("--ct-dir", default=os.path.expanduser("~/works/cloud-translate"))
    a = ap.parse_args()
    if not os.path.isdir(a.tx_dir):
        print("error: tx_dir 없음")
        return 2
    print("=== check_console_glossary ===")
    a_fails, skipped = check_prompt(a.base_dir, a.ko_dir or a.tx_dir, a.ct_dir)
    b_fails, n = check_output(a.base_dir, a.tx_dir)
    fails = a_fails + b_fails
    print()
    for f in fails:
        print("  ✗ " + f)
    label = "A SKIP · " if skipped else ""
    if fails:
        print(f"CONSOLE_GLOSSARY: REPRO ({label}{len(fails)} fail · [B] {n} checks)")
        return 3
    print(f"CONSOLE_GLOSSARY: OK ({label}[B] {n} checks)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
