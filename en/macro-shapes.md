<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Shapes { #sample-macro-shapes }

This document is a fixture for verifying that mkdocs-macros template tags remain unchanged through translation. Patterns from an incident (2026-09-07) where Storage-Object-Storage's `ja/acl-guide.md` lost a line of tags and broke the alpha build are collected here. Since tags are control syntax, they are not subject to translation. If even one is lost, the pair becomes misaligned and the entire build fails with `_Macro Syntax Error_`. (Body modification test: This sentence must be reflected when translation is re-run.)

<a id="wrapped-paragraph"></a>
### Paragraph-Wrapped Conditional { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly in the Console. The opening tag is attached directly above, so in incremental translation this paragraph becomes a single unit with the tag. This is exactly the pattern where the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Inline Conditional { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and in this sentence the opening tag and closing tag are on the same line.{% endif %}

<a id="wrapped-example"></a>
### Example Block-Wrapped Conditional { #wrapped-example }

{% if "gov" not in build_flags %}
The example below is within a conditional block with both `<details>` and code fence included. This is a case where tag protection and fence protection overlap in the same unit.

<details>
<summary>Token Issuance Request Example</summary>

```
$ curl -X POST \
  -H 'Content-Type: application/json' \
  $[ portal_url ]$/v2/tokens
```
</details>

{% endif %}
<a id="variable-table"></a>
### Variable Substitution in Table { #variable-table }

| Category | Address | Notes |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on environment<br>Variables are also substituted within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Both Branches { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must contact the administrator for the issuance procedure.
{% else %}
In the public environment, you can issue it directly from the Console.
{% endif %}
