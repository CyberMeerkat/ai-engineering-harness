#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTEXT_MODE_VERSION="$(python3 - <<'PY' "$ROOT_DIR/versions.json"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['mcp']['context-mode'])
PY
)"
CONTEXT7_MCP_VERSION="$(python3 - <<'PY' "$ROOT_DIR/versions.json"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['mcp']['context7-mcp'])
PY
)"

install_pkg() {
  local bin_name="$1"
  local npm_package="$2"

  if command -v "$bin_name" >/dev/null 2>&1; then
    printf '%s already installed\n' "$bin_name"
    return
  fi

  if command -v npm >/dev/null 2>&1; then
    npm install -g "$npm_package"
    return
  fi

  printf 'Missing %s and npm is unavailable; install %s manually.\n' "$bin_name" "$npm_package" >&2
}

install_pkg context-mode "context-mode@${CONTEXT_MODE_VERSION}"
install_pkg context7-mcp "@upstash/context7-mcp@${CONTEXT7_MCP_VERSION}"
