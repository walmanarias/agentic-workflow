---
description: Review the current diff for clean code, correctness, security, and tests.
argument-hint: [optional scope or PR]
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
---

Invoke the `code-reviewer` agent to review: **$ARGUMENTS** (default: the uncommitted/working diff).

Apply the `clean-code` skill. Check AC coverage, test quality (no weakened/skipped tests, behavior not internals), security (injection, authz, secrets), performance (N+1, indexes, unbounded loads), and maintainability. Also check conformance to the project's curated conventions (`docs/conventions.md`) and advisory rules (`.claude/rules/9x-*`) when they exist — flag deviations; do not fail if these files are absent. Group findings as Blocking / Should-fix / Nit with file:line, why it matters, and a concrete fix. End with a verdict. Do not edit files.
