---
description: Run the full Spec-Driven Development + TDD loop for a feature, end to end.
argument-hint: <feature description>
model: sonnet
---

Drive the complete SDD + TDD lifecycle for: **$ARGUMENTS**

Use the `spec-driven-development` skill as the playbook and delegate each phase to the right subagent. Stop and ask the user only at the approval gates.

1. **Design (if non-trivial/new module):** invoke the `architect` agent → `docs/design/`. Skip for small changes.
2. **Spec:** invoke `spec-writer` → `specs/<feature>.spec.md`. **Gate:** show the numbered acceptance criteria and get approval before coding.
3. **Red:** invoke `tdd-test-writer` to write failing tests mapped to each AC. Show the failing output.
4. **Green:** invoke `implementer` (and the relevant stack expert — react / react-native / node-backend / nestjs / nextjs / dotnet / avalonia / database) to pass the tests with clean code.
5. **Refactor:** keep tests green while improving structure.
6. **E2E:** invoke `e2e-tester` for criteria marked (E2E).
7. **QA (visual):** invoke `qa-visual` to capture screenshots of the user-facing flows and catch visual bugs (layout, overflow, spacing, contrast, theme). Fix Blocking + Should-fix via `implementer`, then re-inspect until clean. Skip for non-UI changes.
8. **Review:** invoke `code-reviewer`; address Blocking + Should-fix.
9. **Curate:** invoke `curator` to feed back on the work + process and update the project's conventions (`docs/conventions.md`) and advisory rules (`.claude/rules/9x-*`). Advisory only — never blocks.
10. **Describe:** run `/update-pr` to generate/refresh the PR title and description from the branch commits (stack-aware; preserves existing media).
11. **Verify:** confirm every AC maps to a passing test, coverage/lint/type gates pass, and the spec's Definition of Done is met. Summarize what shipped.

Never write production code before a failing test exists. Never weaken a test to make it pass.

**Keep the loop token-frugal:** each subagent returns a compact summary (file paths + `AC-n` ids + verdict/counts), not full file contents, diffs, or run logs. Pass those paths/ids between phases; don't re-echo a subagent's output into this thread. The `qa-visual` phase returns findings + screenshot paths only — never the screenshots.
