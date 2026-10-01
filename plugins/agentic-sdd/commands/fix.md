---
description: Lightweight bug-fix track — reproduce with a failing regression test, fix minimally, review, PR, ship.
argument-hint: <bug description, issue link, or error>
---

Fix the bug: **$ARGUMENTS**

/fix: reproduce → RED regression test → GREEN fix → commit → /review → /create-pr → /triage → /ship

1. **Branch:** `fix/<slug>` from an up-to-date default branch.
2. **Reproduce:** find the cause (use the `engineering:debug` approach if available: reproduce,
   isolate, diagnose). Write `specs/fixes/<slug>.md`: symptom, repro steps, root cause, expected
   behavior as `AC-1` (+ `AC-2…` for related regressions), and the affected area. Ask the user to
   confirm only if the expected behavior is ambiguous.
3. **RED:** `tdd-test-writer` writes a regression test named after `AC-1` that fails *because of
   the bug* (show the failure).
4. **GREEN:** `implementer` makes the minimal fix; refactor only what the fix touches.
5. **Commit:** `fix(<scope>): <what> (AC-1)` through the gate.
6. **E2E / QA:** only if a user-facing flow is affected.
7. **Review → PR → triage → ship:** `/review`, `/create-pr`, `/triage`, `/ship` (curation is
   optional for fixes — run `/curate` when the bug reveals a pattern worth a convention).

If the "bug" turns out to be missing behavior or a spec change, stop and switch to `/feature`.
