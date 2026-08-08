# CLAUDE.md — Agentic Workflow Source of Truth

This repository is a **template** that brings a Spec-Driven Development (SDD) + Test-Driven Development (TDD) agentic workflow to any project. It ships as a Claude Code **plugin** (`agentic-sdd`) and as a copyable `.claude/` folder. This file is the operational contract the agents follow; install instructions, repository layout, and CI notes live in `README.md`.

> **Stack:** React, React Native, Node.js (Express/Fastify), NestJS, Next.js, C#/ASP.NET Core Web APIs, Avalonia (XAML) desktop, .NET MAUI (incl. Xamarin.Forms migration), Python (Django/DRF, FastAPI, Flask), PostgreSQL, MongoDB. Unit tests with Jest/Vitest, xUnit, pytest; E2E with Playwright / Detox / Supertest / Testcontainers / WebApplicationFactory / Avalonia.Headless / Appium / httpx. Cross-platform incl. macOS (Tahoe) on Apple Silicon — .NET work targets modern cross-platform **.NET 8/9** (arm64), never the Windows-only .NET Framework.

> **Language:** English is the default — respond in **Spanish only when the user writes in Spanish or explicitly asks for it**. Generated artifacts (specs, test names, comments, commit/PR descriptions) follow the working language, but Conventional Commits prefixes (`feat`, `fix`, …), the `AC-n` / `CONV-<area>-n` ids, and code/technical names always stay in English.

---

## The core idea

The **spec is the source of truth**. Tests encode the spec. Code satisfies the tests. Work flows in one direction and every line traces back to a numbered acceptance criterion (`AC-n`).

```
/plan → /spec → /tdd → /implement → /e2e → /qa → /review → /curate → /update-pr → /ship
design  spec    RED     GREEN+refac   E2E    QA    review   curate     PR desc      ship gate
```

**Two hard rules, everywhere:**
1. No production code is written before a failing test exists for that behavior.
2. Never weaken, skip, or delete a test to make code pass. If a test is wrong, fix it deliberately and say why.

Run the whole loop with one command — `/feature <description>` — which stops at the approval gates (after the spec, before shipping). Or drive each phase yourself with the individual commands.

## Context & token discipline

Artifacts on disk are the interface between phases. Every agent writes its full output to its artifact (spec, design doc, tests, QA report) and returns only a compact summary — file paths, `AC-n` ids, verdict/counts. Pass paths between phases; never re-echo a subagent's output into the orchestrating thread. Each agent starts from the artifacts named in its task and widens its search only when they don't answer the question. Screenshots stay inside `qa-visual`'s context — only text findings + paths come back.

## Commands

| Command | What it does | Delegates to |
|---|---|---|
| `/feature <desc>` | Full SDD+TDD loop end to end | all lifecycle agents |
| `/plan <desc>` | Architecture/design brief + ADRs | `architect` |
| `/spec <desc>` | Testable spec with numbered `AC-n` | `spec-writer` |
| `/tdd <spec>` | Failing tests (RED) mapped to each `AC-n` | `tdd-test-writer` |
| `/implement <scope>` | Minimal clean code to pass (GREEN), then refactor | `implementer` (+ stack skill) |
| `/e2e <flow>` | Reliable end-to-end / integration tests | `e2e-tester` |
| `/qa [flow]` | Visual QA — screenshots + inspection | `qa-visual` |
| `/review [scope]` | Clean-code / correctness / security / test review of the diff | `code-reviewer` |
| `/curate [scope]` | Retrospective; curates conventions & advisory rules | `curator` |
| `/refactor <target>` | Behavior-preserving cleanup under green tests | `refactorer` |
| `/cicd <target>` | GitHub Actions CI/CD pipeline (build→test→deploy) | `cicd-engineer` |
| `/update-pr [context]` | PR title & description from branch commits | (gh CLI) + `pr-description` skill |
| `/triage-copilot [pr]` | Triage Copilot review comments; fix (TDD) or reply + resolve | (gh CLI) |
| `/triage-reviews [pr]` | Triage human review comments; answer, implement, or discuss | (gh CLI) |
| `/ship [feature]` | Pre-merge gate: verifies the Definition of Done | (verification) |

## Agents (lifecycle)

