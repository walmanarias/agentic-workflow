---
name: spec-driven-development
description: Use when starting any non-trivial feature or change, to run the Spec-Driven Development loop — write a testable spec, derive tests, implement, and verify against the spec. Trigger on "spec", "SDD", "new feature", "requirements", or when work should start from a written contract rather than ad-hoc coding.
---

# Spec-Driven Development (SDD)

The spec is the source of truth. Tests encode the spec; code satisfies the tests. Work flows in one direction and every step traces back to a numbered acceptance criterion.

## The loop
1. **(Optional) Design** — for new services/modules or cross-cutting changes, run the `architect` agent first to produce `docs/design/<feature>.md` and ADRs.
2. **Specify** — `spec-writer` produces `specs/<feature>.spec.md`: summary, user stories, functional + non-functional requirements, **numbered Given/When/Then acceptance criteria (AC-n)**, edge cases, out-of-scope, and a Definition of Done.
3. **Red** — `tdd-test-writer` turns each `AC-n` into failing tests that reference the AC id. Confirm they fail for the right reason.
4. **Green** — `implementer` writes the minimum clean code to pass.
5. **Refactor** — improve structure with tests staying green.
6. **E2E** — `e2e-tester` covers the criteria marked "needs E2E" through real interfaces.
7. **Review** — `code-reviewer` checks AC coverage, clean code, security, performance.
8. **Verify** — every `AC-n` maps to a passing test; the Definition of Done is met.

## Rules
- No production code before a spec and a failing test exist for the behavior.
- Every acceptance criterion is numbered and traceable to at least one automated test.
- Scope is fixed by the spec; new ideas become new ACs or open questions, not silent additions.
- A change is "done" only when the spec's Definition of Done is satisfied and gates (lint, types, coverage) pass.

## Spec template
See `references/spec-template.md` for the canonical structure. Place specs in `specs/`, designs in `docs/design/`, decisions in `docs/adr/`.
