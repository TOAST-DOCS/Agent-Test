<a id="compute-instance-api-v2-guide"></a>

## Compute > Instance > API v2 ガイド

インスタンスは、API 呼び出し時の認証/認可に IaaS トークンを使用します。IaaS トークンは、NHN Cloud の OpenStack ベースのインフラサービス (IaaS) で使用する認証トークンです。IaaS トークンの発行と使用については、「[IaaS トークン](/nhncloud/ja/public-api/iaas-token)」を参照してください。

インスタンス API は `compute` タイプのエンドポイントを使用します。正確なエンドポイントは、トークン発行レスポンスの `serviceCatalog` を参照してください。

| タイプ | リージョン | エンドポイント |
|---|---|---|
| compute | 韓国(板橋)リージョン<br>韓国(坪村)リージョン<br>韓国(光州)リージョン<br>日本リージョン | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

API レスポンスには、ガイドに記載されていないフィールドが含まれる場合があります。これらのフィールドは NHN Cloud の内部目的で使用されており、事前の告知なしに変更される場合があるため、使用しないでください。

<a id="instance-flavors"></a>

## インスタンスタイプ

<a id="list-flavors"></a>
### タイプ一覧の表示

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

#### リクエスト

この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ (GB)<br>指定したサイズよりブロックストレージサイズが大きいタイプのみ返します |
| minRam | Query | Integer | - | 最小 RAM サイズ (MB)<br>指定したサイズより RAM サイズが大きいタイプのみ返します |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| flavors | Body | Object | インスタンスタイプ一覧オブジェクト |
| flavors.id | Body | UUID | インスタンスタイプ ID |
| flavors.links | Body | Object | インスタンスタイプのパスオブジェクト |
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
### タイプ一覧の詳細表示

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

#### リクエスト

この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| minDisk | Query | Integer | - | 最小ブロックストレージサイズ (GB)<br>指定したサイズよりブロックストレージサイズが大きいタイプのみ返します |
| minRam | Query | Integer | - | 最小 RAM サイズ (MB)<br>指定したサイズより RAM サイズが大きいタイプのみ返します |

#### レスポンス

