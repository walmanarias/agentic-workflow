---
name: task-planning
description: Use after a spec is approved and before any test is written — slice the spec's acceptance criteria into small, ordered, vertical slices (1–3 ACs each) that each run one RED → GREEN → REFACTOR cycle and end in one green commit. Also defines the feature's status.md (resumable state). Trigger on "plan", "break down", "slices", "tasks", or "/plan".
---

# Task planning (spec → slices)

TDD pays off in small cycles. A plan turns the approved spec into **slices**: each one a thin,
vertical piece of behavior that can be tested, implemented, refactored and committed on its own.
Without it, the loop degenerates into "write every test, then write every line of code".

## Inputs
- `specs/<feature>/spec.md` (status **Approved**) — the ACs.
- `docs/design/<feature>.md` when the architect ran — boundaries, contracts, data model.
- The code the feature touches (read only what you need to place files).

## Rules for slicing
1. **1–3 ACs per slice.** Group ACs that share one code path; split an AC that spans several.
2. **Vertical, not horizontal.** A slice cuts through the layers it needs (route → service → repo)
   rather than "all repositories first". Each slice leaves the system working.
3. **Walking skeleton first.** Slice T-1 is the thinnest end-to-end happy path; error paths,
   edge cases and NFRs follow. Then order by dependency, then by risk (riskiest early).
4. **Every AC in exactly one slice.** `(E2E)` ACs still get unit/integration coverage in their
   slice; the E2E test itself comes in the `/e2e` phase.
5. **Name the test level and expected files** so the test writer and implementer don't search.
6. **Mark independence.** Slices that touch disjoint files are `independent: yes` (they could be
   run in parallel worktrees); the default is sequential.
7. **Small enough to review.** If a slice would touch more than ~5 production files or ~300
   lines, split it.

## Output — `specs/<feature>/plan.md`
Use `references/plan-template.md`. Then create or update `specs/<feature>/status.md` from
`references/status-template.md` with every slice listed as `todo`.

## The per-slice cycle (what `/feature` runs for each slice)
1. `tdd-test-writer` — failing tests for the slice's ACs only (RED, fails for the right reason).
2. `implementer` — minimum code to pass, then refactor on green (GREEN → REFACTOR).
3. Orchestrator — run `ac_trace.py` for the slice's ACs and mark the slice `done` in `status.md`.
4. Commit the slice and `status.md` together: `feat(<scope>): <slice title> (AC-x, AC-y)`; the
   pre-commit gate must pass (stage and commit in separate commands).

## When the spec turns out wrong mid-slice
Stop the slice. `spec-writer` amends the spec (bumps `Version`, records the change in the spec's
changelog, status back to **Draft**), the human re-approves, the planner updates the affected
slices, and only then do tests change — deliberately, with a `Test-Change:` trailer.
