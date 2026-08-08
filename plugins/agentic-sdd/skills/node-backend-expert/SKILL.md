---
name: node-backend-expert
description: Express / Fastify API expertise — layered architecture, validation at the edge, auth, error handling, and Jest + Supertest testing. Load for plain Node HTTP backends; nestjs-expert covers NestJS.
---

# Node.js backends (Express / Fastify)

Build clean, secure Node.js APIs in TypeScript on **Express** or **Fastify**.

## Architecture
- Layered/hexagonal: `routes/controllers` → `services` (domain logic) → `repositories` (DB). Controllers stay thin; business rules never touch the framework or the driver directly.
- **Folder layout:** organize into layer folders (`routes/`, `controllers/`, `services/`, `repositories/`, `schemas/`, `middleware/`) or feature-first modules (`modules/<feature>/` each holding its own route/service/repo), with shared code in `shared/`/`lib/` — never a flat `src/`. Match the repo's existing structure — see `rules/25-structure.md`.
- **Validation at the edge:** Zod (or Fastify JSON Schema / TypeBox) on every request body, params, and query. Never trust input.
- **Config:** validated env (Zod) loaded once; no `process.env` reads scattered through code; secrets never hard-coded.

## Framework specifics
- **Express:** central async error middleware (wrap handlers so rejections are caught), helmet, cors, rate limiting, request-id + structured logging (pino).
- **Fastify:** lean on the plugin system and schema-based validation/serialization; use decorators and hooks; register routes as encapsulated plugins; prefer schemas for speed and docs.

## Cross-cutting
- AuthN/AuthZ checked per route; principle of least privilege. Consistent typed error responses (problem-details style). Idempotency for unsafe retried operations. Pagination on list endpoints. Graceful shutdown and health/readiness probes.
- DB access follows the `database-expert` skill's patterns; no N+1; use transactions for multi-write invariants.

## Testing (TDD)
- Jest + Supertest against the built app. Integration tests hit a real/containerized DB (Testcontainers), not mocks, for repository and route tests. Unit-test services in isolation. Hand E2E/contract suites to `e2e-tester`.

## Process
Detect Express vs Fastify and existing structure → match it → write failing tests → implement thin controller + tested service → verify security, validation, lint, types.
