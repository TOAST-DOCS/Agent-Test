<!-- pre-align:aligned sig=2e2588e1a607 -->

<a id="compute-instance-api-v2-guide"></a>

## Compute > Instance > API v2 Guide { #compute-instance-api-v2-guide }

Instance uses the IaaS token for authentication/authorization when making API calls. The IaaS token is an authentication token used by the NHN Cloud's OpenStack-based infrastructure service (IaaS). For more information on IaaS token issuance and usage, see [IaaS token](/nhncloud/en/public-api/iaas-token).

The Instance API uses the `compute` type endpoint. For the exact endpoint, refer to `serviceCatalog` from the token issuance response.

| Type | Region | Endpoint |
|---|---|---|
| compute | Korea (Pangyo) Region<br>Korea (Pyeongchon) region<br>Korea (Gwangju) region<br>Japan Region | https://kr1-api-instance-infrastructure.nhncloudservice.com<br>https://kr2-api-instance-infrastructure.nhncloudservice.com<br>https://kr3-api-instance-infrastructure.nhncloudservice.com<br>https://jp1-api-instance-infrastructure.nhncloudservice.com | (row modification test)
| TEST-ROW | (New row test) | (New row test) |
API responses may show fields not specified in the guide. These fields are used internally by NHN Cloud and are subject to change without prior notice, so they are not used.

<a id="instance-flavors"></a>
## Instance Type { #instance-flavors }

<a id="list-flavors"></a>
### List Flavors { #list-flavors }

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
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br>Returns only flavors with block storage sizes greater than the specified value |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only flavors with RAM sizes greater than specified value |

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
| minDisk | Query | Integer | - | Minimum block storage size (GB)<br>Returns only flavors with block storage sizes greater than the specified value |
| minRam | Query | Integer | - | Minimum RAM size (MB)<br>Returns only flavors with RAM sizes greater than specified value |

<a id="list-flavors-with-details-response"></a>
#### Response

| Name | Type | Format | Description |
|---|---|---|---|
| flavors | Body | Object | Instance type list object |
| flavors.id | Body | UUID | Instance type ID |
| flavors.links | Body | Object | Instance type path object |
| flavors.name | Body | String | Instance type name |
| flavors.ram | Body | Integer | Memory size (MB) |
| flavors.OS-FLV-DISABLED:disabled | Body | Boolean | Enabled status |
| flavors.vcpus | Body | Integer | Number of vCPUs |
| flavors.extra_specs | Body | Object | Additional specifications object |
| flavors.swap | Body | Integer | Swap area size (GB) |
| flavors.os-flavor-access:is_public | Body | Boolean | Public status |
| flavors.rxtx_factor | Body | Float | Network transmission packet rate |
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
| keypair | Body | Object | List of key pair objects |
| keypair.public_key | Body | String | Public key |
| keypair.user_id | Body | String | Key pair owner ID |
| keypair.name | Body | String | Key pair name |
| keypair.deleted | Body | Boolean | Whether the key pair has been deleted |
| keypair.created_at | Body | Datetime | Key pair creation time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
| keypair.updated_at | Body | Datetime | Key pair update time<br>`YYYY-MM-DDThh:mm:ss.SSSSSS` |
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
|--------|-------------|
| `ACTIVE` | Instance is active |
| `BUILD` | Instance is being created |
| `DELETED` | Instance has been deleted |
| `ERROR` | The previous action on the instance failed |
| `HARD_REBOOT` | Instance is being force restarted<br> Same as turning the physical server's power switch off and back on again |
| `MIGRATING` | Instance is migrating<br> This is caused by a real-time migration (moving active instances) |
| `PASSWORD` | Password is being reset on the instance |
| `PAUSED` | Instance is paused<br>A paused instance is stored in the hypervisor's memory |
| `REBOOT` | Instance is soft rebooting<br> A reboot command is being sent to the virtual machine's operating system |
| `REBUILD` | Instance is being rebuilt from its original image |
| `RESCUE` | Instance is running in rescue mode |
| `RESIZE` | Instance is changing flavors or migrating to another host<br>Instance has been stopped and restarted |
| `REVERT_RESIZE` | Instance is restored to its original state when a failure occurs while changing flavors or migrating to another host |
| `VERIFY_RESIZE` | Instance is waiting for confirmation after changing flavors or migrating to another host<br>In NHN Cloud, the status is automatically changed to `ACTIVE` |
| `SHELVED_OFFLOADED` | Instance has been shelved |
| `SHUTOFF` | Instance is stopped |
| `SUSPENDED` | Instance has entered hibernation mode initiated by the administrator |
| `UNKNOWN` | Instance status is unknown<br>`If an instance enters this state, contact an administrator.` |

