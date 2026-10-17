<!-- machine_translated: true -->

{% set f = (build_flags | select("in", ["public","gov","ncgn","ninc","ngsc","ngovc","ngoic"]) | list | first) %}
{% set ep_domain = {"ninc":"ninc.go.kr","ngsc":"ngsc.go.kr","ngovc":"ngovc.com","ngoic":"ngoic.com"} %}

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2ガイド { #compute-instance-api-v2-guide }

{% if "public" in build_flags %}
InstanceはAPI呼び出し時の認証/認可にIaaSトークンを使用します。IaaSトークンは、NHN CloudのOpenStackベースのインフラサービス(IaaS)で使用する認証トークンです。IaaSトークンの発行および使用の詳細については、[IaaSトークン](/nhncloud/ja/public-api/iaas-token)を参照してください。
{% elif "gov" in build_flags %}
InstanceはAPI呼び出し時の認証/認可にIaaSトークンを使用します。IaaSトークンは、NHN CloudのOpenStackベースのインフラサービス(IaaS)で使用する認証トークンです。IaaSトークンの発行および使用の詳細については、[IaaSトークン](/nhncloud/ja/public-api/iaas-token-gov)を参照してください。
{% else %}
APIを使用するには、APIエンドポイントとトークンなどが必要です。[API使用の準備](/Compute/Compute/ja/identity-api/)を参照して、API使用に必要な情報を準備します。
{% endif %}

インスタンスAPIは`compute`タイプエンドポイントを利用します。正確なエンドポイントはトークン発行レスポンスの`serviceCatalog`を参照します。

| タイプ | リージョン | エンドポイント |
|---|---|---|
{%- if "public" in build_flags %}
| compute | 韓国(パンギョ)リージョン<br>韓国(ピョンチョン)リージョン<br>韓国(クァンジュ)リージョン<br>日本リージョン | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |
{% elif "gov" in build_flags %}
| compute | 韓国(パンギョ)リージョン<br>韓国(ピョンチョン)リージョン | https://kr1-api-instance-infrastructure.gov-nhncloudservice.com<br>https://kr2-api-instance-infrastructure.gov-nhncloudservice.com |
{% else %}
| compute | 韓国(大邱)リージョン | https://kr4-api-instance-infrastructure.$[ ep_domain[f] ]$ |
{% endif %}

APIレスポンスにガイドに明示されていないフィールドが表示される場合があります。それらのフィールドは、NHN Cloud内部用途で使用され、事前に告知せずに変更する場合があるため使用しないでください。

<a id="create-instance"></a>
### インスタンスを作成する { #create-instance }

インスタンスを作成します。

インスタンス作成APIを呼び出し、インスタンス照会でインスタンスの状態を確認します。

* インスタンスの状態が**ACTIVE**になるとインスタンスが正常に作成完了します。
* インスタンスの状態が**BUILDING**から長時間変わらなかったり、**ERROR**の場合は、インスタンス作成引数を確認し、再度作成してください。

* RAMが2GB以上のインスタンスタイプを使用します。

* Windowsインスタンスは2GB以上のRAMが必要です。RAM 2GB以上のインスタンスタイプを使用します。
* 50GB以上のルートブロックストレージが必要です。
* U2タイプはWindowsイメージを使用できません。

ルートブロックストレージサイズは、Linuxは10GB、Windowsは50GBから指定できます。

インスタンス作成リクエスト時にスケジューラヒントで配置ポリシーを割り当てることができます。



{% if "public" in build_flags %}

{% else %}
{% endif %}
```
POST /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="create-instance-request"></a>
#### リクエスト

{% if "public" in build_flags %}
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
{%- else %}
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| tokenId | Header | String | O | トークンID |
{%- endif %}
| server | body | Object | O | サーバーオブジェクト |
{%- if "public" in build_flags %}
| server.security_groups | body | Object | - | セキュリティグループリストオブジェクト<br>省略する場合`default`グループが追加される |
| server.security_groups.name | body | String | - | **(条件付き必須)** インスタンスに追加するセキュリティグループ名 |
| server.user_data | body | String | - | インスタンス起動後に実行するスクリプトおよび設定<br>base64エンコーディングされた文字列で65535バイトまで許可 |
{%- elif "gov" in build_flags %}
| server.security_groups | body | Object | - | セキュリティグループリストオブジェクト<br>省略した場合、`default` グループが追加されます |
| server.security_groups.name | body | String | - | **(条件付き必須)** インスタンスに追加するセキュリティグループの名前 |
| server.user_data | body | String | - | インスタンス起動後に実行するスクリプトおよび設定<br>base64エンコードされた文字列で65535バイトまで許可 |
{%- else %}
| server.security_groups | body | Object | - | セキュリティグループリストオブジェクト<br>省略した場合は`default`グループが追加されます |
| server.security_groups.name | body | String | - | インスタンスに追加するセキュリティグループ名 |
| server.user_data | body | String | - | インスタンス起動後に実行するスクリプトおよび設定<br>base64エンコードされた文字列で65535バイトまで許可 |
{%- endif %}
| server.availability_zone | body | String | - | インスタンスを作成するアベイラビリティゾーン<br>指定しない場合、任意のゾーンが選択される<br>ルートブロックストレージのソースタイプが`volume`, `snapshot`の場合、元のブロックストレージのアベイラビリティゾーンと同じに設定する必要があります。 |
| server.imageRef | Body | String | - | インスタンスを作成する際に使用するイメージID<br>ルートブロックストレージのソースタイプが`volume`, `snapshot`の場合は設定不要 |
{%- if "public" in build_flags %}
| server.flavorRef | Body | String | O | インスタンスを作成する時に使用するインスタンスタイプID |
| server.networks | Body | Object | O | インスタンスを作成する時に使用するネットワーク情報オブジェクト<br>指定した数のNICが追加される。ネットワークID、サブネットID、ポートID、固定IPの中から1つ指定 |
| server.networks.uuid | Body | UUID | - |  **(条件付き必須)**インスタンスを作成する時に使用するネットワークID |
| server.networks.subnet | Body | UUID | - |  **(条件付き必須)**インスタンスを作成する時に使用するネットワークのサブネットID |
| server.networks.port | Body | UUID | - |  **(条件付き必須)**インスタンスを作成する際に使用するポートID<br>ポートIDを指定する際に要求したセキュリティグループは、指定した既存のポートには適用されない。 |
| server.networks.fixed_ip | Body | String | - |  **(条件付き必須)**インスタンスを作成する時に使用する固定IP |
| server.name | Body | String | O | インスタンスの名前<br>英字基準255文字まで許可、ただし、Windowsイメージの場合は15文字以下にする必要がある。 |
| server.metadata | Body | Object | - | インスタンスに追加するメタデータオブジェクト<br>255文字以下のキーと値のペア |
{%- elif "gov" in build_flags %}
| server.flavorRef | Body | String | O | インスタンスを作成する際に使用するインスタンスタイプID |
| server.networks | Body | Object | O | インスタンスを作成する際に使用するネットワーク情報オブジェクト<br>指定した数だけNICが追加され、ネットワークID、サブネットID、ポートID、固定IPのいずれかで指定 |
| server.networks.uuid | Body | UUID | - | **(条件付き必須)** インスタンスを作成する際に使用するネットワークID |
| server.networks.subnet | Body | UUID | - | **(条件付き必須)** インスタンスの作成時に使用するネットワークのサブネットID |
| server.networks.port | Body | UUID | - | **(条件付き必須)** インスタンスを作成する際に使用するポートID<br>ポートIDを指定した場合、リクエストしたセキュリティグループは指定した既存のポートに適用されません |
| server.networks.fixed_ip | Body | String | - | **(条件付き必須)** インスタンス作成時に使用する固定IP |
| server.name | Body | String | O | インスタンスの名前<br>英字基準で255文字まで許可されますが、Windowsイメージの場合は15文字以下である必要があります |
| server.metadata | Body | Object | - | インスタンスに追加するメタデータオブジェクト<br>最大255文字以下のキーと値のペア |
{%- else %}
| server.flavorRef | Body | String | O | インスタンスを作成する際に使用するインスタンスタイプID |
| server.networks | Body | Object | O | インスタンスを作成する際に使用するネットワーク情報オブジェクト<br>指定した数だけNICが追加され、ネットワークID、サブネットID、ポートID、固定IPのいずれか一つで指定 |
| server.networks.uuid | Body | UUID | - | **(条件付き必須)** インスタンスを作成する際に使用するネットワークID |
| server.networks.subnet | Body | UUID | - | **(条件付き必須)** インスタンスを作成する際に使用するネットワークのサブネットID |
| server.networks.port | Body | UUID | - | **(条件付き必須)** インスタンスを作成する際に使用するポートID<br>ポートIDを指定した場合、リクエストしたセキュリティグループは指定した既存のポートに適用されません |
| server.networks.fixed_ip | Body | String | - | **(条件付き必須)** インスタンスを作成する際に使用する固定IP |
| server.name | Body | String | O | インスタンスの名前<br>英字基準で255文字まで許可されますが、Windowsイメージの場合は15文字以下である必要があります |
| server.metadata | Body | Object | - | インスタンスに追加するメタデータオブジェクト<br>最大255文字以下のキーと値のペア |
{%- endif %}
| server.block_device_mapping_v2 | Body | Object | O | インスタンスのブロックストレージ情報オブジェクト<br>**ローカルブロックストレージを使用するU2以外のインスタンスタイプを使用する場合は必ず指定する必要がある。** |
| server.block_device_mapping_v2.source_type | Body | Enum | O | 作成するブロックストレージ原本のタイプ<br>- `image`:イメージを利用してブロックストレージを作成<br>- `blank`:空のブロックストレージ作成(ルートブロックストレージとして使用できない)<br>- `volume`:既存のブロックストレージを使用<br>- `snapshot`:スナップショットを利用してブロックストレージ作成 |
| server.block_device_mapping_v2.uuid | Body | String | - |  **(条件付き必須)**ブロックストレージのソースタイプによって異なる設定が必要<br>- ソースタイプが`image`の場合、イメージIDを設定<br>- ソースタイプが`volume`の場合、既存のブロックストレージIDを設定<br>- ソースタイプが`snapshot`の場合、スナップショットIDを設定<br>- ソースタイプが`blank`の場合、設定不要<br>ルートブロックストレージの場合、必ず起動可能な原本である必要があります。 |
{%- if "public" in build_flags %}
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 指定したブロックストレージの起動順序<br>-`0`はルートブロックストレージ<br>- それ以外は追加ブロックストレージ<br>サイズが大きいほど起動順序が下がる。 |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | インスタンスブロックストレージの位置。インスタンスタイプに応じて別々に設定必要。<br>- `local`：GPUインスタンス、U2インスタンスタイプを利用する場合。<br>- `volume`：その他のインスタンスタイプを利用する場合。 |
{%- elif "gov" in build_flags %}
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 指定したブロックストレージの起動順序<br>`0`の場合はルートブロックストレージ<br>それ以外は追加ブロックストレージ<br>値が大きいほど起動順序は低くなります |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | インスタンスのブロックストレージの場所。インスタンスタイプに応じて異なる設定が必要です。<br>- `local`: GPUインスタンス、U2インスタンスタイプを使用する場合<br>- `volume`: その他のインスタンスタイプを使用する場合 |
{%- else %}
| server.block_device_mapping_v2.boot_index | Body | Integer | O | 指定したブロックストレージの起動順序<br>- `0`の場合はルートブロックストレージ<br>- それ以外は追加ブロックストレージ<br>値が大きいほど起動順序は低くなります |
{%- endif %}
| server.block_device_mapping_v2.volume_type | Body | Enum    | - |  **(条件付き必須)**作成するブロックストレージのタイプ<br>ブロックストレージのソースタイプが`volume`, `snapshot`の場合設定不要<br>`ユーザーガイド > Storage > Block Storage > API v2ガイド`で**ブロックストレージタイプリスト表示**レスポンスの`name`参考 |
{%- if "public" in build_flags %}
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | インスタンスを削除する時のブロックストレージ処理。デフォルト値は`false`。<br>`true`なら削除、`false`なら維持 |
{%- elif "gov" in build_flags %}
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | インスタンス削除時のブロックストレージの処理方法。デフォルト値は`false`。<br>`true`の場合は削除、`false`の場合は維持 |
{%- else %}
| server.block_device_mapping_v2.destination_type | Body | Enum | O | インスタンスブロックストレージの場所。インスタンスタイプによって異なる設定が必要です。<br>- `local`: U2インスタンスタイプを使用する場合<br>- `volume`: U2以外のインスタンスタイプを使用する場合                                                                          |
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | インスタンス削除時のブロックストレージの処理方法。デフォルト値は`false`。<br>`true`の場合は削除、`false`の場合は保持 |
{%- endif %}
| server.block_device_mapping_v2.volume_size | Body | Integer | - | **(条件付き必須)**作成するブロックストレージサイズ<br>ブロックストレージのソースタイプによって異なる設定が必要<br>- ソースタイプが`volume`の場合は設定不要<br>- ソースタイプが`snapshot`の場合は原本ブロックストレージサイズ以上に設定<br>`GB`単位<br>U2インスタンスタイプを使用してルートブロックストレージを作成する場合にはU2インスタンスタイプに明示されたサイズで作成され、この値は無視される。<br>インスタンスタイプによって作成できるルートブロックストレージのサイズが異なるため、詳細は`ユーザーガイド > Compute > Instance > コンソール使用ガイド > インスタンス作成 > ブロックストレージサイズ`を参考 |
{%- if "public" in build_flags %}
| server.block_device_mapping_v2.nhn_encryption                   | Body | Object | - | **(条件付き必須)**ブロックストレージの暗号化情報                                                                                                                                                                                      |
| server.block_device_mapping_v2.nhn_encryption.skm_appkey        | Body | String | - | **(条件付き必須)**Secure Key Managerサービスのアプリケーションキー                                                                                                                                                                            |
| server.block_device_mapping_v2.nhn_encryption.skm_key_id        | Body | String | - | **(条件付き必須)**暗号化ブロックストレージの作成に使用するSecure Key Managerの対称鍵ID                                                                                                                                  |
| server.key_name | Body | String | O | インスタンスの接続に使用するキーペア |
{%- else %}
| server.key_name | Body | String | O | インスタンスへの接続に使用するキーペア |
{%- endif %}
| server.min_count | Body | Integer | - | 現在のリクエストで作成するインスタンス数の最小値。<br>デフォルト値は1。<br>ブロックストレージのソースタイプが`volume`の場合、`1`のみ設定可能 |
| server.max_count | Body | Integer | - | 現在のリクエストで作成するインスタンス数の最大値。<br>デフォルト値はmin_count、最大値は10。<br>ブロックストレージのソースタイプが`volume`の場合、`1`のみ設定可能 |
{%- if "public" in build_flags %}
| server.return_reservation_id | Body | Boolean | - | インスタンス作成リクエスト予約ID。<br>Trueに指定すると、インスタンス作成情報の代わりに予約IDを返す。<br>デフォルト値はFalse |
{%- else %}
| server.return_reservation_id | Body | Boolean | - | インスタンス作成リクエストの予約ID。<br>Trueに設定すると、インスタンス作成情報の代わりに予約IDを返します。<br>デフォルト値はFalseです。 |
{%- endif %}
| os:scheduler_hints | Body | Object | - | スケジューラヒントオブジェクト |
| os:scheduler_hints.group | Body | String | - | 配置ポリシーID |

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

| 名前 | 種類 | 形式 | 説明                                                                                                                                                                                                          |
|---|---|---|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server.security_groups.name | Body | String | 作成したインスタンスのセキュリティグループ名                                                                                                                                                                                          |
| server.id | Body | UUID | 作成したインスタンスのID                                                                                                                                                                                                 |

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
{% if "public" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% elif "gov" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.gov-nhncloudservice.com/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% else %}
        "href": "https://kr4-api-instance-infrastructure.$[ ep_domain[f] ]$/v2/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% endif %}
        "rel": "self"
      },
      {
{% if "public" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% elif "gov" in build_flags %}
        "href": "https://kr1-api-instance-infrastructure.gov-nhncloudservice.com/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% else %}
        "href": "https://kr4-api-instance-infrastructure.$[ ep_domain[f] ]$/6cdebe3eb0094910bc41f1d42ebe4cb7/servers/3a005d5b-63cf-4493-bfc6-49db990b5b50",
{% endif %}
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
### インスタンスを修正する { #modify-instance }
作成されたインスタンスを修正します。変更できるプロパティは一部の項目に制限されます。

```
PUT /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="modify-instance-request"></a>
#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | 変更するインスタンスID |
| tokenId | Header | String | O | トークンID |
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

<a id="modify-instance-response"></a>
#### レスポンス
インスタンスの表示と同じです。

---

<a id="delete-instance"></a>
### インスタンスを削除する { #delete-instance }
作成されたインスタンスを削除します。

```
DELETE /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="delete-instance-request"></a>
#### リクエスト
このAPIはリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | 削除するインスタンスID |
| tokenId | Header | String | O | トークンID |

<a id="delete-instance-response"></a>
#### レスポンス
このAPIはレスポンス本文を返しません。

---

<a id="manage-block-storage-attachment"></a>
## ブロックストレージ接続管理 { #manage-block-storage-attachment }

<a id="list-additional-block-storage-attached-to-the-instance"></a>
### インスタンスに接続されたブロックストレージリスト表示 { #list-additional-block-storage-attached-to-the-instance }
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

<a id="list-additional-block-storage-attached-to-the-instance-request"></a>
#### リクエスト
このAPIはリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | 変更するインスタンスID |
| tokenId | Header | String | O | トークンID |
| limit | Query | Integer | - | 照会するリストの数 |
| offset | Query | Integer | - | 返されるリストの開始点<br>全てのリストの中からoffset番目のブロックストレージから返す |

<a id="list-additional-block-storage-attached-to-the-instance-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| volumeAttachments | Body | Array | 接続情報オブジェクトリスト |
| volumeAttachments.device | Body | String | インスタンスのブロックストレージ名<br>例) `/dev/vdb` |
| volumeAttachments.id | Body | UUID | 接続情報ID |
| volumeAttachments.serverId | Body | UUID | インスタンスID |
| volumeAttachments.volumeId | Body | UUID | ブロックストレージID |

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

<a id="show-additional-block-storage-attached-to-the-instance"></a>
### インスタンスに接続されたブロックストレージ表示 { #show-additional-block-storage-attached-to-the-instance }
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

<a id="show-additional-block-storage-attached-to-the-instance-request"></a>
#### リクエスト
このAPIはリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | インスタンスID |
| volumeId | URL | UUID | O | 照会するブロックストレージID |
| tokenId | Header | String | O | トークンID |

<a id="show-additional-block-storage-attached-to-the-instance-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| volumeAttachment | Body | Object | 接続情報オブジェクト |
| volumeAttachment.device | Body | String | インスタンスのブロックストレージ名<br>例) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | 接続情報ID |
| volumeAttachment.serverId | Body | UUID | インスタンスID |
| volumeAttachment.volumeId | Body | UUID | ブロックストレージID |

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
### インスタンスに追加ブロックストレージを接続する { #attach-additional-block-storage-to-the-instance }
```
POST /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

<a id="attach-additional-block-storage-to-the-instance-request"></a>
#### リクエスト

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | 変更するインスタンスID |
| tokenId | Header | String | O | トークンID |
| volumeAttachment | Body | Object | O | ブロックストレージ接続リクエストオブジェクト |
| volumeAttachment.volumeId | Body | UUID | O | 接続するブロックストレージID |

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

<a id="attach-additional-block-storage-to-the-instance-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| volumeAttachment | Body | Object | 接続情報オブジェクト |
| volumeAttachment.device | Body | String | インスタンスのブロックストレージ名<br>例) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | 接続情報ID |
| volumeAttachment.serverId | Body | UUID | インスタンスID |
| volumeAttachment.volumeId | Body | UUID | ブロックストレージID |

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
### インスタンスブロックストレージの接続を切る { #detach-block-storage-from-the-instance }
```
DELETE /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

<a id="detach-block-storage-from-the-instance-request"></a>
#### リクエスト
このAPIはリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | インスタンスID |
| volumeId | URL | UUID | O | 接続を切るブロックストレージID |
| tokenId | Header | String | O | トークンID |

<a id="detach-block-storage-from-the-instance-response"></a>
#### レスポンス
このAPIはレスポンス本文を返しません。

---

<a id="additional-instance-features"></a>
## インスタンス追加機能 { #additional-instance-features }
NHN Cloudは、次のようなインスタンス制御および付加機能を提供します。

* インスタンスの起動、停止、終了、再起動
* インスタンスタイプ変更
* インスタンスイメージ作成
* セキュリティグループの追加および削除

<a id="start-stopped-instance"></a>
### 停止したインスタンスの起動 { #start-stopped-instance }

停止したインスタンスを再び起動し、状態を**ACTIVE**に変更します。このAPIを呼び出すにはインスタンスの状態が**SHUTOFF**になっている必要があります。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

<a id="start-stopped-instance-request"></a>
#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | 変更するインスタンスID |
| tokenId | Header | String | O | トークンID |
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

<a id="start-stopped-instance-response"></a>
#### レスポンス
このAPIはレスポンス本文を返しません。

---

<a id="start-terminated-instance"></a>
### 終了したインスタンスの起動 { #start-terminated-instance }

停止したインスタンスを再起動し、状態を**ACTIVE**に変更します。このAPIを呼び出すには、インスタンスの状態が**SHELVED_OFFLOADED**である必要があります。

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

<a id="start-terminated-instance-request"></a>
#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|--|---|---|---|--|
| tenantId | URL | String | O | テナントID |
| serverId | URL | UUID | O | 変更するインスタンスID |
| tokenId | Header | String | O | トークンID |
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

<a id="start-terminated-instance-response"></a>
#### レスポンス
このAPIはレスポンス本文を返しません。

---
