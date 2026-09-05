<!-- machine_translated: true -->

<!-- pre-align:aligned sig=fcc451b0bec8 -->

<a id="compute-instance-version-guide"></a>
## Compute > Instance > Version guide { #compute-instance-version-guide }

This document describes the cluster image versions and release history supported by the Instance service, including the major changes introduced in each version, the minor version upgrade policy, and the end-of-support schedule. When you create a new cluster, the latest minor version is selected by default. For clusters already in operation, you can request a minor version upgrade through the console or API. Minor version upgrades proceed on a per-node-pool basis using rolling updates without service interruption and do not affect the data plane. However, a brief delay in the control plane may occur, so we recommend that you schedule the upgrade during a time of low traffic. During the upgrade, new workload deployments and node pool expansion requests are queued and processed sequentially after the upgrade completes. Before the upgrade starts, you can check the estimated time required and the progress status for each node on the details page in the console. If necessary, you can pause or roll back the upgrade on a per-node-pool basis. Rollback is only possible to the last successfully applied minor version, and the control plane maintains the latest minor version even after rollback. To retry the upgrade after a rollback, resolve the cause of the failure and click the Retry button in the console. (Content update test: This sentence should be reflected when the translation is re-executed.)

<a id="version-history"></a>
### Version history { #version-history }

| Version | Release date | Key changes |
|---|---|---|
| 1.202601.1 | 2026-01-15 | Initial release. Node pool automation, autoscaling, and multi-region support. |
| 1.202602.1 | 2026-02-20 | Improved system log collector and expanded backup storage. Added node self-heal feature. |
| 1.202603.1 | 2026-03-25 | Network performance tuning. LB node health-check interval reduced. Pod scheduler improved. |
| 1.202604.1 | 2026-04-30 | Security patch. Container runtime vulnerability fixed. Audit log fields expanded. |
| 1.202605.1 | 2026-05-30 | Dashboard UI redesign. Notification channels expanded. Unified monitoring widget added. |

<a id="upgrade-policy"></a>
### Upgrade policy { #upgrade-policy }

The standard support period for each minor version is 12 months from release. Advance notices are sent through the console banner and notification channels starting 60 days before end of support, and clusters past their end-of-support date are automatically promoted to the latest minor version. Clusters scheduled for automatic promotion display a countdown banner at the top of the console detail page starting 30 days before end of support, and you can manually advance the upgrade at any time.
