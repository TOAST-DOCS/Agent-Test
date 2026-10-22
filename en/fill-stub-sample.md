<!-- machine_translated: true -->

<!-- pre-align:aligned sig=28e448e4e890 -->

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

This is a body stub with a table. After it is filled in, the table must have the same number of columns and rows as the Korean source.

| Item | Description | Default |
|---|---|---|
| Instance Type | CPU/memory specifications of the instance to create | m2.c1m2 |
| Block Storage | Size of the root volume (GB) | 20 |
| Boot Script | Script to run on the first boot of the instance | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

Code blocks are not subject to translation. The block below must remain unchanged even after it is filled in.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only this sentence outside the block is subject to translation, and command and comment lines are not modified.

<a id="fill-stub-heading"></a>
## Section with an Unfilled Heading { #fill-stub-heading }

The corresponding section in en/ja is a heading stub where the heading is still in Korean.
When filling stubs, translate both the heading and the body, but the heading level and `{ #id }` must follow the ko source as the authoritative reference.

<a id="fill-stub-heading-child"></a>
### When the Child Heading Is Also Empty { #fill-stub-heading-child }

This is a case where heading stubs appear consecutively. Each must be filled in independently of the parent section,
and the `###` level must not be promoted to `##` or demoted.

<a id="section-1"></a>
## Section Without an Anchor { #section-1 }

**This is a negative control. Do not attach an `<a id>` anchor or a `{ #id }` attribute to this heading.**

Because the fill operation locates ko sections by shared anchors, stubs without anchors must not be filled and must be reported as "skipped" in the PR body.
If they are silently filled or silently dropped, it is a defect.

If pre-align is run on this document again, an id will be attached to this heading and the control will be lost,
in which case revert from the copy in `archive/fill-stub/`.

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.

The options are listed below.

| Option | Value |
| --- | --- |
| mode | fast |
