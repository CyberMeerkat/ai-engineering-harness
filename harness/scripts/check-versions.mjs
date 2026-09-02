#!/usr/bin/env node
// check-versions.mjs — CLI wrapper around lib/version-check.mjs.
//
//   node harness/scripts/check-versions.mjs           report; exit 0 unless a pin is unpublished
//   node harness/scripts/check-versions.mjs --json     machine-readable
//   node harness/scripts/check-versions.mjs --strict   also exit 1 when an update is available
//
// Exit codes are chosen so this is safe to wire into CI as an advisory job:
//   0  pins current, floating, or the registry was unreachable
//   1  a pin references a version that is not published (always an error), or
//      --strict was passed and an update is available
//
// Being behind is NOT an error by default. It is a recommendation, and a check that
// fails the build for a recommendation is one people route around.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { checkVersions, summarise, formatReport } from "./lib/version-check.mjs";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(SCRIPT_DIR, "..", "..");
const VERSIONS_PATH = path.join(ROOT_DIR, "versions.json");

const argv = process.argv.slice(2);
const asJson = argv.includes("--json");
const strict = argv.includes("--strict");

const versions = JSON.parse(fs.readFileSync(VERSIONS_PATH, "utf8"));
const results = await checkVersions(versions);
const status = summarise(results);

if (asJson) {
  console.log(JSON.stringify({ status, results }, null, 2));
} else {
  console.log(`version pins: ${status}\n`);
  for (const line of formatReport(results)) console.log(line);
}

if (status === "PIN_UNAVAILABLE") process.exit(1);
if (strict && status === "CANDIDATE_FOUND") process.exit(1);
process.exit(0);
