<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Pattern Collection { #sample-macro-shapes }

This document is a fixture for verifying that mkdocs-macros template tags remain unchanged through translation. The patterns collected here are from an incident on September 7, 2026, when `ja/acl-guide.md` in Storage-Object-Storage lost one tag line and broke the alpha build. Tags are control syntax and are not translation targets; if even one is lost, the pairing becomes misaligned and the entire build fails with `_Macro Syntax Error_`. (Body update test: This sentence should be reflected when translation is rerun.)

<a id="wrapped-paragraph"></a>
### Conditional wrapping a paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly from the Console. This paragraph has an opening tag attached directly above it, making it a single unit with the tag in incremental translation. This is exactly the pattern in which the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Inline conditional { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has opening and closing tags on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional wrapping an example block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below contains both `<details>` and code fence within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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

| Category | Address | Remarks |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Two-way branching { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must inquire about the issuance process with the administrator.
{% else %}
In the public environment, you can issue directly from the Console.
{% endif %}
