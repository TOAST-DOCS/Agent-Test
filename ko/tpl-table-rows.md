<!-- pre-align:aligned sig=00d5570bd1c0 -->

{% set f = (build_flags | select("in", ["public","gov","ncgn","ninc","ngsc","ngovc","ngoic"]) | list | first) %}
{% set ep_domain = {"ninc":"ninc.go.kr","ngsc":"ngsc.go.kr","ngovc":"ngovc.com","ngoic":"ngoic.com"} %}
<a id="compute-image-api-v2-guide"></a>
## Compute > Image > API v2 가이드 { #compute-image-api-v2-guide }

{% if "public" in build_flags %}
Image은(는) API 호출 시 인증/인가를 위해 IaaS 토큰을 사용합니다. IaaS 토큰은 NHN Cloud의 OpenStack 기반 인프라 서비스(IaaS)에서 사용하는 인증 토큰입니다. IaaS 토큰 발급 및 사용에 대한 자세한 내용은 [IaaS 토큰](/nhncloud/ko/public-api/iaas-token) 을 참고하세요.
{% elif "gov" in build_flags %}
Image은(는) API 호출 시 인증/인가를 위해 IaaS 토큰을 사용합니다. IaaS 토큰은 NHN Cloud의 OpenStack 기반 인프라 서비스(IaaS)에서 사용하는 인증 토큰입니다. IaaS 토큰 발급 및 사용에 대한 자세한 내용은 [IaaS 토큰](/nhncloud/ko/public-api/iaas-token-gov) 을 참고하세요.
{% else %}
API를 사용하려면 API 엔드포인트와 토큰 등이 필요합니다. [API 사용 준비](/Compute/Compute/ko/identity-api/)를 참고하여 API 사용에 필요한 정보를 준비합니다.
{% endif %}

이미지 API는 `image` 타입 엔드포인트를 이용합니다. 정확한 엔드포인트는 토큰 발급 응답의 `serviceCatalog`를 참조합니다.

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "public" in build_flags %}
| image | 한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>일본 리전 | https://kr1-api-image-infrastructure.nhncloudservice.com<br>https://kr2-api-image-infrastructure.nhncloudservice.com<br>https://kr3-api-image-infrastructure.nhncloudservice.com<br>https://jp1-api-image-infrastructure.nhncloudservice.com |
{% elif "gov" in build_flags %}
| image | 한국(판교) 리전<br>한국(평촌) 리전 | https://kr1-api-image-infrastructure.gov-nhncloudservice.com<br>https://kr2-api-image-infrastructure.gov-nhncloudservice.com |
{% else %}
| image | 한국(대구) 리전 | https://kr4-api-image-infrastructure.$[ ep_domain[f] ]$ |
{% endif %}

API 응답에 가이드에 명시되지 않은 필드가 나타날 수 있습니다. 이런 필드는 NHN Cloud 내부 용도로 사용되며 사전 공지 없이 변경될 수 있으므로 사용하지 않습니다.

<a id="image"></a>
## 이미지 { #image }

<a id="list-images"></a>
### 이미지 목록 조회 { #list-images }

```
GET /v2/images
X-Auth-Token: {tokenId}
```

