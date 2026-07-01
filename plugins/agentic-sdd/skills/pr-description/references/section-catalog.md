# PR Description — Section Catalog & Style Guide

Exact formats for each conditional section, the writing-style guide, worked examples, and the success checklist. The lean overview lives in `../SKILL.md`; load this file only when you need a specific section's template.

## Conditional section templates

Add a section **only** when the branch's commits actually contain that kind of change.

### 📐 Business Rules

Add if commits mention "business rule", "logic", "behavior", "when/then", decision trees, or user-facing behavior changes.

```markdown
## 📐 Business Rules - [Feature Name]

1. **Condition** → Result
2. **Condition** → Result
```

### 🧪 Test Coverage

Add if test files or testing keywords appear. Detect across the whole stack:

- **JS/TS unit:** `*.test.ts(x)` / `*.spec.ts(x)` (Jest/Vitest, React Testing Library, RN Testing Library)
- **JS/TS integration / E2E:** Playwright (`e2e/**/*.spec.ts`), Detox/Maestro (`*.e2e.ts`), Supertest (API)
- **.NET unit:** `*Tests.cs` in a `*.Tests` project (xUnit + FluentAssertions)
- **.NET integration / E2E:** `WebApplicationFactory`, Testcontainers for .NET, Avalonia headless (`[AvaloniaFact]`), Appium

```markdown
## 🧪 Test Coverage

### ✅ Unit Tests ([X] tests)

- [Framework]: [Count] scenarios — [area]

### 🎭 Integration / E2E ([X] scenarios)

- [Tool]: [flow covered]
```

### ♿ Accessibility

Add for UI component changes or commits mentioning "accessibility", "aria", "keyboard", "screen reader".

```markdown
## ♿ Accessibility (WCAG 2.2 AA)

- ⌨️ Keyboard navigation: [details]
- 🔊 Screen reader: [ARIA implementation]
- 🎨 Visual indicators: [focus states]
- 🏗️ Semantic HTML: [proper elements]
```

### 🌍 Internationalization

Add for locale file changes (`locales/**`) or commits mentioning "i18n", "translation", "locale".

````markdown
## 🌍 Internationalization

Added for **[X] locales**: [list]

```json
{
  "key": "Translation"
}
```
````

### 🔌 API / Contract Changes

Add if commits touch HTTP endpoints, DTOs, GraphQL, or contracts (Express / Fastify / NestJS / ASP.NET Core Web API).

```markdown
## 🔌 API Changes

- `METHOD /path` — added / changed / removed; request & response shape; **breaking? yes/no**
- Versioning / migration notes for consumers
```

### 🗄️ Database & Migrations

Add if commits include migrations or schema/model changes (PostgreSQL / MongoDB / EF Core).

```markdown
## 🗄️ Database & Migrations

- [PostgreSQL] migration `NNNN_name` — [what]; reversible: yes/no; index/lock impact
- [MongoDB] collection/index change — [what]; backfill needed: yes/no
```

### 📑 Spec & Acceptance Criteria

Add if the branch implements a spec under `specs/` (Spec-Driven Development).

```markdown
## 📑 Spec & Acceptance Criteria

- Spec: `specs/<feature>.spec.md`
- Covers: AC-1, AC-2, … (each mapped to a passing test)
```

### 🔗 Related Work

Add if commits reference other PRs (#XXX) or build on previous work.

```markdown
## 🔗 Related Work

- Builds on [#XXX](link) - [description]
- Addresses review from [#YYY](link)
```

### 💬 Designer Feedback (from user-provided context)

When the user passes context like `mention the conversation with John Doe about grouping`:

```markdown
## 💬 Designer Feedback - John Doe (Teams)

**Q: Should we group ships under "All Ships" or divide by Ocean/River?**

> For ships filter, Royal doesn't offer river cruises so use "All ships". Celebrity offers both, so divide between Ocean and River sections.
```

## Writing style

**Emojis (use consistently):** ✨ new features · 🔧 technical implementation · 📐 business rules · 🎯 main features · 🔌 API/contract · 🗄️ database/migrations · 📑 spec/AC · ♿ accessibility · 🧪 tests · 🌍 i18n · 🗑️ removals · ✅ completed/added.

**Bullets:** start with emoji + bold component name; use `code` for technical terms; active voice, present tense; concise but specific.

**Sections:** clear hierarchy with emojis; Summary / Demo / What's Changed always; the rest conditional; Accessibility required for any UI change.

**DO:** preserve ALL media from existing PRs · use the project emoji patterns · add Accessibility for UI changes · incorporate user-provided context · be specific about component names · link related PRs mentioned in commits.

**DON'T:** remove screenshots/videos · remove designer-feedback sections · use vague titles ("Update components") · skip accessibility for UI changes · write novels · copy commit messages verbatim · forget user context.

## Worked examples

### Example 1 — basic `/update-pr`

5 commits on `feature/mobile-filters`; main change `MobileFilterDrawer`; tests added.

```markdown
# ✨ Implement Mobile Filter Drawer with Sticky Footer

## 📋 Summary

Implements a mobile-responsive filter drawer with sticky header/footer…

## 🎨 What's Changed

- ✨ **MobileFilterDrawer** - Full-screen drawer for mobile
- 🔧 Sticky footer with Reset/Apply buttons
- ♿ Focus trap and keyboard navigation

## ♿ Accessibility (WCAG 2.2 AA)

…
```

### Example 2 — updating an existing PR

Existing PR has 3 screenshots + an initial description; new commits add bug fixes and tests.
Result: keeps all 3 screenshots, adds a "Bug Fixes" entry, updates the test count, enhances the summary.

## Success checklist

A good PR description is scannable (emojis, headings, bullets); answers "what changed and why"; includes Accessibility for UI changes; preserves all media and manual content; follows the project emoji patterns; incorporates user-provided context; has a specific, action-oriented title; and links related work when relevant.
