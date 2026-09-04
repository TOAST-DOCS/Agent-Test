<!-- machine_translated: true -->

<!-- pre-align:aligned sig=8e6d00d3460b -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 ガイド { #compute-instance-api-v2-guide }

インスタンスは、API 呼び出し時の認証/認可に IaaS トークンを使用します。IaaS トークンは、NHN Cloud の OpenStack ベースのインフラストラクチャサービス (IaaS) で使用される認証トークンです。IaaS トークンの発行および使用の詳細については、「[IaaS トークン](/nhncloud/ja/public-api/iaas-token)」を参照してください。

インスタンス API は `compute` タイプのエンドポイントを使用します。正確なエンドポイントについては、トークン発行応答の `serviceCatalog` を参照してください。

| タイプ | リージョン | エンドポイント |
|---|---|---|
| compute | 韓国(パンギョ)リージョン<br>韓国(ピョンチョン)リージョン<br>韓国(クァンジュ)リージョン<br>日本リージョン | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com (行の修正テスト) |
| TEST-ROW | (新規行テスト) | (新規行テスト) |

| コード | 意味 |
|---|---|
| RETRY | 再試行可能な一時的なエラーです。 |
| FATAL | 再試行しても失敗するエラーです。 |

API 応答には、このガイドに明示されていないフィールドが表示される場合があります。これらのフィールドは NHN Cloud の内部用途に使用され、予告なく変更される可能性があるため、使用しないでください。

<a id="instance-flavors"></a>
## インスタンスタイプ { #instance-flavors }

<a id="list-flavors"></a>
### タイプリストの表示 { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ(GB)<br>指定したサイズより大きいブロックストレージサイズを持つタイプのみを返します |
| minRam | Query | Integer | - | 最小 RAM サイズ(MB)<br>指定したサイズより大きい RAM サイズを持つタイプのみを返します |

<a id="response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| flavors | Body | Object | インスタンスタイプリスト オブジェクト |
| flavors.id | Body | UUID | インスタンスタイプ ID |
| flavors.links | Body | Object | インスタンスタイプパス オブジェクト |
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
### タイプの詳細一覧表示 { #list-flavors-with-details }

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

<a id="list-flavors-with-details-request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ(GB)<br>指定したサイズより大きいブロックストレージサイズを持つタイプのみを返します |
| minRam | Query | Integer | - | 最小 RAM サイズ(MB)<br>指定したサイズより大きい RAM サイズを持つタイプのみを返します |

<a id="list-flavors-with-details-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明             |
|---|---|---|----------------|
| flavors | Body | Object | インスタンスタイプリスト オブジェクト  |
| flavors.id | Body | UUID | インスタンスタイプ ID     |
| flavors.links | Body | Object | インスタンスタイプパス オブジェクト  |
| flavors.name | Body | String | インスタンスタイプ名     |
| flavors.ram | Body | Integer | メモリサイズ(MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | 有効化状態         |
| flavors.vcpus | Body | Integer | vCPU 数        |
| flavors.extra_specs | Body | Object | 追加仕様 オブジェクト       |
| flavors.swap | Body | Integer | スワップ領域サイズ(GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | 共有状態          |
| flavors.rxtx_factor | Body | Float | ネットワーク送受信パケット比 |
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
## Availability Zone { #availability-zones }

<a id="list-availability-zones"></a>
### 可用性ゾーンの一覧表示 { #list-availability-zones }

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

<a id="list-availability-zones-request"></a>
#### リクエスト
このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |

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
### キーペア一覧の表示 { #list-key-pairs }
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="list-key-pairs-request"></a>
#### リクエスト
このAPIはリクエストボディを必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |

<a id="list-key-pairs-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypairs | Body | Array | キーペアオブジェクト一覧 |
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
### キーペアの表示 { #show-key-pair }
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="show-key-pair-request"></a>
#### リクエスト
このAPIはリクエストボディを必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークンID |

<a id="show-key-pair-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクト一覧 |
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
### キーペアを作成/登録する { #createregister-key-pair }

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
| keypair.public_key | Body | String | - | 登録する公開キー。このフィールドが省略されている場合は、新しいキーペアを生成します。 |

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
| keypair.private_key | Body | String | 秘密キー。新しいキーペアを生成した場合は秘密キーを返します。 |
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
### キーペアを削除する { #delete-key-pair }
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="delete-key-pair-request"></a>
#### リクエスト
このAPIはリクエストボディを必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークンID |

<a id="delete-key-pair-response"></a>
#### レスポンス
このAPIはレスポンスボディを返しません。


<a id="instance"></a>
## インスタンス { #instance }

<a id="instance-status"></a>
### インスタンスの状態 { #instance-status }

インスタンスはさまざまな状態を持ち、状態に応じて実行できるアクションが決まっています。インスタンスの状態一覧は次のとおりです。

| 状態名              | 説明                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | インスタンスが有効な状態の場合 |
| `BUILD` | インスタンスが作成中の場合 |
| `DELETED` | インスタンスが削除された場合 |
| `ERROR` | インスタンスで直前に実行したアクションが失敗した場合 |
| `HARD_REBOOT` | インスタンスを強制的に再起動した場合<br> 物理サーバーの電源を切り、再度電源を入れるのと同じ動作 |
| `MIGRATING` | インスタンスがマイグレーション中の場合<br> これはライブマイグレーション(実行中のインスタンスの移動)操作によって発生します。 |
| `PASSWORD` | インスタンスでパスワードをリセット中の場合 |
| `PAUSED` | インスタンスが一時停止された場合<br>一時停止されたインスタンスは、ハイパーバイザーのメモリに保存されます。 |
| `REBOOT` | インスタンスがソフトリブート状態の場合<br> リブートコマンドが仮想マシンのオペレーティングシステムに渡されます。 |
| `REBUILD` | インスタンスを作成時のイメージから再構築する状態 |
| `RESCUE` | インスタンスをレスキューモードで実行中の場合 |
| `RESIZE` | インスタンスタイプを変更するか、インスタンスを別のホストに移動する場合<br>インスタンスが停止した後、再起動された状態 |
| `REVERT_RESIZE` | インスタンスタイプの変更またはインスタンスを別のホストに移動する過程で失敗した場合に、元の状態に復旧される場合 |
| `VERIFY_RESIZE` | インスタンスタイプの変更またはインスタンスを別のホストに移動する過程を完了し、ユーザーの承認を待つ場合<br>NHN Cloud では、この場合は自動的に `ACTIVE` 状態になります。 |
| `SHELVED_OFFLOADED` | インスタンスが終了された場合 |
| `SHUTOFF` | インスタンスが停止された場合 |
| `SUSPENDED` | インスタンスが管理者によって休止状態に進入した場合 |
| `UNKNOWN` | インスタンスの状態を特定できない場合<br>`このような状態になった場合は、管理者にお問い合わせください。` |

<a id="list-instances"></a>
### インスタンス一覧を表示 { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| reservation_id | Query | String | - | インスタンス作成予約 ID。<br>予約 ID を指定すると、同時に作成されたインスタンス一覧のみが返されます。 |
| changes-since | Query | Datetime | - | 指定された時刻以降に変更されたインスタンス一覧を返します。`YYYY-MM-DDThh:mm:ss` の形式です。 |
| image | Query | UUID | - | イメージ ID<br>指定されたイメージを使用したインスタンス一覧を返します。 |
| flavor | Query | UUID | - | インスタンスタイプ ID<br>指定されたタイプを使用したインスタンス一覧を返します。 |
| name | Query | String | - | インスタンス名<br>指定された名前を持つインスタンス一覧を返します。正規表現で照会できます。 |
| status | Query | Enum | - | インスタンスの状態<br>指定された状態を持つインスタンス一覧を返します。 |
| limit | Query | Integer | - | インスタンス一覧の個数<br>指定された個数のインスタンス一覧を返します。 |
| marker | Query | UUID | - | 一覧の最初のインスタンス UUID<br>ソート基準に従って、`marker` で指定されたインスタンスから `limit` 個数のインスタンス一覧を返します。 |

<a id="list-instances-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| servers | Body | Object | インスタンス一覧オブジェクト |
| id | Body | UUID | インスタンス UUID |
| links | body | Object | インスタンスパス オブジェクト |
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

<a id="list-instances-with-details"></a>
### インスタンス一覧の詳細を表示 { #list-instances-with-details }

インスタンス一覧を表示と同じように、現在のテナントに作成されたインスタンス一覧を返します。ただし、インスタンスごとの詳細情報も照会されます。

```
GET /v2/{tenantId}/servers/detail
X-Auth-Token: {tokenId}
```

<a id="list-instances-with-details-request"></a>
#### リクエスト

インスタンス一覧を表示と同じリクエスト形式です。

<a id="list-instances-with-details-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| servers | body | Object | インスタンス一覧オブジェクト |
| status | body | Enum | インスタンスの状態 |
| servers.id | Body | UUID | インスタンス ID |
| servers.name | Body | String | インスタンス名、最大 255 文字 |
| servers.updated | Body | Datetime | インスタンスの最終更新時刻、`YYYY-MM-DDThh:mm:ssZ` 形式 |
| servers.hostId | Body | String | インスタンスが実行中のホスト ID |
| servers.addresses | Body | Object | インスタンスの IP アドレス一覧オブジェクト。<br>インスタンスに接続されたポート数分のリストが生成されます。 |
| servers.addresses."Network 名前" | Body | Object | インスタンスに接続されたネットワーク別ポート情報 |
| servers.addresses."Network 名前".OS-EXT-IPS-MAC:mac_addr | Body | String | インスタンスに接続されたポートの MAC アドレス |
| servers.addresses."Network 名前".version | Body | Integer | インスタンスに接続されたポートの IP バージョン<br>NHN Cloud は IPv4 のみをサポート |
| servers.addresses."Network 名前".addr | Body | String | インスタンスに接続されたポートの IP アドレス |
| servers.addresses."Network 名前".OS-EXT-IPS:type | Body | Enum | ポートの IP アドレスタイプ<br>`fixed` または `floating` のいずれか |
| servers.links | Body | Object | インスタンスパスオブジェクト |
| servers.key_name | Body | String | インスタンスキーペア名 |
| servers.image | Body | Object | インスタンスイメージオブジェクト |
| servers.image.id | Body | UUID | インスタンスイメージ ID |
| servers.image.links | Body | Object | インスタンスイメージパスオブジェクト |
| servers.OS-EXT-STS:task_state | Body | String | インスタンスタスク状態<br>インスタンスに操作を実行したときの操作進行状態を示します。 |
| servers.OS-EXT-STS:vm_state | Body | String | インスタンスの現在の状態 |
| servers.OS-SRV-USG:launched_at | Body | Datetime | インスタンスの最後のブート時刻<br>`YYYY-MM-DDThh:mm:ss.ssssss` 形式 |
| servers.OS-SRV-USG:terminated_at | Body | Datetime | インスタンス削除時刻<br>`YYYY-MM-DDThh:mm:ssZ` 形式 |
| servers.flavor | Body | Object | インスタンスタイプ情報オブジェクト |
| servers.flavor.id | Body | UUID | インスタンスタイプ ID |
| servers.flavor.links | Body | Object | インスタンスタイプパスオブジェクト |
| servers.security_groups | Body | Object | インスタンスに割り当てられたセキュリティグループリストオブジェクト |
| servers.security_groups.name | Body | String | インスタンスに割り当てられたセキュリティグループ名 |
| servers.user_id | Body | String | インスタンスを作成したユーザー ID |
| servers.created | Body | Datetime | インスタンス作成時刻。`YYYY-MM-DDThh:mm:ssZ` 形式 |
| servers.tenant_id | Body | String | インスタンスが属するテナント ID |
| servers.os-extended-volumes:volumes_attached | Body | Object | インスタンスに接続された追加ブロックストレージリストオブジェクト |
| servers.os-extended-volumes:volumes_attached.id | Body | UUID | インスタンスに接続された追加ブロックストレージ ID |
| servers.OS-EXT-STS:power_state | Body | Integer | インスタンスの電源状態<br>- `1`: On<br>- `4`: Off |
| servers.metadata | Body | Object | インスタンスメタデータオブジェクト<br>インスタンスメタデータをキー値ペアで保存 |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | インスタンスに接続された追加ローカルブロックストレージサイズ |
| server.NHN-EXT-ATTR:protect | Body | Boolean | インスタンス削除保護の有無 |

<details><summary>例</summary>
<p>

```json
{
  "servers": [
    {
      "status": "ACTIVE",
      "updated": "2020-02-25T01:22:24Z",
      "hostId": "078d06f898889699f8731d030812e43d2c417edb2cf641dda598c7bd",
      "addresses": {
        "vpc2": [
          {
            "OS-EXT-IPS-MAC:mac_addr": "fa:16:3e:54:a7:64",
            "version": 4,
            "addr": "172.16.0.40",
            "OS-EXT-IPS:type": "fixed"
          }
        ]
      },
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
      "key_name": "access-key",
      "image": {
        "id": "8b9f8d47-b89b-45af-b1d6-3f7ce7e06a11",
        "links": [
          {
            "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/images/8b9f8d47-b89b-45af-b1d6-3f7ce7e06a11",
            "rel": "bookmark"
          }
        ]
      },
      "OS-EXT-STS:task_state": null,
      "OS-EXT-STS:vm_state": "active",
      "OS-SRV-USG:launched_at": "2020-02-25T01:22:23.000000",
      "flavor": {
        "id": "35a73b57-58a7-434d-aa08-5249aaa95b3e",
        "links": [
          {
            "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/35a73b57-58a7-434d-aa08-5249aaa95b3e",
            "rel": "bookmark"
          }
        ]
      },
      "id": "aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
      "security_groups": [
        {
          "name": "default"
        }
      ],
      "OS-SRV-USG:terminated_at": null,
      "OS-EXT-AZ:availability_zone": "kr-pub-b",
      "user_id": "b6ab578c20c94306ac1f41ffc4415b29",
      "name": "Web-Server",
      "created": "2020-02-25T01:15:46Z",
      "tenant_id": "6cdebe3eb0094910bc41f1d42ebe4cb7",
      "os-extended-volumes:volumes_attached": [
        {
          "id": "90712f4f-2faa-4e4f-8eb1-9313a8595570"
        }
      ],
      "accessIPv4": "",
      "accessIPv6": "",
      "progress": 0,
      "OS-EXT-STS:power_state": 1,
      "config_drive": "",
      "metadata": {
        "os_distro": "Windows",
        "description": "Windows 2012 R2 STD (2020.02.18)",
        "os_version": "2012 R2 STD",
        "project_domain": "NORMAL",
        "hypervisor_type": "qemu",
        "monitoring_agent": "sysmon",
        "image_name": "Windows 2012 R2 STD (2020.02.18) EN",
        "volume_size": "50",
        "os_architecture": "amd64",
        "login_username": "Administrator",
        "os_type": "Windows",
        "tc_env": "sysmon"
      },
      "NHN-EXT-ATTR:ephemeral_disk_size": 0,
      "NHN-EXT-ATTR:protect": false
    }
  ]
}
```

</p>
</details>

---

<a id="get-instance"></a>
### インスタンスを表示 { #get-instance }

```
GET /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="get-instance-request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | インスタンス ID |
| tokenId | Header | String | O | トークン ID |

<a id="get-instance-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| server | body | Object | インスタンスオブジェクト |
| status | body | Enum | インスタンスの状態 |
| server.id | Body | UUID | インスタンスID |
| server.name | Body | String | インスタンス名、最大255文字 |
| server.updated | Body | Datetime | インスタンスの最終更新時刻、`YYYY-MM-DDThh:mm:ssZ`形式 |
| server.hostId | Body | String | インスタンスが実行中のホストID |
| server.addresses | Body | Object | インスタンスIPリストオブジェクト <br>インスタンスに接続されたポート数分のリストが生成されます |
| server.addresses."Network名" | Body | Object | インスタンスに接続されたNetworkごとのポート情報 |
| server.addresses."Network名".OS-EXT-IPS-MAC:mac_addr | Body | String | インスタンスに接続されたポートのMACアドレス |
| server.addresses."Network名".version | Body | Integer | インスタンスに接続されたポートのIPバージョン<br>NHN CloudはIPv4のみサポート |
| server.addresses."Network名".addr | Body | String | インスタンスに接続されたポートのIPアドレス |
| server.addresses."Network名".OS-EXT-IPS:type | Body | Enum | ポートのIPアドレスタイプ<br>`fixed`または`floating`のいずれか |
| server.links | Body | Object | インスタンス経路オブジェクト |
| server.key_name | Body | String | インスタンスキーペア名 |
| server.image | Body | Object | インスタンスイメージオブジェクト |
| server.image.id | Body | UUID | インスタンスイメージID |
| server.image.links | Body | Object | インスタンスイメージ経路オブジェクト |
| server.OS-EXT-STS:task_state | Body | String | インスタンスタスク状態<br>インスタンスに動作を実行した場合、動作進行状態を通知します |
| server.OS-EXT-STS:vm_state | Body | String | インスタンスの現在の状態 |
| server.OS-SRV-USG:launched_at | Body | Datetime | インスタンスの最後の起動時刻<br>`YYYY-MM-DDThh:mm:ss.ssssss`形式 |
| server.OS-SRV-USG:terminated_at | Body | Datetime | インスタンス削除時刻<br>`YYYY-MM-DDThh:mm:ssZ`形式 |
| server.flavor | Body | Object | インスタンスタイプ情報オブジェクト |
| server.flavor.id | Body | UUID | インスタンスタイプID |
| server.flavor.links | Body | Object | インスタンスタイプ経路オブジェクト |
| server.security_groups | Body | Object | インスタンスに割り当てられたセキュリティグループリストオブジェクト |
| server.security_groups.name | Body | String | インスタンスに割り当てられたセキュリティグループ名 |
| server.user_id | Body | String | インスタンスを作成したユーザーID |
| server.created | Body | Datetime | インスタンス作成時刻、`YYYY-MM-DDThh:mm:ssZ`形式 |
| server.tenant_id | Body | String | インスタンスが属するテナントID |
| server.os-extended-volumes:volumes_attached | Body | Object | インスタンスに接続された追加ブロックストレージリストオブジェクト |
| server.os-extended-volumes:volumes_attached.id | Body | UUID | インスタンスに接続された追加ブロックストレージID |
| server.OS-EXT-STS:power_state | Body | Integer | インスタンスの電源状態<br>- `1`: On<br>- `4`: Off |
| server.metadata | Body | Object | インスタンスメタデータオブジェクト<br>インスタンスメタデータをキーと値のペアで保存 |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | インスタンスに接続された追加ローカルブロックストレージサイズ |
| server.NHN-EXT-ATTR:protect | Body | Boolean | インスタンス削除保護の有無 |

<details><summary>例</summary>
<p>

```json
{
  "server": {
    "status": "ACTIVE",
    "updated": "2020-02-25T01:22:24Z",
    "hostId": "078d06f898889699f8731d030812e43d2c417edb2cf641dda598c7bd",
    "addresses": {
      "vpc2": [
        {
          "OS-EXT-IPS-MAC:mac_addr": "fa:16:3e:54:a7:64",
          "version": 4,
          "addr": "172.16.0.40",
          "OS-EXT-IPS:type": "fixed"
        }
      ]
    },
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
    "key_name": "access-key",
    "image": {
      "id": "8b9f8d47-b89b-45af-b1d6-3f7ce7e06a11",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/images/8b9f8d47-b89b-45af-b1d6-3f7ce7e06a11",
          "rel": "bookmark"
        }
      ]
    },
    "OS-EXT-STS:task_state": null,
    "OS-EXT-STS:vm_state": "active",
    "OS-SRV-USG:launched_at": "2020-02-25T01:22:23.000000",
    "flavor": {
      "id": "35a73b57-58a7-434d-aa08-5249aaa95b3e",
      "links": [
        {
          "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/flavors/35a73b57-58a7-434d-aa08-5249aaa95b3e",
          "rel": "bookmark"
        }
      ]
    },
    "id": "aaf2778b-ea03-4ccc-8b1b-92f4b686c3ec",
    "security_groups": [
      {
        "name": "default"
      }
    ],
    "OS-SRV-USG:terminated_at": null,
    "OS-EXT-AZ:availability_zone": "kr-pub-b",
    "user_id": "b6ab578c20c94306ac1f41ffc4415b29",
    "name": "Web-Server",
    "created": "2020-02-25T01:15:46Z",
    "tenant_id": "6cdebe3eb0094910bc41f1d42ebe4cb7",
    "os-extended-volumes:volumes_attached": [
      {
        "id": "90712f4f-2faa-4e4f-8eb1-9313a8595570"
      }
    ],
    "accessIPv4": "",
    "accessIPv6": "",
    "progress": 0,
    "OS-EXT-STS:power_state": 1,
    "config_drive": "",
    "metadata": {
      "os_distro": "Windows",
      "description": "Windows 2012 R2 STD (2020.02.18)",
      "os_version": "2012 R2 STD",
      "project_domain": "NORMAL",
      "hypervisor_type": "qemu",
      "monitoring_agent": "sysmon",
      "image_name": "Windows 2012 R2 STD (2020.02.18) EN",
      "volume_size": "50",
      "os_architecture": "amd64",
      "login_username": "Administrator",
      "os_type": "Windows",
      "tc_env": "sysmon"
    },
    "NHN-EXT-ATTR:ephemeral_disk_size": 0,
    "NHN-EXT-ATTR:protect": false
  }
}
```

</p>
</details>

---

<a id="create-instance"></a>
### インスタンスを作成する { #create-instance }

インスタンスを作成します。

インスタンス作成 API を呼び出した後、インスタンス照会によってインスタンスの状態を確認します。

* インスタンスの状態が **ACTIVE** に変わると、インスタンスが正常に作成完了します。
* インスタンスの状態が **BUILDING** のままで継続する場合、または **ERROR** である場合、インスタンス作成パラメータを確認して再度作成を試みます。

Windows インスタンスは、安定した動作のために次のような作成上の制約があります。

* RAM が 2GB 以上のインスタンスタイプを使用します。
* 50GB 以上のルートブロックストレージが必要です。
* U2 タイプは Windows イメージを使用することはできません。

ルートブロックストレージのサイズは、Linux は 10GB、Windows は 50GB から指定できます。

インスタンス作成要求時にスケジューラーヒントを使用して配置ポリシーを割り当てることができます。



```
POST /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="create-instance-request"></a>
#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| server | body | Object | O | サーバーオブジェクト |
| server.security_groups | body | Object | - | セキュリティグループリストオブジェクト<br>省略した場合、`default` グループが追加されます |
| server.security_groups.name | body | String | - | **(条件付き必須)** インスタンスに追加するセキュリティグループ名 |
| server.user_data | body | String | - | インスタンス起動後に実行するスクリプトおよび設定<br>Base64 エンコードされた文字列で 65535 バイトまで許可 |
| server.availability_zone | body | String | - | インスタンスを作成する可用性ゾーン<br>指定しない場合は任意に選択されます<br>ルートブロックストレージのソースタイプが `volume`、`snapshot` の場合、元のブロックストレージの可用性ゾーンと同じに設定する必要があります |
| server.imageRef | Body | String | - | インスタンスを作成するときに使用するイメージ ID<br>ルートブロックストレージのソースタイプが `volume`、`snapshot` の場合、設定は不要です |
| server.flavorRef | Body | String | O | インスタンスを作成するときに使用するインスタンスタイプ ID |
| server.networks | Body | Object | O | インスタンスを作成するときに使用するネットワーク情報オブジェクト<br>指定した数だけ NIC が追加され、ネットワーク ID、サブネット ID、ポート ID、固定 IP のいずれかで指定 |
| server.networks.uuid | Body | UUID | - | **(条件付き必須)** インスタンスを作成するときに使用するネットワーク ID |
| server.networks.subnet | Body | UUID | - | **(条件付き必須)** インスタンスを作成するときに使用するネットワークのサブネット ID |
| server.networks.port | Body | UUID | - | **(条件付き必須)** インスタンスを作成するときに使用するポート ID<br>ポート ID を指定する場合、要求したセキュリティグループは指定した既存ポートに適用されません |
| server.networks.fixed_ip | Body | String | - | **(条件付き必須)** インスタンスを作成するときに使用する固定 IP |
| server.name | Body | String | O | インスタンスの名前<br>英文字ベースで 255 文字まで許可されていますが、Windows イメージの場合は 15 文字以下である必要があります |
| server.metadata | Body | Object | - | インスタンスに追加するメタデータオブジェクト<br>最大長 255 文字以下のキー値ペア |
| server.block_device_mapping_v2 | Body | Object | O | インスタンスのブロックストレージ情報オブジェクト |
| server.block_device_mapping_v2.source_type | Body | Enum | O | 作成するブロックストレージのソースタイプ<br>- `image`: イメージを使用してブロックストレージを作成<br>- `blank`: 空のブロックストレージを作成（ルートブロックストレージとして使用できません）<br>- `volume`: 既に作成されたブロックストレージを使用<br>- `snapshot`: スナップショットを使用してブロックストレージを作成 |
| server.block_device_mapping_v2.uuid | Body | String | - | **(条件付き必須)** ブロックストレージのソースタイプに応じて異なるように設定が必要<br>- ソースタイプが `image` の場合、イメージ ID を設定<br>- ソースタイプが `volume` の場合、既に作成されたブロックストレージ ID を設定<br>- ソースタイプが `snapshot` の場合、スナップショット ID を設定<br>- ソースタイプが `blank` の場合、設定は不要<br>ルートブロックストレージの場合、ブート可能なソースである必要があります |
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 指定したブロックストレージの起動順序<br>-`0` の場合、ルートブロックストレージ<br>- その他は追加ブロックストレージ<br>サイズが大きいほど起動順序は低くなります |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | インスタンスブロックストレージの場所。インスタンスタイプに応じて異なるように設定が必要です。<br>- `local`: GPU インスタンス、U2 インスタンスタイプを使用する場合<br>- `volume`: その他のインスタンスタイプを使用する場合 |
| server.block_device_mapping_v2.volume_type | Body | Enum    | - | **(条件付き必須)** 作成するブロックストレージのタイプ<br>ブロックストレージのソースタイプが `volume`、`snapshot` の場合、設定は不要です<br>`ユーザーガイド > Storage > Block Storage > API v2 ガイド` で **ブロックストレージタイプリスト表示** レスポンスの `name` を参照 |
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | インスタンス削除時のブロックストレージの処理の有無。デフォルト値は `false`。<br>`true` の場合、削除; `false` の場合、保持 |
| server.block_device_mapping_v2.volume_size | Body | Integer | - | **(条件付き必須)** 作成するブロックストレージのサイズ<br>ブロックストレージのソースタイプに応じて異なるように設定が必要<br>- ソースタイプが `volume` の場合、設定は不要です<br>- ソースタイプが `snapshot` の場合、元のブロックストレージサイズ以上に設定<br>`GB` 単位<br>U2 インスタンスタイプを使用し、ルートブロックストレージを作成する場合、U2 インスタンスタイプに明示されたサイズで作成され、この値は無視されます<br>インスタンスタイプに応じて作成可能なルートブロックストレージのサイズが異なるため、詳細については `ユーザーガイド > Compute > Instance > コンソール使用ガイド > インスタンス作成 > ブロックストレージサイズ` を参照 |
| server.block_device_mapping_v2.nhn_encryption                   | Body | Object | - | **(条件付き必須)** ブロックストレージの暗号化情報                                                                                                                                                                                        |
| server.block_device_mapping_v2.nhn_encryption.skm_appkey        | Body | String | - | **(条件付き必須)** Secure Key Manager サービスのアプリキー                                                                                                                                                              |
| server.block_device_mapping_v2.nhn_encryption.skm_key_id        | Body | String | - | **(条件付き必須)** 暗号化ブロックストレージ作成に使用する Secure Key Manager の対称鍵 ID                                                                                                                                  |
| server.key_name | Body | String | O | インスタンスアクセスに使用するキーペア |
| server.min_count | Body | Integer | - | 現在のリクエストで作成するインスタンス個数の最小値。<br>デフォルト値は 1。<br>ブロックストレージのソースタイプが `volume` の場合、`1` でのみ設定可能 |
| server.max_count | Body | Integer | - | 現在のリクエストで作成するインスタンス個数の最大値。<br>デフォルト値は min_count、最大値は 10。<br>ブロックストレージのソースタイプが `volume` の場合、`1` でのみ設定可能 |
| server.return_reservation_id | Body | Boolean | - | インスタンス作成要求予約 ID。<br>True に指定する場合、インスタンス作成情報の代わりに予約 ID を返します。<br>デフォルト値は False |
| os:scheduler_hints | Body | Object | - | スケジューラーヒントオブジェクト |
| os:scheduler_hints.group | Body | String | - | 配置ポリシー ID |

<details><summary>例</summary>
<p>

```json
{
  "server": {
    "name": "DB-Master",
    "imageRef": "9956f822-29c9-4f81-9410-0c392d9c8c24",
    "flavorRef": "a4b6a0f7-aeff-4d78-a8d5-7de9f007012d",
    "networks": [{
      "subnet": "b83863ff-0355-4c73-8c10-0bdf66a69aab"
    }],
    "availability_zone": "kr-pub-a",
    "key_name": "access-key",
    "max_count": 1,
    "min_count": 1,
    "block_device_mapping_v2": [{
      "source_type": "image",
      "uuid": "9956f822-29c9-4f81-9410-0c392d9c8c24",
      "boot_index": 0,
      "volume_size": 1000,
      "destination_type": "volume",
      "delete_on_termination": 1
    }],
    "security_groups": [{
      "name": "default"
    }]
  },
  "os:scheduler_hints": {
    "group": "f878bd5b-49a7-499f-966e-1eceb21cb06b"
  }
}
```

</p>
</details>

<a id="create-instance-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明                                                                                                                                                                                                           |
|---|---|---|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server.security_groups.name | Body | String | 作成したインスタンスのセキュリティグループ名                                                                                                                                                                                           |
| server.id | Body | UUID | 作成したインスタンスの ID                                                                                                                                                                                                 |

<details><summary>例</summary>
<p>

```json
{
  "server": {
    "security_groups": [
      {
        "name": "default"
      }
    ],
    "id": "3a005d5b-63cf-4493-bfc6-49db990b5b50",
    "links": [
      {
        "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
        "rel": "self"
      },
      {
        "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
        "rel": "bookmark"
      }
    ]
  }
}
```

</p>
</details>

---

<a id="modify-instance"></a>
### インスタンスを変更する { #modify-instance }
作成されたインスタンスを変更します。変更できる属性は一部の項目に制限されています。

```
PUT /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="modify-instance-request"></a>
#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| server | Body | Object | O | インスタンス変更要求オブジェクト |
| server.name | Body | String | - | インスタンスの新しい名前 |

<details><summary>例</summary>
<p>

```json
{
    "server": {
        "name": "new-server-test"
    }
}
```

</p>
</details>

<a id="modify-instance-response"></a>
#### レスポンス
インスタンスの表示と同じです。

---

<a id="delete-instance"></a>
### インスタンスの削除 { #delete-instance }
インスタンスを削除します。

```
DELETE /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="delete-instance-request"></a>
#### リクエスト
このAPI はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | 削除するインスタンスID |
| tokenId | Header | String | O | トークンID |

<a id="delete-instance-response"></a>
#### レスポンス
このAPI はレスポンス本文を返しません。

---
