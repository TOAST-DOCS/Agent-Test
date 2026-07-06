# Heading Lint Demo — Report-Only Rules

T3 (7+ `#`) and F1 (unclosed fence with no clean heuristic candidate)
are surfaced but NOT auto-fixed — a safe rewrite needs human judgment.
The tool inserts an HTML-comment marker just above each finding and
posts an inline review comment there; accepting the `suggestion` block
removes the marker in one click.

<a id="t3"></a>
<!-- heading-lint: T3 L10 — 리뷰 후 이 라인 삭제 (suggestion accept 시 자동 제거) -->
####### T3 seven hashes exceeds CommonMark h6 cap

Body prose for T3.

<a id="f1"></a>
## F1 unclosed code fence with no candidate

The 4-backtick fence below has no matching closer anywhere in the file
and no shorter fence-of-same-char candidate to guess from — pure F1.

$ line 1 inside the never-closed fence
$ line 2 still inside
$ this line, and every line below, is silently swallowed as code