| 名前 | 種類 | 形式 | 説明             |
|---|---|---|----------------|
| flavors | Body | Object | インスタンスタイプ一覧オブジェクト  |
| flavors.id | Body | UUID | インスタンスタイプ ID     |
| flavors.links | Body | Object | インスタンスタイプのパスオブジェクト  |
| flavors.name | Body | String | インスタンスタイプ名     |
| flavors.ram | Body | Integer | メモリサイズ (MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | 有効かどうか         |
| flavors.vcpus | Body | Integer | vCPU 数        |
| flavors.extra_specs | Body | Object | 追加仕様オブジェクト       |
| flavors.swap | Body | Integer | スワップ領域サイズ (GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | 共有かどうか          |
| flavors.rxtx_factor | Body | Float | ネットワーク送信/受信パケット比率 |
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

## 可用性ゾーン

<a id="list-availability-zones"></a>
### 可用性ゾーン一覧の表示

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

#### リクエスト
このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |

#### レスポンス
| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| availabilityZoneInfo | Body | Object | 可用性ゾーン情報オブジェクト |
| availabilityZoneInfo.zoneName | Body | String | 可用性ゾーン名 |
| availabilityZoneInfo.zoneState | Body | Object | 可用性ゾーン状態情報オブジェクト |
| availabilityZoneInfo.available | Body | Object | 可用性ゾーンの状態 |

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

## キーペア

<a id="list-key-pairs"></a>
### キーペア一覧の表示
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

#### リクエスト
このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypairs | Body | Array | キーペアオブジェクトの一覧 |
| keypairs.keypair | Body | Object | キーペアオブジェクト |
| keypairs.keypair.name | Body | String | キーペア名 |
| keypairs.keypair.public_key | Body | String | 公開鍵 |
| keypairs.keypair.fingerprint | Body | String | キーペアのフィンガープリント |

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
### キーペアの表示
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

#### リクエスト
このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークンID |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクトの一覧 |
| keypair.public_key | Body | String | 公開鍵 |
| keypair.user_id | Body | String | キーペア所有者ID |
| keypair.name | Body | String | キーペア名 |
| keypair.deleted | Body | Boolean | キーペアの削除有無 |
| keypair.created_at | Body | Datetime | キーペアの作成日時<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | キーペアの更新日時<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | キーペアの削除日時<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.fingerprint | Body | String | キーペアのフィンガープリント |
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
### キーペアの作成/登録

```
POST /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
| keypair | Body | Object | O | キーペアオブジェクト |
| keypair.name | Body | String | O | 作成または登録するキーペア名 |
| keypair.public_key | Body | String | - | 登録する公開鍵。このフィールドを省略すると、新しいキーペアを作成します。 |

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

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| keypair | Body | Object | キーペアオブジェクト |
| keypair.public_key | Body | String | 公開鍵 |
| keypair.private_key | Body | String | 秘密鍵。新しいキーペアを作成した場合に秘密鍵を返します。 |
| keypair.user_id | Body | String | キーペア所有者ID |
| keypair.name | Body | String | キーペア名 |
| keypair.fingerprint | Body | String | キーペアのフィンガープリント |

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
### キーペアの削除
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

#### リクエスト
このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| keypairName | URL | String | O | キーペア名 |
| tokenId | Header | String | O | トークンID |

#### レスポンス
このAPIはレスポンス本文を返しません。


<a id="instance"></a>

## インスタンス

<a id="instance-status"></a>

### インスタンスの状態

インスタンスはさまざまな状態を持ち、状態に応じて実行できる操作が決まっています。インスタンスの状態一覧は次のとおりです。

| 状態名              | 説明                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | インスタンスがアクティブな状態の場合 |
| `BUILD` | インスタンスが作成中の場合 |
| `DELETED` | インスタンスが削除された場合 |
| `ERROR` | 直前にインスタンスに対して実行した操作が失敗した場合 |
| `HARD_REBOOT` | インスタンスを強制再起動した場合<br> 物理サーバーの電源をオフにして再度オンにする動作と同等です |
| `MIGRATING` | インスタンスがマイグレーション中の場合<br> これはライブマイグレーション（アクティブなインスタンスの移動）作業によって発生します |
| `PASSWORD` | インスタンスでパスワードをリセット中の場合 |
| `PAUSED` | インスタンスが一時停止されている場合<br>一時停止されたインスタンスはハイパーバイザーのメモリに保存されます |
| `REBOOT` | インスタンスがソフト再起動状態の場合<br> 再起動コマンドが仮想マシンのオペレーティングシステムに送信されます |
| `REBUILD` | インスタンスを作成時のイメージから新たに作り直している状態 |
| `RESCUE` | インスタンスをリカバリモードで実行中の場合 |
| `RESIZE` | インスタンスタイプを変更するか、インスタンスを別のホストに移動する場合<br>インスタンスが停止され、再起動された状態 |
| `REVERT_RESIZE` | インスタンスタイプの変更またはインスタンスを別のホストへの移動が失敗した際に、元の状態に戻すためにリカバリを行う場合 |
| `VERIFY_RESIZE` | インスタンスがタイプ変更または別のホストへの移動プロセスを完了し、ユーザーの承認を待っている場合<br>NHN Cloud ではこの場合、自動的に `ACTIVE` 状態になります |
| `SHELVED_OFFLOADED` | インスタンスが終了した場合 |
| `SHUTOFF` | インスタンスが停止した場合 |
| `SUSPENDED` | インスタンスが管理者によって休止状態に移行した場合 |
| `UNKNOWN` | インスタンスの状態が不明な場合<br>`インスタンスがこの状態に移行した場合は、管理者にお問い合わせください。` | 

<a id="list-instances"></a>

### インスタンス一覧の表示

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

#### リクエスト

この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| reservation_id | Query | String | - | インスタンス作成予約 ID。<br>予約 ID を指定すると、同時に作成されたインスタンスの一覧のみを返します |
| changes-since | Query | Datetime | - | 指定した日時以降に変更されたインスタンスの一覧を返します。`YYYY-MM-DDThh:mm:ss` 形式。 |
| image | Query | UUID | - | イメージ ID<br>指定したイメージを使用したインスタンスの一覧を返します |
| flavor | Query | UUID | - | インスタンスタイプ ID<br>指定したタイプを使用したインスタンスの一覧を返します |
| name | Query | String | - | インスタンス名<br>指定した名前を持つインスタンスの一覧を返します。正規表現でのクエリが可能です |
| status | Query | Enum | - | インスタンスのステータス<br>指定したステータスを持つインスタンスの一覧を返します |
| limit | Query | Integer | - | インスタンス一覧の件数<br>指定した件数分のインスタンスの一覧を返します |
| marker | Query | UUID | - | 一覧の最初のインスタンス UUID<br>ソート基準に従い、`marker` で指定されたインスタンスから `limit` 件数分のインスタンスの一覧を返します |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| servers | Body | Object | インスタンス一覧オブジェクト |
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

<a id="list-instances-with-details"></a>

### インスタンス一覧の詳細表示

インスタンス一覧の表示と同様に、現在のテナントに作成されたインスタンスの一覧を返します。ただし、インスタンスごとの詳細情報も合わせて照会されます。

```
GET /v2/{tenantId}/servers/detail
X-Auth-Token: {tokenId}
```

#### リクエスト

インスタンス一覧の表示と同じリクエスト形式です。

#### レスポンス

| 名前 | 種類 | 形式 | 説明                                                                                                                                                                                                        |
|---|---|---|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| servers | body | Object | インスタンス一覧オブジェクト                                                                                                                                                                                                |
| status | body | Enum | インスタンスのステータス                                                                                                                                                                                                   |
| servers.id | Body | UUID | インスタンス ID                                                                                                                                                                                                   |
| servers.name | Body | String | インスタンス名。最大 255 文字                                                                                                                                                                                          |
| servers.updated | Body | Datetime | インスタンスの最終更新日時。`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                  |
| servers.hostId | Body | String | インスタンスが稼働しているホスト ID                                                                                                                                                                                        |
| servers.addresses | Body | Object | インスタンスの IP 一覧オブジェクト。<br>インスタンスに接続されたポート数分のリストが生成されます。                                                                                                                                                             |
| servers.addresses."Network 名" | Body | Object | インスタンスに接続された Network ごとのポート情報                                                                                                                                                                                  |
| servers.addresses."Network 名".OS-EXT-IPS-MAC:mac_addr | Body | String | インスタンスに接続されたポートの MAC アドレス                                                                                                                                                                                      |
| servers.addresses."Network 名".version | Body | Integer | インスタンスに接続されたポートの IP バージョン<br>NHN Cloud は IPv4 のみサポートします                                                                                                                                                |
| servers.addresses."Network 名".addr | Body | String | インスタンスに接続されたポートの IP アドレス                                                                                                                                                                                       |
| servers.addresses."Network 名".OS-EXT-IPS:type | Body | Enum | ポートの IP アドレスタイプ<br>`fixed` または `floating` のいずれか                                                                                                                                                                |
| servers.links | Body | Object | インスタンスパスオブジェクト                                                                                                                                                                                                |
| servers.key_name | Body | String | インスタンスのキーペア名                                                                                                                                                                                               |
| servers.image | Body | Object | インスタンスイメージオブジェクト                                                                                                                                                                                               |
| servers.image.id | Body | UUID | インスタンスイメージ ID                                                                                                                                                                                               |
| servers.image.links | Body | Object | インスタンスイメージパスオブジェクト                                                                                                                                                                                            |
| servers.OS-EXT-STS:task_state | Body | String | インスタンスのタスク状態<br>インスタンスに操作を加えた際の処理進行状態を示します                                                                                                                                                               |
| servers.OS-EXT-STS:vm_state | Body | String | インスタンスの現在の状態                                                                                                                                                                                                |
| servers.OS-SRV-USG:launched_at | Body | Datetime | インスタンスの最終起動日時<br>`YYYY-MM-DDThh:mm:ss.ssssss` 形式                                                                                                                                                         |
| servers.OS-SRV-USG:terminated_at | Body | Datetime | インスタンスの削除日時<br>`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                   |
| servers.flavor | Body | Object | インスタンスタイプ情報オブジェクト                                                                                                                                                                                             |
| servers.flavor.id | Body | UUID | インスタンスタイプ ID                                                                                                                                                                                                |
| servers.flavor.links | Body | Object | インスタンスタイプパスオブジェクト                                                                                                                                                                                             |
| servers.security_groups | Body | Object | インスタンスに割り当てられたセキュリティグループ一覧オブジェクト                                                                                                                                                                                     |
| servers.security_groups.name | Body | String | インスタンスに割り当てられたセキュリティグループ名                                                                                                                                                                                        |
| servers.user_id | Body | String | インスタンスを作成したユーザー ID                                                                                                                                                                                          |
| servers.created | Body | Datetime | インスタンスの作成日時。`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                     |
| servers.tenant_id | Body | String | インスタンスが属するテナント ID                                                                                                                                                                                           |
| servers.os-extended-volumes:volumes_attached | Body | Object | インスタンスに接続された追加ブロックストレージ一覧オブジェクト                                                                                                                                                                                |
| servers.os-extended-volumes:volumes_attached.id | Body | UUID | インスタンスに接続された追加ブロックストレージ ID                                                                                                                                                                                   |
| servers.OS-EXT-STS:power_state | Body | Integer | インスタンスの電源状態<br>- `1`: On<br>- `4`: Off                                                                                                                                                                    |
| servers.metadata | Body | Object | インスタンスメタデータオブジェクト<br>インスタンスのメタデータをキーと値のペアで保持します                                                                                                                                                                   |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | インスタンスに接続された追加ローカルブロックストレージのサイズ                                                                                                                                                                   |
| server.NHN-EXT-ATTR:protect | Body | Boolean | インスタンスの削除保護の有無                                                                                                                                                                   |

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

### インスタンスの表示

```
GET /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

#### リクエスト

このAPIはリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | インスタンスID |
| tokenId | Header | String | O | トークンID |

#### レスポンス

| 名前 | 種類 | 形式 | 説明                                                                                                                                                                                                       |
|---|---|---|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server | body | Object | インスタンスオブジェクト                                                                                                                                                                                                  |
| status | body | Enum | インスタンスのステータス                                                                                                                                                                                                  |
| server.id | Body | UUID | インスタンス ID                                                                                                                                                                                                  |
| server.name | Body | String | インスタンス名、最大 255 文字                                                                                                                                                                                         |
| server.updated | Body | Datetime | インスタンスの最終更新日時、`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                 |
| server.hostId | Body | String | インスタンスが稼働しているホスト ID                                                                                                                                                                                       |
| server.addresses | Body | Object | インスタンスの IP リストオブジェクト <br>インスタンスに接続されたポート数分のリストが生成されます                                                                                                                                                              |
| server.addresses."Network 名" | Body | Object | インスタンスに接続されたネットワークごとのポート情報                                                                                                                                                                                 |
| server.addresses."Network 名".OS-EXT-IPS-MAC:mac_addr | Body | String | インスタンスに接続されたポートの MAC アドレス                                                                                                                                                                                     |
| server.addresses."Network 名".version | Body | Integer | インスタンスに接続されたポートの IP バージョン<br>NHN Cloud は IPv4 のみをサポートします                                                                                                                                               |
| server.addresses."Network 名".addr | Body | String | インスタンスに接続されたポートの IP アドレス                                                                                                                                                                                      |
| server.addresses."Network 名".OS-EXT-IPS:type | Body | Enum | ポートの IP アドレスタイプ<br>`fixed` または `floating` のいずれか                                                                                                                                               |
| server.links | Body | Object | インスタンスパスオブジェクト                                                                                                                                                                                               |
| server.key_name | Body | String | インスタンスのキーペア名                                                                                                                                                                                              |
| server.image | Body | Object | インスタンスイメージオブジェクト                                                                                                                                                                                              |
| server.image.id | Body | UUID | インスタンスイメージ ID                                                                                                                                                                                              |
| server.image.links | Body | Object | インスタンスイメージパスオブジェクト                                                                                                                                                                                           |
| server.OS-EXT-STS:task_state | Body | String | インスタンスのタスク状態<br>インスタンスに操作を実行したときの進行状態を通知します                                                                                                                                               |
| server.OS-EXT-STS:vm_state | Body | String | インスタンスの現在の状態                                                                                                                                                                                               |
| server.OS-SRV-USG:launched_at | Body | Datetime | インスタンスの最終起動日時<br>`YYYY-MM-DDThh:mm:ss.ssssss` 形式                                                                                                                                                        |
| server.OS-SRV-USG:terminated_at | Body | Datetime | インスタンスの削除日時<br>`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                  |
| server.flavor | Body | Object | インスタンスタイプ情報オブジェクト                                                                                                                                                                                            |
| server.flavor.id | Body | UUID | インスタンスタイプ ID                                                                                                                                                                                               |
| server.flavor.links | Body | Object | インスタンスタイプパスオブジェクト                                                                                                                                                                                            |
| server.security_groups | Body | Object | インスタンスに割り当てられたセキュリティグループリストオブジェクト                                                                                                                                                                                    |
| server.security_groups.name | Body | String | インスタンスに割り当てられたセキュリティグループ名                                                                                                                                                                                       |
| server.user_id | Body | String | インスタンスを作成したユーザー ID                                                                                                                                                                                         |
| server.created | Body | Datetime | インスタンスの作成日時、`YYYY-MM-DDThh:mm:ssZ` 形式                                                                                                                                                                    |
| server.tenant_id | Body | String | インスタンスが属するテナント ID                                                                                                                                                                                          |
| server.os-extended-volumes:volumes_attached | Body | Object | インスタンスに接続された追加ブロックストレージリストオブジェクト                                                                                                                                                                               |
| server.os-extended-volumes:volumes_attached.id | Body | UUID | インスタンスに接続された追加ブロックストレージ ID                                                                                                                                                                                  |
| server.OS-EXT-STS:power_state | Body | Integer | インスタンスの電源状態<br>- `1`: On<br>- `4`: Off                                                                                                                                                                   |
| server.metadata | Body | Object | インスタンスメタデータオブジェクト<br>インスタンスメタデータをキーと値のペアで保持します                                                                                                                                                                  |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | インスタンスに接続された追加ローカルブロックストレージのサイズ                                                                                                                                                                  |
| server.NHN-EXT-ATTR:protect | Body | Boolean | インスタンスの削除保護の有効/無効                                                                                                                                                                  |

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

### インスタンスの作成

インスタンスを作成します。

インスタンス作成 API を呼び出した後、インスタンス照会によってインスタンスの状態を確認します。

* インスタンスの状態が **ACTIVE** になると、インスタンスが正常に作成完了します。
* インスタンスの状態が **BUILDING** のまま長時間経過する場合、または **ERROR** の場合は、インスタンス作成パラメータを確認し、再度作成を試みます。

Windows インスタンスは、安定した動作のために次の作成制約条件があります。

* RAM が 2 GB 以上のインスタンスタイプを使用します。
* 50 GB 以上のルートブロックストレージが必要です。
* U2 タイプは Windows イメージを使用することはできません。

ルートブロックストレージのサイズは、Linux は 10 GB、Windows は 50 GB から指定できます。

インスタンス作成リクエスト時に、スケジューラーヒントを通じて配置ポリシーを割り当てることができます。



```
POST /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| server | body | Object | O | サーバーオブジェクト |
| server.security_groups | body | Object | - | セキュリティグループリストオブジェクト<br>省略した場合、`default` グループが追加されます |
| server.security_groups.name | body | String | - | **(条件付き必須)** インスタンスに追加するセキュリティグループ名 |
| server.user_data | body | String | - | インスタンス起動後に実行するスクリプトおよび設定<br>base64 エンコードされた文字列で 65535 バイトまで許可 |
| server.availability_zone | body | String | - | インスタンスを作成する可用性ゾーン<br>指定しない場合は任意に選択されます<br>ルートブロックストレージのソースタイプが `volume`、`snapshot` の場合は、元のブロックストレージの可用性ゾーンと同じに設定する必要があります |
| server.imageRef | Body | String | - | インスタンス作成時に使用するイメージ ID<br>ルートブロックストレージのソースタイプが `volume`、`snapshot` の場合は設定不要 |
| server.flavorRef | Body | String | O | インスタンス作成時に使用するインスタンスタイプ ID |
| server.networks | Body | Object | O | インスタンス作成時に使用するネットワーク情報オブジェクト<br>指定した数だけ NIC が追加されます。ネットワーク ID、サブネット ID、ポート ID、固定 IP のいずれかで指定します |
| server.networks.uuid | Body | UUID | - | **(条件付き必須)** インスタンス作成時に使用するネットワーク ID |
| server.networks.subnet | Body | UUID | - | **(条件付き必須)** インスタンス作成時に使用するネットワークのサブネット ID |
| server.networks.port | Body | UUID | - | **(条件付き必須)** インスタンス作成時に使用するポート ID<br>ポート ID を指定した場合、リクエストしたセキュリティグループは指定した既存ポートに適用されません |
| server.networks.fixed_ip | Body | String | - | **(条件付き必須)** インスタンス作成時に使用する固定 IP |
| server.name | Body | String | O | インスタンスの名前<br>英字基準で 255 文字まで許可されますが、Windows イメージの場合は 15 文字以下である必要があります |
| server.metadata | Body | Object | - | インスタンスに追加するメタデータオブジェクト<br>最大長 255 文字以下のキーと値のペア |
| server.block_device_mapping_v2 | Body | Object | O | インスタンスのブロックストレージ情報オブジェクト |
| server.block_device_mapping_v2.source_type | Body | Enum | O | 作成するブロックストレージの元のタイプ<br>- `image`: イメージを使用してブロックストレージを作成<br>- `blank`: 空のブロックストレージを作成（ルートブロックストレージとしては使用できません）<br>- `volume`: 既存のブロックストレージを使用<br>- `snapshot`: スナップショットを使用してブロックストレージを作成 |
| server.block_device_mapping_v2.uuid | Body | String | - | **(条件付き必須)** ブロックストレージのソースタイプに応じて異なる設定が必要<br>- ソースタイプが `image` の場合はイメージ ID を設定<br>- ソースタイプが `volume` の場合は既存のブロックストレージ ID を設定<br>- ソースタイプが `snapshot` の場合はスナップショット ID を設定<br>- ソースタイプが `blank` の場合は設定不要<br>ルートブロックストレージの場合は必ず起動可能な元データである必要があります |
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 指定したブロックストレージの起動順序<br>- `0` の場合はルートブロックストレージ<br>- それ以外は追加ブロックストレージ<br>値が大きいほど起動順序は低くなります |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | インスタンスのブロックストレージの配置場所。インスタンスタイプに応じて異なる設定が必要です。<br>- `local`: GPU インスタンス、U2 インスタンスタイプを使用する場合<br>- `volume`: その他のインスタンスタイプを使用する場合 |
| server.block_device_mapping_v2.volume_type | Body | Enum    | - | **(条件付き必須)** 作成するブロックストレージのタイプ<br>ブロックストレージのソースタイプが `volume`、`snapshot` の場合は設定不要<br>`ユーザーガイド > Storage > Block Storage > API v2ガイド` の **ブロックストレージタイプ一覧表示** レスポンスの `name` を参照 |
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | インスタンス削除時のブロックストレージの処理方法。デフォルト値は `false` です。<br>`true` の場合は削除、`false` の場合は保持 |
| server.block_device_mapping_v2.volume_size | Body | Integer | - | **(条件付き必須)** 作成するブロックストレージのサイズ<br>ブロックストレージのソースタイプに応じて異なる設定が必要<br>- ソースタイプが `volume` の場合は設定不要<br>- ソースタイプが `snapshot` の場合は元のブロックストレージのサイズ以上に設定<br>`GB` 単位<br>U2 インスタンスタイプを使用してルートブロックストレージを作成する場合は、U2 インスタンスタイプに指定されたサイズで作成されるため、この値は無視されます<br>インスタンスタイプによって作成できるルートブロックストレージのサイズが異なりますので、詳細は `ユーザーガイド > Compute > Instance > コンソール使用ガイド > インスタンスの作成 > ブロックストレージサイズ` を参照してください |
| server.block_device_mapping_v2.nhn_encryption                   | Body | Object | - | **(条件付き必須)** ブロックストレージの暗号化情報                                                                                                                                                                                        |
| server.block_device_mapping_v2.nhn_encryption.skm_appkey        | Body | String | - | **(条件付き必須)** Secure Key Manager サービスのアプリケーションキー                                                                                                                                                                              |
| server.block_device_mapping_v2.nhn_encryption.skm_key_id        | Body | String | - | **(条件付き必須)** 暗号化ブロックストレージ作成に使用する Secure Key Manager の対称キー ID                                                                                                                                  |
| server.key_name | Body | String | O | インスタンス接続に使用するキーペア |
| server.min_count | Body | Integer | - | 現在のリクエストで作成するインスタンス数の最小値。<br>デフォルト値は 1 です。<br>ブロックストレージのソースタイプが `volume` の場合は `1` のみ設定可能 |
| server.max_count | Body | Integer | - | 現在のリクエストで作成するインスタンス数の最大値。<br>デフォルト値は min_count、最大値は 10 です。<br>ブロックストレージのソースタイプが `volume` の場合は `1` のみ設定可能 |
| server.return_reservation_id | Body | Boolean | - | インスタンス作成リクエストの予約 ID。<br>True を指定するとインスタンス作成情報の代わりに予約 ID を返します。<br>デフォルト値は False |
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

### インスタンスの修正
作成されたインスタンスを修正します。変更できる属性は一部の項目に制限されます。

```
PUT /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| server | Body | Object | O | インスタンス変更リクエストオブジェクト |
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

#### レスポンス
インスタンスの表示と同じです。

---

<a id="delete-instance"></a>

### インスタンスの削除
作成されたインスタンスを削除します。

```
DELETE /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

#### リクエスト
この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 削除するインスタンス ID |
| tokenId | Header | String | O | トークン ID |

#### レスポンス
この API はレスポンス本文を返しません。

---

<a id="manage-block-storage-attachment"></a>

## ブロックストレージ接続管理

<a id="list-additional-block-storage-attached-to-the-instance"></a>
### インスタンスに接続されたブロックストレージの一覧表示
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

#### リクエスト
この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| limit | Query | Integer | - | 照会するリストの件数 |
| offset | Query | Integer | - | 返却するリストの開始位置<br>全リストのうち offset 番目のブロックストレージから返却 |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| volumeAttachments | Body | Array | 接続情報オブジェクトの一覧 |
| volumeAttachments.device | Body | String | インスタンスのブロックストレージ名<br>例) `/dev/vdb` |
| volumeAttachments.id | Body | UUID | 接続情報 ID |
| volumeAttachments.serverId | Body | UUID | インスタンス ID |
| volumeAttachments.volumeId | Body | UUID | ブロックストレージ ID |

<details><summary>例</summary>
<p>

```json
{
    "volumeAttachments": [
        {
            "device": "/dev/vda",
            "id": "227cc671-f30b-4488-96fd-7d0bf13648d8",
            "serverId": "4b293d31-ebd5-4a7f-be03-874b90021e54",
            "volumeId": "227cc671-f30b-4488-96fd-7d0bf13648d8"
        },
        {
            "device": "/dev/vdb",
            "id": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113",
            "serverId": "4b293d31-ebd5-4a7f-be03-874b90021e54",
            "volumeId": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113"
        }
    ]
}
```

</p>
</details>

---

<a id="list-additional-block-storage-attached-to-the-instance"></a>
### インスタンスに接続されたブロックストレージの確認
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

#### リクエスト
この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | インスタンス ID |
| volumeId | URL | UUID | O | 照会するブロックストレージ ID |
| tokenId | Header | String | O | トークン ID |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| volumeAttachment | Body | Object | 接続情報オブジェクト |
| volumeAttachment.device | Body | String | インスタンスのブロックストレージ名<br>例) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | 接続情報 ID |
| volumeAttachment.serverId | Body | UUID | インスタンス ID |
| volumeAttachment.volumeId | Body | UUID | ブロックストレージ ID |

