# Metrics — Reference Documentation

> Detailed procedures, templates, and checklists for each `/metrics` flag.
> Loaded on demand by the metrics skill dispatcher.

## Triage Integration

After every operation, update `## Metrics & KPIs` in `.claude/state/triage.md`:

```markdown
## Metrics & KPIs
**Updated:** <YYYY-MM-DD HH:MM>
**Defined:** <N> KPIs  |  **Instrumented:** <N>  |  **Unmeasured:** <N>

### KPI Status
| KPI | Category | Target | Current | Instrumented |
|-----|----------|--------|---------|--------------|
| User engagement | Business | >70% DAU | UNMEASURED | NO |
| API error rate | Technical | <1% | 0.3% | YES |

### Milestone Coverage
| Milestone | Success metrics defined | Instrumented |
|-----------|----------------------|--------------|
| M-001 | 3 | 1/3 |

### Recommendations
- <e.g., "Add event tracking to console.vue for user engagement KPI">
```

Also update the inline triage section:

```markdown
## Metrics
**Updated:** <YYYY-MM-DD>
**North star:** <metric name> — <current value> / <target>

### KPI Dashboard
| KPI | Current | Target | Trend | Source |
|-----|---------|--------|-------|--------|
| PSP subscriptions | <N> | 500 | <up/down/flat> | DB query |
| UCL verification | <N>/<total> | 100% | <up> | triage |
| Test pass rate | <N>/<N> | 100% | <up/down> | Jest |
| Brand compliance | <N>% | 95% | <up> | /brand |

### Instrumentation Gaps
- <metrics that should be tracked but aren't>
```

## UCL Integration

The Use Case Log is the shared contract that defines every use case and acceptance criterion. Metrics should reference which UCs drive each KPI to create traceability between business outcomes and user journeys.

**Source of truth:** `.claude/data/plans/UCL-PROJECT.md`
**Triage summary:** `## Use Case Log` section in `.claude/state/triage.md`

### How metrics uses the UCL

1. **Map KPIs to UCs:** every KPI should trace to one or more use cases. PSP subscriptions maps to UC-V01/V02. Order completion maps to UC-C11. Photo uploads map to UC-C08.
2. **UC-driven instrumentation checks:** when running `--check` or `--implementation`, verify that the code paths serving each UC have the analytics calls needed to measure the mapped KPI.
3. **KPI definitions reference UCs:** when defining a new KPI via `--define`, include the UC mapping. "Pack adoption rate (UC-C05, UC-C06)" is traceable. "Pack adoption rate" alone is not.
4. **Milestone metrics inherit UC mappings:** when checking milestone success criteria via `--check <milestone>`, cross-reference the milestone's UC coverage from the UCL to ensure every UI-facing AC has instrumentation.
5. **Dashboard includes UC coverage:** the `--dashboard` output should include a UCL instrumentation line showing how many UC-mapped KPIs are fully instrumented.

### Rules

- Every KPI should have at least one UC mapping — flag unmapped KPIs as "no UC traceability"
- When reporting instrumentation gaps, reference the UC whose user journey is unmeasured
- Never fabricate UC mappings — if a KPI is purely technical (e.g., API latency), it may not map to a specific UC and that is acceptable

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `.claude/state/triage.md` — cross-skill state
2. Read `.claude/state/metrics.md` — your domain state
3. Read `.claude/data/milestones/M-*.md` — milestone success criteria
4. Scan `web/src/` for analytics-related files (analytics.vue, tracking utilities)
5. Grep `web/src/` for tracking/analytics calls (event emitters, analytics.track, gtag, etc.)
6. Grep the project's API directory for logging/metrics endpoints (metrics, counters, usage logs)
7. Check for analytics configuration (environment variables, API keys for analytics services)
8. Read sprint files for feature acceptance criteria that imply metrics
```

---

## Flag: --session-start

Output this structured briefing:

```
=== KPI & Metrics Briefing ===
Project:              <name>
Defined KPIs:         <N>
Instrumented:         <N> (<pct>%)
Unmeasured:           <N>
──────────────────────────────
KPI DASHBOARD
| KPI | Category | Target | Current | Instrumented |
|-----|----------|--------|---------|--------------|
| <name> | <cat> | <target> | <value or UNMEASURED> | YES/NO/PARTIAL |
...

