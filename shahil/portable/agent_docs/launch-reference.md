# Launch — Reference Documentation

> Detailed procedures, templates, and checklists for each `/launch` flag.
> Loaded on demand by the launch skill dispatcher.

## Triage Integration

After every operation, update `.claude/state/triage.md` section `## Launch Readiness`:

```markdown
## Launch Readiness
**Updated:** <YYYY-MM-DD HH:MM>
**Active launches:** <N>

### Upcoming
| Launch | Target | Go/No-Go | Milestone |
|--------|--------|----------|-----------|
| L-001 | 2026-04-01 | 4/6 GREEN | M-001 |

### Blockers
- <what's preventing go — with affected launch ID>

### Recommendations
- <cross-skill actions — e.g., "Need /brand --check before L-001 go/no-go">
```

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `.claude/state/triage.md` — cross-skill state
2. Read `.claude/state/launch.md` — your domain state
3. Scan launch files in `.claude/data/launches/L-*.md`
4. Read `.claude/data/milestones/M-*.md` — milestone dependencies for launches
5. Read `.claude/state/metrics.md` — KPI instrumentation status
6. Check docs/ for user-facing documentation readiness
7. Check web/src/ for in-app notification or announcement components
8. Read docs/architecture.md section "Active gaps" — known risks that could affect launch
```

---

## Flag: --session-start

Output this structured briefing:

```
=== Launch Readiness Briefing ===
Project:         <name>
Active launches: <N>
──────────────────────────────
UPCOMING LAUNCHES
  L-<NNN>: <title> — <status> (target: <date>)
    Milestone: M-<NNN> — <PASSED / NOT PASSED>
    Go/No-Go: <N/6 GREEN>
    Blockers: <count or "none">
  ...

CHANNEL STATUS
  In-app:    <READY / NOT CONFIGURED>
  Telegram:  <READY / NOT CONFIGURED>
  Email:     <READY / NOT CONFIGURED>
  Landing:   <READY / NOT CONFIGURED>
  Social:    <READY / NOT CONFIGURED>

ASSET READINESS
  <N> assets complete / <M> total

LAUNCH HEALTH: <GREEN / YELLOW / RED>
  <1-line justification>
=================================
```

---

## Flag: --plan <launch>

### Step 1 — Gather Context
Run Phase 0 context gathering.

### Step 2 — Determine Launch ID
- Scan `.claude/data/launches/` for existing launch files
- Assign next sequential ID: `L-<NNN>`
- Generate slug from launch title (lowercase, hyphenated)

### Step 3 — Create Launch Plan File
Create `.claude/data/launches/L-<NNN>-<slug>.md` using this format:

```markdown
# L-<NNN>: <Launch Title>

**Status:** PLANNING
**Target date:** <YYYY-MM-DD>
**Milestone dependency:** M-<NNN>

## What's Launching
<1-2 sentences — the user-facing change>

## Audience
<who sees this, how they'll discover it>

## Channels
| Channel | Status | Owner | Notes |
|---------|--------|-------|-------|
| In-app notification | NOT STARTED | Engineering | — |
| Telegram announcement | NOT STARTED | Marketing | — |
| Email to existing users | NOT STARTED | Marketing | — |
| Landing page update | NOT STARTED | Design | — |
| Social media | NOT STARTED | Marketing | — |

## Assets Required
- [ ] Feature announcement copy
- [ ] Updated screenshots
- [ ] Help documentation
- [ ] Email template
- [ ] Social media posts
- [ ] In-app notification text
- [ ] Telegram bot announcement text

## Go/No-Go Criteria
| Dimension | Criterion | Status |
|-----------|-----------|--------|
| Product | All sprint AC met | PENDING |
| Engineering | Deployed to prod, health GREEN | PENDING |
| Docs | User-facing docs updated | PENDING |
| Brand | Assets consistent with brand guidelines | PENDING |
| Security | No critical vulnerabilities | PENDING |
| Metrics | KPI tracking in place | PENDING |

## Rollback Plan
<what to do if launch goes badly — feature flags, revert deploy, comms plan>

## Post-Launch Success Criteria
<how we'll know in 7 days if this was successful — measurable outcomes>
```

### Step 4 — Update State Files
- Update `.claude/state/launch.md`
- Update `.claude/state/triage.md` section `## Launch Readiness`

---

## Flag: --checklist <launch>

### Step 1 — Load Launch File
Read `.claude/data/launches/L-<NNN>-*.md` matching the launch identifier.

### Step 2 — Evaluate Each Checklist Dimension

**Product readiness:**
- Read milestone file — check if all gates are PASSED
- Read sprint state — confirm all committed items shipped
- Cross-reference product-owner sprint file

**Engineering readiness:**
- Read deploy state — confirm deployed to target environment
- Read quality-gate state — confirm verification passed
- Check health endpoint status

**Documentation readiness:**
- Scan `docs/` for user-facing guides covering the launched feature
- Check if help text / tooltips exist in frontend components
- Verify API docs are current

**Brand readiness:**
- Read brand state — confirm compliance score
- Check that marketing assets match brand guidelines
- Verify screenshots are current

