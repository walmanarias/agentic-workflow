# agentic-sdd evals

Behavioral evals for the prompts (agents, commands, skills), run with Claude Code's plugin eval
runner. They catch regressions that `tests/run.sh` can't — the hooks are tested there; here we
check that the *instructions* still produce the right artifacts.

```bash
# Write/Edit are gated tools in the eval runner — grant them; --scaffold runs case setup scripts.
claude plugin eval plugins/agentic-sdd --allow-tools Write Edit --scaffold            # all cases
claude plugin eval plugins/agentic-sdd --allow-tools Write Edit --scaffold --runs 1   # quick smoke run
claude plugin eval plugins/agentic-sdd --case plan-slices-the-spec --allow-tools Write Edit --scaffold
```

Cases cost real model calls, so CI doesn't run them; run them before a release or after
changing an agent, command, or playbook.

| Case | Checks |
|---|---|
| `spec-writes-testable-contract` | `/spec` writes `specs/<feature>/spec.md` with numbered ACs, size, DoD; no code |
| `plan-slices-the-spec` | `/plan` on an approved spec writes `plan.md` + `status.md`; 1–3 ACs per slice, every AC once |
