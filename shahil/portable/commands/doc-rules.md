---
description: Universal documentation standard — audit, fix, init, and session-start briefing for any project
argument-hint: [--session-start] [--check] [--fix] [--init] [--file <path>] [--sync]
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

# doc-rules — Universal Documentation Standard

You enforce the Universal Documentation Standard (UDS) on any project. You are self-discovering: you read the project to understand it before applying any rules.

## Arguments

The user invoked this command with: $ARGUMENTS

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Read `.claude/state/docs.md` and output a structured briefing for this session. If no state file exists, run `--check` first. |
| `--check` | Discover project → audit all docs → report violations → write `.claude/state/docs.md`. Do not fix. |
| `--fix` | `--check` then fix all fixable violations → commit → update state file. |
| `--init` | Bootstrap UDS structure on a project that has none. Creates dirs, governance playbook, and state file. |
| `--file <path>` | Scope `--check` or `--fix` to a single file. |
| `--sync` | Update `## Documentation` in `.claude/state/triage.md` from the current `docs-state.md`. Fast — no re-scan. |
| (no args) | Same as `--check`. |

---

## Phase 0 — Self-discovery (always run first)

Before applying any rule, build a mental model of this project:

```
1. Find the repo root: look for .git/, CLAUDE.md, or README.md
2. Read CLAUDE.md if it exists — it contains project-specific overrides
3. Read README.md first section — understand what the project does
4. Scan for docs/ directory — note subdirectory structure
5. Check for an existing governance playbook (any *playbook*.md under docs/)
6. Check for a CI guard script (any *guard*.py or *lint-docs* in scripts/ or .github/)
7. Check .gitignore for ignored directories (management/, .claude/, etc.)
8. Read .claude/state/docs.md if it exists — previous audit state
9. Read .claude/state/triage.md if it exists — understand cross-skill context before reporting
```

Record findings as your working context. All subsequent steps use what you discovered here — never assume project-specific paths.

---

## Flag: --session-start

Read `.claude/state/docs.md` and output this structured briefing:

```
=== Doc landscape briefing ===
Project:      <name from README/CLAUDE.md>
Docs root:    <discovered path>
Governance:   <playbook path or MISSING>
Guard:        <guard script path + last known status, or MISSING>
Structure:    <subdirs found>
Last audit:   <date from state file>
Compliance:   <N/M docs compliant>
Open issues:  <count and summary>
Continuity:   <any in-progress doc work noted in state file>
===============================
```

If `.claude/state/docs.md` does not exist: output "No state file found — running --check now" then execute `--check`.

---

## Flag: --init

Use this on a project with no docs structure. Steps:

**1. Confirm project name and purpose** — read README first paragraph.

**2. Create UDS directory structure:**
```
docs/
├── architecture.md
├── architecture-updates.md
├── assumptions.md
├── adr/
├── ops/
├── integrations/
├── reference/
└── archive/
```

**3. Write starter files** — each with the required header block (see U3). Minimal viable content only:
- `docs/architecture.md` — H1, header block, stub sections: Quick orientation, Components, Authentication model, Known Issues (stub pointing to ops/runbooks.md), Active gaps
- `docs/architecture-updates.md` — H1, header block, first date entry
- `docs/assumptions.md` — H1, header block, three sections: Confirmed, Resolved, Still open

**4. Write the governance playbook** at `docs/documentation-management-playbook.md` — a copy of the core rules from this skill (U1–U8) adapted to the discovered project paths.

**5. Bootstrap `.claude/state/docs.md`** (see State file spec).

**6. If no CI guard script exists** — note it as an open item in the state file. Do not create it automatically unless the user asks; CI tooling varies per project.

---

## Flag: --check / --fix

### Step 1 — Inventory

List every `.md` file under the docs root (recursive). For each, record:
- Path
- Has H1 (required)
- Has Owner header — **two valid formats, check for either:**
  - Regular docs: `> **Owner:** …` bold front-matter block after H1
  - ADRs (`adr/` subdir): `Owner: …` plain text in metadata block at lines 3–6
- Has Review cadence — same two-format rule as Owner above
- Filename is lowercase-hyphenated (no spaces, no ALLCAPS stems or prefixes)
- Is in a semantically appropriate subdirectory (see U1)
- For ADRs: has all four metadata fields — `Status:`, `Date:`, `Owner:`, `Review cadence:` — in lines 3–8 (before first `##`)

**Lesson learned ** ADRs use the metadata-block format only — they do NOT additionally need the `> **Owner:**` front-matter block. A regex checking only for `**Owner:**` will false-positive on every ADR. Check `Owner:` (unbolded, start of line) in the first 8 lines for ADR files.

### Step 2 — Run CI guard (if one exists)

```bash
<discovered guard command>
```

Capture all failures. If no guard exists, note it as a gap but do not block.

### Step 3 — Architecture.md discipline check

