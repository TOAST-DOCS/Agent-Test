<!-- machine_translated: true -->

<!-- pre-align:aligned sig=77a16f7da63f -->

{% set f = (build_flags | select("in", ["public","gov","ncgn","ninc","ngsc","ngovc","ngoic"]) | list | first) %}
{% set ep_domain = {"ninc":"ninc.go.kr","ngsc":"ngsc.go.kr","ngovc":"ngovc.com","ngoic":"ngoic.com"} %}

<a id="compute-image-api-v2-guide"></a>
## Compute > Image > API v2ガイド { #compute-image-api-v2-guide }

{% if "public" in build_flags %}
ImageはAPI呼び出し時の認証/認可にIaaSトークンを使用します。IaaSトークンは、NHN CloudのOpenStackベースのインフラサービス(IaaS)で使用する認証トークンです。IaaSトークンの発行および使用の詳細については、[IaaSトークン](/nhncloud/ja/public-api/iaas-token)を参照してください。
{% elif "gov" in build_flags %}
ImageはAPI呼び出し時の認証/認可にIaaSトークンを使用します。IaaSトークンは、NHN CloudのOpenStackベースのインフラサービス(IaaS)で使用する認証トークンです。IaaSトークンの発行および使用の詳細については、[IaaSトークン](/nhncloud/ja/public-api/iaas-token-gov)を参照してください。
{% else %}
APIを使用するには、APIエンドポイントとトークンなどが必要です。[API使用の準備](/Compute/Compute/ja/identity-api/)を参照して、API使用に必要な情報を準備します。
{% endif %}

イメージAPIは、`image`タイプエンドポイントを利用します。正確なエンドポイントはトークン発行レスポンスの`serviceCatalog`を参照します。

| タイプ | リージョン | エンドポイント |
|---|---|---|
{% if "public" in build_flags %}
| image | 韓国(パンギョ)リージョン<br>韓国(ピョンチョン)リージョン<br>韓国(クァンジュ)リージョン<br>日本リージョン | https://kr1-api-image-infrastructure.nhncloudservice.com<br>https://kr2-api-image-infrastructure.nhncloudservice.com<br>https://kr3-api-image-infrastructure.nhncloudservice.com<br>https://jp1-api-image-infrastructure.nhncloudservice.com |
{% elif "gov" in build_flags %}
| image | 韓国(パンギョ)リージョン<br>韓国(ピョンチョン)リージョン | https://kr1-api-image-infrastructure.gov-nhncloudservice.com<br>https://kr2-api-image-infrastructure.gov-nhncloudservice.com |
{% else %}
| image | 韓国(大邱)リージョン | https://kr4-api-image-infrastructure.$[ ep_domain[f] ]$ |
{% endif %}

APIレスポンスにガイドに明示されていないフィールドが表示される場合があります。それらのフィールドは、NHN Cloud内部用途で使用され、事前に告知せずに変更する場合があるため使用しないでください。

<a id="image"></a>
## イメージ { #image }

<a id="list-images"></a>
### イメージリスト照会 { #list-images }

```
GET /v2/images
X-Auth-Token: {tokenId}
```

