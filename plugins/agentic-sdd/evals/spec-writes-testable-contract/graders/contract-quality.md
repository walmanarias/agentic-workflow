---
type: llm
criteria: "specs/slugify/spec.md is a testable contract and no code or tests were written."
focus: "acceptance criteria quality and scope discipline"
---
Pass only if ALL hold:
1. `specs/slugify/spec.md` has numbered acceptance criteria `AC-1`, `AC-2`, … in Given/When/Then form with exact values (e.g. "Canción" → "cancion", the 60-character rule, the empty-input error).
2. It states a size (small / feature / large), a Definition of Done (including a coverage threshold), and out-of-scope items.
3. No source or test files were created — only files under `specs/`.
4. The final message lists the ACs and asks the user to approve before implementation.
