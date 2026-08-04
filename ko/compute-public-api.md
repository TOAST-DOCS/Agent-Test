{%- set variant = ("ngoic" if "ngoic" in build_flags
              else "ngovc" if "ngovc" in build_flags
              else "ngsc"  if "ngsc"  in build_flags
              else "ninc"  if "ninc"  in build_flags
              else "") -%}
## Compute > Instance > API v2 가이드 (mkdocs 문법 데모)

이 문서는 `compute-public-api.md` 에서 실제로 사용되는 Jinja 고급 문법을 최소한의 예제로 보여 줍니다.

{#
  이 라인은 Jinja 주석입니다. 렌더링 결과에는 노출되지 않으며,
  {% ... %} 이 아니라 {# ... #} 형태로 작성합니다.
#}

## 1. 다중 분기 `{%- set -%}`

파일 최상단에서 build_flag 조합을 하나의 변수로 응축했습니다.

{% raw %}
```jinja
{%- set variant = ("ngoic" if "ngoic" in build_flags
              else "ngovc" if "ngovc" in build_flags
              else "ngsc"  if "ngsc"  in build_flags
              else "ninc"  if "ninc"  in build_flags
              else "") -%}
```
{% endraw %}

현재 `variant` 값: `$[ variant ]$`

## 2. dict 리터럴 + `.get()`

{%- set kr4_host_map = {
      "ngoic": "kr4-api-instance-infrastructure.ngoic.com",
      "ngovc": "kr4-api-instance-infrastructure.ngovc.com",
      "ngsc":  "kr4-api-instance-infrastructure.ngsc.go.kr",
      "ninc":  "kr4-api-instance-infrastructure.ninc.go.kr",
} -%}
{%- set kr4_host = kr4_host_map.get(variant, "(없음)") -%}

`variant` 를 키로 dict 에서 조회한 결과: `$[ kr4_host ]$`

{% raw %}
```jinja
{%- set kr4_host_map = { "ngoic": "...", "ngovc": "...", ... } -%}
{%- set kr4_host = kr4_host_map.get(variant, "(없음)") -%}
```
{% endraw %}

## 3. `{% macro %}` 정의와 호출

{%- set kr1_host = "kr1-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set kr2_host = "kr2-api-instance-infrastructure.nhncloudservice.com" -%}
{% macro api_host(region) -%}
{%- if region == "kr1" -%}$[ kr1_host ]$
{%- elif region == "kr2" -%}$[ kr2_host ]$
{%- endif -%}
{%- endmacro %}

| 리전 | 엔드포인트 |
|---|---|
| 한국(판교) | https://$[ api_host("kr1") ]$ |
| 한국(평촌) | https://$[ api_host("kr2") ]$ |

{% raw %}
```jinja
{% macro api_host(region) -%}
{%- if region == "kr1" -%}$[ kr1_host ]$
{%- elif region == "kr2" -%}$[ kr2_host ]$
{%- endif -%}
{%- endmacro %}

https://$[ api_host("kr1") ]$
```
{% endraw %}

## 4. dict 속성 접근 (`hosts.kr1`)

{%- set hosts = { "kr1": kr1_host, "kr2": kr2_host } -%}

| 리전 | 엔드포인트 |
|---|---|
| 한국(판교) | https://$[ hosts.kr1 ]$ |
| 한국(평촌) | https://$[ hosts.kr2 ]$ |

{% raw %}
```jinja
{%- set hosts = { "kr1": kr1_host, "kr2": kr2_host } -%}

https://$[ hosts.kr1 ]$
```
{% endraw %}

## 5. 인라인 `{% if %}` (문장/URL 내부)

인라인 조건으로 URL 접미사를 붙일 수 있습니다.
자세한 내용은 [IaaS 토큰](/nhncloud/ko/public-api/iaas-token{% if "gov" in build_flags %}-gov{% endif %}) 을 참고하세요.

{% raw %}
```jinja
[IaaS 토큰](/nhncloud/ko/public-api/iaas-token{% if "gov" in build_flags %}-gov{% endif %})
```
{% endraw %}

## 6. `{% if not build_flags %}` — 빈 build_flags 검사

`build_flags` 자체가 비어 있는 경우(=기본 빌드)를 판별합니다.

{% if not build_flags %}
현재 build_flags 가 비어 있어 이 문단이 렌더링됩니다.
{% else %}
현재 build_flags 가 설정되어 있어 else 분기가 렌더링됩니다.
{% endif %}

{% raw %}
```jinja
{% if not build_flags %}
기본 빌드 전용 문단
{% else %}
build_flag 가 하나라도 설정된 빌드 전용 문단
{% endif %}
```
{% endraw %}
