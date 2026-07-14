# AI Engineering Harness — Install

This repo contains assets for AI-assisted development: skills, MCP definitions, plugin manifests, templates, and setup scripts.

Assets live in:

- `harness/` for OpenCode and shared cross-tool assets

Shared integrations are defined in `stack/manifest.json`, and generators build tool-specific outputs from it.

## What gets installed

- OpenCode itself if missing
- OpenCode desktop client on macOS and Windows if missing
- project-local `opencode.jsonc`
- project-local `.opencode/skills/` built from repo-managed skills
- global OpenCode app bundle under `~/.config/opencode/` with MCPs, plugins, and shared skills for the desktop app
- a local `harness/.env.team` file seeded from the example template

## Prerequisites

- Python 3 for template rendering on macOS/Linux
- Node.js 22+ and npm for OpenCode + MCP helper installation

Node.js is also auto-installed or upgraded to the required major version when a supported installer is available:

- macOS/Linux: Homebrew first, then nvm if present
- Windows: nvm-windows, WinGet, Chocolatey, or Scoop

## Quick start

From the repo root:

```bash
./setup.sh
```

On Windows PowerShell:

```powershell
.\setup.ps1
```

By default this:

1. runs a pre-flight prerequisite check
2. installs OpenCode CLI if it is not already installed
3. installs the native OpenCode desktop client on macOS and Windows if not already installed
4. installs local MCP helper binaries when possible
5. uses pinned OpenCode/context-mode versions from `versions.json`
6. builds a minimal project-local OpenCode config from repo templates
7. builds a global OpenCode app bundle in `~/.config/opencode/opencode.json`
8. copies core repo-managed skills into `.opencode/skills/`
9. copies the full shared skill bundle into `~/.config/opencode/skills/`
10. creates `harness/.env.team` if it does not exist yet
11. validates the OpenCode output

## Setup options

| Flag | What it does |
|---|---|
| `--dry-run` / `-DryRun` | Print every action without executing it |
| `--incremental` / `-Incremental` | Update in place, keep global OpenCode state (default) |
| `--reset` / `-Reset` | Wipe global OpenCode config/data/cache before rebuild |
| `--uninstall` / `-Uninstall` | Restore the newest backup and exit |
| `--doctor` / `-Doctor` | Diagnostic report: versions, PATH health, writable dirs |

## After setup

1. Review `harness/.env.team` and replace placeholder values.
2. Review `opencode.jsonc` in the repo root.
3. Open the native OpenCode desktop client if you want the GUI, or run `opencode` from this repo root for CLI use.
4. The desktop app reads its shared bundle from `~/.config/opencode/opencode.json` and `~/.config/opencode/skills/`.
5. Complete provider setup inside OpenCode with `/connect` on first boot.

Current default MCP bundle:

- `context-mode`
- `context7`
- optional `jira`
- optional `figma`

Pinned versions are stored in `versions.json`.

`context7-mcp` is installed from `@upstash/context7-mcp` by the setup flow when npm is available.

The setup uses a project-local `.opencode/` folder instead of user-global symlinks.

For first boot safety, the repo-local project config stays minimal. The native app bundle in `~/.config/opencode/` carries the broader MCP/plugin/shared-skill setup used by the desktop clients.

Setup backs up existing global OpenCode state before overwriting. Backups are kept under `~/.config/opencode-harness-backups/<timestamp>/`. The newest 5 backups are retained; older ones are pruned automatically.

## Notes

- No secrets are committed here.
- OAuth and machine-local bridge setup stay local.
- This repo is the source of truth, and setup builds per-tool outputs from it without merging conflicting raw configs.

## Update behavior

- Pinned package installs reduce drift but also reduce automatic movement to newer releases.
- For OpenCode, if you install a pinned npm version, treat updates as deliberate rather than relying on ad hoc local auto-updates.
- To update intentionally, bump `versions.json`, review, and rerun setup.
