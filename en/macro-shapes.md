<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Patterns { #sample-macro-shapes }

This document is a fixture for verifying that mkdocs-macros template tags remain unchanged even after translation. The patterns collected here originated from an incident (2026-09-07) in which `ja/acl-guide.md` in Storage-Object-Storage lost a line of tags and broke the alpha build. Tags are control syntax and are not subject to translation. If even one tag is lost, the pair becomes mismatched and the entire build fails with `_Macro Syntax Error_`. (Body modification test: This sentence should be reflected when the translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional wrapping a paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly from the console. This paragraph has an opening tag immediately above it, making it a single unit with the tag in incremental translation. This is the exact pattern that caused the incident.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional within a single line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and the opening and closing tags are on the same line as the sentence.{% endif %}

<a id="wrapped-example"></a>
### Conditional wrapping an example block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below has `<details>` and code fence together within the conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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
### Variable substitution in a table { #variable-table }

| Category | Address | Remarks |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution also works within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Bidirectional branching { #branch-both-ways }

{% if "gov" in build_flags %}
In the government cloud environment, you must contact the administrator for the issuance procedure.
{% else %}
In the public environment, you can issue directly from the console.
{% endif %}