---
description: Retrospective on the feature just built — feedback on the work + process, and curate the project's living conventions & advisory rules.
argument-hint: [scope or feature]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

Invoke the `curator` agent to curate: **$ARGUMENTS** (default: the feature/diff just reviewed).

Apply the `curation` skill. Reflect on the work and the process, then harvest durable decisions
into `docs/conventions.md` (organized by area, each with a `CONV-<area>-n` id and provenance) and
promote the strongest into advisory `.claude/rules/9x-*` rules that cite the conventions they
encode. Persist the retrospective to `docs/curation/<date>-<feature>.md`.

Advisory only: write docs and rules under `docs/` and `.claude/rules/`. Never edit hooks/gates,
never touch production code or tests, and never block a commit. Runs after `/review`, before
`/ship`.
