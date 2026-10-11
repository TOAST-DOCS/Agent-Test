{% set f = (build_flags | select("in", ["public","gov","ncgn","ninc","ngsc","ngovc","ngoic"]) | list | first) %}
{% set ep_domain = {"ninc":"ninc.go.kr","ngsc":"ngsc.go.kr","ngovc":"ngovc.com","ngoic":"ngoic.com"} %}
<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 가이드 { #compute-instance-api-v2-guide }

{% if "public" in build_flags %}
Instance는 API 호출 시 인증/인가를 위해 IaaS 토큰을 사용합니다. IaaS 토큰은 NHN Cloud의 OpenStack 기반 인프라 서비스(IaaS)에서 사용하는 인증 토큰입니다. IaaS 토큰 발급 및 사용에 대한 자세한 내용은 [IaaS 토큰](/nhncloud/ko/public-api/iaas-token) 을 참고하세요.
{% elif "gov" in build_flags %}
Instance는 API 호출 시 인증/인가를 위해 IaaS 토큰을 사용합니다. IaaS 토큰은 NHN Cloud의 OpenStack 기반 인프라 서비스(IaaS)에서 사용하는 인증 토큰입니다. IaaS 토큰 발급 및 사용에 대한 자세한 내용은 [IaaS 토큰](/nhncloud/ko/public-api/iaas-token-gov) 을 참고하세요.
{% else %}
API를 사용하려면 API 엔드포인트와 토큰 등이 필요합니다. [API 사용 준비](/Compute/Compute/ko/identity-api/)를 참고하여 API 사용에 필요한 정보를 준비합니다.
{% endif %}

인스턴스 API는 `compute` 타입 엔드포인트를 이용합니다. 정확한 엔드포인트는 토큰 발급 응답의 `serviceCatalog`를 참조합니다.

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "public" in build_flags %}
| compute | 한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>일본 리전 | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |
{% elif "gov" in build_flags %}
| compute | 한국(판교) 리전<br>한국(평촌) 리전 | https://kr1-api-instance-infrastructure.gov-nhncloudservice.com<br>https://kr2-api-instance-infrastructure.gov-nhncloudservice.com           |
{% else %}
| compute | 한국(대구) 리전 | https://kr4-api-instance-infrastructure.$[ ep_domain[f] ]$ |
{% endif %}

API 응답에 가이드에 명시되지 않은 필드가 나타날 수 있습니다. 이런 필드는 NHN Cloud 내부 용도로 사용되며 사전 공지 없이 변경될 수 있으므로 사용하지 않습니다.

<a id="create-instance"></a>
### 인스턴스 생성하기 { #create-instance }

인스턴스를 생성합니다.

인스턴스 생성 API를 호출한 후에 인스턴스 조회를 통해 인스턴스 상태를 확인합니다.

* 인스턴스의 상태가 **ACTIVE**가 되면 인스턴스가 정상적으로 생성 완료됩니다.
* 인스턴스 상태가 **BUILDING**에서 오래 지속되거나 **ERROR**인 경우, 인스턴스 생성 매개 변수를 확인하고 다시 생성을 시도합니다.

Windows 인스턴스는 안정적인 동작을 위해 다음과 같은 생성 제약 조건이 있습니다.

* RAM이 2GB 이상인 인스턴스 타입을 사용합니다.
* 50GB 이상의 루트 블록 스토리지가 필요합니다.
* U2 타입은 Windows 이미지를 사용할 수 없습니다.

루트 블록 스토리지 크기는 Linux는 10GB, Windows는 50GB부터 지정할 수 있습니다.

인스턴스 생성 요청 시 스케줄러 힌트를 통해 배치 정책을 할당할 수 있습니다.


{% if "public" in build_flags %}

