#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMAN_DIR="$ROOT_DIR/naman"
VERSIONS_PATH="$ROOT_DIR/versions.json"
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  printf 'Usage: ./setup.sh\n' >&2
  exit 1
fi

install_opencode_desktop() {
  [ "$(uname -s)" = "Darwin" ] || return 0

  if [ -d "/Applications/OpenCode.app" ] || [ -d "$HOME/Applications/OpenCode.app" ]; then
    printf 'OpenCode desktop already installed\n'
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    printf 'Skipping OpenCode desktop install: python3 is required to read versions.json\n' >&2
    return 0
  fi

  local arch asset version base_url tmp_dir dmg_path mount_point app_target_dir
  arch="$(uname -m)"
  if [ "$arch" = "arm64" ]; then
    arch="arm64"
  else
    arch="x64"
  fi

  asset="$(python3 - <<'PY' "$VERSIONS_PATH" "$arch"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    versions = json.load(f)

print(versions['opencode']['desktop']['macos'][sys.argv[2]])
PY
)"
  version="$(python3 - <<'PY' "$VERSIONS_PATH"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    versions = json.load(f)

print(versions['opencode']['desktop']['version'])
PY
)"

  base_url="https://github.com/anomalyco/opencode/releases/download/v${version}"
  tmp_dir="$(mktemp -d)"
  dmg_path="$tmp_dir/$asset"
  mount_point="$tmp_dir/mount"
  app_target_dir="/Applications"
  if [ ! -w "$app_target_dir" ]; then
    app_target_dir="$HOME/Applications"
    mkdir -p "$app_target_dir"
  fi

  printf 'Installing OpenCode desktop (%s)\n' "$asset"
  curl -fsSL "$base_url/$asset" -o "$dmg_path"
  mkdir -p "$mount_point"
  hdiutil attach "$dmg_path" -mountpoint "$mount_point" -nobrowse >/dev/null
  cp -R "$mount_point/OpenCode.app" "$app_target_dir/OpenCode.app"
  hdiutil detach "$mount_point" >/dev/null
  rm -rf "$tmp_dir"
  printf 'Installed OpenCode desktop to %s/OpenCode.app\n' "$app_target_dir"
}

printf '==> Install OpenCode CLI\n'
bash "$NAMAN_DIR/scripts/install-opencode.sh"
printf '==> Install OpenCode desktop (if needed)\n'
install_opencode_desktop
if ! command -v claude >/dev/null 2>&1; then
  printf 'claude not found; installing Claude Code with official installer\n'
  curl -fsSL https://claude.ai/install.sh | bash
  if ! command -v claude >/dev/null 2>&1; then
    printf 'Claude Code install completed, but the claude command is still unavailable. Restart your shell and re-run setup.\n' >&2
    exit 1
  fi
fi
printf '==> Ensure Node version\n'
bash "$NAMAN_DIR/scripts/install-node.sh"
printf '==> Install MCP dependencies\n'
bash "$NAMAN_DIR/scripts/install-mcp-deps.sh"
printf '==> Build OpenCode configs and skills\n'
bash "$NAMAN_DIR/scripts/build-project-opencode.sh"
printf '==> Validate OpenCode setup\n'
bash "$NAMAN_DIR/scripts/validate-setup.sh"
printf '==> Generate Claude home\n'
bash "$NAMAN_DIR/scripts/generate-claude-home.sh"
printf '==> Validate Claude setup\n'
bash "$NAMAN_DIR/scripts/validate-claude-setup.sh"

printf '\nSetup complete.\n'
printf 'Next: review %s/.env.team, then run opencode from this repo root or Claude Code with ~/.claude.\n' "$NAMAN_DIR"
