<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Collection of macro tag shapes { #sample-macro-shapes }

This document is a fixture to verify that mkdocs-macros template tags do not change even after translation. The patterns shown here were collected from an incident on 2026-09-07 where Storage-Object-Storage's `ja/acl-guide.md` lost a line of tags and broke the alpha build. Tags are control syntax and are not translation targets. If even one is lost, the pairing becomes misaligned and the entire build fails with a `_Macro Syntax Error_`. (Prose edit test: This sentence must be reflected when translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional wrapping a paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly from the console. This paragraph has the opening tag directly above it, so in incremental translation it becomes a single unit with the tag. This pattern is exactly what caused the incident.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional within a line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has the opening and closing tags on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional wrapping an example block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below has both `<details>` and code fences within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

<details>
<summary>Token issuance request example</summary>

```
$ curl -X POST \
  -H 'Content-Type: application/json' \
  $[ portal_url ]$/v2/tokens
```
</details>

{% endif %}
<a id="variable-table"></a>
### Variable substitution in a table { #variable-table }

| Category | Address | Notes |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies by environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Both-way branching { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must inquire about the issuance procedure from the administrator.
{% else %}
In the public environment, you can issue directly from the console.
{% endif %}