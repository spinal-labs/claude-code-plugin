#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_root="$(cd "$script_dir/.." && pwd)"
hook_script="$plugin_root/scripts/spinal-capture-hook.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

make_hook_json() {
  local command="$1"
  python3 - "$command" <<'PY'
import json
import sys

print(json.dumps({
    "session_id": "test-session",
    "transcript_path": "/tmp/transcript.jsonl",
    "cwd": "/tmp/repo",
    "permission_mode": "default",
    "hook_event_name": "PreToolUse",
    "tool_name": "Bash",
    "tool_input": {"command": sys.argv[1]},
    "tool_use_id": "toolu_test",
}))
PY
}

assert_file_contains() {
  local path="$1"
  local needle="$2"
  if ! grep -Fq -- "$needle" "$path"; then
    printf 'expected %s to contain %s\n' "$path" "$needle" >&2
    printf '%s contents:\n' "$path" >&2
    cat "$path" >&2 || true
    exit 1
  fi
}

assert_file_absent() {
  local path="$1"
  if [ -e "$path" ]; then
    printf 'expected %s to be absent\n' "$path" >&2
    cat "$path" >&2 || true
    exit 1
  fi
}

stub_dir="$tmp_dir/bin"
mkdir -p "$stub_dir"

cat >"$stub_dir/spinal" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${SPINAL_STUB_ARGS}"
cat >"${SPINAL_STUB_STDIN}"
exit "${SPINAL_STUB_EXIT:-0}"
SH
chmod +x "$stub_dir/spinal"

export CLAUDE_PLUGIN_ROOT="$plugin_root"
export SPINAL_STUB_ARGS="$tmp_dir/args"
export SPINAL_STUB_STDIN="$tmp_dir/stdin"

PATH="$stub_dir:$PATH" "$hook_script" >"$tmp_dir/out" 2>"$tmp_dir/err" < <(make_hook_json "gh pr create --title 'Add feature'")
assert_file_contains "$SPINAL_STUB_ARGS" "capture --from-claude-hook"
assert_file_contains "$SPINAL_STUB_STDIN" "gh pr create"

rm -f "$SPINAL_STUB_ARGS" "$SPINAL_STUB_STDIN"
PATH="$stub_dir:$PATH" "$hook_script" >"$tmp_dir/out" 2>"$tmp_dir/err" < <(make_hook_json "npm test")
assert_file_contains "$SPINAL_STUB_ARGS" "capture --from-claude-hook"
assert_file_contains "$SPINAL_STUB_STDIN" "npm test"

rm -f "$SPINAL_STUB_ARGS" "$SPINAL_STUB_STDIN"
PATH="/usr/bin:/bin" "$hook_script" >"$tmp_dir/out" 2>"$tmp_dir/err" < <(make_hook_json "gh pr create")
assert_file_absent "$SPINAL_STUB_ARGS"
assert_file_contains "$tmp_dir/err" "spinal CLI not found"

rm -f "$SPINAL_STUB_ARGS" "$SPINAL_STUB_STDIN"
SPINAL_STUB_EXIT=23 PATH="$stub_dir:$PATH" "$hook_script" >"$tmp_dir/out" 2>"$tmp_dir/err" < <(make_hook_json "gh pr create")
assert_file_contains "$tmp_dir/err" "failed with exit code 23"

set +e
SPINAL_CAPTURE_HOOK_FAIL_CLOSED=1 SPINAL_STUB_EXIT=23 PATH="$stub_dir:$PATH" "$hook_script" >"$tmp_dir/out" 2>"$tmp_dir/err" < <(make_hook_json "gh pr create")
status=$?
set -e
if [ "$status" -ne 2 ]; then
  printf 'expected fail-closed mode to exit 2, got %s\n' "$status" >&2
  exit 1
fi

printf 'spinal capture hook tests passed\n'
