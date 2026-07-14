# Project Skills

## Autonomous Delivery System

Twenty-one triage-integrated skills work together through a shared triage state (`.claude/state/triage.md`) to enable autonomous, milestone-driven delivery across all business dimensions.

### Onboarding

| Skill | Command | Role |
|-------|---------|------|
| Onboard | `/onboard` | **Start here** — session orientation, project health dashboard, context briefing |

### Planning Skills (think before building)

| Skill | Command | Role |
|-------|---------|------|
| Grill Me | `/grill-me` | **Pre-planning interview** — exhaustive questioning before any plan begins. Feeds into engineering-plan or product-owner. |
| Engineering Plan | `/engineering-plan` | Technical design, vertical slice decomposition, task breakdown, implementation plans |
| Product Owner | `/product-owner` | Sprint planning, backlog, prioritization, feature delivery |

### Execution Skills (delivery & coordination)

| Skill | Command | Role |
|-------|---------|------|
| Milestone | `/milestone` | **Orchestrator** — defines milestones with gates, dependencies, and autonomous execution chains |
| Dev Manager | `/dev-manager` | Delivery tracking, blockers, velocity, risk management |
| Agent Coordination | `/agent-coordination` | Multi-agent orchestration, parallel execution, state reconciliation, permission handling |

### Quality Skills (testing & review)

| Skill | Command | Role |
|-------|---------|------|
| Test | `/test` | Test discovery, execution, evidence capture, coverage tracking |
| Review | `/review` | Code review, PR creation, merge readiness checklists |
| Quality Gate | `/quality-gate` | Acceptance criteria verification, test evidence, health checks |
| Security Review | `/security-review` | CVE tracking, vulnerability scanning, compliance gating |
| Audit | `/audit` | Acceptance verification, test-coverage mapping, gate enforcement |
| UX Audit | `/ux-audit` | User journey mapping, screen evaluation, RBAC verification, visual consistency |
| Domain Audit | `/domain-audit` | Business rules, actors, data vectors, scoring models, integration contracts |

### Delivery Skills (deploy, changelog & learning)

| Skill | Command | Role |
|-------|---------|------|
| Deploy | `/deploy` | Build, push, deploy, verify, rollback across environments |
| Changelog | `/changelog` | Structured changelogs from commits, sprints, milestones |
| Learned | `/learned` | Post-session self-learning — captures problems, resolutions, prevention rules |
| Status | `/status` | Master dashboard — gathers all skill state, presents 3 strategic options |

### Security Skills (offensive + defensive)

| Skill | Command | Role |
|-------|---------|------|
| Security Review | `/security-review` | CVE tracking, vulnerability scanning, dependency audit |
| DevSecOps | `/devsecops` | White/grey/black hat testing, SDLC security gates, threat modelling |

### Governance Skills (compliance & communications)

| Skill | Command | Role |
|-------|---------|------|
| Compliance | `/compliance` | PCI DSS, POPIA, GDPR, SARS, jurisdiction-specific regulatory frameworks |
| Comms | `/comms` | PR voice, cultural sensitivity, official communications approval framework |

### Finance Skills (financial governance)

| Skill | Command | Role |
|-------|---------|------|
| Finance Analyst | `/finance-analyst` | **Wise Owl** — financial impact assessment (FIA), data-driven targets, pricing validation, cost optimisation |
| CFO | `/cfo` | Strategic financial governance, runway tracking, investment decisions, capital allocation |
| Accountant | `/accountant` | SARS/VAT compliance, PayFast reconciliation, invoicing, per-service cost tracking |

### Business Skills (brand & go-to-market)

| Skill | Command | Role |
|-------|---------|------|
| Brand | `/brand` | Design token enforcement, Figma drift, asset consistency |
| Launch | `/launch` | Launch plans, channels, assets, go/no-go criteria |
| Metrics | `/metrics` | KPI definition, analytics instrumentation, success tracking |
| Doc Rules | `/doc-rules` | Documentation compliance, architecture health, governance |

## Quick Start

