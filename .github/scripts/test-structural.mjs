#!/usr/bin/env node
// test-structural.mjs — structural invariants for the harness.
//
// These are assertions about the SHAPE of the repo, not about behaviour. They run in
// milliseconds, make no network calls, and cost nothing — so they can run on every push
// without anybody weighing whether it is worth it.
//
// What they are for: the class of bug where two files that must agree quietly stop
// agreeing. A rule added to harness/rules/ but never listed in its README. A skill
// directory with no SKILL.md. A manifest pointing at a source directory that was
// renamed. None of these break a dry-run, so CI's existing jobs pass and the drift ships.
//
// Deliberately NOT here: anything requiring the network (see harness/scripts/
// check-versions.mjs) or a real OpenCode install (see the dry-run matrix job).
//
//   node .github/scripts/test-structural.mjs
//
// Exits 0 when every invariant holds, 1 otherwise.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..", "..");

let failures = 0;
let passes = 0;

function check(label, fn) {
  let result;
  try {
    result = fn();
  } catch (e) {
    console.error(`FAIL: ${label}\n      threw: ${e.message}`);
    failures++;
    return;
  }
  if (result === true || result === undefined) {
    console.log(`OK: ${label}`);
    passes++;
  } else {
    console.error(`FAIL: ${label}\n      ${result}`);
    failures++;
  }
}

/** Same contract as check(), for invariants that need to await (dynamic imports). */
async function checkAsync(label, fn) {
  let result;
  try {
    result = await fn();
  } catch (e) {
    console.error(`FAIL: ${label}\n      threw: ${e.message}`);
    failures++;
    return;
  }
  if (result === true || result === undefined) {
    console.log(`OK: ${label}`);
    passes++;
  } else {
    console.error(`FAIL: ${label}\n      ${result}`);
    failures++;
  }
}

function readJson(rel) {
  return JSON.parse(fs.readFileSync(path.join(REPO_ROOT, rel), "utf8"));
}

function listDirs(rel) {
  const full = path.join(REPO_ROOT, rel);
  if (!fs.existsSync(full)) return [];
  return fs
    .readdirSync(full, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name);
}

// ── versions.json ─────────────────────────────────────────────────────────────
console.log("\n--- versions.json ---");

const versions = readJson("versions.json");

check("versions.json declares a Node major", () =>
  Number.isInteger(versions?.node?.major) || "node.major must be an integer"
);

check("versions.json declares an opencode npm pin", () =>
  typeof versions?.opencode?.npm === "string" || "opencode.npm must be a string"
);

check("opencode npm pin and desktop version agree", () => {
  const npm = versions.opencode.npm;
  const desktop = versions.opencode.desktop?.version;
  // Two pins for one product drift the moment somebody bumps only the one they were
  // looking at. They install the same release; they must be the same string.
  return npm === desktop || `opencode.npm (${npm}) !== opencode.desktop.version (${desktop})`;
});

check("every version pin is exact, not a range", () => {
  const bad = [];
  const walk = (obj, trail) => {
    for (const [k, v] of Object.entries(obj ?? {})) {
      if (v && typeof v === "object") walk(v, `${trail}.${k}`);
      // "latest" is a deliberate non-pin; a caret/tilde/comparator is an unreviewed one.
      else if (typeof v === "string" && /^[\^~]|^[<>]=?/.test(v)) bad.push(`${trail}.${k} = "${v}"`);
    }
  };
  walk(versions.opencode, "opencode");
  walk(versions.mcp, "mcp");
  return bad.length === 0 || `range pins found: ${bad.join(", ")}`;
});

check("desktop asset names exist for both platforms and both arches", () => {
  const d = versions.opencode.desktop;
  const missing = [];
  for (const os of ["macos", "windows"]) {
    for (const arch of ["arm64", "x64"]) {
      if (!d?.[os]?.[arch]) missing.push(`${os}.${arch}`);
    }
  }
  return missing.length === 0 || `missing desktop assets: ${missing.join(", ")}`;
});

// ── stack/manifest.json ───────────────────────────────────────────────────────
console.log("\n--- stack/manifest.json ---");

const manifest = readJson("stack/manifest.json");

