# UX Review — Flujo de creación de eventos: refactorización a multi-paso vs formulario único

**Fecha:** 2026-06-11T17:52:22Z
**Veredicto:** APROBADO CON NOTAS

> **Nota de auditoría:** Pencil Desktop no estaba activo durante esta revisión. Las herramientas Pencil MCP (`get_editor_state`, `batch_get`, `get_screenshot`) retornaron error de conexión. La auditoría se realizó basándose en: (1) docs/improvements/event-form-paginated-refactor-brief.md — especificación visual completa con anatomía de cada pantalla, (2) docs/plans/event-form-stepper/phases/phase-02-wizard-completo.md — criterios de aceptación detallados, (3) código actual en lib/features/events/presentation/form/ — estado real de la implementación, (4) docs/features/events.md — documentación del feature. El veredicto considera únicamente los hallazgos detectables desde estos fuentes. Una re-auditoría con Pencil activo es recomendable antes de iniciar Frontend si hay duda sobre la fidelidad visual de los frames nuevos (`AybHb`, `EzQtb`, `XbcHD`, `FW3Hd`, `IMyvf`, `z58GM`, `veaGt`, `kY0VR`).

---

## Frames revisados

| Frame ID | Nombre | Fuente | Estados revisados | Veredicto |
|----------|--------|--------|-------------------|-----------|
| `zbCa0` | Crear Evento (formulario único — baseline) | Inventario design-skill.md | idle (scroll único) | Conforme — referencia base |
| `AybHb` | Step 1 — Información básica | event-form-paginated-refactor-brief.md §3.2 | idle, portada vacía, portada seleccionada | Aprobado con notas |
| `EzQtb` | Step 2 — Configuración del evento | event-form-paginated-refactor-brief.md §3.3 | idle | Aprobado con notas |
| `XbcHD` | Step 3 — Ruta del evento | event-form-paginated-refactor-brief.md §3.4 | idle | Aprobado con notas |
| `FW3Hd` | Step 4 — Revisa tu evento | event-form-paginated-refactor-brief.md §3.5 | idle | Aprobado con notas |
| `IMyvf` | Desconocido — no en inventario design-skill.md | N/A | — | No auditado (Pencil inactivo) |
| `z58GM` | Desconocido — no en inventario design-skill.md | N/A | — | No auditado (Pencil inactivo) |
| `veaGt` | Desconocido — no en inventario design-skill.md | N/A | — | No auditado (Pencil inactivo) |
| `kY0VR` | Desconocido — no en inventario design-skill.md | N/A | — | No auditado (Pencil inactivo) |

---

