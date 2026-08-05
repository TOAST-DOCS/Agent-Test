<a id="security-network-firewall"></a>
## Security > Network Firewall > 콘솔 사용 가이드 { #security-network-firewall }

mkdocs / Jinja 조건문 문법 데모용 문서입니다. 각 절은 소스 코드와 렌더링 결과를 함께 보여 줍니다.

{% if "gov" in build_flags -%}
<br>

{% endif -%}
<a id="raw-if-endraw-raw-endif-endraw"></a>
## 1. 블록 조건문 ({% raw %}`{% if %}`{% endraw %} ~ {% raw %}`{% endif %}`{% endraw %}) { #raw-if-endraw-raw-endif-endraw }

**소스**

{% raw %}
```jinja
{% if "gov" not in build_flags %}
[gov 빌드가 아닌 경우에만 표시되는 문단]

* 일반 공용 문서에서만 노출됩니다.

{% endif %}
```
{% endraw %}

**렌더링 결과**

{% if "gov" not in build_flags %}
[gov 빌드가 아닌 경우에만 표시되는 문단]

* 일반 공용 문서에서만 노출됩니다.

{% endif %}
<a id="if-else"></a>
## 2. 리스트 내부 if / else 분기 { #if-else }

**소스**

{% raw %}
```jinja
* 2개의 프로젝트
{%- if "gov" in build_flags %}
* 2개의 VPC(각 프로젝트에 Hub VPC, Spoke VPC)
{%- else %}
* 2개의 VPC(각각 프로젝트에 Hub VPC, Spoke VPC)
{%- endif %}
* Hub VPC 내 3개의 서브넷
```
{% endraw %}

**렌더링 결과**

* 2개의 프로젝트
{%- if "gov" in build_flags %}
* 2개의 VPC(각 프로젝트에 Hub VPC, Spoke VPC)
{%- else %}
* 2개의 VPC(각각 프로젝트에 Hub VPC, Spoke VPC)
{%- endif %}
* Hub VPC 내 3개의 서브넷

<a id="section-1"></a>
## 3. 인용문 내부 조건문 { #section-1 }

**소스**

{% raw %}
```jinja
> [참고]
>
> * 공통으로 노출되는 항목입니다.
{%- if "gov" in build_flags %}
> * gov 빌드에서만 노출되는 항목입니다.
{%- endif %}
> * 다시 공통 항목입니다.
```
{% endraw %}

**렌더링 결과**

> [참고]
>
> * 공통으로 노출되는 항목입니다.
{%- if "gov" in build_flags %}
> * gov 빌드에서만 노출되는 항목입니다.
{%- endif %}
> * 다시 공통 항목입니다.

<a id="if-else-2"></a>
## 4. 이미지 if / else 분기 { #if-else-2 }

**소스**

{% raw %}
```jinja
{% if "gov" in build_flags -%}
![gov_image](https://example.com/gov.png)
{%- else -%}
![public_image](https://example.com/public.png)
{%- endif %}
```
{% endraw %}

**렌더링 결과**

{% if "gov" in build_flags -%}
![gov_image](https://example.com/gov.png)
{%- else -%}
![public_image](https://example.com/public.png)
{%- endif %}

<a id="or"></a>
## 5. or 연산자 { #or }

**소스**

{% raw %}
```jinja
{% if "public" in build_flags or "gov" in build_flags -%}
public 또는 gov 빌드에서만 노출되는 섹션입니다.
{% endif -%}
```
{% endraw %}

**렌더링 결과**

{% if "public" in build_flags or "gov" in build_flags -%}
public 또는 gov 빌드에서만 노출되는 섹션입니다.
{% endif -%}

<a id="raw---endraw-raw---endraw"></a>
## 6. 공백 제어 ({% raw %}`{%-`{% endraw %}, {% raw %}`-%}`{% endraw %}) 비교 { #raw---endraw-raw---endraw }

아래 두 블록은 whitespace trim 여부만 다릅니다.

**소스**

{% raw %}
```jinja
{% if "gov" in build_flags %}
trim 없이 렌더링되어 위·아래에 빈 줄이 남습니다.
{% endif %}

{%- if "gov" in build_flags -%}
trim 적용으로 위·아래 빈 줄이 제거됩니다.
{%- endif -%}
```
{% endraw %}

**렌더링 결과**

{% if "gov" in build_flags %}
trim 없이 렌더링되어 위·아래에 빈 줄이 남습니다.
{% endif %}

{%- if "gov" in build_flags -%}
trim 적용으로 위·아래 빈 줄이 제거됩니다.
{%- endif -%}



<a id="for-endfor"></a>
## 7. 반복 구문 ({% raw %}`{% for %}`{% endraw %} ~ {% raw %}`{% endfor %}`{% endraw %}) { #for-endfor }

{%- set env = {
      "api": {
        "regions": [
          {"name": "kr1", "url": "kr1-api-instance-infrastructure.nhncloudservice.com"},
          {"name": "kr2", "url": "kr2-api-instance-infrastructure.nhncloudservice.com"},
          {"name": "kr3", "url": "kr3-api-instance-infrastructure.nhncloudservice.com"},
        ]
      }
} -%}

**소스**

{% raw %}
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
{% endraw %}

**렌더링 결과**

{% for r in env.api.regions %}$[ r.url ]$<br>{% endfor %}

<a id="section-2"></a>
## 제목 분기 { #section-2 }


{% if "public" in build_flags %}
<a id="public"></a>
### public 제목 { #public }
{% endif %}

{% if "gov" in build_flags %}
<a id="gov"></a>
### gov 제목 { #gov }
{% endif %}

본문은 동일합니다.
