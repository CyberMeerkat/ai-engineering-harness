> This file documents what was removed when forking upstream. Historical only.

# Sanitisation Notes

The directory was reduced to portable, team-shareable assets only.

## Removed from the initial import

| Removed content | Why it was removed |
|---|---|
| Personal OpenCode config and wrappers | Useful for one machine, not as team source-of-truth. |
| Scheduler/runtime scripts | Operational plumbing, not shared skill content. |
| Codex config and vendor system skills | Tool-vendor content, not team-authored assets. |
| Machine-specific rule files | Unsafe or overly local for shared reuse. |

## Remaining review guidance

- `skills/opencode/` should stay focused on team-authored skills.
- `skills/shared/` is appropriate only if the team wants to vendor and maintain that skill family here.
- Any future MCP config checked in here should use templates and avoid secrets.
- Password-bearing instructions should use placeholders or env variables, never personal defaults.
