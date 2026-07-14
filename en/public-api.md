<a id="compute-instance-api-v2-guide"></a>

## Compute > Instance > API v2 Guide

Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is an authentication token used for NHN Cloud's OpenStack-based infrastructure services (IaaS). For more information on issuing and using IaaS tokens, see [IaaS token](/nhncloud/en/public-api/iaas-token).

The Instance API uses the `compute` type endpoint. For the exact endpoint, see `serviceCatalog` from the token issue response.

| Type | Region | Endpoint |
|---|---|---|
| compute | Korea (Pangyo) region<br>Korea (Pyeongchon) region<br>Korea (Gwangju) region<br>Japan region | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com |

API response may show the fields not specified by the guide. These fields are internally used by NHN Cloud, and not used because they are subject to change without prior notice.

<a id="instance-flavors"></a>

## Instance Type

<a id="list-flavors"></a>
### List Flavors

```
GET /v2/{tenantId}/flavors
X-Auth-Token: {tokenId}
```

#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br>Returns only flavors with block storage sizes greater than the specified value |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only flavors with RAM sizes greater than specified value |

#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance flavor list object |
| flavors.id | Body | UUID | Instance flavor ID |
| flavors.links | Body | Object | Instance flavor path object |
| flavors.name | Body | String | Instance flavor name |


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
### List Flavors with Details

```
GET /v2/{tenantId}/flavors/detail
X-Auth-Token: {tokenId}
```

#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br>Returns only flavors with block storage sizes greater than the specified value |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only flavors with RAM sizes greater than specified value |

#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance flavor list object |
| flavors.id | Body | UUID | Instance flavor ID |
| flavors.links | Body | Object | Instance flavor path object |
| flavors.name | Body | String | Instance flavor name |
| flavors.ram | Body | Integer | Memory size (MB) |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | Whether the flavor is enabled |
| flavors.vcpus | Body | Integer | Number of vCPUs |
| flavors.extra_specs | Body | Object | Additional specifications object |
| flavors.swap | Body | Integer | Swap area size (GB) |
| flavors.os-flavor-access:is_public | Body | Boolean | Whether the flavor is public |
| flavors.rxtx_factor | Body | Float | Network send/receive packet ratio |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | Ephemeral block storage size (GB) |
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

## Availability Zone

<a id="list-availability-zones"></a>
### List Availability Zones

```
GET /v2/{tenantId}/os-availability-zone
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |

#### Response
| Name | Type | Format | Description |
|---|---|---|---|
| availabilityZoneInfo | Body | Object | Availability zone info object |
| availabilityZoneInfo.zoneName | Body | String | Availability zone name |
| availabilityZoneInfo.zoneState | Body | Object | Availability zone state info object |
| availabilityZoneInfo.available | Body | Object | Availability zone status |

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

## Key Pairs

<a id="list-key-pairs"></a>
### List Key Pairs
```
GET /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |

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
### Get Key Pair
```
GET /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| keypairName | URL | String | O | Key pair name |
| tokenId | Header | String | O | Token ID |

#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| keypair | Body | Object | Key pair object list |
| keypair.public_key | Body | String | Public key |
| keypair.user_id | Body | String | Key pair owner ID |
| keypair.name | Body | String | Key pair name |
| keypair.deleted | Body | Boolean | Whether the key pair has been deleted |
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
### Create/Register Key Pair

```
POST /v2/{tenantId}/os-keypairs
X-Auth-Token: {tokenId}
```

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
### Delete Key Pair
```
DELETE /v2/{tenantId}/os-keypairs/{keypairName}
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| keypairName | URL | String | O | Key pair name |
| tokenId | Header | String | O | Token ID |

#### Response
This API does not return a response body.


<a id="instance"></a>

## Instance

<a id="instance-status"></a>

### Instance status

Instances exist in various statuses, and each status defines its own set of permissible operations. See the following list of instance statuses.

