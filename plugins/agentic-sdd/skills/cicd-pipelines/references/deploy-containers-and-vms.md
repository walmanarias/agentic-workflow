# Deploy: Containers & VMs

Build the image once, push to a registry, then deploy. Use **OIDC** for AWS/Azure/GCP.

## Build & push (shared)
```yaml
- uses: actions/checkout@v4
- uses: docker/setup-buildx-action@v3
- uses: docker/build-push-action@v6
  with: { push: true, tags: "${{ env.IMAGE }}:${{ github.sha }}" }
```

## Targets
- **AWS ECS / App Runner:** `aws-actions/configure-aws-credentials` (OIDC `role-to-assume`) → push to ECR → `aws ecs update-service --force-new-deployment` (or App Runner deploy).
- **Azure Container Apps / App Service:** `azure/login` (OIDC) → push to ACR → `az containerapp update --image ...` (or `az webapp deploy`).
- **GCP Cloud Run:** `google-github-actions/auth` (Workload Identity) → push to Artifact Registry → `gcloud run deploy --image ...`.
- **Railway:** `railway up` / `railway redeploy` with `RAILWAY_TOKEN` (project token secret).
- **Fly.io:** `superfly/flyctl-actions` → `flyctl deploy` with `FLY_API_TOKEN`.

## VM / AWS EC2
- Prefer **SSM**: `aws ssm send-command` to pull the new image and restart the service (no inbound SSH).
- SSH fallback: `appleboy/ssh-action` with a deploy key in secrets; run a pull+restart script.
- Or **CodeDeploy** for blue/green with an `appspec.yml`.

## Notes
- Secrets per environment (registry creds via OIDC; `RAILWAY_TOKEN`/`FLY_API_TOKEN`/SSH key as Environment secrets).
- Run DB migrations as a pre-deploy step against the target environment; coordinate with `database-expert`. Python: Django `python manage.py migrate`; SQLAlchemy (FastAPI/Flask) `alembic upgrade head`.
- **Rollback:** redeploy the previous image tag / `flyctl releases rollback` / ECS task-set rollback.
