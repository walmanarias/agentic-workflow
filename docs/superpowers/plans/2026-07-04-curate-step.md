# Curate Step Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a first-class `curate` step to the agentic-sdd workflow — a `curator` agent, a `/curate` command, and a `curation` skill — that runs `/review → /curate → /ship`, gives feedback on the work and process, and curates the target project's living conventions and advisory rules.

**Architecture:** Follow the repo's `command → agent → skill` triad plus loop wiring. The three new files reference each other (command delegates to agent, both apply the skill). Then edit the docs/config that describe the loop so `curate` appears everywhere, and make `/review` + `/ship` read the curated conventions as advisory checks. No JSON manifests or the installer change — the installer copies whole directories and Claude Code auto-discovers agents/commands/skills.

**Tech Stack:** Markdown (agent/command/skill definitions, docs), Bash (hook script). This is a template/plugin repo — there is no application code. The RED/GREEN cycle is adapted: each task's "test" is a verification command (`grep`, `head`, `python3 -c json.load`, `bash -n`, the installer end-to-end run) that fails before the change and passes after.

## Global Constraints

- Every `agents/*.md`, `commands/*.md`, and `skills/*/SKILL.md` file MUST have `---` as its first line (CI: "frontmatter present").
- New agent/command/skill files land under `plugins/agentic-sdd/` (the plugin source), not `.claude/`.
- i18n (from `CLAUDE.md`): agent/command/skill **bodies** follow the existing English-with-Spanish-triggers style; `description` frontmatter includes Spanish trigger synonyms (as in `code-reviewer.md`). Generated runtime artifacts (conventions, feedback) are Spanish. Ids (`CONV-n`, `AC-n`) and Conventional-Commit prefixes (`feat`, `fix`, …) stay English.
- Loop position is fixed: `… → /review → /curate → /update-pr → /ship` (curate immediately after review).
- Curator is **advisory**: it writes only under `docs/` and `.claude/rules/`; it never edits hooks/gates/`settings.json` and never blocks a commit.
- Rule numbering for curated project rules is `9x` (`.claude/rules/9x-<topic>.md`), 90+.
- Convention ids are `CONV-<area>-n`.
- Work happens on branch `feat/curate-step` (already created; the design doc is already committed there).
- Commit messages: Conventional-Commit prefix in English, description in Spanish, ending with the `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` trailer.

---

### Task 1: The `curation` skill

**Files:**
- Create: `plugins/agentic-sdd/skills/curation/SKILL.md`

**Interfaces:**
- Produces: the skill named `curation`, referenced by name from `agents/curator.md` and `commands/curate.md` (Tasks 2–3). Defines the harvest method and the two artifact templates (`docs/conventions.md` with `CONV-<area>-n` ids; `.claude/rules/9x-*`).

- [ ] **Step 1: Verify the skill does not exist yet (RED)**

Run: `test ! -e plugins/agentic-sdd/skills/curation/SKILL.md && echo ABSENT`
Expected: prints `ABSENT`

- [ ] **Step 2: Create the skill file**

Create `plugins/agentic-sdd/skills/curation/SKILL.md` with exactly this content:

