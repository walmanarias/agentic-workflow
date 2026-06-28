---
name: e2e-testing
description: Use when adding or fixing end-to-end / integration tests, to select the right tool for the stack and write reliable, hermetic flows. Trigger on "e2e", "end-to-end", "integration test", "Playwright", "Detox", "Supertest", "flaky test", or before shipping a user-facing flow.
---

# E2E & Integration Testing

Verify whole flows through real interfaces. Complement unit tests; don't duplicate them.

## Pick the tool by stack
| Stack | Tool | Notes |
|---|---|---|
| Next.js / React web | **Playwright** (or Cypress) | Drive the browser; assert by role/text; test SSR + navigation + forms/actions |
| React Native | **Detox** or **Maestro** | Simulator/device flows; RN Testing Library for component-integration |
| Express / Fastify / NestJS API | **Supertest** / **Pactum** | Hit the real app instance; real/containerized DB |
| Service-to-service contracts | **Pact** | Consumer-driven contract tests |
| Any DB integration | **Testcontainers** | Ephemeral PostgreSQL/MongoDB, no mocking the DB |

## Principles
- **Hermetic:** each test seeds and tears down its own data; isolated DB state (transaction rollback or ephemeral container) so tests are parallel-safe and order-independent.
- **Observable outcomes only:** assert UI text/roles, HTTP status+body, or persisted DB state — never internals.
- **No flake:** wait on conditions, never fixed sleeps; stable selectors (`data-testid`/ARIA roles); retries only for genuinely async UI. Run new E2E twice to catch flakiness.
- **Lean:** cover critical journeys and highest-risk failures (auth, payments, data loss). Push exhaustive cases down to unit tests.
- **CI-ready:** tag E2E suites to run separately; document required containers/env vars.

See `references/playwright-setup.md` and `references/api-e2e-setup.md`.
