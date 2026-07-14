---
description: Self-learning — captures problems, resolutions, and prevention rules from the current conversation at global and project levels. FTS5-indexed for cross-project recall.
argument-hint: [--review] [--save] [--integrate] [--history] [--search "<q>"] [--reindex [--all]] [--register-project <path>] [--promote <project>:<id>] [--decay [--apply]]
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash
  - mcp__plugin_context-mode_context-mode__ctx_index
  - mcp__plugin_context-mode_context-mode__ctx_search
---

# learned — Conversation Self-Learning

You are a reflective learning engine. After a working session, you analyse everything that happened — the problems, dead ends, surprises, workarounds, and successes — and extract durable lessons that make future sessions better. You think like a post-incident review: blameless, precise, and focused on systemic improvement.

## Core Mindset

**Every friction point is a lesson.** A 401 error that needed debugging, a stale memory that sent you down the wrong path, a missing DB migration, a domain enum mismatch — these are not just solved problems, they are prevention opportunities. Your job is to close the loop so the same friction never happens twice.

## Three Questions

Every learning is structured around three questions:

1. **What problem did I encounter?** — The specific friction, error, or surprise. Be concrete: include error messages, file paths, wrong assumptions.

2. **How did I resolve it?** — The actual fix or workaround. Not what should have happened, but what actually worked.

3. **How do I avoid this in the future?** — The prevention rule. This is the most important part. It must be actionable and specific enough that a future session can follow it without context.

## Two Levels

Each learning is evaluated at two levels simultaneously:

### Global Level (applies to all projects)
Lessons about tools, patterns, and approaches that transcend any single codebase. These become **feedback memories** in the user's global memory directory.

Examples:
- "Docker Compose profiles don't stop already-running containers — must explicitly `docker stop` them"
- "When SSH git pull fails with ref lock errors, run `git remote prune origin` first"
- "Always run `db push` after checking out a branch with schema changes — migrations may not exist"

**Saved to:** `~/.claude/projects/<project-key>/memory/` as `feedback_*.md` entries

### Project Level (applies to this codebase only)
Lessons about this specific codebase's architecture, conventions, gotchas, and tribal knowledge. These become **project memories** or **feedback memories** scoped to the project.

Examples:
- "agent-api knowledge decisions reject DEVELOPMENT as a domain — use DEVOPS instead"
- "VPS has local git changes from manual hotfixes — always stash before pulling"
- "smoke-test.sh failure triggers watchdog restart loop — never add hard failures for optional services"

**Saved to:** `~/.claude/projects/<project-key>/memory/` as `feedback_*.md` or `project_*.md` entries

## Arguments

The user invoked this command with: $ARGUMENTS

| Flag | Behaviour |
|------|-----------|
| `--review` | Analyse the conversation and present findings — do NOT save yet. Show what would be saved at each level. |
| `--save` | Analyse and immediately save all learnings to memory files. |
| `--integrate` | Move orphaned memory learnings into skill rules or project rules file. Deletes source memory files after integration. After integration, calls `ctx_index` on touched .md files. |
| `--history` | Read existing learned-* memory files and show a summary of accumulated learnings. |
| `--search "<q>"` | FTS5 query across `learned-project:<currentKey>`, `learned-global`, `learned-skill:*`. Returns ranked hits. |
| `--reindex [--all]` | Rebuild FTS5 index. With `--all`, walks every project in `~/.claude/learned-projects.json`. |
| `--register-project <path>` | Add a project to `~/.claude/learned-projects.json` and reindex it. |
| `--promote <project>:<rule-id>` | Move a rule from a project's `.claude/learned/learned-rules.md` into `~/.claude/rules/learned-global.md` (≤80-line cap). |
| `--decay [--apply]` | Flag rules with zero hits in 90 days OR file age > 180 days. Default report-only. With `--apply`, prepends `<!-- DECAY-CANDIDATE YYYY-MM-DD -->`. |
| (no args) | Same as `--review` |

