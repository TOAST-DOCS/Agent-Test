<!-- machine_translated: true -->

<!-- pre-align:aligned sig=27ed74e0499b -->

<a id="compute-instance-api-v2-guide"></a>

## Compute > Instance > API v2 Guide { #compute-instance-api-v2-guide }

Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is the authentication token used by the NHN Cloud's OpenStack-based infrastructure service (IaaS). For more information on issuing and using IaaS tokens, see [IaaS token](/nhncloud/en/public-api/iaas-token).

The Instance API uses the `compute` type endpoint. For the exact endpoint, see `serviceCatalog` from the token issue response.

| Type | Region | Endpoint |
|---|---|---|
| compute | Korea (Pangyo) region<br>Korea (Pyeongchon) region<br>Korea (Gwangju) region<br>Japan region | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

API response may show the fields not specified by the guide. These fields are internally used by NHN Cloud, and not used because they are subject to change without prior notice.

<a id="instance-flavors"></a>

## Instance Types { #instance-flavors }

<a id="list-flavors"></a>
### List Types { #list-flavors }

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

<a id="list-flavors-request"></a>
#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br>Returns only types with a block storage size larger than the specified size |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only types with a RAM size larger than the specified size |

<a id="list-flavors-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance type list object |
| flavors.id | Body | UUID | Instance type ID |
| flavors.links | Body | Object | Instance type path object |
| flavors.name | Body | String | Instance type name |


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
### List Types with Details { #list-flavors-with-details }

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
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br>Returns only types with a block storage size larger than the specified size |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only types with a RAM size larger than the specified size |

<a id="list-flavors-with-details-response"></a>
#### Response

| Name | Type | Format | Description             |
|---|---|---|----------------|
| flavors | Body | Object | Instance type list object  |
| flavors.id | Body | UUID | Instance type ID     |
| flavors.links | Body | Object | Instance type path object  |
| flavors.name | Body | String | Instance type name     |
| flavors.ram | Body | Integer | Memory size (MB)     |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | Whether enabled         |
| flavors.vcpus | Body | Integer | Number of vCPUs        |
| flavors.extra_specs | Body | Object | Additional specifications object       |
| flavors.swap | Body | Integer | Swap area size (GB)  |
| flavors.os-flavor-access:is_public | Body | Boolean | Whether shared          |
| flavors.rxtx_factor | Body | Float | Network send/receive packet ratio |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | Temporary block storage size (GB)     |
| flavors.disk | Body | Integer | Root block storage size (GB) |

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
| availabilityZoneInfo | Body | Object | Availability zone information object |
| availabilityZoneInfo.zoneName | Body | String | Availability zone name |
| availabilityZoneInfo.zoneState | Body | Object | Availability zone state information object |
| availabilityZoneInfo.available | Body | Object | Availability zone state |

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
| keypairs | Body | Array | Key pair object list |
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
| keypair | Body | Object | Key pair object list |
| keypair.public_key | Body | String | Public key |
| keypair.user_id | Body | String | Key pair owner ID |
| keypair.name | Body | String | Key pair name |
| keypair.deleted | Body | Boolean | Whether the key pair is deleted |
| keypair.created_at | Body | Datetime | Key pair created time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | Key pair updated time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | Key pair deleted time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
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
| keypair.public_key | Body | String | - | Public key to register. If left blank, a new key pair is created. |

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
| keypair.private_key | Body | String | Private key. Visible if a key pair has been newly generated. |
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

| Status Name              | Description                                                                                                |
|-------------------|---------------------------------------------------------------------------------------------------|
| `ACTIVE` | Instance is active |
| `BUILD` | Instance is being created |
| `DELETED` | Instance is deleted |
| `ERROR` | Previous operation on the instance failed |
| `HARD_REBOOT` | Instance is force rebooted<br>Same as turning the physical server's power switch off and back on again |
| `MIGRATING` | Instance is being migrated<br>This occurs due to live migration (moving active instances) |
| `PASSWORD` | Instance password is being reset |
| `PAUSED` | Instance is paused<br>Paused instance is stored in hypervisor memory |
| `REBOOT` | Instance is in soft reboot<br>Reboot command is sent to the virtual machine's operating system |
| `REBUILD` | Instance is being rebuilt from the original image |
| `RESCUE` | Instance is running in rescue mode |
| `RESIZE` | Instance flavor is being changed or migrated to another host<br>Instance is stopped and then restarted |
| `REVERT_RESIZE` | Instance is restored to its original state when a failure occurs while changing flavors or migrating to another host |
| `VERIFY_RESIZE` | Instance is waiting for confirmation after changing flavors or migrating to another host<br>In NHN Cloud, it automatically changes to `ACTIVE` status |
| `SHELVED_OFFLOADED` | Instance is shelved and offloaded |
| `SHUTOFF` | Instance is stopped |
| `SUSPENDED` | Instance is in hibernation mode by administrator |
| `UNKNOWN` | Instance status is unknown<br>`If the instance enters this state, contact your administrator.` | 

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
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| reservation_id | Query | String | - | Reservation ID for instance creation.<br>If specified, returns only instances created simultaneously |
| changes-since | Query | Datetime | - | Returns list of instances changed since the specified time. `YYYY-MM-DDThh:mm:ss` format. |
| image | Query | UUID | - | Image ID<br>Returns list of instances using the specified image |
| flavor | Query | UUID | - | Instance flavor ID<br>Returns list of instances using the specified flavor |
| name | Query | String | - | Instance name<br>Returns list of instances with the specified name; regex is supported |
| status | Query | Enum | - | Instance status<br>Returns list of instances with the specified status |
| limit | Query | Integer | - | Instance list count<br>Returns the specified number of instances |
| marker | Query | UUID | - | First instance UUID in the list<br>According to sort order, returns up to `limit` instances starting from the instance specified as `marker` |

<a id="list-instances-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| servers | Body | Object | Instance list object |
| id | Body | UUID | Instance UUID |
| links | body | Object | Instance path object |
| name | body | String | Instance name |

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