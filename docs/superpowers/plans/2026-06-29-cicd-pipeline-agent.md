# CI/CD Pipeline Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `cicd-engineer` agent + `cicd-pipelines` skill + `/cicd` command to the `agentic-sdd` plugin that generates full GitHub Actions CI/CD pipelines (build → test → deploy) tailored to a project's stack.

**Architecture:** Content-only feature — markdown agent/command/skill files plus one validated example workflow. The agent detects the stack and deploy target, applies the skill, and writes `.github/workflows/*.yml`. The skill holds the reusable model + per-target recipes in `references/`. A canonical example workflow under the skill is validated by `actionlint` in the plugin's own CI.

**Tech Stack:** Markdown (Claude Code plugin format), GitHub Actions YAML, `actionlint`, the repo's existing plugin-validation CI (`.github/workflows/ci.yml`).

## Global Constraints

- **CI platform:** GitHub Actions only. No GitLab/Azure Pipelines output.
- **Default promotion model:** staging → **manual approval** (GitHub Environment + required reviewers) → production. No tag-trigger by default.
- **Names (verbatim):** agent `cicd-engineer`; command `/cicd`; skill `cicd-pipelines`.
- **Agent frontmatter:** `tools: Read, Write, Edit, Grep, Glob, Bash` and `model: opus` (match the stack experts).
- **Command frontmatter:** `allowed-tools: Read, Write, Edit, Grep, Glob, Bash` and `model: opus`.
- **Skill frontmatter:** `name` + `description` only (no tools/model) — match `e2e-testing`.
- **Agent behavior rule (verbatim intent):** never deploy, push, or write a secret value; author workflow files + a setup checklist only.
- **Security baseline in generated pipelines:** least-privilege `permissions:` (default `contents: read`; `id-token: write` only on cloud-deploy jobs); OIDC over long-lived keys; pinned actions; `concurrency` + `cancel-in-progress`; Environment secrets.
- **Counts after this feature:** agents 15→**16**, commands 12→**13**, skills 5→**6**.
- **Deploy targets covered by references:** Cloudflare (Workers/Pages); containerized cloud (AWS ECS/App Runner, Azure Container Apps/App Service, GCP Cloud Run, Railway, Fly.io); VM/EC2 (SSM/SSH); frontend hosts (Vercel/Netlify); mobile (RN via EAS/Fastlane); packages (npm/NuGet).

---

## File Structure

**Create:**
- `plugins/agentic-sdd/skills/cicd-pipelines/SKILL.md` — the playbook (model, stage anatomy, decision table, security baseline).
- `plugins/agentic-sdd/skills/cicd-pipelines/references/examples/full-cicd.yml` — actionlint-validated canonical pipeline (staging → approval → prod).
- `plugins/agentic-sdd/skills/cicd-pipelines/references/github-actions-foundations.md` — workflow skeleton, permissions, OIDC, concurrency, caching, pinning, environments.
- `plugins/agentic-sdd/skills/cicd-pipelines/references/build-and-test.md` — the CI gate per stack (mirrors the local hooks).
- `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-cloudflare.md`
- `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-containers-and-vms.md`
- `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-frontend-hosts.md`
- `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-mobile-and-packages.md`
- `plugins/agentic-sdd/agents/cicd-engineer.md`
- `plugins/agentic-sdd/commands/cicd.md`

**Modify:**
- `.github/workflows/ci.yml` — add an `actionlint` step for the example + an installer assertion for the new agent + extend the YAML-parse glob.
- `CLAUDE.md` — command/agent/skill tables, counts, one-line note.
- `README.md` — counts, lists, CI note.
- `plugins/agentic-sdd/.claude-plugin/plugin.json` — keywords.

---

## Task 1: `cicd-pipelines` skill + canonical example workflow

**Files:**
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/SKILL.md`
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/references/examples/full-cicd.yml`

