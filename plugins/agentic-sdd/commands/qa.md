---
description: Visually QA a user-facing flow — capture screenshots and catch visual bugs functional tests miss.
argument-hint: <user flow or screen>
allowed-tools: Read, Write, Grep, Glob, Bash
---

Invoke the `qa-visual` agent for: **$ARGUMENTS**

Follow the `visual-qa` skill. Capture screenshots with the stack's E2E driver (Playwright for web, Detox/Maestro for React Native, Appium/Avalonia.Headless for desktop, Appium for MAUI mobile/desktop) across the states people forget — loading, empty, error, long-text, narrow + wide breakpoints, light + dark theme — then read each screenshot and report visual defects grouped Blocking / Should-fix / Nit, each tied to an `AC-n` and its screenshot path. Write the report to `specs/<feature>/qa.md`. Hand Blocking + Should-fix to the `implementer`, then re-inspect only the fixed screens — at most `$AGENTIC_SDD_MAX_ROUNDS` (default 3) rounds, then hand what's left to the user. Return findings + screenshot paths only — never the images.
