# UX Review — flutter-permanent-delete-vehicle

**Fecha:** 2026-06-17T17:16:40Z
**Veredicto:** APROBADO CON NOTAS

---

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|-------------------|-----------|
| `EM0D6` | [Garaje-Archivados] Menú — Vehículo Archivado | idle | Aprobado con notas |
| `SqWs1` | [Garaje-Archivados] Diálogo — Eliminar Permanente | idle | Aprobado |
| `x7j5iJ` | [Garaje-Archivados] Diálogo — Eliminar (cargando) | loading | Aprobado con notas |
| `fOIJD` | [Garaje-Archivados] Snackbar — Error de operación | error | Aprobado |
| `HpUYE` | [Garaje-Archivados] F3 — Garaje archivados expandidos | idle (sección expandida) | Aprobado con notas |

---

## Hallazgos por frame

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| `x7j5iJ` | Nielsen H4 — Consistencia; Nielsen H1 — Visibilidad del estado | Sugerencia | El botón de acción en estado loading cambia de `#ef4444` (rojo) a `#242429` (gris oscuro), en lugar de mantenerse rojo con `opacity: 0.5`. Visualmente el botón queda idéntico en color al de cancelar. La spec del handoff de diseño dice explícitamente "CTA destructivo con `opacity: 0.5`". Aunque "Eliminando..." + spinner diferencian el estado, la pérdida del color rojo rompe la consistencia visual de la acción destructiva. | Cambiar `fill` de `B6WcU` de `#242429` a `#ef4444` y mantener `opacity: 0.5`, como dicta la spec. El estado de carga debe preservar el color de la acción — solo reducir opacidad, no cambiar el color. |
| `EM0D6` | WCAG 2.1 AA — Touch target; Ley de Fitts | Sugerencia | El botón de cierre (`jnKZS`, la X) mide 36×36px, por debajo del mínimo de 44×44px establecido en el playbook. Es acción secundaria (el sheet se puede cerrar deslizando) pero el estándar aplica a todos los elementos interactivos. | Aumentar `jnKZS` a 44×44px (o agregar padding invisible al hit area). Al ser un patrón repetido en toda la app, aplicar el fix en el componente base de bottom sheet si existe. |
| `HpUYE` | Nielsen H4 — Consistencia; Gestalt — Continuidad | Sugerencia | El frame se llama "F3 — Garaje archivados expandidos" y muestra los vehículos archivados visibles, pero el chevron del header de la sección archivada es `chevron-right` en lugar de `chevron-down`. En el frame `fOIJD` el mismo header usa `chevron-down` (estado expandido). El icono correcto para "expandido" es `chevron-down`; `chevron-right` señala "contraído" (drill-down). Esto genera ambigüedad sobre el estado de la sección. | Actualizar el chevron en `HpUYE` → `VocBq` de `chevron-right` a `chevron-down` para reflejar el estado expandido, consistente con el patrón del frame `fOIJD`. |
| `SqWs1` | Nielsen H5 — Prevención de errores; Nielsen H6 — Reconocimiento sobre memoria | Conforme | El diálogo muestra texto genérico sin nombre de vehículo interpolado. Esto es correcto para un frame estático de diseño — la interpolación ocurre en runtime via `vehicle_permanentDeleteMessage(name)`. El copy documental especifica la interpolación correctamente. | Sin acción requerida. |
| `SqWs1` | WCAG 2.1 AA — Contraste; Ley de Fitts | Conforme | Botón "Eliminar permanentemente": texto blanco (`#FFFFFF`) sobre `#ef4444` — ratio ≈ 4.5:1, cumple AA. Ambos botones tienen `height: 50px` > mínimo 44px. Icono `triangle-alert` en rojo con fondo `#EF44441A` — contraste de estado correcto. | Sin acción. |
| `EM0D6` | Nielsen H5 — Prevención de errores; Laws of UX — Postel | Conforme | La fila "Eliminar permanentemente" usa rojo (`#EF4444`) tanto en el icono (`trash-2`) como en el label. Diferenciación visual clara de acción destructiva vs acción neutral ("Restaurar" en gris/blanco). Height de ambas filas: 56px, supera el mínimo de 44px. | Sin acción. |
| `fOIJD` | Nielsen H9 — Recuperación de errores | Conforme | El snackbar de error incluye botón "Reintentar" (`#F98C1F` sobre `#3D1010`) — acción concreta disponible. Texto en español llano: "No se pudo completar la operación. Inténtalo de nuevo." Sin jerga técnica. | Sin acción. |
| `x7j5iJ` | Nielsen H1 — Visibilidad del estado | Conforme | El spinner (`loader-circle`) + texto "Eliminando..." en el botón deshabilitado comunican el estado de progreso correctamente. Ambos botones tienen opacidad reducida para señalar no-interactividad. | Sin acción. |
| `HpUYE` | Ley de Miller — Carga cognitiva | Conforme | La sección "ARCHIVADOS" agrupa los vehículos archivados con opacidad reducida (0.6/0.65), diferenciándolos visualmente de los activos. El header de sección usa acento gris (`#9CA3AF`) vs naranja primario de secciones activas — jerarquía correcta. | Sin acción. |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

Ninguno. No hay hallazgos Bloqueantes. Frontend puede proceder.

---

## Sugerencias — backlog de UX (no bloquean)

- **`x7j5iJ` (S1):** El botón de acción en loading debería mantener `fill: #ef4444` con `opacity: 0.5` en lugar de `fill: #242429`. La spec de diseño lo indica explícitamente y la consistencia de color de la acción destructiva es importante para el flujo — el usuario que ve el botón rojo oscurecer sabe que su acción está en progreso; si el botón cambia de color, puede parecer que se canceló la acción. Fix en Pencil: actualizar `B6WcU.fill` a `#ef4444`.

- **`EM0D6` (S2):** Botón de cierre (X) en 36×36px — aumentar a 44×44px para cumplir el estándar de touch targets del playbook. Bajo impacto individual (el sheet se puede deslizar para cerrar) pero es una deuda de accesibilidad acumulada si el mismo patrón se repite en todos los bottom sheets de la app.

- **`HpUYE` (S3):** Chevron `chevron-right` en el header de la sección "ARCHIVADOS" cuando la sección está expandida. Debería ser `chevron-down` para que el icono indique correctamente el estado expandido, consistente con el frame `fOIJD` donde ya usa `chevron-down`. Fix trivial en Pencil: `VocBq.icon = "chevron-down"`.

---

## Resumen ejecutivo

Los cinco frames del flujo de eliminación permanente están bien ejecutados. El lenguaje destructivo es claro y consistente: rojo `#EF4444` para icono, texto de fila y CTA del diálogo; overlay oscuro; descripción de irreversibilidad en español llano. Los touch targets de las filas del menú (56px) y los botones del diálogo (50px) superan los mínimos. El estado de error incluye acción de reintento. No se detectaron violaciones Bloqueantes.

Las tres sugerencias son correcciones menores de consistencia: el botón de acción en loading debería preservar el rojo en lugar de volverse gris (coherencia entre estados), el botón de cierre necesita un touch target más amplio (deuda de accesibilidad preexistente), y el chevron de la sección archivada en HpUYE apunta a la dirección incorrecta para el estado expandido. Ninguna bloquea el inicio del frontend.

---

## Veredicto final

**APROBADO CON NOTAS** — Sin Bloqueantes. Frontend puede implementar. Las 3 Sugerencias van al backlog de UX para corrección en iteración posterior o en el próximo Design pass.