**Security readiness:**
- Read security state — confirm no CRITICAL or HIGH vulnerabilities
- Verify auth coverage for new endpoints

**Metrics readiness:**
- Read metrics state — confirm KPIs are instrumented
- Verify analytics tracking is in place for launched features

### Step 3 — Output Checklist
```
LAUNCH CHECKLIST — L-<NNN>: <title>

| Dimension | Items | Done | Status |
|-----------|-------|------|--------|
| Product | 3 | 2 | YELLOW |
| Engineering | 4 | 4 | GREEN |
| Docs | 2 | 0 | RED |
| Brand | 2 | 1 | YELLOW |
| Security | 2 | 2 | GREEN |
| Metrics | 3 | 1 | RED |

OVERALL: <N/M dimensions GREEN> — <GO / NOT READY>

Pending items:
- [ ] <specific action needed>
- [ ] <specific action needed>
```

### Step 4 — Update Launch File
Write updated statuses back to the launch plan file.

---

## Flag: --go-no-go <launch>

### Step 1 — Run All Dimension Checks
This is the critical gate. Every dimension must be GREEN.

**For each of the 6 dimensions:**
1. **Product:** Read milestone file — status must be PASSED. Read sprint — all AC met.
2. **Engineering:** Read deploy state — must be deployed to prod with GREEN health. Read quality-gate — all gates PASS.
3. **Docs:** Verify user-facing documentation exists for every feature in the launch scope.
4. **Brand:** Read brand state — compliance score must be above threshold (90%+). All marketing assets reviewed.
5. **Security:** Read security state — posture must be CLEAN or LOW. No CRITICAL or HIGH open items.
6. **Metrics:** Read metrics state — all KPIs linked to the launch milestone must be instrumented (YES or PARTIAL).

### Step 2 — Produce Go/No-Go Verdict

```
=== GO/NO-GO ASSESSMENT — L-<NNN>: <title> ===
Target date: <YYYY-MM-DD>
Milestone:   M-<NNN> — <status>

| Dimension | Status | Evidence | Verdict |
|-----------|--------|----------|---------|
| Product | All 5 AC met | Sprint file S-004 | GO |
| Engineering | Deployed rev 93 | Health: 200 OK | GO |
| Docs | 2/3 guides written | Missing: API guide | NO-GO |
| Brand | 94% compliance | Brand state | GO |
| Security | CLEAN | Last scan: today | GO |
| Metrics | 3/3 instrumented | Metrics state | GO |

VERDICT: NO-GO (1 dimension failing)

Required actions before GO:
1. Write API guide for new endpoints → /doc-rules --check
2. Re-run /launch --go-no-go L-001 after fix

===================================================
```

### Step 3 — Update Launch File
Set status to READY if all GREEN, keep at PLANNING if any NO-GO.

### Step 4 — Update State Files

---

## Flag: --assets <launch>

### Step 1 — Load Launch File
Read the launch plan's "Assets Required" section.

### Step 2 — Scan for Existing Assets
- Check `web/public/assets/` for images/screenshots
- Check `docs/` for help documentation
- Grep codebase for notification/announcement text
- Check for email templates in project

### Step 3 — Produce Asset Inventory

```
ASSET INVENTORY — L-<NNN>: <title>

| Asset | Status | Location | Notes |
|-------|--------|----------|-------|
| Feature announcement copy | DONE | launches/L-001 section copy | — |
| Updated screenshots | NOT STARTED | — | Need: console, admin views |
| Help documentation | IN PROGRESS | docs/integrations/ | Missing: PCE guide |
| Email template | NOT STARTED | — | — |
| Social media posts | NOT STARTED | — | — |
| In-app notification text | DONE | web/src/components/... | — |
| Telegram announcement | NOT STARTED | — | — |

Progress: 2/7 assets ready
```

### Step 4 — Update Launch File
Update the "Assets Required" checklist with current statuses.

---

## Flag: --channels

### Step 1 — Audit All Communication Channels

**In-app notifications:**
- Grep `web/src/` for notification components, toast/alert systems
- Check if there's a notification banner or announcement component
- Verify feature flag or toggle mechanism exists

**Telegram:**
- Check if Telegram bot is configured and running (read triage section Deployments)
- Verify broadcast/announcement command exists
- Check `api/` for Telegram announcement endpoints

**Email:**
- Check for email sending capability (SMTP config, email templates)
- Verify email list management exists
- Check for unsubscribe compliance

**Landing page:**
- Check `web/src/pages/` for public-facing pages
- Verify landing page can be updated independently
- Check for feature showcase sections

**Social media:**
- Check for social meta tags in HTML
- Verify Open Graph tags are correct
- Check for share functionality

### Step 2 — Output Channel Status

```
CHANNEL AUDIT

| Channel | Configured | Ready for Launch | Gap |
|---------|------------|------------------|-----|
| In-app | YES | YES | — |
| Telegram | YES | PARTIAL | No broadcast cmd |
| Email | NO | NO | No SMTP config |
| Landing page | YES | YES | — |
| Social media | PARTIAL | NO | Missing OG tags |

Recommendations:
- Set up SMTP for email channel
- Add /broadcast command to Telegram bot
- Add Open Graph meta tags to index.html
```

