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
        -not -path '*/bin/*' -not -path '*/obj/*' 2>/dev/null | head -1)"
  [ -n "$hit" ] && dirname "$hit"
}

# dotnet_target: prints the .sln if present, else the first .csproj (for build/test/format).
dotnet_target() {
  local d; d="$(dotnet_root)"; [ -z "$d" ] && return 0
  local sln; sln="$(ls "$d"/*.sln 2>/dev/null | head -1)"
  if [ -n "$sln" ]; then printf '%s' "$sln"; return 0; fi
  find "$d" -maxdepth 4 -name '*.csproj' -not -path '*/bin/*' -not -path '*/obj/*' 2>/dev/null | head -1
}
