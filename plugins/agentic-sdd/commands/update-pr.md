---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
description: Generate or update PR title and description from commits on current branch
argument-hint: [optional extra context to emphasize]
model: opus
---

Automatically generate or update the current PR's title and description by analyzing commits on the branch. Creates comprehensive, well-structured descriptions following project patterns.

> **Where this fits in the workflow:** run `/update-pr` after `/review` and before `/ship` — once the change is reviewed and tests are green, generate/refresh the PR description, then `/ship` verifies the Definition of Done. Sections are added only when the commits actually contain the relevant changes, so this works for any stack (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia, PostgreSQL/MongoDB) — UI-only sections like Accessibility and i18n appear only for front-end changes.

## Usage Examples

```bash
# Basic usage - analyzes commits and generates PR description
/update-pr

# With additional context
/update-pr make sure to mention the conversation with John Doe about grouping ships

# With specific instructions
/update-pr add a section about the business rules for filter application

# Emphasize something specific
/update-pr highlight the accessibility improvements in keyboard navigation
```

## How It Works

1. **Analyzes current branch commits** - Extracts all commits not on main
2. **Checks for existing PR** - Preserves screenshots/videos if PR exists
3. **Generates title + description** - Following project emoji and structure patterns
4. **Updates PR automatically** - Uses `gh pr edit` to update title and body

## What Gets Generated

**Standard Structure:**

```markdown
# <emoji> Title

## 📋 Summary

[2-3 sentences from commits]

## 📸 Demo

[Preserved if exists, or placeholder]

## 🎨 What's Changed

[Bullet points from commits organized by component/feature]

[Additional sections based on changes detected:]

- 📐 Business Rules (if logic/rules in commits)
- 🧪 Test Coverage (if tests added)
- ♿ Accessibility (if UI changes)
- 🌍 Internationalization (if locale changes)
- 🔗 Related Work (if mentions other PRs)
```

## Step 1: Get Current Branch and Commits

```bash
# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Get base branch (main or master)
BASE_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)

# Get all commits on this branch
git log ${BASE_BRANCH}..HEAD --pretty=format:"%h|%s|%b" --reverse
```

**Parse commit information:**

- Extract conventional commit types (feat, fix, refactor, etc.)
- Identify components/features changed
- Note any special keywords (BREAKING, business rule, accessibility, etc.)

## Step 2: Check for Existing PR

```bash
# Try to get existing PR
gh pr view --json number,title,body,url 2>/dev/null
```

**If PR exists:**

- Extract and preserve ALL media: `<img>` tags, video URLs, Loom links
- Extract and preserve special sections: Designer Feedback, Manual Notes
- Update mode: Merge new information with existing content

**If PR doesn't exist:**

- Generate fresh description
- Note: User will create PR after reviewing (`gh pr create`)

## Step 3: Generate Title

**Format:** `<emoji> <type>: <Short Description>`

**Choose emoji based on primary change type:**

- ✨ feat → New feature/component
- 🔄 refactor → Code improvement
- 🐛 fix → Bug fix
- 🎨 style/ui → Design/styling
- ♿ a11y → Accessibility
- 🧪 test → Tests
- 📝 docs → Documentation
- 🔧 chore → Maintenance
- ⚡ perf → Performance

**Title examples from codebase:**

- `✨ Implement Mobile-Responsive Filter Experience with Enhanced Chip Component`
- `🔄 Refactor: Self-Contained RefiningFilters Components`
- `✨ Implement SelectedFilters Component with Horizontal Scrolling`

**Rules:**

- Be specific (include main component name)
- Use action verbs (Implement, Add, Fix, Refactor)
- Keep under 80 characters if possible

## Step 4: Generate Description Body

### 4.1 Always Include Sections

**📋 Summary (Required)**

- 2-3 sentences explaining what changed and why
- Extract from commit messages
- Focus on user/developer impact

**📸 Demo (Required)**

- If PR exists: **PRESERVE ALL existing media**
- If new PR: `_Screenshots/videos to be added_`
- Never remove existing images/videos

**🎨 What's Changed (Required)**

- Group changes by component/feature using commits
- Use emojis for bullet points (✨, 🔧, 📐, etc.)
- Format: `- ✨ **ComponentName** - Brief description`
- Sub-sections for major components

### 4.2 Conditional Sections (Add Based on Changes)

**📐 Business Rules** - Add if commits mention:

- "business rule", "logic", "behavior", "when/then"
- Decision trees or conditional logic
- User-facing behavior changes

Format:

```markdown
## 📐 Business Rules - [Feature Name]

1. **Condition** → Result
2. **Condition** → Result
```

