---
description: Write a testable Spec-Driven Development spec for a feature (step 1).
argument-hint: <feature description>
model: sonnet
---

Invoke the `spec-writer` agent to produce `specs/<feature>.spec.md` for: **$ARGUMENTS**

Follow the `spec-driven-development` skill and its `spec-template.md`. Output must include numbered Given/When/Then acceptance criteria (AC-n), edge cases, non-functional requirements, out-of-scope, and a Definition of Done. Do not write code or tests. End by listing the ACs and asking the user to approve before implementation.
