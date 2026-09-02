# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

Four integrity checks, adapted from patterns in the Delta `delta-delivery-loop` harness
(the successor to the repo this one was forked from). Each one turns something that was
previously an assumption into something CI can fail on.

- **Structural invariants** (`.github/scripts/test-structural.mjs`, CI job `test-structural`). 22 assertions about the *shape* of the repo — no network, no OpenCode install, runs in milliseconds. Targets the class of drift where two files that must agree quietly stop agreeing: a rule added to `harness/rules/` but never listed in its README, a skill directory with no `SKILL.md`, a manifest pointing at a renamed directory, a skill whose frontmatter `name` no longer matches its folder. None of these break a dry-run, so before this job they would ship green.
  - Each invariant was verified by deliberately breaking it and confirming the failure. Eight mutation cases were run (orphan rule file, range pin, disagreeing opencode pins, missing manifest dir, timestamp in an always-loaded rule, skill name mismatch, introduced dependency, malformed allowlist entry); all eight were caught.
  - Two invariants caught real pre-existing drift on first run: `project-setup.md` was missing from the `harness/rules/README.md` table, and the CI syntax-check job never covered `harness/scripts/*.mjs` (only `lib/*.mjs`). Both fixed here.

- **Version pin drift checker** (`harness/scripts/check-versions.mjs`, `harness/scripts/lib/version-check.mjs`, `./setup.sh --check-versions` / `.\setup.ps1 -CheckVersions`, CI job `version-drift`). Compares every pin in `versions.json` against what npm actually publishes.
  - **It never writes.** A bump changes what every fresh install receives, so it is a reviewed edit, not a side effect of running a diagnostic. Reports `PIN_CURRENT` / `CANDIDATE_FOUND` / `PIN_UNAVAILABLE` / `PIN_FLOATING` / `CHECK_FAILED` and exits 0 — except on `PIN_UNAVAILABLE`, which breaks fresh installs outright.
  - **An unreachable registry is never reported as "behind."** A timeout, an offline laptop, and a private-registry 403 all report `CHECK_FAILED`. Reporting a network failure as staleness trains people to ignore the report.
  - Scheduled weekly in CI as well as on push: a pin goes stale because upstream released, not because this repo changed, so a push-only trigger would never notice.
  - Found two genuine drifts on first run: `opencode` (1.16.2, several releases behind) and `context-mode` (1.0.162 → 1.0.169).

- **Dependency policy as reviewable data** (`stack/dependency-policy.json`, `harness/scripts/check-deps.mjs`, CI job `dependency-policy`). Declares zero direct dependencies, exact versions only, no optional deps, no native modules, lockfile integrity required.
  - The bar is zero rather than few because the difference is a discontinuity, not a matter of degree: at zero, every audit and lockfile-integrity question disappears; at one, none of them do. This matters more here than in an ordinary application — the harness installs plugins that run with filesystem and shell access in every project the user opens.
  - The allowlist has a real contract: an entry must name `approvedBy` (a **person** — "team", "automation", "ci" or a bot name is rejected), `approvedOn`, `reason`, and `enabled: true`. An entry missing any required field is **reported and refused**, never treated as approval, because a half-filled exemption is how a policy quietly becomes decorative. Optional `reviewBy` warns once past.
  - Verified to actually fail: range dependency, exact-but-unapproved dependency, and `optionalDependencies` were each introduced and confirmed to exit 1.

- **`harness/rules/context-discipline.md`** — a new always-loaded rule covering cache-prefix discipline (volatile content appended at the tail, never spliced into earlier turns; no timestamps or run IDs interpolated into stable content), caps on agent-maintained state files (120 lines, 40 ledger entries, oldest-first eviction), and keeping bulk content out of the main context by deriving in a sandbox rather than reading-then-summarising.
  - Partially enforced rather than merely stated: `test-structural.mjs` fails if any file in `harness/rules/` contains a timestamp or run-ID placeholder, since an always-loaded file that changes byte-for-byte busts the provider prompt cache on every turn of every session.
  - Cache-prefix and bounded-state patterns adapted from the MIT-licensed `oh-my-opencode-slim` approach by way of `delta-delivery-loop`. Adopted as written policy, deliberately not as a dependency — which is also the policy in the new dependency file.

### Changed

- `harness/rules/README.md` — table now lists all three rule files; `project-setup.md` had been missing since it was added.
- `.github/workflows/ci.yml` — `test-installer-core` now syntax-checks `harness/scripts/*.mjs`, not just `harness/scripts/lib/*.mjs`. Added a weekly `schedule` trigger for the drift check.
- `harness/scripts/lib/doctor.mjs` — closes by pointing at `--check-versions`. Doctor deliberately does not run it (doctor is expected to work offline and finish instantly), but the pinned-versions section is where someone looks when they suspect their tooling is out of date, so the pointer belongs there.
- `CONTRIBUTING.md` — documents the dependency policy, the version-pin workflow, and the expanded pre-PR check list. Adds a note that a new check should be deliberately broken once before being committed: a check that has never failed is indistinguishable from one that cannot.

