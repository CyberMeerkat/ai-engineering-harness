# Architect — Reference Documentation

> Detailed procedures, templates, and checklists for each `/architect` flag.
> Loaded on demand by the architect skill dispatcher.

## Triage Integration

After every operation, update `.claude/state/architect.md`:

```markdown
## Architecture
**Updated:** <YYYY-MM-DD>
**Architecture doc:** docs/architecture.md — <CURRENT / DRIFT DETECTED>
**Schema:** <N> models, <migration status>

### Component Health
| Unit | Components | Tests | Integration | Status |
|------|-----------|-------|-------------|--------|

### Branch Status
| Repo | Branch | Ahead/Behind | Stale Branches |
|------|--------|-------------|----------------|

### Schema Drift
- <migrations pending or db:push drift detected>

### Dependency Health
- <outdated packages, CVEs, version conflicts>

### ADR Log
| ID | Date | Decision | Status |
|----|------|----------|--------|
```

## UCL Integration

**Source of truth:** `.claude/data/plans/UCL-PROJECT.md`

Architecture decisions affect which use cases can be implemented. Map:
- Which components serve which UCs
- Which integration points are required for which UCs
- Which schema models back which UCs
- Where architectural constraints limit UC implementation

---

## Phase 0 — Context Gathering (always run first)

```
1. Read `docs/architecture.md` — master architecture document
2. Read `.claude/state/triage.md` — lean index
3. Read `.claude/state/architect.md` — previous state (if exists)
4. Read `apps/api/prisma/schema.prisma` — current data model
5. Read `apps/api/package.json` — API dependencies + version
6. Read `apps/mobile-app/package.json` + `app.json` — mobile deps + version
7. Read `docker-compose.yml` + `docker-compose.agents.yml` — service topology
8. Git status + branch info
9. Git log (last 10 commits) — recent changes
10. Scan `.claude/data/plans/EP-*.md` — active engineering plans
```

---

## Flag: --session-start

Output system health dashboard:

```
=== Architecture Dashboard ===
Project:        <name>
Architecture:   docs/architecture.md — <CURRENT / DRIFT>
REPOSITORIES
  api:        main @ <hash> — <status>
  mobile-app: main @ <hash> — <status>
SCHEMA
  Models: <N>
  Migration status: <in sync / drift detected>
COMPONENTS
  API services: <N>
  API routes: <N>
  Mobile screens: <N>
  Admin pages: <N>
DEPENDENCIES
  API: <N> deps (<N> outdated, <N> vulnerable)
BRANCHES
  Stale (>5 days): <N>
INTEGRATION UNITS
  | Unit | Status | Last Tested |
ARCHITECTURE HEALTH: <GREEN / YELLOW / RED>
================================
```

---

## Flag: --status

Full architecture inventory with drift detection.

### Steps
1. Scan components — Glob all source files, categorize by type
2. Map dependencies — trace imports/requires for dependency graph
3. Detect drift — compare code topology against `docs/architecture.md`
4. Check branch health — stale, diverged, unmerged across repos
5. Dependency health — `npm outdated` per repo, flag CVEs
6. Output status report
7. Update state files

---

## Flag: --component <name>

Deep dive on a specific component.

```
COMPONENT: <name>
Type:       <service / screen / route / model>
Path:       <file path(s)>
DEPENDENCIES (what it imports):
DEPENDENTS (what imports it):
API SURFACE:
TEST COVERAGE:
UCL MAPPING:
RECENT CHANGES: (last 5 commits)
```

---

## Flag: --release <version>

1. Pre-release checks — all tests pass, no drift, gates pass
2. Version bump in package.json / app.json
3. Generate changelog from commits since last tag
4. Create tags: `api-v<version>`, `mobile-v<version>`, etc.
5. Output release notes

---

## Flag: --branch-check

Per-repo branch audit:
```
REPO: <name> (<branch>)
  Active branches: <N>
  Stale (>5 days): <list>
  Diverged (>10 behind main): <list>
  Recommended cleanup: <branches to delete>
```