check("every declared source directory exists", () => {
  const keys = [
    "projectSkillsSources",
    "globalSkillsSources",
    "localPluginsSources",
    "globalAgentsSources",
    "rulesSources",
  ];
  const missing = [];
  for (const key of keys) {
    for (const rel of manifest.opencode?.[key] ?? []) {
      if (!fs.existsSync(path.join(REPO_ROOT, rel))) missing.push(`${key}: ${rel}`);
    }
  }
  return missing.length === 0 || `manifest points at directories that do not exist:\n      ${missing.join("\n      ")}`;
});

check("every MCP pinned in versions.json is declared in the manifest", () => {
  // A pin with no manifest entry is a version nobody installs; a manifest entry with no
  // pin installs whatever npm serves that day. Both are drift.
  const pinned = Object.keys(versions.mcp ?? {});
  const declared = Object.keys(manifest.sharedMcp ?? {});
  // manifest keys are MCP names; versions keys are npm package names. Only local
  // (npm-installed) MCPs must correspond.
  const localMcps = declared.filter((n) => manifest.sharedMcp[n].type === "local");
  const unpinned = localMcps.filter(
    (n) => !pinned.includes(n) && !pinned.includes(`${n}-mcp`)
  );
  return unpinned.length === 0 || `local MCPs with no version pin: ${unpinned.join(", ")}`;
});

check("protected-branch permission rules cover every protected branch", () => {
  const rules = Object.keys(manifest.opencode?.globalPermission?.bash ?? {});
  const expected = ["develop", "dev", "staging", "stable", "main"];
  const missing = expected.filter((b) => !rules.some((r) => r === `git push * ${b}`));
  return missing.length === 0 || `no push-permission rule for: ${missing.join(", ")}`;
});

// ── harness/rules ─────────────────────────────────────────────────────────────
console.log("\n--- harness/rules (always-loaded context) ---");

const ruleFiles = fs
  .readdirSync(path.join(REPO_ROOT, "harness", "rules"))
  .filter((f) => f.endsWith(".md") && f !== "README.md");

check("every rule file is listed in harness/rules/README.md", () => {
  // Rules are loaded into EVERY session's context. An undocumented one is context
  // everybody pays for and nobody can account for.
  const readme = fs.readFileSync(path.join(REPO_ROOT, "harness", "rules", "README.md"), "utf8");
  const undocumented = ruleFiles.filter((f) => !readme.includes(f));
  return undocumented.length === 0 || `rule files missing from README table: ${undocumented.join(", ")}`;
});

check("README.md is excluded from the rules that get loaded", () => {
  // copyRulesFlat() excludes README.md by name. If that ever regresses, the README
  // itself becomes always-loaded instruction text.
  const projectConfig = fs.readFileSync(
    path.join(REPO_ROOT, "harness", "scripts", "lib", "project-config.mjs"),
    "utf8"
  );
  return /README\.md/.test(projectConfig) || "project-config.mjs no longer mentions README.md — the exclusion may have been dropped";
});

check("no rule file interpolates volatile content into always-loaded context", () => {
  // Cache-prefix discipline, enforced rather than merely stated in
  // context-discipline.md. A timestamp or run ID in an always-loaded file busts the
  // provider prompt cache on every turn of every session, forever.
  const offenders = [];
  const volatile = [
    [/\bgenerated (?:on|at)\b[:\s]/i, "'generated on/at'"],
    [/\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/, "an ISO timestamp"],
    [/\{\{\s*(?:timestamp|now|date|run_?id|session_?id)\s*\}\}/i, "a volatile template placeholder"],
  ];
  for (const f of ruleFiles) {
    const body = fs.readFileSync(path.join(REPO_ROOT, "harness", "rules", f), "utf8");
    for (const [re, what] of volatile) {
      if (re.test(body)) offenders.push(`${f} contains ${what}`);
    }
  }
  return offenders.length === 0 || `cache-busting content in always-loaded rules:\n      ${offenders.join("\n      ")}`;
});

// ── skills ────────────────────────────────────────────────────────────────────
console.log("\n--- skills ---");

const skillRoots = ["harness/skills/opencode", "harness/skills/shared"];

