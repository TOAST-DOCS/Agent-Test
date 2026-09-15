<!-- machine_translated: true -->

<!-- pre-align:aligned sig=cdbc88f0a12c -->

{%- set api_host = "api-jinja.gov-nhncloudservice.com" if "gov" in build_flags else "api-jinja.nhncloudservice.com" -%}
<a id="sample-jinja-guide"></a>
## Sample > Jinja Guide { #sample-jinja-guide }

{%- if "gov" not in build_flags %}
This document is a fixture for verifying that mkdocs-macros Jinja conditional branching and variable substitution remain identical across ko/en/ja. Tags are control syntax and are not translated; only the body text differs by language.
{%- endif %}

<a id="endpoint"></a>
### Endpoint { #endpoint }

{% if "gov" in build_flags -%}
In the gov environment, use a dedicated endpoint. You can't access it via public domains. (Content modification within tag block: This text should be reflected on re-translation.)
{% else -%}
In the public environment, use the default endpoint. See the table below for region-specific hosts.
{% endif %}

The API host is `$[ api_host ]$`.

| Region | Host | Note |
|---|---|---|
| Korea (Pangyo) | kr1-$[ api_host ]$ | Default region<br>Always available |
| Korea (Pyeongchon) | kr2-$[ api_host ]$ | Redundant configuration |

<a id="auth"></a>
### Authentication { #auth }

{% if "ngsc" in build_flags -%}
The NGSC environment follows a separate authentication procedure. Contact your representative for the issuance process.
{% else -%}
Issue a token and include it in the request header. Tokens have an expiration time.
{% endif %}

<a id="reference"></a>
### References { #reference }

- [Preparing to use the API](/nhncloud/en/public-api/)