<a id="list-images-request"></a>
#### リクエスト
このAPIはリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明                                                                                                                                                             |
|---|---|---|---|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| tokenId | Header | String | O | トークンID                                                                                                                                                         |
| limit | Query | Integer | - | 返すイメージの個数。(基本値は25)                                                                                                                                             |
| marker | Query | UUID | - | 照会するイメージリストの最初のイメージID<br>ソート方式に従って`marker`に指定されたイメージから`limit`分のイメージリストを照会                                                                                      |
| name | Query | String | - | 照会するイメージ名                                                                                                                                                      |
| visibility | Query | Enum | - | 照会するイメージの表示プロパティ<br>`public`, `private`、`shared`の中から1つの値のみ選択可能<br>省略するとすべての種類のイメージリストを返す                                                                       |
| owner | Query | String  | - | 照会するイメージが属しているテナントID                                                                                                                                           |
| status | Query | Enum    | - | 照会するイメージの状態<br>`queued`：イメージをコンバーティング中<br>`saving`：イメージをアップロード中<br>`active`：正常<br>`killed`：システムによってイメージ削除<br>`deleted`：削除されたイメージ<br>`pending_delete`：イメージ削除待機中 |
| size_min | Query | Integer | - | 照会するイメージの最小サイズ(Byte)                                                                                                                                           |
| size_max | Query | Integer | - | 照会するイメージの最大サイズ(Byte)                                                                                                                                           |
| sort_key | Query | String | - | イメージリストをソートする時に使用するプロパティ<br>イメージのすべてのプロパティを指定可能。基本値は`created_at`                                                                                               |
| sort_dir | Query | Enum | - | イメージリストのソート方向<br>`asc` (昇順)、`desc` (降順)のうち、1つの値のみ選択可能。基本値は降順                                                                                                   |
{% if "public" in build_flags %}
| member_status | Query | Enum | - | 共有されたイメージの場合、メンバーステータスに応じたイメージリストを照会<br>`accepted`, `pending`, `rejected`, `all`のいずれか1つの値のみ選択可能<br>デフォルト値は`accepted` |
{% else %}
{% endif %}

<a id="list-images-response"></a>
#### レスポンス

