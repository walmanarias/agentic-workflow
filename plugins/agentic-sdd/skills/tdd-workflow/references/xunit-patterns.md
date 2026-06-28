# xUnit patterns (C# / .NET)

## Structure
- One test class per unit; `[Fact]` for single cases, `[Theory]` + `[InlineData]`/`[MemberData]` for tables.
- Arrange–Act–Assert with blank-line separation. Name tests `Method_Scenario_Expected` and reference the AC ("Signup_WhenEmailTaken_Returns409_AC3").
- FluentAssertions for readable assertions (`result.Should().Be(...)`).

## Test doubles
- NSubstitute or Moq for collaborators behind interfaces; prefer hand-written fakes for repositories/gateways.
- Don't mock what you don't own — wrap third-party SDKs behind an interface first.

## Async & determinism
- `await Assert.ThrowsAsync<T>(() => sut.DoAsync())`. Always thread `CancellationToken`.
- Inject `TimeProvider` (and a GUID provider) so time/ids are fixed in tests; never use `DateTime.Now` directly.

## Integration (ASP.NET Core)
- `WebApplicationFactory<TProgram>`; override services with test doubles via `WithWebHostBuilder` / `ConfigureTestServices`.
- Back with Testcontainers for .NET (PostgreSQL/Mongo). Apply migrations in a fixture; truncate or rollback between tests.

## Avalonia (headless)
- Install `Avalonia.Headless.XUnit`; use `[AvaloniaFact]` (not `[Fact]`) so the UI thread is set up.
- Build the control/window, pump layout, assert on properties/bindings. Use `AutomationProperties` ids for lookups.

## Coverage gate
- `dotnet test --collect:"XPlat Code Coverage"` (coverlet); enforce thresholds in CI.
