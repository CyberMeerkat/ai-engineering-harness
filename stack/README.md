# Stack Composition

This folder is the composition layer for the repo.

It defines canonical shared integrations once, then generators build tool-specific outputs.

## Rules

- `harness/` is the source for OpenCode/shared skills, MCP inventory, plugin templates, and setup helpers.
- `manifest.json` is the canonical registry for shared MCP integrations.
- Per-tool generated outputs should be derived from this layer instead of hand-maintained in multiple places.

## Current generators

- `harness/scripts/build-project-opencode.sh` reads this manifest for OpenCode MCP and plugin generation.
