<!-- pre-align:aligned sig=e2epostmaint1 -->

<a id="pm-intro"></a>
## Translation PR Maintenance Sample { #pm-intro }

This document is a fixture for verifying translation PR maintenance (`--post-maint`).
The ko PR changes only one sentence in this paragraph.

<a id="pm-markup"></a>
## Markup Defect { #pm-markup }

For more information, see the [API guide\](https://docs.example.com/api/).

<a id="pm-stub"></a>
## Section With an Empty Body { #pm-stub }

<!-- TODO: translate body -->

<a id="pm-table"></a>
## Table With a Duplicated Header { #pm-table }

| Value | Type | Description |
|---|---|---|
| Name | Type | Description |
|---|---|---|
| appKey | String | App key |
| secretKey | String | Secret key |
| region | String | Region code |

<a id="pm-jinja"></a>
## Template Tags { #pm-jinja }

{% if "gov" in build_flags %}
In the government environment, the console menu names are different.

<a id="pm-tail"></a>
## Last Section { #pm-tail }

This section must be preserved byte-for-byte by every maintenance step.
