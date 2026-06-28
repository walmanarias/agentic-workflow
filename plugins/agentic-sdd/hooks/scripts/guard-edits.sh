#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit): block clearly-bad content from being written.
# Exit 2 => the edit is blocked and the reason is fed back to Claude.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

file="$(json_get '.tool_input.file_path')"
content="$(json_get '.tool_input.content')"
[ -z "$content" ] && content="$(json_get '.tool_input.new_string')"
[ -z "$file" ] && exit 0

violations=""

if is_js_file "$file"; then
  if is_test_file "$file" && printf '%s' "$content" | grep -Eq '\.only\s*\('; then
    violations="${violations}- Focused test (.only) detected — it would silently skip the rest of the suite.\n"
  fi
  if printf '%s' "$content" | grep -Eq '(^|[^A-Za-z0-9_])debugger\s*;'; then
    violations="${violations}- 'debugger;' statement detected — remove before saving.\n"
  fi
  if printf '%s' "$content" | grep -Eq 'eslint-disable($|[^-])' && ! printf '%s' "$content" | grep -Eq 'eslint-disable.*--'; then
    violations="${violations}- Blanket 'eslint-disable' without a reason — disable a specific rule and explain why.\n"
  fi
fi

if is_cs_file "$file"; then
  if printf '%s' "$content" | grep -Eq 'Debugger\s*\.\s*Break\s*\('; then
    violations="${violations}- 'Debugger.Break()' detected — remove before saving.\n"
  fi
  if printf '%s' "$content" | grep -Eq '#pragma\s+warning\s+disable' && ! printf '%s' "$content" | grep -Eq 'disable\s+[A-Z]{2,}[0-9]'; then
    violations="${violations}- Blanket '#pragma warning disable' (no specific code) — disable a specific analyzer id and explain why.\n"
  fi
fi

if [ -n "$violations" ]; then
  printf 'Blocked by agentic-sdd quality guard:\n%b' "$violations" >&2
  exit 2
fi
exit 0
