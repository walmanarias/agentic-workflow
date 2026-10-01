# agentic-sdd

Spec-Driven Development + slice-based TDD workflow plugin for Claude Code. Lifecycle agents,
stack-expert skills, slash commands, tools, and hooks that enforce the hard rules — for the stacks
registered in [`tools/stacks.json`](tools/stacks.json) (React, React Native, Angular, Node
(Express/Fastify), NestJS, Next.js, Remix / React Router 7, C#/ASP.NET Core, Avalonia, .NET MAUI,
Python (Django/DRF, FastAPI, Flask), PostgreSQL and MongoDB).

/spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship

See the repository [`CLAUDE.md`](../../CLAUDE.md) for full usage. Start with `/feature <description>`; bugs with `/fix <description>`.

## Components
- `agents/` — 11 lifecycle agents (spec-writer, architect, planner, tdd-test-writer, implementer, e2e-tester, qa-visual, code-reviewer, curator, refactorer, cicd-engineer)
- `commands/` — /feature, /spec, /plan, /tdd, /implement, /e2e, /qa, /review, /create-pr, /triage, /triage-copilot, /triage-reviews, /curate, /ship, /fix, /refactor, /cicd, /update-pr
- `skills/` — 11 workflow playbooks (spec-driven-development, task-planning, tdd-workflow, e2e-testing, visual-qa, clean-code, stack-testing-recipes, cicd-pipelines, pr-description, xamarin-maui-migration, curation) + 14 stack-expert skills loaded in-context by the lifecycle agents
- `hooks/` — session start (stack + resume), edit guard, role guard, command guard, post-edit format, pre-commit gate
- `tools/` — stack registry + detection, AC traceability, changed-files coverage
- `rules/` — workflow, testing, clean-code, structure, security, git
- `evals/` — `claude plugin eval` cases
