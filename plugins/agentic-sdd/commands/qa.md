---
description: Visually QA a user-facing flow — capture screenshots and catch visual bugs functional tests miss.
argument-hint: <user flow or screen>
allowed-tools: Read, Write, Grep, Glob, Bash
model: sonnet
---

Invoke the `qa-visual` agent for: **$ARGUMENTS**

Follow the `visual-qa` skill. Capture screenshots with the stack's E2E driver (Playwright for web, Detox/Maestro for React Native, Appium/Avalonia.Headless for desktop) across the states people forget — loading, empty, error, long-text, narrow + wide breakpoints, light + dark theme — then read each screenshot and report visual defects grouped Blocking / Should-fix / Nit, each tied to an `AC-n` and its screenshot path. Hand Blocking + Should-fix to the `implementer`, then re-inspect until clean. Return findings + screenshot paths only — never the images.
