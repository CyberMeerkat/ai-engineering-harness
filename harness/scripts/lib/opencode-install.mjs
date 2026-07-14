// opencode-install.mjs — OpenCode CLI + desktop app installation.
// Consolidates install-opencode.sh (bash) and Install-OpenCode/
// Install-OpenCodeDesktop (PowerShell) into one implementation.

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { commandExists, commandRuns, runInherit, isWindows, isMac, action } from "./platform.mjs";

/**
 * Returns true if the `opencode` command exists AND actually runs
 * (--help or --version exits 0). A present-but-broken install (e.g. after
 * an interrupted upgrade) is treated as "not working".
 */
export function isOpenCodeRunnable() {
  if (!commandExists("opencode")) return false;
  return commandRuns("opencode", ["--help"]) || commandRuns("opencode", ["--version"]);
}

/**
 * Installs the OpenCode CLI if not already present and runnable. Tries, in
 * order: brew (mac/linux) -> scoop/choco (windows) -> npm -> bun -> pnpm ->
 * yarn. Mirrors the fallback chain from the original bash/PowerShell
 * implementations exactly.
 */
export async function installOpenCode(dryRun, versions) {
  if (isOpenCodeRunnable()) {
    console.log("opencode already installed");
    return;
  }

  if (dryRun) {
    console.log(
      "[dry-run] opencode not installed; would install via brew/scoop/choco/npm/bun/pnpm/yarn"
    );
    return;
  }

  const npmVersion = versions.opencode.npm;

  if ((isMac || process.platform === "linux") && commandExists("brew")) {
    runInherit("brew", ["install", "anomalyco/tap/opencode"]);
    return;
  }
  if (isWindows && commandExists("scoop")) {
    runInherit("scoop", ["install", "opencode"]);
    return;
  }
  if (isWindows && commandExists("choco")) {
    runInherit("choco", ["install", "opencode", "-y"]);
    return;
  }
  if (commandExists("npm")) {
    runInherit("npm", ["install", "-g", `opencode-ai@${npmVersion}`]);
    return;
  }
  if (commandExists("bun")) {
    runInherit("bun", ["install", "-g", `opencode-ai@${npmVersion}`]);
    return;
  }
  if (commandExists("pnpm")) {
    runInherit("pnpm", ["install", "-g", `opencode-ai@${npmVersion}`]);
    return;
  }
  if (commandExists("yarn")) {
    runInherit("yarn", ["global", "add", `opencode-ai@${npmVersion}`]);
    return;
  }

  throw new Error(
    "Unable to install OpenCode automatically. Install Homebrew or a supported Node package manager first."
  );
}

/** Resolves the expected OpenCode Desktop install path per platform. */
export function resolveDesktopPath() {
  if (isMac) {
    const candidates = [
      "/Applications/OpenCode.app",
      path.join(os.homedir(), "Applications", "OpenCode.app"),
    ];
    return candidates.find((p) => fs.existsSync(p)) || null;
  }
  if (isWindows) {
    const candidates = [
      path.join(process.env.LOCALAPPDATA || "", "OpenCode", "OpenCode.exe"),
      path.join(process.env.LOCALAPPDATA || "", "Programs", "OpenCode", "OpenCode.exe"),
      path.join(process.env.LOCALAPPDATA || "", "Programs", "opencode", "OpenCode.exe"),
      path.join(process.env.ProgramFiles || "", "OpenCode", "OpenCode.exe"),
      path.join(process.env.ProgramFiles || "", "opencode", "OpenCode.exe"),
      path.join(process.env["ProgramFiles(x86)"] || "", "OpenCode", "OpenCode.exe"),
      path.join(process.env["ProgramFiles(x86)"] || "", "opencode", "OpenCode.exe"),
    ];
    const direct = candidates.find((p) => fs.existsSync(p));
    if (direct) return direct;

    // Fallback: recursive search under LOCALAPPDATA / ProgramFiles / ProgramFiles(x86)
    // for any OpenCode.exe, regardless of the parent folder naming convention
    // (e.g. an install under a scoped npm-style folder like
    // "Programs\@opencode-aidesktop\OpenCode.exe"). Ports the same fallback
    // the original PowerShell Resolve-OpenCodeDesktopPath had — without this,
    // non-standard install locations are silently missed and the installer
    // would try to redundantly reinstall over a working install.
    const searchRoots = [
      process.env.LOCALAPPDATA,
      process.env.ProgramFiles,
      process.env["ProgramFiles(x86)"],
    ].filter((p) => p && fs.existsSync(p));

    for (const root of searchRoots) {
      const found = findFileRecursive(root, /^opencode\.exe$/i, 6);
      if (found) return found;
    }
    return null;
  }
  return null; // no desktop app on Linux
}

