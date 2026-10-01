---
description: Write failing tests (RED) for one slice of the plan — or for a spec/behavior.
argument-hint: <slice id (T-n) | spec path | behavior>
---

Invoke the `tdd-test-writer` agent for: **$ARGUMENTS**

Follow the `tdd-workflow` skill. Scope to the slice's ACs when a slice id is given (read
`specs/<feature>/plan.md`). Use the repo's runner — Jest/Vitest, Jasmine/Karma, xUnit, or pytest
(the session's `Stack →` line names it). Reference the AC id in every test name. Do NOT write
production code (the role guard blocks it). Run the suite and show that the new tests fail for the
right reason. Return the `AC-n → test` map, then hand off to `/implement`.
