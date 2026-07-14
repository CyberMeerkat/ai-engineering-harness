# Compact — Context Continuation Snapshot

You are generating a **compact continuation prompt** that captures the full state needed to resume this conversation in a fresh context window. This is critical for preserving work continuity.

## Instructions

1. **Analyse the conversation** — review the full history of what was discussed, decided, attempted, and completed.

2. **Generate a structured snapshot** with these sections:

### Output format

Write the snapshot to a file at `.claude/compact/<timestamp>.md` (create the directory if needed) AND display it to the user. Use this exact structure:

```markdown
## Context: <Project Name> — <Brief Task Description>

**Branch:** `<current git branch>`
**Date:** <today's date>

### Train of Thought

A concise decision arc — how the session started, what pivots happened, and where it ended. Written as a numbered sequence of decisions, not a narrative. Each line = one decision or pivot. This is the "why" chain that a new session needs to understand the reasoning, not just the output.

Format:
1. **Started:** <what the user asked for and why>
2. **Decided:** <first major decision and its rationale>
3. **Decided:** <next decision — especially if it changed direction>
4. **Encountered:** <any problem that altered the plan>
5. **Resolved:** <how the problem was solved>
6. **Decided:** <subsequent decisions...>
7. **Ended:** <where the work stopped and what's next>

Rules:
- Max 10 entries. If more happened, keep only the decisions that a new session MUST know.
- Skip routine steps (reading files, running tests). Only capture direction changes.
- Each entry is 1 line. If it needs 2 lines, it's two decisions.
- Include the "why" — "Decided to use profiles instead of removing services — preserves local dev compatibility" not just "Used profiles."

### Completed
<Bulleted list of everything accomplished this session, with commit hashes where applicable>

### Current objective
<Numbered list of the immediate next steps that were about to be executed or discussed>

### Key state
<Any critical runtime state: tokens, URLs, file paths, environment details, error messages, or configuration that would be needed to continue>

### Key references
<File paths, endpoints, credentials (reference only, not values), and resources relevant to the current task>

### Doc Impact
<Flag any changes that affect architecture, features, or system behaviour — not bug fixes or minor edits>

Format:
- [ ] `<file>` — <what changed and why it needs updating>
- [x] `<file>` — <already updated this session>

If ALL doc impact items are [x] (already handled), write: "All doc impacts addressed this session."

If any are [ ] (not yet updated), write a WARNING:
> ⚠ Architectural changes were made but docs are stale. Before compacting, consider updating the flagged files or noting them as tech debt.

Files to always check when flagging doc impact:
- `CLAUDE.md` — project overview, commands, rules, service URLs
- `docs/architecture/PROJECT-ARCHITECTURE.md` — container architecture, tech stack, production environment
- Memory files — if the change invalidates a stored memory, flag it

### Overall objective
<1-2 sentences on the broader goal this work contributes to>
```

3. **Quality rules:**
   - Be specific — include commit hashes, file paths, endpoint URLs, branch names, exact error messages
   - Include enough context that a fresh Claude instance with NO prior conversation history can pick up exactly where you left off
   - Do NOT include secrets or passwords — reference them by name (e.g., "admin credentials from HANDOFF.md")
   - Preserve decision rationale — if something was tried and rejected, note why
   - If there are pending git changes (uncommitted, unpushed), call that out explicitly
   - **Train of Thought must be under 10 entries** — dense and decisive, not a diary
   - **Total snapshot must be under 500 words** — dense and scannable, not verbose

4. **After generating**, tell the user:
   > Snapshot saved. You can start a new conversation and paste this as your opening message, or I can continue from here.
