<!-- pre-align:aligned sig=e2e0f1e1d01 -->

<a id="tnk"></a>
# 표 첫 열 키 e2e 픽스처

이 문서는 자동 생성된 e2e 픽스처입니다 (20260928-053041).

<a id="tnk-overview"></a>
## 개요 { #tnk-overview }

메시지 조회 API의 응답 필드와 오류 코드를 설명합니다.

<a id="tnk-t1"></a>
## 중첩 필드 { #tnk-t1 }

| 이름 |	타입|	설명|
|---|---|---|
|header|	Object|	헤더 영역|
|- resultCode|	Integer|	결과 코드|
|- resultMessage|	String| 결과 메시지|
|- isSuccessful|	Boolean| 성공 여부|
|messageSearchResultResponse|	Object|	본문 영역|
|- messages | List |	메시지 리스트 |
|-- requestId | String |	요청 ID |
|-- plusFriendId | String |	플러스친구 ID |
|-- senderKey | String |	발신 키 |
|-- recipientNo | String |	수신 번호 |
|-- resultCode | String |	수신 결과 코드 |
|- totalCount | Integer | 총개수 |

<a id="tnk-t2"></a>
## 오류 코드 { #tnk-t2 }

| resultCode | resultMessage | 설명 |
| --- | --- | --- |
|-40000| InvalidParam | 파라미터에 오류가 있음 |
|-40010| InvalidGroupID | 그룹 아이디 오류 |
|-40020| DuplicatedGroupID | 중복된 그룹 아이디 |
|-40070| ServiceQuotaExceededException | 생성할 수 있는 최대 그룹 개수 초과 |
|-41000| UnauthorizedAppKey | 승인되지 않은 앱키 |
|-50000| InternalServerError | 서버 오류 |

<a id="tnk-t3"></a>
## 라이브러리 { #tnk-t3 }

| 라이브러리       | 용도                            |
| ---------------- | ------------------------------- |
| ZeroMQ           | 서버의 IPC                      |
| Netty            | 서버-클라이언트 통신            |
| Protocol Buffers | 서버-클라이언트 메시지 직렬화   |

<a id="tnk-t4"></a>
## 오류 이름 { #tnk-t4 }

| Error | Error Code | Description |
| --- | --- | --- |
| NOT\_INITIALIZED | 1 | Gamebase가 초기화되어 있지 않습니다. |
| NOT\_LOGGED_IN | 2 | 로그인이 필요합니다. (Standalone에 한함) |
| UI\_TERMS\_UNREGISTERED\_SEQ | 6923 | 등록되지 않은 약관 Seq 값을 설정하였습니다. |
| UI\_TERMS\_ALREADY\_IN\_PROGRESS\_ERROR | 6924 | Terms API 호출이 아직 완료되지 않았습니다.<br/>잠시 후 다시 시도하세요. |

<a id="tnk-c1"></a>
## 설정 항목 { #tnk-c1 }

| 항목 | 설명 |
| --- | --- |
| 알림 설정 | 알림을 받을 채널을 선택합니다. |
| 수신 대상 | 알림을 받을 멤버를 지정합니다. |
| 발송 시간 | 알림을 보낼 시간대를 설정합니다. |
| 보관 기간 | 발송 이력을 보관할 기간입니다. |

<a id="tnk-c2"></a>
## 템플릿 필드 { #tnk-c2 }

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| header.isSuccessful | Boolean | 성공 여부 |
| header.resultCode | Integer | 결과 코드 |
| body.data.templateId | String | 템플릿 ID |
| body.data.templateName | String | 템플릿 이름 |
