# Agentic Workflow — Spec-Driven Development + TDD

A reusable Claude Code workflow that enforces **Spec-Driven Development (SDD)** and **Test-Driven Development (TDD)** across a full-stack TypeScript/JavaScript stack: **React, React Native, Node.js (Express/Fastify), NestJS, Next.js, PostgreSQL, MongoDB**.

It ships as a Claude Code **plugin** (`agentic-sdd`) *and* as a copyable `.claude/` folder, so you can install it in any repo and start shipping clean, tested, maintainable code.

> **Read [`CLAUDE.md`](./CLAUDE.md) for the full source of truth** on how the agents, skills, commands, hooks, and rules work together.

## What's inside

- **13 agents** — 7 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `code-reviewer`, `refactorer`) + 6 stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, PostgreSQL/MongoDB).
- **9 commands** — `/feature`, `/plan`, `/spec`, `/tdd`, `/implement`, `/e2e`, `/review`, `/refactor`, `/ship`.
- **5 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `clean-code`, `stack-testing-recipes`.
- **Enforcing hooks** — block focused tests/`debugger`, lint changed files, and gate `git commit` on lint + types + tests.
- **5 rule files** — workflow, testing, clean code, security, git hygiene.

## Quick start (this repo)

Open this folder with Claude and run:

```
/feature add a health-check endpoint that returns build version and DB status
```

It runs the whole loop — spec → failing tests → implementation → E2E → review → ship — stopping at the approval gates.

## Install into another repo

### Option A — as a plugin (recommended, updatable)

Push this repo to GitHub, then in the target project:

```
/plugin marketplace add walmanarias/agentic-workflow
/plugin install agentic-sdd@agentic-workflow
```

(Replace `walmanarias/agentic-workflow` with your repo path. You can also add it from a local path during development.)

### Option B — copy the `.claude/` folder (self-contained)

```
bash scripts/install.sh /path/to/your/repo
```

This copies `agents/`, `commands/`, `skills/`, `hooks/`, and `rules/` into `<repo>/.claude/`, wires up `settings.json` (merged with any existing one when `jq` is available), and adds a starter `CLAUDE.md` if the repo doesn't have one. Re-run any time to update; pass `--force` to overwrite settings.

## Requirements in the target repo (for the full quality gate)

The hooks degrade gracefully — missing tooling is skipped, never failed. For the complete gate, the target repo should have:

- `package.json` scripts: `lint`, `typecheck` (or a `tsconfig.json`), and `test`.
- ESLint and (for typecheck) TypeScript installed locally.

## The workflow in one line

```
/plan → /spec → /tdd (RED) → /implement (GREEN + refactor) → /e2e → /review → /ship
```

No production code before a failing test. Never weaken a test to pass. Commits are gated on lint + types + tests.

## License

MIT — see [`LICENSE`](./LICENSE).