Start any session with the relevant briefing:
```
/milestone --session-start      # Full milestone dashboard
/dev-manager --session-start    # Delivery briefing
/product-owner --session-start  # Product briefing
/engineering-plan --session-start  # Engineering briefing
```

Or for domain-specific context:
```
/quality-gate --session-start   # Verification status
/deploy --session-start         # Deployment status
/brand --session-start          # Brand health
/launch --session-start         # Launch readiness
/security-review --session-start  # Security posture
/metrics --session-start        # KPI dashboard
/doc-rules --session-start      # Doc compliance
```

## Autonomous Delivery Flow

```
User defines milestone → /milestone --define "Sprint 5 Deploy"
                                    ↓
              /milestone --run "Sprint 5 Deploy"
                                    ↓
         ┌──────────────────────────┼──────────────────────────┐
         ↓                          ↓                          ↓
  /quality-gate              /security-review            /doc-rules
   --verify                     --scan                     --check
         ↓                          ↓                          ↓
    PASS/FAIL                  PASS/FAIL                  PASS/FAIL
         └──────────────────────────┼──────────────────────────┘
                                    ↓
                    All gates PASS? ──→ NO: remediation plan
                         ↓ YES
                  /deploy --execute prod
                    (user confirmation required)
                         ↓
                  /deploy --verify prod
                         ↓
                  /brand --check
                         ↓
                  /metrics --check
                         ↓
                  Milestone PASSED ✓
```

## Shared State Files

| File | Purpose |
|------|---------|
| `.claude/state/triage.md` | **Central hub** — cross-skill shared state |
| `.claude/state/milestone.md` | Milestone orchestrator state |
| `.claude/state/engineering-plan.md` | Engineering plan domain state |
| `.claude/state/dev-manager.md` | Delivery tracking domain state |
| `.claude/state/product-owner.md` | Product/sprint domain state |
| `.claude/state/docs.md` | Documentation compliance state |
| `.claude/state/quality-gate.md` | Verification & evidence state |
| `.claude/state/deploy.md` | Deployment history & environment state |
| `.claude/state/brand.md` | Brand compliance state |
| `.claude/state/launch.md` | Launch readiness state |
| `.claude/state/security.md` | Security posture state |
| `.claude/state/metrics.md` | KPI tracking state |
| `.claude/state/finance.md` | Finance state (analyst + CFO + accountant) |

### Data Directories

| Directory | Contents |
|-----------|----------|
| `.claude/data/plans/` | Engineering plan files (`EP-*.md`) |
| `.claude/data/sprints/` | Sprint scope documents (`sprint-*.md`) |
| `.claude/data/milestones/` | Milestone definitions (`M-*.md`) |
| `.claude/data/evidence/` | Verification evidence (test results, screenshots, health checks) |
| `.claude/data/launches/` | Launch plan files (`L-*.md`) |

## Workflow

```
/grill-me "feature" --for-plan          ← Think: exhaust the decision tree
    ↓
/engineering-plan --plan --from-grill-me ← Plan: vertical slices with HITL/AFK
    ↓
/test --tdd --plan EP-NNN               ← Build: red-green-refactor per slice
    ↓
/quality-gate --verify                  ← Verify: AC evidence + health
    ↓
/deploy --execute prod                  ← Ship: git-only path to production
```

1. **Grill Me** (optional) interviews exhaustively to resolve all design decisions
2. **Product Owner** plans sprints and prioritizes features
3. **Engineering Plan** designs technical implementation with vertical slices
4. **Test** drives development via TDD red-green-refactor per slice
5. **Dev Manager** tracks progress and identifies blockers
6. **Quality Gate** verifies acceptance criteria with evidence
7. **Security Review** ensures no vulnerabilities block deployment
8. **Doc Rules** ensures documentation keeps pace with delivery
9. **Deploy** pushes to environments with safety checks
10. **Brand** enforces design system consistency
11. **Launch** manages go-to-market readiness
10. **Metrics** tracks KPIs and success criteria
11. **Milestone** orchestrates the entire chain autonomously

All skills update the **triage** after every operation. Any new agent reads the **triage** to instantly understand the full project state.

## Build Plan

See `.claude/autonomous-delivery-plan.md` for the full system design and continuation protocol.
