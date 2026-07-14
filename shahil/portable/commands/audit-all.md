# audit-all — Full Stakeholder Audit in One Command

You are the audit orchestrator. You run every staff-perspective skill in the correct dependency order, reconcile their outputs, produce a unified gap analysis, and sync to whatever workflow system the project uses (via `/workflow --sync`). The user runs ONE command and gets every perspective — delivery, product, architecture, legal, security, brand, UX, finance — with a clear "here vs there" verdict.

## When to Use

- Sprint boundary (before starting a new sprint)
- Before a major deployment or launch
- When the user says "full audit", "where do we stand", "revenue readiness"
- Quarterly review

## Arguments

| Flag | Behaviour |
|------|-----------|
| `--full` | All 4 layers + tests + workflow sync |
| `--quick` | Layers 0-2 only (skip tests, skip workflow sync) |
| `--gates-only` | Skip skill execution, just read existing state files and report gate verdicts |
| (no args) | Same as `--full` |

---

## Architecture: 4-Layer Execution

Skills write to separate state files. No skill spawns another. The orchestrator (you) dispatches skills in waves, waits between layers, and reconciles at the end.

```
LAYER 0: Ground Truth (parallel — 3 skills)
  /dev-manager --velocity    → state/dev-manager.md
  /product-owner --roadmap   → state/product-owner.md
  /architect --status        → state/architect.md

LAYER 1: Compliance & Design (parallel — 4 skills)
  /legal --full              → state/legal.md
  /devsecops (white hat)     → findings (no state file yet)
  /brand --check             → state/brand.md
  /ux-audit --full           → state/ux-audit.md

LAYER 2: Financial Synthesis (sequential — 1 skill)
  /cfo --board-report        → state/finance.md

LAYER 3: Orchestration (sequential — 3 steps)
  State reconciliation       → triage.md gate verdicts
  /status --full             → dashboard + 3 options
  /workflow --sync           → project workflow system
```

### Why This Order

- **Layer 0 first:** Establishes what exists (code, delivery, backlog). All downstream skills reference these.
- **Layer 1 second:** Evaluates against external standards (legal, security, brand, UX). Needs Layer 0's picture of what exists.
- **Layer 2 third:** CFO needs delivery health + compliance posture + UX readiness to assess financial viability.
- **Layer 3 last:** Synthesizes everything and makes it visible.

### Parallelism

- Layer 0: 3 skills run as parallel subagents (separate state files, no conflicts)
- Layer 1: 4 skills run as parallel subagents (separate state files, no conflicts)
- Layer 2: 1 skill, sequential (needs all prior state)
- Layer 3: 3 steps, sequential (each depends on previous)

---

## Execution: --full

### Step 1 — Pre-flight

Read `.claude/state/triage.md` to establish current sprint, gate verdicts, and blockers. This is the baseline.

Check production/deployment state per the project's conventions. If the project has a deploy skill (e.g. `/deploy-vps`, `/deploy`), run its `--status` variant; otherwise surface recent git history with `git log --graph --decorate -5` and note any uncommitted changes.

### Step 2 — Layer 0: Ground Truth (parallel)

Launch 3 subagents simultaneously. Each agent:
1. Reads triage.md + its own state file
2. Reads relevant source code
3. Produces findings
4. Reports back (parent writes state file updates)

**Dev Manager focus:** Velocity trend, sprint reliability, deploy state, risk register.
**Product Owner focus:** Roadmap priorities, UCL gap analysis (which unverified ACs block revenue?), S(N+1) recommendation.
**Architect focus:** Schema status, branch health, component inventory, drift assessment.

### Step 3 — Layer 1: Compliance & Design (parallel)

Launch 4 subagents simultaneously after Layer 0 completes.

**Legal focus:** PII in API responses, data-retention controls, email template leakage, payment/financial data exposure, jurisdictional regulatory requirements per project CLAUDE.md.
**DevSecOps focus:** Auth/session handling, input validation, secrets in config, mock/test-route guards in production, rate limiting, OWASP Top 10. Prioritise the threat surfaces identified in the project CLAUDE.md.
**Brand focus:** Color token compliance, email template brand adherence, asset naming, score calculation.
**UX/Design focus:** New screen inventory, consistency with existing patterns, accessibility, mobile responsiveness, interaction patterns.

### Step 4 — Layer 1 Results → Triage

After all 4 Layer 1 agents report back:
- Update triage gate verdicts based on findings
- List any new blockers (P0/CRITICAL findings)
- Note fixed items from this session

### Step 5 — Layer 2: Financial (sequential)

