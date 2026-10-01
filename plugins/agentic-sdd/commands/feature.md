---
description: Run the full Spec-Driven Development + TDD loop for a feature, end to end — or resume one that is in flight.
argument-hint: <feature description | existing feature name to resume>
---

Drive the complete SDD + TDD lifecycle for: **$ARGUMENTS**

/spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship

Playbooks: `spec-driven-development` (the loop), `task-planning` (slices + status file). Delegate
each phase to its subagent; you are the orchestrator — you own `specs/<feature>/status.md`, the
commits, and the human gates. Stop and ask the user only at the gates (🚦).

## 0. Resume or start
- If `specs/<feature>/status.md` exists (or the argument names an in-flight feature listed at
  session start), **resume** at its `Phase` — don't redo finished work.
- Otherwise **size** the request:
  - *trivial* (no behavior change: copy, config, docs) → make the change, commit through the gate, stop.
  - *bug* → hand over to `/fix`.
  - *small* (≤ 3 ACs, one module) → loop without the architect.
  - *feature / large* (new module/service, cross-cutting, new data model) → loop with the architect.
- Create the branch `feat/<feature>` from an up-to-date default branch (never work on `main`).

## 1. Spec — `spec-writer` → `specs/<feature>/spec.md`
🚦 Show the numbered ACs, the size, and open questions; get approval. Record `Approved` + version in
the spec, then commit it: `docs(spec): <feature> v1`.

## 2. Plan — `/plan`
- *feature/large:* `architect` → `docs/design/<feature>.md` + ADRs. 🚦 Show the 3–6 key decisions; get approval.
- Always: `planner` → `specs/<feature>/plan.md` + `status.md` (slices of 1–3 ACs). Commit with the
  design docs: `docs(plan): <feature>`.

## 3. Slices — for each `todo` slice T-n, in plan order
1. **RED:** `tdd-test-writer` scoped to T-n's ACs. Confirm they fail for the right reason.
2. **GREEN → REFACTOR:** `implementer` scoped to T-n (loads the stack skills from the session's
   `Stack →` line). Tests stay green through the refactor.
3. **Trace:** `python3 "${CLAUDE_PLUGIN_ROOT}/tools/ac_trace.py" specs/<feature>` — T-n's ACs must
   show OK (gaps from later slices are expected).
4. **Status:** update `status.md`: T-n → `done`; phase → next slice.
5. **Commit:** `git add` the slice's files **and** `specs/<feature>/status.md` in one command, then
   `git commit -m "feat(<scope>): <slice> (AC-x, AC-y)"` in a separate command. The gate runs; if it
   blocks, fix the cause (via the right agent) — never bypass. The sha is in `git log`.

**Spec wrong mid-slice?** Stop. `spec-writer` amends (version bump, status Draft) → 🚦 re-approval →
`planner` re-slices → then tests change deliberately (`Test-Change:` trailer).

## 4. E2E — `e2e-tester` for every `(E2E)` AC → commit `test(e2e): …` (with `status.md`).

## 5. Visual QA — `qa-visual` (UI changes only) → `specs/<feature>/qa.md`. Blocking + Should-fix go
to `implementer`; re-inspect only the fixed screens. Commit fixes.

## 6. Review — `code-reviewer` on `merge-base..HEAD` → `specs/<feature>/review.md`. Blocking +
Should-fix go back to `implementer` (or `refactorer` for pure structure), then re-review the delta.
Commit the fixes together with `review.md` / `qa.md` / `status.md` — artifacts are always committed,
so the working tree is clean for the PR.

## 7. Open the PR — `/create-pr` (push + `gh pr create` + description). Phase → `pr-open`.
Then **pause**: tell the user the PR is open and that `/feature <feature>` resumes after reviewers
(Copilot / teammates) have commented.

## 8. Triage — `/triage` (Copilot first, then humans). Phase → `triage`.

## 9. Curate — `curator`, now that the review feedback exists. Commit `docs: curate conventions (<feature>)`, push.

## 10. Ship — `/ship`: DoD gate + green CI + 🚦 explicit merge confirmation → merge → deploy check.

## Loop limits
QA, review and triage fix-rounds each stop after `$AGENTIC_SDD_MAX_ROUNDS` (default **3**). Count
them in `status.md`; at the limit, stop and hand the remaining findings to the user with a
recommendation instead of looping again.

## Hard rules
- Never write production code before a failing test exists. Never weaken a test to make it pass.
- Never `--no-verify`, never force-push, never merge without the user's explicit yes.

**Token-frugal:** each subagent returns a compact summary (paths + `AC-n` ids + verdict/counts).
Pass paths/ids between phases; don't re-echo subagent output. `qa-visual` returns findings +
screenshot paths only — never images.
