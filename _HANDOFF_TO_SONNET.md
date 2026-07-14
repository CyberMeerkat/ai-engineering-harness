# Handoff: ai-engineering-harness rework

**For:** Claude Sonnet 4.6 (or any capable coding agent) executing Phases 1, 2, 3, and 5 of the harness rework.
**From:** Prior analysis session (Opus 4.7).
**Working directory:** `D:\ai-harness` (Windows, PowerShell 7+).
**Delete this file after completing all four phases and passing the final verification (§8).**

---

## 0. What you're inheriting

You are working inside a **hard fork** of `The-Delta-AI-Library/delta-ai-harness` (upstream sha `24fb9db`, imported 2026-07-14). The fork lives at `D:\ai-harness`, is a fresh `git init`, has **no remotes**, and is on branch `main`. The initial commit (`4358977`) contains 181 tracked files snapshotted from upstream.

The goal: produce a **clean, provider-agnostic, OpenCode-focused harness** called `ai-engineering-harness`, ready for local testing and eventual publication to a new (user-owned) GitHub repo.

The prior analysis session already did the reading and produced the plan. **Do not re-explore or re-analyse the upstream repo.** Everything you need is in this handoff.

---

## 1. Absolute rules

1. **Do not push. Do not add any remote.** The user will publish manually when they're ready.
2. **One commit per phase.** Commit only after the phase's verification block passes. Use a fresh `user.name`/`user.email` per commit (`-c user.name='rework' -c user.email='rework@localhost'`) — the user's real git identity is not configured for this fork.
3. **Work in `D:\ai-harness`.** Use the `workdir` parameter on shell tools, not `cd` inside commands.
4. **Windows environment.** Shell is PowerShell 7+. `bash` scripts stay `bash` scripts (they are targeted at users on macOS/Linux/WSL); you edit them but do not execute them here — no bash on this host.
5. **Do not "improve" anything not listed in this handoff.** No refactors, no drive-by fixes, no adding features. If you see something suspect, note it under §9 in a `_OBSERVATIONS.md` file, do not fix it.
6. **Ask the user (not guess) when a decision is ambiguous.** All non-obvious decisions have already been made — see §2. If you encounter one that isn't there, stop and ask.
7. **Preserve the exact case and punctuation of upstream identifiers** you are not renaming (e.g. `opencode`, `OpenCode`, `context-mode`, `context7-mcp`, `@upstash/context7-mcp`, `anomalyco/tap/opencode`, `github.com/anomalyco/opencode`). These are **upstream project identifiers, not company references** — they stay.
8. **Never delete `versions.json`, `stack/manifest.json`, or any file under `naman/skills/`.** These are the content payload of the harness.

---

## 2. Decisions already made (do not re-litigate)

| Decision | Value |
|---|---|
| Project name | `ai-engineering-harness` |
| Root source folder | `harness/` (rename from `naman/`) |
| Backup dir names | `.harness-backups` (was `.delta-ai-harness-backups`) and `opencode-harness-backups` (was `opencode-delta-ai-harness-backups`) |
| Claude Code support | **Dropped entirely.** Delete `shahil/`, `naman/scripts/generate-claude-home.sh`, `naman/scripts/validate-claude-setup.sh`, and the `claude` block in `stack/manifest.json`. |
| Codex CLI support | **Dropped.** Delete `naman/templates/codex-config.template.toml` and `naman/plugins/codex.plugins.toml`. Trim Codex mentions from READMEs. |
| Default MCP bundle | Unchanged: `context-mode`, `context7` enabled; `jira`, `figma` present but `enabledByDefault: false`. |
| `naman/mcp/team-mcp/` scaffold | **Delete.** It is a misleading stub (a bare `http.createServer`, not an MCP). If a real in-house MCP is needed later, use `@modelcontextprotocol/sdk`. |
| `naman/flows/` | **Delete.** Empty placeholder, undocumented shape. |
| Provider coupling | The OpenCode side is already provider-agnostic. Do not add any provider/model config. Provider setup happens inside OpenCode via `/connect` on first boot — leave that alone. |
| Node/Python prereqs | Keep as-is: Python 3 (bash scripts read `versions.json` via inline Python) and Node.js pinned major (see `versions.json`). |
| Windows support | `setup.ps1` stays a monolith for now. Deduplication with bash scripts is Phase 4 (out of scope here). |
| License | MIT. |
| Commit style | Conventional Commits (`chore:`, `feat:`, `docs:`). Sign nothing. |

---

## 3. Naming map (apply everywhere)

