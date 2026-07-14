---
description: "Shared engineering rules — referenced by architect, dev-manager, product-owner, devsecops, audit, and review skills"
---

# Engineering Rules

> Cross-cutting quality rules that ALL skills must enforce. Individual skills reference this file instead of duplicating rules. Updated when post-audit findings reveal systemic patterns.

## Authorization & Identity

1. **Ownership checks must use FK IDs, never emails.** Emails are mutable and may differ between User accounts and domain profiles (vendor registers with company email, user account has personal email). Always match by foreign key: `subscription.vendorId === vendorProfile.id`. Email-based matching is a broken-access-control vulnerability (OWASP A01).

2. **Authorization ACs must specify the identity model.** When an AC says "only the owner can do X", define HOW ownership is determined. The AC should read: "only the vendor whose vendorId matches the subscription's vendorId can cancel" — not "only the owner."

3. **Middleware guards must handle all enum values explicitly.** If auth middleware checks `accountStatus`, every enum value (ACTIVE, SUSPENDED, RESTRICTED, BANNED, INACTIVATED) must have a documented allow/deny decision. Unhandled values default to allow — which is the wrong default for security.

## Error Handling

4. **Empty catch blocks are defects.** Any `catch (err) { }` that silently swallows errors is a bug. At minimum, log with context: `logger.warn('X failed', { id, error: err.message })`. Silent failures in email sends, webhooks, or async side-effects create invisible production issues.

5. **Errors in security-adjacent paths must be logged for incident response.** Auth, authorization, payment, and fraud-detection catch blocks need sufficient context for forensic analysis — not just the error message, but the userId, action attempted, and timestamp.

## Integration Wiring

6. **Verify function signatures before wiring services together.** When connecting services (e.g., calling `emailService.sendX` from `orderService`), verify the actual function signature matches the call site. Parameter name mismatches cause silent `undefined` propagation.

7. **Every email send must have a template.** Before wiring `emailService.sendTemplateEmail(to, templateName, data)`, verify the template file exists at `api/src/templates/emails/{templateName}.hbs` OR has a database fallback. A missing template throws `EmailTemplateMissingError` at runtime — P0 bug in any user-facing flow.

8. **Include relations in the original query instead of separate lookups.** When a service method queries a record and later needs a related entity, use `include: { user: ... }` in the original query instead of a second `findUnique`. Every extra DB round-trip adds latency and failure surface.

9. **Imports belong at the top of the file.** Inline `require()` inside methods is inconsistent with codebase patterns and slightly slower (cache lookup per call). Import at module level.

## Testing & Verification

10. **"Verified" means tested, not audited.** Code audit (grepping for a function call) proves the code path exists. It does not prove the feature works. ACs must be verified by executing the code — automated tests that exercise the path, or manual runtime verification.

11. **Test assertions must verify behaviour, not tautologies.** Tests like `expect('MISSING').toBe('MISSING')` always pass regardless of code state. Verification tests must assert on actual service behaviour (spy on method calls, check return values, verify DB state). Use `test.todo()` for documentation-only placeholders.

12. **Track test counts accurately.** When tests are added, removed, or replaced, update the count in triage immediately. Run the suite after any test file change and record the actual pass/total.

## Infrastructure & Portability

13. **Shell scripts must be portable across bash 3.2+.** macOS ships bash 3.2 which lacks `declare -A` (associative arrays), `readarray`, and other bash 4+ features. Use POSIX-compatible patterns: `for pair in "key:value"; do repo="${pair%%:*}"; branch="${pair##*:}"`.

14. **Migration SQL must target the actual PostgreSQL version.** `ADD CONSTRAINT IF NOT EXISTS` requires PG 17+. If production runs PG 16, use `DO $$ BEGIN ... EXCEPTION WHEN duplicate_object THEN NULL; END $$;` wrappers. Always verify the production PG version before writing DDL.

15. **Avoid duplicated guards at multiple layers.** If auth middleware blocks a condition (e.g., SUSPENDED accounts), don't add the same check in the service layer unless there's a concrete bypass path. Redundant guards add DB queries and create N-places-to-update maintenance burden.

