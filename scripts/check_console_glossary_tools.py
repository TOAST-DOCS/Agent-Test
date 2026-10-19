#!/usr/bin/env python3
"""콘솔 용어집 — 정비 도구 · 한글 검수 e2e 판정 (cloud-user-guide-agent/584). 모델 없음.

    check_console_glossary_tools.py fill|hangul|tables <base_dir> <head_dir> [<prompts_dir>]
    check_console_glossary_tools.py review <review.log>

판정은 두 층이다 — 모델 판단이 끼는 자리를 결정적 판정과 섞지 않는다:

[A] 프롬프트 (결정적, hard) — <prompts_dir> 에 실행 중 CLI 엔진이 쓴 용어집 파일
    (`glossary_*.md`)을 모아 넘기면, 언어마다 `### Console UI labels` 절에 그 도구가 보낸
    조각의 콘솔 낱말이 실렸는지 본다. 기능 이전 코드는 이 절 자체가 없다.
[B] 산출물 — **굵게인 자리**(한글 잔존의 `**실패 사유 포함**`)는 hard. **굵게가 아닌
    자리**(채우기의 표 셀·산문, 표 정비의 설명 칸)는 584 결정 2번대로 "같은 뜻일 때만" 을
    모델이 판단하므로 WARN 으로만 센다 — daily-webhook-review 의 `bold_here=false` 와 같다.

fill    빈 번역 채우기 — `#cgf-fields` 는 굵게가 **없는** 절이다 (표 셀 + 산문). 콘솔 용어는
        `#cgf-intro` 의 굵게로 정해지므로, 도구가 문서 전체를 판정 근거로 넘겨야 맞는다.
hangul  한글 잔존 — `#cgh-notify` 의 남은 한글 `**실패 사유 포함**` 이 콘솔 문자열로.
tables  깨진 표 정비 — 빠진 행 `notifyEnabled` · `withReason` 의 설명 칸이 콘솔 문자열로
        (설명 칸에는 굵게가 없다 — 굵게는 `#cgt-intro`).
        세 도구 모두 대조군: 도구가 고치지 않는 `#cg?-intro` 는 base 와 바이트 동일.
review  한글 검수 (`review_pr.py --dry-run` 로그) — 콘솔 라벨 줄(6 `(NHN Cloud) Log&Crash
        Search` · 7 `최대재시도횟수`)에 라벨 글자를 바꾸는 지적이 없고, 대조군 줄(12 `예)` ·
        13 굵게 아닌 `Log&Crash 서비스`)은 여전히 지적된다.

exit 0 OK · 3 REPRO · 2 인프라
"""
from __future__ import annotations

import os
import re
import sys

ANCHOR_RE = re.compile(r'<a id="([^"]+)"></a>')
HANGUL = re.compile(r"[가-힣]")

# (where, word, need, hard) — hard=False 는 굵게가 아닌 자리 (모델 판단, WARN)
EXPECT = {
    "fill": ("console-glossary-fill.md", "cgf-intro", {
        "en": [("cgf-fields", "Allowed lateness", 2, False),
               ("cgf-fields", "Reason for failure included", 1, False)],
        "ja": [("cgf-fields", "遅延許可時間", 2, False),
               ("cgf-fields", "失敗の理由を含める", 1, False)]}),
    "hangul": ("console-glossary-hangul.md", "cgh-intro", {
        "en": [("cgh-notify", "Reason for failure included", 1, True)],
        "ja": [("cgh-notify", "失敗の理由を含める", 1, True)]}),
    "tables": ("console-glossary-tables.md", "cgt-intro", {
        "en": [("row:notifyEnabled", "Notification sent", 1, False),
               ("row:withReason", "Reason for failure included", 1, False)],
        "ja": [("row:notifyEnabled", "通知送信", 1, False),
               ("row:withReason", "失敗の理由を含める", 1, False)]}),
}
# [A] 도구가 보낸 조각에 든 콘솔 낱말 — 프롬프트의 콘솔 절에 실려야 한다
PROMPT_KEYS = {"fill": {"지연 허용 시간", "실패 사유 포함"},
               "hangul": {"실패 사유 포함"},
               "tables": {"알림 전송", "실패 사유 포함"}}


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


def count(body, word, lang):
    return body.lower().count(word.lower()) if lang == "en" else body.count(word)


def check_prompts(tool, prompts_dir):
    """[A] 실행 중 쓰인 CLI 용어집 파일의 콘솔 절."""
    fails = []
    files = sorted(f for f in os.listdir(prompts_dir) if f.startswith("glossary_"))
    for lang in ("en", "ja"):
        keys = set()
        for f in files:
            if f"_{lang}_" not in f:
                continue
            body = read(os.path.join(prompts_dir, f)) or ""
            if "### Console UI labels" in body:
                sec = body.split("### Console UI labels", 1)[1].split("\n### ", 1)[0]
                keys |= set(re.findall(r"^- (.+?) → ", sec, re.M))
        want = PROMPT_KEYS[tool]
        ok = want <= keys
        print(f"  [A] {lang}: 콘솔 절의 키 {sorted(keys)} (기대 ⊇ {sorted(want)}) {'OK' if ok else 'FAIL'}")
        if not ok:
            fails.append(f"[A] {lang}: 프롬프트 콘솔 절에 {sorted(want - keys)} 없음")
    return fails


