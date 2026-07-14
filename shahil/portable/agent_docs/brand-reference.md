# Brand — Reference Documentation

> Detailed procedures, templates, and checklists for each `/brand` flag.
> Loaded on demand by the brand skill dispatcher.

## Canonical Brand Source of Truth

> **CUSTOMIZATION REQUIRED:** Each project must define a brand source-of-truth document.
> This is the single file that contains the brand's identity, voice, visual rules, and decision framework.
>
> **How to set up:**
> 1. Create a brand constitution file (e.g., `docs/brand/BRAND_SOUL.md` or `intelligence/specification/brand/`)
> 2. Replace the path below with the actual path to your brand document
> 3. The brand file should contain at minimum:
>    - Brand identity (name, promise, archetype, values)
>    - Target audience (demographics, personas, the "user test" — who must feel seen?)
>    - Voice & tone rules (how the brand speaks, per context/vertical)
>    - Visual identity (color tokens, typography scale, button styles, motion)
>    - Product architecture (tiers, signature products, sub-brands if any)
>    - Content & editorial rules (photography, blog, social, email)
>    - Brand decision framework (tests to validate any output)
>    - Technical tokens (CSS custom properties, Tailwind/React Native tokens)
>
> **If no brand file exists:** Run `--guidelines` to generate a baseline from the codebase,
> then refine it into a proper brand document.

Before any brand evaluation, read the brand source-of-truth file:
```
<BRAND_SOURCE_PATH>  <!-- Replace with your brand file path -->
```

## Brand Token Reference

> **CUSTOMIZATION REQUIRED:** Replace these placeholder tokens with your project's actual brand tokens.
> These are used during `--check` and `--tokens` scans to validate code against the brand.

| Token | Name | Hex | Use |
|-------|------|-----|-----|
| `--color-primary` | Primary | `#______` | CTA buttons, active nav, key interactive elements |
| `--color-text-primary` | Text Primary | `#______` | Headings, nav labels, prices |
| `--color-bg-primary` | Background | `#______` | Page background |
| `--color-text-secondary` | Text Secondary | `#______` | Body text, descriptions |
| `--color-bg-section` | Section Background | `#______` | Alternating section backgrounds |
| `--color-bg-accent` | Accent Background | `#______` | Hover states, accent areas |
| `--color-border` | Border | `#______` | Dividers, input/card borders |
| `--color-text-muted` | Muted Text | `#______` | Placeholders, disabled states |
| `--color-accent` | Accent | `#______` | Accent highlights (use sparingly) |
| `--color-success` | Success | `#______` | Success states |

> **Instructions to fill:** Run your project, inspect the CSS custom properties or Tailwind config,
> and populate each row. Add additional rows for sub-brand colors, status colors, etc.

**Typography:**

| Role | Font Family | Sizes/Weights |
|------|------------|---------------|
| Display / Headings | `"______", serif` | H1: __px, H2: __px, H3: __px, H4: __px |
| Body / UI | `"______", sans-serif` | Body: __px, Small: __px, Caption: __px |

> **Instructions:** Identify the heading and body fonts from your project's CSS/config.
> Document the exact type scale — sizes, weights, line-heights, letter-spacing.

**Button Styles:**

| Style | Background | Text Color | Border | Radius | Height |
|-------|-----------|-----------|--------|--------|--------|
| Primary | `#______` | `#______` | None | __px | __px |
| Secondary | Transparent | `#______` | 1px solid `#______` | __px | __px |

> **Instructions:** Document every button variant in the design system.
> Include hover, focus, active, and disabled states.

## Design System Cross-Reference (ui-ux-pro-max)

When running `--check` or `--tokens`, also run the design system generator and compare output:

```bash
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<project-context>" --design-system -p "<project>"
```

Compare the returned design system against the project's actual tokens:
- Tokens that align with the design system recommendation → **PASS**
- Tokens that intentionally diverge for brand reasons → **OVERRIDE** (document reason)
- Missing tokens that the design system recommends adding → **SUGGESTION**

