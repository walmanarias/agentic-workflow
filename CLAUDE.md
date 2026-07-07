# CLAUDE.md — Agentic Workflow Source of Truth

This repository is a **template** that brings a Spec-Driven Development (SDD) + Test-Driven Development (TDD) agentic workflow to any of your projects. It ships as a Claude Code **plugin** (`agentic-sdd`) and as a copyable `.claude/` folder. This file is the single source of truth for how the agents, skills, commands, hooks, and rules fit together.

> Stack this workflow targets: **React, React Native, Node.js (Express / Fastify), NestJS, Next.js, C# / ASP.NET Core Web APIs, Avalonia (XAML) desktop, Python (Django / DRF, FastAPI, Flask), PostgreSQL, MongoDB**, tested with **Jest/Vitest**, **xUnit**, and **pytest** (unit) and **Playwright / Detox / Supertest / Testcontainers / WebApplicationFactory / Avalonia.Headless / Appium / httpx** (E2E/integration). Cross-platform, including **macOS (Tahoe) on Apple Silicon** — .NET work targets modern cross-platform **.NET 8/9** (arm64), not the Windows-only .NET Framework.

> **Language:** **English is the default.** Every agent and command matches the language of the conversation — respond in **Spanish only when the user writes in Spanish or explicitly asks for it**; otherwise respond in English. Generated artifacts (specs, acceptance-criteria prose, test names, code comments, commit-message descriptions, PR descriptions) follow that same working language. Regardless of language, these stay in **English by convention**: the Conventional Commits prefixes (`feat`, `fix`, …), the `AC-n` / `CONV-<area>-n` identifiers, and code / technical names (APIs, types, commands).

---

## The core idea

The **spec is the source of truth**. Tests encode the spec. Code satisfies the tests. Work flows in one direction and every line traces back to a numbered acceptance criterion (`AC-n`).

```
/plan → /spec → /tdd → /implement → /e2e → /review → /curate → /update-pr → /ship
design  spec    RED     GREEN+refac   E2E    review   curate     PR desc      ship gate
(opt)  (truth) (tests) (clean code)  (flows)         (conv.)     (describe)
```

**Two hard rules, everywhere:**
1. No production code is written before a failing test exists for that behavior.
2. Never weaken, skip, or delete a test to make code pass. If a test is wrong, fix it deliberately and say why.

---

## How to use it (the happy path)

Run the whole loop with one command:

```
/feature add password reset via email with a 15-minute expiring token
```

`/feature` orchestrates every phase below and stops at approval gates (after the spec, before shipping). Or drive each phase yourself with the individual commands.

---

## Commands

Slash commands are the entry points. Each delegates to the right agent and applies the relevant skill.

| Command | What it does | Delegates to |
|---|---|---|
| `/feature <desc>` | Runs the full SDD+TDD loop end to end | all lifecycle agents |
| `/plan <desc>` | Architecture/design brief + ADRs (for new modules/services) | `architect` |
| `/spec <desc>` | Writes a testable spec with numbered acceptance criteria | `spec-writer` |
| `/tdd <spec>` | Writes failing tests (RED) mapped to each `AC-n` | `tdd-test-writer` |
| `/implement <scope>` | Minimal clean code to pass (GREEN), then refactor | `implementer` + stack expert |
| `/e2e <flow>` | Reliable end-to-end / integration tests | `e2e-tester` |
| `/review [scope]` | Clean-code / correctness / security / test review of the diff | `code-reviewer` |
| `/curate [scope]` | Retrospective — feedback on work + process; curates the project's living conventions & advisory rules | `curator` |
| `/refactor <target>` | Behavior-preserving cleanup, guarded by tests | `refactorer` |
| `/cicd <target>` | Generates/updates a full GitHub Actions CI/CD pipeline (build→test→deploy, stack-aware) | `cicd-engineer` |
| `/update-pr [context]` | Generates/updates the PR title & description from branch commits (stack-aware, preserves media) | (gh CLI) + `pr-description` skill |
| `/triage-copilot [pr]` | Evaluates GitHub Copilot's PR review comments; applies valid fixes (TDD) or replies with reasoning, then resolves the threads | (gh CLI) |
| `/triage-reviews [pr]` | Triages human reviewers' PR comments; answers questions, implements clear change requests (TDD), discusses disagreements | (gh CLI) |
| `/ship [feature]` | Pre-merge gate: verifies the Definition of Done | (verification) |

---

## Agents

Agents are specialists Claude calls automatically (or that commands invoke). Two groups:

### Lifecycle agents (the SDD/TDD pipeline)

