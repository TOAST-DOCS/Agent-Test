<!-- machine_translated: true -->

<!-- pre-align:aligned sig=8e6d00d3460b -->

<a id="compute-instance-api-v2-guide"></a>
## Compute > Instance > API v2 Guide { #compute-instance-api-v2-guide }

Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is the authentication token used by the NHN Cloud's OpenStack-based infrastructure service (IaaS). For more information on IaaS token issuance and usage, see [IaaS token](/nhncloud/en/public-api/iaas-token). (Text modification test: This sentence should be reflected when the translation is re-executed.)

The Instance API uses the `compute` type endpoint. For the exact endpoint, see `serviceCatalog` from the token issue response.

| Type | Region | Endpoint |
|---|---|---|
| compute | Korea (Pangyo) region<br/>Korea (Pyeongchon) region<br/>Korea (Gwangju) region<br/>Japan region | https://kr1-api-instance-infrastructure.nhncloudservice.com<br/>https://kr2-api-instance-infrastructure.nhncloudservice.com<br/>https://kr3-api-instance-infrastructure.nhncloudservice.com<br/>https://jp1-api-instance-infrastructure.nhncloudservice.com |

API response may show fields that are not specified in this guide. These fields are used internally by NHN Cloud and are subject to change without prior notice, so they are not used.

<a id="instance-flavors"></a>
## Instance Types { #instance-flavors }

<a id="list-flavors"></a>
### List Instance Types { #list-flavors }

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
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br/>Returns only flavors with block storage sizes greater than the specified value |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br/>Returns only flavors with RAM sizes greater than specified value |

<a id="response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance type list object |
| flavors.id | Body | UUID | Instance type ID |
| flavors.links | Body | Object | Instance type link object |
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
### List Instance Types in Detail { #list-flavors-with-details }

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
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br/>Returns only flavors with block storage sizes greater than the specified value |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br/>Returns only flavors with RAM sizes greater than specified value |

<a id="list-flavors-with-details-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance type list object |
| flavors.id | Body | UUID | Instance type ID |
| flavors.links | Body | Object | Instance type link object |
| flavors.name | Body | String | Instance type name |
| flavors.ram | Body | Integer | Memory size (MB) |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | Enabled status |
| flavors.vcpus | Body | Integer | vCPU count |
| flavors.extra_specs | Body | Object | Additional specification object |
| flavors.swap | Body | Integer | Swap area size (GB) |
| flavors.os-flavor-access:is_public | Body | Boolean | Public sharing status |
| flavors.rxtx_factor | Body | Float | Network transmission/reception packet ratio |
| flavors.OS-FLV-EXT-DATA:ephemeral | Body | Integer | Temporary block storage size (GB) |
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
| availabilityZoneInfo | Body | Object | Availability zone info object |
| availabilityZoneInfo.zoneName | Body | String | Availability zone name |
| availabilityZoneInfo.zoneState | Body | Object | Availability zone state info object |
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
## Key Pair { #key-pairs }

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
| keypair | Body | Object | Key pair object |
| keypair.public_key | Body | String | Public key |
| keypair.user_id | Body | String | Key pair owner ID |
| keypair.name | Body | String | Key pair name |
| keypair.deleted | Body | Boolean | Key pair deletion status |
| keypair.created_at | Body | Datetime | Key pair creation time<br/>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | Key pair modification time<br/>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.deleted_at | Body | Datetime | Key pair deletion time<br/>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
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
### Create or Register a Key Pair { #createregister-key-pair }

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
### Delete a Key Pair { #delete-key-pair }
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
| `ACTIVE` | Instance is in an active state |
| `BUILD` | Instance is being created |
| `DELETED` | Instance has been deleted |
| `ERROR` | The previous operation performed on the instance failed |
| `HARD_REBOOT` | Instance has been hard rebooted<br/>Same as turning the physical server's power switch off and back on again |
| `MIGRATING` | Instance is being migrated<br/>This is caused by a real-time migration (moving active instances) |
| `PASSWORD` | Instance password is being reset |
| `PAUSED` | Instance has been paused<br/>A paused instance is stored in the hypervisor's memory |
| `REBOOT` | Instance is performing a soft reboot<br/>The reboot command has been sent to the virtual machine's operating system |
| `REBUILD` | Instance is being rebuilt from the original image |
| `RESCUE` | Instance is running in rescue mode |
| `RESIZE` | Instance is changing flavors or migrating to another host<br/>The instance has been stopped and restarted |
| `REVERT_RESIZE` | Instance is restored to its original state when a failure occurs while changing flavors or migrating to another host |
| `VERIFY_RESIZE` | Instance is waiting for confirmation after changing flavors or migrating to another host<br/>In NHN Cloud, the status is automatically changed to `ACTIVE` |
| `SHELVED_OFFLOADED` | Instance has been shelved |
| `SHUTOFF` | Instance has been shut off |
| `SUSPENDED` | Instance has been suspended by the administrator |
| `UNKNOWN` | The instance status is unknown<br/>`If the instance enters this status, contact the administrator` |