For full integration rules: read `~/.claude/agent_docs/ui-ux-pro-max-reference.md`

## Brand Decision Framework

> **CUSTOMIZATION REQUIRED:** Define 5-8 tests that every output must pass before shipping.
> These should reflect your brand's core values and audience.
>
> **Example tests (replace with your own):**
> 1. **Audience Test** — Would your target user feel seen by this?
> 2. **Quality Test** — Does this feel premium / appropriate for your brand tier?
> 3. **Voice Test** — Is the brand speaking consistently? (whispering, not shouting?)
> 4. **Meaning Test** — Does this connect to something meaningful for the user?
> 5. **Simplicity Test** — Can you remove something and make it better?

## Triage Integration

After every operation, update `## Brand & Design` in `.claude/state/triage.md`:

```markdown
## Brand & Design
**Updated:** <YYYY-MM-DD HH:MM>
**Brand compliance:** <N>% (tokens vs hardcoded)

### Design System Health
- Components: <N> UI library + <N> custom
- Token coverage: <N>% of color/spacing/typography values use tokens
- Assets: <N> in assets/

### Violations
- <hardcoded values, naming inconsistencies, missing tokens>

### Figma Drift
- Last checked: <date>
- Drift: <NONE / N components differ>

### Recommendations
- <e.g., "Convert 12 hardcoded hex values to CSS variables">
```

## UCL Integration

The Use Case Log is the shared contract between product-owner, dev-manager, and brand. It defines every use case, acceptance criterion, and known bug across all actors. You **reference** it to understand which use cases have UI-facing ACs that need brand compliance.

**Source of truth:** `.claude/data/plans/UCL-PROJECT.md`
**Triage summary:** `## Use Case Log` section in `.claude/state/triage.md`

### How brand uses the UCL

1. **Scope brand checks to active UCs:** when running `--check`, cross-reference the UCL to identify which use cases have UI-facing ACs. Focus brand violations on screens/components that serve those UCs.
2. **Brand compliance per UC:** in your violation report, group findings by the UC they affect. A violation in the vendor subscription page maps to UC-V05 (or whichever UC covers subscriptions). This lets product-owner know exactly which use cases have brand gaps.
3. **Brand gate references UCs:** when product-owner asks for a brand gate on a delivered item, your PASS/FAIL response should reference the UC(s) and AC(s) that were checked. "PASS — UC-V03 AC-1,2,3 screens are brand-compliant" is actionable. "PASS — looks fine" is not.
4. **UCL bugs with brand impact:** if a UCL bug affects UI (e.g., BUG-C02 "photo upload not integrated into ConfiguratorScreen"), note it in your brand state as a screen that cannot be fully audited until the bug is fixed.
5. **New UI-facing ACs need brand review:** when product-owner adds new UCs with UI-facing ACs, those ACs inherit a brand gate requirement. Surface any un-reviewed UI ACs in your `--session-start` output.

### Rules

- Never block a brand gate for UCs with no UI-facing ACs (pure backend UCs are not your domain)
- Always reference UC IDs when reporting violations — this is how product-owner maps brand issues back to delivery items
- If a UC's screens cannot be audited (e.g., the feature isn't built yet), report it as "NOT AUDITABLE — <reason>" rather than PASS or FAIL

---

## Phase 0 — Context Gathering (always run first)

