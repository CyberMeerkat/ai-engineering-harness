# Legal Lens — Plan Review Checklist

> Loaded automatically by `/engineering-plan --plan` during Step 2b (Stakeholder Review Gate).
> Produces 0-3 acceptance criteria from a legal/data protection perspective.

## Review Questions

For the proposed design, evaluate:

1. **PII handling** — Does this feature collect, store, process, or display personally identifiable information?
2. **Consent flows** — If collecting new data, is there a consent mechanism? Can consent be withdrawn?
3. **Data retention** — Is there a retention policy for any new data? Is automatic cleanup implemented?
4. **Right to deletion** — Can a user request deletion of data created by this feature?
5. **Data export** — Can a user export data created by this feature (data portability)?
6. **Error sanitisation** — Do error responses avoid leaking PII, internal paths, or system details?
7. **Logging hygiene** — Do log statements avoid recording PII, tokens, or credentials?
8. **Third-party data sharing** — Does this feature send user data to external services? Is that disclosed?
9. **Audit trail** — Are significant data operations (create, update, delete) logged for compliance?
10. **Age/jurisdiction** — Are there age verification or jurisdiction-specific requirements?

## AC Generation Rules

- Only generate ACs for concerns that are RELEVANT to this specific plan
- Max 3 ACs — focus on the highest-risk data protection concerns
- Each AC must be testable and specific (not "ensure POPIA compliance")
- Format: `AC-LEG-N: <specific, verifiable criterion>`
- If no legal concerns, output "No legal/data concerns for this plan."
