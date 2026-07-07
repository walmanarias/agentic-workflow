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
- **Trace everything.** Each convention cites where it came from (`From: <feature> (AC-n),
  <date>`). Don't invent conventions the code doesn't actually support.
- **Reconcile, don't hoard.** Supersede outdated conventions; don't accumulate contradictions.
- **Language:** conventions, feedback, and the retrospective follow the conversation's working
  language (English by default; Spanish when the user is working in Spanish); ids
  (`CONV-n`, `AC-n`) and Conventional-Commit prefixes stay English.

## Artifact — `docs/conventions.md`
Living document, organized by area. Each entry has a stable id, a rationale, an example, and
provenance.

    # Project conventions
    > Living document, curated by `curator` after each feature. Advisory.

    ## Naming
    ### CONV-naming-1: <convention statement>
    - Why: <reason>
    - Example: <good vs bad>
    - From: <feature> (AC-n), <date>

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

    # Rule: <title> (advisory — curated)
    > Enforces: CONV-<area>-n, CONV-<area>-m. Advisory — surfaced by /review and /ship, not a commit gate.

    <short, actionable policy, in bullets>
