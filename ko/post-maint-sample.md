<!-- pre-align:aligned sig=e2epostmaint1 -->

<a id="pm-intro"></a>
## 번역 PR 문서 정비 샘플 { #pm-intro }

이 문서는 번역 PR 문서 정비(`--post-maint`)를 검증하는 픽스처입니다.
ko PR 은 이 문단의 문장 한 줄만 바꿉니다.

<a id="pm-markup"></a>
## 마크업 결함 { #pm-markup }

자세한 내용은 [API 가이드\](https://docs.example.com/api/)를 참고하세요.

<a id="pm-stub"></a>
## 본문이 빈 섹션 { #pm-stub }

인스턴스를 생성하면 상태가 **실행 중** 으로 바뀔 때까지 몇 분이 걸릴 수 있습니다.

<a id="pm-table"></a>
## 행이 빠진 표 { #pm-table }

| 이름 | 타입 | 설명 |
|---|---|---|
| appKey | String | 앱키 |
| secretKey | String | 보안 키 |
| region | String | 리전 코드 |

<a id="pm-jinja"></a>
## 템플릿 태그 { #pm-jinja }

{% if "gov" in build_flags %}
공공 환경에서는 콘솔 메뉴 이름이 다릅니다.
{% endif %}

<a id="pm-tail"></a>
## 마지막 섹션 { #pm-tail }

이 섹션은 어떤 정비에서도 바이트 단위로 보존되어야 합니다.
