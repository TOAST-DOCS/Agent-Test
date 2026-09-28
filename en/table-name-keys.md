<!-- machine_translated: true -->

<!-- pre-align:aligned sig=e2e0f1e1d01 -->

<a id="tnk"></a>
# Table first-column key e2e fixture

This document is a generated e2e fixture (20260928-053041).

<a id="tnk-overview"></a>
## Overview { #tnk-overview }

This document describes the response fields returned by the message query API and the error codes when a request fails.

<a id="tnk-t1"></a>
## Nested Fields { #tnk-t1 }

| Value | Type | Description |
| --- | --- | --- |
| header | Object | Header area |
| - resultCode | Integer | Result code |
| - resultMessage | String | Result message |
| - isSuccessful | Boolean | Successful or not |
| messageSearchResultResponse | Object | Body area |
| - messages | List | Message list |
| -- requestId | String | Request ID |
| -- plusFriendId | String | Plus Friend ID |
| -- senderKey | String | Sender key |
|-- recipientNo | String |	Recipient number |
| -- resultCode | String | Receiving result code |
| - totalCount | Integer | Total count |

<a id="tnk-t2"></a>
## Error Codes { #tnk-t2 }

| resultCode | resultMessage | Description |
| --- | --- | --- |
|-40000| InvalidParam | The parameter contains an error |
|-40010| InvalidGroupID | Group ID error |
|-40020| DuplicatedGroupID | Duplicate group ID |
|-40070| ServiceQuotaExceededException | Exceeded the maximum number of groups you can create |
|-41000| UnauthorizedAppKey | Unauthorized Appkey |
|-50000| InternalServerError | Server error |

<a id="tnk-t3"></a>
## Libraries { #tnk-t3 }

| Library       | Usage                            |
| ---------------- | ------------------------------- |
| ZeroMQ           | Server's IPC                      |
| Netty            | Communication between server and client            |
| Protocol Buffers | Parallelization of messages between server and client   |

<a id="tnk-t4"></a>
## Error Names { #tnk-t4 }

| Error | Error Code | Description |
| --- | --- | --- |
| NOT\_INITIALIZED | 1 | Gamebase not initialized. |
| NOT\_LOGGED\_IN | 2 | Login is required. (Only Standalone) |
| UI\_TERMS\_UNREGISTERED\_SEQ | 6923 | The unregistered terms Seq value has been set. |
| UI\_TERMS\_ALREADY\_IN\_PROGRESS\_ERROR | 6924 | The Terms API call has not been completed yet.<br/>Please try again later. |

<a id="tnk-c1"></a>
## Settings { #tnk-c1 }

| Item | Description |
| --- | --- |
| Notification settings | Select the channel to receive notifications. |
| Recipients | Specify the members who receive notifications. |
| Delivery time | Set the time period for sending notifications. |
| Retention period | Period to keep the delivery history. |

<a id="tnk-c2"></a>
## Template Fields { #tnk-c2 }

| Name | Type | Description |
| --- | --- | --- |
| header.isSuccessful | Boolean | Whether successful |
| header.resultCode | Integer | Result code |
| body.data.templateId | String | Template ID |
| body.data.templateName | String | Template name |
