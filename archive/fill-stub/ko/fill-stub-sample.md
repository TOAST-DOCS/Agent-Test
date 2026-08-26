<!-- pre-align:aligned sig=28e448e4e890 -->

<a id="fill-stub-sample"></a>
## 빈 번역 채우기 샘플 { #fill-stub-sample }

이 문서는 **빈 번역 채우기**(`translate/translate_fill_stubs.py`) 를 검증하기 위한 테스트 픽스처입니다.
en/ja 사본에는 pre-align 이 남기는 두 종류의 stub 이 일부러 남아 있으며, 채우기 실행이 그 stub 만 정확히
채우고 나머지 섹션은 바이트 단위로 보존하는지 확인합니다.

이 문서는 사용자 가이드 메뉴(`ko/nav.yml`) 에 등록하지 않습니다. 배포되는 문서가 아니라 파이프라인 픽스처입니다.

<a id="fill-stub-untouched"></a>
## 이미 번역된 섹션 { #fill-stub-untouched }

이 섹션은 en/ja 에 이미 번역되어 있습니다. 채우기 실행 뒤에도 **바이트 단위로 동일** 해야 합니다.
한 글자라도 달라졌다면 채우기가 stub 바깥을 건드린 것이므로 결함입니다.

<a id="fill-stub-body"></a>
## 본문만 비어 있는 섹션 { #fill-stub-body }

en/ja 의 같은 섹션은 heading 은 번역되어 있고 본문만 body stub 으로 비어 있습니다.
채우기 실행은 heading 줄을 그대로 두고 이 문단만 번역해 넣어야 합니다.

인스턴스를 생성하면 콘솔의 상태가 **실행 중** 으로 바뀔 때까지 몇 분이 걸릴 수 있습니다.
상태가 오래 바뀌지 않으면 이미지와 인스턴스 타입의 조합이 올바른지 먼저 확인합니다.

<a id="fill-stub-table"></a>
## 표가 있는 섹션 { #fill-stub-table }

본문에 표가 있는 body stub 입니다. 채워진 뒤에도 표의 열 수와 행 수가 ko 와 같아야 합니다.

| 항목 | 설명 | 기본값 |
|---|---|---|
| 인스턴스 타입 | 생성할 인스턴스의 CPU/메모리 사양 | m2.c1m2 |
| 블록 스토리지 | 루트 볼륨의 크기(GB) | 20 |
| 부팅 스크립트 | 인스턴스 최초 부팅 시 실행할 스크립트 | 없음 |

<a id="fill-stub-code"></a>
## 코드 블록이 있는 섹션 { #fill-stub-code }

코드 블록은 번역 대상이 아닙니다. 아래 블록은 채워진 뒤에도 내용이 그대로여야 합니다.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

블록 밖의 이 문장만 번역 대상이며, 명령과 주석 줄은 손대지 않습니다.

<a id="fill-stub-heading"></a>
## 제목까지 비어 있는 섹션 { #fill-stub-heading }

en/ja 의 같은 섹션은 heading 이 아직 한국어인 heading stub 입니다.
채우기 실행은 heading 과 본문을 함께 번역하되, heading 의 레벨과 `{ #id }` 는 ko 를 정본으로 따라야 합니다.

<a id="fill-stub-heading-child"></a>
### 하위 제목도 비어 있는 경우 { #fill-stub-heading-child }

heading stub 이 연달아 나오는 경우입니다. 부모 섹션과 독립적으로 각각 채워져야 하고,
`###` 레벨이 `##` 로 승격되거나 강등되면 안 됩니다.

## 앵커가 없는 섹션

**부정 대조군입니다. 이 heading 에는 `<a id>` 앵커도 `{ #id }` 속성도 붙이지 마세요.**

채우기는 공유 앵커로 ko 섹션을 찾기 때문에, 앵커가 없는 stub 은 채우지 않고 PR 본문에
"건너뜀" 으로 보고해야 합니다. 조용히 채워지거나 조용히 사라지면 결함입니다.

pre-align 을 이 문서에 다시 돌리면 이 heading 에도 id 가 붙어 대조군이 사라지므로,
그때는 `archive/fill-stub/` 의 사본으로 되돌립니다.

<a id="fill-stub-tail"></a>
## 마지막 섹션 { #fill-stub-tail }

stub 뒤에 오는 섹션입니다. 앞 섹션들이 채워진 뒤에도 이 섹션은 바이트 단위로 보존되어야 합니다.