---

## Flag: --post-launch <launch>

### Step 1 — Gather Post-Launch Data
- Read launch file — check post-launch success criteria
- Read metrics state — KPI values since launch
- Check deploy state — any incidents since launch?
- Check quality-gate state — any failures since launch?
- Scan git log for hotfixes or patches since launch date

### Step 2 — Produce Post-Launch Review

```
=== POST-LAUNCH REVIEW — L-<NNN>: <title> ===
Launched: <YYYY-MM-DD>
Review date: <YYYY-MM-DD>
Days since launch: <N>

## Metrics Performance
| KPI | Target | Actual | Status |
|-----|--------|--------|--------|
| User engagement | >70% | 65% | BELOW TARGET |
| Error rate | <1% | 0.2% | ON TARGET |
| Feature adoption | >30% | 45% | ABOVE TARGET |

## Issues Since Launch
- <issue with severity and resolution status>

## Hotfixes Deployed
- <commit/deploy with date>

## User Feedback
- <summarized feedback from channels>

## Verdict
<SUCCESS / PARTIAL SUCCESS / NEEDS ATTENTION>
<1-2 sentence summary>

## Follow-up Actions
- <specific actions based on review>
=============================================
```

### Step 3 — Update Launch File
Set status to POST-LAUNCH, record review findings.

### Step 4 — Update State Files

---

## State file spec — `.claude/state/launch.md`

```markdown
# Launch State

**Last updated:** <YYYY-MM-DD>

## Active Launches

| ID | Title | Status | Target | Milestone | Go/No-Go |
|----|-------|--------|--------|-----------|----------|

## Channel Configuration

| Channel | Status | Last Verified |
|---------|--------|---------------|
| In-app | CONFIGURED | <date> |
| Telegram | CONFIGURED | <date> |
| Email | NOT CONFIGURED | — |
| Landing page | CONFIGURED | <date> |
| Social media | PARTIAL | <date> |

## Recent Launches

| ID | Title | Launched | Verdict |
|----|-------|----------|---------|

## Launch Log

| Date | Event | Detail |
|------|-------|--------|
```

---

## Launch Plan File Format — `.claude/data/launches/L-<NNN>-<slug>.md`

```markdown
# L-<NNN>: <Launch Title>

**Status:** PLANNING | READY | GO | LAUNCHED | POST-LAUNCH
**Target date:** <YYYY-MM-DD>
**Milestone dependency:** M-<NNN>

## What's Launching
<1-2 sentences — the user-facing change>

## Audience
<who sees this, how they'll discover it>

## Channels
| Channel | Status | Owner | Notes |
|---------|--------|-------|-------|
| In-app notification | NOT STARTED | Engineering | — |
| Telegram announcement | NOT STARTED | Marketing | — |
| Email to existing users | NOT STARTED | Marketing | — |
| Landing page update | NOT STARTED | Design | — |
| Social media | NOT STARTED | Marketing | — |

## Assets Required
- [ ] Feature announcement copy
- [ ] Updated screenshots
- [ ] Help documentation
- [ ] Email template
- [ ] Social media posts
- [ ] In-app notification text
- [ ] Telegram bot announcement text

## Go/No-Go Criteria
| Dimension | Criterion | Status |
|-----------|-----------|--------|
| Product | All sprint AC met | PENDING |
| Engineering | Deployed to prod, health GREEN | PENDING |
| Docs | User-facing docs updated | PENDING |
| Brand | Assets consistent with brand guidelines | PENDING |
| Security | No critical vulnerabilities | PENDING |
| Metrics | KPI tracking in place | PENDING |

## Rollback Plan
<what to do if launch goes badly — feature flags, revert deploy, comms plan>

## Post-Launch Success Criteria
<how we'll know in 7 days if this was successful — measurable outcomes>
```

---

## Important Constraints

1. **Never commit code** in a launch run — only touch `.claude/` files and docs.
2. **Launch depends on milestone PASSED** — never recommend GO if the linked milestone has not passed all gates. The milestone is the engineering quality foundation; the launch is the market-facing layer on top.
3. **Go/no-go checks ALL 6 dimensions** — Product, Engineering, Docs, Brand, Security, Metrics. A single RED dimension means NO-GO. There is no partial launch.
4. **Be specific about gaps** — don't say "docs need work"; say "missing API guide for PCE endpoints". Actionable gaps lead to faster resolution.
5. **Always update triage** — this is how other skills see launch readiness status.
6. **Track all 5 channels** — in-app, Telegram, email, landing page, social. Even if a channel is not used for a particular launch, record it as N/A rather than omitting it.
7. **Post-launch review is mandatory** — every launch should have a review within 7 days. If the user doesn't trigger it, recommend it.
8. **Asset tracking is granular** — each asset has a status (NOT STARTED, IN PROGRESS, DONE) and a location when complete.
9. **Rollback plans are not optional** — every launch plan must have a rollback section. If the user doesn't provide one, prompt for it.
10. **Never auto-launch** — the GO decision always requires explicit user approval, even if all dimensions are GREEN.
