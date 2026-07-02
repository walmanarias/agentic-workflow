#!/usr/bin/env bash
# Injects a short reminder of the SDD/TDD workflow at session start.
cat <<'MSG'
[agentic-sdd] Desarrollo Guiado por Especificación (SDD) + TDD activo.
Flujo: /plan (diseño) -> /spec -> /tdd (RED) -> /implement (GREEN+refactor) -> /e2e -> /review -> /ship.
Reglas: nada de código de producción antes de una prueba que falle; nunca debilites una prueba para que pase; código limpio + errores tipados; los commits pasan por lint + tipos + pruebas. Consulta CLAUDE.md.
MSG
exit 0