```
1. Read the brand source-of-truth file (see "Canonical Brand Source" section above)
2. Read `.claude/state/triage.md` — cross-skill state (including ## Use Case Log)
3. Read `.claude/data/plans/UCL-PROJECT.md` — full use case log with all ACs
4. Read `.claude/state/brand.md` — your domain state (last scan results, compliance score)
4. Read `<web-dir>/CLAUDE.md` — design system rules and conventions
5. Read `<web-dir>/components.json` — component library configuration (e.g., shadcn-vue)
6. Read `<web-dir>/src/lib/utils.ts` — utility helpers (e.g., cn() for class merging)
7. Scan Tailwind config: `<web-dir>/tailwind.config.*` or CSS with @theme
8. Glob `<web-dir>/src/components/ui/**/*.vue` — UI library components
9. Glob `<web-dir>/src/components/**/*.vue` — custom components
10. Glob `<web-dir>/public/assets/**/*` — brand assets (SVGs, images)
11. Read `<web-dir>/src/assets/` — embedded assets if any
```

**Critical:** Step 1 is non-negotiable. The brand source-of-truth file IS the brand. Every finding, score, and recommendation must be traceable to a rule in that document.

> **How to discover the brand file:** Look for files named `*soul*`, `*brand*`, `*identity*`,
> or `*guidelines*` in the project's docs, intelligence, or specification directories.
> If none exist, scan the Tailwind config and CSS for token definitions to build a baseline.

### Design System Knowledge

> **CUSTOMIZATION REQUIRED:** Update this section to match your project's stack.

This skill understands the project design system:

- **Framework:** ___ (e.g., Vue 3 + Vite, React + Next.js, Svelte)
- **Component library:** ___ (e.g., shadcn-vue, shadcn/ui, Radix, headless-ui)
- **Components path:** `<web-dir>/src/components/ui/`
- **Utility:** ___ (e.g., `cn()` for conditional class merging)
- **Config:** ___ (e.g., `components.json` for shadcn)
- **Convention:** CSS variables / Tailwind classes for theming, NOT hardcoded hex/rgb values
- **Brand source:** ___ (path to brand constitution file)

---

## Flag: --session-start

Output this structured briefing:

```
=== Brand Health Dashboard ===
Project:        <project-name>
Brand source:   <brand-file-path or "NOT CONFIGURED">
Design system:  <framework> + <component-library>
──────────────────────────────
DESIGN SYSTEM STATUS
  UI components:    <N> installed
  Custom components: <N>
  Design rules file: <present / missing>

TOKEN COVERAGE
  Colors:     <N>% using tokens (N/M values)
  Typography: <N>% using tokens (N/M values)
  Spacing:    <N>% using tokens (N/M values)
  Overall:    <N>%

BRAND ASSETS
  SVGs:       <N> in public/assets/
  Images:     <N>
  Unused:     <N> (referenced nowhere in code)

FIGMA DRIFT
  Last checked: <date or "never">
  Status:       <UNKNOWN / CLEAN / N components differ>

VIOLATIONS
  <N> hardcoded colors found
  <N> inconsistent component usages
  <N> naming convention issues

UCL BRAND COVERAGE
  UI-facing UCs:    <N> (of <total> UCs)
  Brand-audited:    <N>/<N> UI UCs checked
  Pending review:   <N> UI ACs with no brand gate
  Not auditable:    <N> (feature not built / blocked by bug)

BRAND HEALTH: <GREEN / YELLOW / RED>
  <1-line justification>
===============================
```

---

## Flag: --check

Full brand consistency audit.

### Step 1 — Token Scan
Scan all component files (`.vue`, `.tsx`, `.jsx`, `.svelte`) for:

1. **Hardcoded colors:** hex values (`#fff`, `#1a2b3c`), `rgb()`, `rgba()`, `hsl()` in:
   - `style` blocks
   - Inline `style` attributes
   - Class attributes that contain color literals instead of design system classes
2. **Hardcoded typography:** pixel font sizes (`font-size: 14px`), font-family declarations not using CSS variables
3. **Hardcoded spacing:** pixel values in margins/padding that should use the design system spacing scale

For each finding, record:
- File path and line number
- The hardcoded value
- Suggested token/variable replacement (referencing the brand source-of-truth)

### Step 2 — Component Consistency
Check component library usage:

