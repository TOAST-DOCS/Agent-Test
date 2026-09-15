<!-- machine_translated: true -->

<!-- pre-align:aligned sig=acfdd30fe5ef -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 Guide { #compute-instance-api-v2-guide }

Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is the authentication token used by NHN Cloud's OpenStack-based infrastructure service (IaaS). For more information about IaaS token issuance and usage, see [IaaS token](/nhncloud/en/public-api/iaas-token).

The Instance API uses the `compute` type endpoint. For the exact endpoint, refer to the `serviceCatalog` in the token issuance response.

| Type | Region | Endpoint |
|---|---|---|
| compute | Korea (Pangyo) Region<br>Korea (Pyeongchon) Region<br>Korea (Gwangju) Region<br>Japan Region | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com (Row modification test) |
| TEST-ROW | (New row test) | (New row test) |

The API response may include fields not specified in this guide. These fields are used for internal NHN Cloud purposes and may change without prior notice, so do not use them.

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
| minDisk | Query | Integer | - | Minimum Block Storage size (GB)<br>Returns only types with Block Storage size larger than the specified size |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only types with RAM size larger than the specified size |

<a id="response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance flavor list object |
| flavors.id | Body | UUID | Instance flavor ID |
| flavors.links | Body | Object | Instance flavor path object |
| flavors.name | Body | String | Flavor name |


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
| minDisk | Query | Integer | - | Minimum Block Storage size (GB)<br>Returns only types with Block Storage size larger than the specified size |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only types with RAM size larger than the specified size |

<a id="list-flavors-with-details-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance flavor list object |
| flavors.id | Body | UUID | Instance flavor ID |
| flavors.links | Body | Object | Instance flavor path object |
| flavors.name | Body | String | Flavor name |
| flavors.ram | Body | Integer | Memory size (MB) |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | Disabled status |
| flavors.vcpus | Body | Integer | Number of vCPUs |
| flavors.extra_specs | Body | Object | Additional specifications |
| flavors.swap | Body | Integer | Swap size (GB) |
| flavors.os-flavor-access:is_public | Body | Boolean | Public status |
| flavors.rxtx_factor | Body | Float | Network send/receive packet ratio |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | Ephemeral storage size (GB) |
| flavors.disk | Body | Integer | Root Block Storage size (GB) |

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
## Availability Zones { #availability-zones }

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
| availabilityZoneInfo | Body | Object | Availability Zone information object |
| availabilityZoneInfo.zoneName | Body | String | Availability Zone name |
| availabilityZoneInfo.zoneState | Body | Object | Availability Zone status information object |
| availabilityZoneInfo.available | Body | Object | Availability Zone status |

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
| keypairs | Body | Array | List of key pair objects |
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
| keypair | Body | Object | List of key pair objects |
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
| keypair.name | Body | String | O | Name of the key pair to create or register |
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
| keypair.private_key | Body | String | Private key. Returned when a new key pair is created. |
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
### Instance Status { #instance-status }

Instances exist in various statuses, and each status defines its own set of permissible operations. See the following list of instance statuses.

| Status | Description |
|---|---|
| `ACTIVE` | The instance is in an active state. |
| `BUILD` | The instance is being created. |
| `DELETED` | The instance has been deleted. |
| `ERROR` | The most recent action taken on the instance failed. |
| `HARD_REBOOT` | The instance is being forcibly restarted.<br>This is equivalent to powering off and then powering on the physical server. |
| `MIGRATING` | The instance is being migrated.<br>This occurs due to live migration (active instance movement) operations. |
| `PASSWORD` | A password reset is in progress on the instance. |
| `PAUSED` | The instance is paused.<br>A paused instance is stored in the hypervisor's memory. |
| `REBOOT` | The instance is in a soft reboot state.<br>A reboot command has been sent to the virtual machine's operating system. |
| `REBUILD` | The instance is being recreated from the original image. |
| `RESCUE` | The instance is running in rescue mode. |
| `RESIZE` | The instance type is being changed or the instance is being moved to a different host.<br>The instance has been stopped and restarted. |
| `REVERT_RESIZE` | The instance is being recovered to its original state after a resize or migration failed. |
| `VERIFY_RESIZE` | The instance has completed a resize or migration and is awaiting user confirmation.<br>On NHN Cloud, the instance automatically transitions to `ACTIVE` status in this case. |
| `SHELVED_OFFLOADED` | The instance has been shelved and offloaded. |
| `SHUTOFF` | The instance has been shut off. |
| `SUSPENDED` | The instance has been suspended by an administrator. |
| `UNKNOWN` | The instance status is unknown.<br>`If the instance enters this state, contact an administrator.` |

<a id="list-instances"></a>
### List Instances { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID. |
| tokenId | Header | String | O | Token ID. |
| reservation_id | Query | String | - | Instance reservation ID.<br>When a reservation ID is specified, only instances created simultaneously are returned. |
| changes-since | Query | Datetime | - | Returns instances modified after the specified time in the format `YYYY-MM-DDThh:mm:ss`. |
| image | Query | UUID | - | Image ID.<br>Returns instances using the specified image. |
| flavor | Query | UUID | - | Instance type ID.<br>Returns instances using the specified type. |
| name | Query | String | - | Instance name.<br>Returns instances with the specified name; can be queried using regular expressions. |
| status | Query | Enum | - | Instance status.<br>Returns instances with the specified status. |
| limit | Query | Integer | - | Number of instances in the list.<br>Returns the specified number of instances. |
| marker | Query | UUID | - | UUID of the first instance in the list.<br>Returns the specified number of instances starting from the instance specified by `marker` according to the sort order. |

<a id="list-instances-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| servers | Body | Object | Instance list object. |
| id | Body | UUID | Instance UUID. |
| links | body | Object | Instance path object. |
| name | body | String | Instance name. |

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

<a id="test-added-endpoint"></a>
### New test endpoint { #test-added-endpoint }

```
POST /v2/{tenantId}/test-added-endpoint
X-Auth-Token: {tokenId}
```

<a id="test-added-request"></a>
#### Request { #test-added-request }

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| name | Body | String | O | Endpoint name |

<a id="test-added-response"></a>
#### Response { #test-added-response }

| Name | Type | Format | Description |
|---|---|---|---|
| endpoint | Body | Object | Created endpoint object |
| endpoint.id | Body | String | Endpoint ID |
| endpoint.name | Body | String | Endpoint name |