MILESTONE COVERAGE
| Milestone | Metrics defined | Instrumented | Gap |
|-----------|----------------|--------------|-----|
| M-001 | 3 | 1/3 | 2 missing |
...

IMPLEMENTATION GAPS
- <specific gap — e.g., "console.vue has no page view tracking">
...

METRICS HEALTH: <GREEN / YELLOW / RED>
  <1-line justification>
===============================
```

---

## Flag: --define <metric>

### Step 1 — Gather Context
Run Phase 0 context gathering.

### Step 2 — Define the KPI
Prompt for or infer:
- **Name:** clear, descriptive metric name
- **Category:** Business | Engagement | Technical | Adoption
- **Target:** measurable target value with timeframe
- **Data source:** where the data comes from (frontend event, API log, database query, external service)
- **Milestone link:** which milestone this KPI supports (if any)

### Step 3 — Write KPI Definition
Append to `.claude/state/metrics.md` using this format:

```markdown
## KPI: <Name>

**Category:** Business | Engagement | Technical | Adoption
**Target:** <measurable target value>
**Current:** UNMEASURED
**Data source:** <where the data comes from>
**Instrumented:** NO
**Milestone:** M-<NNN> (if linked)

### How to measure
<specific query, API call, or dashboard view to obtain this metric>

### Implementation check
- [ ] Frontend event fires on <action>
- [ ] API logs <metric> to <destination>
- [ ] Dashboard displays this KPI
```

### Step 4 — Verify Instrumentation Feasibility
- Check if the data source exists in the codebase
- Check if the frontend component exists where tracking should be added
- Check if the API endpoint exists where logging should occur
- Note what implementation work is needed

### Step 5 — Update State Files
- Update `.claude/state/metrics.md` with new KPI
- Update `.claude/state/triage.md` section `## Metrics & KPIs`
- If implementation work is needed, recommend `/engineering-plan --update` to create tasks

---

## Flag: --check <milestone>

### Step 1 — Load Milestone
Read `.claude/data/milestones/M-<NNN>-*.md` matching the milestone identifier.

### Step 2 — Extract Success Criteria
Parse the milestone's "Success Criteria" section — each criterion implies one or more measurable metrics.

### Step 3 — Cross-Reference with KPIs
For each success criterion:
1. Find the matching KPI definition in metrics-state.md
2. If no KPI exists, flag it as UNDEFINED
3. If KPI exists, check instrumentation status

### Step 4 — Verify Instrumentation in Code
For each KPI linked to this milestone:

**Frontend checks:**
- Grep `web/src/` for the specific tracking call or event
- Check if the relevant Vue component emits the expected event
- Verify analytics.vue (or equivalent dashboard page) has a data source for this KPI
- Check for page view tracking on relevant pages

**API checks:**
- Grep the project's API directory for logging or metrics collection related to this KPI
- Check if usage counters or event logs capture the relevant action
- Verify API middleware logs request metrics (latency, error rate, endpoint usage)

**Infrastructure checks:**
- Check if CloudWatch metrics or log groups capture the needed data
- Verify health check endpoints report the right signals

### Step 5 — Produce Coverage Report

```
MILESTONE METRICS CHECK — M-<NNN>: <title>

| Success Criterion | KPI | Instrumented | Evidence |
|-------------------|-----|--------------|----------|
| Users can activate packs | Pack adoption rate | PARTIAL | API logs activation, no frontend event |
| Error rate < 1% | API error rate | YES | Middleware logs all 5xx |
| Users see PCE profile | PCE engagement | NO | No tracking in PceProfilePanel.vue |

Coverage: 1/3 fully instrumented
Verdict: FAIL — 2 metrics need implementation work

Required actions:
1. Add event tracking to PceProfilePanel.vue for PCE engagement
2. Add frontend event to pack activation flow
3. Re-run /metrics --check M-001 after implementation
```

### Step 6 — Update State Files

---

## Flag: --implementation

