---
description: Evaluate GitHub Copilot's PR review comments, decide which are valid, then apply fixes (TDD) or reply with reasoning, and resolve the threads.
argument-hint: [PR number or URL] [optional guidance, e.g. "be conservative"]
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
model: sonnet
---

Triage the **GitHub Copilot** code-review comments on a pull request: judge each suggestion on its merits, then either implement it (following our TDD + clean-code rules) or decline it with a courteous, reasoned reply — and resolve the thread. Optional context: **$ARGUMENTS**

> **Where this fits:** run after a PR is open and Copilot has reviewed it (typically after `/update-pr`). This is distinct from `/review`, which is *our own* reviewer over the diff; here you are responding to an external automated reviewer.

## Prerequisites
- GitHub CLI installed and authenticated (`gh auth status`). If not, stop and tell the user to run `gh auth login`.
- You are on the PR's branch (or the PR number/URL is given in `$ARGUMENTS`).

## Default behavior (safe)
- You **make changes on the current branch and commit** them (commits pass the gated pre-commit hook). You do **not** push, merge, or force-anything — leave that to the user.
- You reply to every Copilot thread you act on, and **resolve** threads you've addressed (applied or reasoned-declined). You **leave unresolved** anything that needs a human decision.
- Never blindly apply a suggestion. Never weaken, skip, or delete a test to satisfy one.

## Step 1 — Identify the PR and fetch Copilot threads

```bash
# Resolve PR number (from $ARGUMENTS if given, else the current branch's PR)
PR=$(echo "$ARGUMENTS" | grep -oE '[0-9]+' | head -1)
[ -z "$PR" ] && PR=$(gh pr view --json number -q .number)

# Owner/repo for GraphQL
read -r OWNER REPO < <(gh repo view --json owner,name -q '.owner.login + " " + .name')

# Pull all review threads with each comment's author, body, location, and ids
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
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

**Filter to Copilot.** Keep only threads whose first comment author login is one of: `copilot-pull-request-reviewer[bot]`, `github-copilot[bot]`, `Copilot`, or any login containing `copilot`. Skip threads that are already `isResolved`. Note threads marked `isOutdated` (the code moved) — usually decline-and-resolve unless still relevant.

For each kept thread record: `threadId` (node id, for resolving), the first comment's `databaseId` (numeric, for replying), `path`, `line`, the suggestion body, and any fenced ` ```suggestion ` block.

## Step 2 — Evaluate each suggestion on its merits

Read the referenced `path` around `line` (and the surrounding function) before judging. Then classify:

- **Accept** — the suggestion is correct and consistent with our rules (`.claude/rules/` and the skills): fixes a real bug, closes a security hole, removes genuine duplication/smell, improves correctness or clarity, or strengthens a test.
- **Decline** — it is wrong or not worth doing: a false positive, contradicts the spec/acceptance criteria, conflicts with our conventions, is purely stylistic and already covered by lint/formatter, weakens or over-mocks a test, adds needless abstraction (YAGNI), or is a speculative micro-optimization without evidence.
- **Defer** — legitimate but needs a human call: ambiguous intent, a product/security decision, a larger refactor outside this PR's scope, or anything you cannot verify.

Be fair and specific. Judge the idea, not the source — Copilot is often right about real bugs and often wrong about context it can't see. When in doubt between Decline and Defer, prefer Defer.

## Step 3 — Act on each thread

**Accept → implement (TDD):**
1. If it changes behavior, add or adjust a failing test first (or note the existing test that covers it), then make the minimal clean change so tests pass. If it's a pure refactor, keep tests green throughout. Use the relevant stack expert for the file's technology.
2. Stage the change. Keep one focused commit per logical fix (Conventional Commits, e.g. `fix: guard null user in AuthService (copilot review)`).
3. Reply on the thread summarizing what you changed and why, then resolve it.

**Decline → reply and resolve:**
- Post a brief, respectful reason ("Thanks — leaving as-is: the empty array is intentional per AC-4, and the existing test asserts it."). Cite the rule, spec/AC, or context that makes the suggestion not apply. Then resolve.

**Defer → reply, leave open:**
- Note that it needs a human decision and why; do **not** resolve. Add it to the summary so the user can follow up.

### Reply to a thread

```bash
# Reply under the Copilot comment (uses the first comment's numeric databaseId)
gh api --method POST "repos/{owner}/{repo}/pulls/$PR/comments/$COMMENT_DBID/replies" \
  -f body="$REPLY_TEXT"
```

### Resolve a thread

```bash
gh api graphql -f query='
mutation($threadId:ID!){
  resolveReviewThread(input:{threadId:$threadId}){ thread{ id isResolved } }
}' -f threadId="$THREAD_ID"
```

## Step 4 — Commit, verify, report

- Run the gate before committing: lint/type-check/tests (JS) or `dotnet format`/`build -warnaserror`/`test` (.NET). Everything must be green. The pre-commit hook enforces this; don't bypass it.
- Do not push or merge — tell the user the branch is updated and ready to push/review.
- End with a summary table:

```markdown
## Copilot review triage — PR #<n>

| Thread | File:line | Verdict | Action |
|---|---|---|---|
| 1 | src/auth/service.ts:42 | ✅ Accept | Added null guard + test; resolved |
| 2 | src/utils/date.ts:10 | 🚫 Decline | Stylistic, handled by lint; replied + resolved |
| 3 | src/orders/repo.ts:88 | 🕓 Defer | Needs decision on index strategy; left open |

Commits: <shas>.  Tests: green.  Left for you: thread #3.
```

## Rules
- Never weaken, skip, or delete a test to satisfy a suggestion. If Copilot suggests changing a test, treat it as a spec question, not a quick fix.
- Don't resolve a thread you didn't actually address. Don't reply with empty acknowledgements — every reply states a decision and a reason.
- Keep replies short, factual, and kind. Disagree without being dismissive.
- Apply our clean-code, testing, and security rules as the standard of "valid", not Copilot's defaults.
- If `gh` is missing/unauthenticated or there are no Copilot threads, say so and stop — don't invent comments.
