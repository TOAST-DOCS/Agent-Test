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

<!-- TODO: translate body -->

<a id="fill-stub-table"></a>
## Section With a Table { #fill-stub-table }

This is a body stub that contains a table. After it is filled in, the number of columns and rows in the table must match those in the Korean source.

| Item | Description | Default |
|---|---|---|
| Instance type | CPU/memory specifications for the instance to create | m2.c1m2 |
| Block Storage | Root volume size (GB) | 20 |
| Boot script | Script to run on the first boot of the instance | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

Code blocks are not subject to translation. The block below must remain as-is even after it has been filled in.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only this sentence outside the block is subject to translation; commands and comment lines must not be modified.

<a id="fill-stub-heading"></a>
## Section where even the heading is a stub { #fill-stub-heading }

The corresponding section in en/ja is a heading stub where the heading is still in Korean.
When running the fill operation, translate both the heading and the body, but the heading level and `{ #id }` must follow the ko source as the authoritative reference.

<a id="fill-stub-heading-child"></a>
### When the child heading is also empty { #fill-stub-heading-child }

This is a case where heading stubs appear consecutively. Each must be filled independently from the parent section, and the `###` level must not be promoted to `##` or demoted.

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.
