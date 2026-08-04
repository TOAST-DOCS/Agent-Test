# MkDocs 템플릿 문법 규칙

이 저장소의 `ko/`, `en/`, `ja/` Markdown 파일은 배포 시 커스텀 delimiter 를 사용하는 Jinja2 기반 전처리기를 통해 렌더링됩니다. 아래는 실제로 배포 파이프라인이 지원하는 것으로 확인된 문법이며, `ko/overview.md` 와 `ko/public-api.md` 에 실사용 예시가 있습니다.

## Delimiter

| 종류 | 열기 | 닫기 | 예 |
|---|---|---|---|
| 표현식(변수/함수 호출) | `$[` | `]$` | `$[ hosts.kr1 ]$` |
| 블록 태그 | `{%` | `%}` | `{% if "gov" in build_flags %}` |
| 주석 | `{#` | `#}` | `{# 렌더에 표시되지 않는 메모 #}` |

> **주의**: 표현식은 표준 Jinja 의 `{{ }}` 가 아닌 **`$[ ]$`** 를 씁니다. `{{ ... }}` 는 배포 결과에 raw 텍스트로 그대로 노출됩니다.

## 화이트스페이스 제어

블록 태그 앞·뒤의 공백/줄바꿈을 제거하려면 `-` 를 붙입니다.

```jinja
{%- if "gov" in build_flags -%}   ← 태그 앞·뒤 공백 모두 제거
{% if "gov" in build_flags -%}    ← 뒷쪽만 제거 (앞 공백 유지)
{%- if "gov" in build_flags %}    ← 앞쪽만 제거
```

주석에도 동일하게 적용: `{#- ... -#}` vs `{# ... #}`. 주석 자체는 어떻게 쓰든 렌더 결과에서 사라지지만, 앞뒤 공백 처리 방식이 다릅니다. **연속된 blank line 이 중요한 위치 (heading 직후 등) 에서는 dash 를 붙이지 마세요** — 앞뒤 공백이 지워져 heading 이 다음 요소와 붙어버립니다.

## 조건 블록

가장 자주 쓰이는 패턴이며, 배포 파이프라인이 확실히 지원합니다.

### 단일 조건

```jinja
{% if "gov" in build_flags -%}
gov 전용 문단
{% endif -%}
```

### if / else

```jinja
{% if "gov" in build_flags -%}
gov 문구
{%- else -%}
그 외 문구
{%- endif %}
```

### 다중 조건 (elif)

```jinja
{% if "gov" in build_flags %}
...
{% elif "ngoic" in build_flags or "ngovc" in build_flags %}
...
{% else %}
...
{% endif %}
```

### 부정 및 OR

```jinja
{% if "gov" not in build_flags %} ... {% endif %}
{% if "public" in build_flags or "gov" in build_flags -%} ... {%- endif %}
```

## 변수 정의 (`{% set %}`)

파일 상단에서 자주 파생 변수를 만듭니다. 여러 줄로 흩어써도 됩니다.

```jinja
{%- set variant = ("ngoic" if "ngoic" in build_flags
              else "ngovc" if "ngovc" in build_flags
              else "") -%}
{%- set kr3_host = "kr3-api-instance-infrastructure.nhncloudservice.com" -%}
{%- set hosts = {
      "kr1": kr1_host,
      "kr2": kr2_host,
      "kr3": kr3_host,
} -%}
```

사용 시:

```jinja
| compute | 한국(광주) 리전 | https://$[ hosts.kr3 ]$ |
```

## Macro 정의

인자를 받는 재사용 가능 함수 정의.

```jinja
{% macro api_host(region) -%}
$[ hosts.get(region, "") ]$
{%- endmacro %}
```

호출:

```jinja
| compute | 한국(판교) 리전 | https://$[ api_host("kr1") ]$ |
```

## `build_flags` 변수

배포 파이프라인이 각 build 별로 주입하는 리스트입니다. 파일 안에서 정의하지 않고, 곧바로 참조합니다.

|  build_flag  |  대상 build  |
|---|---|
| `gov` | 공공기관용 |
| `ngoic` | 대구 리전 - ngoic |
| `ngovc` | 대구 리전 - ngovc |
| `ngsc`  | 대구 리전 - ngsc |
| `ninc`  | 대구 리전 - ninc |
| `public` | 일반 상용 (`overview.md` 에서 사용) |
| (빈 리스트) | 기본 build |

체크는 리스트 멤버십으로 합니다: `"gov" in build_flags`.

## 실사용 파일

| 파일 | 사용하는 문법 |
|---|---|
| [`ko/overview.md`](ko/overview.md) | `{% if %}` 조건 블록 + `{%- ... -%}` 화이트스페이스 제어 |
| [`ko/public-api.md`](ko/public-api.md) | 위 항목 전부 + `{% set %}` + `{% macro %}` + `$[ ]$` 표현식 + `{# #}` 주석 |

## 로컬 검증 방법

Python + Jinja2 로 렌더링해 결과를 확인할 수 있습니다. 커스텀 delimiter 를 지정하는 것이 핵심.

```python
import jinja2
env = jinja2.Environment(
    variable_start_string='$[',
    variable_end_string=']$',
    keep_trailing_newline=True,
    trim_blocks=True,
)
tpl = env.from_string(open('ko/public-api.md').read())
print(tpl.render(build_flags=['gov']))     # gov build 렌더 결과
print(tpl.render(build_flags=[]))          # 기본 build
```

## 배포 확인

이 저장소는 https://docs.alpha-nhncloud.com/ko/Open%20Source/agent-test/ 로 배포됩니다. 새로 문법을 도입한 뒤에는 배포 페이지에서 raw 템플릿 텍스트 (`$[`, `{%`, `{#`) 가 노출되지 않았는지 반드시 눈으로 확인하세요.
