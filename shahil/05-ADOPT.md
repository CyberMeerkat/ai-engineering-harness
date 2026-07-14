# 05 — Adoption Guide (stand it up on a fresh machine)

> For an engineer who has never seen this setup. Goal: from a clean Claude Code install to a working harness
> in a project. The sanitised, copy-ready files are in [`portable/`](portable/).

> Preferred path in this repo: run the unified installer at the repo root. It generates `~/.claude/` from
> `shahil/portable/` and builds the OpenCode setup from `naman/`.

```bash
cd <repo-root>
./setup.sh
```

---

## What's portable vs machine-specific vs never-share

| Bucket | Items | Action |
|---|---|---|
| **Portable (copy)** | `hooks/`, `rules/`, `commands/`, `agents/`, `agent_docs/`, `scaffold/`, `scripts/scaffold.sh` | Copy from `portable/`. |
| **Re-create (don't copy verbatim)** | `settings.json` (absolute paths), `.mcp.json` (binary path), `learned-projects.json` (your projects), `registry.txt` (your repos), `permissions.allow` project entries | Use `portable/settings.template.json`, fill placeholders. |
| **Install from source** | `skills/` (L2), plugins, MCP server binaries | Re-install — never copy caches. |
| **Never share** | `projects/`, `*/memory/`, `context-mode/*.db`, `.credentials*`, all L4 | Excluded from the kit. |

---

## Prerequisites

| Dep | Why | Install |
|---|---|---|
| **Claude Code CLI** | The host (L1) | Anthropic install instructions |
| **Node.js (via nvm)** | cavemem + `.mjs` hook + JS tooling | `nvm install --lts` |
| **python3** | hooks parse tool JSON; statusline renders | system python3 |
| **codebase-memory-mcp** | the code knowledge-graph MCP | install its binary to `~/.local/bin/` (see its project) |
| **cavemem** | conversational-memory MCP | `npm i -g cavemem` |

> If you don't want cavemem or codebase-memory-mcp, that's fine — just **omit their hooks + MCP entries**
> (steps 3–5) so you don't get reminders pointing at tools that aren't there.

---

## Install order

### 1. Plugins & marketplaces (L2)
Add the marketplaces, then enable the plugins (matches `extraKnownMarketplaces` / `enabledPlugins`):
```
/plugin marketplace add mksglu/context-mode
/plugin marketplace add anthropics/claude-plugins-official
/plugin marketplace add bradautomates/claude-video
/plugin marketplace add kepano/obsidian-skills
/plugin install context-mode figma watch obsidian gopls-lsp
```

### 2. MCP server binaries
- `codebase-memory-mcp` → install to `~/.local/bin/codebase-memory-mcp`
- `cavemem` → `npm i -g cavemem` (note the resulting global path for settings)

### 3. Copy the harness files
From the kit into `~/.claude/`:
```bash
cp -R portable/hooks portable/rules portable/commands portable/agents \
      portable/agent_docs portable/scaffold ~/.claude/
mkdir -p ~/.claude/scripts && cp portable/scripts/scaffold.sh ~/.claude/scripts/
chmod +x ~/.claude/hooks/*            # hooks must be executable
```

### 4. Configure `settings.json`
Start from `portable/settings.template.json`, replace every `{{PLACEHOLDER}}`:

| Placeholder | Replace with |
|---|---|
| `{{HOME}}` | your home dir (e.g. `/Users/you`) |
| `{{CAVEMEM_PATH}}` | output of `npm root -g`/cavemem `dist/index.js` (or delete cavemem blocks) |
| `{{PROD_IP}}`, `{{PROD_HOST}}`, `{{PROD_PATH}}` | your prod target — **or delete those hook rules entirely** |

Then create the MCP wiring:
```bash
# ~/.claude/.mcp.json
{ "mcpServers": { "codebase-memory-mcp": { "command": "{{HOME}}/.local/bin/codebase-memory-mcp" } } }

# ~/.claude/.claude/settings.local.json
{ "enabledMcpjsonServers": ["codebase-memory-mcp"] }
```

### 5. Sanity-check the hooks
```bash
echo '{"tool_input":{"command":"echo hi"}}' | ~/.claude/hooks/check-destructive-ops.sh   # → exit 0
echo '{"tool_name":"Write","tool_input":{"file_path":"x.ts","content":"const k=\"AKIA0000000000000000\""}}' \
     | ~/.claude/hooks/check-secrets.sh                                                     # → BLOCKED
```

### 6. Bootstrap a project
The harness stores *programs* globally and *data* per-repo. In any project:
```bash
cd ~/code/my-project
~/.claude/scripts/scaffold.sh --init        # creates .claude/{state,data,…} + CLAUDE.md
~/.claude/scripts/scaffold.sh --register     # add this repo to registry.txt
```

---

## First session walkthrough

```
/onboard                      # orientation: context brief + health pulse + options
/status                       # empty-state dashboard → bootstrap recommendations
/product-owner --plan-sprint 1   # or /grill-me for greenfield
/architect --status           # inventory components, detect drift
# …then the delivery loop:
/grill-me "<feature>" --for-plan
/engineering-plan --plan      # auto-runs the 4-lens review gate
/test --tdd
/quality-gate --verify
/deploy --execute             # pauses for your confirmation
```

After bootstrap, the daily rhythm is: `/status` → pick an option → work → `/verify --full` → commit.

---

## Keeping a team in sync

Once several repos are registered:
```bash
~/.claude/scripts/scaffold.sh --list         # see all registered workspaces
~/.claude/scripts/scaffold.sh --distribute    # push harness updates to every repo
~/.claude/scripts/scaffold.sh --diff <path>   # check drift before distributing
```
Edit the canonical source in `~/.claude/` → `--distribute` → every teammate's project picks it up.

---

## Gotchas (learned the hard way)

- **Hooks reference project-level files** (`.claude/rules/learned-rules.md`, `scripts/deploy.sh`) that only
  exist after `--init`. Run the bootstrap before expecting the destructive-ops rules to resolve cleanly.
- **The destructive-ops hook hard-codes a prod IP/host.** Replace or delete those rules — they'll silently
  *not* protect your infra and *will* leak the original target if copied verbatim.
- **codebase-memory-mcp / cavemem are external.** Without them, the `cbm-*` and cavemem hooks/MCP entries are
  noise — remove what you don't install.
- **node version matters.** cavemem's path embeds a specific nvm version; if you upgrade node, re-point
  `{{CAVEMEM_PATH}}` (or reinstall the global).

→ The copy-ready files live in [`portable/`](portable/). See its `README.md` for the manifest.
