# Agentic Workflow — Spec-Driven Development + TDD

A reusable Claude Code workflow that enforces **Spec-Driven Development (SDD)** and **Test-Driven Development (TDD)** across a full-stack TypeScript/JavaScript, **C#/.NET**, and **Python** stack: **React, React Native, Angular, Node.js (Express/Fastify), NestJS, Next.js, Remix (incl. React Router 7 framework mode), C# / ASP.NET Core Web APIs (StyleCop Analyzers code style), Avalonia (XAML) desktop, .NET MAUI (cross-platform mobile/desktop), Python (Django/DRF, FastAPI, Flask), PostgreSQL, MongoDB**.

It ships as a Claude Code **plugin** (`agentic-sdd`) *and* as a copyable `.claude/` folder, so you can install it in any repo and start shipping clean, tested, maintainable code. Cross-platform, including **macOS (Tahoe) on Apple Silicon** — .NET work targets modern cross-platform **.NET 8/9** (arm64-native), not the Windows-only .NET Framework.

> **Read [`CLAUDE.md`](./CLAUDE.md) for the full source of truth** on how the agents, skills, commands, hooks, and rules work together.

> **Language:** **English by default.** Agents and commands match the conversation — they answer in **Spanish only when you write in Spanish or ask for it**, and generated artifacts (specs, tests, commit/PR descriptions) follow that same working language. The `AC-n` / `CONV-<area>-n` ids, Conventional Commits prefixes, and code / technical names always stay English. See [`CLAUDE.md`](./CLAUDE.md) for the details.

## What's inside