1. Scan for raw HTML elements that should use the component library:
   - `<button>` instead of `<Button>`
   - `<input>` instead of `<Input>`
   - `<select>` instead of `<Select>`
   - `<table>` instead of `<Table>`
   - `<dialog>` instead of `<Dialog>`
2. Check that all component imports use the correct alias paths
3. Verify class merging utilities are used (not string concatenation)

### Step 3 — CSS Variable Consistency
1. Scan CSS files and `<style>` blocks for custom property definitions
2. Verify they follow the naming convention from the design system docs
3. Check for duplicate or conflicting variable definitions

### Step 4 — Asset Naming
1. Check all files in assets directories for naming consistency:
   - Lowercase kebab-case expected
   - Consistent prefixing (e.g., `icon-`, `logo-`, `illustration-`)
2. Check SVGs for optimization (viewBox present, no unnecessary metadata)

### Step 5 — Calculate Compliance Score
```
Brand Compliance Score: <N>%

Token usage:       <N>% (<good/fair/poor>)
Component usage:   <N>% (<good/fair/poor>)
CSS consistency:   <N>% (<good/fair/poor>)
Asset naming:      <N>% (<good/fair/poor>)

Violations: <N> total
  CRITICAL: <N> (raw HTML replacing component library)
  HIGH:     <N> (hardcoded colors in components)
  MEDIUM:   <N> (hardcoded spacing/typography)
  LOW:      <N> (naming conventions, minor inconsistencies)
```

### Step 6 — Output Violation Report
List all violations grouped by severity, with file paths and suggested fixes.

### Step 7 — Update State Files
Update `.claude/state/brand.md` with scan results and compliance score.

---

## Flag: --fix

Auto-fix detected brand violations.

### Step 1 — Read Current Violations
Read `.claude/state/brand.md` for the latest violation list from `--check`.
If no recent check exists, run `--check` first.

### Step 2 — Categorize Fixable Items

**Auto-fixable:**
- Hex colors with known token mappings -> replace with CSS variable or design system class
- Raw HTML elements -> component library import + replacement
- Missing class merging utility usage

**Manual review required:**
- Colors with no clear token match (may be intentional one-offs)
- Complex component replacements that change behavior
- Asset renaming (may break references)

### Step 3 — Apply Fixes
For each auto-fixable violation:
1. Read the file
2. Apply the fix using Edit tool
3. Verify the fix doesn't break the template structure
4. Record the fix in state file

### Step 4 — Output Fix Report
```
=== Brand Fixes Applied ===
Fixed: <N> violations
Skipped: <N> (require manual review)
Remaining: <N> total violations

FIXES APPLIED:
  <file>:<line> — replaced #1a2b3c with var(--primary)
  <file>:<line> — replaced <button> with <Button>
  ...

MANUAL REVIEW NEEDED:
  <file>:<line> — unknown color #xyz, no token match
  ...
============================
```

### Step 5 — Re-scan
After fixes, run a quick re-scan to update the compliance score.

---

## Flag: --assets

Brand asset inventory.

### Step 1 — Discover Assets
1. Glob `<web-dir>/public/assets/**/*` — all public assets
2. Glob `<web-dir>/src/assets/**/*` — embedded assets
3. Categorize: SVG icons, logos, illustrations, raster images, fonts

### Step 2 — Usage Map
For each asset:
1. Grep all component and style files for references to the asset filename
2. Record: which components use it, how many references

### Step 3 — Identify Issues
- **Unused assets:** present in assets/ but referenced nowhere
- **Missing assets:** referenced in code but file doesn't exist
- **Duplicate assets:** same visual in different files/formats
- **Unoptimized SVGs:** missing viewBox, inline styles, unnecessary metadata

