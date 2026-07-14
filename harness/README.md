# Harness

This directory is the source of truth for the harness: a repo-first library that builds a project-local OpenCode setup from a fresh clone.

## What belongs here

- authored skills and flows
- reusable helper scripts that are part of a skill
- portable docs that explain installation and conventions
- future MCP server definitions or adapters that are meant to be shared
- plugin manifests and install templates

## What does not belong here

- personal OpenCode instance config
- machine-local wrappers like Tailscale launch scripts
- scheduler/runtime plumbing for one developer machine
- caches, logs, auth, sqlite, sessions, or `node_modules`

## Current contents

| Path | Notes |
|---|---|
| `skills/opencode/` | OpenCode skills. |
| `skills/shared/` | Reusable skills from the `understand-*` family. |
| `mcp/` | Shared MCP notes and future server definitions. |
| `plugins/` | Repo-managed plugin manifests and inventory notes. |
| `plugins/local/` | Local enforcement plugins (secret scanning, generated-file protection, JWT stripping) — installed globally, auto-loaded by OpenCode. |
| `templates/` | Config templates for local tool setup. |
| `scripts/setup.mjs` | Main installer orchestrator — the single source of truth for install logic (see `scripts/lib/`). Invoked by the thin `../setup.sh` / `../setup.ps1` launchers, not directly. |
| `scripts/lib/` | One module per concern: prereqs, opencode-install, mcp-install, project-config (templates/skills/plugins), backup, validate, uninstall, doctor, platform (cross-platform helpers). |

## Recommended OpenCode setup

This repo is the right approach if you use it as the source of truth for shared skills, not as a full checked-in personal OpenCode home directory.

Recommended model:

1. Keep shared skills and future MCP integration code in this repo.
2. Keep secrets and machine-specific auth local.
3. Build a project-local `.opencode/` and `opencode.jsonc` from repo-managed templates.
4. Keep MCP and plugin choices in repo-managed manifests/templates.
5. Add actual MCP server code under `mcp/` when it exists.

That gives you a custom OpenCode setup driven by this repo without coupling the repo to one person's machine.

The overlap between tools is defined once in `../stack/manifest.json` and then rendered into tool-specific outputs.

## Local inventory worth templating

The default integration set is:

- OpenCode MCPs: `context-mode`, `context7`, `jira`, `figma`
- OpenCode plugin: `context-mode`

Those are represented as templates rather than checked-in live configs.

## Installer architecture

`../setup.sh` and `../setup.ps1` are thin launchers whose only job is to make sure a working Node.js is present, then hand off to `scripts/setup.mjs`. Every other concern — OpenCode install, MCP install, project config, skills, plugins, backup/retention, validate, uninstall, doctor — lives in exactly one place (the Node.js core under `scripts/lib/`) instead of being maintained twice in parallel bash and PowerShell implementations. One side benefit: the Node core uses native `JSON.parse`/`fetch()`, so `python3` and `curl` are no longer required once Node itself is bootstrapped.

## Bootstrapping

Review `harness/.env.team`, then run `../setup.sh` to build the project-local OpenCode setup.
