<!-- machine_translated: true -->

<!-- pre-align:aligned sig=27ed74e0499b -->

<a id="compute-instance-api-v2-guide"></a>

## Compute > Instance > API v2 ガイド { #compute-instance-api-v2-guide }

インスタンスは、API呼び出し時の認証・認可のためにIaaSトークンを使用します。IaaSトークンはNHN CloudのOpenStackベースのインフラストラクチャサービス(IaaS)で使用される認証トークンです。IaaSトークンの発行と使用の詳細については、[IaaSトークン](/nhncloud/ja/public-api/iaas-token)を参照してください。

インスタンスAPIは`compute`タイプのエンドポイントを使用します。正確なエンドポイントはトークン発行レスポンスの`serviceCatalog`を参照します。

| 種類 | リージョン | エンドポイント |
|---|---|---|
| compute | 韓国(パンギョ)リージョン<br>韓国(ペンチョン)リージョン<br>韓国(光州)リージョン<br>日本リージョン | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

APIレスポンスには、本ガイドで明記されていないフィールドが表示される場合があります。これらのフィールドはNHN Cloud内部用途で使用され、予告なく変更される可能性があるため、使用しないでください。

<a id="instance-flavors"></a>

## インスタンスタイプ { #instance-flavors }

<a id="list-flavors"></a>
### タイプの一覧を表示 { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="list-flavors-request"></a>
#### リクエスト

このAPIはリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ(GB)<br>指定したサイズより大きいブロックストレージサイズを持つタイプのみを返します |
| minRam | Query | Integer | - | 最小RAM容量(MB)<br>指定したサイズより大きいRAM容量を持つタイプのみを返します |

<a id="list-flavors-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| flavors | Body | Object | インスタンスタイプ一覧オブジェクト |
| flavors.id | Body | UUID | インスタンスタイプID |
| flavors.links | Body | Object | インスタンスタイプパスオブジェクト |
| flavors.name | Body | String | インスタンスタイプ名 |


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
### タイプの詳細一覧を表示 { #list-flavors-with-details }

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

<a id="list-flavors-with-details-request"></a>
#### リクエスト

このAPIはリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ(GB)<br>指定したサイズより大きいブロックストレージサイズを持つタイプのみを返します |
| minRam | Query | Integer | - | 最小RAM容量(MB)<br>指定したサイズより大きいRAM容量を持つタイプのみを返します |