| Status | Description |
|---|---|
| `ACTIVE` | Instance is active |
| `BUILD` | Instance is being created |
| `DELETED` | Instance has been deleted |
| `ERROR` | The last operation performed on the instance failed |
| `HARD_REBOOT` | Instance has been hard-rebooted<br>Same as turning the physical server's power switch off and back on again |
| `MIGRATING` | Instance is being migrated<br>This is caused by a real-time migration (moving active instances) |
| `PASSWORD` | Instance is resetting its password |
| `PAUSED` | Instance is paused<br>A paused instance is stored in the hypervisor's memory |
| `REBOOT` | Instance is soft-rebooting<br>The reboot command is sent to the virtual machine's operating system |
| `REBUILD` | Instance is being rebuilt from the image used at the time of creation |
| `RESCUE` | Instance is running in rescue mode |
| `RESIZE` | Instance is changing flavors or migrating to another host<br>The instance has been stopped and restarted |
| `REVERT_RESIZE` | Instance is restored to its original state when a failure occurs while changing flavors or migrating to another host |
| `VERIFY_RESIZE` | Instance is waiting for confirmation after changing flavors or migrating to another host<br>In NHN Cloud, the status is automatically changed to `ACTIVE`. |
| `SHELVED_OFFLOADED` | Instance has been terminated |
| `SHUTOFF` | Instance has been stopped |
| `SUSPENDED` | Instance has been suspended by an administrator |
| `UNKNOWN` | The status of the instance is unknown<br>`If the instance enters this status, contact the administrator.` |

<a id="list-instances"></a>

### List Instances

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| reservation_id | Query | String | - | Reservation ID for instance creation. <br>If specified, only returns list of instances that have been created simultaneously |
| changes-since | Query | Datetime | - | Returns list of instances changed since the specified time. `YYYY-MM-DDThh:mm:ss` format. |
| image | Query | UUID | - | Image ID<br>Return list of instances using the specified image |
| flavor | Query | UUID | - | Instance type ID<br>Return list of instances using the specified type |
| name | Query | String | - | Instance name<br>Return list of instances with specified name, regex is supported |
| status | Query | Enum | - | Instance status<br>Return list of instances with the specified status |
| limit | Query | Integer | - | Number of instances in the list<br>Return list of instances up to the specified count |
| marker | Query | UUID | - | UUID of the first instance in the list<br>Return list of up to `limit` instances from the instance specified as the `marker`, according to the sort order |

#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| servers | Body | Object | List of instances object |
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

<a id="list-instances-with-details"></a>

### List Instances with Details

Return the list of instances created in the current tenant, same as List Instances. However, detailed instance information is returned.

```
GET /v2/{tenantId}/servers/detail
X-Auth-Token: {tokenId}
```

#### Request

The request format is the same as List Instances.

#### Response

| Name | Type | Format | Description                                                                                                                                                                                                        |
|---|---|---|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| servers | Body | Object | List object of instances                                                                                                                                                                                                |
| status | Body | Enum | Instance status                                                                                                                                                                                                   |
| servers.id | Body | UUID | Instance ID                                                                                                                                                                                                   |
| servers.name | Body | String | Instance name, up to 255 characters                                                                                                                                                                                          |
| servers.updated | Body | Datetime | Last updated time of instance in `YYYY-MM-DDThh:mm:ssZ` format                                                                                                                                                                  |
| servers.hostId | Body | String | ID of the host on which the instance is running                                                                                                                                                                                        |
| servers.addresses | Body | Object | List object of instance IPs. <br>The size of the list is the number of ports attached to the instance.                                                                                                                                                             |
| servers.addresses."Network 이름" | Body | Object | Port information for each Network attached to the instance                                                                                                                                                                                  |
| servers.addresses."Network 이름".OS-EXT-IPS-MAC:mac_addr | Body | String | MAC address of the port attached to the instance                                                                                                                                                                                      |
| servers.addresses."Network 이름".version | Body | Integer | IP version of the port attached to the instance<br>NHN Cloud supports IPv4 only                                                                                                                                                                |
| servers.addresses."Network 이름".addr | Body | String | IP address of the port attached to the instance                                                                                                                                                                                       |
| servers.addresses."Network 이름".OS-EXT-IPS:type | Body | Enum | IP address type of the port<br>Either `fixed` or `floating`                                                                                                                                                                |
| servers.links | Body | Object | Instance path object                                                                                                                                                                                                |
| servers.key_name | Body | String | Instance key pair name                                                                                                                                                                                               |
| servers.image | Body | Object | Instance image object                                                                                                                                                                                               |
| servers.image.id | Body | UUID | Instance image ID                                                                                                                                                                                               |
| servers.image.links | Body | Object | Instance image path object                                                                                                                                                                                            |
| servers.OS-EXT-STS:task_state | Body | String | Instance task state<br>Shows the status of a task operating on an instance                                                                                                                                                               |
| servers.OS-EXT-STS:vm_state | Body | String | Current state of the instance                                                                                                                                                                                                |
| servers.OS-SRV-USG:launched_at | Body | Datetime | Last boot time of the instance<br>`YYYY-MM-DDThh:mm:ss.ssssss` format                                                                                                                                                         |
| servers.OS-SRV-USG:terminated_at | Body | Datetime | Instance deletion time<br>`YYYY-MM-DDThh:mm:ssZ` format                                                                                                                                                                   |
| servers.flavor | Body | Object | Instance type information object                                                                                                                                                                                             |
| servers.flavor.id | Body | UUID | Instance type ID                                                                                                                                                                                                |
| servers.flavor.links | Body | Object | Instance type path object                                                                                                                                                                                             |
| servers.security_groups | Body | Object | List object of security groups assigned to the instance                                                                                                                                                                                     |
| servers.security_groups.name | Body | String | Name of the security group assigned to the instance                                                                                                                                                                                        |
| servers.user_id | Body | String | ID of the user who created the instance                                                                                                                                                                                          |
| servers.created | Body | Datetime | Instance created time. `YYYY-MM-DDThh:mm:ssZ` format                                                                                                                                                                     |
| servers.tenant_id | Body | String | Tenant ID that the instance belongs to                                                                                                                                                                                           |
| servers.os-extended-volumes:volumes_attached | Body | Object | List object of additional block storage attached to the instance                                                                                                                                                                                |
| servers.os-extended-volumes:volumes_attached.id | Body | UUID | ID of the additional block storage attached to the instance                                                                                                                                                                                   |
| servers.OS-EXT-STS:power_state | Body | Integer | Power state of the instance<br>- `1`: On<br>- `4`: Off                                                                                                                                                                    |
| servers.metadata | Body | Object | Instance metadata object<br>Stores instance metadata as key-value pairs                                                                                                                                                                   |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | Size of an additional local block storage attached to the instance                                                                                                                                                                   |
| server.NHN-EXT-ATTR:protect | Body | Boolean | Whether delete protection is enabled for the instance                                                                                                                                                                   |

