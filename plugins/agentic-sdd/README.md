# agentic-sdd

Spec-Driven Development + TDD workflow plugin for Claude Code. Provides lifecycle and
stack-expert agents, skills, slash commands, and enforcing quality-gate hooks for
React, React Native, Node (Express/Fastify), NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML, Python (Django/DRF, FastAPI, Flask), PostgreSQL and MongoDB.

See the repository [`CLAUDE.md`](../../CLAUDE.md) for full usage. Start with `/feature <description>`.

## Components
- `agents/` — 8 lifecycle agents + 11 stack experts
- `commands/` — /feature, /plan, /spec, /tdd, /implement, /e2e, /review, /refactor, /cicd, /update-pr, /triage-copilot, /triage-reviews, /ship
- `skills/` — spec-driven-development, tdd-workflow, e2e-testing, clean-code, stack-testing-recipes, cicd-pipelines
- `hooks/` — session reminder, edit guard, post-edit lint, pre-commit gate
- `rules/` — workflow, testing, clean-code, security, git
