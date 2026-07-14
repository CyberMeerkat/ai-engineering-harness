#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$ROOT_DIR/harness"
VERSIONS_PATH="$ROOT_DIR/versions.json"

DRY_RUN=0
MODE="incremental"
UNINSTALL=0
DOCTOR=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --reset) MODE="reset"; shift ;;
    --incremental) MODE="incremental"; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --doctor) DOCTOR=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: ./setup.sh [options]

Options:
  --dry-run       Print actions without executing them.
  --incremental   Update in place, keep global OpenCode state (default).
  --reset         Wipe global OpenCode config/data/cache before rebuild.
  --uninstall     Restore the newest backup and exit.
  --doctor        Run diagnostics and exit.
  -h, --help      Show this message.
EOF
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

export DRY_RUN MODE

bash "$HARNESS_DIR/scripts/check-prereqs.sh" || exit 1

if [ "$UNINSTALL" = "1" ]; then
  if [ "$DRY_RUN" = "1" ]; then
    bash "$HARNESS_DIR/scripts/uninstall.sh" --dry-run
  else
    bash "$HARNESS_DIR/scripts/uninstall.sh"
  fi
  exit $?
fi
if [ "$DOCTOR" = "1" ]; then
  bash "$HARNESS_DIR/scripts/doctor.sh"
  exit $?
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

  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] OpenCode desktop not installed; would download and install it\n'
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
bash "$HARNESS_DIR/scripts/install-opencode.sh"
printf '==> Install OpenCode desktop (if needed)\n'
install_opencode_desktop
printf '==> Ensure Node version\n'
bash "$HARNESS_DIR/scripts/install-node.sh"
printf '==> Install MCP dependencies\n'
bash "$HARNESS_DIR/scripts/install-mcp-deps.sh"
printf '==> Build OpenCode configs and skills\n'
bash "$HARNESS_DIR/scripts/build-project-opencode.sh"
if [ "$DRY_RUN" = "0" ]; then
  printf '==> Validate OpenCode setup\n'
  bash "$HARNESS_DIR/scripts/validate-setup.sh"
else
  printf '[dry-run] would run validation checks\n'
fi

printf '\nSetup complete.\n'
printf 'Next: review %s/.env.team, then run opencode from this repo root.\n' "$HARNESS_DIR"
