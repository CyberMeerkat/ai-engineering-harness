---
description: "Code review & PR management — review diffs, create PRs with checklists, verify merge readiness"
---

# /review — Code Review & PR Management

You are the review skill. You review code changes, create pull requests with structured checklists, and verify merge readiness across quality gates.

## Phase 0 — Context (every invocation)

1. Read `.claude/state/triage.md` — check § Reviews for open PR state
2. Read `.claude/state/review.md` if it exists — detailed review domain state
3. Check `git status`, `git log`, and current branch to understand the working state
4. Identify the base branch (usually `main`)

## Flags

| Flag | Behaviour |
|------|-----------|
| `--session-start` | Read triage, output review dashboard (open PRs, pending reviews, merge readiness) |
| `--diff` | Review the current staged + unstaged changes — produce findings |
| `--diff <base>` | Review changes between current branch and `<base>` |
| `--pr` | Create a pull request from current branch with structured description |
| `--pr <number>` | Review an existing PR by number (uses `gh pr view`) |
| `--checklist` | Generate a merge-readiness checklist for current branch |
| `--findings` | Detailed code review findings (bugs, style, security, performance) |
| `--approve <number>` | Mark a PR as reviewed with findings summary |
| `--status` | Show all open PRs and their review/gate status |
| (no args) | Same as `--diff` for current branch vs base |

## Review Protocol

### For `--diff` / `--findings`

1. **Scope** — identify all changed files (added, modified, deleted)
2. **Categorize** — group changes by type:
   - Feature code (new functionality)
   - Bug fix (correcting existing behaviour)
   - Refactor (structural change, no behaviour change)
   - Test (new/modified tests)
   - Config/infra (CI, Dockerfile, Terraform, etc.)
   - Docs (documentation changes)
3. **Review each file** for:
   - **Correctness** — logic errors, edge cases, off-by-one
   - **Security** — injection, auth bypass, secrets exposure, OWASP top 10
   - **Performance** — N+1 queries, unnecessary allocations, missing indexes
   - **Style** — naming, structure, consistency with project conventions
   - **Testing** — are new code paths covered by tests?
   - **Breaking changes** — API contract changes, migration requirements
4. **Severity per finding:**
   - BLOCKER — must fix before merge
   - WARNING — should fix, but not a gate
   - INFO — suggestion or nitpick
5. **Output** — structured findings table + summary verdict (APPROVE / REQUEST CHANGES / NEEDS DISCUSSION)

### For `--pr`

1. Analyse all commits on current branch vs base branch
2. Draft PR title (under 70 chars) and structured body:
   - Summary (1-3 bullets)
   - Changes by category
   - Testing done
   - Merge checklist (auto-populated from gate status)
3. Create PR using `gh pr create`
4. Update triage § Reviews

### For `--checklist`

Cross-reference with other skills to build merge readiness:

| Gate | Source | Status |
|------|--------|--------|
| Tests pass | `/test --run` or CI | PASS/FAIL/UNKNOWN |
| No critical CVEs | `/security-review --scan` | PASS/FAIL/UNKNOWN |
| Docs updated | `/doc-rules --check` | PASS/FAIL/UNKNOWN |
| Brand consistent | `/brand --check` | PASS/FAIL/UNKNOWN |
| Lint clean | CI or local | PASS/FAIL/UNKNOWN |
| Reviewed | This skill | PENDING/APPROVED |

## Triage Update Format

```markdown
## Reviews
**Updated:** <YYYY-MM-DD HH:MM>
**Open PRs:** <N>  |  **Merge-ready:** <N>

### Open Pull Requests
| PR | Branch | Title | Review | Gates | Merge-ready |
|----|--------|-------|--------|-------|-------------|
| #<N> | <branch> | <title> | APPROVED | 4/5 | NO — tests failing |

### Recent Reviews
- <branch>: <APPROVE/REQUEST CHANGES> — <one-line summary>

### Recommendations
- <e.g., "Fix failing tests on feat/pce before merging">
```