<a id="list-instances"></a>
### List Instances { #list-instances }

```
GET /v2/{tenantId}/servers
X-Auth-Token: {tokenId}
```

<a id="list-instances-request"></a>
#### Request

This API does not require a request body.

| Name | Category | Type | Required | Description |
|---|---|---|---|---|
| tenantId | URL | String | O | Tenant ID |
| tokenId | Header | String | O | Token ID |
| reservation_id | Query | String | - | Instance creation reservation ID. <br>If specified, only returns list of instances created simultaneously |
| changes-since | Query | Datetime | - | Returns list of instances changed since the specified time. `YYYY-MM-DDThh:mm:ss` format. |
| image | Query | UUID | - | Image ID<br>Return list of instances using the specified image |
| flavor | Query | UUID | - | Instance type ID<br>Return list of instances using the specified type |
| name | Query | String | - | Instance name<br>Return list of instances with specified name, regex is supported |
| status | Query | Enum | - | Instance status<br>Return list of instances with specified status |
| limit | Query | Integer | - | Number of instances in the list<br>Return list of the specified number of instances |
| marker | Query | UUID | - | First instance UUID in the list<br>Return list of up to `limit` instances from the instance specified as the `marker`, according to the sort order |

<a id="list-instances-response"></a>
#### Response

