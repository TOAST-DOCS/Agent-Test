<!-- machine_translated: true -->

<!-- pre-align:aligned sig=dc7f43ef0b72 -->

<a id="fill-stub-sample"></a>
## Fill Empty Translation Sample { #fill-stub-sample }

This document is a test fixture for **Fill empty translations** (`translate/translate_fill_stubs.py`).
The en/ja copies deliberately keep the two kinds of stub that pre-align leaves behind, so a fill run
can be checked for filling exactly those stubs and preserving every other section byte-for-byte.

This document is not registered in the user guide menu (`ko/nav.yml`). It is a pipeline fixture, not a published guide. The document maintenance e2e added this sentence.

<a id="fill-stub-untouched"></a>
## Already Translated Section { #fill-stub-untouched }

This section is already translated in en/ja. It must stay **byte-for-byte identical** after a fill run.
If even one character changes, the fill touched something outside a stub, which is a defect.

<a id="fill-stub-body"></a>
## Section With an Empty Body { #fill-stub-body }

<!-- TODO: translate body -->

<a id="fill-stub-table"></a>
## Section With a Table { #fill-stub-table }

This is a body stub with a table. After it is filled in, the number of columns and rows in the table must match those in the Korean source.

| Item | Description | Default |
|---|---|---|
| Instance type | CPU/memory specifications of the instance to create | m2.c1m2 |
| Block Storage | Size of the root volume (GB) | 20 |
| Boot script | Script to run on the first boot of the instance | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

Code blocks are not subject to translation. The block below must remain unchanged even after it is filled in.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only this sentence outside the block is subject to translation; command and comment lines are left untouched.

<a id="fill-stub-heading"></a>
## Section Where Even the Heading Is Empty { #fill-stub-heading }

The same section in en/ja is a heading stub where the heading is still in Korean.
When filling, translate both the heading and the body, but the heading level and `{ #id }` must follow the ko source as the authoritative reference.

<a id="fill-stub-heading-child"></a>
### When the Child Heading Is Also Empty { #fill-stub-heading-child }

This is a case where heading stubs appear consecutively. Each one must be filled in independently of the parent section,
and the `###` level must not be promoted to `##` or demoted.

<a id="section-1"></a>
## Section Without an Anchor { #section-1 }

**This is a negative control. Do not attach an `<a id>` anchor or a `{ #id }` attribute to this heading.**

Because the fill process finds ko sections by shared anchors, a stub without an anchor must not be filled and must instead be reported as "skipped" in the PR body. If it is silently filled or silently removed, it is a defect.

If pre-align is run again on this document, an id will be added to this heading and the control will be lost, so the copy in `archive/fill-stub/` must be restored at that point.

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.

The options are listed below.

| Option | Value |
| --- | --- |
| mode | fast |
