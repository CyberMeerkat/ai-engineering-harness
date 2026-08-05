# BMAD Integration

This directory holds the harness-specific configuration for [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) — the AI-driven agile development framework that scaffolds every project built using this harness.

## How BMAD fits into this harness

BMAD is **project-level** — it installs into each project (`.bmad-core/`, `_bmad/`, `.opencode/skills/`). This harness does two things on top of that:

1. **Global agents** (`harness/agents/`) — The five BMAD personas (Mary, John, Sally, Winston, Amelia) are available as global OpenCode agents in every project, installed by `setup.sh` / `setup.ps1`. You get the personas immediately, even before BMAD is installed in a specific project.

2. **Team customizations** (`harness/bmad/custom/`) — TOML override files that BMAD's customization system picks up from `_bmad/custom/` in each project. These let you standardise the agents' behavior (persistent facts, persona tweaks, menu additions) across all projects without editing BMAD itself.

## Setting up BMAD in a new project

Run the BMAD installer from your project root:

```bash
npx bmad-method install
```

The interactive installer will:
- Ask which modules to include (accept defaults for the full suite)
- Drop `.bmad-core/`, `_bmad/`, and `.opencode/skills/` into the project
- Wire up OpenCode skills for all agents and workflows

After installing, copy the harness team customizations:

```bash
# from the project root, after npx bmad-method install
cp -r <path-to-harness>/harness/bmad/custom/ _bmad/custom/
```

Or, if you're scaffolding the project using the harness setup scripts directly, this will be handled automatically in future (tracked as a planned enhancement).

## Team customizations (`custom/`)

The `custom/` directory contains TOML override files that apply on top of BMAD's defaults. Each file targets a specific agent or cross-cutting config:

| File | What it customizes |
|---|---|
| `bmad-agent-analyst.toml` | Mary's persona, persistent facts, menu |
| `bmad-agent-pm.toml` | John's persona, persistent facts, menu |
| `bmad-agent-ux-designer.toml` | Sally's persona, persistent facts, menu |
| `bmad-agent-architect.toml` | Winston's persona, persistent facts, menu |
| `bmad-agent-dev.toml` | Amelia's persona, persistent facts, menu |
| `config.toml` | Cross-agent settings (output paths, language, user name) |

These are **team-wide** overrides (committed to this repo). Personal overrides go in `_bmad/custom/<skill-name>.user.toml` in each project and should be gitignored.

## Customization philosophy

BMAD's customization system is additive — your overrides layer on top of BMAD's defaults, not replace them. Principles:

- **Add persistent facts** to give agents standing context (your org's tech stack, standards, constraints).
- **Extend principles** to encode your team's non-negotiables.
- **Adjust communication style** only if you genuinely need a different voice.
- **Don't rename agents** — Mary, John, Sally, Winston, Amelia are the identities. If you need a fundamentally different persona, create a new agent file in `harness/agents/`.

## BMAD version

This harness targets **BMAD Method v6+**. Check https://github.com/bmad-code-org/BMAD-METHOD for the latest.
