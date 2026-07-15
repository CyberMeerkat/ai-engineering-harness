// protect-branches.mjs — tool.execute.before enforcement plugin.
//
// Scope (intentionally narrow — see harness/rules/branching.md for the full
// policy this backstops):
//
//   1. `git merge` while the CURRENT branch is protected. The relevant
//      condition here ("what branch am I on") is never present in the merge
//      command's own text, so OpenCode's declarative permission.bash
//      pattern matching cannot express this at all, in any form. This check
//      always runs through this plugin.
//
//   2. `git push` with NO explicit destination branch (e.g. bare `git push`
//      or `git push origin`), when that implicit push resolves to a
//      protected branch. Declarative permission.bash rules like
//      `"git push * develop": "ask"` correctly catch EXPLICIT protected
//      pushes with real ask/once/always/reject UX (see stack/manifest.json)
//      — this plugin deliberately does NOT re-check the explicit case, so
//      it never fights with a user's answer to that native prompt.
//
// Auto-detects whether the repo actually uses this branching model (checks
// for a `develop` branch, locally or on a remote) and no-ops entirely if
// not, so this doesn't interfere with repos using a different flow.
//
// Neither case can trigger OpenCode's native "ask" dialog (plugins can only
// block or allow — see harness/plugins/README.md for why). Blocking with a
// clear message that explains how to proceed is the closest equivalent a
// plugin can offer.

import { execFileSync } from "node:child_process";

const DEFAULT_PROTECTED_BRANCHES = ["develop", "dev", "staging", "stable", "main"];
const OVERRIDE_PREFIX = "HARNESS_ALLOW_PROTECTED_OP=1";

function getProtectedBranches() {
  const override = process.env.HARNESS_PROTECTED_BRANCHES;
  if (override) {
    return override
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
  }
  return DEFAULT_PROTECTED_BRANCHES;
}

function hasOverride(command) {
  return command.trim().startsWith(OVERRIDE_PREFIX);
}

function gitCapture(args, cwd) {
  try {
    return execFileSync("git", args, { cwd, encoding: "utf8" }).trim();
  } catch {
    return null;
  }
}

/** True if the repo has a `develop` branch, locally or on any remote. */
function repoUsesGitflow(cwd) {
  if (gitCapture(["branch", "--list", "develop"], cwd)) return true;
  if (gitCapture(["branch", "-r", "--list", "*/develop"], cwd)) return true;
  return false;
}

function getCurrentBranch(cwd) {
  return gitCapture(["rev-parse", "--abbrev-ref", "HEAD"], cwd);
}

/** Splits a compound shell command into segments on &&, ;, ||, |. */
function splitCompound(command) {
  return command
    .split(/&&|\|\||;|\|/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function isGitSubcommand(segment, subcommand) {
  const tokens = segment.split(/\s+/);
  return tokens[0] === "git" && tokens[1] === subcommand;
}

/**
 * Parses `git push [flags] [remote] [refspec]`. Returns { explicit, branch }
 * — explicit is false for bare `git push` / `git push <remote>` (no
 * refspec given, target depends on the current branch's tracked upstream).
 */
function parsePushTarget(segment) {
  const tokens = segment.split(/\s+/).slice(2); // drop "git" "push"
  const positional = tokens.filter((t) => !t.startsWith("-"));

  if (positional.length < 2) {
    return { explicit: false, branch: null };
  }

  const refspec = positional[1];
  if (refspec.includes(":")) {
    const dest = refspec.split(":")[1];
    return dest ? { explicit: true, branch: dest } : { explicit: false, branch: null }; // "branch:" is a delete, not protected-relevant
  }
  return { explicit: true, branch: refspec };
}

function implicitPushError(branch, command) {
  return new Error(
    `CONFIRM NEEDED: this push has no explicit destination branch, and resolves to the protected branch '${branch}' via your current checkout.\n` +
      `Command: ${command}\n\n` +
      `Re-run with the branch named explicitly (e.g. "git push origin ${branch}") so this is handled as a normal confirmation, or ask the user first. If they've already said yes, prefix with ${OVERRIDE_PREFIX}:\n` +
      `  ${OVERRIDE_PREFIX} git push origin ${branch}`
  );
}

function mergeError(branch, command) {
  return new Error(
    `CONFIRM NEEDED: you are on the protected branch '${branch}' and about to merge into it.\n` +
      `Command: ${command}\n\n` +
      `Ask the user for explicit go-ahead first. If they've already said yes in this conversation, re-run prefixed with ${OVERRIDE_PREFIX} to proceed:\n` +
      `  ${OVERRIDE_PREFIX} ${command}`
  );
}

export const ProtectBranches = async ({ project, client, $, directory, worktree }) => {
  const cwd = worktree || directory;

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return;

      const rawCommand = output.args?.command || "";
      if (!rawCommand.trim()) return;
      if (hasOverride(rawCommand)) return;

      // Cheap pre-filter before doing any git subprocess calls.
      if (!/\bgit\s+(push|merge)\b/.test(rawCommand)) return;

      let gitflowChecked = false;
      let usesGitflow = false;
      const protectedBranches = getProtectedBranches();

      for (const segment of splitCompound(rawCommand)) {
        const isPush = isGitSubcommand(segment, "push");
        const isMerge = isGitSubcommand(segment, "merge");
        if (!isPush && !isMerge) continue;

        if (!gitflowChecked) {
          usesGitflow = repoUsesGitflow(cwd);
          gitflowChecked = true;
        }
        if (!usesGitflow) continue;

        if (isPush) {
          const { explicit, branch } = parsePushTarget(segment);
          if (explicit) continue; // deliberately deferred to permission.bash "ask" rules

          const currentBranch = getCurrentBranch(cwd);
          if (currentBranch && protectedBranches.includes(currentBranch)) {
            throw implicitPushError(currentBranch, segment);
          }
        }

        if (isMerge) {
          const currentBranch = getCurrentBranch(cwd);
          if (currentBranch && protectedBranches.includes(currentBranch)) {
            throw mergeError(currentBranch, segment);
          }
        }
      }
    },
  };
};
