# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo actually is

Not a product codebase — a **test fixture** for the NHN Cloud translation pipeline. It holds:

- `ko/`, `en/`, `ja/` — parallel Markdown docs (based on NHN Cloud "Compute > Instance") used as translation input/output samples.
- `archive/{alpha-origin,aligned,alpha-origin-40pct}/{ko,en,ja}/` — frozen seed states that the restore scripts copy back into `ko/en/ja/` before each e2e run. `alpha-origin` is the canonical seed; `aligned/` is a pre-aligned `public-api.md`; `alpha-origin-40pct/` is a size-reduced variant used by the re-translate flow.
- `scripts/` — the real "code": bash scripts that drive an external dashboard/Jenkins pipeline (fix-heading-syntax → align → ko-review → translate) and verify results with `scripts/check_docs_align.py` (structure) plus the `claude` CLI (semantics, ko-review only).
- Documentation in `scripts/dashboard-api.md` describes the dashboard endpoints these scripts hit.

There is **no build, no test framework, no lint**. The e2e scripts are the tests.

## Branch conventions

- `alpha` — canonical branch. **Must stay clean** — e2e scripts default to spinning up a fresh session branch instead of committing here. Only script/doc edits belong on `alpha`.
- `beta` — kept in sync with `alpha` for downstream consumers.
- `e2e/<UTC-timestamp>` — a session branch created by `e2e-align-and-translate.sh` at start of each run. All pipeline PRs/commits happen here.
- `translate-test/<ts>` — head branch of the ko-mutation PR that a session opens; created by `create-translate-test-pr.sh`.
- `translate/translate-test/<ts>-<hash>-<ts>` — head branch of the translation-result PR produced by the translate Jenkins job.
- `pre-align/fix-headings-*`, `pre-align/fix-heading-syntax-*` — head branches of PRs produced by the Jenkins align / fix-heading-syntax jobs.
- `alpha-origin` (remote) — historical reference; the *directory* `archive/alpha-origin/` is what restore uses, not this branch.

## Running the e2e pipeline

Prerequisites (all must be on PATH): `git`, `gh` (logged in), `curl`, `python3`, `claude` (Claude Code CLI).

Env: `load_env.sh` at repo root exports `DASHBOARD_BASE_URL` and `DASHBOARD_API_TOKEN`. **It is untracked and holds a real token — never commit it.**

```bash
source ./load_env.sh

# Full round1 e2e (~25-35min; it was ~2h before the deterministic verifier).
# Creates e2e/<ts> from alpha, runs the whole pipeline
# on it, merges everything into that session branch. Alpha is not touched.
bash scripts/e2e-align-and-translate.sh
# → prints "E2E_BASE_BRANCH=e2e/<ts>" as a marker for the wrapper

# Round2 — 2nd-generation drift on the same session branch (~1h)
bash scripts/e2e-translate-round2.sh --base-branch e2e/<ts>

# Override the auto-created branch (e.g., to re-run on alpha directly)
bash scripts/e2e-align-and-translate.sh --base-branch alpha
```

Common flags for both e2e scripts: `--engine api|cli`, `--model haiku|sonnet|opus`, `--tm-top-k N`, `--chunk-workers N`, `--guidelines-variant-{en,ja} <v>`, `--verify py|fable`. Round1 also has `--align-v2 / --no-align-v2` and `--from-aligned <branch>` (skip steps 2–9, see "Suite runtime shape"). Round2 requires `--base-branch` when the session branch isn't `alpha`.

`scripts/e2e-suite.sh` is the runner for all of the above (`all` = every plan except `round2`, which needs a manual merge first). `scripts/e2e-concurrent-prs.sh` (`concurrent` plan) is the one e2e that never touches the dashboard — it reproduces the concurrent-ko-PR scenario (A opened, B opened+merged+translated, then A merged and translated) with the **local** `translate_pr.py` and checks that A's translation preserves B's new section / table row.

`scripts/e2e-retranslate-align-and-translate.sh` is a variant of round1 that appends a full re-translation of `public-api.md` to the align PR (using `/api/translate/file` and a 40%-reduced fixture for speed).

## Design points to preserve

