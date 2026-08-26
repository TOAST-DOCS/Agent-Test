<!-- pre-align:aligned sig=7e09fc5b0570 -->

<a id="fix-links-overview"></a>
## Link Fix Test { #fix-links-overview }

This document is an e2e fixture for **link fix** (`dashboard/viewer/link_fix.py`, Jenkins `fix-links`).
Each section below targets one deterministic rule with a **deliberately malformed link**, and
`scripts/e2e-fix-links.sh` judges the repair rule by rule.

This document is not registered in the user guide menu (`ko/nav.yml`). It is a pipeline fixture, not a published guide.

<a id="fix-links-self"></a>
## self-link { #fix-links-self }

A link to this very file written as a deployed-URL-shaped path. Only the in-file `#slug` should survive.

* [Valid links](./fix-links/#fix-links-controls)

<a id="fix-links-relativize"></a>
## relativize { #fix-links-relativize }

Links to a file in this repo written as an absolute URL / repo-rooted path. Both should become `./overview.md#pricing`.

* [Pricing (github blob URL)](https://github.com/TOAST-DOCS/Agent-Test/blob/alpha/en/overview.md#pricing)
* [Pricing (repo-rooted path)](/en/overview.md#pricing)

<a id="fix-links-langdir"></a>
## lang-dir { #fix-links-langdir }

An in-repo link pointing at another language folder. The same-language twin exists, so it should be swapped.

* [Pricing (other language folder)](../ko/overview.md#pricing)

<a id="fix-links-nested"></a>
## nested-frag { #fix-links-nested }

A link whose fragment swallowed a deployed-URL fragment, leaving `#a/#b`. Only the part after the last `/#` should survive.

* [Pricing (nested fragment)](./overview.md#overview/#pricing)

<a id="fix-links-heading"></a>
## heading-frag { #fix-links-heading }

The fragment is dead, but the link text matches a heading in the target document exactly.
It should become that heading's canonical id.

* [Key Pair](./overview.md#keypair-legacy-slug)

<a id="fix-links-report"></a>
## Links That Must Be Reported, Not Fixed { #fix-links-report }

Links whose repair cannot be verified to resolve. They must be neither silently fixed nor silently skipped —
they belong in the PR body's "needs a human" table with a reason.

* [A document that does not exist](./no-such-doc-e2e.md#nowhere)
* [No way to tell which anchor](./overview.md#anchor-that-does-not-exist-e2e)

<a id="fix-links-controls"></a>
## Valid Links { #fix-links-controls }

**Negative controls.** Every link below is already correct, so it must stay **byte-for-byte identical**
after a fix run. If even one changed, the fixer touched a healthy link.

* [First section of this document](#fix-links-overview)
* [Overview document](./overview.md)
* [Pricing in the overview document](./overview.md#pricing)
* [Pricing in the overview document (deployed-URL shape — the corpus's dominant practice)](./overview/#pricing)
* [NHN Cloud](https://www.nhncloud.com/)

Links inside a code fence are not links, so they must survive untouched as well.

```markdown
[broken link inside a fence](./no-such-doc-e2e.md#nowhere)
[self-path inside a fence](./fix-links/#fix-links-controls)
```
