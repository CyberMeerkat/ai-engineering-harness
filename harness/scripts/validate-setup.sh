#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_ROOT="$ROOT_DIR"

check_file() {
  local path="$1"
  if [ ! -e "$path" ]; then
    printf 'Missing required path: %s\n' "$path" >&2
    exit 1
  fi
}

check_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$cmd" >&2
    exit 1
  fi
}

check_command_runs() {
  local cmd="$1"
  if ! "$cmd" --help >/dev/null 2>&1; then
    if ! "$cmd" --version >/dev/null 2>&1; then
      printf 'Installed command failed to run: %s\n' "$cmd" >&2
      exit 1
    fi
  fi
}

if ! command -v opencode >/dev/null 2>&1; then
  printf 'opencode is not installed\n' >&2
  exit 1
fi

check_command context-mode
check_command context7-mcp
check_command_runs opencode
check_command_runs context-mode
check_command_runs context7-mcp

check_file "$PROJECT_ROOT/opencode.jsonc"
check_file "$PROJECT_ROOT/.opencode/skills/frontend-design/SKILL.md"
check_file "$HOME/.config/opencode/opencode.json"
check_file "$HOME/.config/opencode/skills/understand/SKILL.md"

python3 - <<'PY' "$PROJECT_ROOT/opencode.jsonc"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    json.load(f)
PY

python3 - <<'PY' "$HOME/.config/opencode/opencode.json"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    config = json.load(f)

assert 'mcp' in config
assert 'plugin' in config
PY

printf 'opencode installed\n'
printf 'context-mode installed\n'
printf 'context7-mcp installed\n'
printf 'required commands execute\n'
printf 'project config present\n'
printf 'core repo-managed OpenCode skills present\n'
printf 'global app bundle present\n'