<a id="list-images-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명                                                                                                                                                       |
|---|---|---|---|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| tokenId | Header | String | O | 토큰 ID                                                                                                                                                    |
| limit | Query | Integer | - | 반환할 이미지 개수(기본값은 25)                                                                                                                                      |
| marker | Query | UUID | - | 조회할 이미지 목록의 첫 번째 이미지 ID<br>정렬 방식에 따라 `marker`로 지정된 이미지부터 `limit`만큼의 이미지 목록을 조회                                                                           |
| name | Query | String | - | 조회할 이미지 이름                                                                                                                                               |
| visibility | Query | Enum | - | 조회할 이미지의 보여 주기 속성<br>`public`, `private`, `shared` 중 하나의 값만 선택 가능<br>생략하면 모든 종류의 이미지 목록 반환                                                               |
| owner | Query | String  | - | 조회할 이미지가 속한 테넌트 ID                                                                                                                                       |
| status | Query | Enum    | - | 조회할 이미지 상태<br>`queued`: 이미지 변환 중<br>`saving`: 이미지 업로드 중<br>`active`: 정상<br>`killed`: 시스템에서 이미지 삭제<br>`deleted`: 삭제된 이미지<br>`pending_delete`: 이미지 삭제 대기 중 |
| size_min | Query | Integer | - | 조회할 이미지의 최소 크기(바이트)                                                                                                                                      |
| size_max | Query | Integer | - | 조회할 이미지의 최대 크기(바이트)                                                                                                                                      |
| sort_key | Query | String | - | 이미지 목록을 정렬할 때 사용할 속성<br>이미지의 모든 속성을 지정 가능, 기본값은 `created_at`                                                                                             |
| sort_dir | Query | Enum | - | 이미지 목록 정렬 방향<br>`asc`(오름차순), `desc`(내림차순) 중 하나의 값만 선택 가능, 기본값은 내림차순                                                                                      |
{% if "public" in build_flags %}
| member_status | Query | Enum | - | 공유 받은 이미지의 경우 멤버 상태에 따른 이미지 목록을 조회<br>`accepted`, `pending`, `rejected`, `all` 중 하나의 값만 선택 가능<br>기본값은 `accepted` |
{% else %}
{% endif %}

<a id="list-images-response"></a>
#### 응답