{% else %}
{% endif %}
```
POST /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="create-instance-request"></a>
#### 요청

{% if "public" in build_flags %}
| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| tokenId | Header | String | O | 토큰 ID |
{% else %}
| 이름 | 종류 | 형식 | 필수 | 설명                                                                                                                                                                                        |
|---|---|---|---|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| tenantId | URL | String | O | 테넌트 ID                                                                                                                                                                                    |
| tokenId | Header | String | O | 토큰 ID                                                                                                                                                                                     |
{% endif %}
| server | body | Object | O | 서버 객체 |
{% if "public" in build_flags %}
| server.security_groups | body | Object | - | 보안 그룹 목록 객체<br>생략할 경우 `default` 그룹이 추가됨 |
| server.security_groups.name | body | String | - | **(조건부 필수)** 인스턴스에 추가할 보안 그룹 이름 |
| server.user_data | body | String | - | 인스턴스 부팅 후 실행할 스크립트 및 설정<br>base64 인코딩된 문자열로 65535 바이트까지 허용 |
{% elif "gov" in build_flags %}
| server.security_groups | body | Object | - | 보안 그룹 목록 객체<br>생략할 경우 `default` 그룹이 추가됨                                                                                                                                                   |
| server.security_groups.name | body | String | - | **(조건부 필수)** 인스턴스에 추가할 보안 그룹 이름                                                                                                                                                                        |
| server.user_data | body | String | - | 인스턴스 부팅 후 실행할 스크립트 및 설정<br>base64 인코딩된 문자열로 65535 바이트까지 허용                                                                                                                                |
{% else %}
| server.security_groups | body | Object | - | 보안 그룹 목록 객체<br>생략할 경우 `default` 그룹이 추가됨                                                                                                                                                   |
| server.security_groups.name | body | String | - | 인스턴스에 추가할 보안 그룹 이름                                                                                                                                                                        |
| server.user_data | body | String | - | 인스턴스 부팅 후 실행할 스크립트 및 설정<br>base64 인코딩된 문자열로 65535 바이트까지 허용                                                                                                                                |
{% endif %}
| server.availability_zone | body | String | - | 인스턴스를 생성할 가용성 영역<br>지정하지 않을 경우 임의로 선택됨<br>루트 블록 스토리지의 소스 타입이 `volume`, `snapshot`인 경우 원본 블록 스토리지의 가용성 영역과 동일하게 설정 필요 |
| server.imageRef | Body | String | - | 인스턴스를 생성할 때 사용할 이미지 ID<br>루트 블록 스토리지의 소스 타입이 `volume`, `snapshot`인 경우 설정 불필요 |
{% if "public" in build_flags %}
| server.flavorRef | Body | String | O | 인스턴스를 생성할 때 사용할 인스턴스 타입 ID |
| server.networks | Body | Object | O | 인스턴스를 생성할 때 사용할 네트워크 정보 객체<br>지정한 개수만큼 NIC가 추가되며, 네트워크 ID, 서브넷 ID, 포트 ID, 고정 IP 중 하나로 지정 |
| server.networks.uuid | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 네트워크 ID |
| server.networks.subnet | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 네트워크의 서브넷 ID |
| server.networks.port | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 포트 ID<br>포트 ID 지정 시 요청한 보안 그룹은 지정한 기존 포트에 적용되지 않음 |
| server.networks.fixed_ip | Body | String | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 고정 IP |
| server.name | Body | String | O | 인스턴스의 이름<br>영문자 기준 255자까지 허용되지만, Windows 이미지의 경우 15자 이하여야 함 |
| server.metadata | Body | Object | - | 인스턴스에 추가할 메타데이터 객체<br>최대 길이 255자 이하의 키-값 쌍 |
{% elif "gov" in build_flags %}
| server.flavorRef | Body | String | O | 인스턴스를 생성할 때 사용할 인스턴스 타입 ID                                                                                                                                                                |
| server.networks | Body | Object | O | 인스턴스를 생성할 때 사용할 네트워크 정보 객체<br>지정한 개수만큼 NIC가 추가되며, 네트워크 ID, 서브넷 ID, 포트 ID, 고정 IP 중 하나로 지정                                                                                                  |
| server.networks.uuid | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 네트워크 ID                                                                                                                                                                   |
| server.networks.subnet | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 네트워크의 서브넷 ID                                                                                                                                                              |
| server.networks.port | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 포트 ID<br>포트 ID 지정 시 요청한 보안 그룹은 지정한 기존 포트에 적용되지 않음                                                                                                                                                                     |
| server.networks.fixed_ip | Body | String | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 고정 IP                                                                                                                                                                     |
| server.name | Body | String | O | 인스턴스의 이름<br>영문자 기준 255자까지 허용되지만, Windows 이미지의 경우 15자 이하여야 함                                                                                                                               |
| server.metadata | Body | Object | - | 인스턴스에 추가할 메타데이터 객체<br>최대 길이 255자 이하의 키-값 쌍                                                                                                                                                |
{% else %}
| server.flavorRef | Body | String | O | 인스턴스를 생성할 때 사용할 인스턴스 타입 ID                                                                                                                                                                |
| server.networks | Body | Object | O | 인스턴스를 생성할 때 사용할 네트워크 정보 객체<br>지정한 개수만큼 NIC가 추가되며, 네트워크 ID, 서브넷 ID, 포트 ID, 고정 IP 중 하나로 지정                                                                                                  |
| server.networks.uuid | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 네트워크 ID |
| server.networks.subnet | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 네트워크의 서브넷 ID |
| server.networks.port | Body | UUID | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 포트 ID<br>포트 ID 지정 시 요청한 보안 그룹은 지정한 기존 포트에 적용되지 않음 |
| server.networks.fixed_ip | Body | String | - | **(조건부 필수)** 인스턴스를 생성할 때 사용할 고정 IP |
| server.name | Body | String | O | 인스턴스의 이름<br>영문자 기준 255자까지 허용되지만, Windows 이미지의 경우 15자 이하여야 함                                                                                                                               |
| server.metadata | Body | Object | - | 인스턴스에 추가할 메타데이터 객체<br>최대 길이 255자 이하의 키-값 쌍                                                                                                                                                |
{% endif %}
| server.block_device_mapping_v2 | Body | Object | O | 인스턴스의 블록 스토리지 정보 객체 |
| server.block_device_mapping_v2.source_type | Body | Enum | O | 생성할 블록 스토리지 원본의 타입<br>- `image`: 이미지를 이용해 블록 스토리지 생성<br>- `blank`: 빈 블록 스토리지 생성(루트 블록 스토리지로 사용할 수 없음)<br>- `volume`: 기존에 생성된 블록 스토리지를 사용<br>- `snapshot`: 스냅숏을 이용해 블록 스토리지 생성 |
| server.block_device_mapping_v2.uuid | Body | String | - | **(조건부 필수)** 블록 스토리지의 소스 타입에 따라 다르게 설정 필요<br>- 소스 타입이 `image`인 경우 이미지 ID를 설정<br>- 소스 타입이 `volume`인 경우 기존에 생성된 블록 스토리지 ID를 설정<br>- 소스 타입이 `snapshot`인 경우 스냅숏 ID를 설정<br>- 소스 타입이 `blank`인 경우 설정 불필요<br>루트 블록 스토리지인 경우 반드시 부팅 가능한 원본이어야 함 |
{% if "public" in build_flags %}
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 지정한 블록 스토리지의 부팅 순서<br>-`0`이면 루트 블록 스토리지<br>- 그 외는 추가 블록 스토리지<br>크기가 클수록 부팅 순서는 낮아짐 |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | 인스턴스 블록 스토리지의 위치, 인스턴스 타입에 따라 다르게 설정 필요.<br>- `local`: GPU 인스턴스, U2 인스턴스 타입을 이용하는 경우<br>- `volume`: 그 외의 인스턴스 타입을 이용하는 경우 |
{% elif "gov" in build_flags %}
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 지정한 블록 스토리지의 부팅 순서<br>-`0`이면 루트 블록 스토리지<br>- 그 외는 추가 블록 스토리지<br>크기가 클수록 부팅 순서는 낮아짐                                                                                                                         |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | 인스턴스 블록 스토리지의 위치, 인스턴스 타입에 따라 다르게 설정 필요.<br>- `local`: GPU 인스턴스, U2 인스턴스 타입을 이용하는 경우<br>- `volume`: 그 외의 인스턴스 타입을 이용하는 경우 |
{% else %}
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 지정한 블록 스토리지의 부팅 순서<br>-`0`이면 루트 블록 스토리지<br>- 그 외는 추가 블록 스토리지<br>크기가 클수록 부팅 순서는 낮아짐                                                                                                                         |
{% endif %}
| server.block_device_mapping_v2.volume_type | Body | Enum    | - | **(조건부 필수)** 생성할 블록 스토리지의 타입<br>블록 스토리지의 소스 타입이 `volume`, `snapshot`인 경우 설정 불필요<br>`사용자 가이드 > Storage > Block Storage > API v2 가이드`에서 **블록 스토리지 타입 목록 보기** 응답의 `name` 참고 |
{% if "public" in build_flags %}
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | 인스턴스 삭제 시 블록 스토리지 처리 여부, 기본값은 `false`.<br>`true`면 삭제, `false`면 유지 |
{% elif "gov" in build_flags %}
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | 인스턴스 삭제 시 블록 스토리지 처리 여부, 기본값은 `false`.<br>`true`면 삭제, `false`면 유지                                                                                                                         |
{% else %}
| server.block_device_mapping_v2.destination_type | Body | Enum | O | 인스턴스 블록 스토리지의 위치, 인스턴스 타입에 따라 다르게 설정 필요.<br>- `local`: U2 인스턴스 타입을 이용하는 경우<br>- `volume`: U2 외의 인스턴스 타입을 이용하는 경우                                                                          |
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | 인스턴스 삭제 시 블록 스토리지 처리 여부, 기본값은 `false`.<br>`true`면 삭제, `false`면 유지                                                                                                                         |
{% endif %}
| server.block_device_mapping_v2.volume_size | Body | Integer | - | **(조건부 필수)** 생성할 블록 스토리지 크기<br>블록 스토리지의 소스 타입에 따라 다르게 설정 필요<br>- 소스 타입이 `volume`인 경우 설정 불필요<br>- 소스 타입이 `snapshot`인 경우 원본 블록 스토리지 크기보다 같거나 크게 설정<br>`GB` 단위<br>U2 인스턴스 타입을 사용하고 루트 블록 스토리지를 생성하는 경우에는 U2 인스턴스 타입에 명시된 크기로 생성되며 이 값은 무시됨<br>인스턴스 타입에 따라 생성할 수 있는 루트 블록 스토리지의 크기가 다르므로 자세한 내용은 `사용자 가이드 > Compute > Instance > 콘솔 사용 가이드 > 인스턴스 생성 > 블록 스토리지 크기`를 참고 |
{% if "public" in build_flags %}
| server.block_device_mapping_v2.nhn_encryption                   | Body | Object | - | **(조건부 필수)** 블록 스토리지의 암호화 정보                                                                                                                                                                                        |
| server.block_device_mapping_v2.nhn_encryption.skm_appkey        | Body | String | - | **(조건부 필수)** Secure Key Manager 서비스의 앱키                                                                                                                                                                              |
| server.block_device_mapping_v2.nhn_encryption.skm_key_id        | Body | String | - | **(조건부 필수)** 암호화 블록 스토리지 생성에 사용할 Secure Key Manager의 대칭 키 ID                                                                                                                                  |
| server.key_name | Body | String | O | 인스턴스 접속에 사용할 키페어 |
{% else %}
| server.key_name | Body | String | O | 인스턴스 접속에 사용할 키페어                                                                                                                                                                          |
{% endif %}
| server.min_count | Body | Integer | - | 현재 요청으로 생성할 인스턴스 개수의 최솟값.<br>기본값은 1.<br>블록 스토리지의 소스 타입이 `volume`인 경우 `1`로만 설정 가능 |
| server.max_count | Body | Integer | - | 현재 요청으로 생성할 인스턴스 개수의 최댓값.<br>기본값은 min_count, 최댓값은 10.<br>블록 스토리지의 소스 타입이 `volume`인 경우 `1`로만 설정 가능 |
{% if "public" in build_flags %}
| server.return_reservation_id | Body | Boolean | - | 인스턴스 생성 요청 예약 ID.<br>True로 지정하면 인스턴스 생성 정보 대신 예약 ID를 반환.<br>기본값은 False |
{% else %}
| server.return_reservation_id | Body | Boolean | - | 인스턴스 생성 요청 예약 ID.<br>True로 지정하면 인스턴스 생성 정보 대신 예약 ID를 반환.<br>기본값은 False                                                                                                                    |
{% endif %}
| os:scheduler_hints | Body | Object | - | 스케줄러 힌트 객체 |
| os:scheduler_hints.group | Body | String | - | 배치 정책 ID |

<details><summary>예시</summary>
<p>

```json
{
  "server": {
    "name": "DB-Master",
    "imageRef": "9956f822-29c9-4f81-9410-0c392d9c8c24",
    "flavorRef": "a4b6a0f7-aeff-4d78-a8d5-7de9f007012d",
    "networks": [{
      "subnet": "b83863ff-0355-4c73-8c10-0bdf66a69aab"
    }],
    "availability_zone": "kr-pub-a",
    "key_name": "access-key",
    "max_count": 1,
    "min_count": 1,
    "block_device_mapping_v2": [{
      "source_type": "image",
      "uuid": "9956f822-29c9-4f81-9410-0c392d9c8c24",
      "boot_index": 0,
      "volume_size": 1000,
      "destination_type": "volume",
      "delete_on_termination": 1
    }],
    "security_groups": [{
      "name": "default"
    }]
  },
  "os:scheduler_hints": {
    "group": "f878bd5b-49a7-499f-966e-1eceb21cb06b"
  }
}
```

</p>
</details>

<a id="create-instance-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명                                                                                                                                                                                                           |
|---|---|---|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server.security_groups.name | Body | String | 생성한 인스턴스의 보안 그룹 이름                                                                                                                                                                                           |
| server.id | Body | UUID | 생성한 인스턴스의 ID                                                                                                                                                                                                 |

<details><summary>예시</summary>
<p>

```json
{
  "server": {
    "security_groups": [
      {
        "name": "default"
      }
    ],
    "id": "3a005d5b-63cf-4493-bfc6-49db990b5b50",
    "links": [
      {
{% if "public" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% elif "gov" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.gov-nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% else %}
        "href": "https://kr4-api-instance-infrastructure.$[ ep_domain[f] ]$/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% endif %}
        "rel": "self"
      },
      {
{% if "public" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% elif "gov" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.gov-nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% else %}
        "href": "https://kr4-api-instance-infrastructure.$[ ep_domain[f] ]$/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% endif %}
        "rel": "bookmark"
      }
    ]
  }
}
```

</p>
</details>

---

<a id="modify-instance"></a>
### 인스턴스 수정하기 { #modify-instance }
생성된 인스턴스를 수정합니다. 변경할 수 있는 속성은 일부 항목으로 제한됩니다.

```
PUT /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="modify-instance-request"></a>
#### 요청

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|---|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 변경할 인스턴스 ID |
| tokenId | Header | String | O | 토큰 ID |
| server | Body | Object | O | 인스턴스 변경 요청 객체 |
| server.name | Body | String | - | 인스턴스의 새로운 이름 |

