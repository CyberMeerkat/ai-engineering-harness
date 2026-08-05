# BMAD Agents

This directory contains OpenCode agent files for the five core BMAD Method personas. They are installed **globally** to `~/.config/opencode/agents/` by `setup.sh` / `setup.ps1`, making them available in every project you open in OpenCode — consistent with the harness philosophy of globally installing things that should apply everywhere.

## The BMAD workflow

BMAD organises AI-assisted development into four phases. Each agent owns one phase and hands off to the next:

```
Phase 1: Analysis      → Mary   (bmad-analyst)   brainstorming, research, product brief
Phase 2: Planning      → John   (bmad-pm)         PRD, epics, stories
           + Sally (bmad-ux)          UX spec, interaction design
Phase 3: Solutioning   → Winston (bmad-architect)  architecture, implementation readiness
Phase 4: Implementation → Amelia (bmad-dev)         TDD, story implementation, QA
```

## Two levels of BMAD

**These global agents** give you the personas in any project — lightweight, always available.

**Full BMAD** (installed per project via `npx bmad-method install`) adds:
- Structured workflow skills (e.g. `bmad-prd`, `bmad-architecture`, `bmad-dev-story`)
- Artifact templates and output directories
- Team and user customization via `_bmad/custom/*.toml`
- Python scripts that merge config layers

Every project built using this harness should have BMAD installed. See `harness/bmad/README.md` for setup guidance.

## Adding or customising an agent

To add a new agent or override a persona, add or edit a `.md` file here. The frontmatter `description` is what OpenCode uses to decide which agent to load — make it specific and front-load the trigger keywords.

See `~/.config/opencode/agents/` for the deployed copies, and the `customize-opencode` skill for the full OpenCode agent spec.
