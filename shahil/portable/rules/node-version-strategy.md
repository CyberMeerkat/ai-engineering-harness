# Node Version Strategy

> Universal rule. Loaded every session via ~/.claude/rules/.
> Default Node = latest LTS. Every project pins its own version. No exceptions.

## Enforcement directive for Claude (read this first)

When operating in any Node project (presence of `package.json`), Claude MUST:

1. **On first action in the project this session**, check for `.nvmrc` and `engines.node` in `package.json`.
2. **If either missing**, flag it as a finding before proceeding with the user's task. Format:
   `✗ Node-pin gap: <project> missing [.nvmrc | engines.node | both]. Per ~/.claude/rules/node-version-strategy.md, this is required.`
3. **Offer to fix it** in the same turn. Inline the two-file change (1-line `.nvmrc`, ~3-line `engines` block) so the user can approve or decline immediately.
4. **If the user says "skip" or declines**, proceed with the task but record the gap once. Do not nag every turn.
5. **When creating a new Node project**, both files MUST be created in the initial scaffold. No exceptions, no separate ask.
6. **When suggesting `npm rebuild`** (e.g. native module ABI errors), check `.nvmrc` matches active node first; mismatch = root cause, fix that before rebuilding.

This is not advisory. The rule loads every session; treat it as the same kind of constraint as the git-workflow branch protection rules.

## Policy

**Global default: latest Node LTS.** Newest projects get modern APIs and current security patches without opt-in.

**Per-project pin: mandatory.** Every Node project MUST declare its required Node version in two places:

1. `.nvmrc` at project root (used by nvm/fnm/volta auto-switch)
2. `engines.node` in `package.json` (used by npm install warnings + CI)

Both must agree. Mismatch = bug.

## Why this direction (not "old default, latest opt-in")

- New code constantly hits "feature not in this Node" walls when default is old
- EOL Node loses CVE patches → unpatched attack surface across everything not actively pinned
- Native modules (better-sqlite3, sharp, node-gyp deps) tied to ABI; switching Node = `npm rebuild`. Per-project pin prevents surprise rebuilds when cd'ing between projects.

## Version manager (current: nvm)

Working with nvm. Setup:

```bash
# ~/.zshrc — already present if nvm installed
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install latest LTS, set as default
nvm install --lts
nvm alias default 'lts/*'

# Auto-switch on cd into a project that has .nvmrc
# Add to ~/.zshrc AFTER the nvm load lines:
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use --silent
    fi
  elif [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvm use default --silent
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
```

Future migration target: **volta**. Pins via `package.json` `volta` field, no shell hook, faster startup, cross-shell. Migrate when convenient — not required.

## Per-project required artefacts

Every Node project MUST contain:

```bash
# .nvmrc
22
```

```jsonc
// package.json
{
  "engines": {
    "node": ">=22 <23"
  }
}
```

Range follows semver-major bound. Use `>=X <Y` not `^X` (npm `engines` does not support caret syntax cleanly).

When pinning a precise version (because of native-module ABI), use:

```
v22.11.0
```

in `.nvmrc` and matching `"node": "22.11.0"` (exact) in `engines`.

## Enforcement

Three layers, applied in order of cost:

### 1. Pre-commit (cheap, local)

`.husky/pre-commit` or `lefthook.yml` runs:

```bash
#!/usr/bin/env bash
[ -f .nvmrc ] || { echo "✗ .nvmrc missing"; exit 1; }
node -e "const p=require('./package.json'); if(!p.engines?.node){process.exit(1)}" \
  || { echo "✗ package.json engines.node missing"; exit 1; }
NVMRC="$(cat .nvmrc | tr -d 'v ' | head -c2)"
ACTIVE="$(node --version | tr -d 'v' | head -c2)"
[ "$NVMRC" = "$ACTIVE" ] || { echo "✗ .nvmrc=$NVMRC but active node=$ACTIVE"; exit 1; }
```

### 2. CI gate (runs on every PR)

GitHub Actions snippet:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version-file: '.nvmrc'   # fails workflow if absent
- run: |
    test -f .nvmrc || exit 1
    node -e "if(!require('./package.json').engines?.node)process.exit(1)"
```

### 3. Claude Code session check (loaded via rules)

When opening a Node project, check for `.nvmrc` + `engines.node`. If either missing, surface as a finding before doing other work.

## Native module discipline

Projects with C++/native deps (better-sqlite3, sharp, bcrypt, canvas, etc.) MUST pin Node to a precise version (`v22.11.0`, not `22`). ABI changes between minor versions are rare but real. Add to project README:

```
**Requires Node v22.11.0.** This project links native modules. Run `nvm use` (auto via .nvmrc).
If you see `NODE_MODULE_VERSION` errors after a Node upgrade: `npm rebuild`.
```

## Migrations between Node majors

Procedure:
1. Bump `.nvmrc` and `engines.node` together in one commit
2. `nvm install` → `npm rebuild` → `npm test` locally
3. Update CI matrix if testing multiple versions
4. Note in CHANGELOG which native modules were rebuilt

Never bump silently — Node majors break things (deprecations, V8 changes, native ABI).

## Quick reference

| Scenario | Action |
|---|---|
| Starting new project | `nvm install --lts; echo 22 > .nvmrc; npm init` then add `engines` |
| Joining existing project | `nvm use` (reads `.nvmrc`); if missing, add it as first PR |
| Native module ABI error | `npm rebuild <module>` then verify with `node --version` matches `.nvmrc` |
| Two projects, different Node | Each has own `.nvmrc`; auto-switch hook handles cd |
| Working across projects fast | Migrate to volta later — auto-switch with no hook |
