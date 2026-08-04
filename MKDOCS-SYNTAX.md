# MkDocs 템플릿 문법 규칙

이 저장소의 `ko/`, `en/`, `ja/` Markdown 파일은 배포 시 커스텀 delimiter 를 사용하는 Jinja2 기반 전처리기를 통해 렌더링됩니다. 아래는 실제로 배포 파이프라인이 지원하는 것으로 확인된 문법이며, `ko/overview.md` 와 `ko/public-api.md` 에 실사용 예시가 있습니다.

## Delimiter

| 종류 | 열기 | 닫기 | 예 |
|---|---|---|---|
| 표현식(변수/함수 호출) | `$[` | `]$` | `$[ hosts.kr1 ]$` |
| 블록 태그 | `{%` | `%}` | `{% if "gov" in build_flags %}` |
| 주석 | `{#` | `#}` | `{# 렌더에 표시되지 않는 메모 #}` |

> **주의**: 표현식은 표준 Jinja 의 `{{ }}` 도, 유사 delimiter `{[ ]}` 도 아닌 **`$[ ]$`** 를 씁니다. 다른 형태로 쓰면 배포 결과에 raw 텍스트로 그대로 노출됩니다.

## 파이프라인 특성 (중요)

배포 파이프라인은 **`trim_blocks=False`** 로 동작합니다. 즉 `{% ... %}` 블록 태그 뒤의 개행이 자동으로 제거되지 **않습니다**. 로컬에서 Jinja2 를 기본 설정 (`trim_blocks=True`) 으로 테스트하면 문제 없이 렌더되지만, 배포 시 예기치 않은 빈 줄이 삽입되어 아래와 같은 문제가 생길 수 있습니다:

- **마크다운 표가 깨져서** header 만 있고 데이터 행이 `<p>` 로 분리됨
- 헤딩 다음에 원치 않는 blank line 이 여러 줄 삽입됨
- 리스트/코드블록의 경계가 어긋남

이 때문에 **모든 블록 태그에 dash whitespace 제어를 명시적으로 붙이는 습관** 이 필요합니다.

## 화이트스페이스 제어

블록 태그 앞·뒤의 공백/줄바꿈을 제거하려면 `-` 를 붙입니다.

```jinja
{%- if "gov" in build_flags -%}   ← 태그 앞·뒤 공백 모두 제거
{% if "gov" in build_flags -%}    ← 뒷쪽만 제거 (앞 공백 유지)
{%- if "gov" in build_flags %}    ← 앞쪽만 제거
```

주석에도 동일하게 적용: `{#- ... -#}` vs `{# ... #}`. 주석 자체는 어떻게 쓰든 렌더 결과에서 사라지지만, 앞뒤 공백 처리 방식이 다릅니다.

> **주의**: 연속된 blank line 이 중요한 위치 (heading 직후, 표 뒤 등) 에서는 dash 를 붙이지 마세요 — 앞뒤 공백이 지워져 heading 이 다음 요소와 붙어버립니다.

## 조건 블록

가장 자주 쓰이는 패턴입니다.

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

**표 안에서 사용할 때는 반드시 branch 사이에 `{%- ... -%}` 를 붙여야** 표가 깨지지 않습니다. `trim_blocks=False` 파이프라인에서 elif/else 태그 뒤의 개행이 살아남기 때문입니다.

```jinja
{% if "gov" in build_flags -%}
gov 문구
{%- elif "ngoic" in build_flags or "ngovc" in build_flags -%}
ngoic/ngovc 문구
{%- else -%}
그 외 문구
{% endif %}
```

- `{% if ... -%}` : 태그 뒤 개행 제거 (다음 branch 내용이 자기 줄에서 시작하게)
- `{%- elif ... -%}` / `{%- else -%}` : 이전 branch 끝의 개행과 자기 뒤 개행을 모두 제거
- `{% endif %}` : 앞 dash 없이 → 마지막 branch 뒤 개행을 보존 (표 뒤에 blank line 확보용)

### 부정 및 OR

```jinja
{% if "gov" not in build_flags %} ... {% endif %}
{% if "public" in build_flags or "gov" in build_flags -%} ... {%- endif %}
```

## 마크다운 표 안의 조건 블록

Markdown 표는 header, separator, data row 사이에 **빈 줄이 없어야** 완결됩니다. 조건 블록이 표 데이터 행을 감쌀 때는 위의 dash 규칙을 반드시 따르세요.