<a id="list-instances"></a>
### List Instances { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### Request

This API does not require a request body.

| Name | Location | Type | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| reservation_id | Query | String | - | Instance creation reservation ID. <br/>If specified, only returns list of instances that have been created simultaneously |
| changes-since | Query | Datetime | - | Returns list of instances changed since the specified time. Format: `YYYY-MM-DDThh:mm:ss` |
| image | Query | UUID | - | Image ID<br/>Return list of instances using the specified image |
| flavor | Query | UUID | - | Instance type ID<br/>Return list of instances using the specified type |
| name | Query | String | - | Instance name<br/>Return list of instances with specified name, regex is supported |
| status | Query | Enum | - | Instance status<br/>Return list of instances with specified status |
| limit | Query | Integer | - | Number of instances in list<br/>Return list of up to specified number of instances |
| marker | Query | UUID | - | UUID of first instance in list<br/>Return list of up to `limit` instances from the instance specified as `marker`, according to the sort order |

<a id="list-instances-response"></a>
#### Response

| Name | Location | Type | Description |
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

<a id="list-instances-with-details"></a>
### List Instances with Details { #list-instances-with-details }

Return the list of instances created in the current tenant, same as List Instances. However, detailed instance information is returned.

```
GET /v2/{tenantId}/servers/detail
X-Auth-Token: {tokenId}
```

<a id="list-instances-with-details-request"></a>
#### Request

The request format is the same as List Instances.

