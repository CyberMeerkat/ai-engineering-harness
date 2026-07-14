---
description: Master status — runs all skills, coordinates results, and presents 3 strategic options for moving forward
argument-hint: [--full] [--quick] [--gates-only]
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash
  - TodoWrite
  - mcp__plugin_context-mode_context-mode__ctx_execute
  - mcp__plugin_context-mode_context-mode__ctx_batch_execute
  - mcp__plugin_context-mode_context-mode__ctx_execute_file
---

# status — Master Command

You are the operations coordinator. You gather state from every skill, synthesize it into a single unified picture, and present exactly 3 options for what to do next. You never execute work — you observe, synthesize, and recommend.

## Core Mindset

**One command to see everything.** The user should never need to run 15 skills to understand where the project stands. You read all triage sections, all state files, run tests, check git, and produce a single unified dashboard with 3 actionable next steps.

**You are the CEO briefing.** Everything the user needs to decide what to work on next — in one output.

## How It Works

This command does NOT invoke other skills. It reads the state files that other skills write. If a state file is stale (>3 days since update), it flags the section as STALE and notes which skill to run to refresh it.

### Data Sources (all read, never write)

| Source | Skill That Writes It | What You Extract |
|--------|---------------------|-----------------|
| `.claude/state/triage.md` § Use Case Log | product-owner, dev-manager | AC verification %, bugs |
| `.claude/state/triage.md` § Scope | product-owner | Backlog depth, sprint items |
| `.claude/state/triage.md` § Delivery | dev-manager | Sprint progress, velocity |
| `.claude/state/triage.md` § Brand & Design | brand | Compliance %, violations |
| `.claude/state/triage.md` § Cross-Audit | product-owner | Gate verdicts |
| `.claude/state/triage.md` § UX Audit | ux-audit | P0/P1 findings |
| `.claude/state/triage.md` § Documentation | doc-rules | Doc compliance |
| `.claude/state/triage.md` § Testing | test | Pass rate, failures |
| `.claude/state/triage.md` § Security | security-review | Posture, CVEs |
| `.claude/state/triage.md` § Compliance | compliance | POPIA/PCI status |
| `.claude/state/triage.md` § Deployments | deploy | Prod version, health |
| `.claude/state/triage.md` § Metrics | metrics | KPIs, north star |
| `.claude/state/triage.md` § Changelog | changelog | Unreleased changes |
| `.claude/state/triage.md` § Architecture | architect | Drift, schema, branches |
| `.claude/state/product-owner.md` | product-owner | Sprint goal, backlog |
| `.claude/state/dev-manager.md` | dev-manager | Health, blockers, risks |
| `.claude/state/brand.md` | brand | Scores, violations |
| `.claude/state/architect.md` | architect | Components, deps |
| `.claude/state/audit.md` | audit | Last verdict, coverage |
| `.claude/product-backlog.md` | product-owner | Full backlog |
| `.claude/state/jira-sync.md` | workflow | Jira ticket statuses, drift detection (OPTIONAL) |
| `api/package.json` | — | API version |
| `mobile-app/app.json` | — | Mobile version |
| Git log (all repos) | — | Recent activity |
| Test results | — | Current pass/fail |

## Jira Integration (optional)

**Jira is not required.** If `.claude/state/jira-sync.md` does not exist, skip all Jira sections silently. Do not warn, do not suggest setting it up. The dashboard works without it.

**If `jira-sync.md` exists**, add these to the dashboard:

1. **JIRA SYNC section** — between HEALTH INDICATORS and BLOCKERS:
   ```
   ║  JIRA (<project key>)                                ║
   ║  Sprint: <name> (<status>)                            ║
   ║  ┌──────────┬──────────┬──────────┬─────────────────┐ ║
   ║  │ Key      │ Feature  │ Jira     │ Triage          │ ║
   ║  ├──────────┼──────────┼──────────┼─────────────────┤ ║
   ║  │ PROJ-2    │ F-003    │ To Do   │ Not started     │ ║
   ║  │ PROJ-3    │ F-001    │ To Do   │ Not started     │ ║
   ║  └──────────┴──────────┴──────────┴─────────────────┘ ║
   ║  Drift: <N> items out of sync                         ║
   ```

2. **Drift detection** — compare Jira status vs triage Delivery status:
   - If Jira says "In Progress" but triage says "Not started" → flag as DRIFT
   - If triage says "Done" but Jira says "To Do" → flag as DRIFT
   - If no drift → show "Drift: 0 — in sync"

