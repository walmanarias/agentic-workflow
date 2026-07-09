# Design — `qa-visual` agent + token-frugal return contracts

**Date:** 2026-07-08
**Status:** Approved (brainstorming) → pending implementation plan
**Scope:** Two independent changes to the `agentic-sdd` plugin template.

---

## Problem

1. **Visual bugs slip through the flow.** Every test the workflow produces is *functional*: `e2e-tester` asserts on "user-visible behavior and accessibility roles," never on visual appearance. A broken layout, overflow, misalignment, bad spacing, low contrast, or busted styling passes all tests, so the user is the one who catches it by eye and requests manual rework. Nothing in the flow looks at the rendered UI.
2. **Sessions burn tokens.** A user session exceeded 234k tokens. The `/feature` loop already isolates work in subagents, and `implementer`/`e2e-tester` already return compact summaries — but that return discipline is not universal across the 20 agents, so subagents dump file contents/logs into the orchestrator context and inflate it.

## Goals

- Add a QA agent that **catches visual bugs automatically**, removing the manual eyeball-and-rework step.
- Wire it into the `/feature` flow as a first-class phase.
- Reduce per-session token consumption by **generalizing the existing return-contract pattern**, with no new heavyweight machinery.

## Non-goals

- No committed screenshot-baseline / visual-regression tests (Playwright `toHaveScreenshot`, Percy, Chromatic, Applitools). Considered and declined — regression-oriented, needs baseline upkeep, and won't catch a bug present from the start.
- No new frugality *rule* file, model-tiering, or per-command token-budget config (the "comprehensive" option was not chosen).

---

## Part 1 — The `qa-visual` agent

Agent-driven visual inspection. The agent drives the running app, captures screenshots, and **reads them** to judge whether the UI looks right — no baseline images to maintain, catches first-time bugs.

### Capture mechanism (decided)

Reuse the stack's **existing E2E driver** to capture, then the agent `Read`s the PNGs:

| Stack | Capture tool (already in `e2e-tester`) |
|---|---|
| Next.js / React (web) | Playwright screenshots (per route/state/breakpoint) |
| React Native | Detox / Maestro device screenshots |
| Avalonia desktop (XAML) | Appium screenshots / `Avalonia.Headless` render-to-bitmap |
| Blazor / .NET web | Playwright for .NET |

Rationale: portable to any repo, **no new or paid dependencies**, reuses the E2E harness, and works in plain Claude Code because `Read` renders image files. Rejected alternative: external SaaS (Percy/Chromatic/Applitools) — paid third-party deps, regression-oriented.

### Agent contract

- **File:** `plugins/agentic-sdd/agents/qa-visual.md`. `tools: Read, Write, Edit, Grep, Glob, Bash`. `model: sonnet`.
- **Trigger:** after a user-facing flow is implemented and functionally green; keywords "qa", "visual", "visual bug", "UI check", "looks wrong". Spanish triggers too ("qa", "visual", "revisión visual", "se ve mal"), matching the other agents' bilingual trigger convention.
- **Process:**
  1. Read the spec's user-facing `AC-n` + any `docs/design/` references.
  2. Launch the running app; drive each flow with the stack's E2E driver, capturing screenshots to a **gitignored** dir (`.qa-visual/` or similar) — including the states people forget: loading, empty, error, long-text, and narrow/wide breakpoints.
  3. `Read` each PNG and inspect for visual defects: broken layout, overflow/clipping, misalignment, bad spacing, low contrast, truncated text, unloaded images, wrong theme.
  4. Report findings grouped **Blocking / Should-fix / Nit** (mirrors `code-reviewer`), each tied to an `AC-n` and its screenshot path.
  5. Hand confirmed defects to `implementer` + the stack expert to fix, then **re-inspect until clean**. This loop is what removes the manual rework.
- **Token safety (ties into Part 2):** the agent `Read`s the images **inside its own subagent context** and returns to the orchestrator only *text findings + PNG paths* — never the images. The image-heavy work never touches the main `/feature` context.

### Flow integration

- **New command** `plugins/agentic-sdd/commands/qa.md` → `/qa [flow]`, delegates to `qa-visual`.
- **`commands/feature.md`:** insert a **QA (visual)** phase between step 6 (E2E) and step 7 (Review):
  `… → /e2e → /qa → /review → /curate → …`
- **New skill** `plugins/agentic-sdd/skills/visual-qa/SKILL.md`: the playbook — capture-by-stack table, the visual-inspection checklist, and the report format. Parallels the existing `e2e-testing` skill. Optional `references/capture-by-stack.md` if the SKILL grows past ~60 lines.
- **Doc updates:** `CLAUDE.md` (agents table, commands table, skills table, the flow diagram + happy-path line), `hooks/scripts/session-start.sh` (flow line), `README.md` if it enumerates agents/commands.

---

## Part 2 — Token-frugal return contracts

Generalize the pattern `implementer` and `e2e-tester` already use.

- **Audit the lifecycle agents first** (the ones inside the `/feature` loop, where the 234k accumulates): `architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `qa-visual` (new), `code-reviewer`, `curator`, `refactorer`, `cicd-engineer`. Add/tighten a one-line **"Return to the caller"** clause on each: a concise summary (paths + verdicts + counts), never full file contents, diffs, or run logs. Stack-expert agents are a follow-up, lower-churn pass.
- **Orchestration guidance** in `feature.md`: pass file paths / `AC-n` ids between phases; do not re-echo a subagent's output into the main thread.
- No new rule file, no model-tiering, no budget config — scoped to the return-contract audit only.

---

## Files touched (implementation summary)

**New:** `agents/qa-visual.md`, `commands/qa.md`, `skills/visual-qa/SKILL.md` (+ optional `references/capture-by-stack.md`).
**Edited:** `commands/feature.md`, `CLAUDE.md`, `hooks/scripts/session-start.sh`, `README.md`, and the lifecycle `agents/*.md` (return-contract clauses).

## Testing / verification

This template ships Markdown assets (agents/commands/skills), not runtime code, so verification is structural:
- The plugin's own CI (`.github/workflows/ci.yml`) validates plugin structure — the new agent/command/skill must satisfy it (frontmatter, required fields).
- Manual smoke: run `/qa` against a small sample UI repo; confirm it captures screenshots, reads them, and reports a seeded visual defect (e.g. an intentionally clipped element) grouped Blocking/Should-fix/Nit with the screenshot path — and that the orchestrator context receives text + paths only, not the images.
- Confirm `/feature` names the QA phase between E2E and Review, and `CLAUDE.md` + `session-start.sh` reflect the new phase consistently.

## Open questions

None blocking. Agent name `qa-visual` and "lifecycle-agents-first" audit scope are confirmed.
