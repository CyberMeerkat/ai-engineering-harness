// uninstall.mjs — restores the newest backup created by setup.
// Consolidates uninstall.sh (bash) / Invoke-Uninstall (PowerShell).

import fs from "node:fs";
import path from "node:path";
import { action } from "./platform.mjs";
import { findNewestBackup } from "./backup.mjs";
import { resolveGlobalDirs } from "./project-config.mjs";

/**
 * Restores ~/.config/opencode, ~/.local/share/opencode, and the OpenCode
 * cache dir from the newest available backup. Throws if no backup exists.
 */
export async function uninstall(dryRun) {
  const dirs = resolveGlobalDirs();
  const newest = findNewestBackup(dirs.backupRoot);

  if (!newest) {
    throw new Error("no backups found; nothing to uninstall");
  }

  console.log(`restoring from backup: ${newest}`);

  const restoreMap = {
    config: dirs.config,
    data: dirs.data,
    cache: dirs.cache,
  };

  for (const [backupName, dest] of Object.entries(restoreMap)) {
    const src = path.join(newest, backupName);
    if (!fs.existsSync(src)) {
      console.log(`skip ${backupName} (not in backup)`);
      continue;
    }

    await action(dryRun, `restore ${dest} from ${src}`, () => {
      if (fs.existsSync(dest)) fs.rmSync(dest, { recursive: true, force: true });
      fs.cpSync(src, dest, { recursive: true });
    });

    if (dryRun) {
      console.log(`[dry-run] would restore ${dest}`);
    } else {
      console.log(`restored ${dest}`);
    }
  }

  console.log("uninstall complete");
}
