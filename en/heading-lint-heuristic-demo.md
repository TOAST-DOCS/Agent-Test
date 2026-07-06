# Heading Lint Demo — F1x Heuristic

The 4-backtick fence below opens on line 8 and never has a matching
4-backtick closer, but the single 3-backtick line at line 10 is the
obvious "author meant this to close" candidate — the F1x heuristic
extends it to 4 backticks so the fence closes there. Inline review
comment on the extended line offers a one-click revert if the guess is
wrong.

````
$ echo "code inside the 4-backtick fence"

<a id="after-fence"></a>
## After the fence

This heading and everything below MUST render as normal markdown after
the fence closes — before the fix, the whole tail of the file was
silently absorbed as code because the fence stayed open.