<details><summary>例</summary>
<p>

```json
{
    "volumeAttachment": {
        "device": "/dev/sdb",
        "id": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113",
        "serverId": "1ad6852e-6605-4510-b639-d0bff864b49a",
        "volumeId": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113"
    }
}
```

</p>
</details>

---

<a id="attach-additional-block-storage-to-the-instance"></a>
### インスタンスへの追加ブロックストレージの接続
```
POST /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| volumeAttachment | Body | Object | O | ブロックストレージ接続リクエストオブジェクト |
| volumeAttachment.volumeId | Body | UUID | O | 接続するブロックストレージ ID |

<details><summary>例</summary>
<p>

```json
{
  "volumeAttachment": {
      "volumeId": "a07f71dc-8151-4e7d-a0cc-cd24a3f11113"
  }
}
```

</p>
</details>

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| volumeAttachment | Body | Object | 接続情報オブジェクト |
| volumeAttachment.device | Body | String | インスタンスのブロックストレージ名<br>例) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | 接続情報 ID |
| volumeAttachment.serverId | Body | UUID | インスタンス ID |
| volumeAttachment.volumeId | Body | UUID | ブロックストレージ ID |

<details><summary>例</summary>
<p>

```json
{
    "volumeAttachment": {
        "device": "/dev/vdc",
        "id": "227cc671-f30b-4488-96fd-7d0bf13648d8",
        "serverId": "4b293d31-ebd5-4a7f-be03-874b90021e54",
        "volumeId": "227cc671-f30b-4488-96fd-7d0bf13648d8"
    }
}
```

</p>
</details>

---

<a id="detach-block-storage-from-the-instance"></a>
### インスタンスのブロックストレージの接続解除
```
DELETE /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

