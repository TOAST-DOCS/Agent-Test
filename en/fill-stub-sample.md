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

This is a body stub with a table. After it is filled, the number of columns and rows must remain the same as the Korean (ko) version.

| Item | Description | Default Value |
|---|---|---|
| Instance type | CPU/memory specification of instance to create | m2.c1m2 |
| Block Storage | Root volume size (GB) | 20 |
| Boot script | Script executed when the instance first boots | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

Code blocks should not be translated. The block below must remain unchanged even after it is filled.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only this sentence outside the block is a translation target, and command and comment lines should not be modified.

<a id="fill-stub-heading"></a>
## Section with Empty Heading { #fill-stub-heading }

The same section in en/ja is a heading stub where the heading remains in Korean.
When executing the fill operation, translate both the heading and body together; however, the heading level and `{ #id }` must take the Korean version as the canonical source.

<a id="fill-stub-heading-child"></a>
### When child headings are also empty { #fill-stub-heading-child }

This is a case where heading stubs appear consecutively. Each must be filled independently of the parent section, and the `###` level must not be promoted or demoted to `##`.

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.
