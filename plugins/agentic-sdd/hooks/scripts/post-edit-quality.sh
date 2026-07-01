#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): format/lint the changed file and feed any
# problems back to Claude (exit 2) so they get fixed immediately.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

file="$(json_get '.tool_input.file_path')"
[ -z "$file" ] && exit 0
case "$file" in *node_modules*|*/dist/*|*/build/*|*/.next/*|*/bin/*|*/obj/*|*/.venv/*|*/venv/*|*/__pycache__/*) exit 0;; esac

# --- JavaScript / TypeScript: ESLint --fix on the changed file ---
if is_js_file "$file"; then
  [ -f "$file" ] || exit 0
  root="$(project_root)"
  command -v npx >/dev/null 2>&1 || exit 0
  ( cd "$root" && npx --no-install eslint --version >/dev/null 2>&1 ) || exit 0
  out="$( cd "$root" && npx --no-install eslint --fix "$file" 2>&1 )"; status=$?
  if [ $status -ne 0 ]; then
    printf 'ESLint reported problems in %s (auto-fixable issues were fixed):\n%s\n\nFix the remaining issues before continuing.\n' "$file" "$out" >&2
    exit 2
  fi
  exit 0
fi

# --- C# / XAML: dotnet format the changed file ---
if is_cs_file "$file"; then
  has_dotnet || exit 0
  target="$(dotnet_target)"; [ -z "$target" ] && exit 0
  out="$( dotnet format "$target" --include "$file" 2>&1 )"; status=$?
  if [ $status -ne 0 ]; then
    printf 'dotnet format reported issues for %s:\n%s\n\nResolve them before continuing.\n' "$file" "$out" >&2
    exit 2
  fi
  exit 0
fi

# --- Python: ruff (lint --fix + format), else black, on the changed file ---
if is_py_file "$file"; then
  [ -f "$file" ] || exit 0
  root="$(python_root)"; [ -z "$root" ] && exit 0   # not a recognized Python project — leave it alone
  # Only format with a tool the project has adopted, matching the commit gate — so a
  # merely-installed (but unused) ruff/black never silently reformats the file.
  ruff="$(py_tool ruff)"
  if [ -n "$ruff" ] && py_uses "$root" ruff; then
    ( cd "$root" && $ruff check --fix "$file" >/dev/null 2>&1 )
    ( cd "$root" && $ruff format "$file" >/dev/null 2>&1 )
    out="$( cd "$root" && $ruff check "$file" 2>&1 )"; status=$?
    if [ $status -ne 0 ]; then
      printf 'Ruff reported problems in %s (auto-fixable issues were fixed):\n%s\n\nFix the remaining issues before continuing.\n' "$file" "$out" >&2
      exit 2
    fi
    exit 0
  fi
  black="$(py_tool black)"
  if [ -n "$black" ] && py_uses "$root" black; then
    out="$( cd "$root" && $black "$file" 2>&1 )"; status=$?
    if [ $status -ne 0 ]; then
      printf 'black reported issues for %s:\n%s\n\nResolve them before continuing.\n' "$file" "$out" >&2
      exit 2
    fi
  fi
  exit 0
fi
exit 0
