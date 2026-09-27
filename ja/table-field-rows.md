<!-- machine_translated: true -->

<!-- pre-align:aligned sig=e2e0f1e1d00 -->

<a id="tfr"></a>
# table-field-rows e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです (20260927-143557)。

<a id="tfr-overview"></a>
## 概要 { #tfr-overview }

サービス設定を修正するAPIです。リクエスト本文には修正するフィールドのみを入れ、入れないフィールドは既存の値を維持します。

<a id="tfr-fields"></a>
## リクエスト本文 { #tfr-fields }

[フィールド]

| 名前          | タイプ | 必須か | デフォルト値 | 有効範囲                                            | 説明                                                 |
| --------------------- | ------- | --------- | ------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| domain                | String  | 必須  |        | 最大255文字                                            | 修正するドメイン(サービス名)                                   |
| useOriginCacheControl | Boolean | 選択   |        | true/false                                                        | キャッシュ期限設定(true：オリジンサーバー設定を使用、 false：ユーザー設定を使用). useOriginCacheControlまたはcacheTypeのいずれかを必ず入力する必要があります。      |
| cacheType             | String  | 選択   |        | BYPASS, NO_STORE            | キャッシュタイプ設定。 useOriginCacheControlまたはcacheTypeのいずれかを必ず入力する必要があります。                                          |
| referrerType          | String  | 必須  |        | BLACKLIST/WHITELIST                                          | リファラーアクセス管理("BLACKLIST"：ブラックリスト、"WHITELIST"：ホワイトリスト) |
| referrers             | List    | 任意 |        |                                                              | 正規表現形式のリファラーヘッダリスト |
| isAllowWhenEmptyReferrer | Boolean | 任意     | true      | true/false             | リファラーヘッダがない場合、コンテンツアクセス許可(true)/拒否(false)             |
| description           | String  | 任意  |        | 最大255文字                                            | 説明                                                 |
| domainAlias           | List    | 任意 |        | 最大255文字                                              | ドメインエイリアス(個人または会社が所有しているドメインを使用) |
| defaultMaxAge         | Integer | 任意 | 0      | 0～2,147,483,647                                            | キャッシュ満了時間(秒)、デフォルト値0は604,800秒です。              |
| origins               | List    | 必須  |        |                                                              | オリジンサーバー                                            |
| origins[0].origin     | String  | 必須  |        | 最大255文字                                            | オリジンサーバー(ドメインまたはIP)                                      |
| origins[0].originPath | String  | 任意  |        | 最大8192文字                                           | オリジンサーバーの下層パス                                  |
| forwardHostHeader     | String  | 必須 |        | ORIGIN_HOSTNAME<br/>REQUEST_HOST_HEADER   | CDNサーバーがオリジンサーバーにコンテンツをリクエストする時、伝達するホストヘッダ設定("ORIGIN_HOSTNAME"：オリジンサーバーのホスト名で設定、"REQUEST_HOST_HEADER"：クライアントリクエストのホストヘッダで設定 |
| useOrigin             | String  | 必須  |        | Y/N                                                          | キャッシュ期限設定(Y：オリジン設定の使用、"N"：ユーザー設定の使用)      |
| rootPathAccessControl  | Object  | 任意 |  |  | CDNサービスのルートパスに対するアクセス制御設定 | 

- `forwardHostHeader`の既定値は、`domainAlias`を設定した場合は`REQUEST_HOST_HEADER`です。
