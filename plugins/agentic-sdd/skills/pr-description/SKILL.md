---
name: pr-description
description: Use when writing or updating a pull request title and description from a branch's commits. Produces a scannable, stack-aware PR body — emoji-tagged sections added only when the commits warrant them — while preserving existing screenshots, videos, and designer feedback. Trigger on "PR description", "update PR", "write the PR", or "/update-pr".
---

# PR Description

Turn a branch's commits into a scannable PR title + description. Add a section **only** when the commits actually contain that kind of change, so one playbook fits any stack (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia, PostgreSQL/MongoDB) — UI-only sections (Accessibility, i18n) appear only for front-end work.

## Title

`<emoji> <type>: <short, specific description>` — ≤ 80 chars, action verb (Implement / Add / Fix / Refactor), name the main component.

Emoji by primary change: ✨ feat · 🐛 fix · 🔄 refactor · 🎨 style/ui · ♿ a11y · ⚡ perf · 🧪 test · 📝 docs · 🔧 chore.

## Body structure

**Always include:**

- `## 📋 Summary` — 2–3 sentences: what changed and why (user/developer impact).
- `## 📸 Demo` — preserved media if the PR has any, else `_Screenshots/videos to be added_`.
- `## 🎨 What's Changed` — bullets grouped by component: `- ✨ **Component** — brief description`.

**Conditional — add a section only when the commits contain it:**

| Section | Add when commits touch… |
|---|---|
| 📐 Business Rules | logic / behavior / "when → then", decision trees |
| 🧪 Test Coverage | test files or test keywords (jest / vitest / xunit / playwright / detox / appium) |
| ♿ Accessibility | UI changes, aria / keyboard / screen-reader |
| 🌍 Internationalization | `locales/**`, i18n / translation keys |
| 🔌 API / Contract | HTTP endpoints, DTOs, GraphQL, contracts |
| 🗄️ Database & Migrations | migrations, schema / model / index changes |
| 📑 Spec & Acceptance Criteria | a `specs/<feature>.spec.md` on the branch |
| 🔗 Related Work | references to other PRs (#NNN) |

## Always preserve (when updating an existing PR)

Every `<img>` / video / Loom link, any `## 💬 Designer Feedback` section, and manual notes — merge new content in, never remove existing media.

## Reference

See `references/section-catalog.md` for the exact markdown template of each conditional section, the full emoji/style guide, worked before/after examples, and the success checklist — load it only when you need a specific section's format.
