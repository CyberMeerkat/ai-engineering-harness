// version-check.mjs — reports when a pinned version in versions.json has fallen
// behind what the registry actually publishes. NEVER writes.
//
// This exists because the pins in versions.json rot silently. Nothing consults npm,
// so a pin only gets bumped when a human happens to notice their tooling is old —
// which in practice means it is discovered as a bug report, months late, by whoever
// hits the resulting breakage.
//
// Three properties, each chosen against a specific failure:
//
//   1. It NEVER edits a pin. A version bump changes what every fresh install of this
//      harness receives; that is a reviewed decision, not a side effect of running a
//      diagnostic. The checker reports and exits.
//
//   2. Unreachable is not "behind". A registry timeout, an offline laptop, or a
//      private-registry 403 all report CHECK_FAILED — never "update available".
//      Reporting a network failure as staleness trains people to ignore the report.
//
//   3. It costs no inference and blocks nothing. This is an HTTPS GET against the npm
//      registry with a short timeout. A check that is slow or noisy gets disabled.
//
// Status vocabulary (borrowed deliberately from the same reporting shape used for
// harness content drift, so both read the same way):
//
//   PIN_CURRENT      the pin matches the latest published version
//   CANDIDATE_FOUND  a newer version exists; a human decides whether to take it
//   PIN_UNAVAILABLE  the pinned version is not published (typo, or it was unpublished)
//   PIN_FLOATING     the pin is "latest" — deliberately unpinned, nothing to compare
//   CHECK_FAILED     the registry could not be reached; no conclusion drawn

const REGISTRY = "https://registry.npmjs.org";

/** Packages in versions.json that map to a real npm package, and where the pin lives. */
export function pinnedPackages(versions) {
  const pins = [
    { name: "opencode-ai", pinned: versions?.opencode?.npm, field: "opencode.npm" },
  ];

  for (const [pkg, version] of Object.entries(versions?.mcp ?? {})) {
    pins.push({ name: pkg, pinned: version, field: `mcp.${pkg}` });
  }

  return pins.filter((p) => p.pinned);
}

/** GETs a registry URL with a timeout, returning parsed JSON or an error string. */
async function registryGet(url, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: controller.signal });
    if (res.status === 404) return { notFound: true };
    if (!res.ok) return { error: `HTTP ${res.status}` };
    return { body: await res.json() };
  } catch (e) {
    return { error: e.name === "AbortError" ? `timed out after ${timeoutMs}ms` : e.message };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Resolves the latest published version of a package.
 *
 * Deliberately hits `/{pkg}/latest` rather than the full packument. The abbreviated
 * packument for a package with many releases is enormous — opencode-ai's is ~14 MB and
 * takes ~17s, which blew the timeout and reported CHECK_FAILED on a perfectly reachable
 * registry. `/{pkg}/latest` is ~2 KB and ~250ms for the same answer.
 */
async function latestVersion(pkg, timeoutMs) {
  const { body, error, notFound } = await registryGet(`${REGISTRY}/${encodeURIComponent(pkg)}/latest`, timeoutMs);
  if (notFound) return { error: "package not found in registry" };
  if (error) return { error };
  if (!body?.version) return { error: "registry response had no version field" };
  return { latest: body.version };
}

/**
 * Confirms a specific version is actually published. Only called when the pin differs
 * from latest, so the common "pin is current" case costs exactly one small request.
 */
async function versionExists(pkg, version, timeoutMs) {
  const { error, notFound } = await registryGet(
    `${REGISTRY}/${encodeURIComponent(pkg)}/${encodeURIComponent(version)}`,
    timeoutMs
  );
  if (notFound) return { exists: false };
  if (error) return { error };
  return { exists: true };
}

/** Numeric-aware semver comparison. Returns >0 when a is newer than b. */
export function compareVersions(a, b) {
  const parse = (v) => String(v).replace(/^v/, "").split("-")[0].split(".").map((n) => parseInt(n, 10) || 0);
  const [x, y] = [parse(a), parse(b)];
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    const diff = (x[i] ?? 0) - (y[i] ?? 0);
    if (diff !== 0) return diff;
  }
  return 0;
}

