#!/usr/bin/env bash
# Tras completar un subagente tipo Task (generalPurpose), inyecta el paso "Revisor"
# del harness Implementador → Judge (Clean Architecture).
set -euo pipefail
exec python3 -c '
import json, sys

data = json.load(sys.stdin)
status = data.get("status")
if status != "completed":
    print("{}")
    sys.exit(0)

modified = data.get("modified_files") or []
task = data.get("task") or ""
summary = (data.get("summary") or "").strip()
if len(summary) > 3500:
    summary = summary[:3500] + "\n… (truncado)"

files_lines = "\n".join(f"- `{f}`" for f in modified[:80]) or "- _(ninguno reportado por el hook — usa `git status` / `git diff`)_"

msg = f"""### Harness — Paso revisor (Clean Architecture)

El **subagente implementador** terminó correctamente. Cambia de rol: eres el **Senior Code Reviewer** del proyecto.

**Activa la regla del repo:** `@agent-clean-architecture-reviewer` (archivo `.cursor/rules/agent-clean-architecture-reviewer.mdc`) y alinea con **`rideglory-coding-standards.mdc`**.

**Contexto del subagente**
- **Tarea:** {task}
- **Resumen:** {summary}

**Archivos modificados (hook `subagentStop`):**
{files_lines}

**Instrucciones**
1. Revisa el diff: `git diff` / diff por archivo respecto a la base adecuada (working tree o último commit).
2. Emite el **Veredicto** y el **Feedback para el implementador** en el formato definido en la regla del revisor.
3. **No implementes** correcciones tú mismo salvo que el usuario lo pida; si hay `CAMBIOS REQUERIDOS`, deja el texto listo para devolver al agente implementador en el siguiente turno.

_Paso automático generado por `.cursor/hooks/subagent-clean-arch-review.sh`._
"""

print(json.dumps({"followup_message": msg}))
'
