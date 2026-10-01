#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit): block clearly-bad content from being written.
# Exit 2 => the edit is blocked and the reason is fed back to Claude.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input

file="$(json_get '.tool_input.file_path')"
[ -z "$file" ] && exit 0
content="$(json_get_edits)"
[ -z "$content" ] && exit 0

violations=""
add() { violations="${violations}- $1\n"; }

# Lines that are deliberately exempt carry `sdd-allow-skip: <reason>`.
active() { printf '%s\n' "$content" | grep -v 'sdd-allow-skip:'; }

# --- Tests switched off (never weaken a test to go green) ---
if is_any_test_file "$(rel_path "$file")"; then
  re="$(skip_re_for "$file")"
  if [ -n "$re" ] && active | grep -Eq "$re"; then
    add "$(t "Skipped/disabled test detected (.skip, xit, .todo, Skip=, pytest.mark.skip/xfail, ...). Never switch a test off to go green. If the skip is deliberate (e.g. platform-specific), add \`sdd-allow-skip: <reason>\` on that line." \
             "Prueba omitida/desactivada detectada (.skip, xit, .todo, Skip=, pytest.mark.skip/xfail, ...). Nunca desactives una prueba para pasar. Si es deliberado (p. ej. específico de plataforma), agrega \`sdd-allow-skip: <motivo>\` en esa línea.")"
  fi
  if is_js_file "$file" && active | grep -Eq '\.only[[:space:]]*\('; then
    add "$(t "Focused test (.only) detected — it would silently skip the rest of the suite." \
             "Prueba enfocada (.only) detectada — saltaría en silencio el resto de la suite.")"
  fi
fi

if is_js_file "$file"; then
  if active | grep -Eq '(^|[^A-Za-z0-9_])debugger[[:space:]]*;'; then
    add "$(t "'debugger;' statement detected — remove it before saving." "Sentencia 'debugger;' detectada — elimínala antes de guardar.")"
  fi
  if printf '%s' "$content" | grep -Eq 'eslint-disable($|[^-])' && ! printf '%s' "$content" | grep -Eq 'eslint-disable.*--'; then
    add "$(t "Blanket 'eslint-disable' without a reason — disable one specific rule and explain why (\`-- reason\`)." \
             "'eslint-disable' general sin motivo — desactiva una regla específica y explica por qué (\`-- motivo\`).")"
  fi
fi

if is_cs_file "$file"; then
  if printf '%s' "$content" | grep -Eq 'Debugger[[:space:]]*\.[[:space:]]*Break[[:space:]]*\('; then
    add "$(t "'Debugger.Break()' detected — remove it before saving." "'Debugger.Break()' detectado — elimínalo antes de guardar.")"
  fi
  if printf '%s' "$content" | grep -Eq '#pragma[[:space:]]+warning[[:space:]]+disable' && ! printf '%s' "$content" | grep -Eq 'disable[[:space:]]+[A-Z]{2,}[0-9]'; then
    add "$(t "Blanket '#pragma warning disable' (no specific id) — disable one analyzer id and explain why." \
             "'#pragma warning disable' general (sin código específico) — desactiva un id de analizador específico y explica por qué.")"
  fi
fi

if is_py_file "$file"; then
  if printf '%s' "$content" | grep -Eq 'pdb\.set_trace[[:space:]]*\(|(^|[^A-Za-z0-9_.])breakpoint[[:space:]]*\('; then
    add "$(t "Breakpoint ('breakpoint()' / 'pdb.set_trace()') detected — remove it before saving." \
             "Punto de interrupción ('breakpoint()' / 'pdb.set_trace()') detectado — elimínalo antes de guardar.")"
  fi
  if printf '%s' "$content" | grep -Eq '#[[:space:]]*noqa([^:]|$)'; then
    add "$(t "Blanket '# noqa' without a code — silence one rule (e.g. 'noqa: E501') and explain why." \
             "'# noqa' general sin código — silencia una regla específica (p. ej. 'noqa: E501') y explica por qué.")"
  fi
  if printf '%s' "$content" | grep -Eq '#[[:space:]]*type:[[:space:]]*ignore($|[^[])'; then
    add "$(t "Blanket '# type: ignore' without a code — scope it (e.g. 'type: ignore[assignment]') and explain why." \
             "'# type: ignore' general sin código — acótalo (p. ej. 'type: ignore[assignment]') y explica por qué.")"
  fi
fi

if [ -n "$violations" ]; then
  printf '%s\n%b' "$(t "Blocked by the agentic-sdd quality guard:" "Bloqueado por el guardián de calidad de agentic-sdd:")" "$violations" >&2
  exit 2
fi
exit 0
