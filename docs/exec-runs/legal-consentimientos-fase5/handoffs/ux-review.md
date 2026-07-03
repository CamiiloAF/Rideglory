# UX Review — legal-consentimientos-fase5

**Fecha:** 2026-07-03T02:40:29Z (reconfirmado en ronda 2, 2026-07-03T02:42:21Z, tras intento de FIX de Design)
**Rol:** UX Reviewer (rg-exec, nivel normal)
**Status:** blocked

## BLOQUEADO — no hay frames que revisar

`docs/exec-runs/legal-consentimientos-fase5/handoffs/design.md` reporta `status: blocked` — el rol de Design nunca llegó a producir diseño. Dos intentos consecutivos de Design contra `mcp__pencil__get_editor_state(include_schema: true)` fallaron con:

```
MCP error -32603: failed to connect to running Pencil app: visual_studio_code after 3 retries: transport not connected to app: visual_studio_code
```

Design documentó explícitamente que no leyó ni modificó `rideglory.pen`, no exportó pantallas, y no generó ningún HTML sustituto, en cumplimiento de la regla `feedback_pencil_mcp_block.md`.

Antes de escribir este review, reintenté yo mismo la misma llamada para confirmar que el bloqueo sigue vigente y no era transitorio:

```
mcp__pencil__get_editor_state(include_schema: true)
→ MCP error -32603: failed to connect to running Pencil app: visual_studio_code after 3 retries: transport not connected to app: visual_studio_code
```

Mismo error, sin cambios. El bloqueo persiste.

## Por qué no puedo proceder con la auditoría

Mi mandato es evaluar **frames diseñados en Pencil** (`EventOrganizerResponsibilityPage`, `MedicalConsentPage`) contra Nielsen, Laws of UX, WCAG 2.1 AA, HIG/Material y reglas Rideglory. No existe ningún frame — Design no llegó a crear `EventOrganizerResponsibilityPage` ni `MedicalConsentPage` en `rideglory.pen`. No hay `get_screenshot`/`snapshot_layout` posibles porque no hay nodos que exportar.

Por la misma regla que aplicó a Design (`feedback_pencil_mcp_block.md`), **no debo inventar mockups HTML, wireframes descriptivos ni "specs de facto"** como sustituto del diseño en Pencil, aunque el PRD normalizado (§3) describa el contenido funcional esperado de ambas pantallas (botones, mensajes de error inline, textos legales placeholder). Evaluar prosa descriptiva del PRD como si fuera un diseño visual no es una auditoría UX real — sería fabricar una aprobación sin fundamento visual.

## Frames revisados

| ID | Nombre | Veredicto |
|----|--------|-----------|
| — | `EventOrganizerResponsibilityPage` | No revisado — no existe en Pencil (Design bloqueado) |
| — | `MedicalConsentPage` | No revisado — no existe en Pencil (Design bloqueado) |

## Hallazgos

| Frame | Heurística/Ley | Severidad | Descripción específica | Fix requerido |
|-------|-----------------|-----------|-------------------------|----------------|
| N/A (proceso) | — | Bloqueante | Pencil MCP no conecta (`transport not connected to app: visual_studio_code`); no hay frames de `EventOrganizerResponsibilityPage` ni `MedicalConsentPage` que auditar | Un humano debe: (1) confirmar que la extensión Pencil está instalada/activa como panel visible en la ventana de VS Code, (2) confirmar que `rideglory.pen` está abierto como pestaña en el editor Pencil (no solo en el explorador de archivos), (3) reiniciar la extensión/ventana si el panel no aparece, (4) validar que el servidor MCP del lado de la extensión esté escuchando. Solo entonces reintentar la fase completa desde Design |

No se puede clasificar ningún hallazgo de contraste, touch targets, jerarquía visual, agrupación Gestalt, affordance de botones, etc. sin frames reales — cualquier hallazgo de ese tipo en este momento sería especulativo.

## Bloqueantes — deben resolverse antes de que Frontend empiece

