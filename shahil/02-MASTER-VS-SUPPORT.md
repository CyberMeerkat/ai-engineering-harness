# 02 — Master vs Support

> Ownership (L1–L4) answers *"who made it"*. This doc answers *"what role does it play"*: which files
> **drive** behaviour (master), which **back** the masters (support), which are the **capability catalogue**
> (library), and which are **disposable** (ephemeral). The test for "master": *if it changes or disappears,
> behaviour across the whole harness changes.*

---

## The four roles

| Role | Definition | Members |
|---|---|---|
| **MASTER** | Drives behaviour; referenced by many; load-bearing | `settings.json`, `.mcp.json` (+ nested `settings.local.json`), `rules/*.md`, the 8 wired `hooks/`, `commands/README.md`, `scaffold/CLAUDE.md`, `scripts/scaffold.sh` |
| **SUPPORT** | Backs a master; leaf reference/data | `agent_docs/*`, `agents/*`, `learned-projects.json`, `registry.txt`, `scripts/jira.sh` |
| **LIBRARY** | The invokable capability catalogue | `commands/` (43), `skills/` (23) |
| **EPHEMERAL** | Machine-generated; no behavioural role | everything in L4 |

---

## MASTER files — in priority order

### 1. `settings.json` — the spine
Everything hangs off this. It declares:
- **hooks** → the entire enforcement + session-bootstrap layer
- **enabledPlugins** → context-mode, figma, watch, obsidian, gopls-lsp
- **mcpServers** → cavemem
- **statusLine** → the python status renderer
- **permissions.allow** → the auto-approved Bash/MCP allowlist
- **extraKnownMarketplaces** → where L2 skills/plugins come from

If you change one file to understand or port the harness, it's this one. *Master of masters.*

### 2. MCP wiring — `.mcp.json` + `.claude/.claude/settings.local.json`
`.mcp.json` registers `codebase-memory-mcp`; the nested `settings.local.json` pre-approves it
(`enabledMcpjsonServers`). Together they stand up the code knowledge-graph that the `cbm-*` hooks assume.

### 3. `rules/*.md` — always-loaded behavioural spine
Ten files injected into every session before any task. They are *master* because they silently shape 100%
of output (tone, git flow, testing, node pinning, memory hygiene, UI routing, search-first). Changing one
changes every future reply. See [`01-INVENTORY.md`](01-INVENTORY.md#rules--always-loaded-behavioural-spine-10).

### 4. The 8 wired `hooks/`
Deterministic gates on tool calls + session start. Master because they *override the model* — they fire
regardless of what the model "decides". The destructive-ops and secrets hooks are the harness's safety
floor. See [`03-SUBSYSTEMS.md` §C](03-SUBSYSTEMS.md).

### 5. `commands/README.md` — the system's own map
Not executable, but master-grade documentation: it defines the autonomous delivery flow, the shared-state
contract, and the role of every command. Any agent dropped into a project reads this to understand the org.

### 6. `scaffold/CLAUDE.md` — the architecture spec + project template
Declares the 5-layer productivity stack and the canonical project-level `.claude/` structure. It is the
*template* stamped into every repo by the scaffold system, so it defines the runtime shape of every project.

### 7. `scripts/scaffold.sh` — the distribution engine
Turns "my harness" into "our harness". `--init` stamps the structure into a repo; `--distribute` pushes
updates to every path in `registry.txt`; `--fork`/`--diff`/`--update` manage drift. Master because it is the
mechanism by which the whole system propagates and stays in sync.

---

## SUPPORT files

| File(s) | Supports | Relationship |
|---|---|---|
| `agent_docs/*-reference.md` | the matching command | Command is a lean dispatcher → reads its reference doc on demand (skill-budget split). |
| `agent_docs/lenses/*.md` | `/engineering-plan --plan` | Loaded at the Step-2b stakeholder review gate; each emits 0–3 acceptance criteria. |
| `agent_docs/deploy/rules.md` | `/deploy` | Learned deployment rules, loaded only when deploying. |
| `agents/*.md` | orchestrator commands | Personas the Skill/Agent layer can delegate to (auditor/state-reader/implementer). |
| `learned-projects.json` | `learned-reindex.sh` + `/learned` | Project key→path registry for cross-project recall. |
| `registry.txt` | `scaffold.sh` | List of workspaces that receive `--distribute`. |
| `scripts/jira.sh` | `/workflow`, finance/PM commands | Jira issue/sprint/transition helper. |

Support files are *leaf*: they're read by a master, but nothing reads them transitively to change global
behaviour. You can delete a single reference doc and only its one command degrades.

---

## LIBRARY — the capability catalogue

`commands/` (43) and `skills/` (23) are the menu of things you can invoke. They're not "master" because
behaviour only changes when you *call* them — they're dormant otherwise. But they are the bulk of the value
and the bulk of the authored work (for `commands/`).

- **`commands/`** = your authored org-as-skills. Each is L3 + library.
- **`skills/`** = mostly installed (L2) + library. Re-install from source when sharing.

---

## Impact analysis ("what breaks if…")

| Remove / change… | Impact |
|---|---|
| `settings.json` | Harness collapses to vanilla Claude Code — no hooks, no plugins, no statusline, no allowlist. |
| any `rules/*.md` | That standing constraint silently stops applying to every session. |
| a wired hook | Its guarantee becomes ~80%-reliable model behaviour instead of 100% deterministic. |
| `.mcp.json` / nested local | `codebase-memory-mcp` disappears; `cbm-*` hooks nag toward a tool that isn't there. |
| `scripts/scaffold.sh` + `registry.txt` | Can't propagate or sync the harness; each repo drifts independently. |
| `commands/X.md` | Only `/X` is lost; the rest of the org is unaffected (loose coupling via shared state). |
| an `agent_docs/*` ref | Only that command's deep procedures are lost; the dispatcher still runs, shallowly. |
| anything in L4 | Nothing — it regenerates. |

---

## Ownership × Role matrix (quick reference)

| | MASTER | SUPPORT | LIBRARY | EPHEMERAL |
|---|---|---|---|---|
| **L3 (yours)** | settings.json, .mcp.json, rules/, hooks/(×8), commands/README, scaffold/CLAUDE, scaffold.sh | agent_docs/, agents/, learned-projects.json, registry.txt, jira.sh | commands/ (43) | — |
| **L2 (installed)** | — | — | skills/ (23) | context-mode/, plugins/cache |
| **L1 (vanilla)** | (settings schema) | — | built-ins | projects/, file-history/, ide/ |
| **L4** | — | — | — | sessions/, compact/, tasks/, caches… |

→ Continue to [`03-SUBSYSTEMS.md`](03-SUBSYSTEMS.md) for how the moving parts actually work.
