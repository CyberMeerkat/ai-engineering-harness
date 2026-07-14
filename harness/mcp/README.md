# MCP Integrations

This folder is for shared MCP definitions, adapters, and server code to manage in-repo.

## Current inventory

### OpenCode MCPs currently configured

- `context-mode` via local command `context-mode`
- `context7` via local command `context7-mcp`
- `jira` via Atlassian remote MCP (disabled by default — requires per-user OAuth)
- `figma` via local SSE endpoint `http://127.0.0.1:3845/sse` (disabled by default — requires local bridge)

## Recommended pattern

Keep shared MCP wiring here as templates or deployable server code.
Do not commit live tokens, personal OAuth state, or machine-local endpoint assumptions.

> To add a real MCP, build with `@modelcontextprotocol/sdk` and register it in `stack/manifest.json`.

## Repo-managed files

- `manifest.json` records the current MCP inventory bundled by default.
- Future shared MCP server code can live under subdirectories here.