**Interfaces:**
- Produces: skill named `cicd-pipelines`; the reference paths `references/github-actions-foundations.md`, `references/build-and-test.md`, `references/deploy-cloudflare.md`, `references/deploy-containers-and-vms.md`, `references/deploy-frontend-hosts.md`, `references/deploy-mobile-and-packages.md`, `references/examples/full-cicd.yml` (created in later tasks). Consumed by Tasks 4 (agent), 5 (command), 6 (CI), 7 (docs).

- [ ] **Step 1: Write the canonical example workflow**

Create `plugins/agentic-sdd/skills/cicd-pipelines/references/examples/full-cicd.yml`:

```yaml
# Canonical agentic-sdd CI/CD pipeline: staging -> manual approval -> production.
# Replace the echo placeholders with the project's gate (references/build-and-test.md)
# and target deploy steps (references/deploy-*.md). Validated by actionlint.
name: CI/CD

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: cicd-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  ci:
    name: Build & test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Gate (lint, typecheck, test, build)
        run: echo "Replace with the stack gate — see references/build-and-test.md"

  deploy-staging:
    name: Deploy (staging)
    needs: ci
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to staging
        run: echo "Replace with the target deploy — see references/deploy-*.md"

  deploy-production:
    name: Deploy (production)
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        run: echo "Replace with the target deploy — see references/deploy-*.md"
```

- [ ] **Step 2: Verify the example is valid GitHub Actions (test)**

Run:
```bash
docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7 -color \
  plugins/agentic-sdd/skills/cicd-pipelines/references/examples/full-cicd.yml
```
Expected: exit 0, no findings. (If Docker is unavailable locally, install the binary: `bash <(curl -s https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash) 1.7.7` then `./actionlint <path>`.) The manual-approval gate is the `environment: production` block — required reviewers are configured in GitHub repo settings, not YAML.

- [ ] **Step 3: Write `SKILL.md`**

Create `plugins/agentic-sdd/skills/cicd-pipelines/SKILL.md`:

````markdown
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

1. **CI gate** — mirror the local commit hooks: Node = lint + typecheck + test + build; .NET = `dotnet format --verify-no-changes` + `build -warnaserror` + `test`. Block deploy on red.
2. **Build artifact** — produce the deployable (image, bundle, package) once; reuse across environments.
3. **Deploy staging** — auto on merge to `main`; run smoke checks.
4. **Approval** — `environment: production` with required reviewers.
5. **Deploy production** — after approval; verify post-deploy; keep rollback ready.

## Target → mechanism → reference

| App / target | Deploy mechanism | Reference |
|---|---|---|
| Cloudflare Workers / Pages | Wrangler | `references/deploy-cloudflare.md` |
| Containerized API (AWS ECS/App Runner, Azure Container Apps/App Service, GCP Cloud Run, Railway, Fly.io) | Build image → push → deploy | `references/deploy-containers-and-vms.md` |
| VM / AWS EC2 | SSM / SSH / CodeDeploy | `references/deploy-containers-and-vms.md` |
| Next.js / React / SPA | Vercel / Netlify (+ PR previews) | `references/deploy-frontend-hosts.md` |
| React Native app | EAS / Fastlane → TestFlight / Play | `references/deploy-mobile-and-packages.md` |
| Library (npm / NuGet) | Publish on release | `references/deploy-mobile-and-packages.md` |

## Security baseline

- Least-privilege `permissions:` — default `contents: read`; add `id-token: write` only on jobs that assume a cloud role via **OIDC** (prefer OIDC over long-lived keys).
- Pin actions to a major version or SHA; set `concurrency` with `cancel-in-progress` for CI.
- Secrets live in GitHub **Environment** secrets (per staging/production), never in YAML or logs.

See `references/github-actions-foundations.md` (skeleton) and `references/build-and-test.md` (gate), and `references/examples/full-cicd.yml` for a working default pipeline.
````

- [ ] **Step 4: Verify frontmatter + example presence (test)**

Run:
```bash
S=plugins/agentic-sdd/skills/cicd-pipelines
head -1 "$S/SKILL.md" | grep -q '^---' && echo "frontmatter ok"
grep -q '^name: cicd-pipelines$' "$S/SKILL.md" && echo "name ok"
test -f "$S/references/examples/full-cicd.yml" && echo "example ok"
```
Expected: `frontmatter ok`, `name ok`, `example ok`.

