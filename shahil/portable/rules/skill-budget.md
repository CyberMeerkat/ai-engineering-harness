# Skill Budget

> Universal rule. Loaded every session.
> Caps on-demand context cost when skills are invoked.

## The rule

Skills don't cost per-message tokens (they're on-demand), but a single `/skill` invocation pulls the entire dispatcher into the conversation and keeps it there until `/clear` or `/compact`. A 35 KB skill silently steals 8,750 tokens that you can't see in `ctx:` until you've already paid.

### Hard cap

- **Skill dispatcher: ≤15 KB** (~3,750 tokens)
- **Reference doc per topic: any size**, lives in `~/.claude/agent_docs/<skill>/`
- **Loaded only when dispatcher decides** — `Read('~/.claude/agent_docs/deploy/rules.md')` is explicit

### When you must split

If a skill body exceeds 15 KB:
1. Extract reference content into `~/.claude/agent_docs/<skill>/`:
   - `rules.md` — learned rules accumulated by `/learned --integrate`
   - `procedures.md` — step-by-step playbooks
   - `reference.md` — config flags, command reference
2. Dispatcher keeps:
   - Frontmatter + 1-paragraph description
   - Trigger conditions ("when to use")
   - Index of reference docs with one-line summary each
   - Usage examples (most common 3-5 invocations)
3. Dispatcher loads reference docs as needed:
   ```markdown
   For deployment rules and learned constraints, see `~/.claude/agent_docs/deploy/rules.md`.
   ```

## Worked example: /deploy split

Before:
- `~/.claude/commands/deploy.md` — 34.7 KB monolith (45 learned rules + procedures + flags)

After:
- `~/.claude/commands/deploy.md` — ~3 KB dispatcher (when-to-use, flags index, one-line pointers)
- `~/.claude/agent_docs/deploy/rules.md` — 25 KB (45 rules)
- `~/.claude/agent_docs/deploy/procedures.md` — 5 KB (deployment playbooks)
- `~/.claude/agent_docs/deploy/diagnostics.md` — 2 KB (recovery flows)

Dispatcher reads rules.md only when planning a deploy. Diagnostics loads only on `/deploy --diagnose`. Procedures loads only when running a full deploy.

Net: a `/deploy --status` invocation pulls 3 KB instead of 35 KB.

## Detection

`/token-audit --enforce` flags every skill >15 KB and offers to apply the split.

## Exceptions

A skill can exceed 15 KB if every section is needed on every invocation (rare). If you think this applies, justify it in the dispatcher header. Default assumption: split.
