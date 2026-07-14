#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NODE_MAJOR_REQUIRED="$(python3 - <<'PY' "$ROOT_DIR/versions.json"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['node']['major'])
PY
)"
BREW_FORMULA="$(python3 - <<'PY' "$ROOT_DIR/versions.json"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['node']['brewFormula'])
PY
)"

node_major() {
  node -p 'process.versions.node.split(".")[0]'
}

if command -v node >/dev/null 2>&1; then
  CURRENT_MAJOR="$(node_major)"
  if [ "$CURRENT_MAJOR" -ge "$NODE_MAJOR_REQUIRED" ]; then
    printf 'node version ok (%s)\n' "$(node -p 'process.versions.node')"
    exit 0
  fi
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
  printf '[dry-run] node %s+ not satisfied; would install via brew/nvm\n' "$NODE_MAJOR_REQUIRED"
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  brew install "$BREW_FORMULA"
  BREW_PREFIX="$(brew --prefix "$BREW_FORMULA")"
  export PATH="$BREW_PREFIX/bin:$PATH"
  if command -v node >/dev/null 2>&1; then
    CURRENT_MAJOR="$(node_major)"
    if [ "$CURRENT_MAJOR" -ge "$NODE_MAJOR_REQUIRED" ]; then
      printf 'node installed (%s)\n' "$(node -p 'process.versions.node')"
      exit 0
    fi
  fi
fi

if [ -s "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.nvm/nvm.sh"
  nvm install "$NODE_MAJOR_REQUIRED"
  nvm use "$NODE_MAJOR_REQUIRED"
  if command -v node >/dev/null 2>&1; then
    CURRENT_MAJOR="$(node_major)"
    if [ "$CURRENT_MAJOR" -ge "$NODE_MAJOR_REQUIRED" ]; then
      printf 'node installed via nvm (%s)\n' "$(node -p 'process.versions.node')"
      exit 0
    fi
  fi
fi

printf 'Node.js %s+ is required. Install it (for example via Homebrew or nvm) and re-run setup.\n' "$NODE_MAJOR_REQUIRED" >&2
exit 1
