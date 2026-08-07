<!-- pre-align:aligned sig=9b1876e3ba07 -->

# 브랜치 복원 테스트

## 목적

`translate_pr.py` 가 merged PR 의 삭제된 head 브랜치를 복원한 뒤 번역을
수행하는지 검증하는 픽스처.

## 시나리오

1. 이 PR 을 merged + delete-branch 로 처리한다.
2. `translate_pr.py` 를 이 PR URL 로 실행한다.
3. 로그에 `Restoring deleted source branch` 가 있어야 하고 번역 PR 이 열려야 한다.
