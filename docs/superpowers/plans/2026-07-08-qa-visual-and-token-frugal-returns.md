# qa-visual Agent + Token-Frugal Return Contracts — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `qa-visual` agent that catches visual bugs automatically by driving the app and reading screenshots, wire it into `/feature`, and tighten return-to-caller contracts on the lifecycle agents to cut per-session token use.

**Architecture:** This repo is the `agentic-sdd` plugin **template** — its deliverables are Markdown assets (agents, commands, skills) plus shell hooks, not runtime code. So "tests" are structural: frontmatter checks, `bash -n`, and cross-reference consistency greps that fail before an asset exists / is wired and pass after. Claude Code auto-discovers agents/commands/skills by directory, and `scripts/install.sh` copies those directories wholesale, so no manifest enumeration needs updating.

**Tech Stack:** Markdown (YAML frontmatter), Bash, the agentic-sdd plugin layout.

## Global Constraints

- Work happens on branch `feat/qa-visual-and-token-frugal` (already created; the gate fix + design doc are already committed there).
- New agent name is exactly `qa-visual`; new command is exactly `/qa`; new skill is exactly `visual-qa`; the new flow phase label is exactly **QA (visual)**. Use these verbatim everywhere.
- Every new `agents/*.md`, `commands/*.md`, and `skills/*/SKILL.md` MUST start with a `---` YAML frontmatter line (the plugin CI enforces `head -1 | grep '^---'`).
- Agents/commands are bilingual by convention: include English **and** Spanish trigger keywords in `description`, matching existing agents. `AC-n` ids, Conventional Commit prefixes, and technical names stay English.
- The `qa-visual` phase sits between `/e2e` and `/review` in every representation of the flow (feature.md, CLAUDE.md diagram + happy-path, README, session-start.sh).
- Commit messages use Conventional Commits and end with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

## File Structure

**New:**
- `plugins/agentic-sdd/agents/qa-visual.md` — the visual-QA agent (built with a token-frugal return contract from the start).
- `plugins/agentic-sdd/commands/qa.md` — the `/qa [flow]` command; delegates to `qa-visual`.
- `plugins/agentic-sdd/skills/visual-qa/SKILL.md` — capture-by-stack table + inspection checklist + report format.

**Modified:**
- `plugins/agentic-sdd/commands/feature.md` — insert the QA (visual) phase; add token-frugal orchestration note.
- `plugins/agentic-sdd/hooks/scripts/session-start.sh` — add `/qa` to the flow line.
- `.gitignore` — ignore the screenshot output dir.
- `CLAUDE.md` — agents/commands/skills tables, flow diagram, happy-path line.
- `README.md` — agent/command counts + lists + flow line.
- `plugins/agentic-sdd/.claude-plugin/plugin.json` — version bump.
- Lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `curator`, `refactorer`, `cicd-engineer`) — add/tighten return-to-caller clause. (`implementer`, `e2e-tester`, `code-reviewer` already have one — verify only.)

---

### Task 1: `qa-visual` agent

**Files:**
- Create: `plugins/agentic-sdd/agents/qa-visual.md`

**Interfaces:**
- Produces: agent named `qa-visual` (used by `commands/qa.md`, `commands/feature.md`, `CLAUDE.md`, `README.md`). Report severities: **Blocking / Should-fix / Nit** (same vocabulary as `code-reviewer`). Return contract: text findings + screenshot paths only, never image contents.
- Consumes: the stack's E2E capture tools already documented in the `e2e-testing` skill (Playwright / Detox-Maestro / Appium-Avalonia.Headless).

- [ ] **Step 1: Write the verification (must fail before the file exists)**

Run: `test -f plugins/agentic-sdd/agents/qa-visual.md && head -1 plugins/agentic-sdd/agents/qa-visual.md | grep -q '^---' && echo PASS || echo FAIL`
Expected: `FAIL`

- [ ] **Step 2: Create the agent file**

