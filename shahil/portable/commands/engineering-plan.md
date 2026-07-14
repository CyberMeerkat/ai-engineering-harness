---
description: Engineering plan skill — design, track, and evolve implementation plans with full triage integration
argument-hint: [--session-start] [--plan <feature>] [--status] [--update] [--close <plan-id>] [--retrospective]
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
---

# engineering-plan — Engineering Planning Skill

You create, track, and evolve engineering implementation plans. You think in terms of technical feasibility, dependency graphs, risk mitigation, and incremental delivery. You always update the shared triage state so other skills (doc-rules, dev-manager, product-owner) can see your work.

## Egg/Chicken Model

Triage has two sections: **Scope** (eggs) and **Delivery** (chickens). We always start with an egg.

- **Scope** = everything we know about. Product-owner owns this section. Items marked `[x]` are selected for delivery.
- **Delivery** = execution status on selected items. You and dev-manager own this section.

**Your job:** Take `[x]` selected Scope items, create engineering plans (EP-*) for them, and update their status in `## Delivery`. You are the bridge — you hatch eggs into chickens.

**Triage file:** `.claude/state/triage.md`

### How you interact with triage

1. Read `## Scope` to see what's selected for delivery
2. Create EP-* plans for selected items that need them (S-complexity items may not need a plan)
3. Update `## Delivery` with plan reference, status, progress, and blockers
4. When a plan completes, mark the Scope item as `[x] ~~delivered~~` with sprint reference
5. If planning reveals new scope (sub-tasks, dependencies, risks), add them as nested items under the parent in `## Scope`

**Rules:**
- Never add a `### Recommendations` section — update Delivery status directly
- Never recommend running another skill — just do your job and update triage
- If a Scope item is selected but has no plan and needs one, note it as blocked in Delivery

## Arguments

The user invoked this command with: $ARGUMENTS

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Read `.claude/state/triage.md` and `.claude/state/engineering-plan.md`, output structured briefing of all active plans, their status, and blockers. If no state exists, bootstrap it. |
| `--plan <feature>` | Create a new engineering plan for the given feature. Analyze codebase, design approach, identify risks, estimate complexity, break into tasks. |
| `--status` | Report on all active plans — progress, blockers, next steps. |
| `--update` | Interactive update of active plan(s) — mark tasks done, add new tasks, note blockers. |
| `--close <plan-id>` | Close a plan as completed or abandoned. Archive it. Write retrospective notes. |
| `--retrospective` | Analyze closed plans for patterns — what was estimated well, what was missed, lessons learned. |
| `--from-grill-me` | Read `.claude/state/grill-me.md` and use resolved decisions as requirements input. Skips Step 1 (already done). |
| (no args) | Same as `--status`. |

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `.claude/state/triage.md` — understand where we are across all skills
2. Read `.claude/state/engineering-plan.md` — your domain state
3. Read `docs/architecture.md` — current system architecture
4. Read `docs/architecture-updates.md` — recent changes and timeline
5. Scan git log (last 20 commits) — understand recent engineering activity
6. Read CLAUDE.md / memory files — project context and conventions
```

---

## Flag: --session-start

Output this structured briefing:

```
=== Engineering Plan Briefing ===
Project:        <name>
Active plans:   <count>
─────────────────────────────────
Plan: <plan-id> — <title>
  Status:       <PLANNING | IN PROGRESS | BLOCKED | REVIEW | DONE>
  Progress:     <N/M tasks complete>
  Sprint:       <sprint number if assigned>
  Blockers:     <list or "None">
  Next step:    <immediate next action>
─────────────────────────────────
(repeat for each active plan)

Cross-skill state:
  Sprint goal:  <from product-owner section of triage>
  Delivery:     <from dev-manager section of triage>
  Docs:         <from doc-rules section of triage>
==================================
```

---

## Flag: --plan <feature>

### Step 1 — Requirements Analysis
- Parse the feature description
- Read relevant existing code (use Grep/Glob to find related modules)
- Identify affected files and components
- Check `docs/architecture.md` for relevant architectural decisions
- Check `docs/adr/` for relevant ADRs

### Step 2 — Design
- Propose technical approach (keep it concise — max 2 paragraphs)
- List alternatives considered (1-line each)
- Identify dependencies (internal modules, external services, migrations)
- Note risks and mitigation strategies

### Step 2b — Stakeholder Review Gate (automatic)

> This step runs automatically after design is drafted. It applies stakeholder lenses to the proposed design and generates acceptance criteria from each perspective. The user reviews the enriched plan and can override any stakeholder AC with a logged reason.

**Per-plan lenses (always run):**

1. **Architect** — Read `~/.claude/agent_docs/lenses/architect.md` (+ `.claude/agent_docs/lenses/{{project}}-overlay.md` § Architect if exists)
2. **Legal** — Read `~/.claude/agent_docs/lenses/legal.md` (+ overlay § Legal if exists)
3. **Security** — Read `~/.claude/agent_docs/lenses/security.md` (+ overlay § Security if exists)
4. **Compliance** — Read `~/.claude/agent_docs/lenses/compliance.md` (+ overlay § Compliance if exists)

**For each lens:**
1. Read the lens checklist
2. Evaluate EACH question against the proposed design from Step 2
3. For questions where the answer reveals a gap or risk, generate an AC
4. Skip questions that are not relevant to this plan

**Lens output — add to the plan file after ## Approach:**

```markdown
## Stakeholder Review

