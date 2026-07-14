---
description: Quality gate — verifies acceptance criteria via tests, scans, and health checks with evidence collection
argument-hint: [--session-start] [--verify <milestone>] [--test] [--health <url>] [--evidence <milestone>] [--report]
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

# quality-gate — Verification & Evidence

You verify acceptance criteria via tests, scans, and health checks. You produce evidence artifacts that gate milestone progression. You are rigorous: if a check cannot run, the verdict is UNKNOWN — never PASS.

## Intercommunication Protocol

All project skills share a common triage state at `.claude/state/triage.md`. This is the single source of truth for cross-skill awareness.

**After every operation**, update the `## Quality Gates` section of `.claude/state/triage.md`:
- Read other sections to inform your decisions (sprint AC from product-owner, security posture from security-review, deployment status from deploy)

**Cross-skill triggers** — after completing your work, recommend the user invoke:
- `/security-review --scan` if tests pass and the milestone is approaching deployment
- `/deploy --plan <env>` if all gates pass for a milestone
- `/product-owner --sync` if acceptance criteria verification reveals scope gaps
- `/milestone --gate <milestone>` to update the milestone's gate status with your results

## Arguments

The user invoked this command with: $ARGUMENTS

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Read triage + quality-gate state, output gate status for all active milestones |
| `--verify <milestone>` | Run all verification checks for a milestone's acceptance criteria |
| `--test` | Run project test suite, capture results as evidence |
| `--health <url>` | HTTP health check against deployed service |
| `--evidence <milestone>` | List all collected evidence for a milestone |
| `--report` | Generate a verification report suitable for stakeholder review |
| (no args) | Same as `--verify` for the current milestone |

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `.claude/state/triage.md` — understand where we are across all skills
2. Read `.claude/state/quality-gate.md` — your domain state
3. Read `.claude/state/milestone.md` — active milestones and their gates
4. Scan `.claude/data/sprints/` — find current sprint AC from product-owner sprint files
5. Scan `.claude/data/evidence/` — inventory existing evidence files
6. Read `docs/architecture.md` — understand system topology for health checks
7. Scan git log (last 20 commits) — understand recent test-relevant changes
```

---

## Flag: --session-start

Output this structured briefing:

```
=== Quality Gate Briefing ===
Project:            <name>
Active milestones:  <count with pending gates>
Evidence files:     <count in .claude/data/evidence/>
──────────────────────────────────
Milestone: M-<NNN> — <title>
  Tests:    <PASS / FAIL / UNKNOWN / NOT RUN>
  Lint:     <PASS / FAIL / UNKNOWN / NOT RUN>
  Health:   <PASS / FAIL / UNKNOWN / NOT RUN>
  AC:       <N/M criteria verified>
  Overall:  <PASS / FAIL / INCOMPLETE>
  Last run: <YYYY-MM-DD or "Never">
──────────────────────────────────
(repeat for each active milestone)

Cross-skill state:
  Sprint:     <from product-owner section of triage>
  Security:   <from security section of triage>
  Deployment: <from deployments section of triage>
  Docs:       <from documentation section of triage>
==================================
```

If no state file exists, bootstrap `.claude/state/quality-gate.md` with empty tables.

---

## Flag: --verify <milestone>

### Step 1 — Load Acceptance Criteria

- Read the milestone file from `.claude/data/milestones/M-<NNN>-*.md`
- Read the current sprint file from `.claude/data/sprints/` — extract acceptance criteria
- Build a checklist of verifiable criteria

### Step 2 — Run Test Suite

- Execute `pytest` in the project root (or discovered test command)
- Capture exit code, summary line (passed/failed/errors), and first 100 lines of output
- Write evidence file to `.claude/data/evidence/<milestone>-tests-<YYYY-MM-DD>.md`
- Verdict: PASS if exit code 0 and no failures; FAIL if any failures; UNKNOWN if pytest cannot run

### Step 3 — Run Lint/Type Checks

- Execute lint command (ruff, flake8, or discovered linter)
- Execute type checker if configured (mypy, pyright)
- Capture results and write evidence file
- Verdict: PASS if zero errors; FAIL if errors found; UNKNOWN if tools not available

### Step 4 — Verify Acceptance Criteria

For each AC item from Step 1:
- Determine how to verify it (test existence, grep for implementation, API check)
- Record verification method and result
- Verdict per criterion: PASS / FAIL / UNKNOWN (cannot be verified automatically)

### Step 5 — Health Check (if deployment URL known)

- Read deployment URL from triage § Deployments or milestone file
- If URL available, run `--health <url>` inline
- If no URL, mark health gate as NOT APPLICABLE

### Step 6 — Compile Gate Verdict

- Overall: PASS only if ALL gates are PASS or NOT APPLICABLE
- Overall: FAIL if any gate is FAIL
- Overall: INCOMPLETE if any gate is UNKNOWN and none are FAIL

### Step 7 — Write Evidence and Update State

- Write per-gate evidence files to `.claude/data/evidence/`
- Update `.claude/state/quality-gate.md`
- Update triage § Quality Gates
- If milestone file exists, update gate status rows in the milestone file

---

## Flag: --test

### Step 1 — Discover Test Configuration

- Check for `pytest.ini`, `pyproject.toml [tool.pytest]`, `setup.cfg [tool:pytest]`
- Check for `package.json` test scripts (for frontend tests)
- Note test directories found

### Step 2 — Run Tests

```bash
# Python tests
cd <project-root> && python -m pytest --tb=short -q 2>&1 | head -200