{% if "public" in build_flags %}
| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| images | Body | Array | 이미지 목록 객체 |
{% else %}
| 이름 | 종류 | 형식 | 설명                                                                                 |
|---|---|---|------------------------------------------------------------------------------------|
| images | Body | Array | 이미지 목록 객체                                                                          |
{% endif %}
| images.status | Body | String | 이미지 상태<br>`queued`, `saving`, `active`, `killed`, `deleted`, `pending_delete` 중 하나 |
{% if "public" in build_flags %}
| images.name | Body | String | 이미지 이름 |
| images.tags | Body | Array | 이미지 태그 목록 |
| images.container_format | Body | String | 이미지 컨테이너 포맷 |
| images.created_at | Body | Datetime | 생성 시각 |
| images.disk_format | Body | String | 이미지 디스크 포맷 |
| images.updated_at | Body | Datetime | 수정 시각 |
| images.min_disk | Body | Integer | 이미지 최소 디스크 요구량(GB)<br>`min_disk` 값보다 큰 블록 스토리지에서만 사용할 수 있음 |
| images.protected | Body | Boolean | 이미지 보호 여부<br>`protected=true`인 경우 수정 및 삭제 불가 |
| images.id | Body | UUID | 이미지 ID |
| images.min_ram | Body | Integer | 이미지 최소 메모리 요구량(MB)<br>`min_disk` 값보다 큰 인스턴스에서만 사용할 수 있음 |
| images.checksum | Body | String | 이미지 내용 해시값<br>내부적으로 이미지 유효성 검증을 위해 사용 |
| images.owner | Body | String | 이미지가 속한 테넌트 ID |
| images.visibility | Body | Enum | 이미지 가시성<br>`public`, `private`, `shared` 중 하나 |
| images.virtual_size | Body | Integer | 이미지 가상 크기 |
| images.size | Body | Integer | 이미지 실제 크기(바이트) |
| images.properties | Body | Object | 이미지 속성 객체<br>이미지별 사용자 지정 속성을 키-값 쌍 형태로 기술 |
| images.self | Body | URI | 이미지 경로 |
| images.file | Body | String | 이미지 파일 경로 |
| images.schema | Body | URI | 이미지 스키마 경로 |
| schema | Body | URI | 이미지 목록 스키마 경로 |
| first | Body | URI | 이미지 목록의 첫 번째 페이지에 해당하는 경로 |
| next| Body | URI | 이미지 목록의 다음 페이지에 해당하는 경로 |
{% elif "gov" in build_flags %}
| images.name | Body | String | 이미지 이름                                                                             |
| images.tags | Body | Array | 이미지 태그 목록                  |
| images.container_format | Body | String | 이미지 컨테이너 포맷                                                                        |
| images.created_at | Body | Datetime | 생성 시각                                                                              |
| images.disk_format | Body | String | 이미지 디스크 포맷                                                                         |
| images.updated_at | Body | Datetime | 수정 시각                                                                              |
| images.min_disk | Body | Integer | 이미지 최소 디스크 요구량(GB)<br>`min_disk` 값보다 큰 블록 스토리지에서만 사용할 수 있음                         |
| images.protected | Body | Boolean | 이미지 보호 여부<br>`protected=true`인 경우 수정 및 삭제 불가                                       |
| images.id | Body | UUID | 이미지 ID                                                                             |
| images.min_ram | Body | Integer | 이미지 최소 메모리 요구량(MB)<br>`min_disk` 값보다 큰 인스턴스에서만 사용할 수 있음                            |
| images.checksum | Body | String | 이미지 내용 해시값<br>내부적으로 이미지 유효성 검증을 위해 사용                                              |
| images.owner | Body | String | 이미지가 속한 테넌트 ID                                                                     |
| images.visibility | Body | Enum | 이미지 가시성<br>`public`, `private`, `shared` 중 하나                                      |
| images.virtual_size | Body | Integer | 이미지 가상 크기                                                                          |
| images.size | Body | Integer | 이미지 실제 크기(바이트)                                                                     |
| images.properties | Body | Object | 이미지 속성 객체<br>이미지별 사용자 지정 속성을 키-값 쌍 형태로 기술                                          |
| images.self | Body | URI | 이미지 경로                                                                             |
| images.file | Body | String | 이미지 파일 경로                                                                          |
| images.schema | Body | URI | 이미지 스키마 경로                                                                         |
| schema | Body | URI | 이미지 목록 스키마 경로                                                                      |
| first | Body | URI | 이미지 목록의 첫 번째 페이지에 해당하는 경로                                                          |
| next| Body | URI | 이미지 목록의 다음 페이지에 해당하는 경로                                                            |
{% else %}
| images.name | Body | String | 이미지 이름                                                                             |
| images.tag | Body | String | 이미지 태그<br>`_AVAILABLE_` 태그를 삭제하면 콘솔에서는 조회되지 않으므로, 태그를 삭제하지 않도록 주의                  |
| images.container_format | Body | String | 이미지 컨테이너 포맷                                                                        |
| images.created_at | Body | Datetime | 생성 시각                                                                              |
| images.disk_format | Body | String | 이미지 디스크 포맷                                                                         |
| images.updated_at | Body | Datetime | 수정 시각                                                                              |
| images.min_disk | Body | Integer | 이미지 최소 디스크 요구량(GB)<br>`min_disk` 값보다 큰 블록 스토리지에서만 사용할 수 있음                         |
| images.protected | Body | Boolean | 이미지 보호 여부<br>`protected=true`인 경우 수정 및 삭제 불가                                       |
| images.id | Body | UUID | 이미지 ID                                                                             |
| images.min_ram | Body | Integer | 이미지 최소 메모리 요구량(MB)<br>`min_disk` 값보다 큰 인스턴스에서만 사용할 수 있음                            |
| images.checksum | Body | String | 이미지 내용 해시값<br>내부적으로 이미지 유효성 검증을 위해 사용                                              |
| images.owner | Body | String | 이미지가 속한 테넌트 ID                                                                     |
| images.visibility | Body | Enum | 이미지 가시성<br>`public`, `private`, `shared` 중 하나                                      |
| images.virtual_size | Body | Integer | 이미지 가상 크기                                                                          |
| images.size | Body | Integer | 이미지 실제 크기(바이트)                                                                     |
| images.properties | Body | Object | 이미지 속성 객체<br>이미지별 사용자 지정 속성을 키-값 쌍 형태로 기술                                          |
| images.self | Body | URI | 이미지 경로                                                                             |
| images.file | Body | String | 이미지 파일 경로                                                                          |
| images.schema | Body | URI | 이미지 스키마 경로                                                                         |
| schema | Body | URI | 이미지 목록 스키마 경로                                                                      |
| first | Body | URI | 이미지 목록의 첫 번째 페이지에 해당하는 경로                                                          |
| next| Body | URI | 이미지 목록의 다음 페이지에 해당하는 경로                                                            |
{% endif %}

