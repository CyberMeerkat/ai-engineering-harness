// mcp-install.mjs — MCP helper binary installation (context-mode, context7-mcp).
// Consolidates install-mcp-deps.sh (bash) and Install-McpDeps (PowerShell).

import { commandExists, commandRuns, runInherit, action } from "./platform.mjs";

/**
 * Installs a single npm-based MCP helper binary if not already present.
 * Returns without action if the binary already exists on PATH.
 */
async function installPkg(dryRun, binName, npmPackage) {
  if (commandExists(binName)) {
    console.log(`${binName} already installed`);
    return;
  }

  if (dryRun) {
    console.log(`[dry-run] ${binName} not installed; would run: npm install -g ${npmPackage}`);
    return;
  }

  if (!commandExists("npm")) {
    throw new Error(`${binName} is required and npm is unavailable to install it.`);
  }

  runInherit("npm", ["install", "-g", npmPackage]);
}

/**
 * Installs context-mode and context7-mcp at their pinned versions from
 * versions.json.
 */
export async function installMcpDeps(dryRun, versions) {
  await installPkg(dryRun, "context-mode", `context-mode@${versions.mcp["context-mode"]}`);
  await installPkg(
    dryRun,
    "context7-mcp",
    `@upstash/context7-mcp@${versions.mcp["context7-mcp"]}`
  );
}

/** Returns true if both context-mode and context7-mcp are installed and runnable. */
export function areMcpDepsRunnable() {
  return (
    commandExists("context-mode") &&
    commandExists("context7-mcp") &&
    (commandRuns("context-mode", ["--help"]) || commandRuns("context-mode", ["--version"])) &&
    (commandRuns("context7-mcp", ["--help"]) || commandRuns("context7-mcp", ["--version"]))
  );
}
