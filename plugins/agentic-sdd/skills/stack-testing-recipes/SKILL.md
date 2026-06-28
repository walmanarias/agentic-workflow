---
name: stack-testing-recipes
description: Use to pick the right testing tools and write the right kind of tests for a specific technology in the stack (React, React Native, Express, Fastify, NestJS, Next.js, PostgreSQL, MongoDB). Trigger on "how do I test <tech>", "which test tool", or when setting up testing for a given framework.
---

# Stack Testing Recipes

Match the test type and tool to the technology. Always follow the pyramid: many unit, some integration, few E2E.

## React (web)
- **Unit/component:** Jest/Vitest + React Testing Library. Query by role/label/text; `userEvent` for interaction; MSW for network. No logic-by-snapshot.
- **E2E:** Playwright.

## React Native
- **Component:** React Native Testing Library + Jest (accessibility queries).
- **E2E:** Detox or Maestro on simulator/device.

## Express / Fastify
- **Unit:** test services in isolation with faked repositories.
- **Integration:** Jest + Supertest against the app factory; real DB via Testcontainers.

## NestJS
- **Unit:** instantiate providers with mocked deps (no Nest boot).
- **Integration/E2E:** `Test.createTestingModule` + Supertest; containerized DB; override only externals.

## Next.js (App Router)
- **Unit:** Jest/Vitest + RTL for client components; test server actions/route handlers/data fns as plain functions.
- **E2E:** Playwright for SSR, navigation, forms, and server actions.

## PostgreSQL
- Integration-test repositories + migrations (up and down) against a containerized Postgres. Verify plans with `EXPLAIN ANALYZE`.

## MongoDB
- Integration-test repositories against a containerized Mongo (or in-memory server). Verify queries hit indexes with `explain()`.

## Always
- Deterministic, hermetic, parallel-safe. Inject clock/uuid/random. Coverage thresholds enforced in CI. E2E tagged to run separately.
