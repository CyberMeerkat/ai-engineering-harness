---
description: "Scaffold, sync, and distribute .claude/ directory structures across workspaces"
---

# /scaffold — Project Intelligence Scaffolding

You are the scaffold skill. You manage the `.claude/` directory structure — creating it for new projects, syncing skill templates from the global source, and distributing changes across all registered workspaces.

## Override Model (v2)

**Principle:** Global commands live globally. Projects only store deltas.

Claude Code auto-discovers commands from `~/.claude/commands/` (global). Project `.claude/commands/` holds ONLY:
1. **Project-only commands** — no global counterpart (e.g., `accountant.md`)
2. **Intentional overrides** — forked from global, listed in `.claude/commands/.overrides`

### `.overrides` manifest

Plain-text file at `.claude/commands/.overrides` declaring intentional forks:

```
# Intentional overrides of global commands. One per line: filename # reason
engineering-plan.md  # Intelligence-bridge sync step (EP-008)
milestone.md         # Financial gates added
```

Classification logic used by `--diff` and `--migrate`:
- In `.overrides` + differs from global → **OVERRIDE** (intentional, kept)
- NOT in `.overrides` + differs from global → **STALE** (removed on migrate/update)
- NOT in `.overrides` + identical to global → **DUPLICATE** (removed on migrate/update)
- No global counterpart → **LOCAL** (project-only, always kept)

## Canonical Source

`~/.claude/` is the single source of truth.
- `~/.claude/commands/` → skill definitions (auto-discovered by Claude Code globally)
- `~/.claude/skills/` → audit skill templates (distributed to projects)
- `~/.claude/scaffold/` → templates (CLAUDE.md, .gitignore)
- `~/.claude/scripts/scaffold.sh` → the engine
- `~/.claude/registry.txt` → tracked workspaces

**What gets synced (global → local):**
- `skills/` — audit templates
- `.gitignore` — from template

**What does NOT get synced (v2):**
- `commands/*.md` — NO LONGER copied. Inherited from global automatically. Use `--fork` to customize.

**What stays local (never overwritten):**
- `state/` — project-specific mutable state
- `data/` — project-specific work artifacts
- `compact/` — session snapshots
- `archive/` — project history
- `settings.json` — project permissions
- `settings.local.json` — local permissions
- `CLAUDE.md` — once created, the entrypoint is project-owned
- `commands/.overrides` — project-specific override manifest

## Flags

The user passes a flag to tell you what to do. Parse the flag and run the corresponding command.

| Flag | What to run | Description |
|------|-------------|-------------|
| `--init` | `~/.claude/scripts/scaffold.sh --init` | Create `.claude/` structure. Commands inherited from global. |
| `--update` | `~/.claude/scripts/scaffold.sh --update` | Sync skills, clean duplicate/stale commands |
| `--distribute` | `~/.claude/scripts/scaffold.sh --distribute` | Push updates to ALL registered workspaces |
| `--fork <name>` | `~/.claude/scripts/scaffold.sh --fork <name>` | Copy global command to project + register override |
| `--migrate` | `~/.claude/scripts/scaffold.sh --migrate` | One-time: remove stale copies, respect .overrides |
| `--diff` | `~/.claude/scripts/scaffold.sh --diff` | Show command status (OVERRIDE/LOCAL/STALE/DUPLICATE) |
| `--list` | `~/.claude/scripts/scaffold.sh --list` | Show all registered workspaces |
| `--register` | `~/.claude/scripts/scaffold.sh --register` | Add current workspace to registry |
| `--unregister` | `~/.claude/scripts/scaffold.sh --unregister` | Remove current workspace from registry |
| (no args) | `~/.claude/scripts/scaffold.sh --diff` | Default: show command status |

## Execution