### Step 1 — Full Codebase Analytics Audit

**Frontend scan:**
- Glob `web/src/**/*.vue` — list all Vue components
- Grep each for analytics/tracking calls: `track`, `event`, `gtag`, `analytics`, `logEvent`, `emit('track`
- Grep for page view tracking: `pageview`, `page_view`, `router.afterEach`
- Check `web/src/pages/` — every page should have at least a page view event
- Check interactive components (buttons, forms, modals) — key user actions should be tracked
- Verify analytics.vue exists and has data sources

**API scan:**
- Grep the project's API directory for metrics/logging: `logger`, `metrics`, `counter`, `gauge`, `histogram`, `timing`
- Check middleware for request logging (latency, status codes, endpoint)
- Check for usage tracking on key endpoints (auth, pack activation, PCE, chat)
- Verify health check endpoint exists and reports useful signals

**Infrastructure scan:**
- Check for CloudWatch log group configuration
- Check for metrics export (Prometheus, StatsD, CloudWatch custom metrics)
- Check CI/CD for analytics-related steps

### Step 2 — Gap Analysis

For every user-facing feature, verify basic usage tracking exists:
- **Login/auth:** login attempts, success/failure rate
- **Console (main chat):** messages sent, responses received, session duration
- **Admin panel:** admin actions (user management, config changes)
- **PCE:** profile views, context resets, signal collection
- **Packs:** activation, deactivation, usage per pack
- **Telegram:** commands used, message throughput

### Step 3 — Produce Implementation Report

```
ANALYTICS IMPLEMENTATION AUDIT

Frontend Coverage:
| Page/Component | Page View | User Actions | Events Found |
|----------------|-----------|--------------|--------------|
| console.vue | YES | 2/5 | track_message, track_session |
| admin.vue | NO | 0/3 | — |
| login.vue | YES | 1/1 | track_login |
| PceProfilePanel.vue | NO | 0/2 | — |

API Coverage:
| Endpoint Group | Request Logging | Usage Metrics | Error Tracking |
|----------------|-----------------|---------------|----------------|
| /api/auth/ | YES | YES | YES |
| /api/chat/ | YES | NO | YES |
| /api/packs/ | YES | NO | NO |
| /api/pce/ | NO | NO | NO |

Overall Coverage: <N>% of features have basic tracking
Grade: <A / B / C / D / F>

Priority Implementation Tasks:
1. [HIGH] Add page view tracking to admin.vue
2. [HIGH] Add usage metrics to /api/pce/ endpoints
3. [MEDIUM] Add pack activation tracking to frontend
4. [LOW] Add session duration tracking to console.vue
```

### Step 4 — Update State Files

---

## Flag: --dashboard

### Step 1 — Gather All KPI Data
Read `.claude/state/metrics.md` — collect all defined KPIs.

### Step 2 — Check Current Values
For instrumented KPIs, determine current values:
- Check API logs/endpoints for technical metrics
- Check frontend tracking code for engagement metrics
- Mark UNMEASURED for KPIs without instrumentation

### Step 3 — Generate Dashboard

```
=== KPI DASHBOARD ===
Generated: <YYYY-MM-DD HH:MM>

BUSINESS METRICS
| KPI | Target | Current | Trend | Status |
|-----|--------|---------|-------|--------|
| <name> | <target> | <value> | <up/down/flat> | ON/BELOW/ABOVE TARGET |

ENGAGEMENT METRICS
| KPI | Target | Current | Trend | Status |
|-----|--------|---------|-------|--------|

TECHNICAL METRICS
| KPI | Target | Current | Trend | Status |
|-----|--------|---------|-------|--------|

ADOPTION METRICS
| KPI | Target | Current | Trend | Status |
|-----|--------|---------|-------|--------|

UNMEASURED (action needed)
- <KPI name> — <what's missing>

Summary: <N> KPIs on target, <N> below, <N> unmeasured
=====================
```

### Step 4 — Update State Files

---

## Flag: --review <period>

### Step 1 — Determine Review Window
Parse period argument: `7d`, `14d`, `30d`, `sprint`, or specific date range.

