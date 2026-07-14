#!/bin/bash
# check-secrets.sh — PreToolUse:Write,Edit enforcement hook
# BLOCKS file writes that contain hardcoded secrets.
# Inspired by AgentShield's 14 secret detection patterns.

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_name', ''))
" 2>/dev/null)

# Only check Write and Edit tools
if [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "Edit" ]; then
  exit 0
fi

# Extract the content being written
CONTENT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
# For Write: check content. For Edit: check new_string.
content = ti.get('content', '') or ti.get('new_string', '')
print(content)
" 2>/dev/null)

if [ -z "$CONTENT" ]; then
  exit 0
fi

# Skip if writing to state files, plans, or memory (these may legitimately reference tokens)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', ''))
" 2>/dev/null)

if echo "$FILE_PATH" | grep -qE '\.claude/state/|\.claude/data/|\.claude/compact/|memory/'; then
  exit 0
fi

# Secret patterns (14 patterns from AgentShield + custom additions)
FOUND=""

# AWS Access Key (starts with AKIA)
if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
  FOUND="AWS Access Key ID detected"
fi

# AWS Secret Key (40 chars base64-like after common prefixes)
if echo "$CONTENT" | grep -qE '(aws_secret_access_key|AWS_SECRET_ACCESS_KEY)\s*[=:]\s*[A-Za-z0-9/+=]{40}'; then
  FOUND="AWS Secret Access Key detected"
fi

# GitHub Token (ghp_, gho_, ghs_, ghr_, github_pat_)
if echo "$CONTENT" | grep -qE 'gh[posrn]_[A-Za-z0-9_]{36,}|github_pat_[A-Za-z0-9_]{22,}'; then
  FOUND="GitHub token detected"
fi

# Generic API key patterns (key=..., api_key=..., apikey=...)
if echo "$CONTENT" | grep -qiE '(api[_-]?key|api[_-]?secret|access[_-]?token)\s*[=:]\s*["\x27]?[A-Za-z0-9_\-]{20,}'; then
  FOUND="API key/secret detected"
fi

# Private key blocks
if echo "$CONTENT" | grep -qE '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'; then
  FOUND="Private key block detected"
fi

# Database connection strings with passwords
if echo "$CONTENT" | grep -qiE '(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@'; then
  FOUND="Database connection string with password detected"
fi

# JWT tokens (3-part base64 dot-separated)
if echo "$CONTENT" | grep -qE 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'; then
  # Skip if it's in a docs/example context (markdown code blocks about JWT)
  if ! echo "$FILE_PATH" | grep -qE '\.(md|txt)$'; then
    FOUND="JWT token detected in non-documentation file"
  fi
fi

# Slack webhook URLs
if echo "$CONTENT" | grep -qE 'hooks\.slack\.com/services/T[A-Z0-9]{8,}/B[A-Z0-9]{8,}/[A-Za-z0-9]{20,}'; then
  FOUND="Slack webhook URL detected"
fi

# SendGrid API key
if echo "$CONTENT" | grep -qE 'SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}'; then
  FOUND="SendGrid API key detected"
fi

# Stripe keys
if echo "$CONTENT" | grep -qE '(sk|pk)_(test|live)_[A-Za-z0-9]{20,}'; then
  FOUND="Stripe API key detected"
fi

# Hardcoded passwords in config-like contexts
if echo "$CONTENT" | grep -qiE '(password|passwd|pwd)\s*[=:]\s*["\x27][^"\x27]{8,}["\x27]'; then
  # Skip .env files and docker-compose (they're supposed to have passwords)
  if ! echo "$FILE_PATH" | grep -qE '\.(env|yml|yaml)$'; then
    FOUND="Hardcoded password detected"
  fi
fi

if [ -n "$FOUND" ]; then
  echo "BLOCKED: $FOUND"
  echo "File: $FILE_PATH"
  echo "Secrets must be stored in .env files, never hardcoded in source or config."
  echo "If this is a false positive (documentation/example), override by adding to .claude/settings.json allow list."
  exit 1
fi

exit 0
