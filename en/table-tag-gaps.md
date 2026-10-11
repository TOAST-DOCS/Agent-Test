<!-- machine_translated: true -->

{% set f = (build_flags | select("in", ["public","gov","ncgn","ninc","ngsc","ngovc","ngoic"]) | list | first) %}
{% set ep_domain = {"ninc":"ninc.go.kr","ngsc":"ngsc.go.kr","ngovc":"ngovc.com","ngoic":"ngoic.com"} %}

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 Guide { #compute-instance-api-v2-guide }

{% if "public" in build_flags %}
Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is an authentication token used for NHN Cloud's OpenStack-based infrastructure services (IaaS). For more information on issuing and using IaaS tokens, see the [IaaS token](/nhncloud/en/public-api/iaas-token).
{% elif "gov" in build_flags %}
Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is an authentication token used for NHN Cloud's OpenStack-based infrastructure services (IaaS). For more information on issuing and using IaaS tokens, see the [IaaS token](/nhncloud/en/public-api/iaas-token-gov).
{% else %}
To use the API, API endpoint and token are required. Refer to [API usage preparations](/Compute/Compute/en/identity-api/) to prepare the information required to use the API.
{% endif %}

The Instance API uses the `compute` type endpoint. For the exact endpoint, see `serviceCatalog` from the token issue response.

| Type | Region | Endpoint |
|---|---|---|
{%- if "public" in build_flags %}

| compute | Korea (Pangyo) Region<br>Korea (Pyeongchon) Region<br>Korea (Gwangju) Region<br>Japan Region | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

{% elif "gov" in build_flags %}

| compute | Korea (Pangyo) Region<br>Korea (Pyeongchon) Region | https://kr1-api-instance-infrastructure.gov-nhncloudservice.com<br>https://kr2-api-instance-infrastructure.gov-nhncloudservice.com |
{% else %}

| compute | Korea (Daegu) region | https://kr4-api-instance-infrastructure.$[ ep_domain[f] ]$ |
{% endif %}

In each API response, you may find fields that are not specified within this guide. Those fields are for NHN Cloud internal usage, and as such refrain from using them since they may be changed without prior notice.

<a id="create-instance"></a>
### Create Instance { #create-instance }

Create an instance.

After calling the Create Instance API, query the instance and check its status.

* If the status becomes **ACTIVE**, the instance has been created successfully.
* If the status remains in **BUILDING** for a long time or becomes **ERROR**, check parameters used for instance creation and try creating again.

Windows instances have the following additional restrictions that apply to facilitate stable usage.

* Use an instance flavor with at least 2GB RAM capacity.
* Require 50 GB or more of root block storage.
* U2 flavor instances cannot use Windows images.

The root block storage size that can be specified is 10GB for Linux and 50GB for Windows.

You can assign placement policies via scheduler hints when requesting instance creation.


{% if "public" in build_flags %}

{% else %}
{% endif %}
```
POST /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="create-instance-request"></a>
#### Request

{% if "public" in build_flags %}

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
{%- else %}

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
{%- endif %}

| server.security_groups | body | Object | - | List object of security groups<br>If left blank, the `default` group is added. |
{%- if "public" in build_flags %}

| server | body | Object | O | Server Objects |
| server.security_groups.name | body | String | - | **(Conditionally required)** Name of security group to be added to instance |
| server.user_data | body | String | - | Script to be executed or settings to apply after instance boot<br>Allows up to 65535 bytes of base 64-encoded character strings |
{%- elif "gov" in build_flags %}

| server.security_groups | body | Object | - | List object of security groups<br>If left blank, the `default` group is added. |
| server.security_groups.name | body | String | - | **(Conditionally Required)** Name of security group to be added to instance |
| server.user_data | body | String | - | Script to be executed after instance booting and its configuration<br>Allows up to 65535 bytes of base 64-encoded character strings |
{%- else %}

| server.security_groups | body | Object | - | List object of security groups<br>If left blank, the `default` group is added. |
| server.security_groups.name | body | String | - | Name of security group to be added to instance |
| server.user_data | body | String | - | Script to be executed after instance booting and its configuration<br>Allows up to 65,535 bytes of base64-encoded character strings |
{%- endif %}

| server.availability_zone | body | String | - | Availability zone where instance will be created<br>If left blank, a random zone will be selected<br>If the source type of the root block storage is `volume`, `snapshot`, it must be set to the same availability zone as the source block storage |
| server.imageRef | Body | String | - | Image ID to create instance<br>No configuration required if the source type of the root block storage is `volume`, `snapshot` |
{%- if "public" in build_flags %}

| server.flavorRef | Body | String | O | Instance flavor ID to create instance |
| server.networks | Body | Object | O | Network information object to use when creating instance<br>A NIC is added for each network specified. Specify each network using Network ID, Subnet ID, Port ID, or Fixed IP. |
| server.networks.uuid | Body | UUID | - | **(Conditionally required)** Network ID to create instance |
| server.networks.subnet | Body | UUID | - | **(Conditionally required)** Subnet ID within network to create instance |
| server.networks.port | Body | UUID | - | **(Conditionally required)** Port ID to create instance<br>Security groups requested when specifying a port ID are not applied to existing specified ports |
| server.networks.fixed_ip | Body | String | - | **(Conditionally required)** Fixed IP to create instance |
| server.name | Body | String | O | Instance name<br>Up to 255 alphabetical characters allowed, max 15 characters for Windows images |
| server.metadata | Body | Object | - | Metadata object to add to instance<br>Key-value pairs of max 255 characters |
{%- elif "gov" in build_flags %}

| server.flavorRef | Body | String | O | Instance flavor ID to create instance |
| server.networks | Body | Object | O | Network information object to use when creating instance<br>A NIC is added for each network specified. Specify each network using Network ID, Subnet ID, Port ID, or Fixed IP. |
| server.networks.uuid | Body | UUID | - | **(Conditionally required)** Network ID to create instance |
| server.networks.subnet | Body | UUID | - | **(Conditionally Required)** Subnet ID within network to create instance |
| server.networks.port | Body | UUID | - | **(Conditionally Required)** Port ID to create instance<br>Security groups requested when specifying a port ID are not applied to existing ports you specify |
| server.networks.fixed_ip | Body | String | - | **(Conditionally required)** Fixed IP to create instance |
| server.name | Body | String | O | Instance name<br>Up to 255 alphabetical characters allowed, max 15 characters for Windows images |
| server.metadata | Body | Object | - | Metadata object to add to instance<br>Key-value pairs of max 255 characters |
{%- else %}

| server.flavorRef | Body | String | O | Instance flavor ID to create instance |
| server.networks | Body | Object | O | Network information object to use when creating instance<br>A NIC is added for each network specified. Specify each network using Network ID, Subnet ID, Port ID, or Fixed IP. |
| server.networks.uuid | Body | UUID | - | **(Conditionally required)** Network ID to create instance |
| server.networks.subnet | Body | UUID | - | **(Conditionally Required)** Subnet ID within network to create instance |
| server.networks.port | Body | UUID | - | **(Conditionally Required)** Port ID to create instance<br>Security groups requested when specifying a port ID are not applied to existing ports you specify |
| server.networks.fixed_ip | Body | String | - | **(Conditionally required)** Fixed IP to create instance |
| server.name | Body | String | O | Instance name<br>Up to 255 alphabetical characters allowed, max 15 characters for Windows images |
| server.metadata | Body | Object | - | Metadata object to add to instance<br>Key-value pairs of max 255 characters |
{%- endif %}

| server.block_device_mapping_v2 | Body | Object | O | Block storage information object<br>**Must be specified for any instance flavors other than U2 flavor which uses local block storage** |
| server.block_device_mapping_v2.source_type | Body | Enum | O | Source type of block storage to create<br>- `image`: Use an image to create a block storage<br>- `blank`: Create an empty block storage (cannot be used as root block storage)<br>- `volume`: Use previously created block storage<br>- `snapshot`: Create block storage with snapshots |
| server.block_device_mapping_v2.uuid | Body | String | - | **(Conditionally required)** Different settings required for different types of block storage sources<br>- Set the image ID if the source type is `image`<br>- Set an existing created block storage ID if the source type is `volume`<br>- Set `snapshot` ID if the source type is `snapshot`<br>- No settings required if source type is ` blank`<br>For root block storage, it must be a bootable source. |
{%- if "public" in build_flags %}

| server.block_device_mapping_v2.boot_index | Body | Integer | O | Order to boot the specified block storage<br>- If `, root block storage<br>- If not, additional block storage<br>A larger value indicates lower booting priority |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | Requires different settings depending on the location of instance’s block storage or flavor<br>- `local`: For GPU and U2 instance flavors<br>- `volume`: For other instance flavors |
{%- elif "gov" in build_flags %}

| server.block_device_mapping_v2.boot_index | Body | Integer | O | Order to boot the specified block storage<br>- If `0`, root block storage<br>- If not, additional block storage<br>A larger value indicates lower booting priority |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | Requires different settings depending on the location of instance's block storage or flavor.<br>- `local`: For GPU instance flavors or U2 instance flavors<br>- `volume`: For other instance flavors |
{%- else %}

| server.block_device_mapping_v2.boot_index | Body | Integer | O | Order to boot the specified block storage<br>- If `0`, root block storage<br>- If not, additional block storage<br>A larger value indicates lower booting priority |
{%- endif %}

| server.block_device_mapping_v2.volume_type | Body | Enum    | - | **(Conditionally required)** Type of block storage to create<br>No configuration required if the source type of block storage is `volume`, `snapshot`<br>See `Name` from the response of **List Block Storage Types** in the `User Guide > Storage > Block Storage > API v2 guide`. |
{%- if "public" in build_flags %}

| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | Indicates whether block storage is deleted when an instance is terminated. Default value is `false`.<br>Delete the volume if `true`, keep the volume if `false`. |
{%- elif "gov" in build_flags %}

| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | Indicates whether block storage is deleted when an instance is terminated. Default value is `false`.<br>`true` to delete, `false` to retain |
{%- else %}

| server.block_device_mapping_v2.destination_type | Body | Enum | O | Requires different settings depending on the location of instance's block storage or flavor.<br>- `local`: For U2 instance flavors<br>- `volume`: For other instances flavors                                                                          |
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | Indicates whether block storage is deleted when an instance is terminated. Default value is `false`.<br>`true` to delete, `false` to retain |
{%- endif %}

| server.block_device_mapping_v2.volume_size | Body | Integer | - | **(Conditionally required)** Size of block storage to create<br>Different settings required for different types of block storage sources<br>- No configuration required if source type is `volume`<br>- Set equal to or larger than the original block storage size if the source type is `snapshot`<br>GB (unit)<br>Uses the U2 instance type and root block storage is created with the size specified in the U2 instance type and this value will be ignored<br>Different instance types have different sizes of root block storage that can be created. For more details, see `User Guide > Compute > Instance > Console User Guide > Create Instance > Block Storage Size`. |
{%- if "public" in build_flags %}

| server.block_device_mapping_v2.nhn_encryption                   | Body | Object | - | **(Conditionally required)** Block storage encryption information                                                                                                                                                                                        |
| server.block_device_mapping_v2.nhn_encryption.skm_appkey        | Body | String | - | **(Conditionally required)** AppKeys for Secure Key Manager products                                                                                                                                                                              |
| server.block_device_mapping_v2.nhn_encryption.skm_key_id        | Body | String | - | **(Conditionally required)** Symmetric key ID of Secure Key Manager to be used to create encrypted block storage.                                            |               
| server.key_name | Body | String | O | Key pair to access instance |
{%- else %}

| server.key_name | Body | String | O | Key pair to access instance |
{%- endif %}

| server.min_count | Body | Integer | - | Minimum number of instances to create with this request.<br>Default value is 1.<br>Can only be set to `1` if the source type of the block storage is `volume` |
| server.max_count | Body | Integer | - | Maximum number of instances to create with this request.<br>Default value is min_count, max value is 10.<br>Can only be set to `1` if the source type of the block storage is `volume` |
{%- if "public" in build_flags %}

| server.return_reservation_id | Body | Boolean | - | Instance creation request reservation ID.<br>If set to True, reservation ID is returned instead of instance creation information.<br>Default value is False |
{%- else %}

| server.return_reservation_id | Body | Boolean | - | Reservation ID for instance creation.<br>If set to True, reservation ID is returned instead of instance creation information.<br>The default value is False |
{%- endif %}

| os:scheduler_hints | Body | Object | - | Scheduler Hint Objects |
| os:scheduler_hints.group | Body | String | - | Placement Policy ID |

<details><summary>Example</summary>
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
#### Response

<todo: translate>

<details><summary>Example</summary>
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
### Modify Instance { #modify-instance }
Modify created instance. Only some attributes are allowed to be modified.

```
PUT /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="modify-instance-request"></a>
#### Request

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Modifying instance ID |
| tokenId | Header | String | O | Token ID |
| server | Body | Object | O | Modify instance request object |
| server.name | Body | String | - | New instance name |

<details><summary>Example</summary>
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
#### Response
Same as Get Instance.

---

<a id="delete-instance"></a>
### Delete Instance { #delete-instance }
Delete a created instance.

```
DELETE /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="delete-instance-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Deleting instance ID |
| tokenId | Header | String | O | Token ID |

<a id="delete-instance-response"></a>
#### Response
This API does not return a response body.

---

<a id="manage-block-storage-attachment"></a>
## Manage Block Storage Attachment { #manage-block-storage-attachment }

<a id="list-additional-block-storage-attached-to-the-instance"></a>
### List additional block storage attached to the instance { #list-additional-block-storage-attached-to-the-instance }
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

<a id="list-additional-block-storage-attached-to-the-instance-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Modifying instance ID |
| tokenId | Header | String | O | Token ID |
| limit | Query | Integer | - | Number of volumes to query |
| offset | Query | Integer | - | Start point of returned list<br>Return block storage starting from offset of the entire list |

<a id="list-additional-block-storage-attached-to-the-instance-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| volumeAttachments | Body | Array | List of attachment information objects |
| volumeAttachments.device | Body | String | Block storage name<br>e.g.) `/dev/vdb` |
| volumeAttachments.id | Body | UUID | Attachment information ID |
| volumeAttachments.serverId | Body | UUID | Instance ID |
| volumeAttachments.volumeId | Body | UUID | Block storage ID |

