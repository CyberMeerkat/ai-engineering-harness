---
description: Run SonarQube scan and fix issues file-by-file with validation
argument-hint: [--skip-scan] [--severity BLOCKER,CRITICAL] [--type CODE_SMELL] [--file path] [--dry-run]
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
  - TodoWrite
model: opus
---

# SonarQube Fix — Automated Code Quality Remediation

You are an automated code quality remediation agent. Fix SonarQube issues file-by-file: fix all issues in one file → validate → commit → next file.

## Arguments

The user invoked this command with: $ARGUMENTS

Parse these optional arguments:
- `--skip-scan` — Skip running sonar-scanner, use existing results
- `--severity <list>` — Comma-separated severities (default: all — BLOCKER,CRITICAL,MAJOR,MINOR,INFO)
- `--type <list>` — Comma-separated types (default: CODE_SMELL,BUG,VULNERABILITY)
- `--file <path>` — Fix only issues in this specific file
- `--dry-run` — Show issues without fixing anything

## Configuration

- **Project root:** `<project-root>`
- **Repo root:** `<repo-root>`
- **Project key:** `<project-key>`
- **SonarQube URL:** `http://localhost:9000`
- **Token file:** `<project-dir>/.env.local` (variable: `SONAR_TOKEN`)
- **Helper script:** `<project-dir>/scripts/sonar-issues.py`

## Workflow

Follow these steps in exact order. Do NOT skip steps.

### Step 1 — Load Token

```bash
cd <repo-root> && source <project-dir>/.env.local && echo "Token loaded: ${SONAR_TOKEN:0:8}..."
```

If `.env.local` doesn't exist or SONAR_TOKEN is empty, STOP and tell the user:
> Add `SONAR_TOKEN=squ_xxxxx` to `<project-dir>/.env.local`
> Generate a token at http://localhost:9000 → My Account → Security

### Step 2 — Health Check

```bash
curl -sf http://localhost:9000/api/system/status 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])"
```

If not "UP", tell user to start SonarQube:
```bash
cd <project-root> && docker compose -f docker-compose.sonarqube.yml up -d
```
Then wait ~30s and re-check.

### Step 3 — Run Scan (unless --skip-scan)

```bash
cd <project-root> && source .env.local && sonar-scanner -Dsonar.token="$SONAR_TOKEN"
```

After scan completes, wait for SonarQube to finish processing. Poll the compute engine:
```bash
source <project-root>/.env.local && curl -sf "http://localhost:9000/api/ce/component?component=<project-key>" -u "$SONAR_TOKEN:" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('current',{}).get('status','NO_TASK'))"
```

Wait until status is `SUCCESS`. Poll every 5 seconds, max 2 minutes. If `FAILED`, show the error and stop.

### Step 4 — Fetch and Display Issues

Run the helper script to get issues as JSON:
```bash
cd <project-root> && source .env.local && python3 scripts/sonar-issues.py --json [--severity <from args>] [--type <from args>] [--file <from args>]
```

Parse the JSON output. Create a TodoWrite task list with one task per affected file:
- Format: `<path> — <N> issues (max severity: <SEV>)`
- Order: highest severity first, then most issues

If `--dry-run` was passed, display the issues in a readable table and STOP here.

If there are 0 issues, congratulate the user and stop.

### Step 5 — Fix File by File

For each file in the task list (highest severity first):

#### 5a. Show Issues
Display the issues for this file clearly:
```
File: api/routes.py (5 issues)
  L23  [CRITICAL] [BUG]         Possible null dereference (rule: python:S1234)
  L45  [MAJOR]    [CODE_SMELL]  Cognitive complexity is 18 (rule: python:S3776)
  ...
```

#### 5b. Read and Understand
Read the file using the Read tool. Understand the code context around each issue.

#### 5c. Fix All Issues
Use the Edit tool to fix every issue in the file. Apply minimal, targeted changes:

**Common fixes:**
- **Unused imports/variables** → Remove them
- **Cognitive complexity** → Extract helper functions or simplify conditionals
- **Duplicate code** → Extract shared logic
- **Bare Exception** → Use specific exception types
- **Magic numbers** → Extract to named constants
- **Security issues** → Follow SonarQube's recommended fix
- **Dead code** → Remove it
- **Missing type hints** → Add them where SonarQube flags it
- **Long functions** → Break into smaller functions
- **Nested too deep** → Early returns, guard clauses

If a fix is unclear, risky, or would require major refactoring that could break functionality, SKIP it and note it in the summary.

#### 5d. Validate

**For Python files (`.py`):**
```bash
cd <project-root> && python3 -m ruff check --fix <relative_path>
cd <project-root> && python3 -m ruff format <relative_path>
```

**For Vue/TypeScript/JavaScript files (`.vue`, `.ts`, `.js`, `.tsx`, `.jsx`):**
```bash
cd <project-root>/web && npx eslint --fix src/<relative_from_web_src>
cd <project-root>/web && npm run build
```

If validation fails, fix the errors and re-validate. Repeat until clean.

#### 5e. Commit

After validation passes, commit the changes for this file:
```bash
cd <repo-root>
git add <project-dir>/<relative_path>
```

Also `git add` any files that ruff/eslint auto-fixed as part of `--fix`.

Commit with conventional format:
```bash
git commit -m "$(cat <<'EOF'
fix(<scope>): resolve <N> SonarQube issues in <filename>

<one-line summary per issue fixed>

Severity: <list of severities addressed>
Rules: <list of rule keys>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

Where `<scope>` is derived from the file path:
- `api/...` → `api`
- `app/...` → `app`
- `cli/...` → `cli`
- `web/src/...` → `web`
- `main.py` → `core`

#### 5f. Mark Complete
Update the TodoWrite task for this file to `completed`.

#### 5g. Next File
Move to the next file in the list. Repeat from 5a.

### Step 6 — Summary

After all files are processed, display:

```
=== SonarQube Fix Summary ===
Files processed: X / Y
Issues fixed:    N
Issues skipped:  M (with reasons)
Commits made:    C

Skipped issues:
  - api/foo.py:L42 — Requires major refactor of auth flow
  - ...
```

If issues were skipped, suggest the user review them manually.

If all issues were fixed, suggest running a re-scan to verify:
```
/sonar-fix --skip-scan
```

## Important Rules

1. **NEVER push to remote.** Only commit locally.
2. **NEVER modify test files** unless the issue is in a test file explicitly.
3. **Understand before fixing.** Always read the full function/class context, not just the flagged line.
4. **One commit per file.** All fixes in a single file go in one commit.
5. **Validation is mandatory.** Never commit without passing ruff/eslint + build.
6. **Skip risky fixes.** If a fix could break functionality or requires >50 lines of changes, skip it and document why.
7. **Preserve behavior.** Refactoring must be behavior-preserving. If unsure, skip.
8. **No unnecessary changes.** Don't "improve" code beyond what SonarQube flagged.