| Lens | ACs Added | Key Concern |
|------|-----------|-------------|
| Architect | AC-ARCH-1 | Schema migration needed for new table |
| Legal | AC-LEG-1 | Photo data subject to retention policy |
| Security | — | No new attack surface |
| Compliance | — | No regulatory impact |

### Stakeholder ACs
- [ ] AC-ARCH-1: <specific, verifiable criterion> — [architect]
- [ ] AC-LEG-1: <specific, verifiable criterion> — [legal]

### Overrides
| AC | Override Reason | Date |
|----|----------------|------|
| (none) | | |
```

**Rules:**
- Max 3 ACs per lens (12 total max). Focus on highest-risk concerns only.
- Each AC must be testable and specific — not vague governance language.
- If a lens finds no concerns, it outputs "—" in the table. This is normal and expected.
- Stakeholder ACs are added to the plan's task list and vertical slices like any other AC.
- The user reviews the enriched plan before approving. They may override any AC by adding a row to the Overrides table with a reason. Overrides are logged, not hidden.
- **This step does NOT invoke other skills.** It reads the lens reference docs and applies them. No `/architect` or `/legal` skill is spawned.

**After presenting the stakeholder review, ask the user:**
> "Stakeholder review complete. [N] ACs added across [M] lenses. Review the plan above — approve, or override specific ACs with a reason."

---

### Step 3 — Task Breakdown
- Break into ordered, atomic tasks
- Each task: ID, title, estimated complexity (S/M/L), dependencies, affected files
- Group into phases if >8 tasks
- Identify parallelizable work

### Step 3b — Vertical Slice Decomposition (tracer-bullet strategy)

> This step runs for ALL plans with complexity M or above. The task list from Step 3 is reorganized into vertical slices. Vertical slicing is the PRIMARY decomposition — phases and complexity (S/M/L) apply WITHIN each slice.

**Principle:** Each slice cuts through ALL integration layers end-to-end. A completed slice is independently demoable and verifiable.

#### Slice Design Rules

1. **End-to-end:** Every slice touches schema → service/API → UI (if applicable) → tests. No "just the database layer" slices.
2. **Independently verifiable:** A completed slice can be demonstrated to a stakeholder. "Here, this works now."
3. **Thin over thick:** Prefer many thin slices over few thick ones. A thin slice implements one user story or one AC.
4. **HITL vs AFK classification:**
   - **HITL (Human-in-the-Loop):** Requires user decisions, design review, or manual testing. Cannot be fully automated.
   - **AFK (Autonomous):** Can be implemented end-to-end by an agent without user input. All decisions resolved, all patterns established.
5. **Dependency ordering:** If Slice B depends on Slice A, Slice A comes first. Blockers are created first.
6. **First slice = tracer bullet:** The FIRST slice establishes the full integration path. It may be the thinnest possible implementation, but it proves the architecture works end-to-end.
7. **UC/AC mapping:** Each slice maps to specific use cases and acceptance criteria from the UCL.

#### Slice Output Format

For each slice in the plan file:

```
### Slice 1: <name> [TRACER BULLET]
**Type:** HITL | AFK
**UC mapping:** UC-V03 AC-1, AC-2
**Demonstrates:** <what a stakeholder can see/verify after this slice>
**Depends on:** — (none, or Slice N)

Tasks (from Step 3, reorganized):
- [ ] T1: Schema — <migration/model change> [S]
- [ ] T2: Service — <business logic> [M]
- [ ] T3: API — <endpoint> [S]
- [ ] T4: UI — <component/screen> [M]
- [ ] T5: Test — <integration test proving the slice works> [S]

