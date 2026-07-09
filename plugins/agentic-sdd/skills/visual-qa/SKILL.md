---
name: visual-qa
description: Use when checking that an implemented UI actually looks right — catching visual bugs (layout, overflow, spacing, contrast, truncation, theme) that functional and E2E tests miss. Drive the app, capture screenshots, inspect them. Trigger on "visual qa", "visual bug", "UI check", "looks wrong", or before shipping a user-facing flow.
---

# Visual QA

Functional/E2E tests prove the UI *works*; visual QA proves it *looks right*. Capture screenshots of the real rendered UI and inspect them — don't re-assert behavior.

## Capture the UI by stack
| Stack | Capture tool | Notes |
|---|---|---|
| Next.js / React web | **Playwright** `page.screenshot()` | Per route + state + breakpoint |
| React Native | **Detox** / **Maestro** | Simulator/device screenshots |
| Avalonia desktop (XAML) | **Appium** or **Avalonia.Headless** render-to-bitmap | Headless is fast for in-memory captures |
| .NET web / Blazor | **Playwright for .NET** | Native Apple Silicon |

Save captures to a gitignored dir (`.qa-visual/`). Reuse the stack's E2E harness — you are capturing images, not asserting behavior.

## Capture these states (not just the happy path)
Loading · empty · error · long-text/overflow · narrow **and** wide breakpoints · light **and** dark theme.

## Inspection checklist (read each screenshot for)
- Broken or overlapping layout; content off-screen.
- Overflow / clipping; text truncated or wrapping badly.
- Misalignment; inconsistent spacing/padding.
- Low color contrast (WCAG AA); unreadable text.
- Unloaded images/icons; wrong or missing theme.
- Mismatch with the design reference in `docs/design/`.

## Report format
Group findings **Blocking / Should-fix / Nit**, each tied to an `AC-n` and its screenshot path, with a concrete fix. End with a verdict (Pass / Pass-with-nits / Fail). Hand Blocking + Should-fix to `implementer`, then re-capture and re-inspect until clean.

## Token discipline
`Read` PNGs only inside the QA agent's own context; return **text findings + screenshot paths** to the caller, never the images.