Create `plugins/agentic-sdd/agents/qa-visual.md` with exactly:

```markdown
---
name: qa-visual
description: Use after a user-facing flow is implemented and functionally green, to catch VISUAL bugs that functional/E2E tests miss — broken layout, overflow/clipping, misalignment, bad spacing, low contrast, truncated text, unloaded images, wrong theme. Drives the running app, captures screenshots, and inspects them by eye. Trigger on "qa", "visual", "visual bug", "UI check", "looks wrong", "visual QA". En español — "qa", "visual", "revisión visual", "bug visual", "se ve mal".
tools: Read, Write, Grep, Glob, Bash
model: sonnet
---

You are a visual QA engineer. Functional and E2E tests already pass — your job is the thing they can't see: **does the rendered UI actually look right?** You drive the app, capture screenshots, and inspect them.

## Capture the UI (reuse the stack's E2E driver)
Pick the same tool `e2e-tester` uses for the stack; you are capturing images, not asserting behavior:
- **Next.js / React (web):** Playwright — navigate each route/state and `page.screenshot()`.
- **React Native:** Detox / Maestro device or simulator screenshots.
- **Avalonia desktop (XAML):** Appium screenshots, or `Avalonia.Headless` render-to-bitmap for fast in-memory captures.
- **.NET web / Blazor:** Playwright for .NET.

Save captures to a gitignored dir (`.qa-visual/`). Capture the states people forget: **loading, empty, error, long-text, and narrow + wide breakpoints** — not just the happy path.

## Process
1. Read the spec's user-facing `AC-n` and any references in `docs/design/`.
2. Launch the running app; drive each in-scope flow and capture the screenshots above.
3. `Read` each PNG and inspect it for: broken/overlapping layout, overflow or clipping, misalignment and inconsistent spacing, low color contrast, truncated or wrapped text, unloaded images/icons, wrong light/dark theme, and mismatch with the design reference.
4. Report findings grouped by severity, each tied to an `AC-n` and its screenshot path.
5. Hand confirmed defects to `implementer` (+ the stack expert) to fix, then **re-capture and re-inspect until clean**. This loop is what replaces manual eyeballing.

## Output format
Group findings by severity:
- **Blocking** — unusable or clearly broken UI (overlapping controls, off-screen content, unreadable contrast, missing critical element).
- **Should-fix** — visibly wrong but usable (misalignment, inconsistent spacing, minor truncation).
- **Nit / optional** — polish (pixel nudges, subtle color/spacing preferences).

For each: `AC-n`, screenshot path, what looks wrong, and a concrete fix. End with a verdict (Pass / Pass-with-nits / Fail) and hand off to `implementer` for Blocking + Should-fix.

## Rules
- You verify appearance, not behavior — don't duplicate E2E assertions.
- Never weaken or delete a functional test to make a visual issue go away.
- **Return to the caller:** the verdict, the grouped findings (each with `AC-n` + screenshot path), and the screenshots directory — **never the image contents** (you `Read` PNGs only inside your own context; images are token-heavy and must not reach the orchestrator). Hand off to `implementer`.
```

- [ ] **Step 3: Run the verification to confirm it passes**

Run: `test -f plugins/agentic-sdd/agents/qa-visual.md && head -1 plugins/agentic-sdd/agents/qa-visual.md | grep -q '^---' && echo PASS || echo FAIL`
Expected: `PASS`

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/agents/qa-visual.md
git commit -m "feat(agents): add qa-visual agent for agent-driven visual QA" \
  -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `visual-qa` skill

**Files:**
- Create: `plugins/agentic-sdd/skills/visual-qa/SKILL.md`

**Interfaces:**
- Produces: skill named `visual-qa` (referenced by `commands/qa.md`, `commands/feature.md`, `CLAUDE.md` skills table).
- Consumes: nothing new; mirrors the shape of `skills/e2e-testing/SKILL.md`.

- [ ] **Step 1: Write the verification (must fail)**

