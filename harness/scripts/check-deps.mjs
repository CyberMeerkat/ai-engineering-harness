#!/usr/bin/env node
// check-deps.mjs — enforces stack/dependency-policy.json.
//
// This harness installs plugins, skills and rules into the user's global OpenCode
// config, and its local plugins run with filesystem and shell access in every project
// the user opens. A transitive dependency reaches further here than in an ordinary
// application, so the policy is zero-by-default and every exception is an allowlist
// entry naming a person, a date and a reason.
//
// The policy lives in JSON rather than in this file on purpose: rules in a registry can
// be argued with in a diff; rules buried in a script get quietly relaxed to make a build
// pass. This module only enforces what that file declares.
//
//   node harness/scripts/check-deps.mjs [--dir <path>] [--json]
//
// Exits 0 when compliant, 1 on any violation.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, "..", "..");
const POLICY_PATH = path.join(ROOT_DIR, "stack", "dependency-policy.json");

const argv = process.argv.slice(2);
const dirFlag = argv.indexOf("--dir");
const asJson = argv.includes("--json");

/**
 * Recursively finds every package.json in the repo, excluding vendored trees.
 * The policy applies to the whole repo, not just its root: a dependency added under
 * harness/skills/ has the same reach as one added at the top level, because both are
 * copied into the user's config by setup.
 */
function findManifests(root) {
  const found = [];
  const skip = new Set([".git", "node_modules", "dist", "build", ".opencode"]);
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (!skip.has(entry.name)) stack.push(full);
      } else if (entry.name === "package.json") {
        found.push(full);
      }
    }
  }
  return found.sort();
}

/**
 * An allowlist entry only counts when it is complete, enabled, and human-approved.
 * Anything short of that is reported as a warning rather than silently ignored — an
 * incomplete exemption is a policy failure in its own right, not merely an absent one.
 */
function approvedPackages(policy, warnings) {
  const approved = new Map();
  const required = policy.allowlistContract?.requiredFields ?? [];

  for (const entry of policy.allowlist ?? []) {
    const name = entry.package ?? "(unnamed)";
    const missing = required.filter((f) => entry[f] === undefined || entry[f] === null);
    if (missing.length) {
      warnings.push(`allowlist entry "${name}" is missing: ${missing.join(", ")} — not honoured`);
      continue;
    }
    if (entry.enabled !== true) continue;
    if (/^(team|automation|ci|bot|everyone|n\/a)$/i.test(String(entry.approvedBy).trim())) {
      warnings.push(
        `allowlist entry "${name}" names "${entry.approvedBy}" as approver — must be a person; not honoured`
      );
      continue;
    }
    if (entry.reviewBy && Date.parse(entry.reviewBy) < Date.now()) {
      warnings.push(
        `allowlist entry "${name}" passed its reviewBy (${entry.reviewBy}) — still honoured, but re-confirm`
      );
    }
    approved.set(entry.package, entry);
  }
  return approved;
}

