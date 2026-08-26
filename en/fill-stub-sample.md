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

For the corresponding sections in en/ja, the heading is translated but the body is empty as a stub. When running the fill operation, keep the heading line unchanged and translate only this paragraph to fill it in.

Creating an instance may take a few minutes until the status in the console changes to **Running**.
If the status does not change for a long time, first check that the combination of the image and instance type is correct.

<a id="fill-stub-table"></a>
## Section With a Table { #fill-stub-table }

This is a body stub with a table. After being filled, the table must have the same number of columns and rows as the Korean version.

| Item | Description | Default |
|---|---|---|
| Instance type | CPU/memory specification of instance to create | m2.c1m2 |
| Block storage | Root volume size (GB) | 20 |
| Boot script | Script to run when the instance first boots | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

Code blocks are not translation targets. Even after the block below is filled, its content must remain unchanged.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only sentences outside the block are translation targets. Command and comment lines are not modified.

<a id="fill-stub-heading"></a>
## Section with empty heading { #fill-stub-heading }

The same sections in en/ja are heading stubs where the heading is still in Korean.
A fill operation translates the heading and body together, but the heading level and `{ #id }` must follow Korean (ko) as the source of truth.

<a id="fill-stub-heading-child"></a>
### When child headings are also empty { #fill-stub-heading-child }

This is a case where heading stubs appear consecutively. Each one must be filled independently of the parent section, and the heading level `###` must not be promoted to `##` or demoted.

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.
