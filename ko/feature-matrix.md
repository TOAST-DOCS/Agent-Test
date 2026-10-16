<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > 기능 매트릭스

인스턴스 서비스가 제공하는 기능을 리전과 요금제 관점에서 정리한 문서입니다. 번역 파이프라인 테스트를 위해 표, 목록, 코드 블록, 중첩 heading 을 모두 포함합니다.

<a id="feature-overview"></a>
## 기능 개요

인스턴스의 주요 기능은 다음과 같습니다.

- **인스턴스 생성**: 이미지와 타입을 선택해 가상 서버를 생성합니다. (목록 수정 테스트)
- **인스턴스 템플릿**: 자주 쓰는 설정을 템플릿으로 저장해 재사용합니다.
- **스케줄링**: 지정한 시간에 인스턴스를 시작하거나 중지합니다.
- **모니터링**: CPU, 메모리, 디스크 사용량을 대시보드에서 확인합니다.

<a id="feature-by-region"></a>
## 리전별 기능 제공 여부

리전에 따라 제공되는 기능이 다릅니다. 아래 표에서 확인하세요.

| 기능 코드 | 기능 이름 | 판교 | 평촌 | 일본 (수정) |
|---|---|---|---|---|
| INST-CREATE | 인스턴스 생성 | 제공 | 제공 | 제공 |
| INST-TPL | 인스턴스 템플릿 | 제공 | 제공 | 미제공 |
| INST-SCHED | 인스턴스 스케줄링 | 제공 | 미제공 | 미제공 |
| INST-MON | 인스턴스 모니터링 | 제공 | 제공 | 제공 |

<a id="feature-by-plan"></a>
### 요금제별 제공 한도 및 상세

요금제에 따라 생성 가능한 인스턴스 수가 다릅니다.

| 요금제 | 최대 인스턴스 수 | 최대 블록 스토리지 |
|---|---|---|
| 기본 | 10대 | 1TB |
| 표준 | 50대 | 10TB |

<a id="feature-api"></a>
## API 로 기능 확인

기능 제공 여부는 API 로도 조회할 수 있습니다.

<a id="feature-api-request"></a>
### 조회 요청

아래 예시와 같이 기능 코드를 지정해 호출합니다.

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### 응답 필드

응답 본문의 주요 필드는 다음과 같습니다.

- `code`: 기능 코드
- `available`: 제공 여부 (true/false)
- `regions`: 제공 리전 목록

<a id="feature-notes"></a>
## 참고 사항

기능 제공 여부는 사전 공지 후 변경될 수 있습니다. 최신 정보는 콘솔 공지사항을 확인하세요.