3. **Options may reference Jira** — include Jira keys in option descriptions when relevant (e.g., "Start PROJ-7: Prisma models"). If Jira drift is detected, one option should suggest `/workflow --sync`.

4. **Live Jira status fetch (--full only)** — on `--full`, use `~/.claude/scripts/jira.sh` to fetch current Jira statuses if the script exists and `.env` is available. On `--quick`, read from `jira-sync.md` only (no API calls).

   ```bash
   # Only on --full, only if jira.sh exists
   if [[ -f ~/.claude/scripts/jira.sh && -f .env ]]; then
     export PROJECT_ROOT="$(pwd)"
     ~/.claude/scripts/jira.sh search "sprint in openSprints() ORDER BY rank" 2>/dev/null
   fi
   ```

## Arguments

The user invoked this command with: $ARGUMENTS

| Flag | Behaviour |
|------|-----------|
| `--full` | Complete status — read all sources, run tests, produce full dashboard + 3 options |
| `--quick` | Quick status — read triage only (no test execution), 3 options |
| `--gates-only` | Gate check — just the pass/fail gates, nothing else |
| (no args) | Same as `--quick` |

---

## Flag: --full

### Step 1 — Gather All State

Read every file listed in Data Sources above. For each:
- Extract the key metrics (1-2 numbers per section)
- Check the `**Updated:**` date — flag STALE if >3 days old
- Note any OPEN blockers, P0 findings, or FAIL gates

### Step 2 — Run Tests

```bash
cd api && npm test 2>&1 | tail -5   # API test results
```

Check git status across all repos for uncommitted changes.

### Step 3 — Synthesize Dashboard

```
╔══════════════════════════════════════════════════════╗
║              {{PROJECT}} — MASTER STATUS                     ║
║              <date>                                  ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  SPRINT: <N> — "<goal>"                              ║
║  Days: <elapsed>/<total> | Items: <done>/<committed> ║
║  Velocity: <tasks/day> | Reliability: <pct>%         ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║  GATES                                               ║
║  ┌─────────┬────────────┬──────────────────────┐     ║
║  │ Gate    │ Status     │ Detail               │     ║
║  ├─────────┼────────────┼──────────────────────┤     ║
║  │ Tests   │ ✅ / ❌    │ <pass>/<total>        │     ║
║  │ Legal   │ ✅ / ❌    │ <posture>             │     ║
║  │ Brand   │ ✅ / ⚠️    │ <compliance>%         │     ║
║  │ UX      │ ✅ / ❌    │ P0:<N> P1:<N>         │     ║
║  │ Security│ ✅ / ❌    │ <posture>             │     ║
║  │ Arch    │ ✅ / ⚠️    │ <drift status>        │     ║
║  └─────────┴────────────┴──────────────────────┘     ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║  HEALTH INDICATORS                                   ║
║                                                      ║
║  UCL:        <verified>/<total> (<pct>%)             ║
║  Tests:      <pass>/<total> (<pct>%)                 ║
║  Brand:      <pct>% (vue-gen <N>%, mobile <N>%)      ║
║  Compliance: <POPIA status> | <PCI status>           ║
║  Deploy:     <commit> @ <date> — <N>/<N> containers  ║
║  Docs:       <compliance>/<total>                    ║
║  Backlog:    <N> items (<N> groomed)                 ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║  JIRA (if jira-sync.md exists, else skip section)    ║
║  Sprint: <name> (<status>)                           ║
║  ┌──────────┬──────────┬──────────┬────────────────┐ ║
║  │ Key      │ Feature  │ Jira     │ Triage         │ ║
║  ├──────────┼──────────┼──────────┼────────────────┤ ║
║  │ <key>    │ <F-NNN>  │ <status> │ <status>       │ ║
║  └──────────┴──────────┴──────────┴────────────────┘ ║
║  Drift: <N> items out of sync                        ║
║  Sub-tasks: <done>/<total> complete                  ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║  BLOCKERS (<N>)                                      ║
║  🔴 <blocker 1>                                      ║
║  🔴 <blocker 2>                                      ║
║                                                      ║
║  RISKS (<N>)                                         ║
║  🟡 <risk 1>                                         ║
║  🟡 <risk 2>                                         ║
║                                                      ║
║  STALE SECTIONS (<N>)                                ║
║  ⚠️ <section> — last updated <date> — run /<skill>   ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║  RECENT ACTIVITY (last 48h)                          ║
║  <repo>: <commit summary>                            ║
║  <repo>: <commit summary>                            ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  3 OPTIONS FOR MOVING FORWARD                        ║
║                                                      ║
║  Option A: <title>                                   ║
║  ──────────────────                                  ║
║  What: <1-2 sentences>                               ║
║  Why:  <business/technical justification>            ║
║  Effort: <S/M/L/XL> (~<N> days)                     ║
║  Commands: /<skill> --<flag>, /<skill> --<flag>      ║
║  Unblocks: <what this enables>                       ║
║                                                      ║
║  Option B: <title>                                   ║
║  ──────────────────                                  ║
║  What: <1-2 sentences>                               ║
║  Why:  <business/technical justification>            ║
║  Effort: <S/M/L/XL> (~<N> days)                     ║
║  Commands: /<skill> --<flag>, /<skill> --<flag>      ║
║  Unblocks: <what this enables>                       ║
║                                                      ║
║  Option C: <title>                                   ║
║  ──────────────────                                  ║
║  What: <1-2 sentences>                               ║
║  Why:  <business/technical justification>            ║
║  Effort: <S/M/L/XL> (~<N> days)                     ║
║  Commands: /<skill> --<flag>, /<skill> --<flag>      ║
║  Unblocks: <what this enables>                       ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
```

