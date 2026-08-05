# Project Setup — BMAD Method

This is a standing policy for every project you work in. It is always loaded — you do not need to be told this on every session.

## BMAD is required in every project

Every project built under this harness uses the **BMad Method** for structured AI-driven development. BMAD provides the workflow skills (PRD creation, architecture, sprint planning, story implementation) that the global agents (Mary, John, Sally, Winston, Amelia) invoke.

**Before making any significant changes to a project, check whether BMAD is installed.**

## How to detect whether BMAD is installed

The authoritative check is the `_bmad/` directory in the project root:

```bash
# bash / macOS / Linux
test -d _bmad && echo "BMAD installed" || echo "BMAD NOT installed"

# Windows PowerShell
Test-Path _bmad
```

Secondary check — BMAD workflow skills should be present under `.agents/skills/`:
```bash
# bash
ls .agents/skills/ 2>/dev/null | grep bmad

# PowerShell
Get-ChildItem .agents/skills -ErrorAction SilentlyContinue | Where-Object Name -like 'bmad-*'
```

If `_bmad/` is absent, **BMAD is not installed**. Stop and install it before touching project files.

## How to install BMAD in a project

Run this from the **project root** — non-interactively, targeting OpenCode:

```bash
npx bmad-method install --tools opencode --yes
```

What this creates:
- `_bmad/` — project BMAD root (config, custom overrides, scripts)
- `_bmad-output/planning-artifacts/` — where PRDs, architecture docs, etc. land
- `_bmad-output/implementation-artifacts/` — where stories, sprint plans, etc. land
- `.agents/skills/` — 46 BMAD workflow skills
- `.opencode/commands/` — 46 BMAD commands

**Do not skip this step.** If you are not sure whether you have permission to run installs, ask the user first.

## After installing — apply harness team customizations

BMAD creates its own `_bmad/custom/config.toml` as an empty template on install. The harness version of this file (and the five agent overlay files) should **replace** it — the harness version is the point of standardisation.

Fetch from GitHub and apply with force (handles the config.toml collision):

**bash / macOS / Linux:**
```bash
CUSTOM_URL="https://raw.githubusercontent.com/CyberMeerkat/ai-engineering-harness/main/harness/bmad/custom"
mkdir -p _bmad/custom

for f in config.toml \
          bmad-agent-analyst.toml \
          bmad-agent-pm.toml \
          bmad-agent-ux-designer.toml \
          bmad-agent-architect.toml \
          bmad-agent-dev.toml; do
  curl -fsSL "$CUSTOM_URL/$f" -o "_bmad/custom/$f"
done
```

**Windows PowerShell:**
```powershell
$base = "https://raw.githubusercontent.com/CyberMeerkat/ai-engineering-harness/main/harness/bmad/custom"
New-Item -ItemType Directory -Force -Path "_bmad/custom" | Out-Null

@(
  "config.toml",
  "bmad-agent-analyst.toml",
  "bmad-agent-pm.toml",
  "bmad-agent-ux-designer.toml",
  "bmad-agent-architect.toml",
  "bmad-agent-dev.toml"
) | ForEach-Object {
  Invoke-WebRequest "$base/$_" -OutFile "_bmad/custom/$_" -ErrorAction Stop
}
```

> **Note on config.toml collision:** `npx bmad-method install` always generates `_bmad/custom/config.toml` as a blank template. The harness version has team-wide defaults and should win. The download above overwrites it. This is intentional.

If the local harness clone is available (e.g. at `D:\ai-harness`), you may copy directly instead:
```powershell
# Only if harness clone is locally accessible
Copy-Item D:\ai-harness\harness\bmad\custom\* _bmad\custom\ -Force
```

## Verification after install

```bash
# Should show _bmad/, .agents/skills/, and harness TOML files
test -d _bmad && test -d _bmad/custom && ls _bmad/custom/*.toml
ls .agents/skills/ | grep bmad | wc -l   # expect ~46
```

## When to install vs when to ask

| Situation | Action |
|---|---|
| Starting work in a project with no `_bmad/` | Install BMAD and apply customizations before touching code |
| Returning to a project that already has `_bmad/` | No action needed |
| User explicitly says "skip BMAD for this project" | Proceed; prefix commands with `HARNESS_SKIP_BMAD_CHECK=1` to suppress warnings |
| Unsure whether the project is in scope for BMAD | Ask the user |

## The four BMAD phases — which agent handles what

| Phase | Agent | Key output |
|---|---|---|
| 1 — Analysis | Mary (bmad-analyst) | Product brief, market/domain/technical research |
| 2 — Planning | John (bmad-pm) + Sally (bmad-ux) | PRD, epics/stories, UX spec → `_bmad-output/planning-artifacts/` |
| 3 — Solutioning | Winston (bmad-architect) | Architecture doc, implementation readiness → `_bmad-output/planning-artifacts/` |
| 4 — Implementation | Amelia (bmad-dev) | Stories, sprint plans, code → `_bmad-output/implementation-artifacts/` |

Always start at Phase 1 for net-new features unless the user explicitly places you at a later phase.
