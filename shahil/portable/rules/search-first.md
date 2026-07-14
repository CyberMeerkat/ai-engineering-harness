# Search First

> Before proposing any solution, research the codebase.

## The Rule

When asked to implement, fix, or modify something:

1. **Search** — Grep/Glob for existing implementations, patterns, and related code
2. **Understand** — Read the found code. Identify reusable functions, utilities, and patterns.
3. **Then propose** — Only after understanding what exists, propose the approach.

## Why

- Avoids reimplementing what already exists
- Reuses established patterns (consistency)
- Catches edge cases that existing code already handles
- Prevents introducing conflicting approaches

## When to Skip

- Trivial changes (typo fixes, single-line edits)
- User explicitly says "just do it" or provides the exact code
- The user has already identified the files to change
