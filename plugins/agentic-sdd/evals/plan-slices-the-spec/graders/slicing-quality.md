---
type: llm
criteria: "specs/slugify/plan.md slices AC-1..AC-5 into small, ordered TDD slices."
focus: "slice size, coverage of every AC, ordering"
---
Pass only if ALL hold:
1. Slices are named `T-1`, `T-2`, … and each lists 1–3 ACs.
2. Every one of AC-1 … AC-5 appears in exactly one slice.
3. T-1 is the simplest happy path (AC-1 or equivalent); the error case (AC-5) and the length rule (AC-4) come later.
4. `specs/slugify/status.md` lists every slice as `todo`.
5. No source or test files were created (no architect design either — the spec is "small").
