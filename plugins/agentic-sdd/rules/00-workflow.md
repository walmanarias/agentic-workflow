# Rule: Spec-Driven Development + TDD is mandatory

Every behavior change follows the loop, in order:

`/plan` (design, optional) → `/spec` → `/tdd` (RED) → `/implement` (GREEN → refactor) → `/e2e` → `/review` → `/ship`.

- No production code is written before a failing test exists for that behavior.
- Every acceptance criterion in the spec is numbered (`AC-n`) and maps to at least one automated test.
- A change is "done" only when the spec's Definition of Done is met and all gates pass.
- Scope is fixed by the spec. New ideas become new acceptance criteria or open questions — never silent additions.
