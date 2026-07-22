# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo actually is

Not a product codebase — a **test fixture** for the NHN Cloud translation pipeline. It holds:

- `ko/`, `en/`, `ja/` — parallel Markdown docs (based on NHN Cloud "Compute > Instance") used as translation input/output samples.
- `archive/{alpha-origin,aligned,alpha-origin-40pct}/{ko,en,ja}/` — frozen seed states that the restore scripts copy back into `ko/en/ja/` before each e2e run. `alpha-origin` is the canonical seed; `aligned/` is a pre-aligned `public-api.md`; `alpha-origin-40pct/` is a size-reduced variant used by the re-translate flow.
- `scripts/` — the real "code": bash scripts that drive an external dashboard/Jenkins pipeline (fix-heading-syntax → align → ko-review → translate) and verify results with `claude` CLI.
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

# Full round1 e2e (~2h). Creates e2e/<ts> from alpha, runs the whole pipeline
# on it, merges everything into that session branch. Alpha is not touched.
bash scripts/e2e-align-and-translate.sh
# → prints "E2E_BASE_BRANCH=e2e/<ts>" as a marker for the wrapper

# Round2 — 2nd-generation drift on the same session branch (~1h)
bash scripts/e2e-translate-round2.sh --base-branch e2e/<ts>

# Override the auto-created branch (e.g., to re-run on alpha directly)
bash scripts/e2e-align-and-translate.sh --base-branch alpha
```

Common flags for both e2e scripts: `--engine api|cli`, `--model haiku|sonnet|opus`, `--tm-top-k N`, `--chunk-workers N`, `--guidelines-variant-{en,ja} <v>`. Round1 also has `--align-v2 / --no-align-v2`. Round2 requires `--base-branch` when the session branch isn't `alpha`.

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

Every e2e stage that produces a PR (align, translate) is gated by a `claude -p ... --model fable` invocation that inspects the PR's head branch in a worktree and outputs `ALIGNMENT: OK` or `ALIGNMENT: FAIL` on the last line. The wrapper checks that line to decide merge vs. leave-open. When editing prompts, keep the last-line contract intact — the scripts `grep -q '^ALIGNMENT: OK'` on it.

## Dashboard API contract

`scripts/dashboard-api.md` is the authoritative reference for the endpoints the e2e scripts call (`/api/fix-heading-syntax`, `/api/align`, `/api/ko-review`, `/api/translate`, `/api/translate/file`, `/api/jobs/<id>`). Consult it before adding new API calls or changing request bodies.
