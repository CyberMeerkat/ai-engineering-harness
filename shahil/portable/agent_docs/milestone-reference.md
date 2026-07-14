# Milestone — Reference Documentation

> Detailed procedures, templates, and checklists for each `/milestone` flag.
> Loaded on demand by the milestone skill dispatcher.

## Triage Integration

After every operation, update `.claude/state/triage.md` section `## Milestones`:

```markdown
## Milestones
**Updated:** <YYYY-MM-DD HH:MM>
**Active:** <N>  |  **Passed:** <N>  |  **Failed:** <N>

### Active Milestones
| ID | Title | Target | Gates | Status |
|----|-------|--------|-------|--------|
| M-001 | Sprint 5 Deploy | 2026-04-01 | 4/6 PASS | IN PROGRESS |

### Blocked
- M-002 depends on M-001 (not yet closed)

### Recently Closed
- M-000: Sprint 4 code complete (closed 2026-03-22)

### Recommendations
- <cross-skill actions — e.g., "Run /quality-gate --verify M-001 to advance gates">
```

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `.claude/state/triage.md` — cross-skill state
2. Read `.claude/state/milestone.md` — your domain state (create if missing)
3. Glob `.claude/data/milestones/M-*.md` — all milestone definition files
4. Read each milestone file to build current state picture
5. Git log (last 20 commits) — recent activity
6. Read `.claude/state/engineering-plan.md` — plan status (if exists)
7. Scan `.claude/data/sprints/` for current sprint file (if exists)
8. Check for any active deploy, quality-gate, or security state files
```

If `.claude/data/milestones/` directory does not exist, create it.
If `.claude/state/milestone.md` does not exist, bootstrap it with the template from the State File Spec section below.

---

## Flag: --session-start

Output this structured dashboard:

```
=== Milestone Dashboard ===
Project:         <name>
Date:            <YYYY-MM-DD>
Active:          <N> milestones
Passed:          <N> milestones
Failed:          <N> milestones
Closed:          <N> milestones
──────────────────────────────
ACTIVE MILESTONES
  M-<NNN>: <title>
    Status:   <status>
    Target:   <YYYY-MM-DD>
    Gates:    <N/M PASS>
    Blockers: <dependency or failed gate>
  ...

DEPENDENCY GRAPH
  M-001 → M-002 → M-003
  M-001 → M-004
  (independent: M-005)

RECENTLY CLOSED
  M-000: <title> (closed <date>)
  ...

NEXT ACTIONS
  - <recommended next step for each active milestone>
  ...
=============================
```

---

## Flag: --define <name>

### Step 1 — Assign ID

Scan `.claude/data/milestones/` for existing `M-*.md` files. Determine the next available ID (`M-001`, `M-002`, etc.).

### Step 2 — Gather Details

Ask the user for (or infer from context):
1. **Objective** — what this milestone means for the business (1-2 sentences)
2. **Target date** — when it should be complete
3. **Owner** — who defines success
4. **Dependencies** — which milestones must be CLOSED first (can be none)
5. **Gates** — which verification gates apply. Default gate set:
   - Tests pass (`/quality-gate --verify`)
   - No critical CVEs (`/security-review --scan`)
   - Docs compliant (`/doc-rules --check`)
   - Deployed + healthy (`/deploy --verify`)
   - Brand consistent (`/brand --check`)
   - KPIs defined (`/metrics --check`)
6. **Auto-chain sequence** — ordering of gate skill invocations (defaults to the order above)
7. **Success criteria** — measurable, observable outcomes

### Step 3 — Create Milestone File

Write the milestone file to `.claude/data/milestones/M-<NNN>-<slug>.md` using the Milestone File Format below.

### Step 4 — Update State Files

1. Update `.claude/state/milestone.md` with the new milestone
2. Update `.claude/state/triage.md` section `## Milestones`

---

## Milestone File Format

File path: `.claude/data/milestones/M-<NNN>-<slug>.md`

```markdown
# M-<NNN>: <Title>

**Status:** DEFINED | IN PROGRESS | GATING | PASSED | FAILED | CLOSED
**Created:** <YYYY-MM-DD>
**Target:** <YYYY-MM-DD>
**Owner:** <who defines success>

## Objective
<what this milestone means for the business — 1-2 sentences>

## Dependencies
- M-<NNN>: <must be CLOSED before this can start>

## Gates (all must PASS to close)
| Gate | Skill | Command | Status | Evidence |
|------|-------|---------|--------|----------|
| Tests pass | /quality-gate | --verify M-<NNN> | PENDING | — |
| No critical CVEs | /security-review | --scan | PENDING | — |
| Docs compliant | /doc-rules | --check | PENDING | — |
| Deployed + healthy | /deploy | --verify | PENDING | — |
| Brand consistent | /brand | --check | PENDING | — |
| KPIs defined | /metrics | --check M-<NNN> | PENDING | — |

## Auto-Chain Sequence
1. /quality-gate --verify M-<NNN>
2. /security-review --scan
3. /doc-rules --check
4. /deploy --execute <env>
5. /brand --check
6. /metrics --check M-<NNN>

## Success Criteria
- <measurable, observable outcomes>

## Evidence
<links to test results, screenshots, health checks — populated by gate skills>

## Notes
<freeform>
```

