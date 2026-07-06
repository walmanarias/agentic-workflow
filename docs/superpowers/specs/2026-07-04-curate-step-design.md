# Design: The `curate` step

**Date:** 2026-07-04
**Status:** Approved (design), pending implementation
**Repo:** `agentic-workflow` (the `agentic-sdd` plugin/template)

## Summary

Add a **`curate`** step to the Spec-Driven-Development + TDD workflow. The curator is a
lifecycle agent that runs **after `/review`, before `/ship`** and performs a retrospective on
the feature just built. It gives **feedback** on the work performed, **selects and organizes**
durable decisions into a living conventions document for the *target project*, and
**establishes advisory rules** — ensuring quality by capturing the project's own conventions
and general rules so future features inherit them.

The three decisions that shaped this design:

1. **Curation target = the target project.** The curator grows a living conventions/rules set
   *inside the repo being built* (not the workflow template). Future features in that repo
   inherit the conventions.
2. **Loop placement = `/review → /curate → /ship`.** A standard step in the loop, wired into
   `/feature`, also runnable standalone.
3. **Authority = write docs + advisory rules.** It writes a conventions doc and appends
   project-local rule files, fed to `/review` and `/ship` as conformance checks. It does **not**
   auto-generate commit-blocking hooks — a human opts in before anything hardens into a gate.

Packaging follows the repo's own model (chosen approach **A**, "full lifecycle citizen"): every
real step here is a `command → agent → skill` triad wired into the loop docs, so `curate`
becomes one too.

## Goals

- Give actionable feedback on both the **work** (the diff) and the **process** (how the loop ran).
- Turn recurring decisions into an organized, traceable, living conventions document.
- Promote the strongest, most general conventions into advisory project-local rules.
- Keep the workflow's coherence: `curate` looks and behaves like the other steps.

## Non-goals (YAGNI)

- **No auto-enforcement.** The curator never writes or edits hooks/gates and never blocks commits.
- **No production-code changes.** It writes only docs and rules.
- **No convention hoarding.** One-off decisions are discarded; only likely-to-recur decisions
  become conventions.
- **No curation of the template itself.** Learnings general enough for the template are noted in
  feedback for a human to carry over manually — the curator does not edit the `agentic-sdd`
  plugin.

## Scope of "conventions"

The brief says "steps, tools, **and methodologies**," so conventions cover more than code style.
Convention areas:

