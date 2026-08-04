## Security > Network Firewall > 콘솔 사용 가이드

mkdocs / Jinja 조건문 문법 데모용 문서입니다.

{% if "gov" in build_flags -%}
<br>

{% endif -%}
## 블록 조건문 ({% raw %}`{% if %}`{% endraw %} ~ {% raw %}`{% endif %}`{% endraw %})

기본 조건문으로 특정 build_flag 에서만 노출되는 섹션을 구성합니다.

{% if "gov" not in build_flags %}
[gov 빌드가 아닌 경우에만 표시되는 문단]

* 일반 공용 문서에서만 노출됩니다.

{% endif %}
## 리스트 내부 if / else 분기

* 2개의 프로젝트
{%- if "gov" in build_flags %}
* 2개의 VPC(각 프로젝트에 Hub VPC, Spoke VPC)
{%- else %}
* 2개의 VPC(각각 프로젝트에 Hub VPC, Spoke VPC)
{%- endif %}
* Hub VPC 내 3개의 서브넷

## 인용문 내부 조건문

> [참고]
>
> * 공통으로 노출되는 항목입니다.
{%- if "gov" in build_flags %}
> * gov 빌드에서만 노출되는 항목입니다.
{%- endif %}
> * 다시 공통 항목입니다.

## 이미지 if / else 분기

{% if "gov" in build_flags -%}
![gov_image](https://example.com/gov.png)
{%- else -%}
![public_image](https://example.com/public.png)
{%- endif %}

## or 연산자

{% if "public" in build_flags or "gov" in build_flags -%}
public 또는 gov 빌드에서만 노출되는 섹션입니다.
{% endif -%}

## 공백 제어 ({% raw %}`{%-`{% endraw %}, {% raw %}`-%}`{% endraw %}) 비교

아래 두 블록은 whitespace trim 여부만 다릅니다.

{% if "gov" in build_flags %}
trim 없이 렌더링되어 위·아래에 빈 줄이 남습니다.
{% endif %}

{%- if "gov" in build_flags -%}
trim 적용으로 위·아래 빈 줄이 제거됩니다.
{%- endif -%}
