# UX Review — phase-03-flutter-archivar-restaurar-vehiculos

**Fecha:** 2026-06-16T23:07:06Z
**Veredicto:** APROBADO CON NOTAS

---

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|-------------------|-----------|
| `eKwEX` | Menú — Vehículo Activo | Idle (4 opciones) | Aprobado con notas |
| `EM0D6` | Menú — Vehículo Archivado | Idle (solo Restaurar) | Aprobado con notas |
| `m0Ffw` | F1 — Garaje sin archivados | Vacío (sin sección archivados) | Conforme |
| `HtUQ8` | F2 — Garaje archivados colapsados | Header colapsado + badge "2" | Aprobado con notas |
| `HpUYE` | F3 — Garaje archivados expandidos | Expandido 2 items archivados | Aprobado con notas |
| `CeaoR` | F6 — Diálogo Confirmar Archivado | Modal confirmación | Conforme |
| `vf1hj` | F7 — Snackbar éxito archivado | Snackbar verde | Conforme |
| `B5pRg` | F8 — Snackbar éxito restaurado | Snackbar verde | Conforme |
| `gnCZx` | F9 — Snackbar error | Snackbar rojo | Aprobado con notas |

---

## Hallazgos por frame

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| `HpUYE` (F3) | WCAG 2.1 AA — Clip de contenido / Nielsen #1 Visibilidad del estado | **Sugerencia** | La sección `archivadosSection` (EljAr) está marcada `fully clipped` por `snapshot_layout`: inicia en y=704 dentro de un scrollContent de 638px de alto visible, de modo que los 2 items archivados no son visibles en el Pencil design. En Flutter el widget será scrollable, así que no hay bloqueo funcional; pero el frame de diseño no demuestra que los items archivados son alcanzables visualmente (no muestra el scroll). Riesgo: el frontend podría omitir padding inferior necesario para que el último item no quede bajo el tab bar. | En Pencil: aumentar la altura del frame a ~1100px o reducir el contenido de ejemplo (omitir maintWidget en esta variante) para que ambos items archivados sean visibles sin overflow. Añadir nota de diseño indicando que el contenido es scrollable. |
| `HpUYE` (F3) | Nielsen #4 Consistencia / Gestalt Similaridad | **Sugerencia** | Los dos items archivados usan opacidades distintas: el primero (`rSDeT`) tiene `opacity: 0.65` y el segundo (`G1zJ1e`) tiene `opacity: 0.60`. El handoff especifica 0.65 para todos los archivados. La inconsistencia es de ~8% y probablemente imperceptible en pantalla, pero viola la especificación y puede confundir al frontend si inspecciona el Pencil. | Unificar ambos items a `opacity: 0.65` en Pencil (G1zJ1e: cambiar de 0.60 a 0.65). |
| `HpUYE` (F3) | Nielsen #6 Reconocimiento / Laws of UX — Fitts | **Sugerencia** | El primer item archivado (`rSDeT`) no muestra el badge "Archivado" ni el ícono ⋮. El nodo `right` (If9qt) está en `enabled: false`, mostrando en cambio un estado "Archivando" (loader) deshabilitado invisible. El segundo item sí muestra badge "Archivado" + ícono ⋮. La asimetría hace que el primer item se vea diferente del segundo sin justificación de estado distinto. | En Pencil: en `rSDeT` activar `right` con badge "Archivado" + ícono ⋮ (igual que G1zJ1e), y eliminar o deshabilitar correctamente el estado loader. El estado "Archivando" (carga) debería ser un frame separado (F3-loading) si es un estado de diseño necesario, pero no debe mezclarse en el frame de estado expandido estable. |
| `EM0D6` | Nielsen #2 Match mundo real / Copy | **Sugerencia** | El title del bottom sheet del vehículo archivado es "Honda Africa Twin · Archivado" (texto en color `#9CA3AF`, gris secundario). La especificación no define explícitamente el color del title para archivados, y el gris reduce la prominencia del nombre vs el estado activo (`#FFFFFF`). El pattern existente en eKwEX usa `fill: #FFFFFF` para el title. La diferencia es coherente con el estado dimmed, pero debería documentarse explícitamente. | Sugerencia de bajo impacto: considerar si el title gris es intencional para reforzar el estado "archivado" o si debe ser blanco para mantener consistencia. Documentar la decisión en el handoff. No bloquea. |
| `EM0D6` | Laws of UX — Hick (opciones disponibles) | **Sugerencia** | El menú del vehículo archivado solo tiene una opción ("Restaurar"), sin ningún indicador textual de que otras opciones fueron intencionalmente omitidas. Para un usuario que no recuerde el flujo, podría generar confusión sobre por qué no puede editar un vehículo archivado. | Sugerencia no urgente: considerar añadir texto hint debajo de "Restaurar" (p.ej. "Para editar, restaura el vehículo primero") o un subtítulo en el sheetHead. Decisión de PO; no bloquea implementación. |
| `gnCZx` (F9) | Nielsen #9 Recuperación de errores | **Sugerencia** | El snackbar de error muestra texto "No se pudo completar la acción. Intenta de nuevo." sin un botón de acción de reintento dentro del snackbar. Las reglas Rideglory especifican que errores deben tener "botón reintentar". Sin embargo, el patrón de snackbar en Flutter SnackBar puede incluir un `action` (SnackBarAction). El diseño actual no muestra ese botón de acción. | En el handoff para Frontend: especificar que el SnackBar de error incluya `SnackBarAction(label: 'Reintentar', onPressed: () => /* re-dispatch */)`. En el frame Pencil: añadir botón "Reintentar" como texto al extremo derecho del snackbar. No bloquea: el flujo funciona sin él, pero la regla Rideglory lo requiere como mejora. |
| `eKwEX` | Nielsen #1 Visibilidad / WCAG — Contraste | **Conforme con nota** | El ícono de "Establecer como principal" (estrella) usa `fill: #9CA3AF` sobre fondo `#242429`. Ratio aproximado: #9CA3AF sobre #242429 ≈ 3.0:1. Para un ícono de 20×20px (componente UI) WCAG requiere ≥ 3:1 — pasa justo al límite. Aceptable. | Ninguno requerido. Nota para frontend: no degradar el color del ícono. |
| `CeaoR` (F6) | Rideglory — texto sobre primario naranja | **Conforme** | El CTA "Archivar" usa `fill: #0D0D0F` (darkBgPrimary) sobre `#F98C1F`. Correcto — nunca blanco. Ratio #0D0D0F sobre #F98C1F ≈ 7.8:1 (WCAG AAA). | Ninguno. |
| `vf1hj` / `B5pRg` | Rideglory — texto sobre success verde | **Conforme** | Snackbars de éxito: texto `#0D0D0F` (oscuro) sobre `#22C55E`. Ratio ≈ 6.1:1 (WCAG AA). Ícono check también `#0D0D0F`. Correcto. | Ninguno. |
| `HtUQ8` (F2) | WCAG — Touch target header | **Conforme** | `archiveHeader` (i5A5c) tiene `height: 44` explícito. Cumple el mínimo de 44px. | Ninguno. |
| `eKwEX` / `EM0D6` | Laws of UX — Fitts (opciones menú) | **Conforme** | Todos los ListTile de opciones tienen `height: 56`. Cumple 44px mínimo con margen. | Ninguno. |
| `CeaoR` (F6) | Laws of UX — Fitts (botones diálogo) | **Conforme** | Ambos botones (confirmBtn `QN7N5`, cancelBtn `C0HCdu`) tienen `height: 52`. Cumple. | Ninguno. |
| `m0Ffw` (F1) | Nielsen #7 Eficiencia / EmptyState | **Conforme** | Cuando no hay archivados, la sección no se renderiza (`SizedBox.shrink()`). El garaje no muestra estado vacío erróneo. El diseño muestra el garaje normal sin sección de archivados. Correcto. | Ninguno. |
| `HtUQ8` / `HpUYE` | Nielsen #4 Consistencia — Header sección | **Conforme** | El header "ARCHIVADOS" (i5A5c / FQKhT) sigue el mismo patrón visual que "OTROS VEHÍCULOS": barra gris 3×14px + label uppercase + badge + separador. Consistencia mantenida. | Ninguno. |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

