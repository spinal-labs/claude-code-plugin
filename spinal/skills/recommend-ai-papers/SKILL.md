---
description: Recommend which AI papers to read for a feature you are building, from the local spinal-knowledge markdown archive. Use when the user asks "what papers should I read" for a feature, capability, or research area (agents, evals, MCP, memory, retrieval, coding agents, RL, verification). Reads markdown directly; no index or network needed.
---

# Recommend AI Papers

Return a ranked shortlist of papers to read from the local `spinal-knowledge`
markdown archive, biased toward implementation usefulness over academic completeness.

## Resolve the knowledge root

1. If `SPINAL_KNOWLEDGE_ROOT` is set, use it.
2. Otherwise use `/Users/thejusri/sourcecode/spinal-labs/spinal-knowledge`.

```bash
ROOT="${SPINAL_KNOWLEDGE_ROOT:-/Users/thejusri/sourcecode/spinal-labs/spinal-knowledge}"
```

Paper files live at `$ROOT/<YYYY-MM-DD>/papers/<slug>.md`. Each has an H1 title,
`Published:` / `Source Article:` / `Paper:` / `Tags:` lines, and `## Summary`,
`## Conclusion`, `## Notes` sections.

## Expand the request into search terms

Take the user's feature description and expand it into terms + tags:

- agent feature -> `agents`, `tooling`, `planning`, `memory`
- evaluation feature -> `evaluation`, `verification`, `rl`
- MCP feature -> `mcp`, `architecture`, `tooling`
- coding-agent feature -> `coding`, `agents`, `evaluation`
- retrieval or memory feature -> `retrieval`, `memory`

Always also search the literal salient nouns from the request.

## Search the markdown

Use ripgrep over the archive. Search titles/tags first, then bodies:

```bash
rg -l -i -e 'mcp' -e 'agents' "$ROOT" --glob '*/papers/*.md'
rg -i --heading -e 'mcp' "$ROOT" --glob '*/papers/*.md'
```

## Rank

- Matches in the H1 title or `Tags:` line rank above body-only matches.
- More distinct query-term hits ranks higher.
- Newer `Published:` date is a **weak tiebreaker only**, never the primary signal.
- Prefer papers whose summary/conclusion describe something buildable.

Keep the top 5–8.

## Output

For each recommended paper, in reading order:

1. **Title** — one line on why it's relevant to *this* feature.
2. Paper link (`Paper:` line) and Source Article link (`Source Article:` line).
3. Publication date folder (`YYYY-MM-DD`).

End with a one-line suggested reading order and a note if the archive looks thin
for the topic (so the user knows to widen the query or curate tags).
