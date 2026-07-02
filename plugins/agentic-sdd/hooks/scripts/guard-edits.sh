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
    violations="${violations}- Prueba enfocada (.only) detectada — saltaría en silencio el resto de la suite.\n"
  fi
  if printf '%s' "$content" | grep -Eq '(^|[^A-Za-z0-9_])debugger\s*;'; then
    violations="${violations}- Sentencia 'debugger;' detectada — elimínala antes de guardar.\n"
  fi
  if printf '%s' "$content" | grep -Eq 'eslint-disable($|[^-])' && ! printf '%s' "$content" | grep -Eq 'eslint-disable.*--'; then
    violations="${violations}- 'eslint-disable' general sin motivo — desactiva una regla específica y explica por qué.\n"
  fi
fi

if is_cs_file "$file"; then
  if printf '%s' "$content" | grep -Eq 'Debugger\s*\.\s*Break\s*\('; then
    violations="${violations}- 'Debugger.Break()' detectado — elimínalo antes de guardar.\n"
  fi
  if printf '%s' "$content" | grep -Eq '#pragma\s+warning\s+disable' && ! printf '%s' "$content" | grep -Eq 'disable\s+[A-Z]{2,}[0-9]'; then
    violations="${violations}- '#pragma warning disable' general (sin código específico) — desactiva un id de analizador específico y explica por qué.\n"
  fi
fi

if is_py_file "$file"; then
  if printf '%s' "$content" | grep -Eq 'pdb\.set_trace\s*\(|(^|[^A-Za-z0-9_.])breakpoint\s*\('; then
    violations="${violations}- Punto de interrupción ('breakpoint()' / 'pdb.set_trace()') detectado — elimínalo antes de guardar.\n"
  fi
  if printf '%s' "$content" | grep -Eq '#\s*noqa([^:]|$)'; then
    violations="${violations}- '# noqa' general sin código — silencia una regla específica (p. ej. 'noqa: E501') y explica por qué.\n"
  fi
  if printf '%s' "$content" | grep -Eq '#\s*type:\s*ignore($|[^[])'; then
    violations="${violations}- '# type: ignore' general sin código — acótalo (p. ej. 'type: ignore[assignment]') y explica por qué.\n"
  fi
fi

if [ -n "$violations" ]; then
  printf 'Bloqueado por el guardián de calidad de agentic-sdd:\n%b' "$violations" >&2
  exit 2
fi
exit 0
