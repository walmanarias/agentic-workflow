# Design — `maui-expert` agent (.NET MAUI + Xamarin.Forms migration)

**Date:** 2026-08-04
**Status:** Approved (design); pending implementation plan

## Goal

Add a stack-expert agent to `agentic-sdd` for **.NET MAUI** cross-platform mobile/desktop work (iOS, Android, Windows, Mac Catalyst), specialized in **migrating legacy Xamarin.Forms apps to MAUI**. Unlike the other stack experts — which mostly write unit tests and hand broad E2E flows to `e2e-tester` — this agent owns the **full test pyramid** (unit, integration, E2E) for the MAUI app it's working on, because validating behavioral parity end-to-end is core to a migration, not a separable concern. `architect` also needs to be able to produce real design briefs for this stack, including migration-shaped ones (current state → target state).

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Agent name | `maui-expert` — matches the `<tech>-expert` naming convention (`avalonia-expert`, `react-native-expert`) |
| Testing ownership | `maui-expert` writes and owns unit + integration + E2E tests itself (explicit deviation from the sibling pattern), while `e2e-tester`/`qa-visual`/the testing skills still gain a MAUI row for discoverability when invoked standalone |
| Migration playbook location | **Dedicated skill** `xamarin-maui-migration` (mirrors `cicd-pipelines` backing `cicd-engineer`) — keeps `maui-expert.md` lean and lets the breaking-change map live in a `references/` file other agents can load |
| New slash command | **No** — no `/migrate-maui`. The agent is invoked the same way other stack experts are: pulled in by `implementer`/`architect`, or called directly ("use the maui-expert agent to…") |
| Scope of doc integration | Thread `maui-expert` through every touchpoint that already threads `avalonia-expert` (the closest precedent: XAML/MVVM, C#, Appium) — agent tables, skill tool-tables, plugin manifests — for parity with how existing stacks were integrated |

## Non-goals (YAGNI / scope guard)

- No new slash command.
- No fix for `plugins/agentic-sdd/README.md`'s existing staleness (it already undercounts agents/skills independent of this change — pre-existing drift, out of scope here).
- No fix for `architect.md`'s persona line only naming the JS/TS stack even though .NET/Avalonia/Django/etc. already exist — out of scope; this change only *adds* MAUI awareness, it doesn't rewrite the agent's framing for every other already-missing stack.
- No Xamarin.Android/Xamarin.iOS (classic, non-Forms) migration guidance — scoped to **Xamarin.Forms → MAUI** specifically, since that's what was asked for.

## Components & file layout

```
plugins/agentic-sdd/
  agents/maui-expert.md                          # NEW
  skills/xamarin-maui-migration/
    SKILL.md                                      # NEW — assessment, strategy, tooling, test-first parity approach
    references/
      breaking-changes-map.md                     # NEW — namespace/API/project-structure/tooling mapping table
```

## Component specs

### `maui-expert` agent (`agents/maui-expert.md`)

Same frontmatter shape as siblings: `tools: Read, Write, Edit, Grep, Glob, Bash`, `model: sonnet`. Description triggers on "MAUI", ".NET MAUI", "Xamarin.Forms", "Xamarin migration", "migrate to MAUI", plus Spanish equivalents; cross-references `dotnet-expert` (ASP.NET Core APIs) and `avalonia-expert` (desktop) so routing stays symmetric — and those two agents' descriptions get a one-line cross-reference back to `maui-expert` for mobile.

Body sections:
1. **Architecture & MVVM** — single-project structure (`Platforms/`, `Resources/`, one multi-targeted `.csproj` for `net8.0-ios/-android/-maccatalyst/-windows`), `MauiProgram.cs` DI (`MauiAppBuilder`), Shell navigation, handlers (not renderers), `CommunityToolkit.Mvvm`. Same MVVM discipline as `avalonia-expert` (Views ↔ ViewModels ↔ injected services).
2. **Xamarin.Forms → MAUI migration** — applies the `xamarin-maui-migration` skill: run an inventory pass first (detect `Xamarin.Forms`/`Xamarin.Essentials` package refs, multi-head project layout) → apply the .NET Upgrade Assistant as a first pass → work through the breaking-change map → migrate incrementally, keeping behavior parity, with tests locking in current behavior before code changes where feasible (same "characterize, then change" discipline as `refactorer`).
3. **UI quality** — platform-specific handling (`OnPlatform`, `DeviceInfo.Platform`), accessibility (`SemanticProperties`), `CollectionView` over legacy `ListView`, Hot Reload for iteration.
4. **Testing (owns the full pyramid)** — xUnit + FluentAssertions for ViewModels/services (unit); DI-resolution and repository/service integration tests (e.g. SQLite via sqlite-net-pcl, HTTP via a fake handler); **Appium** for E2E across iOS/Android/Windows (Microsoft's supported path since Xamarin.UITest's retirement), following the same accessibility-id-driven approach `avalonia-expert` uses.
5. **Process** — detect Xamarin.Forms vs MAUI vs mid-migration state → for migrations, inventory breaking changes first → write/confirm parity tests → migrate/implement → run the full pyramid → report gaps.
6. **Return to the caller** — same compact-summary contract as every other stack expert (files changed + key decisions, no pasted file contents).

### `xamarin-maui-migration` skill (`skills/xamarin-maui-migration/SKILL.md`)

Playbook covering:
- **Assessment**: detect current state (TargetFrameworks, `Xamarin.Forms`/`Xamarin.Essentials`/`Xamarin.CommunityToolkit` package refs, multi-head project layout: iOS/Android/UWP heads + shared/.NET Standard library).
- **Strategy**: incremental vs. big-bang — MAUI's single-project model doesn't support running XF and MAUI side-by-side in one head, so recommend migrating one app/shared-library at a time behind version control, with a characterization-test safety net (lock in current behavior via tests before touching code, per the repo's existing refactor discipline).
- **Tooling**: `dotnet-upgrade-assistant` as the mechanical first pass (project file + namespace rewrites); manual pass for anything it can't handle (renderers, effects, third-party libs).
- **Test-first parity approach**: how the full pyramid (unit/integration/E2E) doubles as a migration safety net — write/confirm characterization tests against the pre-migration app where feasible, keep them green through the migration.
- Pointer to `references/breaking-changes-map.md` for the detailed mapping table.

### `references/breaking-changes-map.md`

A reference table/notes covering: namespace & package mapping (`Xamarin.Forms.*`→`Microsoft.Maui.Controls.*`, `Xamarin.Essentials`→built-in `Microsoft.Maui.ApplicationModel`/`.Devices`/`.Storage`, `Xamarin.CommunityToolkit`→`CommunityToolkit.Maui`), renderers→handlers migration steps, `DependencyService`→constructor DI via `MauiProgram`, Effects→Handlers, project structure (multi-head→single project, `MauiIcon`/`MauiSplashScreen`/`MauiImage`/`MauiFont` replacing per-platform resources), Shell (mostly compatible, notes the differences), and known third-party-library compatibility gotchas (many Xamarin `Plugin.*` packages are unmaintained; check for MAUI-compatible replacements or `CommunityToolkit.Maui` equivalents first).

### `architect.md` updates

- Add ".NET MAUI (mobile)" to the persona's stack-awareness line.
- Add a short mobile-specific consideration bullet under the boundaries/patterns step: offline-first data (local SQLite + sync strategy), platform-abstraction boundary via DI for platform services, app lifecycle/backgrounding.
- Note that a migration-shaped design brief should include a current-state → target-state section, referencing `maui-expert`'s breaking-change map rather than re-deriving it.

## Workflow & docs integration (parity with how `avalonia-expert` was threaded through)

- **`CLAUDE.md`**: top stack line gains ".NET MAUI (cross-platform mobile, incl. Xamarin.Forms migration)"; stack-expert agents table gets a `maui-expert` row; skills table gets an `xamarin-maui-migration` row; repo-layout comment counts bump 21→22 agents, 9→10 skills.
- **`README.md`** (root): stack list, agent count/list (21→22), skill count/list (9→10).
- **`plugins/agentic-sdd/.claude-plugin/plugin.json`**: description mention + keywords (`maui`, `xamarin`, `mobile`).
- **`.claude-plugin/marketplace.json`**: plugin description mention.
- **`agents/e2e-tester.md`**: add a MAUI row to "Choose the tool by stack" (Appium; note `maui-expert` also owns E2E directly for migration work).
- **`agents/qa-visual.md`**: add a MAUI row to "Capture the UI" (Appium screenshots).
- **`agents/dotnet-expert.md`** / **`agents/avalonia-expert.md`**: add the one-line cross-reference to `maui-expert` for mobile, matching their existing cross-references to each other.
- **`commands/qa.md`**: extend the driver list to mention MAUI alongside Avalonia/RN.
- **`skills/stack-testing-recipes/SKILL.md`**: new "## .NET MAUI (mobile)" section (unit/integration/E2E recipe, same shape as the existing Avalonia section).
- **`skills/e2e-testing/SKILL.md`**: MAUI row in the tool table.
- **`skills/e2e-testing/references/dotnet-e2e-setup.md`**: new "## MAUI (Appium + device/simulator)" subsection alongside the existing ASP.NET Core / Avalonia / Blazor ones.
- **`skills/visual-qa/SKILL.md`**: MAUI row in "Capture the UI by stack".
- **`skills/pr-description/SKILL.md`**: add ".NET MAUI" to the parenthetical stack list.
- **`skills/pr-description/references/section-catalog.md`**: append MAUI/Appium to the ".NET integration / E2E" bullet.
- **`skills/tdd-workflow/references/xunit-patterns.md`**: new "## MAUI (unit + integration)" section alongside the existing Avalonia one.

## Testing / validation

Markdown-only deliverable (agent/skill/command config), same as the CI/CD-agent precedent — no runtime code to unit-test. Validation is structural:
- The existing plugin-validation CI (`.github/workflows/ci.yml`) must keep passing: JSON manifests parse, agent/command/skill frontmatter present (`---` on line 1), hook scripts still valid shell, copy installer still runs end-to-end.
- Manually verify the copy installer (`scripts/install.sh`) picks up the two new files (add a spot-check, not a permanent CI assertion, since the existing installer test only spot-checks a couple of representative files).
- Cross-check every file in the "Workflow & docs integration" list actually got touched (this list *is* the checklist).

## Open questions / follow-ups

None blocking. `plugins/agentic-sdd/README.md`'s pre-existing staleness and `architect.md`'s narrow persona framing are noted as explicit non-goals above, not silently left inconsistent.
