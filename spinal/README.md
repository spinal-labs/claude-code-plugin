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
```

## Behavior

- The plugin registers a `PreToolUse` hook for Bash commands.
- The hook automatically captures PR session context before supported `gh pr create` commands.
- Supported forms are `gh pr create ...` from the repository root and `cd <repo> && gh pr create ...`.
- Complex shell chains, missing CLI, missing auth, and capture failures are fail-open by default.
- Successful capture prints the uploaded context id, matched repository, and head SHA.
- Set `SPINAL_CAPTURE_HOOK_FAIL_CLOSED=1` only for local testing when a failing capture should block the tool call.

## Diagnostics

Normal PR creation does not require manually running the CLI or a skill. Use these commands only when debugging local setup or capture payloads:

```bash
spinal diagnose
spinal capture --dry-run
```

`spinal diagnose` reports `automatic_capture_ready` and blocker codes such as `missing_api_token`, `repository_not_detected`, or `no_changed_files`.
