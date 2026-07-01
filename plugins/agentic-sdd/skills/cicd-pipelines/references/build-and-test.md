# Build & Test Gate

The CI job mirrors the local commit hooks so CI and local enforce the same bar. Auto-detect the stack and run only what applies.

## Node / TypeScript (Jest/Vitest)
```yaml
- uses: actions/setup-node@v4
  with: { node-version: 20, cache: npm }
- run: npm ci
- run: npm run lint --if-present
- run: npm run typecheck --if-present
- run: npm test --if-present -- --ci
- run: npm run build --if-present
```

## .NET (xUnit)
```yaml
- uses: actions/setup-dotnet@v4
  with: { dotnet-version: |
    8.0.x
    9.0.x }
- run: dotnet restore
- run: dotnet format --verify-no-changes
- run: dotnet build --no-restore -warnaserror
- run: dotnet test --no-build --verbosity normal
```

## Python (pytest — Django / FastAPI / Flask)
```yaml
- uses: actions/setup-python@v5
  with: { python-version: '3.12', cache: pip }
- run: pip install -r requirements.txt   # or: pip install -e ".[dev]"
- run: ruff check .
- run: ruff format --check .
- run: mypy .                            # if the project configures mypy
- run: pytest --cov                      # Django: pytest-django (DJANGO_SETTINGS_MODULE set)
```

- Provision service containers (Postgres/Mongo) via `services:` for integration tests, or let Testcontainers manage them.
- Django: run `python manage.py migrate --check` (or apply migrations) before the suite; keep `SECRET_KEY`/`DJANGO_SETTINGS_MODULE` in CI env.

## Rules
- Block all deploy jobs on a red gate (`needs: ci`).
- Tag slow E2E suites (Playwright/Detox/Appium/Testcontainers) to run in a separate job; gate prod on them when they cover the deploy surface.
- Upload coverage/artifacts where useful; keep the gate fast (cache deps, fail fast).
