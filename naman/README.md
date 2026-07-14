# Naman Shared Team Skills

This directory is now trimmed for the team goal: a shared, repo-first library that builds a project-local OpenCode setup from a fresh clone.

## What belongs here

- team-authored skills and flows
- reusable helper scripts that are part of a skill
- portable docs that explain installation and conventions
- future MCP server definitions or adapters that are meant to be shared by the team
- plugin manifests and install templates

## What does not belong here

- personal OpenCode instance config
- machine-local wrappers like Tailscale launch scripts
- scheduler/runtime plumbing for one developer machine
- Codex system/vendor skills copied from the tool install
- caches, logs, auth, sqlite, sessions, or `node_modules`

## Current contents

| Path | Notes |
|---|---|
| `skills/opencode/` | Team-usable OpenCode skills. |
| `skills/shared/` | Reusable skills copied from the shared `understand-*` plugin source. |
| `flows/` | Placeholder for shared team flows as they are authored. |
| `mcp/` | Shared MCP notes and future server definitions. |
| `plugins/` | Repo-managed plugin manifests and inventory notes. |
| `templates/` | Config templates for local tool setup. |
| `scripts/build-project-opencode.sh` | Builds project-local `.opencode/` and `opencode.jsonc` from repo templates. |
| `scripts/install-opencode.sh` | Installs OpenCode on macOS/Linux. |
| `scripts/install-mcp-deps.sh` | Installs local MCP helper binaries when available. |
| `scripts/validate-setup.sh` | Verifies the repo is ready to run with OpenCode. |

## Recommended OpenCode setup

This repo is the right approach if you use it as the source of truth for shared skills, not as a full checked-in personal OpenCode home directory.

Recommended model:

1. Keep shared skills, flows, and future MCP integration code in this repo.
2. Keep secrets and machine-specific auth local.
3. Build a project-local `.opencode/` and `opencode.jsonc` from repo-managed templates.
4. Keep MCP and plugin choices in repo-managed manifests/templates.
5. Add actual in-house MCP server code under `mcp/` when it exists.

That gives you a custom OpenCode setup driven by this repo without coupling the repo to one person's machine.

For Claude Code, the repo also generates a user-home harness from `shahil/portable/` rather than trying to merge raw Claude files into the OpenCode layout.

The overlap between tools is defined once in `../stack/manifest.json` and then rendered into tool-specific outputs.

## Local inventory worth templating

From the current machine, the reusable integration set is:

- OpenCode MCPs: `context-mode`, `context7`, `jira`, `figma`
- OpenCode plugin: `context-mode`
- Codex plugins: `canva@openai-curated`, `github@openai-curated`

Those are represented as templates rather than checked-in live configs. There is no real shared team MCP in the default setup yet.

## Bootstrapping

- `../setup.sh`

Review `naman/.env.team`, then run `../setup.sh` to build the project-local OpenCode setup.