---

## Flag: --status

### Step 1 — Gather State
Run Phase 0 context gathering.

### Step 2 — Build Dashboard
For each milestone file:
1. Read current status
2. Count gates: PASS / FAIL / PENDING
3. Check dependency status
4. Identify blockers (failed gates, unmet dependencies)

### Step 3 — Output Status Report

```
MILESTONE STATUS REPORT — <date>

| ID | Title | Target | Status | Gates | Blockers |
|----|-------|--------|--------|-------|----------|
| M-001 | Sprint 5 Deploy | 2026-04-01 | IN PROGRESS | 4/6 PASS | — |
| M-002 | Public Beta | 2026-04-15 | DEFINED | 0/6 PASS | Depends on M-001 |

Dependency chain: M-001 → M-002

Recommendations:
- <next actions per milestone>
```

### Step 4 — Update State Files
Update `.claude/state/milestone.md` and `.claude/state/triage.md` section `## Milestones`.

---

## Flag: --run <milestone>

### CRITICAL SAFETY CONSTRAINT

> **The `--run` autonomous loop ALWAYS stops and asks for user confirmation before invoking `/deploy --execute`.** All other skills in the auto-chain can be invoked without confirmation.

### Autonomous Loop Protocol

```
1. Read the milestone file (.claude/data/milestones/M-<NNN>-*.md)
2. Validate milestone status — must be DEFINED, IN PROGRESS, or FAILED to run
   - If CLOSED or PASSED, inform user and stop
3. Check dependencies — all deps must be CLOSED
   - If any dep is not CLOSED, output blocker list and stop
4. Set milestone status to IN PROGRESS
5. For each step in the Auto-Chain Sequence:
   a. Check if this step invokes /deploy --execute
      - YES → STOP. Output current gate status. Ask user:
        "Ready to deploy? /deploy --execute <env> requires your explicit approval. Proceed? (yes/no)"
        Wait for user confirmation before continuing. Do NOT auto-invoke deploy.
      - NO → Continue to step (b)
   b. Invoke the skill using the Skill tool:
      Skill(skill: "<skill-name>", args: "<arguments>")
   c. Capture the result — determine PASS or FAIL from skill output
   d. Update the gate row in the milestone file:
      - Status: PASS or FAIL
      - Evidence: link to evidence file or summary of result
   e. If FAIL:
      - Log the failure details in the milestone file section Notes
      - Decide: can remaining gates still be checked? (yes for independent gates)
      - If all remaining gates depend on the failed gate, stop the loop
      - Otherwise, continue to next gate and note the failure
   f. Update .claude/state/milestone.md with progress
6. After all gates are evaluated:
   - If ALL gates PASS: set milestone status to PASSED
     - Output: "All gates passed. Run /milestone --close M-<NNN> to close this milestone."
   - If ANY gate FAIL: set milestone status to FAILED
     - Output remediation plan: list each failed gate with what needs to happen to fix it
     - Suggest specific skill invocations to address each failure
7. Update .claude/state/triage.md section Milestones
8. Update .claude/state/milestone.md
```

### Auto-Chain Skill Invocation

Use the `Skill` tool to invoke each skill in the chain:

```
Step: /quality-gate --verify M-001
→ Skill(skill: "quality-gate", args: "--verify M-001")

Step: /security-review --scan
→ Skill(skill: "security-review", args: "--scan")

Step: /doc-rules --check
→ Skill(skill: "doc-rules", args: "--check")

Step: /deploy --execute prod
→ STOP — ask user for confirmation first
→ Only after "yes": Skill(skill: "deploy", args: "--execute prod")

Step: /brand --check
→ Skill(skill: "brand", args: "--check")

Step: /metrics --check M-001
→ Skill(skill: "metrics", args: "--check M-001")
```

### Handling Missing Skills

If a skill in the auto-chain does not exist yet (file not found in `.claude/commands/`):
- Set that gate to `SKIPPED` (not FAIL)
- Note in evidence: "Skill not yet implemented"
- Continue to next gate
- Include in final report: "N gates skipped due to missing skills"

---

## Flag: --gate <milestone>

### Step 1 — Read Milestone
Read the milestone file and extract the gates table.

### Step 2 — Check Each Gate
For each gate, check its current status. Do NOT re-run the gate skills — just read current state from:
- The milestone file itself
- Evidence files in `.claude/data/evidence/`
- State files for each skill (quality-gate-state.md, security-state.md, etc.)

### Step 3 — Output Gate Report

