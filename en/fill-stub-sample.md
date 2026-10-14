<!-- pre-align:aligned sig=28e448e4e890 -->

<a id="fill-stub-sample"></a>
## Fill Empty Translation Sample { #fill-stub-sample }

This document is a test fixture for **Fill empty translations** (`translate/translate_fill_stubs.py`).
The en/ja copies deliberately keep the two kinds of stub that pre-align leaves behind, so a fill run
can be checked for filling exactly those stubs and preserving every other section byte-for-byte.

This document is not registered in the user guide menu (`ko/nav.yml`). It is a pipeline fixture, not a published guide.

<a id="fill-stub-untouched"></a>
## Already Translated Section { #fill-stub-untouched }

This section is already translated in en/ja. It must stay **byte-for-byte identical** after a fill run.
If even one character changes, the fill touched something outside a stub, which is a defect.

<a id="fill-stub-body"></a>
## Section With an Empty Body { #fill-stub-body }

For the same sections in en/ja, the heading is translated, but the body remains empty as a body stub.
When running the fill operation, the heading line should be kept as-is, and only this paragraph should be translated and filled in.

When you create an instance, it may take a few minutes for the console status to change to **Running**.
If the status does not change for a long time, first verify that the combination of the image and instance type is correct.

<a id="fill-stub-table"></a>
## Section With a Table { #fill-stub-table }

This is a body stub that contains a table. After being filled, the table must have the same number of columns and rows as the Korean version.

| Item | Description | Default value |
|---|---|---|
| Instance type | CPU/memory specification of instance to create | m2.c1m2 |
| Block Storage | Size of root volume (GB) | 20 |
| Boot script | Script to execute at first boot of instance | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

Code blocks are not subject to translation. The block below should remain unchanged even after it is filled.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only this sentence outside the block is subject to translation, and command and comment lines are not touched.

<a id="fill-stub-heading"></a>
## Section with Heading Stub { #fill-stub-heading }

The corresponding section in en/ja is a heading stub where the heading is still in Korean.
The fill operation translates both the heading and body together; however, the heading level and `{ #id }` must follow the Korean version as the canonical source.

<a id="fill-stub-heading-child"></a>
### When Child Headings Are Also Empty { #fill-stub-heading-child }

This occurs when heading stubs appear consecutively. Each must be filled independently of the parent section, and the ### level must not be promoted to ## or demoted.

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.
