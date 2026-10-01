---
description: Review the branch (merge-base..HEAD plus uncommitted changes) for correctness, tests, clean code, security, and performance.
argument-hint: '[optional scope, base ref, or PR]'
---

Invoke the `code-reviewer` agent to review: **$ARGUMENTS**

**Scope (default):** everything this branch changes — `git diff $(git merge-base <default-branch> HEAD)`
(committed slices) plus any uncommitted changes. The default branch comes from
`git symbolic-ref --short refs/remotes/origin/HEAD` (fallback `main`). A ref or PR number in the
arguments overrides it.

Apply the `clean-code` skill. Check AC coverage (run `${CLAUDE_PLUGIN_ROOT}/tools/ac_trace.py`),
test quality (no weakened/skipped tests, behavior not internals), security (injection, authz,
secrets), performance (N+1, indexes, unbounded loads), maintainability, and conformance to the
project's curated conventions (`docs/conventions.md`, `.claude/rules/9x-*`) when they exist.
Group findings Blocking / Should-fix / Nit with file:line, why, and a concrete fix. Write the
report to `specs/<feature>/review.md` (round number at the top) and return the verdict + Blocking
list. Do not edit source files.