check("every skill directory has a SKILL.md", () => {
  const missing = [];
  for (const root of skillRoots) {
    for (const dir of listDirs(root)) {
      if (!fs.existsSync(path.join(REPO_ROOT, root, dir, "SKILL.md"))) missing.push(`${root}/${dir}`);
    }
  }
  return missing.length === 0 || `skill directories with no SKILL.md: ${missing.join(", ")}`;
});

check("every SKILL.md has name and description frontmatter", () => {
  const bad = [];
  for (const root of skillRoots) {
    for (const dir of listDirs(root)) {
      const p = path.join(REPO_ROOT, root, dir, "SKILL.md");
      if (!fs.existsSync(p)) continue;
      const body = fs.readFileSync(p, "utf8");
      const fm = body.match(/^---\r?\n([\s\S]*?)\r?\n---/);
      if (!fm) {
        bad.push(`${root}/${dir}: no frontmatter block`);
        continue;
      }
      if (!/^name\s*:/m.test(fm[1])) bad.push(`${root}/${dir}: no name:`);
      if (!/^description\s*:/m.test(fm[1])) bad.push(`${root}/${dir}: no description:`);
    }
  }
  return bad.length === 0 || `SKILL.md frontmatter problems:\n      ${bad.join("\n      ")}`;
});

check("skill frontmatter name matches its directory name", () => {
  // OpenCode resolves a skill by directory; the model sees the frontmatter name. When
  // they disagree, a skill the model is told exists cannot be loaded by that name.
  const bad = [];
  for (const root of skillRoots) {
    for (const dir of listDirs(root)) {
      const p = path.join(REPO_ROOT, root, dir, "SKILL.md");
      if (!fs.existsSync(p)) continue;
      const m = fs.readFileSync(p, "utf8").match(/^name\s*:\s*(.+)$/m);
      if (m && m[1].trim() !== dir) bad.push(`${root}/${dir}: frontmatter name is "${m[1].trim()}"`);
    }
  }
  return bad.length === 0 || `skill name/directory mismatch:\n      ${bad.join("\n      ")}`;
});

// ── local plugins ─────────────────────────────────────────────────────────────
console.log("\n--- local plugins ---");

const pluginFiles = fs
  .readdirSync(path.join(REPO_ROOT, "harness", "plugins", "local"))
  .filter((f) => f.endsWith(".mjs"));

await checkAsync("every local plugin exports a factory returning a tool.execute.before hook", async () => {
  const bad = [];
  for (const f of pluginFiles) {
    const url = pathToFileURL(path.join(REPO_ROOT, "harness", "plugins", "local", f)).href;
    let mod;
    try {
      mod = await import(url);
    } catch (e) {
      bad.push(`${f}: failed to import — ${e.message}`);
      continue;
    }
    const factories = Object.values(mod).filter((v) => typeof v === "function");
    if (factories.length === 0) {
      bad.push(`${f}: exports no function`);
      continue;
    }
    try {
      const hooks = await factories[0]({ project: {}, client: {}, $: {}, directory: ".", worktree: "." });
      if (typeof hooks?.["tool.execute.before"] !== "function") {
        bad.push(`${f}: factory returned no tool.execute.before hook`);
      }
    } catch (e) {
      bad.push(`${f}: factory threw — ${e.message}`);
    }
  }
  return bad.length === 0 || `plugin contract violations:\n      ${bad.join("\n      ")}`;
});

check("every local plugin is covered by the functional smoke test", () => {
  // A plugin with no test case is enforcement nobody has verified fires.
  const tests = fs.readFileSync(path.join(SCRIPT_DIR, "test-local-plugins.mjs"), "utf8");
  const uncovered = pluginFiles.filter((f) => !tests.includes(f));
  return uncovered.length === 0 || `plugins with no case in test-local-plugins.mjs: ${uncovered.join(", ")}`;
});

// ── dependency policy ─────────────────────────────────────────────────────────
console.log("\n--- dependency policy ---");

const policy = readJson("stack/dependency-policy.json");