{% if "public" in build_flags %}
| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| images | Body | Array | イメージリストオブジェクト |
{% else %}
| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| images | Body | Array | イメージリストオブジェクト |
{% endif %}
| images.status | Body | String | イメージの状態<br>`queued`、`saving`、`active`、`killed`、`deleted`、`pending_delete`のいずれか1つ。 |
{% if "public" in build_flags %}
| images.name | Body | String | イメージの名前 |
| images.tags | Body | Array | イメージタグリスト |
| images.container_format | Body | String | イメージコンテナフォーマット |
| images.created_at | Body | Datetime | 作成時刻 |
| images.disk_format | Body | String | イメージディスクフォーマット |
| images.updated_at | Body | Datetime | 修正時刻 |
| images.min_disk | Body | Integer | イメージの最小ディスク要求量(GB)<br>`min_disk`の値より大きいブロックストレージでのみ使用できる。 |
| images.protected | Body | Boolean | イメージの保護有無<br>`protected=true`の場合、修正および削除不可 |
| images.id | Body | UUID | イメージID |
| images.min_ram | Body | Integer | イメージ最小メモリ要求量(MB)<br>`min_disk`の値より大きいインスタンスでのみ使用できる |
| images.checksum | Body | String | イメージ内容ハッシュ値<br>内部的にイメージの有効性を検証するために使用 |
| images.owner | Body | String | イメージが属しているテナントID |
| images.visibility | Body | Enum | イメージの可視性<br>`public`、`private`、`shared`のいずれか1つ。 |
| images.virtual_size | Body | Integer | イメージの仮想サイズ |
| images.size | Body | Integer | イメージの実際のサイズ(Byte) |
| images.properties | Body | Object | イメージプロパティオブジェクト<br>イメージごとにユーザー指定プロパティをキーと値のペアで記述 |
| images.self | Body | URI | イメージのパス |
| images.file | Body | String | イメージファイルのパス |
| images.schema | Body | URI | イメージスキーマのパス |
| schema | Body | URI | イメージリストスキーマのパス |
| first | Body | URI | イメージリストの最初のページに該当するパス |
| next| Body | URI | イメージリストの次のページに該当するパス |
{% elif "gov" in build_flags %}
| images.name | Body | String | イメージ名 |
| images.tags | Body | Array | イメージのタグリスト |
| images.container_format | Body | String | イメージのコンテナフォーマット |
| images.created_at | Body | Datetime | 作成日時 |
| images.disk_format | Body | String | イメージのディスクフォーマット |
| images.updated_at | Body | Datetime | 更新日時 |
| images.min_disk | Body | Integer | イメージの最小ディスク要件(GB)<br>`min_disk`の値より大きいブロックストレージでのみ使用できます |
| images.protected | Body | Boolean | イメージの保護有無<br>`protected=true`の場合、修正および削除不可                                       |
| images.id | Body | UUID | イメージID |
| images.min_ram | Body | Integer | イメージの最小メモリ要件（MB）<br>`min_disk`の値より大きいインスタンスでのみ使用できます |
| images.checksum | Body | String | イメージ内容のハッシュ値<br>内部的にイメージの有効性検証のために使用                                              |
| images.owner | Body | String | イメージが属するテナントID |
| images.visibility | Body | Enum | イメージの公開設定<br>`public`、`private`、`shared`のいずれか                                      |
| images.virtual_size | Body | Integer | イメージの仮想サイズ |
| images.size | Body | Integer | イメージの実際のサイズ（バイト）                                                                     |
| images.properties | Body | Object | 画像プロパティオブジェクト<br>画像ごとのカスタムプロパティをキーと値のペアの形式で記述 |
| images.self | Body | URI | イメージパス |
| images.file | Body | String | イメージファイルパス |
| images.schema | Body | URI | イメージスキーマのパス                                                                         |
| schema | Body | URI | イメージ一覧スキーマパス                                                                      |
| first | Body | URI | イメージ一覧の最初のページに対応するパス |
| next| Body | URI | イメージ一覧の次のページに該当するパス                                                            |
{% else %}
| images.name | Body | String | イメージ名 |
| images.tag | Body | String | イメージのタグ<br>`_AVAILABLE_` タグを削除するとコンソールには表示されなくなるため、タグを削除しないよう注意してください。 |
| images.container_format | Body | String | イメージのコンテナフォーマット |
| images.created_at | Body | Datetime | 作成日時 |
| images.disk_format | Body | String | イメージのディスクフォーマット |
| images.updated_at | Body | Datetime | 更新日時 |
| images.min_disk | Body | Integer | イメージの最小ディスク要件（GB）<br>`min_disk`の値より大きいブロックストレージでのみ使用できます |
| images.protected | Body | Boolean | イメージの保護有無<br>`protected=true`の場合、修正および削除不可                                       |
| images.id | Body | UUID | イメージID |
| images.min_ram | Body | Integer | イメージの最小メモリ要件（MB）<br>`min_disk`の値より大きいインスタンスでのみ使用できます |
| images.checksum | Body | String | イメージ内容のハッシュ値<br>内部的にイメージの有効性検証のために使用                                              |
| images.owner | Body | String | イメージが属するテナントID |
| images.visibility | Body | Enum | イメージの可視性<br>`public`、`private`、`shared`のいずれか                                      |
| images.virtual_size | Body | Integer | イメージの仮想サイズ |
| images.size | Body | Integer | イメージの実際のサイズ（バイト）                                                                     |
| images.properties | Body | Object | イメージ属性オブジェクト<br>イメージごとのカスタム属性をキーと値のペアの形式で記述 |
| images.self | Body | URI | イメージパス |
| images.file | Body | String | 画像ファイルのパス |
| images.schema | Body | URI | イメージスキーマのパス |
| schema | Body | URI | イメージ一覧スキーマパス |
| first | Body | URI | イメージ一覧の最初のページに該当するパス |
| next| Body | URI | イメージ一覧の次のページに該当するパス                                                            |
{% endif %}

<details><summary>例</summary>
<p>

