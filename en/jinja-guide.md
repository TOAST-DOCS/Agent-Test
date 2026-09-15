<!-- pre-align:aligned sig=cdbc88f0a12c -->

{%- set api_host = "api-jinja.gov-nhncloudservice.com" if "gov" in build_flags else "api-jinja.nhncloudservice.com" -%}
<a id="sample-jinja-guide"></a>
## Sample > Jinja Guide { #sample-jinja-guide }

This document is a fixture for verifying that mkdocs-macros' Jinja conditionals and variable substitutions stay identical across ko/en/ja. The tags are control syntax, so they are never translated; only the body text differs per language.

<a id="endpoint"></a>
### Endpoint { #endpoint }

{% if "gov" in build_flags -%}
The government environment uses a dedicated endpoint. It cannot be reached over the public domain.
{% else -%}
The public environment uses the default endpoint. Refer to the table below for per-region hosts.
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
