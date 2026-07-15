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
| `local/protect-branches.mjs` | Narrow backstop for the branching policy (see `../rules/branching.md`): blocks `git merge` while on a protected branch, and implicit (no explicit branch name) `git push` that resolves to one. Auto-detects whether the repo uses this branching model at all (checks for a `develop` branch) and is inert otherwise. Deliberately does **not** re-check explicit pushes to a named protected branch — that's handled by the `permission.bash` "ask" rules in `stack/manifest.json` instead, since a plugin can only block/allow, not trigger OpenCode's native ask/once/always/reject prompt. |

Not ported: a 4th original hook (`check-destructive-ops.sh`) blocked specific SSH/docker/scp patterns tied to a *different* engineer's VPS deploy workflow. It wasn't portable as generic content. If you have your own infra rules to enforce, add a new file under `local/` following the same `tool.execute.before` pattern.

## Declarative permission rules (`permission.bash` in `stack/manifest.json`)

The branching policy's *common* case — an explicit `git push origin <protected-branch>` — is handled by native OpenCode permission config (`"ask"`), not a plugin, since only the declarative permission system can trigger the real ask/once/always/reject prompt UI. `protect-branches.mjs` deliberately only covers what text-pattern matching can't see (implicit push target, current-branch context for merge) — see the plugin's own header comment for the full reasoning.

Worth knowing: `opencode --auto` mode auto-approves "ask" rules (only explicit "deny" rules survive auto mode). This policy is a real prompt in normal interactive use, not a guarantee under `--auto`.

## Recommended pattern

Keep plugin selection in repo-managed manifests and templates.
Do not copy installed plugin caches or vendor bundles from personal machines into this repo.

To add a new local plugin: drop a `.mjs` file in `local/`, and `stack/manifest.json`'s `opencode.localPluginsSources` will pick it up automatically on the next `./setup.sh` run — no per-file registration needed.
