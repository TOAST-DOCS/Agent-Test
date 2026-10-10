<!-- machine_translated: true -->

<!-- pre-align:aligned sig=00d5570bd1c0 -->

<a id="compute-image-api-v2-guide"></a>
## Compute > Image > API v2 Guide { #compute-image-api-v2-guide }

Image uses IaaS tokens for authentication and authorization when making API calls. The IaaS token is an authentication token used for NHN Cloud's OpenStack-based infrastructure services (IaaS). For more information on issuing and using IaaS tokens, please refer to the [IaaS Token](/nhncloud/en/public-api/iaas-token).

Image API uses the `image` type endpoint. Refer to the `serviceCatalog` in the token issuance response for the valid endpoint.

| Type | Region | Endpoint |
|---|---|---|
| image | Korea (Pangyo) Region<br>Korea (Pyeongchon) Region<br>Korea (Gwangju) Region<br>Japan Region | https://kr1-api-image-infrastructure.nhncloudservice.com<br>https://kr2-api-image-infrastructure.nhncloudservice.com<br>https://kr3-api-image-infrastructure.nhncloudservice.com<br>https://jp1-api-image-infrastructure.nhncloudservice.com |

In API response, you may find fields that are not specified in the guide. These fields are only for the internal use by NHN Cloud and are subject to change without prior notice, so we advise you not to use them.

<a id="image"></a>
## Image { #image }

<a id="list-images"></a>
### List Images { #list-images }

```
GET /v2/images
X-Auth-Token: {tokenId}
```

<a id="list-images-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description                                                                                                                                                                                                           |
|---|---|---|---|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| tokenId | Header | String | O | Token ID                                                                                                                                                                                                              |
| limit | Query | Integer | - | Image count to return (default is 25)                                                                                                                                                                                 |
| marker | Query | UUID | - | ID of the first image on the list to query<br>Query as much as the `limit` after image specified as the `marker` according to the sorting order                                                                       |
| name | Query | String | - | Name of image to query                                                                                                                                                                                                |
| visibility | Query | Enum | - | Visibility attribute of the image to query<br>Select only one of `public`, `private`, and `shared`<br>If left blank, list of all types of images are returned.                                                        |
| owner | Query | String  | - | ID of the tenant to which the image to query belongs                                                                                                                                                                  |
| status | Query | Enum    | - | Image status to query<br>`queued`: Converting image<br>`saving`: Uploading image<br>`active`: Normal<br>`killed`: Deleting image from system<br>`deleted`: Image deleted<br>`pending_delete`: Delete Image is pending |
| size_min | Query | Integer | - | Minimum size of image to query (bytes)                                                                                                                                                                                |
| size_max | Query | Integer | - | Maximum size of image to query (bytes)                                                                                                                                                                                |
| sort_key | Query | String | - | Attribute to use when sorting the image list<br>All attributes of image can be specified, default is `created_at`                                                                                                     |
| sort_dir | Query | Enum | - | Sorting direction of the image list<br>Select only one of `asc` (ascending order) or `desc` (descending order)                                                                                                        |
{% if "public" in build_flags %}
| member_status | Query | Enum | - | For shared images, a list of images are retrieved according to their member status<br>Only one of the following values can be selected: `accepted`, `pending`, `rejected`, or `all`.<br>default is `accepted` |
| os_type | Query | String | - | OS type of the image to retrieve<br>One of `linux`, `windows` |
| os_distro | Query | String | - | Operating system distribution of the image to retrieve |
{% endif %}

<a id="list-images-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| images | Body | Array | Image list object |
| images.status | Body | String | Image status<br>One of `queued`, `saving`, `active`, `killed`, `deleted`, and `pending_delete` |
| images.name | Body | String | Image name |
| images.tags | Body | Array | Image tag list |
| images.container_format | Body | String | Image container format |
| images.created_at | Body | Datetime | Creation time |
| images.disk_format | Body | String | Image disk format |
| images.updated_at | Body | Datetime | Modification time |
| images.min_disk | Body | Integer | Minimum required disk size of image (GB)<br>Available only for block storage that are larger than `min_disk` |
| images.protected | Body | Boolean | Protect image or not<br>Cannot be modified or deleted when `protected=true` |
| images.id | Body | UUID | Image ID |
| images.min_ram | Body | Integer | Minimum required memory size of image (MB)<br>Available only for instances that are larger than `min_disk` |
| images.checksum | Body | String | Hash for image content<br>Used internally for image validation |
| images.owner | Body | String | ID of the tenant to which the image belongs |
| images.visibility | Body | Enum | Image visibility<br>One of `public`, `private`, and `shared` |
| images.virtual_size | Body | Integer | Virtual size of the image |
| images.size | Body | Integer | Real size of the image (bytes) |
| images.properties | Body | Object | Image properties object<br>Describes user-specified properties for each image in the key-value pair format |
| images.self | Body | URI | Image path |
| images.file | Body | String | File path of image |
| images.schema | Body | URI | Schema path of image |
| schema | Body | URI | Schema path of image list |
| first | Body | URI | Path of the first page of image list |
| next| Body | URI | Path of the next page of image list |