<details><summary>Example</summary>
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

### Get Instance

```
GET /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| tokenId | Header | String | O | Token ID |

#### Response

| Name | Type | Format | Description                                                                                                                                                                                                       |
|---|---|---|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server | body | Object | Instance object                                                                                                                                                                                                  |
| status | body | Enum | Instance status                                                                                                                                                                                                  |
| server.id | Body | UUID | Instance ID                                                                                                                                                                                                  |
| server.name | Body | String | Instance name, up to 255 characters                                                                                                                                                                                         |
| server.updated | Body | Datetime | Last updated time of instance in `YYYY-MM-DDThh:mm:ssZ` format                                                                                                                                                                 |
| server.hostId | Body | String | ID of the host on which the instance is running                                                                                                                                                                                       |
| server.addresses | Body | Object | Instance IP list object <br>The size of the list is the number of ports attached to the instance.                                                                                                                                                              |
| server.addresses."Network name" | Body | Object | Port information by network attached to the instance                                                                                                                                                                                 |
| server.addresses."Network name".OS-EXT-IPS-MAC:mac_addr | Body | String | MAC address of the port attached to the instance                                                                                                                                                                                     |
| server.addresses."Network name".version | Body | Integer | IP version of the port attached to the instance<br>NHN Cloud supports IPv4 only                                                                                                                               |
| server.addresses."Network name".addr | Body | String | IP address of the port attached to the instance                                                                                                                                                                                      |
| server.addresses."Network name".OS-EXT-IPS:type | Body | Enum | IP address type of the port<br>One of `fixed` or `floating`                                                                                                                                               |
| server.links | Body | Object | Instance path object                                                                                                                                                                                               |
| server.key_name | Body | String | Instance key pair name                                                                                                                                                                                              |
| server.image | Body | Object | Instance image object                                                                                                                                                                                              |
| server.image.id | Body | UUID | Instance image ID                                                                                                                                                                                              |
| server.image.links | Body | Object | Instance image path object                                                                                                                                                                                           |
| server.OS-EXT-STS:task_state | Body | String | Instance task state<br>Indicates the progress of an action when an action is applied to the instance                                                                                                                                               |
| server.OS-EXT-STS:vm_state | Body | String | Current state of the instance                                                                                                                                                                               |
| server.OS-SRV-USG:launched_at | Body | Datetime | Last boot time of the instance<br>`YYYY-MM-DDThh:mm:ss.ssssss` format                                                                                                                                                        |
| server.OS-SRV-USG:terminated_at | Body | Datetime | Instance deletion time<br>`YYYY-MM-DDThh:mm:ssZ` format                                                                                                                                                                  |
| server.flavor | Body | Object | Instance type information object                                                                                                                                                                                            |
| server.flavor.id | Body | UUID | Instance type ID                                                                                                                                                                                               |
| server.flavor.links | Body | Object | Instance type path object                                                                                                                                                                                            |
| server.security_groups | Body | Object | List object of security groups assigned to the instance                                                                                                                                                                                    |
| server.security_groups.name | Body | String | Name of the security group assigned to the instance                                                                                                                                                                                       |
| server.user_id | Body | String | ID of the user who created the instance                                                                                                                                                                                         |
| server.created | Body | Datetime | Instance created time. `YYYY-MM-DDThh:mm:ssZ` format                                                                                                                                                                    |
| server.tenant_id | Body | String | Tenant ID to which the instance belongs                                                                                                                                                                                          |
| server.os-extended-volumes:volumes_attached | Body | Object | List object of additional block storage attached to the instance                                                                                                                                                                               |
| server.os-extended-volumes:volumes_attached.id | Body | UUID | ID of the additional block storage attached to the instance                                                                                                                                                                                  |
| server.OS-EXT-STS:power_state | Body | Integer | Power state of the instance<br>- `1`: On<br>- `4`: Off                                                                                                                                                                   |
| server.metadata | Body | Object | Instance metadata object<br>Stores instance metadata as key-value pairs                                                                                                                                                                  |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | Size of an additional local block storage attached to the instance                                                                                                                                                                  |
| server.NHN-EXT-ATTR:protect | Body | Boolean | Whether the instance is protected from deletion                                                                                                                                                                  |

<details><summary>Example</summary>
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

### Create Instance

Creates an instance.

After calling the Create Instance API, check the instance status by retrieving the instance.

* When the instance status becomes **ACTIVE**, the instance has been created successfully.
* If the status remains in **BUILDING** for a long time or becomes **ERROR**, check parameters used for instance creation and try creating again.

Windows instances have the following creation constraints for stable operation:

* Use an instance type with at least 2 GB of RAM.
* At least 50 GB of root block storage is required.
* The U2 type cannot use Windows images.

The root block storage size can be set starting from 10 GB for Linux and 50 GB for Windows.

You can assign a placement policy through scheduler hints when making an instance creation request.



```
POST /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

