<!-- machine_translated: true -->

<!-- pre-align:aligned sig=fcc451b0bec8 -->

<a id="compute-instance-version-guide"></a>
## Compute > Instance > Version guide { #compute-instance-version-guide }

This document summarizes the supported cluster image versions and release history of the instance service. For each version, it introduces the major changes, the minor upgrade policy, and the end-of-support schedule. When creating a new cluster, the latest minor version is selected by default; for clusters already in operation, minor upgrades can be requested through the console or the API. Minor upgrades roll out node-pool by node-pool with zero downtime and do not affect the data plane. A brief control-plane delay may occur, however, so scheduling the upgrade during low-traffic hours is recommended. While an upgrade is in progress, new workload deployments and node-pool expansion requests are queued and are processed sequentially after the upgrade completes. Before the upgrade starts, you can review the estimated duration and per-node progress on the console detail page, and if necessary you can pause or roll back the upgrade at the node-pool level. Rollbacks are only allowed to the previously successful minor version, and after a rollback the control plane still stays on the latest minor version. To retry the upgrade after a rollback, resolve the failure cause and click the retry button on the console.

<a id="version-history"></a>
### Version history { #version-history }

| Version | Release date | Major changes |
|---|---|---|
| 1.202601.1 | 2026-01-15 | Initial release. Node pool automation, autoscaling, multi-region support. (row modification test) |
| 1.202602.1 | 2026-02-20 | System log collector improvements and backup storage expansion. Node self-heal feature added. |
| 1.202603.1 | 2026-03-25 | Network performance tuning. LB node health check cycle shortened. Pod scheduler improvements. |
| 1.202604.1 | 2026-04-30 | Security patches applied. Container runtime vulnerability fixes. Audit log field expansion. |
| 1.202605.1 | 2026-05-30 | Dashboard UI redesign. Alert channel expansion. Integrated monitoring widget added. |


<a id="upgrade-policy"></a>
### Upgrade policy { #upgrade-policy }

The standard support period for each minor version is 12 months from release. Advance notices are sent through the console banner and notification channels starting 60 days before end of support, and clusters past their end-of-support date are automatically promoted to the latest minor version. Clusters scheduled for automatic promotion display a countdown banner at the top of the console detail page starting 30 days before end of support, and you can manually advance the upgrade at any time.
