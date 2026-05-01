#!/usr/bin/env bash

set -u

diagnostic() {
  printf 'spinal capture hook: %s\n' "$*" >&2
}

hook_input="$(cat)"

if [ -z "$hook_input" ]; then
  diagnostic "empty hook input; PR creation will continue"
  exit 0
fi

if ! command -v spinal >/dev/null 2>&1; then
  diagnostic "spinal CLI not found on PATH; run 'spinal capture' manually after creating the PR"
  exit 0
fi

printf '%s' "$hook_input" | spinal capture --from-claude-hook
status=$?
if [ "$status" -eq 0 ]; then
  exit 0
fi

diagnostic "spinal capture failed with exit code $status; PR creation will continue"
if [ "${SPINAL_CAPTURE_HOOK_FAIL_CLOSED:-}" = "1" ]; then
  exit 2
fi
exit 0
