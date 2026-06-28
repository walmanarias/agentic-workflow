# Playwright setup (web)
- `npm i -D @playwright/test && npx playwright install`
- Config: `webServer` to boot the app, `baseURL`, `trace: 'on-first-retry'`, projects per browser.
- Use `getByRole`/`getByText`/`getByLabel`; avoid brittle CSS selectors.
- Seed via API or a test-only endpoint before each spec; reset DB between specs.
- Assert user-visible state and URL; use `expect(locator).toBeVisible()` (auto-waits) not sleeps.