| Old | New |
|---|---|
| `naman/` | `harness/` |
| `naman/.env.team` | `harness/.env.team` |
| `naman/.env.team.example` (template) | `harness/.env.team.example` (path change only; file content untouched) |
| `naman/README.md` | `harness/README.md` |
| `naman/SANITISATION.md` | `harness/SANITISATION.md` |
| `naman/scripts/` | `harness/scripts/` |
| `naman/templates/` | `harness/templates/` |
| `naman/skills/` | `harness/skills/` |
| `naman/mcp/` | `harness/mcp/` (after `naman/mcp/team-mcp/` deletion) |
| `naman/plugins/` | `harness/plugins/` |
| `shahil/` | (deleted) |
| `.delta-ai-harness-backups` | `.harness-backups` |
| `opencode-delta-ai-harness-backups` | `opencode-harness-backups` |
| PowerShell var `$NamanDir` | `$HarnessDir` |
| PowerShell var `$ShahilPortableDir` | (deleted along with all its callers) |
| Bash var `NAMAN_DIR` | `HARNESS_DIR` |
| Bash var `PORTABLE_DIR` (in `generate-claude-home.sh`, being deleted) | n/a |

Files with the old strings baked in (found by grep at analysis time — reconfirm with `git grep` before editing):

- `INSTALL.md`
- `setup.sh`
- `setup.ps1`
- `naman/README.md`
- `naman/SANITISATION.md`
- `naman/scripts/build-project-opencode.sh`
- `naman/scripts/install-opencode.sh`
- `naman/scripts/install-node.sh`
- `naman/scripts/install-mcp-deps.sh`
- `naman/scripts/generate-claude-home.sh` (being deleted anyway)
- `naman/scripts/validate-setup.sh`
- `naman/scripts/validate-claude-setup.sh` (being deleted anyway)
- `stack/README.md`
- `stack/manifest.json`
- `naman/mcp/README.md`
- `naman/plugins/README.md`

---

## 4. Phase 1 — Rename & de-brand

**Goal:** Zero references to `delta`, `naman`, `shahil` in code, paths, or docs. Repo still runs end-to-end (setup.sh completes) after this phase.

### 4.1 Steps (in order)

1. **`git mv naman harness`** — preserves history. Confirm with `git status`.

2. **Delete `shahil/`** — `git rm -r shahil`. (Full deletion; do not stage renames.)

3. **Grep the whole tree for the old names** to catch anything the naming map missed:
   ```powershell
   git grep -n -i -E 'naman|shahil|delta[- ]?(ai|studio|library)|the delta'
   ```
   Expected residual matches after your edits: **zero** (excluding this handoff file and the initial-commit provenance message in `git log`, which stays).

4. **Apply the file-level edits below.** Each is described by file + change. Use `Edit`/`Read` — do not sed-blast across files (the changes are small and readable).

### 4.2 File-level edits

#### `setup.sh`
- Replace every `naman` with `harness` (variables, comments, paths).
  - Line ~4: `NAMAN_DIR="$ROOT_DIR/naman"` → `HARNESS_DIR="$ROOT_DIR/harness"`
  - Every `"$NAMAN_DIR/…"` → `"$HARNESS_DIR/…"`
  - Every `$NAMAN_DIR` in printf strings → `$HARNESS_DIR`
- **Delete these lines** (Claude Code steps — being removed in Phase 2, but do it here so §4.5 verification passes):
  - The `if ! command -v claude` block (installs Claude Code)
  - `printf '==> Generate Claude home\n'` + `bash "$NAMAN_DIR/scripts/generate-claude-home.sh"`
  - `printf '==> Validate Claude setup\n'` + `bash "$NAMAN_DIR/scripts/validate-claude-setup.sh"`
- Update final `printf` from `…then run opencode from this repo root or Claude Code with ~/.claude.` → `…then run opencode from this repo root.`

#### `setup.ps1`
- Every `Naman` → `Harness` (case-preserving) — variables `$NamanDir`, path fragments, comments.
- **Delete these functions and every call site:** `Write-ClaudeHome`, `Validate-ClaudeSetup`, `Install-ClaudeCode`, `Resolve-ClaudeCommand`.
- **Delete** the `$ShahilPortableDir` variable and every reference.
- Replace both occurrences of `.delta-ai-harness-backups` with `.harness-backups`.
- Replace `opencode-delta-ai-harness-backups` with `opencode-harness-backups`.
- Update the final `Write-Host "Next: …"` to drop the "Claude Code with ~/.claude" clause.
- Update comment header at top of file (if any references to the old repo name).