## Safety

- NEVER auto-merge — merging requires explicit user confirmation
- NEVER approve without reviewing — if you can't read the diff, status is UNKNOWN
- NEVER push to main/master without explicit user instruction
- Always show the PR URL after creation so the user can verify

## Learned Rules

1. **MCP SDK `server.tool()` requires Zod schemas, not JSON Schema objects.** When building MCP tools, pass `z.object({...})` not `{ type: 'object', properties: {...} }`. The SDK validates at registration time. *(From: feedback_learned_mcp_sdk_zod_schemas)*
2. **Zod v4 `z.record()` needs two arguments.** Use `z.record(z.string(), z.unknown())` not `z.record(z.unknown())`. The single-arg form was removed in Zod v4. *(From: feedback_learned_zod_v4_record)*
3. **Cross-package TypeScript imports need `dist/` paths at runtime.** When one package `require()`s another in a monorepo, the path must point to compiled `dist/` output, not `.ts` source files. Node.js cannot execute `.ts` files directly. *(From: feedback_learned_cross_package_ts_runtime)*
4. **Use keyword args when calling functions with multiple optional params.** Positional args with multiple optional params of different types cause silent type mismatches — especially when errors are caught by broad `except Exception` clauses. e.g. `sync_pool(pool, db)` passed Session as `limit`. *(From: feedback_learned_keyword_args_for_optional_params)*
5. **SSE/streaming parser state must persist across read chunks.** Declare stateful variables (currentEvent, partial buffers) in the outer scope, not inside per-chunk handler functions. TCP can split events across chunks, losing state that resets per invocation. *(From: feedback_learned_sse_parser_state_scope)*
6. **Stacked PRs: retarget child bases to the integration branch BEFORE merging the parent.** Run `gh pr edit <child> --base develop` on every child PR first, then cascade `gh pr merge N --merge --delete-branch` from parent to child. Merging parent first with `--delete-branch` orphans the child's base ref and may auto-close it. Each merge then fast-forwards cleanly because GitHub recomputes the child's diff against the updated base. *(From: feedback_learned_stacked_pr_base_retarget.md)*
7. **Never squash-merge a stacked PR.** Squashing collapses child commits into a new hash; downstream stacked PRs still reference the original commits and produce phantom conflicts on subsequent merges. Use `gh pr merge N --merge` (merge commit) or `--rebase`. If squashed history is required, flatten the stack into one PR first. Pair with rule 6 (retarget bases). *(From: feedback_learned_no_squash_stacked_prs.md)*
8. **`eslint-disable-next-line` comments are stripped/shifted by prettier `--fix`.** Prettier reformats multi-line expressions and shifts line numbers, causing disable comments to apply to the wrong line. Use `/* eslint-disable rule */` block at file top for file-scope disables (stable against reformatting), or add `// prettier-ignore` above `// eslint-disable-next-line` and collapse the expression to a single line. *(From: feedback_learned_eslint_disable_prettier_conflict.md)*

9. **`git add --all` or `git add .` commits SQLite WAL files and untracked runtime dirs — always stage by explicit path.** `git add --all` silently captures `*.db-shm`, `*.db-wal`, `*.db-journal`, and dirs like `scripts/`, `data/` that are missing from `.gitignore`. These land in commits and require `git reset HEAD~1` + force-push to remove. Prevention: (1) always `git add <specific/file>` by name, (2) ensure `.gitignore` contains `*.db-shm`, `*.db-wal`, `*.db-journal`, and any runtime dirs, (3) `git status` before every commit. *(From: feedback_learned_git_add_all_sqlite_wal.md)*

