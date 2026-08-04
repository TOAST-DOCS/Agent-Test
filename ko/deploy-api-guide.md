{%- set api_host = "api-tcd.gov-nhncloudservice.com" if "gov" in build_flags else "api-tcd.nhncloudservice.com" -%}
## Dev Tools > Deploy > API v2.0 가이드

mkdocs 변수 치환 / `{% raw %}` 블록 문법 데모용 문서입니다.

### 변수 선언 (`{% set %}`)

파일 최상단에서 아래와 같이 build_flag 에 따라 값이 달라지는 변수를 선언했습니다.

{% raw %}
```jinja
{%- set api_host = "api-tcd.gov-nhncloudservice.com" if "gov" in build_flags else "api-tcd.nhncloudservice.com" -%}
```
{% endraw %}

### 본문에서의 변수 치환 (`$[ var ]$`)

```text
https://$[ api_host ]$
```

### 표 안에서의 변수 치환

| Http Method | POST |
| ----------- | ---- |
| Request URL | https://$[ api_host ]$/api/v2.0/projects/{appKey}/deploy |

### 코드 블록 안에서의 변수 치환

``` java
curl --location 'https://$[ api_host ]$/api/v2.0/projects/{appKey}/deploy' \
  --header 'Content-Type: application/json'
```

### `{% raw %}` 로 Jinja 원문 보존

렌더링 대신 원문을 그대로 노출하고 싶을 때 사용합니다.

{% raw %}
```text
{%- set example = "raw 블록 안에서는 이 코드가 렌더링되지 않습니다" -%}
값: $[ example ]$
```
{% endraw %}