```json
{
  "images": [
    {
      "container_format": "bare",
      "min_ram": 0,
      "updated_at": "2018-12-11T01:01:35Z",
      "login_username": "centos",
      "file": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b/file",
      "owner": "c289b99209ca4e189095cdecebbd092d",
      "id": "1c868787-6207-4ff2-a1e7-ae1331d6829b",
      "size": 1778843648,
      "os_distro": "CentOS",
      "self": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b",
      "disk_format": "qcow2",
      "os_version": "6.10",
      "schema": "/v2/schemas/image",
      "status": "active",
      "description": "CentOS 6.10 (2018.10.23)",
      "tags": [],
      "visibility": "public",
      "os_architecture": "amd64",
      "min_disk": 20,
      "virtual_size": null,
      "name": "CentOS 6.10 (2018.10.23)",
      "hypervisor_type": "qemu",
      "created_at": "2018-10-23T02:17:43Z",
      "protected": true,
      "checksum": "f803c5c15bcf9a75935980a900a04584",
      "os_type": "linux"
    }
  ],
  "schema": "/v2/schemas/images",
  "first": "/v2/images",
  "next": "/v2/images?marker=057f9a69-4e4c-4025-8a69-fa248cd9db94"
}
```

</p>
</details>

---

<a id="get-image"></a>
### イメージ表示 { #get-image }

```
GET /v2/images/{imageId}
X-Auth-Token: {tokenId}
```

<a id="get-image-request"></a>
#### リクエスト
このAPIはリクエスト本文を要求しません。

| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| imageId | URL | UUID | O | 照会するイメージID |
| tokenId | Header | String | O | トークンID|

<a id="get-image-response"></a>
#### レスポンス

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| status | Body | String | イメージの状態 |
| name | Body | String | イメージの名前 |
{% if "public" in build_flags %}
| tags | Body | String | イメージタグリスト |
{% elif "gov" in build_flags %}
| tags | Body | Array | イメージのタグリスト |
{% else %}
| tag | Body | String | イメージのタグ<br>`_AVAILABLE_` タグを削除するとコンソールには表示されなくなるため、タグを削除しないように注意してください |
{% endif %}
| container_format | Body | String | イメージコンテナフォーマット |
| created_at | Body | Datetime | 作成時刻 |
| disk_format | Body | String | イメージディスクフォーマット |
| updated_at | Body | Datetime | 修正時刻 |
| min_disk | Body | Integer | イメージ最小ディスク要求量(GB)<br>`min_disk`の値より大きいブロックストレージでのみ使用できる |
| protected | Body | Boolean | イメージ保護有無<br>`protected=true`の場合、修正および削除不可 |
| id | Body | UUID | イメージID |
| min_ram | Body | Integer | イメージ最小メモリ要求量(MB)<br>`min_disk`の値より大きいインスタンスでのみ使用できる |
| checksum | Body | String | イメージ内容のハッシュ値<br>内部的にイメージの有効性を検証するために使用 |
| owner | Body | String | イメージが属しているテナントID |
| visibility | Body | Enum | イメージの可視性<br>`public`、`private`、`shared`のいずれか1つ。 |
| virtual_size | Body | Integer | イメージの仮想サイズ |
| size | Body | Integer | イメージの実際のサイズ(Byte) |
| properties | Body | Object | イメージプロパティオブジェクト<br>イメージごとにユーザー指定プロパティをキーと値のペアで記述 |
| self | Body | URI | イメージのパス |
| file | Body | String | イメージファイルのパス |
| schema | Body | URI | イメージスキーマのパス |

<details><summary>例</summary>
<p>

```json
{
  "container_format": "bare",
  "min_ram": 0,
  "updated_at": "2018-12-11T01:01:35Z",
  "login_username": "centos",
  "file": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b/file",
  "owner": "c289b99209ca4e189095cdecebbd092d",
  "id": "1c868787-6207-4ff2-a1e7-ae1331d6829b",
  "size": 1778843648,
  "os_distro": "CentOS",
  "self": "/v2/images/1c868787-6207-4ff2-a1e7-ae1331d6829b",
  "disk_format": "qcow2",
  "os_version": "6.10",
  "schema": "/v2/schemas/image",
  "status": "active",
  "description": "CentOS 6.10 (2018.10.23)",
  "tags": [],
  "visibility": "public",
  "os_architecture": "amd64",
  "min_disk": 20,
  "virtual_size": null,
  "name": "CentOS 6.10 (2018.10.23)",
  "hypervisor_type": "qemu",
  "created_at": "2018-10-23T02:17:43Z",
  "protected": true,
  "checksum": "f803c5c15bcf9a75935980a900a04584",
  "os_type": "linux"
}
```

