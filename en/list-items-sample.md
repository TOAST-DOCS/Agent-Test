<!-- machine_translated: true -->

<!-- pre-align:aligned sig=df08ceb95bc6 -->

# List-item splice fixture — untouched sibling bullets

A Markdown list has no blank line between its items, so it is captured as a **single block**.
Editing one bullet therefore drags every sibling bullet in the same list through the model, and
a line that reaches the model can be rewritten. cloud-translate `#924` added `LIST_ITEMS`
(`TRANSLATE_DIFF_LIST_ITEMS`), which splits a list into **per-item units** to stop that exposure.

This document is the fixture for the condition under which that feature **silently turns off**.
The condition is the single `<!-- machine_translated: true -->` line at the top of the en/ja
files — ko does not have it, so the document's block count differs by one, and
`_maybe_expand_lists` requires an **exact match**, which makes it abandon list expansion
altogether. The coarse path tolerates the same mismatch through `_structural_alignment`; only
list expansion does not.

The heading structure is identical across the three languages; that one line is the only
difference. Delete it and the feature comes back immediately — that is this fixture's control
arm.

<a id="pinned-siblings"></a>
## Pinned sibling bullets { #pinned-siblings }

**Only the last item** in the list below is edited. The rest are left alone, and their en/ja
translations are **deliberately pinned to wording a fresh translation would plausibly change**.
Exposed, they change; not exposed, they stay byte-identical — that is the judgment.

* [Authentication Overview](./auth-method-overview/)
* [Supported Authentication Methods](./supported-authentication-methods/)
* [Settings by Feature](./feature-settings/)
    * [DEX Encryption Target Specification](./dex-encryption/)
* [Service API](./service-api/)
* [Release Notes](./release-notes/)

Both pinned renderings come from drift that was actually observed.

| Language | Pinned wording | Wording that appears once exposed | Real incident |
| --- | --- | --- | --- |
| en | `Settings by Feature` | `Feature-Specific Settings` | AppGuard#446 (2026-09-11) |
| ja | `認証方式の概要` | `認証方法の概要` | TOAST-Cloud#415 (2026-09-18) |

**The pinned side is the correct one in both cases.** `Settings by Feature` is the entry name in
that guide's table of contents, and `認証方式の概要` is the title of the document the link
arrives at. The new wording is not wrong as language, but it no longer matches the document it
points to, so the reader sees one thing under two names.

<a id="indent-donor"></a>
## Indentation donor { #indent-donor }

The nested bullet in the list above exists for `_reuse_unchanged_list_marker`. Handed an
indented bullet on its own, the model has no surrounding list to copy the depth from and may
strip the indentation or change the marker, which silently moves the item under a different
parent. The marker and the indentation are owned by ko.

<a id="edit-target"></a>
## Edit target { #edit-target }

The e2e changes only the **last item** of the "Pinned sibling bullets" list. Whether that single
item's change drags the whole list into the model is all this fixture asks.