<details><summary>Example</summary>
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
### List additional block storage attached to the instance { #show-additional-block-storage-attached-to-the-instance }
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

<a id="show-additional-block-storage-attached-to-the-instance-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| volumeId | URL | UUID | O | ID of block storage to query |
| tokenId | Header | String | O | Token ID |

<a id="show-additional-block-storage-attached-to-the-instance-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| volumeAttachment | Body | Object | Attachment information object |
| volumeAttachment.device | Body | String | Block storage name<br>e.g.) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | Attachment information ID |
| volumeAttachment.serverId | Body | UUID | Instance ID |
| volumeAttachment.volumeId | Body | UUID | Block storage ID |

<details><summary>Example</summary>
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
### Attach additional block storage to the instance { #attach-additional-block-storage-to-the-instance }
```
POST /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

<a id="attach-additional-block-storage-to-the-instance-request"></a>
#### Request

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Modifying instance ID |
| tokenId | Header | String | O | Token ID |
| volumeAttachment | Body | Object | O | Object to request block storage attachment |
| volumeAttachment.volumeId | Body | UUID | O | ID of block storage to attach |

<details><summary>Example</summary>
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
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| volumeAttachment | Body | Object | Attachment information object |
| volumeAttachment.device | Body | String | Block storage name<br>e.g.) `/dev/vdb` |
| volumeAttachment.id | Body | UUID | Attachment information ID |
| volumeAttachment.serverId | Body | UUID | Instance ID |
| volumeAttachment.volumeId | Body | UUID | Block storage ID |

<details><summary>Example</summary>
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
### Detach block storage from the instance { #detach-block-storage-from-the-instance }
```
DELETE /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

