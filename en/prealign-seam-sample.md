<!-- pre-align:aligned sig=90a77afad7b2 -->

# Alignment Seam Sample

<a id="seam-overview"></a>
## Overview { #seam-overview }

A fixture that measures the places (seams) where pre-align joins sections that were not neighbours. Reproduces cloud-translate#1249.

<a id="seam-glued-control"></a>
## Glued Heading Control { #seam-glued-control }

In this translation, the next section's anchor is glued right under this section's table with no blank line. They were neighbours in the source, so alignment must not change it.

| Name | Description |
| --- | --- |
| alpha | The first value |
<a id="seam-glued-next"></a>
## Glued Next Section { #seam-glued-next }

Control body.

<a id="seam-middle-missing"></a>
## Omitted middle section { #seam-middle-missing }

<!-- TODO: translate body -->

<a id="seam-table-last"></a>
## Section Ending with a Table { #seam-table-last }

In this translation, this section is the last one in the document and ends on the table's last row.

| Name | Type | Description |
| --- | --- | --- |
| totalCount | Integer | Total count |

<a id="seam-missing-last"></a>
## Last missing section { #seam-missing-last }

<!-- TODO: translate body -->

