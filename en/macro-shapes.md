<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Patterns { #sample-macro-shapes }

This document is a fixture to validate that mkdocs-macros template tags remain unchanged through translation. Patterns from an incident (September 7, 2026) where a line of tags was lost in Storage-Object-Storage's `ja/acl-guide.md`, breaking the alpha build, are collected in one place. Tags are control syntax and are not subject to translation; if even one is lost, the pair becomes misaligned and the entire build fails with `_Macro Syntax Error_`. (Body modification test: This sentence should be reflected when the translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional Wrapping a Paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In a public environment, you can configure it directly from the Console. This paragraph has the opening tag attached directly above it, making it a single unit with the tag in incremental translation. This is exactly the pattern where the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional Within a Line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has the opening tag and closing tag on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional Wrapping an Example Block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below contains `<details>` and a code fence together within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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
### Variable Substitution in Tables { #variable-table }

| Classification | Address | Notes |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is added |

<a id="branch-both-ways"></a>
### Both Branches { #branch-both-ways }

{% if "gov" in build_flags %}
In a government network environment, you must contact the responsible person about the issuance procedure.
{% else %}
In a public environment, you can issue it directly from the Console.
{% endif %}
