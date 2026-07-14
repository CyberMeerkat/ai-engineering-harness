#!/usr/bin/env bash
# scaffold.sh — Create, update, and distribute .claude/ directory structures
#
# Usage:
#   scaffold.sh                    # Init: create .claude/ structure in CWD
#   scaffold.sh --init             # Same as above
#   scaffold.sh --update           # Sync skills from global → local, cleanup commands
#   scaffold.sh --distribute       # Push updates to ALL registered workspaces
#   scaffold.sh --list             # List registered workspaces
#   scaffold.sh --register [path]  # Register a workspace (default: CWD)
#   scaffold.sh --unregister [path]# Remove a workspace from registry
#   scaffold.sh --fork <name>      # Copy a global command to project + register override
#   scaffold.sh --migrate [path]   # One-time: clean stale copies, generate .overrides
#   scaffold.sh --diff [path]      # Show command status (OVERRIDE/LOCAL/STALE/DUPLICATE)
#
# Override model (v2):
#   Global commands (~/.claude/commands/) are auto-discovered by Claude Code.
#   Project .claude/commands/ holds ONLY:
#     - Project-only commands (no global counterpart)
#     - Intentional overrides (listed in .claude/commands/.overrides)
#   Everything else inherits from global automatically.
#
# Canonical source: ~/.claude/
#   commands/     → skill definitions (global, auto-discovered)
#   skills/       → skill templates (distributed to projects)
#   scaffold/     → templates (CLAUDE.md, .gitignore)
#   scripts/      → this script
#   registry.txt  → tracked workspaces

set -euo pipefail

GLOBAL_DIR="$HOME/.claude"
REGISTRY="$GLOBAL_DIR/registry.txt"
SCAFFOLD_DIR="$GLOBAL_DIR/scaffold"
COMMANDS_DIR="$GLOBAL_DIR/commands"
SKILLS_DIR="$GLOBAL_DIR/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[scaffold]${NC} $*"; }
warn() { echo -e "${YELLOW}[scaffold]${NC} $*"; }
err()  { echo -e "${RED}[scaffold]${NC} $*" >&2; }
info() { echo -e "${BLUE}[scaffold]${NC} $*"; }

# ─── Registry ────────────────────────────────────────────────────────────────

ensure_registry() {
  [ -f "$REGISTRY" ] || touch "$REGISTRY"
}

is_registered() {
  local path="$1"
  ensure_registry
  grep -qxF "$path" "$REGISTRY" 2>/dev/null
}

register_workspace() {
  local path="${1:-$(pwd)}"
  path="$(cd "$path" && pwd)"  # resolve to absolute
  ensure_registry
  if is_registered "$path"; then
    info "Already registered: $path"
  else
    echo "$path" >> "$REGISTRY"
    log "Registered: $path"
  fi
}

unregister_workspace() {
  local path="${1:-$(pwd)}"
  path="$(cd "$path" && pwd)"
  ensure_registry
  if is_registered "$path"; then
    grep -vxF "$path" "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
    log "Unregistered: $path"
  else
    warn "Not registered: $path"
  fi
}

list_workspaces() {
  ensure_registry
  if [ ! -s "$REGISTRY" ]; then
    info "No workspaces registered."
    return
  fi
  info "Registered workspaces:"
  local i=1
  while IFS= read -r ws; do
    if [ -d "$ws/.claude" ]; then
      echo -e "  ${GREEN}${i}.${NC} $ws"
    else
      echo -e "  ${RED}${i}.${NC} $ws ${RED}(missing .claude/)${NC}"
    fi
    i=$((i + 1))
  done < "$REGISTRY"
}

# ─── Overrides ───────────────────────────────────────────────────────────────

# Check if a filename is listed in .overrides
is_override() {
  local claude_dir="$1"
  local fname="$2"
  local overrides_file="$claude_dir/commands/.overrides"

  [ -f "$overrides_file" ] || return 1
  # Match filename at start of line (before optional comment)
  grep -q "^${fname}" "$overrides_file" 2>/dev/null
}

