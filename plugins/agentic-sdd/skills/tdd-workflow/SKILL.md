---
name: tdd-workflow
description: Use when implementing any behavior change to follow strict Test-Driven Development — Red, Green, Refactor, one small slice at a time — with Jest/Vitest or Jasmine/Karma (JS/TS), xUnit (C#/.NET), or pytest (Python). Trigger on "TDD", "write tests first", "red green refactor", or whenever code is being added/changed and should be driven by tests.
---

# TDD Workflow (Red → Green → Refactor)

Work one **slice** at a time (1–3 ACs from `specs/<feature>/plan.md`). A slice ends in exactly one
green, gated commit. Batching every test up front and every line of code afterwards is not TDD.

## Red — write a failing test
- Take the slice's next acceptance criterion. Write a test that asserts the desired observable behavior.
- Run it; confirm it fails **for the right reason** (missing behavior, not a typo/import error).
- One behavior per test, Arrange–Act–Assert, descriptive name referencing the AC (`... (AC-3)`).

## Green — make it pass simply
- Write the minimum code to pass. Resist adding anything the test doesn't demand.
- Re-run until green.

## Refactor — clean it up
- With the test green, remove duplication, improve names, reduce nesting, extract seams.
- Re-run tests after each change. Never refactor on red.

## Commit
- `feat(<scope>): <slice> (AC-x, AC-y)` — the pre-commit gate runs lint, types and the related tests.

## What good tests look like
- **Behavior over implementation:** assert public contracts and outputs, never private internals or call counts unless the interaction *is* the contract.
- **Deterministic:** inject the clock, seed randomness, no real network/time. Fake at real seams (DB, HTTP, queue) — prefer in-memory fakes over deep mock chains.
- **Isolated:** no shared mutable state, order-independent, parallel-safe.
- **Fast:** unit tests run in milliseconds; push slow flows to integration/E2E.

## The pyramid
Many small unit tests → fewer integration tests (real DB via Testcontainers) → few E2E tests for critical journeys. Don't invert it.

## Hard rules
- Never edit a test to make failing code pass; if a test is wrong, fix the test deliberately, say why, and add a `Test-Change: <reason>` trailer.
- Never delete assertions or skip tests to go green (the hooks block it).
- Coverage is a floor, not a goal — cover behavior and edge cases, not lines for their own sake.

See `references/jest-patterns.md` (JS/TS), `references/xunit-patterns.md` (C#/.NET) and `references/pytest-patterns.md` (Python) for setup, fakes, async, and parameterized-test patterns.