| Agent | Role | Writes to |
|---|---|---|
| `architect` | System design, boundaries, data model, API contracts, trade-offs, ADRs | `docs/design/`, `docs/adr/` |
| `spec-writer` | Turns a request/design into a testable spec with `AC-n` | `specs/` |
| `tdd-test-writer` | RED — failing tests that encode each `AC-n`; never writes production code | test files |
| `implementer` | GREEN → REFACTOR — minimal clean code; never edits tests to pass | source files |
| `e2e-tester` | Picks the right E2E tool per stack; hermetic, parallel-safe flows | E2E test files |
| `code-reviewer` | Reviews the diff; findings grouped Blocking / Should-fix / Nit | review output |
| `curator` | Retrospective — feedback on work + process; curates project conventions & advisory rules | `docs/conventions.md`, `.claude/rules/9x-*` |
| `refactorer` | Behavior-preserving structural improvements under green tests | source files |
| `cicd-engineer` | Generates GitHub Actions CI/CD pipelines (build→test→deploy); default staging→approval→prod | `.github/workflows/` |

### Stack expert agents (deep knowledge per technology)

| Agent | Use for |
|---|---|
| `react-expert` | React web — components, hooks, state, performance, RTL tests |
| `react-native-expert` | React Native / Expo — screens, navigation, native modules, Detox/Maestro |
| `node-backend-expert` | Express / Fastify APIs — routing, validation, auth, Supertest |
| `nestjs-expert` | NestJS — modules, DI, guards/interceptors/pipes, DTOs |
| `nextjs-expert` | Next.js App Router — Server/Client Components, server actions, caching |
| `django-expert` | Django / DRF — apps, ORM, migrations, serializers/viewsets, permissions, pytest-django |
| `fastapi-expert` | FastAPI — routers, `Depends` DI, Pydantic v2, async SQLAlchemy, httpx tests |
| `flask-expert` | Flask — app factory, blueprints, extensions, Marshmallow schemas, test client |
| `dotnet-expert` | C# / ASP.NET Core Web APIs — clean architecture, EF Core, DI, xUnit (modern .NET on arm64) |
| `avalonia-expert` | Avalonia / XAML cross-platform desktop — MVVM, compiled bindings, headless + Appium tests |
| `database-expert` | PostgreSQL & MongoDB — schema, indexes, migrations, transactions, query perf |

The `implementer` pulls in whichever stack expert matches the code being changed. You can also call an expert directly (e.g. "use the nestjs-expert to add a guard").

> If you installed the optional **Engineering** plugin, its skills (`code-review`, `testing-strategy`, `architecture`, `system-design`, `debug`, `tech-debt`, `documentation`, `deploy-checklist`, `incident-response`, `standup`) complement these agents for the surrounding workflow.

---

## Skills

Skills are reusable playbooks the agents (and you) apply. They live in `plugins/agentic-sdd/skills/`.

| Skill | When it applies |
|---|---|
| `spec-driven-development` | Starting any non-trivial feature — the full loop + spec template |
| `tdd-workflow` | Any behavior change — Red/Green/Refactor with Jest/Vitest patterns |
| `e2e-testing` | Adding E2E/integration tests — tool selection + reliability rules |
| `clean-code` | Writing/reviewing/refactoring — naming, SOLID, smells, checklist |
| `stack-testing-recipes` | Choosing the right test tool for a specific framework |
| `cicd-pipelines` | Generating a CI/CD pipeline — promotion model, per-target deploy recipes, security baseline |
| `pr-description` | Writing/updating a PR title & description from commits — section catalog + style guide (loaded by `/update-pr`) |
| `curation` | Curating the project's conventions & advisory rules after a feature — harvest method + artifact templates |

---

## Hooks (enforcing quality gates)

Hooks make the rules non-optional. They run on **your machine** and degrade gracefully if a tool isn't installed.

| Hook event | Script | Effect |
|---|---|---|
| `SessionStart` | `session-start.sh` | Injects a reminder of the workflow + rules |
| `PreToolUse` (Edit/Write) | `guard-edits.sh` | **Blocks** focused tests (`.only`), `debugger;`/`Debugger.Break()`/`breakpoint()`/`pdb.set_trace()`, and blanket `eslint-disable` / `#pragma warning disable` / `# noqa` / `# type: ignore` |
| `PostToolUse` (Edit/Write) | `post-edit-quality.sh` | Runs ESLint `--fix` on changed JS/TS, `dotnet format` on changed C#/XAML, or `ruff` (fix + format) / `black` on changed Python; surfaces remaining errors |
| `PreToolUse` (Bash `git commit`) | `pre-commit-gate.sh` | **Blocks the commit** unless gates pass: JS = lint + typecheck + tests; .NET = `dotnet format --verify-no-changes` + `build -warnaserror` + `test`; Python = `ruff` + `mypy` + `pytest`; and no focus markers/debuggers staged |

