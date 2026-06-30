# Deploy: Frontend Hosts (Vercel / Netlify)

For Next.js / React / static SPAs. Both give PR preview deployments.

## Vercel
```yaml
- uses: actions/checkout@v4
- run: npx vercel deploy --prebuilt --token "$VERCEL_TOKEN"            # add --prod for production
  env:
    VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
    VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
    VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
```
- PR preview: run `vercel deploy` (no `--prod`) on `pull_request` and comment the URL.
- Production: `vercel deploy --prod` from the prod environment job (after approval).

## Netlify
```yaml
- run: npx netlify deploy --dir=dist --site "$NETLIFY_SITE_ID" --auth "$NETLIFY_AUTH_TOKEN"   # add --prod for production
  env:
    NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
    NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```
- **Secrets:** Vercel — `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`; Netlify — `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`.
- **Rollback:** promote a previous deployment in the host dashboard or re-run the prior deploy.
