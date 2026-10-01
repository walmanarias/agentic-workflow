# Rule: Testing standards

- **TDD:** Red → Green → Refactor, one slice (1–3 ACs) at a time. Write the failing test first; write the minimum to pass; refactor on green only.
- **Never weaken a test to make it pass.** If a test is wrong, fix it deliberately, explain why, and add a `Test-Change: <reason>` trailer. Never delete assertions, add `.only`, or skip tests to go green (hooks block it; `sdd-allow-skip: <reason>` marks a deliberate, explained skip).
- **Traceability:** every `AC-n` is referenced by id in at least one test name; `(E2E)` ACs also by an E2E test. `/ship` checks this with `tools/ac_trace.py`.
- **Behavior, not internals:** assert public contracts and observable outputs. No assertions on private state or incidental call counts.
- **Deterministic & hermetic:** inject clock/uuid/random; no real network or wall-clock time; isolated, parallel-safe tests.
- **Pyramid:** many unit tests, fewer integration tests (real DB via Testcontainers), few E2E (Playwright/Detox/Supertest/Appium) for critical journeys.
- **Coverage:** changed-files line coverage ≥ `AGENTIC_SDD_COVERAGE` (default 80%, or the spec's DoD value), checked by `/ship` with `tools/coverage_check.py`. Coverage is a floor, not the goal — cover edge and error paths.
