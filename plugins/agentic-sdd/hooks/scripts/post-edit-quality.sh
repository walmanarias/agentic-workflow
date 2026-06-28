#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): lint the changed JS/TS file and feed any
# problems back to Claude (exit 2) so they get fixed immediately.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

file="$(json_get '.tool_input.file_path')"
[ -z "$file" ] && exit 0
is_js_file "$file" || exit 0
case "$file" in *node_modules*|*/dist/*|*/build/*|*/.next/*) exit 0;; esac
[ -f "$file" ] || exit 0

root="$(project_root)"
command -v npx >/dev/null 2>&1 || exit 0
# Only lint when ESLint is actually installed in the project (no network installs).
( cd "$root" && npx --no-install eslint --version >/dev/null 2>&1 ) || exit 0

out="$( cd "$root" && npx --no-install eslint --fix "$file" 2>&1 )"
status=$?
if [ $status -ne 0 ]; then
  printf 'ESLint reported problems in %s (auto-fixable issues were fixed):\n%s\n\nFix the remaining issues before continuing.\n' "$file" "$out" >&2
  exit 2
fi
exit 0
