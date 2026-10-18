<!-- machine_translated: true -->

<!-- pre-align:aligned sig=e2e09e4r0w -->

<a id="tor"></a>
# table-open-row e2e fixture

This document is a generated e2e fixture (20261018-122611).

<a id="tor-last"></a>
## Authentication Response { #tor-last }

Fields of the authentication registration response.

| Name | Type | Required | Description |
|------------ | ------------- | ----- | ------------ |
|   authId | String| N | Internally managed authentication method ID |
|   userAccessKeyID | String| N | User Access Key ID |
|   secretAccessKey | String| N | Secret key |
|   tokenExpiryPeriod | Long| N | Token expiration period (in seconds) |

|   tokenFormatCode | String| N | Token format code (OPAQUE, JWT) |


<a id="tor-mid"></a>
## Project Response { #tor-mid }

Fields of the project query response.

| Name | Type | Required | Description |
|------------ | ------------- | ----- | ------------ |
|   projectId | String| No | Project ID |
|   projectName | String| No | Project name displayed in the Console

|   ownerUuid | String| No | Project owner UUID |
|   regDatetime | Date| No | Date and time of creation |


<a id="tor-closed"></a>
## Member Response { #tor-closed }

Fields of the member query response.

| Name | Type | Required | Description |
|------------ | ------------- | ----- | ------------ |
|   uuid | String| No | Member UUID |
|   name | String| No | Member name |
|   emailAddress | String| No | Member email address |
|   joinYmdt | Date| No | Date and time of joining |