- [ ] **Step 5: Commit**

```bash
git add plugins/agentic-sdd/skills/cicd-pipelines/SKILL.md \
        plugins/agentic-sdd/skills/cicd-pipelines/references/examples/full-cicd.yml
git commit -m "feat(cicd): add cicd-pipelines skill + validated example pipeline"
```

---

## Task 2: Foundations + build-and-test references

**Files:**
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/references/github-actions-foundations.md`
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/references/build-and-test.md`

**Interfaces:**
- Consumes: the `cicd-pipelines` skill from Task 1 (referenced by `SKILL.md`).
- Produces: the two reference files named in `SKILL.md`'s closing pointer.

- [ ] **Step 1: Write `github-actions-foundations.md`**

Create `plugins/agentic-sdd/skills/cicd-pipelines/references/github-actions-foundations.md`:

```markdown
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
```

- [ ] **Step 2: Write `build-and-test.md`**

Create `plugins/agentic-sdd/skills/cicd-pipelines/references/build-and-test.md`:

```markdown
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

## Rules
- Block all deploy jobs on a red gate (`needs: ci`).
- Tag slow E2E suites (Playwright/Detox/Appium/Testcontainers) to run in a separate job; gate prod on them when they cover the deploy surface.
- Upload coverage/artifacts where useful; keep the gate fast (cache deps, fail fast).
```

- [ ] **Step 3: Verify references resolve (test)**

Run:
```bash
S=plugins/agentic-sdd/skills/cicd-pipelines
for r in github-actions-foundations build-and-test; do
  test -f "$S/references/$r.md" && echo "ok $r"
done
grep -q 'references/github-actions-foundations.md' "$S/SKILL.md" && echo "linked foundations"
grep -q 'references/build-and-test.md' "$S/SKILL.md" && echo "linked build-and-test"
```
Expected: `ok github-actions-foundations`, `ok build-and-test`, `linked foundations`, `linked build-and-test`.

- [ ] **Step 4: Commit**

```bash
git add plugins/agentic-sdd/skills/cicd-pipelines/references/github-actions-foundations.md \
        plugins/agentic-sdd/skills/cicd-pipelines/references/build-and-test.md
git commit -m "feat(cicd): add foundations + build-and-test references"
```

---

## Task 3: Deploy-target references

**Files:**
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-cloudflare.md`
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-containers-and-vms.md`
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-frontend-hosts.md`
- Create: `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-mobile-and-packages.md`

**Interfaces:**
- Consumes: the decision table in `SKILL.md` (Task 1) that names these four files.
- Produces: nothing later tasks import beyond file existence (checked in Task 6 CI).

- [ ] **Step 1: Write `deploy-cloudflare.md`**

Create `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-cloudflare.md`:

```markdown
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
```

- [ ] **Step 2: Write `deploy-containers-and-vms.md`**

Create `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-containers-and-vms.md`:

```markdown
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
- Run DB migrations as a pre-deploy step against the target environment; coordinate with `database-expert`.
- **Rollback:** redeploy the previous image tag / `flyctl releases rollback` / ECS task-set rollback.
```

- [ ] **Step 3: Write `deploy-frontend-hosts.md`**

Create `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-frontend-hosts.md`:

```markdown
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
```

- [ ] **Step 4: Write `deploy-mobile-and-packages.md`**

Create `plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-mobile-and-packages.md`:

```markdown
# Deploy: Mobile & Packages

## React Native (EAS / Fastlane)
```yaml
- uses: actions/checkout@v4
- uses: actions/setup-node@v4
  with: { node-version: 20, cache: npm }
- run: npm ci
- run: npx eas-cli build --platform all --non-interactive --no-wait
  env: { EXPO_TOKEN: ${{ secrets.EXPO_TOKEN }} }
- run: npx eas-cli submit --platform all --non-interactive          # TestFlight / Play (prod job, after approval)
  env: { EXPO_TOKEN: ${{ secrets.EXPO_TOKEN }} }
```
- Bare RN: Fastlane lanes (`fastlane beta`/`release`) with App Store Connect API key + Play service-account JSON in secrets.
- Staging = internal/TestFlight track; production = store release after approval.