/**
 * Bounded-depth recursive file search — Node has no built-in equivalent of
 * PowerShell's `Get-ChildItem -Recurse -Filter`. Depth-limited (default 6)
 * to avoid pathologically slow walks under something like Program Files.
 * Returns the first match's full path, or null.
 */
function findFileRecursive(root, namePattern, maxDepth) {
  const stack = [{ dir: root, depth: 0 }];
  while (stack.length > 0) {
    const { dir, depth } = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue; // permission denied or similar — skip
    }
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isFile() && namePattern.test(entry.name)) {
        return fullPath;
      }
      if (entry.isDirectory() && depth < maxDepth) {
        stack.push({ dir: fullPath, depth: depth + 1 });
      }
    }
  }
  return null;
}

/**
 * Installs the OpenCode desktop app on macOS/Windows if not already present.
 * No-op on Linux (matches original bash behaviour: `[ "$(uname -s)" =
 * "Darwin" ] || return 0` — Windows desktop install lived only in setup.ps1
 * previously; now both platforms are handled in one place).
 */
export async function installOpenCodeDesktop(dryRun, versions) {
  if (!isMac && !isWindows) return;

  const existing = resolveDesktopPath();
  if (existing) {
    console.log(`OpenCode desktop already installed (${existing})`);
    return;
  }

  if (dryRun) {
    console.log("[dry-run] OpenCode desktop not installed; would download and install it");
    return;
  }

  const version = versions.opencode.desktop.version;
  const arch = os.arch() === "arm64" ? "arm64" : "x64";

  if (isMac) {
    await installDesktopMac(version, arch, versions);
  } else {
    await installDesktopWindows(version, arch, versions);
  }

  const installed = resolveDesktopPath();
  if (!installed) {
    throw new Error(
      "OpenCode desktop install completed, but the desktop app was not found in the expected install location."
    );
  }
  console.log(`OpenCode desktop installed (${installed})`);
}

async function installDesktopMac(version, arch, versions) {
  const asset = versions.opencode.desktop.macos[arch];
  const url = `https://github.com/anomalyco/opencode/releases/download/v${version}/${asset}`;
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-desktop-"));
  const dmgPath = path.join(tmpDir, asset);
  const mountPoint = path.join(tmpDir, "mount");

  console.log(`Installing OpenCode desktop (${asset})`);
  await downloadFile(url, dmgPath);

  fs.mkdirSync(mountPoint, { recursive: true });
  runInherit("hdiutil", ["attach", dmgPath, "-mountpoint", mountPoint, "-nobrowse"]);
  try {
    let appTargetDir = "/Applications";
    if (!isWritable(appTargetDir)) {
      appTargetDir = path.join(os.homedir(), "Applications");
      fs.mkdirSync(appTargetDir, { recursive: true });
    }
    fs.cpSync(path.join(mountPoint, "OpenCode.app"), path.join(appTargetDir, "OpenCode.app"), {
      recursive: true,
    });
  } finally {
    runInherit("hdiutil", ["detach", mountPoint], { allowFailure: true });
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }
}

async function installDesktopWindows(version, arch, versions) {
  const asset = versions.opencode.desktop.windows[arch];
  const url = `https://github.com/anomalyco/opencode/releases/download/v${version}/${asset}`;
  const installerPath = path.join(os.tmpdir(), asset);

  console.log(`Installing OpenCode desktop (${asset})`);
  await downloadFile(url, installerPath);

  runInherit(installerPath, ["/S"]);
  fs.rmSync(installerPath, { force: true });
}

function isWritable(dir) {
  try {
    fs.accessSync(dir, fs.constants.W_OK);
    return true;
  } catch {
    return false;
  }
}

/** Downloads `url` to `destPath` using native fetch (no curl dependency). */
async function downloadFile(url, destPath) {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Download failed: ${url} -> HTTP ${res.status}`);
  }
  const buffer = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(destPath, buffer);
}