<details><summary>예시</summary>
<p>

```json
{
    "server": {
        "name": "new-server-test"
    }
}
```

</p>
</details>

<a id="modify-instance-response"></a>
#### 응답
인스턴스 보기와 동일합니다.

---

<a id="delete-instance"></a>
### 인스턴스 삭제하기 { #delete-instance }
생성된 인스턴스를 삭제합니다.

```
DELETE /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="delete-instance-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|--|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 삭제할 인스턴스 ID |
| tokenId | Header | String | O | 토큰 ID |

<a id="delete-instance-response"></a>
#### 응답
이 API는 응답 본문을 반환하지 않습니다.

---

<a id="manage-block-storage-attachment"></a>
## 블록 스토리지 연결 관리 { #manage-block-storage-attachment }

<a id="list-additional-block-storage-attached-to-the-instance"></a>
### 인스턴스에 연결된 블록 스토리지 목록 보기 { #list-additional-block-storage-attached-to-the-instance }
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

<a id="list-additional-block-storage-attached-to-the-instance-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|--|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 변경할 인스턴스 ID |
| tokenId | Header | String | O | 토큰 ID |
| limit | Query | Integer | - | 조회할 목록 개수 |
| offset | Query | Integer | - | 반환할 목록의 시작점<br>전체 목록 중 offset번째 블록 스토리지부터 반환 |

<a id="list-additional-block-storage-attached-to-the-instance-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| volumeAttachments | Body | Array | 연결 정보 객체 목록 |
| volumeAttachments.device | Body | String | 인스턴스의 블록 스토리지 이름<br>예) `/dev/vdb` |
| volumeAttachments.id | Body | UUID | 연결 정보 ID |
| volumeAttachments.serverId | Body | UUID | 인스턴스 ID |
| volumeAttachments.volumeId | Body | UUID | 블록 스토리지 ID |

<details><summary>예시</summary>
<p>

```json
{
    "volumeAttachments": [
        {
            "device": "/dev/vda",
            "id": "227cc671-f30b-4488-96fd-7d0bf13648d8",
            "serverId": "4b293d31-ebd5-4a7f-be03-874b90021e54",
            "volumeId": "227cc671-f30b-4488-96fd-7d0bf13648d8"
        },
        {
            "device": "/dev/vdb",
            "id": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113",
            "serverId": "4b293d31-ebd5-4a7f-be03-874b90021e54",
            "volumeId": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113"
        }
    ]
}
```

</p>
</details>

---

<a id="show-additional-block-storage-attached-to-the-instance"></a>
### 인스턴스에 연결된 블록 스토리지 보기 { #show-additional-block-storage-attached-to-the-instance }
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

<a id="show-additional-block-storage-attached-to-the-instance-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|--|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 인스턴스 ID |
| volumeId | URL | UUID | O | 조회할 블록 스토리지 ID |
| tokenId | Header | String | O | 토큰 ID |

<a id="show-additional-block-storage-attached-to-the-instance-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| volumeAttachment | Body | Object | 연결 정보 객체 |
| volumeAttachment.device | Body | String | 인스턴스의 블록 스토리지 이름<br>예) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | 연결 정보 ID |
| volumeAttachment.serverId | Body | UUID | 인스턴스 ID |
| volumeAttachment.volumeId | Body | UUID | 블록 스토리지 ID |

<details><summary>예시</summary>
<p>

```json
{
    "volumeAttachment": {
        "device": "/dev/sdb",
        "id": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113",
        "serverId": "1ad6852e-6605-4510-b639-d0bff864b49a",
        "volumeId": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113"
    }
}
```

</p>
</details>

---

<a id="attach-additional-block-storage-to-the-instance"></a>
### 인스턴스에 추가 블록 스토리지 연결하기 { #attach-additional-block-storage-to-the-instance }
```
POST /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