#### `harness/scripts/build-project-opencode.sh`
- Line ~12: `GLOBAL_BACKUP_ROOT="${HOME}/.config/opencode-delta-ai-harness-backups"` → `GLOBAL_BACKUP_ROOT="${HOME}/.config/opencode-harness-backups"`
- Every path reference to `$ROOT_DIR/naman/…` → `$ROOT_DIR/harness/…`

#### `harness/scripts/install-opencode.sh`, `install-node.sh`, `install-mcp-deps.sh`, `validate-setup.sh`
- Every `$ROOT_DIR/naman/…` → `$ROOT_DIR/harness/…` (should be minimal — these scripts mostly read `versions.json`).
- Every `naman/` in comments → `harness/`.

#### `INSTALL.md`
- Line ~76: `~/.claude/.delta-ai-harness-backups/<timestamp>/` — **delete this entire section** referring to Claude backups (Claude Code is being dropped).
- Replace every `naman/` mention with `harness/`.
- Rewrite the "What gets installed" and "By default this…" lists to remove Claude/shahil steps.
- Rewrite the "After setup" section to remove steps 6-7 (Claude-related).
- Retitle from "Team Harness Install" to "AI Engineering Harness — Install".

#### `harness/README.md` (formerly `naman/README.md`)
- Replace every `naman/` → `harness/`.
- Remove the "For Claude Code, the repo also generates…" paragraph.
- Remove the Codex plugins bullet under "Local inventory worth templating" (Codex artefacts are being deleted in Phase 2).
- Rewrite section titles to drop "team" framing if it reads awkwardly for a personal harness — keep it neutral (e.g., "What belongs here" is fine as-is).

#### `harness/SANITISATION.md`
- Prepend a one-line note: `> This file documents what was removed when forking upstream. Historical only.`
- Otherwise leave content — it's a factual record.

#### `stack/manifest.json`
- **Delete the entire `"claude"` object.** Result: only `sharedMcp` and `opencode` keys remain.
- Update `projectSkillsSources` and `globalSkillsSources` from `naman/skills/…` → `harness/skills/…`.

#### `stack/README.md`
- Replace `naman/` → `harness/`.
- Delete every mention of `shahil/portable/`, Claude, and `generate-claude-home.sh`.
- Update the "Current generators" list — only `harness/scripts/build-project-opencode.sh` remains.

#### `harness/mcp/README.md`
- Keep as-is except:
  - Fix any `naman/` paths to `harness/`.
  - If it mentions the `team-mcp` scaffold (which is being deleted in Phase 2), leave the mention for Phase 2 to remove.

#### `harness/plugins/README.md`
- Delete the Codex sections (being removed in Phase 2). Leave the file with just the OpenCode section.

### 4.3 Verification (Phase 1)

Run from `D:\ai-harness`:

```powershell
# 1. No old names anywhere
git grep -n -i -E 'naman|shahil|delta[- ]?(ai|studio|library)|the delta' -- ':(exclude)_HANDOFF_TO_SONNET.md'
# EXPECTED: no output

# 2. No stale references to deleted Claude scripts
git grep -n -E 'generate-claude-home|validate-claude-setup|Write-ClaudeHome|Validate-ClaudeSetup|Install-ClaudeCode|Resolve-ClaudeCommand|ShahilPortableDir' -- ':(exclude)_HANDOFF_TO_SONNET.md'
# EXPECTED: no output

# 3. All JSON still parses
Get-ChildItem -Recurse -Filter *.json | ForEach-Object { python -m json.tool $_.FullName > $null; if ($LASTEXITCODE -ne 0) { Write-Host "BROKEN: $($_.FullName)" -ForegroundColor Red } }

# 4. All shell scripts still parse (bash -n on WSL if available; else skip and note)
Get-ChildItem -Recurse -Filter *.sh | ForEach-Object { Write-Host "would check: $($_.FullName)" }
# Note: bash unavailable on this host; parse check deferred to CI (added in Phase 5).

# 5. Directory structure
Get-ChildItem -Force | Select-Object Name
# EXPECTED top-level: .git, .gitignore, harness, INSTALL.md, setup.ps1, setup.sh, stack, versions.json, _HANDOFF_TO_SONNET.md
```

### 4.4 Commit

```powershell
git add -A
git -c user.name='rework' -c user.email='rework@localhost' commit -m "chore: rename naman -> harness, strip delta and claude references

- git mv naman -> harness
- delete shahil/ (Claude Code support dropped)
- rename backup dirs: .delta-ai-harness-backups -> .harness-backups,
  opencode-delta-ai-harness-backups -> opencode-harness-backups
- remove Claude generation + validation steps from setup.sh and setup.ps1
- remove Codex plugin references from README docs (files deleted in phase 2)
- update INSTALL.md and stack/manifest.json for OpenCode-only pipeline"
```

