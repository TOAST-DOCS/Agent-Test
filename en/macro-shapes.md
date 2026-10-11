<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Shape Collection { #sample-macro-shapes }

This document is a fixture to verify that mkdocs-macros template tags remain unchanged even after translation. It collects template tag shapes from the incident where `ja/acl-guide.md` in Storage-Object-Storage lost a tag line and broke the alpha build (September 7, 2026). Tags are control syntax and are not translation targets. If even one is lost, the pair will be misaligned and the entire build will fail with `_Macro Syntax Error_`. (Content modification test: this sentence should be reflected when translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional Wrapping a Paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly from the Console. This paragraph has the opening tag attached right above it, so in incremental translation it becomes one unit with the tag. This is exactly the pattern of the incident that occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional Within a Line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has the opening tag and closing tag on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional Wrapping an Example Block { #wrapped-example }

{% if "gov" not in build_flags %}
The following example contains both `<details>` and a code fence within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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

| Item | Address | Notes |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies by environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Branching Both Ways { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must inquire with the administrator about the issuance procedure.
{% else %}
In the public environment, you can directly issue from the Console.
{% endif %}