<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Shape Collection { #sample-macro-shapes }

This document is a fixture designed to verify that mkdocs-macros template tags remain unchanged even after translation. It collects the patterns that emerged from the incident (September 7, 2026) where a line of tags was lost in `ja/acl-guide.md` of Storage-Object-Storage, breaking the alpha build. Tags are control syntax and are not translation targets. If even one is lost, the pairing becomes misaligned, causing the entire build to fail with `_Macro Syntax Error_`. (Body modification test: This sentence must be reflected when the translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional Block Wrapping a Paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly in the console. This paragraph has the opening tag attached directly above, so it becomes a single unit with the tag in incremental translation. This is exactly the pattern where the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional Within a Single Line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and in this sentence, the opening and closing tags are on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional Block Wrapping an Example Block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below contains both `<details>` and a code fence within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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

| Item | Address | Remarks |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Two-Way Branching { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must contact the administrator to inquire about the issuance procedure.
{% else %}
In the public environment, you can issue it directly from the console.
{% endif %}