<!-- pre-align:aligned sig=e2e0c3117a1 -->

<a id="tcm"></a>
# table-cell-mirror e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです (20261011-225551)。

<a id="tcm-response"></a>
## レスポンス { #tcm-response }

APIレスポンス本文のフィールドです。

| 名前 | タイプ | 必須 | 説明 |
| --- | --- | --- | --- |
| header.isSuccessful | Boolean | Yes | 成功したかどうか |
| header.resultCode | Integer | Yes | 結果コード |
| header.resultMessage | String | Yes | 結果メッセージ |
| body.id | String | No | リソースID |
| body.name | String | No | リソース名 |
| body.createdAt | DateTime | No | 作成日時 |

<a id="tcm-request"></a>
## リクエスト { #tcm-request }

リクエストヘッダーとパラメータです。

| 区分 | 名前 | タイプ | 必須 | 説明 |
| --- | --- | --- | --- | --- |
| Header | X-Auth-Token | String | Yes | 発行されたトークン |
| Path | appKey | String | Yes | アプリケーションキー |
| Query | pageNum | Integer | No | ページ番号 |
| Query | pageSize | Integer | No | ページサイズ |

<a id="tcm-partial"></a>
## 部分修正 { #tcm-partial }

ラベルを指定するフィールドです。

| 名前 | タイプ | 必須 | 説明 |
| --- | --- | --- | --- |
| labelKey | String | Yes | ラベルキー |
| labelValue | String | No | ラベル値 |

<a id="tcm-control"></a>
## 対照群 { #tcm-control }

リソースの位置を指定します。

| 名前 | 必須かどうか | 説明 |
| --- | --- | --- |
| region | 必須 | リージョンコード |
| zone | 任意 | アベイラビリティゾーン |
