<!-- pre-align:aligned sig=e2e0c3117a1 -->

<a id="tcm"></a>
# table-cell-mirror e2e 픽스처

이 문서는 자동 생성된 e2e 픽스처입니다 (20261014-104221).

<a id="tcm-response"></a>
## 응답 { #tcm-response }

API 응답 본문의 필드입니다.

| 이름 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| header.isSuccessful | Boolean | Y | 성공 여부 |
| header.resultCode | Integer | Y | 결과 코드 |
| header.resultMessage | String | Y | 결과 메시지 |
| body.id | String | N | 리소스 ID |
| body.name | String | N | 리소스 이름 |
| body.createdAt | DateTime | N | 생성 일시 |

<a id="tcm-request"></a>
## 요청 { #tcm-request }

요청 헤더와 파라미터입니다.

| 구분 | 이름 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- | --- |
| Header | X-Auth-Token | String | Y | 발급받은 토큰 |
| Path | appKey | String | Y | 앱키 |
| Query | pageNum | Integer | N | 페이지 번호 |
| Query | pageSize | Integer | N | 페이지 크기 |

<a id="tcm-partial"></a>
## 부분 수정 { #tcm-partial }

라벨을 지정하는 필드입니다.

| 이름 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| labelKey | String | Y | 라벨 키(최대 64자, 영문·숫자만 허용) |
| labelValue | String | N | 라벨 값 |

<a id="tcm-control"></a>
## 대조군 { #tcm-control }

리소스의 위치를 지정합니다.

| 이름 | 필수 여부 | 설명 |
| --- | --- | --- |
| region | 필수 | 리전 코드 |
| zone | 필수 | 가용성 영역 |