#### リクエスト
この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | インスタンス ID |
| volumeId | URL | UUID | O | 接続を解除するブロックストレージ ID |
| tokenId | Header | String | O | トークン ID |

#### レスポンス
この API はレスポンス本文を返しません。

---

<a id="additional-instance-features"></a>

## インスタンス追加機能
NHN Cloud は次のインスタンス制御および付加機能を提供します。

* インスタンスの起動、停止、終了、再起動
* インスタンスタイプの変更
* インスタンスイメージの作成
* セキュリティグループの追加および削除

<a id="start-stopped-instance"></a>
### 停止中のインスタンスの起動

停止中のインスタンスを再起動し、状態を **ACTIVE** に変更します。この API を呼び出すには、インスタンスの状態が **SHUTOFF** である必要があります。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| os-start | Body | none | O | インスタンス起動リクエスト |

<details><summary>例</summary>
<p>

```json
{
  "os-start" : null
}
```

</p>
</details>

#### レスポンス
この API はレスポンス本文を返しません。

---

<a id="start-terminated-instance"></a>
### 終了したインスタンスの起動

終了したインスタンスを再起動し、状態を **ACTIVE** に変更します。この API を呼び出すには、インスタンスの状態が **SHELVED_OFFLOADED** である必要があります。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|--|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| unshelve | Body | none | O | インスタンス起動リクエスト |

