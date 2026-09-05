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

The same section in en/ja has the heading already translated, and only the body is empty as a body stub.
When running the fill, keep the heading line as is and translate only this paragraph.

It may take a few minutes for the console status to change to **Running** when you create an instance.
If the status does not change for a long time, first verify that the combination of image and instance type is correct.

<a id="fill-stub-table"></a>
## Section With a Table { #fill-stub-table }

This is a body stub with a table. After it is filled, the table must have the same number of columns and rows as the Korean version.

| Item | Description | Default Value |
|---|---|---|
| Instance Type | CPU and memory specification of instance to create | m2.c1m2 |
| Block Storage | Root volume size (GB) | 20 |
| Boot Script | Script to run when instance first boots | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

Code blocks are not translation targets. The block below must retain its content even after being filled.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only this sentence outside the block is a translation target, and do not modify command and comment lines.

<a id="fill-stub-heading"></a>
## Section with an empty heading { #fill-stub-heading }

The corresponding sections in en/ja are heading stubs where the heading is still in Korean.
The fill operation translates both the heading and body together, but the heading level and `{ #id }` must follow ko as the authoritative source.

<a id="fill-stub-heading-child"></a>
### When child headings are also empty { #fill-stub-heading-child }

This is a case where heading stubs appear consecutively. Each must be filled independently from the parent section, and the `###` level must not be promoted to `##` or demoted.

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.
