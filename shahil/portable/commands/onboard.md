---
description: "Session onboarding — single entry point that chains context briefing, health pulse, and smart options"
---

# /onboard — Session Entry Point

You are the onboard skill. You are the **single command** users run at session start. You chain context orientation, health monitoring, and actionable options — no need to run `/status`, `/brief`, or `/heartbeat` separately. Run `/status` only for a deep 15-section dive.

## Session Detection — New vs Resumed

Before doing anything, determine if this is a **new session** or a **resumed session**:

**New session indicators** (ANY of these):
- No prior conversation messages (first message is the /onboard invocation)
- User said "start", "new session", "begin", or similar
- No compact snapshot from today in `.claude/compact/`
- User explicitly ran `/onboard`

**Resumed session indicators** (ANY of these):
- User said "continue", "pick up", "resume", or similar
- Compact snapshot exists from today
- Prior conversation context references specific tasks or files
- The conversation already has tool call history

## Phase 0 — Context Reads (every invocation)

1. Read `.claude/CLAUDE.md` — understand the `.claude/` directory structure
2. Read `.claude/state/triage.md` — the full project state
3. Scan which state files exist in `.claude/state/` — indicates which skills have been activated
4. Read `.claude/state/triage-lifecycle.md` — understand the lifecycle stages

## Flags

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Same as no args — full onboarding |
| `--quick` | Branch + sprint + blockers + pulse line (4-5 bullets) |
| `--for <role>` | Tailor output: `engineer`, `reviewer`, `pm`, `qa` |
| `--skills` | List all available skills with activation status |
| `--health` | Full heartbeat table (5-check health dashboard) |
| `--context <topic>` | Deep-dive context on a specific topic (reads relevant state + docs) |
| (no args) | Full onboarding |

## New Session Protocol

### Step 1 — Brief Block

Read (in parallel where possible): `triage.md`, `engineering-plan.md`, `dev-manager.md`, `product-owner.md`, `CLAUDE.md` (first 20 lines only).

Output this structured block (max 200 words):

```
## Session Brief — {YYYY-MM-DD}

**Project:** {name} — {one-line description}
**Sprint:** S{N} — {sprint theme}
**Branch:** {from git rev-parse --abbrev-ref HEAD}
**Active EP:** {EP-XXX} — {title} ({status}) [or "None"]

### Current Focus
{2-3 sentences: what we're building and why, from triage + EP}

### Blockers
{bulleted list, or "None"}
```

### Step 2 — Health Pulse

Run these 5 checks (parallel where possible):

| # | Check | How | OK | WARN | ALERT |
|---|-------|-----|----|------|-------|
| 1 | Triage pulse | Count unresolved items in triage | 0-3 | 4-7 | 8+ |
| 2 | State freshness | Check `**Updated:**` in all `.claude/state/*.md` | 0 stale | 1-2 >7d | 3+ >7d |
| 3 | Git health | `git status` + last commit age + branch pattern | Clean, <3d | Dirty or >3d | Both |
| 4 | Token hygiene | `.claude/settings.local.json` size + `eyJ` count | <5KB, 0 JWT | 5-15KB or 1-3 JWT | >15KB or 4+ JWT |
| 5 | Stale archives | Check state/ for >30KB files or "archive" in name | 0 | 1 | 2+ |

Output:

```
### Health Pulse

| Check | Status | Detail |
|-------|--------|--------|
| Triage | {OK/WARN/ALERT} | {N} unresolved, {N} blocked |
| State freshness | {OK/WARN/ALERT} | {N} stale, {N} dead |
| Git | {OK/WARN/ALERT} | {branch}, {detail} |
| Token hygiene | {OK/WARN/ALERT} | {N} KB, {N} JWTs |
| Archives | {OK/WARN/ALERT} | {detail} |

**Pulse:** {HEALTHY / NEEDS ATTENTION / UNHEALTHY}
```

### Step 3 — 3 Options

Derive exactly 3 mutually exclusive options from the brief + pulse:

**Option generation heuristics:**
- If pulse is UNHEALTHY → Option A is always `/heartbeat --fix`
- If EP is in implementation phase → suggest specific coding task from EP
- If EP is in review phase → suggest `/review` or `/quality-gate`
- If no active EP → suggest `/director "<objective from triage>"`
- If tests stale (>3 days) → suggest `/test --run`
- If state files stale → suggest running the owning skill
- Always include one "deep dive" option: `/status --full`

Format each option as:
```
**Option A: {title}**
{What + why in 1 sentence}
→ `{exact command to run}`
```

## Resumed Session Protocol

1. Read the latest compact snapshot (most recent file in `.claude/compact/`)
2. Run health pulse checks inline (same 5 checks, but output single line only)
3. Output:

```
## Resuming — {date}

**Left off:** {from compact: current objective}
**Pulse:** {HEALTHY|NEEDS ATTENTION|UNHEALTHY} — {one-line summary}
**Next:** {from compact: next step}
→ `{suggested command}`
```

Do NOT run the full briefing — the user already has context.

## --quick Flag

Output 4-5 bullets only:
- Branch: `{branch}` (last commit: {relative time})
- Sprint: S{N} — {status}
- Blockers: {list or "None"}
- Pulse: {verdict} — {one-line}
- Suggested: `{one command}`

## --for \<role\> Flag

Filter the full briefing for relevance:
- `engineer` — focus on code, tests, architecture, active EP implementation details
- `reviewer` — focus on open PRs, diff scope, merge readiness
- `pm` — focus on sprint progress, milestone status, delivery risks
- `qa` — focus on test coverage, quality gates, failing tests, UAT status

## --skills Flag

List all available skills with:
- Name and one-line description
- Whether the skill has a state file in `.claude/state/`
- Last updated date (from state file `**Updated:**` timestamp, or "never")

## --health Flag

Run the full heartbeat table from Step 2. If any check is WARN or ALERT, include the recommended fix action below the table.

## --context \<topic\> Flag

Deep-dive on a specific topic:
1. Search triage for the topic keyword
2. Read the most relevant state file
3. Read relevant source files (architecture docs, code)
4. Output a focused briefing on that topic only

## Learned Rules

1. **Bridge script is the sole intelligence interface.** Never add raw HTTP calls to intelligence/agent-api endpoints in skills or commands. All intelligence queries go through the bridge script. *(From: feedback_learned_bridge_sole_interface)*
2. **Fall back to Bash grep when `rg` binary is missing.** Glob/Grep tools fail with `ENOENT posix_spawn rg` on some environments. Use `bash grep -rn` as fallback. *(From: feedback_learned_rg_binary_missing)*
3. **YouTube transcripts can't be fetched via HTML scrape.** `ctx_fetch_and_index` and `WebFetch` on YouTube URLs return only the page shell. Search for `"<video title>" transcript OR blog OR article` instead — the companion blog post usually has the same content. *(From: feedback_learned_youtube_transcript_workaround.md)*
4. **`/onboard` replaces `/status` at session start.** Onboard chains brief block + health pulse + 3 options inline. Only run `/status --full` for a deep 15-section scan. Running both is redundant — double-reads all state files. *(From: feedback_learned_onboard_replaces_status.md)*

## Safety

- NEVER modify project files — this skill is read-only
- NEVER invoke other skills — only recommend them in options
- If triage data is stale (>7 days), flag it but don't fabricate current state
- If a triage section is bootstrap-only (never activated), say so explicitly
