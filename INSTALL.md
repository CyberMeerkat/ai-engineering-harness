# Team Harness Install

This repo contains shared team assets for AI-assisted development: skills, MCP definitions, plugin manifests, templates, and setup scripts.

The repo now composes two source layers:

- `naman/` for OpenCode and shared cross-tool assets
- `shahil/portable/` for Claude-specific harness assets

Shared overlap is defined in `stack/manifest.json`, and generators build tool-specific outputs from it.

## What gets installed

- OpenCode itself if missing
- OpenCode desktop client on macOS and Windows if missing
- project-local `opencode.jsonc`
- project-local `.opencode/skills/` built from repo-managed skills
- global OpenCode app bundle under `~/.config/opencode/` with MCPs, plugins, and shared skills for the desktop app
- generated Claude home config under `~/.claude/`
- a local `naman/.env.team` file seeded from the example template

## Prerequisites

- Python 3 for template rendering on macOS/Linux
- Node.js 22+ and npm for OpenCode + MCP helper installation

Claude Code is auto-installed by setup when missing. If your shell session does not pick up the `claude` command immediately after install, restart the shell and rerun setup.

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

1. installs OpenCode CLI if it is not already installed
2. installs the native OpenCode desktop client on macOS and Windows if it is not already installed
3. verifies Claude Code is already installed
4. installs local MCP helper binaries when possible
5. uses pinned OpenCode/context-mode versions from `versions.json`
6. installs Claude Code if it is missing
7. builds a minimal project-local OpenCode config from repo templates
8. builds a global OpenCode app bundle in `~/.config/opencode/opencode.json`
9. copies core repo-managed skills into `.opencode/skills/`
10. copies the full shared skill bundle into `~/.config/opencode/skills/`
11. creates `naman/.env.team` if it does not exist yet
12. generates a Claude harness into `~/.claude/` from `shahil/portable/`
13. validates both the OpenCode and Claude outputs

## After setup

1. Review `.env.team` and replace placeholder values.
2. Review `opencode.jsonc` in the repo root.
3. Open the native OpenCode desktop client if you want the GUI, or run `opencode` from this repo root for CLI use.
4. The desktop app reads its shared bundle from `~/.config/opencode/opencode.json` and `~/.config/opencode/skills/`.
5. Complete provider setup inside OpenCode with `/connect` on first boot.
6. Start Claude Code and use the generated `~/.claude/` harness.
7. If you are developing the in-house MCP, start from `naman/mcp/team-mcp/`.

If `~/.claude/` already existed, setup creates a backup under:

- `~/.claude/.delta-ai-harness-backups/<timestamp>/`

Current default MCP bundle:

- `context-mode`
- `context7`
- optional `jira`
- optional `figma`

The in-house `team-mcp` scaffold exists in the repo but is not enabled by default because there is no real team MCP yet.

Pinned versions are stored in `versions.json`.

`context7-mcp` is installed from `@upstash/context7-mcp` by the setup flow when npm is available.

The setup now uses a project-local `.opencode/` folder instead of user-global symlinks.

For first boot safety, the repo-local project config stays minimal. The native app bundle in `~/.config/opencode/` carries the broader MCP/plugin/shared-skill setup used by the desktop clients.

Setup also backs up and resets stale global OpenCode config/state directories before first boot so old local state does not poison startup.

Claude output is generated into `~/.claude/` because Claude's harness is intentionally user-home based.

## Notes

- No secrets are committed here.
- OAuth and machine-local bridge setup stay local.
- This repo is the shared source of truth, and setup builds per-tool outputs from it without merging conflicting raw configs.
- Claude generation is backup-first for managed paths, not blind overwrite.

## Update behavior

- Pinned package installs reduce drift but also reduce automatic movement to newer releases.
- For OpenCode, if you install a pinned npm version, treat updates as team-managed rather than relying on ad hoc local auto-updates.
- To update intentionally, bump `versions.json`, review, and rerun setup.

Short answer: pinning OpenCode means you should not rely on regular auto-update prompts as your update mechanism.
