# claude-code-plugin

Home of the **`spinal`** Claude Code plugin (PR/MR session context capture,
local preflight review, and finding validation).

This repo is a plugin **source**, not a marketplace. Install the `spinal` plugin
from the single Spinal Labs marketplace:

```
/plugin marketplace add spinal-labs/spinal-marketplace
/plugin install spinal@spinal-marketplace
```

The plugin lives in [`spinal/`](./spinal); `spinal-marketplace` references it via a
`git-subdir` source.
