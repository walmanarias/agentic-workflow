#!/usr/bin/env bash
# Shared helpers for agentic-sdd hooks. Designed to be safe across any repo:
# if tooling is missing, helpers degrade gracefully instead of blocking.
set -uo pipefail

# Read all of stdin once into HOOK_INPUT (hook payload is JSON).
read_hook_input() { HOOK_INPUT="$(cat 2>/dev/null || true)"; }

# json_get <jq-path>  -> extracts a string field from HOOK_INPUT.
# Tries jq, then python3, then node. Empty string if unavailable/missing.
json_get() {
  local path="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r "$path // empty" 2>/dev/null && return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | python3 -c '
import sys, json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
p=sys.argv[1].lstrip(".").replace("[\"",".").replace("\"]","").split(".")
cur=d
for k in p:
    if k=="": continue
    if isinstance(cur,dict) and k in cur: cur=cur[k]
    else: sys.exit(0)
print(cur if isinstance(cur,str) else "")' "$path" 2>/dev/null && return 0
  fi
  return 0
}

# Locate the project root (walk up for package.json); default to CWD.
project_root() {
  local d="${CLAUDE_PROJECT_DIR:-$PWD}"
  while [ "$d" != "/" ]; do
    [ -f "$d/package.json" ] && { printf '%s' "$d"; return 0; }
    d="$(dirname "$d")"
  done
  printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"
}

# Detect the package manager from lockfiles.
pkg_manager() {
  local r; r="$(project_root)"
  [ -f "$r/pnpm-lock.yaml" ] && { echo pnpm; return; }
  [ -f "$r/yarn.lock" ] && { echo yarn; return; }
  [ -f "$r/bun.lockb" ] && { echo bun; return; }
  echo npm
}

# has_script <name> -> 0 if package.json defines that script.
has_script() {
  local r; r="$(project_root)"
  [ -f "$r/package.json" ] || return 1
  node -e "process.exit((require('$r/package.json').scripts||{})['$1']?0:1)" 2>/dev/null && return 0
  grep -q "\"$1\"[[:space:]]*:" "$r/package.json" 2>/dev/null
}

# run_script <name> -> run a package script with the detected manager.
run_script() {
  local name="$1" pm; pm="$(pkg_manager)"; local r; r="$(project_root)"
  ( cd "$r" && case "$pm" in
      npm)  npm run "$name" --silent ;;
      yarn) yarn -s "$name" ;;
      pnpm) pnpm -s "$name" ;;
      bun)  bun run "$name" ;;
    esac )
}

is_js_file() { case "$1" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.mts|*.cts) return 0;; *) return 1;; esac; }
is_test_file() { case "$1" in *.test.*|*.spec.*|*/__tests__/*) return 0;; *) return 1;; esac; }

# --- .NET helpers ---
is_cs_file() { case "$1" in *.cs|*.axaml|*.xaml|*.csproj) return 0;; *) return 1;; esac; }
has_dotnet() { command -v dotnet >/dev/null 2>&1; }

# repo_root: git top-level, else project_root.
repo_root() { git rev-parse --show-toplevel 2>/dev/null || project_root; }

# dotnet_root: prints the dir containing a .sln/.csproj (searching from repo root, max depth 4), else empty.
dotnet_root() {
  local r; r="$(repo_root)"
  if ls "$r"/*.sln >/dev/null 2>&1 || ls "$r"/*.csproj >/dev/null 2>&1; then printf '%s' "$r"; return 0; fi
  local hit; hit="$(find "$r" -maxdepth 4 \( -name '*.sln' -o -name '*.csproj' \) \
        -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/node_modules/*' 2>/dev/null | head -1)"
  [ -n "$hit" ] && dirname "$hit"
}

# dotnet_target: prints the .sln if present, else the first .csproj (for build/test/format).
dotnet_target() {
  local d; d="$(dotnet_root)"; [ -z "$d" ] && return 0
  local sln; sln="$(ls "$d"/*.sln 2>/dev/null | head -1)"
  if [ -n "$sln" ]; then printf '%s' "$sln"; return 0; fi
  find "$d" -maxdepth 4 -name '*.csproj' -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/node_modules/*' 2>/dev/null | head -1
}

# --- Python helpers ---
is_py_file() { case "$1" in *.py) return 0;; *) return 1;; esac; }
is_py_test_file() { case "$1" in */tests/*|*/test_*.py|test_*.py|*_test.py|*/conftest.py|conftest.py) return 0;; *) return 1;; esac; }

# python_cmd: prefer python3, fall back to python. Empty if neither exists.
python_cmd() {
  command -v python3 >/dev/null 2>&1 && { printf 'python3'; return 0; }
  command -v python  >/dev/null 2>&1 && { printf 'python';  return 0; }
}
has_python() { [ -n "$(python_cmd)" ]; }

# py_tool <name>: prints how to invoke a Python tool — the direct binary if on PATH,
# else `python -m <name>` if importable, else empty. Lets callers degrade gracefully.
py_tool() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 && { printf '%s' "$name"; return 0; }
  local py; py="$(python_cmd)"; [ -z "$py" ] && return 0
  "$py" -m "$name" --version >/dev/null 2>&1 && printf '%s -m %s' "$py" "$name"
}

# python_root: prints the dir containing a Python project marker (checked at the repo
# root, then a shallow search), else empty.
python_root() {
  local r; r="$(repo_root)"
  local f
  for f in pyproject.toml setup.py setup.cfg requirements.txt; do
    [ -f "$r/$f" ] && { printf '%s' "$r"; return 0; }
  done
  local hit; hit="$(find "$r" -maxdepth 3 \( -name pyproject.toml -o -name setup.py -o -name setup.cfg -o -name requirements.txt \) \
        -not -path '*/.venv/*' -not -path '*/venv/*' -not -path '*/node_modules/*' 2>/dev/null | head -1)"
  [ -n "$hit" ] && dirname "$hit"
}

# py_uses <root> <tool>: 0 if the project appears to configure/use the tool, so the
# gate should run it. Keeps the commit gate from firing tools the repo hasn't adopted.
py_uses() {
  local d="$1" tool="$2" pp="$1/pyproject.toml"
  case "$tool" in
    ruff)   { [ -f "$d/ruff.toml" ] || [ -f "$d/.ruff.toml" ]; } && return 0
            grep -q '^\[tool\.ruff' "$pp" 2>/dev/null ;;
    black)  grep -q '^\[tool\.black\]' "$pp" 2>/dev/null ;;
    mypy)   { [ -f "$d/mypy.ini" ] || [ -f "$d/.mypy.ini" ]; } && return 0
            grep -q '^\[tool\.mypy\]' "$pp" 2>/dev/null && return 0
            grep -q '^\[mypy\]' "$d/setup.cfg" 2>/dev/null ;;
    pytest) { [ -f "$d/pytest.ini" ] || [ -f "$d/tox.ini" ] || [ -f "$d/conftest.py" ] || [ -d "$d/tests" ]; } && return 0
            grep -q '^\[tool\.pytest' "$pp" 2>/dev/null ;;
    *) return 1 ;;
  esac
}
