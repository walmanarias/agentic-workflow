---
name: django-expert
description: Django / DRF expertise — apps, models/ORM, migrations, serializers, viewsets, permissions, and pytest-django testing. Load for Django work; fastapi-expert and flask-expert cover the other Python stacks.
---

# Django / Django REST Framework

Build clean, secure **Django** and **DRF** applications in Python (type-hinted, modern Django 5.x).

## Architecture
- **Apps as bounded contexts:** one app per cohesive domain; keep them loosely coupled. Business rules live in a **service/selector layer** (plain functions or classes), not in views or serializers — fat models are fine for invariants, but orchestration belongs in services so it stays unit-testable.
- **App layout:** within an app, split responsibilities into `models.py`, `services.py`/`selectors.py` (promote to `services/`, `selectors/` packages as they grow), `api/` for DRF serializers+viewsets, and a `tests/` package — never one flat `views.py` doing everything. Split project settings into a `settings/` package (`base`/`dev`/`prod`). See `rules/25-structure.md`.
- **Settings split:** `base` + per-environment (`dev`/`staging`/`prod`) modules or env-driven config (`django-environ`/`pydantic-settings`); `DEBUG=False` and a real `SECRET_KEY`/`ALLOWED_HOSTS` in prod. Secrets from env, never committed.
- **Views stay thin:** DRF `ViewSet`/`APIView` (or CBVs) delegate to services; serializers handle shape + validation, not business logic.

## ORM & data
- Avoid N+1: `select_related` (FK/one-to-one) and `prefetch_related` (m2m/reverse) on list/detail queries. Push work into the DB with `annotate`/`aggregate`/`F`/`Q`, not Python loops.
- Wrap multi-write invariants in `transaction.atomic`; use `select_for_update` for contended rows. Add DB-level constraints (`UniqueConstraint`, `CheckConstraint`) and indexes, not just app checks.
- **Migrations are code:** review generated migrations; keep them reversible; test both directions. Apply the `database-expert` skill for schema/index design.

## Validation & security
- Validate at the edge: DRF serializers (`validate_<field>`/`validate`) or forms; never trust client input. Separate request serializers from response serializers; don't expose models raw.
- Lean on Django's built-ins — the ORM parameterizes queries (never string-format SQL), CSRF for session auth, `django.contrib.auth` for authn. Enforce authz with DRF permission classes + object-level checks; add throttling on public endpoints.

## Testing (TDD)
- **pytest-django** (preferred) or Django's `TestCase`. `factory_boy` for fixtures; DRF `APIClient`/`APIRequestFactory` for endpoints. Unit-test services/selectors without the DB where possible; use `pytest.mark.django_db` for ORM-touching tests.
- Integration tests hit a real/containerized Postgres (Testcontainers) for migration + repository behavior, not SQLite substitutes when prod is Postgres. Hand broad flows to `e2e-tester`.

## Process
Detect the Django version, app layout, and settings/config style first → match them → write failing tests → implement thin view + tested service + serializer → run migrations, then lint (`ruff`), types (`mypy`), and `pytest`.