**🧪 Test Coverage** - Add if test files or testing keywords appear in commits. Detect across the whole stack:

- **JS/TS unit:** `*.test.ts(x)` / `*.spec.ts(x)` (Jest/Vitest, React Testing Library, RN Testing Library)
- **JS/TS integration / E2E:** Playwright (`e2e/**/*.spec.ts`), Detox/Maestro (`*.e2e.ts`), Supertest (API)
- **.NET unit:** `*Tests.cs` in a `*.Tests` project (xUnit + FluentAssertions)
- **.NET integration / E2E:** `WebApplicationFactory`, Testcontainers for .NET, Avalonia headless (`[AvaloniaFact]`), Appium
- Commits mentioning "test", "coverage", "e2e", "xunit", "playwright", "detox", "appium"

Format:

```markdown
## 🧪 Test Coverage

### ✅ Unit Tests ([X] tests)

- [Framework]: [Count] scenarios — [area]

### 🎭 Integration / E2E ([X] scenarios)

- [Tool]: [flow covered]
```

**♿ Accessibility** - Add if:

- UI component changes
- Commits mention "accessibility", "aria", "keyboard", "screen reader"

Format:

```markdown
## ♿ Accessibility (WCAG 2.2 AA)

- ⌨️ Keyboard navigation: [details]
- 🔊 Screen reader: [ARIA implementation]
- 🎨 Visual indicators: [focus states]
- 🏗️ Semantic HTML: [proper elements]
```

**🌍 Internationalization** - Add if:

- Locale file changes (`locales/**`)
- Commits mention "i18n", "translation", "locale"

Format:

````markdown
## 🌍 Internationalization

Added for **[X] locales**: [list]

```json
{
  "key": "Translation"
}
```
````

````

