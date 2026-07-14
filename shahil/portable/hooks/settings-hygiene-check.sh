#!/bin/bash
# settings-hygiene-check.sh — Stop hook (or manual)
# Reports if .claude/settings.local.json or always-loaded files exceed thresholds.
# Non-blocking — emits a one-line summary so the user notices regression.

# Reads stdin (Stop hook payload) but doesn't require any field
cat > /dev/null

# Find the active project's settings.local.json — Claude Code sets CLAUDE_PROJECT_DIR
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SETTINGS="$PROJECT_DIR/.claude/settings.local.json"
PROJECT_CLAUDE_MD="$PROJECT_DIR/.claude/CLAUDE.md"
PROJECT_CLAUDE_ROOT="$PROJECT_DIR/CLAUDE.md"

if [ ! -f "$SETTINGS" ]; then
  exit 0
fi

WARNINGS=()

# 1. Settings file size
SIZE=$(wc -c < "$SETTINGS" | tr -d ' ')
if [ "$SIZE" -gt 5120 ]; then
  WARNINGS+=("settings.local.json is ${SIZE} bytes (target <5KB)")
fi

# 2. JWT count
JWT_COUNT=$(grep -c "eyJ" "$SETTINGS" 2>/dev/null || echo 0)
# Subtract 4 for the deny patterns (which contain literal "eyJ")
if [ "$JWT_COUNT" -gt 4 ]; then
  ACTUAL=$((JWT_COUNT - 4))
  WARNINGS+=("settings.local.json has ${ACTUAL} JWT entries (should be 0)")
fi

# 3. Bash entry count
BASH_COUNT=$(grep -c '"Bash(' "$SETTINGS" 2>/dev/null || echo 0)
if [ "$BASH_COUNT" -gt 80 ]; then
  WARNINGS+=("settings.local.json has ${BASH_COUNT} Bash entries (target <80, collapse to wildcards)")
fi

# 4. Always-loaded total
TOTAL=0
[ -f "$PROJECT_CLAUDE_MD" ] && TOTAL=$((TOTAL + $(wc -c < "$PROJECT_CLAUDE_MD" | tr -d ' ')))
[ -f "$PROJECT_CLAUDE_ROOT" ] && TOTAL=$((TOTAL + $(wc -c < "$PROJECT_CLAUDE_ROOT" | tr -d ' ')))
for f in "$PROJECT_DIR"/.claude/rules/*.md; do
  [ -f "$f" ] && TOTAL=$((TOTAL + $(wc -c < "$f" | tr -d ' ')))
done
for f in "$HOME"/.claude/rules/*.md; do
  [ -f "$f" ] && TOTAL=$((TOTAL + $(wc -c < "$f" | tr -d ' ')))
done
if [ "$TOTAL" -gt 30720 ]; then
  KB=$((TOTAL / 1024))
  WARNINGS+=("Always-loaded files total ${KB}KB (target <30KB) — run /token-audit")
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "🪨 hygiene check:"
  for w in "${WARNINGS[@]}"; do echo "  • $w"; done
fi

exit 0
