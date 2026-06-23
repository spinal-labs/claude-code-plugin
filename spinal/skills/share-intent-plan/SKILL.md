---
description: Externalize your implementation plan to Spinal as visual blocks before coding a non-trivial change, then claim the developer's feedback and revise. Use when about to implement a feature/change with multiple moving parts, user-visible behavior, data flow, integration behavior, or non-trivial risk. Re-submit after feedback. Skip for trivial changes (docs, one-line fixes, version bumps).
---

# Share an Intent Plan with Spinal

Before you start editing code on a non-trivial task, externalize your plan to
Spinal as a small set of **blocks**. The developer sees the plan in a web view,
comments on individual blocks in plain language ("this block is wrong, change
X"), and you pick up that feedback and revise. Spinal stores and renders the
plan; it never blocks you — you can write code at any time.

This is a shared scratchpad for intent, **not an approval gate**. Feedback is
steering, not sign-off. Never tell the developer the plan was "approved" or that
Spinal is "waiting to approve" — there is no such state.

## When to use

Use judgment — do not externalize a plan for every change:

- **Do it** when the task has multiple moving parts, user-visible behavior, data
  flow, integration behavior, or non-trivial risk — before you make meaningful
  edits.
- **Skip it** for trivial changes (docs, comments, one-line fixes, version bumps).
- **Re-submit** after the developer leaves feedback, and after any major change of
  direction — preserving block ids (see below).

## Prerequisites

- `spinal` CLI on `PATH`; `spinal login` completed; the repo connected in Spinal.
- A local branch (the plan is keyed to the repo's origin remote and HEAD SHA).

## Submitting a plan

Pipe the plan as JSON on stdin to `spinal plan submit`. Spinal resolves the
session from the repo + HEAD automatically and prints a shareable plan URL.

```bash
spinal plan submit <<'JSON'
{
  "goal": "Add SSO-only login",
  "summary": "Route the SSO callback through the existing auth service and session store.",
  "agent_note": "Initial plan before implementation.",
  "blocks": [
    {
      "id": "sso-callback-input",
      "kind": "input",
      "title": "SSO callback",
      "description": "Receive the provider callback and validate state before issuing a session.",
      "status": "current",
      "references": [{ "kind": "file", "path": "backend/routes/auth.py" }]
    },
    {
      "id": "token-issuer",
      "kind": "component",
      "title": "Session issuer",
      "description": "Reuse the existing token issuer; do not add a parallel path.",
      "status": "current",
      "references": [{ "kind": "service", "value": "auth-service" }]
    }
  ]
}
JSON
```

The command prints the plan URL (e.g. `https://app.spinal.dev/plan/<id>`). Share
that URL with the developer so they can review and comment.

### How to write blocks

- Emit **3 to 12 conceptual blocks** for most plans. Describe components, inputs,
  data stores, external dependencies, consumers, outputs, validation, and notes —
  **not** a file-by-file checklist.
- `kind` is one of: `input`, `component`, `datastore`, `external`, `consumer`,
  `output`, `validation`, `note`.
- `references` are optional and bounded: `{ "kind": "file", "path": "<relative path>" }`
  for repo files, or `{ "kind": "url"|"service"|"route"|"datastore"|"external", "value": "..." }`.
  Repo paths must be relative. Never put secrets in references or descriptions.
- **Write for a glance, not a read.** The developer scans the plan as a labelled
  map, not a document. Keep titles to a short noun phrase (aim for ≤60 chars) and
  descriptions to **one plain sentence** that says what the block does. Put detail
  in `references`, not prose. (Hard caps are 160 / 2000 chars, but brevity wins.)

### Preserving block identity across revisions

You push the **whole plan** on every submit, so block identity must be stable for
feedback to stay anchored:

- Keep a block's `id` the same when it is still conceptually the same block, even
  if its title, description, kind, or order changes.
- Use a **new** `id` only for a genuinely new concept.
- To drop a block from the plan, send it with `"status": "removed"` (do not just
  omit it — omitted blocks are kept so older feedback stays meaningful).

## Claiming developer feedback

The developer leaves comments in the plan UI and clicks **"Send to Claude"** to
release them to you. Feedback is **steering, not approval** — after you share a
plan, keep implementing; do not stop to wait for it.

**Default — keep working, pick feedback up at checkpoints.** After you submit a
plan, continue implementing. Claim whatever has been sent at natural checkpoints
— before a major change of direction, before opening the PR, and at the end of
your turn — with a single non-blocking call that returns immediately:

```bash
spinal plan feedback
```

It prints any pending feedback as JSON and returns right away (an empty list when
there is none). A good message to the developer right after submitting:

> I shared the intent plan here: <plan-url>. I'll keep implementing and will pick
> up any feedback you send from the plan UI.

Never say "waiting for approval", "waiting for sign-off", or "I won't code until
the plan is approved" — there is no such gate.

**Explicit wait — only when the developer asked you to wait.** If, and only if,
the developer said something like "make a plan and wait for my feedback before
coding", block on their feedback so their "Send to Claude" click is what resumes
you — they never touch the terminal:

```bash
spinal plan feedback --wait
```

This polls until the developer sends feedback, then prints it as JSON and returns
(it gives up after a timeout, default 15m; Ctrl-C to stop). Use it **only** for
the explicit "wait before coding" request — never as the default after a submit.

Both forms print pending feedback as JSON (oldest first) and mark it delivered:

```json
{
  "plan_id": "…",
  "revision": 1,
  "feedback": [
    { "id": "…", "block_id": "sso-callback-input", "body": "SSO only; do not add password login.", "created_revision": 1, "created_at": "…" }
  ]
}
```

When `block_id` is set, the comment is about that block; when it is `null`, it is
about the plan as a whole. Incorporate the feedback, then **re-submit the revised
plan** (preserving ids) with `spinal plan submit` so the developer sees that the
plan changed after their comment. When you re-submit, set `base_revision` to the
latest `revision` Spinal gave you (from your last submit or feedback claim); if
the plan moved on since then, Spinal rejects the stale overwrite with a conflict
so you re-claim the newer feedback first.

## Linking the plan to your PR

You do **not** need to add the link yourself. When you open the PR with
`gh pr create`, the Spinal plugin automatically appends the intent-plan link to the
PR description (a `🧭 Intent plan: <url>` line) so reviewers can click through.

If you ever need the link directly (outside the plugin, or for a manual note), get
the canonical link for the current repo + HEAD with `spinal plan url`.

## The loop

1. Externalize intent → `spinal plan submit`.
2. Share the plan URL with the developer and **keep implementing**.
3. Check feedback at checkpoints → `spinal plan feedback` (one-shot, non-blocking).
   Use `spinal plan feedback --wait` only if the developer explicitly asked you to
   wait before coding.
4. If feedback changes direction, revise and re-submit, preserving block ids.
5. Open the PR with `gh pr create` — the plugin auto-appends the intent-plan link.

Treat feedback as steering, not approval. Spinal never holds you: share the plan
and keep coding. The Stop hook claims any feedback the developer sent before you
finish your turn, so nothing is lost if you don't poll yourself.
