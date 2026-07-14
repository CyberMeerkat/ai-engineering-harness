# UI/UX Pro Max — Reference Documentation

> Loaded on demand by `/ux-audit`, `/brand`, and the global `ui-design-system` rule.
> Source: `~/.claude/skills/ui-ux-pro-max/` (BM25 search engine over 16 CSV databases)

## 1. Invocation

### Design System Generation (primary use)

```bash
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<product-context>" --design-system -p "<project>"
```

Returns: pattern, style, colors, typography, effects, anti-patterns, pre-delivery checklist.

### Persist Design System (saves to disk)

```bash
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "<project>"
```

Creates `design-system/MASTER.md` + optional `design-system/pages/<page>.md` with `--page "<name>"`.

### Domain-Specific Search

```bash
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --domain <domain> [-n <max_results>]
```

| Domain | Use For | Example |
|--------|---------|---------|
| `product` | Product type patterns | `"ecommerce marketplace"` |
| `style` | UI styles, effects | `"glassmorphism dark mode"` |
| `color` | Color palettes | `"luxury premium"` |
| `typography` | Font pairings | `"elegant modern"` |
| `landing` | Page structure, CTAs | `"hero social-proof"` |
| `chart` | Chart types | `"real-time dashboard"` |
| `ux` | Best practices | `"animation accessibility"` |
| `google-fonts` | Individual fonts | `"sans serif variable"` |
| `react` | React/Next.js perf | `"suspense memo rerender"` |
| `web` | App interface (iOS/Android/RN) | `"touch targets safe areas"` |
| `prompt` | AI/CSS keywords | `"minimalism"` |

### Stack-Specific Search

```bash
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --stack react-native
```

## 2. Design Rules (150+ rules, 10 categories)

Rules are prioritized 1→10. Apply higher-priority rules first.

### Priority 1: Accessibility (CRITICAL)
- Contrast 4.5:1 for normal text, 3:1 for large text
- Visible focus rings (2-4px) on all interactive elements
- Descriptive alt text for meaningful images
- `aria-label` for icon-only buttons; `accessibilityLabel` in native
- Tab order matches visual order; full keyboard support
- `<label>` with `for` attribute on form inputs
- Skip-to-main-content links for keyboard users
- Sequential heading hierarchy (h1→h6, no level skip)
- Never convey information by color alone (add icon/text)
- Support system text scaling (Dynamic Type, Material)
- Respect `prefers-reduced-motion`
- Meaningful VoiceOver/screen reader labels and reading order
- Escape routes (cancel/back) in modals and multi-step flows

### Priority 2: Touch & Interaction (CRITICAL)
- Minimum 44×44pt (Apple) / 48×48dp (Material) touch targets
- 8px+ spacing between touch targets
- Use click/tap for primary interactions, never hover-only
- Disable button during async + show spinner/progress
- Clear error messages near the problem field
- `cursor-pointer` on clickable elements (web)
- Avoid horizontal swipe conflicts with main scroll
- `touch-action: manipulation` to reduce 300ms tap delay
- Visual press feedback (ripple/highlight)
- Haptic for confirmations (sparingly)
- Keep touch targets away from notch, Dynamic Island, gesture bar

### Priority 3: Performance (HIGH)
- WebP/AVIF with responsive `srcset/sizes`, lazy load non-critical
- Declare `width/height` or `aspect-ratio` to prevent CLS
- `font-display: swap/optional`; preload only critical fonts
- Inline critical CSS for above-the-fold
- Route-level code splitting (React Suspense / Next.js dynamic)
- Async/defer third-party scripts
- Reserve space for async content (skeleton screens for >1s)
- Virtualize lists with 50+ items
- Keep per-frame work under ~16ms for 60fps
- Debounce/throttle high-frequency events

### Priority 4: Style Selection (HIGH)
- Match style to product type (use `--design-system` for recommendations)
- Consistent style across all pages
- SVG icons (Heroicons, Lucide), never emojis as icons
- Shadows, blur, radius aligned with chosen style
- Respect platform idioms (iOS HIG vs Material Design)
- Distinct hover/pressed/disabled states
- Consistent elevation/shadow scale
- Design light/dark variants together
- One icon set/visual language throughout
- Only one primary CTA per screen

### Priority 5: Layout & Responsive (HIGH)
- `viewport meta: width=device-width, initial-scale=1` (never disable zoom)
- Mobile-first design, scale up to tablet and desktop
- Systematic breakpoints: 375 / 768 / 1024 / 1440
- Minimum 16px body text on mobile
- 35-60 chars/line mobile, 60-75 desktop
- No horizontal scroll on mobile
- 4pt/8dp incremental spacing system
- Consistent max-width on desktop (max-w-6xl/7xl)
- Defined z-index scale (0/10/20/40/100/1000)
- Prefer `min-h-dvh` over `100vh` on mobile

