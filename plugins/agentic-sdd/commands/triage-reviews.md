---
description: Triage human reviewers' PR comments — answer questions, implement requested changes (TDD), or discuss disagreements, and reply on every thread.
argument-hint: [PR number or URL] [optional guidance]
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
model: sonnet
---

Triage the **human reviewer** comments on a pull request: answer questions, implement clearly-correct change requests (following our TDD + clean-code rules), and respond thoughtfully to anything you disagree with — replying on every thread. Optional context: **$ARGUMENTS**

> **Where this fits:** run when teammates have reviewed your PR (after `/update-pr`). For the automated reviewer, use `/triage-copilot`. The key difference: **humans have context and authority you don't.** Default to respect — implement what's clearly right, ask or discuss when you disagree, and never dismiss a reviewer by silently resolving their thread.

## Prerequisites
- GitHub CLI installed and authenticated (`gh auth status`). If not, stop and tell the user to run `gh auth login`.
- You are on the PR's branch (or the PR number/URL is given in `$ARGUMENTS`).

## Default behavior (safe + deferential)
- You **make changes on the current branch and commit** them (gated by the pre-commit hook). You do **not** push, merge, or force-anything.
- You **reply to every thread**. You **resolve only threads where you applied the requested change** (and only if your team's convention allows the author to resolve — when unsure, reply and leave it for the reviewer). You **never** resolve a thread by declining a human's request; disagreements stay open for discussion.
- Never weaken, skip, or delete a test to satisfy a comment.

## Step 1 — Identify the PR and fetch human threads

```bash
PR=$(echo "$ARGUMENTS" | grep -oE '[0-9]+' | head -1)
[ -z "$PR" ] && PR=$(gh pr view --json number -q .number)
read -r OWNER REPO < <(gh repo view --json owner,name -q '.owner.login + " " + .name')

gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviews(first:50){ nodes{ author{login} state body } }
      reviewThreads(first:100){
        nodes{
          id isResolved isOutdated
          comments(first:30){
            nodes{ author{login} body path line originalLine diffHunk databaseId url }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F pr="$PR"
```

**Filter to humans.** Exclude any thread whose author login ends in `[bot]` or contains `copilot` (those belong to `/triage-copilot`). Skip `isResolved` threads. Also read the top-level `reviews` to see each reviewer's overall `state` (APPROVED / CHANGES_REQUESTED / COMMENTED) — `CHANGES_REQUESTED` means addressing the threads is required to unblock the merge.

## Step 2 — Classify each comment

Read the referenced code (and surrounding function) first, then sort:

- **Question** — the reviewer is asking for clarification. Answer it directly and honestly on the thread; make a code/comment change only if the question reveals a real gap.
- **Change request (clear)** — a correct, in-scope fix. Implement it.
- **Change request (disagree)** — you have a substantive reason it's wrong or risky. Reply with your reasoning and a proposed alternative; **leave it open** for the reviewer to decide. Do not just comply against your judgment, and do not dismiss it.
- **Nit / optional** — minor preference. Apply if quick and reasonable; otherwise acknowledge and let the reviewer decide.
- **Out of scope** — legitimate but belongs in a follow-up. Acknowledge, suggest a ticket/issue, leave open.

Apply our `.claude/rules/` and skills as the quality bar. When a comment touches the spec or acceptance criteria, treat it as a spec discussion (loop in `/spec` thinking), not a quick patch.

## Step 3 — Act on each thread

**Implement (clear change requests, accepted nits):**
1. TDD: failing test first for any behavior change, then the minimal clean change; pure refactors stay green throughout. Use the relevant stack expert for the file.
2. Commit per logical change (Conventional Commits, referencing the reviewer's point, e.g. `fix: validate email casing per review`).
3. Reply summarizing what you changed (+ commit sha). Resolve only if you applied it and your team lets the author resolve.

**Answer (questions):** reply with a clear, specific answer; resolve if the reviewer's question is fully addressed and no change is needed.

**Discuss (disagreements, out-of-scope):** reply with reasoning / alternative / follow-up suggestion; **leave open**.

### Reply to a thread
```bash
gh api --method POST "repos/{owner}/{repo}/pulls/$PR/comments/$COMMENT_DBID/replies" -f body="$REPLY_TEXT"
```

### Resolve a thread (only when appropriate)
```bash
gh api graphql -f query='
mutation($threadId:ID!){ resolveReviewThread(input:{threadId:$threadId}){ thread{ id isResolved } } }' \
  -f threadId="$THREAD_ID"
```

## Step 4 — Commit, verify, report
- Run the gate (lint/type/test or dotnet format/build/test) — all green — before committing. Don't bypass the hook. Don't push or merge.
- Summary table:

```markdown
## Review triage — PR #<n>

| Thread | Reviewer | File:line | Type | Action |
|---|---|---|---|---|
| 1 | @alice | src/auth/service.ts:42 | Change | Implemented + test; resolved |
| 2 | @bob | src/api/orders.ts:7 | Question | Answered; resolved |
| 3 | @alice | src/db/index.ts:30 | Disagree | Replied with alternative; left open |

Commits: <shas>.  Tests: green.  Reviewers blocking: <list or none>.  Open for discussion: #3.
```

## Rules
- Respect the reviewer. Reply to every thread; never silently resolve or ignore a human comment.
- Never weaken/skip/delete a test to satisfy a comment. Test changes are spec discussions.
- Disagreements stay open with your reasoning — comply only when you're actually persuaded, and say why either way.
- Keep replies concise, specific, and courteous. Apply our rules as the standard of quality.
- If `gh` is missing/unauthenticated or there are no human threads, say so and stop — don't invent comments.
