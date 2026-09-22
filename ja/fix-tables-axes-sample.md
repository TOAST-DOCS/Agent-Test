<!-- pre-align:aligned sig=fxaxes000000 -->

<a id="fxaxes-sample"></a>
## 検出軸フィクスチャー { #fxaxes-sample }

A fixture contrasting the detection axes of fix-tables (identifier / row count / column count). Not registered in `ko/nav.yml`.

<a id="fxaxes-rows"></a>
## A. A Row Dropped From a Table With No Identifiers { #fxaxes-rows }

The first column holds lowercase single words, so `_row_key` counts no keys. The `exact` row is missing here.

| 名前 | 場所 | 型 | 説明 |
|---|---|---|---|
| name | Query | String | 名前で検索します。 |
| exact | Query | Boolean | 完全一致検索の有無です。 |
| limit | Query | Number | 一度に取得する項目数です。 |

<a id="fxaxes-cols"></a>
## B. Every Key Present, One Column Gone { #fxaxes-cols }

The `Not Null` column is missing entirely here. Every identifier survives.

| 名前 | 型 | 必須 | 説明 |
|---|---|---|---|
| resultCode | Integer | O | 結果コード |
| resultMessage | String | O | 結果メッセージ |
| isSuccessful | Boolean | O | 成功の有無 |

<a id="fxaxes-keys"></a>
## C. Control — An Identifier Row Dropped { #fxaxes-keys }

The shape the existing axis already caught. `pageSize` is missing here. That axis must keep catching it.

| Name | Type | Description |
|---|---|---|
| tokenId | Header | Token ID |
| appKey | Path | App key |
| pageSize | Query | ページサイズ |

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
