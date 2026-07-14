---
description: "Context briefing — generates a portable context block from triage, active EP, and sprint scope for subagent prompts or new sessions"
argument-hint: [--full] [--oneliner]
---

# Brief

You generate a portable context block that captures the current project state. This is the "goal ancestry" that subagents need to understand the "why" behind their work.

## Core Mindset

When you spawn a subagent or start a new session, it has zero context. The brief solves this: a concise, paste-ready block that orients any agent in seconds. Think of it as the elevator pitch for the current sprint state.

## How It Works

Read these files (in parallel):
- `.claude/state/triage.md` — sprint status, active scope, gate verdicts
- `.claude/state/engineering-plan.md` — active EP details
- `.claude/state/dev-manager.md` — delivery tracking, risks
- `.claude/state/product-owner.md` — priorities
- `CLAUDE.md` — project overview (first 20 lines only)

## Output Format

### Default (no flags)

```
## Project Brief — {date}

**Project:** {name} — {one-line description}
**Sprint:** S{N} — {sprint theme}
**Branch:** {current branch}
**Active EP:** {EP-XXX} — {title} ({status})

### Current Focus
{2-3 sentences: what we're building right now and why}

### Key Decisions
- {decision 1 — from triage or EP}
- {decision 2}

### Blockers/Risks
- {risk or blocker, if any — "None" if clear}

### Architecture Note
{1 sentence on relevant architecture pattern, e.g. "API uses provider pattern for swappable services"}
```

### `--full` flag
Include all of the above plus:
- Active tasks from dev-manager
- Backlog priorities from product-owner  
- Recent commits (last 5 from `git log --oneline -5`)
- State file freshness (which are stale)

### `--oneliner` flag
Single paragraph, max 100 words. For inline subagent prompts:

```
{{PROJECT}} is a <one-line product description> (<tech stack>). Sprint {N} is focused on {theme}. Active EP: {EP-XXX} ({status}). Current branch: {branch}. Key constraint: {one constraint}.
```

## Rules

1. **Never exceed 200 words** for default output. Subagents need orientation, not a novel.
2. **Always include the branch name** from `git rev-parse --abbrev-ref HEAD`.
3. **Always include the active EP** — this is the "why" that Paperclip's goal ancestry provides.
4. **Dates must be absolute** — never "yesterday" or "last week".
5. **No recommendations.** Brief is read-only context, not advice. Save opinions for `/status`.