#### Request

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| server | body | Object | O | Server object |
| server.security_groups | body | Object | - | Security group list object<br>If omitted, the `default` group is added |
| server.security_groups.name | body | String | - | **(Conditionally required)** Name of the security group to add to the instance |
| server.user_data | body | String | - | Script and configuration to run after the instance boots<br>Base64-encoded string; up to 65,535 bytes allowed |
| server.availability_zone | body | String | - | Availability Zone in which to create the instance<br>If not specified, one is selected randomly<br>If the source type of the root block storage is `volume` or `snapshot`, it must be set to the same Availability Zone as the source block storage |
| server.imageRef | Body | String | - | ID of the image to use when creating the instance<br>Not required if the source type of the root block storage is `volume` or `snapshot` |
| server.flavorRef | Body | String | O | ID of the instance type to use when creating the instance |
| server.networks | Body | Object | O | Network information object to use when creating the instance<br>A NIC is added for each network specified. Specify each network using Network ID, Subnet ID, Port ID, or Fixed IP. |
| server.networks.uuid | Body | UUID | - | **(Conditionally required)** Network ID to use when creating the instance |
| server.networks.subnet | Body | UUID | - | **(Conditionally required)** Subnet ID of the network to use when creating the instance |
| server.networks.port | Body | UUID | - | **(Conditionally required)** Port ID to use when creating the instance<br>If a port ID is specified, the requested security groups are not applied to the specified existing port |
| server.networks.fixed_ip | Body | String | - | **(Conditionally required)** Fixed IP to use when creating the instance |
| server.name | Body | String | O | Name of the instance<br>Up to 255 characters allowed; must be 15 characters or fewer for Windows images |
| server.metadata | Body | Object | - | Metadata object to add to the instance<br>Key-value pairs with a maximum length of 255 characters |
| server.block_device_mapping_v2 | Body | Object | O | Block storage information object for the instance |
| server.block_device_mapping_v2.source_type | Body | Enum | O | Source type of the block storage to create<br>- `image`: Create block storage from an image<br>- `blank`: Create empty block storage (cannot be used as root block storage)<br>- `volume`: Use existing block storage<br>- `snapshot`: Create block storage from a snapshot |
| server.block_device_mapping_v2.uuid | Body | String | - | **(Conditionally required)** Must be set differently depending on the source type of the block storage<br>- If the source type is `image`, set the image ID<br>- If the source type is `volume`, set the ID of the existing block storage<br>- If the source type is `snapshot`, set the snapshot ID<br>- Not required if the source type is `blank`<br>For root block storage, the source must be bootable |
| server.block_device_mapping_v2.boot_index | Body | Integer | O | Boot order of the specified block storage<br>- `0` indicates root block storage<br>- Any other value indicates additional block storage<br>A higher value means a lower boot priority |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | Location of the instance's block storage; must be set differently depending on the instance type.<br>- `local`: For GPU instances or U2 instance types<br>- `volume`: For all other instance types |
| server.block_device_mapping_v2.volume_type | Body | Enum    | - | **(Conditionally required)** Type of block storage to create<br>Not required if the source type of the block storage is `volume` or `snapshot`<br>See the `name` in the **List Block Storage Types** response in `User Guide > Storage > Block Storage > API v2 Guide` |
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | Whether to delete the block storage when the instance is deleted; the default value is `false`.<br>`true` deletes the block storage; `false` retains it |
| server.block_device_mapping_v2.volume_size | Body | Integer | - | **(Conditionally required)** Size of the block storage to create<br>Must be set differently depending on the source type of the block storage<br>- Not required if the source type is `volume`<br>- Set equal to or larger than the original block storage size if the source type is `snapshot`<br>In `GB` units<br>Uses the U2 instance type and root block storage is created with the size specified in the U2 instance type and this value will be ignored<br>Different instance types have different sizes of root block storage that can be created. For more details, see `User Guide > Compute > Instance > Console User Guide > Create Instance > Block Storage Size`. |
| server.block_device_mapping_v2.nhn_encryption                   | Body | Object | - | **(Conditionally required)** Encryption information for the block storage                                                                                                                                                                                        |
| server.block_device_mapping_v2.nhn_encryption.skm_appkey        | Body | String | - | **(Conditionally required)** Appkey of the Secure Key Manager service                                                                                                                                                                                          |
| server.block_device_mapping_v2.nhn_encryption.skm_key_id        | Body | String | - | **(Conditionally required)** Symmetric key ID of Secure Key Manager to use for creating encrypted block storage                                                                                                                                  |
| server.key_name | Body | String | O | Key pair to use for instance access |
| server.min_count | Body | Integer | - | Minimum number of instances to create in the current request.<br>The default value is 1.<br>Can only be set to `1` if the source type of the block storage is `volume` |
| server.max_count | Body | Integer | - | Maximum number of instances to create in the current request.<br>The default value is min_count; the maximum value is 10.<br>Can only be set to `1` if the source type of the block storage is `volume` |
| server.return_reservation_id | Body | Boolean | - | Reservation ID for the instance creation request.<br>If set to True, returns the reservation ID instead of the instance creation information.<br>The default value is False |
| os:scheduler_hints | Body | Object | - | Scheduler hints object |
| os:scheduler_hints.group | Body | String | - | Placement policy ID |

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

