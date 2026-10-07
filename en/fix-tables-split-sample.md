# Split Cell Table Sample

<a id="fix-tables-split-sample"></a>
## Split Cell Table Sample { #fix-tables-split-sample }

This document is a fixture that measures how fix-tables handles **a table whose cell is split over two lines on the translation side**.

<a id="fix-tables-split-cell"></a>
## Table with a Split Cell { #fix-tables-split-cell }

The callback methods are summarized in the following table.

| Callback Name | Meaning | Description |
|----------|------|------|
| onMatch | Process match requests | The user processes match requests directly.<br>That is, it gathers the minimum requests and matches them to the capacity. |
| onRefill | Process match refill requests | Fills a new user when someone leaves a matched room. |

<a id="fix-tables-split-tail"></a>
## Last Section { #fix-tables-split-tail }

| Name | Value |
|------|----|
| `TIMEOUT` | -1 |
| `SUCCESS` | 0 |