</p>
</details>

---

<a id="create-image"></a>
### イメージ作成 { #create-image }

{% if "public" in build_flags %}
空のイメージを作成します。NHN Cloudでイメージを使用するには、`이미지 생성`の後に`이미지 업로드` APIを使用して実際のファイルをアップロードする必要があります。

{% elif "gov" in build_flags %}
空のイメージを作成します。 NHN Cloudでイメージを使用するには`イメージ作成`後に`イメージアップロード`APIを利用して実際のファイルをアップロードする必要があります。

{% else %}
{% endif %}
```
POST /v2/images
X-Auth-Token: {tokenId}
```

<a id="create-image-request"></a>
#### リクエスト
| 名前 | 種類 | 形式 | 必須 | 説明 |
|---|---|---|---|---|
| tokenId | Header | String | O | トークンID |
{% if "public" in build_flags %}
| name | Body | String | O | イメージの名前 |
{% elif "gov" in build_flags %}
| name | Body | String | O | イメージ名 |
{% else %}
{% endif %}
| container_format | Body | String | - | イメージコンテナフォーマット |
| disk_format | Body | String | - | イメージディスクフォーマット |
| min_disk | Body | Integer | - | イメージ最小ディスク要求量(GB) |
| min_ram | Body | Integer | - | イメージ最小メモリ要求量(MB) |
| protected | Body | Boolean | - | イメージ保護有無、trueまたはfalse |
{% if "public" in build_flags %}
| tags | Body | Array | - | イメージタグリスト |
| visibility | Body | String | - | イメージの可視性<br>`private`, `shared`のいずれか |
| os_type | Body | String | O | OSタイプ<br>`windows`, `linux`のいずれか |
| os_distro | Body | String | - | OSディストリビューション |
| os_version | Body | String | - | OSバージョン |
{% elif "gov" in build_flags %}
| tags | Body | Array | - | イメージのタグ一覧 |
| visibility | Body | String | - | イメージの可視性<br>`private`、`shared`のいずれか |
| os_type | Body | String | O | オペレーティングシステムのタイプ<br>`windows`、`linux` のいずれか |
| os_distro | Body | String | - | OSディストリビューション |
| os_version | Body | String | - | OSバージョン |
{% else %}
| tags | Body | Array | - | イメージのタグリスト<br>`_AVAILABLE_` タグを削除するとコンソールには表示されなくなるため、タグを削除しないよう注意 |
| visibility | Body | String | - | イメージの公開設定<br>`public`、`private`、`shared`のいずれか |
{% endif %}

<details><summary>例</summary>
<p>

```json
{
{% if "public" in build_flags %}
    "name": "Ubuntu Image",
{% elif "gov" in build_flags %}
    "name": "Ubuntu Image",
{% else %}
{% endif %}
    "container_format": "bare",
{% if "public" in build_flags %}
    "disk_format": "qcow2",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% elif "gov" in build_flags %}
    "disk_format": "qcow2",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% else %}
    "disk_format": "raw",
    "name": "Ubuntu",
{% endif %}
}
```

<p>
</details>

