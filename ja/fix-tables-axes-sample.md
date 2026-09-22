<!-- pre-align:aligned sig=fxaxes000000 -->

<a id="fxaxes-sample"></a>
## 検出軸フィクスチャー { #fxaxes-sample }

A fixture contrasting the detection axes of fix-tables (identifier / row count / column count). Not registered in `ko/nav.yml`.

<a id="fxaxes-rows"></a>
## A. A Row Dropped From a Table With No Identifiers { #fxaxes-rows }

The first column holds lowercase single words, so `_row_key` counts no keys. The `exact` row is missing here.

| Name | Location | Type | Description |
|---|---|---|---|
| name | Query | String | Searches by name |
| limit | Query | Number | Number of items to fetch at once |

<a id="fxaxes-cols"></a>
## B. Every Key Present, One Column Gone { #fxaxes-cols }

The `Not Null` column is missing entirely here. Every identifier survives.

| Name | Type | Description |
|---|---|---|
| resultCode | Integer | Result code |
| resultMessage | String | Result message |
| isSuccessful | Boolean | Whether it succeeded |

<a id="fxaxes-keys"></a>
## C. Control — An Identifier Row Dropped { #fxaxes-keys }

The shape the existing axis already caught. `pageSize` is missing here. That axis must keep catching it.

| Name | Type | Description |
|---|---|---|
| tokenId | Header | Token ID |
| appKey | Path | App key |

<a id="fxaxes-outlier"></a>
## D. Control — A Row Missing One Pipe { #fxaxes-outlier }

Only the second row here is missing one separator pipe. Row count and majority column count both match, so this **must not be touched**.

| Name | Type | Description |
|---|---|---|
| clusterId | UUID | Cluster UUID |
| clusterName | String  Cluster name |
| nodeCount | Integer | Node count |

<a id="fxaxes-healthy"></a>
## E. Control — A Healthy Table { #fxaxes-healthy }

All three languages agree. It must be preserved byte-for-byte.

| Name | Type | Description |
|---|---|---|
| flavorId | UUID | Instance type UUID |
| imageId | UUID | Image UUID |
