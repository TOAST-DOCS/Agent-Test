## Security > Network Firewall > 콘솔 사용 가이드

Network Firewall을 생성하기 위한 절차와 생성 이후 콘솔을 사용하는 방법을 설명합니다.
테스트

{% if build_flags == "gov" -%}
<br>

{% endif -%}
## 시작하기

Network Firewall을 사용하기 위해서는 가장 먼저 Network Firewall 서비스를 활성화합니다.

{% if build_flags == "gov" -%}
<br>

{% endif -%}
## Network Firewall 생성

### 사전 준비

Network Firewall 생성에 필요한 최소 네트워크 서비스 자원은 아래와 같습니다.

> [참고]
> **Network Firewall > 개요**에서 Network Firewall 서비스 구성도를 참조하세요.


[1개의 프로젝트 구성 시 준비 사항]

* 1개의 프로젝트
* 2개의 VPC(Hub VPC, Spoke VPC)
* Hub VPC 내 3개의 서브넷
    * 트래픽(내부) 서브넷, NAT(외부) 서브넷, 외부 전송 서브넷
* Spoke VPC 내 최소 1개의 서브넷
* Hub VPC의 Routing에 연결된 인터넷 게이트웨이

[1개의 프로젝트 내 2개의 Spoke VPC 구성 시 준비 사항]

* 1개의 프로젝트
* 3개의 VPC(Hub VPC, Spoke1 VPC, Spoke2 VPC)
* Hub VPC 내 3개의 서브넷
    * 트래픽(내부) 서브넷, NAT(외부) 서브넷, 외부 전송 서브넷
* Spoke1 VPC, Spoke2 VPC 내 각각 최소 1개의 서브넷
* Hub VPC의 Routing에 연결된 인터넷 게이트웨이

[1개 이상의 프로젝트 구성 시 준비 사항]

* 2개의 프로젝트
{%- if build_flags == "gov" %}
* 2개의 VPC(각 프로젝트에 Hub VPC, Spoke VPC)
{%- else %}
* 2개의 VPC(각각 프로젝트에 Hub VPC, Spoke VPC)
{%- endif %}
* Hub VPC 내 3개의 서브넷
    * 트래픽(내부) 서브넷, NAT(외부) 서브넷, 외부 전송 서브넷
* Spoke VPC 내 최소 1개의 서브넷
* Hub VPC의 Routing에 연결된 인터넷 게이트웨이

{% if build_flags != "gov" %}
[다른 리전 간 프로젝트 구성 시 준비 사항]

* 1개의 프로젝트
* 2개의 VPC(KR1 리전에 Hub VPC, KR2 리전에 Spoke VPC)
* Hub VPC 내 3개의 서브넷
    * 트래픽(내부) 서브넷, NAT(외부) 서브넷, 외부 전송 서브넷
* Spoke VPC 내 최소 1개의 서브넷
* Hub VPC의 Routing에 연결된 인터넷 게이트웨이

{% endif %}
[단일 VPC 내 여러 개의 서브넷 구성 시 준비 사항]

* 1개의 프로젝트
* 1개의 VPC
* 3개의 Hub 서브넷
    * 트래픽(내부) 서브넷, NAT(외부) 서브넷, 외부 전송 서브넷
* Hub 서브넷과 겹치지 않는 최소 1개의 Spoke 서브넷
* Spoke 서브넷에 연결할 라우팅 테이블
* VPC의 Routing에 연결된 인터넷 게이트웨이


> [참고]
>
>* 위의 서비스 자원은 [Network] 카테고리에서 생성 가능합니다.
>* Network Firewall 생성은 프로젝트당 1개씩만 생성 가능합니다.

### Network Firewall 생성

1. **Security > Network Firewall**로 이동합니다.
2. 각 필수 항목을 모두 선택하고 하단의 **Network Firewall 생성**을 클릭합니다.
    * RBAC: 인스턴스 객체 조회, Network Firewall 서비스 제공에 필요한 API 권한을 부여
    * 구성 방식: 단일 구성과 이중화 구성을 선택합니다.
    * VPC: Network Firewall에서 사용할 VPC
    * 서브넷: Network Firewall에서 내부 트래픽 제어를 위해 사용할 서브넷
    * NAT: Network Firewall에서 외부 트래픽 제어를 위해 사용할 서브넷
    * 외부 전송: Network Firewall에서 생성된 트래픽과 로그를 전송할 서브넷
    <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.09.12/create.png" height="60%" />


> [생성 전 참고 사항]
>
> * 생성된 Network Firewall은 사용자의 프로젝트에 노출되지 않습니다.
> * 서브넷, NAT, 외부 전송에 사용하는 서브넷은 모두 다른 서브넷으로 선택해야 합니다.
>    * 가급적 NHN Cloud 콘솔에서 생성할 수 있는 최소 단위(28비트)로 생성할 것을 권장합니다.
> * Network Firewall이 속할 VPC의 라우팅 테이블에 인터넷 게이트웨이가 연결되어 있어야 생성 가능합니다.
{%- if build_flags == "gov" %}
> * Network Firewall 서비스는 가용 영역을 분리하여 이중화를 기본으로 제공합니다.
{%- endif %}
> * Security Groups와는 별개의 서비스이므로 Network Firewall을 사용하면 두 서비스를 모두 허용해야 인스턴스에 접근할 수 있습니다.
> * Network Firewall이 소유하고 있는 CIDR 대역과 연결이 필요한 CIDR 대역은 중복되지 않아야 합니다.
> * **Network > Network Interface**에서 Virtual_IP 타입으로 생성되어 있는 IP는 Network Firewall에서 이중화 용도로 사용 중이므로 삭제할 경우 통신이 차단될 수 있습니다.
> * 단일 또는 이중화 구성을 선택하여 Network Firewall을 생성한 뒤 변경이 필요할 경우 **옵션** 탭에서 구성을 변경할 수 있습니다. 하지만 가용성 영역은 변경이 불가능하므로 이중화 구성의 경우 가급적 가용성 영역을 분리하여 구성하세요.

