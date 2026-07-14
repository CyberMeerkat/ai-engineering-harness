# Plugin Inventory

This folder tracks plugin choices for OpenCode: both npm-installed plugins and local file-based enforcement plugins.

## npm plugins (registered in `opencode.plugins.json`, installed via npm at OpenCode startup)

- `context-mode`

## Local plugins (`local/`, auto-loaded from `~/.config/opencode/plugins/`)

Security/enforcement hooks ported from a Claude Code hook-based harness onto OpenCode's `tool.execute.before` plugin API. These install **globally only** — they protect every project you work in, not just this repo, since global plugins load regardless of which project OpenCode is opened from.

| File | What it blocks |
|---|---|
| `local/check-secrets.mjs` | File writes/edits containing hardcoded secrets (AWS keys, GitHub tokens, private key blocks, DB connection strings with passwords, JWTs, Slack webhooks, Stripe/SendGrid keys, hardcoded passwords). Skips `.opencode/{state,data,compact}/` and `memory/` paths. |
| `local/check-generated-files.mjs` | Edits to files with a `GENERATED FILE - DO NOT EDIT` / `@generated` / `AUTO-GENERATED` header in the first ~2KB. |
| `local/strip-jwt.mjs` | Bash commands containing a raw JWT (`eyJ...`) so ephemeral tokens never get cached as a standing permission. |

Not ported: a 4th original hook (`check-destructive-ops.sh`) blocked specific SSH/docker/scp patterns tied to a *different* engineer's VPS deploy workflow. It wasn't portable as generic content. If you have your own infra rules to enforce, add a new file under `local/` following the same `tool.execute.before` pattern.

## Recommended pattern

Keep plugin selection in repo-managed manifests and templates.
Do not copy installed plugin caches or vendor bundles from personal machines into this repo.

To add a new local plugin: drop a `.mjs` file in `local/`, and `stack/manifest.json`'s `opencode.localPluginsSources` will pick it up automatically on the next `./setup.sh` run — no per-file registration needed.
