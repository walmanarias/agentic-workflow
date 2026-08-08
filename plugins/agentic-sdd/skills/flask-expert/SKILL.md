---
name: flask-expert
description: Flask expertise — application factory, blueprints, extensions (SQLAlchemy, Marshmallow), auth, and Flask test client testing. Load for Flask apps; fastapi-expert and django-expert cover the other Python stacks.
---

# Flask

Build clean, secure **Flask** applications in modern Python (type-hinted where it helps).

## Architecture
- **Application factory** (`create_app(config)`) so each test/environment gets an isolated app; register **blueprints** per feature and initialize extensions on the app inside the factory (no import-time globals bound to a single app).
- Layered: `views/blueprints` (HTTP only) → `services` (domain logic) → `repositories`/models (persistence). Keep business rules out of view functions so they stay unit-testable without a request context.
- **Package layout:** a package with the factory in `__init__.py`/`app.py`, one folder per blueprint/feature (routes + schemas + services together), plus `models/`, `services/`, `extensions.py`, and `config.py` — never a single flat `app.py`. Match the repo's existing structure — see `rules/25-structure.md`.
- **Config classes** per environment (`Dev`/`Prod`/`Test`) selected via env; secrets from env, never in source; `DEBUG`/`TESTING` off in prod.

## Validation & data
- Validate at the edge with **Marshmallow** (or Pydantic) schemas on every request body/args; separate load (request) from dump (response) schemas — never serialize ORM models raw.
- Persistence via Flask-SQLAlchemy (or SQLAlchemy core) behind a repository boundary; wrap multi-write invariants in a transaction; avoid N+1 with eager loading. Apply the `database-expert` skill for schema/index design.

## Security
- AuthN via Flask-Login or JWT (Flask-JWT-Extended); enforce authz explicitly per route/blueprint (decorators or before-request guards). CSRF protection for session-based form flows. Set security headers, CORS, and rate limiting explicitly; consistent JSON error handlers (register on the app, map exceptions → problem-details shapes).

## Testing (TDD)
- **pytest** + the **Flask test client** built from the factory with a `Test` config; use fixtures for the app/client/session. Unit-test services with faked repositories; integration-test repositories against a real/containerized DB (Testcontainers), rolling back per test. Hand broad flows to `e2e-tester`.

## Process
Detect the factory/blueprint layout, extensions, and config style first → match them → write failing tests → implement thin view + tested service + schema → run lint (`ruff`), types (`mypy`), and `pytest`.
