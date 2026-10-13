<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro Tag Shape Collection { #sample-macro-shapes }

This document is a fixture to verify that mkdocs-macros template tags remain unchanged through translation. The patterns shown here were collected from an incident on 2026-09-07 when Storage-Object-Storage's `ja/acl-guide.md` lost one line of tags and broke the alpha build. Tags are control syntax, not translation targets. If even one tag is lost, the tag pairs become mismatched and the entire build fails with `_Macro Syntax Error_`. (Content modification test: This sentence should be reflected when translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional Wrapping a Paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can set it directly from the console. This paragraph has an opening tag attached right above it, making it one unit with the tag in incremental translation. This is exactly the pattern that caused the incident.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional Within a Single Line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and in this sentence, the opening and closing tags are on the same line.{% endif %}

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

| Category | Address | Remarks |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | The version path is appended |

<a id="branch-both-ways"></a>
### Two-Way Branching { #branch-both-ways }

{% if "gov" in build_flags %}
In the government network environment, you must inquire about the issuance procedure from your administrator.
{% else %}
In the public environment, you can issue it directly from the console.
{% endif %}
