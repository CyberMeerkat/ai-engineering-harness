#!/usr/bin/env bash
# doctor.sh — diagnostic report for ai-engineering-harness setup.
# Checks prereqs, installed tools, version pins, PATH, and writable dirs.
# Exits 0 if all green, 1 if any hard failure.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSIONS_PATH="$ROOT_DIR/versions.json"
HARNESS_DIR="$ROOT_DIR/harness"

FAIL=0

# ── helpers ────────────────────────────────────────────────────────────────────
ok()   { printf '[OK]   %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; FAIL=1; }

# ── 1. prereqs via check-prereqs.sh ───────────────────────────────────────────
printf '--- Prerequisites ---\n'
PREREQS_JSON="$(bash "$HARNESS_DIR/scripts/check-prereqs.sh" --json 2>/dev/null || true)"
if printf '%s' "$PREREQS_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for k, v in data.items():
    if k == 'ok': continue
    prefix = '[OK]  ' if v.startswith('ok') else '[FAIL]'
    print(f'{prefix} {k}: {v}')
sys.exit(0 if data.get('ok') else 1)
"
then
  :
else
  FAIL=1
fi

# ── 2. installed tool versions vs versions.json pins ──────────────────────────
printf '\n--- Version pins ---\n'
PINNED_OPENCODE="$(python3 - <<'PY' "$VERSIONS_PATH"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    v = json.load(f)
print(v['opencode']['npm'])
PY
)"
PINNED_CM="$(python3 - <<'PY' "$VERSIONS_PATH"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    v = json.load(f)
print(v['mcp']['context-mode'])
PY
)"
PINNED_C7="$(python3 - <<'PY' "$VERSIONS_PATH"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    v = json.load(f)
print(v['mcp']['context7-mcp'])
PY
)"

check_tool_version() {
  local tool="$1"
  local pinned="$2"
  if ! command -v "$tool" >/dev/null 2>&1; then
    warn "$tool not installed (run setup to install)"
    return
  fi
  local installed
  installed="$("$tool" --version 2>/dev/null | head -1 | tr -d '[:space:]')" || installed="unknown"
  ok "$tool installed (pinned: $pinned, found: $installed)"
}

check_tool_version opencode "$PINNED_OPENCODE"
check_tool_version context-mode "$PINNED_CM"
check_tool_version context7-mcp "$PINNED_C7"

# ── 3. PATH entries containing opencode or node ────────────────────────────────
printf '\n--- PATH health ---\n'
IFS=':' read -ra PATH_ENTRIES <<< "$PATH"
found_opencode=0
found_node=0
for entry in "${PATH_ENTRIES[@]}"; do
  if [ -x "$entry/opencode" ] || [ -x "$entry/opencode.cmd" ]; then
    ok "opencode on PATH: $entry"
    found_opencode=1
  fi
  if [ -x "$entry/node" ]; then
    ok "node on PATH: $entry"
    found_node=1
  fi
done
[ "$found_opencode" -eq 1 ] || warn "opencode not found on PATH (not installed yet?)"
[ "$found_node" -eq 1 ]     || warn "node not found on PATH"

# ── 4. writable dirs ──────────────────────────────────────────────────────────
printf '\n--- Directories ---\n'
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
OPENCODE_DATA="${OPENCODE_DATA_DIR:-$HOME/.local/share/opencode}"
OPENCODE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"
BACKUP_ROOT="${HOME}/.config/opencode-harness-backups"

for dir in "$OPENCODE_CONFIG" "$OPENCODE_DATA" "$OPENCODE_CACHE" "$BACKUP_ROOT"; do
  if [ -d "$dir" ]; then
    if [ -w "$dir" ]; then
      ok "$dir (exists, writable)"
    else
      fail "$dir (exists, NOT writable)"
    fi
  else
    warn "$dir (does not exist yet — created on first setup)"
  fi
done

# ── 5. project config ─────────────────────────────────────────────────────────
printf '\n--- Project config ---\n'
if [ -f "$ROOT_DIR/opencode.jsonc" ]; then
  ok "opencode.jsonc present"
else
  warn "opencode.jsonc missing (run setup to generate)"
fi
if [ -f "$ROOT_DIR/.opencode/skills/frontend-design/SKILL.md" ]; then
  ok ".opencode/skills populated"
else
  warn ".opencode/skills not populated (run setup to build)"
fi

# ── summary ───────────────────────────────────────────────────────────────────
printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf 'All checks passed.\n'
  exit 0
else
  printf 'One or more checks FAILED. See [FAIL] lines above.\n' >&2
  exit 1
fi
