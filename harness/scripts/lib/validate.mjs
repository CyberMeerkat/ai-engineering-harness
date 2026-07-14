// validate.mjs — post-setup validation. Consolidates validate-setup.sh
// (bash) and Validate-Setup (PowerShell).

import fs from "node:fs";
import path from "node:path";
import { commandExists, commandRuns } from "./platform.mjs";
import { isOpenCodeRunnable } from "./opencode-install.mjs";
import { resolveGlobalDirs } from "./project-config.mjs";

class ValidationError extends Error {}

function requireFile(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new ValidationError(`Missing required path: ${filePath}`);
  }
}

function requireCommand(cmd) {
  if (!commandExists(cmd)) {
    throw new ValidationError(`Missing required command: ${cmd}`);
  }
}

function requireCommandRuns(cmd) {
  if (!commandRuns(cmd, ["--help"]) && !commandRuns(cmd, ["--version"])) {
    throw new ValidationError(`Installed command failed to run: ${cmd}`);
  }
}

/**
 * Runs the full post-setup validation. Throws ValidationError with a
 * descriptive message on the first failure (matching the original
 * bash/PowerShell fail-fast behaviour). Returns silently on success.
 */
export function validateSetup(rootDir) {
  if (!commandExists("opencode")) {
    throw new ValidationError("opencode is not installed");
  }
  requireCommand("context-mode");
  requireCommand("context7-mcp");

  if (!isOpenCodeRunnable()) {
    throw new ValidationError("Installed command failed to run: opencode");
  }
  requireCommandRuns("context-mode");
  requireCommandRuns("context7-mcp");

  const dirs = resolveGlobalDirs();

  requireFile(path.join(rootDir, "opencode.jsonc"));
  requireFile(path.join(rootDir, ".opencode", "skills", "frontend-design", "SKILL.md"));
  requireFile(path.join(dirs.config, "opencode.json"));
  requireFile(path.join(dirs.config, "skills", "understand", "SKILL.md"));
  requireFile(path.join(dirs.config, "plugins", "check-secrets.mjs"));

  // JSON structural checks
  JSON.parse(fs.readFileSync(path.join(rootDir, "opencode.jsonc"), "utf8"));
  const globalConfig = JSON.parse(fs.readFileSync(path.join(dirs.config, "opencode.json"), "utf8"));
  if (!globalConfig.mcp) {
    throw new ValidationError("Global OpenCode app bundle is missing MCP config.");
  }
  if (!globalConfig.plugin) {
    throw new ValidationError("Global OpenCode app bundle is missing plugin config.");
  }

  console.log("opencode installed");
  console.log("context-mode installed");
  console.log("context7-mcp installed");
  console.log("required commands execute");
  console.log("project config present");
  console.log("core repo-managed OpenCode skills present");
  console.log("global app bundle present");
  console.log("local security plugins present");
}

export { ValidationError };
