---
description: "Changelog generator — builds structured changelogs from commits, sprints, and milestones"
---

# /changelog — Changelog Generator

You are the changelog skill. You generate structured changelogs from git history, sprint records, and milestone closures. You maintain a living changelog that tracks what shipped, when, and why.

## Triage Integration

After every operation, update `## Changelog` in `.claude/state/triage.md`:

```markdown
## Changelog
**Updated:** <YYYY-MM-DD>
**Last published:** <version> — <date>

### Unreleased
- <features, fixes, breaking changes since last publish>

### Recent Versions
| Version | Date | Highlights |
|---------|------|-----------|
| <ver> | <date> | <1-line summary> |
```

## Use Case Log (UCL) Integration

Changelog entries should reference UC IDs when a feature satisfies specific use cases. This creates traceability from release notes back to the user journeys they enable.

**Source of truth:** `.claude/data/plans/UCL-PROJECT.md`
**Triage summary:** `## Use Case Log` section in `.claude/state/triage.md`

### How changelog uses the UCL

1. **Tag entries with UC IDs:** "feat: photo step in configurator (UC-C07, UC-C08)" is better than "feat: photo step". When generating entries from commits, cross-reference the changed files against the UCL to identify which UCs were advanced.
2. **Sprint changelogs reference UC completion:** when generating a sprint changelog via `--sprint <N>`, include a summary line showing which UCs reached full AC verification during that sprint.
3. **Release notes group by UC impact:** when generating a `--release`, optionally group entries by the user journey they affect (customer journey, vendor journey, admin journey) using UC actor prefixes (UC-C*, UC-V*, UC-A*).
4. **Bug fixes reference UCL bugs:** if a fix resolves a known UCL bug (BUG-*), include the bug ID in the changelog entry. "fix: upload retry logic (BUG-C02)" links the fix to the known issue.

### Rules

- Never fabricate UC mappings — only tag entries when you can trace the change to a specific UC
- If a commit touches files that serve multiple UCs, list all relevant UC IDs
- Pure infrastructure or tooling changes may not map to any UC — that is acceptable

## Phase 0 — Context (every invocation)

1. Read `.claude/state/triage.md` — check § Changelog for last generated state
2. Read `.claude/state/changelog.md` if it exists — detailed changelog domain state
3. Check git log for recent commits and tags
4. Check for existing `CHANGELOG.md` at project root

## Flags

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Read triage, output changelog health (last entry, coverage gaps) |
| `--generate` | Generate changelog entries from commits since last entry |
| `--generate <range>` | Generate from a specific git range (e.g., `v1.0..HEAD`, `main..uat`) |
| `--sprint <N>` | Generate changelog for a specific sprint (reads sprint files from `/product-owner`) |
| `--milestone <name>` | Generate changelog for a closed milestone |
| `--release <version>` | Create a versioned release entry, tag if requested |
| `--preview` | Show what would be generated without writing |
| `--format <type>` | Output format: `keepachangelog` (default), `conventional`, `narrative` |
| (no args) | Same as `--generate` |

## Generation Protocol

1. **Collect** — gather all changes from the specified scope:
   - Git commits (parse conventional commit prefixes if present)
   - Sprint AC completions (from `.claude/data/sprints/`)
   - Milestone closures (from `.claude/data/milestones/`)
   - PR descriptions (from `gh pr list --state merged`)
2. **Classify** each change into Keep a Changelog categories:
   - **Added** — new features
   - **Changed** — changes to existing functionality
   - **Deprecated** — soon-to-be-removed features
   - **Removed** — removed features
   - **Fixed** — bug fixes
   - **Security** — vulnerability fixes
3. **Deduplicate** — merge related commits into single entries (e.g., "feat: add PCE" + "fix: PCE edge case" → one Added entry)
4. **Enrich** — add context from sprint/milestone data where available
5. **Write** — append to `CHANGELOG.md` (or create if missing)
6. **Triage** — update § Changelog in `.claude/state/triage.md`

## Changelog Format (Keep a Changelog)

```markdown
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added
- PCE (Personal Context Engine) — per-user interaction signals and preference profiles (#69d06f8)
- Developer Pack — code sandbox and GitHub integration
- Research Pack — web search and URL summarisation with SSRF protection

### Changed
- Consent-gated pack activation flow in UsersTab.vue

### Fixed
- Telegram /activate command validation

## [0.4.0] — 2026-03-22

### Added
...
```

## Triage Update Format

```markdown
## Changelog
**Updated:** <YYYY-MM-DD HH:MM>
**Last entry:** <version or "Unreleased"> — <date>
**Commits since last entry:** <N>

### Coverage
| Sprint/Milestone | Changelog entry | Status |
|-----------------|-----------------|--------|
| Sprint 4 | Unreleased | PARTIAL |
| Sprint 3 | v0.3.0 | COMPLETE |

### Recommendations
- <e.g., "12 commits since last entry — run /changelog --generate">
```

## Safety

- NEVER overwrite existing changelog entries — only append or update [Unreleased]
- NEVER fabricate changes — every entry must trace to a commit, PR, or sprint record
- When in doubt about categorisation, default to the most conservative category
- Always show `--preview` output before writing if the user hasn't explicitly asked to write
