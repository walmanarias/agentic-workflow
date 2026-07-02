#!/usr/bin/env bash
# Injects a short reminder of the SDD/TDD workflow at session start.
cat <<'MSG'
[agentic-sdd] Spec-Driven Development + TDD is active.
Workflow: /plan (design) -> /spec -> /tdd (RED) -> /implement (GREEN+refactor) -> /e2e -> /review -> /ship.
Rules: no production code before a failing test; never weaken a test to pass; clean code + typed errors; commits are gated on lint + types + tests. See CLAUDE.md.
MSG
exit 0
