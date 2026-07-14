// backup.mjs — backup-before-overwrite and retention (keep newest N) logic.
// Single-sourced version of the bash backup_dir_if_exists/prune_old_backups
// functions and the PowerShell Invoke-BackupRetention function.

import fs from "node:fs";
import path from "node:path";
import { action } from "./platform.mjs";

/**
 * Copies `sourceDir` into `<backupRoot>/<timestamp>/<name>` if sourceDir
 * exists. No-op (but still logs under dry-run) if it doesn't.
 */
export async function backupDirIfExists(dryRun, sourceDir, backupRoot, timestamp, name) {
  if (!fs.existsSync(sourceDir)) return;

  const backupDir = path.join(backupRoot, timestamp);
  const target = path.join(backupDir, name);

  await action(dryRun, `backup ${sourceDir} -> ${target}`, () => {
    fs.mkdirSync(backupDir, { recursive: true });
    fs.cpSync(sourceDir, target, { recursive: true });
  });
}

/**
 * Keeps the newest `keep` timestamped subdirectories under backupRoot,
 * deleting older ones. Directory names are expected to sort correctly as
 * strings (yyyyMMdd-HHmmss format), same convention as the previous
 * bash/PowerShell implementations.
 */
export async function pruneOldBackups(dryRun, backupRoot, keep = 5) {
  if (!fs.existsSync(backupRoot)) return;

  const entries = fs
    .readdirSync(backupRoot, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort(); // ascending — oldest first, since timestamps are zero-padded and lexicographically sortable

  if (entries.length <= keep) return;

  const toRemove = entries.slice(0, entries.length - keep);
  for (const name of toRemove) {
    const fullPath = path.join(backupRoot, name);
    console.error(`backup retention: removing old backup ${fullPath}`);
    await action(dryRun, `remove old backup ${fullPath}`, () => {
      fs.rmSync(fullPath, { recursive: true, force: true });
    });
  }
}

/**
 * Returns a yyyyMMdd-HHmmss timestamp string, same format as the previous
 * `date +%Y%m%d-%H%M%S` (bash) / `Get-Date -Format 'yyyyMMdd-HHmmss'` (ps1).
 */
export function makeTimestamp(date = new Date()) {
  const pad = (n) => String(n).padStart(2, "0");
  return (
    `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-` +
    `${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`
  );
}

/**
 * Finds the newest timestamped subdirectory under backupRoot. Returns null
 * if backupRoot doesn't exist or has no subdirectories.
 */
export function findNewestBackup(backupRoot) {
  if (!fs.existsSync(backupRoot)) return null;

  const entries = fs
    .readdirSync(backupRoot, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  if (entries.length === 0) return null;
  return path.join(backupRoot, entries[entries.length - 1]);
}
