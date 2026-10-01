---
description: Triage all open review feedback on the PR — Copilot first, then human reviewers — then refresh the description.
argument-hint: [PR number or URL] [optional guidance]
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Skill
model: sonnet
---

Triage the review feedback on: **$ARGUMENTS** (default: the current branch's PR).

1. Run the `/triage-copilot` procedure (automated reviewer).
2. Run the `/triage-reviews` procedure (humans — reply to every thread; never resolve a
   disagreement yourself).
3. If any commits were added, push them (`git push`, never `--force`) and refresh the PR
   description with the `/update-pr` procedure.
4. Count this as one triage round in `specs/<feature>/status.md`. If `$AGENTIC_SDD_MAX_ROUNDS`
   (default 3) is reached with threads still open, stop and hand them to the user.
5. Report: threads accepted / declined / deferred / open, reviewers still blocking
   (`CHANGES_REQUESTED`), and whether the PR is ready for `/curate` → `/ship`.
