# <Feature> Specification

> Status: Draft | Approved   ·   Owner: <name>   ·   Linked design: docs/design/<feature>.md

## Summary
One paragraph: what and why.

## User stories
- As a <role>, I want <capability>, so that <benefit>.

## Functional requirements
- FR-1 ...

## Acceptance criteria
> Each is automatable. Reference the id (AC-1) in the test name.

- **AC-1** — Given <context>, When <action>, Then <observable outcome (exact values/status)>.
- **AC-2** — ...

## Edge cases & error handling
- Empty/missing input, invalid input -> exact response
- Auth/permission failures -> exact response
- Concurrency / duplicate / retry behavior

## Non-functional requirements
- Performance (e.g. p95 < 200ms), security, accessibility, observability.

## Out of scope
- ...

## Definition of Done
- [ ] Every AC has a passing unit/integration test
- [ ] Criteria marked (E2E) have an end-to-end test
- [ ] Coverage >= <threshold> on changed files
- [ ] Lint + type-check pass; no new warnings

## Open questions
- ...
