#!/usr/bin/env bash
# Shared helpers for agentic-sdd hooks. Designed to be safe across any repo:
# if tooling is missing, helpers degrade gracefully instead of blocking.
# No pipefail on purpose: hooks pipe text into `grep -q`, whose early exit would SIGPIPE the
# writer and turn a match into a failure (missed violations on large edits).
set -u

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
  local r g; r="$(project_root)"; g="$(git -C "$r" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$r")"
  local d
  for d in "$r" "$g"; do
    [ -f "$d/pnpm-lock.yaml" ] && { echo pnpm; return; }
    [ -f "$d/yarn.lock" ] && { echo yarn; return; }
    { [ -f "$d/bun.lockb" ] || [ -f "$d/bun.lock" ]; } && { echo bun; return; }
  done
  echo npm
}

# has_script_in <dir> <name> -> 0 if <dir>/package.json defines that script.
has_script_in() {
  local r="$1" name="$2"
  [ -f "$r/package.json" ] || return 1
  node -e "process.exit((require(process.argv[1]).scripts||{})[process.argv[2]]?0:1)" "$r/package.json" "$name" 2>/dev/null && return 0
  grep -q "\"$name\"[[:space:]]*:" "$r/package.json" 2>/dev/null
}
has_script() { has_script_in "$(project_root)" "$1"; }

# run_script_in <dir> <name> -> run a package script in <dir> with the detected manager.
run_script_in() {
  local r="$1" name="$2" pm; pm="$(pkg_manager)"
  ( cd "$r" && case "$pm" in
      npm)  npm run "$name" --silent ;;
      yarn) yarn -s "$name" ;;
      pnpm) pnpm -s "$name" ;;
      bun)  bun run "$name" ;;
    esac )
}
run_script() { run_script_in "$(project_root)" "$1"; }

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