The gate is **polyglot** — it runs whichever toolchains the repo actually has (npm scripts, a `.sln`/`.csproj`, and/or a `pyproject.toml`/`requirements.txt`), and silently skips the rest. Emergency escape: `git commit --no-verify` bypasses it (use sparingly). The hooks never run network installs — they only use tooling already present.

---

## Rules

Short, enforceable policies in `plugins/agentic-sdd/rules/` (mirrored to `.claude/rules/` on install). They are referenced by this file and by the agents:

- `00-workflow.md` — SDD + TDD is mandatory; spec is the contract.
- `10-testing.md` — TDD discipline, behavior-not-internals, the pyramid, coverage.
- `20-clean-code.md` — naming, SOLID, hexagonal boundaries, no smells.
- `25-structure.md` — organize by layer/feature (not flat), follow ecosystem conventions, apply design patterns.
- `30-security.md` — input validation, parameterized queries, authz, secrets.
- `40-git.md` — gated commits, Conventional Commits, focused commits.

---

## Repository layout

```
agentic-workflow/
├── CLAUDE.md                      ← you are here (source of truth)
├── README.md                      ← install + quick start
├── .claude-plugin/
│   └── marketplace.json           ← marketplace manifest (for /plugin install)
├── plugins/
│   └── agentic-sdd/
│       ├── .claude-plugin/plugin.json
│       ├── agents/                ← 20 agents (lifecycle + stack experts)
│       ├── commands/              ← 14 slash commands
│       ├── skills/                ← 8 skills (+ references)
│       ├── hooks/                 ← hooks.json + scripts/
│       ├── rules/                 ← 6 rule files
│       └── settings.template.json ← settings used by the copy installer
├── templates/
│   └── github-ci.yml              ← build+test CI for TARGET repos (installed via --with-ci)
├── .github/workflows/ci.yml       ← validates THIS plugin (not part of the plugin)
└── scripts/
    └── install.sh                 ← copy the workflow into a repo's .claude/ (--with-ci adds CI)
```

> **A note on CI.** GitHub Actions is repo-level config, **not** a plugin component — it isn't bundled when you `/plugin install`, and the copy installer only adds it when you pass `--with-ci`. So there are two distinct workflows: `.github/workflows/ci.yml` here *validates the plugin itself*, while `templates/github-ci.yml` is the *build-and-test* pipeline meant for the repos you install the workflow into.

---

## Installing into your other repos

Two supported ways (pick either; see `README.md` for full detail):

**A. As a plugin (recommended — updatable):**
```
/plugin marketplace add walmanarias/agentic-workflow
/plugin install agentic-sdd@agentic-workflow
```

**B. As a copied `.claude/` folder (self-contained, no marketplace):**
```
bash scripts/install.sh /path/to/your/repo
```
This copies `agents/`, `commands/`, `skills/`, `hooks/`, `rules/` into `<repo>/.claude/` and writes a merged `.claude/settings.json` wired to the hooks. Re-run any time to update.

After either method, open the target repo with Claude and run `/feature ...` to start.

---

## Conventions this workflow assumes

- **JS/TS repos:** ESLint + a `typecheck` (or `tsc --noEmit`) and a `test` script in `package.json` enable the full gate. Tests co-located as `*.test.ts` / `*.spec.ts` or under `__tests__/`.
- **.NET repos:** a `.sln` or `.csproj` enables the .NET gate (`dotnet format`, `dotnet build -warnaserror`, `dotnet test`). Nullable reference types on; xUnit + FluentAssertions; tests in a `*.Tests` project. Target `net8.0`/`net9.0` (arm64 on Apple Silicon).
- **Python repos:** a `pyproject.toml`/`setup.py`/`requirements.txt` enables the Python gate. Each tool runs only when the project adopts it — `ruff` (`[tool.ruff]` or `ruff.toml`) for lint + format, `mypy` (`[tool.mypy]` or `mypy.ini`) for types, `pytest` (a `tests/` dir, `conftest.py`, or `[tool.pytest.ini_options]`). Tests as `test_*.py` / `*_test.py` or under `tests/`.
- Missing toolchains are skipped, not failed — polyglot repos run every applicable gate.
- Specs in `specs/`, designs in `docs/design/`, decisions in `docs/adr/`.
- Each acceptance criterion is referenced by id (`AC-3`) in the test name for traceability.