# Frontend tests (if applicable)
cd <web-dir> && npm test 2>&1 | head -200
```

### Step 3 — Capture Evidence

Write to `.claude/data/evidence/test-run-<YYYY-MM-DD>.md`:

```markdown
# Evidence: Test Run

**Date:** <YYYY-MM-DD HH:MM>
**Verdict:** <PASS / FAIL / UNKNOWN>
**Collected by:** quality-gate --test

## Check Results
- **Backend tests:** <N passed, N failed, N errors>
- **Frontend tests:** <N passed, N failed, N skipped> (or "Not configured")
- **Exit code:** <code>

## Raw Output
<first 100 lines of test output>

## Notes
<any caveats — e.g., "3 tests skipped due to missing fixtures">
```

### Step 4 — Update State

- Update `.claude/state/quality-gate.md` with latest test results
- Update triage § Quality Gates

---

## Flag: --health <url>

### Step 1 — HTTP Health Check

```bash
curl -s -o /dev/null -w "%{http_code} %{time_total}" <url>/health
```

If no `/health` endpoint, try the base URL.

### Step 2 — Validate Response

- Check HTTP status code (200 = PASS, 5xx = FAIL, other = investigate)
- Record response time
- If response body available, check for expected content (e.g., `"status": "ok"`)

### Step 3 — Extended Checks (if applicable)

- Check API versioning endpoint if known
- Check database connectivity indicator in health response
- Record all findings

### Step 4 — Write Evidence

Write to `.claude/data/evidence/health-check-<YYYY-MM-DD>.md`:

```markdown
# Evidence: Health Check

**URL:** <url>
**Date:** <YYYY-MM-DD HH:MM>
**Verdict:** <PASS / FAIL / UNKNOWN>
**Collected by:** quality-gate --health

## Check Results
- **HTTP Status:** <code>
- **Response Time:** <N>ms
- **Body Check:** <PASS / FAIL / SKIPPED>

## Raw Output
<response headers and body excerpt>

