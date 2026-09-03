---
name: stack-testing-recipes
description: Use to pick the right testing tools and write the right kind of tests for a specific technology in the stack (React, React Native, Angular, Express, Fastify, NestJS, Next.js, Remix, Django, FastAPI, Flask, PostgreSQL, MongoDB). Trigger on "how do I test <tech>", "which test tool", or when setting up testing for a given framework.
---

# Stack Testing Recipes

Match the test type and tool to the technology. Always follow the pyramid: many unit, some integration, few E2E.

## React (web)
- **Unit/component:** Jest/Vitest + React Testing Library. Query by role/label/text; `userEvent` for interaction; MSW for network. No logic-by-snapshot.
- **E2E:** Playwright.

## React Native
- **Component:** React Native Testing Library + Jest (accessibility queries).
- **E2E:** Detox or Maestro on simulator/device.

## Angular
- **Unit/component:** Jasmine + Karma (CLI default) or Jest + `@testing-library/angular`/`jest-preset-angular` on a migrated repo; `TestBed` for a minimal standalone testing module. Mock HTTP with `HttpTestingController` (`provideHttpClientTesting()`).
- **E2E:** Playwright or Cypress (Protractor is retired).

## Express / Fastify
- **Unit:** test services in isolation with faked repositories.
- **Integration:** Jest + Supertest against the app factory; real DB via Testcontainers.

## NestJS
- **Unit:** instantiate providers with mocked deps (no Nest boot).
- **Integration/E2E:** `Test.createTestingModule` + Supertest; containerized DB; override only externals.

## Next.js (App Router)
- **Unit:** Jest/Vitest + RTL for client components; test server actions/route handlers/data fns as plain functions.
- **E2E:** Playwright for SSR, navigation, forms, and server actions.

## Remix / React Router 7 (framework mode)
- **Unit:** loaders/actions are plain functions — call them with a constructed `Request`, assert on the `Response`/data. No framework boot needed.
- **Component:** Jest/Vitest + RTL; wrap components using `useLoaderData`/`useFetcher` in `createRemixStub` (`@remix-run/testing`, Remix v2) or `createRoutesStub` (`react-router` v7).
- **E2E:** Playwright — include a JS-disabled pass over the critical flow (progressive enhancement is part of the contract).

## Python (general)
- **pytest** everywhere: `fixtures` for setup, `@pytest.mark.parametrize` for cases, `pytest.raises` for errors. Unit-test services/domain logic with faked collaborators — no DB, no network. Inject clock/uuid; freeze time with a fixture, not real `datetime.now`.

## Django / DRF
- **Unit:** pytest-django + `factory_boy`; test services/selectors and model methods. Mark DB-touching tests `@pytest.mark.django_db`.
- **API/integration:** DRF `APIClient`/`APIRequestFactory` against real URLs; assert status + payload + side effects. Run migrations against a containerized Postgres (Testcontainers) when prod is Postgres — don't test on SQLite substitutes.

## FastAPI
- **Unit:** test services with faked repositories; override `Depends` via `app.dependency_overrides` to inject fakes.
- **Integration:** pytest + `pytest-asyncio` + `httpx.AsyncClient` (ASGI transport) against the app factory; containerized DB for repository tests.

## Flask
- **Unit:** test services without a request context; faked repositories.
- **Integration:** pytest + the Flask test client built from `create_app(TestConfig)`; app/client/session fixtures; containerized DB, rolling back per test.

## PostgreSQL
- Integration-test repositories + migrations (up and down) against a containerized Postgres. Verify plans with `EXPLAIN ANALYZE`.

## MongoDB
- Integration-test repositories against a containerized Mongo (or in-memory server). Verify queries hit indexes with `explain()`.

## C# / ASP.NET Core Web API (.NET 8/9)
- **Unit:** xUnit + FluentAssertions; mock seams with NSubstitute/Moq. Test domain/application logic without booting the host. Inject `TimeProvider` for determinism.
- **Integration/E2E:** `WebApplicationFactory<TProgram>` (Microsoft.AspNetCore.Mvc.Testing) + `HttpClient`; real DB via **Testcontainers for .NET**. Use `[Collection]` to share fixtures; reset DB between tests.
- Run with `dotnet test`; nullable + `-warnaserror` on. arm64-native on macOS Apple Silicon.

## Avalonia desktop (C# / XAML)
- **ViewModel unit:** plain xUnit — ViewModels carry no UI dependency, so they're fast.
- **Headless UI:** `Avalonia.Headless.XUnit` with `[AvaloniaFact]`/`[AvaloniaTheory]` — control logic, layout, and bindings in-memory, no display (ideal for CI).
- **E2E UI:** **Appium** drives the compiled app via the accessibility tree; macOS requires granting the test runner Accessibility permission. Set `AutomationProperties` so controls are findable.

## .NET MAUI (mobile/desktop)
- **Unit:** xUnit + FluentAssertions on ViewModels/services — no UI dependency, so fast.
- **Integration:** DI-container resolution tests (`MauiProgram` registrations resolve); repository tests against SQLite; service tests against a faked `HttpMessageHandler`.
- **E2E:** **Appium** drives the compiled app per platform (iOS/Android/Windows/Mac Catalyst) through the accessibility tree; locate by `AutomationId`/`SemanticProperties.Description`. The `maui-expert` skill treats this as part of MAUI's own full test pyramid.

## .NET web / Blazor front-ends
- Playwright for .NET (runs natively on Apple Silicon) for full browser flows.

## Always
- Deterministic, hermetic, parallel-safe. Inject clock/uuid/random. Coverage thresholds enforced in CI. E2E tagged to run separately.