| Agent | Role | Writes to |
|---|---|---|
| `architect` | System design, boundaries, contracts, ADRs | `docs/design/`, `docs/adr/` |
| `spec-writer` | Testable spec with `AC-n` | `specs/` |
| `tdd-test-writer` | RED — failing tests per `AC-n`; never production code | test files |
| `implementer` | GREEN → REFACTOR; never edits tests to pass | source files |
| `e2e-tester` | Hermetic, parallel-safe E2E per stack | E2E test files |
| `qa-visual` | Screenshots user-facing flows; finds visual bugs | QA report (findings + paths) |
| `code-reviewer` | Reviews the diff — Blocking / Should-fix / Nit | review output |
| `curator` | Retrospective; curates conventions & advisory rules | `docs/conventions.md`, `.claude/rules/9x-*` |
| `refactorer` | Behavior-preserving cleanup under green tests | source files |
| `cicd-engineer` | GitHub Actions pipelines; staging→approval→prod | `.github/workflows/` |

**Stack expertise lives in skills, not agents.** The `implementer`, `tdd-test-writer`, and `e2e-tester` load the matching stack skill into their own context instead of spawning a second agent: `react-expert`, `react-native-expert`, `node-backend-expert`, `nestjs-expert`, `nextjs-expert`, `django-expert`, `fastapi-expert`, `flask-expert`, `dotnet-expert`, `avalonia-expert`, `maui-expert`, `database-expert`. Asking to "use the nestjs-expert" loads that skill.

## Skills

Workflow playbooks in `plugins/agentic-sdd/skills/`: `spec-driven-development` (the loop + spec template), `tdd-workflow` (Red/Green/Refactor), `e2e-testing`, `visual-qa`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description` (loaded by `/update-pr`), `xamarin-maui-migration` (loaded by the `maui-expert` skill), `curation` — plus the 12 stack-expert skills listed above. Deep reference material sits in each skill's `references/` and is read only on demand.

## Hooks (enforcing quality gates)

| Hook event | Script | Effect |
|---|---|---|
| `SessionStart` | `session-start.sh` | Injects a short workflow reminder |
| `PreToolUse` (Edit/Write) | `guard-edits.sh` | **Blocks** focused tests (`.only`), debugger statements, and blanket lint/type-suppression comments |
| `PostToolUse` (Edit/Write) | `post-edit-quality.sh` | Auto-formats the changed file (ESLint / `dotnet format` / `ruff`/`black`); surfaces remaining errors |
| `PreToolUse` (Bash `git commit`) | `pre-commit-gate.sh` | **Blocks the commit** unless gates pass — JS: lint+typecheck+tests; .NET: format+build `-warnaserror`+test; Python: ruff+mypy+pytest — and no focus markers/debuggers staged |

The gate is **polyglot**: it runs whichever toolchains the repo actually has and silently skips the rest. Hooks never run network installs. Emergency escape: `git commit --no-verify` (use sparingly).

## Rules

Short, enforceable policies in `plugins/agentic-sdd/rules/` (mirrored to `.claude/rules/` on install):

- `00-workflow.md` — SDD + TDD is mandatory; spec is the contract.
- `10-testing.md` — TDD discipline, behavior-not-internals, the pyramid, coverage.
- `20-clean-code.md` — naming, SOLID, hexagonal boundaries, no smells.
- `25-structure.md` — organize by layer/feature; ecosystem conventions; design patterns.
- `30-security.md` — input validation, parameterized queries, authz, secrets.
- `40-git.md` — gated commits, Conventional Commits, focused commits.

## Conventions this workflow assumes

- **JS/TS repos:** ESLint + a `typecheck` (or `tsc --noEmit`) and a `test` script in `package.json` enable the full gate. Tests co-located as `*.test.ts` / `*.spec.ts` or under `__tests__/`.
- **.NET repos:** a `.sln` or `.csproj` enables the .NET gate. Nullable reference types on; xUnit + FluentAssertions; tests in a `*.Tests` project. Target `net8.0`/`net9.0` (arm64 on Apple Silicon).
- **Python repos:** a `pyproject.toml`/`setup.py`/`requirements.txt` enables the Python gate; each tool runs only when the project adopts it (`ruff`, `mypy`, `pytest`). Tests as `test_*.py` / `*_test.py` or under `tests/`.
- Missing toolchains are skipped, not failed — polyglot repos run every applicable gate.
- Specs in `specs/`, designs in `docs/design/`, decisions in `docs/adr/`.
- Each acceptance criterion is referenced by id (`AC-3`) in the test name for traceability.
