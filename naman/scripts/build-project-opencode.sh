#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_ROOT="$ROOT_DIR"
OPENCODE_DIR="$PROJECT_ROOT/.opencode"
ENV_FILE="$ROOT_DIR/naman/.env.team"
STACK_MANIFEST="$ROOT_DIR/stack/manifest.json"
GLOBAL_OPENCODE_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
GLOBAL_OPENCODE_DATA_DIR="${OPENCODE_DATA_DIR:-$HOME/.local/share/opencode}"
GLOBAL_OPENCODE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"
GLOBAL_BACKUP_ROOT="${HOME}/.config/opencode-delta-ai-harness-backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OPENCODE_DIR/skills"

if [ ! -f "$ENV_FILE" ]; then
  cp "$ROOT_DIR/naman/templates/.env.team.example" "$ENV_FILE"
fi

set -a
. "$ENV_FILE"
set +a

render_template() {
  local template_file="$1"
  local output_file="$2"
  local mode="$3"
  python3 - <<'PY' "$template_file" "$STACK_MANIFEST" "$output_file" "$mode"
import json
import sys

template_path, manifest_path, output_path, mode = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(template_path, 'r', encoding='utf-8') as f:
    template = json.load(f)

if mode == 'global':
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    mcp = {}
    for name, value in manifest.get('sharedMcp', {}).items():
        config = {'type': value['type']}
        if 'command' in value:
            config['command'] = value['command']
        if 'url' in value:
            config['url'] = value['url']
        if 'enabledByDefault' in value:
            config['enabled'] = bool(value['enabledByDefault'])
        if value.get('oauth'):
            config['oauth'] = {}
        mcp[name] = config

    template['mcp'] = mcp
    template['plugin'] = manifest.get('opencode', {}).get('plugins', [])

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(template, f, indent=2)
    f.write('\n')
PY
}

render_template "$ROOT_DIR/naman/templates/opencode.template.jsonc" "$PROJECT_ROOT/opencode.jsonc" project

backup_dir_if_exists() {
  local source_dir="$1"
  local backup_name="$2"
  if [ -d "$source_dir" ]; then
    mkdir -p "$GLOBAL_BACKUP_ROOT/$TIMESTAMP"
    cp -R "$source_dir" "$GLOBAL_BACKUP_ROOT/$TIMESTAMP/$backup_name"
  fi
}

backup_dir_if_exists "$GLOBAL_OPENCODE_DIR" config
backup_dir_if_exists "$GLOBAL_OPENCODE_DATA_DIR" data
backup_dir_if_exists "$GLOBAL_OPENCODE_CACHE_DIR" cache

rm -rf "$GLOBAL_OPENCODE_DIR" "$GLOBAL_OPENCODE_DATA_DIR" "$GLOBAL_OPENCODE_CACHE_DIR"
mkdir -p "$GLOBAL_OPENCODE_DIR"
render_template "$ROOT_DIR/naman/templates/opencode.template.jsonc" "$GLOBAL_OPENCODE_DIR/opencode.json" global

rm -rf "$OPENCODE_DIR/skills" "$GLOBAL_OPENCODE_DIR/skills"
mkdir -p "$OPENCODE_DIR/skills" "$GLOBAL_OPENCODE_DIR/skills"

copy_skills_flat() {
  local source_root="$1"
  local target_root="$2"
  for skill_dir in "$source_root"/*; do
    [ -d "$skill_dir" ] || continue
    cp -R "$skill_dir" "$target_root/$(basename "$skill_dir")"
  done
}

while IFS= read -r source_root; do
  [ -n "$source_root" ] || continue
  copy_skills_flat "$ROOT_DIR/$source_root" "$OPENCODE_DIR/skills"
done < <(python3 - <<'PY' "$STACK_MANIFEST"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    manifest = json.load(f)

for item in manifest.get('opencode', {}).get('projectSkillsSources', manifest.get('opencode', {}).get('skillsSources', [])):
    print(item)
PY
)

while IFS= read -r source_root; do
  [ -n "$source_root" ] || continue
  copy_skills_flat "$ROOT_DIR/$source_root" "$GLOBAL_OPENCODE_DIR/skills"
done < <(python3 - <<'PY' "$STACK_MANIFEST"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    manifest = json.load(f)

for item in manifest.get('opencode', {}).get('globalSkillsSources', manifest.get('opencode', {}).get('projectSkillsSources', manifest.get('opencode', {}).get('skillsSources', []))):
    print(item)
PY
)

printf 'built %s\n' "$PROJECT_ROOT/opencode.jsonc"
printf 'built %s\n' "$OPENCODE_DIR"
printf 'built %s\n' "$GLOBAL_OPENCODE_DIR/opencode.json"
printf 'built %s\n' "$GLOBAL_OPENCODE_DIR/skills"
if [ -d "$GLOBAL_BACKUP_ROOT/$TIMESTAMP" ]; then
  printf 'backed up prior global OpenCode state to %s\n' "$GLOBAL_BACKUP_ROOT/$TIMESTAMP"
fi
