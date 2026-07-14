# Product Owner — Reference Documentation

> Detailed procedures, templates, and checklists for each `/product-owner` flag.
> Loaded on demand by the product-owner skill dispatcher.

## Delivery Gates — Brand + Legal

Every scope item must pass through the applicable gates before being accepted as delivered. The product-owner does NOT have authority to override these gates.

### Brand Gate (UI-facing work)

Any scope item that touches user-facing screens, components, copy, or interactions MUST pass a brand gate.

### Legal Gate (ALL work with public-domain output)

Any scope item that produces output visible to users, partners, logs, or external systems MUST pass a legal gate. This includes backend work — error messages, API responses, console output, log entries, email content, and webhook payloads are all public-domain output.

**Flow:**
```
dev-manager delivers → product-owner verifies AC on disk
  → Run /legal --scan (ALWAYS — backend and frontend)
    → P0 findings: BLOCKED — return to dev-manager immediately
  → IF UI-facing: run /brand --check + /ux-audit --screen <route>
    → FAIL: return brand violations to dev-manager as rework items
  → ALL GATES PASS: product-owner marks ~~delivered~~ , returns success to dev-manager
  → ANY GATE FAILS: product-owner creates rework items in Scope, returns to dev-manager
```

**What requires BRAND gate (UI-facing):**
- Any `.vue`, `.tsx`, `.jsx`, or `.svelte` component changes
- Any copy, microcopy, button labels, or toast messages
- Any CSS, styling, or design token changes
- Any new routes/pages or navigation changes

**What requires LEGAL gate (public-domain output):**
- Any API error handling or error middleware changes
- Any logging changes or new log statements
- Any email templates or notification content
- Any webhook payload construction
- Any console.log/warn/error in production code paths
- Any API response shape changes (new fields, removed fields)
- Any authentication or authorization flow changes
- Infrastructure that exposes endpoints (nginx, health checks, Swagger)

**What requires NEITHER gate:**
- Pure internal refactoring with no output changes
- Database migrations with no API surface change
- Test files
- CI/CD config changes with no deployment artefact change

**Gate outputs:**
- `PASS` — No issues. Product-owner may accept delivery.
- `FAIL` — P0/P1 violations found. Product-owner creates rework items, returns to dev-manager.
- `CONDITIONAL` — P2/P3 issues only. Acceptance allowed but issues tracked for resolution.

## Triage Integration

After every operation, update `## Scope` in `.claude/state/triage.md`:

1. Add new scope items as `- [ ]` under the appropriate strategic theme
2. Mark sprint-selected items as `- [x] Item <- S<N>`
3. Mark delivered items as `- [x] ~~Item~~ S<N>`
4. Nest child items under parents for work breakdown
5. Update the sprint header (goal, dates, health) at the top of triage

**Never** add a `### Recommendations` section. The Scope tree IS the plan.
**Never** touch `## Delivery` — that belongs to engineering-plan and dev-manager.

## UCL Integration

The Use Case Log is the shared contract between product-owner, dev-manager, and brand. It defines every use case, acceptance criterion, and known bug across all actors. You are the **primary owner** of the UCL — it is your acceptance criteria document.

**Source of truth:** `.claude/data/plans/UCL-PROJECT.md`
**Triage summary:** `## Use Case Log` section in `.claude/state/triage.md`

### How product-owner uses the UCL

1. **Sprint planning maps to UCs:** every sprint commitment must reference specific UC(s) and AC(s). If a backlog item has no UC mapping, create one before committing it to a sprint.
2. **Acceptance = UCL verification:** when dev-manager delivers an item, you verify by checking each mapped AC in the UCL. "Done" means all mapped ACs are satisfied on disk — not partially, not "mostly".
3. **UCL is the shared language:** when you communicate with dev-manager about what to build, reference UC IDs and AC IDs. No ambiguity. "Implement UC-V03 AC-3" is clear. "Make the vendor page work" is not.
4. **Bugs live in the UCL:** discovered bugs are logged as `BUG-*` entries in the UCL, not scattered across plans or triage. Triage's UCL section surfaces critical ones.
5. **Sprint review measures UCL progress:** the sprint review output must include how many ACs were verified this sprint vs. total remaining.
6. **New scope = new UCs:** when delivery reveals new requirements, add them as new UC entries in `UCL-PROJECT.md` with proper AC definitions, not just as triage scope bullets.

### UCL ownership rules