Run: `test -f plugins/agentic-sdd/skills/visual-qa/SKILL.md && echo PASS || echo FAIL`
Expected: `FAIL`

- [ ] **Step 2: Create the skill file**

Create `plugins/agentic-sdd/skills/visual-qa/SKILL.md` with exactly:

```markdown
---
name: visual-qa
description: Use when checking that an implemented UI actually looks right — catching visual bugs (layout, overflow, spacing, contrast, truncation, theme) that functional and E2E tests miss. Drive the app, capture screenshots, inspect them. Trigger on "visual qa", "visual bug", "UI check", "looks wrong", or before shipping a user-facing flow.
---

# Visual QA

Functional/E2E tests prove the UI *works*; visual QA proves it *looks right*. Capture screenshots of the real rendered UI and inspect them — don't re-assert behavior.

## Capture the UI by stack
| Stack | Capture tool | Notes |
|---|---|---|
| Next.js / React web | **Playwright** `page.screenshot()` | Per route + state + breakpoint |
| React Native | **Detox** / **Maestro** | Simulator/device screenshots |
| Avalonia desktop (XAML) | **Appium** or **Avalonia.Headless** render-to-bitmap | Headless is fast for in-memory captures |
| .NET web / Blazor | **Playwright for .NET** | Native Apple Silicon |

Save captures to a gitignored dir (`.qa-visual/`). Reuse the stack's E2E harness — you are capturing images, not asserting behavior.

## Capture these states (not just the happy path)
Loading · empty · error · long-text/overflow · narrow **and** wide breakpoints · light **and** dark theme.

## Inspection checklist (read each screenshot for)
- Broken or overlapping layout; content off-screen.
- Overflow / clipping; text truncated or wrapping badly.
- Misalignment; inconsistent spacing/padding.
- Low color contrast (WCAG AA); unreadable text.
- Unloaded images/icons; wrong or missing theme.
- Mismatch with the design reference in `docs/design/`.

## Report format
Group findings **Blocking / Should-fix / Nit**, each tied to an `AC-n` and its screenshot path, with a concrete fix. End with a verdict (Pass / Pass-with-nits / Fail). Hand Blocking + Should-fix to `implementer`, then re-capture and re-inspect until clean.

## Token discipline
`Read` PNGs only inside the QA agent's own context; return **text findings + screenshot paths** to the caller, never the images.
```

- [ ] **Step 3: Run the verification to confirm it passes**

Run: `test -f plugins/agentic-sdd/skills/visual-qa/SKILL.md && head -1 plugins/agentic-sdd/skills/visual-qa/SKILL.md | grep -q '^---' && echo PASS || echo FAIL`
Expected: `PASS`

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/skills/visual-qa/SKILL.md
git commit -m "feat(skills): add visual-qa skill (capture-by-stack + inspection checklist)" \
  -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `/qa` command

**Files:**
- Create: `plugins/agentic-sdd/commands/qa.md`

**Interfaces:**
- Consumes: agent `qa-visual` (Task 1), skill `visual-qa` (Task 2).
- Produces: command `/qa` (referenced by `CLAUDE.md`, `README.md`).

- [ ] **Step 1: Write the verification (must fail)**

Run: `test -f plugins/agentic-sdd/commands/qa.md && echo PASS || echo FAIL`
Expected: `FAIL`

- [ ] **Step 2: Create the command file**

Create `plugins/agentic-sdd/commands/qa.md` with exactly (mirrors the `/e2e` command shape):

```markdown
---
description: Visually QA a user-facing flow — capture screenshots and catch visual bugs functional tests miss.
argument-hint: <user flow or screen>
allowed-tools: Read, Write, Grep, Glob, Bash
model: sonnet
---

Invoke the `qa-visual` agent for: **$ARGUMENTS**

Follow the `visual-qa` skill. Capture screenshots with the stack's E2E driver (Playwright for web, Detox/Maestro for React Native, Appium/Avalonia.Headless for desktop) across the states people forget — loading, empty, error, long-text, narrow + wide breakpoints, light + dark theme — then read each screenshot and report visual defects grouped Blocking / Should-fix / Nit, each tied to an `AC-n` and its screenshot path. Hand Blocking + Should-fix to the `implementer`, then re-inspect until clean. Return findings + screenshot paths only — never the images.
```

