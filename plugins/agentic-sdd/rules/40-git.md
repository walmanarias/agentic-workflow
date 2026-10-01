# Rule: Git & commit hygiene

- Work on a branch, never the default branch: `feat/<feature>` or `fix/<slug>` (created by `/feature` / `/fix`).
- Commits are gated: lint, type-check, and tests must pass (enforced by the pre-commit hook). Agents never use `--no-verify`; humans keep that escape hatch for genuine emergencies in their own terminal. No force pushes.
- One green commit per slice. Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:` — reference the ACs: `feat(auth): reject duplicate email (AC-3)`.
- A refactor commit changes structure only — never behavior.
- Deliberate test changes (removing a test, net-removing assertions, a justified skip) carry a `Test-Change: <reason>` trailer.
- No focused tests (`.only`), `debugger`, secrets, or commented-out code in committed diffs.
- PRs are opened with `/create-pr` (description generated from the commits by the `pr-description` skill) and merged only by `/ship` after the human confirms. Never delete existing screenshots/videos or designer-feedback sections when updating a PR.
