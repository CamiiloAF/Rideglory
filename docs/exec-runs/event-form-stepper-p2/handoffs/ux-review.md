# UX Review — event-form-stepper-p2

**Fecha:** 2026-06-11T23:14:30Z
**Ronda:** 2 (re-evaluación tras correcciones de diseño)
**Veredicto:** BLOQUEADO

---

## Frames revisados

| Frame ID | Nombre en Pencil | Estados revisados | Veredicto Ronda 2 |
|----------|-----------------|-------------------|-------------------|
| `AybHb` | Crear Evento — V3 Step 1 | Estado base (vacío) | Conforme |
| `EzQtb` | Crear Evento — V3 (Stepper) | Estado base Step 2 | Bloqueante |
| `XbcHD` | Crear Evento — V3 Step 3 | Estado base Step 3 | Conforme |
| `FW3Hd` | Crear Evento — V3 Step 4 | Estado base revisión | Aprobado con notas |

---

## Estado de los bloqueantes de Ronda 1

| Bloqueante | Descripción original | Estado |
|-----------|---------------------|--------|
| B-1 | Step 2 con contenido IA eliminada | **RESUELTO** — EzQtb muestra Dificultad, Tipo, Marcas, Cupo, Precio. Sin rastro de IA. |
| B-2 | Etiqueta "Desc" → "Detalles" en indicador | **RESUELTO** — Todos los indicadores de los 4 frames muestran "Detalles" para el paso 2. |
| B-3 | backBtn 36×36 → 40×40 en Step 1 y Step 3 | **PARCIALMENTE RESUELTO** — AybHb (MrrIM: 40×40 ✓), XbcHD (wUxoT: 40×40 ✓). **EzQtb (l9TbML: 36×36 — no corregido).** |
| B-4 | Botón "Atrás" ausente en NavBar del Step 1 | **RESUELTO** — AybHb NavBar (`xmT0F`) contiene únicamente el botón "Continuar" (`j8LBcS`) a ancho completo. |
| B-5 | Cupo/Precio en Step 3 → reubicar a Step 2 | **RESUELTO** — EzQtb contiene `Ie90s` (CUPO MÁXIMO) e `I8xfa4` (PRECIO POR PERSONA). XbcHD contiene únicamente PUNTOS DE RUTA y DISTANCIA ESTIMADA. |

---

