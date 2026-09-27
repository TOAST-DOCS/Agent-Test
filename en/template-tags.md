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
{# The above macro creates common rows in the response table — comments are not rendered #}

<a id="sample-template-tags"></a>
## Sample > Template tag samples { #sample-template-tags }

This document is a test fixture to verify that mkdocs-macros template tags build after translation and that **Korean strings** embedded by the author in tags are translated. The tags in the `$[ product_name ]$` document are taken directly from actual user guides (Private-DNS, Storage-Object-Storage, Storage-Online-NAS, nhn-cloud-foundry).

<a id="tt-set-literal"></a>
### String literals in variables { #tt-set-literal }

The `set` blocks at the top of the document assign different values to variables depending on the build environment. The regions covered by this guide are $[ region_names ]$, and the API host is `$[ api_host ]$`.

| Classification | Value | Note |
|---|---|---|
| Region | $[ region_names ]$ | Varies by environment |
| API host | `$[ api_host ]$` | Variable name with underscores |
| Query start time | {{executionTime}} | Placeholder substituted by workflow engine |

<a id="tt-inline-literal"></a>
### Conditional strings in sentences { #tt-inline-literal }

You can view the $[ "basic and encryption information" if encrypt else "basic information" ]$ of the container and change access policies and static website settings. Changes take effect immediately.

!!! note "Note"
    You cannot change a general container to an object lock container and vice versa.

    You cannot specify an object lock container as an archive container$[ " or replication target container" if replication else "" ]$. This restriction cannot be lifted.

<a id="tt-macro-arg"></a>
### Korean strings passed as macro arguments { #tt-macro-arg }

The rows in the table below are created by a macro. The second argument is a prefix added before the description.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('interface.', 'Created ') ]$
| interface.subnetId | Body | String | Subnet ID of the interface |

When called without a prefix, the description appears as-is.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### UI placeholders that look like tags { #tt-ui-placeholder }

| Item | Required | Description |
|---|---|---|
| User prompt template | — | A template for configuring input values per row. The {{ column name }} pattern is substituted with the corresponding column value, and if set, takes priority over the joining delimiter. Column names are case-sensitive. |
| Joining delimiter | — | A string to insert between multiple columns when combining them into one input. |

<a id="tt-wrapped"></a>
### Conditional wrapping paragraphs { #tt-wrapped }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly from the console. This paragraph has an opening tag right above it, so in incremental translation it becomes one unit with the tag. Settings take effect immediately upon saving.
{% endif %}

{% if "gov" in build_flags %}In the government network environment, you must inquire with your administrator about the issuance procedure.{% else %}In the public environment, you can issue it directly from the console.{% endif %}

<a id="tt-fenced"></a>
### Tags inside code blocks { #tt-fenced }

mkdocs-macros processes tags inside code blocks as Jinja, so to **show tags as examples**, you must wrap them with `{% raw %}`. If you don't wrap them, conditional statements are evaluated and variables are substituted, causing the example to disappear.

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "Korea (Pangyo) region" -%}
{% endif %}
$[ region_names ]$ / {{ column name }} / $[ api_host ]$
```
{% endraw %}

The block below is a control group without Korean text. It should be identical byte-for-byte even after translation.

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### Final section { #tt-tail }

This section is a control group that remains unchanged. After incremental translation, en/ja should be identical byte-for-byte.