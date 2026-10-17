<a id="mkdocs-followup-control"></a>
## Sample > 정상 매크로 { #mkdocs-followup-control }

{% include-markdown './mkdocs-followup-vars.md' %}

{% if "gov" in build_flags %}
정부망 환경에서는 담당자에게 발급 절차를 문의합니다.
{% else %}
공용 환경에서는 콘솔 `$[ portal_url ]$` 에서 설정합니다.
{% endif %}

| 구분 | 주소 |
| --- | --- |
| 콘솔 | `$[ portal_url ]$` |
| API | `$[ api_base ]$` |
