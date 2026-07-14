#!/usr/bin/env bash
# learned-reindex.sh — SessionStart hook
# Detects which learned source .md files have changed since last reindex.
# Writes a stale-sources list. The /learned skill reads this and prompts the
# agent to call the MCP tool `ctx_index` (which only the agent can do).
# This script never tries to call ctx_index itself.

set -eu

REGISTRY="$HOME/.claude/learned-projects.json"
STATE_DIR="$HOME/.claude/context-mode"
STATE_FILE="$STATE_DIR/learned-index.state"
STALE_FILE="$STATE_DIR/learned-stale.txt"
GLOBAL_FILE="$HOME/.claude/rules/learned-global.md"
SKILLS_DIR="$HOME/.claude/commands"

mkdir -p "$STATE_DIR"
touch "$STATE_FILE"
: > "$STALE_FILE"

mtime_of() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

last_indexed() {
  grep -E "^${1} " "$STATE_FILE" 2>/dev/null | awk '{print $2}' | tail -n1
}

mark_stale() {
  local source="$1"
  local path="$2"
  [ -f "$path" ] || return 0
  local mtime last
  mtime=$(mtime_of "$path")
  last=$(last_indexed "$source")
  if [ -z "$last" ] || [ "$mtime" -gt "$last" ]; then
    echo "${source}|${path}|${mtime}" >> "$STALE_FILE"
  fi
}

# Global rules
mark_stale "learned-global" "$GLOBAL_FILE"

# Project rules from registry (multiline JSON-safe parse)
if [ -f "$REGISTRY" ]; then
  flattened=$(tr -d '\n' < "$REGISTRY" | sed -E 's/[[:space:]]+/ /g')
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    key=$(printf '%s\n' "$entry" | sed -E 's/.*"key"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    path=$(printf '%s\n' "$entry" | sed -E 's/.*"path"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    [ -z "$key" ] || [ -z "$path" ] && continue
    mark_stale "learned-project:$key" "$path/.claude/learned/learned-rules.md"
  done < <(printf '%s\n' "$flattened" | grep -oE '\{[^}]+\}')
fi

# Skill-owned rules
if [ -d "$SKILLS_DIR" ]; then
  for skill_file in "$SKILLS_DIR"/*.md; do
    [ -f "$skill_file" ] || continue
    grep -q "^## Learned Rules" "$skill_file" 2>/dev/null || continue
    skill_name=$(basename "$skill_file" .md)
    mark_stale "learned-skill:$skill_name" "$skill_file"
  done
fi

exit 0
