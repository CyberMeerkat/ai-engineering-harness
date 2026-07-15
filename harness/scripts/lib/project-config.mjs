// project-config.mjs — builds project-local opencode.jsonc, the global
// OpenCode app bundle, and copies skills + local plugins.
// Consolidates build-project-opencode.sh (bash) and Write-ProjectConfig
// (PowerShell) into one implementation. Native JSON.parse/stringify means
// no python3 dependency, unlike the original bash implementation.

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { action } from "./platform.mjs";
import { backupDirIfExists, pruneOldBackups, makeTimestamp } from "./backup.mjs";

/** Resolves the global OpenCode config/data/cache directories, honouring
 * the same env var overrides as the original implementations. */
export function resolveGlobalDirs() {
  const home = os.homedir();
  return {
    config: process.env.OPENCODE_CONFIG_DIR || path.join(home, ".config", "opencode"),
    data: process.env.OPENCODE_DATA_DIR || path.join(home, ".local", "share", "opencode"),
    cache: path.join(process.env.XDG_CACHE_HOME || path.join(home, ".cache"), "opencode"),
    backupRoot: path.join(home, ".config", "opencode-harness-backups"),
  };
}

/**
 * Renders the opencode template into either a minimal project config or
 * the full global config (with mcp + plugin injected from the manifest).
 * `ruleFileNames` (global mode only) is the list of rule .md filenames
 * already copied to ~/.config/opencode/rules/ by the caller — passed in
 * rather than read here since this function only sees the template path,
 * not the repo root.
 */
function renderTemplate(templatePath, manifest, mode, ruleFileNames = []) {
  const template = JSON.parse(fs.readFileSync(templatePath, "utf8"));

  if (mode === "global") {
    const mcp = {};
    for (const [name, value] of Object.entries(manifest.sharedMcp || {})) {
      const config = { type: value.type };
      if (value.command) config.command = value.command;
      if (value.url) config.url = value.url;
      if ("enabledByDefault" in value) config.enabled = Boolean(value.enabledByDefault);
      if (value.oauth) config.oauth = {};
      mcp[name] = config;
    }
    template.mcp = mcp;
    template.plugin = manifest.opencode?.plugins || [];

    if (manifest.opencode?.globalPermission) {
      template.permission = manifest.opencode.globalPermission;
    }

    if (ruleFileNames.length > 0) {
      // Relative to this config file's own directory (~/.config/opencode/),
      // so "rules/<name>.md" resolves correctly regardless of which
      // project the user currently has open.
      template.instructions = ruleFileNames.map((name) => `rules/${name}`);
    }
  }

  return template;
}

function writeJson(filePath, data) {
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + "\n");
}

/** Ensures harness/.env.team exists, seeding from the example template. */
async function ensureEnvFile(dryRun, rootDir) {
  const envFile = path.join(rootDir, "harness", ".env.team");
  const example = path.join(rootDir, "harness", "templates", ".env.team.example");
  if (fs.existsSync(envFile)) return;
  await action(dryRun, `copy .env.team.example -> .env.team`, () => {
    fs.copyFileSync(example, envFile);
  });
}

/** Copies every subdirectory under sourceRoot into targetRoot (skills). */
async function copySkillsFlat(dryRun, sourceRoot, targetRoot) {
  if (!fs.existsSync(sourceRoot)) return;
  const entries = fs.readdirSync(sourceRoot, { withFileTypes: true }).filter((e) => e.isDirectory());
  for (const entry of entries) {
    await action(dryRun, `copy skill ${entry.name}`, () => {
      fs.cpSync(path.join(sourceRoot, entry.name), path.join(targetRoot, entry.name), {
        recursive: true,
      });
    });
  }
}

/** Copies every .mjs/.js file under sourceRoot into targetRoot (plugins). */
async function copyPluginsFlat(dryRun, sourceRoot, targetRoot) {
  if (!fs.existsSync(sourceRoot)) return;
  const entries = fs
    .readdirSync(sourceRoot, { withFileTypes: true })
    .filter((e) => e.isFile() && /\.(mjs|js)$/.test(e.name));
  for (const entry of entries) {
    await action(dryRun, `copy plugin ${entry.name}`, () => {
      fs.copyFileSync(path.join(sourceRoot, entry.name), path.join(targetRoot, entry.name));
    });
  }
}

/**
 * Copies every .md file under sourceRoot into targetRoot (always-loaded
 * rules), except README.md — that's meta-documentation about the folder
 * itself, not model-facing instruction content, and would otherwise get
 * loaded into every session's context by mistake.
 */
async function copyRulesFlat(dryRun, sourceRoot, targetRoot) {
  if (!fs.existsSync(sourceRoot)) return [];
  const entries = fs
    .readdirSync(sourceRoot, { withFileTypes: true })
    .filter((e) => e.isFile() && /\.md$/.test(e.name) && e.name.toLowerCase() !== "readme.md");
  for (const entry of entries) {
    await action(dryRun, `copy rule ${entry.name}`, () => {
      fs.copyFileSync(path.join(sourceRoot, entry.name), path.join(targetRoot, entry.name));
    });
  }
  return entries.map((e) => e.name);
}

