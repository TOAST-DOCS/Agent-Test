<!-- machine_translated: true -->

<!-- pre-align:aligned sig=fcc451b0bec8 -->

<a id="compute-instance-version-guide"></a>
## Compute > Instance > Version guide { #compute-instance-version-guide }

This document summarizes the cluster image versions and release history supported by the Instance service. It covers the major changes introduced in each version, the minor version upgrade policy, and the support end schedule. When you create a new cluster, the latest minor version is selected by default. Existing clusters can request a minor version upgrade through the console or API. Minor version upgrades are performed on a node pool basis using a rolling update without downtime, and there is no impact on the data plane. However, a brief delay may occur on the control plane, so we recommend that you schedule the upgrade during low-traffic hours. During the upgrade, requests for new workload deployments and node pool expansion are queued and processed sequentially after the upgrade completes. Before the upgrade starts, you can check the estimated time required and the per-node progress status on the console's details page. If needed, you can pause or rollback the upgrade on a node pool basis. Rollback is possible only to the last successfully upgraded minor version, and the control plane maintains the latest minor version even after rollback. To retry the upgrade after rollback, resolve the failure cause and then click the retry button in the console. (Body modification test: this sentence should be reflected when the translation is rerun.)

<a id="version-history"></a>
### Version history { #version-history }

| Version | Release date | Key changes |
|---|---|---|
| 1.202601.1 | 2026-01-15 | Initial release. Node pool automation, autoscaling, and multi-region support. |
| 1.202602.1 | February 21, 2026 | Improved system log collector and expanded backup storage. Added node self-heal feature. |
| 1.202603.1 | 2026-03-25 | Network performance tuning. LB node health-check interval reduced. Pod scheduler improved. |
| 1.202603.9 | March 28, 2026 | A new version inserted in the middle. This must be translated. |
| 1.202604.1 | 2026-04-30 | Security patch. Container runtime vulnerability fixed. Audit log fields expanded. |
| 1.202605.1 | 2026-05-30 | Dashboard UI redesign. Notification channels expanded. Unified monitoring widget added. |

<a id="upgrade-policy"></a>
### Upgrade policy { #upgrade-policy }

The standard support period for each minor version is 12 months from release. Advance notices are sent through the console banner and notification channels starting 60 days before end of support, and clusters past their end-of-support date are automatically promoted to the latest minor version. Clusters scheduled for automatic promotion display a countdown banner at the top of the console detail page starting 30 days before end of support, and you can manually advance the upgrade at any time.
