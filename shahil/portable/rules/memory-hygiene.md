# Memory Hygiene

> Universal rule. Loaded every session via ~/.claude/rules/.
> Pairs with the auto-memory system (per-project memory directory).

## The split

Every project's memory directory contains two index files:

- **`MEMORY.md`** — active rules, current conventions, in-flight feedback. **Loaded into every message.** Cap at ~80 lines.
- **`MEMORY.archive.md`** — historical snapshots, integrated/retired learnings, completed initiatives. **Never auto-loaded.** Fetched only on explicit request (`/learned --history` or direct read).

Individual memory files (`feedback_*.md`, `project_*.md`, `reference_*.md`) are NOT auto-loaded — they're indexed in one of the two files and read on demand.

## What goes where

| Type | Goes in | Why |
|---|---|---|
| Active feedback rule the user just gave you | `MEMORY.md` | Needs to influence future replies |
| Project convention currently in force | `MEMORY.md` | Needs to influence future replies |
| Reference pointer (Notion DB, Slack channel) | `MEMORY.md` | Needs to influence future replies |
| User profile / role | `MEMORY.md` | Needs to influence future replies |
| Snapshot of state at a point in time (e.g., "X was complete on date Y") | `MEMORY.archive.md` | Historical record, not load-bearing |
| Learning that has been integrated into a skill or rule | `MEMORY.archive.md` | Skill rule is the enforcement; memory is just provenance |
| Open action item / TODO not yet a rule | `MEMORY.archive.md` (Open action items section) | Aspirational, not active enforcement |

## When to demote (move from MEMORY.md → archive)

Move an entry from MEMORY.md to MEMORY.archive.md when:
- It's been integrated into a skill rule or `learned-rules.md` (the skill is now the source of truth)
- It refers to a completed feature/sprint (no longer in flight)
- It's a point-in-time snapshot ("As of date X, ...") rather than a forward-looking rule
- MEMORY.md exceeds ~80 lines

## When to promote (move from archive → MEMORY.md)

Move from archive back to active when:
- A snapshot becomes load-bearing again (e.g., a deprecated rule is reactivated)
- An open action item becomes a fresh enforceable rule

## Index format

Both files use one-line entries:
```markdown
- [Title](filename.md) — one-line hook (≤120 chars)
```

The link target is the per-memory file (e.g., `feedback_no_stripe.md`), which holds the full content. The hook is what shows up in always-loaded context — make it specific enough that future-Claude knows whether to load the full file.

## How `/learned --integrate` interacts

After a learning is integrated into a skill or rule file:
1. The source memory file is deleted (skill rule is canonical)
2. A pointer is added to MEMORY.archive.md under "Integrated rules" with the date and target
3. MEMORY.md is unaffected (the active index)

This keeps the always-loaded MEMORY.md lean while preserving traceability of where each rule came from.

## FTS5-backed retrieval (post-2026-05-07)

Project-level learned rules live OFF the auto-load path at `<project>/.claude/learned/learned-rules.md` (not `.claude/rules/`). They are indexed into the **context-mode SQLite FTS5** store and surfaced on-demand via `ctx_search` instead of inlined into every message.

### Source naming convention

| Source label | What it indexes |
|---|---|
| `learned-project:<key>` | One project's `.claude/learned/learned-rules.md` (key from `~/.claude/learned-projects.json`) |
| `learned-global` | `~/.claude/rules/learned-global.md` (≤80 lines, always-loaded) |
| `learned-skill:<name>` | The `## Learned Rules` section of `~/.claude/commands/<name>.md` |

### Drift policy

`.md` is canonical. The FTS5 index is a rebuildable cache. If the DB is corrupted or behaviour diverges, run `/learned --reindex --all` to regenerate from the `.md` files in seconds. Never edit the DB directly.

### When to ctx_search vs read flat

- **`ctx_search`** is the default. Use it on any domain-trigger word (Prisma, deploy, port, OpenRouter, tenantId, …) to surface relevant rules from current project + global + skills in one call. Cost: ~200–500 tokens per query vs ~1,800+ tokens for inlining a project's full rules file.
- **Read the flat file directly** (`cat <project>/.claude/learned/learned-rules.md`) when you need exhaustive context — e.g. during an audit or `/learned --decay` review.

### Fallback when context-mode is unavailable

`/learned --search` and the SessionStart reindex hook degrade gracefully. The `--search` flag falls back to:
```
grep -rn "<query>" .claude/learned/ ~/.claude/rules/learned-global.md ~/.claude/commands/
```
The hook silently skips. The always-loaded `learned-global.md` still loads via Claude Code's native `~/.claude/rules/*.md` discovery — global rules survive even total context-mode failure.
