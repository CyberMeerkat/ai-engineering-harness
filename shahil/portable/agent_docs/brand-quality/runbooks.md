# brand-quality — Runbooks

Reference docs loaded on demand by the `brand-quality` skill dispatcher.

## Pre-flight (every BQB run)

```bash
# 1. Verify MCP server is registered + connecting
claude mcp list | grep brand-quality
# expect: brand-quality: ... ✓ Connected

# 2. If ✗ Failed to connect, smoke-test directly:
node --env-file=<projects>/ux/brand-quality-system/.env \
  <projects>/ux/brand-quality-system/build/src/index.js --selftest
# expect: "Brand-Quality MCP server (Snoopy Gem) running on stdio"

# 3. Verify corpus state
sqlite3 <projects>/ux/brand-quality-system/corpus/brand-quality-corpus.db \
  "SELECT COUNT(*), SUM(CASE WHEN embedding IS NULL THEN 0 ELSE 1 END) FROM principles;"
# expect: 95|95 (after B2a; baseline was 83|83)
```

## Common rebuild triggers

```bash
cd <projects>/ux/brand-quality-system

# After authoring new atoms in corpus/sources/*.json:
node -e "JSON.parse(require('fs').readFileSync('corpus/sources/<NN>-<axis>.json'))" && echo "valid"
npm run build
node --env-file=.env build/scripts/ingest.js | tail -5

# After atom rewrites that change content (need re-embed):
node --env-file=.env build/scripts/ingest.js --reembed | tail -5

# After top-K or tool surface changes in src/index.ts:
npm run build  # MCP server picked up on next session restart
```

## Post-corpus-change retrieval audit

```bash
node --env-file=.env build/scripts/audit-retrieval.js \
  --bqb <projects>/ux/{{project}}-tokens/BQB.md \
  --top-k 8 \
  --out audits/phase-<X>-retrieval-log.md
```

Inspect the log for:

- **Thin sections** (top match <50%) — gap, address axis-by-axis
- **Dead atoms** (never in any top-K) — either intentional (non-locked archetype) or actual rewrite candidate
- **Categories with zero hits** — major axis-coverage gap, prioritise next iteration

## Second-target stress test

The {{PROJECT}} BQB locks Creator. To validate that the corpus generalises beyond Creator-locked briefs, audit a target with a different archetype and confirm:

1. Non-Creator archetype atoms (e.g. `archetype-ruler-012`, `archetype-sage-003`) surface in §0 Intent Lock
2. Archetype-tagged anti-cheap atoms (B2a 018–025) surface for Ruler/Sage/Magician targets — these are cold against {{PROJECT}} by design
3. `bridges_to` to ux-skill-system fires ({{PROJECT}} audit ran without ux-skill-system co-retrieval; second target should exercise this path)

Suggested second targets:

- `<projects>/ux/ux-skill-system` — sibling repo, likely Sage archetype (Nielsen heuristic taxonomy)
- A Ruler-archetype target (luxury or institutional brand) — fully untested
- A Magician-archetype target (entertainment or experience brand) — fully untested

If a second target exposes thin retrieval in axes the {{PROJECT}} audit didn't touch, that is the next B-tier expansion priority.

## Regression playbook

If a BQB run produces clearly worse output than a prior run:

1. Diff `corpus/sources/*.json` against the prior commit (or backup) — did atom rewrites change?
2. Check `src/index.ts` for top-K or filter regressions
3. Re-embed the changed atoms only:
   ```bash
   node --env-file=.env build/scripts/ingest.js --reembed --file corpus/sources/<changed>.json
   ```
4. Re-run `audit-retrieval.js` and compare numbers section by section

## Skill-wrapper failure modes

- **Skill triggers but tools return empty** — usually the MCP server isn't connected; check pre-flight
- **Skill triggers on UX questions** — the skill description is too broad; refine triggers in dispatcher
- **Skill produces non-schemed output** — the LLM ignored the canonical SKILL.md; explicitly Read() it before generating

## Where to write BQB output

Default conventions:

- **For an external target:** `<target-repo>/BQB.md` (e.g. {{PROJECT}}: `<projects>/ux/{{project}}-tokens/BQB.md`)
- **For an audit (read-only)** of an external target: `<projects>/ux/brand-quality-system/audits/<date>-<target>-bqb-audit.md`
- **For a dogfood run** on the brand-quality-system itself: `<projects>/ux/brand-quality-system/audits/<date>-self-bqb.md`

Always include the date in the path so multiple iterations don't overwrite each other.
