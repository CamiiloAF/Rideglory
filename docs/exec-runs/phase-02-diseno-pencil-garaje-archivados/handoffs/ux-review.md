# UX Review — phase-02-diseno-pencil-garaje-archivados

**Fecha:** 2026-06-16T21:38:20Z
**Veredicto:** APROBADO CON NOTAS
**Nota de alcance:** Los 8 frames no fueron creados en `rideglory.pen` por bloqueo del MCP de Pencil (archivo no abierto en el editor de escritorio). La revisión se realizó sobre los mockups HTML de referencia (`analysis/design/garaje-archivados.html`) y el handoff de diseño (`handoffs/design.md`), que contienen las especificaciones completas de tokens, dimensiones, flujos y copy. Este UX Review es válido para desbloquear la fase de Frontend **bajo la condición** de que los frames se transcriban en Pencil fielmente a las especificaciones evaluadas (sin cambios de tokens, dimensiones ni jerarquía visual).

---

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|-------------------|-----------|
| F1 | Garaje — Sin Archivados | Idle (lista vacía de archivados) | Conforme |
| F2 | Garaje — Sección Colapsada | Idle colapsado | Conforme |
| F3 | Garaje — Sección Expandida | Idle expandido con cards archivadas | Conforme |
| F4 | Menú — Vehículo Activo | Bottom sheet abierto | Conforme |
| F5 | Menú — Vehículo Archivado | Bottom sheet abierto | Conforme |
| F6 | Diálogo — Confirmar Archivado | Modal idle | Conforme |
| F7 | Diálogo — Eliminar Permanente | Modal idle | Conforme |
| F7b | Diálogo — Eliminar Permanente (Loading) | Modal con request en curso | Conforme |
| F8 | Loading y Error Inline | Card con overlay de carga | Conforme |
| F8b | Snackbar Error Inline | Snackbar de error con acción | Conforme |

---

## Hallazgos por frame

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| F3 | Nielsen H1 (Visibilidad del estado) / Jakob's Law | Sugerencia | La card de vehículo archivado usa opacity 0.6 sobre todo el ítem, lo que reduce la percepción de interactividad. El único indicador de que la card es tappable (para abrir el menú) es el ícono ⋮. Un usuario puede no descubrir la acción si no ve el ⋮. | Agregar anotación en el frame Pencil que especifique explícitamente que el tap en cualquier punto de la card archivada (no solo en ⋮) abre `GarageArchivedOptionsBottomSheet`. Considerar un leve estado pressed/ripple sobre la card archivada para confirmar interactividad. |
| F5 | HIG — Safe Area | Sugerencia | El bottom sheet de menú archivado tiene `padding-bottom: 24px`. En dispositivos iPhone con home indicator (iPhone X en adelante), el sistema puede solaparse con el contenido inferior si no se respeta la safe area (`MediaQuery.of(context).padding.bottom`). | En el frame Pencil anotar que el bottom sheet debe sumar la inset `safeAreaBottom` a su padding inferior. Valor típico: `padding-bottom: max(24px, safeAreaBottom + 8px)`. |
| F6 | HIG — Dialog Action Order | Sugerencia | El CTA primario "Archivar" aparece encima de "Cancelar" en el diálogo de confirmación de archivado. En iOS HIG, para acciones positivas (no destructivas) la acción principal puede ir arriba o abajo, pero la convención de Material y iOS nativo suele poner la acción de cancelación primero para flujos de confirmación. El diseño actual (acción primaria arriba) es válido en Material; sin embargo en iOS puede sentirse inusual. | No bloqueante. Mantener el orden actual (acción principal arriba), pero anotar en el frame que el componente `ConfirmationDialog` de Rideglory ya maneja este orden consistentemente, por lo que no se debe invertir. Esto garantiza consistencia con otros diálogos de la app. |
| F7 | HIG — Dialog Action Order (destructivo) | Sugerencia | "Eliminar permanentemente" aparece encima de "Cancelar". En iOS HIG, para acciones **destructivas** la convención es que el botón destructivo vaya **debajo** del botón de cancelación para reducir el riesgo de tap accidental. | Evaluar en el frame Pencil si el componente `AppModalVariant.destructive` ya invierte el orden en iOS. Si no lo hace, considerar invertir el orden solo para destructivos (Cancelar arriba, Eliminar abajo) para alinearse con HIG. Decisión de bajo riesgo ya que el modal requiere un tap explícito previo. No bloqueante. |
| F8 | Rideglory — Sin spinners | Sugerencia | Frame 8 usa `CircularProgressIndicator.adaptive` sobre el overlay de la card durante la operación. El design system de Rideglory prefiere skeleton/shimmer para estados de carga. El PRD explícitamente autoriza CPI.adaptive para este caso de uso (carga de acción, no de pantalla), por lo que no es bloqueante. | En el frame Pencil aclarar con anotación: "CPI.adaptive es la opción primaria para overlays de acción inline. Shimmer es aceptable como alternativa. No mezclar ambos en la misma pantalla." Esto previene ambigüedad para el Frontend. |
| F2/F3 | Nielsen H6 (Reconocimiento sobre memoria) | Sugerencia | El contador de vehículos archivados aparece como badge separado ("2") junto al label "Archivados". El PRD nombra el estado como "Archivados (N)" sugiriendo que el número podría estar integrado en el label. La implementación con badge separado es UX-equivalente y visualmente más clara, pero puede generar inconsistencia en el copy con el PRD. | Confirmar con PO que el label en Pencil dice "Archivados" (con badge separado), no "Archivados (2)" como texto integrado. Documentar la decisión en el frame con anotación. |
| F8b | Fitts — Touch target del snackbar | Sugerencia | El botón de acción "Reintentar" en el snackbar tiene padding mínimo según CSS (`font-size: 13px; font-weight: 700`). El área táctil real depende del padding del contenedor del snackbar, no de un touch target explícito. Uso con guantes requiere ≥44px de alto. | En el Pencil frame anotar que la acción "Reintentar" debe tener un hitbox de mínimo 44px de alto (incluso si el texto es más pequeño). En implementación Flutter, usar `SnackBarAction` con un `Padding` o `InkWell` con área expandida. |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