<details><summary>예시</summary>
<p>

```json
{
  "images": [
    {
      "container_format": "bare",
      "min_ram": 0,
      "updated_at": "2018-12-11T01:01:35Z",
      "login_username": "centos",
      "file": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b/file",
      "owner": "c289b99209ca4e189095cdecebbd092d",
      "id": "1c868787-6207-4ff2-a1e7-ae1331d6829b",
      "size": 1778843648,
      "os_distro": "CentOS",
      "self": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b",
      "disk_format": "qcow2",
      "os_version": "6.10",
      "schema": "/v2/schemas/image",
      "status": "active",
      "description": "CentOS 6.10 (2018.10.23)",
      "tags": [],
      "visibility": "public",
      "os_architecture": "amd64",
      "min_disk": 20,
      "virtual_size": null,
      "name": "CentOS 6.10 (2018.10.23)",
      "hypervisor_type": "qemu",
      "created_at": "2018-10-23T02:17:43Z",
      "protected": true,
      "checksum": "f803c5c15bcf9a75935980a900a04584",
      "os_type": "linux"
    }
  ],
  "schema": "/v2/schemas/images",
  "first": "/v2/images",
  "next": "/v2/images?marker=057f9a69-4e4c-4025-8a69-fa248cd9db94"
}
```

</p>
</details>

---

<a id="get-image"></a>
### 이미지 보기 { #get-image }

```
GET /v2/images/{imageId}
X-Auth-Token: {tokenId}
```

<a id="get-image-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| imageId | URL | UUID | O | 조회할 이미지 ID |
| tokenId | Header | String | O | 토큰 ID|

<a id="get-image-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| status | Body | String | 이미지 상태 |
| name | Body | String | 이미지 이름 |
{% if "public" in build_flags %}
| tags | Body | String | 이미지 태그 목록 |
{% elif "gov" in build_flags %}
| tags | Body | Array | 이미지 태그 목록 |
{% else %}
| tag | Body | String | 이미지 태그<br>`_AVAILABLE_` 태그를 삭제하면 콘솔에서는 조회되지 않으므로, 태그를 삭제하지 않도록 주의 |
{% endif %}
| container_format | Body | String | 이미지 컨테이너 포맷 |
| created_at | Body | Datetime | 생성 시각 |
| disk_format | Body | String | 이미지 디스크 포맷 |
| updated_at | Body | Datetime | 수정 시각 |
| min_disk | Body | Integer | 이미지 최소 디스크 요구량(GB)<br>`min_disk` 값보다 큰 블록 스토리지에서만 사용할 수 있음 |
| protected | Body | Boolean | 이미지 보호 여부<br>`protected=true`인 경우 수정 및 삭제 불가 |
| id | Body | UUID | 이미지 ID |
| min_ram | Body | Integer | 이미지 최소 메모리 요구량(MB)<br>`min_disk` 값보다 큰 인스턴스에서만 사용할 수 있음 |
| checksum | Body | String | 이미지 내용의 해시값<br>내부적으로 이미지 유효성 검증을 위해 사용 |
| owner | Body | String | 이미지가 속한 테넌트 ID |
| visibility | Body | Enum | 이미지 가시성<br>`public`, `private`, `shared` 중 하나 |
| virtual_size | Body | Integer | 이미지 가상 크기 |
| size | Body | Integer | 이미지 실제 크기(바이트) |
| properties | Body | Object | 이미지 속성 객체<br>이미지별 사용자 지정 속성을 키-값 쌍 형태로 기술 |
| self | Body | URI | 이미지 경로 |
| file | Body | String | 이미지 파일 경로 |
| schema | Body | URI| 이미지 스키마 경로 |

<details><summary>예시</summary>
<p>

