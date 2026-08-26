# fill-stub 픽스처 원본

`{ko,en,ja}/fill-stub-sample.md` 의 **stub 이 살아 있는 상태** 사본이다.

빈 번역 채우기(`translate/translate_fill_stubs.py`, 대시보드 '빈 번역 채우기')
실행이 성공하면 en/ja 의 stub 이 실제 번역으로 채워져 사라진다. 다음 회차를
돌리려면 이 사본으로 되돌려야 한다:

```bash
scripts/restore-fill-stub-sample.sh --dry-run   # 미리보기
scripts/restore-fill-stub-sample.sh             # 실제 복원
```

`ko/fill-stub-sample.md` 도 함께 보관한다 — 앵커 없는 부정 대조군 섹션
(`## 앵커가 없는 섹션`) 은 pre-align 을 다시 돌리면 id 가 붙어 사라지기 때문에,
ko 쪽도 원본에서 되살릴 수 있어야 한다.
