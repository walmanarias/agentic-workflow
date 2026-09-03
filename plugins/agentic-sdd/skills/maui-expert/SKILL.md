---
name: maui-expert
description: .NET MAUI expertise — cross-platform mobile/desktop (iOS, Android, Windows, Mac Catalyst), MVVM, platform integration, security, release readiness, Xamarin.Forms migration, and the full test pyramid incl. Appium E2E. Load for MAUI work; dotnet-expert covers APIs, avalonia-expert covers desktop XAML.
---

# .NET MAUI (cross-platform mobile/desktop)

Build cross-platform mobile and desktop apps (iOS, Android, Windows, Mac Catalyst) in C#/XAML on modern .NET (8/9), including migrations from legacy **Xamarin.Forms**.

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
Apply the `xamarin-maui-migration` skill. Inventory the current project first (TargetFrameworks, `Xamarin.Forms`/`Xamarin.Essentials`/`Xamarin.CommunityToolkit` package refs, multi-head layout) → run the .NET Upgrade Assistant as a mechanical first pass → work through the breaking-change map (`../xamarin-maui-migration/references/breaking-changes-map.md`) for what it can't handle (custom renderers → handlers, `DependencyService` → DI, Effects → Handlers, third-party package replacements) → migrate incrementally with characterization tests locking in current behavior before each change — the same "characterize, then change" discipline `refactorer` uses.

## UI quality & performance
- Platform differences via `OnPlatform`/`DeviceInfo.Platform`, never hardcoded assumptions.
- Accessibility: set `SemanticProperties` so screen readers (and Appium E2E) can find and describe controls.
- Use `CollectionView`/`CarouselView` with virtualization over the legacy `ListView`; cache images; avoid layout thrash on the UI thread — offload work and marshal back via `MainThread.BeginInvokeOnMainThread`.
- Use Hot Reload during iteration; verify on real devices/simulators before calling a screen done — the simulator/emulator hides real performance and gesture issues.

## Code style
- Follow `dotnet-expert`'s **Code style (StyleCop Analyzers)** section for ViewModels/services/code-behind; XAML markup itself isn't covered by StyleCop, so keep it readable via consistent indentation and attribute ordering (name/key attributes first, then layout, then bindings/events).

## Security
- No secrets in source — `SecureStorage`/platform keystores only, per `rules/30-security.md`.
- Certificate pinning for HTTP calls handling sensitive data where warranted; validate all input at service boundaries, never trust deep-link or push-notification payloads blindly.
- Vet dependencies before adding them — many Xamarin-era `Plugin.*` packages are unmaintained; prefer actively maintained MAUI-native or `CommunityToolkit.Maui` packages.

## Release readiness
Prepare the app to be release-ready: app icons/splash screens (`MauiIcon`/`MauiSplashScreen`), platform manifests (`Info.plist`, `AndroidManifest.xml`), version/build numbers. Hand the actual build, code signing, and store submission pipeline to `cicd-engineer` — never run `dotnet publish` or upload to a store as part of feature work.

## Testing (TDD, owns the full pyramid)
- **Unit:** xUnit + FluentAssertions on ViewModels/services — no UI dependency, so they're fast. Mock collaborators with NSubstitute/Moq at real seams.
- **Integration:** DI-container resolution tests (`MauiProgram` registrations resolve correctly); repository tests against SQLite; service tests against a faked `HttpMessageHandler` instead of real network calls.
- **E2E/UI:** **Appium** drives the compiled app per platform (iOS/Android/Windows) through the accessibility tree — Microsoft's supported path since Xamarin.UITest's retirement. Locate controls by `SemanticProperties`/automation id. Unlike the other stacks, MAUI work owns E2E directly rather than deferring wholly to `e2e-tester` — validating behavior end-to-end, through normal development and through a migration, is core to the work.
- Deterministic: inject clock/GUID providers; no real time, no real network in unit/integration tests.

## Process
Detect greenfield vs. brownfield vs. mid-migration state (`Xamarin.Forms`/`Xamarin.Essentials` package refs vs. an existing MAUI `.csproj`) → for migrations, inventory breaking changes first via the `xamarin-maui-migration` skill → write/confirm tests first → implement/migrate → run the full pyramid (unit, integration, E2E) → report gaps.