## Deployment

16. **npm audit must run before every production deploy.** Establish a vulnerability baseline. Critical/high vulnerabilities in production-path dependencies block deployment. Dev-only vulnerabilities are tracked but don't block.

17. **Templates, migrations, and resources must exist before wiring code that references them.** A deploy with code that calls a missing template, an unresolved migration, or a non-existent queue is a guaranteed runtime failure. Treat missing resources as deployment blockers.

## Security Defaults

18. **Production defaults must be restrictive.** CORS origin must default to the production domain (not `*`). Swagger/debug endpoints must be gated behind `NODE_ENV !== 'production'`. Debug ports (9229) must be excluded from production compose. If a config has a permissive default for dev convenience, the production path must override it explicitly. *(From: CORS was `*` in prod, Swagger was publicly accessible — commit 3904ef6)*

19. **Disabled providers must throw, not import.** When a payment/storage/auth provider is deprecated or unsupported, its `case` branch must `throw new Error('X is not supported')` — not `require('./xProvider')`. Dead code paths that still import real modules are latent security risks and confuse dependency analysis. *(From: Stripe provider was still importable after PayFast migration — commit e86052c)*

20. **Structured logging must sanitize request bodies.** Any log statement that includes `req.body`, error context, or user data must strip sensitive fields (password, token, cardNumber, idNumber). Use a `sanitizeBodyForLogging()` utility — never `console.log(req.body)` raw. *(From: errorHandler logged full req.body including passwords — commit 3904ef6)*

## Data Integrity

21. **Integrity-critical models are append-only.** Audit logs, email logs, payment transactions, and status history must NOT have PUT or DELETE routes. CRUD generators must support an `APPEND_ONLY_MODELS` config that omits mutation routes. *(From: audit-logs.js had PUT/DELETE that allowed tampering — commit 53c9804)*

22. **Financial operations need idempotency guards.** Before creating a payment session, refund, or subscription charge, check for existing pending/completed transactions on the same entity. Duplicate charges are litigation-grade bugs. *(From: checkout had no double-payment guard — commit 53c9804)*

23. **Self-destructive admin actions need identity guards.** An admin must not be able to delete, suspend, or demote their own account via CRUD endpoints. Add `if (req.params.id === req.user.id) return 400` guards on delete/suspend routes. *(From: SUPER_ADMIN could delete their own User record — commit e1ed9c9)*

## Code Generation

24. **Generators must have a sensitive-field blocklist.** CRUD code generators must exclude security-sensitive fields (passwordHash, encryptionKeyId, OAuth IDs) from create/update validation schemas AND from API response payloads. Use a `BLOCKED_WRITE_FIELDS` + `SAFE_SELECT` pattern at the generator level. *(From: User CRUD exposed passwordHash in create/update — commit 8685782)*

25. **Generators must support append-only mode.** Models tagged as integrity-critical (audit logs, payment transactions, status history) must generate read-only CRUD — GET/POST only, no PUT/DELETE. This must be configurable in the generator, not hand-edited in output files. *(From: audit-log routes had to be manually stripped of PUT/DELETE — commit 17af1c9)*

## Domain & Brand Consistency

26. **Domain and brand references must use environment variables.** Never hardcode domain names (`printpod.com`), support emails, or brand names in source code. Use `process.env.DOMAIN`, `process.env.SUPPORT_EMAIL`, etc. A single domain change should be a `.env` edit, not a 30-file find-and-replace. *(From: 30+ printpod.com URLs scattered across API — commit 27d837d)*

27. **Inherited/template copy must be reviewed for domain accuracy.** When bootstrapping from a template or boilerplate, audit ALL user-visible strings for domain-specific content (delivery times, company names, contact info). "Fast Delivery in 20-30 minutes" from a food-delivery template is wrong for a platform in a different domain. *(From: HomeScreen had mismatched template copy)*

28. **Style values must use design tokens, never inline literals.** Hardcoded hex colors, font sizes, and spacing values in component files create brand drift. All visual values must reference tokens from the design system config (tailwind.config.js, colors.ts). If 770+ inline values need migration, the tokens were missing from the start. *(From: 49 mobile files had hardcoded Zulzi palette — commit 564a432)*

