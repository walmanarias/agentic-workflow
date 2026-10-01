---
description: Push the feature branch and open (or refresh) its pull request with a generated title and description.
argument-hint: '[feature] [--draft] [extra context for the description]'
allowed-tools: Bash, Read, Grep, Glob, Edit, Skill
model: sonnet
---

Open the pull request for: **$ARGUMENTS**

## 1. Preconditions
```bash
gh auth status                                   # stop and ask for `gh auth login` if this fails
BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@'); BASE=${BASE:-main}
BRANCH=$(git branch --show-current)
git status --porcelain                           # must be empty — commit (through the gate) first
```
- If `BRANCH` is the default branch: stop. Work must be on `feat/<feature>` or `fix/<slug>`.
- The review should be done (`specs/<feature>/review.md` with no open Blocking findings). If not, say so and offer `/review` first.

## 2. Push
```bash
git fetch origin "$BASE"
git push -u origin HEAD          # never --force; if rejected, fetch + rebase/merge and report
```

## 3. Create or refresh the PR
- `gh pr view --json number,url 2>/dev/null` — if a PR exists, run the `/update-pr` procedure and stop.
- Otherwise build the title + body with the **`pr-description`** skill (same procedure as
  `/update-pr` steps 1–4), link the spec (`specs/<feature>/spec.md`) and the slice → commit table
  from `status.md`, then:
```bash
gh pr create --base "$BASE" --head "$BRANCH" --title "<title>" --body "$(cat <<'MD'
<body>
MD
)"            # add --draft when requested
```

## 4. Record and hand off
- Write the PR number + URL into `specs/<feature>/status.md` (phase → `pr-open`).
- Report the URL. Next: wait for reviews (Copilot reviews automatically when enabled in the repo
  settings), then `/triage`.
