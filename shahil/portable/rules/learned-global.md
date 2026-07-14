# Cross-Project Learned Rules

> Always-loaded. Hard cap: 80 lines. Tooling-general rules that apply across every project.
> Populated via `/learned --promote <project>:<rule-id>`. Project-specific rules live in
> `<project>/.claude/learned/learned-rules.md` and are FTS5-indexed for on-demand recall.

<!-- Promote rules here only when they apply to ANY project using the same tooling. -->
<!-- Project-specific rules (data model, business logic, infra paths) stay in project file. -->

## Tooling

1. **Prisma `migration_lock.toml` is required and may be missing from fresh scaffolds.** If `prisma migrate` errors about a missing lock file, check that `prisma/migrations/migration_lock.toml` exists with `provider = "postgresql"` (or matching driver). Add it when creating a new Prisma repo. *(Promoted from project-a 2026-05-07)*

2. **TypeScript `exactOptionalPropertyTypes` semantics — type optional params as `key?: T | undefined`.** When the flag is enabled, optional params must be typed `key?: T | undefined` if callers may pass `undefined` explicitly (parsed query strings, JSON nulls). Otherwise: `not assignable with 'exactOptionalPropertyTypes: true'`. *(Promoted from project-a 2026-05-07)*

3. **NestJS `start:prod` entrypoint is `node dist/src/main.js`, not `node dist/main`.** NestJS preserves the `src/` folder in compiled output. Default scaffolds sometimes emit `start:prod: node dist/main`, which fails: `Cannot find module '.../dist/main'`. Always check entrypoint path before running `npm run start:prod` on a new NestJS repo. *(Promoted from project-a 2026-05-07)*

4. **OpenRouter model slugs are `provider/family-version`, not `provider/version-family`.** Canonical: `anthropic/claude-sonnet-4.6`. Wrong: `anthropic/claude-4.6-sonnet`. The wrong form may alias-resolve but masks drift. Validate before setting `OPENROUTER_MODEL`: `curl -H "Authorization: Bearer $KEY" https://openrouter.ai/api/v1/models | jq -r '.data[].id' | grep <family>` and use the exact match. *(Promoted from project-a 2026-05-07)*

## Process

1. **Cache Jira transition IDs per project — skip the `/transitions` discovery call.** Project-A (project key PROJ): `To Do=11`, `In Progress=21`, `Done=31`. Use directly: `POST /rest/api/3/issue/{key}/transitions` body `{"transition":{"id":"31"}}`. The general rule is "cache transition IDs once per project to avoid the discovery round-trip"; the PROJ-specific values stay accurate only for that project. *(Promoted from project-a 2026-05-07)*

2. **When resuming any local branch >7d old, run a per-file line-divergence check against the trunk BEFORE attempting rebase or merge.** `git fetch && git diff --stat <trunk>...HEAD | sort -nrk3 | head -20` tells you whether rebase is feasible. A single file with thousands of lines divergent (typical after another contributor's large refactor lands) makes rebase impractical regardless of commit count — switch to rebranch-off-trunk + replay a small KEEP set. Decide by the biggest single-file divergence, not by total commit count. *(Promoted from project-b 2026-05-26)*

## Environment

1. **MV3 Chrome extensions cannot be reliably driven by headless / automation tooling on this host.** Concrete blockers observed: (a) headless Chromium doesn't load MV3 service workers, (b) the host's running Chrome has no `DevToolsActivePort` so `playwright-cli attach --cdp=chrome` fails, (c) `cua-driver launch_app` can't resolve Chrome by bundle id or name, (d) "Allow JavaScript from Apple Events" is disabled so AppleScript JS injection is blocked. **Rule:** for any task that requires driving an *unpacked* MV3 extension on this host, plan for manual operator load from the start — do not burn turns trying to automate the extension load step. *(Promoted from project-b 2026-05-26)*

2. **Railway "Raw Editor" / `railway variable list` dumps secret VALUES into the agent transcript.** Treat any such read as a secrets-exposure event: list which secrets were exposed in the session summary and flag them for rotation. Never paste the values back into chat or commit them. Prefer `railway variable list --service <svc> --kv | grep -v '='` style filtering when you only need to confirm a key exists. *(Promoted from project-b 2026-05-26)*
