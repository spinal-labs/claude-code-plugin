#!/usr/bin/env bash

# PostToolUse hook: after `gh pr create`, append the Spinal intent-plan link to the
# new PR's description automatically, so reviewers can click through to the stated
# intent. Quiet no-op when there is no PR URL in the output, no plan for this
# branch, or the gh/spinal CLIs are unavailable. Idempotent.

set -u

diagnostic() {
  printf 'spinal pr-link hook: %s\n' "$*" >&2
}

payload="$(cat)"

if ! command -v spinal >/dev/null 2>&1 || ! command -v gh >/dev/null 2>&1; then
  exit 0
fi

# The PR URL printed by `gh pr create` shows up in the tool output.
pr_url="$(printf '%s' "$payload" | grep -oE 'https://github\.com/[A-Za-z0-9._/-]+/pull/[0-9]+' | head -1)"
if [ -z "$pr_url" ]; then
  exit 0
fi

plan_url="$(spinal plan url 2>/dev/null)"
case "$plan_url" in
  http*) ;;
  *) exit 0 ;;  # no intent plan for this branch
esac

current_body="$(gh pr view "$pr_url" --json body -q .body 2>/dev/null)" || exit 0
case "$current_body" in
  *"$plan_url"*) exit 0 ;;  # already linked
esac

new_body="${current_body}"$'\n\n'"🧭 Intent plan: ${plan_url}"
if gh pr edit "$pr_url" --body "$new_body" >/dev/null 2>&1; then
  diagnostic "appended intent plan link to $pr_url"
fi
exit 0
