#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): format/lint the changed file and feed any
# problems back to Claude (exit 2) so they get fixed immediately. Kept fast: it touches
# only the edited file; the full checks run at the commit gate.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

file="$(json_get '.tool_input.file_path')"
[ -z "$file" ] && exit 0
case "$file" in *node_modules*|*/dist/*|*/build/*|*/.next/*|*/bin/*|*/obj/*|*/.venv/*|*/venv/*|*/__pycache__/*) exit 0;; esac
[ -f "$file" ] || exit 0

# Rules that legitimately fail during RED: a new test imports a module that doesn't exist yet.
RED_RULES='import/no-unresolved,import-x/no-unresolved,n/no-missing-import,node/no-missing-import,import/named,import-x/named'

# --- JavaScript / TypeScript: ESLint --fix on the changed file (nearest package with ESLint) ---
if is_js_file "$file"; then
  command -v npx >/dev/null 2>&1 || exit 0
  root="$(nearest_dir_with "$file" package.json)"; [ -z "$root" ] && root="$(project_root)"
  ( cd "$root" && npx --no-install eslint --version >/dev/null 2>&1 ) || exit 0
  out="$( cd "$root" && npx --no-install eslint --fix "$file" 2>&1 )"; status=$?
  if [ $status -ne 0 ] && is_any_test_file "$(rel_path "$file")"; then
    # RED tolerance: ignore unresolved-import errors in test files; anything else still blocks.
    remaining="$( cd "$root" && npx --no-install eslint --format json "$file" 2>/dev/null | node -e '
      let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{
        const ignore=new Set(process.argv[1].split(","));
        const r=JSON.parse(s);let n=0;for(const f of r)for(const m of f.messages)if(m.severity===2&&!ignore.has(m.ruleId))n++;
        console.log(n);}catch{console.log(-1)}})' "$RED_RULES" )"
    [ "$remaining" = "0" ] && exit 0
  fi
  if [ $status -ne 0 ]; then
    printf '%s\n%s\n\n%s\n' "$(t "ESLint reported problems in $file (auto-fixable ones were fixed):" "ESLint reportó problemas en $file (se corrigieron los arreglables automáticamente):")" \
      "$out" "$(t "Fix the remaining problems before continuing." "Corrige los problemas restantes antes de continuar.")" >&2
    exit 2
  fi
  exit 0
fi

# --- C# / XAML: whitespace-only format of the changed file (fast, no build). ---
# Style/analyzer verification runs at the commit gate (dotnet format --verify-no-changes).
if is_cs_file "$file"; then
  case "$file" in *.cs) ;; *) exit 0;; esac
  has_dotnet || exit 0
  droot="$(nearest_dir_with "$file" .editorconfig '*.sln' '*.csproj')"; [ -z "$droot" ] && droot="$(dirname "$file")"
  out="$( dotnet format whitespace "$droot" --folder --include "$file" 2>&1 )"; status=$?
  if [ $status -ne 0 ]; then
    printf '%s\n%s\n' "$(t "dotnet format whitespace failed on $file:" "dotnet format whitespace falló en $file:")" "$out" >&2
    exit 2
  fi
  exit 0
fi

# --- Python: ruff (lint --fix + format), else black, on the changed file ---
if is_py_file "$file"; then
  root="$(nearest_dir_with "$file" pyproject.toml setup.cfg setup.py ruff.toml .ruff.toml requirements.txt)"
  [ -z "$root" ] && root="$(python_root)"; [ -z "$root" ] && exit 0
  # Only format with a tool the project has adopted, matching the commit gate.
  ruff="$(py_tool ruff)"
  if [ -n "$ruff" ] && py_uses "$root" ruff; then
    ( cd "$root" && $ruff check --fix "$file" >/dev/null 2>&1 )
    ( cd "$root" && $ruff format "$file" >/dev/null 2>&1 )
    out="$( cd "$root" && $ruff check "$file" 2>&1 )"; status=$?
    if [ $status -ne 0 ]; then
      printf '%s\n%s\n\n%s\n' "$(t "Ruff reported problems in $file (auto-fixable ones were fixed):" "Ruff reportó problemas en $file (se corrigieron los arreglables automáticamente):")" \
        "$out" "$(t "Fix the remaining problems before continuing." "Corrige los problemas restantes antes de continuar.")" >&2
      exit 2
    fi
    exit 0
  fi
  black="$(py_tool black)"
  if [ -n "$black" ] && py_uses "$root" black; then
    out="$( cd "$root" && $black "$file" 2>&1 )"; status=$?
    if [ $status -ne 0 ]; then
      printf '%s\n%s\n' "$(t "black reported problems in $file:" "black reportó problemas en $file:")" "$out" >&2
      exit 2
    fi
  fi
  exit 0
fi
exit 0
