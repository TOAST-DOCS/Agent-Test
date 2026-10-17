<!-- machine_translated: true -->

<!-- pre-align:aligned sig=acfdd30fe5ef -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 ガイド { #compute-instance-api-v2-guide }

インスタンスはAPI呼び出し時の認証/認可にIaaSトークンを使用します。IaaSトークンはNHN CloudのOpenStackベースのインフラストラクチャサービス(IaaS)で使用される認証トークンです。IaaSトークンの発行および使用に関する詳細については、[IaaSトークン](/nhncloud/ja/public-api/iaas-token)を参照してください。

インスタンスAPIは`compute`型エンドポイントを使用します。正確なエンドポイントはトークン発行応答の`serviceCatalog`を参照してください。

| 型 | リージョン | エンドポイント |
|---|---|---|
| compute | 韓国(パンギョ)リージョン<br>韓国(ピョンチョン)リージョン<br>韓国(光州)リージョン<br>日本リージョン | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

API応答にガイドに明記されていないフィールドが表示される場合があります。このようなフィールドはNHN Cloudの内部用途で使用され、事前通知なく変更される可能性があるため、使用しないでください。

<a id="instance-flavors"></a>
## インスタンス型 { #instance-flavors }

<a id="list-flavors"></a>
### 型リストを表示 { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ(GB)<br>指定したサイズよりブロックストレージサイズが大きい型のみを返す |
| minRam | Query | Integer | - | 最小RAMサイズ(MB)<br>指定したサイズよりRAMサイズが大きい型のみを返す |

<a id="response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| flavors | Body | Object | インスタンス型リストオブジェクト |
| flavors.id | Body | UUID | インスタンス型ID |
| flavors.links | Body | Object | インスタンス型パスオブジェクト |
| flavors.name | Body | String | インスタンス型名 |


<details><summary>例</summary>
<p>

```json
{
  "flavors": [
    {
      "id": "013bea75-8541-4c6f-9abe-a03fee3d74fe",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/013bea75-8541-4c6f-9abe-a03fee3d74fe",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/013bea75-8541-4c6f-9abe-a03fee3d74fe",
          "rel": "bookmark"
        }
      ],
      "name": "x1.c32m256"
    },
    {
      "id": "0f19a344-bc66-4228-8cb1-fb9ca82c54f5",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/0f19a344-bc66-4228-8cb1-fb9ca82c54f5",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/0f19a344-bc66-4228-8cb1-fb9ca82c54f5",
          "rel": "bookmark"
        }
      ],
      "name": "x1.c32m128"
    }
  ]
}
```

</p>
</details>

---

<a id="list-flavors-with-details"></a>
### 型リスト詳細表示 { #list-flavors-with-details }

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

<a id="list-flavors-with-details-request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ(GB)<br>指定したサイズよりブロックストレージサイズが大きい型のみを返す |
| minRam | Query | Integer | - | 最小RAMサイズ(MB)<br>指定したサイズよりRAMサイズが大きい型のみを返す |

<a id="list-flavors-with-details-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明             |
|---|---|---|----------------|
| flavors | Body | Object | インスタンス型リストオブジェクト  |
| flavors.id | Body | UUID | インスタンス型ID     |
| flavors.links | Body | Object | インスタンス型パスオブジェクト  |
| flavors.name | Body | String | インスタンス型名     |
| flavors.ram | Body | Integer | メモリサイズ(MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | 有効化状態         |
| flavors.vcpus | Body | Integer | vCPU数        |
| flavors.extra_specs | Body | Object | 追加仕様オブジェクト       |
| flavors.swap | Body | Integer | スワップ領域サイズ(GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | 公開状態          |
| flavors.rxtx_factor | Body | Float | ネットワーク送受信パケット比率 |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | 一時ブロックストレージサイズ(GB)     |
| flavors.disk | Body | Integer | ルートブロックストレージサイズ(GB) |

<details><summary>例</summary>
<p>

```json
{
  "flavors": [
    {
      "name": "x1.c32m256",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/97604802-a090-43fa-a5ce-c7cfd737fbba",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/97604802-a090-43fa-a5ce-c7cfd737fbba",
          "rel": "bookmark"
        }
      ],
      "ram": 262144,
      "OS-FLV-DISABLED:disabled": false,
      "vcpus": 32,
      "extra_specs": {
        "flavor_type": "performance"
      },
      "swap": "",
      "os-flavor-access:is_public": true,
      "rxtx_factor": 1.0,
      "OS-FLV-EXT-DATA:ephemeral": 0,
      "disk": 0,
      "id": "97604802-a090-43fa-a5ce-c7cfd737fbba"
    },
    {
      "name": "x1.c32m128",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/31fa632d-aeec-4f12-8a57-ce9d146228e5",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/31fa632d-aeec-4f12-8a57-ce9d146228e5",
          "rel": "bookmark"
        }
      ],
      "ram": 131072,
      "OS-FLV-DISABLED:disabled": false,
      "vcpus": 32,
      "extra_specs": {
        "flavor_type": "performance"
      },
      "swap": "",
      "os-flavor-access:is_public": true,
      "rxtx_factor": 1.0,
      "OS-FLV-EXT-DATA:ephemeral": 0,
      "disk": 0,
      "id": "31fa632d-aeec-4f12-8a57-ce9d146228e5"
    }
  ]
}
```

</p>
</details>

---

<a id="availability-zones"></a>
## アベイラビリティゾーン { #availability-zones }

<a id="list-availability-zones"></a>
### アベイラビリティゾーンリストを表示 { #list-availability-zones }

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

<a id="list-availability-zones-request"></a>
#### リクエスト
このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |

<a id="list-availability-zones-response"></a>
#### レスポンス
| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| availabilityZoneInfo | Body | Object | アベイラビリティゾーン情報オブジェクト |
| availabilityZoneInfo.zoneName | Body | String | アベイラビリティゾーン名 |
| availabilityZoneInfo.zoneState | Body | Object | アベイラビリティゾーン状態情報オブジェクト |
| availabilityZoneInfo.available | Body | Object | アベイラビリティゾーン状態 |

<details><summary>例</summary>
<p>

```json
{
    "availabilityZoneInfo": [
      {
        "zoneState": {
          "available": true
        },
        "zoneName": "kr-pub-a"
      },
      {
        "zoneState": {
          "available": true
        },
        "zoneName": "kr-pub-b"
      }
    ]
}
```

</p>
</details>

---

<a id="key-pairs"></a>
## キーペア { #key-pairs }

<a id="list-key-pairs"></a>
### キーペア一覧表示 { #list-key-pairs }
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="list-key-pairs-request"></a>
#### リクエスト
このAPIはリクエスト本文が不要です。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |

<a id="list-key-pairs-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypairs | Body | Array | キーペアオブジェクトのリスト |
| keypairs.keypair | Body | Object | キーペアオブジェクト |
| keypairs.keypair.name | Body | String | キーペア名 |
| keypairs.keypair.public_key | Body | String | 公開キー |
| keypairs.keypair.fingerprint | Body | String | キーペアフィンガープリント |

<details><summary>例</summary>
<p>

```json
{
  "keypairs": [
    {
      "keypair": {
        "public_key": "ssh-rsa ... Generated-by-Nova",
        "name": "keypair",
        "fingerprint": "SHA256:..."
      }
    }
  ]
}
```

</p>
</details>

---

<a id="show-key-pair"></a>
### キーペア表示 { #show-key-pair }
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="show-key-pair-request"></a>
#### リクエスト
このAPIはリクエスト本文が不要です。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークンID |

<a id="show-key-pair-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクトのリスト |
| keypair.public_key | Body | String | 公開キー |
| keypair.user_id | Body | String | キーペア所有者ID |
| keypair.name | Body | String | キーペア名 |
| keypair.deleted | Body | Boolean | キーペア削除の有無 |
| keypair.created_at | Body | Datetime | キーペア作成時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | キーペア更新時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | キーペア削除時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.fingerprint | Body | String | キーペアフィンガープリント |
| keypair.id | Body | Integer | キーペアID |

<details><summary>例</summary>
<p>

```json
{
  "keypair": {
    "public_key": "ssh-rsa ... Generated-by-Nova",
    "user_id": "826a1213b3f746829515486965690dfe",
    "name": "keypair",
    "deleted": false,
    "created_at": "2020-02-07T03:46:48.000000",
    "updated_at": null,
    "fingerprint": "SHA256:...",
    "deleted_at": null,
    "id": 51
  }
}
```

</p>
</details>

---

<a id="createregister-key-pair"></a>
### キーペア作成/登録 { #createregister-key-pair }

```
POST /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="createregister-key-pair-request"></a>
#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| keypair | Body | Object | O | キーペアオブジェクト |
| keypair.name | Body | String | O | 作成または登録するキーペア名 |
| keypair.public_key | Body | String | - | 登録する公開キー。このフィールドが省略された場合、新しいキーペアを作成します。 |

<details><summary>例</summary>
<p>

```json
{
    "keypair": {
        "name": "keypair-d20a3d59-9433-4b79-8726-20b431d89c78",
        "public_key": "ssh-rsa ... Generated-by-Nova"
    }
}
```

</p>
</details>

<a id="createregister-key-pair-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクト |
| keypair.public_key | Body | String | 公開キー |
| keypair.private_key | Body | String | 秘密鍵。新しいキーペアを作成した場合、秘密鍵を返します。 |
| keypair.user_id | Body | String | キーペア所有者ID |
| keypair.name | Body | String | キーペア名 |
| keypair.fingerprint | Body | String | キーペアフィンガープリント |

<details><summary>例</summary>
<p>

```json
{
    "keypair": {
        "fingerprint": "SHA256:+EZoD ... /DKiGnY4zf5tYrcix0",
        "name": "keypair",
        "public_key": "ssh-rsa ... Generated-by-Nova",
        "user_id": "436f727b7c9142f896ddd56be591dd7f"
    }
}
```

</p>
</details>

---

<a id="delete-key-pair"></a>
### キーペア削除 { #delete-key-pair }
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="delete-key-pair-request"></a>
#### リクエスト
このAPIはリクエスト本文が不要です。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークンID |

<a id="delete-key-pair-response"></a>
#### レスポンス
このAPIはレスポンス本文を返しません。


<a id="instance"></a>
## インスタンス { #instance }

<a id="instance-status"></a>
### インスタンス状態 { #instance-status }

インスタンスはさまざまな状態を持ち、状態に応じて実行できるアクションが決定されています。インスタンス状態の一覧は次のとおりです。

| 状態名              | 説明                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | インスタンスがアクティブな状態である場合 |
| `BUILD` | インスタンスが作成中である場合 |
| `DELETED` | インスタンスが削除された場合 |
| `ERROR` | インスタンスに対して実行された前の操作が失敗した場合 |
| `HARD_REBOOT` | インスタンスが強制的に再起動された場合<br>物理サーバーの電源を切り、再度オンにするのと同じ操作 |
| `MIGRATING` | インスタンスがマイグレーション中である場合<br>これはライブマイグレーション(アクティブインスタンスの移動)操作によって発生します |
| `PASSWORD` | インスタンスでパスワードをリセット中である場合 |
| `PAUSED` | インスタンスが一時停止されている場合<br>一時停止されたインスタンスはハイパーバイザーのメモリに保存されます |
| `REBOOT` | インスタンスがソフト再起動状態である場合<br>再起動コマンドが仮想マシンオペレーティングシステムに渡されます |
| `REBUILD` | インスタンスが作成時のイメージから新たに構築される状態 |
| `RESCUE` | インスタンスがレスキューモードで実行中である場合 |
| `RESIZE` | インスタンスタイプを変更または別のホストにインスタンスを移動する場合<br>インスタンスが停止されてから再起動された状態 |
| `REVERT_RESIZE` | インスタンスタイプを変更または別のホストにインスタンスを移動する処理中に失敗した場合、元の状態に戻すために復旧する場合 |
| `VERIFY_RESIZE` | インスタンスがタイプ変更または別のホストへの移動処理を完了し、ユーザーの承認を待っている場合<br>NHN Cloudではこの場合、自動的に`ACTIVE`状態になります |
| `SHELVED_OFFLOADED` | インスタンスがシャットダウンされた場合 |
| `SHUTOFF` | インスタンスが停止されている場合 |
| `SUSPENDED` | インスタンスが管理者によって休止状態に入った場合 |
| `UNKNOWN` | インスタンスの状態が不明な場合<br>`インスタンスがこの状態に入った場合、管理者に問い合わせてください。` | 

<a id="list-instances"></a>
### インスタンス一覧の表示 { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| reservation_id | Query | String | - | インスタンス作成予約ID。<br>予約IDを指定すると、同時に作成されたインスタンス一覧のみが返されます。 |
| changes-since | Query | Datetime | - | 指定された時刻以降に変更されたインスタンス一覧を返します。`YYYY-MM-DDThh:mm:ss`の形式です。 |
| image | Query | UUID | - | イメージID<br>指定されたイメージを使用するインスタンス一覧を返します。 |
| flavor | Query | UUID | - | インスタンスタイプID<br>指定されたタイプを使用するインスタンス一覧を返します。 |
| name | Query | String | - | インスタンス名<br>指定された名前を持つインスタンス一覧を返します。正規表現で検索できます。 |
| status | Query | Enum | - | インスタンス状態<br>指定された状態を持つインスタンス一覧を返します。 |
| limit | Query | Integer | - | インスタンス一覧の件数<br>指定された件数のインスタンス一覧を返します。 |
| marker | Query | UUID | - | 一覧の最初のインスタンスUUID<br>ソート基準に従って、`marker`で指定されたインスタンスから`limit`件のインスタンス一覧を返します。 |

<a id="list-instances-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| servers | Body | Object | インスタンス一覧オブジェクト |
| id | Body | UUID | インスタンスUUID |
| links | body | Object | インスタンスパスオブジェクト |
| name | body | String | インスタンス名 |

<details><summary>例</summary>
<p>

```json
{
  "servers": [
    {
      "id": "aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
          "rel": "self"
        },
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
          "rel": "bookmark"
        }
      ],
      "name": "Web-Server"
    }
  ]
}
```

</p>
</details>

---