## npm
```yaml
- uses: actions/setup-node@v4
  with: { node-version: 20, registry-url: "https://registry.npmjs.org" }
- run: npm ci
- run: npm publish --provenance --access public
  env: { NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }} }
```
- `--provenance` requires `permissions: { id-token: write }`. Trigger on GitHub Release.

## NuGet
```yaml
- uses: actions/setup-dotnet@v4
  with: { dotnet-version: 9.0.x }
- run: dotnet pack -c Release -o out
- run: dotnet nuget push "out/*.nupkg" --api-key "$NUGET_API_KEY" --source https://api.nuget.org/v3/index.json
  env: { NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }} }
```
- **Rollback:** deprecate/unlist the bad version and publish a fixed one (registries are immutable).
```

- [ ] **Step 5: Verify all four references exist and are linked (test)**

Run:
```bash
S=plugins/agentic-sdd/skills/cicd-pipelines
for r in deploy-cloudflare deploy-containers-and-vms deploy-frontend-hosts deploy-mobile-and-packages; do
  test -f "$S/references/$r.md" || { echo "MISSING $r"; exit 1; }
  grep -q "references/$r.md" "$S/SKILL.md" || { echo "NOT LINKED $r"; exit 1; }
  echo "ok $r"
done
```
Expected: `ok` for all four.

- [ ] **Step 6: Commit**

```bash
git add plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-cloudflare.md \
        plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-containers-and-vms.md \
        plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-frontend-hosts.md \
        plugins/agentic-sdd/skills/cicd-pipelines/references/deploy-mobile-and-packages.md
git commit -m "feat(cicd): add per-target deploy references"
```

---

## Task 4: `cicd-engineer` agent

**Files:**
- Create: `plugins/agentic-sdd/agents/cicd-engineer.md`

**Interfaces:**
- Consumes: the `cicd-pipelines` skill (Task 1).
- Produces: agent named `cicd-engineer` (referenced by the `/cicd` command in Task 5 and the docs in Task 7).

- [ ] **Step 1: Write the agent**

Create `plugins/agentic-sdd/agents/cicd-engineer.md`:

```markdown
---
name: cicd-engineer
description: Use to set up or change a project's CI/CD — generate and maintain GitHub Actions pipelines that build, test, and deploy. Triggers on "ci/cd", "pipeline", "deploy", "github actions", "release", or a deploy target (Cloudflare, AWS, Azure, GCP, Railway, Fly.io, Vercel, Netlify, EAS, npm, NuGet). Defaults to staging → manual-approval → production.
tools: Read, Write, Edit, Grep, Glob, Bash
model: opus
---

You generate and maintain **GitHub Actions CI/CD pipelines** tailored to the repo's stack, applying the `cicd-pipelines` skill. Default promotion: **staging → manual approval → production**.

## Process
1. Detect the stack (`package.json`, `*.sln`/`*.csproj`) and existing workflows under `.github/workflows/`.
2. Confirm with the user: deploy target(s), environment model (default staging → approval → prod), and the secrets/OIDC strategy.
3. Apply the `cicd-pipelines` skill; write `.github/workflows/*.yml`. Extend an existing `ci.yml` rather than clobber it.
4. Validate: run `actionlint` if available and fix every finding.
5. Output a **required secrets / OIDC trust setup** checklist and rollback notes.

## Principles
- CI gate mirrors the local commit hooks (Node: lint + typecheck + test + build; .NET: `format` + `build -warnaserror` + `test`). Block deploy on red.
- Least-privilege `permissions:` (default `contents: read`; `id-token: write` only where a job assumes a cloud role). Prefer **OIDC** over long-lived keys.
- `environment: production` with required reviewers = the manual gate. `concurrency` + `cancel-in-progress`. Pin actions. Cache deps.