<a id="attach-additional-block-storage-to-the-instance-request"></a>
#### 요청

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|--|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 변경할 인스턴스 ID |
| tokenId | Header | String | O | 토큰 ID |
| volumeAttachment | Body | Object | O | 블록 스토리지 연결 요청 객체 |
| volumeAttachment.volumeId | Body | UUID | O | 연결할 블록 스토리지 ID |

<details><summary>예시</summary>
<p>

```json
{
  "volumeAttachment": {
      "volumeId": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113"
  }
}
```

</p>
</details>

<a id="attach-additional-block-storage-to-the-instance-response"></a>
#### 응답

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
| volumeAttachment | Body | Object | 연결 정보 객체 |
| volumeAttachment.device | Body | String | 인스턴스의 블록 스토리지 이름<br>예) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | 연결 정보 ID |
| volumeAttachment.serverId | Body | UUID | 인스턴스 ID |
| volumeAttachment.volumeId | Body | UUID | 블록 스토리지 ID |

<details><summary>예시</summary>
<p>

```json
{
    "volumeAttachment": {
        "device": "/dev/vdc",
        "id": "227cc671-f30b-4488-96fd-7d0bf13648d8",
        "serverId": "4b293d31-ebd5-4a7f-be03-874b90021e54",
        "volumeId": "227cc671-f30b-4488-96fd-7d0bf13648d8"
    }
}
```

