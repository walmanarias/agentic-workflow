# Changelog

All notable changes to the `agentic-sdd` plugin. Versions follow SemVer; `plugin.json` and
`marketplace.json` carry the same version (CI checks it).

## 2.0.0 — 2026-10-01

Closes the gaps from the workflow review: the loop now matches what it promises, and the hard
rules are enforced by hooks rather than only by prompts.

### Loop (breaking)
- New order: `/spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship`.
- `/plan` = optional architect (feature/large) + the new **`planner`** agent / **`task-planning`**
  skill: vertical slices of 1–3 ACs, each one RED → GREEN → REFACTOR → one gated commit.
- Feature folder `specs/<feature>/{spec,plan,status,review,qa}.md`; `status.md` makes `/feature`
  resumable. Legacy `specs/<feature>.spec.md` still read.
- Versioned spec amendments with re-approval before tests change.
- New `/create-pr`, `/triage`, `/fix`. `/curate` runs after triage. `/ship` verifies the DoD and
  CI, asks for explicit confirmation, merges, and watches post-merge workflows.
- `/review` defaults to `merge-base..HEAD` and writes `review.md`.
- QA / review / triage rounds capped by `AGENTIC_SDD_MAX_ROUNDS` (default 3).

### Enforcement
- `role-guard.sh`: per-agent write scopes via the hook input's `agent_type`.
- `bash-guard.sh`: no `--no-verify` / `-n` commits and no force pushes from agents.
- Edit guard and commit gate block skipped/disabled tests (`sdd-allow-skip: <reason>` exempts);
  the gate blocks deleted tests and net-removed assertions without a `Test-Change:` trailer, and
  scans for secrets (plus gitleaks when installed).
- `tools/ac_trace.py` and `tools/coverage_check.py` back `/ship`'s traceability and coverage items.

### Hardening (from an adversarial review of this release)
- The gate checks what will actually be committed: `git add … && git commit`, `-a`, pathspecs and
  `-i/-o` are gated against the working tree vs HEAD (+ untracked files), not the stale index.
- Robust command parsing: paths with spaces / non-ASCII / `~` / `$VAR`, `bash -c "…"`,
  `-S`/`-u` attached values, abbreviated `--no-verif`, and an unparseable command falls back to a
  regex instead of disabling the guards. The hook input's `cwd` is honored.
- Focus/debug markers are checked per language (no more blocks on Django `.only()`, SCSS
  `breakpoint()`, or Markdown); secret regex covers `sk-ant-…` / `sk-proj-…` keys, avoids
  `task-<hex>` false positives, and supports `sdd-allow-secret: <reason>`.
- Non-ASCII filenames (core.quotePath), concluding a merge, bash 3.2 empty arrays (macOS),
  `.vue`/`.svelte`-only commits, and a commit message containing `-name` no longer misbehave.
- Test/production path classification fixed both ways (MSW `mocks/`, `setupTests`, `test-utils`,
  cypress/playwright support, `*.UnitTests` projects ↔ `AbTest.cs`, `openapi.spec.yaml`,
  `src/e2e/`, Django fixtures); NotebookEdit is guarded too.
- RED tolerance also ignores the type-aware `@typescript-eslint/no-unsafe-*` cascade in a test whose
  import doesn't exist yet; ESLint is only invoked where it is configured.
- `ac_trace.py` ignores retired ACs and template guidance, reads the legacy layout, exits 2 on a
  missing spec; `coverage_check.py` merges overlapping Cobertura reports by line.
- `/fix` uses `specs/fix-<slug>/`; workflow artifacts are committed with the work; commands that
  delegate to agents allow the Agent tool; `install.sh` deep-merges `settings.json` (it used to
  replace the project's permission and hook arrays).
- CI template: npm audit only with a package-lock (pnpm audit for pnpm), gitleaks runs as the
  runner user.

### Speed & practicality
- `AGENTIC_SDD_GATE=affected` (default): only the touched stacks; JS lint + related tests per
  package (monorepo-aware). `full` restores 1.x behavior.
- Post-edit: RED-tolerant ESLint for new tests; `dotnet format whitespace --folder` per edit.

### Consistency
- One stack registry (`tools/stacks.json`) + detection at session start; agents no longer
  enumerate stacks.
- One loop line, checked across every file by `scripts/check-consistency.sh`.
- Hook messages English by default (`AGENTIC_SDD_LANG=es` for Spanish).
- Polyglot fixes: pytest patterns, runners in `/tdd`, clean-code, architect.

### Security
- Settings template: narrowed allow-list (no blanket `npx`, `gh api`, `gh pr`), `ask` for push and
  merge, denies for no-verify / force-push variants / destructive `gh` calls.
- CI template: dependency audit (npm / dotnet / pip-audit) and a gitleaks job.

### Quality of the plugin itself
- `tests/run.sh`: behavioral tests for every hook, tool and the installer.
- `evals/`: `claude plugin eval` cases. CI: strict shellcheck, PyYAML frontmatter parsing,
  consistency check.
- Models: opus for spec-writer, architect, planner, code-reviewer; commands no longer force the
  session model (except git/gh-heavy ones).
- Installer preserves curated `9x-*` rules on re-install and rewrites `${CLAUDE_PLUGIN_ROOT}`.

## 1.5.0
- Angular expert skill; StyleCop Analyzers code style for C#.

## 1.x
- Earlier releases: lifecycle agents, stack experts (as skills since #9), visual QA, curate step,
  CI/CD agent, Python stacks, Spanish support. See git history.