---

## 5. Phase 2 — Prune dead code

**Goal:** Remove misleading stubs, unused scaffolding, and provider-tool-specific artefacts. Repo must still run `./setup.sh` (or `.\setup.ps1`) end-to-end after this phase.

### 5.1 Deletions

```powershell
git rm -r harness/mcp/team-mcp
git rm -r harness/flows
git rm harness/templates/codex-config.template.toml
git rm harness/plugins/codex.plugins.toml
git rm harness/scripts/generate-claude-home.sh    # if still present after phase 1
git rm harness/scripts/validate-claude-setup.sh   # if still present after phase 1
```

### 5.2 File-level edits

#### `harness/mcp/README.md`
- Delete the entire "No shared team MCP yet" / `team-mcp/` section (the scaffold no longer exists).
- Replace with a single line under "Recommended pattern": `> To add a real MCP, build with @modelcontextprotocol/sdk and register it in stack/manifest.json.`

#### `harness/plugins/README.md`
- Verify no Codex references remain from Phase 1. This file should end up with just the OpenCode section (a bullet list containing `context-mode`).

#### `harness/README.md`
- Under "Current contents" table, delete the `flows/` row.
- Under "Local inventory worth templating", delete the Codex bullet.

#### `INSTALL.md`
- Delete the sentence "The in-house `team-mcp` scaffold exists in the repo but is not enabled by default because there is no real team MCP yet."

### 5.3 Verification (Phase 2)

```powershell
# 1. Deleted paths are gone
Test-Path harness/mcp/team-mcp; Test-Path harness/flows; Test-Path harness/templates/codex-config.template.toml; Test-Path harness/plugins/codex.plugins.toml; Test-Path harness/scripts/generate-claude-home.sh; Test-Path harness/scripts/validate-claude-setup.sh
# EXPECTED: six `False` lines

# 2. No dangling references to deleted files
git grep -n -E 'team-mcp|generate-claude-home|validate-claude-setup|codex-config\.template|codex\.plugins|naman/flows|harness/flows' -- ':(exclude)_HANDOFF_TO_SONNET.md'
# EXPECTED: no output

# 3. stack/manifest.json still valid, no claude key, no codex refs
python -c "import json; m=json.load(open('stack/manifest.json')); assert 'claude' not in m; assert 'sharedMcp' in m; assert 'opencode' in m; print('manifest ok')"

# 4. setup.sh no longer calls deleted scripts
Select-String -Path setup.sh, setup.ps1 -Pattern 'claude|generate-claude|validate-claude'
# EXPECTED: no output (the string 'claude' in comments about OpenCode's /connect is fine — you may see it if left in setup.ps1; if so, remove it)

# 5. File count is expected: 181 (initial) - shahil (~66) - team-mcp (4) - flows (1) - codex-template (1) - codex-plugins (1) - claude-scripts (2)
git ls-files | Measure-Object -Line
# EXPECTED: ~106 files (exact number depends on shahil file count; verify with git status that only expected deletions happened)
```

### 5.4 Commit

```powershell
git add -A
git -c user.name='rework' -c user.email='rework@localhost' commit -m "chore: prune dead code (team-mcp scaffold, flows placeholder, codex artefacts)

- delete harness/mcp/team-mcp/ (was a bare http.createServer stub, not a real MCP)
- delete harness/flows/ (empty .gitkeep only)
- delete harness/templates/codex-config.template.toml (Codex CLI, not OpenCode)
- delete harness/plugins/codex.plugins.toml (same reason)
- delete Claude generation and validation scripts (Claude Code support dropped)
- update READMEs to remove dangling references"
```

---

## 6. Phase 3 — Harden installer

**Goal:** Make `setup.sh` and `setup.ps1` safe to run repeatedly, safe to preview, safe to roll back, and impossible to run against a missing prereq.

### 6.1 Design decisions (final — do not deviate)

| Feature | Semantics |
|---|---|
| `--dry-run` | Print every filesystem-modifying action prefixed `[dry-run]`, execute none. Non-mutating commands (version checks, existence checks) still run. Applies to setup.sh, setup.ps1, and every script under `harness/scripts/`. |
| `--reset` | Current behaviour (wipe global OpenCode dirs before rebuild). This becomes **opt-in**, not default. |
| `--incremental` (default) | Only overwrite files that changed; do not wipe global OpenCode dirs. Backups still taken before any overwrite. |
| `--uninstall` | Restore from the newest backup in `~/.config/opencode-harness-backups/` and `~/.harness-backups/`; if none exist, print an error and exit 1. |
| `--doctor` | Run all validation checks + report installed vs pinned versions from `versions.json` + PATH health + writable dirs. Exit 0 if all green, 1 otherwise. |
| Backup retention | Keep the newest **5** backups per backup root, prune older with a stderr notice. Configurable via `HARNESS_BACKUP_RETENTION` env var (positive integer). |
| Pre-flight prereq check | New script `harness/scripts/check-prereqs.sh` (bash) and inline PowerShell function `Test-Prereqs`. Fails **before** any destructive action if `node`, `python3`/`python`, `npm`, or `curl` are missing, or if Node major < required. |
| PowerShell PATH mutation | `Ensure-PathContains` becomes `Ensure-PathContains -Confirm` (uses `$PSCmdlet.ShouldProcess` or a plain `Read-Host` prompt if the function is not part of an advanced cmdlet). |

