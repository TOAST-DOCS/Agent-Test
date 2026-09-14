<a id="mkdocs-followup-syntax"></a>
## Sample > 짝을 잃은 조건부 { #mkdocs-followup-syntax }

이 문서는 조건부 태그의 닫는 짝이 사라진 경우를 재현합니다.

{% if "gov" not in build_flags %}
공용 환경에서는 콘솔에서 곧바로 설정할 수 있습니다.

닫는 태그가 없어 이 문서 한 장이 아니라 가이드 전체 빌드가 멈춥니다.
