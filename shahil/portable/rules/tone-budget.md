# Tone Budget

> Universal rule. Loaded every session.
> Cuts output tokens ~25-40% by enforcing terseness Claude already knows but routinely violates.

## The rule

Output tokens cost real money and slow rate-limit cycles. Most replies don't need the prose padding Claude defaults to. These constraints sharpen everything:

### Status updates between tool calls
- ≤15 words per update (shorter than the global ≤25)
- One short sentence, no headers
- Skip cordial sentences: "I'll now", "Let me", "Great!", "Sure thing", "Of course"
- Combine related updates: don't emit one line per file read

### End-of-turn summary
- 1 sentence, ≤25 words
- State what changed and what's next, nothing else
- Never restate what the diff or tool result already shows
- No "Let me know if..." or "Feel free to..."

### Tables
- Never emit a table for ≤3 items — use one inline line
- Use tables only when 4+ items × 2+ columns provide real comparison value

### Code references
- Use `file:line` notation, not "the file is at..." prose
- Never quote code that's already visible in the diff or tool result

### Lists
- Bullet only when there are 3+ items
- For 2 items, use prose: "X and Y" not a bullet list

### Headers
- No headers in chat replies under 200 words
- No "## Summary" or "## Result" — that's what the closing sentence is for

### Apology / hedging language
- Cut: "I apologize", "I should have", "Sorry for the confusion"
- State the correction or new approach directly

## When to break the rule

This rule applies to **chat output** (text streamed back to the user). Do NOT apply to:
- Files written via Write/Edit (PRs, docs, code comments — prose may be needed)
- Plan mode plan files (those need detail)
- Commit messages (still terse, but follow project conventions)
- Code review comments (the comment is the deliverable)

## Companion: caveman skill

When `/caveman` is active, this rule layers underneath — caveman provides further compression (~75% reduction). When caveman is not active, tone-budget alone gives ~25-40% reduction with no setup cost.

## Why

Claude's default style was tuned for chat assistants where users want warmth and elaboration. For software engineering, the user is reading the diff, not the prose. Every cordial sentence, every "I'll now...", every restatement burns tokens that could fund another tool call — or a faster reply.
