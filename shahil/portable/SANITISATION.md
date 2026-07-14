# Sanitisation record — safe to share

This `portable/` tree is a **scrubbed copy** of the personal harness. Both real infrastructure identifiers
and all specific project/company names have been removed and replaced with placeholders. Here's what changed.

## ✅ Removed — real infrastructure (replaced with placeholders)

| Was | Now | Where |
|---|---|---|
| Production server IP | `{{PROD_IP}}` | `hooks/check-destructive-ops.sh`, `hooks/route-deploy-intent.sh` |
| Production hostname | `{{PROD_HOST}}` | `hooks/check-destructive-ops.sh` |
| Production deploy path | `{{PROD_PATH}}` | `hooks/check-destructive-ops.sh`, `commands/deploy.md` |
| Home directory `/Users/<user>` | `{{HOME}}` | `settings.template.json` |
| cavemem absolute node path | `{{CAVEMEM_PATH}}` | `settings.template.json` |
| Machine paths `/Library/Sites/...` | `<projects>/...` | several `commands/*` + `agent_docs/brand-quality/runbooks.md` |
| Project-specific allow-list entries (app screenshots, `npx shadcn/vite`, `/tmp/...` dirs) | dropped | `settings.template.json` |

## ✅ Removed — all specific project & company names (replaced with neutral placeholders)

Every real project name, GitHub org, repo name, and Jira project key has been genericised:

| Real value (removed) | Placeholder |
|---|---|
| Primary product name (×2 variants) | `{{PROJECT}}` / `{{project}}` |
| Other project names (5 distinct) | `project-a` … `project-e` |
| GitHub org | `example-org` |
| Repo / one-off project names | `example-repo`, `example-project` |
| Jira project key | `PROJ` (so keys read `PROJ-7`) |

The business-model descriptors in `commands/brief.md` and `commands/marketing.md` (region, currency,
marketplace model, rollout phases, revenue model) were also genericised to placeholders.

## ℹ️ Intentionally kept — generic compliance frameworks

`POPIA`, `SARS`, `GDPR`, `PCI DSS` remain in `commands/compliance.md`, `commands/legal.md`, and the
compliance lens. These are **public regulatory frameworks**, not project identifiers — the compliance/legal
skills are built around them. Drop or swap them for your jurisdiction's frameworks if you wish.

## Verify it's clean (should print 0)

```bash
cd portable
grep -rEin '([0-9]{1,3}\.){3}[0-9]{1,3}|/opt/|/Users/|\.nvm/versions' . | grep -v SANITISATION.md | wc -l
# and confirm no original names linger — substitute your own former names here:
grep -rEinw 'YOURPROJECT|YOURORG|YOURJIRAKEY' . | wc -l
```

## 🚫 Never copied into this kit

`projects/` (session transcripts), all `*/memory/` (personal/business facts), `context-mode/*.db`,
`.credentials*`, `learned-projects.json` (your project paths), `registry.txt` (your repos), and everything in
the L4 ephemeral bucket. Skills (`skills/`) are **not** copied — re-install them from source (see
`../05-ADOPT.md`).

## Placeholder reference (fill these in for your own setup)

| Placeholder | Fill with |
|---|---|
| `{{HOME}}` | your home dir, e.g. `/Users/you` |
| `{{CAVEMEM_PATH}}` | absolute path to cavemem's `dist/index.js` (or delete cavemem blocks) |
| `{{PROD_IP}}` / `{{PROD_HOST}}` / `{{PROD_PATH}}` | your prod target (regex-escape dots in the hook), or delete those rules |
| `{{PROJECT}}` / `{{project}}` | your project name |
| `project-a`…`project-e`, `example-org`, `example-repo`, `PROJ` | rename to your real projects/org/Jira key as you adopt |