Verify `architecture.md` (or equivalent primary reference) does not contain:
- Sections named `Session-verified updates`, `Sprint N updates` → flag: should be in architecture-updates.md
- Known-issue diagnosis blocks longer than ~20 lines → flag: should be in ops/runbooks.md
- Inline shell command sequences longer than ~10 lines → flag: should be in ops/cloud-deployment.md or equivalent

### Step 4 — Report

Output a violation table:

```
File                              | Violation
----------------------------------|------------------------------------------
docs/ops/runbooks.md              | Missing Owner header
docs/adr/0001-foo.md              | Missing Review cadence in metadata block
docs/My Doc.md                    | Filename has space → my-doc.md
docs/architecture.md              | Contains sprint session block (lines N–M)
```

If `--check` only: stop here, then write state file.

### Step 5 — Fix (--fix only)

Create a TodoWrite task per file. For each:

**5a. Missing headers** — insert header block after H1. Use today's date. Owner = project owner from CLAUDE.md/README, fallback `"Engineering"`. Review cadence = sensible default for that file's subdirectory:

| Subdir | Default cadence |
|--------|----------------|
| `ops/` | When operational procedures, tools, or infrastructure change |
| `integrations/` | When the integrated service API or auth model changes |
| `reference/` | When the referenced paths, env vars, or policies change |
| `adr/` | See U7 |
| `archive/` | Archived — no further review required |
| (root) | When project architecture, conventions, or governance changes |

**5b. Filename violations** — use `git mv` for tracked files. Update cross-references in other docs.

**5c. Guard failures** — rewrite the offending line. For secret-assignment false positives in example text: use `<angle-bracket>` placeholder values — most guards have a negative lookahead that exempts these. Only add to allowlist if rewriting would be misleading.

**5d. Architecture.md extraction** — if sprint/session blocks are found, append them to architecture-updates.md with a date heading. If runbook blocks are found, move to ops/runbooks.md. Replace extracted content with a one-line reference.

**5e. Misplaced files** — flag to user; do not auto-move without confirmation (cross-references could break).

### Step 6 — Re-run guard (--fix only)

Must pass before committing.

### Step 7 — Commit (--fix only)

Stage only docs/ and guard-related files. Never stage feature code in a doc-rules run.

```
docs: enforce doc-rules compliance — <brief summary>
```

### Step 8 — Write state file

Always write `.claude/state/docs.md` after check or fix. See spec below.

### Step 9 — Sync triage (always, after Step 8)

Run `--sync` to update `.claude/state/triage.md § ## Documentation` with the current compliance results.

If no `triage.md` exists yet, create it with only the `## Documentation` section and a minimal header comment. Other sections (`## Engineering Plans`, `## Delivery & Progress`, `## Product & Sprint`) are owned by other skills — do not create them.

---

## State file spec — `.claude/state/docs.md`

Write this file after every `--check` or `--fix` run. It is the session-continuity artifact.

```markdown
# Docs State

**Project:** <name>
**Last audit:** <YYYY-MM-DD>
**Audited by:** doc-rules --<flag>

## Structure

Docs root: <path>
Subdirs: <comma-separated list found>
Governance playbook: <path or MISSING>
CI guard: <command or MISSING> — last status: <PASS N docs / FAIL / MISSING>

## Compliance

| Metric | Value |
|--------|-------|
| Total docs | N |
| Compliant (headers + filename) | N |
| Missing Owner header | N |
| Missing Review cadence | N |
| Filename violations | N |
| Guard failures | N |
| Architecture.md drift | N sections |

## Open violations

<bullet list of remaining violations after this run — empty if --fix resolved all>

## Architecture.md health

Primary ref: <path>
Last reviewed date in doc: <date>
Status: <STABLE / HAS DRIFT — describe>

## Continuity notes

<Any in-progress doc work that the next session or agent should know about.
Freeform. Updated manually or by --fix runs.>
```

---

## Flag: --sync

Update the `## Documentation` section of `.claude/state/triage.md` without re-scanning the project.

**Step 1** — Read `.claude/state/docs.md`. If it does not exist, output:
> "No docs-state.md found — run `/doc-rules --check` first to generate it."
Then stop.

**Step 2** — Write (or replace) the `## Documentation` section in `.claude/state/triage.md`:

```markdown
## Documentation
**Updated:** <YYYY-MM-DD> by doc-rules --sync
**Guard:** <PASS / FAIL> (<N> docs scanned, last audit: <date>)
**Compliance:** <N>/<N> docs  |  Open violations: <N>
**Architecture health:** <STABLE / HAS DRIFT>

### Violations
<bullet list, or "_None_">

### Recommendations
<cross-skill actions — e.g., "Run /engineering-plan after adding new API module" — or "_None_">
```

**Step 3** — Update the top-level header of `triage.md`:
```
**Last updated:** <YYYY-MM-DD>
**Updated by:** doc-rules --sync
```

**Step 4** — If `triage.md` does not exist, create it with only the `## Documentation` section and this minimal header:
```markdown
# Project Triage
<!-- Single source of cross-skill truth. Run /<skill> --session-start to populate all sections. -->

**Last updated:** <YYYY-MM-DD>
**Updated by:** doc-rules --sync
```
Then append the `## Documentation` block. Do not create other sections — those belong to other skills.