<a id="create-image-response"></a>
#### レスポンス
| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| status | Body | String | イメージ状態<br>`queued`, `saving`, `active`, `killed`, `deleted`, `pending_delete`のいずれか |
| name | Body | String | イメージの名前 |
{% if "public" in build_flags %}
| tags | Body | String | イメージタグリスト |
{% elif "gov" in build_flags %}
| tags | Body | Array | イメージのタグ一覧 |
{% else %}
| tags | Body | String | イメージのタグリスト<br>`_AVAILABLE_` タグを削除するとコンソールには表示されなくなるため、タグを削除しないよう注意してください |
{% endif %}
| container_format | Body | String | イメージコンテナフォーマット |
| created_at | Body | Datetime | 作成時刻 |
| disk_format | Body | String | イメージディスクフォーマット |
| updated_at | Body | Datetime | 修正時刻 |
| min_disk | Body | Integer | イメージ最小ディスク要求量(GB)<br>`min_disk`の値より大きいブロックストレージでのみ使用できる |
| protected | Body | Boolean | イメージ保護有無<br>`protected=true`の場合、修正および削除不可 |
| id | Body | UUID | イメージID |
| min_ram | Body | Integer | イメージ最小メモリ要求量(MB)<br>`min_disk`の値より大きいインスタンスでのみ使用できる |
| checksum | Body | String | イメージ内容のハッシュ値<br>内部的にイメージの有効性を検証するために使用 |
| owner | Body | String | イメージが属しているテナントID |
{% if "public" in build_flags %}
| visibility | Body | Enum | イメージの可視性<br>`private`、`shared`のいずれか1つ。 |
{% else %}
| visibility | Body | Enum | イメージの公開設定<br>`public`、`private`、`shared` のいずれか |
{% endif %}
| virtual_size | Body | Integer | イメージの仮想サイズ |
| size | Body | Integer | イメージの実際のサイズ(Byte) |
| properties | Body | Object | イメージプロパティオブジェクト<br>イメージごとにユーザー指定プロパティをキーと値のペアで記述 |
| self | Body | URI | イメージのパス |
| file | Body | String | イメージファイルのパス |
| schema | Body | URI | イメージスキーマのパス |
{% if "public" in build_flags %}
| os_type | Body | String | OSタイプ<br>`windows`, `linux`のいずれか |
| os_distro | Body | String | OSディストリビューション |
| os_version | Body | String | OSバージョン |
{% elif "gov" in build_flags %}
| os_type | Body | String | OSタイプ<br>`windows`、`linux`のいずれか |
| os_distro | Body | String | OSディストリビューション |
| os_version | Body | String | OSバージョン |
{% else %}
{% endif %}

<details><summary>例</summary>
<p>

```json
{
    "status": "queued",
{% if "public" in build_flags %}
    "name": "Ubuntu Image",
{% elif "gov" in build_flags %}
    "name": "Ubuntu Image",
{% else %}
    "name": "Ubuntu",
{% endif %}
    "tags": [],
    "container_format": "bare",
    "created_at": "2015-11-29T22:21:42Z",
    "size": null,
{% if "public" in build_flags %}
    "disk_format": "qcow2",
{% elif "gov" in build_flags %}
    "disk_format": "qcow2",
{% else %}
    "disk_format": "raw",
{% endif %}
    "updated_at": "2015-11-29T22:21:42Z",
    "visibility": "private",
    "locations": [],
    "self": "/v2/images/b2173dd3-7ad6-4362-baa6-a68bce3565cb",
    "min_disk": 0,
    "protected": false,
    "id": "b2173dd3-7ad6-4362-baa6-a68bce3565cb",
    "file": "/v2/images/b2173dd3-7ad6-4362-baa6-a68bce3565cb/file",
    "checksum": null,
    "os_hash_algo": null,
    "os_hash_value": null,
    "os_hidden": false,
    "owner": "bab7d5c60cd041a0a36f7c4b6e1dd978",
    "virtual_size": null,
    "min_ram": 0,
{% if "public" in build_flags %}
    "schema": "/v2/schemas/image",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% elif "gov" in build_flags %}
    "schema": "/v2/schemas/image",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
{% else %}
    "schema": "/v2/schemas/image"
{% endif %}
}
```

<p>
</details>

---

