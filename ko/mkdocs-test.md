# mkdocs 문법 가이드

## 테스트

## build_flags 분기 예제

- Code: [ko/mkdocs-test.md](https://github.com/TOAST-DOCS/Agent-Test/blob/alpha/ko/mkdocs-test.md)

{% if 'ngsc' in build_flags %}
이 문단은 **ngsc** 빌드에서만 노출됩니다. NHN Government Secure Cloud 환경 전용 안내입니다.
{% else %}
이 문단은 **public** 빌드에서 노출됩니다. NHN Cloud public 환경 전용 안내입니다.
{% endif %}

| 항목 | 값 |
| --- | --- |
| 빌드 종류 | {% if 'ngsc' in build_flags %}ngsc{% else %}public{% endif %} |
| 콘솔 URL | {% if 'ngsc' in build_flags %}https://console.gov-nhncloud.com{% else %}https://console.nhncloud.com{% endif %} |

## build_flags 분기 예제 (include 방식)

분기별 내용을 별도 파일(`mkdocs-test-public.md`, `mkdocs-test-ngsc.md`)로 분리하고, `build_flags` 에 따라 다른 파일을 include 합니다.

- Code: [ko/mkdocs-test.md](https://github.com/TOAST-DOCS/Agent-Test/blob/alpha/ko/mkdocs-test.md)
- Code: [ko/mkdocs-test-public.md](https://github.com/TOAST-DOCS/Agent-Test/blob/alpha/ko/mkdocs-test-public.md)
- Code: [ko/mkdocs-test-ngsc.md](https://github.com/TOAST-DOCS/Agent-Test/blob/alpha/ko/mkdocs-test-ngsc.md)

{% if 'ngsc' in build_flags %}
{% include-markdown './mkdocs-test-ngsc.md' %}
{% else %}
{% include-markdown './mkdocs-test-public.md' %}
{% endif %}


