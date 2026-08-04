# mkdocs 문법 가이드

https://mkdocs-macros-plugin.readthedocs.io/en/latest/pages/

# include

`include-mar​kdown` 지시자로 다른 마크다운 파일을 현재 페이지에 삽입할 수 있습니다. 아래 세 절(`nfw`, `deploy`, `compute-instance`)이 실제 include 결과입니다.

`include-markdown` 플러그인은 mkdocs-macros 의 raw 블록을 무시하고 원본 소스에서 지시자를 직접 매칭하므로, 아래 예시는 태그 이름 중간에 zero-width space 를 삽입해 파서가 매칭하지 못하도록 표기했습니다.

**소스**

```jinja
{% include-mar​kdown './nfw-console-guide.md' %}

{% include-mar​kdown './deploy-api-guide.md' %}

{% include-mar​kdown './compute-public-api.md' %}
```

**렌더링 결과**: 아래 세 절

# nfw
{% include-markdown './nfw-console-guide.md' %}

# deploy
{% include-markdown './deploy-api-guide.md' %}

# compute-instance
{% include-markdown './compute-public-api.md' %}
