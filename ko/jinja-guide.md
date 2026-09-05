<!-- pre-align:aligned sig=cdbc88f0a12c -->

{%- set api_host = "api-jinja.gov-nhncloudservice.com" if "gov" in build_flags else "api-jinja.nhncloudservice.com" -%}
<a id="sample-jinja-guide"></a>
## Sample > Jinja 가이드 { #sample-jinja-guide }

이 문서는 mkdocs-macros 의 Jinja 조건부 분기와 변수 치환이 ko/en/ja 세 언어에 동일하게 유지되는지 검증하기 위한 픽스처입니다. 태그는 제어 문법이므로 번역되지 않고, 본문만 언어별로 달라집니다.

<a id="endpoint"></a>
### 엔드포인트 { #endpoint }

{% if "gov" in build_flags -%}
정부망 환경에서는 전용 엔드포인트를 사용합니다. 공용 도메인으로는 접근할 수 없습니다.
{% else -%}
공용 환경에서는 기본 엔드포인트를 사용합니다. 리전별 호스트는 아래 표를 참고하세요.
{% endif %}

API 호스트는 `$[ api_host ]$` 입니다.

| 리전 | 호스트 | 비고 |
|---|---|---|
| 한국(판교) | kr1-$[ api_host ]$ | 기본 리전<br>상시 운영 |
| 한국(평촌) | kr2-$[ api_host ]$ | 이중화 구성 |

<a id="auth"></a>
### 인증 { #auth }

{% if "ngsc" in build_flags -%}
NGSC 환경은 별도 인증 절차를 따릅니다. 담당자에게 발급 절차를 문의하세요.
{% else -%}
토큰을 발급받아 요청 헤더에 담아 호출합니다. 토큰에는 만료 시간이 있습니다.
{% endif %}

<a id="reference"></a>
### References { #reference }

- [API 사용 준비](/nhncloud/ko/public-api/)