No hay hallazgos bloqueantes. El flujo funcional, los tokens de color críticos, los touch targets y la separación activo/archivado están correctamente diseñados. El Frontend puede proceder.

---

## Sugerencias — backlog de UX (no bloquean)

1. **`HpUYE` — Frame demasiado pequeño para mostrar sección expandida:** La `archivadosSection` queda `fully clipped` en el canvas de Pencil (y=704 en contenido de 638px). Aumentar la altura del frame a ~1100px o simplificar el contenido de ejemplo para demostrar visualmente los items archivados. El bug es de representación en Pencil, no de implementación Flutter; sin embargo, dificulta la inspección del diseño.

2. **`HpUYE` — Inconsistencia de opacidad entre items archivados:** item 1 (`rSDeT`) tiene `opacity: 0.65`, item 2 (`G1zJ1e`) tiene `opacity: 0.60`. Unificar a `opacity: 0.65` según spec del handoff.

3. **`HpUYE` — Item 1 archivado sin badge ni ⋮:** `rSDeT` muestra el nodo `right` deshabilitado (estado "Archivando") en lugar del badge "Archivado" + ícono ⋮. Esto crea asimetría visual con el item 2. Si "Archivando" es un estado de carga, debe ser un frame separado; en F3 (estado expandido estable) ambos items deben mostrar badge + ⋮.

