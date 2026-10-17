<a id="jinja-repair-sample"></a>
## Jinja Repair Sample { #jinja-repair-sample }

This document is a fixture for the Jinja syntax repair e2e. It is kept healthy here; the e2e plants defects on a session branch.

<a id="jinja-repair-closer"></a>
### Gov-only Table { #jinja-repair-closer }

This description applies to every environment.

{% if "gov" in build_flags %}
These endpoints are provided only in the public institution environment.

| Region | Endpoint |
|---|---|
| Korea (Pangyo) Region | https://kr1-api.gov-nhncloudservice.com |
{% endif %}

<a id="jinja-repair-opener"></a>
### Notes by Environment { #jinja-repair-opener }

The following note differs by environment.

!!! tip "Note"
    In the general environment, you can apply directly in the console.
{% else %}
!!! tip "Note"
    In the public institution environment, you can use it after approval by the person in charge.
{% endif %}

It takes effect within 10 minutes after you apply.

<a id="jinja-repair-author"></a>
### Upcoming Features { #jinja-repair-author }

The currently provided features are as follows.

- Create instances
- Delete instances

{% if release_2026_11 %}
!!! note "Note"
    The feature scheduled for November 2026 is scheduled snapshots.
{% endif %}

The release schedule may change depending on circumstances.

<a id="jinja-repair-typo"></a>
### Region List { #jinja-repair-typo }

{% if "ncgn" in build_flags %}
- Korea (Daegu) Region
{% endif %}
- Korea (Pangyo) Region
- Korea (Pyeongchon) Region