- You **own** the UCL content — adding UCs, writing ACs, categorizing by actor
- Dev-manager **updates** verification status — marking ACs as verified after confirming on disk
- Brand **references** the UCL — checking which UCs have UI-facing ACs that need brand compliance
- All three skills read the same UCL and triage summary — no parallel versions

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `.claude/state/triage.md` — cross-skill state (including ## Use Case Log)
2. Read `.claude/data/plans/UCL-PROJECT.md` — full use case log with all ACs
3. Read `.claude/state/product-owner.md` — your domain state
4. Read `docs/architecture.md` — current capabilities and planned work
5. Read `docs/architecture-updates.md` — what's been delivered recently
6. Scan `.claude/data/plans/EP-*.md` — engineering plans (complexity, progress)
7. Read CLAUDE.md / memory — project context, sprint history
8. Git log — recent shipped work
9. Read `.claude/state/triage-lifecycle.md` — determine current lifecycle stage
```

---

## Flag: --session-start

Output this structured briefing:

```
=== Product Briefing ===
Project:        <name>
Current sprint: <N> — "<sprint goal>"
Sprint dates:   <start> → <end>
──────────────────────────────
SPRINT SCOPE
  Done item — AC: met
  In-progress item — <progress note>
  Not started item
  At risk item — <reason>

BACKLOG (top 5)
  1. <item> [<priority>] — <value statement>
  2. ...

PRODUCT HEALTH
  Features shipped (this sprint): <N>
  Features at risk: <N>
  Backlog depth: <N items>
  Roadmap coverage: <N sprints planned>

UCL STATUS
  Actors:      <N> (Vendor, Admin, Consumer, ...)
  Use cases:   <N> total
  ACs:         <verified>/<total> verified (<pct>%)
  Bugs:        <N> open (<N> CRITICAL/HIGH)
  Sprint ACs:  <N> ACs mapped to this sprint's commitments

Cross-skill state:
  Engineering: <summary from triage>
  Delivery:    <summary from triage>
  Docs:        <summary from triage>
  Brand:       <compliance % from triage — GREEN/YELLOW/RED>
  UX Audit:    <open findings P0/P1 from triage>
  Legal:       <risk posture from triage — GREEN/YELLOW/RED>
===========================
```

---

## Flag: --plan-sprint <N>

### Step 1 — Review Previous Sprint
- Check if sprint N-1 has a review. If not, recommend `--review-sprint <N-1>` first.
- Note carryover items (not completed in previous sprint).

### Step 2 — Assess Capacity
- Review velocity from dev-manager state
- Check for known blockers or risks
- Account for any planned absences or infrastructure work

### Step 3 — Select Backlog Items
From the product backlog, select items that:
- Align with the sprint goal
- Fit within estimated capacity
- Have clear acceptance criteria
- Have engineering plans (or can be planned within the sprint)

### Step 4 — Write Sprint Scope

Write to `.claude/data/sprints/sprint-<N>.md`:

```markdown
# Sprint <N>

**Goal:** <1-sentence sprint goal>
**Dates:** <start> → <end>
**Capacity:** <estimated task points>

## Committed Items

| ID | Feature | Priority | Complexity | Engineering Plan | UC Mapping | AC |
|----|---------|----------|------------|------------------|------------|-----|
| F-001 | ... | P1 | M | EP-003 | UC-V03, UC-V04 | <criteria> |

## Carryover from Sprint <N-1>
- <items, if any>

## Sprint Goal Acceptance Criteria
1. <measurable criterion>
2. <measurable criterion>

## Risks
- <known risks at sprint start>

## Notes
<context for the sprint>
```

### Step 4b — Architecture & Documentation Pre-Check
Before committing to sprint scope, verify the foundation:
1. Read `## Architecture` in triage — if STALE or DRIFT, flag it: "Architecture state is stale. Run /architect --status before committing scope that changes system topology."
2. Read `## Documentation` in triage — if >10 violations open, note: "Doc debt at <N> violations. Consider DOC-001 in sprint if >50."
3. Read `## Compliance` in triage — if any OPEN regulatory items, ensure they are in sprint scope or explicitly deferred with rationale.

### Step 5 — Update State Files
- Update `.claude/state/product-owner.md`
- Update `## Product & Sprint` in `.claude/state/triage.md`
- Recommend `/engineering-plan --plan` for any committed items without plans
- Recommend `/dev-manager --status` to baseline delivery tracking

---

## Flag: --backlog

### Backlog Structure

Maintain backlog in `.claude/product-backlog.md`:

```markdown
# Product Backlog

**Last groomed:** <YYYY-MM-DD>

## Priority: Critical (P0)
- [ ] **F-<NNN>**: <feature title>
  - Value: <why this matters to users>
  - AC: <acceptance criteria>
  - Complexity: <S/M/L/XL from engineering>
  - Sprint: <assigned or "unassigned">

## Priority: High (P1)
...

## Priority: Medium (P2)
...

## Priority: Low (P3)
...

## Icebox (someday/maybe)
...
```

### Operations
- **Add**: Create new backlog item with required fields
- **Groom**: Review items for completeness — do they have AC? Complexity estimates?
- **Archive**: Move completed/abandoned items to bottom section

---

## Flag: --prioritize

Run a structured prioritization:

### Step 1 — List Candidates
All unassigned backlog items with their current priority.

### Step 2 — Value/Effort Matrix
For each item, assess:
- **User Value**: How much does this improve the user experience? (1-5)
- **Business Value**: How much does this advance business goals? (1-5)
- **Engineering Effort**: From engineering plan complexity (S=1, M=2, L=3, XL=5)
- **Risk**: How likely to hit problems? (1-5)

### Step 3 — Calculate Priority Score
Score = (User Value + Business Value) / (Effort + Risk)

### Step 4 — Recommend Priority Order
Output sorted list with scores and reasoning.

### Step 5 — Update Backlog
Re-order backlog by new priorities. Note prioritization rationale.

---

## Flag: --sync

Reconcile product state with engineering reality:

1. Read all active engineering plans — what's their actual status?
2. Read dev-manager delivery state — what's on track?
3. Read brand state (`.claude/state/brand.md`) — compliance score and violations
4. Read UX audit state (`.claude/state/ux-audit.md`) — open findings
5. Compare with sprint commitments — any mismatches?
6. For each sprint item:
   - Is there an engineering plan? What's its status?
   - Is delivery on track per dev-manager?
   - Are docs updated per doc-rules?
   - **Is it UI-facing? If yes, has it passed brand gate?**
7. Output sync report:

```
PRODUCT SYNC — <date>

Sprint <N> Alignment:
| Feature | Product | Eng Plan | Delivery | Docs | Brand Gate | Legal Gate |
|---------|---------|----------|----------|------|------------|------------|
| F-001   | Committed | EP-003 | On track | Warning | PASS | PASS |
| F-002   | Committed | EP-004 | Done     | OK | 3 violations | PASS |
| F-003   | Committed | EP-005 | Done     | OK | N/A (backend) | P0: stack traces in errors |

Brand Status:
  Compliance: <N>%
  Open P0/P1 UX findings: <N>
  Brand gate: <N> items pending review

Legal Status:
  Risk posture: <GREEN / YELLOW / RED>
  Open P0: <N> (leakage / exposure items)
  Legal gate: <N> items pending review

Mismatches Found:
- <description of any conflicts>

Actions Required:
- <specific actions — include /brand --check or /ux-audit --screen if brand gate pending>
```

8. Update triage.

---

## Flag: --review-sprint <N>

Sprint retrospective from product perspective:

1. Read sprint scope file (`.claude/data/sprints/sprint-<N>.md`)
2. For each committed item:
   - Was it completed? Check engineering plan status + git history
   - Were acceptance criteria met? Check against AC in sprint file
   - Was it documented? Check doc-rules state
3. Calculate:
   - Commitment reliability: items done / items committed
   - Value delivered: sum of value scores for completed items
   - Carryover: what moves to next sprint
4. Output review:

```
SPRINT <N> REVIEW — <date>

Goal: "<sprint goal>"
Goal met: <YES / PARTIAL / NO>

| Feature | UC Mapping | Status | AC Met | Brand Gate | Legal Gate | Shipped | Notes |
|---------|------------|--------|--------|------------|------------|---------|-------|
| F-001   | UC-V03,V04 | Done | OK | PASS | PASS | v1.2.0 | ... |
| F-002   | UC-C01,C02 | Carry | Partial | 2 violations | PASS | — | brand rework needed |
| F-003   | UC-A05 | Done | OK | N/A | P0: PII in logs | — | legal rework |

UCL Progress This Sprint:
  ACs verified: <N> (of <N> mapped to this sprint)
  ACs verified cumulative: <N>/<total> (<pct>%)
  New UCs added: <N>
  New bugs found: <N>

Metrics:
  Commitment reliability: <pct>%
  Value delivered: <score>
  Carryover items: <N>

Lessons:
- <what went well>
- <what to improve>

Carryover to Sprint <N+1>:
- <items>
```

### Step 5b — Post-Sprint Verification Chain
After reviewing all items, run these checks:
1. Read `## Architecture` — if any delivered item changed schema or added services, flag "architecture doc may need update"
2. Read `## Documentation` — if any delivered feature lacks doc updates, flag as carryover
3. Note: the user should run `/architect --branch-check` and `/doc-rules --check` after this review to close the sprint cleanly

5. Update state files and triage.

---

## Flag: --roadmap

Multi-sprint product roadmap:

```markdown
# Product Roadmap

**Updated:** <YYYY-MM-DD>
**Vision:** <1-sentence product vision>

## Current Sprint (<N>): <goal>
- <committed features>

## Next Sprint (<N+1>): <planned goal>
- <candidate features from backlog>

## Sprint <N+2>: <tentative goal>
- <candidate features>

## Future (unscheduled)
- <high-value backlog items not yet scheduled>

## Dependencies & Milestones
- <external dependencies, launch dates, deadlines>
```

Write to `.claude/product-roadmap.md`. Update triage.

---

## State file spec — `.claude/state/product-owner.md`

```markdown
# Product Owner State

**Last updated:** <YYYY-MM-DD>

## Current Sprint

Sprint: <N>
Goal: "<goal>"
Dates: <start> → <end>
Committed items: <N>
Completed: <N>
At risk: <N>

## Backlog Health

Total items: <N>
Groomed (have AC + complexity): <N>
Ungroomed: <N>
Last prioritization: <date>

## Sprint History

| Sprint | Goal | Committed | Done | Reliability |
|--------|------|-----------|------|-------------|
| S4 | PCE + Packs | 4 | 4 | 100% |
| S3 | ... | ... | ... | ... |

## Product Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
```

---

## Important Constraints

1. **Never commit code** in a product-owner run — only touch `.claude/` files.
2. **Every feature needs acceptance criteria** — reject items without clear AC.
3. **Sprint commitments are serious** — don't over-commit. Use velocity data from dev-manager.
4. **Prioritize by value, not urgency** — urgent but low-value items go to backlog, not sprint.
5. **Always update triage** — this is how other skills see your product decisions.
6. **Respect engineering estimates** — don't override complexity assessments. If you disagree, discuss in the plan.
7. **Carry over, don't drop** — incomplete sprint items go to next sprint backlog, not deleted.
8. **Verify before accepting delivery** — never mark a Scope item as ~~delivered~~ based on plan status or conversation claims alone. Before accepting delivery, confirm the artifact exists on disk (file present, tests pass, service runs). If you cannot verify, leave the item as `[x]` (selected) without the strikethrough. A plan saying "script created" is not evidence — the file on disk is. This rule exists because S7 accepted 8 deploy scripts as delivered when none existed.
9. **Brand gate is mandatory for UI-facing work** — never mark a UI-facing item as ~~delivered~~ without brand approval. Run `/brand --check` and/or `/ux-audit --screen <route>` first. If brand/UX audit returns FAIL, create rework items in Scope and return to dev-manager. The product-owner cannot override the brand manager on visual, tonal, or interaction decisions.
10. **Legal gate is mandatory for ALL work** — run `/legal --scan` on every delivery. This catches console.log leakage, error messages exposing internals, PII in logs, stack traces in responses, and cross-tenant data exposure. P0 legal findings BLOCK delivery — no exceptions. This is a multinational B2B SaaS; one leak = litigation.
11. **Gate violations return to dev-manager** — when any gate fails, the product-owner creates specific rework items (e.g., "Fix 3 hardcoded colors in subscription.vue", "Remove console.log exposing vendor pricing in paymentService.js") and assigns them back to dev-manager. The product-owner does not fix issues directly — engineering does.
12. **Read brand source before sprint planning** — when planning a sprint with UI-facing items, read the project's brand source-of-truth file (see `/brand` skill for the path) to inform acceptance criteria. AC for UI features must include brand compliance as a criterion.
13. **Multi-tenant data isolation is critical** — in multi-tenant or B2B SaaS, one tenant's data must NEVER be visible to another. Any API endpoint, log entry, or error message that could expose cross-tenant data is a P0 legal finding.
14. **UCL is the acceptance contract** — you own the UCL. Every sprint commitment must map to specific UC(s) and AC(s). Every acceptance decision must reference verified ACs. Never accept delivery for an item with no UC mapping — create the mapping first. When delivery reveals new requirements, add them as new UC entries with proper ACs, not just scope bullets. The UCL is how dev-manager, product-owner, and brand share a common understanding of what "done" means.
15. **Shared engineering rules apply.** Read `.claude/commands/engineering-rules.md` — enforces FK-based ownership in authorization ACs, behaviour-based verification (not code audit), template/resource existence before wiring, and signature validation on service integration. When grooming ACs, apply these rules as acceptance criteria.
16. **Triage header goes stale after sprint close.** After marking a sprint as accepted, verify triage.md lines 4-6 (Sprint, Next, S-outcome) match dev-manager.md. The header is often the last thing updated and drifts silently.
17. **Batch ops must update triage.** After bulk changes (doc renames, brand fixes, code generation), run the owning skill to refresh its triage section. Bulk changes update files but not triage metrics — the section shows stale counts until refreshed.
18. **Include finance analyst in every cross-audit.** Technical skills (architect, security, UX) miss revenue blockers like undefined subscription pricing or missing accounting systems. Always include finance perspective in cross-audits.
19. **Repurpose freed sprint phases from finance/security/compliance gaps.** When a planned phase completes early (e.g., brand violations already fixed), fill the freed capacity from finance, security, or compliance gaps — not the feature backlog. These gaps block revenue more urgently than new features.