## Container Operations

29. **Healthcheck commands must use tools available in the container image.** `wget` is not in every image (Chatwoot uses Ruby, not Alpine). `pgrep` is not in minimal Python images. Use language-native health checks: Ruby's `Net::HTTP`, Python's `os.kill(1,0)`, Node's `http.get`. Always verify what's installed in the base image before writing healthchecks. *(From: Chatwoot wget failed, GlitchTip pgrep failed — commit 90ae82e)*

30. **Side-effects are part of the operation, not optional follow-ups.** When a business action occurs (vendor rejects order, user deletes account, admin changes status), ALL consequences must be handled atomically: metrics updates, email notifications, audit logging, and downstream triggers. If a side-effect is discovered missing post-launch, it was never in the AC. *(From: vendor rejection didn't update metrics or notify admin — commit e1ed9c9)*

## Secrets & Credentials

31. **Never commit secrets to git — even for "local dev".** Config files containing private keys, JWTs, master encryption keysets, DB passwords, or admin credentials must be gitignored from the start. Use `.example.yaml` templates with placeholder values and document the generation process. If secrets are committed accidentally, rotate them immediately — git history is permanent. *(From: Hatchet server.yaml with JWT private keys + master keyset committed to repo — commit ccb23b0)*

32. **Inline secrets in compose environment blocks are just as bad as committed files.** Base64-encoded private keys, encryption keysets, and cookie secrets in `docker-compose.yml` environment variables are visible to anyone with repo access. Move secrets to config files mounted as volumes (`:ro`), or use `${ENV_VAR}` interpolation from `.env`. *(From: Hatchet engine had raw JWT private key + master keyset as env vars — commit 46d5336)*

33. **Third-party service configs must use the vendor's recommended architecture.** Don't collapse a multi-service system (API + engine + migrate) into a single container with env-var overrides. Follow the vendor's deployment guide — separate services with proper dependency chains (`depends_on: condition: service_completed_successfully` for migration ordering). *(From: Hatchet was a monolith with inline config, had to be split into 3 services — commit 46d5336)*

34. **Hardcoded passwords in compose must use `${ENV_VAR:-default}` syntax.** Every password, token, and connection string in docker-compose files must reference `.env` via interpolation. Direct `password: local_dev_password` strings drift from the actual `.env` values and cause silent auth failures when the real password changes. *(From: 7 agent services had `local_dev_password` while postgres used a different generated password — commit 46d5336, also F-011 infra stabilisation)*

## Deployment Discipline

36. **Git is the ONLY path to production.** Never edit files on VPS/production via SSH (sed, vim, echo >>). Never scp/rsync/docker cp files to production. Never edit docker-compose on VPS without committing to the repo first. All code reaches production through: local edit → commit → push → auto-deploy webhook. Violations create untracked drift that the next deploy silently overwrites. *(From: 2026-04-05 — SSH sed on docker-compose.yml, scp dist to VPS, docker cp into running container, npm install on VPS — all violated git-as-source-of-truth)*

37. **Test locally before pushing.** Run `npm run dev`, `vite build`, or `docker build` locally before pushing to origin. Production is for verification, not experimentation. If the build fails locally, it will fail on VPS — but on VPS it takes down the running service. *(From: package-lock.json drift caused Docker build failure on VPS — lockfile was never tested locally)*

38. **Deploy verification means user-facing, not container-healthy.** A container returning HTTP 200 on `/health` does not mean the feature works. After deploy, verify: (1) the login page renders, (2) the correct sidebar appears per role, (3) key workflows complete. Container health is infrastructure — feature verification is delivery. *(From: VPS showed all containers healthy while vue-gen had zero RBAC — vendors saw 60+ admin CRUD links for 6 sprints)*

39. **RBAC verification is mandatory after every frontend deploy.** Log in (or verify code) as each role and confirm navigation shows only the correct items. The sidebar RBAC gap in vue-gen survived 6 sprints and every audit because no skill checked what users actually see. Grep for `TODO.*role\|TODO.*RBAC\|TODO.*wire` in frontend code. *(From: Sidebar.vue had TODO comments for months — vendorNav existed but was never wired)*

40. **Never regenerate lockfiles on production.** If `npm ci` fails on VPS, the lockfile is stale — fix it locally, commit, push. Running `npm install` on VPS creates a lockfile that exists only on that machine, invisible to git, and will be overwritten on next deploy. *(From: Ran `npm install --package-lock-only` on VPS to unblock Docker build — should have fixed locally first)*

## Mobile & Frontend

41. **AsyncStorage is device-local only.** Mobile preferences stored in AsyncStorage are lost on device switch, app reinstall, or cache clear. Any preference that must persist across devices needs a server-sync mechanism (API endpoint + on-login hydration). *(From: feedback_learned_asyncstorage_not_server_persisted)*

42. **Express route ordering matters.** Specific paths (`/admin/quotes`) must be mounted before parent catch-all paths (`/admin`). Otherwise the parent route handler catches all requests. Verify route ordering in `app.js` after adding new route files. *(From: feedback_learned_express_route_ordering)*

43. **Check existing infrastructure before building.** Before creating a new feature, audit what already exists. NotificationToken, NotificationHistory models, notificationService.js, pushNotificationService.js, and mobile notification slice already exist — F-008 is gap-fill, not greenfield. Duplicate implementations waste time and create maintenance burden. *(From: project_learned_notification_infra_mature)*

44. **Node.js HTTP error `.message` is often empty.** When catching HTTP/network errors, use `err.message || err.code || String(err)` — not just `err.message`. Many Node.js network errors have empty `.message` but populated `.code` (e.g., `ECONNREFUSED`). *(From: feedback_learned_node_http_error_message)*

45. **Service tokens need `{type:'service'}` not `{userId:'system'}`.** For VPS API testing, generate JWT with `{type:'service'}` payload. Tokens with fake userIds fail auth middleware DB lookup. For endpoints requiring a real user context, use a real admin userId from the database. *(From: feedback_learned_service_token_testing)*

46. **npm audit: safe fix first, then --force + test.** Never run `npm audit fix --force` blind. Step 1: `npm audit fix` (non-breaking). Step 2: review what `--force` would change. Step 3: `--force` + run full test suite. Breaking changes from `--force` can corrupt the build. *(From: feedback_learned_npm_audit_two_pass)*

47. **YouTube URLs return page shell only via fetch.** `WebFetch` on YouTube URLs returns the chrome/shell HTML, not video content or transcripts. Use `WebSearch` for written summaries instead. *(From: feedback_learned_youtube_fetch_impossible)*

48. **Circuit breaker: never update `lastProbe` before state check.** In circuit breaker implementations, the probe timestamp must be read before updating — otherwise the state check uses the new timestamp and the half-open window is miscalculated. Use a separate `circuitOpenedAt` field. *(From: feedback_learned_circuit_breaker_timestamp_order)*

## Durability & External Configuration

35. **Code must survive configuration changes in external systems without redeployment.** Any value that a non-developer can change through an external system's UI (pipeline stages, workflow statuses, custom field options, permission levels, category lists) must be fetched dynamically at runtime — never hardcoded. Hardcode only structural identifiers that require developer involvement to change (pipeline IDs, API endpoints, integration keys). Cache dynamic values with a reasonable TTL. Reference items by position, order, or semantic role rather than by name or ID. If an ops person renaming a dropdown option in HubSpot/Jira/Salesforce can break your code, the code is not durable. *(From: 7 hardcoded HubSpot stage IDs replaced with cached API fetch + positional lookup — project-d 2026-04-02)*

## Learned Rules

49. **In bug-fix or validation mode, do not add unrequested features.** If the user asked to debug, validate, or fix a specific problem, solve that problem directly. Do not add schedulers, background automation, new settings, or “helpful” product behavior unless the user explicitly asks for them. If a potential improvement emerges, put it in the plan instead of shipping it ad hoc. *(From: feedback_learned_no_unplanned_features_in_bugfix_mode.md)*
