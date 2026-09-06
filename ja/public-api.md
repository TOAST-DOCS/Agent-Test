<!-- machine_translated: true -->

<!-- pre-align:aligned sig=acfdd30fe5ef -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 ガイド { #compute-instance-api-v2-guide }

インスタンスは API 呼び出し時に認証/認可のために IaaS トークンを使用します。IaaS トークンは NHN Cloud の OpenStack ベースのインフラストラクチャサービス (IaaS) で使用される認証トークンです。IaaS トークンの発行および使用の詳細については、[IaaS トークン](/nhncloud/ja/public-api/iaas-token) を参照してください。

インスタンス API は `compute` タイプのエンドポイントを使用します。正確なエンドポイントはトークン発行応答の `serviceCatalog` を参照してください。

| タイプ | リージョン | エンドポイント |
|---|---|---|
| compute | 韓国(パンギョ) リージョン<br>韓国(ペンチョン) リージョン<br>韓国(光州) リージョン<br>日本 リージョン | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com (行編集テスト) |
| TEST-ROW | (新規行テスト) | (新規行テスト) |

API 応答にガイドで明示されていないフィールドが表示される可能性があります。このようなフィールドは NHN Cloud 内部用途で使用され、事前通知なしに変更される可能性があるため、使用しないでください。

<a id="instance-flavors"></a>
## インスタンスタイプ { #instance-flavors }

<a id="list-flavors"></a>
### タイプ一覧 { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="request"></a>
#### 要求

この API は要求本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ (GB)<br>指定したサイズより大きいブロックストレージサイズのタイプのみを返す |
| minRam | Query | Integer | - | 最小 RAM サイズ (MB)<br>指定したサイズより大きい RAM サイズのタイプのみを返す |

<a id="response"></a>
#### 応答

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| flavors | Body | Object | インスタンスタイプ一覧オブジェクト |
| flavors.id | Body | UUID | インスタンスタイプ ID |
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
### タイプ詳細一覧 { #list-flavors-with-details }

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

<a id="list-flavors-with-details-request"></a>
#### 要求

この API は要求本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ (GB)<br>指定したサイズより大きいブロックストレージサイズのタイプのみを返す |
| minRam | Query | Integer | - | 最小 RAM サイズ (MB)<br>指定したサイズより大きい RAM サイズのタイプのみを返す |

<a id="list-flavors-with-details-response"></a>
#### 応答

| 名前 | 種類 | 形式 | 説明             |
|---|---|---|----------------|
| flavors | Body | Object | インスタンスタイプ一覧オブジェクト  |
| flavors.id | Body | UUID | インスタンスタイプ ID     |
| flavors.links | Body | Object | インスタンスタイプパスオブジェクト  |
| flavors.name | Body | String | インスタンスタイプ名     |
| flavors.ram | Body | Integer | メモリサイズ (MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | 有効化状態         |
| flavors.vcpus | Body | Integer | vCPU 個数        |
| flavors.extra_specs | Body | Object | 追加仕様オブジェクト       |
| flavors.swap | Body | Integer | スワップ領域サイズ (GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | 共有状態          |
| flavors.rxtx_factor | Body | Float | ネットワーク送受信パケット比率 |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | 一時ブロックストレージサイズ (GB)     |
| flavors.disk | Body | Integer | ルートブロックストレージサイズ (GB) |

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
### 可用性ゾーン一覧 { #list-availability-zones }

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

<a id="list-availability-zones-request"></a>
#### 要求

この API は要求本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |

<a id="list-availability-zones-response"></a>
#### 応答

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
### キーペアリストの表示 { #list-key-pairs }

```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="list-key-pairs-request"></a>
#### リクエスト

このAPI はリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |

<a id="list-key-pairs-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypairs | Body | Array | キーペアオブジェクトのリスト |
| keypairs.keypair | Body | Object | キーペアオブジェクト |
| keypairs.keypair.name | Body | String | キーペア名 |
| keypairs.keypair.public_key | Body | String | 公開鍵 |
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

このAPI はリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークン ID |

<a id="show-key-pair-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクトのリスト |
| keypair.public_key | Body | String | 公開鍵 |
| keypair.user_id | Body | String | キーペア所有者 ID |
| keypair.name | Body | String | キーペア名 |
| keypair.deleted | Body | Boolean | 削除フラグ |
| keypair.created_at | Body | Datetime | キーペア作成時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | キーペア更新時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | キーペア削除時刻<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.fingerprint | Body | String | キーペアフィンガープリント |
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
### キーペアの作成/登録 { #createregister-key-pair }

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
| keypair.public_key | Body | String | - | 登録する公開鍵。このフィールドを省略した場合、新しいキーペアが作成されます。 |

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
| keypair.public_key | Body | String | 公開鍵 |
| keypair.private_key | Body | String | 秘密鍵。新しいキーペアを作成した場合、秘密鍵が返されます。 |
| keypair.user_id | Body | String | キーペア所有者 ID |
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
### キーペアの削除 { #delete-key-pair }

```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="delete-key-pair-request"></a>
#### リクエスト

このAPI はリクエストボディを要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークン ID |

<a id="delete-key-pair-response"></a>
#### レスポンス

このAPI はレスポンスボディを返しません。


<a id="instance"></a>
## インスタンス { #instance }

<a id="instance-status"></a>
### インスタンス状態 { #instance-status }

インスタンスは様々な状態を持ち、状態に応じて取ることができるアクションが決まっています。インスタンス状態のリストは次のとおりです。

| 状態名              | 説明                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | インスタンスが有効な状態である場合 |
| `BUILD` | インスタンスが作成中である場合 |
| `DELETED` | インスタンスが削除された場合 |
| `ERROR` | 直前のインスタンスに対して取られたアクションが失敗した場合 |
| `HARD_REBOOT` | インスタンスを強制再起動した場合<br>物理サーバーの電源を切り、再び入れることと同じアクション |
| `MIGRATING` | インスタンスがマイグレーション中である場合<br>これはライブマイグレーション(アクティブなインスタンスの移動)作業により発生する |
| `PASSWORD` | インスタンスでパスワードをリセット中である場合 |
| `PAUSED` | インスタンスが一時停止された場合<br>一時停止されたインスタンスはハイパーバイザーのメモリに保存される |
| `REBOOT` | インスタンスがソフト再起動状態である場合<br>再起動コマンドが仮想マシン OS に渡される |
| `REBUILD` | インスタンスを作成時のイメージから新たに作る状態 |
| `RESCUE` | インスタンスをリカバリモードで実行中である場合 |
| `RESIZE` | インスタンスタイプを変更、またはインスタンスを別のホストに移動する場合<br>インスタンスが停止され、再び開始された状態 |
| `REVERT_RESIZE` | インスタンスタイプの変更、またはインスタンスを別のホストに移動する過程で失敗した場合、元の状態に戻すために復元する場合 |
| `VERIFY_RESIZE` | インスタンスがタイプ変更またはインスタンスを別のホストに移動するプロセスを完了し、ユーザーの承認を待っている場合<br>NHN Cloud ではこの場合自動的に `ACTIVE` 状態になる |
| `SHELVED_OFFLOADED` | インスタンスが終了した場合 |
| `SHUTOFF` | インスタンスが停止した場合 |
| `SUSPENDED` | インスタンスが管理者によって休止状態に入った場合 |
| `UNKNOWN` | インスタンスの状態が判断できない場合<br>インスタンスがこの状態に入った場合は管理者にお問い合わせください。 |

<a id="list-instances"></a>
### インスタンス一覧の表示 { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### リクエスト

このAPI はリクエスト本体を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| reservation_id | Query | String | - | インスタンス作成予約 ID。<br>予約 ID を指定した場合、同時に作成されたインスタンスのリストのみを返します |
| changes-since | Query | Datetime | - | 指定された時刻以降に変更されたインスタンスのリストを返します。形式は `YYYY-MM-DDThh:mm:ss` です。 |
| image | Query | UUID | - | イメージ ID<br>指定されたイメージを使用したインスタンスのリストを返します |
| flavor | Query | UUID | - | インスタンスタイプ ID<br>指定されたタイプを使用したインスタンスのリストを返します |
| name | Query | String | - | インスタンス名<br>指定された名前を持つインスタンスのリストを返します。正規表現でクエリすることが可能です |
| status | Query | Enum | - | インスタンス状態<br>指定された状態を持つインスタンスのリストを返します |
| limit | Query | Integer | - | インスタンスリストのアイテム数<br>指定された数のインスタンスリストを返します |
| marker | Query | UUID | - | リストの最初のインスタンス UUID<br>ソート基準に従い、`marker` で指定されたインスタンスから `limit` の数だけインスタンスリストを返します |

<a id="list-instances-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| servers | Body | Object | インスタンスリストオブジェクト |
| id | Body | UUID | インスタンス UUID |
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

<a id="test-added-endpoint"></a>
### テスト用の新規エンドポイント { #test-added-endpoint }

```
POST /v2/{tenantId}/test-added-endpoint
X-Auth-Token: {tokenId}
```

<a id="test-added-request"></a>
#### リクエスト { #test-added-request }

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| name | Body | String | O | エンドポイント名 |

<a id="test-added-response"></a>
#### レスポンス { #test-added-response }

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| endpoint | Body | Object | 生成されたエンドポイントオブジェクト |
| endpoint.id | Body | String | エンドポイント ID |
| endpoint.name | Body | String | エンドポイント名 |