```json
{
  "container_format": "bare",
  "min_ram": 0,
  "updated_at": "2018-12-11T01:01:35Z",
  "login_username": "centos",
  "file": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b/file",
  "owner": "c289b99209ca4e189095cdecebbd092d",
  "id": "1c868787-6207-4ff2-a1e7-ae1331d6829b",
  "size": 1778843648,
  "os_distro": "CentOS",
  "self": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b",
  "disk_format": "qcow2",
  "os_version": "6.10",
  "schema": "/v2/schemas/image",
  "status": "active",
  "description": "CentOS 6.10 (2018.10.23)",
  "tags": [],
  "visibility": "public",
  "os_architecture": "amd64",
  "min_disk": 20,
  "virtual_size": null,
  "name": "CentOS 6.10 (2018.10.23)",
  "hypervisor_type": "qemu",
  "created_at": "2018-10-23T02:17:43Z",
  "protected": true,
  "checksum": "f803c5c15bcf9a75935980a900a04584",
  "os_type": "linux"
}
```

</p>
</details>

---

<a id="create-image"></a>
### 이미지 생성 { #create-image }

{% if "public" in build_flags %}
빈 이미지를 생성합니다. NHN Cloud에서 이미지를 사용하려면 `이미지 생성` 후에 `이미지 업로드` API를 이용해 실제 파일을 업로드해야 합니다.

{% elif "gov" in build_flags %}
빈 이미지를 생성합니다. NHN Cloud에서 이미지를 사용하려면 `이미지 생성` 후에 `이미지 업로드` API를 이용해 실제 파일을 업로드해야 합니다.

{% else %}
{% endif %}
```
POST /v2/images
X-Auth-Token: {tokenId}
```

<a id="create-image-request"></a>
#### 요청
| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tokenId | Header | String | O | 토큰 ID |
{% if "public" in build_flags %}
| name | Body | String | O | 이미지 이름 |
{% elif "gov" in build_flags %}
| name | Body | String | O | 이미지 이름 |
{% else %}
{% endif %}
| container_format | Body | String | - | 이미지 컨테이너 포맷 |
| disk_format | Body | String | - | 이미지 디스크 포맷 |
| min_disk | Body | Integer | - | 이미지 최소 디스크 요구량(GB) |
| min_ram | Body | Integer | - | 이미지 최소 메모리 요구량(MB) |
| protected | Body | Boolean | - | 이미지 보호 여부, true 또는 false |
{% if "public" in build_flags %}
| tags | Body | Array | - | 이미지 태그 목록 |
| visibility | Body | String | - | 이미지 가시성<br>`private`, `shared` 중 하나 |
| os_type | Body | String | O | 운영체제 타입<br>`windows`, `linux` 중 하나 |
| os_distro | Body | String | - | 운영체제 배포판 |
| os_version | Body | String | - | 운영체제 버전 |
{% elif "gov" in build_flags %}
| tags | Body | Array | - | 이미지 태그 목록 |
| visibility | Body | String | - | 이미지 가시성<br>`private`, `shared` 중 하나 |
| os_type | Body | String | O | 운영체제 타입<br>`windows`, `linux` 중 하나 |
| os_distro | Body | String | - | 운영체제 배포판 |
| os_version | Body | String | - | 운영체제 버전 |
{% else %}
| tags | Body | Array | - | 이미지 태그 목록<br>`_AVAILABLE_` 태그를 삭제하면 콘솔에서는 조회되지 않으므로, 태그를 삭제하지 않도록 주의 |
| visibility | Body | String | - | 이미지 가시성<br>`public`, `private`, `shared` 중 하나 |
{% endif %}

<details><summary>예시</summary>
<p>

```json
{
{% if "public" in build_flags %}
    "name": "Ubuntu Image",
{% elif "gov" in build_flags %}
    "name": "Ubuntu Image",
{% else %}
{% endif %}
    "container_format": "bare",
{% if "public" in build_flags %}
    "disk_format": "qcow2",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% elif "gov" in build_flags %}
    "disk_format": "qcow2",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% else %}
    "disk_format": "raw",
    "name": "Ubuntu",
{% endif %}
}
```

<p>
</details>

