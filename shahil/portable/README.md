# Portable Harness Kit

A sanitised, copy-ready snapshot of the personal Claude Code harness (the **L3 personal layer**). Drop these
into a teammate's `~/.claude/` to give them the same engineering harness.

> **Before you share this kit, read [`SANITISATION.md`](SANITISATION.md).** Real infra identifiers are
> already removed; business-name examples are flagged with an opt-in genericiser.

## What's in here

| Path | What | Notes |
|---|---|---|
| `hooks/` | 11 enforcement/session scripts (8 wired) | `chmod +x` after copying; fill `{{PROD_*}}` in `check-destructive-ops.sh` or delete those rules |
| `rules/` | 10 always-loaded behavioural rules | Drop-in |
| `commands/` | 43 slash-commands + `README.md` (the org-as-skills engine) | Drop-in; `README.md` is the system map |
| `agents/` | 3 subagent personas (auditor, state-reader, implementer) | Drop-in |
| `agent_docs/` | 13 reference docs + the 4 review lenses | Drop-in |
| `scaffold/` | Project template (`CLAUDE.md`, `.gitignore`) | Used by `scaffold.sh --init` |
| `scripts/scaffold.sh` | The distribution engine (`--init`, `--update`, `--distribute`) | Drop-in |
| `settings.template.json` | Sanitised settings with `{{HOME}}`/`{{CAVEMEM_PATH}}` placeholders | Fill, then save as `~/.claude/settings.json` |
| `SANITISATION.md` | What was scrubbed + the business-name toggle | Read first |

## NOT included (install/recreate — see [`../05-ADOPT.md`](../05-ADOPT.md))

- `skills/` → re-install from marketplaces (they're third-party).
- MCP server binaries (`codebase-memory-mcp`, `cavemem`) → install separately.
- `.mcp.json` + nested `.claude/settings.local.json` → 2-line files you create (templates in `../05-ADOPT.md`).
- `learned-projects.json`, `registry.txt` → personal to each engineer; generated as they register projects.

## Quick start

Preferred path: use the repo root installer so Claude and OpenCode are composed from one source of truth.

```bash
cd <repo-root>
./setup.sh
```

This generates `~/.claude/` from `shahil/portable/` and the OpenCode project-local setup from `naman/`.

Manual Claude-only path:

```bash
# 1. copy the harness (skills excluded — install those separately)
cp -R hooks rules commands agents agent_docs scaffold ~/.claude/
mkdir -p ~/.claude/scripts && cp scripts/scaffold.sh ~/.claude/scripts/
chmod +x ~/.claude/hooks/*

# 2. settings: fill placeholders, then install
#    edit settings.template.json -> replace {{HOME}}, {{CAVEMEM_PATH}} (or delete cavemem)
cp settings.template.json ~/.claude/settings.json

# 3. bootstrap a project
cd ~/code/my-repo && ~/.claude/scripts/scaffold.sh --init
```

Full step-by-step (prerequisites, plugins, MCP servers, first session) is in
[`../05-ADOPT.md`](../05-ADOPT.md). Conceptual map of the whole system starts at
[`../00-OVERVIEW.md`](../00-OVERVIEW.md).
