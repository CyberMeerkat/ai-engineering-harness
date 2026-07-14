// doctor.mjs — diagnostic report: prereqs, tool versions, PATH health,
// writable dirs. Consolidates doctor.sh (bash) / Invoke-Doctor (PowerShell).

import fs from "node:fs";
import path from "node:path";
import { commandExists, runCapture } from "./platform.mjs";
import { checkPrereqs } from "./prereqs.mjs";
import { resolveGlobalDirs } from "./project-config.mjs";

function ok(msg) {
  console.log(`[OK]   ${msg}`);
}
function warn(msg) {
  console.log(`[WARN] ${msg}`);
}
function fail(msg) {
  console.error(`[FAIL] ${msg}`);
}

/**
 * Runs the full diagnostic and prints a human-readable report. Returns
 * true if everything is green (no [FAIL] lines), false otherwise. Does not
 * call process.exit — the caller (setup.mjs) decides the exit code.
 */
export function runDoctor(rootDir, versions) {
  let allGreen = true;

  console.log("--- Prerequisites ---");
  const { checks } = checkPrereqs(versions.node.major);
  for (const [name, result] of Object.entries(checks)) {
    if (result.ok) ok(`${name}: ${result.detail}`);
    else {
      fail(`${name}: ${result.detail}`);
      allGreen = false;
    }
  }

  console.log("\n--- Version pins ---");
  const toolChecks = [
    ["opencode", versions.opencode.npm],
    ["context-mode", versions.mcp["context-mode"]],
    ["context7-mcp", versions.mcp["context7-mcp"]],
  ];
  for (const [tool, pinned] of toolChecks) {
    if (commandExists(tool)) {
      let installed = "";
      try {
        installed = runCapture(tool, ["--version"]).split("\n")[0].trim();
      } catch {
        // version lookup failing doesn't block the report
      }
      const foundSuffix = installed ? `, found: ${installed}` : " (tool does not report a version string)";
      ok(`${tool} installed (pinned: ${pinned}${foundSuffix})`);
    } else {
      warn(`${tool} not installed (run setup to install)`);
    }
  }

  console.log("\n--- PATH health ---");
  const pathEntries = (process.env.PATH || "").split(path.delimiter);
  const hasOpenCode = pathEntries.some(
    (p) => fs.existsSync(path.join(p, "opencode")) || fs.existsSync(path.join(p, "opencode.cmd"))
  );
  const hasNode = pathEntries.some(
    (p) => fs.existsSync(path.join(p, "node")) || fs.existsSync(path.join(p, "node.exe"))
  );
  if (hasOpenCode) ok("opencode found on PATH");
  else warn("opencode not found on PATH (not installed yet?)");
  if (hasNode) ok("node found on PATH");
  else warn("node not found on PATH");

  console.log("\n--- Directories ---");
  const dirs = resolveGlobalDirs();
  for (const dir of [dirs.config, dirs.data, dirs.cache, dirs.backupRoot]) {
    if (fs.existsSync(dir)) {
      try {
        fs.accessSync(dir, fs.constants.W_OK);
        ok(`${dir} (exists, writable)`);
      } catch {
        fail(`${dir} (exists, NOT writable)`);
        allGreen = false;
      }
    } else {
      warn(`${dir} (does not exist yet — created on first setup)`);
    }
  }

  console.log("\n--- Project config ---");
  if (fs.existsSync(path.join(rootDir, "opencode.jsonc"))) {
    ok("opencode.jsonc present");
  } else {
    warn("opencode.jsonc missing (run setup to generate)");
  }
  if (fs.existsSync(path.join(rootDir, ".opencode", "skills", "frontend-design", "SKILL.md"))) {
    ok(".opencode/skills populated");
  } else {
    warn(".opencode/skills not populated (run setup to build)");
  }

  console.log("");
  if (allGreen) {
    console.log("All checks passed.");
  } else {
    console.error("One or more checks FAILED. See [FAIL] lines above.");
  }

  return allGreen;
}
