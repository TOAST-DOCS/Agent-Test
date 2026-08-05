{%- set api_host = "api-tcd.gov-nhncloudservice.com" if "gov" in build_flags else "api-tcd.nhncloudservice.com" -%}
<a id="dev-tools-deploy-api-v20"></a>
## Dev Tools > Deploy > API v2.0 가이드 { #dev-tools-deploy-api-v20 }

mkdocs 변수 치환 및 raw 블록 문법 데모용 문서입니다. 각 절은 소스 코드와 렌더링 결과를 함께 보여 줍니다.

<a id="raw-set-endraw"></a>
### 1. 변수 선언 ({% raw %}`{% set %}`{% endraw %}) { #raw-set-endraw }

파일 최상단에서 아래와 같이 build_flag 에 따라 값이 달라지는 변수를 선언했습니다.

**소스**

{% raw %}
```jinja
{%- set api_host = "api-tcd.gov-nhncloudservice.com" if "gov" in build_flags else "api-tcd.nhncloudservice.com" -%}
```
{% endraw %}

<a id="raw-var-endraw"></a>
### 2. 본문에서의 변수 치환 ({% raw %}`$[ var ]$`{% endraw %}) { #raw-var-endraw }

**소스**

{% raw %}
```jinja
https://$[ api_host ]$
```
{% endraw %}

**렌더링 결과**

```text
https://$[ api_host ]$
```

<a id="dev-tools-deploy-api-v20-1"></a>
### 3. 표 안에서의 변수 치환 { #dev-tools-deploy-api-v20-1 }

**소스**

{% raw %}
```jinja
| Http Method | POST |
| ----------- | ---- |
| Request URL | https://$[ api_host ]$/api/v2.0/projects/{appKey}/deploy |
```
{% endraw %}

**렌더링 결과**

| Http Method | POST |
| ----------- | ---- |
| Request URL | https://$[ api_host ]$/api/v2.0/projects/{appKey}/deploy |

<a id="dev-tools-deploy-api-v20-2"></a>
### 4. 코드 블록 안에서의 변수 치환 { #dev-tools-deploy-api-v20-2 }

**소스** (외곽에 4-백틱 fence 를 써서 내부 3-백틱 fence 를 감쌌습니다)

{% raw %}
````jinja
``` java
curl --location 'https://$[ api_host ]$/api/v2.0/projects/{appKey}/deploy' \
  --header 'Content-Type: application/json'
```
````
{% endraw %}

**렌더링 결과**

``` java
curl --location 'https://$[ api_host ]$/api/v2.0/projects/{appKey}/deploy' \
  --header 'Content-Type: application/json'
```

<a id="raw-jinja"></a>
### 5. raw 블록으로 Jinja 원문 보존 { #raw-jinja }

`{​% raw %​}` ... `{​% endraw %​}` 로 감싸면 안쪽의 Jinja 태그가 평가되지 않고 원문 그대로 노출됩니다. (Jinja 의 raw 블록은 중첩을 지원하지 않으므로, 아래 소스는 표기용 태그의 `{` 과 `%` 사이에 zero-width space 를 넣어 파서가 무시하도록 표기했습니다.)

**소스** (바깥 4-백틱 fence 로 감싸고, 표기용 raw 태그는 ZWSP 로 회피)

{% raw %}
````jinja
{​% raw %​}
```text
{%- set example = "raw 블록 안에서는 이 코드가 렌더링되지 않습니다" -%}
값: $[ example ]$
```
{​% endraw %​}
````
{% endraw %}

**렌더링 결과**

{% raw %}
```text
{%- set example = "raw 블록 안에서는 이 코드가 렌더링되지 않습니다" -%}
값: $[ example ]$
```
{% endraw %}