<details><summary>Example</summary>
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
### Get Image { #get-image }

```
GET /v2/images/{imageId}
X-Auth-Token: {tokenId}
```

<a id="get-image-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| imageId | URL | UUID | O | Image ID to query |
| tokenId | Header | String | O | Token ID|
| include_properties | Query | Boolean | - | Whether to include image properties |
{% if "gov" in build_flags %}
| gov_zone | Query | String | - | Public region zone |
{% endif %}

<a id="get-image-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| status | Body | String | Image status |
| name | Body | String | Image name |
| tags | Body | Array | Image tag list |
| container_format | Body | String | Image container format |
| created_at | Body | Datetime | Creation time |
| disk_format | Body | String | Image disk format |
| updated_at | Body | Datetime | Modification time |
| min_disk | Body | Integer | Minimum required disk size of image (GB)<br>Available only for block storage that are larger than `min_disk` |
| protected | Body | Boolean | Protect image or not<br>Cannot be modified or deleted when `protected=true` |
| id | Body | UUID | Image ID |
| min_ram | Body | Integer | Minimum required memory size of image (MB)<br>Available only for instances that are larger than `min_disk` |
| checksum | Body | String | Hash for image content<br>Used internally for image validation |
| owner | Body | String | ID of the tenant to which the image belongs |
| visibility | Body | Enum | Image visibility<br>One of `public`, `private`, and `shared` |
| virtual_size | Body | Integer | Virtual size of the image |
| size | Body | Integer | Real size of the image (bytes) |
| properties | Body | Object | Image properties object<br>Describes user-specified properties for each image in the key-value pair format |
| self | Body | URI | Image path |
| file | Body | String | File path of image |
| schema | Body | URI| Schema path of image |

<details><summary>Example</summary>
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
### Create Image { #create-image }

Create an empty image. To use the image in NHN Cloud, you must upload the actual file using the `Upload Image` API after `creating an image`.

```
POST /v2/images
X-Auth-Token: {tokenId}
```

<a id="create-image-request"></a>
#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tokenId | Header | String | O | Token ID |
| name | Body | String | O | Image name |
| container_format | Body | String | - | Image container format |
| disk_format | Body | String | - | Image disk format |
| min_disk | Body | Integer | - | Minimum required disk size of image (GB) |
| min_ram | Body | Integer | - | Minimum required memory size of image (MB) |
| protected | Body | Boolean | - | Whether to protect image, true or false |
| tags | Body | Array | - | Image tag list |
| visibility | Body | String | - | Image visibility<br>`private` or `shared` |
| os_type | Body | String | O | OS type<br>`windows` or `linux` |
| os_distro | Body | String | - | OS distribution |
| os_version | Body | String | - | OS version |

<details><summary>Example</summary>
<p>

```json
{
    "name": "Ubuntu Image",
    "container_format": "bare",
    "disk_format": "qcow2",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
}
```

<p>
</details>

<a id="create-image-response"></a>
#### Response
| Name | Type | Format | Description |
|---|---|---|---|
| status | Body | String | Image status<br>One of `queued`, `saving`, `active`, `killed`, `deleted`, and `pending_delete` |
| name | Body | String | Image name |
| tags | Body | String | Image tag list |
| container_format | Body | String | Image container format |
| created_at | Body | Datetime | Creation time |
| disk_format | Body | String | Image disk format |
| updated_at | Body | Datetime | Modification time |
| min_disk | Body | Integer | Minimum required disk size of image (GB)<br>Available only for block storage that are larger than `min_disk` |
| protected | Body | Boolean | Protect image or not<br>Cannot be modified or deleted when `protected=true` |
| id | Body | UUID | Image ID |
| min_ram | Body | Integer | Minimum required memory size of image (MB)<br>Available only for instances that are larger than `min_disk` |
| checksum | Body | String | Hash for image content<br>Used internally for image validation |
| owner | Body | String | ID of the tenant to which the image belongs |
| visibility | Body | Enum | Image visibility<br>`private` or `shared` |
| virtual_size | Body | Integer | Virtual size of the image |
| size | Body | Integer | Real size of the image (bytes) |
| properties | Body | Object | Image properties object<br>Describes user-specified properties for each image in the key-value pair format |
| self | Body | URI | Image path |
| file | Body | String | File path of image |
| schema | Body | URI| Schema path of image |
| os_type | Body | String | OS type<br>`windows` or `linux` |
| os_distro | Body | String | OS distribution |
| os_version | Body | String | OS version |

<details><summary>Example</summary>
<p>

```json
{
    "status": "queued",
    "name": "Ubuntu Image",
    "tags": [],
    "container_format": "bare",
    "created_at": "2015-11-29T22:21:42Z",
    "size": null,
    "disk_format": "qcow2",
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
    "schema": "/v2/schemas/image",
    "os_type": "linux",
    "os_distro": "ubuntu",
    "os_version": "Server 22.04 LTS"
}
```

<p>
</details>

---