**나쁜 예 (표가 깨짐):**
```jinja
| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "gov" in build_flags %}
| compute | ... |
{% elif "ngoic" in build_flags %}
| compute | ... |
{% else %}
| compute | ... |
{% endif %}
```
→ `trim_blocks=False` 파이프라인에서 태그 뒤 개행이 남아 separator 와 data row 사이에 빈 줄 삽입 → 표가 header 만 남고 data 는 `<p>` 로 분리됨.

**좋은 예:**
```jinja
| 타입 | 리전 | 엔드포인트 |
|---|---|---|
{% if "gov" in build_flags -%}
| compute | ... |
{%- elif "ngoic" in build_flags -%}
| compute | ... |
{%- else -%}
| compute | ... |
{% endif %}
```

## 반복 블록 (`{% for %}`)

리스트/dict 를 순회하며 반복 렌더합니다. `{% set %}` 으로 정의한 컬렉션이나 macro 인자와 함께 조합해 씁니다.

```jinja
{%- set env = {
      "api": {
        "regions": [
          {"name": "kr1", "url": "kr1-api-instance-infrastructure.nhncloudservice.com"},
          {"name": "kr2", "url": "kr2-api-instance-infrastructure.nhncloudservice.com"},
          {"name": "kr3", "url": "kr3-api-instance-infrastructure.nhncloudservice.com"},
        ]
      }
} -%}

{% for r in env.api.regions %}$[ r.url ]$<br>{% endfor %}
```

- 표현식은 `$[ ]$` 를 씁니다 (`{{ }}` 아님). 위 예의 `$[ r.url ]$` 처럼 loop 변수 속성도 이 delimiter 로 감쌉니다.
- if 블록과 동일하게 **`trim_blocks=False`** 특성이 적용되므로, 여러 줄로 풀어 쓸 때는 dash whitespace 제어를 붙여야 예기치 않은 빈 줄이 안 생깁니다.

### 표 데이터 행을 반복할 때

각 iteration 이 표의 한 행이 되도록 `{% for ... -%}` / `{%- endfor %}` 로 감싸 태그 자체가 만든 개행을 제거하세요. 안 하면 header 와 data 사이에 빈 줄이 들어가 표가 깨집니다.

```jinja
| 리전 | 엔드포인트 |
|---|---|
{% for r in env.api.regions -%}
| $[ r.name ]$ | https://$[ r.url ]$ |
{% endfor %}
```

### 리스트 항목을 반복할 때

마크다운 리스트도 마찬가지로 `-` 를 붙여 항목 사이에 빈 줄이 들어가지 않게 합니다.

```jinja
{% for r in env.api.regions -%}
* $[ r.name ]$ — $[ r.url ]$
{% endfor %}
```

### `{% for %}` 안에서 조건 분기

`loop.first` / `loop.last` / `loop.index` 같은 loop 특수 변수와 `{% if %}` 를 조합해 첫/마지막 항목만 다르게 처리할 수 있습니다.

```jinja
{% for r in env.api.regions -%}
$[ r.url ]${% if not loop.last %}, {% endif -%}
{% endfor %}
```

## 변수 정의 (`{% set %}`)

파생 변수를 만듭니다. 여러 줄로 흩어써도 됩니다.

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

### 정의 위치

`{% set %}` 과 `{% macro %}` 는 **파일 최상단일 필요가 없습니다**. Jinja 는 파일을 위에서 아래로 처리하므로, **사용 지점보다 앞서 정의되기만 하면** 어디든 가능합니다.

| 배치 방식 | 장점 | 단점 |
|---|---|---|
| 파일 최상단 | 한눈에 파악, 여러 섹션에서 재사용 쉬움 | 파일 첫 화면이 setup 코드로 가려짐 |
| 사용 섹션 바로 앞 | 관련 있는 코드가 근처에 모여 있어 문맥이 명확 | 여러 섹션에서 쓰면 중복 정의 위험 |
| 외부 파일 + `{% include %}` | 여러 `.md` 에서 공유 가능 | 파일 하나 늘어남 |

`ko/public-api.md` 는 파일 상단의 `variant` 정의와 각 subsection 안의 host 변수/dict/macro 정의를 조합해서 씁니다.

### 마지막 `-%}` 주의

