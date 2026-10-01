# Rule: Spec-Driven Development + TDD is mandatory

Every behavior change follows the loop, in order:

/spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship

- **Size first.** Trivial (no behavior change) → just commit through the gate. Bug → `/fix`. Feature → the loop above; `/plan` adds the architect only for new modules/services or cross-cutting changes.
- **The spec is the contract.** Every acceptance criterion is numbered (`AC-n`) and maps to at least one automated test. Scope is fixed by the approved spec — new ideas become new ACs (with re-approval) or open questions, never silent additions.
- **Small TDD cycles.** `/plan` slices the spec into vertical slices of 1–3 ACs. Each slice runs RED → GREEN → REFACTOR and ends in one green, gated commit. No production code before a failing test for that behavior.
- **Never weaken a test to pass.** Skips, deleted tests and removed assertions are blocked by the hooks; a deliberate test change carries a `Test-Change: <reason>` commit trailer.
- **Bounded loops.** QA, review and triage fix-rounds stop after `AGENTIC_SDD_MAX_ROUNDS` (default 3) and escalate to the human.
- **State on disk.** Progress lives in `specs/<feature>/status.md`, so any session can resume with `/feature <feature>`.
- A change is "done" only when `/ship` verifies the spec's Definition of Done, CI is green, and the human confirms the merge.
