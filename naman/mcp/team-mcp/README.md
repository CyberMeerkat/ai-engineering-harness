# Team MCP Scaffold

This is the starter location for the in-house team MCP server.

## Intended contents

- server implementation
- MCP tool definitions
- local development instructions
- deployment notes

## Included scaffold

- `package.json`
- `src/server.js`
- `.env.example`

## Local run

```bash
cd naman/mcp/team-mcp
cp .env.example .env
npm start
```

The scaffold exposes:

- `/health`
- `/mcp` placeholder

## Integration target

When this server is ready, update:

- `../manifest.json`
- `../../templates/opencode.template.jsonc`
- `../../templates/.env.team.example`

so local installs can point to the real team MCP endpoint or local dev process.