<details><summary>例</summary>
<p>

```json
{
  "unshelve" : null
}
```

</p>
</details>

#### レスポンス
この API はレスポンス本文を返しません。

---

<a id="stop-instance"></a>
### インスタンスの停止

インスタンスを停止し、状態を **SHUTOFF** に変更します。この API を呼び出すには、インスタンスの状態が **ACTIVE** または **ERROR** である必要があります。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| os-stop | Body | none | O | インスタンス停止リクエスト |

<details><summary>例</summary>
<p>

```json
{
  "os-stop" : null
}
```

</p>
</details>

#### レスポンス
この API はレスポンス本文を返しません。

---

### インスタンスの終了

インスタンスを終了し、状態を **SHELVED_OFFLOADED** に変更します。この API を呼び出すには、インスタンスの状態が **ACTIVE** である必要があります。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明          |
|---|---|---|---|-------------|
| tenantId | URL | String | O | テナント ID      |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID       |
| shelve | Body | none | O | インスタンス終了リクエスト  |

<details><summary>例</summary>
<p>

```json
{
  "shelve" : null
}
```

</p>
</details>

#### レスポンス
この API はレスポンス本文を返しません。

---

### インスタンスの再起動

インスタンスを再起動します。再起動方式は **SOFT** と **HARD** に分けられます。