### 6.2 New file: `harness/scripts/check-prereqs.sh`

Create this bash script. It reads `versions.json`, checks each hard prereq, and exits non-zero with a helpful message on the first failure.

Requirements:
- `set -euo pipefail`
- Check `node` (present and major >= required)
- Check `npm` (present)
- Check `python3` (present) — for reading `versions.json`
- Check `curl` (present) — used by installers
- On failure, print: `Missing prerequisite: <what>. Install <how> and re-run.` and `exit 1`
- On success, print `prereqs ok` and `exit 0`
- Support `--json` flag that prints a JSON summary (used by `--doctor`)

### 6.3 New file: `harness/scripts/uninstall.sh`

Create this bash script. It:
- Reads the newest timestamped dir from `${HOME}/.config/opencode-harness-backups/`
- Copies its contents back to `~/.config/opencode/`, `~/.local/share/opencode/`, `~/.cache/opencode/` (respecting the `config`, `data`, `cache` subdir names used by `build-project-opencode.sh`)
- Refuses to run if the backup root is missing (`exit 1` with message `no backups found; nothing to uninstall`)
- Supports `--dry-run`
- Prints what it restored on success

### 6.4 New file: `harness/scripts/doctor.sh`

Create this bash script. It:
- Runs `check-prereqs.sh --json` and parses the output
- Runs `validate-setup.sh` (silently, capturing exit code)
- Compares installed OpenCode / context-mode / context7-mcp versions against `versions.json` (mismatch = warning, not error)
- Reports PATH entries (`$PATH` split on `:`) that contain `opencode` or `node` binaries
- Reports writable status of `~/.config/opencode`, `~/.local/share/opencode`, `~/.cache/opencode`
- Exit 0 if all green, 1 if any hard failure

Output format: human-readable with `[OK]` / `[WARN]` / `[FAIL]` prefixes on each line.

### 6.5 Edits to `setup.sh`

Add flag parsing at the top (after `set -euo pipefail`):

```bash
DRY_RUN=0
MODE="incremental"
UNINSTALL=0
DOCTOR=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --reset) MODE="reset"; shift ;;
    --incremental) MODE="incremental"; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --doctor) DOCTOR=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: ./setup.sh [options]

Options:
  --dry-run       Print actions without executing them.
  --incremental   Update in place, keep global OpenCode state (default).
  --reset         Wipe global OpenCode config/data/cache before rebuild.
  --uninstall     Restore the newest backup and exit.
  --doctor        Run diagnostics and exit.
  -h, --help      Show this message.
EOF
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
done

export DRY_RUN MODE
```

Add pre-flight check as the **first action** after flag parsing:

```bash
bash "$HARNESS_DIR/scripts/check-prereqs.sh" || exit 1
```

Handle special modes early (before any destructive action):

```bash
if [ "$UNINSTALL" = "1" ]; then
  bash "$HARNESS_DIR/scripts/uninstall.sh" ${DRY_RUN:+--dry-run}
  exit $?
fi
if [ "$DOCTOR" = "1" ]; then
  bash "$HARNESS_DIR/scripts/doctor.sh"
  exit $?
fi
```

Pass `$DRY_RUN` and `$MODE` through to child scripts via env vars. Each child script should check `$DRY_RUN` before any `rm`, `mkdir -p`, `cp -R`, `mv`, or file write.

### 6.6 Edits to `harness/scripts/build-project-opencode.sh`

- Read `DRY_RUN` and `MODE` from env (with defaults).
- Wrap every destructive operation in a `run` function:
  ```bash
  run() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
      printf '[dry-run] %s\n' "$*"
    else
      "$@"
    fi
  }
  ```
  Use `run rm -rf …`, `run cp -R …`, `run mkdir -p …`, `run mv …`. Do **not** wrap the Python heredocs — they only read files.