<a id="list-instances-with-details-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|-----------|
| servers | body | Object | Instance list object |
| status | body | Enum | Instance status |
| servers.id | Body | UUID | Instance ID |
| servers.name | Body | String | Instance name, up to 255 characters |
| servers.updated | Body | Datetime | Last updated time of instance in `YYYY-MM-DDThh:mm:ssZ` format |
| servers.hostId | Body | String | Host ID on which the instance is running |
| servers.addresses | Body | Object | Instance IP list object. <br/>The size of the list is the number of ports attached to the instance. |
| servers.addresses."Network name" | Body | Object | Network-specific port information attached to the instance |
| servers.addresses."Network name".OS-EXT-IPS-MAC:mac_addr | Body | String | MAC address of the port attached to the instance |
| servers.addresses."Network name".version | Body | Integer | IP version of the port attached to the instance<br/>NHN Cloud supports IPv4 only |
| servers.addresses."Network name".addr | Body | String | IP address of the port attached to the instance |
| servers.addresses."Network name".OS-EXT-IPS:type | Body | Enum | Port IP address type<br/>One of `fixed` or `floating` |
| servers.links | Body | Object | Instance path object |
| servers.key_name | Body | String | Instance keypair name |
| servers.image | Body | Object | Instance image object |
| servers.image.id | Body | UUID | Instance image ID |
| servers.image.links | Body | Object | Instance image path object |
| servers.OS-EXT-STS:task_state | Body | String | Instance task state<br/>Shows the status of a task operating on an instance |
| servers.OS-EXT-STS:vm_state | Body | String | Current state of the instance |
| servers.OS-SRV-USG:launched_at | Body | Datetime | Last instance boot time<br/>`YYYY-MM-DDThh:mm:ss.ssssss` format |
| servers.OS-SRV-USG:terminated_at | Body | Datetime | Instance deletion time<br/>`YYYY-MM-DDThh:mm:ssZ` format |
| servers.flavor | Body | Object | Instance type information object |
| servers.flavor.id | Body | UUID | Instance type ID |
| servers.flavor.links | Body | Object | Instance type path object |
| servers.security_groups | Body | Object | List object of security groups assigned to the instance |
| servers.security_groups.name | Body | String | Name of security groups assigned to the instance |
| servers.user_id | Body | String | User ID that created the instance |
| servers.created | Body | Datetime | Instance created time. `YYYY-MM-DDThh:mm:ssZ` format |
| servers.tenant_id | Body | String | Tenant ID to which the instance belongs |
| servers.os-extended-volumes:volumes_attached | Body | Object | List object of additional block storage attached to the instance |
| servers.os-extended-volumes:volumes_attached.id | Body | UUID | ID of additional block storage attached to the instance |
| servers.OS-EXT-STS:power_state | Body | Integer | Power state of the instance<br/>- `1`: On<br/>- `4`: Off |
| servers.metadata | Body | Object | Instance metadata object<br/>Instance metadata is stored as key-value pairs |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | Size of an additional local block storage attached to the instance |
| server.NHN-EXT-ATTR:protect | Body | Boolean | Whether instance deletion protection is enabled |

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
### Get Instance { #get-instance }