* **SOFT** 方式：**「グレースフルシャットダウン (Graceful shutdown)」** によりインスタンスを停止し、再起動します。インスタンスが **ACTIVE** 状態である必要があります。
* **HARD** 方式：強制停止後にインスタンスを再起動します。物理サーバーの電源をオフにして再度オンにする操作と同じ動作です。次の状態のインスタンスのみ強制停止できます。
    * **ACTIVE**
    * **ERROR**
    * **HARD_REBOOT**
    * **PAUSED**
    * **REBOOT**
    * **SHUTOFF**
    * **SUSPENDED**

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| reboot | Body | Object | O | インスタンス再起動リクエストオブジェクト |
| reboot.type | Body | Enum | O | 再起動方式、**SOFT** または **HARD** |

<details><summary>例</summary>
<p>

```json
{
  "reboot" : {
    "type": "SOFT"
  }
}
```

</p>
</details>

#### レスポンス
この API はレスポンス本文を返しません。

---

### インスタンスタイプの変更

インスタンスタイプを変更します。インスタンスの状態が **ACTIVE** または **SHUTOFF** の場合のみ、インスタンスタイプを変更できます。インスタンスの状態が **ACTIVE** の場合、インスタンスタイプの変更過程でインスタンスは停止され、再起動されます。

使用するイメージやインスタンスタイプによって、変更できるタイプが制限される場合があります。詳細な変更制約については、コンソール使用ガイドを参照してください。


