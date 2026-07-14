# Testing Standards

> Universal rules. Loaded every session via ~/.claude/rules/.

## Test Structure (AAA)

Arrange-Act-Assert pattern for all tests:

```javascript
test('returns empty array when no results match', () => {
  // Arrange
  const query = 'nonexistent';
  // Act
  const result = searchProducts(query);
  // Assert
  expect(result).toEqual([]);
});
```

## Test Naming

Describe the behavior, not the implementation:
- `'returns empty array when no markets match query'`
- `'throws error when API key is missing'`
- `'falls back to default when config is invalid'`

## Coverage Target: 80%

All three types required for critical paths:
1. **Unit** — individual functions, utilities, services
2. **Integration** — API endpoints with real DB (Prisma + PostgreSQL)
3. **E2E** — critical user flows (Playwright for admin, manual for mobile)

## Rules

- Fix implementation, not tests (unless the test is wrong)
- Check test isolation — no shared mutable state between tests
- Mock external services, not internal modules
- Use `--forceExit --detectOpenHandles` for Jest with DB connections