def check_doc(tool, base_dir, head_dir):
    doc, control, by_lang = EXPECT[tool]
    fails, n = [], 0
    warns = []
    for lang, checks in by_lang.items():
        head = read(os.path.join(head_dir, lang, doc))
        base = read(os.path.join(base_dir, lang, doc))
        if head is None or base is None:
            fails.append(f"{lang}/{doc} 없음")
            continue
        secs = sections(head)
        for where, word, need, hard in checks:
            if where.startswith("row:"):
                key = where[4:]
                body = "\n".join(ln for ln in head.split("\n") if ln.startswith(f"| {key} "))
            else:
                body = secs.get(where, "")
            got = count(body, word, lang)
            n += 1
            ok = got >= need and body != ""
            verdict = "OK" if ok else ("MISS" if hard else "WARN (굵게 아닌 자리 — 모델 판단)")
            print(f"  [B] {lang} {where}: '{word}' ×{got} (≥{need}) {verdict}")
            if not ok:
                (fails if hard else warns).append(f"{lang} {where}: '{word}' ×{got} < {need}")
        n += 1
        if HANGUL.search(re.sub(r"<!--.*?-->", "", head)):
            fails.append(f"{lang}/{doc}: 한글이 남았다")
            print(f"  [B] {lang}: 한글 잔존 FAIL")
        n += 1
        same = sections(base).get(control) == secs.get(control)
        print(f"  [B] {lang} #{control}: base 와 바이트 동일 {'OK' if same else 'FAIL'}")
        if not same:
            fails.append(f"{lang} #{control}: 도구가 손대지 않을 절이 바뀌었다")
    return fails, n, warns


# review_pr.py _log_report: "  <file>:<line> [<kind>] <message>[ | suggest: …| proposal(예시): …]"
FINDING_RE = re.compile(r"\s(ko/console-glossary-review\.md):(\d+) \[([^\]]+)\] (.*)$")
LABEL_LINES = {6: "(NHN Cloud) Log&Crash Search", 7: "최대재시도횟수"}
CONTROL_LINES = {12: "예)", 13: "Log&Crash 서비스"}


def check_review(log_path):
    text = read(log_path)
    if text is None:
        return ["로그 없음"], 0
    findings = {}
    for ln in text.split("\n"):
        if "console label: dropped" in ln:     # 필터가 뺀 것 — 게시되지 않는다
            continue
        m = FINDING_RE.search(ln)
        if m:
            findings.setdefault(int(m.group(2)), []).append(m.group(4))
    print(f"  지적 줄: {sorted(findings)}")
    fails, n = [], 0
    for line, label in LABEL_LINES.items():
        n += 1
        bad = [f for f in findings.get(line, [])
               if ("| suggest: " in f and label not in f.split("| suggest: ", 1)[1])
               or (label in f.split(" | ", 1)[0])
               or ("Log&Crash" in label and "Log & Crash" in f)
               or ("재시도" in label and "최대 재시도" in f)]
        print(f"  L{line} `{label}`: 라벨을 바꾸는 지적 {len(bad)} {'OK' if not bad else 'FAIL'}")
        for f in bad:
            print(f"      ✗ {f[:140]}")
        if bad:
            fails.append(f"L{line}: 콘솔 라벨 `{label}` 을 바꾸라는 지적 {len(bad)}")
    for line, what in CONTROL_LINES.items():
        n += 1
        ok = bool(findings.get(line))
        print(f"  L{line} 대조군 `{what}`: 지적 {len(findings.get(line, []))} {'OK' if ok else 'FAIL'}")
        if not ok:
            fails.append(f"L{line}: 대조군 `{what}` 이 지적되지 않았다 (필터가 너무 넓다)")
    return fails, n


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("fill", "hangul", "tables", "review"):
        print(__doc__)
        return 2
    tool = sys.argv[1]
    print(f"=== check_console_glossary_tools [{tool}] ===")
    warns = []
    if tool == "review":
        fails, n = check_review(sys.argv[2])
    else:
        fails = check_prompts(tool, sys.argv[4]) if len(sys.argv) > 4 else []
        if len(sys.argv) <= 4:
            print("  [A] SKIP — 프롬프트 디렉터리를 주지 않았다")
        b_fails, n, warns = check_doc(tool, sys.argv[2], sys.argv[3])
        fails += b_fails
    for f in fails:
        print("  ✗ " + f)
    for w in warns:
        print("  △ " + w)
    tag = tool.upper()
    wtag = f" · WARN {len(warns)}" if warns else ""
    if fails:
        print(f"CONSOLE_GLOSSARY_{tag}: REPRO ({len(fails)} fail{wtag} · {n} checks)")
        return 3
    print(f"CONSOLE_GLOSSARY_{tag}: OK ({n} checks{wtag})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
