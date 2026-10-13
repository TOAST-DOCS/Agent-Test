<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Collection of Macro Tag Shapes { #sample-macro-shapes }

This document is a fixture for verifying that mkdocs-macros template tags remain unchanged through translation. Template shapes collected from an incident on 2026-09-07 when a line of tags in `ja/acl-guide.md` of Storage-Object-Storage was lost, breaking the alpha build. Tags are control syntax and are not translation targets; if even one is lost, the pair becomes misaligned and the entire build fails with `_Macro Syntax Error_`. (Body modification test: this sentence should be reflected when translation is re-executed.)

<a id="wrapped-paragraph"></a>
### Conditional Wrapping a Paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly from the Console. This paragraph has an opening tag attached right above it, so it becomes a single unit with the tag in incremental translation. This is exactly the shape where the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional Inside a Single Line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has the opening tag and closing tag on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional Wrapping an Example Block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below contains both `<details>` and a code fence inside a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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
### Variable Substitution Inside a Table { #variable-table }

| Category | Address | Notes |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Branching Both Ways { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must inquire about the issuance procedure from the administrator.
{% else %}
In the public environment, you can issue it directly from the Console.
{% endif %}