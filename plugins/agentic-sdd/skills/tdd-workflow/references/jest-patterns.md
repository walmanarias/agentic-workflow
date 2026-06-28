# Jest / Vitest patterns

## Structure
- Co-locate as `*.test.ts` or under `__tests__/`. One describe per unit; nested describe per scenario.
- AAA with blank lines separating Arrange/Act/Assert.

## Async
- `await expect(fn()).rejects.toThrow(...)` for rejections.
- Never use arbitrary `setTimeout`; use fake timers (`jest.useFakeTimers()`) and advance them.

## Test doubles
- Prefer hand-written in-memory fakes for repositories/gateways behind an interface.
- Use `jest.fn()` for verifying an interaction that is itself the contract (e.g. "publishes event X").
- Mock HTTP with MSW, not by stubbing fetch ad hoc.

## Determinism
- Inject `now()`/`uuid()`/`random()` as dependencies; pass fixed values in tests.

## Parameterized
- `it.each([...])('case %s', ...)` for boundary tables — keep one logical behavior per table.

## Coverage gate (jest.config)
- `coverageThreshold: { global: { branches, functions, lines, statements } }`.
