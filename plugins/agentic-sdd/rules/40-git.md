# Rule: Git & commit hygiene

- Commits are gated: lint, type-check, and tests must pass (enforced by the pre-commit hook). `--no-verify` is for genuine emergencies only.
- Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`. Reference the spec/AC where relevant.
- Small, focused commits. A refactor commit changes structure only — never behavior.
- No focused tests (`.only`), `debugger`, or commented-out code in committed diffs.
