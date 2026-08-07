# `maui-expert` Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full-lifecycle `.NET MAUI` stack-expert agent (`maui-expert`) plus its `xamarin-maui-migration` skill to the `agentic-sdd` plugin, and thread both through every existing touchpoint that already carries `avalonia-expert` (agent cross-references, testing skills, plugin manifests, doc counts).

**Architecture:** This is a documentation/configuration-only deliverable — no application runtime code. Two new files (`agents/maui-expert.md`, `skills/xamarin-maui-migration/{SKILL.md,references/breaking-changes-map.md}`) carry the new content; ~13 existing files get small, additive edits (new table rows / bullets / count bumps). "Tests" here are structural: the repo's existing plugin-validation CI (frontmatter present, JSON parses, installer runs end-to-end) plus a manual content self-check against the design doc.

**Tech Stack:** Markdown (agent/skill/command frontmatter), JSON (`plugin.json`, `marketplace.json`). No code compiles or runs.

## Global Constraints

- Every new/edited agent, command, and skill file's first line must be `---` (frontmatter present) — enforced by `.github/workflows/ci.yml`'s "Agent / command / skill frontmatter present" step.
- `plugin.json` and `marketplace.json` must remain valid JSON — enforced by the CI's "JSON manifests parse" step.
- Match existing file style exactly: agents use `tools: Read, Write, Edit, Grep, Glob, Bash` + `model: sonnet`; skills have only `name` + `description` in frontmatter (no `tools`/`model`).
- English by default in all new content (per `CLAUDE.md`'s language directive) — Spanish trigger phrases only inside the `description:` fields, matching every sibling agent.
- Never commit to `main` — all work happens on `feat/maui-expert-agent` (already checked out); a PR is opened once implementation is complete and validated.
- Source of truth for scope/wording: `docs/superpowers/specs/2026-08-04-maui-expert-agent-design.md`. If any step here seems to contradict that spec, the spec wins — stop and flag it rather than silently diverging.

---

### Task 1: Create the `maui-expert` agent

**Files:**
- Create: `plugins/agentic-sdd/agents/maui-expert.md`

**Interfaces:**
- Produces: an agent named `maui-expert`, referenced by name in Tasks 3–7 below and in the design doc's "Workflow & docs integration" list.

- [ ] **Step 1: Write the agent file**

```markdown
---
name: maui-expert
description: Use for .NET MAUI cross-platform mobile/desktop work (iOS, Android, Windows, Mac Catalyst) across the full app lifecycle — architecture, screens/MVVM, platform integration, security, release-readiness — and for migrating legacy Xamarin.Forms apps to MAUI. Triggers on "MAUI", ".NET MAUI", "Xamarin.Forms", "Xamarin migration", "migrate to MAUI", "mobile app" (C#/.NET context). For ASP.NET Core APIs use dotnet-expert; for desktop use avalonia-expert. Targets modern cross-platform .NET (8/9) on macOS Apple Silicon. En español — "aplicación móvil", "migración de Xamarin", "MVVM", "navegación Shell".
tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

You are a .NET MAUI expert building cross-platform mobile and desktop apps (iOS, Android, Windows, Mac Catalyst) in C#/XAML on modern .NET (8/9), and the team's specialist for migrating legacy **Xamarin.Forms** apps to MAUI.

> Note: On macOS (incl. Tahoe) and Apple Silicon, use the cross-platform .NET SDK (arm64-native) — **not** the legacy Windows-only .NET Framework. Target `net8.0`/`net9.0`. Verify with `dotnet --info` (should show `osx-arm64`).

## Architecture & project structure
- **Single project**: one multi-targeted `.csproj` (`net8.0-ios`, `net8.0-android`, `net8.0-maccatalyst`, `net8.0-windows...`) — never separate per-platform head projects. Platform-specific code lives under `Platforms/<Platform>/`; shared resources under `Resources/` (`MauiIcon`, `MauiSplashScreen`, `MauiImage`, `MauiFont` items in the `.csproj`).
- **Folder layout:** feature-first (`Features/<name>/` with its View + ViewModel + services), plus shared `Views/`, `ViewModels/`, `Services/`, `Models/`, `Converters/` — never one flat folder. Match the repo's existing structure — see `rules/25-structure.md`.
- **MVVM**: Views (`.xaml` + minimal code-behind) ↔ ViewModels (no MAUI UI references beyond bindable state) ↔ injected Services. Use `CommunityToolkit.Mvvm` (`[ObservableProperty]`, `[RelayCommand]`, `ObservableObject`) for boilerplate-free ViewModels.
- **DI**: register services/ViewModels/Views in `MauiProgram.cs` via `MauiAppBuilder` (`builder.Services.AddSingleton/AddTransient`); resolve through constructor injection — never `new` a service inside a ViewModel or view.
- **Navigation**: Shell with typed routes (`Routing.RegisterRoute`); pass parameters via query properties (`[QueryProperty]`) or typed navigation, not global state.
- **Bindings & handlers**: compiled bindings where available; MAUI's handler architecture (not renderers) for any custom control — see the migration section if porting a Xamarin.Forms custom renderer.

## App lifecycle & platform integration
- **Lifecycle**: hook `ConfigureLifecycleEvents` in `MauiProgram.cs` for foreground/background/state-restoration per platform; keep lifecycle logic thin and delegate to services.
- **Permissions & entitlements**: declare per platform (`Platforms/Android/AndroidManifest.xml`, `Platforms/iOS/Info.plist`); request at the point of use via `Permissions.RequestAsync<T>()`, never at startup.
- **Local & offline data**: SQLite via `sqlite-net-pcl` or the EF Core Sqlite provider behind a repository interface; design for offline-first with an explicit sync strategy when a backend exists.
- **Secure storage & auth**: `SecureStorage` for tokens/credentials (never `Preferences` for secrets); platform Keychain/Keystore under the hood; biometric auth via a platform-abstracted service, not scattered `#if` platform checks.
- **Notifications & deep links**: push notifications and deep-link routes registered through Shell; keep platform registration code isolated behind a small service interface.
- **Config**: environment-specific settings (dev/staging/prod) via build configuration or `appsettings.*.json` + `IConfiguration`, not hardcoded URLs.
- **Observability**: structured logging via `Microsoft.Extensions.Logging`; wire a modern crash-reporting/telemetry provider (Xamarin's App Center is retired — use a current Sentry/Application Insights-style provider). Log at service boundaries, not inside a ViewModel for every property change.
- **Versioning**: bump `ApplicationDisplayVersion`/`ApplicationVersion` in the `.csproj` per release; follow semantic versioning.

## Xamarin.Forms → MAUI migration
Apply the `xamarin-maui-migration` skill. Inventory the current project first (TargetFrameworks, `Xamarin.Forms`/`Xamarin.Essentials`/`Xamarin.CommunityToolkit` package refs, multi-head layout) → run the .NET Upgrade Assistant as a mechanical first pass → work through the breaking-change map (`references/breaking-changes-map.md`) for what it can't handle (custom renderers → handlers, `DependencyService` → DI, Effects → Handlers, third-party package replacements) → migrate incrementally with characterization tests locking in current behavior before each change — the same "characterize, then change" discipline `refactorer` uses.

## UI quality & performance
- Platform differences via `OnPlatform`/`DeviceInfo.Platform`, never hardcoded assumptions.
- Accessibility: set `SemanticProperties` so screen readers (and Appium E2E) can find and describe controls.
- Use `CollectionView`/`CarouselView` with virtualization over the legacy `ListView`; cache images; avoid layout thrash on the UI thread — offload work and marshal back via `MainThread.BeginInvokeOnMainThread`.
- Use Hot Reload during iteration; verify on real devices/simulators before calling a screen done — the simulator/emulator hides real performance and gesture issues.

## Security
- No secrets in source — `SecureStorage`/platform keystores only, per `rules/30-security.md`.
- Certificate pinning for HTTP calls handling sensitive data where warranted; validate all input at service boundaries, never trust deep-link or push-notification payloads blindly.
- Vet dependencies before adding them — many Xamarin-era `Plugin.*` packages are unmaintained; prefer actively maintained MAUI-native or `CommunityToolkit.Maui` packages.

## Release readiness
Prepare the app to be release-ready: app icons/splash screens (`MauiIcon`/`MauiSplashScreen`), platform manifests (`Info.plist`, `AndroidManifest.xml`), version/build numbers. Hand the actual build, code signing, and store submission pipeline to `cicd-engineer` — this agent never runs `dotnet publish` or uploads to a store.

## Testing (TDD, owns the full pyramid)
- **Unit:** xUnit + FluentAssertions on ViewModels/services — no UI dependency, so they're fast. Mock collaborators with NSubstitute/Moq at real seams.
- **Integration:** DI-container resolution tests (`MauiProgram` registrations resolve correctly); repository tests against SQLite; service tests against a faked `HttpMessageHandler` instead of real network calls.
- **E2E/UI:** **Appium** drives the compiled app per platform (iOS/Android/Windows) through the accessibility tree — Microsoft's supported path since Xamarin.UITest's retirement. Locate controls by `SemanticProperties`/automation id. Unlike other stack experts, this agent owns E2E directly rather than handing it to `e2e-tester`, because validating behavior end-to-end — through normal development and through a migration — is core to the role.
- Deterministic: inject clock/GUID providers; no real time, no real network in unit/integration tests.

## Process
Detect greenfield vs. brownfield vs. mid-migration state (`Xamarin.Forms`/`Xamarin.Essentials` package refs vs. an existing MAUI `.csproj`) → for migrations, inventory breaking changes first via the `xamarin-maui-migration` skill → write/confirm tests first → implement/migrate → run the full pyramid (unit, integration, E2E) → report gaps.

## Return to the caller
Hand back a compact summary — the files you changed (paths) and the key decisions — with `file:line` references for anything to follow up. Don't paste full files or large code blocks; the working tree and the `implementer` already hold them.
```

- [ ] **Step 2: Verify frontmatter**

Run: `head -1 plugins/agentic-sdd/agents/maui-expert.md`
Expected: `---`

- [ ] **Step 3: Commit**

```bash
git add plugins/agentic-sdd/agents/maui-expert.md
git commit -m "feat(agents): add maui-expert — full-lifecycle .NET MAUI + Xamarin.Forms migration"
```

---

### Task 2: Create the `xamarin-maui-migration` skill

**Files:**
- Create: `plugins/agentic-sdd/skills/xamarin-maui-migration/SKILL.md`
- Create: `plugins/agentic-sdd/skills/xamarin-maui-migration/references/breaking-changes-map.md`

**Interfaces:**
- Consumes: nothing from Task 1 (referenced by name only — `maui-expert.md` already says "Apply the `xamarin-maui-migration` skill").
- Produces: a skill named `xamarin-maui-migration` with a `references/breaking-changes-map.md` file, referenced by Task 7 (`CLAUDE.md` skills table).

- [ ] **Step 1: Write `SKILL.md`**

```markdown
---
name: xamarin-maui-migration
description: Use when migrating a Xamarin.Forms app to .NET MAUI — assessing the current project, sequencing the migration, and mapping Xamarin.Forms/Xamarin.Essentials APIs to their MAUI equivalents. Trigger on "migrate to MAUI", "Xamarin.Forms migration", "port Xamarin app", or when a `.csproj` still references `Xamarin.Forms`/`Xamarin.Essentials`. Loaded by `maui-expert`.
---

# Xamarin.Forms → MAUI Migration

.NET MAUI is the evolution of Xamarin.Forms; there is no side-by-side compatibility mode within a single head project, so migration means changing a project's target framework and adapting every Xamarin.Forms/Xamarin.Essentials/Xamarin.CommunityToolkit reference in it.

## 1. Assess the current project
Look for the signals that place a project pre-migration:
- Multiple head projects (`.iOS`, `.Droid`, `.UWP`) referencing a shared `.NET Standard` class library — MAUI replaces this with **one** multi-targeted project.
- `<PackageReference Include="Xamarin.Forms" .../>`, `Xamarin.Essentials`, `Xamarin.CommunityToolkit` in any `.csproj`.
- Custom renderers (`ExportRenderer`), Effects (`ExportEffect`), and `DependencyService.Get<T>()` usage — each has a different MAUI replacement (see the breaking-change map).
- Third-party NuGet packages that predate MAUI — check each one for a MAUI-compatible version or replacement before migrating code that depends on it; an unmaintained `Plugin.*` package can block the whole migration.

## 2. Choose a strategy
- **Preferred: migrate one app/shared-library at a time**, behind version control, keeping the rest of a solution on Xamarin.Forms until each piece is done. MAUI's single-project model means Xamarin.Forms and MAUI cannot run in the same head project — the cutover for a given head project is all-or-nothing.
- **Big-bang** (small apps only): acceptable when the app is small enough that a full migration completes in one sitting with a green test suite the whole way.
- Either way, **land a characterization-test safety net before touching code** — the same "characterize, then change" discipline as any refactor: write tests that lock in the current, pre-migration behavior for anything you can exercise (ViewModel logic, service behavior, critical user flows), then keep them green through the migration.

## 3. Run the mechanical pass
Use Microsoft's `dotnet-upgrade-assistant` (`dotnet tool install -g upgrade-assistant`) as the first pass — it rewrites the project file to the MAUI single-project format and handles the bulk of namespace renames. It will **not** handle: custom renderers, Effects, `DependencyService` registrations, or third-party package swaps — those need the manual pass below.

## 4. Work the manual pass
Go through `references/breaking-changes-map.md` systematically:
1. Namespaces & packages (`Xamarin.Forms.*` → `Microsoft.Maui.Controls.*`, `Xamarin.Essentials` → built-in Maui Essentials APIs, `Xamarin.CommunityToolkit` → `CommunityToolkit.Maui`).
2. Renderers → Handlers for every custom control.
3. `DependencyService` → constructor DI via `MauiProgram`.
4. Effects → Handlers.
5. Resources → `.csproj` `MauiIcon`/`MauiSplashScreen`/`MauiImage`/`MauiFont` items.
6. Shell — mostly compatible; verify route registration and navigation parameter passing still work as expected.

## 5. Verify parity
Run the full test pyramid (unit, integration, E2E — see `maui-expert`'s testing section) against the migrated app. A migration is done when the characterization tests from step 2 are green again, not when the code merely compiles.

## Rules
- Never delete or weaken a characterization test to make the migration "pass" — if pre-migration behavior was actually a bug, fix it as a separate, explicit, reviewed change.
- Migrate incrementally; don't mix "migrate to MAUI" and "add new feature" in the same change.
- Flag any third-party package with no MAUI-compatible replacement as a blocker, not something to silently work around with a shim.

See `references/breaking-changes-map.md` for the full API/namespace mapping.
```

- [ ] **Step 2: Write `references/breaking-changes-map.md`**

```markdown
# Xamarin.Forms → MAUI breaking-change map

## Namespaces & packages
| Xamarin.Forms | .NET MAUI |
|---|---|
| `Xamarin.Forms` | `Microsoft.Maui.Controls` |
| `Xamarin.Forms.Xaml` | `Microsoft.Maui.Controls.Xaml` |
| `Xamarin.Forms.Application` | `Microsoft.Maui.Controls.Application` |
| `Xamarin.Essentials` | Built in — `Microsoft.Maui.ApplicationModel`, `Microsoft.Maui.Devices`, `Microsoft.Maui.Storage`, `Microsoft.Maui.Networking` (no separate package; part of the MAUI SDK) |
| `Xamarin.CommunityToolkit` | `CommunityToolkit.Maui` (NuGet) |
| `Xamarin.Forms.Shell` | `Microsoft.Maui.Controls` (Shell is built in, no separate namespace) |
| `Xamarin.Forms.PlatformConfiguration` | `Microsoft.Maui.Controls.PlatformConfiguration` |

## Project structure
| Xamarin.Forms | .NET MAUI |
|---|---|
| `.iOS` / `.Droid` / `.UWP` head projects + shared `.NET Standard` library | One project, multi-targeted (`net8.0-ios`, `net8.0-android`, `net8.0-maccatalyst`, `net8.0-windows10.0.19041.0`) |
| Per-platform resource files (`Resources/drawable`, `Assets.xcassets`, …) managed by hand | `MauiIcon`, `MauiSplashScreen`, `MauiImage`, `MauiFont` items in the `.csproj`; MAUI generates the per-platform assets at build time |
| `AssemblyInfo.cs` per head | Centralized in the `.csproj` (`ApplicationId`, `ApplicationDisplayVersion`, `ApplicationVersion`) |

## UI extensibility
| Xamarin.Forms | .NET MAUI |
|---|---|
| Custom Renderers (`ExportRenderer`, `ViewRenderer<TView, TNativeView>`) | **Handlers** (`ExportHandler`/`ICustomHandler`, or `Handler.SetVirtualView`) — a thinner, non-renderer mapping layer between the cross-platform control and its native counterpart |
| Effects (`ExportEffect`, `RoutingEffect`) | Handlers (attach behavior directly in a handler mapper, e.g. `Microsoft.Maui.Handlers.EntryHandler.Mapper.AppendToMapping(...)`) |
| `DependencyService.Get<T>()` | Constructor injection — register the implementation in `MauiProgram.cs` (`builder.Services.AddSingleton<IMyService, MyService>()`) |
| `Device.RuntimePlatform` / `Device.OnPlatform` | `DeviceInfo.Platform` / `OnPlatform<T>` markup or `OnPlatform` in XAML |
| `ListView` | `CollectionView`/`CarouselView` (virtualized, different API surface — grouping/selection/templates changed) |

## App model
| Xamarin.Forms | .NET MAUI |
|---|---|
| `Xamarin.Forms.Application.Current` | `Microsoft.Maui.Controls.Application.Current`; platform lifecycle hooked via `MauiProgram`'s `ConfigureLifecycleEvents`, not per-head `AppDelegate`/`MainActivity` overrides for cross-platform logic |
| `DependencyService`-based platform services | DI-registered platform services, still implemented per-platform under `Platforms/<Platform>/`, but wired through the same container as everything else |
| `Xamarin.Forms.Shell` navigation | Carries over largely as-is — same `Routing.RegisterRoute`/`GoToAsync` model; verify query-property parameter passing after migrating |

## Known gotchas
- Many Xamarin-era `Plugin.*` NuGet packages are unmaintained — check for a MAUI-native replacement or a `CommunityToolkit.Maui` equivalent before assuming a straight package-version bump will work.
- `Entry`/`Editor` default styling and platform-specific look differs from Xamarin.Forms — visual QA every migrated screen, don't assume pixel parity.
- Xamarin's App Center (analytics/crash reporting/distribution) is retired — plan a replacement (e.g. Application Insights, Sentry, or another current provider) as part of the migration, not as an afterthought.
- First-party add-on packages have MAUI-specific successor packages (e.g. `Xamarin.Forms.Maps` → `Microsoft.Maui.Controls.Maps`) — check the exact package name, it usually changed.
```

- [ ] **Step 3: Verify frontmatter**

Run: `head -1 plugins/agentic-sdd/skills/xamarin-maui-migration/SKILL.md`
Expected: `---`

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/skills/xamarin-maui-migration/
git commit -m "feat(skills): add xamarin-maui-migration playbook + breaking-change map"
```

---

### Task 3: `architect.md` MAUI awareness + cross-references in `dotnet-expert.md`/`avalonia-expert.md`

**Files:**
- Modify: `plugins/agentic-sdd/agents/architect.md`
- Modify: `plugins/agentic-sdd/agents/dotnet-expert.md`
- Modify: `plugins/agentic-sdd/agents/avalonia-expert.md`

- [ ] **Step 1: Edit `architect.md`'s persona line**

Old:
```
You are a pragmatic software architect for a full-stack TypeScript/JavaScript shop (React, React Native, Node/Express/Fastify, NestJS, Next.js, PostgreSQL, MongoDB).
```

New:
```
You are a pragmatic software architect for a full-stack TypeScript/JavaScript shop (React, React Native, Node/Express/Fastify, NestJS, Next.js, PostgreSQL, MongoDB) — and for .NET MAUI cross-platform mobile apps, including migrations from Xamarin.Forms.
```

- [ ] **Step 2: Add a mobile-specific bullet to `architect.md`'s boundaries step**

Old:
```
   - **Define the folder structure**, not just the boxes: organize by layer and by feature/domain into named folders — never a flat layout. Follow the ecosystem's idiomatic layout and the repo's existing conventions (see `rules/25-structure.md`); name folders by responsibility and keep dependencies one-directional. Call out the design patterns you choose (repository, ports & adapters, factory, strategy, …) and why.
```

New:
```
   - **Define the folder structure**, not just the boxes: organize by layer and by feature/domain into named folders — never a flat layout. Follow the ecosystem's idiomatic layout and the repo's existing conventions (see `rules/25-structure.md`); name folders by responsibility and keep dependencies one-directional. Call out the design patterns you choose (repository, ports & adapters, factory, strategy, …) and why.
   - **Mobile (.NET MAUI):** call out the platform-abstraction boundary (interfaces + DI for anything platform-specific), the offline-first data strategy (local store + sync) if the app must work without connectivity, and app lifecycle/backgrounding concerns. For a migration-shaped brief, include a current-state → target-state section that references `maui-expert`'s Xamarin.Forms → MAUI breaking-change map rather than re-deriving it.
```

- [ ] **Step 3: Add the cross-reference in `dotnet-expert.md`'s description**

Old:
```
description: Use for C# / .NET backend and ASP.NET Core Web API work — minimal APIs or controllers, dependency injection, EF Core, validation, auth, and xUnit testing. Triggers on "C#", ".NET", "ASP.NET Core", "Web API", "minimal API", "EF Core", "dotnet". Targets modern cross-platform .NET (8/9) on macOS Apple Silicon. For Avalonia desktop UI use avalonia-expert. En español — "API web", "inyección de dependencias", "validación", "autenticación", "pruebas".
```

New:
```
description: Use for C# / .NET backend and ASP.NET Core Web API work — minimal APIs or controllers, dependency injection, EF Core, validation, auth, and xUnit testing. Triggers on "C#", ".NET", "ASP.NET Core", "Web API", "minimal API", "EF Core", "dotnet". Targets modern cross-platform .NET (8/9) on macOS Apple Silicon. For Avalonia desktop UI use avalonia-expert; for .NET MAUI mobile apps use maui-expert. En español — "API web", "inyección de dependencias", "validación", "autenticación", "pruebas".
```

- [ ] **Step 4: Add the cross-reference in `avalonia-expert.md`'s description**

Old:
```
description: Use for cross-platform desktop UI with Avalonia and XAML (AXAML) in C# — views, MVVM, data binding, styles/themes, custom controls, and Avalonia testing (headless xUnit + Appium). Triggers on "Avalonia", "XAML", "AXAML", "desktop app", "MVVM", "view model". Targets modern .NET on macOS Apple Silicon. For ASP.NET Core APIs use dotnet-expert. En español — "aplicación de escritorio", "modelo de vista", "enlace de datos", "estilos", "control personalizado".
```

New:
```
description: Use for cross-platform desktop UI with Avalonia and XAML (AXAML) in C# — views, MVVM, data binding, styles/themes, custom controls, and Avalonia testing (headless xUnit + Appium). Triggers on "Avalonia", "XAML", "AXAML", "desktop app", "MVVM", "view model". Targets modern .NET on macOS Apple Silicon. For ASP.NET Core APIs use dotnet-expert; for .NET MAUI mobile apps use maui-expert. En español — "aplicación de escritorio", "modelo de vista", "enlace de datos", "estilos", "control personalizado".
```

- [ ] **Step 5: Verify**

Run: `grep -n "maui-expert" plugins/agentic-sdd/agents/architect.md plugins/agentic-sdd/agents/dotnet-expert.md plugins/agentic-sdd/agents/avalonia-expert.md`
Expected: one match per file.

- [ ] **Step 6: Commit**

```bash
git add plugins/agentic-sdd/agents/architect.md plugins/agentic-sdd/agents/dotnet-expert.md plugins/agentic-sdd/agents/avalonia-expert.md
git commit -m "docs(agents): make architect MAUI-aware, cross-reference maui-expert"
```

---

### Task 4: `e2e-tester.md`, `qa-visual.md`, `commands/qa.md` — MAUI E2E/QA touchpoints

**Files:**
- Modify: `plugins/agentic-sdd/agents/e2e-tester.md`
- Modify: `plugins/agentic-sdd/agents/qa-visual.md`
- Modify: `plugins/agentic-sdd/commands/qa.md`

- [ ] **Step 1: Insert a MAUI row in `e2e-tester.md`**

Old:
```
- **Avalonia desktop (C#/XAML):** **Appium** drives the compiled app through the platform accessibility tree (real window, native menus/focus) — supported on macOS; grant the test runner Accessibility permission. Use `Avalonia.Headless.XUnit` for fast in-memory UI checks below the E2E layer.
- **.NET web front-ends / Blazor:** Playwright for .NET (runs natively on Apple Silicon).
```

New:
```
- **Avalonia desktop (C#/XAML):** **Appium** drives the compiled app through the platform accessibility tree (real window, native menus/focus) — supported on macOS; grant the test runner Accessibility permission. Use `Avalonia.Headless.XUnit` for fast in-memory UI checks below the E2E layer.
- **.NET MAUI mobile/desktop (C#/XAML):** **Appium** drives the compiled app per platform (iOS simulator, Android emulator/device, Windows) through the accessibility tree — locate controls via `SemanticProperties`. `maui-expert` owns this test layer directly as part of its full-pyramid testing responsibility, rather than always handing off here.
- **.NET web front-ends / Blazor:** Playwright for .NET (runs natively on Apple Silicon).
```

- [ ] **Step 2: Insert a MAUI row in `qa-visual.md`**

Old:
```
- **Avalonia desktop (XAML):** Appium screenshots, or `Avalonia.Headless` render-to-bitmap for fast in-memory captures.
- **.NET web / Blazor:** Playwright for .NET.
```

New:
```
- **Avalonia desktop (XAML):** Appium screenshots, or `Avalonia.Headless` render-to-bitmap for fast in-memory captures.
- **.NET MAUI (mobile/desktop):** Appium screenshots per platform (iOS simulator, Android emulator, Windows).
- **.NET web / Blazor:** Playwright for .NET.
```

- [ ] **Step 3: Extend the driver list in `commands/qa.md`**

Old:
```
Follow the `visual-qa` skill. Capture screenshots with the stack's E2E driver (Playwright for web, Detox/Maestro for React Native, Appium/Avalonia.Headless for desktop) across the states people forget — loading, empty, error, long-text, narrow + wide breakpoints, light + dark theme — then read each screenshot and report visual defects grouped Blocking / Should-fix / Nit, each tied to an `AC-n` and its screenshot path. Hand Blocking + Should-fix to the `implementer`, then re-inspect until clean. Return findings + screenshot paths only — never the images.
```

New:
```
Follow the `visual-qa` skill. Capture screenshots with the stack's E2E driver (Playwright for web, Detox/Maestro for React Native, Appium/Avalonia.Headless for desktop, Appium for MAUI mobile/desktop) across the states people forget — loading, empty, error, long-text, narrow + wide breakpoints, light + dark theme — then read each screenshot and report visual defects grouped Blocking / Should-fix / Nit, each tied to an `AC-n` and its screenshot path. Hand Blocking + Should-fix to the `implementer`, then re-inspect until clean. Return findings + screenshot paths only — never the images.
```

- [ ] **Step 4: Verify**

Run: `grep -ln "MAUI" plugins/agentic-sdd/agents/e2e-tester.md plugins/agentic-sdd/agents/qa-visual.md plugins/agentic-sdd/commands/qa.md`
Expected: all three paths printed.

- [ ] **Step 5: Commit**

```bash
git add plugins/agentic-sdd/agents/e2e-tester.md plugins/agentic-sdd/agents/qa-visual.md plugins/agentic-sdd/commands/qa.md
git commit -m "docs(agents): add MAUI recipe to e2e-tester, qa-visual, and /qa"
```

---

### Task 5: Testing-skill MAUI touchpoints

**Files:**
- Modify: `plugins/agentic-sdd/skills/stack-testing-recipes/SKILL.md`
- Modify: `plugins/agentic-sdd/skills/e2e-testing/SKILL.md`
- Modify: `plugins/agentic-sdd/skills/e2e-testing/references/dotnet-e2e-setup.md`
- Modify: `plugins/agentic-sdd/skills/visual-qa/SKILL.md`
- Modify: `plugins/agentic-sdd/skills/tdd-workflow/references/xunit-patterns.md`

- [ ] **Step 1: Insert a new MAUI section in `stack-testing-recipes/SKILL.md`**

Old:
```
## Avalonia desktop (C# / XAML)
- **ViewModel unit:** plain xUnit — ViewModels carry no UI dependency, so they're fast.
- **Headless UI:** `Avalonia.Headless.XUnit` with `[AvaloniaFact]`/`[AvaloniaTheory]` — control logic, layout, and bindings in-memory, no display (ideal for CI).
- **E2E UI:** **Appium** drives the compiled app via the accessibility tree; macOS requires granting the test runner Accessibility permission. Set `AutomationProperties` so controls are findable.

## .NET web / Blazor front-ends
```

New:
```
## Avalonia desktop (C# / XAML)
- **ViewModel unit:** plain xUnit — ViewModels carry no UI dependency, so they're fast.
- **Headless UI:** `Avalonia.Headless.XUnit` with `[AvaloniaFact]`/`[AvaloniaTheory]` — control logic, layout, and bindings in-memory, no display (ideal for CI).
- **E2E UI:** **Appium** drives the compiled app via the accessibility tree; macOS requires granting the test runner Accessibility permission. Set `AutomationProperties` so controls are findable.

## .NET MAUI (mobile/desktop)
- **Unit:** xUnit + FluentAssertions on ViewModels/services — no UI dependency, so fast.
- **Integration:** DI-container resolution tests (`MauiProgram` registrations resolve); repository tests against SQLite; service tests against a faked `HttpMessageHandler`.
- **E2E:** **Appium** drives the compiled app per platform (iOS/Android/Windows) through the accessibility tree; locate by `SemanticProperties`. Owned directly by `maui-expert` as part of its full test-pyramid responsibility.

## .NET web / Blazor front-ends
```

- [ ] **Step 2: Insert a MAUI row in `e2e-testing/SKILL.md`'s table**

Old:
```
| Avalonia desktop (XAML) | **Appium** (+ Avalonia.Headless for unit) | Drives the real window via the accessibility tree; macOS needs Accessibility permission |
| .NET web / Blazor UI | **Playwright for .NET** | Native Apple Silicon support |
```

New:
```
| Avalonia desktop (XAML) | **Appium** (+ Avalonia.Headless for unit) | Drives the real window via the accessibility tree; macOS needs Accessibility permission |
| .NET MAUI mobile/desktop | **Appium** (+ xUnit for unit/integration) | Drives the compiled app per platform (iOS/Android/Windows) via the accessibility tree; owned by `maui-expert` |
| .NET web / Blazor UI | **Playwright for .NET** | Native Apple Silicon support |
```

- [ ] **Step 3: Insert a MAUI section in `e2e-testing/references/dotnet-e2e-setup.md`**

Old:
```
## Avalonia desktop (Appium)
- Use the Avalonia Appium integration (as Avalonia tests itself). Start the Appium server, point it at the built `.app`/binary.
- macOS: System Settings → Privacy & Security → Accessibility → add the terminal / test runner, or automation is blocked.
- Set `AutomationProperties.AutomationId` on controls; locate by automation id. Keep E2E lean — push logic to headless `[AvaloniaFact]` tests.

## .NET web / Blazor
- `Microsoft.Playwright`; run `pwsh bin/Debug/net9.0/playwright.ps1 install` once. Browsers are arm64-native on Apple Silicon.

## CI notes
- Use a macOS arm64 runner (`macos-14`+). Ensure a container runtime for Testcontainers; for headless Avalonia no display is required.
```

New:
```
## Avalonia desktop (Appium)
- Use the Avalonia Appium integration (as Avalonia tests itself). Start the Appium server, point it at the built `.app`/binary.
- macOS: System Settings → Privacy & Security → Accessibility → add the terminal / test runner, or automation is blocked.
- Set `AutomationProperties.AutomationId` on controls; locate by automation id. Keep E2E lean — push logic to headless `[AvaloniaFact]` tests.

## MAUI (Appium + device/simulator)
- Use Appium with the platform-specific driver: `XCUITest` (iOS simulator/device), `UiAutomator2` (Android emulator/device), `Windows Application Driver` (Windows). Start the Appium server, point it at the built app package per platform.
- Set `SemanticProperties.Description`/`AutomationId` on controls; locate by those, not by visual position.
- iOS/Android runs need a simulator/emulator (or a device farm) — CI needs a macOS runner for iOS, and Android SDK/emulator setup for Android.
- Keep E2E lean — push ViewModel/service logic to xUnit unit tests; reserve Appium for the highest-value user journeys.

## .NET web / Blazor
- `Microsoft.Playwright`; run `pwsh bin/Debug/net9.0/playwright.ps1 install` once. Browsers are arm64-native on Apple Silicon.

## CI notes
- Use a macOS arm64 runner (`macos-14`+) for iOS/Mac Catalyst builds and Appium E2E; Android needs the Android SDK + emulator (works on macOS runners too). Ensure a container runtime for Testcontainers; for headless Avalonia no display is required.
```

- [ ] **Step 4: Insert a MAUI row in `visual-qa/SKILL.md`'s table**

Old:
```
| Avalonia desktop (XAML) | **Appium** or **Avalonia.Headless** render-to-bitmap | Headless is fast for in-memory captures |
| .NET web / Blazor | **Playwright for .NET** | Native Apple Silicon |
```

New:
```
| Avalonia desktop (XAML) | **Appium** or **Avalonia.Headless** render-to-bitmap | Headless is fast for in-memory captures |
| .NET MAUI (mobile/desktop) | **Appium** screenshots per platform | iOS simulator, Android emulator, Windows |
| .NET web / Blazor | **Playwright for .NET** | Native Apple Silicon |
```

- [ ] **Step 5: Insert a new MAUI section in `tdd-workflow/references/xunit-patterns.md`**

Old:
```
## Avalonia (headless)
- Install `Avalonia.Headless.XUnit`; use `[AvaloniaFact]` (not `[Fact]`) so the UI thread is set up.
- Build the control/window, pump layout, assert on properties/bindings. Use `AutomationProperties` ids for lookups.

## Coverage gate
```

New:
```
## Avalonia (headless)
- Install `Avalonia.Headless.XUnit`; use `[AvaloniaFact]` (not `[Fact]`) so the UI thread is set up.
- Build the control/window, pump layout, assert on properties/bindings. Use `AutomationProperties` ids for lookups.

## MAUI (unit + integration)
- ViewModels built with `CommunityToolkit.Mvvm` carry no UI dependency — test them with plain `[Fact]`/`[Theory]`, same as any C# class.
- For DI-registration tests, build a `MauiApp` via `MauiProgram.CreateMauiApp()` (or a test-only builder) and resolve services from `Services` to catch missing/misconfigured registrations.
- For repository tests against SQLite, use a fresh in-memory or temp-file database per test; assert against the real driver, not a mock.

## Coverage gate
```

- [ ] **Step 6: Verify**

Run: `grep -rln "MAUI" plugins/agentic-sdd/skills/stack-testing-recipes/SKILL.md plugins/agentic-sdd/skills/e2e-testing/SKILL.md plugins/agentic-sdd/skills/e2e-testing/references/dotnet-e2e-setup.md plugins/agentic-sdd/skills/visual-qa/SKILL.md plugins/agentic-sdd/skills/tdd-workflow/references/xunit-patterns.md`
Expected: all five paths printed.

- [ ] **Step 7: Commit**

```bash
git add plugins/agentic-sdd/skills/stack-testing-recipes/SKILL.md plugins/agentic-sdd/skills/e2e-testing/SKILL.md plugins/agentic-sdd/skills/e2e-testing/references/dotnet-e2e-setup.md plugins/agentic-sdd/skills/visual-qa/SKILL.md plugins/agentic-sdd/skills/tdd-workflow/references/xunit-patterns.md
git commit -m "docs(skills): add MAUI testing recipes across testing skills"
```

---

### Task 6: `pr-description` MAUI mentions

**Files:**
- Modify: `plugins/agentic-sdd/skills/pr-description/SKILL.md`
- Modify: `plugins/agentic-sdd/skills/pr-description/references/section-catalog.md`

- [ ] **Step 1: Add MAUI to the stack list in `pr-description/SKILL.md`**

Old:
```
Turn a branch's commits into a scannable PR title + description. Add a section **only** when the commits actually contain that kind of change, so one playbook fits any stack (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia, PostgreSQL/MongoDB) — UI-only sections (Accessibility, i18n) appear only for front-end work.
```

New:
```
Turn a branch's commits into a scannable PR title + description. Add a section **only** when the commits actually contain that kind of change, so one playbook fits any stack (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia, .NET MAUI, PostgreSQL/MongoDB) — UI-only sections (Accessibility, i18n) appear only for front-end work.
```

- [ ] **Step 2: Append MAUI to the `.NET integration / E2E` bullet in `references/section-catalog.md`**

Old:
```
- **.NET integration / E2E:** `WebApplicationFactory`, Testcontainers for .NET, Avalonia headless (`[AvaloniaFact]`), Appium
```

New:
```
- **.NET integration / E2E:** `WebApplicationFactory`, Testcontainers for .NET, Avalonia headless (`[AvaloniaFact]`), Appium (Avalonia and MAUI)
```

- [ ] **Step 3: Verify**

Run: `grep -n "MAUI" plugins/agentic-sdd/skills/pr-description/SKILL.md plugins/agentic-sdd/skills/pr-description/references/section-catalog.md`
Expected: one match per file.

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/skills/pr-description/SKILL.md plugins/agentic-sdd/skills/pr-description/references/section-catalog.md
git commit -m "docs(skills): mention MAUI in pr-description stack list and section catalog"
```

---

### Task 7: Registry/manifest updates — `CLAUDE.md`, `README.md`, `plugin.json`, `marketplace.json`

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `plugins/agentic-sdd/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Update `CLAUDE.md`'s top stack line**

Old:
```
> Stack this workflow targets: **React, React Native, Node.js (Express / Fastify), NestJS, Next.js, C# / ASP.NET Core Web APIs, Avalonia (XAML) desktop, Python (Django / DRF, FastAPI, Flask), PostgreSQL, MongoDB**, tested with **Jest/Vitest**, **xUnit**, and **pytest** (unit) and **Playwright / Detox / Supertest / Testcontainers / WebApplicationFactory / Avalonia.Headless / Appium / httpx** (E2E/integration). Cross-platform, including **macOS (Tahoe) on Apple Silicon** — .NET work targets modern cross-platform **.NET 8/9** (arm64), not the Windows-only .NET Framework.
```

New:
```
> Stack this workflow targets: **React, React Native, Node.js (Express / Fastify), NestJS, Next.js, C# / ASP.NET Core Web APIs, Avalonia (XAML) desktop, .NET MAUI (cross-platform mobile, incl. Xamarin.Forms migration), Python (Django / DRF, FastAPI, Flask), PostgreSQL, MongoDB**, tested with **Jest/Vitest**, **xUnit**, and **pytest** (unit) and **Playwright / Detox / Supertest / Testcontainers / WebApplicationFactory / Avalonia.Headless / Appium / httpx** (E2E/integration). Cross-platform, including **macOS (Tahoe) on Apple Silicon** — .NET work targets modern cross-platform **.NET 8/9** (arm64), not the Windows-only .NET Framework.
```

- [ ] **Step 2: Insert `maui-expert` into `CLAUDE.md`'s stack-expert agents table**

Old:
```
| `avalonia-expert` | Avalonia / XAML cross-platform desktop — MVVM, compiled bindings, headless + Appium tests |
| `database-expert` | PostgreSQL & MongoDB — schema, indexes, migrations, transactions, query perf |
```

New:
```
| `avalonia-expert` | Avalonia / XAML cross-platform desktop — MVVM, compiled bindings, headless + Appium tests |
| `maui-expert` | .NET MAUI — cross-platform mobile/desktop (iOS, Android, Windows, Mac Catalyst); MVVM, platform integration, Xamarin.Forms migration, owns its app's full unit/integration/E2E pyramid |
| `database-expert` | PostgreSQL & MongoDB — schema, indexes, migrations, transactions, query perf |
```

- [ ] **Step 3: Insert `xamarin-maui-migration` into `CLAUDE.md`'s skills table**

Old:
```
| `pr-description` | Writing/updating a PR title & description from commits — section catalog + style guide (loaded by `/update-pr`) |
| `curation` | Curating the project's conventions & advisory rules after a feature — harvest method + artifact templates |
```

New:
```
| `pr-description` | Writing/updating a PR title & description from commits — section catalog + style guide (loaded by `/update-pr`) |
| `xamarin-maui-migration` | Migrating a Xamarin.Forms app to .NET MAUI — breaking-change map + incremental migration strategy (loaded by `maui-expert`) |
| `curation` | Curating the project's conventions & advisory rules after a feature — harvest method + artifact templates |
```

- [ ] **Step 4: Bump the repo-layout counts in `CLAUDE.md`**

Old:
```
│       ├── agents/                ← 21 agents (lifecycle + stack experts)
```

New:
```
│       ├── agents/                ← 22 agents (lifecycle + stack experts)
```

Old:
```
│       ├── skills/                ← 9 skills (+ references)
```

New:
```
│       ├── skills/                ← 10 skills (+ references)
```

- [ ] **Step 5: Update `README.md`'s stack list**

Old:
```
A reusable Claude Code workflow that enforces **Spec-Driven Development (SDD)** and **Test-Driven Development (TDD)** across a full-stack TypeScript/JavaScript, **C#/.NET**, and **Python** stack: **React, React Native, Node.js (Express/Fastify), NestJS, Next.js, C# / ASP.NET Core Web APIs, Avalonia (XAML) desktop, Python (Django/DRF, FastAPI, Flask), PostgreSQL, MongoDB**.
```

New:
```
A reusable Claude Code workflow that enforces **Spec-Driven Development (SDD)** and **Test-Driven Development (TDD)** across a full-stack TypeScript/JavaScript, **C#/.NET**, and **Python** stack: **React, React Native, Node.js (Express/Fastify), NestJS, Next.js, C# / ASP.NET Core Web APIs, Avalonia (XAML) desktop, .NET MAUI (cross-platform mobile), Python (Django/DRF, FastAPI, Flask), PostgreSQL, MongoDB**.
```

- [ ] **Step 6: Update `README.md`'s agent count/list**

Old:
```
- **21 agents** — 10 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `qa-visual`, `code-reviewer`, `curator`, `refactorer`, `cicd-engineer`) + 11 stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML, Django/DRF, FastAPI, Flask, PostgreSQL/MongoDB).
```

New:
```
- **22 agents** — 10 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `qa-visual`, `code-reviewer`, `curator`, `refactorer`, `cicd-engineer`) + 12 stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML, .NET MAUI, Django/DRF, FastAPI, Flask, PostgreSQL/MongoDB).
```

- [ ] **Step 7: Update `README.md`'s skill count/list**

Old:
```
- **9 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `visual-qa`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description`, `curation`.
```

New:
```
- **10 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `visual-qa`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`, `pr-description`, `curation`, `xamarin-maui-migration`.
```

- [ ] **Step 8: Update `plugins/agentic-sdd/.claude-plugin/plugin.json`**

Old (`description` field):
```
"description": "Spec-Driven Development lifecycle with TDD and E2E testing. Ships lifecycle agents (spec, tdd, implement, e2e, review, refactor, architect) and stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML desktop, PostgreSQL, MongoDB), reusable skills, slash commands, and enforcing quality-gate hooks for clean, maintainable, scalable code. Cross-platform incl. macOS Apple Silicon.",
```

New:
```
"description": "Spec-Driven Development lifecycle with TDD and E2E testing. Ships lifecycle agents (spec, tdd, implement, e2e, review, refactor, architect) and stack experts (React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML desktop, .NET MAUI mobile incl. Xamarin.Forms migration, PostgreSQL, MongoDB), reusable skills, slash commands, and enforcing quality-gate hooks for clean, maintainable, scalable code. Cross-platform incl. macOS Apple Silicon.",
```

Old (inside the `keywords` array):
```
    "avalonia",
    "xaml",
    "postgresql",
```

New:
```
    "avalonia",
    "xaml",
    "maui",
    "xamarin",
    "mobile",
    "postgresql",
```

- [ ] **Step 9: Update `.claude-plugin/marketplace.json`**

Old:
```
      "description": "Spec-Driven Development with TDD and E2E. Expert agents for React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML desktop, PostgreSQL and MongoDB, plus clean-code review and enforcing hooks. Cross-platform incl. macOS Apple Silicon."
```

New:
```
      "description": "Spec-Driven Development with TDD and E2E. Expert agents for React, React Native, Node/Express/Fastify, NestJS, Next.js, C#/ASP.NET Core, Avalonia/XAML desktop, .NET MAUI mobile, PostgreSQL and MongoDB, plus clean-code review and enforcing hooks. Cross-platform incl. macOS Apple Silicon."
```

- [ ] **Step 10: Verify JSON still parses**

Run: `python3 -c "import json; json.load(open('plugins/agentic-sdd/.claude-plugin/plugin.json')); json.load(open('.claude-plugin/marketplace.json'))" && echo OK`
Expected: `OK`

- [ ] **Step 11: Verify the counts and MAUI mentions**

Run: `grep -n "22 agents\|10 skills" CLAUDE.md README.md; grep -c "maui-expert" CLAUDE.md; grep -c "MAUI" README.md`
Expected: both count lines found in both files; `maui-expert` appears in `CLAUDE.md`; `MAUI` appears in `README.md`.

- [ ] **Step 12: Commit**

```bash
git add CLAUDE.md README.md plugins/agentic-sdd/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "docs: register maui-expert and xamarin-maui-migration in counts and manifests"
```

---

### Task 8: Final validation pass

**Files:** none (verification only)

- [ ] **Step 1: Run the frontmatter check exactly as CI does**

Run:
```bash
for f in plugins/agentic-sdd/agents/*.md plugins/agentic-sdd/commands/*.md plugins/agentic-sdd/skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---' || echo "MISSING frontmatter: $f"
done
echo "frontmatter check done"
```
Expected: no `MISSING frontmatter` lines printed.

- [ ] **Step 2: Run the JSON-manifests check exactly as CI does**

Run:
```bash
for f in .claude-plugin/marketplace.json plugins/agentic-sdd/.claude-plugin/plugin.json plugins/agentic-sdd/hooks/hooks.json plugins/agentic-sdd/settings.template.json; do
  python3 -c "import json,sys; json.load(open('$f'))" && echo "ok  $f"
done
```
Expected: `ok` printed for all four files.

- [ ] **Step 3: Run the copy installer end-to-end and spot-check the two new files**

Run:
```bash
TMP="$(mktemp -d)/app"; mkdir -p "$TMP"
echo '{"scripts":{}}' > "$TMP/package.json"
bash scripts/install.sh "$TMP" --with-ci
test -f "$TMP/.claude/agents/maui-expert.md" && echo "maui-expert.md installed"
test -f "$TMP/.claude/skills/xamarin-maui-migration/SKILL.md" && echo "xamarin-maui-migration SKILL.md installed"
test -f "$TMP/.claude/skills/xamarin-maui-migration/references/breaking-changes-map.md" && echo "breaking-changes-map.md installed"
```
Expected: all three "installed" lines print.

- [ ] **Step 4: Cross-check every file in the design doc's integration list was touched**

Run: `git diff --stat main...HEAD`
Expected: every file listed in `docs/superpowers/specs/2026-08-04-maui-expert-agent-design.md`'s "Workflow & docs integration" section appears in the diff, plus the two new files/directories from Tasks 1–2.

- [ ] **Step 5: Push the branch and open the PR**

```bash
git push -u origin feat/maui-expert-agent
gh pr create --title "feat: add maui-expert agent + xamarin-maui-migration skill" --body "$(cat <<'EOF'
## Summary
- Adds `maui-expert`, a full-lifecycle .NET MAUI agent (architecture, platform integration, security, release-readiness) that also owns its app's full unit/integration/E2E test pyramid, specialized in migrating Xamarin.Forms apps to MAUI.
- Adds the `xamarin-maui-migration` skill (assessment, strategy, breaking-change map) that `maui-expert` applies for migrations.
- Threads `maui-expert` through every touchpoint `avalonia-expert` already has: `architect`, `dotnet-expert`/`avalonia-expert` cross-references, `e2e-tester`, `qa-visual`, `/qa`, the testing skills, `pr-description`, and the plugin/marketplace manifests + doc counts.

See `docs/superpowers/specs/2026-08-04-maui-expert-agent-design.md` for the full design rationale.

## Test plan
- [ ] Frontmatter present on every agent/command/skill (`head -1 ... | grep '^---'`)
- [ ] `plugin.json` / `marketplace.json` / `hooks.json` / `settings.template.json` still parse as JSON
- [ ] `scripts/install.sh` copies `maui-expert.md` and the `xamarin-maui-migration` skill into a target repo's `.claude/`
- [ ] CI (`.github/workflows/ci.yml`) is green
EOF
)"
```

Expected: PR created; report the PR URL back to the user.

---

## Notes for the implementer

- Every "Old" block above must match the target file's current content **exactly** (including surrounding lines) before editing — if it doesn't match, the file has drifted since this plan was written; stop and reconcile against the live file rather than forcing the edit.
- Do not run `git push`/`gh pr create` (Step 5 of Task 8) without the user's go-ahead if this plan is being executed in a context where that wasn't already agreed — pushing and opening a PR are visible, non-trivial actions.
