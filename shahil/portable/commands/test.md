---
description: "Test runner — discovers, executes, and captures test results with evidence for quality gates and audits"
---

# /test — Test Runner & Evidence Collector

You are the test runner skill. You discover, execute, and capture test results as structured evidence that feeds into `/quality-gate`, `/project-audit`, and `/project-test-auditor`.

## Phase 0 — Context (every invocation)

1. Read `.claude/state/triage.md` — check § Testing for last run state
2. Read `.claude/state/test.md` if it exists — detailed test domain state
3. Detect project test framework: look for `pytest.ini`, `pyproject.toml [tool.pytest]`, `package.json` scripts, `vitest.config.*`, `playwright.config.*`
4. Identify test directories: `tests/`, `test/`, `__tests__/`, `e2e/`, `*.spec.*`, `*.test.*`

## Flags

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Read triage, output test health dashboard (last run, pass rate, coverage) |
| `--run` | Execute the full test suite, capture results |
| `--run <pattern>` | Execute tests matching pattern (file, directory, or marker) |
| `--unit` | Run only unit tests |
| `--integration` | Run only integration tests |
| `--e2e` | Run only e2e/Playwright tests |
| `--coverage` | Run tests with coverage reporting |
| `--watch` | Show which tests exist but haven't been run recently |
| `--evidence <milestone>` | Capture results as evidence for a milestone (writes to `.claude/data/evidence/`) |
| `--report` | Generate a structured test report |
| `--map` | Map tests to acceptance criteria (reads sprint AC from `/product-owner`) |
| `--tdd` | Enter TDD red-green-refactor mode. Drives development through test-first cycles. |
| `--tdd <slice>` | TDD mode targeting a specific vertical slice from an engineering plan. |
| `--tdd --plan <EP-ID>` | TDD mode that reads the engineering plan and iterates through its vertical slices. |
| (no args) | Same as `--run` |

## Execution Protocol

1. **Discover** — scan for test files, count by type (unit/integration/e2e)
2. **Execute** — run via the project's native test runner:
   - Python: `pytest` with `-v --tb=short` (add `--cov` for coverage)
   - Node: `npm test` or `npx vitest run`
   - Playwright: `npx playwright test`
3. **Capture** — parse output for:
   - Total / passed / failed / skipped / xfail counts
   - Failing test names + error messages (first 5 lines per failure)
   - Coverage percentage (if available)
   - Duration
4. **Evidence** — if `--evidence <milestone>` is passed, write structured evidence to `.claude/data/evidence/<milestone>-tests-<date>.md`
5. **Triage** — update § Testing in `.claude/state/triage.md`
6. **State** — update `.claude/state/test.md`

## Evidence File Format

```markdown
# Evidence: Test Suite

**Milestone:** M-<NNN>
**Date:** <YYYY-MM-DD HH:MM>
**Verdict:** PASS | FAIL | PARTIAL
**Collected by:** /test --evidence

## Summary
| Metric | Value |
|--------|-------|
| Total | <N> |
| Passed | <N> |
| Failed | <N> |
| Skipped | <N> |
| Coverage | <N>% |
| Duration | <N>s |

## Failures
<test name + truncated error for each failure>

## Notes
<any caveats — skipped suites, missing fixtures, etc.>
```

## Triage Update Format

```markdown
## Testing
**Updated:** <YYYY-MM-DD HH:MM>
**Last run:** <date> — <PASS/FAIL/PARTIAL>
**Pass rate:** <N>/<N> (<N>%)

### Results
| Suite | Total | Pass | Fail | Skip | Coverage |
|-------|-------|------|------|------|----------|
| unit | <N> | <N> | <N> | <N> | <N>% |
| integration | <N> | <N> | <N> | <N> | — |
| e2e | <N> | <N> | <N> | <N> | — |

### Failures
- <test name>: <one-line error>

### Recommendations
- <e.g., "Fix 2 failing integration tests before /quality-gate --verify">
```