## Hallazgos por frame

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| `AybHb` | Nielsen 1 — Visibilidad del estado + Rideglory: Estados de upload (4 fases) | Sugerencia | La especificación del área de portada menciona "área de tap (ícono + texto 'Agregar portada') que abre CoverPickerSheet" y "cuando hay portada seleccionada → mostrar preview con opción de cambiar", pero no documenta explícitamente el estado de carga mientras se genera la portada con IA. El frame base `zbCa0` tampoco tiene este estado. CoverPickerSheet cierra inmediatamente al pulsar "Generar con IA" y el estado de generación se refleja en `CoverPreviewWidget`, pero no está claro si el diseño muestra shimmer/skeleton o spinner durante ese proceso. Las 4 fases aprobadas (selección → progreso → procesamiento → confirmación) deben ser visibles en Step 1. | Verificar en Pencil que `AybHb` incluye un estado de generación de portada con shimmer/skeleton sobre el área de portada. Si no existe, añadirlo al frame. El plan ya establece que "sin spinner propio: el estado de generación se refleja en `CoverPreviewWidget`" — asegurar que `CoverPreviewWidget` use shimmer, no spinner. |
| `AybHb` | Nielsen 3 — Control y libertad / Ley de Hick | Sugerencia | En Step 1, el botón "Atrás" tiene `opacity: 0.4` (deshabilitado) porque es el primer paso. El brief especifica que "no regresa". Sin embargo, no hay botón "Cancelar" visible que permita abandonar la creación. En el formulario actual (`zbCa0`), el botón "Cancelar" está en el AppBar. En el wizard, el AppBar solo tiene "←" (Atrás en círculo) + "Nuevo Evento". Una vez dentro del wizard, el usuario queda atrapado sin ruta de escape obvia salvo swipe-back nativo. | El AppBar debe conservar una acción de "Cancelar" (AppTextButton, text-secondary) en el lado derecho mientras el botón trailing "Publicar" fue removido. Alternativamente, el botón "←" del AppBar (que en Step 1 actúa como cerrar) debe estar activo y claramente diferenciado del botón "Atrás" del nav bar deshabilitado. Documentar la diferencia semántica en el diseño. |
| `AybHb` | WCAG 2.1 AA — Touch targets (componentes) | Sugerencia | El botón "←" del AppBar se especifica como "36 px en círculo bg-secondary". WCAG 2.1 AA requiere 44×44px mínimo para touch targets. 36px está por debajo del mínimo. El contexto de uso (organizador creando evento, típicamente en pantalla táctil) eleva el riesgo. | Ampliar el área táctil del botón "←" a 44×44px mínimo. El círculo visual puede mantenerse en 36px si se añade padding invisible (`SizedBox(width: 44, height: 44)` centrado sobre el círculo de 36px). |
| `EzQtb` | Nielsen 8 — Diseño minimalista / Ley de Miller | Sugerencia | Step 2 agrupa 5 secciones: Dificultad, Tipo de Evento, Cupo Máximo, Precio, Marcas Permitidas. Esto puede resultar en un scroll largo en un paso que se presenta como "Configuración". Miller (7±2) se aplica a listas/opciones, no a secciones de formulario, pero la densidad cognitiva del paso merece validación visual. En contraste, Step 1 tiene Portada + Info básica + Fecha/hora — igualmente denso. | No es un cambio de diseño requerido. Verificar en Pencil que el Step 2 con todas las secciones cabe en scroll sin que alguna sección quede cortada en el fold inicial. Si Marcas Permitidas queda oculta (nunca visible sin scroll), evaluar moverla a un estado colapsado o a un paso propio. Este hallazgo se resuelve con la verificación visual en Pencil. |
| `FW3Hd` | Nielsen 6 — Reconocimiento sobre memoria / Nielsen 10 — Ayuda | Sugerencia | Step 4 ("Revisa tu evento") es solo lectura y muestra resumen de campos. La especificación no menciona botones de edición inline por card (e.g., "Editar básico", "Editar configuración"). Sin edición directa desde Step 4, el usuario que detecta un error debe navegar manualmente con "Atrás" hasta el paso correcto — esto requiere recordar en qué paso está cada campo. | Evaluar añadir un icono/botón de edición (lápiz o "Editar") por cada card del resumen en Step 4, que navegue directamente al paso correspondiente (`cubit.goToStep(n)`). Si el alcance no lo permite para esta fase, documentar como mejora futura (tech debt UX) en el plan. |
| `FW3Hd` | Rideglory — Texto sobre primario naranja | Sugerencia | El CTA "Publicar Evento" es un pill accent (naranja `#f98c1f`). El brief y los criterios de aceptación de Phase 2 AC-3 especifican explícitamente: "El botón accent tiene texto en `AppColors.darkBgPrimary`, nunca blanco." Esta regla debe verificarse en el frame Pencil antes de implementar — si el frame muestra texto blanco sobre el botón naranja, es una violación bloqueante. | Verificar en Pencil que el label "Publicar Evento" en el pill naranja usa color texto oscuro (`#0D0D0F`). Si usa blanco → escalar a Bloqueante. (No escalado ahora por imposibilidad de verificar Pencil.) |
| `XbcHD` | Ley de Fitts / WCAG — Touch targets | Sugerencia | Step 3 contiene `EventFormLocationsSection` que incluye búsqueda de lugares, puntos de ruta y posiblemente un mapa. Los elementos de toque del constructor de ruta (botones de agregar waypoint, eliminar, seleccionar en mapa) deben tener ≥ 44px. La especificación del brief no los dimensiona explícitamente. | Verificar en el frame `XbcHD` que los controles de punto de ruta (add, remove, edit) tienen altura mínima 44px. Los iconos de acción en filas de waypoint son propensos a quedar en 24–32px. |
| `zbCa0` | Nielsen 5 — Prevención de errores | Sugerencia | En el formulario actual (`zbCa0` — scroll único), el campo "Ciudad" existe y es parte del payload. El plan elimina este campo de la UI en modo wizard pero mantiene `city: ''` en el payload. La especificación especifica esto claramente. Sin embargo, si el modo edición conserva el scroll anterior, el campo "Ciudad" seguirá existiendo en edición pero no en creación — creando inconsistencia de formulario visible para el organizador que edita un evento creado con el wizard (donde `city` fue guardado como `''`). | Documentar este comportamiento inconsistente en los criterios de aceptación del modo edición. En particular: si el organizador edita un evento creado con el wizard, la ciudad aparecerá vacía en el campo ciudad del formulario de edición. Evaluar si el campo debe ocultarse o rellenarse con `meetingPointName` como proxy. |
| `IMyvf`, `z58GM`, `veaGt`, `kY0VR` | N/A | N/A | Frames no identificados en el inventario de design-skill.md. No fue posible auditar por unavailability de Pencil MCP. Podrían corresponder a: variantes de estado de los pasos (loading, error, vacío), estados intermedios del CoverPickerSheet, o la portada con IA generada. | Reactivar Pencil Desktop y ejecutar auditoría parcial de estos 4 frames si corresponden a estados UI críticos (error, carga, éxito). Si son variantes de componentes auxiliares, un comentario en el handoff es suficiente. |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

