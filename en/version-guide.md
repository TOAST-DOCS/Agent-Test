<!-- machine_translated: true -->

<!-- pre-align:aligned sig=fcc451b0bec8 -->

<a id="compute-instance-version-guide"></a>
## Compute > Instance > Version guide { #compute-instance-version-guide }

This document provides an overview of the cluster image versions supported by the Instance service and their release history. It introduces the key changes introduced in each version, the minor version upgrade policy, and the support end-of-life schedule. When you create a new cluster, the latest minor version is selected by default. For clusters already in operation, you can request a minor version upgrade through the console or API. Minor version upgrades are performed in a rolling manner at the node pool level without interruption, and the data plane is not affected. However, a brief delay may occur on the control plane, so we recommend that you schedule the upgrade during a time when traffic is low. During the upgrade, new workload deployments and node pool expansion requests are queued and processed sequentially after the upgrade is complete. Before the upgrade begins, you can check the estimated time required and the progress status for each node on the details page in the console. If necessary, you can pause or roll back the upgrade at the node pool level. You can roll back only to the last successfully completed minor version. After the rollback, the control plane maintains the latest minor version. To attempt an upgrade again after a rollback, resolve the cause of the failure and then click the retry button in the console. (Body modification test: this sentence should be reflected when translation is re-run.)

<a id="version-history"></a>
### Version history { #version-history }

| Version | Release date | Key changes |
|---|---|---|
| 1.202601.1 | 2026-01-15 | Initial release. Node pool automation, autoscaling, and multi-region support. |
| 1.202602.1 | February 21, 2026 | Improved the system log collector and expanded the backup storage. Added the node self-heal feature. |
| 1.202603.1 | 2026-03-25 | Network performance tuning. LB node health-check interval reduced. Pod scheduler improved. |
| 1.202603.9 | March 28, 2026 | This is a newly inserted version. It should be translated. |
| 1.202604.1 | 2026-04-30 | Security patch. Container runtime vulnerability fixed. Audit log fields expanded. |
| 1.202605.1 | 2026-05-30 | Dashboard UI redesign. Notification channels expanded. Unified monitoring widget added. |

<a id="upgrade-policy"></a>
### Upgrade policy { #upgrade-policy }

The standard support period for each minor version is 12 months from release. Advance notices are sent through the console banner and notification channels starting 60 days before end of support, and clusters past their end-of-support date are automatically promoted to the latest minor version. Clusters scheduled for automatic promotion display a countdown banner at the top of the console detail page starting 30 days before end of support, and you can manually advance the upgrade at any time.