function checkManifest(manifestPath, policy, approved, violations) {
  // A target outside the repo (via --dir) produces a relative path made of `..`
  // segments, which is unreadable; fall back to the absolute path in that case.
  const relative = path.relative(ROOT_DIR, manifestPath);
  const rel = !relative || relative.startsWith("..") ? manifestPath : relative;
  let pkg;
  try {
    pkg = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  } catch (e) {
    violations.push(`${rel}: not valid JSON — ${e.message}`);
    return;
  }

  const { rules } = policy;
  const fields = [
    ["dependencies", rules.maxDirectDependencies],
    ["devDependencies", rules.maxDirectDevDependencies],
  ];

  for (const [field, max] of fields) {
    const entries = Object.entries(pkg[field] ?? {});
    const unapproved = entries.filter(([name]) => !approved.has(name));

    if (unapproved.length > max) {
      for (const [name, range] of unapproved) {
        violations.push(`${rel} ${field}: "${name}@${range}" is not allowlisted (limit ${max})`);
      }
    }

    // Exact-version checking applies to allowlisted packages too: approval covers a
    // package, not every future version of it.
    if (rules.requireExactVersions) {
      for (const [name, range] of entries) {
        if (typeof range === "string" && /^[\^~]|[<>]=?/.test(range)) {
          violations.push(
            `${rel} ${field}: "${name}@${range}" is a range; policy requires an exact version`
          );
        }
      }
    }
  }

  if (!rules.allowOptionalDependencies && Object.keys(pkg.optionalDependencies ?? {}).length) {
    violations.push(
      `${rel}: optionalDependencies present — ${Object.keys(pkg.optionalDependencies).join(", ")}`
    );
  }

  // A lockfile resolving real packages means something was installed regardless of what
  // the manifest claims; the two must agree.
  const lockPath = path.join(path.dirname(manifestPath), "package-lock.json");
  if (!fs.existsSync(lockPath)) return;

  let lock;
  try {
    lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));
  } catch (e) {
    violations.push(`${rel}: adjacent package-lock.json is not valid JSON — ${e.message}`);
    return;
  }

  const installed = Object.entries(lock.packages ?? {}).filter(([k]) => k.startsWith("node_modules/"));
  const unapproved = installed.filter(([k]) => !approved.has(k.replace(/^node_modules\//, "")));
  if (unapproved.length > 0) {
    violations.push(
      `${rel}: package-lock.json resolves ${unapproved.length} package(s) not covered by the manifest or allowlist`
    );
  }

  if (rules.requireLockfileIntegrity) {
    const unverifiable = installed.filter(([, m]) => !m.link && (!m.integrity || !m.resolved));
    if (unverifiable.length) {
      violations.push(
        `${rel}: package-lock.json has ${unverifiable.length} entr(ies) without resolved+integrity — npm cannot verify what it downloads`
      );
    }
  }
}

function main() {
  let policy;
  try {
    policy = JSON.parse(fs.readFileSync(POLICY_PATH, "utf8"));
  } catch (e) {
    console.error(`Cannot read dependency policy at ${POLICY_PATH}: ${e.message}`);
    process.exit(1);
  }

  const targetDir = dirFlag === -1 ? ROOT_DIR : path.resolve(argv[dirFlag + 1]);
  const violations = [];
  const warnings = [];
  const approved = approvedPackages(policy, warnings);
  const manifests = findManifests(targetDir);

  for (const manifest of manifests) {
    checkManifest(manifest, policy, approved, violations);
  }

  if (asJson) {
    console.log(
      JSON.stringify(
        {
          target: targetDir,
          manifestsFound: manifests.map((m) => {
            const r = path.relative(ROOT_DIR, m);
            return !r || r.startsWith("..") ? m : r;
          }),
          violations,
          warnings,
          approved: [...approved.keys()],
        },
        null,
        2
      )
    );
    process.exit(violations.length ? 1 : 0);
  }

  for (const w of warnings) console.log(`  [WARN] ${w}`);

  if (violations.length === 0) {
    if (manifests.length === 0) {
      // No manifest at all is the strongest possible compliance, not a gap.
      console.log("dependency policy: OK — no package.json in the repo (zero dependency surface)");
    } else {
      const n = approved.size;
      console.log(
        `dependency policy: OK — ${manifests.length} manifest(s) checked${n ? ` (${n} allowlisted)` : ", zero dependencies"}`
      );
    }
    process.exit(0);
  }

  console.error("\ndependency policy VIOLATED:\n");
  for (const v of violations) console.error(`  ${v}`);
  console.error(
    `\n${policy.rationale}\n\n` +
      "If a dependency is genuinely warranted, add an allowlist entry to\n" +
      "stack/dependency-policy.json naming who approved it, when, and why.\n" +
      "Editing that file IS the approval step — do not weaken the rules to pass."
  );
  process.exit(1);
}

main();
