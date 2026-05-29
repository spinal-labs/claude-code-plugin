# Spinal Claude Code Plugin

The Spinal Claude Code plugin captures local PR/MR session context before you open a PR/MR — `gh pr create` (GitHub), `glab mr create` (GitLab), or `git push` (the GitLab web-UI flow) — and sends it through the installed `spinal` CLI, so the PR/MR review skips what you already handled locally.

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

- The plugin registers `PreToolUse` hooks for Bash commands.
- The hooks automatically capture PR/MR session context before supported `gh pr create`, `glab mr create`, and `git push` commands.
- Supported forms are the command from the repository root and `cd <repo> && <command> ...`.
- Complex shell chains, missing CLI, missing auth, and capture failures are fail-open by default.
- Successful capture prints the uploaded context id, matched repository, and head SHA.
- Set `SPINAL_CAPTURE_HOOK_FAIL_CLOSED=1` only for local testing when a failing capture should block the tool call.

## Skills

- **prepare-pr-session-summary** / **capture-pr-context** — enrich or diagnose the automatic session-context capture before you open a PR/MR.
- **preflight-before-pr** — run `spinal preflight` locally on non-trivial changes before opening a PR/MR, so findings are fixed before the review comments. Judgment-based: Claude runs it for substantial changes, skips trivial ones, and never blocks opening the PR/MR on it.
- **validate-pr-findings** — reproduce a reviewed PR's findings locally with `spinal validate <PR#>`. Claude Code selects it after a PR has a completed Spinal review. It calls the CLI with `--json` (stable contract: an `outcome` of `validated`/`skipped`/`dry_run`/`needs_opt_in`, exit `0` = ran), runs the generated test on the host (`--yes`) or in a container (`--sandbox --sandbox-image <img>`), and relays the result as developer preflight only — never as a CI or merge gate.

## Diagnostics

Normal PR creation does not require manually running the CLI or a skill. Use these commands only when debugging local setup or capture payloads:

```bash
spinal diagnose
spinal capture --dry-run
```

`spinal diagnose` reports `automatic_capture_ready` and blocker codes such as `missing_api_token`, `repository_not_detected`, or `no_changed_files`.
