# The Harness — Overview

> **Read this first.** A 100% analysis of a personal Claude Code setup, packaged so any engineer can
> understand what it is and adopt it. Generated 2026-06-05.

---

## TL;DR

This is not a vanilla Claude Code install. It is a **personal engineering harness** built on top of Claude
Code that turns a single AI session into a **coordinated delivery organisation**. Three things make it
distinct:

1. **An "org-as-skills" delivery engine** — 43 custom slash-commands (architect, product-owner, dev-manager,
   QA, security, deploy, CFO, accountant, brand, launch…) that coordinate through a shared, file-based state
   hub and can run a milestone autonomously from plan → test → gate → deploy.
2. **A defensive enforcement layer** — shell hooks that run *deterministically* on every tool call to block
   destructive ops, secret leaks, and edits to generated files — plus 10 always-loaded behavioural rules.
3. **A stacked memory/recall system** — three independent MCP memory engines (cavemem, context-mode,
   codebase-memory-mcp) wired in simultaneously, on top of a hand-rolled file-memory + cross-project
   "learned rules" system.

The rest of these docs separate **what the user built** from **what ships with Claude Code** and **what was
installed from third parties**, classify every file as master/support/library/ephemeral, and explain how the
pieces wire together.

---

## The two questions this answers

| Your question | Where it's answered |
|---|---|
| What's *mine* vs the *vanilla* Claude deployment? | The 4-Layer Ownership Model (below) + [`01-INVENTORY.md`](01-INVENTORY.md) |
| Which files are *master* vs *support*? | [`02-MASTER-VS-SUPPORT.md`](02-MASTER-VS-SUPPORT.md) |
| How do the files *relate*? | [`04-RELATIONSHIPS.md`](04-RELATIONSHIPS.md) + the diagram below |
| What is actually *happening* here? | [`03-SUBSYSTEMS.md`](03-SUBSYSTEMS.md) |
| How does another engineer *adopt* it? | [`05-ADOPT.md`](05-ADOPT.md) + [`portable/`](portable/) |

---

## The 4-Layer Ownership Model

Your mental model was "custom harness vs vanilla". The truth has **four** layers — and the middle one
matters, because an engineer adopting your setup has to *install* it, not just copy files.

| Layer | Name | Who made it | Ships in this repo? | Share it? |
|---|---|---|---|---|
| **L1** | **Vanilla Claude Code** | Anthropic (the CLI) | Schema/runtime only | N/A — they install the CLI |
| **L2** | **Installed third-party** | Community / Anthropic marketplaces | Yes (cached) | Re-install from source, don't copy |
| **L3** | **Personal harness** *(your IP)* | **You** | **Yes** | **This is the thing to share** |
| **L4** | **Ephemeral / local state** | The machine | Yes | Never — exclude entirely |

- **L1 — Vanilla.** The `settings.json` *schema*, plugin framework, session/transcript store (`projects/`),
  `file-history/`, `ide/`, and built-ins like `/init`, `/review`, `/security-review`. You configure L1; you
  don't author it.
- **L2 — Installed third-party.** Plugins (`context-mode`, `figma`, `watch`, `obsidian`, `gopls-lsp`,
  `caveman`) and marketplace skills (the design-taste family, the spec-driven-dev family `build/check/spec/
  backprop`, `skill-creator`, `find-skills`, `cua-driver`). You *curated* these; you didn't write them.
- **L3 — Personal harness.** `settings.json` *contents*, `hooks/`, `rules/`, `commands/`, `agents/`,
  `agent_docs/`, `scripts/`, the memory + learned systems, `.mcp.json`. **This is your IP and the subject of
  the shareable kit.**
- **L4 — Ephemeral.** `sessions/`, `session-env/`, `shell-snapshots/`, `paste-cache/`, `compact/`, `tasks/`,
  `cache/`, `downloads/`, `debug/`, `backups/`, `*.jsonl`, `stats-cache.json`, `.credentials*`. Captured by
  *convention* in the inventory, never shared.

---

## The 5-Layer Productivity Stack (your own architecture)

Your `scaffold/CLAUDE.md` states the design philosophy explicitly. This is the spine of the whole harness —
each layer trades context-cost against compliance:

```
Layer 5: Subagents   — Delegated work, separate context, tool restrictions   (agents/)
Layer 4: Worktrees   — Parallel isolation, one task per session
Layer 3: Hooks       — Deterministic enforcement, 100% compliance, 0 ctx cost (hooks/)
Layer 2: Skills      — On-demand workflows, load only when invoked (~80%)     (commands/ + skills/)
Layer 1: CLAUDE.md   — Persistent context, loads every session (~80%)         (rules/ globally)
```