- [ ] **Step 3: Run the verification to confirm it passes**

Run: `test -f plugins/agentic-sdd/commands/qa.md && head -1 plugins/agentic-sdd/commands/qa.md | grep -q '^---' && echo PASS || echo FAIL`
Expected: `PASS`

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/commands/qa.md
git commit -m "feat(commands): add /qa command delegating to qa-visual" \
  -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Wire QA into `/feature` + gitignore

**Files:**
- Modify: `plugins/agentic-sdd/commands/feature.md`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: agent `qa-visual`, phase label **QA (visual)**.

- [ ] **Step 1: Write the verification (must fail)**

Run: `grep -q 'qa-visual' plugins/agentic-sdd/commands/feature.md && echo PASS || echo FAIL`
Expected: `FAIL`

- [ ] **Step 2: Insert the QA phase in feature.md**

In `plugins/agentic-sdd/commands/feature.md`, find the E2E step:

```markdown
6. **E2E:** invoke `e2e-tester` for criteria marked (E2E).
7. **Review:** invoke `code-reviewer`; address Blocking + Should-fix.
```

Replace it with (renumbering the remaining steps by +1):

```markdown
6. **E2E:** invoke `e2e-tester` for criteria marked (E2E).
7. **QA (visual):** invoke `qa-visual` to capture screenshots of the user-facing flows and catch visual bugs (layout, overflow, spacing, contrast, theme). Fix Blocking + Should-fix via `implementer`, then re-inspect until clean. Skip for non-UI changes.
8. **Review:** invoke `code-reviewer`; address Blocking + Should-fix.
```

Then renumber the subsequent steps in that list: Curate `8→9`, Describe `9→10`, Verify `10→11`.

- [ ] **Step 3: Add a token-frugal orchestration note in feature.md**

In `plugins/agentic-sdd/commands/feature.md`, find the final line:

```markdown
Never write production code before a failing test exists. Never weaken a test to make it pass.
```

Replace it with:

```markdown
Never write production code before a failing test exists. Never weaken a test to make it pass.

**Keep the loop token-frugal:** each subagent returns a compact summary (file paths + `AC-n` ids + verdict/counts), not full file contents, diffs, or run logs. Pass those paths/ids between phases; don't re-echo a subagent's output into this thread. The `qa-visual` phase returns findings + screenshot paths only — never the screenshots.
```

- [ ] **Step 4: Ignore the screenshot output dir**

In `.gitignore`, after the `coverage/` line, add:

```
.qa-visual/
```

- [ ] **Step 5: Run the verifications to confirm they pass**

Run:
```bash
grep -q 'qa-visual' plugins/agentic-sdd/commands/feature.md \
  && grep -q '^7. \*\*QA (visual):\*\*' plugins/agentic-sdd/commands/feature.md \
  && grep -q '^\.qa-visual/$' .gitignore \
  && grep -q 'token-frugal' plugins/agentic-sdd/commands/feature.md \
  && echo PASS || echo FAIL
```
Expected: `PASS`

- [ ] **Step 6: Commit**

```bash
git add plugins/agentic-sdd/commands/feature.md .gitignore
git commit -m "feat(feature): insert QA (visual) phase between E2E and Review" \
  -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Documentation consistency (CLAUDE.md, README, session-start, plugin.json)

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `plugins/agentic-sdd/hooks/scripts/session-start.sh`
- Modify: `plugins/agentic-sdd/.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: `qa-visual`, `/qa`, `visual-qa`, phase label **QA (visual)** — all must appear consistently.

- [ ] **Step 1: Write the verification (must fail)**