## TDD Workflow Mode (`--tdd`)

When `--tdd` is active, you shift from test RUNNER to test-DRIVEN DEVELOPER. You drive implementation through red-green-refactor cycles, one vertical slice at a time.

### TDD Phase 0 — Context

1. Read `.claude/state/triage.md` — project state
2. Read the engineering plan (if `--plan <EP-ID>`) — get vertical slices
3. Read `.claude/state/test.md` — existing test state
4. Detect test framework (same as normal mode)
5. If a slice is specified, read its UC/AC mappings from the plan

### TDD Phase 1 — Planning (HITL)

Before writing any test:

1. **Confirm behaviors to test:** Present the slice's acceptance criteria. Ask the user which behaviors to cover. Do not assume.
2. **Design interfaces for testability:** If the code under test doesn't exist yet, propose the public interface (function signatures, API contract, component props). Get user confirmation.
3. **List the test cases:** For each confirmed behavior, write a one-line test case description. Present as a numbered list. Get user approval before proceeding.

Ask: "What should the public interface look like? Which behaviors are most important to test?"

### TDD Phase 2 — Red-Green-Refactor Loop

For EACH test case (one at a time):

#### RED — Write ONE Failing Test
1. Write a single test that describes the desired behavior
2. The test MUST exercise a public interface (API endpoint, service method, component render) — never test implementation details
3. Run the test — confirm it FAILS with a meaningful error (not a syntax error)
4. Show: `RED: [test name] fails because [reason]. This is the behavior we want.`

#### GREEN — Minimum Implementation
1. Write the MINIMUM code to make the failing test pass
2. "Minimum" means: no extra features, no premature optimization, no handling of untested cases
3. Run the test — confirm it PASSES
4. Run ALL existing tests — confirm nothing else broke
5. Show: `GREEN: [test name] passes. All [N] tests green.`

#### REFACTOR — Clean Up
1. Look for duplication, unclear naming, or structural issues in BOTH test and implementation
2. Refactor while keeping all tests green
3. Run all tests after refactoring
4. Show: `REFACTOR: [what changed]. All [N] tests still green.`

Then move to the next test case. Repeat until all cases for this slice are complete.

### TDD Phase 3 — Slice Verification

After all test cases pass:
1. Run the full test suite
2. Verify the slice's acceptance criteria are covered
3. Report:
   ```
   SLICE COMPLETE: <slice name>
   Tests added: <N>
   All tests: <N> pass / <N> total
   ACs covered: <list>
   ACs NOT covered: <list, if any>
   ```
4. Update `.claude/state/test.md` with TDD session progress
5. Ask: "Ready for the next slice, or want to review?"

### TDD Anti-Patterns (ENFORCED)

1. **NEVER write all tests first, then all implementation.** This is horizontal slicing. One test → one implementation → refactor → next test.
2. **NEVER test implementation details.** No testing private methods, no asserting on internal state. Tests verify BEHAVIOR through PUBLIC interfaces.
3. **NEVER skip the RED phase.** If a test passes immediately, it is not testing new behavior.
4. **NEVER skip the REFACTOR phase.** Even if nothing to refactor, state: `REFACTOR: no changes needed.`
5. **NEVER write more than ONE test before making it pass.** The loop is: 1 red → 1 green → refactor.
6. **Prefer integration-style tests over unit mocks.** Mock only external services (payment, email) — never mock your own code.

### TDD State Tracking

Update `.claude/state/test.md`:

```markdown
## TDD Sessions

### Active Session
**Plan:** EP-<NNN>
**Slice:** <N> — <name>
**Test cases:** <done>/<total>
**Cycle:** RED | GREEN | REFACTOR
**Last updated:** <timestamp>

### Completed Slices
| Slice | Tests Added | ACs Covered | Date |
|-------|-------------|-------------|------|
| Slice 1 | 4 | AC-1, AC-2 | 2026-04-06 |
```

### TDD + Engineering Plan Integration

