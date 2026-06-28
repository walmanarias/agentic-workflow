# API integration/E2E (Express / Fastify / NestJS)
- Build the app factory so tests import the same app the server uses.
- Supertest: `await request(app).post('/x').send(body).expect(201)`.
- Spin up PostgreSQL/MongoDB with Testcontainers; run migrations before the suite.
- Wrap each test in a transaction that rolls back, or truncate between tests.
- Cover: happy path, validation errors (422), authz failures (401/403), idempotency/retries.
- Tag with a separate Jest project/config so `test:e2e` runs apart from unit.
