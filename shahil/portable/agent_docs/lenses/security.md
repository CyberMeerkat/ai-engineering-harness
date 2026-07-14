# Security Lens — Plan Review Checklist

> Loaded automatically by `/engineering-plan --plan` during Step 2b (Stakeholder Review Gate).
> Produces 0-3 acceptance criteria from a security/DevSecOps perspective.

## Review Questions

For the proposed design, evaluate:

1. **New endpoints** — Are new API endpoints protected by authentication middleware?
2. **Authorization** — Are role-based access controls (RBAC) applied? Can users access only their own data?
3. **Input validation** — Is all user input validated and sanitised at the system boundary?
4. **Rate limiting** — Do new endpoints have appropriate rate limits configured?
5. **Secrets management** — Are any new credentials/keys stored in `.env`, not hardcoded?
6. **SQL injection** — Are database queries parameterised (Prisma handles this, but raw queries need checking)?
7. **XSS/injection** — Is user-generated content escaped before rendering?
8. **File uploads** — If accepting files, are type/size limits enforced? Is content validated?
9. **Cryptography** — If encrypting data, are standard algorithms and key sizes used?
10. **Dependency risk** — Does this add new npm packages? Are they from trusted sources with no known CVEs?

## AC Generation Rules

- Only generate ACs for concerns that are RELEVANT to this specific plan
- Max 3 ACs — focus on the highest-risk security concerns
- Each AC must be testable and specific (not "ensure security best practices")
- Format: `AC-SEC-N: <specific, verifiable criterion>`
- If no security concerns, output "No security concerns for this plan."
