---
name: spec-driven-development
description: Use when starting any non-trivial feature or change, to run the Spec-Driven Development loop — write a testable spec, plan it into small TDD slices, implement slice by slice, verify, open the PR, triage, curate and ship. Trigger on "spec", "SDD", "new feature", "requirements", or when work should start from a written contract rather than ad-hoc coding.
---

# Spec-Driven Development (SDD)

The spec is the source of truth. Tests encode the spec; code satisfies the tests. Work flows in one
direction and every step traces back to a numbered acceptance criterion (`AC-n`).

/spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship

## Size first
| Size | Example | Path |
|---|---|---|
| trivial | copy, config, docs — no behavior change | commit through the gate |
| bug | behavior differs from what was intended | `/fix` (regression test → fix) |
| small | ≤ 3 ACs, one module | loop, no architect |
| feature / large | new module/service, cross-cutting, new data model | loop with the architect |

## The loop
1. **Specify** — `spec-writer` → `specs/<feature>/spec.md`: size, numbered Given/When/Then ACs
   (`(E2E)` marked), edge cases, NFRs, out-of-scope, Definition of Done. 🚦 human approval.
2. **Plan** — `architect` (feature/large only) → `docs/design/<feature>.md` + ADRs; then `planner`
   → `specs/<feature>/plan.md` (vertical slices of 1–3 ACs) + `status.md`.
3. **Per slice** — `tdd-test-writer` (RED, slice ACs only) → `implementer` (GREEN → REFACTOR) →
   `ac_trace.py` → one gated commit `feat(<scope>): <slice> (AC-x)`.
4. **E2E** — `e2e-tester` for every `(E2E)` AC.
5. **Visual QA** — `qa-visual` for UI changes.
6. **Review** — `code-reviewer` over the whole branch → `specs/<feature>/review.md`.
7. **Create PR** — push + `gh pr create` with a generated description.
8. **Triage** — Copilot, then human review threads.
9. **Curate** — conventions + advisory rules, informed by the review feedback.
10. **Ship** — DoD gate (traceability, full suites, coverage, review, triage, CI) → 🚦 human
    confirms → merge → watch the deploy.

## Feature folder
```
specs/<feature>/
  spec.md      contract (Status, Version, Changelog)
  plan.md      slices T-1…T-n
  status.md    phase, slice → commit, loop rounds, blockers — resume point
  review.md    code-reviewer report (latest round)
  qa.md        visual QA report
docs/design/<feature>.md · docs/adr/NNNN-*.md · docs/curation/<date>-<feature>.md
specs/fixes/<slug>.md       (/fix)
```
Legacy `specs/<feature>.spec.md` files are still read; new work uses the folder.

## Rules
- No production code before an approved spec and a failing test for the behavior.
- Every AC is numbered and traceable to at least one automated test (`tools/ac_trace.py`).
- Scope is fixed by the spec; changes go through a versioned amendment and re-approval.
- Loops (QA, review, triage) stop after `$AGENTIC_SDD_MAX_ROUNDS` (default 3) and escalate.
- A change is "done" only when `/ship` passes and the human confirms the merge.

## Spec template
See `references/spec-template.md`.