/**
 * Main entry point — builds the project-local opencode.jsonc + .opencode/,
 * and the global OpenCode app bundle (~/.config/opencode/). Mirrors
 * build-project-opencode.sh / Write-ProjectConfig exactly, including the
 * backup-before-overwrite + retention behaviour and incremental vs reset
 * modes.
 */
export async function buildProjectConfig(dryRun, mode, rootDir, manifest, retentionCount = 5) {
  const projectOpencodeDir = path.join(rootDir, ".opencode");
  const dirs = resolveGlobalDirs();
  const timestamp = makeTimestamp();

  await ensureEnvFile(dryRun, rootDir);

  const templatePath = path.join(rootDir, "harness", "templates", "opencode.template.jsonc");

  // 1. project-local opencode.jsonc (no mcp/plugin injection)
  await action(dryRun, `write ${path.join(rootDir, "opencode.jsonc")}`, () => {
    const projectTemplate = renderTemplate(templatePath, manifest, "project");
    writeJson(path.join(rootDir, "opencode.jsonc"), projectTemplate);
  });

  // 2. backup existing global state (always, regardless of mode)
  await backupDirIfExists(dryRun, dirs.config, dirs.backupRoot, timestamp, "config");
  await backupDirIfExists(dryRun, dirs.data, dirs.backupRoot, timestamp, "data");
  await backupDirIfExists(dryRun, dirs.cache, dirs.backupRoot, timestamp, "cache");

  // 3. reset mode wipes global state; incremental mode leaves it in place
  //    (render/copy steps below overwrite the relevant files either way)
  if (mode === "reset") {
    for (const dir of [dirs.config, dirs.data, dirs.cache]) {
      await action(dryRun, `remove ${dir} (reset mode)`, () => {
        fs.rmSync(dir, { recursive: true, force: true });
      });
    }
  }

  await pruneOldBackups(dryRun, dirs.backupRoot, retentionCount);

  await action(dryRun, `create ${dirs.config}`, () => {
    fs.mkdirSync(dirs.config, { recursive: true });
  });

  // 4. always-loaded rules: clear then repopulate, before rendering the
  //    global config below (which needs the resulting filenames for
  //    `instructions`).
  const globalRules = path.join(dirs.config, "rules");
  await action(dryRun, "clear existing global rules", () => {
    if (fs.existsSync(globalRules)) fs.rmSync(globalRules, { recursive: true, force: true });
    fs.mkdirSync(globalRules, { recursive: true });
  });
  let ruleFileNames = [];
  for (const sourceRel of manifest.opencode?.rulesSources || []) {
    const copied = await copyRulesFlat(dryRun, path.join(rootDir, sourceRel), globalRules);
    ruleFileNames = ruleFileNames.concat(copied);
  }

  // 5. global opencode.json (with mcp/plugin/permission/instructions injection)
  await action(dryRun, `write global opencode.json`, () => {
    const globalTemplate = renderTemplate(templatePath, manifest, "global", ruleFileNames);
    writeJson(path.join(dirs.config, "opencode.json"), globalTemplate);
  });

  // 6. skills: clear then repopulate from manifest-declared sources
  const projectSkills = path.join(projectOpencodeDir, "skills");
  const globalSkills = path.join(dirs.config, "skills");

  await action(dryRun, "create skills dirs", () => {
    fs.mkdirSync(projectSkills, { recursive: true });
    fs.mkdirSync(globalSkills, { recursive: true });
  });
  await action(dryRun, "clear existing project skills", () => {
    if (fs.existsSync(projectSkills)) fs.rmSync(projectSkills, { recursive: true, force: true });
    fs.mkdirSync(projectSkills, { recursive: true });
  });
  await action(dryRun, "clear existing global skills", () => {
    if (fs.existsSync(globalSkills)) fs.rmSync(globalSkills, { recursive: true, force: true });
    fs.mkdirSync(globalSkills, { recursive: true });
  });

  for (const sourceRel of manifest.opencode?.projectSkillsSources || []) {
    await copySkillsFlat(dryRun, path.join(rootDir, sourceRel), projectSkills);
  }
  for (const sourceRel of manifest.opencode?.globalSkillsSources || []) {
    await copySkillsFlat(dryRun, path.join(rootDir, sourceRel), globalSkills);
  }

  // 7. local plugins: global only (see harness/plugins/README.md for why)
  const globalPlugins = path.join(dirs.config, "plugins");
  await action(dryRun, "clear existing global plugins", () => {
    if (fs.existsSync(globalPlugins)) fs.rmSync(globalPlugins, { recursive: true, force: true });
    fs.mkdirSync(globalPlugins, { recursive: true });
  });
  for (const sourceRel of manifest.opencode?.localPluginsSources || []) {
    await copyPluginsFlat(dryRun, path.join(rootDir, sourceRel), globalPlugins);
  }

  console.log(`built ${path.join(rootDir, "opencode.jsonc")}`);
  console.log(`built ${projectOpencodeDir}`);
  console.log(`built ${path.join(dirs.config, "opencode.json")}`);
  console.log(`built ${globalRules}`);
  console.log(`built ${globalSkills}`);
  console.log(`built ${globalPlugins}`);

  if (!dryRun && fs.existsSync(path.join(dirs.backupRoot, timestamp))) {
    console.log(`backed up prior global OpenCode state to ${path.join(dirs.backupRoot, timestamp)}`);
  }
}
