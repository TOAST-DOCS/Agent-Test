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

When you create an instance, it may take a few minutes for the status in the console to change to **Running**.

If the status does not change for an extended period, first verify that the combination of the image and instance type is correct.

<a id="fill-stub-table"></a>
## Section With a Table { #fill-stub-table }

| Item | Description | Default |
|---|---|---|
| Instance Type | CPU/memory specification of the instance to create | m2.c1m2 |
| Block Storage | Size of the root volume (GB) | 20 |
| Boot Script | Script to run when the instance boots for the first time | None |

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

This request does not return a response body. For a valid request, return status code 200.

The code block is not a translation target. The block below must retain its content even after it is filled.

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

Only this sentence outside the block is a translation target, and command and comment lines are not modified.

<a id="fill-stub-heading"></a>
## Section with empty heading { #fill-stub-heading }

The same section in en/ja has a heading stub where the heading is still in Korean.
When performing fill, translate both the heading and body together, but the heading level and `{ #id }` must follow ko as the authoritative source.

<a id="fill-stub-heading-child"></a>
### When a subheading is also empty { #fill-stub-heading-child }

This occurs when heading stubs appear consecutively. Each must be filled independently of the parent section,
and the `###` level must not be promoted to `##` or demoted.

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.