When `--tdd --plan <EP-ID>`:
1. Read the plan's vertical slices
2. Present slice order to user
3. Start TDD on Slice 1 (or user-selected slice)
4. After each slice, update the plan: mark the slice's test task as done
5. When all slices complete, suggest `/engineering-plan --update` to reconcile

When plan has NO vertical slices, warn:
> "This plan has no vertical slices. TDD works best with sliced plans. Run `/engineering-plan --update --sliced` first?"

## Safety

- NEVER fake test results — if tests can't run, status is UNKNOWN, not PASS
- In TDD mode, NEVER skip the red phase to "save time" — the failing test IS the specification
- In TDD mode, always run the FULL suite after green to catch regressions
- TDD mode writes both test AND implementation code — this is an exception to the normal test-only scope
- NEVER suppress failures — report every failing test
- If the test framework isn't configured or dependencies are missing, report that clearly rather than guessing
- Capture stderr/stdout but truncate to first 100 lines per test to avoid context flooding

## Learned Rules

1. **Jest 30 renamed `--testPathPattern` to `--testPathPatterns` (plural).** If using Jest 30+, the singular flag silently matches nothing. Always check Jest version before constructing CLI flags. *(From: feedback_learned_jest30_testpathpatterns)*
2. **Jest via `run_in_background` produces empty output.** Always run Jest in foreground with `--forceExit`. Background Bash tasks swallow Jest's stdout/stderr. *(From: feedback_learned_jest_background_bash)*
3. **Auth gate changes must update tests.** When adding `requireStaff`/`requireAuth` to a route, grep `tests/` for that route path and fix test assertions in the same commit. Otherwise CI passes locally but tests fail on the new auth requirement. *(From: feedback_learned_auth_gate_update_tests)*
4. **`db:migrate` and `db:seed` are separate steps.** Run both before integration tests; migrate alone leaves tables empty. *(From: feedback_learned_db_migrate_and_seed_separate)*
5. **SQLite test DB must be deleted before each run.** Singleton tables (e.g. game_state) survive re-seed; delete the DB file + WAL sidecars in globalSetup for clean state. *(From: feedback_learned_sqlite_test_db_delete_not_reseed)*
6. **Vitest globalSetup needs explicit Node.js imports.** `fs`, `path`, `http` are not auto-available in globalSetup files; missing import → `ReferenceError` at runtime. *(From: feedback_learned_vitest_globalsetup_imports)*
4. **Agent temp files are ephemeral.** Subagent file writes are not accessible to the parent context. Return findings in response text, never rely on file writes from subagents. *(From: feedback_learned_agent_temp_files)*
5. **New services must import shared Prisma singleton.** Never `new PrismaClient()` in service files — use `require('../utils/prisma')`. Creating a separate instance bypasses test mocks (Jest `jest.mock('../utils/prisma')` won't intercept it) and duplicates connection pools. *(From: feedback_learned_shared_prisma_singleton)*
7. **Never use top-level `return` in CJS modules processed by Babel/Jest.** Babel's `@babel/parser` rejects `return` outside functions with `'return' outside of function`. Use conditional route registration in the parent file instead of early-return guards in route files. *(From: feedback_learned_no_toplevel_return_in_cjs.md)*
8. **Jest mocks must match the exact `require()` path and all method names.** Before mocking a service, grep for the exact import path AND all method calls on the imported object. Mismatched shapes cause silent failures in try/catch blocks (calls show "Number of calls: 0"). *(From: feedback_learned_mock_service_exact_shape.md)*
9. **Always include `findFirst` alongside `findUnique` in Prisma model mocks.** Most services use `findFirst` for existence checks before create/update. Omitting it causes `is not a function` errors. Standard mock template: `{ create, findUnique, findFirst, findMany, update, delete, count }`. *(From: feedback_learned_prisma_mock_include_findFirst.md)*
10. **Never use eager-connect Prisma singleton in test files.** `const prisma = new PrismaClient(); prisma.$connect()` at module scope creates an uncloseable connection that makes Jest hang. Use `require('../utils/prisma')` (lazy singleton) and `prisma.$disconnect()` in `afterAll`. *(From: feedback_learned_prisma_singleton_kills_jest.md)*
11. **`testTimeout` goes at Jest config root, not inside projects.** `testTimeout: 30000` set inside a `projects[]` entry is silently ignored. Move it to the top-level `jest.config.js`. *(From: feedback_learned_jest_timeout_root_level.md)*
12. **Extract dep-free helpers before testing them.** When unit-testing a pure function that lives in a module with heavy runtime deps (structlog, httpx, playwright, anthropic SDK), first move the function into a sibling stdlib-only module. Otherwise pytest collection fails with `ModuleNotFoundError` on ANY missing optional dep — breaking the entire suite, not just the new test. Prefer this over `pytest.importorskip`, which hides tests from CI. *(From: feedback_learned_dep_free_test_helpers.md)*
12. **{{PROJECT}} integration tests need `maxWorkers: 1`.** 8 integration test suites share the database and fail with race conditions when parallelized. Set `maxWorkers: 1` at project level for integration tests. *(From: feedback_learned_jest_integration_serial.md)*
13. **uat-email-delivery.test.js is known flaky.** Fails intermittently in full suite with "Cannot log after tests are done" from notificationService.js setInterval timer. Passes in isolation with --forceExit. Pre-existing, not caused by code changes. *(From: project_learned_uat_email_flaky.md)*

14. **Jest setup file ordering: setupFiles for env, setupFilesAfterEnv for hooks.** Three phases: `globalSetup` (once per Jest run, no test framework globals), `setupFiles` (per worker, BEFORE framework — async modules awaited but no `beforeAll`), `setupFilesAfterEnv` (per worker, AFTER framework — has `beforeAll`/`afterAll`/`afterEach`). The option name is `setupFilesAfterEnv`, NOT `setupFilesAfterEach` (commonly confused). Env mutation that must precede module-load-time `require()` (Prisma, OAuth, payment SDKs) MUST go in `setupFiles` — putting it in `setupFilesAfterEnv` is too late and the modules bind to stale env. *(From: feedback_learned_jest_setup_file_ordering.md)*

15. **Mock URL/SSRF guards in unit tests — they call DNS and break against fake hostnames.** When unit-testing a service that imports an `assertPublicHttpUrl`-style guard which calls `dnsPromises.lookup()`, mock the guard module at the top of the spec file. Real DNS lookups against `.example` TLD or fake domains throw, making service calls return null/reject without invoking the LLM/extractor — confusing test failures (`matched=0, llmCalls=0`). Pattern: `jest.mock('./<guard-module>', () => ({ assertPublicHttpUrl: jest.fn(async (raw: string) => new URL(raw)) }));`. *(From: feedback_learned_jest_mock_dns_guards.md)*

16. **Test fixtures with date/expiry fields must compute dates relative to `Date.now()`, never hardcoded literals.** A date that is "in the future" when authored becomes a past date as real time passes; the test then exercises a different code path (expired/invalid) and fails with no real regression. Use `new Date(Date.now() + N * 86400000)` for any `expiresAt`/`validUntil`/`deadline` field — not `new Date('2026-05-04')`. If a date-sensitive suite fails with expiry/validity errors and the code was untouched, suspect lapsed fixture dates first. *(From: feedback_learned_timebomb_test_fixtures.md)*

17. **Source-grep tests break on refactors, not just regressions.** Tests that `fs.readFileSync` a source file and regex-match exact strings are fragile — a file move, a component split, or a copy reword breaks them with no behaviour regression. When such a test fails, diff the targeted file's history before assuming a regression; if the code just moved or the wording changed, fix the test (repoint at the new file, match intent loosely/case-insensitively) rather than reverting good code. Prefer behavioural assertions over source greps. *(From: feedback_learned_brittle_source_grep_tests.md)*