```
GET /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="get-instance-request"></a>
#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID |
| tokenId | Header | String | O | Token ID |

<a id="get-instance-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| server | body | Object | Instance object |
| status | body | Enum | Instance status |
| server.id | Body | UUID | Instance ID |
| server.name | Body | String | Instance name, up to 255 characters |
| server.updated | Body | Datetime | Last updated time of instance in `YYYY-MM-DDThh:mm:ssZ` format |
| server.hostId | Body | String | Host ID where the instance is running |
| server.addresses | Body | Object | Instance IP address list object <br/>The size of the list is the number of ports attached to the instance. |
| server.addresses."Network name" | Body | Object | Port information per network connected to the instance |
| server.addresses."Network name".OS-EXT-IPS-MAC:mac_addr | Body | String | MAC address of the port attached to the instance |
| server.addresses."Network name".version | Body | Integer | IP version of the port attached to the instance<br/>NHN Cloud supports only IPv4 |
| server.addresses."Network name".addr | Body | String | IP address of the port attached to the instance |
| server.addresses."Network name".OS-EXT-IPS:type | Body | Enum | IP address type of the port<br/>Either `fixed` or `floating` |
| server.links | Body | Object | Instance path object |
| server.key_name | Body | String | Instance key pair name |
| server.image | Body | Object | Instance image object |
| server.image.id | Body | UUID | Instance image ID |
| server.image.links | Body | Object | Instance image path object |
| server.OS-EXT-STS:task_state | Body | String | Instance task state<br/>Indicates the progress of an operation when an action is performed on the instance |
| server.OS-EXT-STS:vm_state | Body | String | Current status of the instance |
| server.OS-SRV-USG:launched_at | Body | Datetime | Last instance boot time<br/>`YYYY-MM-DDThh:mm:ss.ssssss` format |
| server.OS-SRV-USG:terminated_at | Body | Datetime | Instance deletion time<br/>`YYYY-MM-DDThh:mm:ssZ` format |
| server.flavor | Body | Object | Instance type information object |
| server.flavor.id | Body | UUID | Instance type ID |
| server.flavor.links | Body | Object | Instance type path object |
| server.security_groups | Body | Object | List object of security groups assigned to the instance |
| server.security_groups.name | Body | String | Name of security group assigned to the instance |
| server.user_id | Body | String | User ID who created the instance |
| server.created | Body | Datetime | Instance created time. `YYYY-MM-DDThh:mm:ssZ` format |
| server.tenant_id | Body | String | Tenant ID to which the instance belongs |
| server.os-extended-volumes:volumes_attached | Body | Object | List object of additional block storage attached to the instance |
| server.os-extended-volumes:volumes_attached.id | Body | UUID | ID of additional block storage attached to the instance |
| server.OS-EXT-STS:power_state | Body | Integer | Power state of the instance<br/>- `1`: On<br/>- `4`: Off |
| server.metadata | Body | Object | Instance metadata object<br/>Store instance metadata as key-value pairs |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | Size of an additional local block storage attached to the instance |
| server.NHN-EXT-ATTR:protect | Body | Boolean | Whether to protect the instance from deletion |

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
### Create Instance { #create-instance }

Creates an instance.

After calling the Create Instance API, verify the instance status by querying the instance.

* When the instance status becomes **ACTIVE**, the instance is successfully created.
* If the status remains in **BUILDING** for a long time or becomes **ERROR**, check parameters used for instance creation and try creating again.

Windows instances have the following creation restrictions for stable operation:

* Use an instance type with 2 GB or more of RAM.
* A root block storage of 50 GB or more is required.
* The U2 instance type cannot be used with Windows images.

The root block storage size can be set to 10 GB or more for Linux and 50 GB or more for Windows.

When creating an instance, you can assign a placement policy through scheduler hints.



```
POST /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="create-instance-request"></a>
#### Request

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| server | body | Object | O | Server object |
| server.security_groups | body | Object | - | Security group list object<br/>If not specified, the `default` group is added |
| server.security_groups.name | body | String | - | **(Conditionally required)** Name of the security group to add to the instance |
| server.user_data | body | String | - | Script and configuration to be executed after the instance boots<br/>Base64-encoded string up to 65,535 bytes is allowed |
| server.availability_zone | body | String | - | Availability zone where the instance will be created<br/>If not specified, one is selected automatically<br/>If the source type of the root block storage is `volume` or `snapshot`, it must be set to the same availability zone as the source block storage |
| server.imageRef | Body | String | - | Image ID to use when creating the instance<br/>Not required if the source type of the root block storage is `volume` or `snapshot` |
| server.flavorRef | Body | String | O | Instance type ID to use when creating the instance |
| server.networks | Body | Object | O | Network information object to use when creating the instance<br/>A NIC is added for each network specified. Specify each network using Network ID, Subnet ID, Port ID, or Fixed IP. |
| server.networks.uuid | Body | UUID | - | **(Conditionally required)** Network ID to use when creating the instance |
| server.networks.subnet | Body | UUID | - | **(Conditionally required)** Subnet ID of the network to use when creating the instance |
| server.networks.port | Body | UUID | - | **(Conditionally required)** Port ID to use when creating the instance<br/>If a port ID is specified, the requested security groups are not applied to the specified existing port |
| server.networks.fixed_ip | Body | String | - | **(Conditionally required)** Fixed IP to use when creating the instance |
| server.name | Body | String | O | Instance name<br/>Up to 255 characters are allowed based on English characters, but for Windows images, must be 15 characters or fewer |
| server.metadata | Body | Object | - | Metadata object to add to the instance<br/>Key-value pairs with a maximum length of 255 characters each |
| server.block_device_mapping_v2 | Body | Object | O | Block storage information object for the instance |
| server.block_device_mapping_v2.source_type | Body | Enum | O | Type of the source for the block storage to be created<br/>- `image`: Create block storage using an image<br/>- `blank`: Create empty block storage (cannot be used as root block storage)<br/>- `volume`: Use existing block storage<br/>- `snapshot`: Create block storage using a snapshot |
| server.block_device_mapping_v2.uuid | Body | String | - | **(Conditionally required)** Must be set differently depending on the source type of block storage<br/>- If the source type is `image`, set the image ID<br/>- If the source type is `volume`, set the existing block storage ID<br/>- If the source type is `snapshot`, set the snapshot ID<br/>- If the source type is `blank`, not required<br/>If it is root block storage, the source must be bootable |
| server.block_device_mapping_v2.boot_index | Body | Integer | O | Boot order of the specified block storage<br/>- `0` is the root block storage<br/>- Otherwise, additional block storage<br/>The larger the size, the lower the boot order |
| server.block_device_mapping_v2.destination_type | Body | Enum | O | Location of the instance block storage, must be set differently depending on the instance type.<br/>- `local`: When using GPU instance or U2 instance type<br/>- `volume`: When using other instance types |
| server.block_device_mapping_v2.volume_type | Body | Enum    | - | **(Conditionally required)** Type of block storage to be created<br/>Not required if the source type of block storage is `volume` or `snapshot`<br/>See `name` in the response of **View Block Storage Type List** in `User Guide > Storage > Block Storage > API v2 Guide` |
| server.block_device_mapping_v2.delete_on_termination | Body | Boolean | - | Whether to process block storage when the instance is deleted, default is `false`.<br/>`true` deletes it, `false` retains it |
| server.block_device_mapping_v2.volume_size | Body | Integer | - | **(Conditionally required)** Size of block storage to be created<br/>Must be set differently depending on the source type of block storage<br/>- If the source type is `volume`, not required<br/>- If the source type is `snapshot`, set equal to or larger than the original block storage size<br/>In GB units<br/>When using the U2 instance type and creating root block storage, it is created with the size specified in the U2 instance type and this value is ignored<br/>Different instance types have different sizes of root block storage that can be created. For more details, see `User Guide > Compute > Instance > Console User Guide > Create Instance > Block Storage Size` |
| server.block_device_mapping_v2.nhn_encryption                   | Body | Object | - | **(Conditionally required)** Block storage encryption information                                                                                                                                                                                        |
| server.block_device_mapping_v2.nhn_encryption.skm_appkey        | Body | String | - | **(Conditionally required)** App key of the Secure Key Manager service                                                                                                                                                                              |
| server.block_device_mapping_v2.nhn_encryption.skm_key_id        | Body | String | - | **(Conditionally required)** Symmetric key ID of the Secure Key Manager to be used for creating encrypted block storage                                                                                                                  |
| server.key_name | Body | String | O | Key pair to use for instance access |
| server.min_count | Body | Integer | - | Minimum number of instances to be created in the current request.<br/>Default is 1.<br/>Can only be set to `1` if the source type of block storage is `volume` |
| server.max_count | Body | Integer | - | Maximum number of instances to be created in the current request.<br/>Default is min_count, maximum is 10.<br/>Can only be set to `1` if the source type of block storage is `volume` |
| server.return_reservation_id | Body | Boolean | - | Reservation ID for the instance creation request.<br/>If set to True, returns the reservation ID instead of instance creation information.<br/>Default is False |
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

<a id="create-instance-response"></a>
#### Response

| Name | Type | Format | Description                                                                                                                                                                                                           |
|---|---|---|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server.security_groups.name | Body | String | Security group name of the created instance                                                                                                                                                                                           |
| server.id | Body | UUID | ID of the created instance                                                                                                                                                                                                 |

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
| serverId | URL | UUID | O | Instance ID to modify |
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
Same as the instance view.

---

<a id="delete-instance"></a>
### Delete Instance { #delete-instance }

Deletes an instance.

```
DELETE /v2/{tenantId}/servers/{serverId}
X-Auth-Token: {tokenId}
```

<a id="delete-instance-request"></a>
#### Request

This API does not require a request body.

| Name | Type | Format | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| serverId | URL | UUID | O | Instance ID to delete |
| tokenId | Header | String | O | Token ID |

<a id="delete-instance-response"></a>
#### Response

This API does not return a response body.

---
