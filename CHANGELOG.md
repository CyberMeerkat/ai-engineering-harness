# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-07-14

### Added

- **Installer consolidated into a single Node.js core.** `setup.sh` and `setup.ps1` are now thin launchers (~90 lines each) whose only job is to bootstrap a working Node.js, then hand off to `harness/scripts/setup.mjs`. Every other concern — OpenCode CLI/desktop install, MCP install, project config rendering, skills/plugins copying, backup/retention, validate, uninstall, doctor — lives in exactly one place (`harness/scripts/lib/*.mjs`) instead of two independently-maintained, occasionally-drifting bash/PowerShell implementations.
- Side benefit: the Node core uses native `JSON.parse`/`fetch()`, so **`python3` and `curl` are no longer required** once Node itself is bootstrapped (previously hard prerequisites for template rendering and desktop-app downloads).
- 3 local security plugins (`harness/plugins/local/`), ported from a Claude Code hook-based harness onto OpenCode's `tool.execute.before` plugin API, installed globally on every setup run: `check-secrets.mjs`, `check-generated-files.mjs`, `strip-jwt.mjs`. See `harness/plugins/README.md`.
- `.github/scripts/test-local-plugins.mjs` — 12-case functional smoke test for the security plugins, run in CI on every push.
- CI: `test-installer-core` (syntax-checks every `lib/*.mjs` module) and an extra `--doctor` pass in the dry-run matrix.
- `.gitattributes` — forces LF on `.sh` files regardless of a cloning machine's `core.autocrlf` setting (prevents CRLF corruption breaking bash execution on a fresh Windows clone).

### Removed

- 8 redundant bash scripts fully replaced by the Node.js core: `install-opencode.sh`, `install-node.sh`, `install-mcp-deps.sh`, `build-project-opencode.sh`, `validate-setup.sh`, `check-prereqs.sh`, `uninstall.sh`, `doctor.sh`.
- `incident-report-logger` skill — authored for workplace/client incident reporting, doesn't fit a personal harness.
- CI's `Set up Python` step in the dry-run matrix (no longer needed — see python3 removal above).

### Fixed (found via actual execution, not just code review)

- Two bash 3.2 incompatibilities (macOS's default shell — `declare -A` needs bash 4+).
- `doctor.sh`'s broken `pipe | python3 - <<heredoc` pattern (heredoc hijacks stdin meant for the piped data).
- `--dry-run` was performing real installs in `install-opencode.sh`, `install-node.sh`, `install-mcp-deps.sh`, and the desktop installer (no dry-run awareness at all — only "already installed" fast paths existed).
- Unguarded `.env.team` sourcing and `validate-setup.sh` call in `setup.sh` crashed dry-run under `set -e`.
- `setup.ps1`'s `Get-ChildItem -Include '*.mjs','*.js' -Path $source` silently returned zero results (a documented `-Include`/`-Path` gotcha) — would have shipped a plugin-copy feature that copied nothing, forever, with no visible error.
- `resolveDesktopPath()` initially missed non-standard OpenCode Desktop install locations (e.g. `Programs\@opencode-aidesktop\`) — ported the original PowerShell's recursive-search fallback, which the direct port had dropped.
- A test helper script's own path resolution mishandled Windows drive letters (`new URL().pathname` vs `fileURLToPath()`).

See `_OBSERVATIONS.md` for the full bug-by-bug record across all phases.

## [0.1.0] - 2026-07-14

Initial fork from upstream delta-ai-harness (ref sha 24fb9db). See commit history for full rework details.

### Added

- `--dry-run`, `--incremental`, `--reset`, `--uninstall`, `--doctor` flags on `setup.sh` and `setup.ps1`
- `harness/scripts/check-prereqs.sh` — pre-flight prerequisite check (node, python3, npm, curl)
- `harness/scripts/uninstall.sh` — restore the newest backup and exit
- `harness/scripts/doctor.sh` — diagnostic report: versions, PATH health, writable dirs
- Backup retention: keep newest 5 by default (`HARNESS_BACKUP_RETENTION` overrides)
- `--incremental` mode (default): update in place without wiping global OpenCode state
- Pre-flight prerequisite check runs before any destructive action
- `setup.ps1` `Ensure-PathContains` now prompts before writing to persistent User PATH
- GitHub Actions CI: shellcheck, PSScriptAnalyzer, JSON validation, dry-run matrix (ubuntu/macos/windows)
- Root `README.md`, `LICENSE` (MIT), `CHANGELOG.md`, `CONTRIBUTING.md`
- `.editorconfig` and `.shellcheckrc` for consistent formatting

### Removed

- Claude Code generation pipeline (`shahil/`, `generate-claude-home.sh`, `validate-claude-setup.sh`)
- Codex CLI artefacts (`codex-config.template.toml`, `codex.plugins.toml`)
- `naman/mcp/team-mcp/` scaffold (was a bare HTTP server stub, not an MCP)
- `naman/flows/` empty placeholder

### Changed

- Renamed `naman/` → `harness/`
- Renamed backup dirs: `.delta-ai-harness-backups` → `.harness-backups`, `opencode-delta-ai-harness-backups` → `opencode-harness-backups`
- Removed `claude` block from `stack/manifest.json` (OpenCode-only pipeline)
- `harness/README.md` updated to reflect new name and dropped Claude/Codex references
- `INSTALL.md` retitled and rewritten for OpenCode-only setup
- `harness/mcp/README.md` simplified; team-mcp scaffold removed
- `harness/plugins/README.md` trimmed to OpenCode section only
- `versions.json` now carries `harness.version = "0.1.0"`
