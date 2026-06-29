# Agentic Workflow — Spec-Driven Development + TDD

A reusable Claude Code workflow that enforces **Spec-Driven Development (SDD)** and **Test-Driven Development (TDD)** across a full-stack TypeScript/JavaScript **and C#/.NET** stack: **React, React Native, Node.js (Express/Fastify), NestJS, Next.js, C# / ASP.NET Core Web APIs, Avalonia (XAML) desktop, PostgreSQL, MongoDB**.

It ships as a Claude Code **plugin** (`agentic-sdd`) *and* as a copyable `.claude/` folder, so you can install it in any repo and start shipping clean, tested, maintainable code. Cross-platform, including **macOS (Tahoe) on Apple Silicon** — .NET work targets modern cross-platform **.NET 8/9** (arm64-native), not the Windows-only .NET Framework.

> **Read [`CLAUDE.md`](./CLAUDE.md) for the full source of truth** on how the agents, skills, commands, hooks, and rules work together.

## What's inside

- **15 agents** — 7 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `code-reviewer`, `refactorer`) + 8 stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML, PostgreSQL/MongoDB).
- **10 commands** — `/feature`, `/plan`, `/spec`, `/tdd`, `/implement`, `/e2e`, `/review`, `/refactor`, `/update-pr`, `/ship`.
- **5 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `clean-code`, `stack-testing-recipes`.
- **Enforcing, polyglot hooks** — block focused tests/`debugger`/`Debugger.Break()`, format/lint changed files (ESLint or `dotnet format`), and gate `git commit` on the toolchains the repo has (JS: lint + types + tests; .NET: format + build `-warnaserror` + test).
- **5 rule files** — workflow, testing, clean code, security, git hygiene.
- **CI workflow** — GitHub Actions on a macOS Apple Silicon runner covering both Node and .NET (build, test, e2e).

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

- **JS/TS:** `package.json` scripts `lint`, `typecheck` (or a `tsconfig.json`), and `test`; ESLint and TypeScript installed locally.
- **.NET:** a `.sln`/`.csproj`, the .NET 8/9 SDK (`dotnet`), and a `*.Tests` xUnit project. For Testcontainers-backed integration tests, a container runtime (Docker Desktop or Colima/Podman) running on arm64. For Avalonia Appium E2E on macOS, grant the test runner Accessibility permission (System Settings → Privacy & Security → Accessibility).

## The workflow in one line

```
/plan → /spec → /tdd (RED) → /implement (GREEN + refactor) → /e2e → /review → /update-pr → /ship
```

No production code before a failing test. Never weaken a test to pass. Commits are gated on lint + types + tests.

## License

MIT — see [`LICENSE`](./LICENSE).
