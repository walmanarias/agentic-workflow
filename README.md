# Agentic Workflow — Spec-Driven Development + TDD

A reusable Claude Code workflow that enforces **Spec-Driven Development (SDD)** and **Test-Driven Development (TDD)** across a full-stack TypeScript/JavaScript, **C#/.NET**, and **Python** stack: **React, React Native, Node.js (Express/Fastify), NestJS, Next.js, C# / ASP.NET Core Web APIs, Avalonia (XAML) desktop, Python (Django/DRF, FastAPI, Flask), PostgreSQL, MongoDB**.

It ships as a Claude Code **plugin** (`agentic-sdd`) *and* as a copyable `.claude/` folder, so you can install it in any repo and start shipping clean, tested, maintainable code. Cross-platform, including **macOS (Tahoe) on Apple Silicon** — .NET work targets modern cross-platform **.NET 8/9** (arm64-native), not the Windows-only .NET Framework.

> **Read [`CLAUDE.md`](./CLAUDE.md) for the full source of truth** on how the agents, skills, commands, hooks, and rules work together.

## What's inside

- **19 agents** — 8 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `code-reviewer`, `refactorer`, `cicd-engineer`) + 11 stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML, Django/DRF, FastAPI, Flask, PostgreSQL/MongoDB).
- **13 commands** — `/feature`, `/plan`, `/spec`, `/tdd`, `/implement`, `/e2e`, `/review`, `/refactor`, `/cicd`, `/update-pr`, `/triage-copilot`, `/triage-reviews`, `/ship`.
- **7 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description`.
- **Enforcing, polyglot hooks** — block focused tests/`debugger`/`Debugger.Break()`/`breakpoint()`, format/lint changed files (ESLint, `dotnet format`, or `ruff`), and gate `git commit` on the toolchains the repo has (JS: lint + types + tests; .NET: format + build `-warnaserror` + test; Python: ruff + mypy + pytest).
- **5 rule files** — workflow, testing, clean code, security, git hygiene.
- **CI templates** — a build-and-test GitHub Actions workflow (Node + .NET on macOS Apple Silicon) you can drop into target repos with `--with-ci`. This repo's own CI just validates the plugin.

## Quick start (this repo)

Open this folder with Claude and run:

```
/feature add a health-check endpoint that returns build version and DB status
```

It runs the whole loop — spec → failing tests → implementation → E2E → review → ship — stopping at the approval gates.

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

This copies `agents/`, `commands/`, `skills/`, `hooks/`, and `rules/` into `<repo>/.claude/`, writes `.claude/settings.json` (merged with any existing one when `jq` is available — template values win on conflicts), and adds a starter `CLAUDE.md` if the repo doesn't already have one. The `.claude/` folder is meant to be **committed** to the target repo.

Flags:

| Flag | Effect |
| --- | --- |
| `--force` | Overwrite `.claude/settings.json` outright instead of merging it |
| `--with-ci` | Also drop the Node/.NET build-and-test workflow into `.github/workflows/ci.yml` |

If `.github/workflows/ci.yml` already exists, `--with-ci` writes `agentic-sdd-ci.yml` alongside it instead (unless you also pass `--force`). Likewise, without `jq` an existing `settings.json` is preserved and the template is written next to it as `settings.agentic-sdd.json` for you to merge by hand.

**Updating an existing install** — there's no marketplace link, so you re-run the installer against your local checkout:

```bash
cd /path/to/agentic-workflow && git pull      # 1. update the template itself
bash scripts/install.sh /path/to/your/repo    # 2. re-apply it (add --with-ci to refresh CI)
```

Re-running **fully replaces** `agents/`, `commands/`, `skills/`, and `rules/` (so renamed or removed files are cleaned up, not left stale) and re-applies the hooks. Your `settings.json` is re-merged — pass `--force` to overwrite it. ⚠️ The `jq` merge replaces overlapping **arrays** wholesale, so re-check `permissions` if you customized them. Then commit the refreshed `.claude/`.

## CI: two separate things

- **This template repo's CI** (`.github/workflows/ci.yml`) only **validates the plugin** — manifests parse, frontmatter is present, hook scripts and the installer are valid shell, and the copy installer runs end-to-end. It is *not* part of the plugin and isn't installed anywhere.
- **The build-and-test CI for your projects** lives in `templates/github-ci.yml` and reaches a target repo only when you run the installer with `--with-ci` (or copy it yourself). Plugin installs (marketplace) never carry CI — GitHub Actions is repo-level config, not a plugin component.
- **A tailored full pipeline** is what the `/cicd` command (the `cicd-engineer` agent) generates per project — build + test + deploy with a staging → manual-approval → production flow. It can read and extend the static `ci.yml` rather than replace it.

## Requirements in the target repo (for the full quality gate)

The hooks degrade gracefully — missing tooling is skipped, never failed. For the complete gate, the target repo should have:

- **JS/TS:** `package.json` scripts `lint`, `typecheck` (or a `tsconfig.json`), and `test`; ESLint and TypeScript installed locally.
- **.NET:** a `.sln`/`.csproj`, the .NET 8/9 SDK (`dotnet`), and a `*.Tests` xUnit project. For Testcontainers-backed integration tests, a container runtime (Docker Desktop or Colima/Podman) running on arm64. For Avalonia Appium E2E on macOS, grant the test runner Accessibility permission (System Settings → Privacy & Security → Accessibility).
- **Python:** a `pyproject.toml`/`setup.py`/`requirements.txt`, plus the tools the project adopts — `ruff` (lint + format), `mypy` (types), and `pytest` (with a `tests/` dir or `conftest.py`). Django adds `pytest-django` + `DJANGO_SETTINGS_MODULE`; integration tests reuse the same arm64 container runtime via Testcontainers.

## The workflow in one line

```
/plan → /spec → /tdd (RED) → /implement (GREEN + refactor) → /e2e → /review → /update-pr → /ship
```

No production code before a failing test. Never weaken a test to pass. Commits are gated on lint + types + tests.

## License

MIT — see [`LICENSE`](./LICENSE).
