#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OPENCODE_NPM_VERSION="$(python3 - <<'PY' "$ROOT_DIR/versions.json"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['opencode']['npm'])
PY
)"

opencode_works() {
  if ! command -v opencode >/dev/null 2>&1; then
    return 1
  fi
  opencode --help >/dev/null 2>&1 || opencode --version >/dev/null 2>&1
}

if opencode_works; then
  printf 'opencode already installed\n'
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew install anomalyco/tap/opencode
      exit 0
    fi
    ;;
  Linux)
    if command -v brew >/dev/null 2>&1; then
      brew install anomalyco/tap/opencode
      exit 0
    fi
    ;;
esac

if command -v npm >/dev/null 2>&1; then
  npm install -g "opencode-ai@${OPENCODE_NPM_VERSION}"
  exit 0
fi

if command -v bun >/dev/null 2>&1; then
  bun install -g "opencode-ai@${OPENCODE_NPM_VERSION}"
  exit 0
fi

if command -v pnpm >/dev/null 2>&1; then
  pnpm install -g "opencode-ai@${OPENCODE_NPM_VERSION}"
  exit 0
fi

if command -v yarn >/dev/null 2>&1; then
  yarn global add "opencode-ai@${OPENCODE_NPM_VERSION}"
  exit 0
fi

printf 'Unable to install OpenCode automatically. Install Homebrew or a supported Node package manager first.\n' >&2
exit 1
