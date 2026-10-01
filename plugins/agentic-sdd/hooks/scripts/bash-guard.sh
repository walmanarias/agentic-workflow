#!/usr/bin/env bash
# PreToolUse(Bash): commands an agent must never run on its own.
#  - `git commit --no-verify` / `-n`: bypasses the quality gate. Humans keep the escape
#    hatch in their own terminal; the agent does not.
#  - force pushes (`--force`, `-f`, `--force-with-lease`, `+refspec`) and `git push --no-verify`.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$DIR/lib.sh"
read_hook_input
cmd="$(json_get '.tool_input.command')"
[ -z "$cmd" ] && exit 0
case "$cmd" in *git*) ;; *) exit 0;; esac
NL=$'\n'

msg=""
base="$(json_get '.cwd')"
while IFS=$'\t' read -r kind a b _; do
  case "$kind" in
    COMMIT) [ "$a" = "1" ] && msg="${msg}- $(t "Agents may not bypass the commit gate (--no-verify / -n). Fix what the gate reports; a human can bypass in their own terminal in a real emergency." "Los agentes no pueden saltarse la barrera de commit (--no-verify / -n). Corrige lo que reporta; un humano puede saltarla en su propia terminal en una emergencia real.")${NL}" ;;
    PUSH)   [ "$a" = "1" ] && msg="${msg}- $(t "Force pushes are blocked (--force, -f, --force-with-lease, +refspec). Push normally or ask the human." "Los push forzados están bloqueados (--force, -f, --force-with-lease, +refspec). Haz push normal o pídeselo al humano.")${NL}"
            [ "$b" = "1" ] && msg="${msg}- $(t "git push --no-verify is blocked." "git push --no-verify está bloqueado.")${NL}" ;;
  esac
done <<< "$(git_cmd_info "$cmd" "$base")"

if [ -n "$msg" ]; then
  printf '%s\n%s' "$(t "Blocked by the agentic-sdd command guard:" "Bloqueado por el guardián de comandos de agentic-sdd:")" "$msg" >&2
  exit 2
fi
exit 0
