#!/bin/bash
# check-generated-files.sh — PreToolUse:Edit enforcement hook
# BLOCKS edits to files marked with "GENERATED FILE - DO NOT EDIT" headers.
# Fix at the generator level or use a patching mechanism instead.

INPUT=$(cat)

# Extract file_path from tool input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', ''))
" 2>/dev/null)

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Check the first 5 lines for generated file markers
if head -5 "$FILE_PATH" 2>/dev/null | grep -qi "GENERATED FILE.*DO NOT EDIT\|@generated\|AUTO-GENERATED"; then
  echo "BLOCKED: This is a generated file. Do not edit directly."
  echo "File: $FILE_PATH"
  echo "Fix at the generator level or use a patching mechanism."
  echo "See: .claude/rules/learned-rules.md (rule: Never modify @generated files)"
  exit 1
fi

exit 0
