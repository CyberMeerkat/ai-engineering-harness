---
description: Security review — scans for vulnerabilities, gates deployments, tracks CVEs, and maintains compliance posture
argument-hint: [--session-start] [--scan] [--cves] [--compliance] [--gate <milestone>] [--remediate] [--audit-trail]
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

# security-review — Security Posture

You assess and maintain the project's security posture. You read scan results (Trivy, SonarQube), check for secrets in code, validate auth middleware coverage, gate deployments, track CVEs, and maintain a compliance checklist. You never auto-suppress vulnerabilities — you report and suggest.

## Intercommunication Protocol

All project skills share a common triage state at `.claude/state/triage.md`. This is the single source of truth for cross-skill awareness.

**After every operation**, update the `## Security` section of `.claude/state/triage.md`:
- Read other sections to inform your decisions (deployment status from deploy, quality gates from quality-gate, engineering plans for new attack surface)

**Cross-skill triggers** — after completing your work, recommend the user invoke:
- `/quality-gate --verify <milestone>` if security gates pass and quality verification is pending
- `/deploy --plan <env>` if security posture is CLEAN or LOW and deployment is next
- `/sonar-fix` if SonarQube findings need code-level remediation
- `/milestone --gate <milestone>` to update the milestone's security gate status
- `/engineering-plan --plan` if a vulnerability requires architectural changes

## Triage Integration

After every operation, update `## Security` in `.claude/state/triage.md`:

```markdown
## Security
**Updated:** <YYYY-MM-DD>
**Posture:** GREEN / YELLOW / RED
**Last scan:** <date> — <scope>

### Findings
| Severity | Count | Fixed | Open |
|----------|-------|-------|------|
| CRITICAL | <N> | <N> | <N> |
| HIGH | <N> | <N> | <N> |

### CVE Tracking
- <open CVEs with affected packages>

### Recommendations
- <prioritized fixes>
```

## Use Case Log (UCL) Integration

Security findings that affect acceptance criteria must reference UC IDs. A vulnerability in the vendor auth flow maps to UC-V05/V06. A PII leak maps to the affected consumer journey. This lets product-owner trace security issues back to delivery items.

## Arguments

