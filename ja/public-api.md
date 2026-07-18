<!-- pre-align:aligned sig=2e2588e1a607 -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 ガイド { #compute-instance-api-v2-guide }

Instance は API 呼び出し時の認証・認可のために IaaS トークンを使用します。IaaS トークンは NHN Cloud の OpenStack ベースのインフラストラクチャサービス (IaaS) で使用される認証トークンです。IaaS トークンの発行および使用の詳細については、[IaaS トークン](/nhncloud/ja/public-api/iaas-token) を参照してください。

インスタンス API は `compute` タイプ エンドポイントを使用します。正確なエンドポイントについては、トークン発行応答の `serviceCatalog` を参照してください。

| タイプ | リージョン | エンドポイント |
|---|---|---|
| compute | 韓国 (パンギョ) リージョン<br>韓国 (ピョンチョン) リージョン<br>韓国 (クアンジュ) リージョン<br>日本 リージョン | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com | (行修正テスト)
| TEST-ROW | (新規行テスト) | (新規行テスト) |
API 応答に本ガイドで明示されていないフィールドが含まれる場合があります。これらのフィールドは NHN Cloud の内部用途で使用され、予告なく変更される可能性があるため、使用しないでください。

<a id="instance-flavors"></a>
## インスタンス タイプ { #instance-flavors }

<a id="list-flavors"></a>
### タイプ リストの表示 { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="list-flavors-request"></a>
#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ (GB)<br>指定したサイズよりブロックストレージサイズが大きいタイプのみ返す |
| minRam | Query | Integer | - | 最小 RAM サイズ (MB)<br>指定したサイズより RAM サイズが大きいタイプのみ返す |

<a id="list-flavors-response"></a>
#### 応答

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| flavors | Body | Object | インスタンス タイプ リスト オブジェクト |
| flavors.id | Body | UUID | インスタンス タイプ ID |
| flavors.links | Body | Object | インスタンス タイプ パス オブジェクト |
| flavors.name | Body | String | インスタンス タイプ 名 |


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
### タイプ リストの詳細表示 { #list-flavors-with-details }

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
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ (GB)<br>指定したサイズよりブロックストレージサイズが大きいタイプのみ返す |
| minRam | Query | Integer | - | 最小 RAM サイズ (MB)<br>指定したサイズより RAM サイズが大きいタイプのみ返す |

<a id="list-flavors-with-details-response"></a>
#### 応答

| 名前 | 種類 | 形式 | 説明             |
|---|---|---|----------------|
| flavors | Body | Object | インスタンス タイプ リスト オブジェクト  |
| flavors.id | Body | UUID | インスタンス タイプ ID     |
| flavors.links | Body | Object | インスタンス タイプ パス オブジェクト  |
| flavors.name | Body | String | インスタンス タイプ 名     |
| flavors.ram | Body | Integer | メモリ サイズ (MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | 有効化 状態         |
| flavors.vcpus | Body | Integer | vCPU 個数        |
| flavors.extra_specs | Body | Object | 追加 仕様 オブジェクト       |
| flavors.swap | Body | Integer | スワップ エリア サイズ (GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | 公開 状態          |
| flavors.rxtx_factor | Body | Float | ネットワーク 送信/受信 パケット 比率 |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | 一時 ブロックストレージ サイズ (GB)     |
| flavors.disk | Body | Integer | ルート ブロックストレージ サイズ (GB) |

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
### 可用性ゾーンの一覧表示 { #list-availability-zones }

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

<a id="list-availability-zones-request"></a>
#### リクエスト
この API はリクエスト本文を要求しません。

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
### キーペア一覧を表示 { #list-key-pairs }
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="list-key-pairs-request"></a>
#### リクエスト
この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |

<a id="list-key-pairs-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypairs | Body | Array | キーペアオブジェクトの一覧 |
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
### キーペアを表示 { #show-key-pair }
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="show-key-pair-request"></a>
#### リクエスト
この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークン ID |

<a id="show-key-pair-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクトの一覧 |
| keypair.public_key | Body | String | 公開鍵 |
| keypair.user_id | Body | String | キーペア所有者 ID |
| keypair.name | Body | String | キーペア名 |
| keypair.deleted | Body | Boolean | キーペア削除の有無 |
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
### キーペアを作成/登録 { #createregister-key-pair }

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
| keypair.public_key | Body | String | - | 登録する公開鍵。このフィールドが省略されると、新しいキーペアを作成します。 |

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
| keypair.private_key | Body | String | 秘密鍵。新しいキーペアを作成した場合、秘密鍵を返します。 |
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
### キーペアを削除 { #delete-key-pair }
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="delete-key-pair-request"></a>
#### リクエスト
この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークン ID |

<a id="delete-key-pair-response"></a>
#### レスポンス
この API はレスポンス本文を返しません。


<a id="instance"></a>
## インスタンス { #instance }

<a id="instance-status"></a>
### インスタンスの状態 { #instance-status }

インスタンスはさまざまな状態を持っており、状態に応じて実行できるアクションが決定されます。インスタンスの状態リストは次のとおりです。

| 状態名 | 説明 |
|---|---|
| `ACTIVE` | インスタンスがアクティブな状態の場合 |
| `BUILD` | インスタンスが作成中の場合 |
| `DELETED` | インスタンスが削除された場合 |
| `ERROR` | インスタンスで実行されたアクションが失敗した場合 |
| `HARD_REBOOT` | インスタンスが強制的に再起動された場合<br>物理サーバーの電源を切ってから再度オンにすることと同じアクション |
| `MIGRATING` | インスタンスがマイグレーション中の場合<br>これはライブマイグレーション（アクティブなインスタンスの移動）により発生します |
| `PASSWORD` | インスタンスでパスワードをリセット中の場合 |
| `PAUSED` | インスタンスが一時停止された場合<br>一時停止されたインスタンスはハイパーバイザーのメモリに保存されます |
| `REBOOT` | インスタンスがソフト再起動状態の場合<br>再起動コマンドが仮想マシンのオペレーティング システムに渡されます |
| `REBUILD` | インスタンスを作成時のイメージから新しく作り直す状態 |
| `RESCUE` | インスタンスが復旧モードで実行されている場合 |
| `RESIZE` | インスタンスのタイプを変更するか、インスタンスを別のホストに移動する場合<br>インスタンスが停止されてから再度開始された状態 |
| `REVERT_RESIZE` | インスタンスのタイプを変更するか別のホストに移動するプロセス中に失敗した場合に、元の状態に復旧する場合 |
| `VERIFY_RESIZE` | インスタンスがタイプの変更または別のホストへの移動を完了し、ユーザーの承認を待っている場合<br>NHN Cloud では、この場合自動的に `ACTIVE` 状態になります |
| `SHELVED_OFFLOADED` | インスタンスが終了された場合 |
| `SHUTOFF` | インスタンスが停止された場合 |
| `SUSPENDED` | インスタンスが管理者により休止状態に設定された場合 |
| `UNKNOWN` | インスタンスの状態を判断できない場合<br>`インスタンスがこの状態に入った場合は、管理者に問い合わせてください。` |

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
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| reservation_id | Query | String | - | インスタンス作成予約 ID。<br>予約 IDを指定すると、同時に作成されたインスタンス一覧のみを返します。 |
| changes-since | Query | Datetime | - | 指定された時刻以降に変更されたインスタンス一覧を返します。`YYYY-MM-DDThh:mm:ss` の形式。 |
| image | Query | UUID | - | イメージ ID<br>指定されたイメージを使用したインスタンス一覧を返します。 |
| flavor | Query | UUID | - | インスタンスタイプ ID<br>指定されたタイプを使用したインスタンス一覧を返します。 |
| name | Query | String | - | インスタンス名<br>指定された名前を持つインスタンス一覧を返します。正規表現で検索可能です。 |
| status | Query | Enum | - | インスタンス状態<br>指定された状態を持つインスタンス一覧を返します。 |
| limit | Query | Integer | - | インスタンス一覧の個数<br>指定された個数分のインスタンス一覧を返します。 |
| marker | Query | UUID | - | 一覧の最初のインスタンス UUID<br>ソート基準に従い、`marker` で指定されたインスタンスから `limit` 個数分のインスタンス一覧を返します。 |

<a id="list-instances-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| servers | Body | Object | インスタンス一覧オブジェクト |
| id | Body | UUID | インスタンス UUID |
| links | body | Object | インスタンスリンク オブジェクト |
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
### インスタンス一覧の詳細表示 { #list-instances-with-details }

インスタンス一覧の表示と同じように、現在のテナントに作成されたインスタンス一覧を返します。ただし、インスタンスごとの詳細情報も一緒に返されます。

```
GET /v2/{tenantId}/servers/detail
X-Auth-Token: {tokenId}
```

<a id="list-instances-with-details-request"></a>
#### リクエスト

インスタンス一覧の表示と同じリクエスト形式です。

<a id="list-instances-with-details-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明                                                                                                                                                                                                        |
|---|---|---|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| servers | body | Object | インスタンス一覧オブジェクト                                                                                                                                                                                                |
| status | body | Enum | インスタンス状態                                                                                                                                                                                                   |
| servers.id | Body | UUID | インスタンス ID                                                                                                                                                                                                   |
| servers.name | Body | String | インスタンス名、最大 255 文字                                                                                                                                                                                          |
| servers.updated | Body | Datetime | インスタンス最終更新時刻、`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                  |
| servers.hostId | Body | String | インスタンスが実行中のホスト ID                                                                                                                                                                                        |
| servers.addresses | Body | Object | インスタンス IP 一覧オブジェクト。<br>インスタンスに接続されたポート数分のリストが生成されます。                                                                                                                                                             |
| servers.addresses."Network 名前" | Body | Object | インスタンスに接続された Network ごとのポート情報                                                                                                                                                                                  |
| servers.addresses."Network 名前".OS-EXT-IPS-MAC:mac_addr | Body | String | インスタンスに接続されたポートの MAC アドレス                                                                                                                                                                                      |
| servers.addresses."Network 名前".version | Body | Integer | インスタンスに接続されたポートの IP バージョン<br>NHN Cloud は IPv4 のみをサポート                                                                                                                                                                |
| servers.addresses."Network 名前".addr | Body | String | インスタンスに接続されたポートの IP アドレス                                                                                                                                                                                       |
| servers.addresses."Network 名前".OS-EXT-IPS:type | Body | Enum | ポートの IP アドレスタイプ<br>`fixed` または `floating` のいずれか                                                                                                                                                                |
| servers.links | Body | Object | インスタンスパスオブジェクト                                                                                                                                                                                                |
| servers.key_name | Body | String | インスタンスキーペア名                                                                                                                                                                                               |
| servers.image | Body | Object | インスタンスイメージオブジェクト                                                                                                                                                                                               |
| servers.image.id | Body | UUID | インスタンスイメージ ID                                                                                                                                                                                               |
| servers.image.links | Body | Object | インスタンスイメージパスオブジェクト                                                                                                                                                                                            |
| servers.OS-EXT-STS:task_state | Body | String | インスタンスのタスク状態<br>インスタンスに操作が行われたときに、操作の進行状態を表示します                                                                                                                                                               |
| servers.OS-EXT-STS:vm_state | Body | String | インスタンスの現在の状態                                                                                                                                                                                                |
| servers.OS-SRV-USG:launched_at | Body | Datetime | インスタンス最後のブート時刻<br>`YYYY-MM-DDThh:mm:ss.ssssss` 形式                                                                                                                                                         |
| servers.OS-SRV-USG:terminated_at | Body | Datetime | インスタンス削除時刻<br>`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                   |
| servers.flavor | Body | Object | インスタンスタイプ情報オブジェクト                                                                                                                                                                                             |
| servers.flavor.id | Body | UUID | インスタンスタイプ ID                                                                                                                                                                                                |
| servers.flavor.links | Body | Object | インスタンスタイプパスオブジェクト                                                                                                                                                                                             |
| servers.security_groups | Body | Object | インスタンスに割り当てられたセキュリティグループ一覧オブジェクト                                                                                                                                                                                     |
| servers.security_groups.name | Body | String | インスタンスに割り当てられたセキュリティグループ名                                                                                                                                                                                        |
| servers.user_id | Body | String | インスタンスを作成したユーザー ID                                                                                                                                                                                          |
| servers.created | Body | Datetime | インスタンス作成時刻。`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                     |
| servers.tenant_id | Body | String | インスタンスが属するテナント ID                                                                                                                                                                                           |
| servers.os-extended-volumes:volumes_attached | Body | Object | インスタンスに接続された追加ブロックストレージ一覧オブジェクト                                                                                                                                                                                |
| servers.os-extended-volumes:volumes_attached.id | Body | UUID | インスタンスに接続された追加ブロックストレージ ID                                                                                                                                                                                   |
| servers.OS-EXT-STS:power_state | Body | Integer | インスタンスの電源状態<br>- `1`: On<br>- `4`: Off                                                                                                                                                                    |
| servers.metadata | Body | Object | インスタンスメタデータオブジェクト<br>インスタンスメタデータをキーと値のペアで保存します                                                                                                                                                                   |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | インスタンスに接続された追加ローカルブロックストレージサイズ                                                                                                                                                                   |
| server.NHN-EXT-ATTR:protect | Body | Boolean | インスタンス削除保護の有無                                                                                                                                                                   |

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
### インスタンスの表示 { #get-instance }

```
GET /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="get-instance-request"></a>
#### リクエスト

この API はリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | インスタンス ID |
| tokenId | Header | String | O | トークン ID |

<a id="get-instance-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| server | body | Object | インスタンスオブジェクト。 |
| status | body | Enum | インスタンス状態。 |
| server.id | Body | UUID | インスタンス ID。 |
| server.name | Body | String | インスタンス名、最大 255 文字。 |
| server.updated | Body | Datetime | インスタンス最終修正時刻、`YYYY-MM-DDThh:mm:ssZ` 形式。 |
| server.hostId | Body | String | インスタンスが実行中のホスト ID。 |
| server.addresses | Body | Object | インスタンス IP リストオブジェクト。<br>インスタンスに接続されたポート数分のリストが作成されます。 |
| server.addresses."Network 名前" | Body | Object | インスタンスに接続された Network ごとのポート情報。 |
| server.addresses."Network 名前".OS-EXT-IPS-MAC:mac_addr | Body | String | インスタンスに接続されたポートの MAC アドレス。 |
| server.addresses."Network 名前".version | Body | Integer | インスタンスに接続されたポートの IP バージョン。<br>NHN Cloud は IPv4 のみサポート。 |
| server.addresses."Network 名前".addr | Body | String | インスタンスに接続されたポートの IP アドレス。 |
| server.addresses."Network 名前".OS-EXT-IPS:type | Body | Enum | ポートの IP アドレスタイプ。<br>`fixed` または `floating` のいずれか。 |
| server.links | Body | Object | インスタンスリンクオブジェクト。 |
| server.key_name | Body | String | インスタンスキーペア名。 |
| server.image | Body | Object | インスタンスイメージオブジェクト。 |
| server.image.id | Body | UUID | インスタンスイメージ ID。 |
| server.image.links | Body | Object | インスタンスイメージリンクオブジェクト。 |
| server.OS-EXT-STS:task_state | Body | String | インスタンス作業状態。<br>インスタンスに動作を加えたとき、動作進行状態を通知します。 |
| server.OS-EXT-STS:vm_state | Body | String | インスタンス現在状態。 |
| server.OS-SRV-USG:launched_at | Body | Datetime | インスタンス最後の起動時刻、`YYYY-MM-DDThh:mm:ss.ssssss` 形式。 |
| server.OS-SRV-USG:terminated_at | Body | Datetime | インスタンス削除時刻、`YYYY-MM-DDThh:mm:ssZ` 形式。 |
| server.flavor | Body | Object | インスタンスタイプ情報オブジェクト。 |
| server.flavor.id | Body | UUID | インスタンスタイプ ID。 |
| server.flavor.links | Body | Object | インスタンスタイプリンクオブジェクト。 |
| server.security_groups | Body | Object | インスタンスに割り当てられたセキュリティグループリストオブジェクト。 |
| server.security_groups.name | Body | String | インスタンスに割り当てられたセキュリティグループ名。 |
| server.user_id | Body | String | インスタンスを作成したユーザー ID。 |
| server.created | Body | Datetime | インスタンス作成時刻、`YYYY-MM-DDThh:mm:ssZ` 形式。 |
| server.tenant_id | Body | String | インスタンスが属するテナント ID。 |
| server.os-extended-volumes:volumes_attached | Body | Object | インスタンスに接続された追加ブロックストレージリストオブジェクト。 |
| server.os-extended-volumes:volumes_attached.id | Body | UUID | インスタンスに接続された追加ブロックストレージ ID。 |
| server.OS-EXT-STS:power_state | Body | Integer | インスタンスの電源状態。<br>- `1`: On<br>- `4`: Off |
| server.metadata | Body | Object | インスタンスメタデータオブジェクト。<br>インスタンスメタデータをキー値ペアで保管。 |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | インスタンスに接続された追加ローカルブロックストレージサイズ。 |
| server.NHN-EXT-ATTR:protect | Body | Boolean | インスタンス削除保護の有無。 |

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