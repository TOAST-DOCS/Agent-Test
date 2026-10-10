<!-- pre-align:aligned sig=178a08dfcc40 -->

<a id="compute-instance-spec-guide"></a>
## Compute > Instance > 리소스 명세 가이드 { #compute-instance-spec-guide }

인스턴스 API 응답 본문의 리소스 필드 명세를 정리한 문서입니다. 각 필드의 경로, 타입, Not Null 여부, 설명을 표로 제공합니다.

<a id="resource-fields"></a>
### 리소스 필드 { #resource-fields }

| 경로 | 타입 | Not Null | 설명 |
| --- | --- | --- | --- |
| resource.id | String | O | 리소스 아이디입니다. |
| resource.name | String | O | 리소스 이름입니다. 콘솔에서 변경할 수 있습니다. |
| resource.status | Enum | O | 리소스 상태입니다.<br>[ACTIVE(사용 중), PAUSED(일시 중지), DELETED(삭제됨)] |
| resource.quota | Object | X | 리소스 할당량 정보입니다. |
| resource.quota.limit | Integer | X | 최대 할당량입니다. 기본값은 100입니다. |
| resource.quota.used | Integer | X | 현재 사용량입니다. |
| resource.labels | Array | X | 리소스에 부여된 라벨 목록입니다. |

<a id="spec-change-policy"></a>
### 명세 변경 정책 { #spec-change-policy }

필드 추가는 하위 호환으로 간주되어 예고 없이 반영될 수 있습니다. 필드 삭제 또는 타입 변경은 최소 30일 전에 공지사항으로 안내됩니다.
