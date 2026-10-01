---
description: Plan an approved spec — optional architecture brief + ADRs, then slice the ACs into small TDD slices with a resumable status file.
argument-hint: <feature name or spec path> [--design]
---

Plan: **$ARGUMENTS**

1. Require an approved spec at `specs/<feature>/spec.md` (legacy `specs/<feature>.spec.md` is
   accepted). If none or still Draft, stop and point to `/spec`.
2. **Design (when warranted):** if `--design` was passed, or the spec's size is *feature/large*
   (new module/service, cross-cutting change, new data model), invoke the `architect` agent →
   `docs/design/<feature>.md` + ADRs under `docs/adr/`. Show the key decisions and get approval.
   Skip for *small* changes.
3. **Slices (always):** invoke the `planner` agent (applies the `task-planning` skill) →
   `specs/<feature>/plan.md` + `specs/<feature>/status.md`.
4. Show the slice list (`T-n: title — ACs`) and hand off to `/tdd T-1` (or let `/feature` run the slices).
