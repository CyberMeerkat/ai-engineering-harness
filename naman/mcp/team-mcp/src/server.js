import http from 'node:http';

const port = Number(process.env.TEAM_MCP_PORT || 8787);

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ ok: true, service: 'team-mcp' }));
    return;
  }

  if (req.url === '/mcp') {
    res.writeHead(501, { 'content-type': 'application/json' });
    res.end(JSON.stringify({
      error: 'Not implemented',
      message: 'Add MCP tool handlers in naman/mcp/team-mcp/src/server.js'
    }));
    return;
  }

  res.writeHead(404, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(port, '127.0.0.1', () => {
  console.log(`team-mcp listening on http://127.0.0.1:${port}`);
  console.log(`health: http://127.0.0.1:${port}/health`);
  console.log(`mcp: http://127.0.0.1:${port}/mcp`);
});