- When `MODE="incremental"`, skip the three `rm -rf` calls that wipe global OpenCode dirs; only the backup step runs, then the render/copy operations overwrite files in place.
- After backups are taken, invoke retention: keep the newest `${HARNESS_BACKUP_RETENTION:-5}` timestamped subdirs under `$GLOBAL_BACKUP_ROOT`, delete older with a stderr notice.

### 6.7 Edits to `setup.ps1`

Mirror the flag parsing and pre-flight logic in PowerShell:

```powershell
param(
  [switch]$DryRun,
  [switch]$Reset,
  [switch]$Incremental,
  [switch]$Uninstall,
  [switch]$Doctor,
  [switch]$Help
)
if ($Help) { <inline usage>; exit 0 }
if ($Reset -and $Incremental) { Write-Error 'Choose --reset OR --incremental, not both.'; exit 1 }
$Mode = if ($Reset) { 'reset' } else { 'incremental' }  # default incremental
```

- Add a `Test-Prereqs` function that mirrors `check-prereqs.sh`.
- Add `Invoke-Uninstall` and `Invoke-Doctor` functions (native PowerShell — do not shell out to bash).
- Wrap `Remove-Item -Recurse -Force`, `Copy-Item -Recurse`, `New-Item -ItemType Directory` calls in a helper `Invoke-Action` that honours `$DryRun`.
- Change `Ensure-PathContains` to prompt via `Read-Host` before writing to persistent User PATH (skip prompt if `$DryRun`; skip write if user declines).
- Implement backup retention (newest 5) around `$backupRoot` and `$globalBackupRoot`.

### 6.8 Verification (Phase 3)

```powershell
# 1. New scripts exist and are readable
Test-Path harness/scripts/check-prereqs.sh
Test-Path harness/scripts/uninstall.sh
Test-Path harness/scripts/doctor.sh
# EXPECTED: three True

# 2. Help output works
# (You cannot run bash setup.sh here; instead, grep for the help text.)
Select-String -Path setup.sh -Pattern 'Usage: \./setup\.sh'
Select-String -Path setup.ps1 -Pattern 'DryRun'
# EXPECTED: at least one match each

# 3. Dry-run wrapping present in build script
Select-String -Path harness/scripts/build-project-opencode.sh -Pattern 'DRY_RUN|\[dry-run\]'
# EXPECTED: matches for both the env var read and the print prefix

# 4. Backup retention logic present
Select-String -Path harness/scripts/build-project-opencode.sh -Pattern 'HARNESS_BACKUP_RETENTION|retention'
# EXPECTED: at least one match

# 5. setup.ps1 Ensure-PathContains uses a prompt
Select-String -Path setup.ps1 -Pattern 'Read-Host|ShouldProcess' -Context 0,3
# EXPECTED: at least one match in the Ensure-PathContains function region
```

### 6.9 Commit

```powershell
git add -A
git -c user.name='rework' -c user.email='rework@localhost' commit -m "feat(installer): add --dry-run, --incremental, --uninstall, --doctor, prereq check, backup retention

- new scripts: check-prereqs.sh, uninstall.sh, doctor.sh
- setup.sh + setup.ps1 accept --dry-run, --reset, --incremental (default),
  --uninstall, --doctor
- destructive ops in build-project-opencode.sh gated by DRY_RUN and MODE env vars
- backup retention keeps newest 5 (HARNESS_BACKUP_RETENTION overrides)
- setup.ps1 Ensure-PathContains prompts before mutating User PATH"
```

---

## 7. Phase 5 — Quality gaps

**Goal:** Repo looks like a serious open-source project. Ready to publish.

### 7.1 New files

#### `README.md` (repo root)

Structure:
```markdown
# ai-engineering-harness

A repo-first, provider-agnostic harness for OpenCode: skills, MCP definitions, plugin manifests, and setup scripts.

## Quickstart

- macOS/Linux: `./setup.sh`
- Windows: `.\setup.ps1`

See [INSTALL.md](INSTALL.md) for prereqs and options.

## What's inside

<one-line description of harness/, stack/, versions.json, and the setup scripts>

## Philosophy

- Repo is source-of-truth for skills, MCP wiring, plugins. Setup builds outputs.
- Provider auth stays in OpenCode (via `/connect`) — harness never touches API keys.
- Every destructive operation backs up first; retention keeps the newest 5.

## Commands

| Command | What it does |
|---|---|
| `./setup.sh` | Full install (incremental by default) |
| `./setup.sh --dry-run` | Preview without touching the filesystem |
| `./setup.sh --reset` | Wipe global OpenCode state before rebuild |
| `./setup.sh --uninstall` | Restore the newest backup |
| `./setup.sh --doctor` | Diagnostic report |

## Layout

<tree of top-level directories, one-line each>

## License

MIT — see [LICENSE](LICENSE).
```