# ---------------------------------------------------------------------------
# i18n — hook messages default to English; set AGENTIC_SDD_LANG=es for Spanish.
# t "<english>" "<spanish>"
t() { if [ "${AGENTIC_SDD_LANG:-en}" = "es" ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

# Directory holding the hook scripts, and the plugin's tools/ dir (stack registry,
# AC traceability, coverage). Works for plugin installs and for the copy installer
# (.claude/hooks/scripts + .claude/tools).
sdd_scripts_dir() { ( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd ); }
sdd_tools_dir() { ( cd "$(dirname "${BASH_SOURCE[0]}")/../../tools" 2>/dev/null && pwd ); }

# json_get_edits: every piece of text an Edit/Write/MultiEdit call would write,
# newline-joined (Write .content, Edit .new_string, legacy MultiEdit .edits[].new_string).
json_get_edits() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits // [] | .[]?.new_string)] | map(select(. != null)) | join("\n")' 2>/dev/null && return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | python3 -c '
import sys, json
try: ti=json.load(sys.stdin).get("tool_input") or {}
except Exception: sys.exit(0)
parts=[ti.get("content"), ti.get("new_string")]+[e.get("new_string") for e in (ti.get("edits") or []) if isinstance(e,dict)]
print("\n".join(p for p in parts if isinstance(p,str)))' 2>/dev/null
  fi
  return 0
}

# rel_path <abs-or-rel file> -> path relative to the project dir (best effort).
rel_path() {
  local f="$1" base="${CLAUDE_PROJECT_DIR:-$PWD}"
  base="${base%/}"
  case "$f" in "$base"/*) printf '%s' "${f#"$base"/}";; *) printf '%s' "${f#./}";; esac
}

# is_any_test_file <path>: test code or test-support files in any supported stack.
is_any_test_file() {
  local p="$1" base="${1##*/}"
  case "$p" in *.md|*.mdx) return 1;; esac
  # *.test.* / *.spec.* / *.e2e.* only for code files (not openapi.spec.yaml, foo.spec.md).
  case "$base" in
    *.test.*|*.spec.*|*.e2e.*|*.cy.*)
      case "$base" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.mts|*.cts|*.vue|*.svelte|*.py|*.cs|*.snap) return 0;; esac ;;
  esac
  case "$p" in
    */src/e2e/*|src/e2e/*) return 1;;   # e.g. end-to-end *encryption* code in src/
  esac
  case "$p" in
    */__tests__/*|__tests__/*|*/__mocks__/*|__mocks__/*|*/__fixtures__/*|__fixtures__/*|*/__snapshots__/*) return 0;;
    */mocks/*|mocks/*|*test-utils*|*test-helpers*|*testing-utils*) return 0;;
    */e2e/*|e2e/*|*/tests/*|tests/*|*/test/*|test/*|*/testdata/*|cypress/*|*/cypress/*|playwright/*|*/playwright/*) return 0;;
    test_*.py|*/test_*.py|*_test.py|conftest.py|*/conftest.py|pytest.ini|*/pytest.ini) return 0;;
    *Tests/*|*Tests.csproj) return 0;;   # .NET test projects: X.Tests, X.UnitTests, X.IntegrationTests, X.UITests
    *setupTests.*|*/test-setup.*|test-setup.*|*/vitest.setup.*|vitest.setup.*|*/jest.setup.*|jest.setup.*) return 0;;
    jest.config.*|*/jest.config.*|vitest.config.*|*/vitest.config.*|vitest.workspace.*|*/vitest.workspace.*) return 0;;
    playwright.config.*|*/playwright.config.*|cypress.config.*|*/cypress.config.*|karma.conf.*|*/karma.conf.*) return 0;;
    .detoxrc*|*/.detoxrc*|.maestro/*|*/.maestro/*) return 0;;
  esac
  return 1
}

# Regexes for tests that are switched off — the "never weaken a test" rule.
# A line containing `sdd-allow-skip: <reason>` is exempt (deliberate, explained skip).
# shellcheck disable=SC2034  # the regexes below are used by the scripts that source lib.sh
SKIP_RE_JS='(^|[^A-Za-z0-9_$.])(x(it|test|describe)|f(it|describe)|(it|test|describe|context|suite)\.(skip|todo))[[:space:]]*\(|\.describe\.skip[[:space:]]*\(|\.fixme[[:space:]]*\('
SKIP_RE_CS='(Fact|Theory|Test|TestMethod|AvaloniaFact|AvaloniaTheory)[[:space:]]*\([^)]*Skip[[:space:]]*=|\[Ignore|\[Explicit'
SKIP_RE_PY='@pytest\.mark\.(skip|skipif|xfail)|pytest\.skip[[:space:]]*\(|@unittest\.(skip|expectedFailure)'
# shellcheck disable=SC2034
# Focus / debugger markers per language (the gate applies each only to matching files).
FOCUS_RE_JS_TEST='(^|[^A-Za-z0-9_$])(it|test|describe|context|suite)\.only[[:space:]]*\(|(^|[^A-Za-z0-9_$])f(it|describe)[[:space:]]*\('
FOCUS_RE_JS='(^|[^A-Za-z0-9_])debugger[[:space:]]*;'
# shellcheck disable=SC2034
FOCUS_RE_PY='pdb\.set_trace[[:space:]]*\(|(^|[^A-Za-z0-9_.])breakpoint[[:space:]]*\(\)'
# shellcheck disable=SC2034
FOCUS_RE_CS='Debugger[[:space:]]*\.[[:space:]]*Break[[:space:]]*\('
# shellcheck disable=SC2034
ASSERT_RE='expect[[:space:]]*\(|assert|Assert\.|\.Should\(|\.should[.(]|verify[[:space:]]*\(|toHaveBeenCalled'
# shellcheck disable=SC2034
SECRET_RE='AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|(^|[^A-Za-z0-9])sk-(ant-|proj-|svcacct-)?[A-Za-z0-9_-]{32,}|(^|[^A-Za-z0-9])[rs]k_live_[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{35}'

# skip_re_for <path>: the skip regex for a test file's language (empty if none).
skip_re_for() {
  case "$1" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.mts|*.cts) printf '%s' "$SKIP_RE_JS";;
    *.cs) printf '%s' "$SKIP_RE_CS";;
    *.py) printf '%s' "$SKIP_RE_PY";;
  esac
}

# nearest_dir_with <file> <marker...>: walk up from the file's directory to the git
# root and print the first directory containing any marker file. Empty if none.
nearest_dir_with() {
  local f="$1"; shift
  local d top; d="$(cd "$(dirname "$f")" 2>/dev/null && pwd)" || return 0
  top="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || printf '/')"
  while :; do
    local m; for m in "$@"; do compgen -G "$d/$m" >/dev/null 2>&1 && { printf '%s' "$d"; return 0; }; done
    [ "$d" = "$top" ] || [ "$d" = "/" ] && return 0
    d="$(dirname "$d")"
  done
}

# npm_dep_in <dir> <name>: 0 if <dir>/package.json lists the dependency.
npm_dep_in() {
  [ -f "$1/package.json" ] || return 1
  node -e 'const p=require(process.argv[1]);const d={...p.dependencies,...p.devDependencies};process.exit(d[process.argv[2]]?0:1)' "$1/package.json" "$2" 2>/dev/null && return 0
  grep -q "\"$2\"[[:space:]]*:" "$1/package.json" 2>/dev/null
}

# git_cmd_info <command> [base-dir]: parse a Bash command line (gitcmd.py) and print one
# TAB-separated line per git invocation of interest:
#   COMMIT <no_verify> <all> <pathspec> <add_before> <dir>      PUSH <force> <no_verify>
# Falls back to a coarse regex when python is missing or the command can't be parsed.
git_cmd_info() {
  local py; py="$(python_cmd)"
  if [ -n "$py" ]; then
    "$py" "$(sdd_scripts_dir)/gitcmd.py" "$1" "${2:-}" 2>/dev/null && return 0
  fi
  local c="$1" base="${2:-.}" tab=$'\t'
  if printf '%s' "$c" | grep -Eq '(^|[;&|[:space:]"'"'"'])git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)'; then
    local nv=0 all=0 add=0
    printf '%s' "$c" | grep -Eq -- '--no-veri|[[:space:]]-[a-zA-Z]*n[a-zA-Z]*([[:space:]]|$)' && nv=1
    printf '%s' "$c" | grep -Eq -- '--all|[[:space:]]-[a-zA-Z]*a[a-zA-Z]*([[:space:]]|$)' && all=1
    printf '%s' "$c" | grep -Eq 'git[[:space:]]+(add|rm|mv)[[:space:]]' && add=1
    # Unparseable: assume the worst about what gets committed (pathspec=1).
    printf 'COMMIT%s%s%s%s%s1%s%s%s%s\n' "$tab" "$nv" "$tab" "$all" "$tab" "$tab" "$add" "$tab" "$base"
  fi
  if printf '%s' "$c" | grep -Eq '(^|[;&|[:space:]"'"'"'])git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)'; then
    local f=0 nv=0
    printf '%s' "$c" | grep -Eq -- '--force|--mirror|[[:space:]]-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$)|[[:space:]]\+[^[:space:]]+' && f=1
    printf '%s' "$c" | grep -Eq -- '--no-veri' && nv=1
    printf 'PUSH%s%s%s%s\n' "$tab" "$f" "$tab" "$nv"
  fi
  return 0
}