The insight encoded here: **rules and skills are ~80% reliable** (the model can ignore them), so anything
*non-negotiable* (no secrets, no destructive VPS ops, no editing generated files) is pushed **down to the
hook layer**, which is 100% deterministic and costs zero context tokens.

---

## One-screen architecture

```
                       ┌─────────────────────────────────────────────┐
                       │  settings.json   (THE SPINE — wires it all)  │
                       └───────┬───────────────┬───────────────┬──────┘
            hooks ◄────────────┘               │               └────────► statusLine (python)
              │                          enabledPlugins                    dir/branch/model/ctx%/limits
   PreToolUse │ (deterministic gates)    context-mode, figma,
   ┌──────────┴──────────┐               watch, obsidian, gopls
   │ check-destructive   │                     │
   │ check-secrets       │              ┌──────┴──────┐
   │ check-generated     │              │  MCP layer  │
   │ strip-jwt           │              ├─────────────┤
   │ cbm-discovery-gate  │              │ cavemem     │ (settings.json mcpServers)
   └─────────────────────┘              │ context-mode│ (plugin)
   SessionStart                         │ codebase-mem│ (.mcp.json + .claude/.claude/settings.local.json)
   ┌─────────────────────┐              └─────────────┘
   │ cbm-session-reminder│
   │ context-mode-heal   │     rules/*.md  ── 10 always-loaded behavioural rules (the "CLAUDE.md layer")
   │ learned-reindex     │           │
   └─────────────────────┘           └── referenced by hooks + the /learned skill

   commands/ (43)  ──►  agent_docs/*-reference.md  ──►  PROJECT-level .claude/state/triage.md + data/
   "org-as-skills"      (lean dispatcher → deep ref)    (the shared brain, created per-repo by /scaffold)

   agents/ (3)     auditor (read-only) · state-reader · implementer
```

---

## What's actually going on here — the 6 characteristics

1. **Autonomous Delivery System.** `commands/README.md` is its map. 21+ triage-integrated skills feed one
   shared state file; `/milestone --run` chains quality-gate → security → docs → deploy, always pausing for
   human confirmation before production. → [`03-SUBSYSTEMS.md` §A](03-SUBSYSTEMS.md)
2. **Triple memory stack.** cavemem + context-mode + codebase-memory-mcp run *at the same time*, each with
   its own hooks and its own purpose (conversational memory / context compression / code knowledge-graph).
   Plus your own file-memory and cross-project learned-rules. → [`03-SUBSYSTEMS.md` §B](03-SUBSYSTEMS.md)
3. **Hook-enforced guardrails.** 8 wired shell hooks make safety deterministic — including blocks that
   hard-code a real production VPS IP/hostname (see sanitisation note). → [`03-SUBSYSTEMS.md` §C](03-SUBSYSTEMS.md)
4. **Always-loaded behavioural spine.** 10 `rules/*.md` (tone-budget, skill-budget, git-workflow, testing,
   node-version, memory-hygiene, ui-design-system, search-first, coding-standards, learned-global) shape
   every reply before any task starts.
5. **Design-system pipeline.** A rule forces every UI task through `ui-ux-pro-max` (a heavyweight design
   engine) cross-referenced with brand tokens, then checked against anti-patterns.
6. **Self-distributing.** `/scaffold` + `scripts/scaffold.sh` + `registry.txt` can push the harness into any
   registered repo and keep them in sync — this is the built-in answer to "share it with my team".

---

## Headline numbers

| Thing | Count | Notes |
|---|---|---|
| Custom slash-commands | **43** (+README) | The org-as-skills engine — all L3 |
| Always-loaded rules | **10** | `rules/*.md` |
| Hook scripts | **11** | 8 wired, 3 dormant/reference |
| Subagent personas | **3** | auditor, state-reader, implementer |
| Reference docs | **13** | `agent_docs/` (7 refs + deploy + brand-quality + 4 lenses) |
| Skills (installed/mixed) | **23** | mostly L2; `ui-ux-pro-max` is the heavyweight |
| MCP memory servers | **3** | cavemem, context-mode, codebase-memory-mcp |
| Enabled plugins | **5** | context-mode, figma, watch, obsidian, gopls-lsp |

→ Continue to [`01-INVENTORY.md`](01-INVENTORY.md) for the exhaustive file-by-file map.