```
GATE REPORT — M-<NNN>: <Title>

| Gate | Status | Last Checked | Evidence |
|------|--------|--------------|----------|
| Tests pass | PASS | 2026-03-22 | .claude/data/evidence/M-001-tests-2026-03-22.md |
| No critical CVEs | FAIL | 2026-03-22 | .claude/data/evidence/M-001-security-2026-03-22.md |
| Docs compliant | PASS | 2026-03-22 | .claude/data/evidence/M-001-docs-2026-03-22.md |
| Deployed + healthy | PENDING | — | — |
| Brand consistent | PENDING | — | — |
| KPIs defined | PENDING | — | — |

Overall: 2/6 PASS | 1/6 FAIL | 3/6 PENDING
Verdict: NOT READY TO CLOSE

Remediation:
- "No critical CVEs" FAILED — run /security-review --remediate to address findings
- "Deployed + healthy" PENDING — run /deploy --execute <env> then /deploy --verify <env>
- "Brand consistent" PENDING — run /brand --check
- "KPIs defined" PENDING — run /metrics --check M-<NNN>
```

### Step 4 — Update State
Update milestone file gate statuses and `.claude/state/triage.md` section `## Milestones`.

---

## Flag: --close <milestone>

### Step 1 — Verify Eligibility
Read the milestone file. To close:
- Status must be PASSED (all gates PASS)
- If status is not PASSED, refuse to close and explain which gates are blocking

### Step 2 — Archive with Evidence
1. Set status to CLOSED in the milestone file
2. Add closure date
3. Compile evidence summary in the milestone file section Evidence:
   - List each gate with its evidence file link
   - Include final pass date for each gate
4. Add a closure entry to `.claude/state/milestone.md` section Closure Log

### Step 3 — Check Downstream
Scan all other milestone files for dependencies on this milestone:
- If any milestone was blocked waiting on this one, note that it is now unblocked
- Suggest: "M-<NNN> is now unblocked — run `/milestone --run M-<NNN>` to begin execution"

### Step 4 — Update State
1. Update `.claude/state/milestone.md`
2. Update `.claude/state/triage.md` section `## Milestones` — move to Recently Closed

---

## Flag: --roadmap

### Step 1 — Build Dependency Graph
Read all milestone files. Build the full dependency graph.

### Step 2 — Identify Critical Path
The critical path is the longest chain of dependent milestones. Highlight it.

### Step 3 — Output Roadmap

```
=== Milestone Roadmap ===

DEPENDENCY GRAPH
  M-001: Sprint 5 Deploy (IN PROGRESS, target 2026-04-01)
    └→ M-002: Public Beta (DEFINED, target 2026-04-15)
       └→ M-003: GA Launch (DEFINED, target 2026-05-01)
  M-004: Security Hardening (DEFINED, target 2026-04-10) [independent]

CRITICAL PATH
  M-001 → M-002 → M-003
  Total duration: <estimated days>
  On track: <YES/NO — based on current gate status and target dates>

TIMELINE
  2026-04-01  M-001 target (4/6 gates passing)
  2026-04-10  M-004 target (0/4 gates passing)
  2026-04-15  M-002 target (blocked by M-001)
  2026-05-01  M-003 target (blocked by M-002)

AT RISK
  - M-001 has 2 failing gates with target in 10 days
  - M-002 cannot start until M-001 closes

RECOMMENDATIONS
  - Focus on M-001 gate failures: /milestone --run M-001
  - M-004 is independent — can run in parallel
=============================
```

---

## State File Spec — `.claude/state/milestone.md`

```markdown
# Milestone State

**Last updated:** <YYYY-MM-DD HH:MM>

## Summary
Active: <N>  |  Passed: <N>  |  Failed: <N>  |  Closed: <N>  |  Defined: <N>

## Active Milestones

| ID | Title | Status | Target | Gates (pass/total) | Blockers |
|----|-------|--------|--------|--------------------|----------|

## Dependency Graph
<text representation of milestone dependencies>

## Last Run Log

| Date | Milestone | Action | Result |
|------|-----------|--------|--------|
| 2026-03-22 14:00 | M-001 | --run | 4/6 PASS, 2 FAIL |

## Closure Log

| Date | Milestone | Title | Evidence |
|------|-----------|-------|----------|
| 2026-03-22 | M-000 | Sprint 4 code complete | All 6 gates PASS |
```

---

## Important Constraints

1. **Never commit code** in a milestone run — only touch `.claude/` files (milestone definitions, state, triage, evidence).
2. **Never fake gate results** — if a skill invocation fails or a check cannot run, the gate status is PENDING or FAIL, never PASS.
3. **ALWAYS stop before `/deploy --execute`** — the autonomous loop requires explicit user confirmation before any deployment. This is non-negotiable. All other skills can be auto-chained without confirmation.
4. **Respect dependencies** — never start a `--run` on a milestone whose dependencies are not CLOSED. Report the blocker and stop.
5. **Always update triage** — this is how other skills see milestone status. Every operation must end with a triage update.
6. **Always update the state file** — `.claude/state/milestone.md` is the source of truth for milestone orchestration state.
7. **Evidence is mandatory** — every gate PASS or FAIL must have an evidence reference (file link or inline summary). No evidence = PENDING.
8. **Handle missing skills gracefully** — if a skill in the auto-chain doesn't exist yet, mark the gate as SKIPPED, not FAIL. Note the skip and continue.
9. **Be transparent about the autonomous loop** — when running `--run`, output each step as it executes so the user can see progress in real time.
10. **Drive toward closure** — every status report and run result should end with clear next actions to advance the milestone toward CLOSED.
