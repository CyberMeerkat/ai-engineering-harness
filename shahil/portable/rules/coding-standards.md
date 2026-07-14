# Coding Standards

> Universal rules. Loaded every session via ~/.claude/rules/.
> Cherry-picked from ECC common rules, adapted for {{PROJECT}} stack.

## Immutability

Create new objects, never mutate existing ones. Spread/destructure for updates. This prevents hidden side effects and makes debugging easier.

## File Organization

Many small files over few large files:
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type (e.g., `features/auth/` not `controllers/`, `services/`)

## Error Handling

- Handle errors explicitly at every level
- User-facing: friendly messages. Server-side: detailed logging
- Never silently swallow errors (no empty catch blocks)
- Use custom error classes with error codes

## Input Validation

- Validate all user input at system boundaries
- Use schema-based validation (Prisma for DB, express-validator/Zod for API)
- Fail fast with clear error messages
- Never trust external data

## Functions

- Under 50 lines per function
- Single responsibility
- Prefer early returns over deep nesting (max 3-4 levels)
- No magic numbers — use named constants

## Naming

- Variables/functions: `camelCase`
- Booleans: `is`, `has`, `should`, `can` prefix
- Components/types: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Files: `kebab-case` (docs) or `camelCase` (code, matching export name)

## Before Marking Complete

- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] Proper error handling (no empty catches)
- [ ] No hardcoded values
- [ ] No mutation of shared state
