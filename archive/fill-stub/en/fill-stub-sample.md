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

<!-- TODO: translate body -->

<a id="fill-stub-code"></a>
## Section With a Code Block { #fill-stub-code }

<!-- TODO: translate body -->

<a id="fill-stub-heading"></a>
## 제목까지 비어 있는 섹션 { #fill-stub-heading }

<!-- TODO: translate -->

<a id="fill-stub-heading-child"></a>
### 하위 제목도 비어 있는 경우 { #fill-stub-heading-child }

<!-- TODO: translate -->

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## Last Section { #fill-stub-tail }

This section comes after the stubs. It must be preserved byte-for-byte once the sections above are filled.
