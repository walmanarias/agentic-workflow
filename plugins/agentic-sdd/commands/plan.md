---
description: Produce an architecture/design brief and ADRs before specifying or coding.
argument-hint: <feature or system to design>
model: sonnet
---

Invoke the `architect` agent to design: **$ARGUMENTS**

Read the existing repo and stack first. Produce `docs/design/<feature>.md` (context, NFRs, Mermaid component diagram, data model, API contracts, decisions/trade-offs, risks, testability notes) and append ADR(s) under `docs/adr/`. Output type signatures and schema sketches only — no implementation. Recommend the database (PostgreSQL vs MongoDB) with justification. Hand off to `/spec` next.
