<!-- pre-align:aligned sig=27ed74e0499b -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 가이드 { #compute-instance-api-v2-guide }

Instance는 API 호출 시 인증/인가를 위해 IaaS 토큰을 사용합니다. IaaS 토큰은 NHN Cloud의 OpenStack 기반 인프라 서비스(IaaS)에서 사용하는 인증 토큰입니다. IaaS 토큰 발급 및 사용에 대한 자세한 내용은 [IaaS 토큰](/nhncloud/ko/public-api/iaas-token) 을 참고하세요.

인스턴스 API는 `compute` 타입 엔드포인트를 이용합니다. 정확한 엔드포인트는 토큰 발급 응답의 `serviceCatalog`를 참조합니다.

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
| compute | 한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>일본 리전 | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

API 응답에 가이드에 명시되지 않은 필드가 나타날 수 있습니다. 이런 필드는 NHN Cloud 내부 용도로 사용되며 사전 공지 없이 변경될 수 있으므로 사용하지 않습니다.

<a id="instance-flavors"></a>
## 인스턴스 타입 { #instance-flavors }

<a id="list-flavors"></a>
### 타입 목록 보기 { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="list-flavors-request"></a>
#### 요청

이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| tokenId | Header | String | O | 토큰 ID |
| minDisk | Query | Integer | - | 최소 블록 스토리지 크기(GB)<br>지정한 크기보다 블록 스토리지 크기가 큰 타입만 반환 |
| minRam | Query | Integer | - | 최소 RAM 크기(MB)<br>지정한 크기보다 RAM 크기가 큰 타입만 반환 |

<a id="list-flavors-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| flavors | Body | Object | 인스턴스 타입 목록 객체 |
| flavors.id | Body | UUID | 인스턴스 타입 ID |
| flavors.links | Body | Object | 인스턴스 타입 경로 객체 |
| flavors.name | Body | String | 인스턴스 타입 이름 |


<details><summary>예시</summary>
<p>

```json
{
  "flavors": [
    {
      "id": "013bea75-8541-4c6f-9abe-a03fee3d74fe",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/013bea75-8541-4c6f-9abe-a03fee3d74fe",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/013bea75-8541-4c6f-9abe-a03fee3d74fe",
          "rel": "bookmark"
        }
      ],
      "name": "x1.c32m256"
    },
    {
      "id": "0f19a344-bc66-4228-8cb1-fb9ca82c54f5",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/0f19a344-bc66-4228-8cb1-fb9ca82c54f5",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/0f19a344-bc66-4228-8cb1-fb9ca82c54f5",
          "rel": "bookmark"
        }
      ],
      "name": "x1.c32m128"
    }
  ]
}
```

</p>
</details>

---

<a id="list-flavors-with-details"></a>
### 타입 목록 상세 보기 { #list-flavors-with-details }

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

<a id="list-flavors-with-details-request"></a>
#### 요청

이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| tokenId | Header | String | O | 토큰 ID |
| minDisk | Query | Integer | - | 최소 블록 스토리지 크기(GB)<br>지정한 크기보다 블록 스토리지 크기가 큰 타입만 반환 |
| minRam | Query | Integer | - | 최소 RAM 크기(MB)<br>지정한 크기보다 RAM 크기가 큰 타입만 반환 |

<a id="list-flavors-with-details-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명             |
|---|---|---|----------------|
| flavors | Body | Object | 인스턴스 타입 목록 객체  |
| flavors.id | Body | UUID | 인스턴스 타입 ID     |
| flavors.links | Body | Object | 인스턴스 타입 경로 객체  |
| flavors.name | Body | String | 인스턴스 타입 이름     |
| flavors.ram | Body | Integer | 메모리 크기(MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | 활성화 여부         |
| flavors.vcpus | Body | Integer | vCPU 개수        |
| flavors.extra_specs | Body | Object | 추가 사양 객체       |
| flavors.swap | Body | Integer | 스와프 영역 크기(GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | 공유 여부          |
| flavors.rxtx_factor | Body | Float | 네트워크 송신/수신 패킷 비율 |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | 임시 블록 스토리지 크기(GB)     |
| flavors.disk | Body | Integer | 루트 블록 스토리지 크기(GB) |

<details><summary>예시</summary>
<p>

```json
{
  "flavors": [
    {
      "name": "x1.c32m256",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/97604802-a090-43fa-a5ce-c7cfd737fbba",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/97604802-a090-43fa-a5ce-c7cfd737fbba",
          "rel": "bookmark"
        }
      ],
      "ram": 262144,
      "OS-FLV-DISABLED:disabled": false,
      "vcpus": 32,
      "extra_specs": {
        "flavor_type": "performance"
      },
      "swap": "",
      "os-flavor-access:is_public": true,
      "rxtx_factor": 1.0,
      "OS-FLV-EXT-DATA:ephemeral": 0,
      "disk": 0,
      "id": "97604802-a090-43fa-a5ce-c7cfd737fbba"
    },
    {
      "name": "x1.c32m128",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/31fa632d-aeec-4f12-8a57-ce9d146228e5",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/31fa632d-aeec-4f12-8a57-ce9d146228e5",
          "rel": "bookmark"
        }
      ],
      "ram": 131072,
      "OS-FLV-DISABLED:disabled": false,
      "vcpus": 32,
      "extra_specs": {
        "flavor_type": "performance"
      },
      "swap": "",
      "os-flavor-access:is_public": true,
      "rxtx_factor": 1.0,
      "OS-FLV-EXT-DATA:ephemeral": 0,
      "disk": 0,
      "id": "31fa632d-aeec-4f12-8a57-ce9d146228e5"
    }
  ]
}
```

</p>
</details>

---

<a id="availability-zones"></a>
## 가용성 영역 { #availability-zones }

<a id="list-availability-zones"></a>
### 가용성 목록 보기 { #list-availability-zones }

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

<a id="list-availability-zones-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| tokenId | Header | String | O | 토큰 ID |

<a id="list-availability-zones-response"></a>
#### 응답
| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| availabilityZoneInfo | Body | Object | 가용성 영역 정보 객체 |
| availabilityZoneInfo.zoneName | Body | String | 가용성 영역 이름 |
| availabilityZoneInfo.zoneState | Body | Object | 가용성 영역 상태 정보 객체 |
| availabilityZoneInfo.available | Body | Object | 가용성 영역 상태 |

<details><summary>예시</summary>
<p>

```json
{
    "availabilityZoneInfo": [
      {
        "zoneState": {
          "available": true
        },
        "zoneName": "kr-pub-a"
      },
      {
        "zoneState": {
          "available": true
        },
        "zoneName": "kr-pub-b"
      }
    ]
}
```

</p>
</details>

---

<a id="key-pairs"></a>
## 키페어 { #key-pairs }

<a id="list-key-pairs"></a>
### 키페어 목록 보기 { #list-key-pairs }
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="list-key-pairs-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| tokenId | Header | String | O | 토큰 ID |

<a id="list-key-pairs-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| keypairs | Body | Array | 키페어 객체 목록 |
| keypairs.keypair | Body | Object | 키페어 객체 |
| keypairs.keypair.name | Body | String | 키페어 이름 |
| keypairs.keypair.public_key | Body | String | 공개키 |
| keypairs.keypair.fingerprint | Body | String | 키페어 지문 |

<details><summary>예시</summary>
<p>

```json
{
  "keypairs": [
    {
      "keypair": {
        "public_key": "ssh-rsa ... Generated-by-Nova",
        "name": "keypair",
        "fingerprint": "SHA256:..."
      }
    }
  ]
}
```

</p>
</details>

---

<a id="show-key-pair"></a>
### 키페어 보기 { #show-key-pair }
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="show-key-pair-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| keypairName | URL | String | O | 키페어 이름 |
| tokenId | Header | String | O | 토큰 ID |

<a id="show-key-pair-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| keypair | Body | Object | 키페어 객체 목록 |
| keypair.public_key | Body | String | 공개키 |
| keypair.user_id | Body | String | 키페어 소유주 ID |
| keypair.name | Body | String | 키페어 이름 |
| keypair.deleted | Body | Boolean | 키페어 삭제 여부 |
| keypair.created_at | Body | Datetime | 키페어 생성 시각<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | 키페어 수정 시각<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | 키페어 삭제 시각<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.fingerprint | Body | String | 키페어 지문 |
| keypair.id | Body | Integer | 키페어 ID |

<details><summary>예시</summary>
<p>

```json
{
  "keypair": {
    "public_key": "ssh-rsa ... Generated-by-Nova",
    "user_id": "826a1213b3f746829515486965690dfe",
    "name": "keypair",
    "deleted": false,
    "created_at": "2020-02-07T03:46:48.000000",
    "updated_at": null,
    "fingerprint": "SHA256:...",
    "deleted_at": null,
    "id": 51
  }
}
```

</p>
</details>

---

<a id="createregister-key-pair"></a>
### 키페어 생성/등록하기 { #createregister-key-pair }

```
POST /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="createregister-key-pair-request"></a>
#### 요청

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| tokenId | Header | String | O | 토큰 ID |
| keypair | Body | Object | O | 키페어 객체 |
| keypair.name | Body | String | O | 생성 또는 등록할 키페어 이름 |
| keypair.public_key | Body | String | - | 등록할 공개키. 이 필드가 생략되면 새로운 키페어를 생성합니다. |

<details><summary>예시</summary>
<p>

```json
{
    "keypair": {
        "name": "keypair-d20a3d59-9433-4b79-8726-20b431d89c78",
        "public_key": "ssh-rsa ... Generated-by-Nova"
    }
}
```

</p>
</details>

<a id="createregister-key-pair-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| keypair | Body | Object | 키페어 객체 |
| keypair.public_key | Body | String | 공개키 |
| keypair.private_key | Body | String | 비밀키, 새로운 키페어를 생성한 경우에 비밀키를 반환합니다. |
| keypair.user_id | Body | String | 키페어 소유주 ID |
| keypair.name | Body | String | 키페어 이름 |
| keypair.fingerprint | Body | String | 키페어 지문 |

<details><summary>예시</summary>
<p>

```json
{
    "keypair": {
        "fingerprint": "SHA256:+EZoD ... /DKiGnY4zf5tYrcix0",
        "name": "keypair",
        "public_key": "ssh-rsa ... Generated-by-Nova",
        "user_id": "436f727b7c9142f896ddd56be591dd7f"
    }
}
```

</p>
</details>

---

<a id="delete-key-pair"></a>
### 키페어 삭제하기 { #delete-key-pair }
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="delete-key-pair-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| keypairName | URL | String | O | 키페어 이름 |
| tokenId | Header | String | O | 토큰 ID |

<a id="delete-key-pair-response"></a>
#### 응답
이 API는 응답 본문을 반환하지 않습니다.


<a id="instance"></a>
## 인스턴스 { #instance }

<a id="instance-status"></a>
### 인스턴스 상태 { #instance-status }

인스턴스는 다양한 상태를 가지며 상태에 따라 취할 수 있는 동작이 정해져 있습니다. 인스턴스 상태 목록은 다음과 같습니다.

| 상태명              | 설명                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | 인스턴스가 활성 상태인 경우 |
| `BUILD` | 인스턴스가 생성 중인 경우 |
| `DELETED` | 인스턴스가 삭제된 경우 |
| `ERROR` | 직전 인스턴스에 취한 동작이 실패한 경우 |
| `HARD_REBOOT` | 인스턴스를 강제 재시작한 경우<br> 물리 서버의 전원을 내리고 다시 켜는 것과 동일한 동작 |
| `MIGRATING` | 인스턴스가 마이그레이션 중인 경우<br> 이는 실시간 마이그레이션(활성 인스턴스 이동) 작업으로 인해 발생함 |
| `PASSWORD` | 인스턴스에서 비밀번호를 재설정하는 중인 경우 |
| `PAUSED` | 인스턴스가 일시 정지된 경우<br>일시 정지된 인스턴스는 하이퍼바이저의 메모리에 저장됨 |
| `REBOOT` | 인스턴스가 소프트 재부팅 상태인 경우<br> 재부팅 명령이 가상머신 운영 체제에 전달됨 |
| `REBUILD` | 인스턴스를 생성 당시 이미지로부터 새롭게 만들어 내는 상태 |
| `RESCUE` | 인스턴스를 복구 모드에서 실행 중인 경우 |
| `RESIZE` | 인스턴스 타입을 변경하거나 인스턴스를 다른 호스트로 옮기는 경우<br>인스턴스가 중지되었다가 다시 시작된 상태 |
| `REVERT_RESIZE` | 인스턴스 타입을 변경하거나 인스턴스를 다른 호스트로 옮기는 과정에서 실패했을 때 원상태로 돌아가기 위해 복구하는 경우 |
| `VERIFY_RESIZE` | 인스턴스가 타입 변경 또는 인스턴스를 다른 호스트로 옮기는 과정을 마치고 사용자의 승인을 기다리는 경우<br>NHN Cloud에서는 이 경우 자동으로 `ACTIVE` 상태가 됨 |
| `SHELVED_OFFLOADED` | 인스턴스가 종료된 경우 |
| `SHUTOFF` | 인스턴스가 중지된 경우 |
| `SUSPENDED` | 인스턴스가 관리자에 의해 최대 절전 모드로 진입한 경우 |
| `UNKNOWN` | 인스턴스의 상태를 알 수 없는 경우<br>`인스턴스가 이 상태로 진입한 경우 관리자에게 문의합니다.` | 

<a id="list-instances"></a>
### 인스턴스 목록 보기 { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### 요청

이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| tokenId | Header | String | O | 토큰 ID |
| reservation_id | Query | String | - | 인스턴스 생성 예약 ID. <br>예약 ID를 지정하면 동시에 생성된 인스턴스 목록만 반환함 |
| changes-since | Query | Datetime | - | 지정된 시각 이후로 변경된 인스턴스 목록을 반환. `YYYY-MM-DDThh:mm:ss`의 형태. |
| image | Query | UUID | - | 이미지 ID<br>지정된 이미지를 사용한 인스턴스 목록을 반환 |
| flavor | Query | UUID | - | 인스턴스 타입 ID<br>지정된 타입을 사용한 인스턴스 목록을 반환 |
| name | Query | String | - | 인스턴스 이름<br>지정된 이름을 가진 인스턴스 목록을 반환, 정규 표현식으로 질의 가능 |
| status | Query | Enum | - | 인스턴스 상태<br>지정된 상태를 가진 인스턴스 목록을 반환 |
| limit | Query | Integer | - | 인스턴스 목록 개수<br>지정된 개수 만큼의 인스턴스 목록을 반환 |
| marker | Query | UUID | - | 목록의 첫번째 인스턴스 UUID<br>정렬 기준에 따라 `marker`로 지정된 인스턴스부터 `limit` 개수 만큼의 인스턴스 목록을 반환 |

<a id="list-instances-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| servers | Body | Object | 인스턴스 목록 객체 |
| id | Body | UUID | 인스턴스 UUID |
| links | body | Object | 인스턴스 경로 객체 |
| name | body | String | 인스턴스 이름 |

<details><summary>예시</summary>
<p>

```json
{
  "servers": [
    {
      "id": "aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
          "rel": "bookmark"
        }
      ],
      "name": "Web-Server"
    }
  ]
}
```

</p>
</details>

---

