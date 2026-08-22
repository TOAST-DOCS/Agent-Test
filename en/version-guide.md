<!-- machine_translated: true -->

<!-- pre-align:aligned sig=fcc451b0bec8 -->

<a id="compute-instance-version-guide"></a>
## Compute > Instance > Version guide { #compute-instance-version-guide }

Document describing the cluster image versions and release history supported by the Instance service. This document covers major changes introduced in each version, minor version upgrade policies, and support end schedules. When creating a new cluster, the latest minor version is selected by default, and existing clusters can request minor version upgrades through the console or API. Minor version upgrades proceed in a rolling manner without downtime at the node pool level, and the data plane is not affected. However, short latency may occur in the control plane, so we recommend scheduling upgrades during low traffic hours. During the upgrade, new workload deployments and node pool scaling requests are queued and processed sequentially after the upgrade completes. Before the upgrade begins, you can check the estimated duration and per-node progress on the detail page in the console. If necessary, you can pause or roll back the upgrade at the node pool level. You can roll back only to the last successful minor version, and the control plane remains at the latest minor version even after rollback. To retry the upgrade after a rollback, resolve the failure cause and then click the retry button in the console. (Text revision test: This sentence must be reflected when the translation is rerun.)

<a id="version-history"></a>
### Version history { #version-history }

| Version | Release date | Key changes |
|---|---|---|
| 1.202601.1 | 2026-01-15 | Initial release. Node pool automation, autoscaling, and multi-region support. |
| 1.202602.1 | 2026-02-21 | Improved system log collector and expanded backup storage. Added node self-healing feature. |
| 1.202603.1 | 2026-03-25 | Network performance tuning. LB node health-check interval reduced. Pod scheduler improved. |
| 1.202603.9 | 2026-03-28 | This is a new version inserted in the middle. It must be translated. |
| 1.202604.1 | 2026-04-30 | Security patch. Container runtime vulnerability fixed. Audit log fields expanded. |
| 1.202605.1 | 2026-05-30 | Dashboard UI redesign. Notification channels expanded. Unified monitoring widget added. |

<a id="upgrade-policy"></a>
### Upgrade policy { #upgrade-policy }

The standard support period for each minor version is 12 months from release. Advance notices are sent through the console banner and notification channels starting 60 days before end of support, and clusters past their end-of-support date are automatically promoted to the latest minor version. Clusters scheduled for automatic promotion display a countdown banner at the top of the console detail page starting 30 days before end of support, and you can manually advance the upgrade at any time.
