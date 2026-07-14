# UI Design System — Mandatory Rule

> Loaded every session. Ensures all UI work routes through the design intelligence system.

## The Rule

When ANY task involves **creating, modifying, or reviewing** UI components, screens, pages, or visual elements, you MUST:

1. **Generate a design system** before writing UI code:
   ```bash
   python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<product-context>" --design-system -p "<project>"
   ```

2. **Apply** the returned design system (pattern, style, colors, typography, effects) to your output

3. **Cross-reference against the project's brand source-of-truth** — project brand tokens ALWAYS override generic design system suggestions

4. **Check against anti-patterns** returned by the tool

5. **Run the pre-delivery checklist** before marking complete

## Applies To

Files: `.vue`, `.tsx`, `.jsx`, `.css`, `.scss`, `.ts` (component files), React Native StyleSheet, Tailwind config, any file producing visual output.

## When to Skip

- Pure backend logic (API routes, services, database)
- Infrastructure/DevOps (Docker, nginx, scripts)
- Non-visual scripts or automation
- The user explicitly says "skip design system" or provides exact specs

## Reference

For full rules, 150+ design guidelines, and output interpretation:
```
~/.claude/agent_docs/ui-ux-pro-max-reference.md
```

For project-specific brand overrides (if exists):
```
.claude/agent_docs/{{project}}-design-overrides.md
```