Run: `grep -q '/qa' CLAUDE.md && grep -q '/qa' README.md && echo PASS || echo FAIL`
Expected: `FAIL`

- [ ] **Step 2: Update the CLAUDE.md flow diagram**

In `CLAUDE.md`, find the fenced flow block:

```
/plan → /spec → /tdd → /implement → /e2e → /review → /curate → /update-pr → /ship
design  spec    RED     GREEN+refac   E2E    review   curate     PR desc      ship gate
(opt)  (truth) (tests) (clean code)  (flows)         (conv.)     (describe)
```

Replace it with:

```
/plan → /spec → /tdd → /implement → /e2e → /qa → /review → /curate → /update-pr → /ship
design  spec    RED     GREEN+refac   E2E    QA    review   curate     PR desc      ship gate
(opt)  (truth) (tests) (clean code)  (flows) (visual)       (conv.)     (describe)
```

- [ ] **Step 3: Update the CLAUDE.md commands table**

In `CLAUDE.md`, find the `/e2e` command-table row:

```
| `/e2e <flow>` | Reliable end-to-end / integration tests | `e2e-tester` |
```

Insert immediately after it:

```
| `/qa [flow]` | Visual QA — captures screenshots and catches visual bugs functional tests miss | `qa-visual` |
```

- [ ] **Step 4: Update the CLAUDE.md lifecycle agents table**

In `CLAUDE.md`, find the `e2e-tester` row in the lifecycle-agents table:

```
| `e2e-tester` | Picks the right E2E tool per stack; hermetic, parallel-safe flows | E2E test files |
```

Insert immediately after it:

```
| `qa-visual` | Drives the app, screenshots user-facing flows, and inspects them for visual bugs | QA report (findings + screenshot paths) |
```

- [ ] **Step 5: Update the CLAUDE.md skills table**

In `CLAUDE.md`, find the `e2e-testing` skills-table row:

```
| `e2e-testing` | Adding E2E/integration tests — tool selection + reliability rules |
```

Insert immediately after it:

```
| `visual-qa` | Visually QA a UI — capture-by-stack + inspection checklist + report format |
```

- [ ] **Step 6: Update the README counts, lists, and flow**

In `README.md` line 13, change `**20 agents** — 9 lifecycle agents (` to `**21 agents** — 10 lifecycle agents (` and insert `` `qa-visual`, `` immediately before `` `cicd-engineer`) `` in that lifecycle list.

In `README.md` line 14, change `**14 commands** — ` to `**15 commands** — ` and insert `` `/qa`, `` immediately after `` `/e2e`, `` in the command list.

In `README.md` line 118, change the flow line to:

```
/plan → /spec → /tdd (RED) → /implement (GREEN + refactor) → /e2e → /qa → /review → /curate → /update-pr → /ship
```

- [ ] **Step 7: Update session-start.sh flow line**

In `plugins/agentic-sdd/hooks/scripts/session-start.sh`, find:

```
Flujo: /plan (diseño) -> /spec -> /tdd (RED) -> /implement (GREEN+refactor) -> /e2e -> /review -> /curate -> /ship.
```

Replace `-> /e2e -> /review` with `-> /e2e -> /qa (visual) -> /review` so the line reads:

```
Flujo: /plan (diseño) -> /spec -> /tdd (RED) -> /implement (GREEN+refactor) -> /e2e -> /qa (visual) -> /review -> /curate -> /ship.
```

- [ ] **Step 8: Bump plugin version**

In `plugins/agentic-sdd/.claude-plugin/plugin.json`, change `"version": "1.0.0",` to `"version": "1.1.0",`.

- [ ] **Step 9: Verify shell still valid and refs consistent**

