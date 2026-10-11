<!-- machine_translated: true -->

<!-- pre-align:aligned sig=e2e0c3117a1 -->

<a id="tcm"></a>
# table-cell-mirror e2e fixture

This document is a generated e2e fixture (20261011-225551).

<a id="tcm-response"></a>
## Response { #tcm-response }

Fields of the API response body.

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| header.isSuccessful | Boolean | Y | Whether successful |
| header.resultCode | Integer | Y | Result code |
| header.resultMessage | String | Y | Result message |
| body.id | String | N | Resource ID |
| body.name | String | N | Resource name |
| body.createdAt | DateTime | N | Created date and time |

<a id="tcm-request"></a>
## Request { #tcm-request }

Request headers and parameters.

| In | Name | Type | Required | Description |
| --- | --- | --- | --- | --- |
| Header | X-Auth-Token | String | Y | Issued token |
| Path | appKey | String | Y | Appkey |
| Query | pageNum | Integer | N | Page number |
| Query | pageSize | Integer | N | Page size |

<a id="tcm-partial"></a>
## Partial Edit { #tcm-partial }

Fields that specify a label.

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| labelKey | String | Y | Label key (Max. 64 characters, English letters and numbers only) |
| labelValue | String | N | Label value |

<a id="tcm-control"></a>
## Control { #tcm-control }

Specifies the location of the resource.

| Name | Required | Description |
| --- | --- | --- |
| region | Required | Region code |
| zone | Required | Availability Zone |
