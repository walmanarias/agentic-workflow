---
allowed-tools: Bash, Read, Grep, Glob
description: Generate or update PR title and description from commits on current branch
argument-hint: [optional extra context to emphasize]
model: sonnet
---

Generate or update the current PR's title and description by analyzing the branch's commits. Apply the **`pr-description`** skill for the section catalog, emoji/style guide, and worked examples — load its `references/section-catalog.md` only when you need a specific section's exact format.

> **Where this fits:** run `/update-pr` after `/review` and before `/ship` — once the change is reviewed and tests are green, generate/refresh the PR description, then `/ship` verifies the Definition of Done. Sections appear only when the commits actually contain the relevant changes, so this works for any stack; UI-only sections (Accessibility, i18n) show up only for front-end changes.

## Usage

```bash
/update-pr                                                   # analyze commits, generate/refresh description
/update-pr highlight the accessibility keyboard navigation   # emphasize something specific
/update-pr mention John Doe's feedback on button placement   # add designer-feedback context
```

## Procedure

### 1. Get branch + commits

```bash
CURRENT_BRANCH=$(git branch --show-current)
# Base (default) branch — prefer the local ref (fast, no network)
BASE_BRANCH=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
BASE_BRANCH=${BASE_BRANCH:-main}
git log "${BASE_BRANCH}..HEAD" --pretty=format:"%h|%s|%b" --reverse
```

Parse conventional-commit types (feat / fix / refactor / …), the components touched, and keywords (BREAKING, business rule, accessibility, migration, API).

### 2. Check for an existing PR — and preserve its media

```bash
gh pr view --json number,title,body,url 2>/dev/null
```

If a PR exists, **preserve verbatim**: every `<img>` / video / Loom link, any `## 💬 Designer Feedback` section, and manual notes. Merge new content in; never drop existing media. If none exists, generate fresh content (the user creates it with `gh pr create`).

### 3. Generate title + body

Apply the **`pr-description`** skill:

- **Title:** `<emoji> <action> <short, specific description>` (≤ 80 chars; action verb like Implement/Add/Fix/Refactor; emoji by change type; no `type:` prefix; main component named).
- **Always include:** `## 📋 Summary` (2–3 sentences, what + why), `## 📸 Demo` (preserved media or `_Screenshots/videos to be added_`), `## 🎨 What's Changed` (bullets grouped by component).
- **Conditional sections** (Business Rules, Test Coverage, Accessibility, i18n, API/Contract, Database/Migrations, Spec & AC, Related Work): add one **only** when the commits contain that kind of change. Exact templates live in the skill's `references/section-catalog.md`.

### 4. Apply user context

Incorporate `$ARGUMENTS`: add a Designer Feedback section, emphasize a named aspect, or record a business rule — as provided.

### 5. Update the PR

```bash
gh pr edit --title "<generated_title>" --body "$(cat <<'EOF'
<full markdown body>
EOF
)"
gh pr view
```

If no PR exists or the edit fails, print the generated title + body for the user to apply manually (`gh pr create …`).

### 6. Report

Summarize: PR number/URL, whether the title changed, how many commits were summarized, which sections were generated, and what media/notes were preserved.
