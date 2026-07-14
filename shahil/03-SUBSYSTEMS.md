# 03 — Subsystems (what's actually happening)

> Five engines run inside this harness. This doc explains each one's purpose, its moving parts, and the
> non-obvious design decisions behind it.

- [§A — Autonomous Delivery System](#a--autonomous-delivery-system)
- [§B — The memory stack (3 MCP engines + 2 of your own)](#b--the-memory-stack)
- [§C — The enforcement layer (hooks × rules × permissions)](#c--the-enforcement-layer)
- [§D — The design-system pipeline](#d--the-design-system-pipeline)
- [§E — MCP, plugins & the status line](#e--mcp-plugins--the-status-line)

---

## §A — Autonomous Delivery System

The 43 commands aren't independent tools — they're an **organisation modelled as skills**, coordinated
through a shared file-based brain. `commands/README.md` is the canonical spec.

### The shared brain (project-level, not in `~/.claude`)
Every command reads/writes a project-local `.claude/state/` tree that the scaffold system creates *inside
each repo*:

```
.claude/state/triage.md        ← central hub: a lean index (≤120 lines) pointing to domain state
.claude/state/<skill>.md       ← one state file per skill, owned exclusively by that skill
.claude/data/{plans,sprints,milestones,evidence,launches}/   ← work artifacts (EP-*, M-*, L-*)
```

**Key portability fact:** none of this lives in `~/.claude`. The home dir holds the *programs* (commands,
rules, hooks); the *data* is per-project. An engineer adopting the harness runs `/scaffold --init` to
materialise this tree in their repo.

### The contract that makes it work
Three rules keep 43 loosely-coupled skills from stepping on each other:
1. **Single-writer state** — each `state/<skill>.md` is written by exactly one skill; everyone else reads it.
2. **Triage is an index, not a store** — detail lives in domain files; triage just points. Any fresh agent
   reads triage to instantly understand the whole project.
3. **Boundary rule** — skills never spawn other stakeholder skills. `/status` *reads* state and *recommends*;
   it never executes. The one exception is `/milestone --run`.

### The autonomous loop
`/milestone --run <name>` is the conductor. It verifies gates, invokes skills via the Skill tool, re-verifies,
and advances — **always stopping for human confirmation before `/deploy --execute` (non-negotiable)**:

```
/grill-me  →  /engineering-plan  →  /test --tdd  →  /quality-gate  →  /deploy --execute (HITL)
   think         plan (4-lens review gate)   build        verify              ship
```

The parallel gate fan-out from `commands/README.md`:

```
/milestone --run
      ├── /quality-gate --verify   → PASS/FAIL
      ├── /security-review --scan   → PASS/FAIL
      └── /doc-rules --check        → PASS/FAIL
              ↓ all PASS
        /deploy --execute prod  (user confirmation)
              ↓
        /deploy --verify → /brand --check → /metrics --check → Milestone PASSED ✓
```

### Command anatomy (so engineers can extend it)
Every command is a **lean dispatcher** (skill-budget rule: ≤15 KB). Example shape from `milestone.md`:

```yaml
---
description: <one line>
argument-hint: [--session-start] [--define <name>] [--run <milestone>] …
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash, TodoWrite, Skill, ctx_execute, …]
---
# <name> — <role>
## Core Mindset          ← the persona / non-negotiables
## Arguments             ← flag → behaviour table ($ARGUMENTS)
## Reference             ← "read ~/.claude/agent_docs/<name>-reference.md for procedures"
## Boundaries            ← what it reads, what it writes, what it must NOT do
```

The heavy procedures live in `agent_docs/<name>-reference.md`, loaded only when the command runs — keeping
per-invocation context small.

---

## §B — The memory stack

This is the most striking thing in the setup: **five memory/recall systems run at once**, three of them
full MCP servers. They overlap, and that's a deliberate belt-and-braces choice — but it's the first thing to
rationalise if simplifying.

| System | Type | Wired via | Scope / job |
|---|---|---|---|
| **cavemem** | MCP + 5 hooks | `settings.json` `mcpServers` + Post/UserPrompt/Stop/SessionStart/SessionEnd | Automatic *conversational* memory — captures & replays across sessions. |
| **context-mode** | Plugin MCP + 1 hook | plugin + `context-mode-cache-heal.mjs` | *Context-window compression* — runs big shell/data work in a sandbox, indexes output to FTS5, returns digests (`ctx_*` tools). |
| **codebase-memory-mcp** | MCP + 2 hooks | `.mcp.json` + nested `settings.local.json` + `cbm-*` hooks | *Code knowledge-graph* — `search_graph`, `trace_path`, `get_code_snippet` instead of grep/read. |
| **File-memory** | Markdown files | the memory directive + `memory-hygiene.md` rule | Hand-curated facts: `MEMORY.md` index + `feedback_*/project_*/reference_*` files per project. |
| **Learned rules** | Markdown + FTS5 | `learned-projects.json` + `learned-reindex.sh` + `/learned` + `rules/learned-global.md` | Cross-project "lessons" — global (always-loaded, ≤80 lines) + per-project `.claude/learned/learned-rules.md` (FTS5-indexed, recalled on demand). |

### How they differ (the mental model)
- **cavemem** remembers *the conversation* (what you and the agent said/did).
- **context-mode** keeps *raw tool output* out of the window (logs, big files, API responses) and lets the
  agent query it instead of pasting it.
- **codebase-memory-mcp** understands *the code* structurally (who calls what).
- **File-memory** is *you* writing durable facts for future sessions.
- **Learned rules** is *post-mortem knowledge* — "this bug bit us; here's the prevention rule" — promoted
  global when it's tooling-general.

### The learned-rules reindex flow (clever bit)
`learned-reindex.sh` (SessionStart) computes which learned `.md` files changed since last index — global
rules, each project's `.claude/learned/learned-rules.md` (from `learned-projects.json`), and any skill file
with a `## Learned Rules` section — and writes a *stale list*. It never indexes itself (only the agent can
call the `ctx_index` MCP tool); the `/learned` skill reads the stale list and triggers the reindex. Clean
separation of "detect" (deterministic hook) from "act" (agent tool).

> **Simplification note for adopters:** you do not need all five. The minimal useful subset is
> codebase-memory-mcp (code) + file-memory (facts) + learned rules (lessons). cavemem and context-mode are
> powerful but heavy; adopt them deliberately.

---

## §C — The enforcement layer

The philosophy (from `scaffold/CLAUDE.md`): rules and skills are ~80% reliable, so **non-negotiables move
down to hooks**, which are 100% deterministic and cost zero context tokens. Defence-in-depth has three tiers.

### Tier 1 — Hooks (deterministic, runtime)
| Hook | Blocks |
|---|---|
| `check-destructive-ops.sh` | SCP-to-VPS, `docker compose down/restart` on prod, `systemctl restart docker`, ad-hoc prisma on prod — each tied to a past incident. **Hard-codes the production IP + hostname** (see caveat). |
| `check-secrets.sh` | 14 secret classes on Write/Edit: AWS keys, GitHub/Stripe/SendGrid tokens, Slack webhooks, private keys, DB URLs w/ passwords, JWTs, hardcoded passwords. Skips state/data/memory + `.env`/`.yml`. |
| `check-generated-files.sh` | Edits to files with `@generated`/"DO NOT EDIT" in the first 5 lines. |
| `strip-jwt-permissions.sh` | Bash commands carrying a JWT — stops ephemeral tokens accumulating in the permission allowlist. |
| `cbm-code-discovery-gate` | The *first* Grep/Glob/Read/Search per session (exit 2) — forces a conscious choice to use codebase-memory-mcp; subsequent searches pass. |

Hook mechanics: read tool JSON on stdin, `exit 0` allow, `exit 1`/`exit 2` block with a message on
stdout/stderr. They parse input with inline `python3` and reference the learned rule each one enforces.

### Tier 2 — Rules (always-loaded, ~80%)
The 10 `rules/*.md` are softer but broader — style, workflow, standards. They shape intent; hooks catch the
failures. (e.g. `coding-standards` *asks* not to edit generated files; `check-generated-files.sh` *enforces* it.)

### Tier 3 — Permissions (allowlist)
`settings.json` `permissions.allow` pre-approves a tight set (context-mode `ctx_*`, `gh`, `docker push/
manifest`, `osascript`, specific `npx`/screenshot commands) with `defaultMode: auto`. Everything else prompts.

### ⚠ Sanitisation caveat
`check-destructive-ops.sh` embeds a real production IP and hostname, and the secret patterns are tuned to
this user's stack. Before sharing, these become placeholders — see [`05-ADOPT.md`](05-ADOPT.md) and
[`portable/`](portable/).

---

## §D — The design-system pipeline

UI work is *forced* through a pipeline by the `ui-design-system.md` rule (loaded every session). The mandated
flow:

```
ui-design-system.md (rule)
   → run search.py --design-system   (ui-ux-pro-max engine: 50+ styles, 161 palettes, 57 font pairs, 99 UX rules)
   → cross-reference project brand tokens   (project overrides ALWAYS win)
   → check returned anti-patterns
   → run pre-delivery checklist before marking complete
```

Supporting cast:
- **`ui-ux-pro-max`** (skill, the heavyweight) + `agent_docs/ui-ux-pro-max-reference.md` (interpretation guide).
- **`brand-quality`** (skill) + `agent_docs/brand-quality/runbooks.md` — "is this connoisseur-tier / anti-cheap" audits.
- **design-taste skill family** (`design-taste-frontend`, `emil-design-eng`, `high-end-visual-design`,
  `industrial-brutalist-ui`, `minimalist-ui`, `gpt-taste`, `redesign-existing-projects`) — stylistic lenses.
- **figma plugin** — design↔code bridge.
- **`/brand` command** + `agent_docs/brand-reference.md` — token enforcement & Figma-drift tracking.

The rule explicitly defers to a project brand source-of-truth (`.claude/agent_docs/<project>-design-overrides.md`
when present) over generic suggestions — generic design system is the floor, brand tokens are the law.

---

## §E — MCP, plugins & the status line

### MCP servers (3)
| Server | Registered in | Tools |
|---|---|---|
| `cavemem` | `settings.json` `mcpServers` | conversational memory (`mcp`) |
| `codebase-memory-mcp` | `.mcp.json` + nested `settings.local.json` | `search_graph`, `trace_path`, `get_code_snippet`, `index_repository`, … |
| `context-mode` | plugin | `ctx_batch_execute`, `ctx_execute`, `ctx_search`, `ctx_fetch_and_index`, … |

### Plugins (5 enabled, from 5 marketplaces)
`context-mode@context-mode`, `figma@claude-plugins-official`, `watch@claude-video`,
`obsidian@obsidian-skills`, `gopls-lsp@claude-plugins-official`. (`caveman` marketplace is known but the
plugin isn't enabled — cavemem is wired as a raw MCP server instead.) Marketplaces are declared in
`settings.json` `extraKnownMarketplaces`.

### Status line
A single inline `python3` script renders a live status bar:
`dir (git-branch) | model | ctx:% | 5h:% | 7d:% | vim-mode | agent:name | [session-name]`
with colour thresholds (ctx ≥80% red, ≥50% yellow). It shells out to `git symbolic-ref` for the branch and
reads the worktree branch when in one. Pure presentation — no behavioural effect.

### Misc config
`voice` enabled (hold-to-talk), `theme: light-ansi`, `agentPushNotifEnabled: true`,
`skipAutoPermissionPrompt: true`.

→ Continue to [`04-RELATIONSHIPS.md`](04-RELATIONSHIPS.md) for the explicit file-to-file graph.