<a id="list-flavors-with-details-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明             |
|---|---|---|----------------|
| flavors | Body | Object | インスタンスタイプ一覧オブジェクト  |
| flavors.id | Body | UUID | インスタンスタイプID     |
| flavors.links | Body | Object | インスタンスタイプパスオブジェクト  |
| flavors.name | Body | String | インスタンスタイプ名     |
| flavors.ram | Body | Integer | メモリ容量(MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | 有効化状態         |
| flavors.vcpus | Body | Integer | vCPU数        |
| flavors.extra_specs | Body | Object | 追加仕様オブジェクト       |
| flavors.swap | Body | Integer | スワップ領域サイズ(GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | 共有状態          |
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

## 可用性ゾーン { #availability-zones }

<a id="list-availability-zones"></a>
### 可用性ゾーンの一覧を表示 { #list-availability-zones }

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

<a id="list-availability-zones-request"></a>
#### リクエスト
このAPIはリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |

<a id="list-availability-zones-response"></a>
#### レスポンス
| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| availabilityZoneInfo | Body | Object | 可用性ゾーン情報オブジェクト |
| availabilityZoneInfo.zoneName | Body | String | 可用性ゾーン名 |
| availabilityZoneInfo.zoneState | Body | Object | 可用性ゾーン状態情報オブジェクト |
| availabilityZoneInfo.available | Body | Object | 可用性ゾーン状態 |

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
### キーペア一覧を表示する { #list-key-pairs }
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="list-key-pairs-request"></a>
#### リクエスト
このAPIはリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |

<a id="list-key-pairs-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypairs | Body | Array | キーペアオブジェクト一覧 |
| keypairs.keypair | Body | Object | キーペアオブジェクト |
| keypairs.keypair.name | Body | String | キーペア名 |
| keypairs.keypair.public_key | Body | String | 公開キー |
| keypairs.keypair.fingerprint | Body | String | キーペア指紋 |

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
### キーペアを表示する { #show-key-pair }
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="show-key-pair-request"></a>
#### リクエスト
このAPIはリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークン ID |

<a id="show-key-pair-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクト一覧 |
| keypair.public_key | Body | String | 公開キー |
| keypair.user_id | Body | String | キーペア所有者 ID |
| keypair.name | Body | String | キーペア名 |
| keypair.deleted | Body | Boolean | 削除有無 |
| keypair.created_at | Body | Datetime | キーペア作成時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | キーペア更新時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | キーペア削除時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.fingerprint | Body | String | キーペア指紋 |
| keypair.id | Body | Integer | キーペア ID |

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
### キーペアを作成/登録する { #createregister-key-pair }

```
POST /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="createregister-key-pair-request"></a>
#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| keypair | Body | Object | O | キーペアオブジェクト |
| keypair.name | Body | String | O | 作成または登録するキーペア名 |
| keypair.public_key | Body | String | - | 登録する公開キー。このフィールドが省略された場合、新しいキーペアが作成されます。 |

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
| keypair.private_key | Body | String | 秘密キー。新しいキーペアを作成した場合、秘密キーが返されます。 |
| keypair.user_id | Body | String | キーペア所有者 ID |
| keypair.name | Body | String | キーペア名 |
| keypair.fingerprint | Body | String | キーペア指紋 |

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
### キーペアを削除する { #delete-key-pair }
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="delete-key-pair-request"></a>
#### リクエスト
このAPIはリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークン ID |

<a id="delete-key-pair-response"></a>
#### レスポンス
このAPIはレスポンスボディを返しません。


<a id="instance"></a>

## インスタンス { #instance }

<a id="instance-status"></a>
### インスタンス状態 { #instance-status }

インスタンスは様々な状態を持ち、状態に応じて実行できるアクションが決定されます。インスタンス状態の一覧は次のとおりです。

| 状態名              | 説明                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | インスタンスがアクティブな状態である場合 |
| `BUILD` | インスタンスが作成中である場合 |
| `DELETED` | インスタンスが削除された場合 |
| `ERROR` | インスタンスに対して実行された前のアクションが失敗した場合 |
| `HARD_REBOOT` | インスタンスが強制的に再起動された場合<br>物理サーバーの電源をオフにしてから再度オンにすることと同じアクション |
| `MIGRATING` | インスタンスがマイグレーション中である場合<br>これはライブマイグレーション(アクティブなインスタンスの移動)タスクが原因で発生します |
| `PASSWORD` | インスタンスでパスワードをリセット中である場合 |
| `PAUSED` | インスタンスが一時停止された場合<br>一時停止されたインスタンスはハイパーバイザーのメモリに保存されます |
| `REBOOT` | インスタンスがソフト再起動状態である場合<br>再起動コマンドが仮想マシンのオペレーティングシステムに渡されます |
| `REBUILD` | 作成時のイメージからインスタンスを新しく作成する状態 |
| `RESCUE` | インスタンスがリカバリーモードで実行中である場合 |
| `RESIZE` | インスタンスタイプを変更するか、インスタンスを別のホストに移動する場合<br>インスタンスが停止してから再起動された状態 |
| `REVERT_RESIZE` | インスタンスタイプの変更またはインスタンスを別のホストに移動するプロセス中に失敗したとき、元の状態に戻すために復旧する場合 |
| `VERIFY_RESIZE` | インスタンスタイプの変更またはインスタンスを別のホストに移動するプロセスが完了し、ユーザーの承認を待っている場合<br>NHN Cloudではこの場合自動的に`ACTIVE`状態になります |
| `SHELVED_OFFLOADED` | インスタンスがシャットダウンされた場合 |
| `SHUTOFF` | インスタンスが停止された場合 |
| `SUSPENDED` | インスタンスが管理者によって休止モードに入った場合 |
| `UNKNOWN` | インスタンスの状態が不明である場合<br>`インスタンスがこの状態に進入した場合は、管理者に問い合わせてください。` |

<a id="list-instances"></a>
### インスタンス一覧を表示する { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### リクエスト

このAPIはリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| reservation_id | Query | String | - | インスタンス作成予約ID。<br>予約IDを指定すると、同時に作成されたインスタンスのリストのみが返されます |
| changes-since | Query | Datetime | - | 指定された時刻以降に変更されたインスタンスのリストを返します。`YYYY-MM-DDThh:mm:ss`の形式。 |
| image | Query | UUID | - | イメージID<br>指定されたイメージを使用するインスタンスのリストを返します |
| flavor | Query | UUID | - | インスタンスタイプID<br>指定されたタイプを使用するインスタンスのリストを返します |
| name | Query | String | - | インスタンス名<br>指定された名前を持つインスタンスのリストを返します。正規表現でクエリできます |
| status | Query | Enum | - | インスタンス状態<br>指定された状態を持つインスタンスのリストを返します |
| limit | Query | Integer | - | インスタンスリストの数<br>指定された数のインスタンスリストを返します |
| marker | Query | UUID | - | リストの最初のインスタンスUUID<br>ソート基準に従って、`marker`で指定されたインスタンスから`limit`個数分のインスタンスリストを返します |

<a id="list-instances-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| servers | Body | Object | インスタンスリストオブジェクト |
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