# 끊긴 셀 표 샘플

<a id="fix-tables-split-sample"></a>
## 끊긴 셀 표 샘플 { #fix-tables-split-sample }

이 문서는 깨진 표 정비가 **번역본 쪽에서 셀이 두 줄로 끊긴 표**를 다루는 방식을 재는 픽스처입니다.

<a id="fix-tables-split-cell"></a>
## 셀이 끊긴 표 { #fix-tables-split-cell }

콜백 메서드를 정리하면 다음 표와 같습니다.

| 콜백 이름 | 의미 | 설명 |
|----------|------|------|
| onMatch | 매치 요청 처리 | 사용자가 직접 매치 요청을 처리합니다.<br>즉, 최소한의 요청을 모아 정원에 맞춰 매칭합니다. |
| onRefill | 매치 리필 요청 처리 | 매칭된 방에서 누군가 나갈 때 새 유저를 채웁니다. |

<a id="fix-tables-split-tail"></a>
## 마지막 섹션 { #fix-tables-split-tail }

| 이름 | 값 |
|------|----|
| `TIMEOUT` | -1 |
| `SUCCESS` | 0 |
