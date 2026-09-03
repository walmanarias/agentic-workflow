---
name: angular-expert
description: Angular expertise — standalone components, signals, RxJS, dependency injection, routing, reactive forms, and Jasmine/Karma or Jest + Angular Testing Library tests. Load when implementing or testing Angular web UI; database-expert covers the data layer.
---

# Angular (web)

Write accessible, performant, well-tested standalone Angular applications in TypeScript, following the [Angular style guide](https://angular.dev/style-guide).

## Standards
- **Standalone by default:** `standalone: true` components/directives/pipes (the CLI default since v17) bootstrapped with `bootstrapApplication` + `provideRouter`/`provideHttpClient`/etc. Only author new `NgModule`s when extending an existing module-based app — match its conventions rather than mixing styles.
- **Folder layout:** organize by feature (`features/<name>/` holding its components, services, models) once the app outgrows a handful of screens; shared/presentational pieces in `shared/` or `components/ui/`, cross-cutting singletons in `core/`. One exported concept per file, named the Angular CLI way (`<name>.component.ts`/`.service.ts`/`.pipe.ts`/`.directive.ts`). See `rules/25-structure.md`.
- **Components:** small, single-responsibility, `ChangeDetectionStrategy.OnPush` by default. Presentational components take `input()`/`@Input()` and emit `output()`/`@Output()`; container/smart components own state and injected services. Prefer the built-in control-flow syntax (`@if`, `@for … track`, `@switch`) over the legacy `*ngIf`/`*ngFor` structural directives, and `@defer` to lazy-load non-critical UI.
- **State:** signals (`signal()`, `computed()`, `effect()`) for local/component state; RxJS for async streams and event composition (`HttpClient`, WebSockets, complex operators). Interop deliberately with `toSignal()`/`toObservable()` (`@angular/core/rxjs-interop`) rather than mixing manual `.subscribe()` with signals. Prefer the `async` pipe or `takeUntilDestroyed()` over hand-rolled `Subscription` bookkeeping.
- **DI:** constructor injection or the `inject()` function against interfaces/injection tokens. Scope with `providedIn: 'root'` for app-wide singletons; provide narrower services at the route or component level. Never `new` a service that has its own dependencies.
- **Forms:** Reactive Forms (`FormGroup`/`FormControl`/`FormBuilder`) with typed forms for anything beyond a trivial input; validate at the boundary and surface errors explicitly. Reserve template-driven forms for the simplest one-off cases.
- **Routing:** lazy-load feature routes (`loadComponent`/`loadChildren`); guard with functional guards (`CanActivateFn`/`CanMatchFn`), not class-based guards, in standalone apps.
- **Performance:** `OnPush` + signals/immutable inputs to minimize change-detection churn; always set `track` on `@for`; lazy-load routes and `@defer` heavy or below-the-fold UI; avoid calling functions from templates that re-run on every check (memoize with `computed()` instead).
- **Accessibility:** semantic elements first; Angular CDK's `A11yModule` (focus trapping/`LiveAnnouncer`) where native semantics fall short; manage focus on route change; test by role/label, not CSS selectors.
- **Types:** `strict: true` in `tsconfig`; precise `input()`/`Output` types; discriminated unions for variants; no `any`.

## Code style
- Lint with `angular-eslint` (the current official tooling; TSLint/`codelyzer` are retired) and follow the Angular style guide's naming and ordering conventions: `kebab-case.component.ts` files, `PascalCase` classes, members ordered `@Input`s → `@Output`s → view/content children → constructor → lifecycle hooks (in call order) → public methods → private methods.

## Testing (TDD)
- **Unit/component:** Jasmine + Karma (Angular CLI default) or Jest + `@testing-library/angular`/`jest-preset-angular` on a migrated repo — either way, configure a minimal standalone `TestBed` module, query by role/label/text (Angular Testing Library) or `DebugElement`/component harnesses (`ComponentHarness`, e.g. for Material or custom components), and assert user-visible behavior. Mock HTTP with `HttpTestingController` via `provideHttpClientTesting()`.
- **Services:** unit-test in isolation with `TestBed.inject()` or plain instantiation; fake collaborators only at real seams (HTTP, storage, time, randomness).
- No snapshot-only tests for logic; assert behavior, not rendered markup.

## Process
Detect standalone vs. `NgModule`-based and the test runner (Karma/Jasmine vs. Jest) first → follow the repo's existing patterns → write/extend tests with `tdd-test-writer` discipline → implement → verify lint (`angular-eslint`), types (`tsc --noEmit`/`ng build`), and tests. Flag accessibility and change-detection-performance risks explicitly.
