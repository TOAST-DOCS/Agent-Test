# Markup lint sample

`pre-align/fix_markup.py` 데모용 픽스처. 아래 각 절은 린터가 **무엇을 고치고 무엇을
그대로 두는지** 보여준다. 판정은 사이트와 같은 python-markdown 으로 이 문단들을 렌더한
뒤, 독자 눈에 `**` 나 `](` 가 남는지로만 한다.

## 1. M1 — 링크 라벨의 escaped 대괄호 (자동 수정)

`\]` 가 라벨을 닫지 못해 링크가 아예 만들어지지 않는다. 독자는 대괄호와 URL 을 본문
그대로 본다.

* See the [console guide](./console-guide.md) for the console walkthrough.
* See the [Kubernetes documentation](https://kubernetes.io/docs/home/) for how to write **Manifest**.

## 2. M2 — `**` 강조 안쪽의 공백 (자동 수정)

여는 `**` 뒤 또는 닫는 `**` 앞에 공백이 있으면 강조로 짝지어지지 않아 별표가 그대로
보인다.

* You can modify only templates in **Approval/Return** state.
* Click **+ Add** to enter HTTP headers.
* Default of **Monthly Delivery Count** is 1,000 per month.
* You can set the **Start Condition** and **End Condition** of **Artifact**.

**User**

## 3. 고치면 안 되는 것 — 정상 렌더 (변경 없음)

손으로 쓴 CommonMark 모델이 오탐했던 모양들. 실제 렌더러는 전부 정상 처리한다.

* **삭제** 대화 상자가 나타나면 **확인** 버튼을 클릭합니다.
* x** Y**z
* **a****b**
* **설정**을 누릅니다.
* **パス変数**は**{variable}**、下位パスを含むパス変数は**{variable+}**と宣言できます。

저자가 일부러 이스케이프한 것도 건드리지 않는다.

* Write \[label\](url) to show link syntax.
* Use \*\*bold\*\* syntax for emphasis.

## 4. M3 — 렌더에 마크업이 남지만 자동 수정 없음 (보고만)

이 절의 별표는 **글자**다. 고치면 문서 내용이 사라지므로 린터는 보고만 하고 파일은
건드리지 않는다.

| Pattern | Description | Match |
| --- | --- | --- |
| * : path/* | Matches any character except the delimiter `/`. | path/hello-world(Y) |
| ** : path/** | Matches all characters. | path/my/hello-world(Y) |

* 예) 주민번호 뒤 6자리는 000000-0****** 처럼 마스킹합니다.
* 예) /v1.0/appkeys/**{appKey}**/**

## 5. 코드 블록 안 (변경 없음)

```
** X** inside a fence stays a code sample
[label\](url) too
```

    ** X** in an indented code block as well
