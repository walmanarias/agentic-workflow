---
description: Pre-merge gate — verify the whole SDD/TDD Definition of Done before shipping.
argument-hint: [feature]
allowed-tools: Read, Grep, Glob, Bash
model: opus
---

Run the pre-ship checklist for: **$ARGUMENTS**

1. Confirm the spec exists and every acceptance criterion maps to a passing test.
2. Run the full test suite, E2E suite, lint, and type-check — all must pass.
3. Verify coverage meets the threshold on changed files.
4. Run `/review` (code-reviewer) and confirm no Blocking findings remain.
5. Check migration safety (PostgreSQL/Mongo) and backward compatibility of any API/contract change.
6. Confirm the spec's Definition of Done is fully satisfied.
7. Ensure the PR is described — if the branch has an open PR, confirm its title/body are current (run `/update-pr` if stale).

Report a clear PASS/FAIL per item. If any fails, stop and list exactly what's needed — do not declare ready.