**🔗 Related Work** - Add if:
- Commits reference other PRs (#XXX)
- Built on previous work

Format:
```markdown
## 🔗 Related Work

- Builds on [#XXX](link) - [description]
- Addresses review from [#YYY](link)
````

**🔌 API / Contract Changes** - Add if commits touch HTTP endpoints, DTOs, GraphQL, or contracts (Express / Fastify / NestJS / ASP.NET Core Web API):

```markdown
## 🔌 API Changes

- `METHOD /path` — added / changed / removed; request & response shape; **breaking? yes/no**
- Versioning / migration notes for consumers
```

**🗄️ Database & Migrations** - Add if commits include migrations or schema/model changes (PostgreSQL / MongoDB / EF Core):

```markdown
## 🗄️ Database & Migrations

- [PostgreSQL] migration `NNNN_name` — [what]; reversible: yes/no; index/lock impact
- [MongoDB] collection/index change — [what]; backfill needed: yes/no
```

**📑 Spec & Acceptance Criteria** - Add if the branch implements a spec under `specs/` (Spec-Driven Development):

```markdown
## 📑 Spec & Acceptance Criteria

- Spec: `specs/<feature>.spec.md`
- Covers: AC-1, AC-2, … (each mapped to a passing test)
```

### 4.3 Preserve Existing Content

**Always preserve from existing PR:**

- ✅ ALL `<img>` tags with GitHub asset URLs
- ✅ ALL video links (GitHub assets, Loom, etc.)
- ✅ Designer feedback sections starting with `## 💬 Designer Feedback`
- ✅ Manual notes or special instructions
- ✅ Important links or references

**Merge strategy:**

- Keep Demo section intact (never remove media)
- Merge What's Changed (add new bullets, keep existing)
- Update Summary if significantly changed
- Add new sections for new functionality

## Step 5: Apply User-Provided Context

**User can provide additional context in the command:**

```bash
/update-pr mention the conversation with John Doe about ship grouping
```

**Incorporate user context:**

- Add Designer Feedback section if mentioned
- Emphasize specific aspects user mentions
- Add special notes or instructions
- Include rationale for decisions if provided

**Example transformations:**

User: `mention conversation with John Doe about grouping`
→ Add section:

```markdown
## 💬 Designer Feedback - John Doe (Teams)

**Q: Should we group ships under "All Ships" or divide by Ocean/River?**

> For ships filter, Royal doesn't offer river cruises so use "All ships". Celebrity offers both, so divide between Ocean and River sections.
```

User: `highlight the accessibility keyboard navigation improvements`
→ Emphasize in Accessibility section and mention in Summary

User: `add business rule about filters only applying on Apply button`
→ Add to Business Rules section with proper formatting

## Step 6: Update PR

### 6.1 Format Description for gh CLI

Use heredoc to handle multi-line markdown:

```bash
gh pr edit --title "✨ New Title Here" --body "$(cat <<'EOF'
# ✨ Full PR Title

## 📋 Summary
...

[Full markdown content]
EOF
)"
```

### 6.2 Execute Update

```bash
# Update PR title and body
gh pr edit --title "<generated_title>" --body "<generated_body>"

# Verify
gh pr view
```

### 6.3 Handle Errors

**If no PR exists:**

````markdown
ℹ️ No PR found for branch: [branch name]

I've generated a PR title and description. To create the PR:

```bash
gh pr create --title "..." --body "..."
```
````

Or copy the content below and create manually on GitHub.

[Show generated content]

````

**If update fails:**
```markdown
❌ Could not update PR automatically

Generated content is below. Please copy and update manually:

[Show generated content]
````

## Step 7: Output Summary

```markdown
✅ PR Updated Successfully!

**PR #[number]**: [title]
**Branch**: [branch name]
**URL**: [PR URL]

## What Changed

**Title**: [Updated/Unchanged]
**Description**: Updated based on [X] commits

### Sections Generated:

- 📋 Summary
- 🎨 What's Changed
- [Other sections added]

### Preserved:

- ✅ [X] screenshots
- ✅ [X] videos
- ✅ [Other preserved content]

## Review

Please review and add:

- Screenshots/videos if not already present
- Any additional context needed
- Request reviews from team members

**View PR**: `gh pr view --web`
```

## Guidelines

### Writing Style

**Emojis (Use consistently):**

- ✨ New features/components
- 🔧 Technical implementation
- 📐 Business rules
- 🎯 Main features
- 🔌 API / contract changes
- 🗄️ Database / migrations
- 📑 Spec / acceptance criteria
- ♿ Accessibility
- 🧪 Tests
- 🌍 i18n
- 🗑️ Removals
- ✅ Completed/Added

**Bullets:**

- Start with emoji + bold component name
- Use `code` for technical terms
- Active voice, present tense
- Concise but specific

**Sections:**

- Clear hierarchy with emojis
- Required: Summary, Demo, What's Changed
- Conditional: Based on actual changes
- Accessibility: Required for all UI changes

### Critical Rules

**DO:**

- ✅ Preserve ALL media from existing PRs
- ✅ Use project emoji patterns
- ✅ Add Accessibility section for UI changes
- ✅ Include user-provided context
- ✅ Be specific about component names
- ✅ Format business rules clearly
- ✅ Link related PRs when mentioned in commits

**DON'T:**

- ❌ Remove screenshots/videos
- ❌ Remove designer feedback sections
- ❌ Use vague titles ("Update components")
- ❌ Skip accessibility for UI changes
- ❌ Write novels (be concise)
- ❌ Copy entire commit messages verbatim
- ❌ Forget to incorporate user context

## Examples

### Example 1: Basic Usage

```bash
/update-pr
```

**Analyzes commits:**

- 5 commits on feature/mobile-filters
- Main changes: MobileFilterDrawer component
- Tests added for drawer interactions

**Generates:**

```markdown
# ✨ Implement Mobile Filter Drawer with Sticky Footer

## 📋 Summary

Implements mobile-responsive filter drawer with sticky header/footer...

## 🎨 What's Changed

- ✨ **MobileFilterDrawer** - Full-screen drawer for mobile
- 🔧 Sticky footer with Reset/Apply buttons
- ♿ Focus trap and keyboard navigation

## ♿ Accessibility (WCAG 2.2 AA)

...
```

### Example 2: With Context

```bash
/update-pr add section about John Doe's feedback on button placement
```

**Adds to generated description:**

```markdown
## 💬 Designer Feedback - John Doe (Teams)

**Q: Where should the Apply button be positioned?**

> Apply button should be in sticky footer for easy thumb access on mobile.
```

### Example 3: Updating Existing PR

**Existing PR has:**

- 3 screenshots in Demo section
- Initial implementation description

**New commits add:**

- Bug fixes for drawer animation
- Additional test coverage

**Result:**

- ✅ Keeps all 3 screenshots
- ✅ Adds "Bug Fixes" section
- ✅ Updates test count
- ✅ Enhances summary

## Success Criteria

A good PR description:

- ✅ Scannable (emojis, headings, bullets)
- ✅ Answers "what changed and why"
- ✅ Includes accessibility for UI changes
- ✅ Preserves all media and manual content
- ✅ Follows project emoji patterns
- ✅ Incorporates user-provided context
- ✅ Has specific, action-oriented title
- ✅ Links related work when relevant