```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明                                                                                                                                                                                                                 |
|---|---|---|---|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| tenantId | URL | String | O | テナント ID                                                                                                                                                                                                             |
| serverId | URL | UUID | O | 変更するインスタンス ID                                                                                                                                                                                                        |
| tokenId | Header | String | O | トークン ID                                                                                                                                                                                                              |
| resize | Body | Object | O | インスタンスタイプ変更リクエスト                                                                                                                                                                                                      |
| resize.flavorRef | Body | UUID | O | 変更するインスタンスタイプ ID                                                                                                                                                                                                     |

<details><summary>例</summary>
<p>

```json
{
  "resize" : {
    "flavorRef": "b5f1c148-732c-417d-9d1b-1dffca105dbe"
  }
}
```

</p>
</details>

#### レスポンス
この API はレスポンス本文を返しません。

---

### インスタンスイメージの作成

インスタンスからイメージを作成します。`U2` タイプのインスタンスのみ、この API を使用してイメージを作成できます。`U2` タイプ以外のインスタンスイメージの作成については、[ブロックストレージ API](/Storage/Block Storage/ja/public-api/#create-image-with-block-storage) を参照してください。

インスタンスの状態が **ACTIVE**、**SHUTOFF**、**SUSPENDED**、**PAUSED** の場合のみ、イメージを作成できます。イメージの作成はデータの整合性を保証するため、インスタンスを停止した状態で行うことをお勧めします。

イメージの作成が成功すると、イメージの状態が `active` に変わります。イメージの作成が完了したことを確認するには、イメージ照会 API を使用して継続的に状態を確認します。

> [注意]
> 作成されたイメージのサイズは、ルートブロックストレージの実際の使用量より大きくなる場合があります。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| createImage | Body | Object | O | イメージ作成リクエスト |
| createImage.name | Body | String | O | 作成するイメージ名 |
| createImage.metadata | Body | Object | - | 作成するイメージのメタデータ<br>Key-Value 形式で記述 |

<details><summary>例</summary>
<p>

```json
{
  "createImage" : {
      "name" : "foo-image",
      "metadata": {
          "meta_var": "meta_val"
      }
  }
}
```

</p>
</details>


#### レスポンス

この API はレスポンス本文を返しません。作成されたイメージは、レスポンスヘッダーの `Location` で確認します。

| 名前 | 種類 | 形式 | 説明 |
|--|--|--|--|
| Location | Header | String | 作成したイメージ URL |

---

### セキュリティグループの追加

インスタンスにセキュリティグループを追加します。追加したセキュリティグループは、インスタンスのすべてのポートに適用されます。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| addSecurityGroup | Body | Object | O | セキュリティグループ追加リクエストオブジェクト |
| addSecurityGroup.name | Body | String | O | 追加するセキュリティグループ名 |

<details><summary>例</summary>
<p>

```json
{
    "addSecurityGroup": {
        "name": "test"
    }
}
```

</p>
</details>


#### レスポンス
この API はレスポンス本文を返しません。

---

### セキュリティグループの削除

インスタンスからセキュリティグループを削除します。インスタンスのすべてのポートから、指定したセキュリティグループが削除されます。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナント ID |
| serverId | URL | UUID | O | 変更するインスタンス ID |
| tokenId | Header | String | O | トークン ID |
| removeSecurityGroup | Body | Object | O | セキュリティグループ削除リクエストオブジェクト |
| removeSecurityGroup.name | Body | String | O | 削除するセキュリティグループ名 |

<details><summary>例</summary>
<p>

```json
{
    "removeSecurityGroup": {
        "name": "test"
    }
}
```

</p>
</details>


#### レスポンス
この API はレスポンス本文を返しません。


<a id="terminate-instance"></a>

## インスタンスメタデータ

インスタンスメタデータの値に従って、コンソールの **Compute > Instance** サービスページでインスタンスの詳細情報画面の内容を決定します。インスタンスメタデータごとの内容は次のとおりです。

| インスタンスメタデータ | 内容                                           |
|----------------|----------------------------------------------|
| os_distro      | **[基本情報]** の **[OS]** の名前<br>os_version と組み合わせて使用 |
| os_version     | **[基本情報]** の **[OS]** のバージョン<br>os_distro と組み合わせて使用  |
| image_name     | **[基本情報]** の **[イメージ名]**                        |
| os_type      | **[接続情報]** の形式                                 |
| login_username | **[接続情報]** のユーザー名                            |

> [注意] インスタンスメタデータを変更または削除した場合、関連するサービスおよび機能に影響が生じる可能性があります。その結果に対する責任はユーザーにあります。

### インスタンスメタデータ一覧の表示

```
GET /v2/{tenantId}/servers/{serverId}/metadata
X-Auth-Token: {tokenId}
```

#### リクエスト
この API はリクエスト本文を必要としません。

| 名前       | 種類 | 形式 | 必須 | 説明                                               |
|----------|---|---|---|--------------------------------------------------|
| tenantId | URL | String | O | テナント ID                                           |
| serverId | URL | UUID | O | インスタンス ID                                          |
| tokenId  | Header | String | O | トークン ID                                            |

#### レスポンス

| 名前       | 種類 | 形式 | 説明                                               |
|----------|---|---|--------------------------------------------------|
| metadata | Body | Object | インスタンスに作成または変更するメタデータオブジェクト<br>最大長 255 文字以下のキーと値のペア |

<details><summary>例</summary>
<p>

```json
{
    "metadata": {
        "os_distro": "ubuntu",
        "description": "Ubuntu Server 20.04.6 LTS (2023.11.21)",
        "volume_size": "20",
        "project_domain": "NORMAL",
        "monitoring_agent": "sysmon",
        "image_name": "Ubuntu Server 20.04.6 LTS (2023.11.21)",
        "os_version": "Server 20.04 LTS",
        "os_architecture": "amd64",
        "login_username": "ubuntu",
        "os_type": "linux",
        "tc_env": "sysmon,dfeac7db42a192a73959d5646117af58"
    }
}
```

</p>
</details>


<a id="restart-instance"></a>
### インスタンスメタデータの表示

```
GET /v2/{tenantId}/servers/{serverId}/metadata/{key}
X-Auth-Token: {tokenId}
```

#### リクエスト
この API はリクエスト本文を必要としません。

| 名前       | 種類 | 形式 | 必須 | 説明                       |
|----------|---|---|---|--------------------------|
| tenantId | URL | String | O | テナント ID                   |
| serverId | URL | UUID | O | インスタンス ID                  |
| key      | URL | String | O | インスタンスに作成または変更するメタデータのキー |
| tokenId  | Header | String | O | トークン ID                    |

#### レスポンス

| 名前   | 種類 | 形式 | 説明                                               |
|------|---|---|--------------------------------------------------|
| meta | Body | Object | インスタンスに作成または変更するメタデータオブジェクト<br>最大長 255 文字以下のキーと値のペア |

<details><summary>例</summary>
<p>

```json
{
    "meta": {
        "os_version": "Server 20.04 LTS"
    }
}
```

</p>
</details>

<a id="change-instance-flavor"></a>
### インスタンスメタデータの作成/変更

インスタンスのメタデータを作成または変更します。
リクエストするキーが既存のキーと一致する場合、キーと値をリクエスト値に変更します。

```
PUT /v2/{tenantId}/servers/{serverId}/metadata/{key}
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前       | 種類 | 形式 | 必須 | 説明                                               |
|----------|---|---|---|--------------------------------------------------|
| tenantId | URL | String | O | テナント ID                                           |
| serverId | URL | UUID | O | インスタンス ID                                          |
| key      | URL | String | O | インスタンスに作成または変更するメタデータのキー                         |
| tokenId  | Header | String | O | トークン ID                                            |
| meta     | Body | Object | O | インスタンスに作成または変更するメタデータオブジェクト<br>最大長 255 文字以下のキーと値のペア |

<details>
<summary>例</summary>
<p>