- **Naming**
- **Structure** (layer/feature organization)
- **Testing** (patterns, fixtures, naming)
- **Error handling**
- **API** (contracts, versioning)
- **Database** (schema, migrations, indexes)
- **Tooling** (the project's chosen tools and how they're used)
- **Process / Workflow** (the project's own steps and methodologies)

## Components

### New files (in the plugin: `plugins/agentic-sdd/`)

| File | Purpose |
|---|---|
| `agents/curator.md` | The specialist agent. Tools: Read, Write, Edit, Grep, Glob, Bash. Writes only under `docs/` and `.claude/rules/`. |
| `commands/curate.md` | `/curate [scope]` — entry point. Default scope: the feature/diff just reviewed. Delegates to `curator`, applies the `curation` skill. |
| `skills/curation/SKILL.md` | The playbook: the harvest methodology + the two artifact templates (conventions doc, project rule). |

*(If the templates grow long, they may move to `skills/curation/references/`.)*

### Runtime artifacts (created in the TARGET project; defined by the skill, not shipped)

| Artifact | Purpose |
|---|---|
| `docs/conventions.md` | Living conventions doc, organized by area. Each entry: stable id `CONV-<area>-n`, statement, *why*, good/bad example, provenance (`Since: <feature> (AC-n), <date>`). The curator **reconciles** — refines/supersedes stale entries rather than blindly appending. |
| `.claude/rules/9x-<topic>.md` | Advisory project-local rules, same format as the shipped `00–40` rules, numbered **90+** to sit clearly apart. Header marks them advisory and cites the `CONV` ids they enforce. |
| `docs/curation/<date>-<feature>.md` | Persisted retrospective/feedback log (kept, for traceability of feedback over time). |

Micro-choices confirmed at design approval: skill name **`curation`**; rule numbering **`9x`**;
keep the optional **`docs/curation/`** log.

## Curator behavior (the method, encoded in the skill)

**Inputs:** the spec (`specs/*`), the reviewed diff, the review findings, and the *existing*
`docs/conventions.md` + `.claude/rules/9x-*`.

1. **Reflect** — read the spec, diff, and review output → concise feedback on what the work did
   well, where the process had friction, and gaps (missing tests, unclear ACs, repeated review
   nits).
2. **Select** — identify durable decisions worth generalizing (naming, structure, error handling,
   test patterns, API/DB, tooling, process). Discard one-offs.
3. **Organize** — merge into `docs/conventions.md` under the right area heading; dedupe and
   supersede outdated entries; assign/keep stable `CONV-<area>-n` ids.
4. **Establish** — for conventions strong and general enough to enforce, write/update an advisory
   `.claude/rules/9x-<topic>.md` in the shipped-rule format, citing the `CONV` ids.
5. **Report** — output feedback + a summary of conventions added/changed + rules proposed +
   author action items; persist the retrospective to `docs/curation/`.

**Guardrails:**

- Advisory only — never edits hooks/gates; never blocks commits.
- Writes docs/rules, never production code; write paths limited to `docs/` and `.claude/rules/`.
- Every convention traces to observed practice or an explicit decision — no inventing conventions
  the code doesn't support.
- Reconcile, don't hoard — supersede stale conventions instead of duplicating.

## Artifact formats

### `docs/conventions.md`

```markdown
# Project Conventions
> Living document, curated by the `curator` after each feature. Advisory.

## Naming
### CONV-naming-1: <statement>
- Why: <rationale>
- Example: <good vs bad>
- Since: <feature> (AC-n), <date>

## Structure
## Testing
## Error handling
## API
## Database
## Tooling
## Process / Workflow
```

Stable `CONV-<area>-n` ids mirror the `AC-n` traceability idea so rules and reviews can reference
individual conventions.

### `.claude/rules/9x-<topic>.md`

Mirrors the existing rule files (`# Rule: <title>`, short enforceable policy, bullets). A header
line notes it is **advisory**, **curated**, and which `CONV` ids it enforces. Numbered 90+.

## Wiring into the existing workflow (edits to existing files)

| File | Edit |
|---|---|
| `CLAUDE.md` | Insert `→ curate` in the loop diagram between review and ship; add rows to the Commands, Lifecycle-agents (writes → `docs/conventions.md`, `.claude/rules/9x-*`), and Skills tables. |
| `rules/00-workflow.md` | Add `/curate` to the loop line. |
| `commands/feature.md` | Insert a **Curate** step after Review (before Describe/Verify). |
| `commands/review.md` + `agents/code-reviewer.md` | Add a check: flag violations of `docs/conventions.md` / `9x` rules *if present*. |
| `commands/ship.md` | Add a checklist item: curation ran; feature conforms to established conventions; no unresolved curation actions. |
| `hooks/scripts/session-start.sh` | Add `/curate` to the Spanish loop reminder. |
| `README.md` | Add `/curate` to the command reference. |

**Ordering note (no chicken-and-egg):** `/review` checks conformance to *existing* conventions
(from prior features); `/curate` then harvests *new* conventions from the current feature. New
conventions apply going forward — they do not retroactively fail the feature that produced them.
`/ship` verifies curation ran and the feature honored the conventions that existed at review time.

## i18n

Mirror the existing files exactly:

- Agent/command/skill **bodies** follow the current style; **`description` frontmatter** includes
  Spanish trigger synonyms (as in `code-reviewer.md`, `refactorer.md`).
- **Generated artifacts** (conventions entries, feedback, retrospective) are written in Spanish per
  `CLAUDE.md`.
- **Ids** (`CONV-n`, `AC-n`) and **Conventional-Commit prefixes** (`feat`, `fix`, …) stay English.

## Validation

- Conform new files to whatever `.github/workflows/ci.yml` checks (frontmatter, referenced-file
  existence, table consistency in `CLAUDE.md`).
- Run that validation before finishing.
- The repo's polyglot pre-commit gate skips toolchains it can't find; this is a markdown/template
  repo, so the plugin's own CI is the binding check.

## Acceptance criteria

- **AC-1** A `curator` agent, a `/curate` command, and a `curation` skill exist, each with valid
  frontmatter matching the repo's conventions and Spanish trigger synonyms in their descriptions.
- **AC-2** The `curate` step appears in the loop everywhere the loop is documented: `CLAUDE.md`
  diagram + tables, `rules/00-workflow.md`, `commands/feature.md`, `hooks/scripts/session-start.sh`,
  and `README.md`, positioned `/review → /curate → /ship`.
- **AC-3** The `curation` skill defines the harvest methodology and both artifact templates
  (`docs/conventions.md` with `CONV-<area>-n` ids; `.claude/rules/9x-*` advisory rules).
- **AC-4** The curator is advisory: its documented behavior writes only under `docs/` and
  `.claude/rules/`, never edits hooks/gates, and never blocks commits.
- **AC-5** `/review` (and `code-reviewer`) and `/ship` read `docs/conventions.md` / `9x` rules and
  report conformance *when present*, without failing if they are absent.
- **AC-6** The plugin's CI (`.github/workflows/ci.yml`) passes with the new files and edits.
