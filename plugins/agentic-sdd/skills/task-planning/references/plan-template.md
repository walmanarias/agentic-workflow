# Plan: <Feature>

> Spec: specs/<feature>/spec.md (v<N>, Approved) · Design: docs/design/<feature>.md | none
> Size: small | feature | large · Slices: <count>

## Slices

### T-1: <thin end-to-end happy path>
- **ACs:** AC-1
- **Test level:** unit | integration | component
- **Files (expected):** `src/<feature>/domain/...`, `src/<feature>/api/...`, tests alongside
- **Depends on:** —
- **Independent:** no
- **Done when:** AC-1 tests green; committed `feat(<scope>): <title> (AC-1)`

### T-2: <next behavior>
- **ACs:** AC-2, AC-3
- ...

## E2E (after all slices)
- AC-4 (E2E), AC-7 (E2E) → `e2e-tester`

## Risks / notes
- ...
