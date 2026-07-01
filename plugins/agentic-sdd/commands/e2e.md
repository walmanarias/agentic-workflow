---
description: Add reliable end-to-end / integration tests for a flow.
argument-hint: <user flow or feature>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

Invoke the `e2e-tester` agent for: **$ARGUMENTS**

Follow the `e2e-testing` skill. Pick the tool by stack (Playwright for web, Detox/Maestro for React Native, Supertest/Pactum for APIs, Testcontainers for the DB). Cover critical journeys and high-risk failures. Tests must be hermetic, parallel-safe, and free of fixed sleeps. Run them twice to check for flakiness. Document any CI setup (containers, env vars).
