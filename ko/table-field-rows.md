<!-- pre-align:aligned sig=7a202975f1db -->

<a id="tfr"></a>
# table-field-rows e2e 픽스처

이 문서는 자동 생성된 e2e 픽스처입니다 (20260927-143557).

<a id="tfr-overview"></a>
## 개요 { #tfr-overview }

서비스 설정을 수정하는 API입니다. 요청 본문에는 수정할 필드만 넣고, 넣지 않은 필드는 기존 값을 유지합니다.

<a id="tfr-fields"></a>
## 요청 본문 { #tfr-fields }

[필드]

| 이름                  | 타입    | 필수 여부 | 기본값 | 유효 범위                                                    | 설명                                                         |
| --------------------- | ------- | --------- | ------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| domain                | String  | 필수      |        | 최대 255자                                                   | 수정할 도메인(서비스 이름)                                   |
| useOriginCacheControl | Boolean | 선택      |        | true/false                                                        | 캐시 만료 설정(true: 원본 서버 설정 사용, false: 사용자 설정 사용). useOriginCacheControl이나 cacheType 중 하나는 반드시 입력해야 합니다.      |
| cacheType             | String  | 선택      |        | BYPASS, NO_STORE            | 캐시 타입 설정. useOriginCacheControl이나 cacheType 중 하나는 반드시 입력해야 합니다.                                          |
| referrerType          | String  | 필수      |        | BLACKLIST/WHITELIST                                          | 리퍼러 접근 관리("BLACKLIST": 블랙리스트, "WHITELIST": 화이트리스트) |
| referrers             | List    | 선택      |        |                                                              | 정규 표현식 형태의 리퍼러 헤더 목록 |
| isAllowWhenEmptyReferrer | Boolean | 선택      | true      | true/false             | 리퍼러 헤더가 없는 경우 콘텐츠 접근 허용(true)/거부(false) 여부             |
| description           | String  | 선택      |        | 최대 255자                                                   | 설명                                                         |
| domainAlias           | List    | 선택      |        | 최대 255자                                                   | 도메인 별칭(개인 또는 회사가 소유한 도메인 사용) |
| defaultMaxAge         | Integer | 선택      | 0      | 0~2,147,483,647                                            | 캐시 만료 시간(초), 기본값 0은 604,800초입니다.              |
| origins               | List    | 필수      |        |                                                              | 원본 서버                                                    |
| origins[0].origin     | String  | 필수      |        | 최대 255자                                                   | 원본 서버(도메인 또는 IP)                                      |
| origins[0].originPath | String  | 선택      |        | 최대 8192자                                                  | 원본 서버 하위 경로                                          |
| forwardHostHeader     | String  | 필수      |        | ORIGIN_HOSTNAME<br/>REQUEST_HOST_HEADER   | CDN 서버가 원본 서버로 콘텐츠 요청 시 전달할 호스트 헤더 설정("ORIGIN_HOSTNAME": 원본 서버의 호스트 이름으로 설정, "REQUEST_HOST_HEADER": 클라이언트 요청의 호스트 헤더로 설정)|
| useOrigin             | String  | 필수      |        | Y/N                                                          | 캐시 만료 설정(Y: 원본 설정 사용, "N":사용자 설정 사용)      |
| rootPathAccessControl  | Object  | 선택 |  |  | CDN 서비스의 루트 경로에 대한 접근 제어 설정 | 

- `forwardHostHeader`의 기본값은 `domainAlias`를 설정한 경우 `REQUEST_HOST_HEADER`입니다.
