<a id="jinja-repair-sample"></a>
## Jinja 복원 샘플 { #jinja-repair-sample }

이 문서는 Jinja 문법 오류 복원 e2e 의 픽스처입니다. 정상 상태로 보관하고, e2e 가 세션 브랜치에 결함을 심습니다.

<a id="jinja-repair-closer"></a>
### 공공 전용 표 { #jinja-repair-closer }

모든 환경에 공통인 설명입니다.

{% if "gov" in build_flags %}
공공기관용 환경에서만 제공하는 엔드포인트입니다.

| 리전 | 엔드포인트 |
|---|---|
| 한국(판교) 리전 | https://kr1-api.gov-nhncloudservice.com |
{% endif %}

<a id="jinja-repair-opener"></a>
### 환경별 안내 { #jinja-repair-opener }

다음 안내는 환경마다 다릅니다.

{% if "gov" not in build_flags %}
!!! tip "알아두기"
    일반 환경에서는 콘솔에서 바로 신청할 수 있습니다.
{% else %}
!!! tip "알아두기"
    공공기관용 환경에서는 담당자 승인 후 사용할 수 있습니다.
{% endif %}

신청 후 10분 이내에 적용됩니다.

<a id="jinja-repair-author"></a>
### 출시 예정 기능 { #jinja-repair-author }

현재 제공하는 기능은 다음과 같습니다.

- 인스턴스 생성
- 인스턴스 삭제

{% if release_2026_11 %}
!!! note "참고"
    2026년 11월 출시 예정인 기능은 스냅숏 예약입니다.

출시 일정은 사정에 따라 바뀔 수 있습니다.

<a id="jinja-repair-typo"></a>
### 리전 목록 { #jinja-repair-typo }

{% if "ncgn" in build_flags %}
- 한국(대구) 리전
{% endif %}
- 한국(판교) 리전
- 한국(평촌) 리전