1. **Pencil MCP sin conexión de transporte.** Design no pudo producir `EventOrganizerResponsibilityPage` ni `MedicalConsentPage`, y por consiguiente UX Review no tiene material que auditar. Frontend no debe empezar a implementar UI nueva sin un diseño aprobado en Pencil — hacerlo violaría la regla de memoria `feedback_ui_design_first.md` (diseñar primero, esperar aprobación explícita, luego implementar) y `feedback_design_pencil.md` (todo diseño nuevo vive en `rideglory.pen`).

## Sugerencias — backlog de UX (no bloquean)

Ninguna — no hay diseño sobre el cual sugerir mejoras no bloqueantes. Una vez desbloqueado Pencil y producido el diseño real, este review debe repetirse desde cero contra los frames concretos, evaluando en particular (a partir de lo descrito en el PRD normalizado, solo como puntos de atención a verificar visualmente, no como aprobación anticipada):

- Contraste WCAG AA del texto de error inline (`colorScheme.error`) sobre el fondo oscuro de ambas pantallas.
- Tamaño de touch target (≥48x48dp) de `AppButton`/`AppTextButton` en los pares "Acepto y publico el evento"/"Revisar evento" y "Autorizar"/"No autorizar".
- Jerarquía visual entre la acción primaria (aceptar/autorizar) y la secundaria (revisar/no autorizar) — evitar que ambas compitan visualmente (Hick's Law: reducir carga de decisión en un consentimiento legal sensible).
- Legibilidad y scrolleabilidad del bloque de texto legal largo (patrón ya usado en `registration_medical_step.dart`/`registration_waiver_step.dart` — Jakob's Law: consistencia con el patrón existente en el wizard).
- Estado de carga (spinner) en `AppButton` durante la llamada HTTP de autorización — debe bloquear doble-tap (Postel's Law / robustez ante input duplicado), consistente con el guardrail de `_isNavigating` ya documentado en el PRD.
- Si cualquiera de las dos pantallas usa `AppColors.primary` como fondo, verificar que texto/iconos sean oscuros (`colorScheme.onPrimary`/`darkBgPrimary`), nunca blancos (regla `feedback_dark_text_on_primary`).

## Veredicto final

**blocked** — no existen frames en Pencil para `EventOrganizerResponsibilityPage` ni `MedicalConsentPage`; Design está bloqueado por fallo de transporte MCP↔extensión Pencil, reconfirmado nuevamente en esta segunda ronda (post-intento de FIX de Design). Esta fase no puede avanzar a Frontend sin diseño aprobado. Se requiere intervención humana en la GUI de VS Code/Pencil (extensión Pencil instalada/activa, `rideglory.pen` abierto como pestaña dentro del editor Pencil, servidor MCP del lado de la extensión escuchando) antes de reintentar Design y, después, este UX Review.

## Change log

- 2026-07-03T02:40:29Z: Reintento de `mcp__pencil__get_editor_state(include_schema: true)` confirma el mismo error de transporte reportado por Design. Se documenta bloqueo sin fabricar mockups/specs sustitutos, por regla `feedback_pencil_mcp_block.md`. Status: blocked.
- 2026-07-03T02:42:21Z (ronda 2, tras "modo FIX por UX Review" de Design en `design.md`): Design registró un segundo intento de desbloqueo (activar VS Code vía `osascript`, forzar apertura de `rideglory.pen` con `open -a`, esperar 5s) y reintentó `get_editor_state`; obtuvo el mismo error de transporte, sin cambios. Yo reconfirmé de forma independiente llamando `mcp__pencil__get_editor_state(include_schema: true)` en este mismo turno: **idéntico error**:
  ```
  MCP error -32603: failed to connect to running Pencil app: visual_studio_code after 3 retries: transport not connected to app: visual_studio_code
  ```
  Esto confirma que la causa raíz no es "VS Code cerrado" ni "archivo `.pen` no abierto" (ambas condiciones fueron remediadas por Design en su intento), sino el puente de transporte MCP↔extensión Pencil en sí — no reparable por un agente de terminal. No se produjo ningún frame nuevo, no hay nada que auditar, y por `feedback_pencil_mcp_block.md` no se fabrica ningún sustituto HTML/wireframe. El Bloqueante único permanece abierto. Status: blocked (sin cambios respecto a la ronda 1).
