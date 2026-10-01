# CLAUDE.md — Agentic Workflow Source of Truth

This repository is a **template** that brings a Spec-Driven Development (SDD) + Test-Driven Development (TDD) agentic workflow to any project. It ships as a Claude Code **plugin** (`agentic-sdd`) and as a copyable `.claude/` folder. This file is the operational contract the agents follow; install instructions, repository layout, and CI notes live in `README.md`.

> **Stack:** the supported stacks live in one registry — [`plugins/agentic-sdd/tools/stacks.json`](plugins/agentic-sdd/tools/stacks.json) — one entry per stack-expert skill: React, React Native, Angular, Node (Express/Fastify), NestJS, Next.js, Remix / React Router 7, Django/DRF, FastAPI, Flask, C#/ASP.NET Core (StyleCop Analyzers), Avalonia, .NET MAUI, PostgreSQL/MongoDB. At session start the hook detects the repo's stack from it and prints `Stack → load these skills: …`. Cross-platform incl. macOS on Apple Silicon — .NET work targets **.NET 8/9** (arm64), never the Windows-only .NET Framework.

> **Language:** English is the default — respond in **Spanish only when the user writes in Spanish or explicitly asks for it**. Generated artifacts (specs, test names, comments, commit/PR descriptions) follow the working language, but Conventional Commits prefixes, the `AC-n` / `T-n` / `CONV-<area>-n` ids, and code/technical names always stay in English. Hook messages are English unless `AGENTIC_SDD_LANG=es`.

---

## The core idea

The **spec is the source of truth**. Tests encode the spec. Code satisfies the tests. Work flows in one direction and every line traces back to a numbered acceptance criterion (`AC-n`) — in **small slices**, each one a full RED → GREEN → REFACTOR cycle that ends in one green commit.

/spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship

```
spec      plan          slices (RED→GREEN→REFACTOR→commit)   E2E   QA   review  PR    triage  curate  ship
contract  design+slices T-1, T-2, … one gated commit each    (E2E) UI   branch  open  threads conv.   gate+merge
```

**Hard rules, everywhere (enforced by hooks, not just prompts):**
1. No production code before a failing test for that behavior — `tdd-test-writer` can only write tests, `implementer` can't touch them (role guard).
2. Never weaken, skip, or delete a test to make code pass — skips are blocked at edit time; deleted tests and net-removed assertions are blocked at commit unless a `Test-Change: <reason>` trailer explains them.
3. Agents never bypass the gate (`--no-verify`) or force-push (bash guard). Merges happen only after the human says yes.

Run the whole loop with `/feature <description>` — it sizes the request, stops at the approval gates (🚦 spec, design, merge), pauses after opening the PR, and **resumes** from `specs/<feature>/status.md` when re-run. Bugs take the short track: `/fix <description>`.

## Sizing

| Size | Path |
|---|---|
| trivial (no behavior change) | commit through the gate |
| bug | `/fix` — regression test → fix → review → PR → ship |
| small (≤ 3 ACs, one module) | loop without the architect |
| feature / large | loop with the architect in `/plan` |

## Artifacts (the interface between phases)

```
specs/<feature>/spec.md     contract — Status, Version, Size, ACs, DoD, Changelog
specs/<feature>/plan.md     slices T-1…T-n (1–3 ACs each, vertical, walking skeleton first)
specs/<feature>/status.md   phase · slice → commit · loop rounds · blockers · PR  (resume point)
specs/<feature>/review.md   code-reviewer report (latest round)
specs/<feature>/qa.md       visual QA report
specs/fixes/<slug>.md       /fix notes (repro, root cause, AC-1)
docs/design/<feature>.md, docs/adr/NNNN-*.md        architect
docs/conventions.md, docs/curation/<date>-<f>.md    curator
```

## Context & token discipline

Artifacts on disk are the interface between phases. Every agent writes its full output to its artifact and returns only a compact summary — file paths, `AC-n`/`T-n` ids, verdict/counts. Pass paths between phases; never re-echo a subagent's output into the orchestrating thread. Each agent starts from the artifacts named in its task and widens its search only when they don't answer the question. Screenshots stay inside `qa-visual`'s context — only text findings + paths come back.

## Loop limits

QA, review, and triage fix-rounds are capped at `AGENTIC_SDD_MAX_ROUNDS` (default **3**), counted in `status.md`. At the cap the orchestrator stops and hands the remaining findings to the human with a recommendation.

## Commands

