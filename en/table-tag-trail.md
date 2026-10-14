<!-- machine_translated: true -->

<!-- pre-align:aligned sig=6cb69b3e1d0e -->

<a id="ttt"></a>
# table-tag-trail e2e fixture

This document is a generated e2e fixture (20261014-120919).

<a id="ttt-reuse"></a>
## Sorting Parameters { #ttt-reuse }

| Name | Description |
| --- | --- |
| sort_dir | Sort direction |
{%- if "public" in build_flags %}
| member_status | Member status |
{% else %}
{% endif %}

Used to sort the list.

<a id="ttt-retx"></a>
## Paging Parameters { #ttt-retx }

| Name | Description |
| --- | --- |
| limit | Number of items to retrieve at once |
| offset | Start position of the query (from 0) |
{% if "gov" in build_flags %}
{% endif %}

Used to retrieve the list in pages.

<a id="ttt-append"></a>
## Filter Parameters { #ttt-append }

{%- if "public" in build_flags %}
| Name | Description |
| --- | --- |
| name | Name filter |
| status | Status filter |
| createdFrom | Created time starts |
| createdTo | Created time ends |
{% endif %}

Used to filter the list.

<a id="ttt-blank"></a>
## Search Parameters { #ttt-blank }

| Name | Description |
| --- | --- |
| keyword | Search keyword |
| scope | Search scope |

{% if "gov" in build_flags %}
In Government environments, the search scope is limited.
{% endif %}

Used to search the list.

<a id="ttt-plain"></a>
## Response Fields { #ttt-plain }

| Name | Description |
| --- | --- |
| totalCount | Total count matching the conditions |
| items | List of items |

Fields of the response body.
