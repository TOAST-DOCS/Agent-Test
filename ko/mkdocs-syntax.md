# mkdocs 문법 가이드

https://mkdocs-macros-plugin.readthedocs.io/en/latest/pages/

# include

`{% raw %}{% include-markdown %}{% endraw %}` 지시자로 다른 마크다운 파일을 현재 페이지에 삽입할 수 있습니다. 아래 세 절(`nfw`, `deploy`, `compute-instance`)이 실제 include 결과입니다.

**소스**

{% raw %}
```jinja
{% include-markdown './nfw-console-guide.md' %}

{% include-markdown './deploy-api-guide.md' %}

{% include-markdown './compute-public-api.md' %}
```
{% endraw %}

**렌더링 결과**: 아래 세 절

# nfw
{% include-markdown './nfw-console-guide.md' %}

# deploy
{% include-markdown './deploy-api-guide.md' %}

# compute-instance
{% include-markdown './compute-public-api.md' %}
