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
{# The macro above builds the common rows of a response table — comments are not rendered #}

<a id="sample-template-tags"></a>
## Sample > Template Tag Shapes { #sample-template-tags }

This document is a fixture for verifying that mkdocs-macros template tags still build after translation and that the **Korean strings** an author put inside a tag are translated. The tags in the `$[ product_name ]$` document are taken verbatim from real user guides (Private-DNS, Storage-Object-Storage, Storage-Online-NAS, nhn-cloud-foundry).

<a id="tt-set-literal"></a>
### Korean Strings Held in Variables { #tt-set-literal }

The `set` block at the top of the document assigns a different value to each variable per build environment. The regions this guide covers are $[ region_names ]$, and the API host is `$[ api_host ]$`.

| Item | Value | Note |
|---|---|---|
| Region | $[ region_names ]$ | Differs per environment |
| API host | `$[ api_host ]$` | A variable name with an underscore |
| Query start time | {{executionTime}} | A placeholder substituted by the workflow engine |

<a id="tt-inline-literal"></a>
### Conditional Strings Inside a Sentence { #tt-inline-literal }

You can view the container's $[ "basic and encryption information" if encrypt else "basic information" ]$ and change settings for access policies and static websites. Changes take effect immediately.

!!! note "Note"
    You cannot change a general container to an object lock container.

    An object lock container cannot be designated$[ " or a replication target container" if replication else "" ]$ as an archive container. This restriction cannot be lifted.

<a id="tt-macro-arg"></a>
### Korean Strings Passed as Macro Arguments { #tt-macro-arg }

The rows of the table below are produced by a macro. The second argument is a prefix attached to the description.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('interface.', 'Newly created ') ]$
| interface.subnetId | Body | String | The subnet ID of the interface |

Called without a prefix, the description appears as is.

| Name | Type | Format | Description |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### UI Placeholders That Look Like Tags { #tt-ui-placeholder }

| Item | Required | Description |
|---|---|---|
| User prompt template | X | Template for configuring per-row input values. The {{ column name }} pattern is replaced with the corresponding column value. When set, this takes precedence over the join separator. Column names are case-sensitive. |
| Join delimiter | X | The string inserted between columns when several columns are merged into one input. |

<a id="tt-wrapped"></a>
### Conditionals Wrapping a Paragraph { #tt-wrapped }

{% if "gov" not in build_flags %}
In a public environment, you can configure this directly from the console. This paragraph is attached immediately after the opening tag, making it a single unit with the tag in incremental translation. Settings are applied as soon as they are saved.
{% endif %}

{% if "gov" in build_flags %}In the government environment, ask your contact person about the issuance procedure.{% else %}In the public environment you can issue it directly in the console.{% endif %}

<a id="tt-fenced"></a>
### Tags Inside a Code Block { #tt-fenced }

mkdocs-macros processes tags inside a code block as Jinja too, so a tag shown **as an example** must be wrapped in `{% raw %}`. Without the wrapper the conditional is evaluated and the variables are substituted, and the example disappears.

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "Korea (Pangyo) Region" -%}
{% endif %}
$[ region_names ]$ / {{ column name }} / $[ api_host ]$
```
{% endraw %}

The block below is a control with no Korean in it. It must stay byte-identical through translation.

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### Last Section { #tt-tail }

This section is a control that never changes. After an incremental translation, en/ja must still be byte-identical here.