</p>
</details>

---

<a id="detach-block-storage-from-the-instance"></a>
### 인스턴스 블록 스토리지 연결 끊기 { #detach-block-storage-from-the-instance }
```
DELETE /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

<a id="detach-block-storage-from-the-instance-request"></a>
#### 요청
이 API는 요청 본문을 요구하지 않습니다.

| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|--|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 인스턴스 ID |
| volumeId | URL | UUID | O | 연결을 끊을 블록 스토리지 ID |
| tokenId | Header | String | O | 토큰 ID |

<a id="detach-block-storage-from-the-instance-response"></a>
#### 응답
이 API는 응답 본문을 반환하지 않습니다.

---

<a id="additional-instance-features"></a>
## 인스턴스 추가 기능 { #additional-instance-features }
NHN Cloud는 다음과 같은 인스턴스 제어 및 부가 기능을 제공합니다.

* 인스턴스 시작, 중지, 종료, 재시작
* 인스턴스 타입 변경
* 인스턴스 이미지 생성
* 보안 그룹 추가 및 삭제

<a id="start-stopped-instance"></a>
### 중지된 인스턴스 시작 { #start-stopped-instance }

중지된 인스턴스를 다시 시작하고 상태를 **ACTIVE**로 변경합니다. 이 API를 호출하려면 인스턴스의 상태가 **SHUTOFF**여야 합니다.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

<a id="start-stopped-instance-request"></a>
#### 요청
| 이름 | 종류 | 형식 | 필수 | 설명 |
|---|---|---|---|--|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 변경할 인스턴스 ID |
| tokenId | Header | String | O | 토큰 ID |
| os-start | Body | none | O | 인스턴스 시작 요청 |

<details><summary>예시</summary>
<p>

```json
{
  "os-start" : null
}
```

</p>
</details>

<a id="start-stopped-instance-response"></a>
#### 응답
이 API는 응답 본문을 반환하지 않습니다.

---

<a id="start-terminated-instance"></a>
### 종료된 인스턴스 시작 { #start-terminated-instance }

종료된 인스턴스를 다시 시작하고 상태를 **ACTIVE**로 변경합니다. 이 API를 호출하려면 인스턴스의 상태가 **SHELVED_OFFLOADED**여야 합니다.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

<a id="start-terminated-instance-request"></a>
#### 요청
| 이름 | 종류 | 형식 | 필수 | 설명 |
|--|---|---|---|--|
| tenantId | URL | String | O | 테넌트 ID |
| serverId | URL | UUID | O | 변경할 인스턴스 ID |
| tokenId | Header | String | O | 토큰 ID |
| unshelve | Body | none | O | 인스턴스 시작 요청 |

<details><summary>예시</summary>
<p>

```json
{
  "unshelve" : null
}
```

</p>
</details>

<a id="start-terminated-instance-response"></a>
#### 응답
이 API는 응답 본문을 반환하지 않습니다.

---
