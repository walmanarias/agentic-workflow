---
description: Refactor code without changing behavior, guarded by green tests.
argument-hint: <target code / smell>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: opus
---

Invoke the `refactorer` agent for: **$ARGUMENTS**

Follow the `clean-code` skill. Confirm tests are green first (add characterization tests if coverage is thin). Refactor in small reversible steps, running tests after each. Behavior must not change — if you find a bug, flag it and fix it as a separate tested change. Show before/after improvements (complexity, duplication, coupling) and confirm the suite stayed green.
