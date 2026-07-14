#!/usr/bin/env node
// setup.mjs — main orchestrator for the ai-engineering-harness installer.
//
// This is the single source of truth for install logic. The thin
// setup.sh / setup.ps1 launchers only bootstrap a working Node.js runtime
// (the one thing that has to happen before this script can run at all),
// then exec this file with the user's original arguments.
//
// Consolidates what were previously two independently-maintained,
// occasionally-drifting implementations (bash + PowerShell) into one.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { reportPrereqs } from "./lib/prereqs.mjs";
import { installOpenCode, installOpenCodeDesktop } from "./lib/opencode-install.mjs";
import { installMcpDeps } from "./lib/mcp-install.mjs";
import { buildProjectConfig } from "./lib/project-config.mjs";
import { validateSetup, ValidationError } from "./lib/validate.mjs";
import { uninstall } from "./lib/uninstall.mjs";
import { runDoctor } from "./lib/doctor.mjs";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const HARNESS_DIR = path.dirname(SCRIPT_DIR);
const ROOT_DIR = path.dirname(HARNESS_DIR);
const VERSIONS_PATH = path.join(ROOT_DIR, "versions.json");
const MANIFEST_PATH = path.join(ROOT_DIR, "stack", "manifest.json");

const HELP_TEXT = `Usage: node harness/scripts/setup.mjs [options]
(normally invoked via ./setup.sh or .\\setup.ps1, not directly)

Options:
  --dry-run       Print actions without executing them.
  --incremental   Update in place, keep global OpenCode state (default).
  --reset         Wipe global OpenCode config/data/cache before rebuild.
  --uninstall     Restore the newest backup and exit.
  --doctor        Run diagnostics and exit.
  -h, --help      Show this message.
`;

function parseArgs(argv) {
  const flags = {
    dryRun: false,
    mode: "incremental",
    uninstall: false,
    doctor: false,
    help: false,
  };

  for (const arg of argv) {
    switch (arg) {
      case "--dry-run":
        flags.dryRun = true;
        break;
      case "--reset":
        flags.mode = "reset";
        break;
      case "--incremental":
        flags.mode = "incremental";
        break;
      case "--uninstall":
        flags.uninstall = true;
        break;
      case "--doctor":
        flags.doctor = true;
        break;
      case "-h":
      case "--help":
        flags.help = true;
        break;
      default:
        console.error(`Unknown option: ${arg}`);
        process.exit(1);
    }
  }

  return flags;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

async function main() {
  const flags = parseArgs(process.argv.slice(2));

  if (flags.help) {
    console.log(HELP_TEXT);
    process.exit(0);
  }

  const versions = readJson(VERSIONS_PATH);

  // Prereq check always runs first, regardless of mode — fails fast before
  // any destructive action if npm (or, in principle, an inadequate Node) is
  // missing. Node itself is already guaranteed adequate by the launcher.
  reportPrereqs(versions.node.major);

  if (flags.uninstall) {
    try {
      await uninstall(flags.dryRun);
      process.exit(0);
    } catch (e) {
      console.error(e.message);
      process.exit(1);
    }
  }

  if (flags.doctor) {
    const allGreen = runDoctor(ROOT_DIR, versions);
    process.exit(allGreen ? 0 : 1);
  }

  const manifest = readJson(MANIFEST_PATH);

  console.log("==> Install OpenCode CLI");
  await installOpenCode(flags.dryRun, versions);

  console.log("==> Install OpenCode desktop (if needed)");
  await installOpenCodeDesktop(flags.dryRun, versions);

  console.log("==> Install MCP dependencies");
  await installMcpDeps(flags.dryRun, versions);

  console.log("==> Build OpenCode configs and skills");
  await buildProjectConfig(flags.dryRun, flags.mode, ROOT_DIR, manifest);

  if (!flags.dryRun) {
    console.log("==> Validate OpenCode setup");
    try {
      validateSetup(ROOT_DIR);
    } catch (e) {
      if (e instanceof ValidationError) {
        console.error(e.message);
        process.exit(1);
      }
      throw e;
    }
  } else {
    console.log("[dry-run] would run validation checks");
  }

  console.log("\nSetup complete.");
  console.log(`Next: review ${path.join(HARNESS_DIR, ".env.team")}, then run opencode from this repo root.`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