<a id="create-image-response"></a>
#### 응답
| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| status | Body | String | 이미지 상태<br>`queued`, `saving`, `active`, `killed`, `deleted`, `pending_delete` 중 하나 |
| name | Body | String | 이미지 이름 |
{% if "public" in build_flags %}
| tags | Body | String | 이미지 태그 목록 |
{% elif "gov" in build_flags %}
| tags | Body | Array | 이미지 태그 목록 |
{% else %}
| tags | Body | String | 이미지 태그 목록<br>`_AVAILABLE_` 태그를 삭제하면 콘솔에서는 조회되지 않으므로, 태그를 삭제하지 않도록 주의 |
{% endif %}
| container_format | Body | String | 이미지 컨테이너 포맷 |
| created_at | Body | Datetime | 생성 시각 |
| disk_format | Body | String | 이미지 디스크 포맷 |
| updated_at | Body | Datetime | 수정 시각 |
| min_disk | Body | Integer | 이미지 최소 디스크 요구량(GB)<br>`min_disk` 값보다 큰 블록 스토리지에서만 사용할 수 있음 |
| protected | Body | Boolean | 이미지 보호 여부<br>`protected=true`인 경우 수정 및 삭제 불가 |
| id | Body | UUID | 이미지 ID |
| min_ram | Body | Integer | 이미지 최소 메모리 요구량(MB)<br>`min_disk` 값보다 큰 인스턴스에서만 사용할 수 있음 |
| checksum | Body | String | 이미지 내용의 해시값<br>내부적으로 이미지 유효성 검증을 위해 사용 |
| owner | Body | String | 이미지가 속한 테넌트 ID |
{% if "public" in build_flags %}
| visibility | Body | Enum | 이미지 가시성<br>`private`, `shared` 중 하나 |
{% else %}
| visibility | Body | Enum | 이미지 가시성<br>`public`, `private`, `shared` 중 하나 |
{% endif %}
| virtual_size | Body | Integer | 이미지 가상 크기 |
| size | Body | Integer | 이미지 실제 크기(바이트) |
| properties | Body | Object | 이미지 속성 객체<br>이미지별 사용자 지정 속성을 키-값 쌍 형태로 기술 |
| self | Body | URI | 이미지 경로 |
| file | Body | String | 이미지 파일 경로 |
| schema | Body | URI| 이미지 스키마 경로 |
{% if "public" in build_flags %}
| os_type | Body | String | 운영체제 타입<br>`windows`, `linux` 중 하나 |
| os_distro | Body | String | 운영체제 배포판 |
| os_version | Body | String | 운영체제 버전 |
{% elif "gov" in build_flags %}
| os_type | Body | String | 운영체제 타입<br>`windows`, `linux` 중 하나 |
| os_distro | Body | String | 운영체제 배포판 |
| os_version | Body | String | 운영체제 버전 |
{% else %}
{% endif %}

<details><summary>예시</summary>
<p>

```json
{
    "status": "queued",
{% if "public" in build_flags %}
    "name": "Ubuntu Image",
{% elif "gov" in build_flags %}
    "name": "Ubuntu Image",
{% else %}
    "name": "Ubuntu",
{% endif %}
    "tags": [],
    "container_format": "bare",
    "created_at": "2015-11-29T22:21:42Z",
    "size": null,
{% if "public" in build_flags %}
    "disk_format": "qcow2",
{% elif "gov" in build_flags %}
    "disk_format": "qcow2",
{% else %}
    "disk_format": "raw",
{% endif %}
    "updated_at": "2015-11-29T22:21:42Z",
    "visibility": "private",
    "locations": [],
    "self": "/v2/images/b2173dd3-7ad6-4362-baa6-a68bce3565cb",
    "min_disk": 0,
    "protected": false,
    "id": "b2173dd3-7ad6-4362-baa6-a68bce3565cb",
    "file": "/v2/images/b2173dd3-7ad6-4362-baa6-a68bce3565cb/file",
    "checksum": null,
    "os_hash_algo": null,
    "os_hash_value": null,
    "os_hidden": false,
    "owner": "bab7d5c60cd041a0a36f7c4b6e1dd978",
    "virtual_size": null,
    "min_ram": 0,
{% if "public" in build_flags %}
    "schema": "/v2/schemas/image",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% elif "gov" in build_flags %}
    "schema": "/v2/schemas/image",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% else %}
    "schema": "/v2/schemas/image"
{% endif %}
}
```

<p>
</details>

---
