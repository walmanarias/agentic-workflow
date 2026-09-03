---
name: dotnet-expert
description: C# / ASP.NET Core Web API expertise — clean architecture, minimal APIs or controllers, EF Core, DI, validation, StyleCop Analyzers code style, and xUnit + WebApplicationFactory testing on modern cross-platform .NET (8/9). Load for .NET backend work; avalonia-expert and maui-expert cover .NET UI stacks and share this skill's code-style section.
---

# C# / ASP.NET Core Web APIs

Build clean, testable **ASP.NET Core** Web APIs on **modern cross-platform .NET (8/9)**.

> Note: On macOS (incl. Tahoe) and Apple Silicon, use the cross-platform .NET SDK (arm64-native) — **not** the legacy Windows-only .NET Framework. Target `net8.0`/`net9.0`. Verify with `dotnet --info` (should show `osx-arm64`).

## Architecture
- Clean/onion layering: **Domain** (entities, value objects, domain logic — no framework refs) → **Application** (use cases, ports/interfaces, CQRS handlers) → **Infrastructure** (EF Core, external services) → **API** (thin endpoints). Domain and Application stay free of ASP.NET and EF types.
- **Folder/project layout:** a project per layer in the solution (`*.Domain`, `*.Application`, `*.Infrastructure`, `*.Api`), never one flat project; inside each, group by feature/concern (`Features/`, `Endpoints/`, `Entities/`, `Persistence/`, `Configuration/`). Match the existing solution structure — see `rules/25-structure.md`.
- **Endpoints:** Minimal APIs (grouped with `MapGroup`) or controllers — keep them thin; delegate to application services/handlers. Use typed results (`Results<Ok<T>, NotFound, ValidationProblem>`).
- **DI:** constructor injection against interfaces; register with correct lifetimes (singleton/scoped/transient); never `new` infrastructure inside domain/application.
- **Validation:** validate input at the edge (Data Annotations, FluentValidation, or `Microsoft.AspNetCore.Http.Validation`); never trust client input. Use DTOs/records for requests and responses — never expose EF entities directly.
- **Config:** `IOptions<T>` bound from configuration with validation (`ValidateOnStart`); secrets via user-secrets/env, never in source.

## Idioms & quality
- Nullable reference types **on**; treat warnings as errors. `async/await` all the way down with `CancellationToken` threaded through. Avoid `async void` and sync-over-async (`.Result`/`.Wait()`).
- Records for immutable DTOs/value objects; expression-bodied members where clear; pattern matching over type checks.
- Use `ProblemDetails` for consistent error responses; global exception handling middleware; structured logging (Serilog/`ILogger`).
- Persistence via EF Core or Dapper behind a repository/`DbContext` boundary — apply the `database-expert` skill for schema/index/migration design (PostgreSQL/MongoDB). No N+1; use `AsNoTracking` for reads; explicit transactions for multi-write invariants.

## Code style (StyleCop Analyzers)
Enforce style with **[StyleCop.Analyzers](https://github.com/DotNetAnalyzers/StyleCopAnalyzers/blob/master/DOCUMENTATION.md)** — a Roslyn analyzer package, not a separate CLI step: reference it in every project (`PrivateAssets="all"`), commit a shared `stylecop.json` (documentation settings, company name, per-rule overrides) plus severities in `.editorconfig`/`.globalconfig`. Because it runs as build-time analyzers, its warnings ride the existing `dotnet build -warnaserror` gate (`hooks/pre-commit-gate.sh`) automatically — no extra hook step needed.

Apply its rule categories deliberately rather than accepting every default:
- **Spacing (SA1000s)** — consistent whitespace around keywords, operators, and casts.
- **Readability (SA1100s)** — e.g. SA1101 (`this.` qualification) and explicit precedence in non-obvious expressions; many teams disable SA1101 as noise — pick one answer repo-wide.
- **Ordering (SA1200s)** — `using`s inside the namespace (SA1200), `System.*` first (SA1208), alphabetical (SA1210); members ordered const → static fields → instance fields → constructors → properties → methods, each block by access level then static-before-instance (SA1201–SA1204, SA1214–SA1215).
- **Naming (SA1300s)** — PascalCase for types, constants, and non-private members (SA1300, SA1303–SA1304); `I`-prefixed interfaces (SA1302); camelCase locals/parameters (SA1312–SA1313); no Hungarian notation or `m_`/`s_` prefixes (SA1305, SA1308). SA1309 (no leading underscore on fields) fights the now-common `_camelCase` private-field convention — reconfigure it in `stylecop.json` rather than silently violating it everywhere.
- **Maintainability (SA1400s)** — explicit access modifiers always declared (SA1400); fields private, exposed via properties (SA1401); one type and one namespace per file (SA1402–SA1403); suppressions require a justification (SA1404); dead code removed (SA1409).
- **Layout (SA1500s)** — braces on their own line and never omitted; one statement/declaration per line; consistent blank-line usage.
- **Documentation (SA1600s)** — XML doc comments on public API and a file header (SA1633) — only enforced once `<GenerateDocumentationFile>true</GenerateDocumentationFile>` is set; skip this category for internal-only tooling.

## Testing (TDD, xUnit)
- **Unit:** xUnit + FluentAssertions; mock collaborators with NSubstitute/Moq at real seams; test domain/application logic without booting the host.
- **Integration/E2E:** `WebApplicationFactory<TProgram>` (`Microsoft.AspNetCore.Mvc.Testing`) to spin up the real app in-memory; hit endpoints with `HttpClient`; back it with a real/containerized DB via **Testcontainers for .NET** (works on Apple Silicon with Docker/Podman). Hand broad flows to `e2e-tester`.
- Deterministic: inject `TimeProvider`/clock and GUID providers; no real time or network in unit tests.

## Process
Detect the target framework and solution layout first (`*.sln`, `*.csproj`) → follow existing structure → write failing xUnit tests → implement thin endpoint + tested application service → run `dotnet format`, `dotnet build -warnaserror`, `dotnet test`.
