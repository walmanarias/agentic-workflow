# Rule: Security baseline

- Validate and sanitize all external input at the boundary (Zod / schema validation).
- Parameterized queries only — never interpolate user input into SQL or Mongo queries.
- Enforce authentication and authorization per route/action; least privilege.
- No secrets in code or logs; load secrets from validated env; deny reading `.env`/keys.
- Set security headers, CORS, and rate limits on public endpoints. Avoid leaking sensitive data in errors/logs.
