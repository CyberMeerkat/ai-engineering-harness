# Observations

Items noted during the rework but not acted on (per handoff §9 and §10 "do not improve anything not listed"), plus a record of real bugs CI caught after publishing.

---

## 0. Real bugs found and fixed via CI (resolved)

The rework was authored on a Windows host with no bash available, so the bash-side scripts were never actually executed locally — only reasoned through. Publishing to GitHub and letting CI run on real ubuntu/macos/windows runners caught concrete bugs that local review missed:

1. **`declare -A` (bash 4+ only) in `check-prereqs.sh` and `uninstall.sh`** — macOS ships bash 3.2 by default (frozen since 2007 over GPLv3 licensing) and does not support associative arrays. Fixed by replacing with plain named variables / a case-statement lookup function.
2. **`doctor.sh` piped JSON into `python3 - <<'PY'`** — combining a pipe with `python3 -` (read script from stdin) and a heredoc is broken: the heredoc hijacks stdin for the script source, so `json.load(sys.stdin)` has nothing to read. Fixed by capturing the piped output into a variable and passing the script via `python3 -c` instead.
3. **`--dry-run` performed real installs** — `install-opencode.sh`, `install-node.sh`, `install-mcp-deps.sh`, and `install_opencode_desktop()` in `setup.sh` had no DRY_RUN awareness at all; they only had "already installed, skip" fast paths. On a clean CI runner (nothing pre-installed), dry-run fell through to the real `npm install -g` / `brew install` / `curl | hdiutil` logic. This was invisible during local testing because opencode/node/mcp deps were already installed on the dev host, so the early-exit paths were the only ones ever exercised.
4. **`build-project-opencode.sh` sourced `.env.team` unconditionally** — dry-run correctly skips creating the file, but the very next line did `. "$ENV_FILE"` unguarded, crashing the whole script under `set -e` when the file didn't exist. Same bug class as the `setup.ps1 Validate-Setup` fix below, just the bash twin, missed because there was no bash to test against locally.
5. **`setup.ps1 Assert-NodeVersion`** had the same real-install gap as #3, on the PowerShell side.
6. **`setup.sh`'s call to `validate-setup.sh`** was unguarded — same bug class as `setup.ps1`'s original `Validate-Setup` issue, just not caught until CI ran the bash path for real.

All six are fixed as of commit `91a2d26`. CI is green across ubuntu-latest, macos-latest, and windows-latest.

**Takeaway:** local review and reasoning caught the *design* of dry-run mode correctly, but only real execution on real bash 3.2 (macOS) and a clean environment (no pre-installed tools) surfaced the actual gaps. Any future changes to the install scripts should be validated by pushing and watching CI, not just by local reasoning on a host where everything is already installed.

---

## 1. `codex` grep false positives in Phase 5 / final verification

The handoff's final grep pattern includes `codex` as a match term. This produces 8 false-positive matches that are intentional content, not Codex CLI coupling:

| File | Match | Why it's safe |
|---|---|---|
| `harness/SANITISATION.md:13` | "Codex config and vendor system skills" | Historical record of what was removed from the upstream import. The word "Codex" here means "OpenAI Codex CLI tool content", confirming it was already removed. |
| `harness/skills/shared/understand-dashboard/SKILL.md` (×3 paths) | `~/.codex/understand-anything/...` | Install path for the `understand-anything` plugin. `~/.codex/` is this plugin's own directory, not an OpenAI Codex CLI reference. |
| `harness/skills/shared/understand-domain/SKILL.md` | same | Same plugin path |
| `harness/skills/shared/understand/SKILL.md` | same | Same plugin path |

**Recommendation:** Remove `codex` from the final grep pattern. The patterns that matter are the two engineer names and the company name regex — not `codex`. Alternatively, exclude the skills payload directory from the sweep with `:(exclude)harness/skills/`.

---

## 2. LF→CRLF warnings on commit

Git emits `LF will be replaced by CRLF` warnings for edited files on this Windows host. The `.editorconfig` added in Phase 5 sets `end_of_line = lf` for all files (except `.ps1`), which will normalise this once a `.gitattributes` is added or `core.autocrlf` is configured.

**Recommendation (optional, post-rework):** Add a `.gitattributes` file with `* text=auto eol=lf` and `*.ps1 text eol=crlf` to enforce consistent line endings across all platforms.

---

## 3. `harness/SANITISATION.md` still mentions "team" framing

The file refers to "team-shareable assets" and "team-authored skills" in its remaining body. These phrases are benign for a personal harness but slightly odd. Not changed because the file is a historical record and the handoff only asks to prepend one note to it.

---

## 4. Skill relevance review (personal harness, not team harness)

Two of the three OpenCode-specific skills were originally authored for a team/workplace context and may not fit a personal harness:

- `incident-report-logger` — produces incident reports "for clients, outages, and remediation summaries" in a fixed operational format. This reads as workplace/on-call tooling, not personal dev harness content.
- `tailscale-opencode-web` — runs OpenCode Web via Tailscale. This is **directly relevant** to the stated goal of using the harness across multiple devices (remote access to a running OpenCode session) — recommend keeping.
- `frontend-design` — generically useful, no team-specific framing. Recommend keeping.

**Not acted on** — this is a content/curation decision for the harness owner, not a bug. Flagging for a decision.

---

*Generated during the rework execution (Phases 1–5) and the post-publish CI hardening pass. Review before publishing further changes.*