1. Run the appropriate shell command using Bash
2. Display the output to the user
3. If `--init` was run, remind the user to customize their `CLAUDE.md` entrypoint
4. If `--fork` was run, remind the user to edit the forked command and document the reason in `.overrides`
5. If `--distribute` was run, show the summary of which workspaces were updated

## Safety

- NEVER overwrite `state/triage.md` on `--update` — that's project-specific state
- NEVER overwrite `CLAUDE.md` on `--update` — once created, the project owns it
- NEVER overwrite `settings.json` or `settings.local.json` — project-specific config
- NEVER overwrite `.overrides` — that's the project's override manifest
- `--migrate` removes stale/duplicate copies but preserves overrides and local commands
- `--distribute` syncs skills and cleans commands, never touches state

## Learned Rules

1. **Hatchet `database.yaml` is seed-only.** The config file initializes the admin user on first boot. To change the Hatchet admin password after init, use the Hatchet dashboard UI — editing the YAML has no effect. *(From: project_learned_hatchet_seed_only_config)*
2. **MCP tool/resource count is documented in 8+ files across 4 directories.** After adding or removing MCP tools or resources, grep all `.md` files for the old count and update every reference. Files span `intelligence/`, `.claude/`, `docs/`, and root `CLAUDE.md`. *(From: feedback_learned_mcp_tool_count_docs_spread)*
3. **Batch sed must target both quote styles.** When replacing import paths across a codebase, always target both single-quoted (`'old/path'`) and double-quoted (`"old/path"`) imports. Missing one style leaves broken references. *(From: feedback_learned_sed_both_quote_styles)*
4. **Create generic skill first, then fork for project overrides.** When a rule applies broadly, create a parameterized global version in `~/.claude/commands/`. Only fork to a project override if the project needs different behavior — never start with a project-specific version. *(From: feedback_learned_generic_skill_first)*
5. **`create-next-app` silently overwrites `.gitignore`.** After running `create-next-app` or any scaffold that initializes a new project, always check and rewrite `.gitignore` — the tool replaces custom entries with its defaults. *(From: feedback_learned_create_next_app_gitignore)*

5. **Skill dispatchers must stay under 100 lines.** Claude follows ~150-200 instructions; skills over 100 lines exceed the budget and tail sections get skimmed. Detailed procedures go in `~/.claude/agent_docs/{name}-reference.md`. The dispatcher keeps: frontmatter, role identity, arguments table, reference pointer, boundaries. *(From: feedback_learned_lean_dispatcher_pattern.md)*

7. **Keep CLAUDE.md under 200 lines / 8 KB.** CLAUDE.md loads on every message. Anthropic warns bloated CLAUDE.md causes instruction-ignoring. Move service URL tables, Docker commands, intelligence docs, and reference tables to on-demand docs (e.g., `docs/claude-code-reference.md`). After adding content, check: `wc -l CLAUDE.md` — if >200 lines, extract least-needed sections. *(From: feedback_learned_claudemd_size_limit.md)*

6. **"Never do X" rules go in hooks, not advisory context.** Advisory (CLAUDE.md, rules/, skills) gets ~80% compliance. Hooks get 100% — they run as code. When adding an absolute rule, create a script in `~/.claude/hooks/` and wire it in `~/.claude/settings.json` under PreToolUse or PostToolUse. *(From: feedback_learned_hooks_over_advisory.md)*

8. **When `npm install -g` fails with EACCES, clone the repo and copy files manually.** Don't retry with sudo (often unavailable in sandboxed shells). Use: `git clone <repo> /tmp/<name> && cp -R /tmp/<name>/src/<skill>/* <target-dir>/`. Error signature: `EACCES: permission denied, mkdir '/Volumes/BuildCache'`. *(From: feedback_learned_npm_eacces_clone_workaround.md)*

9. **`ui-ux-pro-max` SKILL.md lives in `.claude/skills/<name>/` not the repo root.** Runtime files (scripts, data, templates) are in `src/<name>/`. When installing from GitHub, copy both locations: `src/<skill>/*` for runtime + `.claude/skills/<skill>/SKILL.md` for the skill definition. *(From: feedback_learned_uiux_skill_file_locations.md)*

