<!-- pre-align:aligned sig=86fc80138a36 -->

<a id="fix-tables-sample"></a>
## Fix Broken Tables Sample { #fix-tables-sample }

This document is a test fixture for **Fix broken tables** (`translate/translate_fix_tables.py`).
The en/ja copies deliberately keep three shapes of table divergence from ko, so a fix run can be checked
for rebuilding exactly those section bodies from ko and preserving every other section byte-for-byte.

This document is not registered in the user guide menu (`ko/nav.yml`). It is a pipeline fixture, not a published guide.

<a id="fix-tables-untouched"></a>
## Section With a Healthy Table { #fix-tables-untouched }

The table in this section is translated with the same identifier rows as ko. It must stay **byte-for-byte identical** after a fix run.

| Name | Type | Format | Description |
|---|---|---|---|
| tokenId | Header | String | Token ID |
| appKey | Path | String | App key |
| pageSize | Query | Integer | Number of items per page |

<a id="fix-tables-missing"></a>
## Section Whose Table Went Missing { #fix-tables-missing }

The same section in en/ja has no table below. Because the table count inside the section differs from ko, a fix run must rebuild this section body from ko.

<a id="fix-tables-shifted"></a>
## Section Whose First Column Was Overwritten { #fix-tables-shifted }

The same section in en/ja has a table with ko's row and column count, but the identifiers in the first column were overwritten with format names. ko's identifier rows are absent from the paired table, so it must be rebuilt.

| Name | Type | Format | Description |
|---|---|---|---|
| UUID | Body | UUID | Instance type UUID |
| UUID | Body | UUID | Image UUID |
| String | Body | String | Key pair name |

<a id="fix-tables-rows"></a>
## Section Missing a Row { #fix-tables-rows }

The same section in en/ja lost one identifier row from its table. The remaining rows are fine.

| Name | Type | Format | Description |
|---|---|---|---|
| volumeId | Body | UUID | Block storage UUID |
| volumeType | Body | String | Storage type |

<a id="fix-tables-prose-keys"></a>
## Table Without Identifiers { #fix-tables-prose-keys }

**Negative control.** The first column of this table is prose, so it has no identifier rows, and the en/ja table has the same row and column count. Nothing observable is wrong, so a fix run must leave this section alone.

| Item | Description |
|---|---|
| Instance type | CPU/memory spec of the instance to create |
| Block storage | Size of the root volume |

### Child Section Without an Anchor

**Second negative control. Do not add an `<a id>` anchor or a `{ #id }` attribute to this heading.**

The table below is missing one identifier row in en/ja. But this heading has no anchor, so the table is attributed to the section above while the rebuild unit stops at this heading. A fix run must not rebuild the section above; it must report it as skipped in the PR body.

| Name | Type | Format | Description |
|---|---|---|---|
| metricName | Body | String | Metric name |
| duration | Body | Integer | Duration (minutes) |

<a id="fix-tables-tail"></a>
## Last Section { #fix-tables-tail }

This section comes after the fix targets. It must be preserved byte-for-byte once the sections above are rebuilt.
