# MCP Integrations

This folder is for shared MCP definitions, adapters, and server code the team wants to manage in-repo.

## Current inventory from local setups

### OpenCode MCPs currently used

- `context-mode` via local command `context-mode`
- `context7` via local command `context7-mcp`
- `jira` via Atlassian remote MCP
- `figma` via local SSE endpoint `http://127.0.0.1:3845/sse`

### No shared team MCP yet

- the repo currently bundles existing MCP integrations only
- `team-mcp/` is a scaffold for future work, not part of the default generated config

## Recommended pattern

Keep shared MCP wiring here as templates or deployable server code.
Do not commit live tokens, personal OAuth state, or machine-local endpoint assumptions.

## Repo-managed files

- `manifest.json` records the current MCP inventory bundled by default.
- future shared MCP server code can live under subdirectories here.
