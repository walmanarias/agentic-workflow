# .NET E2E / integration setup (macOS Apple Silicon)

## ASP.NET Core Web API
- Reference `Microsoft.AspNetCore.Mvc.Testing`; make `Program` discoverable (`public partial class Program {}`).
- `using var app = new WebApplicationFactory<Program>(); var client = app.CreateClient();`
- Real DB: **Testcontainers for .NET** (`Testcontainers.PostgreSql`, `Testcontainers.MongoDb`). Needs a container runtime (Docker Desktop or Colima/Podman) running on arm64.
- Cover: 2xx happy path, 400/422 validation, 401/403 authz, idempotency/retries. Reset DB per test (Respawn or truncate).

## Avalonia desktop (Appium)
- Use the Avalonia Appium integration (as Avalonia tests itself). Start the Appium server, point it at the built `.app`/binary.
- macOS: System Settings → Privacy & Security → Accessibility → add the terminal / test runner, or automation is blocked.
- Set `AutomationProperties.AutomationId` on controls; locate by automation id. Keep E2E lean — push logic to headless `[AvaloniaFact]` tests.

## .NET web / Blazor
- `Microsoft.Playwright`; run `pwsh bin/Debug/net9.0/playwright.ps1 install` once. Browsers are arm64-native on Apple Silicon.

## CI notes
- Use a macOS arm64 runner (`macos-14`+). Ensure a container runtime for Testcontainers; for headless Avalonia no display is required.