Run CFO assessment. Provide context from ALL Layer 0 + Layer 1 findings:
- Delivery health (from dev-manager)
- Compliance posture (from legal + devsecops)
- UX readiness (from ux-audit)
- Revenue model, break-even, runway

### Step 6 — Layer 3: Reconciliation

**Step 6a — State reconciliation (parent does this):**
- Read all updated state files
- Verify triage gate verdicts match individual skill conclusions
- Resolve cross-skill conflicts
- Update triage.md with consolidated verdicts

**Step 6b — Run /status --full logic:**
- Read all state files (now fresh)
- Run tests if the project's test runner is available
- Produce the dashboard with 3 strategic options
- Gap analysis: "here" (current state) vs "there" (next milestone)

**Step 6c — Run /workflow --sync logic:**
- Push state updates to whatever workflow system the project uses (Jira globally, Notion in projects that override workflow.md)
- Update production state section in the workflow sync state file
- Report drift (if any)

---

## Output Format

The final output MUST include:

### 1. Audit Summary Table

```
AUDIT RESULTS — <date>
┌──────────────┬─────────┬──────────────────────────────────┐
│ Skill        │ Verdict │ Key Finding                      │
├──────────────┼─────────┼──────────────────────────────────┤
│ Dev Manager  │ ✅/⚠️/❌ │ <one-line summary>               │
│ Product Owner│ ✅/⚠️/❌ │ <one-line summary>               │
│ Architect    │ ✅/⚠️/❌ │ <one-line summary>               │
│ Legal        │ ✅/⚠️/❌ │ <one-line summary>               │
│ DevSecOps    │ ✅/⚠️/❌ │ <one-line summary>               │
│ Brand        │ ✅/⚠️/❌ │ <one-line summary>               │
│ UX/Design    │ ✅/⚠️/❌ │ <one-line summary>               │
│ CFO          │ ✅/⚠️/❌ │ <one-line summary>               │
└──────────────┴─────────┴──────────────────────────────────┘
```

### 2. Gate Verdicts (from triage)

The 8-gate table from `/status`.

### 3. Gap Analysis

```
HERE → THERE
┌─────────────┬──────────────────┬──────────────────┬──────────┐
│ Dimension   │ Current State    │ Target State     │ Gap      │
├─────────────┼──────────────────┼──────────────────┼──────────┤
│ ...         │ ...              │ ...              │ ...      │
└─────────────┴──────────────────┴──────────────────┴──────────┘
```

### 4. Three Strategic Options

From `/status` — always exactly 3, mutually exclusive, actionable.

### 5. Workflow Sync Report

Drift count, pages/tickets updated, any errors.

---

## Subagent Prompts

Each subagent must be briefed with:
1. What skill perspective they represent
2. What files to read (state file + source code)
3. What specific questions to answer (project-specific, pulled from CLAUDE.md — not generic)
4. Output format: findings with severity + one-line summary
5. Word limit: 300 words max per agent

The parent agent (you) synthesizes all 8 reports into the final output.

---

## Important Constraints

1. **Never skip Layer 0.** Even if state files are fresh, re-read them — the codebase may have changed.
2. **Layer 1 MUST wait for Layer 0.** Compliance skills need the ground truth picture.
3. **Layer 2 MUST wait for Layer 1.** CFO needs the compliance posture.
4. **Always produce the gap analysis.** This is the whole point — "where are we vs where do we need to be."
5. **Always sync via /workflow (--full).** The audit is incomplete if stakeholders can't see it in the project's workflow system.
6. **8 skills, 4 layers, 3 options.** Not 7 skills, not 5 layers, not 2 options. The format is fixed.
7. **Findings fix in the same session.** If the audit surfaces P0/CRITICAL/HIGH findings, fix them before producing the final dashboard. The dashboard should reflect the post-fix state.
8. **One command replaces 8 manual skill invocations.** The user should never need to run individual skills for a status check.

## Timing Estimate

- Layer 0: ~3 min (3 parallel agents)
- Layer 1: ~5 min (4 parallel agents)
- Layer 2: ~2 min (1 agent, reads state only)
- Layer 3: ~5 min (reconciliation + status + workflow sync)
- **Total: ~15 min** (vs ~35 min sequential)

## Relationship to Other Commands

| Command | Scope | When |
|---------|-------|------|
| `/audit-all` | All 8 skills + synthesis + workflow sync | Sprint boundary, quarterly, pre-launch |
| `/status` | Read state files, no skill execution | Daily check |
| `/workflow --sync` | Workflow system sync only | After any state change |
| Project deploy skill | Deployment operations | Deployment (project-specific) |
| `/verify` | Tests + lint + security only | Per-PR |
