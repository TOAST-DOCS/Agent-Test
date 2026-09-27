<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Examples { #sample-macro-shapes }

This document is a fixture to verify that mkdocs-macros template tags remain unchanged even after translation. These tag patterns resulted from an incident (2026-09-07) where Storage-Object-Storage's `ja/acl-guide.md` lost a line of tags and broke the alpha build; we have collected them in one place. Tags are control syntax and should not be translated. If even one is lost, the pairing becomes broken and the entire build fails with `_Macro Syntax Error_`. (Body edit test: This sentence should be reflected when the translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional wrapping a paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can set it up directly on the console. This paragraph has the opening tag attached right above it, making it one unit with the tag in incremental translation. The exact pattern that caused the incident is this one.
{% endif %}
<br>

<a id="inline-condition"></a>
### Inline conditional { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has the opening tag and closing tag on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional wrapping an example block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below contains `<details>` and code fences together within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

<details>
<summary>Token generation request example</summary>

```
$ curl -X POST \
  -H 'Content-Type: application/json' \
  $[ portal_url ]$/v2/tokens
```
</details>

{% endif %}
<a id="variable-table"></a>
### Variable substitution in tables { #variable-table }

| Category | Address | Notes |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies by environment<br>Variable substitution also works within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Two-way branching { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must contact the person in charge to inquire about the issuance process.
{% else %}
In the public environment, you can generate it directly on the console.
{% endif %}