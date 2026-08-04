# mkdocs 문법 가이드

https://mkdocs-macros-plugin.readthedocs.io/en/latest/pages/

# include

`include-mar​kdown` 지시자로 다른 마크다운 파일을 현재 페이지에 삽입할 수 있습니다. 아래 세 절(`nfw`, `deploy`, `compute-instance`)이 실제 include 결과입니다.

`include-markdown` 플러그인은 mkdocs-macros 의 raw 블록을 무시하고 원본 소스에서 지시자를 직접 매칭합니다. 반대로 mkdocs-macros 는 raw 블록을 존중하지만 ZWSP 가 섞인 태그도 여전히 Jinja 로 파싱하려 합니다. 그래서 아래 예시는 **바깥에 `{% raw %}` 로 감싸고 (macros 회피)**, **태그 이름 중간에 zero-width space 를 넣어 (include-markdown 회피)** 두 가지 처리를 모두 적용했습니다.

**소스**

{% raw %}
```jinja
{% include-mar​kdown './nfw-console-guide.md' %}

{% include-mar​kdown './deploy-api-guide.md' %}

{% include-mar​kdown './compute-public-api.md' %}
```
{% endraw %}

**렌더링 결과**: 아래 세 절

# 기본 문법

{% include-markdown './nfw-console-guide.md' %}

# Sample: api url 을 변수화

{% include-markdown './deploy-api-guide.md' %}

# Sample: 분기 처리 방식 2가지

{% include-markdown './compute-public-api.md' %}