## Hallazgos Ronda 2

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| `EzQtb` Step 2 | WCAG 2.5.5 (Touch target) + Ley de Fitts + Nielsen H4 (Consistencia) | **Bloqueante** | El `backBtn` de Step 2 (nodo `l9TbML`) mide **36×36 px** con `cornerRadius: 18`. Los frames Step 1 (MrrIM: 40×40) y Step 3 (wUxoT: 40×40) ya fueron corregidos, pero EzQtb no. La corrección B-3 fue incompleta: el Step 2 quedó sin aplicar. Inconsistencia directa que rompe la expectativa táctil entre pasos y viola AC #11 del PRD. | Actualizar `backBtn` (id `l9TbML`) en frame `EzQtb` de 36×36 a **40×40 px**; `cornerRadius` de 18 → 20. |
| `FW3Hd` Step 4 | Nielsen H6 (Reconocimiento sobre memoria) + Nielsen H3 (Control y libertad) | **Sugerencia** | Step 4 presenta **4 cards de revisión**: Información básica, Configuración, Ruta y **Fecha y hora**. El handoff original especifica 3 cards (Básico / Configuración / Ruta) y el PRD AC #13 define `goToStep(0, 1, 2)`. Un 4.º card con "Editar" requiere `goToStep(3)` — índice no documentado. Si la fecha merece card separado (justificación UX válida: es dato crítico para una rodada), debe actualizarse el contrato en el handoff y añadir las ARB keys correspondientes. | Definir explícitamente si el card "Fecha y hora" es intencional. Si lo es: (a) documentar `goToStep(0)` para la acción "Editar" del card Fecha (Step 1 contiene Fecha y Hora), (b) añadir ARB key `event_step_review_dateSection`. Si no: fusionar los campos Fecha/Hora dentro del card "Información básica". |
| `FW3Hd` Step 4 | WCAG 1.4.3 (Contraste) | **Sugerencia** | El botón "Guardar como borrador" (`SvL8T`) usa `fill: "$text-secondary"` (estimado `#A0A0B0`) sobre `fill: "$bg-tertiary"` (estimado `#242429`). El ratio estimado es ~4.2:1, levemente por debajo del umbral WCAG AA (4.5:1) para texto normal a 14 px. | Cambiar el fill del texto a `$text-primary` (#FFFFFF) sobre `$bg-tertiary`, o usar el patrón `AppTextButton` sin relleno de fondo. Verificar ratio post-fix ≥ 4.5:1. |
| `AybHb` Step 1 | Ley de Postel + Nielsen H10 (Ayuda contextual) | **Sugerencia** | El campo "Nombre del evento" no presenta placeholder de ejemplo en el estado vacío. La primera interacción del organizador con el formulario se beneficia de guía contextual sobre el tipo de nombre esperado. | Añadir `placeholder: "Ej: Rodada al Nevado del Ruiz"` al campo de nombre. |
| `XbcHD` Step 3 | Nielsen H1 (Visibilidad del estado) — estados incompletos | **Sugerencia** | El frame solo muestra Step 3 con waypoints ya cargados. No existe frame para el estado vacío del mapa (donde debería aparecer `PulsingMapDot`), ni para el estado de carga del autocomplete (`SearchSkeletonList`). Los estados S-3 y S-5 están documentados en el handoff pero no tienen representación visual en Pencil. | Añadir frame "Step 3 — Ruta (vacío)" con `PulsingMapDot` en el centro del mapa y sin waypoints. Añadir variante de estado loading del autocomplete con `SearchSkeletonList` (3 filas shimmer). |
| `AybHb` Step 1 | Regla Rideglory — estados de upload (4 fases) | **Sugerencia** | Solo existe el estado vacío del área de portada. No hay frame para estado post-selección (preview de imagen cargada) ni para el `CoverPickerSheet` (bottom sheet). | Añadir estado "portada seleccionada" con preview de imagen y opción de cambiarla. Añadir frame de `CoverPickerSheet` como estado separado. |
| `EzQtb` Step 2 | Rideglory — texto oscuro sobre primario | **Conforme** | Botón "Continuar" (`XJ6S2`) usa `fill: "$text-inverse"` sobre `fill: "$accent"`. `$text-inverse` resuelve a `#0D0D0F` (darkBgPrimary) según la confirmación de Ronda 1. Texto oscuro sobre naranja: correcto. | — |
| `AybHb` Step 1 | Rideglory — texto oscuro sobre primario | **Conforme** | Botón "Continuar" (`j8LBcS`) usa `fill: "$text-inverse"` sobre `fill: "$accent"`. Correcto. | — |
| `XbcHD` Step 3 | Rideglory — texto oscuro sobre primario | **Conforme** | Botón "Continuar" (`k3Ampy`) usa `fill: "$text-inverse"` sobre `fill: "$accent"`. Correcto. | — |
| `FW3Hd` Step 4 | Rideglory — texto oscuro sobre primario | **Conforme** | Botón "Publicar Evento" (`gmvdp`) usa `fill: "$text-inverse"` sobre `fill: "$accent"`. Correcto. Los iconos también usan `fill: "$text-inverse"`. | — |
| `AybHb` Step 1 | Nielsen H1 (Visibilidad del estado) — indicador | **Conforme** | Step 1 activo: círculo con `fill: "$accent"`, `stroke: "$accent-subtle" (outer)`, número `"1"` en `$text-inverse`. Steps futuros: `fill: "$bg-secondary"`, `stroke: "$border"`. Distinción clara sin depender solo del color (tamaño de stroke + número). | — |
| `EzQtb` Step 2 | Nielsen H1 — indicador | **Conforme** | Step 1 completado: círculo con ícono `check` en `$text-inverse` sobre `$accent`, línea de conexión naranja (`$accent`). Step 2 activo: círculo naranja con número. Steps futuros: gris. WCAG 1.4.1 cumplido: el check-icon diferencia "completado" de "activo" sin depender solo del color. | — |
| `XbcHD` Step 3 | Nielsen H4 (Consistencia) — contenido | **Conforme** | Step 3 contiene únicamente PUNTOS DE RUTA y DISTANCIA ESTIMADA. Cupo y Precio removidos correctamente. | — |
| `AybHb` Step 1 | WCAG 2.5.5 — NavBar | **Conforme** | Botón "Continuar" (`j8LBcS`): `height: 52`. Supera el mínimo de 44px. NavBar Step 1 sin botón "Atrás" — correcto para paso 0. | — |
| `FW3Hd` Step 4 | Nielsen H2 (Match mundo real) + Copy | **Conforme** | Copy en español sentence case: "Publicar Evento", "Guardar como borrador", "Editar", "Revisa tu evento", "Confirma los datos antes de publicar". Sin ALL CAPS en botones. | — |
| `FW3Hd` Step 4 | Nielsen H5 (Prevención de errores) — revisión | **Conforme** | Step 4 presenta cards con todos los campos clave (Nombre, Fecha, Portada, Dificultad, Tipo, Cupo, Precio, Ruta) y un botón "Editar" por card. El usuario puede verificar y corregir cualquier dato antes de publicar. | — |
| `XbcHD` Step 3 | WCAG 2.5.5 — backBtn | **Conforme** | `wUxoT`: 40×40 px, `cornerRadius: 20`. AC #11 del PRD cumplido. | — |
| `AybHb` Step 1 | WCAG 2.5.5 — backBtn | **Conforme** | `MrrIM`: 40×40 px, `cornerRadius: 20`. AC #11 del PRD cumplido. | — |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

**B-6 — backBtn de Step 2 no corregido (`EzQtb`, nodo `l9TbML`)**

El fix B-3 de Ronda 1 fue aplicado en Step 1 (MrrIM: 40×40) y Step 3 (wUxoT: 40×40), pero **el frame Step 2 (`EzQtb`) conserva su `backBtn` (`l9TbML`) a 36×36 px con `cornerRadius: 18`**. La inconsistencia hace que el área táctil del back button varíe entre pasos — toca en Step 1 (40px), se reduce en Step 2 (36px), vuelve a subir en Step 3 (40px) — violando WCAG 2.5.5, la ley de Fitts y Nielsen H4 (consistencia entre pantallas).

**Fix:** Actualizar nodo `l9TbML` en frame `EzQtb`: `width: 40, height: 40, cornerRadius: 20`.

---

## Sugerencias — backlog de UX (no bloquean)

- **S-1 (`FW3Hd`):** Step 4 tiene 4 cards de revisión (Básico, Configuración, Ruta, Fecha y hora) en lugar de las 3 del handoff original. Definir si el 4.º card es intencional; si lo es, documentar `goToStep(0)` para su acción "Editar" y añadir ARB key `event_step_review_dateSection`.
- **S-2 (`FW3Hd`):** Botón "Guardar como borrador" con `$text-secondary` sobre `$bg-tertiary` — contraste estimado ~4.2:1, levemente bajo el umbral WCAG AA 4.5:1. Cambiar a `$text-primary` o usar `AppTextButton` sin fondo.
- **S-3 (`AybHb`):** Campo nombre sin placeholder de ejemplo. Añadir `"Ej: Rodada al Nevado del Ruiz"` para reducir fricción en el primer input del formulario.
- **S-4 (`XbcHD`):** Faltan frames para estado vacío de Step 3 (con `PulsingMapDot`) y estado de carga del autocomplete (con `SearchSkeletonList`). Frontend necesita referencia visual para S-3 y S-5 documentados en el handoff.
- **S-5 (`AybHb`):** Falta frame del estado post-selección de portada (preview de imagen) y del `CoverPickerSheet` (bottom sheet).

---

## Resumen ejecutivo

Ronda 2 de la auditoría UX, evaluada tras las correcciones aplicadas por el Design agent. De los 5 bloqueantes identificados en Ronda 1, **4 fueron resueltos correctamente**: el Step 2 ahora muestra los campos de Detalles sin contenido de IA (B-1), las etiquetas del indicador dicen "Detalles" en todos los frames (B-2), el botón "Atrás" fue eliminado del NavBar de Step 1 (B-4), y los campos Cupo/Precio fueron movidos de Step 3 a Step 2 (B-5). La calidad del diseño mejoró notablemente y la arquitectura del wizard ahora es coherente con el PRD.

Sin embargo, **persiste un bloqueante**: el fix B-3 (backBtn 36→40px) se aplicó en Step 1 y Step 3 pero fue omitido en Step 2 (`EzQtb`, nodo `l9TbML` sigue en 36×36px). Una sola corrección de dos dimensiones en Pencil resuelve este issue y desbloquea el frontend.

Las sugerencias restantes (4.º card de revisión, contraste del borrador, placeholder de nombre, frames de estados vacíos) no bloquean la implementación y pueden abordarse en iteraciones posteriores.

---

## Veredicto final

**BLOQUEADO** — 1 bloqueante pendiente: `backBtn` de Step 2 (`EzQtb`, nodo `l9TbML`) a 36×36px — debe ser 40×40px para coincidir con Step 1 y Step 3 y cumplir AC #11 del PRD. Una corrección puntual en Pencil desbloquea el frontend.
