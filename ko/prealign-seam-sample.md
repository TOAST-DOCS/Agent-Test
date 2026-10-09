# 정렬 이음매 샘플

<a id="seam-overview"></a>
## 개요

pre-align 이 절을 새로 맞붙이는 자리(이음매)를 재는 픽스처입니다. cloud-translate#1249 재현용.

<a id="seam-glued-control"></a>
## 붙은 heading 대조군

번역본에서는 이 절의 표 바로 아래에 다음 절의 앵커가 빈 줄 없이 붙어 있습니다. 원래 이웃이므로 정렬이 고치지 않아야 합니다.

| 이름 | 설명 |
| --- | --- |
| alpha | 첫 번째 값 |

<a id="seam-glued-next"></a>
## 붙은 다음 절

대조군 본문입니다.

<a id="seam-middle-missing"></a>
## 중간 누락 절

번역본에 없는 중간 절입니다. 앞 절이 빈 줄로 끝나므로 수정 전후가 같아야 합니다.

<a id="seam-table-last"></a>
## 표로 끝나는 절

번역본에서는 이 절이 문서의 마지막이고 표의 마지막 행으로 끝납니다.

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| totalCount | Integer | 전체 개수 |

<a id="seam-missing-last"></a>
## 마지막 누락 절

번역본에 없는 마지막 절입니다. 이 절의 stub 이 표 바로 아래에 붙으면 heading 이 표의 셀이 됩니다.
