#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME_DIR:-$HOME/.claude}"
PORTABLE_DIR="$ROOT_DIR/shahil/portable"
ENV_FILE="$ROOT_DIR/naman/.env.team"
STACK_MANIFEST="$ROOT_DIR/stack/manifest.json"
BACKUP_ROOT="$CLAUDE_HOME/.delta-ai-harness-backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$CLAUDE_HOME"

if [ ! -f "$ENV_FILE" ]; then
  cp "$ROOT_DIR/naman/templates/.env.team.example" "$ENV_FILE"
fi

set -a
. "$ENV_FILE"
set +a

backup_path_if_exists() {
  local path="$1"
  local rel_name="$2"
  if [ -e "$path" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -R "$path" "$BACKUP_DIR/$rel_name"
  fi
}

replace_managed_dir() {
  local name="$1"
  local source="$PORTABLE_DIR/$name"
  local target="$CLAUDE_HOME/$name"
  backup_path_if_exists "$target" "$name"
  rm -rf "$target"
  cp -R "$source" "$target"
}

replace_managed_dir hooks
replace_managed_dir rules
replace_managed_dir commands
replace_managed_dir agents
replace_managed_dir agent_docs
replace_managed_dir scaffold

mkdir -p "$CLAUDE_HOME/scripts"
backup_path_if_exists "$CLAUDE_HOME/scripts/scaffold.sh" "scripts-scaffold.sh"
cp "$PORTABLE_DIR/scripts/scaffold.sh" "$CLAUDE_HOME/scripts/scaffold.sh"
chmod +x "$CLAUDE_HOME/hooks"/* "$CLAUDE_HOME/scripts/scaffold.sh"

CAVEMEM_PATH="${CAVEMEM_PATH:-{{CAVEMEM_PATH}}}" \
HOME_PLACEHOLDER="$HOME" \
python3 - <<'PY' "$PORTABLE_DIR/settings.template.json" "$STACK_MANIFEST" "$CLAUDE_HOME/settings.json"
import json
import os
import sys

src, manifest_path, dest = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('{{HOME}}', os.environ.get('HOME_PLACEHOLDER', ''))
content = content.replace('{{CAVEMEM_PATH}}', os.environ.get('CAVEMEM_PATH', '{{CAVEMEM_PATH}}'))

settings = json.loads(content)

with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest = json.load(f)

settings['enabledPlugins'] = manifest.get('claude', {}).get('enabledPlugins', settings.get('enabledPlugins', {}))

with open(dest, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
PY

printf 'built Claude home at %s\n' "$CLAUDE_HOME"
if [ -d "$BACKUP_DIR" ]; then
  printf 'backed up prior Claude files to %s\n' "$BACKUP_DIR"
fi
