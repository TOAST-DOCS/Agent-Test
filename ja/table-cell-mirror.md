<!-- machine_translated: true -->

<!-- pre-align:aligned sig=e2e0c3117a1 -->

<a id="tcm"></a>
# table-cell-mirror e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです (20261011-225551)。

<a id="tcm-response"></a>
## レスポンス { #tcm-response }

APIレスポンス本文のフィールドです。

| 名前 | タイプ | 必須 | 説明 |
| --- | --- | --- | --- |
| header.isSuccessful | Boolean | Y | 成功したかどうか |
| header.resultCode | Integer | Y | 結果コード |
| header.resultMessage | String | Y | 結果メッセージ |
| body.id | String | N | リソースID |
| body.name | String | N | リソース名 |
| body.createdAt | DateTime | N | 作成日時 |

<a id="tcm-request"></a>
## リクエスト { #tcm-request }

リクエストヘッダーとパラメータです。

| 区分 | 名前 | タイプ | 必須 | 説明 |
| --- | --- | --- | --- | --- |
| Header | X-Auth-Token | String | Y | 発行されたトークン |
| Path | appKey | String | Y | アプリケーションキー |
| Query | pageNum | Integer | N | ページ番号 |
| Query | pageSize | Integer | N | ページサイズ |

<a id="tcm-partial"></a>
## 部分修正 { #tcm-partial }

ラベルを指定するフィールドです。

| 名前 | タイプ | 必須 | 説明 |
| --- | --- | --- | --- |
| labelKey | String | Y | ラベルキー(最大64文字、英数字のみ) |
| labelValue | String | N | ラベル値 |

<a id="tcm-control"></a>
## 対照群 { #tcm-control }

リソースの位置を指定します。

| 名前 | 必須かどうか | 説明 |
| --- | --- | --- |
| region | 必須 | リージョンコード |
| zone | 必須 | アベイラビリティゾーン |
