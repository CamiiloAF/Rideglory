# UX Review — legal-privacidad-edad-fase7-organizador

**Fecha:** 2026-07-03T17:00:15Z
**Veredicto:** APROBADO CON NOTAS

## Contexto

Esta fase es **retroactiva y sin cambios visuales** (`needsDesign = false`, confirmado por
Design en `handoffs/design.md`). El único cambio de alcance (AC10) es una corrección de
lógica de fallback para `bloodType` nullable dentro de un `Text` ya existente en
`registration_detail_page.dart` — el árbol de widgets, layout y estilo de la fila "Tipo de
sangre" no cambian. No se creó ni modificó ningún frame en `rideglory.pen`.

Se auditó el frame `dJQM1` (`Detalle Inscripción — Vista Owner (Fase 7)`) contra los 5
frameworks vía `get_editor_state` + `batch_get` + `get_screenshot` para verificar
independientemente la afirmación de Design, y para detectar cualquier hallazgo preexistente
relevante que debiera documentarse como backlog.

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|--------------------|-----------|
| `dJQM1` | Detalle Inscripción — Vista Owner (Fase 7) | Estado único (aprobado, con filas ofuscadas y reales mezcladas; CTA Bar con Llamar/WhatsApp) | Conforme (sin cambios de esta fase) |

No existen frames de estado adicionales (loading/error/vacío) para este cambio: la fila de
tipo de sangre es texto estático dentro de una card ya cargada, sin estado propio.

## Hallazgos

| Frame | Heurística/Ley | Severidad | Descripción específica | Fix requerido |
|-------|-----------------|-----------|-------------------------|----------------|
| `dJQM1` — filas con valor ofuscado (`Identificación`, `Correo electrónico`, `Ciudad`, `Tipo de sangre`) | WCAG 2.1 AA — contraste texto normal ≥4.5:1 | Sugerencia (preexistente, fuera de alcance) | `rowValue` en estado ofuscado usa `#6B7280` sobre fondo de card `#242429` ≈ contraste 3.2:1 — por debajo del mínimo 4.5:1 para texto normal 13px/600 (no califica como "texto grande" bajo WCAG). Es un patrón usado en 4+ filas de esta pantalla y probablemente en otras pantallas del sistema (no introducido por esta fase). | Backlog de design system: subir el valor a un gris con ≥4.5:1 contra `#242429` (p. ej. `#8B93A1` o similar) para todas las instancias del patrón "valor ofuscado", en una iteración futura de Design — no bloquea esta fase porque el estilo no cambia aquí y afecta a un componente compartido más allá del alcance de este fix. |
| `dJQM1` — fila `rowValue` genérica (afecta directamente la fila "Tipo de sangre", objeto de AC10) | Postel's Law / Nielsen #8 (estética minimalista, prevención de desbordes) | Sugerencia | El nodo `rowValue` no tiene `textGrowth: fixed-width` ni límite de líneas — es de ancho automático (`auto`), sin wrap ni truncamiento. El propio `design.md` señala el riesgo: si el backend retorna un sentinel crudo largo (p. ej. `"__NOT_SHARED__"`) en `bloodTypeRaw`, el texto puede desbordar visualmente la fila (el `rowsContainer` recorta con `clip:true`, por lo que el texto se cortaría abruptamente a la mitad sin ellipsis, en vez de fallar). No rompe la funcionalidad (AC10 solo exige no crashear) pero es un defecto visual potencial. | No requiere cambio en Pencil (el layout no cambia). Ítem para Frontend/QA: aplicar `maxLines: 1` + `TextOverflow.ellipsis` al `Text` de `rowValue` en `registration_detail_page.dart` como salvaguarda defensiva, y verificar visualmente en QA con un valor largo simulado. Ya recomendado en `design.md § Notas para Frontend`; se ratifica aquí como hallazgo formal de UX. |
| `dJQM1` — CTA Bar (Llamar / WhatsApp) | Regla Rideglory — texto oscuro sobre primario / touch targets outdoor | Conforme | Botón "Llamar": relleno `#F98C1F` con texto e icono `#0D0D0F` (oscuro) — cumple la regla cero-tolerancia. Altura 50px en ambos botones — supera el mínimo 44px y el umbral crítico de 48px para uso con guantes. Botón "WhatsApp": outline + relleno translúcido verde con texto/icono verde sobre fondo casi negro — contraste alto, sin problema. | Ninguno. |
| `dJQM1` — título de navegación (`navTitle` = "Inscripción de Piloto") | Nielsen #2 (match sistema-mundo real) / consistencia de copy | Sugerencia (no bloqueante, fuera de alcance visual) | El texto estático del mockup no coincide literalmente con los títulos dinámicos que exige AC1/AC3 ("Detalles de solicitud" vs. "Mi inscripción"), pero esto es esperado: el frame es una referencia visual única y el título real se computa en código según `isOrganizerView`, no es un elemento de diseño a clonar por variante. | Ninguno para Design. Frontend debe verificar en implementación que el título dinámico coincide con AC1–AC3 (ya cubierto por criterios de aceptación, no por Pencil). |

## Bloqueantes — deben resolverse antes de que Frontend empiece

Ninguno. No hay hallazgos Bloqueantes: el frame `dJQM1` no cambia en esta fase, el layout de
la fila "Tipo de sangre" es correcto y estable, los botones de contacto cumplen touch targets
y la regla de texto oscuro sobre acento, y no hay riesgo de crash por el fallback de
`bloodType` a nivel visual.

## Sugerencias — backlog de UX (no bloquean)

1. **Contraste de valores ofuscados (`••••`)** — subir `#6B7280` a un tono con ≥4.5:1 sobre
   `#242429` en el design system compartido (afecta múltiples pantallas, no solo esta fase).
2. **Truncamiento defensivo de `rowValue`** — agregar `maxLines: 1` + `TextOverflow.ellipsis`
   al `Text` de valor en `registration_detail_page.dart` (fila "Tipo de sangre" y análogas)
   como salvaguarda ante sentinels largos del backend (`"__NOT_SHARED__"`), verificado en QA.
3. **Deuda de string sin uso** — `registration_maskedValue` queda sin call-sites tras el fix
   de AC10; decidir en una fase futura si se elimina del ARB (ya documentado por Architect).

## Veredicto final

**APROBADO CON NOTAS** — no hay bloqueantes. Los hallazgos son preexistentes o de
implementación defensiva, no requieren cambios en Pencil y no impiden que Frontend comience
la implementación del fix de AC10.