### Fixed

- `versions.json` pinned `opencode.npm`/`opencode.desktop.version` at `1.16.2`, several releases behind current (`1.18.26` at time of writing). Fresh installs and `--incremental` re-runs of `setup.sh`/`setup.ps1` were pulling a stale CLI/desktop build. Bumped both to `1.18.26`. Desktop release asset filenames (`opencode-desktop-{mac,win}-{arm64,x64}.{dmg,exe}`) are unchanged in the upstream release, so no changes were needed in `harness/scripts/lib/opencode-install.mjs`.
- Investigated `The-Delta-AI-Library/delta-ai-harness` (our original fork source) and its successor `delta-delivery-loop` harness family for an upstream fix to port. Neither tracks the `opencode` CLI binary version at all — both assume it's externally managed and only detect drift in their own harness *content* (agent/skill files) via `git ls-remote` against their own repos. No reusable fix existed upstream for this; the pin simply needed manual bumping. The `version-drift` check added above is what stops it going stale unnoticed again.

## [0.3.0] - 2026-07-15

### Added

- **Branching policy.** `harness/rules/branching.md` — always-loaded instructions (via OpenCode's `instructions` config) documenting the feature/fix branch workflow: `feature/<slug>`/`fix/<slug>` branches based on `develop`, pull `develop` first, PRs target `develop`, agents don't merge their own PRs.
- Enforcement is split across two mechanisms, each used for what it's actually good at:
  - `stack/manifest.json` → `opencode.globalPermission` — native `permission.bash` "ask" rules for explicit `git push` to a protected branch (`develop`/`dev`/`staging`/`stable`/`main`). Real ask/once/always/reject UX via OpenCode's own permission system.
  - `harness/plugins/local/protect-branches.mjs` — a narrow plugin backstop for what declarative pattern matching can't see: implicit (no explicit branch name) `git push`, and `git merge` while the current branch is protected (the current-branch condition is never present in the merge command's own text, so there's no declarative alternative for this case at all). Auto-detects whether a repo uses this branching model (checks for a `develop` branch) and is inert otherwise. Supports an explicit `HARNESS_ALLOW_PROTECTED_OP=1` override prefix for cases the user has already authorized in conversation.
- `stack/manifest.json` gained `opencode.rulesSources` (mirrors `localPluginsSources`) — drop a `.md` file in `harness/rules/` and it's picked up automatically on the next setup run, no per-file registration needed.
- `project-config.mjs` now copies rules and renders `permission`/`instructions` into the global OpenCode config (project-local config stays minimal, as before).
- 12 new functional test cases in `.github/scripts/test-local-plugins.mjs` covering `protect-branches.mjs` (explicit vs implicit push, merge, override prefix, compound commands, no-gitflow inertness) using a real git sandbox, not mocks.

### Fixed (found via testing before push, not after)

- `copyRulesFlat()` initially matched *any* `.md` file in the rules source directory, which would have picked up `harness/rules/README.md` itself and loaded it into every session's context as if it were model-facing instruction content. Excluded `README.md` explicitly.
- A redundant, duplicate dry-run file-listing code path (meant to preview `instructions` accurately) had the same README.md bug and was simply dead code once traced through — `copyRulesFlat()`'s return value already handles both dry-run and real mode correctly. Removed rather than fixed twice.

See `_OBSERVATIONS.md` for further detail on the design tradeoffs (why merge protection can't use declarative "ask" rules at all, and the `--auto` mode caveat).

## [0.2.0] - 2026-07-14

### Added

- **Installer consolidated into a single Node.js core.** `setup.sh` and `setup.ps1` are now thin launchers (~90 lines each) whose only job is to bootstrap a working Node.js, then hand off to `harness/scripts/setup.mjs`. Every other concern — OpenCode CLI/desktop install, MCP install, project config rendering, skills/plugins copying, backup/retention, validate, uninstall, doctor — lives in exactly one place (`harness/scripts/lib/*.mjs`) instead of two independently-maintained, occasionally-drifting bash/PowerShell implementations.
- Side benefit: the Node core uses native `JSON.parse`/`fetch()`, so **`python3` and `curl` are no longer required** once Node itself is bootstrapped (previously hard prerequisites for template rendering and desktop-app downloads).
- 3 local security plugins (`harness/plugins/local/`), ported from a Claude Code hook-based harness onto OpenCode's `tool.execute.before` plugin API, installed globally on every setup run: `check-secrets.mjs`, `check-generated-files.mjs`, `strip-jwt.mjs`. See `harness/plugins/README.md`.
- `.github/scripts/test-local-plugins.mjs` — 12-case functional smoke test for the security plugins, run in CI on every push.
- CI: `test-installer-core` (syntax-checks every `lib/*.mjs` module) and an extra `--doctor` pass in the dry-run matrix.
- `.gitattributes` — forces LF on `.sh` files regardless of a cloning machine's `core.autocrlf` setting (prevents CRLF corruption breaking bash execution on a fresh Windows clone).

### Removed

- 8 redundant bash scripts fully replaced by the Node.js core: `install-opencode.sh`, `install-node.sh`, `install-mcp-deps.sh`, `build-project-opencode.sh`, `validate-setup.sh`, `check-prereqs.sh`, `uninstall.sh`, `doctor.sh`.
- `incident-report-logger` skill — authored for workplace/client incident reporting, doesn't fit a personal harness.
- CI's `Set up Python` step in the dry-run matrix (no longer needed — see python3 removal above).

### Fixed (found via actual execution, not just code review)

- Two bash 3.2 incompatibilities (macOS's default shell — `declare -A` needs bash 4+).
- `doctor.sh`'s broken `pipe | python3 - <<heredoc` pattern (heredoc hijacks stdin meant for the piped data).
- `--dry-run` was performing real installs in `install-opencode.sh`, `install-node.sh`, `install-mcp-deps.sh`, and the desktop installer (no dry-run awareness at all — only "already installed" fast paths existed).
- Unguarded `.env.team` sourcing and `validate-setup.sh` call in `setup.sh` crashed dry-run under `set -e`.
- `setup.ps1`'s `Get-ChildItem -Include '*.mjs','*.js' -Path $source` silently returned zero results (a documented `-Include`/`-Path` gotcha) — would have shipped a plugin-copy feature that copied nothing, forever, with no visible error.
- `resolveDesktopPath()` initially missed non-standard OpenCode Desktop install locations (e.g. `Programs\@opencode-aidesktop\`) — ported the original PowerShell's recursive-search fallback, which the direct port had dropped.
- A test helper script's own path resolution mishandled Windows drive letters (`new URL().pathname` vs `fileURLToPath()`).

See `_OBSERVATIONS.md` for the full bug-by-bug record across all phases.

## [0.1.0] - 2026-07-14

Initial fork from upstream delta-ai-harness (ref sha 24fb9db). See commit history for full rework details.

### Added

- `--dry-run`, `--incremental`, `--reset`, `--uninstall`, `--doctor` flags on `setup.sh` and `setup.ps1`
- `harness/scripts/check-prereqs.sh` — pre-flight prerequisite check (node, python3, npm, curl)
- `harness/scripts/uninstall.sh` — restore the newest backup and exit
- `harness/scripts/doctor.sh` — diagnostic report: versions, PATH health, writable dirs
- Backup retention: keep newest 5 by default (`HARNESS_BACKUP_RETENTION` overrides)
- `--incremental` mode (default): update in place without wiping global OpenCode state
- Pre-flight prerequisite check runs before any destructive action
- `setup.ps1` `Ensure-PathContains` now prompts before writing to persistent User PATH
- GitHub Actions CI: shellcheck, PSScriptAnalyzer, JSON validation, dry-run matrix (ubuntu/macos/windows)
- Root `README.md`, `LICENSE` (MIT), `CHANGELOG.md`, `CONTRIBUTING.md`
- `.editorconfig` and `.shellcheckrc` for consistent formatting

### Removed

- Claude Code generation pipeline (`shahil/`, `generate-claude-home.sh`, `validate-claude-setup.sh`)
- Codex CLI artefacts (`codex-config.template.toml`, `codex.plugins.toml`)
- `naman/mcp/team-mcp/` scaffold (was a bare HTTP server stub, not an MCP)
- `naman/flows/` empty placeholder

### Changed

- Renamed `naman/` → `harness/`
- Renamed backup dirs: `.delta-ai-harness-backups` → `.harness-backups`, `opencode-delta-ai-harness-backups` → `opencode-harness-backups`
- Removed `claude` block from `stack/manifest.json` (OpenCode-only pipeline)
- `harness/README.md` updated to reflect new name and dropped Claude/Codex references
- `INSTALL.md` retitled and rewritten for OpenCode-only setup
- `harness/mcp/README.md` simplified; team-mcp scaffold removed
- `harness/plugins/README.md` trimmed to OpenCode section only
- `versions.json` now carries `harness.version = "0.1.0"`
