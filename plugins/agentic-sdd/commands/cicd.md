---
description: Generate or update a full GitHub Actions CI/CD pipeline (build → test → deploy) for this project.
argument-hint: [deploy target and/or app path; optional environment model]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: opus
---

Invoke the `cicd-engineer` agent for: **$ARGUMENTS**

Follow the `cicd-pipelines` skill. Detect the stack, confirm the deploy target(s), environment model (default **staging → manual approval → production**), and secrets/OIDC strategy with the user, then write `.github/workflows/*.yml`. Validate with `actionlint`. Output the required secrets / OIDC setup checklist and rollback notes. Do **not** deploy or push. This complements `/ship`, which verifies the pipeline is green before release.
