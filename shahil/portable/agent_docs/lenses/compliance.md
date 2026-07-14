# Compliance Lens — Plan Review Checklist

> Loaded automatically by `/engineering-plan --plan` during Step 2b (Stakeholder Review Gate).
> Produces 0-3 acceptance criteria from a regulatory compliance perspective.

## Review Questions

For the proposed design, evaluate:

1. **Applicable frameworks** — Which regulations apply? (POPIA, GDPR, PCI DSS, SARS, industry-specific)
2. **Data processing register** — Does this add a new processing activity that needs documenting?
3. **Cross-border transfer** — Does data leave the jurisdiction? Is there an adequacy mechanism?
4. **Payment data** — Does this touch card numbers, bank details, or payment tokens? PCI DSS scope?
5. **Marketing communications** — Does this send marketing emails/push? Is opt-out implemented?
6. **Breach notification** — If this creates a new data store, is it covered by the breach response plan?
7. **Data minimisation** — Is only the minimum necessary data collected for the stated purpose?
8. **Purpose limitation** — Is collected data used only for the purpose disclosed to the user?
9. **Record keeping** — Are there tax/financial record-keeping requirements (SARS 5-year retention)?
10. **Accessibility** — Does this feature meet basic accessibility standards?

## AC Generation Rules

- Only generate ACs for concerns that are RELEVANT to this specific plan
- Max 3 ACs — focus on the highest-risk compliance concerns
- Each AC must be testable and specific (not "ensure regulatory compliance")
- Format: `AC-COMP-N: <specific, verifiable criterion>`
- If no compliance concerns, output "No compliance concerns for this plan."