Verification: <how to prove this slice works — specific command, URL, or test>
```

#### Relationship to Step 3

Step 3's flat task list (with S/M/L complexity) is NOT replaced. Step 3b REORGANIZES those tasks into vertical slices. Each slice contains tasks from Step 3, grouped by vertical cut rather than horizontal layer.

#### From Grill-Me (`--from-grill-me`)

If `--from-grill-me` is active:
- Read `.claude/state/grill-me.md` — use resolved decisions as requirements
- Skip Step 1 (requirements analysis already done in grill-me session)
- Import the Grill-Me Summary directly as the design basis for Step 2
- If unresolved branches exist, warn and suggest `/grill-me --resume` first

#### Suggestion for complex features

When `/engineering-plan --plan <feature>` is invoked for L/XL complexity without `--from-grill-me`, suggest:
> "This is an L-complexity feature. Consider running `/grill-me <feature> --for-plan` first to resolve design decisions."

This is a suggestion, not a gate.

### Step 4 — Write Plan File
Write to `.claude/data/plans/EP-<NNN>-<slug>.md`:

```markdown
# EP-<NNN>: <Title>

**Status:** PLANNING
**Created:** <YYYY-MM-DD>
**Sprint:** <if assigned>
**Complexity:** <S/M/L/XL>

## Objective
<1-2 sentences>

## Approach
<technical design>

## Stakeholder Review

| Lens | ACs Added | Key Concern |
|------|-----------|-------------|
| Architect | — | |
| Legal | — | |
| Security | — | |
| Compliance | — | |

### Stakeholder ACs
<generated by Step 2b — or "None" if no concerns>

### Overrides
| AC | Override Reason | Date |
|----|----------------|------|
| (none) | | |

## Risks
- <risk>: <mitigation>

## Tasks
- [ ] T1: <task> [S] — <files>
- [ ] T2: <task> [M] — <files>, depends: T1
...

## Dependencies
- <list>

## Vertical Slices

### Slice 1: <name> [TRACER BULLET]
**Type:** HITL | AFK
**UC mapping:** <UC-IDs>
**Demonstrates:** <verifiable outcome>
**Depends on:** —

- [ ] T1: ... [S]
- [ ] T2: ... [M]

**Verification:** <how to verify>

### Slice 2: <name>
...

## Slice Dependency Graph
Slice 1 → Slice 2 → Slice 4
Slice 1 → Slice 3
(Slice 3 and Slice 2 can run in parallel after Slice 1)

## Notes
<freeform>
```

### Step 5 — Update State Files
- Append plan summary to `.claude/state/engineering-plan.md`
- Update `## Engineering Plans` in `.claude/state/triage.md`

---

## Flag: --status

Read all plan files from `.claude/data/plans/EP-*.md`. For each:
1. Parse task checkboxes — calculate completion %
2. Check git log for commits mentioning the plan ID
3. Cross-reference with triage for sprint assignment and delivery status
4. Output summary table

---

## Flag: --update

1. List active plans
2. For each plan the user wants to update:
   - Show current tasks with status
   - Accept task completions, new tasks, blocker notes
   - Update the plan file
   - Update state files and triage

---

## Flag: --close <plan-id>

1. Read the plan file
2. Verify all tasks are done (or explicitly marked as abandoned)
3. Write closing notes: what shipped, what was deferred, lessons learned
4. Set status to DONE or ABANDONED
5. Move plan file to `.claude/data/plans/archive/`
6. Update state files and triage
7. Recommend `/engineering-plan --retrospective` if ≥3 plans closed

---

## State file spec — `.claude/state/engineering-plan.md`

```markdown
# Engineering Plan State

**Last updated:** <YYYY-MM-DD>

## Active Plans

| ID | Title | Status | Progress | Sprint | Blockers |
|----|-------|--------|----------|--------|----------|
| EP-001 | ... | IN PROGRESS | 3/7 | S4 | None |

## Recently Closed

| ID | Title | Outcome | Closed |
|----|-------|---------|--------|
| EP-000 | ... | DONE | 2026-03-20 |

## Patterns & Lessons
- <lessons from retrospectives>
```

---

## Triage Update Protocol

After every operation, update `## Delivery` in `.claude/state/triage.md`:

1. For each selected Scope item you created a plan for, add/update a Delivery entry:
   ```
   **F-NNN: Feature Name**
   Plan: EP-NNN — <title>
   Status: <⬜ Not started | 🔄 In progress | ⬜ Blocked | ✅ Done>
   Progress: <N/M tasks>
   Blocker: <if any>
   ```
2. Update the `### Blockers` table in Delivery if blockers changed
3. When a plan completes, also mark the Scope item as `[x] ~~delivered~~ ✅`
4. If planning reveals new sub-scope, add `- [ ]` items nested under the parent in `## Scope`

**Never** add a `### Recommendations` section. Update Delivery status directly.
**Never** recommend running another skill. Blockers are noted in Delivery; the user decides what to run.

---

## Important constraints

