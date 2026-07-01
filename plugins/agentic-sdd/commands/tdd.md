---
description: Write failing tests (RED) for a spec or behavior — TDD step.
argument-hint: <spec file or behavior>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

Invoke the `tdd-test-writer` agent for: **$ARGUMENTS**

Follow the `tdd-workflow` skill. Read the spec, map each acceptance criterion to failing tests that reference the AC id, using the repo's runner (Jest/Vitest). Do NOT write production code. Run the suite and show that the new tests fail for the right reason. Provide a checklist mapping AC-n -> test(s), then hand off to `/implement`.
