# 마크업 정정 — 사이트 펜스 파서(superfences) 픽스처

마크업 정정(`pre-align/fix_markup.py`)의 렌더러가 사이트와 같은 `pymdownx.superfences` 로 펜스를 읽는지 보는 픽스처다 (cloud-translate#1361). 절마다 기대값이 다르다.

<a id="sf-absorbed-bullet"></a>
## A. 펜스 아래 붙은 불릿 (Push console-guide 모양)

번호 목록 바로 아래 0칸 펜스가 빈 줄 없이 붙고, 닫는 펜스 아래 불릿이 붙어 있다. 사이트에서 불릿은 번호 목록의 4번째 항목("4.")이 된다. 기대: 사이트처럼 읽는 렌더러만 M15 로 고친다.

1. **Security Profiles** 탭을 클릭합니다.
2. 앱 정보를 입력합니다.
3. 아래와 같은 명령어로 MD5, SHA256 정보를 조회할 수 있습니다.
```
> keytool -list -v -keystore {keystoreFileName}
```
- 등록 완료 후 **Show** 버튼을 클릭하면 API key 정보를 조회할 수 있습니다.

<a id="sf-fence-prose-leak"></a>
## B. 펜스가 붙은 목록 항목의 산문 (대조군 — 커버리지)

목록 항목 바로 아래 4칸 펜스가 붙어 있고, 항목 산문의 `**` 가 샌다. 기대: 수정 전후 모두 M2 로 고친다.

1. ** 저장**을 클릭합니다.
    ```text
    POST /v1/save
    ```

<a id="sf-plain-leak"></a>
## C. 일반 문단 (대조군)

목록도 펜스도 없는 문단의 `**` 누수다. 기대: 수정 전후 모두 M2 로 고친다.

설정이 끝나면 ** 확인**을 클릭합니다.

<a id="sf-list-fence-ok"></a>
## D. 정상 목록 안 코드 블록 (손대지 않음)

펜스·본문·닫는 펜스가 모두 4칸이다. 기대: 수정 전후 모두 바뀌지 않는다.

1. 첫 페이지를 요청합니다.

    ```text
    GET /v1/items?size=20
    → 목록 20건
    ```

2. 다음 페이지를 요청합니다.
