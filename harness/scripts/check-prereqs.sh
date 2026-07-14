#!/usr/bin/env bash
# check-prereqs.sh — pre-flight prerequisite check for ai-engineering-harness setup
# Exits 0 (prereqs ok) or 1 (first missing prereq).
# Supports --json flag to print a machine-readable summary (used by doctor.sh).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSIONS_PATH="$ROOT_DIR/versions.json"

JSON_MODE=0
if [ "${1:-}" = "--json" ]; then
  JSON_MODE=1
fi

# Read required Node major from versions.json
NODE_MAJOR_REQUIRED="$(python3 - <<'PY' "$VERSIONS_PATH"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['node']['major'])
PY
)"

# ── check functions ────────────────────────────────────────────────────────────
check_python3() {
  command -v python3 >/dev/null 2>&1
}

check_node() {
  if ! command -v node >/dev/null 2>&1; then
    return 1
  fi
  local major
  major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)"
  [ "$major" -ge "$NODE_MAJOR_REQUIRED" ] 2>/dev/null
}

check_npm() {
  command -v npm >/dev/null 2>&1
}

check_curl() {
  command -v curl >/dev/null 2>&1
}

# ── evaluate ───────────────────────────────────────────────────────────────────
FAIL=0

declare -A RESULTS
RESULTS[python3]=$(check_python3 && echo ok || echo fail)
RESULTS[node]=$(check_node && echo "ok (node $(node -p 'process.versions.node' 2>/dev/null))" || echo "fail (need ${NODE_MAJOR_REQUIRED}+)")
RESULTS[npm]=$(check_npm && echo ok || echo fail)
RESULTS[curl]=$(check_curl && echo ok || echo fail)

for key in python3 node npm curl; do
  if [[ "${RESULTS[$key]}" == fail* ]]; then
    FAIL=1
  fi
done

# ── output ─────────────────────────────────────────────────────────────────────
if [ "$JSON_MODE" = "1" ]; then
  printf '{\n'
  printf '  "python3": "%s",\n' "${RESULTS[python3]}"
  printf '  "node": "%s",\n' "${RESULTS[node]}"
  printf '  "npm": "%s",\n' "${RESULTS[npm]}"
  printf '  "curl": "%s",\n' "${RESULTS[curl]}"
  printf '  "ok": %s\n' "$([ "$FAIL" -eq 0 ] && echo true || echo false)"
  printf '}\n'
  exit "$FAIL"
fi

# human-readable output
for key in python3 node npm curl; do
  val="${RESULTS[$key]}"
  if [[ "$val" == ok* ]]; then
    printf '[OK]   %s: %s\n' "$key" "$val"
  else
    printf '[FAIL] %s: %s\n' "$key" "$val" >&2
  fi
done

if [ "$FAIL" -ne 0 ]; then
  printf '\nMissing prerequisites above. Install them and re-run setup.\n' >&2
  printf 'Suggested installers:\n' >&2
  check_python3 || printf '  python3: https://www.python.org/downloads/ or brew install python3\n' >&2
  check_node    || printf '  node %s+: https://nodejs.org/ or brew install node\n' "$NODE_MAJOR_REQUIRED" >&2
  check_npm     || printf '  npm: comes with Node.js\n' >&2
  check_curl    || printf '  curl: brew install curl or your OS package manager\n' >&2
  exit 1
fi

printf 'prereqs ok\n'
exit 0
