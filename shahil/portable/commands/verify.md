---
description: Verification loop — composite build/test/lint/security check after implementation
argument-hint: [--full] [--quick] [--fix]
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - TodoWrite
---

# verify — Post-Implementation Verification Loop

You run a composite verification chain after code changes. Build, test, lint, and security — in one pass. You catch what individual tools miss by running the full chain and reporting a unified verdict.

## Core Mindset

**Verify the whole, not just the part you changed.** A passing unit test doesn't mean the build works. A passing build doesn't mean lint is clean. Run everything, report everything.

## Arguments

The user invoked this command with: $ARGUMENTS

| Flag | Behaviour |
|------|-----------|
| `--full` | Run all checks: build, test, lint, type-check, security audit |
| `--quick` | Run tests only (fastest feedback) |
| `--fix` | Run all checks, auto-fix what's fixable (lint:fix), re-run |
| (no args) | Same as `--full` |

## Verification Chain

Run these sequentially. Stop on first failure unless `--fix` is active.

### 1. Build Check
```bash
cd apps/api && npm run build 2>&1 || echo "BUILD: FAIL"
```

### 2. Test Suite
```bash
cd apps/api && npm test 2>&1 | tail -20
```

### 3. Lint Check
```bash
cd apps/api && npm run lint 2>&1 | tail -20
```
With `--fix`: run `npm run lint:fix` first, then re-check.

### 4. Security Audit
```bash
cd apps/api && npm audit --production 2>&1 | tail -10
```

### 5. Output Verdict

```
=== VERIFICATION LOOP ===
Build:    PASS / FAIL
Tests:    PASS (N/M) / FAIL (N failures)
Lint:     PASS / FAIL (N issues)
Security: PASS / WARN (N advisories)

VERDICT: PASS / FAIL
  Failed: <list of failed checks>
  Action: <what to fix>
========================
```

## Boundaries

- This skill NEVER modifies source code (except lint:fix with `--fix` flag)
- This skill reads test output but doesn't fix failing tests
- Report failures clearly — don't try to fix them automatically

## Learned Rules

1. **Verify multi-step pipeline writes from the system of record, not queue/UI state.** Queue badges, approval tables, and “executed” labels are only hints. When proving a pipeline succeeded, read the final owner of the data (HubSpot, Postgres, external API) directly. If UI state and canonical data disagree, treat it as a UI/ops bug rather than assuming the write failed. *(From: feedback_learned_verify_pipeline_writes_from_system_of_record.md)*
