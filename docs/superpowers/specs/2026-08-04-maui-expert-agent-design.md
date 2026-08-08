# Design — `maui-expert` agent (.NET MAUI + Xamarin.Forms migration)

**Date:** 2026-08-04
**Status:** Implemented — see `docs/superpowers/plans/2026-08-04-maui-expert-agent.md` and PR #8

## Goal

Add a stack-expert agent to `agentic-sdd` for **.NET MAUI** cross-platform mobile/desktop work (iOS, Android, Windows, Mac Catalyst). This is a **general-purpose MAUI development expert** — capable of writing an application across its **whole lifecycle and development workflow** (scaffolding, feature/screen development, platform integration, release-readiness, maintenance) following industry-standard MAUI/.NET practices — with an added specialty in **migrating legacy Xamarin.Forms apps to MAUI**. Unlike the other stack experts — which mostly write unit tests and hand broad E2E flows to `e2e-tester` — this agent owns the **full test pyramid** (unit, integration, E2E) for the MAUI app it's working on, because validating behavior (through normal development and through a migration) is core to the role, not a separable concern. `architect` also needs to be able to produce real design briefs for this stack, including migration-shaped ones (current state → target state).

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Agent name | `maui-expert` — matches the `<tech>-expert` naming convention (`avalonia-expert`, `react-native-expert`) |
| Scope | **Full-lifecycle MAUI development expert**, not a migration-only specialist — matches the depth of `react-native-expert`/`dotnet-expert` (architecture, platform integration, security, observability, release-readiness), *plus* the Xamarin.Forms migration specialty |
| Testing ownership | `maui-expert` writes and owns unit + integration + E2E tests itself (explicit deviation from the sibling pattern), while `e2e-tester`/`qa-visual`/the testing skills still gain a MAUI row for discoverability when invoked standalone |
| Migration playbook location | **Dedicated skill** `xamarin-maui-migration` (mirrors `cicd-pipelines` backing `cicd-engineer`) — keeps `maui-expert.md` lean and lets the breaking-change map live in a `references/` file other agents can load |
| New slash command | **No** — no `/migrate-maui`. The agent is invoked the same way other stack experts are: pulled in by `implementer`/`architect`, or called directly ("use the maui-expert agent to…") |
| Release/CI boundary | `maui-expert` gets the app to release-ready (icons, splash, manifests, versioning, platform config) but does **not** own the build/signing/store-submission pipeline — that stays `cicd-engineer`'s job, same division of labor it already has with every other stack expert |
| Scope of doc integration | Thread `maui-expert` through every touchpoint that already threads `avalonia-expert` (the closest precedent: XAML/MVVM, C#, Appium) — agent tables, skill tool-tables, plugin manifests — for parity with how existing stacks were integrated |

## Non-goals (YAGNI / scope guard)

- No new slash command.
- `plugins/agentic-sdd/README.md`'s pre-existing staleness was originally scoped out here as unrelated drift, but was fixed during PR #8's review once flagged as directly relevant (its component counts/lists now match reality).
- No fix for `architect.md`'s persona line only naming the JS/TS stack even though .NET/Avalonia/Django/etc. already exist — out of scope; this change only *adds* MAUI awareness, it doesn't rewrite the agent's framing for every other already-missing stack.
- No Xamarin.Android/Xamarin.iOS (classic, non-Forms) migration guidance — scoped to **Xamarin.Forms → MAUI** specifically, since that's what was asked for.
- No build/signing/store-submission pipeline authoring inside `maui-expert` — that's `cicd-engineer`'s job (extended in a follow-up if/when someone asks for MAUI CI/CD specifically; not part of this change, see `cicd-pipelines` skill's existing target table).

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

Same frontmatter shape as siblings: `tools: Read, Write, Edit, Grep, Glob, Bash`, `model: sonnet`. Description triggers on "MAUI", ".NET MAUI", "Xamarin.Forms", "Xamarin migration", "migrate to MAUI", "mobile app" (C#/.NET context), plus Spanish equivalents; cross-references `dotnet-expert` (ASP.NET Core APIs) and `avalonia-expert` (desktop) so routing stays symmetric — and those two agents' descriptions get a one-line cross-reference back to `maui-expert` for mobile.

Body sections (breadth matches `react-native-expert`'s — the closest full-lifecycle mobile-expert precedent — plus the migration specialty):

1. **Architecture & project structure** — single-project structure (`Platforms/`, `Resources/`, one multi-targeted `.csproj` for `net8.0-ios/-android/-maccatalyst/-windows`), `MauiProgram.cs` DI (`MauiAppBuilder`), Shell navigation with typed routes, handlers (not renderers), `CommunityToolkit.Mvvm` (`[ObservableProperty]`/`[RelayCommand]`). Same MVVM discipline as `avalonia-expert` (Views ↔ ViewModels ↔ injected services); feature-first folder layout per `rules/25-structure.md`.
2. **App lifecycle & platform integration** — `ConfigureLifecycleEvents` (foreground/background/state restoration), permissions & entitlements per platform (`Info.plist`, `AndroidManifest.xml`), local/offline data (SQLite via `sqlite-net-pcl` or EF Core, sync strategy), secure storage & credentials (`SecureStorage`, platform Keychain/Keystore, biometric auth), push notifications, deep linking, app configuration per environment, structured logging/telemetry/crash reporting (`Microsoft.Extensions.Logging` + a modern crash-reporting provider — note Xamarin's App Center is retired), semantic versioning (`ApplicationDisplayVersion`/`ApplicationVersion`).
3. **Xamarin.Forms → MAUI migration** — applies the `xamarin-maui-migration` skill: run an inventory pass first (detect `Xamarin.Forms`/`Xamarin.Essentials` package refs, multi-head project layout) → apply the .NET Upgrade Assistant as a first pass → work through the breaking-change map → migrate incrementally, keeping behavior parity, with tests locking in current behavior before code changes where feasible (same "characterize, then change" discipline as `refactorer`).
4. **UI quality & performance** — platform-specific handling (`OnPlatform`, `DeviceInfo.Platform`), accessibility (`SemanticProperties`), `CollectionView`/virtualization over legacy `ListView`, image caching, startup-time and memory considerations, Hot Reload for iteration.
5. **Security** — no secrets in source (use `SecureStorage`/platform keystores), certificate pinning for HTTP where warranted, input validation at service boundaries, dependency vetting (flagging unmaintained Xamarin `Plugin.*` packages) — ties back to `rules/30-security.md`.
6. **Release readiness** — app icons/splash (`MauiIcon`/`MauiSplashScreen`), platform manifests, build/version numbering; hands the actual build/signing/store-submission pipeline to `cicd-engineer` (never runs `dotnet publish`/store uploads itself, mirroring `cicd-engineer`'s own "never deploy" rule).
7. **Testing (owns the full pyramid)** — xUnit + FluentAssertions for ViewModels/services (unit); DI-resolution and repository/service integration tests (e.g. SQLite via sqlite-net-pcl, HTTP via a fake handler); **Appium** for E2E across iOS/Android/Windows (Microsoft's supported path since Xamarin.UITest's retirement), following the same accessibility-id-driven approach `avalonia-expert` uses.
8. **Process** — detect greenfield vs. brownfield vs. mid-migration state → for migrations, inventory breaking changes first (via the `xamarin-maui-migration` skill) → write/confirm tests first → implement/migrate → run the full pyramid → report gaps.
9. **Return to the caller** — same compact-summary contract as every other stack expert (files changed + key decisions, no pasted file contents).

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
- Note that a migration-shaped design brief should include a current-state → target-state section, referencing the `xamarin-maui-migration` skill's breaking-change map rather than re-deriving it.

## Workflow & docs integration (parity with how `avalonia-expert` was threaded through)

- **`CLAUDE.md`**: top stack line gains ".NET MAUI (cross-platform mobile, incl. Xamarin.Forms migration)"; stack-expert agents table gets a `maui-expert` row; skills table gets an `xamarin-maui-migration` row; repo-layout comment counts bump 21→22 agents, 9→10 skills.
- **`README.md`** (root): stack list, agent count/list (21→22), skill count/list (9→10).
- **`plugins/agentic-sdd/.claude-plugin/plugin.json`**: description mention + keywords (`maui`, `xamarin`, `mobile`).
- **`.claude-plugin/marketplace.json`**: plugin description mention.
- **`agents/e2e-tester.md`**: add a MAUI row to "Choose the tool by stack" (Appium; note `maui-expert` also owns E2E directly as part of its full-pyramid testing responsibility).
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

None blocking. `plugins/agentic-sdd/README.md`'s pre-existing staleness was fixed during PR #8's review (see the non-goals note above); `architect.md`'s narrow persona framing remains an explicit non-goal, not silently left inconsistent.