`{%- set foo = ... -%}` 처럼 뒤에 `-%}` 를 쓰면 뒤이은 **모든 공백** (여러 개의 `\n` 포함) 이 제거됩니다. 표나 heading 앞에서 이걸 쓰면 blank line 이 사라져 markdown 이 깨질 수 있습니다. 표 바로 앞의 마지막 `set` 은 `-%}` 대신 `%}` 로 닫으세요:

```jinja
{%- set hosts = { ... } %}

| 타입 | 리전 | 엔드포인트 |
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

### 자체 완결형 macro

macro 가 외부 변수 (`hosts` 같은) 에 의존하면, 다른 곳에서 그 이름을 재정의하거나 삭제하면 macro 도 영향을 받습니다. 완전히 독립시키려면 **인자만으로 결과가 나오도록** 하세요:

```jinja
{% macro api_host(region) -%}
{%- if region == "kr1" -%}$[ kr1_host ]$
{%- elif region == "kr2" -%}$[ kr2_host ]$
{%- elif region == "kr3" -%}$[ kr3_host ]$
{%- endif -%}
{%- endmacro %}
```

`ko/public-api.md` 의 "엔드포인트 (방식 1: macro)" subsection 에서 이 패턴을 사용합니다.

## `{% raw %}` — 템플릿 문법 자체를 문서에 노출

Jinja 문법을 **원문 그대로** 보여주려면 (예: 코드 펜스 안에 template 소스 예시를 넣을 때) `{% raw %}` ~ `{% endraw %}` 로 감쌉니다. 이 안의 `$[ ]$`, `{% %}`, `{# #}` 는 evaluation 되지 않고 텍스트로 출력됩니다.

````jinja
{% raw %}
```jinja
{%- set kr1_host = "..." -%}
| compute | ... | https://$[ api_host("kr1") ]$ |
```
{% endraw %}
````

렌더 결과: 위 코드 펜스 내용이 문자 그대로 문서에 노출됩니다.

## `{# #}` 주석

렌더 결과에는 나타나지 않는 작성자 메모용. `{{ }}` 나 `$[ ]$` 를 안에 써도 evaluation 되지 않으므로 문법 예시를 담기 좋습니다:

```jinja
{#
  이 섹션은 API URL 을 방식 1 (macro) 로 작성합니다: $[ api_host("kr1") ]$
  다른 방식(hosts.kr1, kr1_host)과 섞지 마세요.
#}
```

## `build_flags` 변수

배포 파이프라인이 각 build 별로 주입하는 리스트입니다. 파일 안에서 정의하지 않고, 곧바로 참조합니다.

| build_flag | 대상 build |
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
| [`ko/public-api.md`](ko/public-api.md) | 위 항목 전부 + `{% set %}` + `{% macro %}` + `$[ ]$` 표현식 + `{# #}` 주석 + `{% raw %}` |

## 빌드 오류를 부르는 함정

실제로 밟았던 함정들입니다. 새 파일을 작성하거나 include 를 도입할 때 아래를 확인하세요.

### 1. 인라인/헤딩의 bare Jinja 태그는 파싱됩니다

mkdocs-macros 는 **마크다운을 몰라서** 백틱을 존중하지 않습니다. Jinja 를 먼저 파싱하기 때문에 아래는 모두 syntax error 를 냅니다:

```markdown
## `{% set %}` 사용법           ← 값 없는 set → 파싱 에러
어떻게 `{% if %}` 를 쓰는가     ← 조건 없는 if → 파싱 에러
`{% macro %}` 를 정의합니다     ← 이름 없는 macro → 파싱 에러
`{%-` 와 `-%}` 의 차이         ← 미완성 태그 → 파싱 에러
```

**해결:** 인라인/헤딩에서 Jinja 태그를 텍스트로 언급할 때는 `{% raw %}...{% endraw %}` 로 감싸거나 아예 다른 표기로 대체하세요.

```markdown
## {% raw %}`{% set %}`{% endraw %} 사용법
```

**증상 예:** 배포 로그에 `[macros] - ERROR # _Macro Syntax Error_` 가 뜨고 페이지 전체가 렌더링되지 않습니다.

### 2. `{% raw %}` 는 중첩되지 않습니다

Jinja 규칙상 raw 블록 안에서 만나는 첫 `{% endraw %}` 가 outer raw 를 닫습니다. 그래서 raw 블록 자체를 소스 코드로 보여주는 것은 raw 로 감싸는 것만으로는 불가능합니다.

**해결 (택 1):**
- 표기용 `{% raw %}` 태그의 `{` 과 `%` 사이에 zero-width space (U+200B) 를 삽입해 파서가 태그로 인식하지 않게 한다.
- 소스 표시를 포기하고 텍스트로 설명한다.

### 3. `include-markdown` 플러그인은 raw 블록을 무시합니다

`include-markdown` 은 mkdocs-macros 와 **별개** 플러그인이며, mkdocs 의 `page_content` 이벤트에서 **원본 소스를 정규식으로 직접** 매칭합니다. 따라서 아래처럼 raw 로 감싸도 실제 include 로 파싱되어 실행됩니다:

```markdown
{% raw %}
{% include-markdown %}    ← raw 안이지만 플러그인이 매칭 → "no path" 에러
{% endraw %}
```

**증상 예:** 배포 로그에 `ERROR - Found no path passed including with 'include-markdown' directive at ...` 가 뜹니다.

**해결:** 표기용 지시자의 태그 이름 중간(예: `include-` 와 `markdown` 사이) 에 zero-width space 를 삽입해 플러그인의 정규식이 매칭되지 않게 하세요. 시각적으로는 동일하고, 실제 include 라인은 그대로 동작합니다.

**주의 — ZWSP 만으로는 부족합니다:** ZWSP 는 include-markdown 정규식만 피할 뿐, 이후에 실행되는 mkdocs-macros 는 여전히 `{%` 를 태그 시작으로 보고 `include-mar​kdown` 를 Jinja 로 파싱하려 합니다 (`include` 다음의 `-mar…` 를 subtraction 으로 잘못 해석 → syntax error). **바깥을 `{% raw %}...{% endraw %}` 로도 감싸야 합니다.** 즉 include-markdown 회피용 ZWSP + macros 회피용 raw 블록, 두 가지를 함께 적용해야 안전합니다.

```markdown
{% raw %}
{% include-mar​kdown './target.md' %}
{% endraw %}
```

### 4. include 대상 파일의 오류는 상위 페이지의 오류로 표시됩니다

include 된 파일의 Jinja 문법 오류는 **include 를 수행하는 상위 파일** 의 에러로 로그에 나타납니다. `Open Source/agent-test/ko/mkdocs-syntax.md` 에서 에러가 났다고 해서 반드시 그 파일이 원인은 아닙니다. include 대상 (`nfw-console-guide.md`, `deploy-api-guide.md`, `compute-public-api.md` 등) 부터 함께 살펴보세요.

## 로컬 검증 방법

로컬에서는 Python + Jinja2 로 렌더링해 결과를 확인합니다. 커스텀 delimiter 를 지정하는 것이 핵심.

**두 모드 모두 검증** 하세요. 배포 파이프라인은 `trim_blocks=False` 로 동작하므로, `trim_blocks=True` 로만 테스트하면 배포 시 표가 깨지는 등의 문제가 잡히지 않습니다.

```python
import jinja2

for trim in (True, False):
    env = jinja2.Environment(
        variable_start_string='$[',
        variable_end_string=']$',
        keep_trailing_newline=True,
        trim_blocks=trim,   # 배포 파이프라인은 False
    )
    tpl = env.from_string(open('ko/public-api.md').read())
    for flags in [[], ['gov'], ['ngoic']]:
        out = tpl.render(build_flags=flags)
        # 표 렌더 결과 등을 눈으로 확인
```

## 배포 확인

이 저장소는 https://docs.alpha-nhncloud.com/ko/Open%20Source/agent-test/ 로 배포됩니다. 배포는 커밋 후 최대 **20분 정도** 걸릴 수 있습니다. 새로 문법을 도입한 뒤에는 배포 페이지에서 다음을 확인하세요:

- Raw 템플릿 텍스트 (`$[`, `{%`, `{#`) 가 code fence 바깥에 노출되지 않았는지
- 마크다운 표가 header + data 모두 완결되어 렌더되는지
- 조건에 따라 다른 build 에서 원치 않는 빈 줄이 삽입되지 않았는지

배포된 원본 HTML 을 `curl` 로 받아 검사하면 문제를 정확히 짚을 수 있습니다:

```bash
curl -s -H 'Cache-Control: no-cache' \
  "https://docs.alpha-nhncloud.com/ko/Open%20Source/agent-test/ko/public-api/?nocache=$(date +%s)" \
  | grep -c '<td></td>'   # 표에 빈 셀이 몇 개인지 (0 이면 정상)
```