---

## Universal rules (U1–U8)

These rules apply to every project regardless of stack, language, or size.

### U1 — Directory layout

Every project adopting UDS uses this structure under its docs root:

```
docs/
├── architecture.md           stable decisions + contracts (primary entry point)
├── architecture-updates.md   timeline, sprint notes, incident summaries
├── <governance-playbook>.md  the doc rules for this project
├── assumptions.md            open assumptions and uncertainty register
├── adr/                      architecture decision records
├── ops/                      runbooks, deployment, backup, access review
├── integrations/             per-service and per-channel guides
├── reference/                static reference: paths, env vars, vendor policy
└── archive/                  superseded artefacts (never delete)
```

Slight variations are acceptable (e.g. `runbooks/` instead of `ops/`) — record the actual layout in `.claude/state/docs.md`.

**Lesson learned**: check `.gitignore` before creating a new top-level directory. Names like `management/`, `.claude/`, `build/`, `dist/` are commonly gitignored. If your intended location is ignored, use `docs/<subdir>` instead.

### U2 — Filename conventions

- Lowercase only
- Hyphens as word separators (never spaces, never underscores in stems)
- No ALLCAPS stems (`paths.md` not `PATHS.md`)
- Spaces in filenames break shell glob, `head`, and CI path references — always fix with `git mv`

### U3 — Required headers

Every `.md` in docs root and all subdirs must have this block **directly after the H1**:

```markdown
> **Owner:** <name or team>
> **Last reviewed:** <YYYY-MM-DD>
> **Review cadence:** <trigger description>
```

ADRs additionally require a metadata block at lines 3–6 (before first `##`):

```
Status: Accepted | Superseded | Deprecated
Date: YYYY-MM-DD
Owner: <team>
Review cadence: <trigger or "Archived — no further review required">
```

**Batch injection**: when ≥ 4 files need headers, write a short script rather than editing each file individually — it is faster and avoids inconsistencies.

### U4 — CI guard

A docs guard should check two things at minimum:

1. **Broken references** — file paths or workflow filenames cited in docs must exist on disk.
2. **Hardcoded secrets** — variable assignments with literal values (`MY_KEY=abc123`) must not appear in docs.

**Self-reference trap**: if a doc describes the guard's own detection pattern, write any examples using `<angle-bracket>` placeholder values (e.g. `MY_KEY=<your-value-here>`). Most guards have a negative lookahead that exempts values starting with `<`.

If no guard exists, note it as a gap in the state file and recommend adding one.

### U5 — Architecture.md discipline

The primary architecture reference must stay **stable and decision-oriented**.

Time-based content belongs in `architecture-updates.md`:
- Sprint session notes
- Incident summaries
- Remediation timelines

Operational content belongs in `ops/`:
- Known-issue diagnosis and step-by-step remediation
- Release commands and deploy recipes
- Backup and restore procedures

When content is extracted from `architecture.md`, update its internal reference table (usually near the top under "Related docs" or "Operational update log").

### U6 — Archive policy

Never delete superseded documentation. Move to `docs/archive/` and add:

```
> **Review cadence:** Archived — no further review required.
```

Archive when:
- A planning doc's work is fully executed
- A sprint-scoped note has been superseded by the next sprint's work
- A feature spec has been fully implemented and its decisions captured in an ADR

### U7 — ADR workflow

1. New decision: `docs/adr/NNNN-short-slug.md`, sequential number, U3 headers + metadata block.
2. Supersede: set `Status: Superseded`, add `Superseded: YYYY-MM-DD`, set cadence to `Archived — no further review required.`
3. Never delete ADRs — they are a permanent decision audit trail.

### U8 — Session and agent continuity

Write `.claude/state/docs.md` after every check or fix run. Any agent or new session should run `--session-start` as its first action to get an accurate briefing without re-scanning the project.

Do not rely on memory alone for cross-session continuity. The state file is the source of truth.

---

## Important constraints

1. **Never commit feature code** in a doc-rules run — only touch `docs/`, guard scripts, and allowlist files.
2. **Never delete `.md` files** — move to `docs/archive/`.
3. **Never auto-move files** without confirming with the user — cross-references break silently.
4. **`--init` is additive** — never overwrite existing content. If `architecture.md` already exists, skip it.
5. **Respect CLAUDE.md overrides** — if the project defines different conventions in CLAUDE.md, follow those and note the deviation in the state file.
6. **Guard self-reference trap applies to this skill too** — if you write doc content that describes secret-detection patterns, use `<placeholder>` values in any examples.
7. **Use two-pass perl for markdown link transforms.** When renaming doc files and updating cross-references: Pass 1 handles pure ALLCAPS names, Pass 2 handles mixed-case remainders. Verify after each pass — single-pass transforms miss edge cases where a filename contains both upper and lower case segments. *(From: feedback_learned_perl_markdown_link_transform)*
