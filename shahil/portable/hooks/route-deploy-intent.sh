#!/bin/bash
# route-deploy-intent.sh — UserPromptSubmit hook
# When the user's prompt matches deploy intent, inject a system-reminder
# nudging Claude to invoke the /deploy-vps skill before writing any commands.

INPUT=$(cat)

PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('prompt', ''), end='')
except Exception:
    pass
" 2>/dev/null)

if [ -z "$PROMPT" ]; then
  exit 0
fi

# Keywords that indicate deploy/VPS intent.
# Case-insensitive word-boundary matches to avoid false positives like
# "deploy a PDF" or "deploying creativity" in prose.
if echo "$PROMPT" | grep -iqE '\b(deploy|deployment|ship it|push to (prod|production|main)|run (the )?migration( on)? (vps|prod)|migrate (on|to) (vps|prod)|restart (the )?(api|service|container)|vps|prisma migrate (deploy|dev)|db push|db migrate)\b'; then
  cat <<'REMINDER'
<deploy-intent-reminder>
Deploy / VPS intent detected in the user's prompt.

Before writing any Bash or SSH command:
1. Read scripts/README.md (one-page cheatsheet of allowed operations)
2. Invoke the Skill tool with name "deploy-vps" — this loads the 7 SAFETY RULES + valid flags (--deploy, --status, --restart, --db-push, --diagnose, --recover)
3. Do NOT compose `ssh root@{{PROD_IP}} "docker compose ..."` from memory — the PreToolUse hook will block it and point you back here.
4. Canonical deploy path: commit + push to main → webhook runs scripts/deploy.sh (which now handles prisma migrate deploy automatically when migrations are in the push).
5. If your need is not covered by the skill's flags or scripts/deploy.sh, STOP and ask the user — do not improvise.
</deploy-intent-reminder>
REMINDER
fi

exit 0