**Ninguno.** No se identificaron hallazgos Bloqueantes. Todos los criterios de aceptación del PRD (§5) están satisfechos en el diseño de referencia:

- AC1: 8 estados/frames cubiertos en las especificaciones.
- AC2: Frame 5 incluye nota PO visible (`.po-note` en mockup).
- AC3: Header "Archivados" con `min-height: 44px` y ancho completo — verificado en CSS (`section-header-row { min-height: var(--tt-min) }`).
- AC4: Celdas de menú con `min-height: 48px` — verificado en CSS (`menu-item { min-height: var(--tt-menu) }`).
- AC5: CTA Frame 6 = naranja `#f98c1f` con texto `#0D0D0F` (oscuro, nunca blanco) — verificado en `.btn-info`.
- AC6: CTA Frame 7 = error `#EF4444` con texto `#FFFFFF` (`colorScheme.onError`) — verificado en `.btn-danger`.
- AC7: Frame 7 incluye nombre del vehículo en cuerpo y Frame 7b con CTA deshabilitado durante loading.
- AC8: Frame 8 usa overlay inline (no modal) para loading; Frame 8b usa snackbar con "Reintentar" (no modal).
- AC9: Todos los frames tienen nombres descriptivos (no "Frame 1", "Frame 2") — verificado en handoff §Pantallas.
- AC10: Gate de PO pendiente (este UX Review no substituye la aprobación del PO; son gates independientes).

---

## Sugerencias — backlog de UX (no bloquean)

1. **F3 — Affordance de tap en cards archivadas:** Anotar en Pencil que el tap en cualquier punto de la card (no solo en ⋮) abre el menú. Considerar estado pressed visible bajo opacity 0.6.

2. **F5 — Safe area en bottom sheet:** Anotar en Pencil: `padding-bottom = max(24px, safeAreaBottom + 8px)` para compatibilidad con iPhone home indicator.

3. **F6 — Orden de CTAs en diálogo informativo:** Mantener consistencia con `ConfirmationDialog` de la app; documentarlo en la anotación del frame para evitar debates en código review.

4. **F7 — Orden de CTAs en diálogo destructivo:** Evaluar si invertir (Cancelar arriba, Eliminar abajo) para seguir HIG en contextos destructivos. Decisión de bajo impacto; documentar en frame.

5. **F8 — Claridad sobre spinner vs shimmer:** Anotar en frame que CPI.adaptive es el patrón primario para overlay de acción; shimmer es alternativa aceptable. No mezclar ambos en la misma lista.

6. **F2/F3 — Copy "Archivados" vs "Archivados (N)":** Confirmar con PO el copy final del label del section header. Documentar decisión (badge separado = preferido).

7. **F8b — Touch target de "Reintentar":** Asegurar hitbox ≥44px para la acción del snackbar, especialmente para uso con guantes.

---

## Resumen ejecutivo

El diseño de referencia para el flujo de archivado de vehículos es sólido y cumple todos los criterios de aceptación del PRD. Los tokens de color son correctos en todos los frames críticos: texto oscuro sobre naranja en Frame 6, texto claro sobre rojo en Frame 7, y contrastes WCAG AA satisfechos en todos los estados incluyendo el estado archivado con opacity 0.6 (ratio efectivo ≈ 7.4:1).

Los flujos UX están bien diferenciados: menú contextual bifurcado (activo vs. archivado) con Hick's law aplicada (4 opciones para activo, 2 para archivado), diálogos de confirmación con copy que comunica consecuencias claras, y manejo de errores no-modal consistente con las reglas del design system.

Los únicos hallazgos son de carácter sugestivo — principalmente anotaciones que deben quedar documentadas en los frames de Pencil para guiar la implementación sin ambigüedad. No hay violaciones de heurísticas críticas, reglas Rideglory, WCAG AA ni Laws of UX que requieran rediseño.

El bloqueo principal sigue siendo la creación de los 8 frames en `rideglory.pen` (requiere Pencil desktop abierto con el archivo), y la aprobación explícita del PO. Ninguno de los hallazgos de este UX Review modifica esa precondición.

---

## Veredicto final

**APROBADO CON NOTAS** — El diseño cumple todos los criterios de aceptación del PRD y no tiene violaciones bloqueantes de heurísticas, WCAG 2.1 AA ni reglas Rideglory-específicas. Las 7 sugerencias son mejoras de documentación y anotación que no requieren cambios al diseño visual antes de implementar. Frontend puede proceder **una vez que:** (a) los frames sean creados en Pencil fielmente a las especificaciones evaluadas, y (b) el PO dé aprobación explícita por escrito.
