# ai-engineering-harness

A repo-first, provider-agnostic harness for [OpenCode](https://opencode.ai): skills, MCP definitions, plugin manifests, and setup scripts.

Provider auth stays inside OpenCode (via `/connect` on first boot) — this repo never touches API keys or model selection.

## Quickstart

```bash
# macOS / Linux
./setup.sh

# Windows PowerShell
.\setup.ps1
```

See [INSTALL.md](INSTALL.md) for prerequisites and all options.

## Commands

| Command | What it does |
|---|---|
| `./setup.sh` | Full install, incremental by default |
| `./setup.sh --dry-run` | Preview every action without touching the filesystem |
| `./setup.sh --reset` | Wipe global OpenCode state before rebuild |
| `./setup.sh --uninstall` | Restore the newest backup |
| `./setup.sh --doctor` | Diagnostic report: versions, PATH health, writable dirs |

Windows equivalents use `-DryRun`, `-Reset`, `-Uninstall`, `-Doctor` switches on `setup.ps1`.

## What's inside

| Path | Purpose |
|---|---|
| `harness/` | Source of truth: skills, scripts, MCP config, plugin manifests, templates |
| `stack/manifest.json` | Canonical registry of shared MCP integrations and skill sources |
| `versions.json` | Pinned versions for OpenCode, MCPs, and Node.js |
| `setup.sh` / `setup.ps1` | Entry points — build outputs from repo sources |

## Philosophy

- **Repo is source-of-truth.** Setup builds generated outputs (`opencode.jsonc`, `.opencode/skills/`, `~/.config/opencode/`) from repo-managed templates and manifests. Never edit the outputs directly.
- **Provider-agnostic.** No provider, model, or API key is baked in. Use any provider OpenCode supports.
- **Safe to re-run.** Every destructive operation backs up first. Retention keeps the newest 5 backups; older ones are pruned automatically.
- **Incremental by default.** `--reset` is opt-in; the default run updates in place.

## Default MCP bundle

| MCP | Type | Enabled by default |
|---|---|---|
| `context-mode` | local | yes |
| `context7` | local | yes |
| `jira` | remote (Atlassian) | no — requires per-user OAuth |
| `figma` | remote (local bridge) | no — requires local bridge |

## Security enforcement

Three local OpenCode plugins install globally on every `./setup.sh` run and protect every project you work in, not just this repo: secret-scanning on file writes/edits, generated-file edit protection, and JWT-in-bash-command blocking. See [`harness/plugins/README.md`](harness/plugins/README.md).

## Layout

```
harness/
  scripts/      setup helpers + new: check-prereqs, uninstall, doctor
  skills/
    opencode/   skills loaded by OpenCode (frontend-design, tailscale-opencode-web)
    shared/     understand-* skill family (codebase analysis, onboarding, domain extraction)
  mcp/          MCP inventory notes; add real MCP servers here
  plugins/      plugin manifests + local/ (security enforcement plugins, installed globally)
  templates/    opencode.template.jsonc, .env.team.example
stack/
  manifest.json canonical MCP + skill source registry
versions.json   pinned tool versions
setup.sh        bash entry point (macOS/Linux/WSL)
setup.ps1       PowerShell entry point (Windows)
```

## License

MIT — see [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
