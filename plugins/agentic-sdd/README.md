# agentic-sdd

Spec-Driven Development + TDD workflow plugin for Claude Code. Provides lifecycle agents,
stack-expert skills, slash commands, and enforcing quality-gate hooks for
React, React Native, Angular, Node (Express/Fastify), NestJS, Next.js, Remix (incl. React Router 7 framework mode), C#/ASP.NET Core (StyleCop Analyzers), Avalonia/XAML, .NET MAUI, Python (Django/DRF, FastAPI, Flask), PostgreSQL and MongoDB.

See the repository [`CLAUDE.md`](../../CLAUDE.md) for full usage. Start with `/feature <description>`.

## Components
- `agents/` — 10 lifecycle agents (architect, spec-writer, tdd-test-writer, implementer, e2e-tester, qa-visual, code-reviewer, curator, refactorer, cicd-engineer)
- `commands/` — /feature, /plan, /spec, /tdd, /implement, /e2e, /qa, /review, /curate, /refactor, /cicd, /update-pr, /triage-copilot, /triage-reviews, /ship
- `skills/` — 10 workflow playbooks (spec-driven-development, tdd-workflow, e2e-testing, visual-qa, clean-code, stack-testing-recipes, cicd-pipelines, pr-description, xamarin-maui-migration, curation) + 14 stack-expert skills loaded in-context by the lifecycle agents
- `hooks/` — session reminder, edit guard, post-edit lint, pre-commit gate
- `rules/` — workflow, testing, clean-code, structure, security, git