check("dependency policy declares the rules the checker reads", () => {
  const required = [
    "maxDirectDependencies",
    "maxDirectDevDependencies",
    "allowOptionalDependencies",
    "allowNativeModules",
    "requireExactVersions",
    "requireLockfileIntegrity",
  ];
  const missing = required.filter((k) => policy.rules?.[k] === undefined);
  return missing.length === 0 || `policy.rules missing: ${missing.join(", ")}`;
});

check("allowlist contract names its required fields", () => {
  const fields = policy.allowlistContract?.requiredFields;
  return (
    (Array.isArray(fields) && fields.includes("approvedBy") && fields.includes("reason")) ||
    "allowlistContract.requiredFields must exist and include approvedBy and reason"
  );
});

check("every allowlist entry satisfies the contract it declares", () => {
  // The policy file is data, so nothing stops a malformed entry being committed. The
  // checker refuses to honour one — this makes that refusal visible at review time
  // rather than as a surprise later.
  const required = policy.allowlistContract?.requiredFields ?? [];
  const bad = [];
  for (const entry of policy.allowlist ?? []) {
    const missing = required.filter((f) => entry[f] === undefined || entry[f] === null);
    if (missing.length) bad.push(`"${entry.package ?? "(unnamed)"}" missing ${missing.join(", ")}`);
    if (entry.enabled === true && /^(team|automation|ci|bot|everyone|n\/a)$/i.test(String(entry.approvedBy).trim())) {
      bad.push(`"${entry.package}" names a non-person approver`);
    }
  }
  return bad.length === 0 || `allowlist entries that would be refused: ${bad.join("; ")}`;
});

check("the repo actually holds the zero-dependency line it declares", () => {
  if (policy.rules.maxDirectDependencies !== 0) return true; // policy changed deliberately
  const found = [];
  const skip = new Set([".git", "node_modules", "dist", "build", ".opencode"]);
  const stack = [REPO_ROOT];
  while (stack.length) {
    const dir = stack.pop();
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (!skip.has(e.name)) stack.push(full);
      } else if (e.name === "package.json") {
        const pkg = JSON.parse(fs.readFileSync(full, "utf8"));
        const n = Object.keys(pkg.dependencies ?? {}).length + Object.keys(pkg.devDependencies ?? {}).length;
        if (n > 0) found.push(`${path.relative(REPO_ROOT, full)} (${n})`);
      }
    }
  }
  return found.length === 0 || `manifests with dependencies: ${found.join(", ")}`;
});

// ── installer core ────────────────────────────────────────────────────────────
console.log("\n--- installer core ---");

check("no lib module hardcodes a developer-specific absolute path", () => {
  const libDir = path.join(REPO_ROOT, "harness", "scripts", "lib");
  const offenders = [];
  const files = [
    ...fs.readdirSync(libDir).map((f) => path.join(libDir, f)),
    path.join(REPO_ROOT, "harness", "scripts", "setup.mjs"),
  ].filter((f) => f.endsWith(".mjs"));
  for (const f of files) {
    const body = fs.readFileSync(f, "utf8");
    // A home directory baked into an installer works on exactly one machine.
    if (/["'`](?:\/Users\/(?!<)|\/home\/(?!<)|[A-Za-z]:\\\\Users\\\\)/.test(body)) {
      offenders.push(path.relative(REPO_ROOT, f));
    }
  }
  return offenders.length === 0 || `hardcoded home paths in: ${offenders.join(", ")}`;
});

check("setup.mjs documents every flag it parses", () => {
  const body = fs.readFileSync(path.join(REPO_ROOT, "harness", "scripts", "setup.mjs"), "utf8");
  const parsed = [...body.matchAll(/case\s+"(--[\w-]+)"/g)].map((m) => m[1]);
  const help = body.slice(body.indexOf("HELP_TEXT"), body.indexOf("function parseArgs"));
  const undocumented = [...new Set(parsed)].filter((f) => !help.includes(f));
  return undocumented.length === 0 || `flags parsed but absent from --help: ${undocumented.join(", ")}`;
});

// ── summary ───────────────────────────────────────────────────────────────────
console.log("");
if (failures > 0) {
  console.error(`${failures} structural invariant(s) violated (${passes} passed).`);
  process.exit(1);
}
console.log(`all ${passes} structural invariants hold`);
