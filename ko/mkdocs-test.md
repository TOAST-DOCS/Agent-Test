# mkdocs 문법 가이드

## 테스트

## build_flags 분기 예제

{% if 'ngsc' in build_flags %}
{% include-markdown './mkdocs-test-ngsc.md' %}
{% else %}
{% include-markdown './mkdocs-test-public.md' %}
{% endif %}


