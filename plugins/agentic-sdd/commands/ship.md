---
description: Ship the PR — verify the Definition of Done and CI, get the human's explicit go, merge, and watch the deploy.
argument-hint: [feature or PR number]
allowed-tools: Bash, Read, Grep, Glob, Edit, Skill
---

Ship: **$ARGUMENTS** (default: the current branch's PR).

## 1. Definition-of-Done gate — report PASS/FAIL per item
1. **Spec & traceability:** `python3 "${CLAUDE_PLUGIN_ROOT}/tools/ac_trace.py" specs/<feature>` exits 0
   (every AC has a test; every `(E2E)` AC has an E2E test).
2. **Full suites:** unit + integration + E2E, lint, type-check — run the project's commands
   (or `AGENTIC_SDD_GATE=full` semantics: every stack, whole project). All green.
3. **Coverage:** run the suite with coverage (json-summary / cobertura), then
   `python3 "${CLAUDE_PLUGIN_ROOT}/tools/coverage_check.py"` (threshold: the spec's DoD, else
   `$AGENTIC_SDD_COVERAGE`, else 80). Exit 0.
4. **Review:** `specs/<feature>/review.md` has no open Blocking findings and is newer than the last
   code commit — otherwise run `/review` on the delta.
5. **Triage:** no unresolved review threads, no reviewer in `CHANGES_REQUESTED`
   (`gh pr view --json reviewDecision,reviews` + the reviewThreads GraphQL query from `/triage-copilot`).
6. **Curation:** `docs/curation/*-<feature>.md` exists (skip for `/fix` unless curated); the change
   conforms to `docs/conventions.md` when it exists.
7. **Data & contracts:** migrations are reversible/backward-compatible; API changes are versioned
   or backward compatible.
8. **PR description** is current (refresh with `/update-pr` if commits were added since).
9. **CI:** `gh pr checks --watch --fail-fast` — every required check green.

If any item FAILS: stop, list exactly what's needed, update `status.md` — do not merge.

## 2. 🚦 Human confirmation (mandatory)
Show the PASS table, the PR URL, and the merge method you'll use
(`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed` — prefer squash).
**Ask the user to confirm the merge and wait for an explicit yes.** Never merge on your own.

## 3. Merge
```bash
gh pr merge <number> --squash --delete-branch      # or the allowed method the user confirmed
MERGE_SHA=$(gh pr view <number> --json mergeCommit -q .mergeCommit.oid)
```

## 4. Post-merge verification
- Find workflows triggered by the merge: `gh run list --branch <base> --commit "$MERGE_SHA" --json databaseId,name,status`.
  Watch each with `gh run watch <id> --exit-status`.
- If a deploy pauses at a protected environment (staging → approval → production), report that it
  awaits the reviewer's approval in GitHub — don't approve it yourself.
- **If a deploy or post-merge check fails:** report it with the failing job's log excerpt and the
  rollback path — revert PR (`git revert -m 1 $MERGE_SHA` on a `revert/<feature>` branch → `/create-pr`)
  or the pipeline's documented rollback. Propose; don't execute a rollback without the user's go.

## 5. Close out
- `status.md` → phase `shipped`, merge sha, date. Sync local: `git switch <base> && git pull --ff-only`.
- Summarize what shipped (ACs, PR, deploy status).
