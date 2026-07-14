# 01 — Full Inventory (100% file/folder map)

> Every top-level entry in `~/.claude` is listed here with a classification (L1/L2/L3/L4) and a one-line
> purpose. Authored content (L3) and installed content (L2) are exhaustive; ephemeral content (L4) is
> captured by **naming convention + format**, not by reading contents — per the "deep on the harness, light
> on the disposable" principle.
>
> Legend: **L1** vanilla · **L2** installed third-party · **L3** personal harness (your IP) · **L4** ephemeral.

---

## Top-level files

| Entry | Layer | Purpose |
|---|---|---|
| `settings.json` | **L3** | The spine. Hooks, permissions, statusline, enabled plugins, marketplaces, cavemem MCP. |
| `.mcp.json` | **L3** | Registers the `codebase-memory-mcp` server. |
| `learned-projects.json` | **L3** | Registry of projects (key→path) for cross-project learned-rule recall. |
| `registry.txt` | **L3** | Scaffold's list of workspaces that receive `/scaffold --distribute`. |
| `settings.json.bak`, `settings.json.orig` | L4 | Auto/manual backups of settings. Exclude. |
| `history.jsonl` | L4 | Global command history. Exclude. |
| `stats-cache.json` | L4 | Usage/rate-limit stats cache. Exclude. |
| `mcp-needs-auth-cache.json` | L4 | MCP auth-state cache. Exclude. |
| `.caveman-active` | L4 | Flag file for the caveman plugin. Exclude. |
| `.last-cleanup` | L4 | Timestamp of last housekeeping run. Exclude. |
| `.DS_Store` | L4 | macOS Finder metadata. Exclude. |
| `.credentials*` *(if present)* | L4 | **Secrets — never read, never share.** |

---

## Top-level directories — the personal harness (L3)

These are the files to understand, document, and share.

### `commands/` — the org-as-skills engine (43 commands + README)

Lean dispatchers (YAML frontmatter + ~50–80 lines) that route to deep reference docs. Grouped by role:

