---
description: Reproduce a reviewed PR's findings locally with `spinal validate`. Use after a PR has a completed Spinal review, to run a Spinal-generated test against the working tree (host or sandboxed container) before relying on a finding.
---

# Validate PR Findings Locally

`spinal validate <PR#>` asks Spinal to generate a test that reproduces a finding
from that PR's completed review, runs it locally, and reports a classification.
It is **developer preflight**: it does not satisfy CI validation or merge gates,
and its result must never be relayed as if it does.

## When to use

- A PR exists and has a **completed Spinal review** (status `reviewed`).
- The local checkout is at the **same commit** that was reviewed (the backend
  rejects a mismatch with a 404).
- You want to confirm a finding is real before acting on it.

Do not use it as a merge gate, a CI substitute, or on un-reviewed code.

## Prerequisites

- `spinal` CLI on `PATH`; `spinal login` completed; repo connected in Spinal.
- An open PR for the current branch with a completed review.

## How to run

Always pass `--json` — it is the stable machine contract. Choose an execution mode:

- **Sandbox (preferred when an image with the repo's toolchain is available, e.g.
  the team's CI image):** runs in a container, no network, repo mounted.
  ```bash
  spinal validate <PR#> --json --sandbox --sandbox-image <image>
  ```
- **Host:** runs the generated test directly on the machine. Requires explicit
  opt-in because it executes Spinal-generated code locally.
  ```bash
  spinal validate <PR#> --json --yes
  ```
- **Inspect only (no execution):**
  ```bash
  spinal validate <PR#> --json --dry-run
  ```

Without `--yes` or `--sandbox`, the command does not execute anything and returns
`{"outcome":"needs_opt_in"}`.

## Output contract (`--json`)

Exactly one JSON object on stdout. Exit code `0` means the command ran (read the
result from JSON); non-zero means it failed to run (auth, network, no review,
docker missing, bad args) — the reason is on stderr.

`outcome` is one of:

- `validated` — the test ran. Fields:
  - `classification`: one of
    - `passed` — the generated test passed; the finding was **not** reproduced here.
    - `locally_reproduced` — the test reproduced the finding locally. Strong signal it is real; address it before merge.
    - `infra_failed` — could not run the test in this environment. Not a pass or a fail.
    - `test_generation_failed` — the generated test did not run (generation issue). Not a pass or a fail.
  - `error_signature` (nullable), `run_id`, `worktree_dirty` (bool), `sandbox` (bool).
- `skipped` — no runnable test could be generated; see `skip_reason`.
- `dry_run` — `test_command`, `validation_mode`, and `files` (each `file_path` + `content`).
- `needs_opt_in` — re-run with `--yes` or `--sandbox`.

## Relaying results

- Report the verdict, never inflate it: a `passed`/`locally_reproduced` result is
  a **local preflight signal only**, not CI or merge approval.
- If `worktree_dirty` is `true`, say so — the result reflects the uncommitted
  working tree, not the committed head.
- Treat `infra_failed` / `test_generation_failed` as "could not validate," not as
  a pass or a failure.