## Notes
<any caveats>
```

---

## Flag: --evidence <milestone>

### Step 1 — Inventory Evidence

- Glob `.claude/data/evidence/<milestone>-*.md`
- Also glob `.claude/data/evidence/*` and filter for milestone references in content

### Step 2 — Output Evidence Summary

```
=== Evidence for M-<NNN> ===
Total files: <N>
Last collected: <date>

| File | Gate | Verdict | Date |
|------|------|---------|------|
| M-001-tests-2026-03-22.md | Tests | PASS | 2026-03-22 |
| M-001-lint-2026-03-22.md | Lint | PASS | 2026-03-22 |
| M-001-health-2026-03-22.md | Health | FAIL | 2026-03-22 |
=============================
```

---

## Flag: --report

### Step 1 — Gather All Data

- Read quality-gate state file
- Read all evidence files for active milestones
- Read triage for cross-skill context

### Step 2 — Generate Report

Write to `.claude/data/evidence/verification-report-<YYYY-MM-DD>.md`:

```markdown
# Verification Report

**Generated:** <YYYY-MM-DD HH:MM>
**Generated by:** quality-gate --report

## Executive Summary
<1-2 sentences: overall quality posture>

## Milestone Gate Status

### M-<NNN>: <Title>
| Gate | Verdict | Evidence | Last Checked |
|------|---------|----------|--------------|
| Tests | PASS | [link] | 2026-03-22 |
| Lint | PASS | [link] | 2026-03-22 |
| Health | FAIL | [link] | 2026-03-22 |
| AC | 3/4 | [link] | 2026-03-22 |

**Overall: FAIL**
**Blockers:** Health check returning 503

## Recommendations
- <actionable next steps>

## Evidence Index
- <list of all evidence files with paths>
```

### Step 3 — Update State and Triage

---

## State file spec — `.claude/state/quality-gate.md`

```markdown
# Quality Gate State

**Last updated:** <YYYY-MM-DD>

## Gate Status by Milestone

| Milestone | Tests | Lint | Health | AC | Overall | Last Run |
|-----------|-------|------|--------|----|---------|----------|
| M-001 | PASS | PASS | FAIL | 3/4 | FAIL | 2026-03-22 |

## Recent Runs

| Date | Flag | Milestone | Outcome |
|------|------|-----------|---------|
| 2026-03-22 | --verify M-001 | M-001 | FAIL |
| 2026-03-22 | --test | — | PASS |

## Evidence Inventory

| Milestone | Evidence Files | Last Collected |
|-----------|---------------|----------------|
| M-001 | 4 | 2026-03-22 |

## Notes
<freeform — patterns, recurring failures, environment issues>
```

---

## Evidence file format

All evidence files live in `.claude/data/evidence/` and follow this naming convention:

`<milestone>-<gate>-<YYYY-MM-DD>.md`

Examples:
- `M-001-tests-2026-03-22.md`
- `M-001-lint-2026-03-22.md`
- `M-001-health-2026-03-22.md`
- `M-001-ac-2026-03-22.md`
- `test-run-2026-03-22.md` (standalone --test, no milestone)
- `health-check-2026-03-22.md` (standalone --health, no milestone)
- `verification-report-2026-03-22.md` (--report output)

Standard evidence file structure:

```markdown
# Evidence: <gate name>

**Milestone:** M-<NNN>
**Date:** <YYYY-MM-DD HH:MM>
**Verdict:** PASS | FAIL | UNKNOWN
**Collected by:** quality-gate --<flag>

## Check Results
<structured output from the verification>

## Raw Output
<truncated test/scan output — first 100 lines>

## Notes
<any caveats or partial passes>
```

---

## Triage Update Protocol

After every operation, update `.claude/state/triage.md` § `## Quality Gates`:

```markdown
## Quality Gates
**Updated:** <YYYY-MM-DD HH:MM>
**Last verification:** <milestone> — <PASS/FAIL>

### Gate Status by Milestone
| Milestone | Tests | Lint | Health | AC | Overall |
|-----------|-------|------|--------|----|---------|
| M-001 | PASS | PASS | FAIL | 3/4 | FAIL |

### Evidence Trail
- M-001: 4 evidence files, last collected <date>

### Recommendations
- <what needs fixing before gates can pass>
```

Update the top-level header of `triage.md`:
```
**Last updated:** <YYYY-MM-DD>
**Updated by:** quality-gate --<flag>
```

If `triage.md` does not exist, create it with only the `## Quality Gates` section and a minimal header. Do not create other sections — those belong to other skills.

---

## Important constraints

1. **NEVER fake evidence** — if a check cannot run (missing tool, no test suite, unreachable URL), the verdict is UNKNOWN, never PASS. Document why the check could not run.
2. **NEVER commit feature code** in a quality-gate run — only touch `.claude/` files and evidence artifacts.
3. **Evidence is append-only** — never overwrite previous evidence files. Each run creates a new dated file. Old evidence is the audit trail.
4. **Respect test timeouts** — cap test execution at 5 minutes. If tests hang, kill and record UNKNOWN with a note.
5. **Health checks are non-destructive** — only GET/HEAD requests. Never POST/PUT/DELETE against a live service.
6. **AC verification is honest** — if you cannot automatically verify a criterion (e.g., "UX feels smooth"), mark it UNKNOWN with a note explaining it requires manual verification.
7. **Always update triage** — this is how other skills see your work. Never skip this step.
8. **Read sprint AC from product-owner files** — do not invent acceptance criteria. If no sprint file exists, note it and ask the user.
9. **Evidence directory must exist** — create `.claude/data/evidence/` if it does not exist before writing evidence files.
10. **Post-deploy verification means user-facing, not container-healthy.** When `--health <url>` is used after a deploy, the check MUST go beyond HTTP 200 on a health endpoint. Verify: (a) the login page renders (check response body contains expected `<title>` or form), (b) static assets load (check main JS bundle returns 200), (c) API returns expected response structure (not just status code). A healthy container with broken RBAC, missing assets, or wrong base path is a FAIL, not a PASS. *(Added: 2026-04-05 — containers were healthy for 6 sprints while vue-gen showed admin nav to all roles)*
11. **RBAC is a quality gate.** When verifying a frontend deployment, check that navigation/sidebar returns different items per role. Read the sidebar computed property and verify it branches on user role. If it returns the same nav for all roles, that's a FAIL. Grep for `TODO.*role\|TODO.*RBAC` — any unwired RBAC is a blocking finding.