### Step 2 — Gather Data for Period
- Git log for the period — what shipped
- KPI values at start vs end of period (from state file history if available)
- Incidents or issues during period (from triage)
- Deployments during period (from deploy state)

### Step 3 — Produce Review

```
=== METRICS REVIEW — <period> ===
Period: <start> to <end>

FEATURES SHIPPED
- <feature with date>

KPI MOVEMENT
| KPI | Start | End | Delta | Interpretation |
|-----|-------|-----|-------|----------------|
| User engagement | 60% | 65% | +5% | Improving after console redesign |
| Error rate | 0.5% | 0.3% | -0.2% | Improved after hotfix |

NOTABLE CHANGES
- <significant metric movement with likely cause>

AREAS OF CONCERN
- <metrics moving in wrong direction>

RECOMMENDATIONS
- <data-driven suggestions for next period>
=================================
```

### Step 4 — Update State Files

---

## State file spec — `.claude/state/metrics.md`

```markdown
# Metrics State

**Last updated:** <YYYY-MM-DD>

## Summary

Defined KPIs: <N>
Instrumented: <N>
Unmeasured: <N>
Implementation grade: <A-F>

## KPI Definitions

<KPI definition blocks — see format below>

## Milestone Coverage

| Milestone | Metrics Defined | Instrumented | Verdict |
|-----------|----------------|--------------|---------|

## Implementation Audit

**Last audit:** <YYYY-MM-DD>
**Frontend coverage:** <N>%
**API coverage:** <N>%

## Metrics Log

| Date | Event | Detail |
|------|-------|--------|
```

---

## KPI Definition Format

Each KPI is defined as a section within `.claude/state/metrics.md`:

```markdown
## KPI: <Name>

**Category:** Business | Engagement | Technical | Adoption
**Target:** <measurable target value>
**Current:** <current value or UNMEASURED>
**Data source:** <where the data comes from>
**Instrumented:** YES | NO | PARTIAL
**Milestone:** M-<NNN> (if linked)

### How to measure
<specific query, API call, or dashboard view to obtain this metric>

### Implementation check
- [ ] Frontend event fires on <action>
- [ ] API logs <metric> to <destination>
- [ ] Dashboard displays this KPI
```

**KPI Categories:**
- **Business:** Revenue, conversion, retention, user growth — the metrics stakeholders care about
- **Engagement:** DAU, session duration, messages sent, features used — how actively users interact
- **Technical:** Error rate, latency, uptime, build time — system health indicators
- **Adoption:** Feature activation rate, pack usage, new feature uptake — are users discovering and using new capabilities

---

## Important Constraints

1. **Never commit code** in a metrics run — only touch `.claude/` files. If instrumentation code needs to be written, output the required changes as recommendations and suggest `/engineering-plan --update` to create implementation tasks.
2. **Never fabricate metric values** — if a metric cannot be measured, its value is UNMEASURED, not an estimate. The value of this skill is honest assessment of what is and isn't tracked.
3. **Every user-facing feature should have basic usage tracking** — at minimum a page view event for pages and an action event for key interactions. Flag features without any tracking as gaps.
4. **Verify analytics.vue has data sources** — the dashboard page must be connected to actual data. A dashboard that displays nothing is worse than no dashboard (it creates false confidence).
5. **Always update triage** — this is how other skills (especially `/launch` and `/milestone`) see metrics readiness.
6. **KPIs must be SMART** — Specific, Measurable, Achievable, Relevant, Time-bound. Reject vague metrics like "improve user experience" — demand measurable targets.
7. **Cross-reference milestones** — every milestone should have at least one measurable success criterion with a corresponding KPI. If a milestone has no metrics, flag it immediately.
8. **Implementation audit is non-destructive** — `--implementation` only reads code and reports findings. It never modifies application source code.
9. **Four categories are exhaustive** — every KPI must fit into Business, Engagement, Technical, or Adoption. If it doesn't fit, reconsider whether it's a real KPI.
10. **Instrumentation status is tristate** — YES (fully tracked end-to-end), PARTIAL (some tracking exists but incomplete), NO (nothing in place). Never mark PARTIAL as YES.
