---
name: fastapi-expert
description: FastAPI expertise — routers, Depends DI, Pydantic v2, async SQLAlchemy, OAuth2/JWT, and httpx testing. Load for FastAPI services; django-expert and flask-expert cover the other Python stacks.
---

# FastAPI

Build clean, secure **FastAPI** services in modern async Python (3.11+), typed end to end.

## Architecture
- Layered: `routers` (HTTP only) → `services` (domain logic) → `repositories` (persistence). Routers stay thin; business rules never import the web framework or the DB driver directly.
- **Package layout:** an `app/` package split by layer (`api/routers/`, `services/`, `repositories/`, `schemas/`, `models/`, `core/` for config/deps) or per-feature packages — never a single `main.py`. Use `__init__.py` to keep boundaries explicit. Match the repo's existing structure — see `rules/25-structure.md`.
- **Dependency injection via `Depends`:** inject sessions, config, and the current user; override dependencies in tests instead of monkeypatching. Keep dependencies small and composable.
- **App factory:** build the app in a function so tests construct isolated instances; register routers, middleware, and lifespan (startup/shutdown) explicitly.

## Models & validation
- **Pydantic v2** models on every request and response; set `response_model` so outputs are filtered and documented. Separate request/response schemas from ORM entities — never return ORM objects raw.
- Config via `pydantic-settings` (`BaseSettings`), loaded once and injected; no scattered `os.environ` reads; secrets from env only.

## Async & data
- Endpoints and DB access are `async` all the way down — async SQLAlchemy 2.0 (or an async driver); never make blocking calls inside `async def` (offload CPU/blocking work to `run_in_executor`/a worker).
- One session per request via a dependency; wrap multi-write invariants in a transaction. No N+1 — eager-load relations. Apply the `database-expert` skill for schema/index design.

## Security
- OAuth2/JWT through security dependencies (`OAuth2PasswordBearer` / `Security`); enforce authz in dependencies, not scattered in handlers. Validate every input via Pydantic; return consistent error shapes (exception handlers → RFC-7807-style problem details). CORS and rate limiting configured explicitly.

## Testing (TDD)
- **pytest** + **httpx** `AsyncClient` (via ASGI transport) against the app factory; use dependency overrides to fake externals. Unit-test services with faked repositories; integration-test repositories against a real/containerized DB (Testcontainers). `pytest-asyncio` for async tests. Hand broad flows to `e2e-tester`.

## Process
Detect the app layout, Python/FastAPI version, and async-DB setup first → match them → write failing tests → implement thin router + tested service with proper `Depends` + Pydantic schemas → run lint (`ruff`), types (`mypy`), and `pytest`.