| Command | What it does | Delegates to |
|---|---|---|
| `/feature <desc\|name>` | Full loop end to end; resumes an in-flight feature | all lifecycle agents |
| `/spec <desc>` | Testable spec with numbered `AC-n`, size, DoD | `spec-writer` |
| `/plan <feature>` | Design brief + ADRs (feature/large) and the slice plan + status file | `architect`, `planner` |
| `/tdd <T-n>` | Failing tests (RED) for one slice | `tdd-test-writer` |
| `/implement <T-n>` | Minimal clean code to pass (GREEN), then refactor; commit | `implementer` (+ stack skills) |
| `/e2e <flow>` | E2E tests for every `(E2E)` AC | `e2e-tester` |
| `/qa [flow]` | Visual QA — screenshots + inspection | `qa-visual` |
| `/review [scope]` | Review `merge-base..HEAD` → `review.md` | `code-reviewer` |
| `/create-pr [feature]` | Push + `gh pr create` with a generated description | (gh CLI) + `pr-description` skill |
| `/triage [pr]` | Copilot, then human review threads; push fixes; refresh PR | runs `/triage-copilot` + `/triage-reviews` |
| `/triage-copilot [pr]` | Triage Copilot comments; fix (TDD) or reply + resolve | (gh CLI) |
| `/triage-reviews [pr]` | Triage human comments; answer, implement, or discuss | (gh CLI) |
| `/curate [feature]` | Retrospective incl. review feedback; conventions & advisory rules | `curator` |
| `/ship [feature\|pr]` | DoD gate + CI → human confirms → merge → watch deploy | (verification + gh CLI) |
| `/fix <bug>` | Bug track: regression test → fix → review → PR → ship | `tdd-test-writer`, `implementer`, … |
| `/refactor <target>` | Behavior-preserving cleanup under green tests | `refactorer` |
| `/cicd <target>` | GitHub Actions CI/CD pipeline (build→test→deploy) | `cicd-engineer` |
| `/update-pr [context]` | Refresh PR title & description from branch commits | (gh CLI) + `pr-description` skill |

## Agents (lifecycle)

| Agent | Model | Role | Writes to (role guard) |
|---|---|---|---|
| `spec-writer` | opus | Testable spec with `AC-n`; versioned amendments | `specs/` |
| `architect` | opus | System design, boundaries, contracts, ADRs | `docs/design/`, `docs/adr/` |
| `planner` | opus | Slices ACs into TDD slices; status file | `specs/` |
| `tdd-test-writer` | sonnet | RED — failing tests per slice | test files only |
| `implementer` | sonnet | GREEN → REFACTOR; never edits tests | anything but tests |
| `e2e-tester` | sonnet | Hermetic, parallel-safe E2E per stack | tests, fixtures, test config |
| `qa-visual` | sonnet | Screenshots user-facing flows; visual bugs | `.qa-visual/`, `specs/*/qa.md` |
| `code-reviewer` | opus | Reviews the branch — Blocking / Should-fix / Nit | `specs/*/review.md` |
| `curator` | sonnet | Retrospective; conventions & advisory rules | `docs/`, `.claude/rules/9x-*` |
| `refactorer` | sonnet | Behavior-preserving cleanup under green tests | source files |
| `cicd-engineer` | sonnet | GitHub Actions pipelines; staging→approval→prod | `.github/`, `docs/` |

**Stack expertise lives in skills, not agents.** `implementer`, `tdd-test-writer`, and `e2e-tester` load the stack skills named in the session's `Stack →` line (from `tools/stacks.json`) into their own context instead of spawning a second agent. Asking to "use the nestjs-expert" loads that skill. Meta-framework skills layer on top of `react-expert` (Next.js, Remix: the meta-framework skill owns routes/data, `react-expert` owns components). `avalonia-expert` and `maui-expert` follow `dotnet-expert`'s StyleCop Analyzers code-style rules.

## Skills