Run:
```bash
bash -n plugins/agentic-sdd/hooks/scripts/session-start.sh \
  && python3 -c "import json; json.load(open('plugins/agentic-sdd/.claude-plugin/plugin.json'))" \
  && grep -q '/qa' CLAUDE.md && grep -q 'qa-visual' CLAUDE.md \
  && grep -q '21 agents' README.md && grep -q '15 commands' README.md \
  && grep -q '/qa (visual)' plugins/agentic-sdd/hooks/scripts/session-start.sh \
  && echo PASS || echo FAIL
```
Expected: `PASS`

- [ ] **Step 10: Commit**

```bash
git add CLAUDE.md README.md plugins/agentic-sdd/hooks/scripts/session-start.sh plugins/agentic-sdd/.claude-plugin/plugin.json
git commit -m "docs: reflect qa-visual + /qa across CLAUDE.md, README, session-start" \
  -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Token-frugal return contracts on lifecycle agents

**Files:**
- Modify: `plugins/agentic-sdd/agents/architect.md`
- Modify: `plugins/agentic-sdd/agents/spec-writer.md`
- Modify: `plugins/agentic-sdd/agents/tdd-test-writer.md`
- Modify: `plugins/agentic-sdd/agents/curator.md`
- Modify: `plugins/agentic-sdd/agents/refactorer.md`
- Modify: `plugins/agentic-sdd/agents/cicd-engineer.md`

**Interfaces:**
- Consumes: nothing. `implementer`, `e2e-tester`, `code-reviewer`, and the new `qa-visual` already carry a compact-return clause — do NOT edit those; this task only fills the gap.

- [ ] **Step 1: Confirm which lifecycle agents lack a return clause (the failing check)**

Run:
```bash
grep -Li 'return to the caller\|return findings compactly\|return .* compact' \
  plugins/agentic-sdd/agents/architect.md \
  plugins/agentic-sdd/agents/spec-writer.md \
  plugins/agentic-sdd/agents/tdd-test-writer.md \
  plugins/agentic-sdd/agents/curator.md \
  plugins/agentic-sdd/agents/refactorer.md \
  plugins/agentic-sdd/agents/cicd-engineer.md
```
Expected: lists the files still missing a clause (the ones to fix in Step 2). If a file is already compliant, skip it in Step 2.

- [ ] **Step 2: Append the tailored return clause to each agent**

For each agent below, add the clause as the final bullet of its last section (create a short `## Handoff` section at end of file if there's no natural bullet list). Use these exact lines:

`architect.md`:
```markdown
- **Return to the caller:** the design/ADR file paths, the key decisions (one line each), and the open risks — not the full document body (it's on disk). Hand off to `spec-writer`.
```

`spec-writer.md`:
```markdown
- **Return to the caller:** the spec file path and the numbered `AC-n` list (ids + one line each) — not the full spec prose. Hand off to `tdd-test-writer`.
```

`tdd-test-writer.md`:
```markdown
- **Return to the caller:** the test file paths, the `AC-n`→test mapping, and the failing-run summary (counts + first failure line) — not full test source or run logs. Hand off to `implementer`.
```

`curator.md`:
```markdown
- **Return to the caller:** the conventions/rule file paths and a one-line summary of what was added or changed — not the full artifact bodies.
```

`refactorer.md`:
```markdown
- **Return to the caller:** files changed (paths), what improved (one line each), and the green-test confirmation (counts) — not the full diff.
```

`cicd-engineer.md`:
```markdown
- **Return to the caller:** the workflow file path(s) and the pipeline shape (jobs/stages, one line each) — not the full YAML.
```

- [ ] **Step 3: Verify every lifecycle agent now carries a return clause**

