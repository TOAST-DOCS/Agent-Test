<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > 매크로 태그 모양 모음 { #sample-macro-shapes }

이 문서는 mkdocs-macros 템플릿 태그가 번역을 거쳐도 한 글자도 변하지 않는지 검증하기 위한 픽스처입니다. Storage-Object-Storage의 `ja/acl-guide.md` 가 태그 한 줄을 잃어 alpha 빌드를 깨뜨린 사고(2026-09-07)에서 나온 모양들을 한곳에 모았습니다. 태그는 제어 문법이라 번역 대상이 아니고, 하나라도 유실되면 짝이 어긋나 `_Macro Syntax Error_` 로 빌드 전체가 실패합니다. (본문 수정 테스트: 이 문장은 번역 재실행 시 반영되어야 합니다.)

<a id="wrapped-paragraph"></a>
### 문단을 감싼 조건부 { #wrapped-paragraph }

{% if "gov" not in build_flags %}
공용 환경에서는 콘솔에서 곧바로 설정할 수 있습니다. 이 문단은 여는 태그가 바로 위에 붙어 있어 증분 번역에서 태그와 한 유닛이 됩니다. 사고가 난 모양이 정확히 이것입니다.
{% endif %}
<br>

<a id="inline-condition"></a>
### 한 줄 안의 조건부 { #inline-condition }

{% if "gov" not in build_flags %}포털 주소는 `$[ portal_url ]$` 이며, 이 문장은 여는 태그와 닫는 태그가 같은 줄에 있습니다.{% endif %}

<a id="wrapped-example"></a>
### 예시 블록을 감싼 조건부 { #wrapped-example }

{% if "gov" not in build_flags %}
아래 예시는 조건부 블록 안에 `<details>` 와 코드 펜스가 함께 들어 있습니다. 태그 보호와 펜스 보호가 같은 유닛에서 겹치는 경우입니다.

<details>
<summary>토큰 발급 요청 예시</summary>

```
$ curl -X POST \
  -H 'Content-Type: application/json' \
  $[ portal_url ]$/v2/tokens
```
</details>

{% endif %}
<a id="variable-table"></a>
### 표 안의 변수 치환 { #variable-table }

| 구분 | 주소 | 비고 |
|---|---|---|
| 콘솔 | `$[ portal_url ]$` | 환경에 따라 달라집니다<br>표 행 안에서도 치환됩니다 |
| API | `$[ portal_url ]$/v2` | 버전 경로가 붙습니다 |

<a id="branch-both-ways"></a>
### 양쪽 분기 { #branch-both-ways }

{% if "gov" in build_flags %}
정부망 환경에서는 담당자에게 발급 절차를 문의해야 합니다.
{% else %}
공용 환경에서는 콘솔에서 직접 발급할 수 있습니다.
{% endif %}