10. **`next@14.2.35` has a swc version-mismatch crash — pin `next` to whatever version matches its `@next/swc-*` optionalDependencies.** `next@14.2.35`'s optionalDependencies pin `@next/swc-*@14.2.33`. At runtime `patchIncorrectLockfile()` sees the version mismatch and crashes with `TypeError: Cannot read properties of undefined (reading 'os')` during `next build`. Always run `npm view next@<version> optionalDependencies` before pinning — if versions differ, pin `next` down to the swc version. pnpm won't realign optional deps on its own. *(From: feedback_learned_next_14_2_35_swc_mismatch.md)*

11. **Next.js `output: 'standalone'` places `server.js` at `.next/standalone/` root — NOT under the monorepo app path.** After enabling standalone output, `docker build --target builder` and inspect `.next/standalone/` before writing runner COPY destinations. Default layout has `server.js`, `package.json`, `node_modules/`, and a minimal `.next/` at the root. In the runner: copy standalone tree to `./` (places `server.js` at `/app/server.js`), copy `public/` to `./public` (not `./apps/<name>/public`), copy `.next/static/` to `./.next/static`. CMD must be `["node", "server.js"]`, not `["node", "apps/<name>/server.js"]`. Setting `outputFileTracingRoot` changes this; default does not preserve monorepo subdirectories. *(From: feedback_learned_next_standalone_server_js_location.md)*

12. **`pnpm/action-setup@v4` refuses double-pin between workflow `version:` and `packageManager:`.** Error: `ERR_PNPM_BAD_PM_VERSION: Multiple versions of pnpm specified`. Use ONE source of truth — prefer `"packageManager": "pnpm@X.Y.Z"` in root `package.json` and omit the action's `version:` input. Grep `-rn "version:" .github/workflows/` after seeing this error to find every workflow that pins. *(From: feedback_learned_pnpm_action_setup_double_pin.md)*

13. **`dorny/paths-filter@v3` needs explicit `permissions: pull-requests: read`.** The default `GITHUB_TOKEN` on `pull_request` triggers is restrictive enough to fail silently with `##[error]Resource not accessible by integration` when the action calls `listFiles(pull_number: NN)`. Add a top-level `permissions: { contents: read, pull-requests: read }` block. The error is hidden from `gh run view --log-failed` — use `gh run view --job <id> --log | grep -i 'not accessible'` to surface it. *(From: feedback_learned_dorny_paths_filter_permissions.md)*

14. **`pip install --target` skips platform postinstall scripts — add `sitecustomize.py` for packages that need it (e.g. pywin32).** `pip install pywin32 --target dir` succeeds but `import pywintypes` raises `ModuleNotFoundError` because the postinstall that runs `AddDllDirectory` on `pywin32_system32` was skipped. Fix: emit a `sitecustomize.py` into the target dir that calls `os.add_dll_directory()` + extends `sys.path` with pywin32 sub-dirs at interpreter startup. Python auto-imports sitecustomize.py when found on PYTHONPATH. *(From: feedback_learned_pip_target_postinstall.md)*

15. **Windows Git Bash CI: wrap all paths passed to Windows-native executables with `cygpath -w` — MSYS paths (`/d/a/...`) cause FileNotFoundError.** When build scripts run on Windows with Git Bash, `$(pwd)` returns MSYS paths. Windows-native `python3` (from `/c/hostedtoolcache/...`) cannot read them. Add a `to_native()` helper: `if command -v cygpath >/dev/null; then cygpath -w "$1"; else printf '%s' "$1"; fi`. Apply to every path in argv and PYTHONPATH entries (also swap `:` → `;` as PSEP on Windows). *(From: feedback_learned_windows_msys_cygpath.md)*
