#!/bin/bash
# check-destructive-ops.sh — PreToolUse:Bash enforcement hook
# BLOCKS dangerous operations that have caused incidents in the past.
# Each check references the learned rule it enforces.
#
# >>> SANITISED FOR SHARING <<<
# Replace the placeholders below with YOUR infrastructure before use, OR delete
# the rules you don't need. Placeholders use regex-escaped forms where shown.
#   {{PROD_IP}}    e.g. 203\.0\.113\.10   (escape the dots for grep -E)
#   {{PROD_HOST}}  e.g. prod\.example\.com
#   {{PROD_PATH}}  e.g. /opt/app
# If you have no remote VPS, you can safely delete Rules 1 and 3–6.

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

# Rule 1: Never SCP files to a git-managed VPS (learned rule #1)
if echo "$COMMAND" | grep -qE "scp\s.*{{PROD_IP}}|scp\s.*{{PROD_HOST}}"; then
  echo "BLOCKED: Never SCP files to a git-managed VPS."
  echo "Production at {{PROD_PATH}} receives code via git pull only."
  echo "SCP creates uncommitted changes that block the next git pull --ff-only."
  echo "See: .claude/rules/learned-rules.md (rule #1)"
  exit 1
fi

# Rule 2: docker compose restart doesn't reload env vars (learned rule #2)
if echo "$COMMAND" | grep -qE "docker.compose\s+restart\b"; then
  echo "WARNING: 'docker compose restart' does NOT reload env vars."
  echo "Use 'docker compose up -d <service>' to recreate the container with new env."
  echo "See: .claude/rules/learned-rules.md (rule #2)"
  # Warning only — don't block, but make it visible
  exit 0
fi

# Rule 3: SSH-wrapped docker/systemctl on the VPS — use the deploy skill/script
# Pattern: ssh followed anywhere by VPS hostname/IP AND docker compose
if echo "$COMMAND" | grep -qE 'ssh\s+.*({{PROD_IP}}|{{PROD_HOST}})' && \
   echo "$COMMAND" | grep -qE 'docker\s+compose\b'; then
  echo "BLOCKED: Don't SSH and run 'docker compose' on the VPS by hand."
  echo ""
  echo "Use the skill or script that already handles this safely:"
  echo "  • Full deploy:    push to main -> webhook runs scripts/deploy.sh"
  echo "  • Status check:   /deploy-vps --status"
  echo "  • Service restart: /deploy-vps --restart <service>"
  echo "  • DB migration:   /deploy-vps --db-push (dev) / push commit (prod — deploy.sh handles)"
  echo "  • Recovery:       /deploy-vps --recover"
  echo ""
  echo "See: .claude/commands/deploy-vps.md (7 SAFETY RULES)"
  echo "     .claude/rules/learned-rules.md (rules #5, #7)"
  echo "     scripts/README.md (cheatsheet)"
  echo ""
  echo "If the skill truly does not cover your need, stop and ask the user — do not improvise."
  exit 1
fi

# Rule 4: SSH + docker compose down — destroys named volumes (learned rule #7)
if echo "$COMMAND" | grep -qE 'ssh\s+.*({{PROD_IP}}|{{PROD_HOST}}).*docker\s+compose\s+down'; then
  echo "BLOCKED: 'docker compose down' on VPS destroys named volumes (node_modules, .next, DB data)."
  echo "Use '/deploy-vps --restart <service>' (uses --force-recreate, preserves volumes)."
  echo "See: .claude/rules/learned-rules.md (rule #7)"
  exit 1
fi

# Rule 5: SSH + systemctl restart docker — kills everything (learned rule #6)
if echo "$COMMAND" | grep -qE 'ssh\s+.*({{PROD_IP}}|{{PROD_HOST}}).*systemctl\s+restart\s+docker'; then
  echo "BLOCKED: 'systemctl restart docker' on VPS kills ALL containers + wipes anonymous volumes."
  echo "For stuck containers: 'docker rm -f <id>'. Daemon restart is absolute last resort."
  echo "See: .claude/rules/learned-rules.md (rule #6)"
  exit 1
fi

# Rule 6: SSH + docker compose exec + prisma — manual migrations bypass deploy.sh
if echo "$COMMAND" | grep -qE 'ssh\s+.*({{PROD_IP}}|{{PROD_HOST}}).*docker\s+compose\s+.*exec.*prisma'; then
  echo "BLOCKED: Don't run 'prisma' commands on VPS via ad-hoc 'docker compose exec'."
  echo "Migrations are handled by scripts/deploy.sh (triggered by push-to-main)."
  echo "Dev-only fallback: /deploy-vps --db-push"
  echo "See: .claude/commands/deploy-vps.md"
  exit 1
fi

exit 0