#### Response

| Name | Type | Format | Description                                                                                                                                                                                                           |
|---|---|---|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server.security_groups.name | Body | String | Name of the security group for the created instance                                                                                                                                                                                          |
| server.id | Body | UUID | ID of the created instance                                                                                                                                                                                                |

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

### Modify Instance
Modify created instance. Only some attributes are allowed to be modified.

```
PUT /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

#### Request

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| server | Body | Object | O | Modify instance request object |
| server.name | Body | String | - | New name of the instance |

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

#### Response
Same as View Instance.

---

<a id="delete-instance"></a>

### Delete Instance
Deletes an instance.

```
DELETE /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to delete |
| tokenId | Header | String | O | Token ID |

#### Response
This API does not return a response body.

---

<a id="manage-block-storage-attachment"></a>

## Manage Block Storage Attachments

<a id="list-additional-block-storage-attached-to-the-instance"></a>
### List Additional Block Storage Attached to the Instance
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| limit | Query | Integer | - | Number of items to retrieve |
| offset | Query | Integer | - | Starting point of the list to return<br>Return block storage starting from offset of the entire list |

#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| volumeAttachments | Body | Array | List of attachment information objects |
| volumeAttachments.device | Body | String | Block storage name of the instance<br>e.g., `/dev/vdb` |
| volumeAttachments.id | Body | UUID | Attachment information ID |
| volumeAttachments.serverId | Body | UUID | Instance ID |
| volumeAttachments.volumeId | Body | UUID | Block Storage ID |

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

