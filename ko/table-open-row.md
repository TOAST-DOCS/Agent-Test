<!-- pre-align:aligned sig=e2e09e4r0w -->

<a id="tor"></a>
# table-open-row e2e 픽스처

이 문서는 자동 생성된 e2e 픽스처입니다 (20261018-122611).

<a id="tor-last"></a>
## 인증 응답 { #tor-last }

인증 정보 등록 응답의 필드입니다.

| 이름 | 타입 | 필수 | 설명 |
|------------ | ------------- | ----- | ------------ |
|   authId | String| N | 내부적으로 관리하는 인증 수단 아이디 |
|   userAccessKeyID | String| N | User Access Key ID |
|   secretAccessKey | String| N | 비밀 키 |
|   tokenExpiryPeriod | Long| N | 토큰 만료 기간(초 단위)
|   tokenFormatCode | String| N | 토큰 포맷 코드(OPAQUE, JWT) |


<a id="tor-mid"></a>
## 프로젝트 응답 { #tor-mid }

프로젝트 조회 응답의 필드입니다.

| 이름 | 타입 | 필수 | 설명 |
|------------ | ------------- | ----- | ------------ |
|   projectId | String| No | 프로젝트 아이디 |
|   projectName | String| No | 콘솔에 표시되는 프로젝트 이름
|   ownerUuid | String| No | 프로젝트 소유자 UUID |
|   regDatetime | Date| No | 생성 일시 |


<a id="tor-closed"></a>
## 멤버 응답 { #tor-closed }

멤버 조회 응답의 필드입니다.

| 이름 | 타입 | 필수 | 설명 |
|------------ | ------------- | ----- | ------------ |
|   uuid | String| No | 멤버 UUID |
|   name | String| No | 멤버 이름 |
|   emailAddress | String| No | 멤버 이메일 주소 |
|   joinYmdt | Date| No | 가입 일시 |