### Priority 6: Typography & Color (MEDIUM)
- Line-height 1.5-1.75 for body text
- Limit to 65-75 characters per line
- Match heading/body font personalities
- Consistent type scale (12/14/16/18/24/32)
- Semantic color tokens (primary, secondary, error, surface), not raw hex
- Dark mode uses desaturated/lighter tonal variants, not inverted
- Foreground/background pairs ≥4.5:1 (AA) or 7:1 (AAA)
- Use tabular/monospaced figures for data columns, prices, timers

### Priority 7: Animation (MEDIUM)
- 150-300ms for micro-interactions; complex ≤400ms; avoid >500ms
- Only animate `transform`/`opacity` (never width/height/top/left)
- Skeleton/progress for loading >300ms
- Max 1-2 animated elements per view
- `ease-out` for entering, `ease-in` for exiting
- Every animation must express cause-effect, not decoration
- Smooth state transitions (don't snap)
- Exit animations shorter than enter (~60-70%)
- Stagger list items by 30-50ms
- Animations must be interruptible by user interaction
- Never block user input during animation

### Priority 8: Forms & Feedback (MEDIUM)
- Visible label per input (not placeholder-only)
- Error below the related field
- Loading → success/error on submit
- Mark required fields (asterisk)
- Helpful empty states with action
- Auto-dismiss toasts in 3-5s
- Confirm before destructive actions
- Validate on blur, not keystroke
- Semantic input types for correct mobile keyboard
- Undo support for destructive/bulk actions
- Multi-step flows show progress indicator
- Auto-save drafts on long forms

### Priority 9: Navigation (HIGH)
- Bottom nav max 5 items with labels + icons
- Drawer/sidebar for secondary navigation only
- Back navigation preserves scroll/state
- All key screens reachable via deep link
- Current location highlighted in navigation
- Search easily reachable (top bar or tab)
- Breadcrumbs for 3+ level hierarchies (web)
- Large screens prefer sidebar; small use bottom/top nav
- Modals never for primary navigation flows

### Priority 10: Charts & Data (LOW)
- Chart type matches data type (trend→line, comparison→bar, proportion→pie)
- Accessible colors; avoid red/green only
- Table alternative for screen readers
- Patterns/textures supplement color
- Always show legend near the chart
- Tooltips on hover (web) or tap (mobile)
- Label axes with units
- Responsive charts that reflow on small screens
- `prefers-reduced-motion` for chart animations

## 3. Output Interpretation

The design system generator returns an ASCII box with these sections:

| Section | What It Contains | How to Use |
|---------|-----------------|------------|
| **PATTERN** | Page structure (e.g., "Marketplace / Directory") with sections, CTA strategy | Use as layout blueprint |
| **STYLE** | UI style name, keywords, mode support (light/dark) | Apply visual treatment consistently |
| **COLORS** | 10 semantic tokens with hex values and CSS variable names | Map to project's color system |
| **TYPOGRAPHY** | Font pairing with Google Fonts link and CSS import | Use project fonts if brand overrides exist |
| **KEY EFFECTS** | Shadows, animations, hover behaviors, timing | Apply as interaction polish layer |
| **ANTI-PATTERNS** | What NOT to do for this product type | Check output against these |
| **PRE-DELIVERY** | Validation checklist (contrast, cursor, hover, responsive) | Run before marking complete |

## 4. Brand Override Protocol

**Project brand tokens ALWAYS take precedence over generic suggestions.**

When the design system returns colors/typography:
1. **Compare** each suggestion against the project's brand source-of-truth
2. **Replace** generic colors with project brand tokens
3. **Document** any intentional divergence with a reason
4. **Keep** pattern, effects, anti-patterns, and checklist (these are universal)

For {{PROJECT}} specifically, read `.claude/agent_docs/{{project}}-design-overrides.md` which contains the full token table.

## 5. Multi-Stack Mapping

### Vue 3 (ERP/Admin portals)
- Colors → CSS custom properties (`--color-primary: #1a1a2e`) + Tailwind theme extension
- Typography → Tailwind `fontFamily` config
- Spacing → Tailwind spacing scale (4px base)
- Components → shadcn-vue component library

### React Native / Expo (Mobile)
- Colors → `colors.ts` StyleSheet tokens
- Typography → `Text` component with style variants
- Spacing → numeric values (4/8/12/16/24/32)
- Touch targets → `minHeight: 44` on Pressable/TouchableOpacity

### Next.js 14 (Storefront)
- Colors → Tailwind config `theme.extend.colors` + CSS variables
- Typography → `next/font` with Google Fonts
- Layout → Tailwind responsive classes (sm/md/lg/xl)
- Performance → Next.js Image component, dynamic imports