<a id="list-additional-block-storage-attached-to-the-instance"></a>
### Get Block Storage Attached to the Instance
```
GET /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| volumeId | URL | UUID | O | ID of block storage to retrieve |
| tokenId | Header | String | O | Token ID |

#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| volumeAttachment | Body | Object | Attachment information object |
| volumeAttachment.device | Body | String | Block storage name of the instance<br>e.g., `/dev/vdb` |
| volumeAttachment.id | Body | UUID | Attachment information ID |
| volumeAttachment.serverId | Body | UUID | Instance ID |
| volumeAttachment.volumeId | Body | UUID | Block Storage ID |

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
### Attach Additional Block Storage to the Instance
```
POST /v2/{tenantId}/servers/{serverId}/os-volume_attachments
X-Auth-Token: {tokenId}
```

#### Request

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
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

#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| volumeAttachment | Body | Object | Attachment information object |
| volumeAttachment.device | Body | String | Block storage name of the instance<br>e.g., `/dev/vdb` |
| volumeAttachment.id | Body | UUID | Attachment information ID |
| volumeAttachment.serverId | Body | UUID | Instance ID |
| volumeAttachment.volumeId | Body | UUID | Block Storage ID |

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
### Detach Block Storage from the Instance
```
DELETE /v2/{tenantId}/servers/{serverId}/os-volume_attachments/{volumeId}
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| volumeId | URL | UUID | O | ID of block storage to detach |
| tokenId | Header | String | O | Token ID |

#### Response
This API does not return a response body.

---

<a id="additional-instance-features"></a>

## Additional Instance Features
NHN Cloud provides the following instance control and additional features:

* Start, stop, terminate, and restart instances
* Change the instance flavor
* Create an instance image
* Add and remove security groups

<a id="start-stopped-instance"></a>
### Start a Stopped Instance

Restart a stopped instance and change its status to **ACTIVE**. To call this API, the instance status must be **SHUTOFF**.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| os-start | Body | none | O | Request to start the instance |

<details><summary>Example</summary>
<p>

```json
{
  "os-start" : null
}
```

</p>
</details>

#### Response
This API does not return a response body.

---

<a id="start-terminated-instance"></a>
### Start a Terminated Instance

Restart a terminated instance and changes its status to **ACTIVE**. To call this API, the instance's state must be **SHELVED_OFFLOADED**.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|--|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| unshelve | Body | none | O | Request to start the instance |

<details><summary>Example</summary>
<p>

```json
{
  "unshelve" : null
}
```

</p>
</details>

#### Response
This API does not return a response body.

---

<a id="stop-instance"></a>
### Stop an Instance

Stop instance and change its status to **SHUTOFF**. To call this API, the instance status must be either **ACTIVE** or **ERROR**.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| os-stop | Body | none | O | Request to stop the instance |

<details><summary>Example</summary>
<p>

```json
{
  "os-stop" : null
}
```

</p>
</details>

#### Response
This API does not return a response body.

---

### Terminate an Instance

Terminates an instance and changes its status to **SHELVED_OFFLOADED**. To call this API, the instance status must be **ACTIVE**.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description          |
|---|---|---|---|-------------|
| tenantId | URL | String | O | Tenant ID      |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID       |
| shelve | Body | none | O | Request to terminate the instance  |

<details><summary>Example</summary>
<p>

```json
{
  "shelve" : null
}
```

</p>
</details>

#### Response
This API does not return a response body.

---

### Restart an Instance

Restarts an instance. The restart type can be **SOFT** or **HARD**.

* **SOFT**: An instance is stopped via **"Graceful Shutdown"** and restarted. The instance must be in **ACTIVE** status.
* **HARD**: Forcefully stop the instance and restart it. This works the same way as turning the power switch of a physical server off and on again. An instance can only be forcefully stopped when it is in one of these statuses.
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