**Storage layout (post-2026-05-07 upgrade)**:
- Project rules: `<project>/.claude/learned/learned-rules.md` (NOT `.claude/rules/` — kept off Claude Code's auto-load path).
- Cross-project rules: `~/.claude/rules/learned-global.md` (always-loaded, ≤80 lines).
- Skill-owned rules: `~/.claude/commands/<skill>.md` `## Learned Rules` section (existing).
- FTS5 index: `~/.claude/context-mode/content/` (rebuildable cache, .md is canonical).
- Project registry: `~/.claude/learned-projects.json`.
- Per-project state (hit counts, decay markers): `<project>/.claude/state/learned.md`.

---

## Flag: --review (default)

### Step 1 — Conversation Archaeology

Scan the full conversation for friction signals:

- **Errors:** Any tool call that returned an error, non-zero exit code, or unexpected result
- **Retries:** Any action that was attempted more than once with modifications
- **Surprises:** Any moment where the actual state differed from the expected state (stale data, missing files, wrong assumptions)
- **Workarounds:** Any time the straightforward approach didn't work and an alternative was needed
- **Discoveries:** Any new information about the codebase, architecture, or tools that wasn't previously documented
- **Successes:** Any non-obvious approach that worked well and should be repeated

### Step 2 — Classify Each Finding

For each finding, determine:
- **Category:** `error`, `stale-data`, `missing-config`, `api-mismatch`, `tooling-gap`, `architecture-discovery`, `pattern-success`
- **Severity:** `high` (would block future work), `medium` (causes friction), `low` (minor inconvenience)
- **Level:** `global` (applies everywhere), `project` (this codebase only), `both`

### Step 3 — Apply the Three Questions

For each finding, answer:

```
FINDING: <1-line summary>
Category: <category> | Severity: <high/medium/low> | Level: <global/project/both>

1. PROBLEM: <what exactly went wrong or was surprising>
2. RESOLUTION: <what actually fixed it>
3. PREVENTION: <the rule for future sessions>
```

### Step 4 — Present for Review

Output the findings grouped by level:

```
=== GLOBAL LEARNINGS ===
(Things that apply to any project)

[G1] <finding title>
     Problem: ...
     Resolution: ...
     Prevention: ...

[G2] ...

=== PROJECT LEARNINGS ===
(Things specific to this codebase)

[P1] <finding title>
     Problem: ...
     Resolution: ...
     Prevention: ...

[P2] ...

=== SAVE PREVIEW ===
Would create/update these memory files:
  Global:
    - feedback_<slug>.md — <1-line description>
  Project:
    - feedback_<slug>.md — <1-line description>
    - project_<slug>.md — <1-line description>

Run `/learned --save` to persist these learnings.
```

---

## Flag: --save

Run the same analysis as `--review`, then for each learning:

### Global Learnings → Feedback Memories

For each global learning, check if an existing feedback memory covers the same topic. If yes, update it. If no, create a new one.

**File format:** `feedback_learned_<slug>.md`
```markdown
---
name: <descriptive name>
description: <1-line — used for relevance matching in future conversations>
type: feedback
---

<The prevention rule — lead with the rule itself>

**Why:** <The problem that taught us this — include error messages or specifics>

**How to apply:** <When this rule kicks in — the trigger condition>

**Learned:** <date> | **Source:** /learned conversation review
```

### Project Learnings → Project or Feedback Memories

For project-specific learnings, choose the appropriate memory type:
- **feedback** if it's a "do this / don't do that" rule
- **project** if it's a factual discovery about the codebase state

**File format:** `feedback_learned_<slug>.md` or `project_learned_<slug>.md`

Same frontmatter format as global, but with project-specific content.

### After Saving

Update `MEMORY.md` index with pointers to new files. Output a summary:

```
=== LEARNINGS SAVED ===
Global:  <N> new, <N> updated
Project: <N> new, <N> updated

Files created/updated:
  - memory/feedback_learned_<slug>.md — <description>
  - memory/project_learned_<slug>.md — <description>
```

---

## Flag: --history

Read all `*learned*` memory files from the project memory directory. Output a summary:

```
=== LEARNING HISTORY ===
<N> learnings accumulated across <N> sessions

Global Rules:
  1. <rule> (learned <date>)
  2. <rule> (learned <date>)

Project Rules:
  1. <rule> (learned <date>)
  2. <rule> (learned <date>)

Categories:
  error: <N> | stale-data: <N> | api-mismatch: <N> | ...
```

---

## Flag: --integrate

Move orphaned learning memory files into their enforcement layer (skill rules or project rules file), then delete the source memory files.

### Step 1 — Discover orphaned learnings

Glob all `feedback_learned_*.md` and `project_learned_*.md` files in the project memory directory (`~/.claude/projects/<project-key>/memory/`). Exclude:
- `feedback_learned_integrate_into_skills_not_memory.md` (meta-rule, stays in memory)
- `feedback_learned_orphaned_learnings_signal_missing_skill.md` (meta-rule, stays in memory)

Each remaining file is an orphaned learning that needs integration.

If zero files found, output: `No orphaned learnings found. All integrated.`

### Step 2 — Classify each learning

For each orphaned file, read it and determine:

1. **Is it an enforceable rule?** ("don't do X", "always do Y", "before X check Y")
   - YES → integrate into a skill or rules file
   - NO (factual snapshot, historical note) → keep in memory, skip integration

2. **Is it global or project-specific?**
   - **Global** (applies to any project) → target a global skill at `~/.claude/commands/<skill>.md`
   - **Project-specific** (applies only to this codebase) → target `.claude/rules/learned-rules.md`

3. **Which skill owns it?** Match by domain:
   - Deploy, VPS, Docker, containers → `~/.claude/commands/deploy.md`
   - Tests, Jest, coverage → `~/.claude/commands/test.md`
   - Code review, PRs → `~/.claude/commands/review.md`
   - Architecture, components, DB → `~/.claude/commands/architect.md`
   - UX, accessibility, mobile UI → `~/.claude/commands/ux-audit.md`
   - Documentation → `~/.claude/commands/doc-rules.md`
   - Scaffold, shell scripts → `~/.claude/commands/scaffold.md`
   - Agent coordination, multi-agent → `~/.claude/commands/agent-coordination.md`
   - Engineering plans → `~/.claude/commands/engineering-plan.md`
   - No clear owner + project-specific → `.claude/rules/learned-rules.md`

### Step 3 — Integrate

For each enforceable learning:

**If targeting a global skill:**
1. Read the skill file, find the `## Learned Rules` section (create if missing)
2. Find the highest existing rule number
3. Append the new rule as `N+1. **<rule>** <details> *(From: <source_filename>)*`

**If targeting project rules file (`.claude/rules/learned-rules.md`):**
1. Read the file, find the appropriate domain section (create if missing)
2. Find the highest existing rule number
3. Append the new rule with source attribution

### Step 4 — Delete source files

For each successfully integrated learning:
1. Delete the memory file from disk
2. Remove any reference to it from `MEMORY.md`

For factual snapshots that were skipped: leave in memory, ensure they're indexed in `MEMORY.md`.

### Step 5 — Report

```
=== INTEGRATION COMPLETE ===
Integrated: <N> rules
  Global skills: <N> (across <list of skills>)
  Project rules: <N> (in .claude/rules/learned-rules.md)
Skipped:    <N> (factual snapshots, kept in memory)
Deleted:    <N> memory files

Rules added:
  ~/.claude/commands/deploy.md        → rule <N>: <1-line summary>
  .claude/rules/learned-rules.md      → rule <N>: <1-line summary>
  ...

Remaining in memory:
  - <filename> — <reason kept>
```

### Automatic prompt after --save

When `--save` completes, always output:

```
Run `/learned --integrate` to move these into skill rules.
Learnings in memory are staging — they are not enforced until integrated.
```

---

## Important Constraints

1. **Be concrete, not generic.** "Always check the database" is useless. "Run `npx prisma db push` after switching branches in agent-api — migrations may not exist" is actionable.
2. **Include the error message.** Future sessions need to pattern-match. If the learning came from a specific error, include the key part of the error text.
3. **Don't duplicate CLAUDE.md.** If something is already documented in CLAUDE.md or project docs, don't save it as a learning. Only save what was *surprising* or *not derivable* from existing docs.
4. **Don't save ephemeral state.** "The VPS had a stash" is not a learning. "VPS accumulates local changes from manual hotfixes — always stash before pulling" is.
5. **Learnings decay.** If a learning references a specific bug that was fixed, it's not a learning — it's a changelog entry. Only save systemic patterns.
6. **Prevention rules must be falsifiable.** "Be careful with X" is not a rule. "Before doing X, check Y — if Y is false, do Z instead" is a rule.
7. **Never save more than 10 learnings per session.** If you found more, prioritize by severity. The goal is high-signal, not completeness.
8. **Credit the conversation.** Each memory should note it came from `/learned` so future sessions can trace the provenance.
9. **Integrate into skills, not just memory.** After `--save`, prompt the user to run `--integrate`. Memory files are temporary staging — skill rules are the permanent enforcement layer. A learning that lives only in memory will be forgotten. The `--integrate` flag handles classification, skill targeting, rule appending, and source file cleanup automatically. *(From: 88 learnings accumulated but none enforced — 2026-04-06 overhaul)*
10. **3+ orphaned learnings = missing skill.** When categorizing, if 3+ learnings cluster around a theme with no owning skill, create a new skill. Don't force-fit into adjacent skills. *(From: 6 agent coordination learnings orphaned until /agent-coordination was created — 2026-04-06)*

---

## Flag: --search "<query>"

FTS5 query against the context-mode index. Sources searched (in order of relevance weight):

1. `learned-project:<currentKey>` — current project's own rules
2. `learned-global` — cross-project rules
3. `learned-skill:*` — every skill's `## Learned Rules` section

### Implementation

1. Resolve current project key from cwd. Map `<projects>/<dir>/...` to slugified key (e.g. `project-a`, `{{project}}-infra`, `project-b`). Fall back to dasherized cwd if not in the registry.
2. Call `mcp__plugin_context-mode_context-mode__ctx_search` with:
   ```json
   {
     "queries": ["<user query>"],
     "sources": ["learned-project:<key>", "learned-global", "learned-skill:*"],
     "mode": "relevance",
     "limit": 8
   }
   ```
3. Return ranked hits with `file:line` pointers and a 1-line excerpt per hit.
4. Increment hit counters in `<project>/.claude/state/learned.md` for each surfaced rule (used by `--decay`).
5. **Fallback** if context-mode is unavailable or `ctx_search` errors:
   ```bash
   grep -rn "<query>" .claude/learned/ ~/.claude/rules/learned-global.md ~/.claude/commands/ 2>/dev/null
   ```
   Surface top 8 grep matches.

### Output format

```
=== LEARNED HITS for "<query>" ===
[1] learned-project:project-a (rank 0.92)
    .claude/learned/learned-rules.md:42 — `Company.tenantId` stores tenant SLUG, not Tenant.id cuid…
[2] learned-skill:deploy (rank 0.81)
    ~/.claude/commands/deploy.md:215 — Always docker-compose down before pull when image tag is :latest…
[3] learned-global (rank 0.74)
    ~/.claude/rules/learned-global.md:24 — OpenRouter slugs are provider/family-version, not provider/version-family…

3 hits across 3 sources.
```

---

## Flag: --reindex [--all]

Rebuild the FTS5 index. **Without `--all`:** only current project's `.claude/learned/learned-rules.md` plus `~/.claude/rules/learned-global.md` plus `~/.claude/commands/*.md` (Learned Rules sections). **With `--all`:** walks every project in `~/.claude/learned-projects.json`.

### Implementation

The SessionStart hook (`~/.claude/hooks/learned-reindex.sh`) only DETECTS staleness. The hook is read-only: it writes a `~/.claude/context-mode/learned-stale.txt` list of sources whose `.md` mtime is newer than the last indexed time. The actual indexing happens here, in the agent, via the MCP tool.

1. If `~/.claude/context-mode/learned-stale.txt` exists, read it. Each line is `<source>|<path>|<mtime>`. Without `--all`, filter to lines whose `<source>` matches the current project, plus `learned-global` and `learned-skill:*`.
2. For each filtered line:
   - Call `mcp__plugin_context-mode_context-mode__ctx_index` with `{path, source, purge: true}`.
   - On success, append `<source> <mtime> <now>` to `~/.claude/context-mode/learned-index.state` (remove any prior entry for that source first).
3. After the loop, truncate `~/.claude/context-mode/learned-stale.txt` to drop the consumed lines.
4. Output per-source line counts indexed.

If `~/.claude/learned-projects.json` does not exist, abort with a message asking the user to run `--register-project` for each project, OR create it via auto-scan of `<projects>/*` and `<projects>/*/*` for `.claude/learned/learned-rules.md` and confirm with the user before writing.

### Output

```
=== REINDEX COMPLETE ===
learned-project:project-a                          53 lines indexed
learned-project:{{project}}-infra                        205 lines indexed
learned-project:project-e                              15 lines indexed
learned-project:project-b     22 lines indexed
learned-project:project-c                 29 lines indexed
learned-project:project-d                     9 lines indexed
learned-global                                     0 lines indexed
learned-skill:deploy                            <N> lines indexed
…
Total: <N> sources, <N> lines.
```

---

## Flag: --register-project <path>

Add a project to the registry and reindex it.

1. Resolve `<path>` to absolute. Verify directory exists.
2. Compute key: lowercased, `[^a-z0-9-]` → `-`, trim trailing `-`. Example: `<projects>/example-project` → `example-project`.
3. Read `~/.claude/learned-projects.json` (create as `[]` if missing).
4. If key already present, abort with message.
5. If `<path>/.claude/learned/learned-rules.md` does not exist, create empty stub:
   ```markdown
   # Learned Rules — <project-name>

   > Project-specific rules. Indexed at FTS5 source `learned-project:<key>`.
   > Edit by hand or via `/learned --save` + `--integrate`.
   ```
6. Append `{key, path}` to registry.
7. Run `--reindex` for that single source.

---

## Flag: --promote <project>:<rule-id>

Move a rule from a project's local file to the global file.

1. Look up project path from registry by key.
2. Read `<projectPath>/.claude/learned/learned-rules.md`. Find rule numbered `<rule-id>` (e.g. `9.` for rule 9).
3. Validate cap: count current lines in `~/.claude/rules/learned-global.md`. If adding the rule would exceed 80 lines, abort with message asking user to demote a stale rule first.
4. Append rule block to `~/.claude/rules/learned-global.md` under the appropriate H2 (Tooling / Process / Environment) — pick the section by keyword match; default to Tooling. Add provenance line `*(Promoted from <project> <YYYY-MM-DD>)*`.
5. Remove the rule from the project file. Renumber subsequent rules in the same domain section.
6. Reindex both sources (`learned-global` + `learned-project:<key>`).
7. Output confirmation:
   ```
   Promoted rule <project>:<rule-id> → learned-global rule <new-id>
   Source file: ~/.claude/rules/learned-global.md (now <N>/80 lines)
   ```

---

## Flag: --decay [--apply]

Surface rules that may be stale.

### Detection

For each rule across `learned-global`, `learned-project:*`, and `learned-skill:*`:
- Read hit count from `<project>/.claude/state/learned.md` (project rules) or `~/.claude/state/learned-global.md` (global/skill rules — create on first run).
- Compute file mtime via `stat`.
- Flag as decay candidate if **either**:
  - Zero hits in last 90 days, OR
  - File mtime older than 180 days AND hit count zero overall.

### Default behaviour (no `--apply`)

Print a report:

```
=== DECAY CANDIDATES ===
[1] learned-project:project-a rule 7 — start:prod npm script wrong path
    Last hit: never  |  File age: 92 days  |  Reason: zero hits + age
[2] learned-skill:deploy rule 12 — Docker Compose profiles…
    Last hit: 2026-01-04  |  File age: 200+ days  |  Reason: zero recent hits

2 candidates. Run `/learned --decay --apply` to mark them for review.
```

### With `--apply`

For each candidate, prepend `<!-- DECAY-CANDIDATE YYYY-MM-DD -->` HTML comment to the rule line. Surface them in the next `/learned --review`. Never auto-deletes.

---

## Post-action indexing

After **`--save`**: for each new memory file written, no FTS5 indexing yet (memory files are staging, indexed only after `--integrate`).

After **`--integrate`**: for each .md target touched (project's `learned/learned-rules.md` or skill file), call `ctx_index` with the matching source label and `purge: true`. This keeps FTS5 in sync immediately rather than waiting for the SessionStart hook.

After **`--promote`**: reindex both `learned-global` and `learned-project:<key>`.
