# Heading Lint Demo — Deterministic Rules

This file exercises the five deterministic rules in
`pre-align/fix_heading_syntax.py`. Every heading below is intentionally
malformed; a corpus-lint run should auto-fix each one and open a PR whose
diff replaces the broken headings with the corrected form.

<a id="t1"></a>
### T1 no space after hashes

Body prose for T1.

<a id="t2"></a>
#### T2 stray period after hashes

Body prose for T2.

<a id="t4"></a>
### T4 doubled heading prefix

Body prose for T4.

<a id="t5"></a>
### T5 stray leading emphasis marker

Body prose for T5.

<a id="l1"></a>
## L1 indented heading

Body prose for L1.