Workflow playbooks in `plugins/agentic-sdd/skills/`: `spec-driven-development` (the loop + spec template + feature folder), `task-planning` (slices + plan/status templates), `tdd-workflow` (Red/Green/Refactor; Jest/Vitest, xUnit, pytest patterns), `e2e-testing`, `visual-qa`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description`, `xamarin-maui-migration`, `curation` — plus the 14 stack-expert skills in the registry. Deep reference material sits in each skill's `references/` and is read only on demand.

## Tools

`plugins/agentic-sdd/tools/` (copied to `.claude/tools/` by the installer; referenced as `${CLAUDE_PLUGIN_ROOT}/tools/…`):

| Tool | Used by | Does |
|---|---|---|
| `stacks.json` + `detect_stack.py` | session start, agents | the stack registry and repo detection |
| `ac_trace.py` | `/feature` per slice, `/review`, `/ship` | every `AC-n` → a test; `(E2E)` ACs → an E2E test |
| `coverage_check.py` | `/ship` | changed-files line coverage vs threshold (istanbul json-summary, cobertura) |

## Hooks (enforcing quality gates)

| Hook event | Script | Effect |
|---|---|---|
| `SessionStart` | `session-start.sh` | Loop reminder, detected stack, tools path, in-flight features to resume |
| `PreToolUse` (Edit/Write) | `guard-edits.sh` | **Blocks** focused/skipped tests, debugger statements, blanket lint/type suppressions |
| `PreToolUse` (Edit/Write) | `role-guard.sh` | **Blocks** an agent writing outside its role (uses the hook input's `agent_type`) |
| `PreToolUse` (Bash) | `bash-guard.sh` | **Blocks** `git commit --no-verify`/`-n` and force pushes from agents |
| `PreToolUse` (Bash `git commit`) | `pre-commit-gate.sh` | **Blocks the commit** on weakened tests, secrets, focus/debug markers, or failing lint/types/tests (JS per package; .NET format+build `-warnaserror`+test; Python ruff+mypy+pytest) |
| `PostToolUse` (Edit/Write) | `post-edit-quality.sh` | Formats the changed file (ESLint / `dotnet format whitespace` / ruff/black); RED-tolerant for new tests |

The gate is **polyglot** and runs only the toolchains the repo has. `AGENTIC_SDD_GATE=affected` (default) gates only the stacks a commit touches, with JS lint/tests scoped to the staged files; `full` runs everything on every commit. CI and `/ship` always run the full suites. Hooks never run network installs. `sdd-allow-skip: <reason>` on a line marks a deliberate skip; `Test-Change: <reason>` in the commit message marks a deliberate test removal.

## Settings (env)

| Variable | Default | Meaning |
|---|---|---|
| `AGENTIC_SDD_LANG` | `en` | Hook message language (`en` / `es`) |
| `AGENTIC_SDD_GATE` | `affected` | Commit gate scope (`affected` / `full`) |
| `AGENTIC_SDD_COVERAGE` | `80` | Changed-files coverage threshold for `/ship` |
| `AGENTIC_SDD_MAX_ROUNDS` | `3` | Max QA / review / triage fix-rounds before escalating |
| `AGENTIC_SDD_ROLE_GUARD` | `on` | `off` disables the role guard (humans only) |

## Rules

Short, enforceable policies in `plugins/agentic-sdd/rules/` (mirrored to `.claude/rules/` on install; the project's curated `9x-*` rules survive re-installs):

- `00-workflow.md` — the loop, sizing, slices, bounded loops, state on disk.
- `10-testing.md` — TDD discipline, traceability, behavior-not-internals, the pyramid, coverage.
- `20-clean-code.md` — naming, SOLID, hexagonal boundaries, no smells.
- `25-structure.md` — organize by layer/feature; ecosystem conventions; design patterns.
- `30-security.md` — input validation, parameterized queries, authz, secrets.
- `40-git.md` — branches, gated commits, Conventional Commits, `Test-Change:` trailer, PR + merge flow.

## Conventions this workflow assumes

- **JS/TS repos:** ESLint + a `typecheck` (or `tsc --noEmit`) and a `test` script in `package.json` enable the full gate; with Vitest or Jest as a dependency the gate runs only tests related to the staged files. Tests co-located as `*.test.ts` / `*.spec.ts` or under `__tests__/`. Coverage: add the `json-summary` reporter.
- **.NET repos:** a `.sln` or `.csproj` enables the .NET gate. Nullable reference types on; xUnit + FluentAssertions; tests in a `*.Tests` project. Target `net8.0`/`net9.0` (arm64 on Apple Silicon). Coverage: `--collect "XPlat Code Coverage"`.
- **Python repos:** a `pyproject.toml`/`setup.py`/`requirements.txt` enables the Python gate; each tool runs only when the project adopts it (`ruff`, `mypy`, `pytest`). Tests as `test_*.py` / `*_test.py` or under `tests/`. Coverage: `pytest --cov --cov-report=xml`.
- Missing toolchains are skipped, not failed — polyglot repos run every applicable gate.
- Each acceptance criterion is referenced by id (`AC-3`) in the test name for traceability.

## Developing this repo

- `bash tests/run.sh` — behavioral tests for every hook and tool (fixtures piped into the scripts).
- `bash scripts/check-consistency.sh` — the loop line, counts, versions, stack registry and frontmatter agree everywhere.
- `claude plugin eval plugins/agentic-sdd` — eval cases in `plugins/agentic-sdd/evals/`.
- CI runs all of the above plus strict shellcheck and actionlint.
