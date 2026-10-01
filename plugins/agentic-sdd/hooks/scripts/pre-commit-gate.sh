#!/usr/bin/env bash
# PreToolUse(Bash): when the command is a `git commit`, enforce the quality gate.
# Blocks the commit (exit 2) if the staged diff weakens tests, leaks a secret, or leaves
# focus/debug markers, or if lint/format, build/type-check, or tests fail.
# Polyglot: JavaScript/TypeScript (per package, monorepo-aware), C#/.NET, Python.
#
# AGENTIC_SDD_GATE=affected (default) — only the stacks whose files are staged; JS lint +
#   tests scoped to the staged files (vitest related / jest --findRelatedTests); type-check,
#   .NET build+test and mypy/pytest stay project-wide. CI and /ship run everything.
# AGENTIC_SDD_GATE=full — every applicable gate on the whole project, every commit.
#
# Deliberate test changes (deleting a test file, net-removing assertions, a justified skip)
# need a `Test-Change: <reason>` trailer in the commit message.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

cmd="$(json_get '.tool_input.command')"
case "$cmd" in *commit*) ;; *) exit 0;; esac
info="$(git_cmd_info "$cmd" | grep '^COMMIT' | head -1)"
[ -z "$info" ] && exit 0
read -r _ cdir no_verify <<< "$info"
[ "$no_verify" = "1" ] && exit 0   # bash-guard.sh blocks this; don't spend minutes gating it.

base="${CLAUDE_PROJECT_DIR:-$PWD}"
case "$cdir" in /*) ;; .) cdir="$base" ;; *) cdir="$base/$cdir" ;; esac
root="$(git -C "$cdir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0
export CLAUDE_PROJECT_DIR="$root"

mode="${AGENTIC_SDD_GATE:-affected}"
fail=""
section() { fail="${fail}\n### $1\n$2\n"; }

# Commit that stages with `-a`/`--all` commits tracked modifications too — include them.
if printf '%s' "$cmd" | grep -Eq 'commit[^|;&]*([[:space:]]-[a-zA-Z]*a|--all)'; then
  staged="$( { git diff --cached --name-only --diff-filter=ACMR; git diff --name-only --diff-filter=ACMR; } | sort -u )"
  diffcmd="git diff HEAD"
else
  staged="$(git diff --cached --name-only --diff-filter=ACMR)"
  diffcmd="git diff --cached"
fi
deleted="$($diffcmd --name-only --diff-filter=D 2>/dev/null)"
test_change=0
printf '%s' "$cmd" | grep -q 'Test-Change:' && test_change=1

# ---------------------------------------------------------------- static scan of the diff
added="$($diffcmd -U0 2>/dev/null | grep -E '^\+' | grep -Ev '^\+\+\+ ')"
bad="$(printf '%s\n' "$added" | grep -v 'sdd-allow-skip:' | grep -En "$FOCUS_RE" || true)"
[ -n "$bad" ] && section "$(t "Focus markers / debugger statements in the staged diff" "Marcadores de enfoque / depurador en el diff preparado")" "$bad"

secrets="$(printf '%s\n' "$added" | grep -En "$SECRET_RE" | sed -E 's/(.{12}).*/\1…/' || true)"
[ -n "$secrets" ] && section "$(t "Possible secret in the staged diff (redacted). Move it to env/secret storage." "Posible secreto en el diff preparado (ocultado). Muévelo a variables de entorno/almacén de secretos.")" "$secrets"
if command -v gitleaks >/dev/null 2>&1; then
  out="$(gitleaks protect --staged --redact --no-banner 2>&1)" || section "gitleaks" "$out"
fi

# Test weakening: skips added, test files deleted, assertions net-removed.
skips=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  is_any_test_file "$f" || continue
  re="$(skip_re_for "$f")"; [ -z "$re" ] && continue
  hit="$($diffcmd -U0 -- "$f" | grep -E '^\+' | grep -Ev '^\+\+\+ ' | grep -v 'sdd-allow-skip:' | grep -E "$re" || true)"
  [ -n "$hit" ] && skips="${skips}${f}: ${hit}\n"
