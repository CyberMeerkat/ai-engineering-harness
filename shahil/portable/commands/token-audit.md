---
description: Audit Claude Code setup for token efficiency — measures always-loaded files, checks for bloat, produces scorecard
---

# Token Efficiency Audit

You are auditing the current project's Claude Code setup for token waste.

## What to measure

### 1. Always-loaded files (cost per message)
These files load on EVERY message. Measure each:
- `CLAUDE.md` (project root)
- `.claude/CLAUDE.md` (if exists)
- All files in `.claude/rules/`
- All files in `~/.claude/rules/`
- `MEMORY.md` in the project memory directory

Use `wc -c` to get byte counts. Convert to approximate tokens (divide by 4).

### 2. Settings bloat
- Read `.claude/settings.local.json`
- Count entries containing `eyJ` (JWT tokens that accumulate)
- Count total Bash permission entries
- Flag if >10 KB

### 3. Skills (on-demand — informational only)
- Count files in `.claude/commands/` and `~/.claude/commands/`
- Report total size but note these are ON-DEMAND (no per-message cost)
- Flag any skill >20 KB as candidate for splitting

### 4. State file hygiene
- Check `.claude/state/` for archive files (>30 KB or with "archive" in name)
- Check `.claude/compact/` for stale snapshots

### 5. MCP servers
- Read `.mcp.json` and `~/.claude/.mcp.json`
- Count active servers (each adds system-reminder overhead)

## Output format

Produce a scorecard:

| Area | Size | Tokens/msg | Grade | Action |
|------|------|------------|-------|--------|

Grades:
- **A** = optimal (<5 KB always-loaded, or on-demand)
- **B** = acceptable (5-15 KB)
- **C** = needs attention (15-25 KB)
- **D** = bloated (>25 KB)

Then list top 3 recommended actions with estimated savings.

## Thresholds (from Anthropic + community best practices)
- CLAUDE.md: aim for <200 lines, <8 KB
- Rules: aim for <15 KB total
- Settings.local.json: aim for <3 KB
- Total always-loaded: aim for <30 KB
- Skills: no limit (on-demand), but individual skills <15 KB (per skill-budget.md)

## Flag: --enforce

Run the audit AND auto-apply remediations for any C/D-graded area. Specifically:

1. **JWTs in `settings.local.json`** — strip lines containing `eyJ` (preserving deny patterns).
2. **Specific Bash entries subsumed by wildcards** — collapse to wildcard form (e.g. drop `Bash(ssh root@host ...)` if `Bash(ssh:*)` exists).
3. **Settings file >5 KB after collapse** — surface remaining specific entries that could be wildcarded; ask user before collapsing.
4. **`MEMORY.md` >80 lines or >10 KB** — move "Snapshots" / "Open action items" sections to `MEMORY.archive.md`.
5. **Any skill >15 KB** — apply skill-budget split (extract Learned Rules to `~/.claude/agent_docs/<skill>/rules.md`).
6. **`.claude/compact/` >5 files** — invoke `scripts/archive-compact-snapshots.sh`.

Always:
- Show what will change BEFORE writing (dry-run summary)
- Re-read settings.local.json immediately before writing (permission dialog mutation race — see learned rule #1)
- Log audit result + remediations to `.claude/state/token-audit.md` for trend tracking

After enforcement, re-run audit and report new grade. Target: B or A-.

## Flag: --diff

Compare current state against `.claude/state/token-audit.md` history. Report regressions:
- Settings file grew by >2 KB
- New JWT entries appeared
- Always-loaded total grew by >5 KB
- A new skill exceeded 15 KB

Use this after a few sessions to detect creep before it becomes a cleanup project.

## Companion rules (loaded automatically)

- `~/.claude/rules/memory-hygiene.md` — MEMORY.md vs MEMORY.archive.md split convention
- `~/.claude/rules/tone-budget.md` — output token discipline (~25-40% reduction)
- `~/.claude/rules/skill-budget.md` — skills >15 KB must split into dispatcher + agent_docs

## Companion plugin

- `caveman` (juliusbrussee/caveman) — installed via plugin marketplace. `/caveman` toggles ~75% output compression. Layer 3 of the token efficiency plan; tone-budget rule is the always-on fallback when caveman is off.

## Learned Rules

1. **`settings.local.json` Write fails after Read due to permission approval mutations.** Claude Code's permission dialog mutates the file between Read and Write calls. Always re-read immediately before writing. Error: "File content has changed since it was last read". *(From: feedback_learned_settings_local_write_race.md)*
2. **Use wildcard Bash permissions to prevent JWT accumulation.** Wildcard patterns (`Bash(git:*)`, `Bash(node:*)`) prevent bloat from one-off command approvals. Grep for `eyJ` to find JWT entries. Never approve commands containing JWTs — they're ephemeral. *(From: feedback_learned_wildcard_bash_permissions.md)*
