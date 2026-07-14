#!/usr/bin/env bash
# setup.sh — thin launcher.
#
# This script's ONLY job is to make sure a working Node.js is present, then
# hand off to the real installer (harness/scripts/setup.mjs). Every other
# concern (OpenCode install, MCP install, project config, skills, plugins,
# backup/retention, validate, uninstall, doctor) lives in exactly one place
# — the Node.js core — instead of being duplicated here and in setup.ps1.
#
# This file can't be empty: bootstrapping a working Node.js is inherently
# the one thing that has to happen *before* a Node.js script can run at all.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$ROOT_DIR/harness"
VERSIONS_PATH="$ROOT_DIR/versions.json"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  # setup.mjs prints the real usage text; -h/--help is also valid before
  # Node is confirmed present, so just hand off directly (--help never
  # touches the filesystem, no need to bootstrap Node version checking
  # first if Node is already available; if it's not, fall through to the
  # normal bootstrap below, which will surface a clear error instead).
  :
fi

node_major() {
  node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0
}

# Minimal, dependency-free JSON field extraction — deliberately not using
# python3/jq/node here, since ensuring one of those exists is the very
# thing this bootstrap step is responsible for. Single-pass grep (no -A
# context matching) so it doesn't depend on exact line offsets.
read_required_major() {
  grep -m1 -oE '"major"[[:space:]]*:[[:space:]]*[0-9]+' "$VERSIONS_PATH" | grep -oE '[0-9]+'
}

read_brew_formula() {
  grep -m1 -oE '"brewFormula"[[:space:]]*:[[:space:]]*"[^"]+"' "$VERSIONS_PATH" | sed -E 's/.*"([^"]+)"$/\1/'
}

REQUIRED_MAJOR="$(read_required_major)"
if [ -z "$REQUIRED_MAJOR" ]; then
  printf 'Could not read required Node.js version from %s\n' "$VERSIONS_PATH" >&2
  exit 1
fi

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    local current
    current="$(node_major)"
    if [ "$current" -ge "$REQUIRED_MAJOR" ]; then
      return 0
    fi
  fi

  if command -v brew >/dev/null 2>&1; then
    local formula
    formula="$(read_brew_formula)"
    brew install "$formula"
    local brew_prefix
    brew_prefix="$(brew --prefix "$formula" 2>/dev/null || true)"
    if [ -n "$brew_prefix" ]; then
      export PATH="$brew_prefix/bin:$PATH"
    fi
  elif [ -s "$HOME/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.nvm/nvm.sh"
    nvm install "$REQUIRED_MAJOR"
    nvm use "$REQUIRED_MAJOR"
  else
    printf 'Node.js %s+ is required. Install it (for example via Homebrew or nvm) and re-run setup.\n' "$REQUIRED_MAJOR" >&2
    exit 1
  fi

  if ! command -v node >/dev/null 2>&1; then
    printf 'Node.js install completed, but node is still unavailable. Restart your shell and re-run setup.\n' >&2
    exit 1
  fi

  local current
  current="$(node_major)"
  if [ "$current" -lt "$REQUIRED_MAJOR" ]; then
    printf 'Node.js %s+ is required. Current version: %s\n' "$REQUIRED_MAJOR" "$(node -p 'process.versions.node')" >&2
    exit 1
  fi
}

ensure_node

exec node "$HARNESS_DIR/scripts/setup.mjs" "$@"
