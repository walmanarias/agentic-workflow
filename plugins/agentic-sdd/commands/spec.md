---
description: Write a testable Spec-Driven Development spec for a feature (first step of the loop).
argument-hint: <feature description>
---

Invoke the `spec-writer` agent to produce `specs/<feature>/spec.md` for: **$ARGUMENTS**

Follow the `spec-driven-development` skill and its `spec-template.md`. Output must include the size
(small / feature / large), numbered Given/When/Then acceptance criteria (`AC-n`, `(E2E)` marked),
edge cases, non-functional requirements, out-of-scope, a Definition of Done (with the coverage
threshold), and open questions. Do not write code or tests. End by listing the ACs and asking the
user to approve; on approval set `Status: Approved` and `Version: 1` and hand off to `/plan`.