#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| reboot | Body | Object | O | Instance reboot request object |
| reboot.type | Body | Enum | O | Reboot type, **SOFT** or **HARD** |

<details><summary>Example</summary>
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

#### Response
This API does not return a response body.

---

### Change Instance Flavor

Change the flavor of an instance. Flavors can only be changed when an instance is **ACTIVE** or **SHUTOFF**. If an instance is **ACTIVE**, the instance is stopped and restarted while changing flavors.

Depending on the current image and flavor you are using, you may be restricted from changing to some flavors. For more details, see the Console Guide.


```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description                                                                                                                                                                                                                 |
|---|---|---|---|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| tenantId | URL | String | O | Tenant ID                                                                                                                                                                                                             |
| serverId | URL | UUID | O | ID of the instance to modify                                                                                                                                                                                                        |
| tokenId | Header | String | O | Token ID                                                                                                                                                                                                              |
| resize | Body | Object | O | Instance flavor change request                                                                                                                                                                                                      |
| resize.flavorRef | Body | UUID | O | ID of the flavor to change to                                                                                                                                                                                                     |

<details><summary>Example</summary>
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

#### Response
This API does not return a response body.

---

### Create an Instance Image

Create an image from an instance. Only `U2` flavor instances can create images via this API. To create images of non-`U2` flavor instances, see [Block Storage API](/Storage/Block Storage/en/public-api/#create-image-with-block-storage).

Images can only be created when an instance is **ACTIVE**, **SHUTOFF**, **SUSPENDED**, or **PAUSED**. It is recommended to stop instances before creating images to ensure data integrity.

When an image is successfully created, the image status becomes `active`. To check if an image is successfully created, use the Get Image API to continuously check its status.

> [Caution]
> The size of a created image may be larger than the actual usage of the root Block Storage.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| createImage | Body | Object | O | Request to create an image |
| createImage.name | Body | String | O | Name of the image to create |
| createImage.metadata | Body | Object | - | Metadata of the image to create<br>Described in key-value format |

<details><summary>Example</summary>
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


#### Response

This API does not return a response body. The created image can be found in the `Location` header of the response.

| Name | Type | Format | Description |
|--|--|--|--|
| Location | Header | String | URL of the created image |

---

### Add a Security Group

Adds a security group to an instance. The added security group is applied to all ports of the instance.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| addSecurityGroup | Body | Object | O | Security group add request object |
| addSecurityGroup.name | Body | String | O | Name of the security group to add |

<details><summary>Example</summary>
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


#### Response
This API does not return a response body.

---

### Remove a Security Group

Removes a security group from an instance. The specified security group is removed from all ports of the instance.

```
POST /v2/{tenantId}/servers/{serverId}/action
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|---|---|---|---|--|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | ID of the instance to modify |
| tokenId | Header | String | O | Token ID |
| removeSecurityGroup | Body | Object | O | Security group remove request object |
| removeSecurityGroup.name | Body | String | O | Name of the security group to remove |

<details><summary>Example</summary>
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


#### Response
This API does not return a response body.


<a id="terminate-instance"></a>

## Instance Metadata

Instance metadata values determine the content of the instance details screen on the **Compute > Instance** service page in the console. The details for each instance metadata item are as follows.

| Instance Metadata | Description |
|----------------|----------------------------------------------|
| os_distro      | The OS name in **Basic Information**<br>Used in combination with os_version |
| os_version     | The OS version in **Basic Information**<br>Used in combination with os_distro |
| image_name     | The **Image Name** in **Basic Information** |
| os_type        | The **Connection Information** format |
| login_username | The user name in **Connection Information** |

> [Caution] Modifying or deleting instance metadata may affect related services and features, and you are responsible for the consequences.

### List Instance Metadata

```
GET /v2/{tenantId}/servers/{serverId}/metadata
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|----------|---|---|---|--------------------------------------------------|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| tokenId  | Header | String | O | Token ID |

#### Response

| Name | Type | Format | Description |
|----------|---|---|--------------------------------------------------|
| metadata | Body | Object | Metadata object to create or modify for the instance<br>Key-value pairs of max 255 characters |

<details><summary>Example</summary>
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
### Get Instance Metadata

```
GET /v2/{tenantId}/servers/{serverId}/metadata/{key}
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|----------|---|---|---|--------------------------|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| key      | URL | String | O | Key of the metadata to create or modify for the instance |
| tokenId  | Header | String | O | Token ID |

#### Response

