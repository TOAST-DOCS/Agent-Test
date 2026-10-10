<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > Macro tag shapes { #sample-macro-shapes }

This document is a fixture to verify that mkdocs-macros template tags remain unchanged even after translation. This collection of shapes comes from an incident (2026-09-07) where Storage-Object-Storage's `ja/acl-guide.md` lost one line of tags and broke the alpha build. Tags are control syntax and are not subject to translation; if even one is lost, the pairing becomes misaligned and the entire build fails with `_Macro Syntax Error_`. (Content modification test: this sentence should be reflected when the translation is re-run.)

<a id="wrapped-paragraph"></a>
### Conditional wrapping a paragraph { #wrapped-paragraph }

{% if "gov" not in build_flags %}
In the public environment, you can configure it directly in the Console. This paragraph has the opening tag attached right above it, so in incremental translation, the tag and paragraph form one unit. This is exactly the pattern where the incident occurred.
{% endif %}
<br>

<a id="inline-condition"></a>
### Conditional within a single line { #inline-condition }

{% if "gov" not in build_flags %}The portal address is `$[ portal_url ]$`, and in this sentence, the opening and closing tags are on the same line.{% endif %}

<a id="wrapped-example"></a>
### Conditional wrapping an example block { #wrapped-example }

{% if "gov" not in build_flags %}
The example below contains both a `<details>` element and a code fence within a conditional block. This is a case where tag protection and fence protection overlap in the same unit.

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

| Type | Address | Note |
|---|---|---|
| Console | `$[ portal_url ]$` | Varies depending on the environment<br>Substitution also occurs within table rows |
| API | `$[ portal_url ]$/v2` | Version path is appended |

<a id="branch-both-ways"></a>
### Branching both ways { #branch-both-ways }

{% if "gov" in build_flags %}
You must inquire about the token issuance procedure from the administrator.
{% else %}
In the public environment, you can directly issue tokens from the Console.
{% endif %}