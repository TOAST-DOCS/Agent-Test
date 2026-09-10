<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0877fab4a34e -->

{% if "gov" in build_flags -%}
  {%- set api_host      = "api-tt.gov-nhncloudservice.com" -%}
  {%- set region_names  = "Korea (Pangyo) Region" -%}
  {%- set encrypt       = false -%}
{%- elif "ngsc" in build_flags -%}
  {%- set api_host      = "api-tt.ngsc.go.kr" -%}
  {%- set region_names  = "Korea (Daegu) Region" -%}
  {%- set encrypt       = false -%}
{%- else -%}
  {%- set api_host      = "api-tt.nhncloudservice.com" -%}
  {%- set region_names  = "Korea (Pangyo) Region<br>Korea (Pyeongchon) Region<br>Korea (Gwangju) Region<br>Korea (Busan) Region" -%}
  {%- set encrypt       = true -%}
{%- endif -%}
{%- set replication = "gov" not in build_flags -%}
{%- set product_name = "Template Tag Sample" -%}

{% macro tt_response_table(prefix='', desc_prefix='') -%}
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$Interface ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$Interface path |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$Interface status |{% endmacro %}
{# The macro above creates common rows for the response table — comments are not rendered #}

<a id="sample-template-tags"></a>
## Sample > Template tag format collection { #sample-template-tags }

This document is a fixture for verifying that mkdocs-macros template tags build correctly after translation and that **Korean strings** written by the author inside the tags are translated. The tags in the `$[ product_name ]$` document are taken directly from actual user guides (Private-DNS, Storage-Object-Storage, Storage-Online-NAS, nhn-cloud-foundry).

<a id="tt-set-literal"></a>
### Korean strings in variables { #tt-set-literal }

The `set` block at the top of the document stores different values in variables depending on the build environment. The region covered by this guide is $[ region_names ]$, and the API host is `$[ api_host ]$`.

| Category | Value | Notes |
|---|---|---|
| Region | $[ region_names ]$ | Varies by environment |
| API host | `$[ api_host ]$` | Variable name that contains an underscore |
| Query start time | {{executionTime}} | Placeholder replaced by the workflow engine |

<a id="tt-inline-literal"></a>
### Conditional strings in sentences { #tt-inline-literal }

You can check the $[ "basic and encryption information" if encrypt else "basic information" ]$ of the container and change the access policy and static website settings. Changes take effect immediately.

!!! note "Note"
    You cannot change a general container to an object lock container.

    You cannot specify an object lock container as an archive container$[ " or as a replication target container" if replication else "" ]$. This restriction cannot be lifted.

<a id="tt-macro-arg"></a>
### Korean strings passed as macro arguments { #tt-macro-arg }

The rows in the table below are created by the macro. The second argument is a prefix that is prepended to the description.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('interface.', 'Newly created ') ]$
| interface.subnetId | Body | String | Subnet ID of the interface |

When called without a prefix, the description appears as-is.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### UI placeholders that look like tags { #tt-ui-placeholder }

| Item | Required | Description |
|---|---|---|
| User prompt template | X | Template for configuring input values per row. The {{ column name }} pattern is replaced with the corresponding column value. When set, it takes precedence over the combination separator. Column names are case-sensitive. |
| Combination separator | X | A string inserted between multiple columns when combining them into a single input. |

<a id="tt-wrapped"></a>
### Conditional wrapping a paragraph { #tt-wrapped }

{% if "gov" not in build_flags %}
In a public environment, you can configure settings directly in the console. This paragraph has an opening tag immediately above it, making it a single unit with the tag in incremental translation. Settings take effect as soon as they are saved.
{% endif %}

{% if "gov" in build_flags %}In a government network environment, you must contact the administrator to inquire about the issuance procedure.{% else %}In a public environment, you can obtain it directly in the console.{% endif %}

<a id="tt-fenced"></a>
### Tags inside code blocks { #tt-fenced }

Because mkdocs-macros processes tags inside code blocks with Jinja, you must wrap them in `{% raw %}` **to show them as examples**. If you do not wrap them, conditionals are evaluated and variables are substituted, causing the example to disappear.

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "Korea (Pangyo) region" -%}
{% endif %}
$[ region_names ]$ / {{ column name }} / $[ api_host ]$
```
{% endraw %}

The block below is a control group with no Korean text. It must be byte-identical even after translation.

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### Last section { #tt-tail }

This section is an unchanged control group. After incremental translation, en/ja must be byte-identical.