10. **Check CI on stacked feature branches before pushing or reviewing.** Branch protection only enforces CI on PRs targeting protected branches like `main`/`develop`; pushes to a stacked feature branch don't gate-check anyone. Code that hasn't been merged in a week may have rotted in CI without anyone noticing. First action when picking up a stacked branch — `gh run list --branch <head> --limit 3 --json conclusion,headSha,createdAt`. If any are red, fix them before adding new commits. Same when retargeting a PR base. *(From: feedback_learned_check_ci_on_stacked_branch.md)*

11. **Detect superset PR stacks before bottom-up merging.** Run `git log origin/<upstream>..origin/<downstream>` and the reverse. If the second count is `0`, the downstream branch is a STRICT SUPERSET of the upstream — every upstream commit is already in downstream. Retarget the downstream PR's base directly to the original target via `gh pr edit <pr> --base develop` and close the upstream PR as superseded. One merge replaces N. Saves a full review + merge cycle. *(From: feedback_learned_detect_superset_pr_stack.md)*

12. **Verify column existence with `\d <table>` before claiming absence.** Before recommending a schema change to "add a missing column", run `\d <schema>.<table>` and `SELECT COUNT(*) FILTER (WHERE <col> IS NOT NULL) FROM <table>`. Sparse/NULL values look identical to a missing column when querying via app code; misdiagnosis cascades into wrong architectural recommendations. CIPC `web_url` was claimed missing based on `skippedNoWebsite=5/5` — the column existed; data was just NULL on K2024 SMEs. *(From: feedback_learned_verify_column_before_claiming_absence.md)*
13. **Use isolated git worktrees when release branches differ from dirty working branches.** If the active tree has unrelated changes and the deploy branch is different from the implementation branch, create a fresh worktree on the target branch and cherry-pick there. Validate in the worktree, push, then delete it. This avoids clobbering unrelated edits and keeps release history clean. *(From: feedback_learned_use_worktrees_for_dirty_multi_branch_releases.md)*
14. **IDE "Push" silently fails on branches with no upstream — use `git push -u origin <branch>` for first push.** Many IDE Push buttons (VS Code, GitKraken, GitHub Desktop) no-op on first-push branches without any error surfaced; some require "Publish Branch" instead. Verify push state via `git config branch.<name>.remote` (empty = no upstream), `git reflog show <branch> | grep push:` (empty = push never executed), `git ls-remote origin refs/heads/<branch>` (empty = absent on remote). For first push of any new branch, always run `git push -u origin <branch>` from terminal — `-u` sets upstream so subsequent IDE pushes work. *(From: feedback_learned_ide_push_silent_fail_no_upstream.md)*
15. **Multi-repo handover requires four-check audit per repo.** `git branch --show-current` is a hypothesis until verified. Run per repo: (a) `git branch --show-current` + `git log -1 --format='%h %s (%cr)'`, (b) `git for-each-ref --sort=-committerdate refs/heads/ | head -10` to spot newer feature branches, (c) `git config branch.<current>.remote` + `git ls-remote origin refs/heads/<current>` to confirm pushed, (d) `git remote -v` to catch multi-remote setups (fork + org). Only recommend handover branches passing all 4 checks. If a branch fails (c) instruct push first; if (d) document the alternate-remote setup teammates need. *(From: feedback_learned_repo_handover_branch_audit.md)*
16. **Check API payload aliases before adding reshape nodes (n8n/Zapier/Make).** Before designing a Set/Code/Mapper node to reshape payload keys (camelCase→snake_case, alt names→canonical), grep the target FastAPI endpoint for `model_validator(mode="before")` or `Field(alias=...)`. If aliases exist, drop the reshape node and POST the producer's native payload directly. Wasted reshape work + maintenance surface otherwise. Reserve reshape only for fields the endpoint cannot derive. *(From: feedback_learned_check_payload_aliases_before_reshape.md)*

