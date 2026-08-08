---
name: xamarin-maui-migration
description: Use when migrating a Xamarin.Forms app to .NET MAUI — assessing the current project, sequencing the migration, and mapping Xamarin.Forms/Xamarin.Essentials APIs to their MAUI equivalents. Trigger on "migrate to MAUI", "Xamarin.Forms migration", "port Xamarin app", or when a `.csproj` still references `Xamarin.Forms`/`Xamarin.Essentials`. Loaded by the `maui-expert` skill.
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
Use Microsoft's .NET Upgrade Assistant (`dotnet tool install -g upgrade-assistant`; run `upgrade-assistant upgrade`) as the first pass — it rewrites the project file to the MAUI single-project format and handles the bulk of namespace renames. It will **not** handle: custom renderers, Effects, `DependencyService` registrations, or third-party package swaps — those need the manual pass below.

## 4. Work the manual pass
Go through `references/breaking-changes-map.md` systematically:
1. Namespaces & packages (`Xamarin.Forms.*` → `Microsoft.Maui.Controls.*`, `Xamarin.Essentials` → built-in MAUI Essentials APIs, `Xamarin.CommunityToolkit` → `CommunityToolkit.Maui`).
2. Renderers → Handlers for every custom control.
3. `DependencyService` → constructor DI via `MauiProgram`.
4. Effects → Handlers.
5. Resources → `.csproj` `MauiIcon`/`MauiSplashScreen`/`MauiImage`/`MauiFont` items.
6. Shell — mostly compatible; verify route registration and navigation parameter passing still work as expected.

## 5. Verify parity
Run the full test pyramid (unit, integration, E2E — see the `maui-expert` skill's testing section) against the migrated app. A migration is done when the characterization tests from step 2 are green again, not when the code merely compiles.

## Rules
- Never delete or weaken a characterization test to make the migration "pass" — if pre-migration behavior was actually a bug, fix it as a separate, explicit, reviewed change.
- Migrate incrementally; don't mix "migrate to MAUI" and "add new feature" in the same change.
- Flag any third-party package with no MAUI-compatible replacement as a blocker, not something to silently work around with a shim.

See `references/breaking-changes-map.md` for the full API/namespace mapping.
