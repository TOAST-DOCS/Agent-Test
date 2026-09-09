<!-- pre-align:aligned sig=0877fab4a34e -->

{% if "gov" in build_flags -%}
  {%- set api_host      = "api-tt.gov-nhncloudservice.com" -%}
  {%- set region_names  = "한국(판교) 리전" -%}
  {%- set encrypt       = false -%}
{%- elif "ngsc" in build_flags -%}
  {%- set api_host      = "api-tt.ngsc.go.kr" -%}
  {%- set region_names  = "한국(대구) 리전" -%}
  {%- set encrypt       = false -%}
{%- else -%}
  {%- set api_host      = "api-tt.nhncloudservice.com" -%}
  {%- set region_names  = "한국(판교) 리전<br>한국(평촌) 리전<br>한국(광주) 리전" -%}
  {%- set encrypt       = true -%}
{%- endif -%}
{%- set replication = "gov" not in build_flags -%}
{%- set product_name = "템플릿 태그 샘플" -%}

{% macro tt_response_table(prefix='', desc_prefix='') -%}
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$인터페이스 ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$인터페이스 경로 |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$인터페이스 상태 |{% endmacro %}
{# 위 매크로는 응답 표의 공통 행을 만든다 — 주석은 렌더되지 않는다 #}

<a id="sample-template-tags"></a>
## Sample > 템플릿 태그 모양 모음 { #sample-template-tags }

이 문서는 mkdocs-macros 템플릿 태그가 번역을 거친 뒤에도 빌드되고, 태그 안에 저자가 넣은 **한글 문자열**은 번역되는지 검증하기 위한 픽스처입니다. `$[ product_name ]$` 문서의 태그는 실제 사용자 가이드(Private-DNS, Storage-Object-Storage, Storage-Online-NAS, nhn-cloud-foundry)에서 그대로 가져온 모양입니다.

<a id="tt-set-literal"></a>
### 변수에 담긴 한글 문자열 { #tt-set-literal }

문서 상단의 `set` 블록은 빌드 환경마다 다른 값을 변수에 담습니다. 이 가이드가 다루는 리전은 $[ region_names ]$ 이며, API 호스트는 `$[ api_host ]$` 입니다.

| 구분 | 값 | 비고 |
|---|---|---|
| 리전 | $[ region_names ]$ | 환경별로 다릅니다 |
| API 호스트 | `$[ api_host ]$` | 밑줄이 들어간 변수 이름입니다 |
| 조회 시작 시간 | {{executionTime}} | 워크플로 엔진이 치환하는 자리 표시자입니다 |

<a id="tt-inline-literal"></a>
### 문장 안의 조건부 문자열 { #tt-inline-literal }

컨테이너의 $[ "기본 정보와 암호화 정보" if encrypt else "기본 정보" ]$를 확인하고, 접근 정책과 정적 웹사이트 설정을 변경할 수 있습니다.

!!! note "참고"
    일반 컨테이너를 오브젝트 잠금 컨테이너로 변경할 수 없습니다.

    오브젝트 잠금 컨테이너는 아카이브 컨테이너$[ " 또는 복제 대상 컨테이너로" if replication else "로" ]$ 지정할 수 없습니다.

<a id="tt-macro-arg"></a>
### 매크로 인자로 넘긴 한글 문자열 { #tt-macro-arg }

아래 표의 행은 매크로가 만듭니다. 두 번째 인자는 설명 앞에 붙는 접두어입니다.

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
$[ tt_response_table('interface.', '생성된 ') ]$
| interface.subnetId | Body | String | 인터페이스의 서브넷 ID |

접두어 없이 호출하면 설명이 그대로 나옵니다.

| 이름 | 종류 | 형식 | 설명 |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### 태그처럼 보이는 UI 자리 표시자 { #tt-ui-placeholder }

| 항목 | 필수 | 설명 |
|---|---|---|
| 사용자 프롬프트 템플릿 | X | 행별 입력 값 구성 템플릿. {{ 칼럼 이름 }} 패턴이 해당 칼럼 값으로 치환되며, 설정하면 결합 구분자보다 우선 적용됩니다. |
| 결합 구분자 | X | 여러 칼럼을 하나의 입력으로 합칠 때 사이에 넣는 문자열입니다. |

<a id="tt-wrapped"></a>
### 문단을 감싼 조건부 { #tt-wrapped }

{% if "gov" not in build_flags %}
공용 환경에서는 콘솔에서 곧바로 설정할 수 있습니다. 이 문단은 여는 태그가 바로 위에 붙어 있어 증분 번역에서 태그와 한 유닛이 됩니다.
{% endif %}

{% if "gov" in build_flags %}정부망 환경에서는 담당자에게 발급 절차를 문의해야 합니다.{% else %}공용 환경에서는 콘솔에서 직접 발급할 수 있습니다.{% endif %}

<a id="tt-fenced"></a>
### 코드 블록 안의 태그 { #tt-fenced }

mkdocs-macros 는 코드 블록 안의 태그도 Jinja 로 처리하므로, 태그를 **예시로 보여 주려면** `{% raw %}` 로 감싸야 합니다. 감싸지 않으면 조건문이 평가되고 변수가 치환되어 예시가 사라집니다.

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "한국(판교) 리전" -%}
{% endif %}
$[ region_names ]$ / {{ 칼럼 이름 }} / $[ api_host ]$
```
{% endraw %}

아래 블록은 한글이 없는 대조군입니다. 번역을 거쳐도 바이트 단위로 같아야 합니다.

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### 마지막 절 { #tt-tail }

이 절은 변경되지 않는 대조군입니다. 증분 번역 뒤에도 en/ja 가 바이트 단위로 같아야 합니다.