| Name | Type | Format | Description |
|------|---|---|--------------------------------------------------|
| meta | Body | Object | Metadata object to create or modify for the instance<br>Key-value pairs of max 255 characters |

<details><summary>Example</summary>
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
### Create or Modify Instance Metadata

Creates or modifies the metadata of an instance.
If the requested key matches an existing key, the key-value pair is updated to the requested value.

```
PUT /v2/{tenantId}/servers/{serverId}/metadata/{key}
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|----------|---|---|---|--------------------------------------------------|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| key      | URL | String | O | Key of the metadata to create or modify for the instance |
| tokenId  | Header | String | O | Token ID |
| meta     | Body | Object | O | Metadata object to create or modify for the instance<br>Key-value pairs of max 255 characters |

<details>
<summary>Example</summary>
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


#### Response

| Name | Type | Format | Description |
|------|---|---|--------------------------------------------------|
| meta | Body | Object | Metadata object to create or modify for the instance<br>Key-value pairs of max 255 characters |

<details><summary>Example</summary>
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
### Delete Instance Metadata

Deletes the metadata of an instance that matches the requested key.

```
DELETE /v2/{tenantId}/servers/{serverId}/metadata/{key}
X-Auth-Token: {tokenId}
```

#### Request
This API does not require a request body.

| Name | Type | Format | Required | Description |
|----------|---|---|---|---------------------|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| key      | URL | String | O | Key of the metadata to delete from the instance |
| tokenId  | Header | String | O | Token ID |

#### Response
This API does not return a response body.

## Placement Policy

<a id="add-security-group"></a>
### Create Placement Policy

Creates a placement policy.
Only the `anti-affinity` placement policy type for distributed placement is provided.

```
POST /v2/{tenantId}/os-server-groups
X-Auth-Token: {tokenId}
```

#### Request
| Name | Type | Format | Required | Description |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| server_group | Body | Object | O | Placement policy object |
| server_group.name | Body | String | O | Placement policy name |
| server_group.policies | Body | Array | O | Placement policy type<br>Only `anti-affinity` can be set |

<details>
<summary>Example</summary>
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

#### Response

| Name | Type | Format | Description |
|-----|-----|-----|-----|
| server_group | Body | Object | Placement policy object |
| server_group.id | Body | String | Placement policy ID |
| server_group.name | Body | String | Placement policy name |
| server_group.policies | Body | Array | Placement policy type |
| server_group.members | Body | Array | List of instance IDs assigned to the placement policy |
| server_group.metadata | Body | Object | Placement policy metadata object<br>Always displayed as an empty value |

<details><summary>Example</summary>
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
### List Placement Policies

```
GET /v2/{tenantId}/os-server-groups
X-Auth-Token: {tokenId}
```

#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |

#### Response

| Name | Type | Format | Description |
|-----|-----|-----|-----|
| server_groups | Body | Array | List of placement policy objects |
| server_groups.id | Body | String | Placement policy ID |
| server_groups.name | Body | String | Placement policy name |
| server_groups.policies | Body | Array | Placement policy type |
| server_groups.members | Body | Array | List of instance IDs assigned to the placement policy |
| server_groups.metadata | Body | Object | Placement policy metadata object<br>Always displayed as an empty value |

<details><summary>Example</summary>
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

### Get Placement Policy

```
GET /v2/{tenantId}/os-server-groups/{servergroupId}
X-Auth-Token: {tokenId}
```

#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | Tenant ID |
| servergroupId | URL | String | O | Placement policy ID |
| tokenId | Header | String | O | Token ID |

#### Response

| Name | Type | Format | Description |
|-----|-----|-----|-----|
| server_group | Body | Object | Placement policy object |
| server_group.id | Body | String | Placement policy ID |
| server_group.name | Body | String | Placement policy name |
| server_group.policies | Body | Array | Placement policy type |
| server_group.members | Body | Array | List of instance IDs assigned to the placement policy |
| server_group.metadata | Body | Object | Placement policy metadata object<br>Always displayed as an empty value |

<details><summary>Example</summary>
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

### Delete Placement Policy

```
DELETE /v2/{tenantId}/os-server-groups/{servergroupId}
X-Auth-Token: {tokenId}
```

#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|-----|-----|-----|-----|-----|
| tenantId | URL | String | O | Tenant ID |
| servergroupId | URL | String | O | Placement policy ID |
| tokenId | Header | String | O | Token ID |

#### Response

This API does not return a response body.