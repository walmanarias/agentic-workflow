#!/usr/bin/env bash
# PreToolUse(Bash): when the command is a `git commit`, enforce the quality gate.
# Blocks the commit (exit 2) if lint/format, build/type-check, or tests fail.
# Handles JavaScript/TypeScript (npm scripts), C#/.NET (dotnet), and Python repos, incl. polyglot.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

cmd="$(json_get '.tool_input.command')"
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+commit' || exit 0
printf '%s' "$cmd" | grep -Eq '\-\-no-verify' && exit 0   # explicit emergency escape

root="$(repo_root)"
fail=""

# --- Static scan of staged diff: focus markers / debugger leftovers (JS + C# + Python) ---
staged="$( cd "$root" && git diff --cached --name-only 2>/dev/null )"
if [ -n "$staged" ]; then
  bad="$( cd "$root" && git diff --cached -U0 2>/dev/null | grep -E '^\+' \
        | grep -En '\.only\s*\(|(^|[^A-Za-z0-9_])debugger\s*;|Debugger\s*\.\s*Break\s*\(|pdb\.set_trace\s*\(|(^|[^A-Za-z0-9_.])breakpoint\s*\(' || true )"
  [ -n "$bad" ] && fail="${fail}\n### Marcadores de enfoque / depurador en el diff preparado\n${bad}\n"
fi

# --- JavaScript / TypeScript gates (npm scripts) ---
proot="$(project_root)"
if [ -f "$proot/package.json" ]; then
  if has_script "lint";      then out="$(run_script lint 2>&1)"            || fail="${fail}\n### Lint FALLÓ\n${out}\n"; fi
  if has_script "typecheck"; then out="$(run_script typecheck 2>&1)"       || fail="${fail}\n### Verificación de tipos FALLÓ\n${out}\n"; fi
  if has_script "test";      then out="$( cd "$proot" && CI=true run_script test 2>&1 )" || fail="${fail}\n### Pruebas FALLARON\n${out}\n"; fi
fi

# --- C# / .NET gates (dotnet) ---
if has_dotnet; then
  target="$(dotnet_target)"
  if [ -n "$target" ]; then
    out="$(dotnet format "$target" --verify-no-changes 2>&1)" || fail="${fail}\n### dotnet format FALLÓ (ejecuta 'dotnet format')\n${out}\n"
    out="$(dotnet build "$target" -warnaserror --nologo 2>&1)" || fail="${fail}\n### dotnet build FALLÓ\n${out}\n"
    out="$(dotnet test "$target" --nologo --verbosity quiet 2>&1)" || fail="${fail}\n### dotnet test FALLÓ\n${out}\n"
  fi
fi

# --- Python gates (ruff / mypy / pytest) — each runs only if the repo adopts it ---
pyroot="$(python_root)"
if [ -n "$pyroot" ] && has_python; then
  ruff="$(py_tool ruff)"
  if [ -n "$ruff" ] && py_uses "$pyroot" ruff; then
    out="$( cd "$pyroot" && $ruff check . 2>&1 )"         || fail="${fail}\n### Ruff lint FALLÓ (ejecuta 'ruff check --fix')\n${out}\n"
    out="$( cd "$pyroot" && $ruff format --check . 2>&1 )" || fail="${fail}\n### Verificación de formato Ruff FALLÓ (ejecuta 'ruff format')\n${out}\n"
  else
    black="$(py_tool black)"
    if [ -n "$black" ] && py_uses "$pyroot" black; then
      out="$( cd "$pyroot" && $black --check . 2>&1 )" || fail="${fail}\n### black --check FALLÓ (ejecuta 'black .')\n${out}\n"
    fi
  fi
  mypy="$(py_tool mypy)"
  if [ -n "$mypy" ] && py_uses "$pyroot" mypy; then
    out="$( cd "$pyroot" && $mypy . 2>&1 )" || fail="${fail}\n### mypy FALLÓ\n${out}\n"
  fi
  pytest="$(py_tool pytest)"
  if [ -n "$pytest" ] && py_uses "$pyroot" pytest; then
    out="$( cd "$pyroot" && $pytest -q 2>&1 )" || fail="${fail}\n### pytest FALLÓ\n${out}\n"
  fi
fi

if [ -n "$fail" ]; then
  printf 'Commit bloqueado por la barrera de calidad de agentic-sdd. Corrige esto y vuelve a hacer commit (usa --no-verify solo en emergencias reales):\n%b' "$fail" >&2
  exit 2
fi
exit 0