<a id="detach-block-storage-from-the-instance-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| volumeId | URL | UUID | O | ID of block storage to detach |
| tokenId | Header | String | O | Token ID |

<a id="detach-block-storage-from-the-instance-response"></a>
#### Response
This API does not return a response body.

---

<a id="additional-instance-features"></a>
## Additional Instance Features { #additional-instance-features }
NHN Cloud provides the following additional features to handle instances.

* Start, Stop, Terminate, and Restart Instance
* Change Instance Flavor
* Create Instance Image
* Add/Delete Security Group

<a id="start-stopped-instance"></a>
### Start Stopped Instance { #start-stopped-instance }

Restart a stopped instance and change its status to **ACTIVE**. To call this API, the instance status must be **SHUTOFF**.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

<a id="start-stopped-instance-request"></a>
#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Modifying instance ID |
| tokenId | Header | String | O | Token ID |
| os-start | Body | none | O | Instance start request |

<details><summary>Example</summary>
<p>

```json
{
  "os-start" : null
}
```

</p>
</details>

<a id="start-stopped-instance-response"></a>
#### Response
This API does not return a response body.

---

<a id="start-terminated-instance"></a>
### Start Terminated Instance { #start-terminated-instance }

Restart a terminated instance and changes its status to **ACTIVE**. To call this API, the instance's state must be **SHELVED_OFFLOADED**.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

<a id="start-terminated-instance-request"></a>
#### Request
| Name | Type | Format | Required | Description |
|--|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Modifying instance ID |
| tokenId | Header | String | O | Token ID |
| unshelve | Body | none | O | Instance start request |

<details><summary>Example</summary>
<p>

```json
{
  "unshelve" : null
}
```

</p>
</details>

<a id="start-terminated-instance-response"></a>
#### Response
This API does not return a response body.

---
