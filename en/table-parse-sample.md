<!-- machine_translated: true -->

<!-- pre-align:aligned sig=6c39f4c29b20 -->

<a id="table-parse-sample"></a>
## Table Parsing Sample { #table-parse-sample }

This document is a fixture collecting the places where **who counts a table's rows** gives different answers.
It is not registered in the user guide menu (`ko/nav.yml`) — it is a pipeline fixture, not a published guide.

Three parties count the rows of one table, and they do not agree.

| Counted by | Counted how | What it decides |
|---|---|---|
| Site renderer | python-markdown — the only line break is `\n` | The row count the reader sees |
| Translation pipeline | lines starting with a pipe after `str.splitlines()` | The basis for table repair |
| Markup fix (M7) | Whether the render holds more rows than the source wrote | What maintenance can fix |

Below are the four types of that mismatch. (md_lines before/after comparison 20260922-031407) The expected verdict of each section is deterministically checked by `scripts/check_table_parse.py`.

<a id="table-parse-u2028"></a>
## A. A Table Cut Short by U+2028 { #table-parse-u2028 }

The last cell of the first row holds a **U+2028** (LINE SEPARATOR). Markdown does not treat it as a line break, so **the rendered table is a healthy three rows.** But `str.splitlines()` does split on U+2028, so the pipeline reads this table as **one row**.

The result: the translation's table reconcile reads "ko has 1 row, en/ja have 3", takes ko as authoritative and **deletes rows 2 and 3 from en/ja**. Because the render is fine, the markup fix (M7) cannot see this table — and it is right not to, there is nothing to fix. **The document is correct; only the parser is wrong.**

Live case: `TOAST-DOCS/DDoS-Guard` `ko/l7-ddos-settings-guide.md` — three tables read as ko 1 row against en/ja 10, 9 and 3, leaving 19 en and 16 ja rows queued for deletion.

| No. | Item | Configuration example |
|---|---|---|
| 1 | Header timeout | client_header_timeout 10s<BR>client_body_timeout 10s |

<a id="table-parse-newline"></a>
## B. A Table Cut Short by a Real Line Break { #table-parse-newline }

The table is the same as A's and **differs by exactly one character** — a **real `\n`** in place of U+2028. Here the render breaks too — the continuation line falls out of the table as a paragraph — so the markup fix (M7) catches it as "a cell's line break split one row in two" and repairs it by deleting one line break.

So **A and B look the same to the pipeline and different to document maintenance.** Maintenance drains the stock of B only; A is structurally out of its reach because the render is healthy.

| No. | Item | Configuration example |
|---|---|---|
| 1 | Header timeout | client_header_timeout 10s<BR>client_body_timeout 10s |

<a id="table-parse-outlier"></a>
## C. A Row Missing One Pipe { #table-parse-outlier }

All three languages hold **three rows and four columns, and the row counts already match.** Only the second row of en/ja is missing one separator pipe, leaving it with three cells.

`_table_ncols` derives a table's column count from the **minimum** cell count across its rows, so this table reads as three columns. It is therefore judged to have a different schema from ko (four columns) — though it does not — and the most destructive repair, a **whole-table rewrite including the header**, is selected. Since the row counts already agree, the premise "row counts are kept equal by maintenance" does not block this one.

Live case: `OCR#177` (build #370) — ko 10 rows against en 10 rows, but three en rows carried 6, 3 and 3 cells instead of 4: four model calls, en left unrepaired after two failed verifications, ja column-synced for nothing. The same shape survives in 13 corpus documents (`Alimtalk/en/error-code.md` holds a 230-row one).

| Name | Type | Format | Description |
|---|---|---|---|
| tokenId | Header | String | Token ID |
| appKey | Path | String | App key |
| pageSize | Query | Integer | Items per page |

<a id="table-parse-control"></a>
## D. Control — A Table That Really Did Lose a Row { #table-parse-control }

en/ja do not have ko's `SVC-104` row. This is a well-aligned keyed table, so it must **still be repaired** regardless of the guards for A and C. Without this section, the change is indistinguishable from one that simply made the pipeline repair less.

| Code | Description |
|---|---|
| SVC-101 | The request format is invalid |
| SVC-102 | Authentication information is missing |
| SVC-103 | The request quota has been exceeded |
| SVC-104 | Could not find the target resource. |
