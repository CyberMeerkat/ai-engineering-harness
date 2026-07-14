# Stack Composition

This folder is the composition layer for the repo.

It defines canonical shared integrations once, then generators build tool-specific outputs for:

- OpenCode
- Claude Code

## Rules

- `naman/` remains the source for OpenCode/shared skills, MCP inventory, plugin templates, and setup helpers.
- `shahil/portable/` remains the source for Claude-specific harness assets.
- `manifest.json` is the canonical overlap registry for shared MCP integrations.
- Per-tool generated outputs should be derived from this layer instead of hand-maintained in multiple places.

## Current generators

- `naman/scripts/build-project-opencode.sh` reads this manifest for OpenCode MCP and plugin generation.
- `naman/scripts/generate-claude-home.sh` reads this manifest for Claude plugin enablement.
