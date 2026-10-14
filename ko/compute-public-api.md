{%- set variant = ("ngoic" if "ngoic" in build_flags
              else "ngovc" if "ngovc" in build_flags
              else "ngsc"  if "ngsc"  in build_flags
              else "ninc"  if "ninc"  in build_flags
              else "") -%}
<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 가이드 { #compute-instance-api-v2-guide }

{% if "ngoic" in build_flags or "ngovc" in build_flags or "ngsc" in build_flags or "ninc" in build_flags %}
API를 사용하려면 API 엔드포인트와 토큰 등이 필요합니다. [API 사용 준비](/Compute/Compute/ko/identity-api-$[ variant ]$/)를 참고하여 API 사용에 필요한 정보를 준비합니다.
{% else %}
Instance는 API 호출 시 인증/인가를 위해 IaaS 토큰을 사용합니다. IaaS 토큰은 NHN Cloud의 OpenStack 기반 인프라 서비스(IaaS)에서 사용하는 인증 토큰입니다. IaaS 토큰 발급 및 사용에 대한 자세한 내용은 [IaaS 토큰](/nhncloud/ko/public-api/iaas-token{% if "gov" in build_flags %}-gov{% endif %}) 을 참고하세요.
{% endif %}

인스턴스 API는 `compute` 타입 엔드포인트를 이용합니다. 정확한 엔드포인트는 토큰 발급 응답의 `serviceCatalog`를 참조합니다.

<a id="1-macro"></a>
### 엔드포인트 (방식 1: macro) { #1-macro }
{#
  방식 1 예시 — region 을 인자로 받는 macro 로 URL 을 조립합니다.
  이 섹션에서 필요한 변수/매크로를 자체적으로 정의합니다.
#}

{%- set kr4_host_map = {
      "ngoic": "kr4-api-instance-infrastructure.ngoic.com",
      "ngovc": "kr4-api-instance-infrastructure.ngovc.com",
      "ngsc":  "kr4-api-instance-infrastructure.ngsc.go.kr",
      "ninc":  "kr4-api-instance-infrastructure.ninc.go.kr",
} -%}
{%- set kr4_host = kr4_host_map.get(variant, "") -%}
{%- set kr1_host = ("kr1-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr1-api-instance-infrastructure.gncloud.go.kr"           if variant
              else "kr1-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr2_host = ("kr2-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr2-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr3_host = "kr3-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set jp1_host = "jp1-api-instance-infrastructure.nhncloudservice.com" -%}
{% macro api_host(region) -%}
{%- if region == "kr1" -%}$[ kr1_host ]$
{%- elif region == "kr2" -%}$[ kr2_host ]$
{%- elif region == "kr3" -%}$[ kr3_host ]$
{%- elif region == "kr4" -%}$[ kr4_host ]$
{%- elif region == "jp1" -%}$[ jp1_host ]$
{%- endif -%}
{%- endmacro %}

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "gov" in build_flags -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전 | https://$[ api_host("kr1") ]$<br>https://$[ api_host("kr2") ]$           |
{%- elif "ngoic" in build_flags or "ngovc" in build_flags or "ngsc" in build_flags or "ninc" in build_flags -%}
| compute | 한국(대구) 리전 | https://$[ api_host("kr4") ]$ |
{%- else -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>일본 리전 | https://$[ api_host("kr1") ]$<br>https://$[ api_host("kr2") ]$<br>https://$[ api_host("kr3") ]$<br>https://$[ api_host("jp1") ]$ |
{% endif %}

방식 1 소스 ([GitHub code view](./public-api/)):

{% raw %}
```jinja
{%- set kr4_host_map = {
      "ngoic": "kr4-api-instance-infrastructure.ngoic.com",
      "ngovc": "kr4-api-instance-infrastructure.ngovc.com",
      "ngsc":  "kr4-api-instance-infrastructure.ngsc.go.kr",
      "ninc":  "kr4-api-instance-infrastructure.ninc.go.kr",
} -%}
{%- set kr4_host = kr4_host_map.get(variant, "") -%}
{%- set kr1_host = ("kr1-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr1-api-instance-infrastructure.gncloud.go.kr"           if variant
              else "kr1-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr2_host = ("kr2-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr2-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr3_host = "kr3-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set jp1_host = "jp1-api-instance-infrastructure.nhncloudservice.com" -%}
{% macro api_host(region) -%}
{%- if region == "kr1" -%}$[ kr1_host ]$
{%- elif region == "kr2" -%}$[ kr2_host ]$
{%- elif region == "kr3" -%}$[ kr3_host ]$
{%- elif region == "kr4" -%}$[ kr4_host ]$
{%- elif region == "jp1" -%}$[ jp1_host ]$
{%- endif -%}
{%- endmacro %}

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "gov" in build_flags -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전 | https://$[ api_host("kr1") ]$<br>https://$[ api_host("kr2") ]$ |
{%- elif "ngoic" in build_flags or "ngovc" in build_flags or "ngsc" in build_flags or "ninc" in build_flags -%}
| compute | 한국(대구) 리전 | https://$[ api_host("kr4") ]$ |
{%- else -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>일본 리전 | https://$[ api_host("kr1") ]$<br>https://$[ api_host("kr2") ]$<br>https://$[ api_host("kr3") ]$<br>https://$[ api_host("jp1") ]$ |
{% endif %}
```
{% endraw %}

<a id="2-dict"></a>
### 엔드포인트 (방식 2: dict) { #2-dict }
{#
  방식 2 예시 — 이 섹션에서 hosts dict 를 자체적으로 정의합니다.
  macro 는 필요 없습니다.
#}

{%- set kr4_host_map = {
      "ngoic": "kr4-api-instance-infrastructure.ngoic.com",
      "ngovc": "kr4-api-instance-infrastructure.ngovc.com",
      "ngsc":  "kr4-api-instance-infrastructure.ngsc.go.kr",
      "ninc":  "kr4-api-instance-infrastructure.ninc.go.kr",
} -%}
{%- set kr4_host = kr4_host_map.get(variant, "") -%}
{%- set kr1_host = ("kr1-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr1-api-instance-infrastructure.gncloud.go.kr"           if variant
              else "kr1-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr2_host = ("kr2-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr2-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr3_host = "kr3-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set jp1_host = "jp1-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set hosts = {
      "kr1": kr1_host,
      "kr2": kr2_host,
      "kr3": kr3_host,
      "jp1": jp1_host,
      "kr4": kr4_host,
} %}

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "gov" in build_flags -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전 | https://$[ hosts.kr1 ]$<br>https://$[ hosts.kr2 ]$           |
{%- elif "ngoic" in build_flags or "ngovc" in build_flags or "ngsc" in build_flags or "ninc" in build_flags -%}
| compute | 한국(대구) 리전 | https://$[ hosts.kr4 ]$ |
{%- else -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>일본 리전 | https://$[ hosts.kr1 ]$<br>https://$[ hosts.kr2 ]$<br>https://$[ hosts.kr3 ]$<br>https://$[ hosts.jp1 ]$ |
{% endif %}

방식 2 소스 ([GitHub code view](./public-api/)):

{% raw %}
```jinja
{%- set kr4_host_map = {
      "ngoic": "kr4-api-instance-infrastructure.ngoic.com",
      "ngovc": "kr4-api-instance-infrastructure.ngovc.com",
      "ngsc":  "kr4-api-instance-infrastructure.ngsc.go.kr",
      "ninc":  "kr4-api-instance-infrastructure.ninc.go.kr",
} -%}
{%- set kr4_host = kr4_host_map.get(variant, "") -%}
{%- set kr1_host = ("kr1-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr1-api-instance-infrastructure.gncloud.go.kr"           if variant
              else "kr1-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr2_host = ("kr2-api-instance-infrastructure.gov-nhncloudservice.com" if "gov" in build_flags
              else "kr2-api-instance-infrastructure.nhncloudservice.com") -%}
{%- set kr3_host = "kr3-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set jp1_host = "jp1-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set hosts = {
      "kr1": kr1_host, "kr2": kr2_host, "kr3": kr3_host,
      "jp1": jp1_host, "kr4": kr4_host,
} -%}

| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "gov" in build_flags -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전 | https://$[ hosts.kr1 ]$<br>https://$[ hosts.kr2 ]$ |
{%- elif "ngoic" in build_flags or "ngovc" in build_flags or "ngsc" in build_flags or "ninc" in build_flags -%}
| compute | 한국(대구) 리전 | https://$[ hosts.kr4 ]$ |
{%- else -%}
| compute | 한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전<br>일본 리전 | https://$[ hosts.kr1 ]$<br>https://$[ hosts.kr2 ]$<br>https://$[ hosts.kr3 ]$<br>https://$[ hosts.jp1 ]$ |
{% endif %}
```
{% endraw %}

API 응답에 가이드에 명시되지 않은 필드가 나타날 수 있습니다. 이런 필드는 NHN Cloud 내부 용도로 사용되며 사전 공지 없이 변경될 수 있으므로 사용하지 않습니다.
