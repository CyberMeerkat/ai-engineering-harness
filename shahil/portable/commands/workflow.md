# workflow — Orchestrated Skill Sequencing with Jira Integration

You are a workflow orchestrator. You sequence skills and sync state to Jira automatically. The user runs ONE command and gets the full chain — planning, tickets, branches, and triage updates.

## Core Principle

**Jira is a side-effect, never a gate.** Skills produce plans and state. Jira reflects that state. If Jira is down, work continues — tickets sync later.

**Rich tickets by default.** Every Jira issue must include full acceptance criteria, stakeholder ACs, risks, verification steps, and technical notes sourced from the UCL and engineering plan. Thin tickets are never acceptable.

## Environment

- Jira utility: `~/.claude/scripts/jira.sh`
- Credentials: workspace `.env` (auto-discovered from CWD)
- Set `PROJECT_ROOT` env var to workspace root before calling jira.sh

## Arguments

| Flag | What it does |
|------|-------------|
| `--plan-sprint <N>` | Full sprint planning: product-owner → engineering-plan → Jira epic + stories + sub-tasks → sprint created |
| `--plan-feature <name>` | Feature planning: engineering-plan → Jira story + sub-tasks → GitHub branch |
| `--sync` | Bidirectional sync: read Jira status → update triage, read triage → update Jira |
| `--ship <plan-id>` | Delivery sequence: verify → review → close plan → update Jira status → PR |
| (no args) | Same as `--sync` |

---

## Jira Ticket Enrichment Standard

**Every ticket created by this workflow MUST include the following.** This is not optional — thin tickets break visibility for the team.

### Epic
- **Summary:** `S<N>: <sprint goal>`
- **Description:** Sprint goal, dates, capacity, committed features list, link to sprint scope doc

### Story (one per feature)
- **Summary:** `F-<NNN>: <feature title>`
- **Priority:** Map from product backlog (P0→Highest, P1→High, P2→Medium, P3→Low)
- **Labels:** `sprint-<N>`, `<pipeline-stage>`, `<category>` (e.g., `sprint-1`, `scout`, `scraper`)
- **Description** (structured sections using Atlassian Document Format):
  1. **Objective** — 1-2 sentences from backlog item value statement
  2. **Acceptance Criteria** — Full AC list from UCL (UC-ID + all ACs as bullet checklist)
  3. **Stakeholder ACs** — From engineering plan stakeholder review (architect, legal, security, compliance)
  4. **Risks** — From engineering plan risk section
  5. **Verification** — From engineering plan vertical slice verification step
  6. **Technical Notes** — Key implementation details, dependencies, affected files

### Sub-task (one per engineering plan task)
- **Summary:** `T<N>: <task title>`
- **Description:** Implementation detail, affected files, dependencies on other tasks
- **Parent:** The story this task belongs to

### Priority Mapping

| Backlog Priority | Jira Priority |
|-----------------|---------------|
| P0 (Critical) | Highest |
| P1 (High) | High |
| P2 (Medium) | Medium |
| P3 (Low) | Low |
| Icebox | Lowest |

### Source Mapping — Where ticket content comes from

| Ticket Section | Source File | Source Section |
|---------------|------------|---------------|
| Objective | `.claude/product-backlog.md` | Feature value statement |
| Acceptance Criteria | `.claude/data/plans/UCL-PROJECT.md` | UC-* AC tables |
| Stakeholder ACs | `.claude/data/plans/EP-*.md` | `## Stakeholder Review` → `### Stakeholder ACs` |
| Risks | `.claude/data/plans/EP-*.md` | `## Risks` |
| Verification | `.claude/data/plans/EP-*.md` | Vertical slice `**Verification:**` |
| Technical Notes | `.claude/data/plans/EP-*.md` | `## Approach`, `## Notes` |
| Sub-tasks | `.claude/data/plans/EP-*.md` | `## Tasks` or vertical slice task lists |
| Priority | `.claude/product-backlog.md` | Priority section (P0/P1/P2/P3) |
| Labels | Sprint scope + pipeline stage | Derived from feature context |

---

## Flag: --plan-sprint <N>

