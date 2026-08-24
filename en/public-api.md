<!-- machine_translated: true -->

<!-- pre-align:aligned sig=8e6d00d3460b -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 Guide { #compute-instance-api-v2-guide }

Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is the authentication token used by the NHN Cloud's OpenStack-based infrastructure service (IaaS). For more information on IaaS token issuance and usage, see [IaaS Token](/nhncloud/en/public-api/iaas-token).

The Instance API uses the `compute` type endpoint. Refer to the `serviceCatalog` in the token issuance response for the exact endpoint.

| Type | Region | Endpoint |
|---|---|---|
| compute | Korea (Pangyo) Region<br>Korea (Pyeongchon) Region<br>Korea (Gwangju) Region<br>Japan Region | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

The API response may contain fields that are not specified in this guide. These fields are for internal NHN Cloud use and may be changed without prior notice, so do not use them.

<a id="instance-flavors"></a>
## Instance Flavors { #instance-flavors }

<a id="list-flavors"></a>
### List Flavors { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="request"></a>
#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| minDisk | Query | Integer | - | Minimum Block Storage size (GB)<br>Returns only types with Block Storage size greater than the specified size |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only types with RAM size greater than the specified size |

<a id="response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance Flavor list object |
| flavors.id | Body | UUID | Instance Flavor ID |
| flavors.links | Body | Object | Instance Flavor link object |
| flavors.name | Body | String | Instance Flavor name |


<details><summary>Example</summary>
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
### List Flavors with Details { #list-flavors-with-details }

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

<a id="list-flavors-with-details-request"></a>
#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| minDisk | Query | Integer | - | Minimum Block Storage size (GB)<br>Returns only types with Block Storage size greater than the specified size |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only types with RAM size greater than the specified size |

<a id="list-flavors-with-details-response"></a>
#### Response

| Name | Type | Format | Description             |
|---|---|---|---|
| flavors | Body | Object | Instance Flavor list object  |
| flavors.id | Body | UUID | Instance Flavor ID     |
| flavors.links | Body | Object | Instance Flavor link object  |
| flavors.name | Body | String | Instance Flavor name     |
| flavors.ram | Body | Integer | Memory size (MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | Enable status         |
| flavors.vcpus | Body | Integer | Number of vCPUs        |
| flavors.extra_specs | Body | Object | Additional specs object       |
| flavors.swap | Body | Integer | Swap space size (GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | Public status          |
| flavors.rxtx_factor | Body | Float | Network send/receive ratio |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | Ephemeral storage size (GB)     |
| flavors.disk | Body | Integer | Root disk size (GB) |

<details><summary>Example</summary>
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
### List Availability Zones { #list-availability-zones }

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

<a id="list-availability-zones-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |

<a id="list-availability-zones-response"></a>
#### Response
| Name | Type | Format | Description |
|---|---|---|---|
| availabilityZoneInfo | Body | Object | Availability Zone Information Object |
| availabilityZoneInfo.zoneName | Body | String | Availability Zone Name |
| availabilityZoneInfo.zoneState | Body | Object | Availability Zone State Information Object |
| availabilityZoneInfo.available | Body | Object | Availability Zone State |

<details><summary>Example</summary>
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
## Key Pairs { #key-pairs }

<a id="list-key-pairs"></a>
### List Key Pairs { #list-key-pairs }
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="list-key-pairs-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |

<a id="list-key-pairs-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| keypairs | Body | Array | Key pair objects |
| keypairs.keypair | Body | Object | Key pair object |
| keypairs.keypair.name | Body | String | Key pair name |
| keypairs.keypair.public_key | Body | String | Public key |
| keypairs.keypair.fingerprint | Body | String | Key pair fingerprint |

<details><summary>Example</summary>
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
### Get Key Pair { #show-key-pair }
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="show-key-pair-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| keypairName | URL | String | O | Key pair name |
| tokenId | Header | String | O | Token ID |

<a id="show-key-pair-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| keypair | Body | Object | Key pair object |
| keypair.public_key | Body | String | Public key |
| keypair.user_id | Body | String | Key pair owner ID |
| keypair.name | Body | String | Key pair name |
| keypair.deleted | Body | Boolean | Whether the key pair is deleted |
| keypair.created_at | Body | Datetime | Key pair creation time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | Key pair modification time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | Key pair deletion time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.fingerprint | Body | String | Key pair fingerprint |
| keypair.id | Body | Integer | Key pair ID |

<details><summary>Example</summary>
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
### Create or Register Key Pair { #createregister-key-pair }

```
POST /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

<a id="createregister-key-pair-request"></a>
#### Request

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| keypair | Body | Object | O | Key pair object |
| keypair.name | Body | String | O | Key pair name to create or register |
| keypair.public_key | Body | String | - | Public key to register. If this field is omitted, a new key pair is created. |

<details><summary>Example</summary>
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
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| keypair | Body | Object | Key pair object |
| keypair.public_key | Body | String | Public key |
| keypair.private_key | Body | String | Private key. Returned only when a new key pair is created. |
| keypair.user_id | Body | String | Key pair owner ID |
| keypair.name | Body | String | Key pair name |
| keypair.fingerprint | Body | String | Key pair fingerprint |

<details><summary>Example</summary>
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
### Delete Key Pair { #delete-key-pair }
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

<a id="delete-key-pair-request"></a>
#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| keypairName | URL | String | O | Key pair name |
| tokenId | Header | String | O | Token ID |

<a id="delete-key-pair-response"></a>
#### Response
This API does not return a response body.


<a id="instance"></a>
## Instance { #instance }

<a id="instance-status"></a>
### Instance status { #instance-status }

Instances exist in various statuses, and each status defines its own set of permissible operations. See the following list of instance statuses.

| Status name              | Description                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | Instances that are in an active state |
| `BUILD` | Instances that are being created |
| `DELETED` | Instances that have been deleted |
| `ERROR` | Instances where the previous operation failed |
| `HARD_REBOOT` | Instances being forcibly restarted<br>This is equivalent to powering off and back on a physical server |
| `MIGRATING` | Instances undergoing migration<br>This occurs due to live migration (moving active instances) |
| `PASSWORD` | Instances for which a password is being reset |
| `PAUSED` | Instances that are paused<br>Paused instances are stored in the hypervisor's memory |
| `REBOOT` | Instances in soft reboot state<br>The reboot command is issued to the instance's operating system |
| `REBUILD` | The state in which instances are recreated from the original image |
| `RESCUE` | Instances being run in recovery mode |
| `RESIZE` | Changing the instance type or moving an instance to another host<br>The instance is stopped and then restarted |
| `REVERT_RESIZE` | Recovery to the original state when a resize or migration operation fails |
| `VERIFY_RESIZE` | Instances awaiting user confirmation after a resize or migration operation completes<br>In NHN Cloud, instances automatically transition to `ACTIVE` state |
| `SHELVED_OFFLOADED` | Instances that have been shelved |
| `SHUTOFF` | Instances that have been stopped |
| `SUSPENDED` | Instances suspended into hibernation mode by an administrator |
| `UNKNOWN` | Instances whose status is unknown<br>Contact your administrator if an instance enters this state. |

<a id="list-instances"></a>
### List instances { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| reservation_id | Query | String | - | Instance creation reservation ID.<br>If you specify a reservation ID, only instances created simultaneously are returned. |
| changes-since | Query | Datetime | - | Returns the list of instances that changed after the specified time. Format: `YYYY-MM-DDThh:mm:ss`. |
| image | Query | UUID | - | Image ID<br>Returns instances that use the specified image. |
| flavor | Query | UUID | - | Instance type ID<br>Returns instances that use the specified type. |
| name | Query | String | - | Instance name<br>Returns instances with the specified name. Regex queries are supported. |
| status | Query | Enum | - | Instance status<br>Returns instances with the specified status. |
| limit | Query | Integer | - | Number of instances<br>Returns the specified number of instances. |
| marker | Query | UUID | - | The first instance UUID in the list<br>Returns instances starting from the instance specified by `marker` up to `limit` instances based on the sort criteria. |

<a id="list-instances-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| servers | Body | Object | Instance list object |
| id | Body | UUID | Instance UUID |
| links | Body | Object | Instance path object |
| name | Body | String | Instance name |

<details><summary>Example</summary>
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