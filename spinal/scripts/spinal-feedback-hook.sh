#!/usr/bin/env bash

# Stop hook: when the agent finishes a turn, claim any developer feedback the
# developer sent from the Spinal plan UI and, if there is any, block the stop so
# the agent addresses it and re-submits the revised plan. Quiet (allows stop)
# when there is no pending feedback, no plan, or the CLI is unavailable.

set -u

diagnostic() {
  printf 'spinal feedback hook: %s\n' "$*" >&2
}

# Consume the Stop hook payload from stdin (not needed, but keep the pipe clean).
cat >/dev/null 2>&1 || true

if ! command -v spinal >/dev/null 2>&1; then
  diagnostic "spinal CLI not found on PATH; skipping feedback check"
  exit 0
fi

feedback_json="$(spinal plan feedback 2>/dev/null)"
if [ $? -ne 0 ] || [ -z "$feedback_json" ]; then
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  diagnostic "python3 not found; cannot parse feedback, allowing stop"
  exit 0
fi

SPINAL_FEEDBACK_JSON="$feedback_json" python3 <<'PY'
import json
import os
import sys

try:
    data = json.loads(os.environ.get("SPINAL_FEEDBACK_JSON", "") or "{}")
except Exception:
    sys.exit(0)

items = data.get("feedback") or []
if not items:
    sys.exit(0)

lines = []
for fb in items:
    block_id = fb.get("block_id")
    where = f"block '{block_id}'" if block_id else "the plan overall"
    lines.append(f"- On {where}: {fb.get('body', '').strip()}")

reason = (
    "The developer sent feedback on your Spinal intent plan. Incorporate it, then "
    "re-submit the revised plan with `spinal plan submit` (preserve block ids so "
    "the feedback stays anchored):\n" + "\n".join(lines)
)

rev = data.get("revision")
if rev is not None:
    reason += (
        f"\n\nThe current intent plan is at revision {rev}. When you re-submit the "
        f"revised plan, set base_revision to {rev} so Spinal can detect a stale overwrite."
    )

print(json.dumps({"decision": "block", "reason": reason}))
PY

exit 0
