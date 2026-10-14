<!-- pre-align:aligned sig=e2e0c3117a1 -->

<a id="tcm"></a>
# table-cell-mirror e2e fixture

This document is a generated e2e fixture (20261014-104221).

<a id="tcm-response"></a>
## Response { #tcm-response }

Fields of the API response body.

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| header.isSuccessful | Boolean | Yes | Whether successful |
| header.resultCode | Integer | Yes | Result code |
| header.resultMessage | String | Yes | Result message |
| body.id | String | No | Resource ID |
| body.name | String | No | Resource name |
| body.createdAt | DateTime | No | Created date and time |

<a id="tcm-request"></a>
## Request { #tcm-request }

Request headers and parameters.

| In | Name | Type | Required | Description |
| --- | --- | --- | --- | --- |
| Header | X-Auth-Token | String | Yes | Issued token |
| Path | appKey | String | Yes | Appkey |
| Query | pageNum | Integer | No | Page number |
| Query | pageSize | Integer | No | Page size |

<a id="tcm-partial"></a>
## Partial Edit { #tcm-partial }

Fields that specify a label.

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| labelKey | String | Yes | Label key |
| labelValue | String | No | Label value |

<a id="tcm-control"></a>
## Control { #tcm-control }

Specifies the location of the resource.

| Name | Required | Description |
| --- | --- | --- |
| region | Required | Region code |
| zone | Optional | Availability zone |
