# Branching Workflow

This is a standing policy for how agents work with git branches in this project. It is always loaded (see `instructions` in the OpenCode config) — you don't need to be told this on every session.

## Starting new work

- **Feature work** → create a branch named `feature/<kebab-case-slug>` (e.g. `feature/add-dark-mode`).
- **Fix/bug work** → create a branch named `fix/<kebab-case-slug>` (e.g. `fix/login-crash`).
- Do this **unless the user explicitly instructs otherwise** (e.g. "just work directly on this branch," "no need for a new branch").

Before creating either branch type:

1. Check out `develop`.
2. Pull the latest `develop` (`git fetch origin develop && git merge --ff-only origin/develop`, or `git pull origin develop` if you're already tracking it).
3. Create the new branch from that up-to-date `develop`.

Both `feature/*` and `fix/*` branches are based on `develop` — not `main`, not whatever branch happened to be checked out before.

## While working

- Push commits to your `feature/*` or `fix/*` branch freely. That's expected, not something to ask permission for.
- When a **slice of work is complete** — a full feature, a full fix, or a full phase of a larger piece of work — open a pull request.
  - **PRs always target `develop`**, not `main`/`stable`/`staging`/`dev`.
  - Do not open a PR mid-way through unrelated, unfinished work; a PR should represent a coherent, reviewable slice.

## Hard rules

- **Agents do not merge branches themselves.** Open the PR and stop — a human merges it. This is true even for PRs you opened yourself.
- **Agents do not push to `develop`, `dev`, `staging`, `stable`, or `main`, and do not merge into them, without the user's explicit go-ahead in the current conversation.** If you find yourself about to run a command that would do this, stop and ask first rather than proceeding and relying on a permission prompt to catch it.

## Why the explicit-branch-name rule matters

Always specify the target branch explicitly in `git push` and `git merge` commands:

```bash
# Good - explicit, and the permission system can recognize + confirm this
git push origin feature/add-dark-mode
git push origin develop

# Avoid - implicit target depends on the current branch, which the
# permission system can't see from the command text alone
git push
git push origin
```

This project's OpenCode config has permission rules that prompt for confirmation when a command explicitly names one of `develop`/`dev`/`staging`/`stable`/`main` as a push or merge target. Those rules can only see the literal command text — they cannot resolve what branch a bare `git push` would actually push to. Using explicit branch names means the confirmation prompt actually fires when it should, instead of a protected-branch push silently slipping through in implicit form. A backstop check also runs for the implicit case specifically, but it can only block-and-ask-you-to-be-explicit, not give you the full approve/deny prompt — so explicit names are always the better path.

## Quick reference

| Situation | What to do |
|---|---|
| Starting a new feature | `git checkout develop && git pull`, then `git checkout -b feature/<slug>` |
| Starting a new fix | `git checkout develop && git pull`, then `git checkout -b fix/<slug>` |
| A slice of work is done | Push the branch, open a PR targeting `develop` |
| PR needs merging | Stop. Tell the user it's ready. Do not merge it yourself. |
| About to push/merge to develop/dev/staging/stable/main | Stop and ask the user first, in conversation, before running the command |
