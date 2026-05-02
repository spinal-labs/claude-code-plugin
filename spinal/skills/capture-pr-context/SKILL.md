---
description: Diagnose Spinal's automatic PR session-context capture hook.
disable-model-invocation: true
---

# Capture PR Context

Use this helper only when automatic capture did not run, the hook reported a diagnostic, or support needs to preview the captured payload. Normal PR creation should not require manually invoking this skill or running `spinal capture`.

Before running `gh pr create`, write a single JSON object to `${TMPDIR:-/tmp}/spinal-session-summary.json` with these fields only:

```json
{
  "stated_goal": "one short sentence describing what this PR does",
  "non_goals": ["explicit non-goals only, max 5, each <= 200 chars"],
  "validation_summary": {
    "passed": 0,
    "failed": 0,
    "last_failure": null
  },
  "excerpts": ["up to 3 short user-stated intent quotes, each <= 300 chars"]
}
```

Use only what is actually in this session. Do not fabricate values. If no validation command ran, set `passed` and `failed` to `0` and `last_failure` to `null`.

Prerequisites:

- The `spinal` CLI is installed and available on `PATH`.
- `spinal login` has completed, or `spinal login --api-base-url <url> --token <token>` has stored a manual CLI token.
- The current git repository is connected in Spinal.

For diagnostics, run these commands from the repository root:

```bash
spinal login
spinal diagnose
spinal capture --dry-run
```

For automatic capture, verify the plugin hook is installed with `/hooks` and that `spinal` is on `PATH`. The hook is fail-open by default, so PR creation should proceed even when capture fails.

If `spinal diagnose` shows `has_api_token: false`, run `spinal login` before retrying capture. If `repository_detected` is false, rerun the command from inside the git repository that will be used for the PR.
