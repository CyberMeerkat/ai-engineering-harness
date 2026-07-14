# .claude/ — Project Intelligence Layer

> **Entrypoint.** Start here. This file indexes every resource in the `.claude/` directory.

## Quick Start

1. Read `.claude/state/triage.md` — lean index (pointers to state files)
2. Run `/<skill> --session-start` for domain-specific briefing
3. Check `~/.claude/commands/` for the full skill catalogue

## Architecture: 5-Layer Productivity Stack

```
Layer 5: Subagents      — Delegated work, separate context, tool restrictions
Layer 4: Worktrees      — Parallel isolation, one task per session
Layer 3: Hooks          — Deterministic enforcement, 100% compliance, zero context cost
Layer 2: Skills         — On-demand workflows, loads only when invoked (~80% compliance)
Layer 1: CLAUDE.md      — Persistent project context, loads every session (~80% compliance)
```

## Directory Map

```
.claude/
├── CLAUDE.md               <- you are here
├── settings.json            config: permissions (shared)
├── settings.local.json      config: permissions (local, gitignored)
│
├── rules/                  <- Project-specific enforcement rules (if any)
│
├── commands/               <- Project-specific skill overrides (if any)
│   └── .overrides           lists which commands are intentional forks
│
├── agent_docs/             <- Reference docs loaded on-demand by skills
│   └── lenses/              stakeholder review checklists (project overlay)
│
├── agents/                 <- Project-specific agent personas (if any)
│
├── state/                  <- Mutable state (skills read + write, gitignored)
│   └── triage.md            lean index — pointers to domain state files
│
├── data/                   <- Work artifacts
│   ├── plans/               engineering plan files (EP-*.md)
│   ├── sprints/             sprint scope documents
│   ├── milestones/          milestone definitions
│   ├── evidence/            verification evidence
│   └── launches/            launch plan files
│
├── compact/                <- Context continuation snapshots (gitignored)
│
└── archive/                <- Completed / historical
```

## What's Available Globally

These load from `~/.claude/` — no project setup needed:

| Layer | Global Location | What's There |
|-------|----------------|-------------|
| Skills | `~/.claude/commands/` | ~36 lean dispatchers (architect, product-owner, dev-manager, etc.) |
| Reference | `~/.claude/agent_docs/` | Detailed procedures per skill + stakeholder lenses |
| Agents | `~/.claude/agents/` | 3 personas: auditor (read-only), state-reader, implementer |
| Hooks | `~/.claude/hooks/` | Generated file protection, destructive op blocking, secret detection |
| Rules | `~/.claude/rules/` | Coding standards, testing standards, search-first |

## Stakeholder Review Gate

Every `/engineering-plan --plan` automatically applies 4 stakeholder lenses:

| Lens | Global Checklist | Project Overlay |
|------|-----------------|----------------|
| Architect | `~/.claude/agent_docs/lenses/architect.md` | `.claude/agent_docs/lenses/overlay.md` § Architect |
| Legal | `~/.claude/agent_docs/lenses/legal.md` | same |
| Security | `~/.claude/agent_docs/lenses/security.md` | same |
| Compliance | `~/.claude/agent_docs/lenses/compliance.md` | same |

To add project-specific concerns, edit `.claude/agent_docs/lenses/overlay.md`.

## First Run

```
/status              → See empty state, get bootstrap recommendations
/product-owner --plan-sprint 1   → Define scope from existing code (or /grill-me for greenfield)
/architect --status  → Inventory components, detect drift
```

After bootstrap, every session starts with `/status` → pick an option → work → `/verify --full` → commit.

## Key Principles

- **Skills are lean dispatchers** (~50-80 lines) that route to reference docs in `~/.claude/agent_docs/`
- **Hooks enforce non-negotiable rules** (100% compliance, zero context cost)
- **Stakeholder review is automatic** on every engineering plan
- **Status reads state, never spawns skills**
- **Triage is a lean index** — detail lives in domain state files
- **Boundary rule** — skills never spawn other stakeholder skills

## Scaffold System

Managed by `/scaffold` backed by `~/.claude/scripts/scaffold.sh`.

| Command | What it does |
|---------|-------------|
| `/scaffold --init` | Create this structure in a new project |
| `/scaffold --update` | Sync skills + ensure directories are current |
| `/scaffold --distribute` | Push updates to ALL registered workspaces |
| `/scaffold --fork <name>` | Copy a global skill to project for customization |
| `/scaffold --diff` | Show drift between global and local |

**What stays local** (never overwritten): `state/`, `data/`, `compact/`, `archive/`, `settings.json`, `CLAUDE.md` (after init)

## Conventions

- **State files** — `state/<skill>.md`, each owned by one skill
- **Triage** — lean index only, never exceeds 120 lines
- **Skills** — lean dispatchers, reference docs in `~/.claude/agent_docs/`
- **Data files** — `data/<category>/`, prefixed with type codes (EP-, M-, L-)
- **Boundary rule** — skills never spawn other stakeholder skills