# Get the reason comment for an override
override_reason() {
  local claude_dir="$1"
  local fname="$2"
  local overrides_file="$claude_dir/commands/.overrides"

  [ -f "$overrides_file" ] || return
  # Extract comment after # on the matching line
  grep "^${fname}" "$overrides_file" 2>/dev/null | sed 's/^[^#]*#\s*//' | head -1
}

# ─── Init ─────────────────────────────────────────────────────────────────────

do_init() {
  local target="${1:-$(pwd)}"
  local claude_dir="$target/.claude"

  if [ -d "$claude_dir" ] && [ -f "$claude_dir/CLAUDE.md" ]; then
    warn ".claude/ already exists at $target — use --update to sync."
    return 1
  fi

  log "Initializing .claude/ at $target"

  # Create directory structure
  mkdir -p \
    "$claude_dir/commands" \
    "$claude_dir/skills" \
    "$claude_dir/state" \
    "$claude_dir/data/plans" \
    "$claude_dir/data/plans/archive" \
    "$claude_dir/data/sprints" \
    "$claude_dir/data/milestones" \
    "$claude_dir/data/evidence" \
    "$claude_dir/data/launches" \
    "$claude_dir/agent_docs/lenses" \
    "$claude_dir/agents" \
    "$claude_dir/compact" \
    "$claude_dir/archive"

  log "Created directory structure"

  # Copy templates
  if [ -f "$SCAFFOLD_DIR/CLAUDE.md" ]; then
    cp "$SCAFFOLD_DIR/CLAUDE.md" "$claude_dir/CLAUDE.md"
    log "Copied CLAUDE.md template"
  else
    warn "No CLAUDE.md template found at $SCAFFOLD_DIR/CLAUDE.md — skipped"
  fi

  if [ -f "$SCAFFOLD_DIR/.gitignore" ]; then
    cp "$SCAFFOLD_DIR/.gitignore" "$claude_dir/.gitignore"
    log "Copied .gitignore template"
  else
    warn "No .gitignore template found — skipped"
  fi

  # Seed settings.json if missing
  if [ ! -f "$claude_dir/settings.json" ]; then
    cat > "$claude_dir/settings.json" <<'SETTINGS'
{
  "permissions": {
    "allow": []
  }
}
SETTINGS
    log "Created default settings.json"
  fi

  # Seed triage.md if missing
  if [ ! -f "$claude_dir/state/triage.md" ]; then
    local project_name
    project_name="$(basename "$target")"
    cat > "$claude_dir/state/triage.md" <<TRIAGE
# Triage

**Last updated:** $(date +%Y-%m-%d) (scaffold --init)
**Sprint:** —
**Next:** —

---

## Use Case Log

| Actor | Use Cases | ACs | Verified |
|-------|-----------|-----|----------|
| — | 0 | 0 | 0 |

---

## State Files

| Domain | State File | Last Updated | Owner Skill |
|--------|-----------|--------------|-------------|
| Product | state/product-owner.md | — | /product-owner |
| Engineering | state/engineering-plan.md | — | /engineering-plan |
| Delivery | state/dev-manager.md | — | /dev-manager |
| Architecture | state/architect.md | — | /architect |
| Brand | state/brand.md | — | /brand |
| Legal | state/legal.md | — | /legal |

---

## Active Scope (undelivered)

_Run \`/product-owner --plan-sprint 1\` to define initial scope._

---

## Cross-Audit Gate Verdicts

| Gate | Status | Detail |
|------|--------|--------|
| Tests | — | Not yet run |
| Legal | — | Not yet audited |
| Brand | — | Not yet audited |
| UX | — | Not yet audited |
| Security | — | Not yet audited |

---

## Active Blockers

None.

---

## Velocity

| Sprint | Committed | Delivered | Reliability |
|--------|-----------|-----------|-------------|
| — | — | — | — |
TRIAGE
    log "Seeded state/triage.md"
  fi

  # v2: Do NOT copy global commands — they are auto-discovered by Claude Code.
  # Project commands/ starts empty; user runs --fork to customize specific commands.
  info "Commands: inherited from global (~/.claude/commands/). Use --fork to customize."

  # Seed project overlay template
  local project_name
  project_name="$(basename "$target")"
  if [ ! -f "$claude_dir/agent_docs/lenses/overlay.md" ]; then
    cat > "$claude_dir/agent_docs/lenses/overlay.md" <<OVERLAY
# ${project_name} — Stakeholder Lens Overlay

> Project-specific additions to the global lens checklists.
> Read AFTER the global lens files during Step 2b of /engineering-plan --plan.
> Add project-specific concerns under the relevant heading below.

## Architect — Project Additions

_No project-specific architectural concerns yet._

## Legal — Project Additions

_No project-specific legal concerns yet._

## Security — Project Additions

_No project-specific security concerns yet._

## Compliance — Project Additions

_No project-specific compliance concerns yet._
OVERLAY
    log "Seeded stakeholder lens overlay template"
  fi

  # Sync skills from global
  sync_skills "$claude_dir"

  # Register workspace
  register_workspace "$target"

  echo ""
  log "Done! Structure created at $claude_dir"
  info "Entrypoint: $claude_dir/CLAUDE.md"
  echo ""
  info "What's ready to use (global, no setup needed):"
  info "  Skills:    ~36 in ~/.claude/commands/ (architect, product-owner, etc.)"
  info "  Hooks:     3 in ~/.claude/hooks/ (generated files, destructive ops, secrets)"
  info "  Rules:     3 in ~/.claude/rules/ (coding standards, testing, search-first)"
  info "  Agents:    3 in ~/.claude/agents/ (auditor, state-reader, implementer)"
  info "  Lenses:    4 in ~/.claude/agent_docs/lenses/ (auto-review on /engineering-plan)"
  echo ""
  info "Project-specific:"
  info "  Edit .claude/agent_docs/lenses/overlay.md to add project-specific review concerns"
  info "  Run /scaffold --fork <command> to customize a global skill for this project"
}

# ─── Sync ─────────────────────────────────────────────────────────────────────

# v2: sync_commands is no longer used. Commands are not copied.
# Projects inherit global commands automatically.
# Only --fork creates project-level command overrides.

cleanup_commands() {
  local claude_dir="$1"
  local removed_dup=0
  local removed_stale=0

  if [ ! -d "$COMMANDS_DIR" ] || [ ! -d "$claude_dir/commands" ]; then
    return
  fi

  for dest in "$claude_dir/commands"/*.md; do
    [ -f "$dest" ] || continue
    local fname
    fname="$(basename "$dest")"
    local src="$COMMANDS_DIR/$fname"

    # Skip files with no global counterpart (project-only)
    [ -f "$src" ] || continue

    # Skip intentional overrides
    if is_override "$claude_dir" "$fname"; then
      continue
    fi

    # Remove if identical to global (duplicate)
    if diff -q "$src" "$dest" > /dev/null 2>&1; then
      rm "$dest"
      removed_dup=$((removed_dup + 1))
    else
      # Drifted but NOT in .overrides = stale copy, remove it
      rm "$dest"
      removed_stale=$((removed_stale + 1))
    fi
  done

  if [ $removed_dup -gt 0 ] || [ $removed_stale -gt 0 ]; then
    log "Cleanup: removed $removed_dup duplicates, $removed_stale stale copies"
  else
    info "Cleanup: no duplicates or stale copies found"
  fi
}

sync_skills() {
  local claude_dir="$1"
  local updated=0

  if [ ! -d "$SKILLS_DIR" ]; then
    return
  fi

  # Sync each skill directory
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local dest_dir="$claude_dir/skills/$skill_name"

    mkdir -p "$dest_dir"

    # Sync all files recursively
    while IFS= read -r -d '' src_file; do
      local rel_path="${src_file#$skill_dir}"
      local dest_file="$dest_dir/$rel_path"
      mkdir -p "$(dirname "$dest_file")"

      if [ ! -f "$dest_file" ] || ! diff -q "$src_file" "$dest_file" > /dev/null 2>&1; then
        cp "$src_file" "$dest_file"
        updated=$((updated + 1))
      fi
    done < <(find "$skill_dir" -type f -print0)
  done

  if [ $updated -gt 0 ]; then
    log "Synced skills: $updated files updated"
  fi
}

do_update() {
  local target="${1:-$(pwd)}"
  local claude_dir="$target/.claude"

  if [ ! -d "$claude_dir" ]; then
    err "No .claude/ found at $target — run --init first."
    return 1
  fi

  log "Updating $claude_dir from global canonical source"

  # v2: Clean up duplicates and stale copies (respects .overrides)
  cleanup_commands "$claude_dir"

  # Sync skills
  sync_skills "$claude_dir"

  # Update templates (only if they haven't been customized — check marker)
  if [ -f "$SCAFFOLD_DIR/.gitignore" ]; then
    cp "$SCAFFOLD_DIR/.gitignore" "$claude_dir/.gitignore"
    info "Updated .gitignore from template"
  fi

  # Ensure directory structure is complete (includes v2 additions)
  mkdir -p \
    "$claude_dir/state" \
    "$claude_dir/data/plans" \
    "$claude_dir/data/plans/archive" \
    "$claude_dir/data/sprints" \
    "$claude_dir/data/milestones" \
    "$claude_dir/data/evidence" \
    "$claude_dir/data/launches" \
    "$claude_dir/agent_docs/lenses" \
    "$claude_dir/agents" \
    "$claude_dir/rules" \
    "$claude_dir/compact" \
    "$claude_dir/archive"

  # Seed project overlay template if missing
  if [ ! -f "$claude_dir/agent_docs/lenses/overlay.md" ]; then
    local _project_name
    _project_name="$(basename "$target")"
    cat > "$claude_dir/agent_docs/lenses/overlay.md" <<OVERLAY
# ${_project_name} — Stakeholder Lens Overlay

> Project-specific additions to the global lens checklists.
> Read AFTER the global lens files during Step 2b of /engineering-plan --plan.
> Add project-specific concerns under the relevant heading below.

## Architect — Project Additions

_No project-specific architectural concerns yet._

## Legal — Project Additions

_No project-specific legal concerns yet._

## Security — Project Additions

_No project-specific security concerns yet._

## Compliance — Project Additions

_No project-specific compliance concerns yet._
OVERLAY
    info "Seeded stakeholder lens overlay template"
  fi

  # Register if not already
  register_workspace "$target"

  log "Update complete."
}

# ─── Fork ────────────────────────────────────────────────────────────────────

do_fork() {
  local cmd_name="$1"
  local target="${2:-$(pwd)}"
  local claude_dir="$target/.claude"
  local reason="${3:-forked from global}"

  if [ ! -d "$claude_dir" ]; then
    err "No .claude/ found at $target — run --init first."
    return 1
  fi

  local src="$COMMANDS_DIR/$cmd_name"
  if [ ! -f "$src" ]; then
    err "Global command not found: $cmd_name"
    err "Available: $(ls "$COMMANDS_DIR"/*.md 2>/dev/null | xargs -I{} basename {} | tr '\n' ' ')"
    return 1
  fi

  local dest="$claude_dir/commands/$cmd_name"
  local overrides_file="$claude_dir/commands/.overrides"

  # Copy the command
  cp "$src" "$dest"
  log "Copied $cmd_name to project"

  # Register in .overrides
  if [ ! -f "$overrides_file" ]; then
    echo "# Intentional overrides of global commands. One per line: filename # reason" > "$overrides_file"
  fi

  # Don't add if already registered
  if ! grep -q "^${cmd_name}" "$overrides_file" 2>/dev/null; then
    echo "$cmd_name  # $reason" >> "$overrides_file"
    log "Registered override: $cmd_name ($reason)"
  else
    info "Already in .overrides: $cmd_name"
  fi
}

# ─── Migrate ─────────────────────────────────────────────────────────────────

do_migrate() {
  local target="${1:-$(pwd)}"
  local claude_dir="$target/.claude"

  if [ ! -d "$claude_dir" ]; then
    err "No .claude/ found at $target — run --init first."
    return 1
  fi

  log "Migrating $claude_dir to override model (v2)..."

  local removed_dup=0
  local removed_stale=0
  local kept_override=0
  local kept_local=0

  if [ ! -d "$claude_dir/commands" ]; then
    info "No commands directory — nothing to migrate."
    return
  fi

  for dest in "$claude_dir/commands"/*.md; do
    [ -f "$dest" ] || continue
    local fname
    fname="$(basename "$dest")"
    local src="$COMMANDS_DIR/$fname"

    # No global counterpart = project-only, keep it
    if [ ! -f "$src" ]; then
      kept_local=$((kept_local + 1))
      continue
    fi

    # In .overrides = intentional, keep it
    if is_override "$claude_dir" "$fname"; then
      kept_override=$((kept_override + 1))
      continue
    fi

    # Identical to global = duplicate, remove
    if diff -q "$src" "$dest" > /dev/null 2>&1; then
      rm "$dest"
      removed_dup=$((removed_dup + 1))
    else
      # Drifted but not in .overrides = stale, remove
      warn "  Removing stale: $fname"
      rm "$dest"
      removed_stale=$((removed_stale + 1))
    fi
  done

  # Clean up .overrides-related files (README.md that's a duplicate)
  # README.md in commands/ is special — remove if it matches global
  if [ -f "$claude_dir/commands/README.md" ] && [ -f "$COMMANDS_DIR/README.md" ]; then
    if ! is_override "$claude_dir" "README.md"; then
      if diff -q "$COMMANDS_DIR/README.md" "$claude_dir/commands/README.md" > /dev/null 2>&1; then
        rm "$claude_dir/commands/README.md"
        removed_dup=$((removed_dup + 1))
      fi
    fi
  fi

  echo ""
  log "Migration complete:"
  echo -e "  ${GREEN}Kept${NC}     $kept_override overrides (in .overrides)"
  echo -e "  ${BLUE}Kept${NC}     $kept_local project-only commands"
  echo -e "  ${YELLOW}Removed${NC}  $removed_dup duplicates (identical to global)"
  echo -e "  ${RED}Removed${NC}  $removed_stale stale copies (drifted, not in .overrides)"
}

# ─── Distribute ───────────────────────────────────────────────────────────────

do_distribute() {
  ensure_registry

  if [ ! -s "$REGISTRY" ]; then
    warn "No workspaces registered. Use --register to add workspaces."
    return
  fi

  local total=0
  local success=0
  local failed=0
  local skipped=0

  log "Distributing updates to all registered workspaces..."
  echo ""

  while IFS= read -r ws; do
    total=$((total + 1))

    if [ ! -d "$ws" ]; then
      err "  ✗ $ws — directory missing"
      failed=$((failed + 1))
      continue
    fi

    if [ ! -d "$ws/.claude" ]; then
      warn "  ⊘ $ws — no .claude/ (skipped, use --init)"
      skipped=$((skipped + 1))
      continue
    fi

    info "  → $ws"
    do_update "$ws" 2>&1 | sed 's/^/    /'
    success=$((success + 1))
  done < "$REGISTRY"

  echo ""
  log "Distribution complete: $success updated, $skipped skipped, $failed failed (of $total total)"
}

# ─── Diff ─────────────────────────────────────────────────────────────────────

do_diff() {
  local target="${1:-$(pwd)}"
  local claude_dir="$target/.claude"

  if [ ! -d "$claude_dir/commands" ]; then
    err "No .claude/commands/ found at $target"
    return 1
  fi

  local overrides=0
  local locals=0
  local stale=0
  local duplicates=0

  info "Command status: $claude_dir/commands/"
  echo ""

  # Check project files against global
  for dest in "$claude_dir/commands"/*.md; do
    [ -f "$dest" ] || continue
    local fname
    fname="$(basename "$dest")"
    local src="$COMMANDS_DIR/$fname"

    if [ ! -f "$src" ]; then
      # No global counterpart = project-only
      echo -e "  ${BLUE}LOCAL${NC}      $fname"
      locals=$((locals + 1))
    elif is_override "$claude_dir" "$fname"; then
      local reason
      reason="$(override_reason "$claude_dir" "$fname")"
      echo -e "  ${GREEN}OVERRIDE${NC}   $fname  ${CYAN}($reason)${NC}"
      overrides=$((overrides + 1))
    elif diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}DUPLICATE${NC}  $fname  (identical to global — safe to remove)"
      duplicates=$((duplicates + 1))
    else
      echo -e "  ${RED}STALE${NC}      $fname  (drifted from global, not in .overrides)"
      stale=$((stale + 1))
    fi
  done

  # Check .overrides file
  if [ -f "$claude_dir/commands/.overrides" ]; then
    echo ""
    info ".overrides file: present"
  else
    echo ""
    info ".overrides file: not found"
  fi

  echo ""
  log "Summary: $overrides overrides, $locals local, $duplicates duplicates, $stale stale"

  if [ $duplicates -gt 0 ] || [ $stale -gt 0 ]; then
    warn "Run --migrate to clean up $((duplicates + stale)) unnecessary files."
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
  --init|"")
    do_init "${2:-$(pwd)}"
    ;;
  --update)
    do_update "${2:-$(pwd)}"
    ;;
  --distribute)
    do_distribute
    ;;
  --list)
    list_workspaces
    ;;
  --register)
    register_workspace "${2:-$(pwd)}"
    ;;
  --unregister)
    unregister_workspace "${2:-$(pwd)}"
    ;;
  --fork)
    if [ -z "${2:-}" ]; then
      err "Usage: scaffold.sh --fork <command-name.md> [path] [reason]"
      exit 1
    fi
    do_fork "$2" "${3:-$(pwd)}" "${4:-forked from global}"
    ;;
  --migrate)
    do_migrate "${2:-$(pwd)}"
    ;;
  --diff)
    do_diff "${2:-$(pwd)}"
    ;;
  --help|-h)
    echo "Usage: scaffold.sh [flag] [path]"
    echo ""
    echo "Override model (v2):"
    echo "  Global commands are auto-discovered from ~/.claude/commands/."
    echo "  Project .claude/commands/ holds only project-specific and forked commands."
    echo "  Intentional overrides are tracked in .claude/commands/.overrides."
    echo ""
    echo "Flags:"
    echo "  --init         Create .claude/ structure (default). Commands inherited from global."
    echo "  --update       Sync skills, clean duplicate/stale commands"
    echo "  --distribute   Push updates to ALL registered workspaces"
    echo "  --fork <name>  Copy a global command to project + register as override"
    echo "  --migrate      One-time cleanup: remove stale copies, respect .overrides"
    echo "  --diff         Show command status (OVERRIDE/LOCAL/STALE/DUPLICATE)"
    echo "  --list         List registered workspaces"
    echo "  --register     Add a workspace to the registry"
    echo "  --unregister   Remove a workspace from the registry"
    echo "  --help         Show this help"
    ;;
  *)
    err "Unknown flag: $1 — use --help for usage"
    exit 1
    ;;
esac