---

## Flag: --integrate

1. Run all tests across repos
2. Check cross-repo consistency (API shapes match mobile expectations)
3. Schema consistency (Prisma client versions, enum alignment)
4. Output integration report

---

## Flag: --adr <title>

Write to `.claude/data/adrs/ADR-<NNN>-<slug>.md`:

```markdown
# ADR-<NNN>: <title>
**Date:** <YYYY-MM-DD>
**Status:** PROPOSED / ACCEPTED / DEPRECATED / SUPERSEDED

## Context
## Decision
## Consequences
## Alternatives Considered
```

---

## Flag: --deps

Dependency audit output:
```
DEPENDENCY AUDIT — <date>
API: <N> deps, <N> outdated, <N> vulnerable
Mobile: <N> deps, <N> outdated
Admin: <N> deps, <N> outdated
Cross-Repo Conflicts: <package version mismatches>
```

---

## Flag: --schema-check

```
SCHEMA AUDIT — <date>
Models: <N>, Enums: <N>, Relations: <N>
Migration Status: <in sync / drift>
Model Inventory: | Model | Fields | Relations | Indexes | Used By |
Schema Risks: <missing indexes, cascade deletes, defaults>
```

---

## State File Spec — `.claude/state/architect.md`

```markdown
# Architect State
**Last updated:** <YYYY-MM-DD>
**Architecture doc:** docs/architecture.md — <hash>

## Repository Status
| Repo | Branch | HEAD | Tests | Status |

## Schema Summary
Models: <N>, Enums: <N>, Last migration: <date>, Drift: <none/detected>

## Component Inventory
### API Services (<N>)
### API Routes (<N>)
### Mobile Screens (<N>)
### Admin Pages (<N>)

## Integration Unit Status
| Unit | Components | Tests | Integration | Last Verified |

## Dependency Summary
| Repo | Total | Outdated | Vulnerable |

## ADR Log
| ID | Date | Title | Status |

## Release History
| Version | Date | Repos | Tag |
```

---

## Important Constraints

1. Architecture doc is the constitution. Read it before every operation. Flag drift immediately.
2. Never merge without tests. Unit tests for changed components, integration tests for affected units.
3. Schema changes need migrations. `db:push` is for dev iteration only. Production uses `db:migrate:deploy`.
4. Multi-repo features need coordination. API first, then consumers. Tag all repos at release.
5. Branch hygiene is non-negotiable. Stale branches and unmerged PRs are architecture debt.
6. ADRs for significant decisions. New service, dependency, auth flow, or integration point.
7. Always update state file after every operation.
8. Integration points are the highest-risk areas. Prioritize integration testing.
9. Component registry must match reality.
10. Version control is not optional. Semantic versioning, tags match across repos.
11. UCL traceability. Orphan components (no UC mapping) are removal candidates.
12. Dependency updates are architecture decisions. Major bumps require ADR + integration testing.
13. Shared engineering rules apply — read `.claude/commands/engineering-rules.md`.
14. Agent domain naming uses unprefixed `.domain` but prefixed manifest IDs (`l2-finance`).
15. `tsconfig rootDir` changes shift `dist/` output structure. Update all entry points.
16. Agent-engine must be built (`npx tsc`) before MCP server.
17. Always `db push` after starting agent-api (no migrations, schema via push only).
18. Check migration before db:push. Use `prisma migrate deploy` when migrations exist.
19. Yarn v1 uses `"*"` not `"workspace:*"` for workspace dependencies.
20. Grep function usage, not just imports, when extracting components (auto-import hides deps).
21. Prisma raw SQL uses lowercase snake_case table names (`subscription_plans` not `SubscriptionPlan`).
22. Brain domain enum mismatch — DEVELOPMENT->DEVOPS, MARKETING->GROWTH, etc.
23. Smoke test: warn not fail for optional services (avoid systemd restart loops).
24. agent-api health at `/health` not `/orchestration/health` (versioned paths need JWT).
