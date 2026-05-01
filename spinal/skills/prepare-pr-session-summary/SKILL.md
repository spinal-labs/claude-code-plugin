---
description: Write Spinal's session-summary JSON immediately before creating a pull request with gh pr create.
---

# Prepare PR Session Summary

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

Use only what is actually in this session. Do not fabricate values. If no validation command ran, set `passed` and `failed` to `0` and `last_failure` to `null`. Then proceed with the PR creation command.
