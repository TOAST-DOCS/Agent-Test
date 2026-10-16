# image-locale — 전체 재번역의 이미지 링크 유지 픽스처

`scripts/e2e-full-retranslate-images.sh` 가 세션 브랜치에 `{ko,en,ja}/image-locale-sample.md`
로 심고 `translate_file.py`(대시보드 '전체 재번역')를 돌린다. 판정은
`scripts/check_image_locale.py` (모델 없이, 이미지 대상만 본다).

| 절 | ko | en / ja 기존 번역본 | 기대 (전체 재번역 후) |
|---|---|---|---|
| `#region` | `…_KR.png` | `…_EN.png` (+ 끼어든 `_KR` 줄, TOAST-Cloud master 모양) / `…_JP.png` | `_EN` 하나 / `_JP` |
| `#analytics` | `…/ko/…_kr_…` | `…/en/…_en_…` / `…/jp/…_jp_…` | 그대로 (디렉터리+파일명) |
| `#migration` | `…_ko_1.png` (목록 안) | `…_en_1` / `…_jp_1` | 그대로 |
| `#own-image` | `putty006.png` | 번역본이 따로 고른 이미지 (`putty-ssh-001-en` / `putty002-en`) | 그대로 (파일명 규칙 없음) |
| `#new-image` (대조군) | `stt_console_ko.png` | 이미지 없음 | ko 값 (짝이 없으므로 모델 출력 그대로) |

근거: Dooray cloud-user-guide-agent/536 · TOAST-Cloud#393 (전체 재번역이 `_EN`/`_JP` → `_KR`).
