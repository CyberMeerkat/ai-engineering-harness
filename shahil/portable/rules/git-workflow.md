# Git Workflow

> Universal rules. Loaded every session via ~/.claude/rules/.

## Branch Strategy

```
main              production — NEVER commit or push directly
develop           integration — WARN before any direct commit
feature/sN/name   feature work — branch from develop, merge back to develop
fix/sN/name       bug fixes — branch from develop, merge back to develop
hotfix/name       production fixes — branch from main, merge to main + develop
```

## Branch Naming

Format: `<type>/s<sprint>/<kebab-case-description>`

Examples:
- `feature/s1/scout-google-maps-scraper`
- `feature/s1/grader-icp-scoring`
- `fix/s2/queue-retry-backoff`
- `hotfix/auth-token-expiry`

Rules:
- Sprint prefix `sN` is required for feature and fix branches
- Description is kebab-case, concise, describes the deliverable
- No ticket IDs in branch names unless the user asks

## Protection Rules

### NEVER (hard block)
- NEVER commit directly to `main`
- NEVER push to `main` (except via PR merge)
- NEVER force-push to `main` or `develop`
- NEVER delete `main` or `develop`

### WARN (confirm with user first)
- Committing directly to `develop` — ask: "This commits directly to develop. Create a feature branch instead?"
- Merging to `develop` without tests passing
- Pushing to `develop` without a PR (unless user explicitly says "push directly")

### ALLOWED (no confirmation needed)
- Creating feature/fix branches from `develop`
- Pushing feature/fix branches to origin
- Creating PRs from feature → develop
- Deleting merged feature branches

## PR Workflow

1. Feature branches PR into `develop`
2. `develop` PRs into `main` (release cuts)
3. PR title format: `[S<sprint>] <description>` (e.g., `[S1] Scout: Google Maps scraper`)
4. PRs require description with Summary and Test Plan sections

## Creating Feature Branches

When asked to create feature branches:
```bash
git checkout develop
git pull origin develop
git checkout -b feature/sN/<name>
git push -u origin feature/sN/<name>
```

## Sprint Branch Organization

Each sprint's work lives under `feature/sN/`:
- Sprint 1: `feature/s1/*`
- Sprint 2: `feature/s2/*`

This makes it easy to see all active work per sprint:
```bash
git branch -r | grep feature/s1
```
