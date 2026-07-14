#!/bin/bash
# strip-jwt-permissions.sh — PreToolUse:Bash hook
# Auto-denies any Bash command containing a JWT token (eyJ...) so that
# permission approval never accumulates ephemeral tokens in settings.local.json.
# Pairs with the deny patterns in settings.local.json — this hook covers the
# permission-resolution gap when the deny pattern doesn't match exactly.

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('command', ''))
" 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Detect JWT pattern: three base64url-encoded segments joined by dots, starting with eyJ
# Real JWTs are >100 chars; we match conservatively: TOKEN= or Bearer followed by eyJ + chars + dot
if echo "$COMMAND" | grep -qE "(TOKEN=|Bearer\s+|Authorization:[^']*Bearer\s+)\"?eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"; then
  echo "BLOCKED: Bash command contains a JWT token (eyJ pattern)."
  echo "JWTs are ephemeral and should never be approved as permissions —"
  echo "they accumulate in settings.local.json and bloat permission lookups."
  echo ""
  echo "Fix: assign the token to a variable in your shell first, then reference it:"
  echo "    export TOKEN=\$(...)        # outside Claude Code"
  echo "    Bash command: curl -H \"Authorization: Bearer \$TOKEN\" ..."
  echo ""
  echo "Or pass via --header value substitution from a file."
  echo "See: .claude/rules/learned-rules.md (token-audit rules)"
  exit 1
fi

exit 0
