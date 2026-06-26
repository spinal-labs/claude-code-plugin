#!/usr/bin/env bash

# PreToolUse hook: in planning_mode=require (internal opt-in only), block the
# first mutating tool until a plan exists for the session, with an auditable
# bypass. A no-op in the default suggest/off modes. Fail-open: any problem exits
# 0 with no output so the tool call proceeds.

set -u

hook_input="$(cat)"

if [ -z "$hook_input" ]; then
  exit 0
fi

if ! command -v spinal >/dev/null 2>&1; then
  exit 0
fi

printf '%s' "$hook_input" | spinal __planning-gate
exit 0
