<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0877fab4a34e -->

{% if "gov" in build_flags -%}
  {%- set api_host      = "api-tt.gov-nhncloudservice.com" -%}
  {%- set region_names  = "Korea (Pangyo) region" -%}
  {%- set encrypt       = false -%}
{%- elif "ngsc" in build_flags -%}
  {%- set api_host      = "api-tt.ngsc.go.kr" -%}
  {%- set region_names  = "Korea (Daegu) region" -%}
  {%- set encrypt       = false -%}
{%- else -%}
  {%- set api_host      = "api-tt.nhncloudservice.com" -%}
  {%- set region_names  = "Korea (Pangyo) region<br>Korea (Pyeongchon) region<br>Korea (Gwangju) region<br>Korea (Busan) region" -%}
  {%- set encrypt       = true -%}
{%- endif -%}
{%- set replication = "gov" not in build_flags -%}
{%- set product_name = "Template tag sample" -%}

{% macro tt_response_table(prefix='', desc_prefix='') -%}
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$Interface ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$Interface path |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$Interface status |{% endmacro %}
{# The macro above creates common rows for the response table — this comment is not rendered #}

<a id="sample-template-tags"></a>
## Sample > Template tag showcase { #sample-template-tags }

This document is a fixture for verifying that mkdocs-macros template tags still build after translation and that **Korean strings** placed inside the tags by the author are translated. The tags in the `$[ product_name ]$` document use patterns taken directly from actual user guides (Private-DNS, Storage-Object-Storage, Storage-Online-NAS, nhn-cloud-foundry).

<a id="tt-set-literal"></a>
### Korean strings in variables { #tt-set-literal }

The `set` block at the top of the document assigns different values to variables depending on the build environment. The region covered by this guide is $[ region_names ]$, and the API host is `$[ api_host ]$`.

| Category | Value | Notes |
|---|---|---|
| Region | $[ region_names ]$ | Varies by environment |
| API host | `$[ api_host ]$` | This is a variable name that contains an underscore |
| Query start time | {{executionTime}} | This is a placeholder replaced by the workflow engine |

<a id="tt-inline-literal"></a>
### Conditional strings within a sentence { #tt-inline-literal }

You can check the $[ "basic information and encryption information" if encrypt else "basic information" ]$ of the container, and change the access policy and static website settings. Changes take effect immediately.

!!! note "Note"
    You cannot change a general container to an object lock container.

    You cannot specify an object lock container as an archive container$[ " or a replication target container" if replication else "" ]$. This restriction cannot be lifted.

<a id="tt-macro-arg"></a>
### Korean strings passed as macro arguments { #tt-macro-arg }

The rows in the table below are created by the macro. The second argument is a prefix added before the description.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('interface.', 'Newly created ') ]$
| interface.subnetId | Body | String | Subnet ID of the interface |

If called without a prefix, the description appears as-is.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### UI placeholders that look like tags { #tt-ui-placeholder }

| Item | Required | Description |
|---|---|---|
| User prompt template | X | A template for configuring input values per row. The {{ column name }} pattern is replaced with the corresponding column value, and if configured, it takes precedence over the join delimiter. Column names are case-sensitive. |
| Join delimiter | X | A string inserted between multiple columns when combining them into a single input. |

<a id="tt-wrapped"></a>
### Conditional wrapping a paragraph { #tt-wrapped }

{% if "gov" not in build_flags %}
In the public environment, you can configure this directly from the console. This paragraph is immediately below the opening tag, making it one unit with the tag in incremental translation. Settings take effect as soon as they are saved.
{% endif %}

{% if "gov" in build_flags %}In the government network environment, you must contact the person in charge to inquire about the issuance procedure.{% else %}In the public environment, you can issue directly from the console.{% endif %}

<a id="tt-fenced"></a>
### Tags inside a code block { #tt-fenced }

Because mkdocs-macros also processes tags inside code blocks as Jinja, you must wrap them in `{% raw %}` **to show them as examples**. If you do not wrap them, the conditional is evaluated and the variable is substituted, causing the example to disappear.

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

This section is an unchanged control group. The en/ja files must be byte-identical even after incremental translation.