1. **Never commit code** in an engineering-plan run — only touch `.claude/` and `docs/` files.
2. **Plans are living documents** — update them as work progresses, don't create new plans for the same feature.
3. **Plan IDs are sequential** — scan existing EP-*.md files to determine next number.
4. **Keep plans actionable** — every task must have clear acceptance criteria implied by its title.
5. **Respect sprint boundaries** — if a plan spans sprints, note it explicitly and coordinate with product-owner.
6. **Always update triage** — this is how other skills see your work. Never skip this step.
7. **Verify before marking done** — never mark a task ✅ based on conversation context or assumed completion. Before marking any task complete, verify the artifact exists: check the file path, confirm the code is present, or confirm the service runs. If you cannot verify, mark as ⚠️ UNVERIFIED. A commit message or plan saying "script created" is not evidence — the file on disk is. This rule exists because S7 marked 8 deploy scripts as shipped when none existed.
8. **Vertical slices are mandatory for M/L/XL plans.** Any plan with complexity M or above MUST include vertical slice decomposition (Step 3b). S-complexity plans may use flat task lists.
9. **First slice is always the tracer bullet.** The thinnest possible end-to-end implementation that proves the architecture. Never skip this — it de-risks the entire plan.
10. **HITL slices first when they unblock AFK slices.** If a HITL slice resolves design decisions needed by downstream AFK slices, schedule it early so autonomous work can proceed.
11. **Use `yt-dlp` for YouTube data extraction, not HTTP fetch.** YouTube pages are JS-rendered — `WebFetch` and browser automation return empty shells. Use `yt-dlp --write-auto-sub --skip-download` for subtitles/metadata. Install via `brew install yt-dlp` if missing. *(From: feedback_learned_yt_dlp_for_youtube.md)*
12. **Deduplicate VTT subtitles after extraction.** Auto-generated VTT has overlapping time windows producing duplicate consecutive lines. After stripping timestamps and HTML tags, always deduplicate consecutive identical lines before processing. *(From: feedback_learned_vtt_deduplication.md)*
13. **Fix generators before writing hand-written stubs.** When generated files are missing, check `package.json` for existing generation scripts first. Run the generator and read the error. Fix the generator (usually a 1-line path bug) instead of hand-writing stubs that bypass the pipeline, miss transitive outputs, and create maintenance burden. *(From: feedback_learned_fix_generators_not_stubs.md)*

14. **When a plan ends with "Open questions — answer before X starts" and that section has ≥3 questions, treat them as PLAN-BLOCKING, not deferrable. Resolve via AskUserQuestion BEFORE writing the final plan to the plan file.** Failure mode if skipped: user approves the default-laden plan, then provides answers post-approval, then the plan has to be rewritten before any code lands — wasted approval round + scope churn + sometimes already-shipped doc commits. Concrete case (W3-impl, 2026-05-27): 5 "open questions" were defaulted to reasonable choices and pushed through ExitPlanMode. User's answers fundamentally reshaped scope — drop Deepgram dependency entirely, revoke §A.A13 Supabase auth, LinkedIn anti-detection becomes hard constraint (~2-day scope expansion), move MVP3 infra into MVP1. Three of five answers changed WHAT IS BUILT, not just timing. Before ExitPlanMode, scan §"Open questions" / §"Risks + open questions" sections. If any question's answer could plausibly: (a) change which dependencies the implementation uses (e.g., drop a vendor), (b) revoke or amend an already-locked §A/§I decision, (c) change MVP scope by >1 day of work → it's plan-blocking. AskUserQuestion FIRST with multiple-choice where possible. Only ExitPlanMode once all such answers are folded in. *(From: feedback_learned_open_questions_block_plans.md)*

15. **When a user answer revokes a locked §A.* or §I.* decision in `EP-XR-012-ecosystem-integration.md`, the revocation itself becomes a workstream — list affected surfaces before proceeding.** When parsing a user reply, watch for phrases that revoke a locked decision: "X is deprecated," "we're not using X anymore," "X is not functional," "drop X." For each such phrase: (1) Identify the §A/§I block being revoked (grep `EP-XR-012-ecosystem-integration.md` for the named system). (2) Before any next code action, list affected surfaces: original §A/§I block (needs revocation note), `ecosystem-invariants.md` mirror, project CLAUDE.mds referencing the old decision, code implementing it (auth flows, env vars, schema), memory files. (3) Either fold cleanup into current plan OR explicitly accept as tech debt with follow-up ticket — do NOT proceed as if old decision still binds (produces silently broken plans). (4) Save a project memory documenting the revocation (date + user quote) so future sessions know decision is dead. Concrete cases: §A.A13 Supabase Auth revoked by "SUPABASE is not functional" required sweep across orch + Funnel + LCI; §A.A20 HubSpot-writeback-for-funnel-scores revoked by "there is no write back to hubspot" required sweep across 5 docs + full PR plan rewrite. *(From: feedback_learned_user_answers_can_revoke_locked_decisions.md)*
