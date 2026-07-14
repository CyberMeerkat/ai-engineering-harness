// platform.mjs — cross-platform helpers shared by every lib/*.mjs module.
// Single source of truth for "does this command exist" and "run this command"
// so install logic doesn't reimplement platform detection per-module.

import { execFileSync, spawnSync } from "node:child_process";

export const isWindows = process.platform === "win32";
export const isMac = process.platform === "darwin";
export const isLinux = process.platform === "linux";

/**
 * Returns true if `cmd` is resolvable on PATH.
 * Windows: `where cmd`. Unix: `command -v cmd` (via sh -c, since command
 * is a shell builtin, not a standalone executable).
 */
export function commandExists(cmd) {
  try {
    if (isWindows) {
      execFileSync("where", [cmd], { stdio: "ignore" });
    } else {
      execFileSync("sh", ["-c", `command -v ${cmd}`], { stdio: "ignore" });
    }
    return true;
  } catch {
    return false;
  }
}

/**
 * Runs `cmd` and returns trimmed stdout as a string. Throws on non-zero exit.
 *
 * On Windows, shell:true is used by default: npm/scoop/choco frequently
 * install CLI shims as .cmd/.bat files, which are not directly executable
 * the way a .exe is — Node's execFileSync/spawnSync fail with EINVAL on
 * them unless a shell (cmd.exe) is used to interpret the file. Unix targets
 * don't have this problem and default to shell:false to avoid the (low but
 * nonzero) shell-quoting/injection surface that shell:true adds.
 */
export function runCapture(cmd, args = [], options = {}) {
  const result = spawnSync(cmd, args, {
    encoding: "utf8",
    shell: isWindows,
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const err = new Error(
      `${cmd} ${args.join(" ")} exited ${result.status}\n${result.stderr || ""}`
    );
    err.status = result.status;
    err.stdout = result.stdout;
    err.stderr = result.stderr;
    throw err;
  }
  return (result.stdout || "").trim();
}

/**
 * Runs `cmd` with inherited stdio (so output streams live to the terminal),
 * for real installs where the user should see progress. Throws on non-zero
 * exit unless `allowFailure` is set. Same Windows shell:true default as
 * runCapture, for the same .cmd/.bat shim reason.
 */
export function runInherit(cmd, args = [], options = {}) {
  const result = spawnSync(cmd, args, {
    stdio: "inherit",
    shell: isWindows,
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0 && !options.allowFailure) {
    const err = new Error(`${cmd} ${args.join(" ")} exited ${result.status}`);
    err.status = result.status;
    throw err;
  }
  return result.status;
}

/**
 * Returns true if running `cmd` with the given args exits 0. Swallows all
 * errors (missing command, non-zero exit, EINVAL on Windows .cmd shims —
 * this function handles the shell:true requirement so callers don't need
 * to know about it). Used for "is this CLI tool installed and working"
 * checks (e.g. `opencode --help`).
 */
export function commandRuns(cmd, args = ["--help"]) {
  try {
    runCapture(cmd, args, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

/**
 * dry-run-aware action wrapper. When dryRun is true, prints the description
 * and returns without calling fn. Mirrors the run()/Invoke-Action pattern
 * from the previous bash/PowerShell implementations, now single-sourced.
 */
export async function action(dryRun, description, fn) {
  if (dryRun) {
    console.log(`[dry-run] ${description}`);
    return undefined;
  }
  return await fn();
}
