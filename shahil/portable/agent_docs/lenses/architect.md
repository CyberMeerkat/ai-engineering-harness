# Architect Lens — Plan Review Checklist

> Loaded automatically by `/engineering-plan --plan` during Step 2b (Stakeholder Review Gate).
> Produces 0-3 acceptance criteria from an architecture perspective.

## Review Questions

For the proposed design, evaluate:

1. **Schema impact** — Does this add/modify database tables or columns? If yes, is a migration planned (not just `db:push`)?
2. **Existing patterns** — Does the design reuse existing service/controller/route patterns, or introduce a new pattern? If new, is the divergence justified?
3. **API contract** — Are new endpoints consistent with existing REST conventions (naming, response format, error codes)?
4. **Integration points** — Which existing services/modules does this touch? Are their interfaces stable or will they need changes?
5. **Data flow** — Is the data flow clear from input to storage to output? Any circular dependencies?
6. **Provider pattern** — If adding a new external integration, does it use the provider abstraction pattern?
7. **Migration safety** — Can the migration run without downtime? Is it backwards-compatible with the current codebase?
8. **Component boundaries** — Does this respect the layered architecture (routes → controllers → services → ORM)?
9. **Cross-app impact** — Does this affect multiple apps (API, mobile, admin, storefront)? Are all consumers accounted for?
10. **Idempotency** — For webhook handlers or async operations, is idempotency ensured?

## AC Generation Rules

- Only generate ACs for concerns that are RELEVANT to this specific plan
- Max 3 ACs — focus on the highest-risk architectural concerns
- Each AC must be testable and specific (not "ensure good architecture")
- Format: `AC-ARCH-N: <specific, verifiable criterion>`
- If no architectural concerns, output "No architectural concerns for this plan."
