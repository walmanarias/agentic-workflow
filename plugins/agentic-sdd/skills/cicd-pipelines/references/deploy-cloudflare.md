# Deploy: Cloudflare (Workers / Pages)

Deploy with **Wrangler**. Token-based (Cloudflare has no GitHub OIDC).

```yaml
- uses: actions/checkout@v4
- uses: actions/setup-node@v4
  with: { node-version: 20, cache: npm }
- run: npm ci
- run: npx wrangler deploy            # Workers; for Pages: npx wrangler pages deploy ./dist
  env:
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
    CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

- **Secrets (per environment):** `CLOUDFLARE_API_TOKEN` (scoped to Workers/Pages edit), `CLOUDFLARE_ACCOUNT_ID`.
- **Staging vs prod:** separate Wrangler environments (`wrangler deploy --env staging|production`) or separate Pages projects; map each to a GitHub Environment.
- **Bindings/migrations:** apply D1 migrations (`wrangler d1 migrations apply`) before the Worker deploy; hand schema design to `database-expert`.
- **Rollback:** `wrangler rollback` (Workers) or redeploy the prior Pages deployment.
