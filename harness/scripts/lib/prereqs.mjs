// prereqs.mjs — pre-flight prerequisite check.
// NOTE: python3 and curl are no longer required here. The old bash/PowerShell
// implementations needed python3 for JSON parsing and curl for downloads;
// Node has both natively (JSON.parse, fetch()). The only real prerequisite
// left for the Node-based core is npm (to install opencode-ai/context-mode/
// context7-mcp packages). Node itself is guaranteed present by the time this
// module runs — the thin setup.sh/setup.ps1 launchers bootstrap Node first.

import { commandExists, runCapture } from "./platform.mjs";

/**
 * Returns { ok: boolean, checks: { npm: {ok, detail}, node: {ok, detail} } }
 */
export function checkPrereqs(requiredNodeMajor) {
  const checks = {};

  const nodeMajor = Number(process.versions.node.split(".")[0]);
  checks.node = {
    ok: nodeMajor >= requiredNodeMajor,
    detail: checks_nodeDetail(nodeMajor, requiredNodeMajor),
  };

  const npmOk = commandExists("npm");
  checks.npm = {
    ok: npmOk,
    detail: npmOk ? `npm found` : `npm not found`,
  };
  if (npmOk) {
    try {
      const version = runCapture("npm", ["--version"]);
      checks.npm.detail = `npm ${version}`;
    } catch {
      // version lookup failing doesn't invalidate presence
    }
  }

  const ok = Object.values(checks).every((c) => c.ok);
  return { ok, checks };
}

function checks_nodeDetail(major, required) {
  return major >= required
    ? `ok (node ${process.versions.node})`
    : `fail (need ${required}+, found ${process.versions.node})`;
}

/**
 * Runs the check and prints [OK]/[FAIL] lines. Returns the same shape as
 * checkPrereqs(). Exits the process with code 1 if `exitOnFailure` is true
 * (default) and any check fails.
 */
export function reportPrereqs(requiredNodeMajor, { exitOnFailure = true } = {}) {
  const { ok, checks } = checkPrereqs(requiredNodeMajor);

  for (const [name, result] of Object.entries(checks)) {
    const prefix = result.ok ? "[OK]  " : "[FAIL]";
    const stream = result.ok ? console.log : console.error;
    stream(`${prefix} ${name}: ${result.detail}`);
  }

  if (!ok) {
    console.error("\nMissing prerequisites above. Install them and re-run setup.");
    if (!checks.npm.ok) {
      console.error("  npm: comes with Node.js — https://nodejs.org/");
    }
    if (exitOnFailure) process.exit(1);
  } else {
    console.log("prereqs ok");
  }

  return { ok, checks };
}