The user invoked this command with: $ARGUMENTS

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Read triage + security state, output security posture summary |
| `--scan` | Run/read latest security scan results (Trivy for containers, SonarQube for code) |
| `--cves` | List known CVEs affecting the project, with severity and fix status |
| `--compliance` | Check compliance requirements (secrets management, auth, data handling) |
| `--gate <milestone>` | Security gate check for a milestone — PASS/FAIL with evidence |
| `--remediate` | Suggest fixes for found vulnerabilities (integrates with `/sonar-fix`) |
| `--audit-trail` | Output security audit trail — who reviewed what, when |
| (no args) | Same as `--scan` |

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `.claude/state/triage.md` — understand where we are across all skills
2. Read `.claude/state/security.md` — your domain state
3. Read `.trivyignore` if it exists — accepted risks
4. Scan for Trivy config/output files (trivy.yaml, trivy-results.json, etc.)
5. Scan for SonarQube config (sonar-project.properties, .sonarcloud.properties)
6. Read Dockerfiles — understand container base images and installed packages
7. Read `docs/architecture.md` — understand auth model, data handling, external integrations
8. Read CI workflow files (.github/workflows/*.yml) — understand existing security CI steps
9. Scan git log (last 20 commits) — check for security-related changes
10. Read `the project's API route directory` route files — understand API surface for auth audit
```

---

## Flag: --session-start

Output this structured briefing:

```
=== Security Posture Briefing ===
Project:          <name>
Posture:          <CLEAN / LOW / MEDIUM / HIGH / CRITICAL>
Last scan:        <date or "Never">
Open findings:    <count by severity>
Accepted risks:   <count from .trivyignore>
───────────────────────────────────
Vulnerability Summary:
  CRITICAL:  <N>
  HIGH:      <N>
  MEDIUM:    <N>
  LOW:       <N>
  ACCEPTED:  <N> (in .trivyignore)
───────────────────────────────────
Compliance:
  Secrets management:    <PASS / FAIL / UNCHECKED>
  Auth coverage:         <PASS / FAIL / UNCHECKED>
  Dependency freshness:  <PASS / FAIL / UNCHECKED>
───────────────────────────────────
Cross-skill state:
  Quality gates: <from quality-gate section of triage>
  Deployment:    <from deployments section of triage>
  Sprint:        <from product-owner section of triage>
===================================
```

If no state file exists, bootstrap `.claude/state/security.md` with empty tables and recommend `--scan`.

---

## Flag: --scan

### Step 1 — Container Vulnerability Scan (Trivy)

- Check if Trivy is installed: `which trivy`
- If available, scan Dockerfiles and built images:
  ```bash
  trivy image --severity HIGH,CRITICAL --format json <image-name> 2>&1 | head -500
  ```
- If Trivy is not installed, check for existing scan output files (trivy-results.json, etc.)
- If no scan data is available, note as UNKNOWN and recommend installing Trivy

### Step 2 — Code Vulnerability Scan (SonarQube)

- Check for SonarQube results via sonar-issues helper if available
- Check for existing SonarQube report files
- If `/sonar-fix` skill data exists, read its findings
- Cross-reference with known code quality issues

### Step 3 — Dependency Vulnerability Check

- Python: check `requirements.txt` or `pyproject.toml` — look for known vulnerable versions
  ```bash
  pip audit --format json 2>&1 | head -200
  ```
- Node: check `package-lock.json` — look for known vulnerable packages
  ```bash
  cd <web-dir> && npm audit --json 2>&1 | head -200
  ```
- If audit tools are not available, manually check critical dependencies against known CVE databases

### Step 4 — Secret Detection

- Grep for patterns that indicate hardcoded secrets:
  - API keys, tokens, passwords in source files (not .env.example or docs with `<placeholder>`)
  - `.env` files that are tracked by git (should be in .gitignore)
  - Private keys or certificates in the repo
  - Connection strings with embedded credentials
- Exclude: `.env.example`, test fixtures with obvious fake values, documentation using `<placeholder>` format
- Check `.gitignore` includes: `.env`, `*.pem`, `*.key`, `credentials.json`

### Step 5 — Auth Middleware Coverage

- Read API route definitions from `the project's API route directory`
- Identify all route handlers and their auth decorators/dependencies
- Check that non-public routes have auth middleware applied
- Flag any routes missing authentication

### Step 6 — Compile Findings

- Aggregate all findings by severity: CRITICAL / HIGH / MEDIUM / LOW
- Cross-reference with `.trivyignore` — mark accepted risks
- Calculate overall posture:
  - CRITICAL: any CRITICAL finding open
  - HIGH: any HIGH finding open (no CRITICALs)
  - MEDIUM: only MEDIUM or lower open
  - LOW: only LOW findings open
  - CLEAN: no open findings

### Step 7 — Update State and Triage

- Write findings to `.claude/state/security.md`
- Update triage § Security
- Write evidence file to `.claude/data/evidence/<milestone>-security-<date>.md` if milestone context exists

---

## Flag: --cves

### Step 1 — Gather CVE Data

- Read security state file for previously identified CVEs
- Read Trivy output for container CVEs
- Read dependency audit output for library CVEs
- Check `.trivyignore` for accepted CVEs

### Step 2 — Output CVE Report

```
=== CVE Report ===
Total:    <N> known CVEs
Open:     <N>
Fixed:    <N>
Accepted: <N>

| CVE ID | Severity | Component | Version | Fix Available | Status |
|--------|----------|-----------|---------|---------------|--------|
| CVE-2026-XXXX | HIGH | fastapi | 0.109.0 | 0.110.0 | OPEN |
| CVE-2026-YYYY | MEDIUM | pillow | 10.2.0 | 10.3.0 | ACCEPTED |
==================
```

### Step 3 — Recommendations

For each OPEN CVE with a fix available:
- Specify the exact version upgrade needed
- Note any breaking changes in the fix version
- Recommend `/sonar-fix` for code-level remediations

---

## Flag: --compliance

### Step 1 — Secrets Management Check

- Verify `.env` is in `.gitignore`
- Verify no tracked files contain hardcoded secrets (re-run secret detection)
- Check that sensitive config is loaded from environment variables, not hardcoded
- Check that API keys / tokens are documented as required env vars (in docs/reference/paths.md or equivalent)
- Verdict: PASS / FAIL

### Step 2 — Auth Coverage Check

- Map all API routes
- Verify auth middleware is applied to non-public routes
- Check for proper role-based access control if applicable
- Verify session/token handling follows security best practices (expiry, refresh, etc.)
- Verdict: PASS / FAIL

### Step 3 — Data Handling Check

- Check for PII handling patterns (logging, storage, transmission)
- Verify database queries use parameterized statements (no SQL injection risk)
- Check CORS configuration
- Check for proper input validation on user-facing endpoints
- Verdict: PASS / FAIL

### Step 4 — Dependency Freshness Check

- Check age of pinned dependencies
- Flag dependencies more than 6 months behind latest
- Flag dependencies with known end-of-life dates
- Verdict: PASS / FAIL

### Step 5 — Output Compliance Report

```
=== Compliance Report ===
Date: <YYYY-MM-DD>

| Check | Verdict | Details |
|-------|---------|---------|
| Secrets management | PASS | .env gitignored, no hardcoded secrets found |
| Auth coverage | FAIL | 2 routes missing auth middleware |
| Data handling | PASS | Parameterized queries, CORS configured |
| Dependency freshness | FAIL | 3 packages >6 months behind |
==========================
```

### Step 6 — Update State and Triage

---

## Flag: --gate <milestone>

### Step 1 — Run Full Security Check

Execute `--scan` logic (Steps 1-6) scoped to the milestone's changes:
- Read milestone file to understand what changed
- Focus scans on affected components

### Step 2 — Gate Verdict

- PASS: no CRITICAL or HIGH findings, compliance checks pass
- FAIL: any CRITICAL or HIGH finding open, or compliance check fails
- UNKNOWN: scan tools unavailable, cannot verify

### Step 3 — Write Evidence

Write to `.claude/data/evidence/<milestone>-security-gate-<YYYY-MM-DD>.md`:

```markdown
# Evidence: Security Gate

**Milestone:** M-<NNN>
**Date:** <YYYY-MM-DD HH:MM>
**Verdict:** PASS | FAIL | UNKNOWN
**Collected by:** security-review --gate

## Vulnerability Summary
| Severity | Count | Accepted | Open |
|----------|-------|----------|------|
| CRITICAL | 0 | 0 | 0 |
| HIGH | 0 | 0 | 0 |
| MEDIUM | 2 | 1 | 1 |

## Compliance
| Check | Verdict |
|-------|---------|
| Secrets management | PASS |
| Auth coverage | PASS |
| Data handling | PASS |

## Open Issues
- <list of issues that caused FAIL, if any>

## Raw Output
<truncated scan output — first 100 lines>

## Notes
<any caveats>
```

### Step 4 — Update State, Triage, and Milestone File

---

## Flag: --remediate

### Step 1 — Read Current Findings

- Load security state file
- Identify all OPEN findings by severity (CRITICAL first)

### Step 2 — Generate Remediation Plan

For each finding:
- **Dependency vulnerabilities:** specify exact version upgrade, check for breaking changes
- **Code vulnerabilities (SonarQube):** recommend invoking `/sonar-fix` with the specific issue
- **Secret exposure:** identify the file and line, recommend moving to env var
- **Auth gaps:** identify the route, recommend adding auth middleware
- **Container vulnerabilities:** recommend base image update in Dockerfile

### Step 3 — Output Remediation Report

```
=== Remediation Plan ===
Total findings: <N>
Auto-fixable: <N>
Manual review needed: <N>

Priority 1 (CRITICAL):
  <finding> → <fix>

Priority 2 (HIGH):
  <finding> → <fix>

Priority 3 (MEDIUM):
  <finding> → <fix>

Cross-skill actions:
  - /sonar-fix: <N> code-level findings to fix
  - /engineering-plan: <if architectural changes needed>
=========================
```

### Step 4 — Update State and Triage

---

## Flag: --audit-trail

### Step 1 — Gather Audit History

- Read security state file — all previous scan entries
- Read evidence files in `.claude/data/evidence/*-security-*.md`
- Read git log for security-related commits

### Step 2 — Output Audit Trail

```
=== Security Audit Trail ===
Project: <name>
Period: <earliest scan date> — <today>

| Date | Action | Findings | Posture | By |
|------|--------|----------|---------|-----|
| 2026-03-22 | --scan | 3 HIGH, 5 MEDIUM | HIGH | security-review |
| 2026-03-20 | --gate M-001 | FAIL (2 HIGH) | HIGH | security-review |
| 2026-03-18 | --remediate | Fixed 1 HIGH | MEDIUM | security-review |

Accepted Risks (.trivyignore):
| CVE/Finding | Accepted Date | Reason |
|-------------|---------------|--------|
| CVE-2026-XXXX | 2026-03-15 | No exploit path in our usage |

Evidence Files:
- .claude/data/evidence/M-001-security-gate-2026-03-22.md
- .claude/data/evidence/M-001-security-gate-2026-03-20.md
==============================
```

---

## State file spec — `.claude/state/security.md`

```markdown
# Security State

**Last updated:** <YYYY-MM-DD>
**Posture:** <CLEAN / LOW / MEDIUM / HIGH / CRITICAL>

## Vulnerability Summary

| Severity | Count | Fixed | Accepted | Open |
|----------|-------|-------|----------|------|
| CRITICAL | 0 | — | — | — |
| HIGH | 2 | 1 | 0 | 1 |
| MEDIUM | 5 | 3 | 1 | 1 |
| LOW | 3 | 0 | 2 | 1 |

## Open Findings

| ID | Severity | Component | Description | Fix Available | Status |
|----|----------|-----------|-------------|---------------|--------|
| F-001 | HIGH | fastapi | CVE-2026-XXXX | 0.110.0 | OPEN |
| F-002 | MEDIUM | route /api/admin | Missing auth middleware | Code fix | OPEN |

## Accepted Risks

| ID | Finding | Accepted Date | Reason | Reviewed By |
|----|---------|---------------|--------|-------------|
| A-001 | CVE-2026-YYYY | 2026-03-15 | No exploit path | security-review |

## Compliance Status

| Check | Verdict | Last Checked | Notes |
|-------|---------|--------------|-------|
| Secrets management | PASS | 2026-03-22 | — |
| Auth coverage | FAIL | 2026-03-22 | 2 routes missing |
| Data handling | PASS | 2026-03-22 | — |
| Dependency freshness | FAIL | 2026-03-22 | 3 packages stale |

## Scan History

| Date | Type | Tool | Findings | Posture |
|------|------|------|----------|---------|
| 2026-03-22 | Full scan | Trivy + npm audit | 10 total | HIGH |
| 2026-03-20 | Gate M-001 | Trivy | FAIL | HIGH |

## Notes
<freeform — environment issues, tool availability, recurring patterns>
```

---

## Triage Update Protocol

After every operation, update `.claude/state/triage.md` § `## Security`:

```markdown
## Security
**Updated:** <YYYY-MM-DD HH:MM>
**Posture:** <CLEAN / LOW / MEDIUM / HIGH / CRITICAL>

### Vulnerability Summary
| Severity | Count | Fixed | Accepted | Open |
|----------|-------|-------|----------|------|
| CRITICAL | 0 | — | — | — |
| HIGH | 2 | 1 | 0 | 1 |
| MEDIUM | 5 | 3 | 1 | 1 |

### Open Issues
- <CVE or finding with affected component and severity>

### Compliance
- Secrets management: <PASS/FAIL>
- Auth coverage: <PASS/FAIL>
- Dependency freshness: <PASS/FAIL>

### Recommendations
- <e.g., "Update fastapi to 0.110.0 to fix CVE-2026-XXXX">
```

Update the top-level header of `triage.md`:
```
**Last updated:** <YYYY-MM-DD>
**Updated by:** security-review --<flag>
```

If `triage.md` does not exist, create it with only the `## Security` section and a minimal header. Do not create other sections — those belong to other skills.

---

## Important constraints

1. **NEVER auto-suppress vulnerabilities** — only report and suggest. The user or a deliberate `.trivyignore` entry is the only way to accept a risk.
2. **NEVER commit feature code** in a security-review run — only touch `.claude/` files, `.trivyignore` (if user explicitly approves), and evidence artifacts.
3. **Respect `.trivyignore`** — findings listed there are ACCEPTED, not OPEN. Always read this file before classifying findings.
4. **Integrate with `/sonar-fix`** — for code-level vulnerabilities found by SonarQube, recommend the user invoke `/sonar-fix` rather than fixing inline. This preserves separation of concerns.
5. **Secret detection is conservative** — flag potential secrets for human review. Do not auto-redact or auto-remove code you are unsure about.
6. **Health check credentials are not secrets** — do not flag test/health-check URLs with embedded tokens if they are clearly marked as non-production.
7. **Always update triage** — this is how other skills see your work. Never skip this step.
8. **Evidence files follow quality-gate conventions** — write to `.claude/data/evidence/` using the same format so `/quality-gate` and `/milestone` can read them.
9. **Scan tools may not be installed** — if Trivy, pip-audit, or npm-audit are unavailable, note the gap as UNKNOWN and recommend installation. Never report PASS when you cannot verify.
10. **Auth middleware audit scope** — check all files in `the project's API route directory` for route definitions. A route is "covered" if it has an auth dependency injected or is explicitly marked as public.

## Learned Rules

1. **Verify findings in source code before acting on state files.** Audit/legal state files are point-in-time snapshots that go stale. Before fixing any finding, read the referenced file and confirm the issue still exists. In one session, 7 of 12 "open" findings were already resolved in code. *(From: feedback_learned_verify_findings_before_fixing.md)*
