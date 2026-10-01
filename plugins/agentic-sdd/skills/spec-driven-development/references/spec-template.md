# <Feature> Specification

> **Status:** Draft | Approved · **Version:** 1 · **Size:** small | feature | large
> **Owner:** <name> · **Linked design:** docs/design/<feature>.md | none

## Summary
One paragraph: what and why.

## User stories
- As a <role>, I want <capability>, so that <benefit>.

## Functional requirements
- FR-1 ...

## Acceptance criteria
> Each is automatable. Reference the id (AC-1) in the test name. Mark ACs that need an
> end-to-end test with (E2E). Never renumber — retire (~~AC-4~~ retired in v2) and add new ids.

- **AC-1** — Given <context>, When <action>, Then <observable outcome (exact values/status)>.
- **AC-2** (E2E) — ...

## Edge cases & error handling
- Empty/missing input, invalid input -> exact response
- Auth/permission failures -> exact response
- Concurrency / duplicate / retry behavior

## Non-functional requirements
- Performance (e.g. p95 < 200ms), security, accessibility, observability.

## Out of scope
- ...

## Definition of Done
- [ ] Every AC has a passing unit/integration test (`ac_trace.py` clean)
- [ ] Every (E2E) AC has an end-to-end test
- [ ] Changed-files coverage >= <threshold, default 80>%
- [ ] Lint + type-check pass; no new warnings
- [ ] Review has no Blocking findings; PR threads triaged; CI green

## Open questions
- ...

## Changelog
- v1 — <date> — initial
