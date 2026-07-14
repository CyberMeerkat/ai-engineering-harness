# `.claude` Harness — Analysis & Shareable Kit

A 100% analysis of a personal Claude Code setup, packaged so any engineer can understand it and adopt it.
Generated 2026-06-05.

## Read in order

| # | Doc | What it gives you |
|---|---|---|
| 00 | [`00-OVERVIEW.md`](00-OVERVIEW.md) | **Start here.** What this is, the 4-layer ownership model, the 5-layer stack, one-screen architecture. |
| 01 | [`01-INVENTORY.md`](01-INVENTORY.md) | The exhaustive file/folder map — every entry classified (custom vs vanilla vs installed vs ephemeral). |
| 02 | [`02-MASTER-VS-SUPPORT.md`](02-MASTER-VS-SUPPORT.md) | Which files drive behaviour (master) vs back them (support) vs are the catalogue (library). |
| 03 | [`03-SUBSYSTEMS.md`](03-SUBSYSTEMS.md) | How the five engines work: delivery system, triple memory stack, enforcement, design pipeline, MCP. |
| 04 | [`04-RELATIONSHIPS.md`](04-RELATIONSHIPS.md) | The file-to-file wiring graph — follow any edge to trace impact. |
| 05 | [`05-ADOPT.md`](05-ADOPT.md) | Stand it up on a fresh machine: prerequisites, install order, first session. |

## The shareable kit

[`portable/`](portable/) — a sanitised, copy-ready snapshot of the personal harness (hooks, rules, commands,
agents, agent_docs, scaffold, scripts, a settings template). Real infra identifiers are removed; see
[`portable/SANITISATION.md`](portable/SANITISATION.md) before sharing.

## One-paragraph answer to "what is this?"

A vanilla Claude Code install configures a single AI assistant. **This** turns it into a coordinated delivery
organisation: 43 custom slash-commands (architect → product-owner → dev-manager → QA → security → deploy,
plus CFO/accountant/brand/launch) that coordinate through a shared per-project state file and can run a
milestone autonomously; a deterministic hook layer that makes safety non-negotiable; ten always-loaded
behavioural rules; three stacked memory engines; and a `scaffold` system that distributes the whole thing
across a team's repos. The personal harness (**L3**) is your IP and the subject of [`portable/`](portable/);
everything else is either vanilla Claude Code (**L1**), installed third-party plugins/skills (**L2**), or
disposable machine state (**L4**).
