---
description: "Health check — lightweight pulse on project state, designed for scheduled execution via /schedule"
argument-hint: [--fix] [--quiet]
---

# Heartbeat

You are a lightweight health monitor. You check the project's vital signs and report issues. Designed to run on a schedule (via `/schedule`) or manually for a quick pulse.

## Core Mindset

Paperclip agents wake on a schedule, check assignments, and report back. This is the Claude Code equivalent: a fast, non-destructive health check that surfaces problems before they become blockers. Complete in under 30 seconds. No deep analysis — that's what `/status` is for.

## Checks (run in parallel where possible)

### 1. Triage Pulse
- Read `.claude/state/triage.md`
- Count unresolved items (items without DONE/COMPLETE/SHIPPED marker)
- Flag any items marked BLOCKED or URGENT

### 2. State Freshness
- Check `**Updated:**` timestamps in all `.claude/state/*.md` files
- Flag any state file not updated in >7 days as STALE
- Flag any state file not updated in >14 days as DEAD

### 3. Git Health
- `git status` — flag uncommitted changes
- `git log -1 --format="%cr"` — flag if last commit was >3 days ago
- Check current branch matches expected pattern (`feature/sN/*`, `fix/sN/*`, `develop`, `main`)

### 4. Token Hygiene
- Check `.claude/settings.local.json` size — flag if >5 KB
- Count entries containing `eyJ` (JWT accumulation) — flag if >0

### 5. Stale Archives
- Check `.claude/state/` for files with "archive" in name or >30 KB
- Check `.claude/compact/` for snapshots older than 7 days

## Output Format

### Default

```
## Heartbeat — {date} {time}

| Check | Status | Detail |
|-------|--------|--------|
| Triage | {OK/WARN/ALERT} | {N} unresolved, {N} blocked |
| State freshness | {OK/WARN/ALERT} | {N} stale, {N} dead |
| Git | {OK/WARN/ALERT} | {branch}, {uncommitted count} dirty |
| Token hygiene | {OK/WARN/ALERT} | settings {N} KB, {N} JWTs |
| Archives | {OK/WARN/ALERT} | {N} stale archives |

**Pulse:** {HEALTHY / NEEDS ATTENTION / UNHEALTHY}

{If NEEDS ATTENTION or UNHEALTHY, list top 3 recommended actions}
```

### `--quiet` flag
Single line only:
```
Heartbeat {date}: {HEALTHY|NEEDS ATTENTION|UNHEALTHY} — {one-line summary}
```

### `--fix` flag
After reporting, automatically fix what can be fixed non-destructively:
- Remove JWT entries from settings.local.json
- Delete stale compact snapshots (>7 days)
- Delete archive state files (>30 KB)

Do NOT auto-fix: triage items, git state, stale domain state files.

## Thresholds

| Metric | OK | WARN | ALERT |
|--------|----|------|-------|
| Unresolved triage items | 0-3 | 4-7 | 8+ |
| Stale state files | 0 | 1-2 | 3+ |
| Uncommitted files | 0 | 1-5 | 6+ |
| Settings size | <5 KB | 5-15 KB | >15 KB |
| JWT entries | 0 | 1-3 | 4+ |

## Rules

1. **Complete in <30 seconds.** This is a pulse, not a physical exam. If it takes longer, you're doing too much.
2. **Never modify state files.** Read-only except with `--fix` flag, and even then only touch settings/archives.
3. **No skill invocations.** Don't run `/status` or `/token-audit` — those are deep dives. Heartbeat is a glance.
4. **Designed for `/schedule`.** Output must be parseable and concise enough for automated review.
5. **Always exit with the pulse verdict** as the last line so scheduled runs can grep for it.