done <<< "$staged"
[ -n "$skips" ] && section "$(t "Skipped/disabled tests added (use \`sdd-allow-skip: <reason>\` on the line if deliberate)" "Pruebas omitidas/desactivadas agregadas (usa \`sdd-allow-skip: <motivo>\` en la línea si es deliberado)")" "$(printf '%b' "$skips")"

if [ "$test_change" = "0" ]; then
  del_tests="$(printf '%s\n' "$deleted" | while IFS= read -r f; do [ -n "$f" ] && is_any_test_file "$f" && printf '%s\n' "$f"; done)"
  [ -n "$del_tests" ] && section "$(t "Test files deleted. If intentional (feature removed, test moved), add a \`Test-Change: <reason>\` trailer to the commit message." "Archivos de prueba eliminados. Si es intencional, agrega el trailer \`Test-Change: <motivo>\` al mensaje del commit.")" "$del_tests"

  removed=0; addedn=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    is_any_test_file "$f" || continue
    d="$($diffcmd -U0 -- "$f" 2>/dev/null)"
    r="$(printf '%s\n' "$d" | grep -E '^-' | grep -Ev '^--- ' | grep -Eo "$ASSERT_RE" | wc -l | tr -d ' ')"
    a="$(printf '%s\n' "$d" | grep -E '^\+' | grep -Ev '^\+\+\+ ' | grep -Eo "$ASSERT_RE" | wc -l | tr -d ' ')"
    removed=$((removed + r)); addedn=$((addedn + a))
  done <<< "$staged"
  if [ "$removed" -gt "$addedn" ]; then
    section "$(t "Assertions net-removed from tests ($removed removed, $addedn added). Never weaken a test to pass; if the change is deliberate, add a \`Test-Change: <reason>\` trailer." "Aserciones eliminadas en neto ($removed eliminadas, $addedn agregadas). Nunca debilites una prueba; si es deliberado, agrega el trailer \`Test-Change: <motivo>\`.")" ""
  fi
fi

# Which stacks does this commit touch?
touches() { printf '%s\n' "$staged" | grep -Eq "$1"; }
JS_RE='\.(ts|tsx|js|jsx|mjs|cjs|mts|cts|vue|svelte)$|(^|/)(package\.json|tsconfig[^/]*\.json|\.eslintrc[^/]*|eslint\.config\.[^/]+|jest\.config\.[^/]+|vitest\.config\.[^/]+)$'
NET_RE='\.(cs|csproj|sln|slnx|props|targets|axaml|xaml|editorconfig)$|(^|/)global\.json$'
PY_RE='\.py$|(^|/)(pyproject\.toml|setup\.cfg|setup\.py|requirements[^/]*\.txt|ruff\.toml|\.ruff\.toml|mypy\.ini|pytest\.ini|tox\.ini)$'
run_stack() { [ "$mode" = "full" ] || touches "$1"; }

# ---------------------------------------------------------------- JavaScript / TypeScript
js_gate_pkg() {  # js_gate_pkg <pkgdir> [files relative to pkgdir...]
  local p="$1"; shift
  local label; label="$(rel_path "$p")"; [ -z "$label" ] || [ "$label" = "$p" ] && label="."
  local out
  if [ $# -gt 0 ] && ( cd "$p" && npx --no-install eslint --version >/dev/null 2>&1 ); then
    out="$( cd "$p" && npx --no-install eslint "$@" 2>&1 )" || section "$(t "Lint FAILED" "Lint FALLÓ") ($label)" "$out"
  elif has_script_in "$p" lint; then
    out="$(run_script_in "$p" lint 2>&1)" || section "$(t "Lint FAILED" "Lint FALLÓ") ($label)" "$out"
  fi
  if has_script_in "$p" typecheck; then
    out="$(run_script_in "$p" typecheck 2>&1)" || section "$(t "Type-check FAILED" "Verificación de tipos FALLÓ") ($label)" "$out"
  elif [ -f "$p/tsconfig.json" ] && ( cd "$p" && npx --no-install tsc --version >/dev/null 2>&1 ); then
    out="$( cd "$p" && npx --no-install tsc --noEmit -p . 2>&1 )" || section "$(t "Type-check FAILED" "Verificación de tipos FALLÓ") ($label)" "$out"
  fi
  if [ $# -gt 0 ] && npm_dep_in "$p" vitest; then
    out="$( cd "$p" && CI=true npx --no-install vitest related --run --passWithNoTests "$@" 2>&1 )" || section "$(t "Tests FAILED" "Pruebas FALLARON") ($label)" "$out"
  elif [ $# -gt 0 ] && npm_dep_in "$p" jest; then
    out="$( cd "$p" && CI=true npx --no-install jest --ci --passWithNoTests --findRelatedTests "$@" 2>&1 )" || section "$(t "Tests FAILED" "Pruebas FALLARON") ($label)" "$out"
  elif has_script_in "$p" test; then
    out="$( cd "$p" && CI=true run_script_in "$p" test 2>&1 )" || section "$(t "Tests FAILED" "Pruebas FALLARON") ($label)" "$out"
  fi
}

if [ "$mode" = "full" ]; then
  [ -f "$root/package.json" ] && js_gate_pkg "$root"
elif touches "$JS_RE"; then
  # Group staged JS/TS files by their nearest package.json (monorepo-aware).
  pkgs="$(printf '%s\n' "$staged" | grep -E "$JS_RE" | while IFS= read -r f; do
            [ -e "$f" ] || continue; d="$(nearest_dir_with "$root/$f" package.json)"; [ -n "$d" ] && printf '%s\n' "$d"; done | sort -u)"
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    files=()
    config=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      [ "$(nearest_dir_with "$root/$f" package.json)" = "$p" ] || continue
      case "$f" in *package.json|*tsconfig*|*eslint*|*jest.config*|*vitest.config*) config=1 ;; esac
      is_js_file "$f" && files+=("${root}/${f}")
    done <<< "$(printf '%s\n' "$staged" | grep -E "$JS_RE")"
    if [ "$config" = "1" ]; then js_gate_pkg "$p"; else js_gate_pkg "$p" "${files[@]}"; fi
  done <<< "$pkgs"
fi

# ---------------------------------------------------------------- C# / .NET
if has_dotnet && run_stack "$NET_RE"; then
  target="$(dotnet_target)"
  if [ -n "$target" ]; then
    if [ "$mode" = "full" ]; then
      out="$(dotnet format "$target" --verify-no-changes 2>&1)" || section "$(t "dotnet format FAILED (run 'dotnet format')" "dotnet format FALLÓ (ejecuta 'dotnet format')")" "$out"
    else
      cs=(); while IFS= read -r f; do case "$f" in *.cs) [ -e "$f" ] && cs+=("$f");; esac; done <<< "$staged"
      if [ ${#cs[@]} -gt 0 ]; then
        out="$(dotnet format "$target" --verify-no-changes --include "${cs[@]}" 2>&1)" || section "$(t "dotnet format FAILED (run 'dotnet format')" "dotnet format FALLÓ (ejecuta 'dotnet format')")" "$out"
      fi
    fi
    out="$(dotnet build "$target" -warnaserror --nologo 2>&1)" || section "$(t "dotnet build FAILED" "dotnet build FALLÓ")" "$out"
    out="$(dotnet test "$target" --nologo --verbosity quiet 2>&1)" || section "$(t "dotnet test FAILED" "dotnet test FALLÓ")" "$out"
  fi
fi

# ---------------------------------------------------------------- Python
pyroot="$(python_root)"
if [ -n "$pyroot" ] && has_python && run_stack "$PY_RE"; then
  pyfiles=(); if [ "$mode" != "full" ]; then while IFS= read -r f; do case "$f" in *.py) [ -e "$f" ] && pyfiles+=("$root/$f");; esac; done <<< "$staged"; fi
  [ ${#pyfiles[@]} -eq 0 ] && pyfiles=(.)
  ruff="$(py_tool ruff)"
  if [ -n "$ruff" ] && py_uses "$pyroot" ruff; then
    out="$( cd "$pyroot" && $ruff check "${pyfiles[@]}" 2>&1 )"           || section "$(t "Ruff lint FAILED (run 'ruff check --fix')" "Ruff lint FALLÓ (ejecuta 'ruff check --fix')")" "$out"
    out="$( cd "$pyroot" && $ruff format --check "${pyfiles[@]}" 2>&1 )"  || section "$(t "Ruff format check FAILED (run 'ruff format')" "Verificación de formato Ruff FALLÓ (ejecuta 'ruff format')")" "$out"
  else
    black="$(py_tool black)"
    if [ -n "$black" ] && py_uses "$pyroot" black; then
      out="$( cd "$pyroot" && $black --check "${pyfiles[@]}" 2>&1 )" || section "$(t "black --check FAILED (run 'black .')" "black --check FALLÓ (ejecuta 'black .')")" "$out"
    fi
  fi
  mypy="$(py_tool mypy)"
  if [ -n "$mypy" ] && py_uses "$pyroot" mypy; then
    out="$( cd "$pyroot" && $mypy . 2>&1 )" || section "$(t "mypy FAILED" "mypy FALLÓ")" "$out"
  fi
  pytest="$(py_tool pytest)"
  if [ -n "$pytest" ] && py_uses "$pyroot" pytest; then
    out="$( cd "$pyroot" && $pytest -q 2>&1 )" || section "$(t "pytest FAILED" "pytest FALLÓ")" "$out"
  fi
fi

if [ -n "$fail" ]; then
  printf '%s\n%b' "$(t "Commit blocked by the agentic-sdd quality gate ($mode). Fix the issues below and commit again:" \
                       "Commit bloqueado por la barrera de calidad de agentic-sdd ($mode). Corrige lo siguiente y vuelve a hacer commit:")" "$fail" >&2
  exit 2
fi
exit 0