4. **`gnCZx` — Snackbar error sin botón reintentar:** Las reglas Rideglory requieren error accionable. Añadir `SnackBarAction(label: 'Reintentar')` en la implementación Flutter y reflejar en Pencil. Puede resolverse directamente en Frontend sin cambio de diseño si el PO lo aprueba.

5. **`EM0D6` — Considerar hint educativo en menú de archivado:** El menú de un solo ítem puede generar confusión sobre qué pasó con las otras opciones. Un subtítulo o hint "Para editar, restaura el vehículo" mejoraría la orientación del usuario. Decisión de PO.

---

## Resumen ejecutivo

El diseño de la Fase 3 cumple con los requisitos funcionales, los tokens del sistema de diseño y las reglas de accesibilidad críticas (WCAG AA en todos los contrastes, touch targets ≥ 44px, texto oscuro sobre naranja). Los flujos de archivar y restaurar son claros, la bifurcación del menú contextual activo/archivado está bien ejecutada, y el diálogo de confirmación usa correctamente `DialogActionType.primary` con texto `#0D0D0F` sobre naranja.

Los cinco hallazgos son sugerencias sin carácter bloqueante. El más relevante para calidad de diseño es la `archivadosSection` fully clipped en F3, que impide inspeccionar visualmente el estado expandido en Pencil; esto debería corregirse en el canvas pero no afecta la implementación Flutter. Los demás (opacidad inconsistente, item 1 sin badge, snackbar sin reintentar, hint educativo en archivado) son mejoras menores de calidad y consistencia.

El snackbar de error sin botón de reintento es el único hallazgo con un vínculo a una regla explícita de Rideglory ("Errores accionables"). Se recomienda que el Frontend lo implemente con `SnackBarAction` sin esperar corrección en Pencil.

## Veredicto final

**APROBADO CON NOTAS** — Sin bloqueantes. 5 sugerencias de mejora documentadas arriba. Frontend puede iniciar implementación de inmediato.