- **11 lifecycle agents** — `spec-writer`, `architect`, `planner`, `tdd-test-writer`, `implementer`, `e2e-tester`, `qa-visual`, `code-reviewer`, `curator`, `refactorer`, `cicd-engineer`.
- **18 commands** — `/feature`, `/spec`, `/plan`, `/tdd`, `/implement`, `/e2e`, `/qa`, `/review`, `/create-pr`, `/triage`, `/triage-copilot`, `/triage-reviews`, `/curate`, `/ship`, `/fix`, `/refactor`, `/cicd`, `/update-pr`.
- **25 skills** — 11 workflow playbooks (`spec-driven-development`, `task-planning`, `tdd-workflow`, `e2e-testing`, `visual-qa`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description`, `xamarin-maui-migration`, `curation`) + 14 **stack-expert skills** registered in one place, [`tools/stacks.json`](plugins/agentic-sdd/tools/stacks.json). Stack expertise ships as skills rather than agents so `implementer`, `tdd-test-writer`, and `e2e-tester` load it into their own context — the session-start hook detects the repo's stack and names the skills to load.
- **Enforcing hooks** — the hard rules are checked, not just asked for: skipped/focused tests and debugger statements are blocked at edit time; a role guard keeps the test writer out of production code and the implementer out of tests; agents can't `--no-verify` or force-push; the commit gate blocks weakened tests (deleted files, net-removed assertions), secrets, and failing lint/types/tests — scoped to the stacks a commit touches (`AGENTIC_SDD_GATE=affected`).
- **Tools** — `ac_trace.py` (every `AC-n` → a test), `coverage_check.py` (changed-files coverage, polyglot), `detect_stack.py`.
- **6 rule files** — workflow, testing, clean code, structure, security, git hygiene.
- **CI templates** — a build-and-test + security (dependency audit, secret scan) GitHub Actions workflow you can drop into target repos with `--with-ci`. This repo's own CI tests the plugin.

## Repository layout

```
agentic-workflow/
├── CLAUDE.md                      ← the operational contract the agents follow
├── README.md                      ← install + quick start (this file)
├── CHANGELOG.md
├── .claude-plugin/
│   └── marketplace.json           ← marketplace manifest (for /plugin install)
├── plugins/
│   └── agentic-sdd/
│       ├── .claude-plugin/plugin.json
│       ├── agents/                ← 11 lifecycle agents
│       ├── commands/              ← 18 slash commands
│       ├── skills/                ← 25 skills (11 playbooks + 14 stack experts)
│       ├── hooks/                 ← hooks.json + scripts/
│       ├── tools/                 ← stacks.json, detect_stack.py, ac_trace.py, coverage_check.py
│       ├── rules/                 ← 6 rule files
│       ├── evals/                 ← `claude plugin eval` cases
│       └── settings.template.json ← settings used by the copy installer
├── templates/
│   └── github-ci.yml              ← build+test+security CI for TARGET repos (via --with-ci)
├── tests/run.sh                   ← behavioral tests for the hooks, tools and installer
├── .github/workflows/ci.yml       ← tests + validates THIS plugin (not part of the plugin)
└── scripts/
    ├── install.sh                 ← copy the workflow into a repo's .claude/
    └── check-consistency.sh       ← loop line / counts / versions / registry agree everywhere
```

## Quick start (this repo)

Open this folder with Claude and run:

```
/feature add a health-check endpoint that returns build version and DB status
```

It runs the whole loop — spec → slice plan → one RED/GREEN/REFACTOR commit per slice → E2E → QA → review → PR → triage → curate → ship — stopping at the approval gates (spec, design, merge). It pauses once the PR is open; run `/feature <name>` again after reviewers comment and it resumes from `specs/<name>/status.md`. For bugs use `/fix <description>`.

## Install into another repo

Two ways to install. **Option A (plugin)** is recommended — it updates cleanly from this repo and copies nothing into your target's git history. **Option B (copy)** is fully self-contained — use it when you can't depend on a marketplace or want the workflow checked into the repo. After either, open the target repo with Claude and run `/feature …` to start.

### Option A — install as a plugin (recommended, updatable)

**One-time setup:** push this template to a GitHub repo you control. It already has `.claude-plugin/marketplace.json` at the root, which is what makes the repo a plugin marketplace.

Then, in the **target** project:

```
/plugin marketplace add walmanarias/agentic-workflow
/plugin install agentic-sdd@agentic-workflow
```

- Replace `walmanarias/agentic-workflow` with your repo path. A full Git URL or a local path also work — handy during local development before you push: `/plugin marketplace add ./path/to/agentic-workflow`.
- The plugin installs at **user scope** by default (available in all your projects). Add `--scope project` to scope it to this repo only, or `--scope local` for a personal, uncommitted install: `/plugin install agentic-sdd@agentic-workflow --scope project`.
- Run `/plugin` anytime for the interactive menu (Discover / Installed / Marketplaces / Errors).

**Make it automatic for a team.** Commit these keys to the target repo's `.claude/settings.json`, and anyone who opens the repo with Claude gets the marketplace and plugin without manual steps:

```json
{
  "extraKnownMarketplaces": {
    "agentic-workflow": {
      "source": { "source": "github", "repo": "walmanarias/agentic-workflow" }
    }
  },
  "enabledPlugins": {
    "agentic-sdd@agentic-workflow": true
  }
}
```

**Updating an existing install** — pull the latest after this template changes:

```
/plugin marketplace update agentic-workflow     # refresh the catalog from your repo
/plugin install agentic-sdd@agentic-workflow    # reinstall to pull the newest version
```

Or enable auto-update from `/plugin` → **Marketplaces**. To remove: `/plugin uninstall agentic-sdd@agentic-workflow` (and `/plugin marketplace remove agentic-workflow` to drop the source — note that also uninstalls its plugins).

### Option B — copy the `.claude/` folder (self-contained)

From your local checkout of this template:

```bash
bash scripts/install.sh /path/to/your/repo
```

This copies `agents/`, `commands/`, `skills/`, `hooks/`, `tools/`, and `rules/` into `<repo>/.claude/` (rewriting `${CLAUDE_PLUGIN_ROOT}` references to `.claude`), writes `.claude/settings.json` (merged with any existing one when `jq` is available — template values win on conflicts), and adds a starter `CLAUDE.md` if the repo doesn't already have one. The `.claude/` folder is meant to be **committed** to the target repo.

Flags:

| Flag | Effect |
| --- | --- |
| `--force` | Overwrite `.claude/settings.json` outright instead of merging it |
| `--with-ci` | Also drop the Node/.NET/Python build-test-security workflow into `.github/workflows/ci.yml` |

If `.github/workflows/ci.yml` already exists, `--with-ci` writes `agentic-sdd-ci.yml` alongside it instead (unless you also pass `--force`). Likewise, without `jq` an existing `settings.json` is preserved and the template is written next to it as `settings.agentic-sdd.json` for you to merge by hand.

**Updating an existing install** — there's no marketplace link, so you re-run the installer against your local checkout:

```bash
cd /path/to/agentic-workflow && git pull      # 1. update the template itself
bash scripts/install.sh /path/to/your/repo    # 2. re-apply it (add --with-ci to refresh CI)
```

Re-running **fully replaces** `agents/`, `commands/`, `skills/`, `tools/`, and the template's `rules/` (so renamed or removed files are cleaned up, not left stale) while **keeping your curated `9x-*` rules**, and re-applies the hooks. Your `settings.json` is re-merged — pass `--force` to overwrite it. ⚠️ The `jq` merge replaces overlapping **arrays** wholesale, so re-check `permissions` if you customized them. Then commit the refreshed `.claude/`.

## CI: two separate things

- **This template repo's CI** (`.github/workflows/ci.yml`) **tests the plugin** — behavioral hook/tool tests (`tests/run.sh`), the consistency check, manifests and YAML frontmatter parse, strict shellcheck, actionlint, and the copy installer end-to-end. It is *not* part of the plugin and isn't installed anywhere.
- **The build-and-test CI for your projects** lives in `templates/github-ci.yml` and reaches a target repo only when you run the installer with `--with-ci` (or copy it yourself). Plugin installs (marketplace) never carry CI — GitHub Actions is repo-level config, not a plugin component.
- **A tailored full pipeline** is what the `/cicd` command (the `cicd-engineer` agent) generates per project — build + test + deploy with a staging → manual-approval → production flow. It can read and extend the static `ci.yml` rather than replace it.

## Requirements in the target repo (for the full quality gate)

The hooks degrade gracefully — missing tooling is skipped, never failed. For the complete gate, the target repo should have:

- **Everywhere:** `git`, `python3` (hook parsing + the `tools/` scripts), and an authenticated **GitHub CLI** (`gh auth login`) for `/create-pr`, `/triage`, and `/ship`.
- **JS/TS:** `package.json` scripts `lint`, `typecheck` (or a `tsconfig.json`), and `test`; ESLint and TypeScript installed locally. For `/ship`'s coverage check add the `json-summary` coverage reporter (Jest `coverageReporters`, Vitest `coverage.reporter`).
- **.NET:** a `.sln`/`.csproj`, the .NET 8/9 SDK (`dotnet`), and a `*.Tests` xUnit project. For Testcontainers-backed integration tests, a container runtime (Docker Desktop or Colima/Podman) running on arm64. For Avalonia Appium E2E on macOS, grant the test runner Accessibility permission (System Settings → Privacy & Security → Accessibility).
- **Python:** a `pyproject.toml`/`setup.py`/`requirements.txt`, plus the tools the project adopts — `ruff` (lint + format), `mypy` (types), and `pytest` (with a `tests/` dir or `conftest.py`). Django adds `pytest-django` + `DJANGO_SETTINGS_MODULE`; integration tests reuse the same arm64 container runtime via Testcontainers.

## The workflow in one line

/spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship

No production code before a failing test. Never weaken a test to pass. One slice = one gated, green commit. Nothing merges without your explicit yes.

## Upgrading from 1.x

2.0 changes the loop and the artifact layout:

- **Order:** `/spec` now comes before `/plan`, and `/plan` produces a **slice plan** (plus the architect's design only for feature/large changes). `/curate` moved after `/triage`. New: `/create-pr`, `/triage`, `/fix`; `/ship` now merges after your confirmation.
- **Layout:** specs live in `specs/<feature>/spec.md` next to `plan.md`, `status.md`, `review.md`, `qa.md`. Legacy `specs/<feature>.spec.md` files are still read.
- **Gate:** the commit gate is scoped to the touched stacks by default — set `AGENTIC_SDD_GATE=full` for the 1.x behavior. Hook messages are English by default — set `AGENTIC_SDD_LANG=es` for Spanish.
- **Test changes:** removing tests or assertions now needs a `Test-Change: <reason>` commit trailer.

## License

MIT — see [`LICENSE`](./LICENSE).
