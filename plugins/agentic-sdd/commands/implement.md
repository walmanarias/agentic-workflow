---
description: Make the failing tests of a slice pass with minimal clean code (GREEN → REFACTOR).
argument-hint: <slice id (T-n) | test scope>
---

Invoke the `implementer` agent for: **$ARGUMENTS**

It loads the stack skills named in the session's `Stack →` line (or detected from
`${CLAUDE_PLUGIN_ROOT}/tools/stacks.json`) plus `tdd-workflow` and `clean-code`. Write the minimum
code to pass the failing tests, then refactor with tests staying green. Never edit a test to pass
(the role guard blocks it); if a test seems wrong, stop and flag it. Run tests + lint + type-check
before declaring done. When run standalone, finish by committing the slice
(`feat(<scope>): <slice> (AC-x)`) through the gate.
