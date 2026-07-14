#!/bin/bash
# compact-check.sh — Checks if context window usage exceeds threshold
# Called as a PostToolUse hook. Reads conversation turn count from stdin (JSON).
# If the conversation is long, outputs a reminder to consider /compact.

# Read the hook input from stdin
INPUT=$(cat)

# Extract the tool name to avoid infinite loops (don't trigger on our own skill invocation)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
if [ "$TOOL_NAME" = "Skill" ]; then
  exit 0
fi

# Use a simple heuristic: count the session message file size as proxy for context usage.
# Claude Code doesn't expose context % directly, so we track invocation count via a temp file.
COUNTER_FILE="/tmp/claude-compact-counter-$$"
if [ ! -f "$COUNTER_FILE" ]; then
  # Try to find the parent process counter file
  COUNTER_FILE="/tmp/claude-compact-counter-$(ps -o ppid= $$ | tr -d ' ')"
fi
if [ ! -f "$COUNTER_FILE" ]; then
  COUNTER_FILE="/tmp/claude-compact-counter"
fi

# Increment counter
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# At ~40 tool calls we're likely past 50% context in a complex session
# Remind every 40 calls (40, 80, 120...)
if [ $((COUNT % 40)) -eq 0 ] && [ "$COUNT" -gt 0 ]; then
  echo "--- CONTEXT CHECK ---"
  echo "You have made ~${COUNT} tool calls this session. Context window may be over 50% used."
  echo "Consider running /compact to create a continuation snapshot before context is exhausted."
  echo "---"
fi