Run:
```bash
missing=$(grep -Li 'return to the caller\|return findings compactly\|return .* compact' \
  plugins/agentic-sdd/agents/architect.md \
  plugins/agentic-sdd/agents/spec-writer.md \
  plugins/agentic-sdd/agents/tdd-test-writer.md \
  plugins/agentic-sdd/agents/implementer.md \
  plugins/agentic-sdd/agents/e2e-tester.md \
  plugins/agentic-sdd/agents/qa-visual.md \
  plugins/agentic-sdd/agents/code-reviewer.md \
  plugins/agentic-sdd/agents/curator.md \
  plugins/agentic-sdd/agents/refactorer.md \
  plugins/agentic-sdd/agents/cicd-engineer.md)
[ -z "$missing" ] && echo PASS || { echo "MISSING: $missing"; echo FAIL; }
```
Expected: `PASS`

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/agents/architect.md plugins/agentic-sdd/agents/spec-writer.md \
  plugins/agentic-sdd/agents/tdd-test-writer.md plugins/agentic-sdd/agents/curator.md \
  plugins/agentic-sdd/agents/refactorer.md plugins/agentic-sdd/agents/cicd-engineer.md
git commit -m "refactor(agents): tighten return-to-caller contracts on lifecycle agents" \
  -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Whole-plugin validation (mirror the CI locally)

**Files:** none (verification only).

- [ ] **Step 1: Run the plugin CI's structural checks locally**

Run:
```bash
# frontmatter present on every agent/command/skill
for f in plugins/agentic-sdd/agents/*.md plugins/agentic-sdd/commands/*.md plugins/agentic-sdd/skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---' || { echo "MISSING frontmatter: $f"; exit 1; }
done
echo "frontmatter ok"
# JSON manifests parse
for f in .claude-plugin/marketplace.json plugins/agentic-sdd/.claude-plugin/plugin.json \
         plugins/agentic-sdd/hooks/hooks.json plugins/agentic-sdd/settings.template.json; do
  python3 -c "import json; json.load(open('$f'))" && echo "ok  $f"
done
# hook scripts valid shell
for f in plugins/agentic-sdd/hooks/scripts/*.sh scripts/install.sh; do bash -n "$f" && echo "ok  $f"; done
```
Expected: `frontmatter ok`, every `ok <file>`, no errors.

- [ ] **Step 2: Confirm the copy installer picks up the new assets**

Run:
```bash
TMP="$(mktemp -d)/app"; mkdir -p "$TMP"; echo '{"scripts":{}}' > "$TMP/package.json"
bash scripts/install.sh "$TMP" >/dev/null
test -f "$TMP/.claude/agents/qa-visual.md" \
  && test -f "$TMP/.claude/commands/qa.md" \
  && test -f "$TMP/.claude/skills/visual-qa/SKILL.md" \
  && echo PASS || echo FAIL
rm -rf "$TMP"
```
Expected: `PASS`

- [ ] **Step 3: Final flow-consistency sweep**

Run:
```bash
for f in plugins/agentic-sdd/commands/feature.md CLAUDE.md README.md \
         plugins/agentic-sdd/hooks/scripts/session-start.sh; do
  grep -q 'qa' "$f" && echo "ok  $f" || echo "MISSING qa ref: $f"
done
```
Expected: `ok` for all four files.

---

## Self-Review

**Spec coverage:**
- Design Part 1 (qa-visual agent, agent-driven inspection, capture-by-stack, Blocking/Should-fix/Nit, re-inspect loop) → Task 1. ✓
- Flow integration (/qa command, feature.md phase, visual-qa skill, doc updates) → Tasks 2–5. ✓
- Token safety for images (Read inside subagent, return paths only) → Task 1 return clause + Task 4 orchestration note. ✓
- Design Part 2 (return-contract audit, lifecycle agents first, no new rule/model-tiering) → Task 6. ✓
- Non-goals (no visual-regression baselines, no frugality rule file) → respected; no task adds them. ✓

**Placeholder scan:** No TBD/TODO; every file step shows the full literal content; every verification is a runnable command with expected output. ✓

**Type/name consistency:** `qa-visual` (agent), `/qa` (command), `visual-qa` (skill), **QA (visual)** (phase label), Blocking/Should-fix/Nit (severities) used verbatim across every task and verification. Counts: 21 agents / 10 lifecycle / 15 commands consistent between README edits and reality. ✓
