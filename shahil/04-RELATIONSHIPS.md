# 04 — Relationships (the file-to-file graph)

> `A → B` reads *"A references / depends on / is wired to B"*. This is the wiring map: follow any edge to see
> how a change propagates.

---

## The central hub

```
settings.json
   ├─→ hooks/*                     (8 wired scripts, by absolute path)
   ├─→ enabledPlugins              (context-mode, figma, watch, obsidian, gopls-lsp)
   ├─→ mcpServers: cavemem
   ├─→ extraKnownMarketplaces      (5 GitHub sources for L2 installs)
   ├─→ statusLine                  (inline python; shells to `git symbolic-ref`)
   └─→ permissions.allow           (ctx_* tools, gh, docker, osascript, npx…)

.mcp.json ─→ codebase-memory-mcp ←─ .claude/.claude/settings.local.json (enabledMcpjsonServers)
                     ↑
        cbm-code-discovery-gate, cbm-session-reminder  (hooks assume this server exists)
```

---

## Pattern 1 — the dispatcher split (skill-budget rule in action)

This is the most repeated relationship in the harness. Each command is thin; its depth lives in `agent_docs/`.

```
commands/<name>.md  ──reads──▶  agent_docs/<name>-reference.md
```

| Command | → Reference doc |
|---|---|
| `architect.md` | `agent_docs/architect-reference.md` |
| `product-owner.md` | `agent_docs/product-owner-reference.md` |
| `milestone.md` | `agent_docs/milestone-reference.md` |
| `metrics.md` | `agent_docs/metrics-reference.md` |
| `launch.md` | `agent_docs/launch-reference.md` |
| `brand.md` | `agent_docs/brand-reference.md` |
| `deploy.md` | `agent_docs/deploy/rules.md` |
| `brand-quality` (skill) | `agent_docs/brand-quality/runbooks.md` |

Governed by: `rules/skill-budget.md` (dispatcher ≤15 KB → reference doc any size).

---

## Pattern 2 — commands share the project brain

```
commands/*  ──read──▶  .claude/state/triage.md         (lean index, everyone reads)
commands/X  ──write─▶  .claude/state/X.md               (single-writer; only X writes its file)
commands/*  ──emit──▶  .claude/data/{plans,sprints,milestones,evidence,launches}/
```

Governed by: `commands/README.md` (the contract) + the per-command "Boundaries" section.

---

## Pattern 3 — skill chaining (who invokes / aggregates whom)

```
/onboard            ─→ chains /brief + /heartbeat (+ recommends next)
/status             ─→ READS all state/*.md, presents 3 options   (never executes — boundary rule)
/director           ─→ decomposes a goal into per-skill tasks
/milestone --run    ─→ Skill-invokes /quality-gate, /security-review, /doc-rules, /deploy, /brand, /metrics
/engineering-plan --plan ─→ loads agent_docs/lenses/{architect,legal,security,compliance}.md (review gate)
/workflow           ─→ sequences skills + scripts/jira.sh
```

The 4-lens review gate edges:
```
engineering-plan.md ─→ lenses/architect.md  ─→ AC-ARCH-*
                    ─→ lenses/legal.md       ─→ AC-LEGAL-*
                    ─→ lenses/security.md    ─→ AC-SEC-*
                    ─→ lenses/compliance.md  ─→ AC-COMP-*
```

---

## Pattern 4 — the enforcement edges (hook → what it references)

```
check-generated-files.sh   ─→ rules/learned-rules.md (project, rule: no @generated edits)
check-destructive-ops.sh   ─→ rules/learned-rules.md (#1,#2,#5,#6,#7) + commands/deploy(-vps).md + scripts/deploy.sh (project)
strip-jwt-permissions.sh   ─→ settings.local.json deny patterns (covers the resolution gap) + token-audit rules
check-secrets.sh           ─→ settings.json allow list (documented override path)
cbm-code-discovery-gate    ─→ codebase-memory-mcp tools (search_graph/trace_path/get_code_snippet)
cbm-session-reminder       ─→ codebase-memory-mcp protocol (printed at session start)
context-mode-cache-heal.mjs─→ plugins/installed_plugins.json + plugins/cache/ (re-symlinks latest)
learned-reindex.sh         ─→ learned-projects.json, rules/learned-global.md, commands/*.md (## Learned Rules),
                              writes ─▶ context-mode/learned-stale.txt  ─read by─▶  /learned skill
```

> Note the cross-references point at *project-level* files (`.claude/rules/learned-rules.md`,
> `commands/deploy-vps.md`, `scripts/deploy.sh`) that live in repos, not in `~/.claude`. The home hooks
> assume a project shaped by the scaffold.

---

## Pattern 5 — the learned-rules loop

```
learned-projects.json ──┐
rules/learned-global.md ─┼─▶ learned-reindex.sh ─▶ context-mode/learned-stale.txt ─▶ /learned ─▶ ctx_index (FTS5)
commands/*.md (## Learned Rules) ─┘                                                          │
                                                                                            ▼
                                          on-demand recall via ctx_search ◀── per-project .claude/learned/learned-rules.md
```

Governed by: `rules/memory-hygiene.md` (FTS5-backed retrieval section) + `rules/learned-global.md`.

---

## Pattern 6 — the distribution loop (how it spreads to a team)

```
scaffold/CLAUDE.md (template) ──┐
~/.claude/commands, agent_docs, ─┼─▶ scripts/scaffold.sh ──▶ reads registry.txt ──▶ each workspace's .claude/
   rules, agents, hooks (source) ┘        │
                                          ├─ --init       stamp structure into a new repo
                                          ├─ --update     sync from global → local
                                          ├─ --distribute push to ALL registered workspaces
                                          ├─ --fork       copy a global command for local override (.overrides)
                                          └─ --diff       show global↔local drift
```

Override model v2: global `~/.claude/commands/` is auto-discovered; a project's `.claude/commands/` holds
*only* project-only commands + intentional overrides listed in `.overrides`. Everything else inherits.

---

## Pattern 7 — the design-system pipeline

```
rules/ui-design-system.md ─▶ ui-ux-pro-max/scripts/search.py --design-system
                          ─▶ agent_docs/ui-ux-pro-max-reference.md (interpretation)
                          ─▶ project brand source-of-truth (.claude/agent_docs/<project>-design-overrides.md) [overrides win]
                          ─▶ design-taste skill family / brand-quality / figma plugin
```

---

## Pattern 8 — file-memory

```
the memory directive + rules/memory-hygiene.md
   ─▶ projects/<slug>/memory/MEMORY.md         (always-loaded index, ≤80 lines)
   ─▶ projects/<slug>/memory/MEMORY.archive.md (never auto-loaded)
   ─▶ feedback_*.md / project_*.md / reference_*.md   (read on demand; linked via [[name]])
```

---

## Reading the graph as an engineer

- To **change behaviour globally** → edit a MASTER node (`settings.json`, a `rule`, a `hook`).
- To **change one capability** → edit its `commands/<name>.md` + `agent_docs/<name>-reference.md` pair.
- To **roll a change out to the team** → edit the source in `~/.claude`, then `scaffold.sh --distribute`.
- To **trace why something is blocked** → it's almost always a Tier-1 hook; check `hooks/` first.

→ Continue to [`05-ADOPT.md`](05-ADOPT.md) to stand this up on a fresh machine.