Keep it under ~80 lines. Link to `INSTALL.md`, `harness/README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `LICENSE`.

#### `LICENSE`

Standard MIT text. Copyright holder: `AI Engineering Harness Contributors`. Year: `2026`.

#### `CHANGELOG.md`

Follows [Keep a Changelog](https://keepachangelog.com/). Initial entry:

```markdown
# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-07-14

Initial fork from upstream (ref sha 24fb9db). See commit history for the rework details.

### Added
- `--dry-run`, `--incremental`, `--reset`, `--uninstall`, `--doctor` flags on setup scripts
- `harness/scripts/check-prereqs.sh`, `uninstall.sh`, `doctor.sh`
- Backup retention (newest 5 by default)
- Pre-flight prerequisite check
- GitHub Actions CI (shellcheck, PSScriptAnalyzer, JSON validation, dry-run matrix)

### Removed
- Claude Code generation pipeline (`shahil/`, `generate-claude-home.sh`, `validate-claude-setup.sh`)
- Codex CLI artefacts (`codex-config.template.toml`, `codex.plugins.toml`)
- `naman/mcp/team-mcp/` scaffold (was a bare HTTP server, not an MCP)
- `naman/flows/` empty placeholder

### Changed
- Renamed `naman/` → `harness/`
- Renamed backup dirs (`.delta-ai-harness-backups` → `.harness-backups`)
- `setup.ps1` `Ensure-PathContains` now prompts before persistent PATH writes
```

#### `CONTRIBUTING.md`

Cover:
- How to propose a new skill (add under `harness/skills/opencode/<name>/SKILL.md` with the standard front-matter)
- How to add a new MCP (edit `stack/manifest.json`, add package to `versions.json` if pinned, update `harness/mcp/README.md`)
- How to add a plugin (edit `harness/plugins/opencode.plugins.json`)
- Coding conventions (shellcheck-clean, PSScriptAnalyzer-clean, 2-space JSON)
- Testing (run `./setup.sh --dry-run` before opening a PR; run `--doctor` to sanity-check)
- Commit style (Conventional Commits)

Keep it under ~120 lines.

#### `.editorconfig`

```ini
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[*.{sh,bash}]
indent_size = 2

[*.{py}]
indent_size = 4

[*.ps1]
end_of_line = crlf
indent_size = 2
```

#### `.shellcheckrc`

```
# shellcheck config
disable=SC1090   # non-constant source (nvm.sh etc.)
disable=SC1091   # source paths that shellcheck cannot follow
external-sources=true
```

#### `versions.json` — add a `harness` field

Add:
```json
"harness": {
  "version": "0.1.0"
}
```

### 7.2 CI workflow: `.github/workflows/ci.yml`

Requirements:
- Trigger on `push` and `pull_request` against `main`.
- Three jobs: `lint-shell`, `lint-powershell`, `dry-run-matrix`.
- `lint-shell`: Ubuntu runner. Runs `shellcheck` on every `.sh` file under the repo. Fails on any warning above severity `warning`.
- `lint-powershell`: Windows runner. Installs `PSScriptAnalyzer`. Runs on `setup.ps1`. Fails on any diagnostic with severity `Error`.
- `dry-run-matrix`: matrix of `ubuntu-latest`, `macos-latest`, `windows-latest`. Installs Node.js at the pinned major, installs Python 3, then runs `./setup.sh --dry-run` (or `.\setup.ps1 -DryRun` on Windows). Must exit 0.
- Add a `validate-json` step that runs `python -m json.tool` over every `.json` file.

### 7.3 Verification (Phase 5)

```powershell
# 1. All new files exist
Test-Path README.md; Test-Path LICENSE; Test-Path CHANGELOG.md; Test-Path CONTRIBUTING.md; Test-Path .editorconfig; Test-Path .shellcheckrc; Test-Path .github/workflows/ci.yml
# EXPECTED: seven True

# 2. LICENSE is MIT
Select-String -Path LICENSE -Pattern 'MIT License'
# EXPECTED: at least one match

# 3. CHANGELOG mentions the fork
Select-String -Path CHANGELOG.md -Pattern '0\.1\.0|Initial fork'
# EXPECTED: at least one match

# 4. CI workflow has the three jobs
Select-String -Path .github/workflows/ci.yml -Pattern 'lint-shell|lint-powershell|dry-run-matrix'
# EXPECTED: three matches

# 5. versions.json has the harness field and is valid
python -c "import json; v=json.load(open('versions.json')); assert v['harness']['version']=='0.1.0'; print('versions ok')"

