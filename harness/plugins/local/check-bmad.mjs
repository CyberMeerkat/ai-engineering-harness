// check-bmad.mjs — tool.execute.before enforcement plugin.
//
// Fires once per session per project when an agent attempts the first
// file-modifying operation (write/edit/patch) in a git repo that doesn't
// have BMAD installed (_bmad/ absent). Throws with the exact install
// command and customization steps so the agent can act immediately.
//
// Fires ONCE then stays silent for the rest of the session — the agent
// is trusted to either install BMAD or confirm with the user that this
// project is out of scope. Re-check happens on the next session.
//
// Override: prefix any command with HARNESS_SKIP_BMAD_CHECK=1 to suppress
// for cases where the user has explicitly opted out of BMAD for this project.

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const MODIFYING_TOOLS = new Set(["write", "edit", "patch"]);

// Per-session, per-project-root tracking. Module-level so it survives
// across tool calls within a single OpenCode session.
const warnedRoots = new Set();

function getGitRoot(cwd) {
  try {
    return execFileSync("git", ["rev-parse", "--show-toplevel"], {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return null; // not a git repo
  }
}

function hasBmad(projectRoot) {
  return fs.existsSync(path.join(projectRoot, "_bmad"));
}

function hasOverride(command = "") {
  return command.includes("HARNESS_SKIP_BMAD_CHECK=1");
}

export const CheckBmad = async ({ project, client, $, directory, worktree }) => {
  const cwd = worktree || directory;

  return {
    "tool.execute.before": async (input, output) => {
      if (!MODIFYING_TOOLS.has(input.tool)) return;

      // Honour explicit opt-out on bash commands
      if (input.tool === "bash" && hasOverride(output.args?.command || "")) return;

      const projectRoot = getGitRoot(cwd);
      if (!projectRoot) return; // not a git repo — skip check

      if (warnedRoots.has(projectRoot)) return; // already warned this session

      if (hasBmad(projectRoot)) return; // BMAD is installed

      warnedRoots.add(projectRoot);

      const CUSTOM_URL =
        "https://raw.githubusercontent.com/CyberMeerkat/ai-engineering-harness/main/harness/bmad/custom";

      const CUSTOM_FILES = [
        "config.toml",
        "bmad-agent-analyst.toml",
        "bmad-agent-pm.toml",
        "bmad-agent-ux-designer.toml",
        "bmad-agent-architect.toml",
        "bmad-agent-dev.toml",
      ];

      throw new Error(
        `BMAD NOT INSTALLED — no _bmad/ found at ${projectRoot}.\n\n` +
        `Every project in this harness requires BMAD before code is written. ` +
        `Install it now, then apply the harness team customizations.\n\n` +
        `Step 1 — Install BMAD (run from ${projectRoot}):\n` +
        `  npx bmad-method install --tools opencode --yes\n\n` +
        `Step 2 — Apply harness team customizations (bash):\n` +
        `  CUSTOM_URL="${CUSTOM_URL}"\n` +
        `  mkdir -p _bmad/custom\n` +
        `  for f in ${CUSTOM_FILES.join(" ")}; do\n` +
        `    curl -fsSL "$CUSTOM_URL/$f" -o "_bmad/custom/$f"\n` +
        `  done\n\n` +
        `  # Note: BMAD creates its own _bmad/custom/config.toml on install.\n` +
        `  # The curl above overwrites it with the harness version — this is correct.\n\n` +
        `Step 2 — Apply harness team customizations (PowerShell):\n` +
        `  $base = "${CUSTOM_URL}"\n` +
        `  New-Item -ItemType Directory -Force -Path "_bmad/custom" | Out-Null\n` +
        `  @(${CUSTOM_FILES.map((f) => `"${f}"`).join(", ")}) | ForEach-Object {\n` +
        `    Invoke-WebRequest "$base/$_" -OutFile "_bmad/custom/$_" -ErrorAction Stop\n` +
        `  }\n\n` +
        `If the user has confirmed this project does not use BMAD, ` +
        `prefix your next command with HARNESS_SKIP_BMAD_CHECK=1 to suppress this warning for the rest of the session.`
      );
    },
  };
};
