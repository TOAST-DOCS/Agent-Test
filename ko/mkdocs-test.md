# mkdocs 문법 가이드

## 테스트

## build_flags 분기 예제

{% if 'ngsc' in build_flags %}
이 문단은 **ngsc** 빌드에서만 노출됩니다. NHN Government Secure Cloud 환경 전용 안내입니다.
{% else %}
이 문단은 **public** 빌드에서 노출됩니다. NHN Cloud public 환경 전용 안내입니다.
{% endif %}

| 항목 | 값 |
| --- | --- |
| 빌드 종류 | {% if 'ngsc' in build_flags %}ngsc{% else %}public{% endif %} |
| 콘솔 URL | {% if 'ngsc' in build_flags %}https://console.gov-nhncloud.com{% else %}https://console.nhncloud.com{% endif %} |


