# Contributing

## Adding a skill

Skills live under `harness/skills/`. There are two categories:

- `harness/skills/opencode/` — skills specific to this harness (loaded into project `.opencode/skills/`)
- `harness/skills/shared/` — broadly reusable skills (also loaded into global `~/.config/opencode/skills/`)

To add a new skill:

1. Create a directory: `harness/skills/opencode/<skill-name>/`
2. Add `SKILL.md` with the standard OpenCode skill front-matter:

   ```yaml
   name: your-skill-name
   description: One-line description shown in OpenCode skill picker.
   ```

   Followed by the skill instructions.

3. If the skill needs helper scripts, add them alongside `SKILL.md` in the same directory.
4. Run `./setup.sh --dry-run` to confirm the skill would be copied to `.opencode/skills/`.

## Adding an MCP

1. Edit `stack/manifest.json` — add an entry under `"sharedMcp"`:

   ```json
   "my-mcp": {
     "type": "local",
     "command": ["my-mcp-binary"],
     "enabledByDefault": true
   }
   ```

2. If the MCP binary is installed via npm, add a version pin to `versions.json` under `"mcp"`.
3. Add an install step to `harness/scripts/lib/mcp-install.mjs`.
4. Update `harness/mcp/README.md` with a brief note.

## Adding a plugin

Edit `harness/plugins/opencode.plugins.json` and add the plugin name to the `"plugins"` array.

## Coding conventions

- **Node.js core (`harness/scripts/setup.mjs`, `harness/scripts/lib/*.mjs`):** each module should be independently testable — export pure-ish functions, avoid top-level side effects. Test with real inputs against a sandboxed temp directory before committing (see any `lib/*.mjs` file for the pattern); don't rely on syntax-checking alone.
- **Local plugins (`harness/plugins/local/*.mjs`):** add a case to `.github/scripts/test-local-plugins.mjs` for any new block/allow behavior.
- **Launcher scripts (`setup.sh`, `setup.ps1`):** keep these thin — Node-bootstrap logic only. Any new install/config logic belongs in `harness/scripts/lib/`, not the launchers.
- **Shell scripts:** shellcheck-clean. Run `shellcheck setup.sh` locally. Disable rules via `.shellcheckrc`, not inline comments.
- **PowerShell:** PSScriptAnalyzer-clean. No `Error`-severity diagnostics.
- **JSON:** 2-space indent. Validate with `node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" <file>`.
- **Markdown:** trailing whitespace trimmed (except `.md` per `.editorconfig`).

## Testing before a PR

```bash
# 1. Dry-run to see what would happen
./setup.sh --dry-run

# 2. Run the diagnostic
./setup.sh --doctor

# 3. Lint the launcher (requires shellcheck)
shellcheck setup.sh

# 4. Syntax-check + smoke-test the local plugins
node --check harness/plugins/local/*.mjs
node .github/scripts/test-local-plugins.mjs

# 5. Validate all JSON
find . -name '*.json' -not -path './.git/*' | xargs -I{} node -e "JSON.parse(require('fs').readFileSync('{}','utf8'))"
```

CI runs all of the above automatically on push and pull request.

## Commit style

This repo uses [Conventional Commits](https://www.conventionalcommits.org/):

- `chore:` — housekeeping, renames, deletions
- `feat:` — new capability
- `fix:` — bug fix
- `docs:` — documentation only
- `ci:` — CI workflow changes

Keep subject lines under 72 characters. Add a body for non-obvious changes.