### Step 4 — Output Inventory
```
=== Brand Asset Inventory ===
Total assets: <N>

ICONS (<N>)
  icon-name.svg — used in: ComponentA, ComponentB (<N> refs)

LOGOS (<N>)
  logo-name.svg — used in: AppSidebar (<N> refs)

ILLUSTRATIONS (<N>)
  ...

ISSUES
  UNUSED: <asset> — no references found
  MISSING: <asset> referenced in <component> but file not found
  UNOPTIMIZED: <asset> — <issue description>

Asset Health: <N> issues found
==============================
```

---

## Flag: --tokens

Focused design token audit.

### Step 1 — Discover Token Definitions
1. Read Tailwind config for theme definitions (colors, spacing, typography)
2. Read CSS files for `--variable` definitions (`:root`, `[data-theme]`, etc.)
3. Read the brand source-of-truth file for documented token conventions
4. Build the canonical token map: name -> value -> usage context

### Step 2 — Scan for Hardcoded Values
Scan all component and style files for values that should use tokens:

**Colors:** Hex, RGB, HSL values (exclude: SVG fill/stroke that are intentional, third-party overrides)
**Typography:** Pixel font sizes, literal font-family declarations, pixel line-heights
**Spacing:** Pixel margin/padding/gap values that should use the spacing scale

### Step 3 — Output Token Audit
```
=== Design Token Audit ===
Token definitions found: <N>
  Colors: <N>
  Typography: <N>
  Spacing: <N>

Hardcoded values found: <N>
  Colors: <N> across <N> files
  Typography: <N> across <N> files
  Spacing: <N> across <N> files

TOKEN COVERAGE: <N>%

TOP OFFENDERS (files with most hardcoded values):
  1. <file> — <N> hardcoded values
  2. <file> — <N> hardcoded values

DETAILED FINDINGS:
  <file>:<line> — `#1a2b3c` -> suggest `var(--primary)` or `text-primary`
  <file>:<line> — `font-size: 14px` -> suggest `text-sm`
===========================
```

---

## Flag: --figma-drift

Compare implemented components against Figma designs using MCP tools.

### Step 1 — Get Figma Context
Use Figma MCP tools to retrieve design context:
1. `mcp__plugin_figma_figma__get_design_context` — retrieve component definitions from Figma
2. `mcp__plugin_figma_figma__get_screenshot` — capture current Figma component screenshots

### Step 2 — Map Figma to Code
For each Figma component:
1. Identify the corresponding code component file
2. Compare: Color values, Typography, Spacing, Border radius/shadows, Component structure

### Step 3 — Detect Drift
Categorize differences:
- **Visual drift:** component looks different from Figma
- **Structural drift:** component structure differs
- **Token drift:** Figma uses a value that code doesn't match
- **Missing:** Figma component exists but no code implementation
- **Orphaned:** Code component exists with no Figma counterpart

### Step 4 — Output Drift Report
```
=== Figma Drift Report ===
Figma project: <project-name>
Checked: <N> components
Drift detected: <N> components

MATCHING (no drift):
  <Component> — code matches Figma

VISUAL DRIFT:
  <Component> — color mismatch: Figma #abc vs code var(--xyz) = #def

STRUCTURAL DRIFT:
  <Component> — Figma has icon slot, code does not

MISSING IN CODE:
  <Figma component name> — no implementation found

ORPHANED IN CODE:
  <Code component> — no Figma counterpart

DRIFT SCORE: <N>% match
============================
```

### Step 5 — Update State
Record drift scan results with timestamp in state file.

---

## Flag: --guidelines

Generate or update `docs/reference/brand-guidelines.md`.

### Step 1 — Gather All Design System Data
1. Run Phase 0 context gathering (includes reading brand source-of-truth file)
2. Run token discovery (from `--tokens` Step 1)
3. Run asset inventory (from `--assets` Step 1-2)
4. Read component list and their visual roles

### Step 2 — Generate Guidelines Document
Write to `docs/reference/brand-guidelines.md`:

```markdown
# Brand Guidelines — <project-name>

**Generated:** <YYYY-MM-DD>
**Source:** Automated scan of design system + brand source-of-truth file

