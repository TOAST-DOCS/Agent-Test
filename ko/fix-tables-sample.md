<!-- pre-align:aligned sig=86fc80138a36 -->

<a id="fix-tables-sample"></a>
## 깨진 표 정비 샘플 { #fix-tables-sample }

이 문서는 **깨진 표 정비**(`translate/translate_fix_tables.py`) 를 검증하기 위한 테스트 픽스처입니다.
en/ja 사본에는 ko 와 표가 어긋난 섹션이 일부러 세 가지 모양으로 남아 있으며, 정비 실행이 그 섹션의
본문만 ko 기준으로 다시 만들고 나머지 섹션은 바이트 단위로 보존하는지 확인합니다.

이 문서는 사용자 가이드 메뉴(`ko/nav.yml`) 에 등록하지 않습니다. 배포되는 문서가 아니라 파이프라인 픽스처입니다.

<a id="fix-tables-untouched"></a>
## 정상 표가 있는 섹션 { #fix-tables-untouched }

이 섹션의 표는 en/ja 에 ko 와 같은 식별자 행으로 번역되어 있습니다. 정비 실행 뒤에도 **바이트 단위로 동일** 해야 합니다.

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| tokenId | Header | String | 토큰 ID |
| appKey | Path | String | 앱키 |
| pageSize | Query | Integer | 한 페이지의 항목 수 |

<a id="fix-tables-missing"></a>
## 표가 사라진 섹션 { #fix-tables-missing }

en/ja 의 같은 섹션에는 아래 표가 없습니다. 섹션 안 표 개수가 ko 와 다르므로 정비 실행이 이 섹션의 본문을 ko 기준으로 다시 만들어야 합니다.

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| clusterId | Body | UUID | 클러스터 UUID |
| clusterName | Body | String | 클러스터 이름 |
| nodeCount | Body | Integer | 노드 수 |

<a id="fix-tables-shifted"></a>
## 첫 열이 덮인 섹션 { #fix-tables-shifted }

en/ja 의 같은 섹션은 표의 행 수와 열 수가 ko 와 같지만, 첫 열의 식별자가 형식 이름으로 덮여 있습니다. ko 식별자 행이 짝 표에 없으므로 다시 만들어야 합니다.

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| flavorId | Body | UUID | 인스턴스 타입 UUID |
| imageId | Body | UUID | 이미지 UUID |
| keyName | Body | String | 키페어 이름 |

<a id="fix-tables-rows"></a>
## 행이 빠진 섹션 { #fix-tables-rows }

en/ja 의 같은 섹션은 표에서 식별자 행 하나가 빠져 있습니다. 나머지 행은 정상입니다.

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| volumeId | Body | UUID | 블록 스토리지 UUID |
| volumeSize | Body | Integer | 크기(GB) |
| volumeType | Body | String | 스토리지 종류 |

<a id="fix-tables-prose-keys"></a>
## 식별자가 없는 표 { #fix-tables-prose-keys }

**부정 대조군입니다.** 이 표의 첫 열은 산문이라 식별자 행이 없고, en/ja 의 표는 행 수·열 수가 같습니다. 관측 가능한 결함이 없으므로 정비 실행은 이 섹션을 건드리지 않아야 합니다.

| 항목 | 설명 |
|---|---|
| 인스턴스 타입 | 생성할 인스턴스의 CPU/메모리 사양 |
| 블록 스토리지 | 루트 볼륨의 크기 |

### 앵커가 없는 하위 섹션

**두 번째 부정 대조군입니다. 이 heading 에는 `<a id>` 앵커도 `{ #id }` 속성도 붙이지 마세요.**

아래 표는 en/ja 에서 식별자 행 하나가 빠져 있습니다. 그러나 이 heading 에는 앵커가 없어 표가 위 섹션 소유로 귀속되고, 재구성 단위는 이 heading 에서 끊깁니다. 정비 실행은 위 섹션을 다시 만들지 않고 PR 본문에 "건너뜀" 으로 보고해야 합니다.

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| metricName | Body | String | 지표 이름 |
| thresholdValue | Body | Integer | 임계치 |
| duration | Body | Integer | 유지 시간(분) |

<a id="fix-tables-tail"></a>
## 마지막 섹션 { #fix-tables-tail }

정비 대상 뒤에 오는 섹션입니다. 앞 섹션들이 다시 만들어진 뒤에도 이 섹션은 바이트 단위로 보존되어야 합니다.
