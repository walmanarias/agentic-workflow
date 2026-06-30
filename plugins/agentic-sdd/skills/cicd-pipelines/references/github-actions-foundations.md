# GitHub Actions Foundations

The skeleton every generated pipeline starts from.

## Triggers & concurrency
- `on: pull_request` for the CI gate; `on: push: branches: [main]` for deploys.
- `concurrency: { group: cicd-${{ github.ref }}, cancel-in-progress: true }` so superseded runs stop.

## Least-privilege permissions
- Set top-level `permissions: { contents: read }`. Grant more only per-job.
- Cloud deploy jobs that use OIDC add `permissions: { contents: read, id-token: write }`.

## OIDC over long-lived keys
- AWS: `aws-actions/configure-aws-credentials` with `role-to-assume` + `aws-region` (no stored access keys).
- Azure: `azure/login` with `client-id`/`tenant-id`/`subscription-id` federated credentials.
- GCP: `google-github-actions/auth` with `workload_identity_provider` + `service_account`.
- Configure the trust/federation on the cloud side once; the workflow only names the role/identity.

## Environments (the gate)
- `environment: staging` on the staging job (auto).
- `environment: production` on the prod job; set **required reviewers** in repo Settings → Environments to make deploy wait for a human click.

## Caching & pinning
- Cache deps: `actions/setup-node` with `cache: npm|pnpm|yarn`; `actions/setup-dotnet` + `actions/cache` for NuGet.
- Pin actions to a major tag (`@v4`) or a commit SHA. Never float on `@master`.

## Secrets
- Store per-environment secrets in Settings → Environments. Reference as `${{ secrets.NAME }}`. Never echo a secret.
