<!-- machine_translated: true -->

<!-- pre-align:aligned sig=fcc451b0bec8 -->

<a id="compute-instance-version-guide"></a>
## Compute > Instance > Version guide { #compute-instance-version-guide }

This document outlines the cluster image versions and release history supported by the Instance service, along with the major changes introduced in each version, the minor version upgrade policy, and the end-of-support schedule. When you create a new cluster, the latest minor version is selected by default. Clusters already in operation can request a minor version upgrade through the console or API. Minor version upgrades are performed on a per-node-pool basis using zero-downtime rolling updates, and the data plane is not affected. However, because a brief delay in the control plane may occur, we recommend that you schedule the upgrade during low-traffic hours. While the upgrade is in progress, new workload deployments and node pool scaling requests are queued and processed sequentially after the upgrade completes. Before the upgrade starts, you can check the estimated duration and per-node progress on the console's details page. If needed, you can pause or roll back the upgrade at the node pool level. Rollback is possible only to the last successfully upgraded minor version, and even after rollback, the control plane maintains the latest minor version. To retry the upgrade after rollback, resolve the cause of the failure and then click the Retry button in the console. (Body modification test: This sentence must be reflected when the translation is re-run.)

<a id="version-history"></a>
### Version history { #version-history }

| Version | Release date | Key changes |
|---|---|---|
| 1.202601.1 | 2026-01-15 | Initial release. Node pool automation, autoscaling, and multi-region support. |
| 1.202602.1 | February 21, 2026 | Improved the System Log Collector and expanded backup storage. Added the Node self-heal feature. |
| 1.202603.1 | 2026-03-25 | Network performance tuning. LB node health-check interval reduced. Pod scheduler improved. |
| 1.202603.9 | March 28, 2026 | This is a newly inserted version. It must be translated. |
| 1.202604.1 | 2026-04-30 | Security patch. Container runtime vulnerability fixed. Audit log fields expanded. |
| 1.202605.1 | 2026-05-30 | Dashboard UI redesign. Notification channels expanded. Unified monitoring widget added. |

<a id="upgrade-policy"></a>
### Upgrade policy { #upgrade-policy }

The standard support period for each minor version is 12 months from release. Advance notices are sent through the console banner and notification channels starting 60 days before end of support, and clusters past their end-of-support date are automatically promoted to the latest minor version. Clusters scheduled for automatic promotion display a countdown banner at the top of the console detail page starting 30 days before end of support, and you can manually advance the upgrade at any time.