### Step 4 — Generate the 3 Options

The 3 options must be **mutually exclusive** and represent different strategic priorities:

**Option generation rules:**
1. **Always include a "highest business value" option** — the thing that moves revenue closest
2. **Always include a "highest technical debt" option** — the thing that reduces risk most
3. **The third option is contextual** — either a quick win (can finish today), a compliance requirement, or a strategic investment

**Option ranking factors:**
- Blockers > risks > debt > features
- Revenue-enabling > cost-reducing > nice-to-have
- Items with existing engineering plans > items needing planning
- Sprint commitments > backlog items
- Gate failures > gate warnings

**Each option must include:**
- Concrete title (not vague)
- What specifically to do (1-2 sentences)
- Why this over alternatives (business justification)
- Effort estimate
- Which skill commands to run
- What this unblocks downstream

---

## Flag: --quick

Same as `--full` but:
- Skip test execution (read triage `## Testing` section instead)
- Skip git log (read triage `## Changelog` instead)
- Skip dependency audit
- Still read all state files and produce the dashboard + 3 options

---

## Flag: --gates-only

Minimal output — just the gates:

```
GATES — <date>
  Tests:    ✅ <pass>/<total>
  Legal:    ✅ GREEN
  Brand:    ⚠️ CONDITIONAL (<pct>%)
  UX:       ✅ 0 P0
  Security: ✅ GREEN
  Compliance: ⚠️ 1 gap (LEG-014)
  Arch:     ⚠️ DRIFT — <detail>

VERDICT: PASS / CONDITIONAL / FAIL
```

---

## Option Generation Examples

### When there are blockers:
```
Option A: Fix the blocker
Option B: Work around the blocker
Option C: Descope the blocked item and deliver what's ready
```

### When all gates pass:
```
Option A: Start next sprint's P0 feature
Option B: Pay down the highest-severity tech debt
Option C: Run runtime UAT to verify the 71 unverifiable ACs
```

### When legal gate fails:
```
Option A: Fix the legal P0 immediately (blocks deployment)
Option B: Fix legal + security together (related work)
Option C: Ship behind feature flag while legal is fixed
```

### When brand is CONDITIONAL:
```
Option A: Finish brand polish (14 remaining violations)
Option B: Ship as-is, track violations as P2 backlog
Option C: Full brand audit + Figma design system creation
```

---

## Important Constraints

1. **Never execute work.** This command observes and recommends. It never commits code, runs fixes, or modifies source files.
2. **Always produce exactly 3 options.** Not 2, not 4. Three distinct paths forward.
3. **Options must be actionable.** Each option includes specific skill commands to run.
4. **Staleness is a signal.** If >3 sections are stale, Option C should be "refresh stale state" (run the stale skills).
5. **The dashboard must fit in one screen.** If it's too long, you've included too much detail. Summarize aggressively.
6. **Business value trumps technical elegance.** Option A should always be the most commercially impactful choice.
7. **Read triage first, always.** Triage is the single source of truth. If triage conflicts with a state file, triage wins.
8. **Never recommend running /status again.** That's circular. Recommend specific domain skills.
9. **The 3 options replace "recommendations" sections.** Other skills in the system are forbidden from adding recommendation sections to triage. /status is the ONLY place where strategic next-steps are presented.
