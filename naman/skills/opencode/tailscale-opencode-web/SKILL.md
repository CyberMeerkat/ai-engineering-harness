---
name: tailscale-opencode-web
description: Run opencode web with a configured password and expose it on Tailscale when user says run via tailscale or run opencode web.
---

## Purpose
Use this skill when the user asks to run OpenCode Web via Tailscale, including phrases like "run via tailscale" or "run opencode web".

## Defaults
- Password env var: `OPENCODE_SERVER_PASSWORD={{OPENCODE_SERVER_PASSWORD}}`
- Port: `4096`
- Bind address: `127.0.0.1`
- Exposure: Tailscale Serve only (tailnet access), not Funnel

## Required workflow
1. Ensure OpenCode Web is running with the password env var:
   - `nohup env OPENCODE_SERVER_PASSWORD="${OPENCODE_SERVER_PASSWORD}" opencode web --port 4096 --hostname 127.0.0.1 >/tmp/opencode-web-4096.log 2>&1 &`
2. Ensure Tailscale Serve points `/` to the local web server:
   - `tailscale serve --bg --https=443 http://127.0.0.1:4096`
3. Verify and report:
   - `lsof -nP -iTCP:4096 -sTCP:LISTEN`
   - `tailscale serve status`
4. Return the tailnet URL from `tailscale serve status` so the user can open it on their phone.

## Safety rules
- Do not enable Funnel unless the user explicitly asks.
- Keep the app bound to localhost and expose through Tailscale Serve.
- If a conflicting process is already on port 4096, stop it and relaunch with the required password env var.
- If `OPENCODE_SERVER_PASSWORD` is not available, ask the user for the password instead of assuming one.

## Troubleshooting
- If Tailscale URL is not reachable on phone, confirm the phone is logged into the same tailnet.
- If auth prompt is missing, confirm process was started with `OPENCODE_SERVER_PASSWORD` set.