*Ningún hallazgo bloqueante confirmado desde las fuentes disponibles.*

**Nota:** El hallazgo de texto sobre primario naranja en `FW3Hd` (botón "Publicar Evento") es condicionalmente bloqueante — solo puede confirmarse con Pencil activo. Si al verificar el frame se detecta texto blanco sobre naranja, debe escalarse a Bloqueante antes de implementar el Step 4.

---

## Sugerencias — backlog de UX (no bloquean)

1. **`AybHb` (Step 1) — Estados de carga de portada con IA:** Añadir shimmer/skeleton en el área de portada durante la generación de IA. Las 4 fases visuales (selección → progreso → procesamiento → confirmación) son un patrón aprobado de Rideglory. Verificar que `CoverPreviewWidget` ya implementa este patrón o planificarlo en la implementación de `EventFormStep1`.

2. **`AybHb` (Step 1) — Ruta de escape desde Step 1:** Agregar "Cancelar" (AppTextButton, text-secondary) en el AppBar de todos los pasos del wizard o habilitar el botón "←" del AppBar para salir en Step 1. El botón "Atrás" del nav bar deshabilitado (`opacity: 0.4`) no cumple como ruta de escape.

3. **`AybHb` (Step 1) — Touch target del botón "←":** Ampliar el área táctil del botón circular de 36px a 44×44px mínimo (padding invisible).

4. **`FW3Hd` (Step 4) — Edición inline desde resumen:** Añadir botón "Editar" por card en Step 4 que navegue directamente al paso correspondiente (`cubit.goToStep(n)`). Sin esto, detectar un error en Step 4 requiere navegar manualmente "Atrás" x veces recordando qué campo pertenece a qué paso.

5. **`FW3Hd` (Step 4) — Verificar texto sobre naranja en Pencil:** Cuando Pencil esté disponible, confirmar que el pill "Publicar Evento" usa `AppColors.darkBgPrimary` (#0D0D0F) en el texto, no blanco. Si se encuentra violación, escalar a Bloqueante.

6. **`XbcHD` (Step 3) — Touch targets en controles de ruta:** Verificar que los controles de add/remove/edit de waypoints tienen ≥ 44px de área táctil.

7. **`zbCa0` → modo edición — Inconsistencia campo Ciudad:** Documentar y gestionar la inconsistencia de que eventos creados con wizard (city: '') mostrarán la ciudad vacía al ser editados en el formulario de edición (scroll único). Evaluar si el campo ciudad debe ocultarse o popularse desde `meetingPointName`.

8. **Frames `IMyvf`, `z58GM`, `veaGt`, `kY0VR` — Auditoría pendiente:** Verificar con Pencil activo qué pantallas o estados representan estos 4 frames y auditar contra los 5 frameworks.

---

## Resumen ejecutivo

El refactor del formulario de creación de eventos de scroll único a wizard de 4 pasos es una mejora UX sólida y bien fundamentada. La Ley de Hick respalda la decisión: dividir ~9 secciones en 4 pasos temáticos reduce la carga cognitiva inicial y facilita la validación por paso. El indicador de progreso visible (4 círculos con estado activo/completado/futuro) sigue el patrón aprobado de formularios multi-paso del proyecto (Mantenimientos). Los criterios de aceptación del plan son exhaustivos y cubren los riesgos UX más críticos (texto oscuro sobre naranja, un widget por archivo, cero métodos `Widget _build`).

Los hallazgos detectados son en su mayoría Sugerencias sin impacto en el core del flujo. El más relevante es la ausencia de ruta de escape visible en Step 1 del wizard: el botón "Atrás" deshabilitado no comunica al usuario cómo salir sin publicar, y el AppBar actual no tiene "Cancelar" cuando el wizard está activo. En el formulario scroll único (`zbCa0`) este problema no existía porque "Cancelar" estaba en el AppBar. El hallazgo sobre los touch targets del botón "←" (36px < 44px WCAG AA) debe resolverse antes de la implementación o durante ella como guardrail técnico. La incapacidad de auditar los frames `IMyvf`, `z58GM`, `veaGt`, `kY0VR` por Pencil inactivo es el principal gap de esta auditoría.

---

## Veredicto final

**APROBADO CON NOTAS** — El diseño del wizard de 4 pasos es coherente con el design system y los patrones UX aprobados del proyecto. No se detectaron violaciones bloqueantes desde las fuentes disponibles. Se requiere: (1) verificar texto sobre naranja en Step 4 con Pencil activo, (2) añadir ruta de escape "Cancelar" en el AppBar del wizard, (3) ampliar touch target del botón "←" a 44×44px. Los demás hallazgos son mejoras de calidad para backlog.
