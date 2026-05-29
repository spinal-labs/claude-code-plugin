---
description: Run Spinal's review locally with `spinal preflight` on non-trivial changes before opening a PR/MR, so findings are fixed before the bot comments. Use when about to open a PR/MR with substantial changes, or when asked to review the local diff before pushing. Skip for trivial changes.
---

# Preflight Before a PR/MR

`spinal preflight` runs the same review engine that comments on the PR/MR, but
against the **local diff**, before you open anything. Running it first means real
findings get fixed locally instead of posted on the MR — and the captured session
context tells the MR review what was already handled, so it does not re-flag it.

This is a developer convenience, not a gate: it does not satisfy CI or merge
requirements, and its result must never be relayed as if it does.

## When to use

Use judgment — do not run it on every PR:

- **Run it** when about to open a PR/MR with substantial or risky changes, or when
  the user asks for a local review before pushing.
- **Skip it** for trivial changes (docs, comments, one-line fixes, version bumps).
- **Do not re-run** it for a HEAD you already reviewed this session, and do not
  block opening the PR/MR on it — offer the findings, let the user decide.

## Prerequisites

- `spinal` CLI on `PATH`; `spinal login` completed; repo connected in Spinal.
- A local branch with committed changes against the base branch.

## How to run

```bash
spinal preflight --base <base-branch> --json
```

- `--json` is the stable machine contract — prefer it and parse the result.
- `--run "<cmd>"` runs a validation command (tests, typecheck) first and feeds the
  result into the review; repeat for several.
- `--mode security,tests,architecture,cleanup,performance` focuses the review.
- `--apply <ordinal>` applies a finding's suggested patch when one is offered;
  review the change with `git diff` before committing.

`spinal critique` is the same command; `preflight` just reads well as a pre-PR step.

## Relaying results

- Report findings by severity; a clean preflight is a local signal, not CI/merge
  approval.
- Address blockers locally (edit, or `--apply <ordinal>` for mechanical fixes),
  then let the user open the PR/MR. The capture hook records the session so the
  MR review skips what you already handled.
