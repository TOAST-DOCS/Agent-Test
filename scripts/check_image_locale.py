#!/usr/bin/env python3
"""전체 재번역 뒤 en/ja 의 이미지 링크가 기존 번역본 그대로인지 판정한다 (모델 없음).

usage: check_image_locale.py <repo> <ref> [--doc image-locale-sample.md]

픽스처는 archive/image-locale/ (README 의 표가 기대값). 절(`<a id>`)마다 이미지
대상만 뽑아 기대값과 비교한다. 산문은 보지 않는다.
exit 0 = 전부 기대대로 · 3 = 하나라도 어긋남
"""
import argparse, base64, json, re, subprocess, sys

R = "https://static.toastoven.net/toast/region_guide/Docs_NHNCloud_Region-Guide"
G = ("https://kr1-api-object-storage.nhncloudservice.com/v1/"
     "AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_gamebase/ConsoleGuide/Analytics")
L = "http://static.toastoven.net/prod_load_balancer/lb_p_migration"
KO_NEW = "http://static.toastoven.net/prod_speech/stt_console_ko.png"

EXPECT = {
    "en": {
        "region": [f"{R}_EN.png"],
        "analytics": [f"{G}/en/analytics_05_en_240103.png"],
        "migration": [f"{L}_en_1.png"],
        "own-image": ["http://static.toastoven.net/prod_instance/putty-ssh-001-en.png"],
        "new-image": [KO_NEW],
    },
    "ja": {
        "region": [f"{R}_JP.png"],
        "analytics": [f"{G}/jp/analytics_05_jp_240103.png"],
        "migration": [f"{L}_jp_1.png"],
        "own-image": ["http://static.toastoven.net/prod_instance/putty002-en.png"],
        "new-image": [KO_NEW],
    },
}
WHAT = {
    "region": "국가 코드 대문자 (_KR → _EN/_JP), en 은 끼어든 _KR 줄 제거",
    "analytics": "디렉터리+파일명 로케일 (ko/…_kr → en/…_en)",
    "migration": "목록 안 이미지 (_ko_1 → _en_1)",
    "own-image": "번역본이 따로 고른 이미지 (파일명 규칙 없음)",
    "new-image": "대조군 — ko 에만 있는 이미지는 ko 값",
}

IMG = re.compile(r"!\[[^\]]*\]\(([^)\s]+)")
ANCHOR = re.compile(r'<a id="([^"]+)"></a>')


def fetch(repo, path, ref):
    out = subprocess.run(["gh", "api", f"repos/{repo}/contents/{path}?ref={ref}"],
                         capture_output=True, text=True, check=True).stdout
    return base64.b64decode(json.loads(out)["content"]).decode()


def sections(text):
    cur, got, fence = None, {}, False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            fence = not fence
        if fence:
            continue
        m = ANCHOR.search(line)
        if m:
            cur = m.group(1)
            got.setdefault(cur, [])
            continue
        if cur:
            got[cur] += IMG.findall(line)
    return got


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("repo"); ap.add_argument("ref")
    ap.add_argument("--doc", default="image-locale-sample.md")
    a = ap.parse_args()
    bad = 0
    for lang, exp in EXPECT.items():
        got = sections(fetch(a.repo, f"{lang}/{a.doc}", a.ref))
        for sec, want in exp.items():
            have = got.get(sec, [])
            ok = have == want
            bad += not ok
            print(f"[{'OK ' if ok else 'FAIL'}] {lang} #{sec:<10} {WHAT[sec]}")
            if not ok:
                print(f"         want {[w.rsplit('/', 2)[-2:] for w in want]}")
                print(f"         have {[h.rsplit('/', 2)[-2:] for h in have]}")
    print(f"IMAGE_LOCALE: {'OK' if not bad else f'FAIL ({bad})'}")
    sys.exit(3 if bad else 0)


if __name__ == "__main__":
    main()
