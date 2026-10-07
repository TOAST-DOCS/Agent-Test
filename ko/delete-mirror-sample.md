<!-- pre-align:aligned sig=18e686d70cbe -->

<a id="delete-mirror-overview"></a>
## 삭제 미러 테스트 { #delete-mirror-overview }

이 문서는 ko PR 이 절 안의 하위 블록 하나를 **삭제만** 하고, 같은 PR 이 en/ja 에서도 그 블록을
이미 지운 경우(TOAST-DOCS/Network#160 → #163, 2026-10-07)를 재현하는 픽스처입니다.
ko 가 건드리지 않은 형제 불릿이 en/ja 에서 바뀌면 결함입니다.

<a id="delete-mirror-2025-11-25"></a>
### 2025. 11. 25. { #delete-mirror-2025-11-25 }

<a id="delete-mirror-2025-11-25-added-features"></a>
#### 기능 추가

##### VPN Gateway
* VPN이 연결된 VPC에 Transit Hub를 연결하면 Transit Hub로 연결된 다른 프로젝트의 VPC에서도 온프레미스 네트워크와 VPN 통신을 지원합니다. (연결된 대역으로 VPN Connection은 추가 생성 필요)

##### Service Gateway
* Service Gateway 생성 시 사용자가 NAT IP를 고정하여 생성할 수 있도록 개선되었습니다.

##### Load Balancer
* 리스너별 사용자 정의 응답 설정 기능이 추가되었습니다.
* X-Forwarded-* 헤더 활성화/비활성화 기능이 추가되었습니다.

<a id="delete-mirror-2024-05-28"></a>
### 2024. 05. 28. { #delete-mirror-2024-05-28 }

<a id="delete-mirror-2024-05-28-feature-updates"></a>
#### 기능 개선

##### Load Balancer
* 로드 밸런서 생성 시 기본 정보에서 IP 접근 제어 설정을 함께 할 수 있도록 개선되었습니다.

<a id="delete-mirror-control"></a>
### 2023. 03. 14. { #delete-mirror-control }

<a id="delete-mirror-control-added-features"></a>
#### 기능 추가

##### Service Gateway
* Service Gateway 서비스가 출시되었습니다.