### 연결 설정

> [예시]
> Network Firewall이 사용하는 VPC(Hub)는 10.0.0.0/24이고, Network Firewall과 연결이 필요한 VPC(Spoke)는 172.16.0.0/24일 때

1. <strong>Network > Peering Gateway</strong>로 이동하여 피어링을 생성합니다.
    * 피어링 게이트웨이 연결에 대한 자세한 사항은 [사용자 가이드](https://docs.nhncloud.com/ko/Network/Peering%20Gateway/ko/console-guide/)를 참조하세요.
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings3.png" height="65%" />
<br>
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings4.png" height="65%" />

> [참고]
>
> Spoke VPC의 위치에 따라 알맞은 피어링을 생성합니다.
> * Spoke VPC가 같은 프로젝트라면 피어링을 생성합니다.
> * Spoke VPC가 다른 프로젝트라면 프로젝트 피어링을 생성합니다.
> * Spoke VPC가 다른 리전이라면 리전 피어링을 생성합니다.

<br>

2. <strong>Network > Routing</strong>으로 이동하여 Hub VPC를 선택한 후 아래의 라우팅을 설정합니다.
    * 대상 CIDR: 172.16.0.0/24
    * 게이트웨이: 피어링 연결 후 추가된 피어링 타입의 게이트웨이
    <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings5.png" height="65%" />
<br>

3. <strong>Network > Routing</strong>으로 이동하여 Spoke VPC를 선택한 후 아래의 라우팅을 설정합니다.
    * 대상 CIDR: 0.0.0.0/0
    * 게이트웨이: 피어링 연결 후 추가된 피어링 타입의 게이트웨이
    <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings6.png" height="65%" />

> [참고]
>
> * 위와 같이 라우팅을 설정하면 Spoke VPC의 모든 통신이 Network Firewall을 통과하게 됩니다.
>   * 통신을 분기 처리해야 할 경우 0.0.0.0/0이 아닌 대상을 명확하게 설정하세요.

<br>

4. <strong>Network > Peering Gateway</strong>로 이동하여 라우팅을 설정합니다.
    * 생성된 피어링을 선택하여 **라우트** 탭으로 이동합니다.
    * **피어** 또는 **로컬 라우트 변경** 버튼을 눌러 아래와 같이 라우팅을 설정합니다.
        * 대상 CIDR: 0.0.0.0/0
        * 게이트웨이: NetworkFirewall\_INF\_TRAFFIC\_VIP
        <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings7.png" height="65%" />
<br>
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings8.png" height="50%" />

위의 라우팅 설정이 완료되면 Spoke VPC에 있는 인스턴스가 Network Firewall을 경유하여 공인 통신을 할 수 있습니다. (<strong>Network Firewall > NAT</strong> 탭에서 NAT 추가 필요)

<br>

**만약 Spoke VPC의 서브넷이 2개 이상이고, Network Firewall을 통해 서브넷 간 트래픽 제어가 필요한 경우** 아래의 라우팅을 추가합니다.

> [예시]
> Spoke VPC(172.16.0.0/24)의 서브넷이 172.16.0.0/25와 172.16.0.128/25일 때

* <strong>Network > Routing</strong>으로 이동하여 Spoke VPC를 선택한 후 아래의 라우팅 2개를 추가합니다.
    * 대상 CIDR: 172.16.0.0/25과 172.16.0.128/25
    * 게이트웨이: 피어링 연결 후 추가된 피어링 타입의 게이트웨이
    <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings9.png" height="65%" />
<br>
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings10.png" height="65%" />
위의 라우팅 설정이 완료되면 Spoke VPC 안에 있는 서브넷 간 Network Firewall을 경유하여 사설 통신을 할 수 있습니다. (<strong>Network Firewall > 정책</strong> 탭에서 정책 추가 필요)

<br>

**만약 Spoke VPC가 2개 이상**이라면 아래의 라우팅을 추가합니다.

> [예시]
> Spoke VPC1(172.16.0.0/24)과 Spoke VPC2(192.168.0.0/24)일 때

* <strong>Network > Routing</strong>으로 이동하여 Hub VPC를 선택한 후 아래의 라우팅 2개를 추가합니다.
    * Spoke VPC 1
        * 대상 CIDR: 172.16.0.0/24
        * 게이트웨이: Hub VPC와 Spoke VPC1 사이에 추가된 피어링 타입의 게이트웨이
    * Spoke VPC 2
        * 대상 CIDR: 192.168.0.0/24
        * 게이트웨이: Hub VPC와 Spoke VPC2 사이에 추가된 피어링 타입의 게이트웨이
        <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.12.19/ConnectionSettings11.png" height="65%" />


> [참고]
> **연결 설정**의 **4**와 같이 Spoke VPC2-Hub 간 VPC 피어링에도 라우트 추가 설정이 필요합니다.

<br>

**만약 같은 VPC에서 Spoke 서브넷을 구성할 경우** 새로운 라우팅 테이블을 생성하여 서브넷을 연결하고 라우트를 추가합니다.
* **Network > Routing**에서 라우팅 테이블을 생성하고 라우트를 추가합니다.
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.11.07/routetable_create.png" height="65%" />
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.11.07/route_create.png" height="65%" />

<br>

{% if build_flags == "gov" -%}
* **Network > Subnet**에서 Network Firewall과 겹치지 않는 서브넷을 새로 생성하고 라우팅 테이블을 연결합니다.
{%- else -%}
* **Network > Subnet**에서 Network Firewall과 겹치지 않는 Spoke 서브넷을 새로 생성하고 라우팅 테이블을 연결합니다.
{%- endif %}
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.11.07/subnet_create.png" height="65%" />
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.11.07/routetable_connect.png" height="65%" />

<br>

{% if build_flags == "gov" -%}
위의 라우팅 설정이 완료되면 서로 다른 Spoke VPC 간 통신과 같은 VPC 내 서브넷 간 통신을 Network Firewall을 경유하여 사설 통신을 할 수 있습니다. (<strong>Network Firewall > 정책</strong> 탭에서 ACL 추가 필요)
{%- else -%}
위의 라우팅 설정이 완료되면 서로 다른 Spoke VPC 간 Network Firewall을 경유하여 사설 통신을 할 수 있습니다. (<strong>Network Firewall > 정책</strong> 탭에서 정책 추가 필요)
{%- endif %}
Network Firewall 서비스 구성도를 참고하여 고객의 환경에 맞게 연결을 설정하세요.

***

## 인스턴스 접속
Network Firewall을 생성하고 연결 설정을 모두 완료한 후 Network Firewall을 경유하여 인스턴스에 접속할 수 있습니다.

예를 들어, 1개의 프로젝트 내 2개의 Spoke VPC로 3개의 서브넷을 구성하고, 외부에서 웹방화벽 접속이 필요할 경우 아래와 같이 NAT, ACL을 설정합니다.

<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.09.12/instance-access
.png" height="65%" />

> [설정 방법]
>
> * **Network Firewall > NAT** 탭으로 이동
> * **추가** 버튼 클릭 후 NAT 설정
>   * 설정 전 **객체** 탭에서 목적지 IP 객체 생성과 여분의 플로팅 IP 필요
> <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.09.12/nat-add.png" height="65%" />
> * **Network Firewall > 정책 > ACL** 탭에서 필요한 ACL을 허용
> <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.09.12/access_acl.png" height="65%" />

위와 같이 설정 후 출발지 IP를 보안 그룹에서 허용하면 인스턴스에 접속 가능합니다.

<br>>

## 정책
Network Firewall을 생성하면 **정책** 탭으로 이동합니다.

![policy-default.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.09.12/policy-default.png)

> [참고]
>
> * default-deny는 필수 정책이며, 수정하거나 삭제할 수 없습니다.
> * default-deny 정책을 통해 차단된 로그는 **옵션** 탭의 **기본 차단 정책 로그 설정**을 **사용**으로 변경한 후 **로그** 탭에서 확인 가능합니다.

<br>

## ACL
**ACL** 탭에서는 Network Firewall과 연결된 VPC 간 트래픽과 인바운드/아웃바운드 트래픽을 제어할 수 있습니다.
<br/>

### 추가

* 출발지, 목적지, 목적지 포트를 기반으로 정책을 추가할 수 있습니다.
    * 이미 만들어진 객체를 통해 출발지, 목적지, 목적지 포트를 선택합니다.
* 정책의 상태(활성화/비활성화)와 동작(허용/차단), 스케줄을 설정 및 정책별 로깅 여부 등의 옵션을 설정하여 정책을 추가할 수 있습니다.
* 스케줄 기능은 정책의 상태를 활성화 한 이후에 동작합니다(정책이 비활성화되어 있을 경우 스케줄 기능이 적용되지 않습니다.).

![acl_add.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.05.27/acl_add.png)

### 복사

* **복사**를 클릭해 정책을 복사할 수 있습니다.
    * 복사: 복사하고자 하는 정책과 동일한 정책을 복사
    * 역방향 복사: 복사하고자 하는 정책의 출발지와 목적지를 변경하여 복사

![acl_copy.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.09.07/acl_copy_1.png)

> [참고]
>
> 복사된 정책은 비활성화됩니다. 사용이 필요할 경우 **수정**을 클릭해 정책을 활성화한 뒤 사용하세요.


### 수정

* **수정**을 클릭해 정책을 수정할 수 있습니다.


### 이동

* **이동**을 클릭해 정책을 이동할 수 있습니다.
    * default-deny 정책 아래로는 이동이 불가능합니다.

![acl_move.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.09.07/acl_move_1.png)

### 삭제

* **삭제**를 클릭해 정책을 삭제할 수 있습니다.

>[주의]
>한번 삭제한 정책은 복구할 수 없으며, default-deny 정책은 삭제할 수 없습니다.

### 정책 일괄 다운로드

* 정책 탭에 생성되어 있는 정책 전체를 한번에 다운로드할 수 있습니다.

### 정책 일괄 등록

* 내려받은 템플릿을 사용하여 정책을 한 번에 등록할 수 있습니다.

![acl_batch.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/23.09.07/acl_batch_1.png)

<br>

## 라우트

**라우트** 탭에서는 Network Firewall을 경유하는 통신의 경로를 지정할 수 있습니다.

![policy-route.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.09.12/policy-route.png)

> [참고]
>
> * Network Firewall의 기본 게이트웨이는 NAT 이더넷이며, 수정하거나 삭제할 수 없습니다.
> * 라우트 설정이 변경될 경우 통신에 문제가 있을 수 있으므로 유의하여 설정하세요.

### 추가

* **추가**를 클릭해 이더넷을 선택하고, 목적지와 게이트웨이를 입력합니다.
    * 목적지: 서브넷 형식으로 입력
    * 이더넷: NAT, TRAFFIC, VPN(IPSec VPN 기능 사용 시) 중 선택
    * 게이트웨이: 호스트 형식으로 입력

> [참고]
>
> * 이더넷을 VPN으로 선택할 경우 게이트웨이는 지정하지 않아도 됩니다.
> * IPSec VPN과 연동된 사설 IP 대역에 대한 라우트 설정은 반드시 이더넷을 VPN으로 설정하세요.
> * 목적지 서브넷 입력 시 아래와 같은 유효성 메시지가 노출될 경우 서브넷 범위를 사전에 확인하여 서브넷의 시작 IP로 입력하세요.
>   * [예시]
>       * 192.168.199.0/21 (X) → 192.168.192.0/21 (O)
>       * 172.16.100.0/20 (X) → 172.16.96.0/20 (O)
>       * 10.10.10.130/25 (X) → 10.10.10.128/25 (O)
>
> ![route_add.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.09.12/route_add.png)

### 수정

* **수정**을 클릭해 라우트를 수정할 수 있습니다.

### 삭제

* **삭제**를 클릭해 라우트를 삭제할 수 있습니다.

<br>

## 객체

**객체** 탭에서는 정책을 생성할 때 사용할 IP, 포트를 생성하고 관리합니다.

### 추가

* 필수 항목을 입력하여 객체를 생성합니다.
    * 객체는 IP, 포트의 2가지 형태로 추가할 수 있습니다.

> [참고]
> 그룹 객체 생성 시 그룹 객체는 추가할 수 없습니다(단일이나 범위 객체만 선택하여 추가 가능).

### 수정

* **수정**을 클릭해 객체를 수정할 수 있습니다.
    * 타입은 수정이 불가능합니다.

### 삭제

* **삭제**를 클릭해 객체를 삭제할 수 있습니다.
    * 자동으로 Network Firewall에서 생성한 객체는 수정이나 삭제할 수 없습니다.

>[주의]
> 정책에서 사용 중인 객체는 삭제 후 ALL 객체로 변경됩니다.

### 인스턴스 객체 추가
* Network Firewall이 생성된 프로젝트 내에 있는 인스턴스를 활용하여 객체를 추가할 수 있습니다.

> [참고]
> 인스턴스와 관계없이 단순히 인스턴스의 이름과 사설 IP 주소만 참고하여 객체를 생성합니다. 생성한 객체는 **객체** 탭에서 관리합니다.


### 객체 일괄 다운로드

* **객체** 탭에 생성되어 있는 IP와 포트 객체 전체를 각각 한 번에 다운로드할 수 있습니다.

<br>

## NAT

**NAT**(네트워크 주소 변환) 탭에서는 외부에서 접속할 인스턴스와 전용으로 사용할 공인 IP를 선택하여 연결합니다.

>[참고]
>
> * NAT는 목적지 기반 및 1:1 방식만 제공합니다.
> * 포트 기반의 NAT는 제공하지 않습니다.
> * NAT를 생성한 뒤 **정책** 탭에 허용 정책을 추가해야만 공인 통신이 가능합니다.
{%- if build_flags == "gov" %}
> * NHN Cloud(공공기관용)에서 제공하는 SSL VPN 서비스와 Network Firewall을 연동하여 사용할 수 있습니다. (**옵션 > SSL VPN 설정**에서 **사용**으로 설정 시)
{%- endif %}
> * NAT에 설정된 NAT 후 사설 IP를 소유한 인스턴스에 직접 Floating IP를 할당할 경우 통신에 문제가 있을 수 있습니다.
> * NAT 삭제 후 사용하지 않는 NAT 전 공인 IP는 **Network > Floating**에서 직접 삭제하세요.

### 추가

* **추가**를 클릭해 NAT를 생성합니다.
{%- if build_flags == "gov" %}
    * 타입을 선택합니다.
{%- endif %}
    * NAT 전 공인 IP는 **Network > Floating IP**에서 미리 생성한 IP 중 하나를 선택합니다.
    * NAT 후 사설 IP에서 선택할 객체는 **객체** 탭에서 미리 생성해야만 **추가**를 클릭해 추가할 수 있습니다.

{% if build_flags == "gov" -%}
![nat_add.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.05.27/nat_add.png)
{%- else -%}
![nat_add.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.04.05/nat_add_2.png)
{%- endif %}

>[참고]
{%- if build_flags == "gov" %}
>
> * 옵션 - SSL VPN 설정에서 사용으로 설정했을 경우에만 타입이 노출됩니다.
> * 타입의 선택에 따라 아래의 NAT 전 공인 IP가 노출됩니다.
>   * Network Firewall: **Network > Floating IP**에서 Public Network로 생성된 Floating IP
>   * SSL VPN: **Network > Floating IP**에서 VPN Network로 생성된 Floating IP
> * 인스턴스 접속은 NAT를 추가하면서 설정한 NAT 전 공인 IP로 접속 가능합니다. (인스턴스에 직접 Floating IP 연결 불필요)
{%- else %}
> 인스턴스 접속은 NAT를 추가하면서 설정한 NAT 전 공인 IP로 접속 가능합니다. (인스턴스에 직접 Floating IP 연결 불필요)
{%- endif %}

### 수정

* **수정**을 클릭해 생성된 NAT를 수정합니다.
    * 수정은 공인 IP와 사설 IP 모두 수정할 수 있습니다.

### 삭제

* **삭제**를 클릭해 생성된 NAT를 삭제합니다.

<br>

{% if build_flags in ["public", "gov"] -%}
## 미러링

**미러링** 탭에서는 Network Firewall을 통과하는 네트워크 패킷을 IDS/IPS, SIEM, NDR 등의 위협 탐지 및 분석 솔루션으로 복사하여, 네트워크 위협을 실시간으로 탐지하고 대응할 수 있도록 합니다.

> [참고]
> **옵션 - 미러링 설정**에서 **사용**으로 설정하여 활성화 후 사용할 수 있습니다. (활성화까지 약 30초 소요)
<br>
>     ![Mirorring_Config_Activation_800.png](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/Mirroring/25.03.06/Mirorring_Config_Activation_800.png)

<br>

### 미러링 룰

* 미러링 룰을 추가하여 복사한 패킷을 원하는 대상 단말로 전송합니다.
![Mirroring_Rule_Contents_Explain_1_900.png](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/Mirroring/25.03.06/Mirroring_Rule_Contents_Explain_1_900.png)
    * 이름: 설정한 이름을 표시합니다.
    * 방향: 설정한 방향을 표시합니다.
    * 미러 지정 인터페이스: 선택한 Network Firewall의 인터페이스를 표시합니다.
    * 미러링 송신 IP: 미러링 인터페이스의 IP를 표시합니다.
    * 미러링 대상 IP: 미러링 패킷을 보낼 목적지 IP를 표시합니다.
    * 필터 그룹: 선택한 필터 그룹을 표시합니다.
    * 상태: 해당 미러링 룰의 상태를 배지를 통해 표시합니다.
        * Active: 활성화
        * Inactive: 비활성화
    * 자세히 보기: 설정한 미러링 룰의 상세 정보를 확인합니다.

<br>

### 추가

* **추가**를 클릭해 미러링 룰을 추가할 수 있습니다.
    ![Mirroring_Rule_Add_900.png](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/Mirroring/25.03.06/Mirroring_Rule_Add_900.png)
    * 상태: 미러링 룰의 활성화 여부를 설정합니다.
    * 방향: 미러 지정 인터페이스에서 미러링할 수신/송신 패킷을 설정합니다. 해당 설정을 통해 특정 방향의 패킷만 미러링할 수 있습니다.
        * 수신(Rx): 미러 지정 인터페이스에서 수신하는 패킷
        * 송신(Tx): 미러 지정 인터페이스에서 송신하는 패킷
    * 미러 지정 인터페이스: Network Firewall의 아래 인터페이스 중에서 선택합니다.
        * NetworkFirewall\_INF\_NAT: Network Firewall의 외부 제어용 상단 인터페이스
        * NetworkFirewall\_INF\_TRAFFIC: Network Firewall의 내부 제어용 하단 인터페이스
    * 미러링 송신 IP: 외부 전송 서브넷의 미러링 인터페이스가 기본으로 설정됩니다.
    * 미러링 대상 IP: 미러링 패킷을 수신할 대상의 사설 IP를 입력합니다.
    * VNI(virtual network identifier): VNI를 입력합니다.

> [참고]
>
> * 미러링 대상 단말이 VXLAN 패킷을 수신할 수 있도록 정책(보안 그룹 및 방화벽 등)에서 미러링 송신 IP와 UDP 포트 4789번에 대한 접속 허용 설정이 필요합니다.
> * 미러링 룰은 최대 3개까지 생성할 수 있습니다.
> * 미러링 룰을 적용할 때 고객의 환경에 따라 많은 통신 데이터를 발생시킬 수 있으므로, 미러링 대상 IP 정보를 정확하게 입력해야 합니다.
> * Network Firewall은 VXLAN 터널을 통해 미러링 패킷을 송신하므로 VNI 설정이 필요합니다. VNI 값은 1\~16,777,215 사이의 숫자로 입력하고, 미러링 대상 장비와 동일하게 설정해야 합니다.

* **필터 그룹**을 선택합니다.
    * 이전에 추가한 필터 그룹이 없으면 **필터 그룹 추가**를 클릭하여 필터 그룹을 추가할 수 있습니다.
    * 자세한 사항은 [필터 그룹 설명](#%ED%95%84%ED%84%B0%20%EA%B7%B8%EB%A3%B9)을 참고하세요.
        ![Mirroring_Rule_Filter_Group_900.png](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/Mirroring/25.03.06/Mirroring_Rule_Filter_Group_900.png)

> [참고]
> 필터 그룹은 룰당 하나만 적용 가능합니다.

<br>

### 수정

* **수정**을 클릭해 미러링 룰을 수정할 수 있습니다.

> [참고]
> 이름, 설명, 상태, 필터 그룹만 수정 가능합니다.

<br>

### 삭제

* **삭제**를 클릭해 미러링 룰을 삭제할 수 있습니다.

<br>

### 필터 그룹

* **필터 그룹**을 통해 미러링 룰에 적용할 필터를 설정하면 사용자가 원하는 패킷만 선별하여 전송할 수 있습니다.
![Filter_Group_Contents_Explain_1_900.png](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/Mirroring/25.03.06/Filter_Group_Contents_Explain_1_900.png)
    * 이름: 설정한 이름을 표시합니다.
    * 연결된 미러링 룰: 해당 필터 그룹을 사용하는 미러링 룰을 표시합니다.
    * 설명: 설명을 표시합니다.
    * 필터 규칙 보기: 해당 필터 그룹에 설정된 규칙을 확인합니다.

<br>

### 추가
* **추가**를 클릭해 필터 그룹을 추가할 수 있습니다.
    ![Filter_Group_Add_900.png](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/Mirroring/25.03.06/Filter_Group_Add_900.png)
    * 필터 규칙 정의
        * 우선순위: 작은 숫자일수록 우선순위가 높습니다. 높은 우선순위부터 규칙을 적용하여 미러링 패킷을 전송합니다.
        * 프로토콜: 프로토콜을 지정합니다.
            * ALL: 모든 프로토콜을 지정합니다. 선택 시 출발지/목적지 설정이 비활성화됩니다.
            * TCP: TCP를 지정합니다.
            * UDP: UDP를 지정합니다.
            * ICMP: ICMP를 지정합니다. 선택 시 출발지/목적지 포트 설정이 비활성화됩니다.
        * 출발지/목적지 CIDR: 출발지와 목적지 CIDR을 설정합니다.
        * 출발지/목적지 포트: ALL, 포트, 포트 범위를 선택하여 설정합니다.
            * ALL: 모든 포트를 지정합니다.
            * 포트: 1\~65535 범위의 포트 하나를 지정합니다.
            * 포트 범위: 1\~65535 범위 내에 포트 범위를 지정합니다.
        * 전송 여부: 해당 규칙에 부합하는 패킷의 전송 여부를 설정합니다.
            * 전송: 규칙에 맞는 패킷을 전송합니다.
            * 미전송: 규칙에 맞는 패킷을 전송하지 않습니다.

> [참고]
>
> * 각 규칙의 [－], [＋] 버튼을 클릭해 삭제하거나 추가할 수 있습니다.
> * 각 규칙의 위, 아래 버튼을 클릭해 규칙의 우선순위를 변경할 수 있습니다.
>     ![Filter_Rule_900.png](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/Mirroring/25.03.06/Filter_Rule_900.png)
> * 필터 그룹은 default 필터 그룹을 포함하여 최대 10개까지 설정 가능합니다.
> * 필터 규칙은 최대 30개까지 설정 가능합니다.
> * 필터 규칙은 우선순위가 높은 순에서 낮은 순으로 적용합니다. 따라서 미전송 규칙에 이미 적용 받은 패킷은 다음 우선순위 규칙에 적용을 받지 않습니다.

<br>

### 수정
* **수정**을 클릭해 필터 그룹을 수정할 수 있습니다.

<br>

### 삭제
* **삭제**를 클릭해 필터 그룹을 삭제할 수 있습니다.

> [참고]
> default 필터 그룹은 삭제할 수 없습니다.

<br>

{% endif -%}
## VPN

**VPN** 탭에서는 사이트간 암호화된 터널을 통해 안전한 사설 통신을 지원합니다.

### 게이트웨이 생성

* **게이트웨이 생성**을 클릭해 피어 VPN 장비와 연결하기 위한 게이트웨이를 생성합니다.

![gw_add.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.05.27/gw_add.png)

> [참고]
>
> * VPC와 서브넷은 수정할 수 없습니다.
> * 게이트웨이는 최대 10개까지 생성 가능합니다.

### 수정

* **수정** 버튼을 클릭해 게이트웨이를 수정합니다.

### 삭제

* **삭제** 버튼을 클릭해 게이트웨이를 삭제합니다.
    * 게이트웨이에 연결된 터널이 있을 경우 삭제가 되지 않습니다.

### 플로팅 IP 연결

* 피어 장비와의 연결에 필요한 플로팅 IP를 설정합니다.
    * 플로팅 IP는 **Network > Floating IP** 에 생성된 목록 중 미사용중인 항목이 노출됩니다.

![fip.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.05.27/fip.png)

### 터널 생성

* 피어 장비와 연결할 터널을 생성합니다.

![tunnel_add.PNG](https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.05.27/tunnel_add.png)

* 터널 설정
    * 게이트웨이: 게이트웨이 탭에서 생성된 게이트웨이가 노출되며, 터널과 연결할 게이트웨이를 선택합니다.
        * 생성된 게이트웨이가 없을 경우 노출되지 않습니다.
    * 피어 IP 주소: 연결할 피어 VPN 장비 IP 주소를 입력합니다.
    * IKE 버전: 피어 VPN 장비와 동일한 버전으로 설정합니다.
        * IKE 버전 1은 Main Mode만 지원됩니다.
    * Pre-Shared Key: 피어 VPN 장비와 동일한 키값을 입력합니다.
    * DPD(dead peer detection): 10초 단위로 총 5회의 재전송을 시도하며, 비활성화 선택 시 피어 VPN 장비의 DPD 요청에 대한 응답만 지원합니다.
    * NAT-Traversal: 터널 생성 시 발생되는 패킷의 삭제를 방지하기 위한 기능으로 일반적으로 피어 VPN 장비가 공인 IP일 경우 사용으로 설정합니다.
* Phase 1/2 설정
    * IPSec VPN 터널을 생성하기 위해 필요한 설정 정보를 입력합니다.

 > [설정 시 참고 사항]
 >
 > * 모든 설정은 피어 VPN 장비와 동일하게 설정합니다.
 > * 로컬 ID는 피어 VPN 장비의 설정 방식에 따라 선택적으로 설정합니다.
 > * Phase 2 추가는 최대 3개까지 가능합니다.
 > * Phase 2의 프라이빗 IP는 /24비트 이하로 설정하세요. /24비트 이상의 값을 설정해야 할 경우 서브넷 범위를 사전에 확인하여 서브넷의 시작 IP로 입력하세요.
 >   * [예시]
 >       * 192.168.100.0/20 (X) → 192.168.96.0/20 (O)
 >       * 172.16.30.0/21 (X) → 172.16.24.0/21 (O)
 >       * 10.0.50.0/22 (X) → 10.0.48.0/22 (O)
 > * 로컬 프라이빗 IP와 피어 프라이빗 IP는 서로 중복되지 않아야 합니다. 이 범위는 VPC 피어링을 포함한 Network Firewall과 연결되는 모든 사설 대역이 포함됩니다.
  > * 아래의 CIDR은 로컬 프라이빗 IP와 피어 프라이빗 IP에 추가할 수 없으며, 추가할 경우 Network Firewall을 경유하는 통신에 문제가 있을 수 있습니다.
 >   * 10.0.0.0/8
 >   * 172.16.0.0/12
 >   * 192.168.0.0/16

### 터널 연결

* 터널은 연결 대기 상태로 생성되며, **연결**을 클릭하여 생성된 터널과 피어 VPN 장비를 연결합니다.

> [참고]
>
> * **상태** 열에서 색상별로 터널의 상태를 확인할 수 있습니다.
 >   * 녹색: 피어 VPN 장비와 정상적으로 연결 중인 상태
 >   * 빨간색: 설정값 또는 통신 상태 등의 문제로 피어 VPN 장비 간 연결이 실패된 상태
 >   * 회색: 연결 대기 상태(새로 생성된 터널)
 >   * 주황색: **중지** 버튼을 클릭해 피어 VPN 장비간 연결이 중지된 상태
> * 터널 생성이 완료된 이후 피어 장비의 종류와 설정에 따라 **연결**을 클릭하지 않아도 연결될 수 있습니다.

### 터널 수정

* **수정** 버튼을 클릭해 터널을 수정합니다.
    * 설정값 중 게이트웨이를 제외한 모든 값은 수정이 가능하며, 수정할 경우 피어 VPN 장비도 동일한 값으로 수정해야 합니다.

### 터널 중지

* **중지** 버튼을 클릭해 터널을 중지합니다.
    * 중지할 경우 피어 VPN 장비를 통한 사설 통신이 중단됩니다.

### 터널 삭제

* **삭제** 버튼을 클릭해 터널을 삭제합니다.

### 이벤트

* 피어 VPN 장비와의 터널 연결 시 발생하는 이벤트 로그를 검색할 수 있습니다.

> [참고]
>
> * 이벤트에서는 터널에 대한 이벤트 로그만 검색할 수 있습니다.
> * VPN 터널을 통한 통신 로그 또는 터널 생성과 삭제 등의 감사 로그는 **로그** 탭에서 확인하세요.


## 로그

**로그** 탭에서는 Network Firewall에서 생성된 로그를 검색할 수 있습니다.

### 검색

* 트래픽: Network Firewall을 경유할 때 허용 또는 차단 정책에 의해 생성된 트래픽 로그를 검색
    * 조회는 1개월 단위로 최대 3개월까지의 과거 데이터만 검색 가능합니다.
        * 최대 저장 로그 개수는 800만 개이며, 트래픽의 양에 따라 저장되는 로그의 양이 달라지므로 과거의 데이터가 조회되지 않을 수 있습니다.
    * 별도의 데이터 저장이 필요한 경우 **옵션** 탭의 **로그 원격 전송 설정**을 참고하세요.

* Audit: 정책 생성 및 삭제 등 Network Firewall의 변경 사항에 대한 로그를 검색
    * 조회는 최대 1개월 단위로 검색 가능하며, 조직 서비스인 CloudTrail에서도 검색할 수 있습니다.

### 엑셀 내려받기

* **엑셀 내려받기**를 클릭해 트래픽과 Audit 로그의 검색 결과를 다운로드할 수 있습니다..
    * 트래픽 로그의 최대 다운로드 개수는 30만 건입니다.

## 모니터

**모니터** 탭에서는 Network Firewall의 상태를 실시간으로 확인할 수 있습니다.
검색은 최대 24시간(1일) 내에서만 가능합니다.

### 검색

* 세션: 현재 Network Firewall을 통해 사용하는 세션의 수량
* 네트워크 사용량: 현재 Network Firewall을 경유하는 인바운드/아웃바운드 트래픽

## 옵션

**옵션** 탭에서는 Network Firewall 운영에 필요한 옵션을 설정할 수 있습니다.

### 로그 설정

* 기본 차단 정책 로그 설정: Network Firewall 생성 후 필수로 생성되는 기본 차단 정책 로그의 저장 여부를 선택합니다.
    * 사용 선택 시 기본 차단 정책으로 생성된 로그는 트래픽 로그에서 검색 가능합니다.
* 로그 원격 전송 설정: 원격지로 트래픽 로그를 저장할 수 있는 옵션을 선택합니다.
    * Syslog: 최대 2개의 원격지 주소로 로그를 전송
        * 2개의 원격지는 개별적으로 설정 가능(IP 주소, 프로토콜, 포트 번호)
    * Object Storage: NHN Cloud에서 제공하는 Object Storage 서비스로 로그를 전송
    <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.11.07/OBS_5.png" height="65%" />
        * 액세스 키 / 비밀 키: Object Storage 서비스에서 S3 API 자격 증명 등록 시 확인 가능한 액세스 키 정보를 입력
        * 버킷 이름: Object Storage 서비스에서 생성한 컨테이너의 이름을 입력
        * 엔드포인트: 리전별 엔드포인트를 확인한 뒤 위치에 맞게 엔드포인트를 입력
        * 리전: 리전별 이름을 확인한 뒤 리전 위치에 맞게 이름을 입력
    * Log & Crash Search: NHN Cloud에서 제공하는 Log & Crash Search 서비스로 로그를 전송
    <img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.11.07/LNCS_2.png" height="65%" />
        * AppKey: Log & Crash Search 서비스를 활성화 후 생성된 AppKey를 입력

> [참고]
> * Object Storage 설정 시 [사용자 가이드](https://docs.nhncloud.com/ko/Storage/Object%20Storage/ko/s3-api-guide/#aws-sdk)를 참고하여 입력하세요.
> * Log & Crash Search 서비스를 사용 시 로그 알람 설정 기능을 활용하여 이상 행위를 탐지할 수 있습니다.
예를 들어, Network Firewall에 특정 목적지로 향하는 SSH 통신에 대한 ACL 차단 정책을 추가한 뒤 해당 정책에서 발생되는 로그에 대한 알람 조건을 설정합니다. (예: 1분 동안 SSH 접속 시도 로그가 20회 이상 발생)
사용자가 설정한 조건을 만족 시 알람을 수신할 수 있습니다.

<br>

### 일반 설정

* MTU(maximum transmission unit) 크기 설정: Network Firewall에 연결된 이더넷의 MTU 크기를 설정합니다.
    * 트래픽: NHN Cloud 내부 통신에 사용하는 이더넷(피어링 통신 포함)
    * NAT: 외부 통신에 사용하는 이더넷

> [참고]
> 트래픽, NAT 이더넷의 기본 MTU 크기는 1450Byte입니다.

<br>

{% if build_flags == "gov" -%}
* SSL VPN 설정: 외부에서 NHN Cloud(공공기관용) 인스턴스 접속이 필요할 경우 사용하는 SSL VPN 서비스와 Network Firewall을 연동하는 옵션을 제공합니다.
<img src="https://kr1-api-object-storage.nhncloudservice.com/v1/AUTH_2acdfabf4efe4efc8a04c00b348110c9/cdn_origin/prod_nfw/24.11.07/SSLVPN.png" height="65%" />

> [참고]
>
> * 해당 옵션을 사용할 경우 NHN Cloud(공공기관용)에서 인스턴스 접속 시 사용하는 Private Network의 사설 VPN Network IP를 **Network Firewall > NAT**에서 설정할 수 있습니다.
> * 옵션 사용 시 SSL VPN 연결 후 인스턴스에 접근할 때 Network Firewall을 통해 접근하게 되며 **정책**에서 통신을 허용해야만 인스턴스 접근이 가능합니다.
> * Network Firewall 연동 시 인스턴스는 SSL VPN 전용 이더넷을 추가로 할당하지 않아도 됩니다. (단, Network Firewall과 연동하지 않을 경우 이더넷을 할당해야 합니다.)

<br>

{% endif -%}
{% if build_flags in ["public", "gov"] -%}
* 미러링 설정: Network Firewall에서 제공하는 기능 중 미러링의 사용 여부를 선택할 수 있습니다.
    * 사용 선택 시 필요한 서브넷은 Network Firewall 생성에 사용했던 서브넷을 사용합니다.

> [참고]
> * ACL 설정에 필요한 미러링 인터페이스의 IP 정보는 **Network - Network Interface**에서 확인 가능합니다.
>   * 인터페이스 이름: NetworkFirewall_INF_MIRRORING_S_NAT_VIP

<br>

{% endif -%}
* Network Firewall 구성: 단일 또는 이중화로 Network Firewall의 구성 방식을 설정할 수 있습니다.

> [참고]
>
> * 구성 방식 변경 시 몇 분 정도의 시간이 소요되며, 구성 변경이 완료되기 전까지 서비스에 영향이 있을 수 있습니다.
> * 정책, NAT 등 Network Firewall 변경 작업은 구성 방식 변경이 완료된 뒤 진행할 것을 권장합니다.

<br>

* Network Firewall 삭제: 운영 중인 Network Firewall을 삭제할 수 있습니다.
    * Network Firewall은 한국(판교) 리전과 한국(평촌) 리전에서 각각 삭제할 수 있습니다.

> [삭제 시 주의 사항]
> 운영 중인 Network Firewall을 삭제할 경우 Network Firewall과 연결된 다른 서비스를 고려하여 진행하세요.

<br>

## common 서비스 비활성화

**프로젝트 관리 > 이용 중인 서비스**에서 Network Firewall 서비스를 비활성화할 수 있습니다.

> [참고]
>
> * Network Firewall 서비스 비활성화는 한국(판교) 리전과 한국(평촌) 리전에 모두 적용됩니다.
> 예를 들어 Network Firewall 서비스를 동일한 프로젝트의 한국(판교) 리전과 한국(평촌) 리전에 모두 활성화한 경우 두 리전 중 하나의 Network Firewall 서비스만 비활성화할 수 없습니다.
> * 비활성화하려면 한국(판교) 리전과 한국(평촌) 리전에서 각각 Network Firewall을 삭제한 뒤 진행하세요.



{% if "public" in build_flags -%}
## public 서비스 비활성화

**프로젝트 관리 > 이용 중인 서비스**에서 Network Firewall 서비스를 비활성화할 수 있습니다.

> [참고]
>
> * Network Firewall 서비스 비활성화는 한국(판교) 리전과 한국(평촌) 리전에 모두 적용됩니다.
> 예를 들어 Network Firewall 서비스를 동일한 프로젝트의 한국(판교) 리전과 한국(평촌) 리전에 모두 활성화한 경우 두 리전 중 하나의 Network Firewall 서비스만 비활성화할 수 없습니다.

{% endif -%}
