<!-- machine_translated: true -->

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
## Pinned sibling bullets

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
## Indentation donor

The nested bullet in the list above exists for `_reuse_unchanged_list_marker`. Handed an
indented bullet on its own, the model has no surrounding list to copy the depth from and may
strip the indentation or change the marker, which silently moves the item under a different
parent. The marker and the indentation are owned by ko.

<a id="edit-target"></a>
## Edit target

The e2e changes only the **last item** of the "Pinned sibling bullets" list. Whether that single
item's change drags the whole list into the model is all this fixture asks.

<a id="nested-admonition"></a>
## Admonition inside a list

The `!!! danger` box below sits under a nested bullet with a 12-space indent, and its body is indented 16 spaces. The e2e edits only two sibling bullets of the same list (**Other SANs** and **Extended key usage OIDs**) and leaves the box alone. The indentation of the box lines is owned by ko.

1. On the Create Certificate Template page, enter the following information.

    - SAN option
        - **Allow IP SANs**: allow IP addresses to be included in the SAN.
        - **Other SANs**: enter other types of SANs (e.g. 1.2.3.4;UTF8:test@example.com)

    - Common applied settings
        - Key parameters
            - **Key algorithm**: Choose among RSA, EC, and ED25519
            - **Key bit**: algorithmic key bit selection
            - **Signature bit**: Select the number of bits in the hash algorithm to use for signing the certificate

            !!! danger "Caution"
                Signature bits can only be set when using the RSA algorithm. Otherwise, it is ignored by the algorithm.

        - Extended key usage
            - **Extended key usage OIDs**: you can manually enter an OID for additional extended key purposes (e.g. 1.3.6.1.5.5.7.3.1, 1.3.6.1.5.5.7.3.2)

2. Click **Add** to add a certificate template.

<a id="nested-admonition-body"></a>
## Editing the body of an admonition inside a list

The e2e edits only **one sentence in the body** of the box below. The box is re-translated, but the indentation of the box line (8 spaces) and of its body (12 spaces) must match ko.

1. On the Create Certificate page, enter the following information.

    - Certificate information
        - **Common name**: Enter the common name (CN) of the certificate.
        - **Validity period**: Enter the validity period of the certificate.

        !!! tip "Note"
            The common name cannot be changed after issuance.

    - SAN information
        - **Subject alternative name**: Enter an additional identifying name in domain format.

2. Click **OK** to create the certificate.

<a id="list-fence-edit"></a>
## Editing one line of a code block inside a list

The code blocks below are the body of numbered list items, so they sit at a 4-space indent. The e2e edits only the **second line** of the second code block. ko is the source of truth for the indentation of every line of a code block (opening fence, body and closing fence).

1. Request the first page without `cursor`.

    ```text
    GET /{API path}?{query conditions}&size=20
    → 20 items in the list, "nextCursor": "Y3Vyc29yLWV4YW1wbGU"
    ```

2. Use the `nextCursor` value from the response as the `cursor` in the next request.

    ```text
    GET /{API path}?{query conditions}&size=20&cursor=Y3Vyc29yLWV4YW1wbGU
    → 7 items in the list, "nextCursor": null
    ```

3. Repeat step 2 until the `nextCursor` in the response becomes `null`.

<a id="list-fence-control"></a>
## Code block outside a list (control)

The e2e also edits the second line of the code block below. A code block outside a list (column 0) has no indentation to lose, so it must match ko even with the code before the fix.

```text
GET /{API path}?{query conditions}&size=20
→ 20 items in the list, "nextCursor": "Y3Vyc29yLWV4YW1wbGU"
```
