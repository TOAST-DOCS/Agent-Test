<!-- pre-align:aligned sig=178a08dfcc40 -->

<a id="compute-instance-spec-guide"></a>
## Compute > Instance > Resource Specification Guide { #compute-instance-spec-guide }

This document describes the resource field specifications in instance API response bodies. Each field's path, type, Not Null status, and description are provided in tables.

<a id="resource-fields"></a>
### Resource fields { #resource-fields }

| Path | Type | Description |
| --- | --- | --- |
| resource.id | String | Resource ID. |
| resource.name | String | Resource name. You can change it in the console. |
| resource.status | Enum | Resource status.<br>[ACTIVE(in use), PAUSED(paused), DELETED(deleted)] |
| resource.quota | Object | Resource quota information. |
| resource.quota.limit | Integer | Maximum quota. The default is 100. |
| resource.quota.used | Integer | Current usage. |
| resource.labels | Array | List of labels attached to the resource. |

<a id="spec-change-policy"></a>
### Specification change policy { #spec-change-policy }

Adding fields is considered backward compatible and may be applied without notice. Field removal or type changes are announced at least 30 days in advance in the notices.
