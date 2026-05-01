# Spinal Claude Code Plugin

The Spinal Claude Code plugin captures local PR session context before simple `gh pr create` commands and sends it through the installed `spinal` CLI.

## Requirements

- Claude Code with plugin support.
- `spinal` CLI installed on `PATH`.
- `spinal login` completed, or a manual token stored with `spinal login --api-base-url <url> --token <token>`.
- The repository is connected in Spinal.

## Install From The Spinal Marketplace

```text
/plugin marketplace add spinal-labs/claude-code-plugin
/plugin install spinal@spinal
```

For local development from this repository:

```bash
claude --plugin-dir ./release/claude-code/spinal
```

Inside Claude Code:

```text
/hooks
/spinal:capture-pr-context
```

## Behavior

- The plugin registers a `PreToolUse` hook for Bash commands.
- The hook captures only simple `gh pr create` commands.
- Complex shell chains, missing CLI, missing auth, and capture failures are fail-open by default.
- Set `SPINAL_CAPTURE_HOOK_FAIL_CLOSED=1` only for local testing when a failing capture should block the tool call.

## Manual Capture

Run from the repository root:

```bash
spinal diagnose
spinal capture --dry-run
spinal capture
```