```markdown
---
name: curation
description: Use after /review and before /ship to curate the project's living conventions and advisory rules — harvest durable decisions from the feature just built, give feedback on the work and the process, and record conventions (docs/conventions.md) and advisory project rules (.claude/rules/9x-*). Trigger on "curate", "curation", "conventions", "retrospective", "harvest learnings". En español — "curar", "curación", "convenciones", "retrospectiva", "cosechar aprendizajes".
---

# Curation

Feedback + continuous improvement. After a feature passes review, the curator reflects on the
work and the process, then **selects and organizes** the durable decisions into the project's
living conventions and promotes the strongest into **advisory** rules. The conventions are the
project's own source of truth for *how we build here*; every future feature inherits them.

Curation is **advisory**: it writes docs and rules only. It never edits hooks or gates and never
blocks a commit. A human decides when a convention hardens into an enforced gate.

## When to run
- Standard loop: `/review → /curate → /ship`, once per feature.
- Standalone: any time you want to harvest conventions from recent work.

## Inputs
- The spec (`specs/*`) and its acceptance criteria.
- The reviewed diff and the `code-reviewer` findings.
- The existing `docs/conventions.md` and `.claude/rules/9x-*` (may not exist yet — that's fine).

## The method
1. **Reflect** — read the spec, the diff, and the review output. Write concise feedback: what the
   work did well, where the process had friction, and gaps (missing tests, unclear ACs, repeated
   review nits, tooling papercuts).
2. **Select** — pick out *durable* decisions worth generalizing across areas: naming, structure,
   testing, error handling, API, database, tooling, process/workflow. Discard one-offs — a
   decision earns a convention only if it is likely to recur (YAGNI).
3. **Organize** — merge each kept decision into `docs/conventions.md` under its area heading.
   Reconcile: refine or supersede stale entries instead of blindly appending. Give every
   convention a stable id `CONV-<area>-n`.
4. **Establish** — for conventions strong and general enough to enforce, write or update an
   advisory rule at `.claude/rules/9x-<topic>.md` in the shipped-rule format, citing the `CONV`
   ids it encodes. Mark it advisory.
5. **Report** — return the feedback, a summary of conventions added/changed and rules proposed,
   and any author action items. Persist the retrospective to `docs/curation/<date>-<feature>.md`.

## Guardrails
- **Advisory only.** Never touch hooks, gates, or `settings.json`. Never block a commit.
- **Docs & rules only.** Write only under `docs/` and `.claude/rules/`. Never change production
  code, tests, or the spec.
- **Trace everything.** Each convention cites where it came from (`Desde: <feature> (AC-n),
  <fecha>`). Don't invent conventions the code doesn't actually support.
- **Reconcile, don't hoard.** Supersede outdated conventions; don't accumulate contradictions.
- **Language:** conventions, feedback, and the retrospective are written in Spanish; ids
  (`CONV-n`, `AC-n`) and Conventional-Commit prefixes stay English.

## Artifact — `docs/conventions.md`
Living document, organized by area. Each entry has a stable id, a rationale, an example, and
provenance.

    # Convenciones del proyecto
    > Documento vivo, curado por `curator` tras cada feature. Advisory.

    ## Naming
    ### CONV-naming-1: <enunciado de la convención>
    - Por qué: <razón>
    - Ejemplo: <bueno vs malo>
    - Desde: <feature> (AC-n), <fecha>

    ## Structure
    ## Testing
    ## Error handling
    ## API
    ## Database
    ## Tooling
    ## Process / Workflow

## Artifact — `.claude/rules/9x-<topic>.md`
Same shape as the shipped `00–40` rules. Numbered 90+ so it never collides with the template's
rules. Header marks it advisory and cites the conventions it enforces.

    # Rule: <título> (advisory — curated)
    > Enforces: CONV-<area>-n, CONV-<area>-m. Advisory — surfaced by /review and /ship, not a commit gate.

    <política corta y accionable, en viñetas>
```

- [ ] **Step 3: Verify the file exists with valid frontmatter (GREEN)**

Run: `head -1 plugins/agentic-sdd/skills/curation/SKILL.md | grep -q '^---' && grep -q '^name: curation' plugins/agentic-sdd/skills/curation/SKILL.md && echo OK`
Expected: prints `OK`

- [ ] **Step 4: Verify both artifact templates are present**

Run: `grep -c 'CONV-<area>-n\|9x-<topic>' plugins/agentic-sdd/skills/curation/SKILL.md`
Expected: `2` or greater

- [ ] **Step 5: Commit**

```bash
git add plugins/agentic-sdd/skills/curation/SKILL.md
git commit -m "$(cat <<'EOF'
feat(skills): añade la skill curation (método + plantillas de artefactos)

Playbook para curar convenciones del proyecto: método de cosecha y las
plantillas de docs/conventions.md (ids CONV-<area>-n) y reglas advisory
.claude/rules/9x-*. Advisory — nunca bloquea commits.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: The `curator` agent

**Files:**
- Create: `plugins/agentic-sdd/agents/curator.md`

**Interfaces:**
- Consumes: the `curation` skill (Task 1) by name.
- Produces: the agent named `curator`, invoked by `/curate` (Task 3) and referenced in `CLAUDE.md`, `feature.md`, `ship.md` (Tasks 4–6). Tools: `Read, Write, Edit, Grep, Glob, Bash`.

- [ ] **Step 1: Verify the agent does not exist yet (RED)**

Run: `test ! -e plugins/agentic-sdd/agents/curator.md && echo ABSENT`
Expected: prints `ABSENT`

- [ ] **Step 2: Create the agent file**

Create `plugins/agentic-sdd/agents/curator.md` with exactly this content:

```markdown
---
name: curator
description: Use after /review and before /ship to run a retrospective on the feature just built — feed back on the work and the process, then curate the project's living conventions (docs/conventions.md) and advisory rules (.claude/rules/9x-*). Selects, organizes, and continuously improves the project's steps, tools, and methodologies. Advisory only — never blocks commits. Proactively invoke once a change has passed review. Trigger on "curate", "curation", "conventions", "retrospective". En español — "curar", "curación", "convenciones", "retrospectiva", "cosechar aprendizajes".
tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

You are the **curator**. After a feature passes review, you ensure quality by capturing how this
project builds software — selecting, organizing, and continuously improving its conventions,
tools, and methodologies. Apply the `curation` skill.

## What you produce
1. **Feedback** on the work performed and the process: what went well, where there was friction,
   and gaps (missing tests, unclear ACs, repeated review nits, tooling papercuts).
2. **Conventions** — durable decisions harvested into `docs/conventions.md`, organized by area,
   each with a stable `CONV-<area>-n` id and provenance.
3. **Advisory rules** — the strongest, most general conventions promoted to
   `.claude/rules/9x-<topic>.md`, citing the `CONV` ids they encode.

## Process
1. **Reflect** — read the spec (`specs/*`), the reviewed diff, and the `code-reviewer` findings.
2. **Select** — keep only decisions likely to recur across naming, structure, testing, error
   handling, API, database, tooling, and process. Discard one-offs (YAGNI).
3. **Organize** — merge into `docs/conventions.md`; reconcile and supersede stale entries rather
   than appending duplicates.
4. **Establish** — write/update advisory `9x` rules for conventions worth enforcing.
5. **Report** — feedback + summary of conventions added/changed + rules proposed + author action
   items; persist the retrospective to `docs/curation/<date>-<feature>.md`.

## Rules
- **Advisory only.** Never edit hooks, gates, or `settings.json`; never block a commit. A human
  decides when a convention becomes an enforced gate.
- **Docs & rules only.** Write solely under `docs/` and `.claude/rules/`. Never touch production
  code, tests, or the spec.
- **Trace everything.** Cite provenance on every convention; don't invent conventions the code
  doesn't support.
- **Reconcile, don't hoard.** Supersede outdated conventions instead of accumulating contradictions.
- Write conventions, feedback, and the retrospective in Spanish; keep ids (`CONV-n`, `AC-n`) and
  Conventional-Commit prefixes in English.
- **Return to the caller:** the feedback, the list of conventions/rules changed (paths + ids), and
  the author action items — not the full file contents.
```

- [ ] **Step 3: Verify the file exists with valid frontmatter and tools (GREEN)**

Run: `head -1 plugins/agentic-sdd/agents/curator.md | grep -q '^---' && grep -q '^name: curator' plugins/agentic-sdd/agents/curator.md && grep -q '^tools: Read, Write, Edit, Grep, Glob, Bash' plugins/agentic-sdd/agents/curator.md && echo OK`
Expected: prints `OK`

- [ ] **Step 4: Verify advisory guardrail is stated**

Run: `grep -qi 'Advisory only' plugins/agentic-sdd/agents/curator.md && echo OK`
Expected: prints `OK`

- [ ] **Step 5: Commit**

```bash
git add plugins/agentic-sdd/agents/curator.md
git commit -m "$(cat <<'EOF'
feat(agents): añade el agente curator (retrospectiva + curación)

Especialista que corre tras /review: retroalimenta el trabajo y el proceso,
y cura convenciones del proyecto (docs/conventions.md) y reglas advisory
9x. Solo escribe en docs/ y .claude/rules/; nunca bloquea commits.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: The `/curate` command

**Files:**
- Create: `plugins/agentic-sdd/commands/curate.md`

**Interfaces:**
- Consumes: the `curator` agent (Task 2) and the `curation` skill (Task 1) by name.
- Produces: the `/curate` command, referenced in `CLAUDE.md`, `feature.md`, `README.md` (Tasks 4–5).

- [ ] **Step 1: Verify the command does not exist yet (RED)**

Run: `test ! -e plugins/agentic-sdd/commands/curate.md && echo ABSENT`
Expected: prints `ABSENT`

- [ ] **Step 2: Create the command file**

Create `plugins/agentic-sdd/commands/curate.md` with exactly this content:

```markdown
---
description: Retrospective on the feature just built — feedback on the work + process, and curate the project's living conventions & advisory rules.
argument-hint: [scope or feature]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

Invoke the `curator` agent to curate: **$ARGUMENTS** (default: the feature/diff just reviewed).

Apply the `curation` skill. Reflect on the work and the process, then harvest durable decisions
into `docs/conventions.md` (organized by area, each with a `CONV-<area>-n` id and provenance) and
promote the strongest into advisory `.claude/rules/9x-*` rules that cite the conventions they
encode. Persist the retrospective to `docs/curation/<date>-<feature>.md`.

Advisory only: write docs and rules under `docs/` and `.claude/rules/`. Never edit hooks/gates,
never touch production code or tests, and never block a commit. Runs after `/review`, before
`/ship`.
```

- [ ] **Step 3: Verify the file exists with valid frontmatter (GREEN)**

Run: `head -1 plugins/agentic-sdd/commands/curate.md | grep -q '^---' && grep -q 'curator' plugins/agentic-sdd/commands/curate.md && echo OK`
Expected: prints `OK`

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/commands/curate.md
git commit -m "$(cat <<'EOF'
feat(commands): añade el comando /curate

Punto de entrada del paso curate: delega en el agente curator y aplica la
skill curation. Corre tras /review, antes de /ship. Advisory.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Wire the loop into `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (loop diagram, Commands table, Lifecycle-agents table, Skills table, repository-layout counts)

**Interfaces:**
- Consumes: the names `/curate`, `curator`, `curation` from Tasks 1–3.

- [ ] **Step 1: Verify curate is not yet in CLAUDE.md (RED)**

Run: `grep -c '/curate\|curator\|curation' CLAUDE.md`
Expected: `0`

- [ ] **Step 2: Update the loop diagram**

Replace this block:

```
/plan → /spec → /tdd → /implement → /e2e → /review → /update-pr → /ship
design  spec    RED     GREEN+refac   E2E    review    PR desc      ship gate
(opt)  (truth) (tests) (clean code)  (flows)          (describe)
```

with:

```
/plan → /spec → /tdd → /implement → /e2e → /review → /curate → /update-pr → /ship
design  spec    RED     GREEN+refac   E2E    review   curate     PR desc      ship gate
(opt)  (truth) (tests) (clean code)  (flows)         (conv.)
```

- [ ] **Step 3: Add the Commands-table row**

Find the row:

```
| `/review [scope]` | Clean-code / correctness / security / test review of the diff | `code-reviewer` |
```

Insert immediately AFTER it:

```
| `/curate [scope]` | Retrospective — feedback on work + process; curates the project's living conventions & advisory rules | `curator` |
```

- [ ] **Step 4: Add the Lifecycle-agents-table row**

Find the row:

```
| `code-reviewer` | Reviews the diff; findings grouped Blocking / Should-fix / Nit | review output |
```

Insert immediately AFTER it:

```
| `curator` | Retrospective — feedback on work + process; curates project conventions & advisory rules | `docs/conventions.md`, `.claude/rules/9x-*` |
```

- [ ] **Step 5: Add the Skills-table row**

Find the row:

```
| `pr-description` | Writing/updating a PR title & description from commits — section catalog + style guide (loaded by `/update-pr`) |
```

Insert immediately AFTER it:

```
| `curation` | Curating the project's conventions & advisory rules after a feature — harvest method + artifact templates |
```

- [ ] **Step 6: Bump the repository-layout counts**

Make these three replacements in the repository-layout code block:
- `← 19 agents (lifecycle + stack experts)` → `← 20 agents (lifecycle + stack experts)`
- `← 13 slash commands` → `← 14 slash commands`
- `← 7 skills (+ references)` → `← 8 skills (+ references)`

- [ ] **Step 7: Verify all references landed (GREEN)**

Run: `grep -q '/curate \[scope\]' CLAUDE.md && grep -q '| `curator` |' CLAUDE.md && grep -q '| `curation` |' CLAUDE.md && grep -q '20 agents' CLAUDE.md && grep -q '14 slash commands' CLAUDE.md && grep -q '8 skills' CLAUDE.md && grep -q '/review → /curate → /update-pr → /ship' CLAUDE.md && echo OK`
Expected: prints `OK`

- [ ] **Step 8: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs(claude): integra el paso curate en la fuente de verdad

Añade /curate al diagrama del flujo (/review -> /curate -> /ship) y filas
en las tablas de comandos, agentes y skills; actualiza los conteos del
layout (20 agentes, 14 comandos, 8 skills).

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Wire the loop into the rule, `/feature`, the session hook, and README

**Files:**
- Modify: `plugins/agentic-sdd/rules/00-workflow.md`
- Modify: `plugins/agentic-sdd/commands/feature.md`
- Modify: `plugins/agentic-sdd/hooks/scripts/session-start.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: `/curate`, `curator` from Tasks 1–3.

- [ ] **Step 1: Verify curate is not yet in these files (RED)**

Run: `grep -c 'curate\|curator\|curation' plugins/agentic-sdd/rules/00-workflow.md plugins/agentic-sdd/commands/feature.md plugins/agentic-sdd/hooks/scripts/session-start.sh README.md`
Expected: every file reports `0`

- [ ] **Step 2: Update `rules/00-workflow.md`**

Replace:

```
`/plan` (design, optional) → `/spec` → `/tdd` (RED) → `/implement` (GREEN → refactor) → `/e2e` → `/review` → `/ship`.
```

with:

```
`/plan` (design, optional) → `/spec` → `/tdd` (RED) → `/implement` (GREEN → refactor) → `/e2e` → `/review` → `/curate` → `/ship`.
```

- [ ] **Step 3: Insert the Curate step into `commands/feature.md`**

Replace:

```
7. **Review:** invoke `code-reviewer`; address Blocking + Should-fix.
8. **Describe:** run `/update-pr` to generate/refresh the PR title and description from the branch commits (stack-aware; preserves existing media).
9. **Verify:** confirm every AC maps to a passing test, coverage/lint/type gates pass, and the spec's Definition of Done is met. Summarize what shipped.
```

with:

```
7. **Review:** invoke `code-reviewer`; address Blocking + Should-fix.
8. **Curate:** invoke `curator` to feed back on the work + process and update the project's conventions (`docs/conventions.md`) and advisory rules (`.claude/rules/9x-*`). Advisory only — never blocks.
9. **Describe:** run `/update-pr` to generate/refresh the PR title and description from the branch commits (stack-aware; preserves existing media).
10. **Verify:** confirm every AC maps to a passing test, coverage/lint/type gates pass, and the spec's Definition of Done is met. Summarize what shipped.
```

- [ ] **Step 4: Update the session-start reminder**

In `plugins/agentic-sdd/hooks/scripts/session-start.sh`, replace:

```
Flujo: /plan (diseño) -> /spec -> /tdd (RED) -> /implement (GREEN+refactor) -> /e2e -> /review -> /ship.
```

with:

```
Flujo: /plan (diseño) -> /spec -> /tdd (RED) -> /implement (GREEN+refactor) -> /e2e -> /review -> /curate -> /ship.
```

- [ ] **Step 5: Update README — agent list (line ~11)**

Replace:

```
- **19 agents** — 8 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `code-reviewer`, `refactorer`, `cicd-engineer`) + 11 stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML, Django/DRF, FastAPI, Flask, PostgreSQL/MongoDB).
```

with:

```
- **20 agents** — 9 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `code-reviewer`, `curator`, `refactorer`, `cicd-engineer`) + 11 stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML, Django/DRF, FastAPI, Flask, PostgreSQL/MongoDB).
```

- [ ] **Step 6: Update README — command list (line ~12)**

Replace:

```
- **13 commands** — `/feature`, `/plan`, `/spec`, `/tdd`, `/implement`, `/e2e`, `/review`, `/refactor`, `/cicd`, `/update-pr`, `/triage-copilot`, `/triage-reviews`, `/ship`.
```

with:

```
- **14 commands** — `/feature`, `/plan`, `/spec`, `/tdd`, `/implement`, `/e2e`, `/review`, `/curate`, `/refactor`, `/cicd`, `/update-pr`, `/triage-copilot`, `/triage-reviews`, `/ship`.
```

- [ ] **Step 7: Update README — skill list (line ~13)**

Replace:

```
- **7 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description`.
```

with:

```
- **8 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description`, `curation`.
```

- [ ] **Step 8: Update README — loop line (line ~116)**

Replace:

```
/plan → /spec → /tdd (RED) → /implement (GREEN + refactor) → /e2e → /review → /update-pr → /ship
```

with:

```
/plan → /spec → /tdd (RED) → /implement (GREEN + refactor) → /e2e → /review → /curate → /update-pr → /ship
```

- [ ] **Step 9: Verify all edits landed (GREEN)**

Run:
```bash
grep -q '/review` → `/curate` → `/ship`' plugins/agentic-sdd/rules/00-workflow.md \
&& grep -q '8. \*\*Curate:\*\*' plugins/agentic-sdd/commands/feature.md \
&& grep -q '10. \*\*Verify:\*\*' plugins/agentic-sdd/commands/feature.md \
&& grep -q -- '-> /review -> /curate -> /ship' plugins/agentic-sdd/hooks/scripts/session-start.sh \
&& grep -q '20 agents' README.md && grep -q '14 commands' README.md \
&& grep -q '8 skills' README.md && grep -q '/review → /curate → /update-pr → /ship' README.md \
&& echo OK
```
Expected: prints `OK`

- [ ] **Step 10: Verify the session hook is still valid shell**

Run: `bash -n plugins/agentic-sdd/hooks/scripts/session-start.sh && echo SHELL_OK`
Expected: prints `SHELL_OK`

- [ ] **Step 11: Commit**

```bash
git add plugins/agentic-sdd/rules/00-workflow.md plugins/agentic-sdd/commands/feature.md plugins/agentic-sdd/hooks/scripts/session-start.sh README.md
git commit -m "$(cat <<'EOF'
docs: propaga el paso curate al rule, /feature, hook y README

/curate entra en el loop del rule 00-workflow, como paso 8 de /feature, en
el recordatorio de session-start y en README (conteos + diagrama).

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Advisory conformance in `/review` and `/ship`

**Files:**
- Modify: `plugins/agentic-sdd/commands/review.md`
- Modify: `plugins/agentic-sdd/agents/code-reviewer.md`
- Modify: `plugins/agentic-sdd/commands/ship.md`

**Interfaces:**
- Consumes: the artifact paths `docs/conventions.md` and `.claude/rules/9x-*` defined by the `curation` skill (Task 1). These are *runtime* artifacts in target projects — the reviewer/ship steps must not fail when they are absent.

- [ ] **Step 1: Verify conventions checks are not yet present (RED)**

Run: `grep -c 'conventions.md\|9x-' plugins/agentic-sdd/commands/review.md plugins/agentic-sdd/agents/code-reviewer.md plugins/agentic-sdd/commands/ship.md`
Expected: every file reports `0`

- [ ] **Step 2: Add the conformance check to `commands/review.md`**

Replace:

```
Apply the `clean-code` skill. Check AC coverage, test quality (no weakened/skipped tests, behavior not internals), security (injection, authz, secrets), performance (N+1, indexes, unbounded loads), and maintainability. Group findings as Blocking / Should-fix / Nit with file:line, why it matters, and a concrete fix. End with a verdict. Do not edit files.
```

with:

```
Apply the `clean-code` skill. Check AC coverage, test quality (no weakened/skipped tests, behavior not internals), security (injection, authz, secrets), performance (N+1, indexes, unbounded loads), and maintainability. Also check conformance to the project's curated conventions (`docs/conventions.md`) and advisory rules (`.claude/rules/9x-*`) when they exist — flag deviations; do not fail if these files are absent. Group findings as Blocking / Should-fix / Nit with file:line, why it matters, and a concrete fix. End with a verdict. Do not edit files.
```

- [ ] **Step 3: Add inspection item 8 to `agents/code-reviewer.md`**

Find:

```
7. **API & DB:** backward compatibility, migration safety (PostgreSQL migrations, Mongo schema changes), contract stability.
```

Insert immediately AFTER it:

```
8. **Conventions:** conformance to the project's curated conventions (`docs/conventions.md`) and advisory `9x` rules (`.claude/rules/9x-*`) when present. Flag deviations (usually Should-fix); never fail if these files don't exist — a project may not have curated conventions yet.
```

- [ ] **Step 4: Add the curation checklist item to `commands/ship.md`**

Find:

```
4. Run `/review` (code-reviewer) and confirm no Blocking findings remain.
```

Insert immediately AFTER it:

```
5. Confirm the curate step ran and the feature conforms to the established conventions (`docs/conventions.md`); no unresolved curation action items remain. Skip if the project has no curated conventions yet.
```

- [ ] **Step 5: Renumber the remaining `ship.md` steps**

After the insertion the tail of the list must read 6/7/8. Replace:

```
5. Check migration safety (PostgreSQL/Mongo) and backward compatibility of any API/contract change.
6. Confirm the spec's Definition of Done is fully satisfied.
7. Ensure the PR is described — if the branch has an open PR, confirm its title/body are current (run `/update-pr` if stale).
```

with:

```
6. Check migration safety (PostgreSQL/Mongo) and backward compatibility of any API/contract change.
7. Confirm the spec's Definition of Done is fully satisfied.
8. Ensure the PR is described — if the branch has an open PR, confirm its title/body are current (run `/update-pr` if stale).
```

- [ ] **Step 6: Verify the edits landed and no duplicate step numbers exist (GREEN)**

Run:
```bash
grep -q 'docs/conventions.md' plugins/agentic-sdd/commands/review.md \
&& grep -q '8. \*\*Conventions:\*\*' plugins/agentic-sdd/agents/code-reviewer.md \
&& grep -q '^5\. Confirm the curate step ran' plugins/agentic-sdd/commands/ship.md \
&& grep -q '^8\. Ensure the PR is described' plugins/agentic-sdd/commands/ship.md \
&& echo OK
```
Expected: prints `OK`

- [ ] **Step 7: Verify ship.md step numbers are the contiguous sequence 1..8**

Run: `grep -oE '^[0-9]+\.' plugins/agentic-sdd/commands/ship.md | tr -d '.' | paste -sd, -`
Expected: `1,2,3,4,5,6,7,8`

- [ ] **Step 8: Commit**

```bash
git add plugins/agentic-sdd/commands/review.md plugins/agentic-sdd/agents/code-reviewer.md plugins/agentic-sdd/commands/ship.md
git commit -m "$(cat <<'EOF'
feat: /review y /ship leen las convenciones curadas (advisory)

code-reviewer añade una comprobación de conformidad con
docs/conventions.md y reglas 9x cuando existen (no falla si faltan); /ship
verifica que el paso curate corrió. Nunca bloquea si no hay convenciones.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Full local validation (mirror CI) + wrap-up

**Files:**
- None (verification only)

**Interfaces:**
- Consumes: all prior tasks.

- [ ] **Step 1: Frontmatter present on every agent/command/skill (mirrors CI job)**

Run:
```bash
for f in plugins/agentic-sdd/agents/*.md plugins/agentic-sdd/commands/*.md plugins/agentic-sdd/skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---' || { echo "MISSING frontmatter: $f"; exit 1; }
done && echo "frontmatter ok"
```
Expected: prints `frontmatter ok`

- [ ] **Step 2: Hook scripts still valid shell (mirrors CI job)**

Run: `for f in plugins/agentic-sdd/hooks/scripts/*.sh scripts/install.sh; do bash -n "$f" && echo "ok $f"; done`
Expected: `ok` for each script, no syntax errors

- [ ] **Step 3: JSON manifests still parse (mirrors CI job)**

Run:
```bash
for f in .claude-plugin/marketplace.json plugins/agentic-sdd/.claude-plugin/plugin.json plugins/agentic-sdd/hooks/hooks.json plugins/agentic-sdd/settings.template.json; do
  python3 -c "import json; json.load(open('$f'))" && echo "ok $f"
done
```
Expected: `ok` for each manifest

- [ ] **Step 4: Copy installer picks up the new files end-to-end (mirrors CI job)**

Run:
```bash
TMP="$(mktemp -d)/app"; mkdir -p "$TMP"; echo '{"scripts":{}}' > "$TMP/package.json"
bash scripts/install.sh "$TMP"
test -f "$TMP/.claude/agents/curator.md" \
&& test -f "$TMP/.claude/commands/curate.md" \
&& test -f "$TMP/.claude/skills/curation/SKILL.md" \
&& echo "installer ok"
```
Expected: prints `installer ok` (the new agent, command, and skill are copied into the target `.claude/`)

- [ ] **Step 5: Loop is consistent across all docs**

Run:
```bash
grep -rl '/review → /curate\|/review -> /curate\|/review` → `/curate' \
  CLAUDE.md README.md plugins/agentic-sdd/rules/00-workflow.md \
  plugins/agentic-sdd/hooks/scripts/session-start.sh | sort
```
Expected: all four files listed (each shows `curate` between review and ship)

- [ ] **Step 6: Confirm working tree is clean (everything committed)**

Run: `git status --porcelain`
Expected: no output (all changes committed across Tasks 1–6)

- [ ] **Step 7: Push the branch and open a PR (only if the user asks to ship)**

```bash
git push -u origin feat/curate-step
gh pr create --fill --base main
```
Expected: PR created. (Do this only when the user confirms they want a PR.)

---

## Self-Review

**Spec coverage** (against `docs/superpowers/specs/2026-07-04-curate-step-design.md`):
- AC-1 (agent + command + skill with valid frontmatter + Spanish triggers) → Tasks 1, 2, 3.
- AC-2 (curate appears everywhere the loop is documented, positioned review→curate→ship) → Tasks 4 (CLAUDE.md), 5 (00-workflow, feature, session-start, README), verified in Task 7 Step 5.
- AC-3 (skill defines method + both artifact templates) → Task 1 (Steps 2, 4).
- AC-4 (advisory: writes only docs/ and .claude/rules/, never gates/blocks) → Tasks 1 & 2 guardrails; asserted in Task 2 Step 4.
- AC-5 (/review and /ship read conventions, report when present, don't fail when absent) → Task 6.
- AC-6 (plugin CI passes) → Task 7 (Steps 1–4 mirror the CI jobs locally).

**Placeholder scan:** no TBD/TODO; every file's full content is inline; every edit shows exact old→new text.

**Type/name consistency:** the names `curator` (agent), `/curate` (command), `curation` (skill), the id scheme `CONV-<area>-n`, the rule path `.claude/rules/9x-<topic>.md`, and the artifact `docs/conventions.md` are used identically across Tasks 1–7 and match the design doc.
