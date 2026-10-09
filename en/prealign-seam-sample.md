# Alignment Seam Sample

<a id="seam-overview"></a>
## Overview

A fixture that measures the places (seams) where pre-align joins sections that were not neighbours. Reproduces cloud-translate#1249.

<a id="seam-glued-control"></a>
## Glued Heading Control

In this translation, the next section's anchor is glued right under this section's table with no blank line. They were neighbours in the source, so alignment must not change it.

| Name | Description |
| --- | --- |
| alpha | The first value |
<a id="seam-glued-next"></a>
## Glued Next Section

Control body.

<a id="seam-table-last"></a>
## Section Ending with a Table

In this translation, this section is the last one in the document and ends on the table's last row.

| Name | Type | Description |
| --- | --- | --- |
| totalCount | Integer | Total count |
