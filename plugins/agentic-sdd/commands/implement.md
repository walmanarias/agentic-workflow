---
description: Make failing tests pass with minimal clean code (GREEN -> REFACTOR).
argument-hint: <feature or test scope>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill
model: sonnet
---

Invoke the `implementer` agent for: **$ARGUMENTS**

It loads the relevant stack-expert skill (react / react-native / node-backend / nestjs / nextjs / remix / django / fastapi / flask / dotnet / avalonia / maui / database) plus `tdd-workflow` and `clean-code`. Write the minimum code to pass the failing tests, then refactor with tests staying green. Never edit a test to pass; if a test seems wrong, stop and flag it. Run full tests + lint + type-check before declaring done. Show the diff and passing output, then hand off to `/review`.