# 6. Full grep sweep one more time (should already be clean from Phase 1, but confirm)
git grep -n -i -E 'naman|shahil|delta[- ]?(ai|studio|library)|the delta' -- ':(exclude)_HANDOFF_TO_SONNET.md' ':(exclude)CHANGELOG.md'
# EXPECTED: no output (CHANGELOG legitimately mentions the fork source SHA and can stay)
```

### 7.4 Commit

```powershell
git add -A
git -c user.name='rework' -c user.email='rework@localhost' commit -m "docs+ci: add README, LICENSE, CHANGELOG, CONTRIBUTING, editorconfig, CI

- root README with quickstart and command table
- MIT license
- Keep a Changelog format, initial 0.1.0 entry documenting the fork rework
- CONTRIBUTING guide covering skills, MCP, plugins, testing, commit style
- .editorconfig + .shellcheckrc for consistent formatting
- GitHub Actions CI: shellcheck, PSScriptAnalyzer, dry-run matrix (ubuntu/macos/windows), json validation
- versions.json now carries harness.version = 0.1.0"
```

---

## 8. Final verification

After all four commits, from `D:\ai-harness`:

```powershell
# 1. Four commits after initial
git log --oneline
# EXPECTED: 5 commits total (initial + 4 phase commits)

# 2. No remotes
git remote -v
# EXPECTED: empty

# 3. Branch is main
git branch --show-current
# EXPECTED: main

# 4. Working tree clean
git status
# EXPECTED: nothing to commit, working tree clean

# 5. Comprehensive grep
git grep -n -i -E 'naman|shahil|delta[- ]?(ai|studio|library)|the delta|generate-claude|validate-claude|team-mcp|codex' -- ':(exclude)_HANDOFF_TO_SONNET.md' ':(exclude)CHANGELOG.md'
# EXPECTED: no output

# 6. Delete this handoff and commit its removal
Remove-Item _HANDOFF_TO_SONNET.md
git add -A
git -c user.name='rework' -c user.email='rework@localhost' commit -m "chore: remove rework handoff (execution complete)"

# 7. Final log
git log --oneline
# EXPECTED: 6 commits total
```

If all six checks pass, stop and hand back to the user with a summary of the final state (commit list, file count, any `_OBSERVATIONS.md` you may have written).

---

## 9. If you get stuck

- **A rename breaks a script:** revert with `git checkout -- <file>`, re-read the file, redo the edit surgically. Do not force through it.
- **A verification step fails and you can't tell why:** stop, write your findings to `_OBSERVATIONS.md`, hand back to the user. Do not commit a broken phase.
- **You find a company reference not in the naming map (§3):** add it to `_OBSERVATIONS.md`, apply the same transformation logic (`delta-*` → strip; personal names → drop), commit as part of Phase 1.
- **A shell/PowerShell idiom you're using might behave differently on Windows vs Unix:** flag it in `_OBSERVATIONS.md` and prefer the more portable idiom. Do not run untested logic against real filesystem paths.
- **You want to add a feature that isn't in this handoff:** don't. Note it in `_OBSERVATIONS.md` for the user to review.

---

## 10. Out of scope (do NOT do)

- **Phase 4 (Node.js rewrite of setup.ps1):** deferred. Do not touch this.
- **Phase 6 (port shahil hook patterns to OpenCode):** deferred.
- **Phase 7 (rework default MCP bundle):** decision was to keep current defaults. Do not change.
- **Adding new skills, MCPs, or plugins:** out of scope.
- **Renaming files inside `harness/skills/`:** these are the payload; do not touch.
- **Rewriting the `understand*` skill Python/mjs helpers:** out of scope.
- **Modifying `versions.json` version pins:** the pins stay; only the new `harness` field is added in Phase 5.
- **Configuring a git remote or pushing:** absolutely not.

---

## 11. Working environment reminder

- **Path:** `D:\ai-harness`
- **Shell:** PowerShell 7+ (`pwsh`). Use the `workdir` parameter on shell tools, not `cd` inside commands.
- **Git identity:** use `-c user.name='rework' -c user.email='rework@localhost'` on every commit; do not `git config` globally.
- **Editor tools:** prefer `Read` + `Edit` for surgical changes; `Write` for new files. Grep with `git grep`, not `Select-String`, when scoping to tracked files.
- **No bash on this host:** you cannot execute `setup.sh` here. Rely on parse-level verification (grep, `python -m json.tool`) and the CI matrix (added in Phase 5) for runtime validation. The user will run `./setup.sh` on their macOS/Linux machine to end-to-end test after handback.

---

*End of handoff. Delete this file after §8 verification passes.*
