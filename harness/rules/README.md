# Always-Loaded Rules

Markdown files here are copied to `~/.config/opencode/rules/` and wired into the global OpenCode config's `instructions` array on every `./setup.sh` run — meaning their content is loaded into every OpenCode session's context automatically, in every project, without the agent needing to be told or having to load a skill on demand.

Use this folder sparingly. Every file here is **always** in context, in every session — unlike skills (loaded on demand) or plugins (silent enforcement, zero context cost). Reserve it for standing behavioral policy that should apply everywhere, all the time.

## Current contents

| File | What it covers |
|---|---|
| `branching.md` | Feature/fix branch naming and workflow, PR conventions, and the non-negotiables around merging and pushing to protected branches. Backed by `../plugins/local/protect-branches.mjs` and the `permission.bash` rules in `stack/manifest.json` for the cases that need actual enforcement, not just guidance. |
| `context-discipline.md` | Cache-prefix discipline (volatile content at the tail, no interpolation into stable content), caps on agent-maintained state files, and keeping bulk content out of the main context. Cost rules — each one compounds silently rather than failing loudly, which is why they are stated rather than left to judgement. Partially enforced: `.github/scripts/test-structural.mjs` fails if any file in this folder interpolates a timestamp or run ID, since that would bust the prompt cache on every turn of every session. |
| `project-setup.md` | BMAD detection and the expectation that every project under this harness uses the BMad Method. Backed by `../plugins/local/check-bmad.mjs`. |

## Adding a new rule

1. Add a `.md` file here.
2. `stack/manifest.json`'s `opencode.rulesSources` will pick it up automatically on the next `./setup.sh` run — no per-file registration needed (same pattern as `plugins/local/`).
3. If the rule has a hard-enforcement counterpart (something that should actually block or prompt, not just be documented), consider whether it belongs as a plugin (`../plugins/local/`) or a `permission` rule (`stack/manifest.json`) too — rules alone are guidance the model can still get wrong; hooks and permission checks are deterministic.
