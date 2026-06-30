# Design — CI/CD pipeline agent for `agentic-sdd`

**Date:** 2026-06-29
**Status:** Approved (design); pending implementation plan
**Branch context:** depends on the plugin-validation CI added in `afec2d4` (present on `add-pr-to-dev-workflow`).

## Goal

Add a capability to the `agentic-sdd` plugin that **generates and maintains a full CI/CD pipeline** (build → test → deploy) tailored to a target project's stack. Today the workflow only ships a single static build-and-test template (`templates/github-ci.yml`, installed via `scripts/install.sh --with-ci`); there is no agent that authors a pipeline for a project's real stack, and nothing covers CD/deployment.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Shape | A **smart-generator agent** (detects stack, takes deploy target as input), not fixed templates |
| CI platform | **GitHub Actions only** |
| Default promotion model | **Staging → manual approval → production** (GitHub Environments + required reviewers). Confirmed: prod is gated by manual approval; no tag-trigger by default |
| Structure | **Agent + skill (with per-target references) + `/cicd` command** |
| Deploy targets (out of the box) | Cloudflare (Workers/Pages); containerized cloud (AWS ECS/App Runner, Azure Container Apps/App Service, GCP Cloud Run, Railway, Fly.io); VM/EC2 (SSM/SSH); frontend hosts (Vercel/Netlify); mobile (RN via EAS/Fastlane → TestFlight/Play); packages (npm/NuGet) |

## Non-goals (YAGNI / scope guard)

- No GitLab CI / Azure Pipelines output (GitHub Actions only).
- No `scripts/install.sh --cicd` flag — the agent is the interface.
- Reference files stay recipe-sized; provider minutiae are deferred to live docs (Cloudflare/Railway skills, context7) at generation time.
- The agent never deploys, pushes, or writes secret values — it authors workflow files and a setup checklist.

## Components & file layout

```
plugins/agentic-sdd/
  agents/cicd-engineer.md              # NEW — lean role agent (principles + decision table)
  commands/cicd.md                     # NEW — /cicd entry point
  skills/cicd-pipelines/
    SKILL.md                           # NEW — promotion model, stage anatomy, target→mechanism table, security baseline
    references/
      github-actions-foundations.md    # workflow skeleton, least-priv permissions, OIDC, concurrency, action pinning, caching, environments
      build-and-test.md                # CI gate mirroring the local hooks (Node: lint+typecheck+test; .NET: format+build -warnaserror+test)
      deploy-cloudflare.md             # Wrangler — Workers/Pages + bindings
      deploy-containers-and-vms.md     # Docker → AWS ECS/App Runner, Azure Container Apps/App Service, GCP Cloud Run, Railway, Fly.io; + EC2/VM via SSM/SSH
      deploy-frontend-hosts.md         # Vercel / Netlify (+ PR preview deploys)
      deploy-mobile-and-packages.md    # RN via EAS/Fastlane → TestFlight/Play; npm / NuGet publish
```

**Names:** agent `cicd-engineer` (role-style, like `e2e-tester`); command `/cicd`; skill `cicd-pipelines`.

## Component specs

### `cicd-engineer` agent (`agents/cicd-engineer.md`)

- **Frontmatter:** `name`, `description` (triggers: "ci/cd", "pipeline", "deploy", "github actions", "release", and the target names), `tools: Read, Write, Edit, Grep, Glob, Bash`, `model: opus` — same shape as the stack experts.
- **Process:** detect stack (`package.json` / `*.sln` / `*.csproj`) → confirm deploy target(s), environment model, and secrets strategy → apply the `cicd-pipelines` skill → write `.github/workflows/*.yml` → validate with `actionlint` if present → emit a "required secrets / OIDC trust setup" checklist. Never deploys or pushes; never writes a secret value.
- **Principles:** CI gate mirrors the local commit hooks; least-privilege `permissions:` (default `contents: read`, escalate per-job); pin actions; **OIDC over long-lived keys**; `environment: production` with required reviewers for the manual gate; `concurrency` + `cancel-in-progress`; dependency caching; fail fast.
- **Collaboration:** pulls the relevant **stack expert** for build/test specifics, **database-expert** for migration steps in deploy jobs, and wires **e2e-tester**'s tagged suites as a pre-deploy gate.
- **Rules:** no secrets in YAML or logs; one concern per workflow file; document every required secret/variable and the OIDC trust setup; staging must pass before prod; always include rollback notes.

### `cicd-pipelines` skill (`skills/cicd-pipelines/SKILL.md`)

Reusable playbook containing:
- The default **staging → manual-approval → prod** model, with the stage diagram.
- Stage anatomy: CI gate → build artifact → deploy staging → smoke check → manual approval (GitHub Environment) → deploy prod → post-deploy verify → rollback notes.
- A **target → deploy-mechanism → reference** decision table.
- The security baseline (OIDC, least-privilege `permissions:`, action pinning, secret/Environment management).
- Pointers into `references/` (kept short and focused, like the `e2e-testing` references).

### `/cicd` command (`commands/cicd.md`)

- **Frontmatter:** `allowed-tools: Bash, Read, Write, Edit, Grep, Glob`, `model: opus`, `argument-hint: [deploy target and/or app path; optional env model]`.
- **Behavior:** delegate to `cicd-engineer` applying the `cicd-pipelines` skill; confirm target/env/secrets with the user; generate the workflow(s); run `actionlint` if available; print the secrets/OIDC checklist. Does **not** deploy. Positioned as a project-setup/maintenance command that complements `/ship` (which verifies the pipeline is green).

## Generated pipeline (default output)

A GitHub Actions workflow with:

```
on: pull_request
  └─ ci: lint · typecheck · test · build         (permissions: contents: read)
on: push (branches: [main])
  └─ ci ─→ deploy-staging                          (environment: staging, auto)
           └─ deploy-prod                          (environment: production = required reviewers → manual approval)
                                                    (permissions: id-token: write for cloud OIDC)
```

- `concurrency` group per ref; `cancel-in-progress` for CI.
- Actions pinned; dependencies cached; optional Node/.NET version matrix.
- Rollback: re-run the prior green deploy / revert + redeploy (documented per target).

## Workflow & docs integration

- **CLAUDE.md:** add `/cicd` to the command table, `cicd-engineer` to the agent table, `cicd-pipelines` to the skills table; bump counts (agents 15→16, commands 12→13, skills 5→6); add a one-line note that CI/CD setup sits *outside* the per-feature loop and that `/ship` checks the pipeline is green.
- **README.md:** same count/list updates, plus a note distinguishing the **static `--with-ci` starter** (zero-config build+test) from the **agent-generated tailored full pipeline** (build+test+deploy). They coexist; the agent can read and extend an existing `ci.yml`.
- **plugin.json:** add keywords (`ci-cd`, `github-actions`, `deployment`, `devops`).

## Testing / validation

This deliverable is markdown (agent/skill/command), so there is no runtime code to unit-test — validation is structural and real:

- The existing **plugin-validation CI** (`afec2d4`) must pass: manifests parse, agent/command frontmatter present, references resolve, the copy installer still runs.
- Add an **`actionlint` step** to that CI to lint-check any example workflow committed under the skill's `references/`, so pipeline examples are verified-valid GitHub Actions syntax.
- The agent runs `actionlint` on its generated output at runtime (when available).

## Open questions / follow-ups

- Branch/PR packaging: the feature depends on `afec2d4` (on `add-pr-to-dev-workflow`). Decide whether to land it on that branch or a dedicated branch once PR #1 merges. (Process detail, not a design blocker.)