## Collaboration
- Pull the matching **stack expert** for build/test specifics, **database-expert** for migration steps in deploy jobs, and wire **e2e-tester**'s tagged suites as a pre-deploy gate.

## Rules
- Never deploy, push, or write a secret value — author workflow files and a setup checklist only.
- One concern per workflow file; staging must pass before prod; always document required secrets/variables, the OIDC trust setup, and rollback.
```

- [ ] **Step 2: Verify agent frontmatter and content (test)**

Run:
```bash
A=plugins/agentic-sdd/agents/cicd-engineer.md
head -1 "$A" | grep -q '^---' && echo "frontmatter ok"
grep -q '^name: cicd-engineer$' "$A" && echo "name ok"
grep -q '^tools: Read, Write, Edit, Grep, Glob, Bash$' "$A" && echo "tools ok"
grep -q '^model: opus$' "$A" && echo "model ok"
grep -q 'cicd-pipelines' "$A" && echo "skill linked"
```
Expected: `frontmatter ok`, `name ok`, `tools ok`, `model ok`, `skill linked`.

- [ ] **Step 3: Commit**

```bash
git add plugins/agentic-sdd/agents/cicd-engineer.md
git commit -m "feat(cicd): add cicd-engineer agent"
```

---

## Task 5: `/cicd` command

**Files:**
- Create: `plugins/agentic-sdd/commands/cicd.md`

**Interfaces:**
- Consumes: the `cicd-engineer` agent (Task 4) and the `cicd-pipelines` skill (Task 1).

- [ ] **Step 1: Write the command**

Create `plugins/agentic-sdd/commands/cicd.md`:

```markdown
---
description: Generate or update a full GitHub Actions CI/CD pipeline (build → test → deploy) for this project.
argument-hint: [deploy target and/or app path; optional environment model]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: opus
---

Invoke the `cicd-engineer` agent for: **$ARGUMENTS**

Follow the `cicd-pipelines` skill. Detect the stack, confirm the deploy target(s), environment model (default **staging → manual approval → production**), and secrets/OIDC strategy with the user, then write `.github/workflows/*.yml`. Validate with `actionlint`. Output the required secrets / OIDC setup checklist and rollback notes. Do **not** deploy or push. This complements `/ship`, which verifies the pipeline is green before release.
```

- [ ] **Step 2: Verify command frontmatter and delegation (test)**

Run:
```bash
C=plugins/agentic-sdd/commands/cicd.md
head -1 "$C" | grep -q '^---' && echo "frontmatter ok"
grep -q 'allowed-tools: Read, Write, Edit, Grep, Glob, Bash' "$C" && echo "tools ok"
grep -q 'cicd-engineer' "$C" && echo "delegates to agent"
grep -q 'cicd-pipelines' "$C" && echo "skill linked"
```
Expected: `frontmatter ok`, `tools ok`, `delegates to agent`, `skill linked`.

- [ ] **Step 3: Commit**

```bash
git add plugins/agentic-sdd/commands/cicd.md
git commit -m "feat(cicd): add /cicd command"
```

---

## Task 6: Plugin-validation CI — actionlint + installer assertion

**Files:**
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: the example workflow (Task 1) and the `cicd-engineer` agent (Task 4).

- [ ] **Step 1: Extend the YAML-parse glob to cover skill example workflows**

In `.github/workflows/ci.yml`, in the `YAML workflows parse` step, replace this line:

```python
          for f in glob.glob('.github/workflows/*.yml') + glob.glob('templates/*.yml'):
```
with:
```python
          for f in (glob.glob('.github/workflows/*.yml') + glob.glob('templates/*.yml')
                    + glob.glob('plugins/agentic-sdd/skills/*/references/examples/*.yml')):
