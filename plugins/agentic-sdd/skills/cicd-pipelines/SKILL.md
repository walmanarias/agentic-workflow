---
name: cicd-pipelines
description: Use when setting up or changing a project's CI/CD — generating GitHub Actions pipelines that build, test, and deploy. Trigger on "ci/cd", "pipeline", "deploy", "github actions", "release", "staging", "production", or a deploy target (Cloudflare, AWS, Azure, GCP, Railway, Fly.io, Vercel, Netlify, EAS, npm, NuGet).
---

# CI/CD Pipelines (GitHub Actions)

Generate full build → test → deploy pipelines tailored to the project's stack. GitHub Actions only. Default promotion: **staging → manual approval → production**.

## Default promotion model

```
PR opened     → CI: lint · typecheck · test · build     (permissions: contents: read)
merge → main  → CI → deploy STAGING                      (environment: staging, auto)
                     → deploy PRODUCTION                 (environment: production = required reviewers → manual approval)
```

Production is gated by a GitHub **Environment** with required reviewers — approval is a human click, not a tag. Rollback: re-run the prior green deploy, or revert + redeploy.

## Stage anatomy

1. **CI gate** — mirror the local commit hooks: Node = lint + typecheck + test + build; .NET = `dotnet format --verify-no-changes` + `build -warnaserror` + `test`; Python = `ruff check` + `ruff format --check` + `mypy` + `pytest`. Block deploy on red.
2. **Build artifact** — produce the deployable (image, bundle, package) once; reuse across environments.
3. **Deploy staging** — auto on merge to `main`; run smoke checks.
4. **Approval** — `environment: production` with required reviewers.
5. **Deploy production** — after approval; verify post-deploy; keep rollback ready.

## Target → mechanism → reference

| App / target | Deploy mechanism | Reference |
|---|---|---|
| Cloudflare Workers / Pages | Wrangler | `references/deploy-cloudflare.md` |
| Containerized API (AWS ECS/App Runner, Azure Container Apps/App Service, GCP Cloud Run, Railway, Fly.io) | Build image → push → deploy | `references/deploy-containers-and-vms.md` |
| Python API (Django / FastAPI / Flask) | Build image → push → deploy (+ run migrations) | `references/deploy-containers-and-vms.md` |
| VM / AWS EC2 | SSM / SSH / CodeDeploy | `references/deploy-containers-and-vms.md` |
| Next.js / React / SPA | Vercel / Netlify (+ PR previews) | `references/deploy-frontend-hosts.md` |
| React Native app | EAS / Fastlane → TestFlight / Play | `references/deploy-mobile-and-packages.md` |
| Library (npm / NuGet) | Publish on release | `references/deploy-mobile-and-packages.md` |

## Security baseline

- Least-privilege `permissions:` — default `contents: read`; add `id-token: write` only on jobs that assume a cloud role via **OIDC** (prefer OIDC over long-lived keys).
- Pin actions to a major version or SHA; set `concurrency` with `cancel-in-progress` for CI.
- Secrets live in GitHub **Environment** secrets (per staging/production), never in YAML or logs.

See `references/github-actions-foundations.md` (skeleton) and `references/build-and-test.md` (gate), and `references/examples/full-cicd.yml` for a working default pipeline.
