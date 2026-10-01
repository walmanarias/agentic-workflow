#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit): enforce role separation between the lifecycle agents.
# Hook input carries `agent_type` when a subagent makes the call; the main thread is never
# restricted. Only agentic-sdd's own agents are guarded (bare name or `agentic-sdd:` prefix).
# Exit 2 => blocked with the reason fed back to the agent.
# Escape hatch for humans: AGENTIC_SDD_ROLE_GUARD=off in settings env.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
[ "${AGENTIC_SDD_ROLE_GUARD:-on}" = "off" ] && exit 0
read_hook_input

agent="$(json_get '.agent_type')"
[ -z "$agent" ] && exit 0
case "$agent" in
  *:*) ns="${agent%%:*}"; role="${agent##*:}"; [ "$ns" = "agentic-sdd" ] || exit 0 ;;
  *)   role="$agent" ;;
esac

file="$(json_get '.tool_input.file_path')"
[ -z "$file" ] && exit 0
rel="$(rel_path "$file")"

deny() {
  printf '%s\n- %s: %s\n- %s\n' \
    "$(t "Blocked by the agentic-sdd role guard:" "Bloqueado por el guardián de roles de agentic-sdd:")" \
    "$role" "$rel" "$1" >&2
  exit 2
}
# shellcheck disable=SC2254  # $p is a glob pattern on purpose
under() { local p; for p in "$@"; do case "$rel" in $p) return 0;; esac; done; return 1; }

case "$role" in
  tdd-test-writer)
    is_any_test_file "$rel" || deny "$(t "RED step: write tests only. Production code belongs to the implementer — import the missing module so the test fails meaningfully." \
                                        "Paso RED: solo pruebas. El código de producción es del implementer — importa el módulo faltante para que la prueba falle con sentido.")" ;;
  e2e-tester)
    is_any_test_file "$rel" || under 'docker-compose*.yml' 'compose*.yml' '*/docker-compose*.yml' \
      || deny "$(t "E2E step: write E2E tests, fixtures and test config only. Hand production changes to the implementer." \
                   "Paso E2E: solo pruebas E2E, fixtures y configuración de pruebas. Pasa los cambios de producción al implementer.")" ;;
  implementer)
    is_any_test_file "$rel" && deny "$(t "GREEN step: never edit tests to make them pass. If a test is wrong, stop and flag it to tdd-test-writer with the reason." \
                                         "Paso GREEN: nunca edites pruebas para que pasen. Si una prueba está mal, detente y repórtalo al tdd-test-writer con el motivo.")" ;;
  spec-writer|planner)
    under 'specs/*' || deny "$(t "This agent writes only under specs/." "Este agente solo escribe bajo specs/.")" ;;
  architect)
    under 'docs/design/*' 'docs/adr/*' || deny "$(t "The architect writes only docs/design/ and docs/adr/ — no code." "El architect solo escribe docs/design/ y docs/adr/ — sin código.")" ;;
  curator)
    under 'docs/*' '.claude/rules/9*' || deny "$(t "Curation is advisory: write only under docs/ and .claude/rules/9x-*." "La curación es consultiva: escribe solo bajo docs/ y .claude/rules/9x-*.")" ;;
  code-reviewer)
    under 'specs/*/review.md' 'specs/*/review-*.md' || deny "$(t "The reviewer only writes its report (specs/<feature>/review.md)." "El revisor solo escribe su reporte (specs/<feature>/review.md).")" ;;
  qa-visual)
    under '.qa-visual/*' 'specs/*/qa.md' || deny "$(t "Visual QA writes only captures/scripts under .qa-visual/ and its report specs/<feature>/qa.md." "QA visual solo escribe capturas/scripts en .qa-visual/ y su reporte specs/<feature>/qa.md.")" ;;
  cicd-engineer)
    under '.github/*' 'docs/*' || deny "$(t "The CI/CD engineer writes only .github/ and docs/." "El ingeniero CI/CD solo escribe .github/ y docs/.")" ;;
esac
exit 0