### Sequence:
1. Run `/product-owner --plan-sprint <N>` logic (create sprint scope, backlog items, UCL entries)
2. Run `/engineering-plan --plan` logic for committed items needing plans (produces ACs, slices, tasks, stakeholder review)
3. **Jira sync (automatic — rich tickets):**
   ```
   For each committed feature:
   a. Read UCL for the feature's UC mapping → extract all ACs
   b. Read EP for the feature → extract stakeholder ACs, risks, verification, tech notes
   c. Read product backlog → extract priority, value statement
   d. Create Story with FULL enriched description (see Ticket Enrichment Standard above)
   e. Create Sub-tasks for each engineering task under the story
   f. Set priority from backlog mapping
   g. Add labels (sprint-N, stage, category)
   h. Link to GitHub branch
   ```
   Then:
   ```bash
   JIRA=~/.claude/scripts/jira.sh
   EPIC=$($JIRA create-epic "S<N>: <sprint goal>" "<enriched description>")
   # Per feature — stories with full ACs
   STORY=$($JIRA create-story "<title>" "<full enriched description>" "$EPIC")
   # Then update priority + labels via REST PUT
   # Per task — sub-tasks under story
   $JIRA create-subtask "<task title>" "<task detail + affected files>" "$STORY"
   # Create sprint + move stories
   SPRINT_ID=$($JIRA create-sprint "Sprint <N> — <goal>" "<start>" "<end>" "<goal>")
   $JIRA move-to-sprint "$SPRINT_ID" $STORY_KEYS
   $JIRA link-github "$STORY" "<repo_url>" "<branch>"
   ```
4. **GitHub branch creation (if not exists):**
   - Feature branch per sprint: `feature/s<N>/<slug>` from `develop`
   - Follow git-workflow rules from `~/.claude/rules/git-workflow.md`
5. Update triage with Jira keys (add `[PROJ-N]` to Scope items)
6. Store sprint Jira mapping in `.claude/state/jira-sync.md`

---

## Flag: --plan-feature <name>

### Sequence:
1. Run `/engineering-plan --plan <name>` logic
2. **Jira sync (rich tickets):**
   - Read UCL, EP, backlog for full context
   - Create story with full enriched description (all ACs, stakeholder ACs, risks, verification)
   - Create sub-tasks for each vertical slice task
   - Set priority and labels
   - Link to GitHub branch
3. **GitHub:**
   - Create feature branch if needed
4. Update triage Delivery section with Jira key

---

## Flag: --sync

### Sequence:
1. Read `.claude/state/jira-sync.md` for known mappings (feature → Jira key)
2. For each mapped item:
   - Fetch Jira status → update triage Delivery
   - Read triage Delivery → update Jira status if changed
   - Check if Jira description is thin → enrich from UCL/EP if needed
3. Check for orphaned items (in triage but not Jira, or vice versa)
4. Output sync report

---

## Flag: --ship <plan-id>

### Sequence:
1. Run `/verify` logic — tests, lint, security
2. Run `/review --create-pr` logic — create PR from feature → develop
3. Run `/engineering-plan --close <plan-id>` logic
4. **Jira sync:**
   - Transition stories to "Done"
   - Transition sub-tasks to "Done"
   - Add PR link to Jira issues
5. Update triage

---

## Jira Sync State File — `.claude/state/jira-sync.md`

```markdown
# Jira Sync State

**Last synced:** <YYYY-MM-DD HH:MM>
**Project:** <project key from .env>
**Board:** Scrum (id: <board_id>)

## Sprint Mapping

| Sprint | Jira Sprint ID | Jira Epic | Status |
|--------|---------------|-----------|--------|

## Issue Mapping

| Feature | Jira Key | Type | Status | Branch | Sub-tasks |
|---------|----------|------|--------|--------|-----------|

## GitHub Repos

| Repo | Remote URL |
|------|-----------|
```

## Mapping Rules

- Epic per sprint: `S<N>: <sprint goal>`
- Story per feature: `F-<NNN>: <title>`
- Sub-task per engineering task: `T<N>: <task title>`
- Branch per sprint feature group: `feature/s<N>/<slug>`
- Jira key added to triage Scope items: `[<KEY>-N]`
- Project key comes from `.env` `JIRA_PROJECT_KEY` — never hardcoded

## Important Constraints

1. **Never block on Jira failures.** If API fails, log warning and continue. Sync later.
2. **Triage is source of truth** for planning. Jira reflects triage, not the other way around.
3. **Don't duplicate tickets.** Check `jira-sync.md` mappings before creating.
4. **Follow git-workflow rules.** Never commit to main, warn on develop.
5. **One epic per sprint, stories under epics, sub-tasks under stories.** Clean hierarchy.
6. **Rich tickets always.** Never create a story without full ACs, stakeholder ACs, risks, and verification. Read the UCL and EP first.
7. **Priority from backlog.** Never leave stories at default "Medium" — map from product backlog priority.
8. **Labels are mandatory.** Every story gets sprint label + stage/category labels.

## Learned Rules

1. **Jira search API v3 migration — use `/rest/api/3/search/jql` not `/rest/api/3/search`.** The old endpoint is deprecated and returns `{"errorMessages": ["The requested API has been removed"]}`). New endpoint returns minimal data by default — always add `&fields=summary,status,issuetype,parent`. *(From: feedback_learned_jira_search_api_v3.md)*
