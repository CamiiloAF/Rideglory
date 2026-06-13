# UX Review — Flujo de creación de eventos (frames pendientes + S-5 naranja)

**Fecha:** 2026-06-11T18:06:24Z
**Veredicto:** BLOQUEADO

---

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|-------------------|-----------|
| `IMyvf` | Custom Route Builder — Vacío | Estado inicial sin waypoints, CTA deshabilitada | Bloqueado |
| `z58GM` | Custom Route Builder — Búsqueda Activa | Buscador abierto con resultados autocomplete | Bloqueado |
| `veaGt` | Custom Route Builder — Con Waypoints | 3 waypoints activos, CTA habilitada | Bloqueado |
| `kY0VR` | Custom Route Builder — Límite 9/9 | 9/9 puntos, banner de límite, CTA habilitada | Bloqueado |
| `FW3Hd` | Crear Evento — V3 Step 4 | Pantalla de revisión final antes de publicar | Bloqueado |

---

## Hallazgos por frame

| # | Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|---|-------|-----------------|-----------|-------------|---------------|
| 1 | z58GM, veaGt, kY0VR | Regla Rideglory S-5 · WCAG 1.4.3 | **Bloqueante** | Texto blanco (#FFFFFF) sobre badge naranja (#F98C1F) en números de waypoint >=2 en pins del mapa y lista lateral. Ratio ~2.9:1 (mínimo AA: 4.5:1). Pin #1 verde (#22C55E) con texto blanco tiene ratio ~1.6:1 — igualmente bloqueante. Afecta: z58GM (pin 2/badge 2), veaGt (pins 2,3/badges 2,3), kY0VR (pins 2-8/badges 2-8). | Cambiar todos los números sobre #F98C1F y #22C55E a #0D0D0F (darkBgPrimary). Aplica a pins del mapa y badges de lista. |
| 2 | FW3Hd | WCAG 1.4.1 · Nielsen #4 | **Bloqueante** | Step indicators (dots 30x30px, fill=#F98C1F) no contienen ícono ni texto — el estado "completado" se comunica solo por el color naranja. WCAG 1.4.1 prohíbe depender exclusivamente del color para transmitir información funcional. | Agregar ícono check (fill=#0D0D0F) dentro de los dots completados. Diferenciar paso activo vs. completado vs. pendiente por forma o ícono, no solo color. |
| 3 | veaGt, z58GM, kY0VR | Ley de Fitts · WCAG 2.5.5 · Outdoor rule | **Bloqueante** | Ícono X para eliminar waypoint mide 16x16px (veaGt/z58GM) y 14x14px (kY0VR). Mínimo requerido: 44x44px WCAG, preferencia 48px en uso con guantes. Es la acción destructiva más frecuente del flujo. | Envolver cada X en un frame contenedor de 44x44px. En kY0VR con 9 items comprimidos, mínimo 40x40px. El touch target es el frame, no el ícono. |
| 4 | veaGt | Ley de Fitts · WCAG 2.5.5 | **Bloqueante** | recenterBtn: 36x36px — por debajo del mínimo de 44x44px para controles de mapa en contexto outdoor. | Aumentar a mínimo 44x44px. |
| 5 | FW3Hd | WCAG 2.5.5 · Nielsen #4 | **Bloqueante** | backBtn en Step 4 mide 36x36px vs. 40x40px en IMyvf y veaGt del mismo flujo. Inconsistente + sub-mínimo. | Unificar a mínimo 40x40px (idealmente 44x44px) en todos los frames del flujo. |
| 6 | IMyvf | WCAG 1.4.3 | **Bloqueante** | Botón "Continuar" deshabilitado: fill=#242429, texto fill=#6B7280. Ratio de contraste ~2.4:1 — por debajo del mínimo de 4.5:1. El texto comunica información funcional al usuario sobre qué debe hacer para avanzar. | Elevar texto disabled a #9CA3AF mínimo (ratio ~5.1:1 sobre #242429). |
| 7 | kY0VR | WCAG 1.4.1 | **Sugerencia** | limitBanner usa solo color naranja (texto + ícono #F98C1F) para comunicar advertencia. Verificar que el ícono sea alert-triangle semántico. | Confirmar ícono de warning, no puramente decorativo. |
| 8 | z58GM | Nielsen #4 · Gestalt Similaridad | **Sugerencia** | Resultado activo en autocomplete se distingue solo por delta de color (#242429 vs #1E1E24) — muy sutil en dark mode. | Agregar indicador de selección más fuerte: borde izquierdo 3px naranja o check mark. |
| 9 | IMyvf | Nielsen #5 · Nielsen #6 | **Sugerencia** | Mapa vacío sin affordance visual de interactividad (sin animación, sin punto de ejemplo). El texto de instrucción es claro, pero la interacción no está demostrada visualmente. | Agregar punto pulsante de ejemplo sobre el mapa para demostrar el gesto de tapping. |
| 10 | FW3Hd | Nielsen #7 · Efecto posición serial | **Sugerencia** | "Guardar como borrador" solo accesible en CTA bar al final. Usuarios indecisos deben scrollear. | Agregar acceso a borrador desde el nav header (ícono overflow o link). |
| 11 | Flujo Route Builder | Nielsen #1 | **Sugerencia** | No existe frame de estado de carga para resultados de búsqueda. Solo hay cursor pulsante en el input. | Crear frame Búsqueda Cargando con skeleton rows en el dropdown. |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

1. **B-1 (z58GM/veaGt/kY0VR):** Texto blanco sobre naranja/verde en todos los badges de waypoints ≥2. Contraste ~2.9:1 y ~1.6:1. Cambiar a #0D0D0F. Este es el hallazgo S-5 reportado — afecta 3 frames con múltiples instancias.

2. **B-2 (FW3Hd):** Step indicator dots comunican "completado" solo por color naranja. WCAG 1.4.1 violado. Agregar ícono check oscuro dentro de los dots completados.

3. **B-3 (veaGt/z58GM/kY0VR):** Botón X eliminar waypoint: 14–16px. Acción destructiva crítica con el target más pequeño de la pantalla. Mínimo 44x44px de tap area.

4. **B-4 (veaGt):** recenterBtn: 36x36px. Aumentar a 44x44px.

5. **B-5 (FW3Hd):** backBtn: 36x36px. Aumentar a mínimo 40x40px, unificar con otros frames.

6. **B-6 (IMyvf):** Texto "Continuar" deshabilitado con contraste ~2.4:1. Elevar a #9CA3AF mínimo.

---

## Sugerencias — backlog de UX (no bloquean)

- **S-1 (kY0VR):** Confirmar ícono semántico en limitBanner.
- **S-2 (z58GM):** Indicador de resultado activo más fuerte en autocomplete.
- **S-3 (IMyvf):** Affordance visual de interactividad en mapa vacío.
- **S-4 (FW3Hd):** Acceso a borrador desde nav header.
- **S-5 (Flujo Route Builder):** Frame de estado de carga para búsqueda.

---

## Resumen ejecutivo

El Custom Route Builder y el Step 4 de revisión de evento muestran un diseño visualmente cohesionado y una jerarquía de información adecuada. El dark mode está bien aplicado en la mayoría de superficies y la experiencia de mapa con pins numerados y lista de waypoints es intuitiva. Sin embargo, hay 6 hallazgos bloqueantes.

El más crítico y sistemático es la violación S-5 — texto blanco sobre naranja/verde en los badges de número de waypoints, presente en 3 frames con múltiples instancias cada uno. Este es exactamente el anti-patrón de cero tolerancia del sistema Rideglory. La segunda prioridad son los touch targets de eliminación de waypoints (14–16px) — incompatibles con el uso outdoor con guantes que define el producto.

El Step 4 (FW3Hd) tiene buena densidad informativa y la jerarquía Publicar/Borrador está correctamente priorizada. Sus bloqueantes son el step indicator monocromático y el back button subdimensionado e inconsistente.

---

## Veredicto final

**BLOQUEADO** — 6 hallazgos bloqueantes: violación S-5 sistemática en badges de waypoint (3 frames), step indicators que dependen solo del color (FW3Hd), touch targets de eliminar waypoint inaceptablemente pequeños (14–16px), recenterBtn 36px, backBtn FW3Hd 36px, y texto disabled con contraste insuficiente en IMyvf.
