#!/usr/bin/env bash
# SessionStart: inject a short workflow reminder, the detected stack (which stack-expert
# skills to load), the helper-tools path, and any in-flight features to resume.
# Everything printed here lands in Claude's context — keep it to a few lines.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
tools="$(sdd_tools_dir)"

t "[agentic-sdd] Spec-Driven Development + TDD is active." "[agentic-sdd] Desarrollo Guiado por Especificación (SDD) + TDD activo."; echo
echo "Loop: /spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship"
t "Rules: no production code before a failing test; never weaken a test to pass; one slice = one green commit. Bugs: /fix. See CLAUDE.md." \
  "Reglas: nada de código de producción antes de una prueba que falle; nunca debilites una prueba; un slice = un commit en verde. Bugs: /fix. Ver CLAUDE.md."; echo

if [ -n "$tools" ] && has_python; then
  stack="$("$(python_cmd)" "$tools/detect_stack.py" "$root" 2>/dev/null)"
  [ -n "$stack" ] && echo "Stack → load these skills when implementing/testing: $stack"
  echo "Tools: $tools (ac_trace.py, coverage_check.py, detect_stack.py)"
fi

# In-flight features (status.md not shipped) — so a new session can resume.
if [ -d "$root/specs" ]; then
  n=0
  for s in "$root"/specs/*/status.md; do
    [ -f "$s" ] || continue
    phase="$(grep -m1 -E '^- \*\*Phase:\*\*' "$s" | sed -E 's/^- \*\*Phase:\*\* *//')"
    case "$phase" in shipped*|"") continue;; esac
    [ $n -eq 0 ] && t "In flight (resume with /feature <name>):" "En curso (reanuda con /feature <nombre>):" && echo
    echo "  - $(basename "$(dirname "$s")"): $phase"
    n=$((n + 1)); [ $n -ge 3 ] && break
  done
fi
exit 0
