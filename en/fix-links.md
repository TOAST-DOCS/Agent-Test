<!-- pre-align:aligned sig=bd7c613fa6f9 -->

<a id="fix-links-overview"></a>
## Link Fix Test { #fix-links-overview }

This document is an e2e fixture for **link fix** (`dashboard/links/fix.py`, Jenkins `fix-links`).
Each section below targets one deterministic rule with a **deliberately malformed link**, and
`scripts/e2e-fix-links.sh` judges the repair rule by rule.

This document is not registered in the user guide menu (`ko/nav.yml`). It is a pipeline fixture, not a published guide.

<a id="fix-links-self"></a>
## self-link { #fix-links-self }

A link to this very file written as a deployed-URL-shaped path. Only the in-file `#slug` should survive.

* [Valid links](#fix-links-controls)

<a id="fix-links-relativize"></a>
## relativize { #fix-links-relativize }

Links to a file in this repo written as an absolute URL / repo-rooted path. Both should become `./overview.md#pricing`.

* [Pricing (github blob URL)](./overview/#pricing)
* [Pricing (repo-rooted path)](./overview/#pricing)

<a id="fix-links-langdir"></a>
## lang-dir { #fix-links-langdir }

An in-repo link pointing at another language folder. The same-language twin exists, so it should be swapped.

* [Pricing (other language folder)](./overview/#pricing)

<a id="fix-links-nested"></a>
## nested-frag { #fix-links-nested }

A link whose fragment swallowed a deployed-URL fragment, leaving `#a/#b`. Only the part after the last `/#` should survive.

* [Pricing (nested fragment)](./overview.md#pricing)

<a id="fix-links-heading"></a>
## heading-frag { #fix-links-heading }

The fragment is dead, but the link text matches a heading in the target document exactly.
It should become that heading's canonical id.

* [Key Pair](./overview.md#key-pair)

<a id="fix-links-langsite"></a>
## lang-site { #fix-links-langsite }

A site-root link naming **another language**. It looks like it carries the locale once, but the
deployed site fills the unwritten first position with this document's language, so it resolves to
`/en/…/ko/…` and dies. It should be swapped to the same-language twin.

* [Pricing (site-root, other language)](./overview/#pricing)

<a id="fix-links-absdocs"></a>
## abs-docs · abs-docs-env { #fix-links-absdocs }

Links to a file in this repo written as a **fully-qualified deploy URL**. One source file is
deployed to alpha/beta/master alike, so hardcoding a host is wrong in at least two environments.
Both should become relative paths; a non-production host gets its own notation code
(`abs-docs-env`).

* [Pricing (production host)](./overview/#pricing)
* [Pricing (alpha host)](./overview/#pricing)

<a id="fix-links-legacyjp"></a>
## legacy-jp { #fix-links-legacyjp }

A link still carrying the pre-2026-08 Japanese segment `jp`. That locale is dead at both
positions, so it should be swapped to this document's language.

* [Pricing (legacy jp)](./overview/#pricing)

<a id="fix-links-report"></a>
## Links That Must Be Reported, Not Fixed { #fix-links-report }

Links whose repair cannot be verified to resolve. They must be neither silently fixed nor silently skipped —
they belong in the PR body's "needs a human" table with a reason.

* [A document that does not exist](./no-such-doc-e2e.md#nowhere)
* [No way to tell which anchor](./overview.md#anchor-that-does-not-exist-e2e)
* [A document that exists only in another language](../ko/mermaid-sample.md)
* [![Figure](/en/overview.md#key-pair)](/en/overview.md#key-pair)

The four above are skipped for different reasons. The last two are, respectively, a link with
**no same-language twin in the repo** (swapping the language alone would turn a live link into a
404) and a snippet holding the target slot **twice** (an image pointing at itself), where which
occurrence to rewrite cannot be determined.
The first of the two only works if it points at a document that exists in ONE language (otherwise
the "swapping the language would 404" judgement never runs), so its target differs per language.
That means this fixture carries a **deliberate** ko/en/ja link divergence, which always shows up as
two findings in the `lang-parity` report. Judge rule (8c) pins those two as expected: if they are
missing, the comparison did not run.


<a id="fix-links-controls"></a>
## Valid Links { #fix-links-controls }

**Negative controls.** Every link below is already correct, so it must stay **byte-for-byte identical**
after a fix run. If even one changed, the fixer touched a healthy link.

* [First section of this document](#fix-links-overview)
* [Overview document](./overview.md)
* [Pricing in the overview document](./overview.md#pricing)
* [Pricing in the overview document (deployed-URL shape — the corpus's dominant practice)](./overview/#pricing)
* [Another repo's guide (site-root — the correct cross-repo form)](/Compute/Instance/en/overview/)
* [NHN Cloud](https://www.nhncloud.com/)

Links inside a code fence are not links, so they must survive untouched as well.

```markdown
[broken link inside a fence](./no-such-doc-e2e.md#nowhere)
[self-path inside a fence](./fix-links/#fix-links-controls)
```
