---
name: tdd-workflow
description: Use when implementing any behavior change to follow strict Test-Driven Development — Red, Green, Refactor — with Jest/Vitest (JS/TS) or xUnit (C#/.NET). Trigger on "TDD", "write tests first", "red green refactor", or whenever code is being added/changed and should be driven by tests.
---

# TDD Workflow (Red → Green → Refactor)

## Red — write a failing test
- Pick the next acceptance criterion or smallest behavior. Write one test that asserts the desired observable behavior.
- Run it; confirm it fails **for the right reason** (missing behavior, not a typo/import error).
- One behavior per test, Arrange–Act–Assert, descriptive name referencing the AC.

## Green — make it pass simply
- Write the minimum code to pass. Resist adding anything the test doesn't demand.
- Re-run until green.

## Refactor — clean it up
- With the test green, remove duplication, improve names, reduce nesting, extract seams.
- Re-run tests after each change. Never refactor on red.

## What good tests look like
- **Behavior over implementation:** assert public contracts and outputs, never private internals or call counts unless the interaction *is* the contract.
- **Deterministic:** inject the clock, seed randomness, no real network/time. Fake at real seams (DB, HTTP, queue) — prefer in-memory fakes over deep mock chains.
- **Isolated:** no shared mutable state, order-independent, parallel-safe.
- **Fast:** unit tests run in milliseconds; push slow flows to integration/E2E.

## The pyramid
Many small unit tests → fewer integration tests (real DB via Testcontainers) → few E2E tests for critical journeys. Don't invert it.

## Hard rules
- Never edit a test to make failing code pass; if a test is wrong, fix the test deliberately and say why.
- Never delete assertions or skip tests to go green.
- Coverage is a floor, not a goal — cover behavior and edge cases, not lines for their own sake.

See `references/jest-patterns.md` (JS/TS) and `references/xunit-patterns.md` (C#/.NET) for setup, fakes, async, and parameterized-test patterns.