## Brand Identity
- Brand name: <from brand file or project config>
- Brand promise: <from brand file>
- Source of truth: <brand-file-path>

## Color Palette
| Token | Value | Usage |
|-------|-------|-------|
| --primary | <value> | Primary actions, links |
| --secondary | <value> | Secondary elements |
| ... | ... | ... |

## Typography
| Token | Value | Usage |
|-------|-------|-------|
| text-sm | <value> | Body text, labels |
| ... | ... | ... |

## Component Library
| Component | Source | Usage |
|-----------|--------|-------|
| Button | <library> | All interactive actions |
| ... | ... | ... |

## Asset Library
| Asset | Type | Usage |
|-------|------|-------|
| logo.svg | Logo | Sidebar, login |
| ... | ... | ... |

## Conventions
- Use design system tokens instead of hardcoded values
- Prefer component library over raw HTML
- ...
```

### Step 3 — Cross-Reference
Recommend `/doc-rules --check` to verify the new document meets documentation standards.

---

## State file spec — `.claude/state/brand.md`

```markdown
# Brand State

**Last updated:** <YYYY-MM-DD HH:MM>

## Compliance Score

Overall: <N>%
- Token coverage: <N>%
- Component consistency: <N>%
- CSS consistency: <N>%
- Asset naming: <N>%

## Last Scan Results

### Violations
| Severity | Count | Fixed | Open |
|----------|-------|-------|------|
| CRITICAL | <N> | <N> | <N> |
| HIGH | <N> | <N> | <N> |
| MEDIUM | <N> | <N> | <N> |
| LOW | <N> | <N> | <N> |

### Top Violation Files
| File | Violations | Types |
|------|-----------|-------|
| <file> | <N> | colors, spacing |

## Design System Inventory

### UI Components
- <list of installed components>

### Custom Components
- <list of project-specific components>

### Design Tokens
- Colors: <N> defined
- Typography: <N> defined
- Spacing: <N> defined

### Assets
- SVGs: <N>
- Images: <N>
- Unused: <N>

## Figma Drift

Last checked: <date or "never">
Components checked: <N>
Drift detected: <N>
Match score: <N>%

## Fix History

| Date | Fixes Applied | Score Before | Score After |
|------|--------------|-------------|------------|
| <date> | <N> | <N>% | <N>% |
```

---

## Important Constraints

1. **Never modify component behavior.** When fixing brand violations, only change styling values. Never alter logic, event handlers, or data flow.
2. **Token matches must be verified.** When suggesting a replacement, verify the token exists. Never invent tokens.
3. **Respect intentional overrides.** Some hardcoded values are intentional. Use heuristics to skip these, flag uncertain cases.
4. **Figma drift requires MCP access.** If Figma tools are not connected, report the limitation clearly.
5. **Always update triage.** This is how other skills see brand status.
6. **Never delete assets.** Only flag unused assets — the user decides.
7. **Compliance score is factual.** Calculate from actual scan data. Never estimate.
8. **Brand source-of-truth overrides general conventions.** If the brand file says something specific, that takes precedence.
9. **Always scan fresh.** Do not rely solely on state file — always re-scan the codebase.
10. **Guidelines generation is idempotent.** Running `--guidelines` multiple times produces consistent output.
11. **UCL grounds brand work in use cases** — violations and compliance scores must reference UC IDs when possible. This lets product-owner and dev-manager trace brand issues back to specific user journeys. A violation report that says "hardcoded color in subscription.vue (UC-V05)" is actionable across all three skills. A report that just says "hardcoded color in subscription.vue" forces the other skills to do their own mapping.
12. **Re-scan brand violations before fixing.** Triage violation counts go stale — violations listed in triage may already be fixed by other skills or sessions. Always re-scan the codebase before starting a fix batch. In the 2026-04-04 audit, 7 of 12 listed violations were already resolved.