```json
{
    "meta": {
        "os_version": "Server 20.04 LTS"
    }
}
```

</p>
</details>


#### レスポンス

| 名前   | 種類 | 形式 | 説明                                               |
|------|---|---|--------------------------------------------------|
| meta | Body | Object | インスタンスに作成または変更するメタデータオブジェクト<br>最大長 255 文字以下のキーと値のペア |

<details><summary>例</summary>
<p>

```json
{
    "meta": {
        "os_version": "Server 20.04 LTS"
    }
}
```

</p>
</details>


<a id="create-instance-image"></a>
### インスタンスメタデータの削除

リクエストするキーと一致するインスタンスのメタデータを削除します。

```
DELETE /v2/{tenantId}/servers/{serverId}/metadata/{key}
X-Auth-Token: {tokenId}
```

#### リクエスト
この API はリクエスト本文を必要としません。

| 名前       | 種類 | 形式 | 必須 | 説明                  |
|----------|---|---|---|---------------------|
| tenantId | URL | String | O | テナント ID              |
| serverId | URL | UUID | O | インスタンス ID             |
| key      | URL | String | O | インスタンスから削除するメタデータのキー |
| tokenId  | Header | String | O | トークン ID               |

#### レスポンス
この API はレスポンス本文を返しません。

## 配置ポリシー

<a id="add-security-group"></a>
### 配置ポリシーの作成

配置ポリシーを作成します。
分散配置のための `anti-affinity` 配置ポリシータイプのみ提供します。

```
POST /v2/{tenantId}/os-server-groups
X-Auth-Token: {tokenId}
```

#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |
| server_group | Body | Object | O | 配置ポリシーオブジェクト |
| server_group.name | Body | String | O | 配置ポリシー名 |
| server_group.policies | Body | Array | O | 配置ポリシータイプ<br>`anti-affinity` のみ設定可能 |

<details>
<summary>例</summary>
<p>

```json
{
    "server_group": {
        "name": "policy-test1",
        "policies": [
            "anti-affinity"            
        ]
    }
}
```

</p>
</details>

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|-----|-----|-----|-----|
| server_group | Body | Object | 配置ポリシーオブジェクト |
| server_group.id | Body | String | 配置ポリシー ID |
| server_group.name | Body | String | 配置ポリシー名 |
| server_group.policies | Body | Array | 配置ポリシータイプ |
| server_group.members | Body | Array | 配置ポリシーに割り当てられたインスタンス ID の一覧 |
| server_group.metadata | Body | Object | 配置ポリシーメタデータオブジェクト<br>常に空の値として表示されます |

<details><summary>例</summary>
<p>

```json
{
    "server_group": {
        "id": "11f5a850-9ecc-4895-af77-de6ea471b65a",
        "name": "policy-test1",
        "policies": [
            "anti-affinity"
        ],
        "members": [],
        "metadata": {}
    }
}
```

</p>
</details>

<a id="delete-security-group"></a>
### 配置ポリシー一覧の表示

```
GET /v2/{tenantId}/os-server-groups
X-Auth-Token: {tokenId}
```

#### リクエスト

この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | テナント ID |
| tokenId | Header | String | O | トークン ID |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|-----|-----|-----|-----|
| server_groups | Body | Array | 配置ポリシーオブジェクトの一覧 |
| server_groups.id | Body | String | 配置ポリシー ID |
| server_groups.name | Body | String | 配置ポリシー名 |
| server_groups.policies | Body | Array | 配置ポリシータイプ |
| server_groups.members | Body | Array | 配置ポリシーに割り当てられたインスタンス ID の一覧 |
| server_groups.metadata | Body | Object | 配置ポリシーメタデータオブジェクト<br>常に空の値として表示されます |

<details><summary>例</summary>
<p>

```json
{
    "server_groups": [
        {
            "id": "11f5a850-9ecc-4895-af77-de6ea471b65a",
            "name": "policy-test1",
            "policies": [
                "anti-affinity"
            ],
            "members": [
                "c040455d-6495-4628-ad81-ade79cf7b8d6",
                "524e7d81-f373-43a0-b2ff-0a15f8255bb5"            
            ],
            "metadata": {}
        },
        {
            "id": "f947c657-cbe0-4bf2-a2aa-59d198f8e096",
            "name": "policy-test2",
            "policies": [
                "anti-affinity"
            ],
            "members": [],
            "metadata": {}
        }
    ]
}
```

</p>
</details>

### 配置ポリシーの表示

```
GET /v2/{tenantId}/os-server-groups/{servergroupId}
X-Auth-Token: {tokenId}
```

#### リクエスト

この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | テナント ID |
| servergroupId | URL | String | O | 配置ポリシー ID |
| tokenId | Header | String | O | トークン ID |

#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|-----|-----|-----|-----|
| server_group | Body | Object | 配置ポリシーオブジェクト |
| server_group.id | Body | String | 配置ポリシー ID |
| server_group.name | Body | String | 配置ポリシー名 |
| server_group.policies | Body | Array | 配置ポリシータイプ |
| server_group.members | Body | Array | 配置ポリシーに割り当てられたインスタンス ID の一覧 |
| server_group.metadata | Body | Object | 配置ポリシーメタデータオブジェクト<br>常に空の値として表示されます |

<details><summary>例</summary>
<p>

```json
{
    "server_group": {
        "id": "11f5a850-9ecc-4895-af77-de6ea471b65a",
        "name": "policy-test1",
        "policies": [
            "anti-affinity"
        ],
        "members": [
            "c040455d-6495-4628-ad81-ade79cf7b8d6",
            "524e7d81-f373-43a0-b2ff-0a15f8255bb5"            
        ],
        "metadata": {}
    }
}
```

</p>
</details>

### 配置ポリシーの削除

```
DELETE /v2/{tenantId}/os-server-groups/{servergroupId}
X-Auth-Token: {tokenId}
```

#### リクエスト

この API はリクエスト本文を必要としません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | テナント ID |
| servergroupId | URL | String | O | 配置ポリシー ID |
| tokenId | Header | String | O | トークン ID |

#### レスポンス

この API はレスポンス本文を返しません。