17. **Retargeting a PR's base branch does NOT re-trigger CI.** GitHub Actions `pull_request` workflows fire on `opened`, `synchronize`, and `reopened` — not on the `edited` activity a base change emits. After `gh pr edit <n> --base <branch>` the pre-retarget check set persists. To run CI against the new base, close+reopen the PR (`reopened`) or push a commit (`synchronize`). Related: a PR based on a feature branch may run a reduced check set vs one targeting `develop`/`main`. *(From: feedback_learned_pr_retarget_ci.md)*

18. **`git fetch` before reasoning about branch divergence — stale local refs produce phantom divergence.** Before any branch-state analysis (`A..B` revision counts, "did this PR merge", ahead/behind), run `git fetch origin` and compare against `origin/<branch>`, never the local tracking ref. A stale local branch makes a merged PR look un-merged: `git log develop..HEAD` against a stale local `develop` once showed 19 phantom commits and an empty `HEAD..develop`, reading as "the PR was never merged" — `git fetch` revealed `origin/develop` was the merge commit, 20 ahead of `origin/main`. Treat local tracking branches as stale until fetched in the current session. *(From: feedback_learned_fetch_before_branch_compare.md)*

19. **Frontend `new Date(isoStr + 'Z')` corrupts ISO strings that already carry a timezone offset — detect offset before forcing UTC.** When a frontend timestamp helper parses ISO strings from multiple backends, the unconditional `+ 'Z'` produces `...+00:00Z` from a backend that returns `2026-05-11T13:31:32.907985+00:00`. `new Date(...)` returns `Invalid Date`; arithmetic yields `NaN`; the UI silently shows `NaNd ago` or blank. No error surfaces. Symptom in the wild: "last synced date not displaying" on a cache modal because the old SQLite backend emitted naive UTC (`...T13:31:32.123456`, no offset) while a new orchestrator HTTP API emitted full ISO with offset. Fix shape: `const hasTZ = /Z$|[+-]\d{2}:?\d{2}$/.test(isoStr); const d = new Date(hasTZ ? isoStr : isoStr + 'Z'); if (isNaN(d.getTime())) return '';`. Apply to every frontend Date parser whose input source is more than one backend. *(From: feedback_learned_timeago_double_z_iso.md)*

20. **`gh pr create|merge` resolves the target repo from cwd — `cd` before every invocation in multi-repo work, or pass `-R owner/repo`.** `gh` walks up from cwd to find `.git` and uses that repo as the target. In a multi-repo session, running `gh pr merge 12` after `cd orchestrator` merged the orch PR #12; re-running the same command intending the project-d PR #12 returned `Pull request example-org/example-repo#12 was already merged` — silent wrong target. Same class caused `gh pr create` to fail with `No commits between develop and feature/...` when cwd pointed at the wrong repo and `gh` couldn't find the branch locally. Discipline: explicit `cd <repo>` line before every `gh pr` call, OR the explicit `gh -R owner/repo pr <subcommand>` form for automation scripts. Verify with `git remote -v | head -1` when in doubt. *(From: feedback_learned_gh_pr_cwd_repo.md)*

21. **For chained/dependent PRs whose diffs overlap in the same file OR whose code depends on yet-unmerged code from an earlier PR, branch PR_n off PR_(n-1), NOT flat off develop/main.** Flat branching forces 3+ manual rebase conflicts when each PR touches the same file; chained branching = zero conflicts after each upstream merges. Shape: `develop ──┬── feature/x/P0 (creates orchestrator-client.js) ──── feature/x/P1 (modifies same file) ──── feature/x/P2 (modifies same file)`. After PR_(n-1) merges to `develop`, PR_n rebases cleanly. Annotate the downstream PR description with "PR base = #X (will rebase to develop after merge)" so reviewers understand the chain. Use `gh pr create --base feature/x/p0 --head feature/x/p1` for the chain. Before opening PR_n, check: (a) does it edit a file an unmerged earlier PR also edits? (b) does it import code not yet on the target branch? If either, branch off the earlier PR. *(From: feedback_learned_chain_dependent_prs_at_git_level.md)*
