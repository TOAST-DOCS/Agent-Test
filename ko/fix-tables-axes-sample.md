<!-- pre-align:aligned sig=fxaxes000000 -->

<a id="fxaxes-sample"></a>
## 검출 축 픽스처 { #fxaxes-sample }

깨진 표 정비의 검출 축(식별자 · 행 수 · 열 수)을 대조하는 픽스처입니다. `ko/nav.yml` 에 등록하지 않습니다.

<a id="fxaxes-rows"></a>
## A. 식별자가 없는 표에서 행이 빠짐 { #fxaxes-rows }

첫 열이 소문자 한 낱말이라 `_row_key` 가 키로 세지 않습니다. en/ja 에 `exact` 행이 없습니다.

| 이름 | 구분 | 타입 | 설명 |
|---|---|---|---|
| name | Query | String | 이름으로 검색합니다 |
| exact | Query | Boolean | 완전 일치 검색 여부입니다 |
| limit | Query | Number | 한 번에 가져올 개수입니다 |

<a id="fxaxes-cols"></a>
## B. 키는 다 있는데 열이 하나 빠짐 { #fxaxes-cols }

en/ja 에 `Not Null` 열이 통째로 없습니다. 식별자는 전부 살아 있습니다.

| 이름 | 타입 | Not Null | 설명 |
|---|---|---|---|
| resultCode | Integer | O | 결과 코드입니다 |
| resultMessage | String | O | 결과 메시지입니다 |
| isSuccessful | Boolean | O | 성공 여부입니다 |

<a id="fxaxes-keys"></a>
## C. 대조군 — 식별자 행이 빠짐 { #fxaxes-keys }

기존 축이 잡던 모양입니다. en/ja 에 `pageSize` 가 없습니다. 이 축은 그대로 잡혀야 합니다.

| 이름 | 타입 | 설명 |
|---|---|---|
| tokenId | Header | 토큰 ID 입니다 |
| appKey | Path | 앱키입니다 |
| pageSize | Query | 페이지 크기입니다 |

<a id="fxaxes-outlier"></a>
## D. 대조군 — 파이프 하나가 빠진 행 { #fxaxes-outlier }

en/ja 의 두 번째 행만 구분 파이프가 하나 빠져 있습니다. 행 수도 열 수(최빈값)도 같으므로 **건드리면 안 됩니다**.

| 이름 | 타입 | 설명 |
|---|---|---|
| clusterId | UUID | 클러스터 UUID 입니다 |
| clusterName | String | 클러스터 이름입니다 |
| nodeCount | Integer | 노드 수입니다 |

<a id="fxaxes-healthy"></a>
## E. 대조군 — 정상 표 { #fxaxes-healthy }

세 언어가 같습니다. 바이트 단위로 보존되어야 합니다.

| 이름 | 타입 | 설명 |
|---|---|---|
| flavorId | UUID | 인스턴스 타입 UUID 입니다 |
| imageId | UUID | 이미지 UUID 입니다 |
