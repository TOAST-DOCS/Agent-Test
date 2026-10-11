<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro tag shape examples { #sample-macro-shapes }

This document is a fixture to verify that mkdocs-macros template tags survive translation unchanged. The shapes included here came from an incident (2026-09-07) where `ja/acl-guide.md` in Storage-Object-Storage lost one line of tags and broke the alpha build. Tags are control syntax and not translation targets; if even one is lost, the pairing becomes misaligned and the entire build fails with `_Macro Syntax Error_`. (Body edit test: this sentence should be reflected when translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional wrapping a paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In public environments, you can configure directly from the console. This paragraph has an opening tag immediately above it, making it a single unit with the tag during incremental translation. This is the exact shape where the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional within a single line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and this sentence has both opening and closing tags on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional wrapping an example block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below contains both `<details>` and a code fence within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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
| Console | `$[ portal_url ]$` | Varies by environment<br>Substitution occurs within table rows as well |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Branching both ways { #branch-both-ways }

{% if "gov" in build_flags %}
In government network environments, you must inquire about the issuance procedure with the administrator.
{% else %}
In public environments, you can issue directly from the console.
{% endif %}