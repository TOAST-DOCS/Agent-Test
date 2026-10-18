<!-- pre-align:aligned sig=e2e09e4r0w -->

<a id="tor"></a>
# table-open-row e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです (20261018-122611)。

<a id="tor-last"></a>
## 認証レスポンス { #tor-last }

認証情報登録レスポンスのフィールドです。

| 名前 | タイプ | 必須 | 説明 |
|------------ | ------------- | ----- | ------------ |
|   authId | String| No | 内部で管理する認証手段ID |
|   userAccessKeyID | String| No | User Access Key ID |
|   secretAccessKey | String| No | 秘密鍵 |
|   tokenExpiryPeriod | Long| No | トークン有効期限(秒単位) |
|   tokenFormatCode | String| No | トークンフォーマットコード(OPAQUE、JWT) |


<a id="tor-mid"></a>
## プロジェクトレスポンス { #tor-mid }

プロジェクト照会レスポンスのフィールドです。

| 名前 | タイプ | 必須 | 説明 |
|------------ | ------------- | ----- | ------------ |
|   projectId | String| No | プロジェクトID |
|   projectName | String| No | プロジェクト名 |
|   ownerUuid | String| No | プロジェクトオーナーUUID |
|   regDatetime | Date| No | 作成日時 |


<a id="tor-closed"></a>
## メンバーレスポンス { #tor-closed }

メンバー照会レスポンスのフィールドです。

| 名前 | タイプ | 必須 | 説明 |
|------------ | ------------- | ----- | ------------ |
|   uuid | String| No | メンバーUUID |
|   name | String| No | 名前 |
|   emailAddress | String| No | メンバーのメールアドレス |
|   joinYmdt | Date| No | 加入日時 |

