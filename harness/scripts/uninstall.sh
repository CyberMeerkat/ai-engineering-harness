#!/usr/bin/env bash
# uninstall.sh — restore the newest backup created by setup.
# Restores ~/.config/opencode, ~/.local/share/opencode, ~/.cache/opencode.
# Supports --dry-run: prints actions without executing them.
set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

BACKUP_ROOT="${HOME}/.config/opencode-harness-backups"

# ── helper ─────────────────────────────────────────────────────────────────────
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# ── locate newest backup ───────────────────────────────────────────────────────
if [ ! -d "$BACKUP_ROOT" ]; then
  printf 'no backups found; nothing to uninstall\n' >&2
  exit 1
fi

# newest timestamp dir is lexicographically last (yyyyMMdd-HHmmss)
NEWEST=""
for dir in "$BACKUP_ROOT"/*/; do
  [ -d "$dir" ] || continue
  NEWEST="$dir"
done

if [ -z "$NEWEST" ]; then
  printf 'no backups found; nothing to uninstall\n' >&2
  exit 1
fi

NEWEST="${NEWEST%/}"
printf 'restoring from backup: %s\n' "$NEWEST"

# ── restore map ────────────────────────────────────────────────────────────────
declare -A RESTORE_MAP
RESTORE_MAP[config]="${HOME}/.config/opencode"
RESTORE_MAP[data]="${HOME}/.local/share/opencode"
RESTORE_MAP[cache]="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"

for backup_name in config data cache; do
  src="$NEWEST/$backup_name"
  dest="${RESTORE_MAP[$backup_name]}"
  if [ -d "$src" ]; then
    if [ "$DRY_RUN" = "0" ] && [ -d "$dest" ]; then
      run rm -rf "$dest"
    elif [ "$DRY_RUN" = "1" ] && [ -d "$dest" ]; then
      run rm -rf "$dest"
    fi
    run cp -R "$src" "$dest"
    printf 'restored %s\n' "$dest"
  else
    printf 'skip %s (not in backup)\n' "$backup_name"
  fi
done

printf 'uninstall complete\n'