/**
 * Probes every pinned package. Network-bound.
 * @returns {Promise<Array<{name,field,pinned,latest,status,detail}>>}
 */
export async function checkVersions(versions, { timeoutMs = 8000 } = {}) {
  const pins = pinnedPackages(versions);

  return Promise.all(
    pins.map(async ({ name, pinned, field }) => {
      // "latest" is a deliberate choice not to pin, not a stale pin. Nothing to compare.
      if (pinned === "latest") {
        return { name, field, pinned, latest: null, status: "PIN_FLOATING", detail: "pin is 'latest' — intentionally unpinned" };
      }

      const { latest, error } = await latestVersion(name, timeoutMs);
      if (error) {
        return { name, field, pinned, latest: null, status: "CHECK_FAILED", detail: error };
      }

      if (compareVersions(latest, pinned) > 0) {
        return { name, field, pinned, latest, status: "CANDIDATE_FOUND", detail: `${pinned} → ${latest}` };
      }

      // The pin is at or ahead of latest. Ahead means it is probably a typo or an
      // unpublished version, so confirm it actually exists before calling it current —
      // a pin nobody can install is a broken install, not a current one.
      if (compareVersions(latest, pinned) < 0) {
        const { exists, error: existsError } = await versionExists(name, pinned, timeoutMs);
        if (existsError) {
          return { name, field, pinned, latest, status: "CHECK_FAILED", detail: existsError };
        }
        if (!exists) {
          return {
            name,
            field,
            pinned,
            latest,
            status: "PIN_UNAVAILABLE",
            detail: `pinned version ${pinned} is not published; latest is ${latest}`,
          };
        }
      }

      return { name, field, pinned, latest, status: "PIN_CURRENT", detail: `${pinned} is current` };
    })
  );
}

/**
 * Overall verdict for a set of results. Deliberately does NOT treat CHECK_FAILED as a
 * problem with the pins — it is a problem with the check.
 */
export function summarise(results) {
  if (results.some((r) => r.status === "PIN_UNAVAILABLE")) return "PIN_UNAVAILABLE";
  if (results.some((r) => r.status === "CANDIDATE_FOUND")) return "CANDIDATE_FOUND";
  if (results.length && results.every((r) => r.status === "CHECK_FAILED")) return "CHECK_FAILED";
  return "PIN_CURRENT";
}

/** Human-readable report. Returns the lines rather than printing, so callers choose the stream. */
export function formatReport(results) {
  const lines = [];
  const width = Math.max(...results.map((r) => r.status.length), 0);
  for (const r of results) {
    lines.push(`  ${r.status.padEnd(width)}  ${r.field.padEnd(22)} ${r.detail}`);
  }

  const candidates = results.filter((r) => r.status === "CANDIDATE_FOUND");
  const unavailable = results.filter((r) => r.status === "PIN_UNAVAILABLE");
  const failed = results.filter((r) => r.status === "CHECK_FAILED");

  if (unavailable.length) {
    lines.push("");
    lines.push(`${unavailable.length} pin(s) reference a version that is not published. This is a typo or an`);
    lines.push("unpublished release — a fresh install would fail. Fix these before the next release.");
  }

  if (candidates.length) {
    lines.push("");
    lines.push(`${candidates.length} pin(s) behind. Edit versions.json to take an update — this checker never`);
    lines.push("writes, because a bump changes what every fresh install receives and is a reviewed");
    lines.push("decision. Check the upstream changelog before bumping.");
  }

  if (failed.length && !candidates.length && !unavailable.length) {
    lines.push("");
    lines.push("Could not reach the registry for some packages. Nothing is reported as behind —");
    lines.push("a network failure is not staleness.");
  }

  if (!candidates.length && !unavailable.length && !failed.length) {
    lines.push("");
    lines.push("All pins match the latest published version.");
  }

  return lines;
}