```

- [ ] **Step 2: Add an `actionlint` step after the `YAML workflows parse` step**

Insert this step immediately after the `YAML workflows parse` step (before `Agent / command / skill frontmatter present`):

```yaml
      - name: actionlint example pipelines
        run: |
          docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7 -color \
            plugins/agentic-sdd/skills/cicd-pipelines/references/examples/*.yml
```

- [ ] **Step 3: Assert the new agent installs (regression guard)**

In the `Copy installer runs end-to-end` step, after the line:
```bash
          test -f "$TMP/.claude/agents/dotnet-expert.md"
```
add:
```bash
          test -f "$TMP/.claude/agents/cicd-engineer.md"
          test -f "$TMP/.claude/skills/cicd-pipelines/SKILL.md"
```

- [ ] **Step 4: Verify the CI file still parses and the checks pass locally (test)**

Run:
```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); print('ci.yml parses')"
docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7 -color \
  plugins/agentic-sdd/skills/cicd-pipelines/references/examples/*.yml && echo "actionlint clean"
TMP="$(mktemp -d)/app"; mkdir -p "$TMP"; echo '{"scripts":{}}' > "$TMP/package.json"
bash scripts/install.sh "$TMP" >/dev/null
test -f "$TMP/.claude/agents/cicd-engineer.md" && test -f "$TMP/.claude/skills/cicd-pipelines/SKILL.md" && echo "installer carries cicd files"
```
Expected: `ci.yml parses`, `actionlint clean`, `installer carries cicd files`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: actionlint example pipelines + assert cicd files install"
```

---

## Task 7: Docs wiring — CLAUDE.md, README.md, plugin.json

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `plugins/agentic-sdd/.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: the names `cicd-engineer`, `/cicd`, `cicd-pipelines` from Tasks 1, 4, 5.

- [ ] **Step 1: CLAUDE.md — add `/cicd` to the command table**

Add this row immediately after the `/refactor` row in the command table:
```markdown
| `/cicd <target>` | Generates/updates a full GitHub Actions CI/CD pipeline (build→test→deploy, stack-aware) | `cicd-engineer` |
```

- [ ] **Step 2: CLAUDE.md — add `cicd-engineer` to the lifecycle agents table**

Add this row after the `refactorer` row in the lifecycle agents table:
```markdown
| `cicd-engineer` | Generates GitHub Actions CI/CD pipelines (build→test→deploy); default staging→approval→prod | `.github/workflows/` |
```

- [ ] **Step 3: CLAUDE.md — add `cicd-pipelines` to the skills table**

Add this row after the `stack-testing-recipes` row in the skills table:
```markdown
| `cicd-pipelines` | Generating a CI/CD pipeline — promotion model, per-target deploy recipes, security baseline |
```

- [ ] **Step 4: CLAUDE.md — bump the repo-layout counts**

Replace:
```
│       ├── agents/                ← 15 agents (lifecycle + stack experts)
│       ├── commands/              ← 12 slash commands
```
with:
```
│       ├── agents/                ← 16 agents (lifecycle + stack experts)
│       ├── commands/              ← 13 slash commands
```
and replace:
```
│       ├── skills/                ← 5 skills (+ references)
```
with:
```
│       ├── skills/                ← 6 skills (+ references)
```

- [ ] **Step 5: README.md — update counts and lists**

Replace the agents bullet:
```markdown
- **15 agents** — 7 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `code-reviewer`, `refactorer`) + 8 stack experts
```
with:
```markdown
- **16 agents** — 8 lifecycle agents (`architect`, `spec-writer`, `tdd-test-writer`, `implementer`, `e2e-tester`, `code-reviewer`, `refactorer`, `cicd-engineer`) + 8 stack experts
```
(keep the rest of that bullet's text after `8 stack experts` unchanged.)

Then replace:
```markdown
- **12 commands** — `/feature`, `/plan`, `/spec`, `/tdd`, `/implement`, `/e2e`, `/review`, `/refactor`, `/update-pr`, `/triage-copilot`, `/triage-reviews`, `/ship`.
```
with:
```markdown
- **13 commands** — `/feature`, `/plan`, `/spec`, `/tdd`, `/implement`, `/e2e`, `/review`, `/refactor`, `/cicd`, `/update-pr`, `/triage-copilot`, `/triage-reviews`, `/ship`.
```
and replace:
```markdown
- **5 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `clean-code`, `stack-testing-recipes`.
```
with:
```markdown
- **6 skills** — `spec-driven-development`, `tdd-workflow`, `e2e-testing`, `clean-code`, `stack-testing-recipes`, `cicd-pipelines`.
```

- [ ] **Step 6: README.md — note the agent in the CI section**

In the `## CI: two separate things` section, append a third bullet:
```markdown
- **A tailored full pipeline** is what the `/cicd` command (the `cicd-engineer` agent) generates per project — build + test + deploy with a staging → manual-approval → production flow. It can read and extend the static `ci.yml` rather than replace it.
```

- [ ] **Step 7: plugin.json — add keywords**

In `plugins/agentic-sdd/.claude-plugin/plugin.json`, in the `keywords` array, add after `"mongodb"`:
```json
    "ci-cd",
    "github-actions",
    "deployment",
    "devops",
```

- [ ] **Step 8: Verify docs consistency (test)**

Run:
```bash
grep -q '/cicd' CLAUDE.md && grep -q 'cicd-engineer' CLAUDE.md && grep -q 'cicd-pipelines' CLAUDE.md && echo "CLAUDE.md ok"
grep -q '16 agents' CLAUDE.md && grep -q '13 slash commands' CLAUDE.md && grep -q '6 skills' CLAUDE.md && echo "CLAUDE.md counts ok"
grep -q '13 commands' README.md && grep -q '6 skills' README.md && grep -q '/cicd' README.md && echo "README ok"
python3 -c "import json; d=json.load(open('plugins/agentic-sdd/.claude-plugin/plugin.json')); assert 'github-actions' in d['keywords']; print('plugin.json ok')"
```
Expected: `CLAUDE.md ok`, `CLAUDE.md counts ok`, `README ok`, `plugin.json ok`.

- [ ] **Step 9: Run the full plugin-validation checks locally (test)**

Run:
```bash
for f in .claude-plugin/marketplace.json plugins/agentic-sdd/.claude-plugin/plugin.json \
         plugins/agentic-sdd/hooks/hooks.json plugins/agentic-sdd/settings.template.json; do
  python3 -c "import json; json.load(open('$f'))" && echo "ok $f"
done
for f in plugins/agentic-sdd/agents/*.md plugins/agentic-sdd/commands/*.md plugins/agentic-sdd/skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---' || { echo "MISSING frontmatter: $f"; exit 1; }
done
echo "frontmatter ok"
```
Expected: every manifest `ok`, and `frontmatter ok`.

- [ ] **Step 10: Commit**

```bash
git add CLAUDE.md README.md plugins/agentic-sdd/.claude-plugin/plugin.json
git commit -m "docs(cicd): wire /cicd, cicd-engineer, cicd-pipelines into CLAUDE.md, README, plugin.json"
```

---

## Self-Review

**Spec coverage:**
- Smart-generator agent → Task 4. ✓
- GitHub Actions only → Global Constraints + every reference. ✓
- Default staging → manual-approval → prod → Task 1 example (`environment: production`) + SKILL.md + agent. ✓
- Agent + skill + command structure → Tasks 1–5. ✓
- All deploy targets → Task 3 references (Cloudflare, containers/VMs incl. EC2, frontend hosts, mobile, packages). ✓
- Docs wiring (CLAUDE.md/README/plugin.json, counts) → Task 7. ✓
- Validation: plugin-validation CI + actionlint on examples → Task 6. ✓
- Agent never deploys/writes secrets → agent Rules (Task 4). ✓

**Placeholder scan:** No TBD/TODO; every file's full content is inline; every test step has an exact command + expected output. The `echo` lines in `full-cicd.yml` are intentional, documented placeholders for the user's project to fill — not plan gaps.

**Type/name consistency:** `cicd-engineer`, `cicd-pipelines`, `/cicd`, and the six `references/*.md` filenames + `references/examples/full-cicd.yml` are used identically across Tasks 1–7. Counts (16/13/6) match in CLAUDE.md and README. `actionlint` pinned to `1.7.7` in both Task 1 and Task 6.
