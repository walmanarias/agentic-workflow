# Rule: Testing standards

- **TDD:** Red → Green → Refactor. Write the failing test first; write the minimum to pass; refactor on green only.
- **Never weaken a test to make it pass.** If a test is wrong, fix it deliberately and explain why. Never delete assertions, add `.only`, or skip tests to go green.
- **Behavior, not internals:** assert public contracts and observable outputs. No assertions on private state or incidental call counts.
- **Deterministic & hermetic:** inject clock/uuid/random; no real network or wall-clock time; isolated, parallel-safe tests.
- **Pyramid:** many unit tests, fewer integration tests (real DB via Testcontainers), few E2E (Playwright/Detox/Supertest) for critical journeys.
- **Coverage** thresholds are enforced in CI; coverage is a floor, not the goal — cover edge and error paths.
