# Observations

Items noted during the rework but not acted on (per handoff §9 and §10 "do not improve anything not listed").

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

*Generated during the rework execution (Phases 1–5). Review before publishing.*