| Group | Commands |
|---|---|
| **Entry / orchestration** | `onboard`, `status`, `brief`, `director`, `milestone`, `workflow`, `agent-coordination` |
| **Planning** | `grill-me`, `engineering-plan`, `product-owner`, `engineering-rules` |
| **Execution / delivery** | `dev-manager`, `deploy`, `changelog`, `scaffold` |
| **Quality / verify** | `test`, `review`, `quality-gate`, `audit`, `audit-all`, `verify`, `sonar-fix`, `ux-audit`, `domain-audit` |
| **Security / compliance** | `security-review`, `devsecops`, `compliance`, `legal`, `doc-rules` |
| **Finance** | `cfo`, `accountant`, `finance-analyst`, `metrics` |
| **Brand / GTM** | `brand`, `comms`, `launch`, `marketing` |
| **Meta / learning** | `learned`, `heartbeat`, `compact`, `token-audit`, `architect`, `go-tooling` |
| **Index** | `README.md` (the system's own map of the delivery flow) |

> Note: `scaffold/CLAUDE.md` cites "~36 dispatchers"; the live count is **43** — the doc is slightly behind
> the directory. The inventory count is authoritative.

### `rules/` — always-loaded behavioural spine (10)

Loaded into *every* session (the "CLAUDE.md layer"). Each is a standing constraint:

| Rule | Enforces |
|---|---|
| `tone-budget.md` | Terse chat output (~25–40% token cut). |
| `skill-budget.md` | Skill dispatchers ≤15 KB; heavy reference content lives in `agent_docs/`. |
| `git-workflow.md` | Branch strategy (`feature/sN/…`), protected branches, PR format. |
| `testing-standards.md` | AAA tests, behaviour-named, 80% coverage target. |
| `node-version-strategy.md` | Mandatory `.nvmrc` + `engines.node`; latest-LTS default. |
| `memory-hygiene.md` | `MEMORY.md` ≤80 lines; active vs archive split. |
| `ui-design-system.md` | Routes all UI work through `ui-ux-pro-max` + brand tokens. |
| `search-first.md` | Research the codebase before proposing solutions. |
| `coding-standards.md` | Immutability, small files/functions, error handling, naming. |
| `learned-global.md` | Cross-project learned rules (≤80 lines, always loaded). |

### `hooks/` — deterministic enforcement (11 scripts; 8 wired, 3 dormant)

| Hook | Wired? | Trigger | Action |
|---|---|---|---|
| `check-generated-files.sh` | ✅ | PreToolUse:Edit | Block edits to `@generated`/"DO NOT EDIT" files. |
| `check-destructive-ops.sh` | ✅ | PreToolUse:Bash | Block dangerous VPS/docker/prisma ops. **Hard-codes prod IP + hostname.** |
| `strip-jwt-permissions.sh` | ✅ | PreToolUse:Bash | Block Bash commands containing JWTs (stops permission-list bloat). |
| `check-secrets.sh` | ✅ | PreToolUse:Write,Edit | Block writes with 14 classes of hardcoded secrets. |
| `cbm-code-discovery-gate` | ✅ | PreToolUse:Grep\|Glob\|Read\|Search | Block the *first* code-search per session → nudge to codebase-memory-mcp. |
| `cbm-session-reminder` | ✅ | SessionStart | Print the "Code Discovery Protocol" reminder. |
| `context-mode-cache-heal.mjs` | ✅ | SessionStart | Repair context-mode's plugin symlink after auto-update. |
| `learned-reindex.sh` | ✅ | SessionStart | Detect stale learned `.md` files; queue them for `/learned` reindex. |
| `compact-check.sh` | ⚪ dormant | — | Pre-compact validation (not referenced in settings). |
| `route-deploy-intent.sh` | ⚪ dormant | — | Deploy-intent routing (not referenced). |
| `settings-hygiene-check.sh` | ⚪ dormant | — | settings.json validation (not referenced). |

### `agents/` — subagent personas (3)

| Agent | Role |
|---|---|
| `auditor.md` | Read-only compliance/security auditor — never edits. |
| `state-reader.md` | Non-interactive state reader/summariser. |
| `implementer.md` | Full-tool code delivery agent — executes approved plans, never touches `.claude/state/`. |

### `agent_docs/` — reference backing store (13)

The "deep content" half of the skill-budget split. Each backs a command (or a review gate):

| File | Backs |
|---|---|
| `architect-reference.md` | `/architect` |
| `product-owner-reference.md` | `/product-owner` |
| `milestone-reference.md` | `/milestone` (file format, autonomous-loop protocol) |
| `metrics-reference.md` | `/metrics` |
| `launch-reference.md` | `/launch` |
| `brand-reference.md` | `/brand` |
| `ui-ux-pro-max-reference.md` | the `ui-ux-pro-max` skill + `ui-design-system` rule |
| `deploy/rules.md` | `/deploy` (learned deployment rules) |
| `brand-quality/runbooks.md` | the `brand-quality` skill |
| `lenses/architect.md`, `lenses/legal.md`, `lenses/security.md`, `lenses/compliance.md` | the 4-lens stakeholder review gate run by `/engineering-plan --plan` |

### `scripts/` — utilities (2)

| Script | Purpose |
|---|---|
| `scaffold.sh` | Create/update/distribute the project-level `.claude/` structure across registered repos. **This is the distribution engine.** |
| `jira.sh` | Jira integration (issue/sprint/transition helpers). |

### `scaffold/` — project template (2)

| File | Purpose |
|---|---|
| `CLAUDE.md` | The canonical project-level `.claude/` entrypoint template (the "5-layer stack" doc). |
| `.gitignore` | Ignores ephemeral project state (`state/`, `data/`, `compact/`). |

### `.claude/` (nested) — local MCP approval (L3)

Contains `settings.local.json` → `{"enabledMcpjsonServers": ["codebase-memory-mcp"]}`. This is how the
`.mcp.json` server gets approved without an interactive prompt.

---

## Top-level directories — installed third-party (L2)

| Dir | What | Notes |
|---|---|---|
| `skills/` (23) | Marketplace + Anthropic skills | Mostly L2: design-taste family (`design-taste-frontend`, `emil-design-eng`, `gpt-taste`, `high-end-visual-design`, `industrial-brutalist-ui`, `minimalist-ui`, `redesign-existing-projects`), SDD family (`build`, `check`, `spec`, `backprop`), `skill-creator`, `find-skills`, `cua-driver`, transcription (`audio-transcribe`, `transcribe`), `playwright-cli`, `playwright-validation`, `full-output-enforcement`, `codebase-memory`, `brand-quality`, `sync`. **`ui-ux-pro-max` is the heavyweight design engine** the global rule depends on. |
| `plugins/` | Plugin install root | `installed_plugins.json`, `known_marketplaces.json`, `cache/`, `marketplaces/`. Enabled: context-mode, figma, watch, obsidian, gopls-lsp. |
| `context-mode/` | context-mode plugin state | FTS5 `.db` files, `sessions/stats-pid-*.json`, `learned-stale.txt`/`learned-index.state` (the latter written by *your* `learned-reindex.sh`). |

> Skills are a **mix** — a few may be self-authored. The reliable signal: anything with a marketplace entry
> in `settings.json`→`extraKnownMarketplaces` is installed (L2). When sharing, **re-install from source**
> rather than copying skill folders.

---

## Top-level directories — vanilla runtime (L1)

| Dir | Purpose |
|---|---|
| `projects/` | Per-project session transcripts (`-Library-Sites-X/…jsonl`) + the file-memory dirs live under here. |
| `file-history/` | UUID-keyed edit history for the Edit/Write tools. |
| `ide/` | IDE integration state (empty here). |

---

## Top-level directories — ephemeral / local (L4) — exclude from sharing

Captured by convention, not content:

| Dir | Format / naming convention |
|---|---|
| `plans/` | Plan-mode artifacts: `<slug>.md` (+ `<slug>-agent-*.md` for agent outputs). |
| `sessions/` | `{pid}.json` session metadata. |
| `session-env/` | UUID dirs — per-session environment snapshots. |
| `shell-snapshots/` | Dated shell state captures. |
| `paste-cache/` | Clipboard history. |
| `compact/` | `YYYYMMDD-HHMMSS.md` context-continuation snapshots. |
| `tasks/` | UUID dirs — TaskCreate/TaskUpdate state. |
| `cache/` | `changelog.md` + assorted JSON caches. |
| `downloads/` | Downloaded plugin/marketplace archives. |
| `debug/` | Debug logs. |
| `backups/` | Timestamped `.claude.json` config backups. |
| `sync-backups/` | Snapshots from the `sync` skill (FIFO, ~1 GB cap). |

---

## The 100% check

The complete top-level set is: **12 files** + **26 directories** = 38 entries. Every one appears above.
To re-verify after any change:

```bash
ls -1Ap ~/.claude          # compare against this doc; every entry must be classified
```

→ Continue to [`02-MASTER-VS-SUPPORT.md`](02-MASTER-VS-SUPPORT.md).