- **Round1 auto-merges** translation-PR → ko-PR head → session branch on `ALIGNMENT: OK`. **Round2 does not** — its translation PR is left OPEN with the fable verification result as a comment. This asymmetry is intentional (round2 output is for human review).
- Round2 detects the translation PR by **head-branch prefix** `translate/<ko_head_ref>-`, not by base. This is because round2 merges its ko-change PR *before* triggering translate, so the resulting PR opens against the session branch rather than the ko-PR branch.
- `create-translate-test-pr.sh` mutates only `ko/` files (en/ja are deliberately left as drift) and refuses to run with a dirty working tree. Its `PLAN_ROUND2` uses `add_section_no_id` / `add_subsection_no_id` — round2 adds new sections **without** anchor ids so the translate job's auto-assignment is exercised end-to-end; the round2 fable prompt has a dedicated "(5) anchor id 자동 할당 검증" check for this.
- Session branches are left behind after each run for debugging. Manual cleanup:
  ```bash
  gh pr list --repo TOAST-DOCS/Agent-Test --search "base:e2e/<ts>" --state open
  gh pr close <N> --repo TOAST-DOCS/Agent-Test --delete-branch
  git push origin :e2e/<ts>
  ```

## Verification model

Every e2e stage that produces a PR (align, translate) is gated by a checker that inspects the PR's head branch in a worktree and prints `ALIGNMENT: OK` or `ALIGNMENT: FAIL` on its **last line**. The wrapper greps that line (`grep -q '^ALIGNMENT: OK'`) to decide merge vs. leave-open — keep that contract intact.

The gate is **`scripts/check_docs_align.py`** (default, `--verify py`), a deterministic implementation of the six structural rules the old fable prompt asked for:

1. heading level order identical across ko/en/ja
2. anchor id order identical (`<a id>`/`<a name>`/`<tag id>` and heading `{ #id }`)
3. table count + per-table data row count identical; orphan table rows (a `|`-run with no separator) fail
4. rows keyed by a language-independent identifier (version/code token) keep the same key set and order
5. no Korean left in en/ja outside fences/inline code — with `scripts/known_korean_leftovers.txt` listing literals that are *expected* to stay (reported as `~`, not FAIL)
6. every row of a table has the header's cell count (a wider row silently loses cells when rendered)
7. `--markup` (markup-churn only): if ko has no bare `<br>` left, neither may en/ja — i.e. cosmetic markup mirroring actually ran

It replaced a `claude -p --model fable` agentic check that spent 15–25 min per stage reading the same 11 documents; the Python version takes ~0.05 s and cannot drift between runs. `--verify fable` still runs the old prompt (kept in the scripts) when a semantic check is wanted. `e2e-korean-review.sh` is unchanged — its check *is* semantic (does the review make sense?) and still uses fable, with the `KO_REVIEW: OK|FAIL` contract.

## Suite runtime shape

`scripts/e2e-suite.sh` runs plans sequentially. Two things keep it from re-paying fixed cost:

- **Deterministic verification** (above) — the two big LLM checks per plan are gone.
- **align prologue reuse** — steps 2–9 (restore → fix-heading-syntax → align → verify → merge) produce the same result every time because the fixture is frozen, so the suite runs them for the **first** align-based plan only, then passes that snapshot branch (`E2E_ALIGNED_BRANCH=<session>-aligned`) to the rest via `e2e-align-and-translate.sh --from-aligned`. Each plan still gets its own session branch, so plans can't interfere. `--no-reuse-align` restores per-plan prologues.

Measured Jenkins-side cost per plan (unchanged by the above): fix-heading-syntax ~1 min, align-heading 3–4 min, ko-review 0.5–2 min, translate 8–15 min. Trimming fixtures therefore buys much less than removing the LLM checks did — `archive/*/public-api.md` was cut to its first five `##` sections (2126 → 1086 lines) because it was pure repetition of the same endpoint shape; the rest of the fixture is left alone on purpose (it carries the align drift, the markup churn counts, and the mutation anchors).

## Dashboard API contract

`scripts/dashboard-api.md` is the authoritative reference for the endpoints the e2e scripts call (`/api/fix-heading-syntax`, `/api/align`, `/api/ko-review`, `/api/translate`, `/api/translate/file`, `/api/jobs/<id>`). Consult it before adding new API calls or changing request bodies.
