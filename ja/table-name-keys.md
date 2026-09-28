<!-- machine_translated: true -->

<!-- pre-align:aligned sig=e2e0f1e1d01 -->

<a id="tnk"></a>
# 表の先頭列キー e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです (20260928-053041).

<a id="tnk-overview"></a>
## 概要 { #tnk-overview }

メッセージ照会APIが返すレスポンスフィールドと、リクエストが失敗した場合のエラーコードを説明します。

<a id="tnk-t1"></a>
## ネストしたフィールド { #tnk-t1 }

| 値                     | タイプ | 説明                                 |
| --------------------------- | ------- | ---------------------------------------- |
| header                      | Object  | ヘッダ領域                              |
| - resultCode                | Integer | 結果コード                              |
| - resultMessage             | String  | 結果メッセージ                             |
| - isSuccessful              | Boolean | 成否                               |
| messageSearchResultResponse | Object  | 本文領域                              |
| - messages                  | List    | メッセージリスト                            |
| -- requestId                | String  | リクエストID                                    |
| -- plusFriendId             | String  | プラスフレンドID                                 |
| -- senderKey                | String  | 発信キー                                    |
| -- recipientNo              | String  | 受信番号                              |
| -- resultCode               | String  | 受信結果コード                           |
| - totalCount                | Integer | 総個数                                    |

<a id="tnk-t2"></a>
## エラーコード { #tnk-t2 }

| resultCode | resultMessage | 説明 |
| --- | --- | --- |
|-40000| InvalidParam | パラメータにエラーがある |
|-40010| InvalidGroupID | グループIDエラー |
|-40020| DuplicatedGroupID | 重複したグループID |
|-40070| ServiceQuotaExceededException | グループの最大作成数を超過 |
|-41000| UnauthorizedAppKey | 承認されていないアプリケーションキー |
|-50000| InternalServerError | サーバーエラー |

<a id="tnk-t3"></a>
## ライブラリ { #tnk-t3 }

| ライブラリ     | 用途                          |
| ---------------- | ------------------------------- |
| ZeroMQ           | サーバーのIPC                      |
| Netty            | サーバー-クライアント通信            |
| Protocol Buffers | サーバー-クライアントメッセージのシリアライズ  |

<a id="tnk-t4"></a>
## エラー名 { #tnk-t4 }

| Error | Error Code | Description |
| --- | --- | --- |
| NOT\_INITIALIZED | 1 | Gamebaseが初期化されていません。 |
| NOT\_LOGGED_IN | 2 | ログインが必要です。(Standaloneのみ) |
| UI\_TERMS\_UNREGISTERED\_SEQ | 6923 | 登録されていない約款Seq値を設定しました。 |
| UI\_TERMS\_ALREADY\_IN\_PROGRESS\_ERROR | 6924 | Terms API 呼び出しがまだ完了していません。<br/>しばらくしてから再度試行してください。 |

<a id="tnk-c1"></a>
## 設定項目 { #tnk-c1 }

| 項目 | 説明 |
| --- | --- |
| 通知設定 | 通知を受け取るチャネルを選択します。 |
| 受信対象 | 通知を受け取るメンバーを指定します。 |
| 配信時間 | 通知を送信する時間帯を設定します。 |
| 保管期間 | 送信履歴を保管する期間です。 |

<a id="tnk-c2"></a>
## テンプレートフィールド { #tnk-c2 }

| 名前 | タイプ | 説明 |
| --- | --- | --- |
| header.isSuccessful | Boolean | 成否 |
| header.resultCode | Integer | 結果コード |
| body.data.templateId | String | テンプレートID |
| body.data.templateName | String | テンプレート名 |
