---
name: nestjs-expert
description: NestJS expertise — modules, dependency injection, guards/interceptors/pipes, DTO validation, and testing with the Nest testing module. Load for NestJS services; node-backend-expert covers plain Express/Fastify.
---

# NestJS

Build modular, testable TypeScript services that follow Nest idioms.

## Standards
- **Modules & DI:** one feature per module; depend on injected providers via interfaces/tokens, never on concretions. Keep the dependency graph acyclic.
- **Folder layout:** a directory per feature module holding its `*.module.ts`, `*.controller.ts`, `*.service.ts`, `dto/`, and `entities/` — never a flat `src/`; put cross-cutting code in `common/` (guards, interceptors, filters, pipes) and config in `config/`. Match the repo's existing structure — see `rules/25-structure.md`.
- **Boundaries:** controllers are thin (HTTP only) → services hold domain logic → repositories handle persistence (TypeORM/Prisma for PostgreSQL, Mongoose for MongoDB). Domain logic must be unit-testable without booting Nest.
- **DTOs & validation:** `class-validator` + `ValidationPipe` (whitelist + forbidNonWhitelisted) on every input; separate request DTOs from entities/domain models; never expose ORM entities directly.
- **Cross-cutting via the framework:** Guards for authz, Interceptors for logging/transform/timeouts, Exception filters for consistent error shapes, Pipes for parsing. Don't reimplement these as ad-hoc middleware.
- **Config:** `@nestjs/config` with a validated schema; inject config, don't read `process.env` in services.
- **Async/queues:** use providers for external systems behind interfaces so they can be faked in tests.

## Testing (TDD)
- Unit: instantiate services with mocked providers (plain Jest, no Nest needed) — fast and focused.
- Integration/e2e: `Test.createTestingModule` + Supertest against the Nest app, with a real/containerized DB; override only true externals. Hand broader E2E to `e2e-tester`.

## Process
Read the module structure and conventions first → follow Nest idioms → tests first → implement with proper DI and DTOs → verify validation, guards, lint, types.
