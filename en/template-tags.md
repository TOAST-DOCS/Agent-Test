<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0877fab4a34e -->

{% if "gov" in build_flags -%}
  {%- set api_host      = "api-tt.gov-nhncloudservice.com" -%}
  {%- set region_names = "Korea (Pangyo) Region" -%}
  {%- set encrypt       = false -%}
{%- elif "ngsc" in build_flags -%}
  {%- set api_host      = "api-tt.ngsc.go.kr" -%}
  {%- set region_names = "Korea (Daegu) Region" -%}
  {%- set encrypt       = false -%}
{%- else -%}
  {%- set api_host      = "api-tt.nhncloudservice.com" -%}
  {%- set region_names = "Korea (Pangyo) Region<br>Korea (Pyeongchon) Region<br>Korea (Gwangju) Region<br>Korea (Busan) Region" -%}
  {%- set encrypt       = true -%}
{%- endif -%}
{%- set replication = "gov" not in build_flags -%}
{%- set product_name = "Template Tag Sample" -%}

{% macro tt_response_table(prefix='', desc_prefix='') -%}
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$Interface ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$Interface path |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$Interface status |{% endmacro %}
{# The above macro creates common rows of the response table — comments are not rendered #}

<a id="sample-template-tags"></a>
## Sample > Template Tag Shape Collection { #sample-template-tags }

This document is a fixture to verify that mkdocs-macros template tags are built after translation, and that **Korean character strings** inserted by the author inside tags are translated. The tags in the `$[ product_name ]$` document are taken directly from actual user guides (Private-DNS, Storage-Object-Storage, Storage-Online-NAS, nhn-cloud-foundry).

<a id="tt-set-literal"></a>
### Korean character strings in variables { #tt-set-literal }

The `set` block at the top of the document stores different values in variables depending on the build environment. The region covered in this guide is $[ region_names ]$, and the API host is `$[ api_host ]$`.

| Item | Value | Note |
|---|---|---|
| Region | $[ region_names ]$ | Varies by environment |
| API host | `$[ api_host ]$` | Variable name with underscores |
| Query start time | {{executionTime}} | Placeholder substituted by the workflow engine |

<a id="tt-inline-literal"></a>
### Conditional strings in sentences { #tt-inline-literal }

You can check the $[ "basic and encryption information" if encrypt else "basic information" ]$ of the container and change access policies and static website settings. Changes are applied immediately.

!!! note "Note"
    You cannot change a general container to an object lock container.

    An object lock container cannot be specified as an archive container$[ " or a replication target container" if replication else "" ]$. This restriction cannot be removed.

<a id="tt-macro-arg"></a>
### Korean character strings passed as macro arguments { #tt-macro-arg }

The rows in the table below are created by macros. The second argument is a prefix attached before the description.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('interface.', 'Created ') ]$
| interface.subnetId | Body | String | Subnet ID of the interface |

If called without a prefix, the description appears as is.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### UI placeholder that looks like a tag { #tt-ui-placeholder }

| Item | Required | Description |
|---|---|---|
| User prompt template | X | Template for input value composition by row. The {{ column name }} pattern is substituted with the value of the corresponding column, and when set, it takes priority over the concatenation delimiter. Column names are case-sensitive. |
| Concatenation delimiter | X | A character string to insert between multiple columns when combining them into a single input. |

<a id="tt-wrapped"></a>
### Conditional wrapping a paragraph { #tt-wrapped }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly in the console. This paragraph has the opening tag attached right above it, so it becomes one unit with the tag in incremental translation. The setting is applied immediately upon saving.
{% endif %}

{% if "gov" in build_flags %}In the government network environment, you must contact the administrator for the issuance procedure.{% else %}In the public environment, you can issue it directly from the console.{% endif %}

<a id="tt-fenced"></a>
### Tags inside code blocks { #tt-fenced }

mkdocs-macros processes tags inside code blocks with Jinja as well, so to **show tags as examples**, you must wrap them with `{% raw %}`. If you don't wrap them, the conditional is evaluated and variables are substituted, causing the example to disappear.

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "Korea (Pangyo) region" -%}
{% endif %}
$[ region_names ]$ / {{ column name }} / $[ api_host ]$
```
{% endraw %}

The block below is a control group with no Korean. It should be byte-identical even after translation.

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### Last section { #tt-tail }

This section is a control group that does not change. After incremental translation, en/ja should be byte-identical.