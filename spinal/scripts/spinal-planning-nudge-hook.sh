#!/usr/bin/env bash

# UserPromptSubmit hook: emit a deterministic, non-blocking planning nudge for
# non-trivial prompts (planning_mode=suggest). Fail-open: any problem exits 0
# with no output so the prompt proceeds unchanged.

set -u

hook_input="$(cat)"

if [ -z "$hook_input" ]; then
  exit 0
fi

if ! command -v spinal >/dev/null 2>&1; then
  exit 0
fi

printf '%s' "$hook_input" | spinal __planning-nudge
exit 0
