<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Patterns { #sample-macro-shapes }

This document is a fixture to verify that mkdocs-macros template tags remain unchanged even after translation. The patterns collected here come from an incident on 2026-09-07 where Storage-Object-Storage's `ja/acl-guide.md` lost one line of a tag and broke the alpha build. Tags are control syntax, not translation targets, and if even one is lost, the pair becomes mismatched, causing the entire build to fail with `_Macro Syntax Error_`. (Body modification test: this sentence must be reflected when translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional Block Wrapping a Paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can set it up directly in the console. This paragraph has the opening tag immediately above it, so it becomes one unit with the tag in incremental translation. This is exactly the pattern where the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Inline Conditional { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has the opening tag and closing tag on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional Block Wrapping an Example Block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below has `<details>` and a code fence together inside the conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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
### Variable Substitution in a Table { #variable-table }

| Category | Address | Remarks |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Two-way Branching { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must contact the person in charge regarding the issuance procedure.
{% else %}
In the public environment, you can issue it directly from the console.
{% endif %}