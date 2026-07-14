#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_ROOT="$ROOT_DIR"
OPENCODE_DIR="$PROJECT_ROOT/.opencode"
ENV_FILE="$ROOT_DIR/harness/.env.team"
STACK_MANIFEST="$ROOT_DIR/stack/manifest.json"
GLOBAL_OPENCODE_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
GLOBAL_OPENCODE_DATA_DIR="${OPENCODE_DATA_DIR:-$HOME/.local/share/opencode}"
GLOBAL_OPENCODE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"
GLOBAL_BACKUP_ROOT="${HOME}/.config/opencode-harness-backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# inherit from parent (setup.sh exports these)
DRY_RUN="${DRY_RUN:-0}"
MODE="${MODE:-incremental}"

# ── dry-run wrapper ────────────────────────────────────────────────────────────
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# ── backup retention ───────────────────────────────────────────────────────────
prune_old_backups() {
  local backup_root="$1"
  local keep="${HARNESS_BACKUP_RETENTION:-5}"
  [ -d "$backup_root" ] || return 0
  local count
  count="$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d | wc -l)"
  if [ "$count" -gt "$keep" ]; then
    # sort ascending (oldest first) and remove all but the newest $keep
    find "$backup_root" -mindepth 1 -maxdepth 1 -type d | sort | head -n "$(( count - keep ))" | while IFS= read -r old_dir; do
      printf 'backup retention: removing old backup %s\n' "$old_dir" >&2
      run rm -rf "$old_dir"
    done
  fi
}

run mkdir -p "$OPENCODE_DIR/skills"

if [ ! -f "$ENV_FILE" ]; then
  run cp "$ROOT_DIR/harness/templates/.env.team.example" "$ENV_FILE"
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

render_template() {
  local template_file="$1"
  local output_file="$2"
  local mode="$3"
  # NOTE: Python heredoc reads files only (not a destructive op — not wrapped in run())
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

if mode != 'global' or True:
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(template, f, indent=2)
        f.write('\n')
PY
}

if [ "$DRY_RUN" = "0" ]; then
  render_template "$ROOT_DIR/harness/templates/opencode.template.jsonc" "$PROJECT_ROOT/opencode.jsonc" project
else
  printf '[dry-run] render_template -> %s/opencode.jsonc\n' "$PROJECT_ROOT"
fi

backup_dir_if_exists() {
  local source_dir="$1"
  local backup_name="$2"
  if [ -d "$source_dir" ]; then
    run mkdir -p "$GLOBAL_BACKUP_ROOT/$TIMESTAMP"
    run cp -R "$source_dir" "$GLOBAL_BACKUP_ROOT/$TIMESTAMP/$backup_name"
  fi
}

backup_dir_if_exists "$GLOBAL_OPENCODE_DIR" config
backup_dir_if_exists "$GLOBAL_OPENCODE_DATA_DIR" data
backup_dir_if_exists "$GLOBAL_OPENCODE_CACHE_DIR" cache

prune_old_backups "$GLOBAL_BACKUP_ROOT"

if [ "$MODE" = "reset" ]; then
  run rm -rf "$GLOBAL_OPENCODE_DIR" "$GLOBAL_OPENCODE_DATA_DIR" "$GLOBAL_OPENCODE_CACHE_DIR"
fi

run mkdir -p "$GLOBAL_OPENCODE_DIR"

if [ "$DRY_RUN" = "0" ]; then
  render_template "$ROOT_DIR/harness/templates/opencode.template.jsonc" "$GLOBAL_OPENCODE_DIR/opencode.json" global
else
  printf '[dry-run] render_template -> %s/opencode.json\n' "$GLOBAL_OPENCODE_DIR"
fi

run rm -rf "$OPENCODE_DIR/skills" "$GLOBAL_OPENCODE_DIR/skills"
run mkdir -p "$OPENCODE_DIR/skills" "$GLOBAL_OPENCODE_DIR/skills"

copy_skills_flat() {
  local source_root="$1"
  local target_root="$2"
  for skill_dir in "$source_root"/*; do
    [ -d "$skill_dir" ] || continue
    run cp -R "$skill_dir" "$target_root/$(basename "$skill_dir")"
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
