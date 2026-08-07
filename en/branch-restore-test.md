<!-- machine_translated: true -->

# Branch restore test

## Purpose

A fixture that verifies whether `translate_pr.py` restores the deleted head branch of a merged PR before performing translation.

## Scenario

1. Process this PR as merged with the branch deleted.
2. Run `translate_pr.py` with this PR URL.
3. The log must contain `Restoring deleted source branch`, and a translation PR must be opened.