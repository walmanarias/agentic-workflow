---
description: Retrospective on the feature — feedback on the work + process (including PR review feedback), and curate the project's living conventions & advisory rules.
argument-hint: [scope or feature]
---

Invoke the `curator` agent to curate: **$ARGUMENTS** (default: the current feature).

Runs **after `/triage`, before `/ship`** — so the retrospective includes what reviewers (Copilot and
humans) said, the richest source of conventions. Apply the `curation` skill. Inputs: the spec,
`specs/<feature>/review.md`, the PR review threads (`gh pr view --comments` / the reviewThreads
query), `status.md` (loop rounds = friction signal), and the branch diff. Harvest durable decisions
into `docs/conventions.md` (`CONV-<area>-n` ids + provenance), promote the strongest into advisory
`.claude/rules/9x-*` rules, and persist the retrospective to `docs/curation/<date>-<feature>.md`.

Advisory only: write docs and rules under `docs/` and `.claude/rules/` (the role guard enforces
it). Never edit hooks/gates, production code or tests, and never block a commit. Commit the result
(`docs: curate conventions (<feature>)`) and push so it lands in the same PR.
