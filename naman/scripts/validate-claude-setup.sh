#!/usr/bin/env bash
set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME_DIR:-$HOME/.claude}"

check_file() {
  local path="$1"
  if [ ! -e "$path" ]; then
    printf 'Missing required Claude path: %s\n' "$path" >&2
    exit 1
  fi
}

check_file "$CLAUDE_HOME/settings.json"
check_file "$CLAUDE_HOME/hooks/check-generated-files.sh"
check_file "$CLAUDE_HOME/commands/status.md"
check_file "$CLAUDE_HOME/rules/search-first.md"
check_file "$CLAUDE_HOME/scripts/scaffold.sh"

python3 - <<'PY' "$CLAUDE_HOME/settings.json"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    json.load(f)
PY

printf 'claude settings present\n'
printf 'claude hooks present\n'
printf 'claude commands present\n'
printf 'claude rules present\n'
printf 'claude settings valid json\n'
