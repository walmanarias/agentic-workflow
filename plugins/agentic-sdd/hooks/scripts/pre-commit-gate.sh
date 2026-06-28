#!/usr/bin/env bash
# PreToolUse(Bash): when the command is a `git commit`, enforce the quality gate.
# Blocks the commit (exit 2) if lint, type-check, or tests fail.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

cmd="$(json_get '.tool_input.command')"
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+commit' || exit 0
# Let explicit emergency escapes through.
printf '%s' "$cmd" | grep -Eq '\-\-no-verify' && exit 0

root="$(project_root)"
fail=""

run_gate() { # <label> <script-name> [fallback-cmd]
  local label="$1" script="$2" fallback="${3:-}"
  if has_script "$script"; then
    if ! out="$(run_script "$script" 2>&1)"; then
      fail="${fail}\n### ${label} FAILED\n${out}\n"
    fi
  elif [ -n "$fallback" ]; then
    if ! out="$( cd "$root" && eval "$fallback" 2>&1 )"; then
      fail="${fail}\n### ${label} FAILED\n${out}\n"
    fi
  fi
}

# Static scan of staged files for focus markers / debugger leftovers.
staged="$( cd "$root" && git diff --cached --name-only 2>/dev/null )"
if [ -n "$staged" ]; then
  bad="$( cd "$root" && git diff --cached -U0 2>/dev/null | grep -E '^\+' | grep -En '\.only\s*\(|(^|[^A-Za-z0-9_])debugger\s*;' || true )"
  [ -n "$bad" ] && fail="${fail}\n### FOCUSED TESTS / DEBUGGER in staged diff\n${bad}\n"
fi

run_gate "Lint"       "lint"      "npx --no-install eslint . || true"
run_gate "Type-check" "typecheck" "[ -f tsconfig.json ] && npx --no-install tsc --noEmit"
# Force non-interactive test mode.
if has_script "test"; then
  if ! out="$( cd "$root" && CI=true run_script test 2>&1 )"; then
    fail="${fail}\n### Tests FAILED\n${out}\n"
  fi
fi

if [ -n "$fail" ]; then
  printf 'Commit blocked by agentic-sdd quality gate. Fix these, then commit again (or use --no-verify only for genuine emergencies):\n%b' "$fail" >&2
  exit 2
fi
exit 0