| Name | Category | Type | Description |
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
|---|---|---|---|
| servers | body | Object | List object of instances |
| status | body | Enum | Instance status |
| servers.id | Body | UUID | Instance ID |
| servers.name | Body | String | Instance name, up to 255 characters |
| servers.updated | Body | Datetime | Last updated time of instance in `YYYY-MM-DDThh:mm:ssZ` format |
| servers.hostId | Body | String | ID of host running the instance |
| servers.addresses | Body | Object | Instance IP list object. <br>The size of the list is the number of ports attached to the instance. |
| servers.addresses."Network name" | Body | Object | Port information by network connected to the instance |
| servers.addresses."Network name".OS-EXT-IPS-MAC:mac_addr | Body | String | MAC address of the port connected to the instance |
| servers.addresses."Network name".version | Body | Integer | IP version of the port connected to the instance<br>NHN Cloud supports only IPv4 |
| servers.addresses."Network name".addr | Body | String | IP address of the port connected to the instance |
| servers.addresses."Network name".OS-EXT-IPS:type | Body | Enum | IP address type of the port<br>Either `fixed` or `floating` |
| servers.links | Body | Object | Instance link object |
| servers.key_name | Body | String | Instance key pair name |
| servers.image | Body | Object | Instance image object |
| servers.image.id | Body | UUID | Instance image ID |
| servers.image.links | Body | Object | Instance image link object |
| servers.OS-EXT-STS:task_state | Body | String | Instance task state<br>Shows the status of a task operating on an instance |
| servers.OS-EXT-STS:vm_state | Body | String | Current instance status |
| servers.OS-SRV-USG:launched_at | Body | Datetime | Last boot time of instance<br>`YYYY-MM-DDThh:mm:ss.ssssss` format |
| servers.OS-SRV-USG:terminated_at | Body | Datetime | Instance termination time<br>`YYYY-MM-DDThh:mm:ssZ` format |
| servers.flavor | Body | Object | Instance type information object |
| servers.flavor.id | Body | UUID | Instance type ID |
| servers.flavor.links | Body | Object | Instance type link object |
| servers.security_groups | Body | Object | List object of security groups assigned to the instance |
| servers.security_groups.name | Body | String | Name of security group assigned to the instance |
| servers.user_id | Body | String | User ID that created the instance |
| servers.created | Body | Datetime | Instance created time. `YYYY-MM-DDThh:mm:ssZ` format |
| servers.tenant_id | Body | String | Tenant ID to which the instance belongs |
| servers.os-extended-volumes:volumes_attached | Body | Object | List object of additional block storage attached to the instance |
| servers.os-extended-volumes:volumes_attached.id | Body | UUID | ID of additional block storage attached to the instance |
| servers.OS-EXT-STS:power_state | Body | Integer | Power state of instance<br>- `1`: On<br>- `4`: Off |
| servers.metadata | Body | Object | Instance metadata object<br>Instance metadata is stored as key-value pairs |
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
### View Instance { #get-instance }

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
| server.name | Body | String | Instance name, maximum 255 characters |
| server.updated | Body | Datetime | Last updated time of instance in `YYYY-MM-DDThh:mm:ssZ` format |
| server.hostId | Body | String | Host ID on which the instance is running |
| server.addresses | Body | Object | List object of instance IPs <br>The size of the list is the number of ports attached to the instance |
| server.addresses."Network name" | Body | Object | Port information by network connected to the instance |
| server.addresses."Network name".OS-EXT-IPS-MAC:mac_addr | Body | String | MAC address of the port attached to the instance |
| server.addresses."Network name".version | Body | Integer | IP version of the port attached to the instance<br>NHN Cloud supports only IPv4 |
| server.addresses."Network name".addr | Body | String | IP address of the port attached to the instance |
| server.addresses."Network name".OS-EXT-IPS:type | Body | Enum | IP address type of the port<br>Either `fixed` or `floating` |
| server.links | Body | Object | Instance path object |
| server.key_name | Body | String | Instance keypair name |
| server.image | Body | Object | Instance image object |
| server.image.id | Body | UUID | Instance image ID |
| server.image.links | Body | Object | Instance image path object |
| server.OS-EXT-STS:task_state | Body | String | Instance task state<br>Shows the status of a task operating on an instance |
| server.OS-EXT-STS:vm_state | Body | String | Current state of the instance |
| server.OS-SRV-USG:launched_at | Body | Datetime | Last boot time of the instance<br>`YYYY-MM-DDThh:mm:ss.ssssss` format |
| server.OS-SRV-USG:terminated_at | Body | Datetime | Instance deletion time<br>`YYYY-MM-DDThh:mm:ssZ` format |
| server.flavor | Body | Object | Instance type information object |
| server.flavor.id | Body | UUID | Instance type ID |
| server.flavor.links | Body | Object | Instance type path object |
| server.security_groups | Body | Object | List object of security groups assigned to the instance |
| server.security_groups.name | Body | String | Name of security group assigned to the instance |
| server.user_id | Body | String | User ID who created the instance |
| server.created | Body | Datetime | Instance created time in `YYYY-MM-DDThh:mm:ssZ` format |
| server.tenant_id | Body | String | Tenant ID to which the instance belongs |
| server.os-extended-volumes:volumes_attached | Body | Object | List object of additional block storage attached to the instance |
| server.os-extended-volumes:volumes_attached.id | Body | UUID | ID of additional block storage attached to the instance |
| server.OS-EXT-STS:power_state | Body | Integer | Power state of the instance<br>- `1`: On<br>- `4`: Off |
| server.metadata | Body | Object | Instance metadata object<br>Stores instance metadata as key-value pairs |
| server.NHN-EXT-ATTR:ephemeral_disk_size | Body | Integer | Size of an additional local block storage attached to the instance |
| server.NHN-EXT-ATTR:protect | Body | Boolean | Whether to enable instance deletion protection |

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