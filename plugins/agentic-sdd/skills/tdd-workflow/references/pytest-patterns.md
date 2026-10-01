# pytest patterns

## Structure
- Tests under `tests/` mirroring the package (`tests/orders/test_service.py`) or co-located `test_*.py`.
- One behavior per test; name with the AC: `def test_rejects_duplicate_email_ac3():` or a docstring/`ids` containing `AC-3`.
- AAA with blank lines separating Arrange / Act / Assert.

## Fixtures
- Fixtures for setup; scope them as narrowly as possible (`function` by default). Share via `conftest.py`.
- Factories (`factory_boy`, or plain builder fixtures) over hand-built dicts.

## Errors & async
- `with pytest.raises(EmailTaken):` for expected errors; assert on the message/fields, not just the type.
- `pytest-asyncio` (`@pytest.mark.asyncio` or `asyncio_mode = "auto"`) for async code; `httpx.AsyncClient` with ASGI transport for FastAPI.

## Test doubles
- Fake repositories/gateways behind a Protocol or ABC; inject them. `monkeypatch` only at real seams.
- FastAPI: `app.dependency_overrides`; Django: `pytest-django` + `@pytest.mark.django_db`.

## Determinism
- Inject `now()`/`uuid4()`; freeze time with a fixture (or `time-machine`/`freezegun`), never real `datetime.now`.

## Parameterized
- `@pytest.mark.parametrize("value, expected", [...], ids=[...])` for boundary tables — one logical behavior per table.

## Coverage gate
- `pytest --cov=<pkg> --cov-report=xml` writes `coverage.xml` (cobertura) for `tools/coverage_check.py`; `--cov-fail-under=<n>` for a global floor.
