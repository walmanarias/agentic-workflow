# Xamarin.Forms → MAUI breaking-change map

## Namespaces, types & packages
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
| Custom Renderers (`ExportRenderer`, `ViewRenderer<TView, TNativeView>`) | **Handlers** — derive from `ViewHandler<TVirtualView, TPlatformView>` (or subclass a built-in handler) and register via `builder.ConfigureMauiHandlers(h => h.AddHandler(typeof(MyControl), typeof(MyControlHandler)))` in `MauiProgram.cs`; for behavior-only tweaks prefer a mapper (`…Handler.Mapper.AppendToMapping`) over a full handler. |
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
