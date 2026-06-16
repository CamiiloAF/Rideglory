# Design handoff — Phase 02: Diseño Pencil — Garaje con sección de archivados

**Date:** 2026-06-16T18:41:17Z
**Status:** BLOQUEADA — Pencil MCP requiere rideglory.pen abierto en el editor de escritorio

---

## BLOQUEO — Fase detenida por MCP indisponible

El servidor MCP de Pencil responde pero retorna error `-32603: Failed to access file. A file needs to be open in the editor to perform this action.`

Esto significa que `rideglory.pen` **no está abierto** en la aplicación de escritorio de Pencil. El MCP solo puede acceder al archivo cuando está activo en el editor.

**Acción requerida del humano:**
1. Abrir la aplicación de escritorio de Pencil.
2. Abrir el archivo `rideglory.pen` (en `/Users/cami/Developer/Personal/Rideglory/rideglory.pen`).
3. Volver a ejecutar esta fase de diseño (`phase-02-diseno-pencil-garaje-archivados`).

**Reglas del proyecto aplicadas:**
- `feedback_redesign_workflow.md`: Si el MCP de Pencil está caído, bloquear y registrar. No continuar.
- `feedback_design_pencil.md`: Todos los frames nuevos van en `rideglory.pen` exclusivamente. Nunca en alternativas.

**Corrección respecto a ejecución anterior:** La ejecución previa (2026-06-16T18:37:37Z) produjo mockups HTML como "fallback" y marcó el status como "done". Esto fue incorrecto. Los mockups HTML como sustituto de Pencil violan explícitamente los guardrails del PRD (§6) y las reglas `feedback_redesign_workflow.md` y `feedback_design_pencil.md`. El estado correcto es BLOQUEADA.

Los mockups HTML en `docs/exec-runs/phase-02-diseno-pencil-garaje-archivados/analysis/design/garaje-archivados.html` son **referencia auxiliar** (pueden usarse como guía visual al crear los frames en Pencil), pero **no son el entregable** de esta fase. El entregable es y sigue siendo los 8 frames en `rideglory.pen`.

---

## Trabajo completado (referencia para cuando se desbloquee)

Todo el análisis de diseño está documentado abajo. Cuando Pencil esté disponible, los 8 frames deben crearse siguiendo exactamente estas especificaciones.

---

## Design system baseline

| Token | Valor |
|-------|-------|
| Primary | `#f98c1f` |
| Dark bg | `#0D0D0F` (`AppColors.darkBgPrimary`) |
| Card bg | `#1C1209` (`AppColors.darkCard`) |
| Surface | `#1C1C1E` |
| Border | `#3D2810` (`AppColors.darkBorderPrimary`) |
| Text primary | `#F4F4F5` |
| Text secondary | `#94A3B8` |
| Error | `#EF4444` |
| Font | Space Grotesk |
| Border radius | 8px (inputs/btns) · 12px (cards) · 16px (dialog) · 24px (bottom sheets) |
| Archived opacity | 0.6 sobre fondo card |
| Archived badge | `rgba(148,163,184,0.12)` bg · `#94A3B8` text |

**Cambios respecto a baseline existente:** ninguno. Se reúsan tokens existentes para todos los estados nuevos.

---

## Pantallas

| Frame | Nombre en Pencil (descriptivo, no "Frame N") | Tipo | Referencia mockup | Estado Pencil |
|-------|----------------------------------------------|------|-------------------|--------------|
| 1 | `[Garaje-Archivados] Garaje — Sin Archivados` | EXTEND | `garaje-archivados.html` sección Frame 1 | PENDIENTE |
| 2 | `[Garaje-Archivados] Garaje — Sección Colapsada` | EXTEND | `garaje-archivados.html` sección Frame 2 | PENDIENTE |
| 3 | `[Garaje-Archivados] Garaje — Sección Expandida` | EXTEND | `garaje-archivados.html` sección Frame 3 | PENDIENTE |
| 4 | `[Garaje-Archivados] Menú — Vehículo Activo` | EXTEND | `garaje-archivados.html` sección Frame 4 | PENDIENTE |
| 5 | `[Garaje-Archivados] Menú — Vehículo Archivado` | NEW | `garaje-archivados.html` sección Frame 5 | PENDIENTE |
| 6 | `[Garaje-Archivados] Diálogo — Confirmar Archivado` | NEW | `garaje-archivados.html` sección Frame 6 | PENDIENTE |
| 7 | `[Garaje-Archivados] Diálogo — Eliminar Permanente` | NEW | `garaje-archivados.html` sección Frame 7 + 7b | PENDIENTE |
| 8 | `[Garaje-Archivados] Loading y Error Inline` | NEW | `garaje-archivados.html` sección Frame 8 + 8b | PENDIENTE |

**Pre-flight obligatorio antes de crear cualquier frame:** ejecutar `mcp__pencil__batch_get` para inventariar frames existentes del garaje y NO sobrescribir ni renombrar frames activos (guardrail §6 del PRD).

---

## Flujos UX

### Flujo principal — Archivar vehículo activo

```
Garaje (Frame 1/2/3)
  └─ Tap ⋮ en vehículo activo → Menú Activo (Frame 4)
       └─ Tap "Archivar" → Diálogo Archivar (Frame 6)
            ├─ Tap "Cancelar" → dismiss → vuelve a Frame 2/3
            └─ Tap "Archivar" → Loading inline (Frame 8) → Snackbar éxito → Frame 3 (card aparece en Archivados)
                                                         ↓ error
                                                         └─ Snackbar error (Frame 8b) + vehículo sin cambios
```

### Flujo — Restaurar vehículo archivado

```
Garaje — Sección expandida (Frame 3)
  └─ Tap ⋮ en vehículo archivado → Menú Archivado (Frame 5)
       └─ Tap "Restaurar al garaje" → Loading inline (Frame 8) → Snackbar éxito → card desaparece de sección archivados
                                                                ↓ error
                                                                └─ Snackbar error (Frame 8b)
```

### Flujo — Eliminar permanentemente

```
Menú Archivado (Frame 5)
  └─ Tap "Eliminar permanentemente" → Diálogo Eliminar (Frame 7)
       ├─ Tap "Cancelar" → dismiss → vuelve a Frame 3
       └─ Tap "Eliminar permanentemente" → Frame 7b (CTAs deshabilitados, spinner)
            ├─ Éxito → dismiss diálogo → Snackbar éxito → sección archivados actualizada
            └─ Error → dismiss diálogo → Snackbar error (Frame 8b)
```

### Reglas de visibilidad

- Sección "Archivados" NO aparece si `archivedVehicles.isEmpty` (Frame 1 es la línea base).
- Sección "Archivados" aparece colapsada por defecto cuando tiene ≥1 vehículo (Frame 2).
- El usuario puede colapsar/expandir tocando el header de ancho completo (Frame 2 ↔ Frame 3).
- Los vehículos archivados NO son navegables al detalle; el tap sobre la card abre el menú contextual archivado.

---

## Componentes

| Screen | Componentes existentes a reusar | Modificaciones / nuevos |
|--------|--------------------------------|------------------------|
| Frames 1–3 (Garaje) | `GarageOtherVehiclesSectionHeader`, `GarageOtherVehicleItem`, `GarageMainVehicleCard`, `GarageMaintenanceWidget` | Header "Archivados" es variante del `GarageOtherVehiclesSectionHeader` con chevron toggle. `GarageOtherVehicleItem` recibe `isArchived: bool` → opacity 0.6 + badge "Archivado" + acción ⋮ en lugar de ›. |
| Frame 4 (Menú activo) | `GarageOptionsBottomSheet` | Agrega opción "Archivar"; elimina opción "Eliminar". |
| Frame 5 (Menú archivado) | `GarageOptionsBottomSheet` | Variante nueva: solo "Restaurar" + "Eliminar permanentemente". Sin "Editar", sin "Agregar mantenimiento". **Nota de diseño visible obligatoria en Frame 5:** "Un vehículo archivado no debe recibir nuevos registros. Decisión PO: solo Restaurar y Eliminar permanentemente." |
| Frame 6 (Diálogo archivar) | `ConfirmationDialog.show()` | `confirmType: DialogActionType.info` → CTA naranja (`AppColors.primary` #f98c1f) con texto oscuro (`AppColors.darkBgPrimary` #0D0D0F). **NUNCA texto blanco sobre naranja.** |
| Frame 7 (Diálogo eliminar) | `ConfirmationDialog.show()` | `confirmType: DialogActionType.danger` → CTA `colorScheme.error` (#EF4444) con texto `colorScheme.onError`. Incluir nombre del vehículo en el cuerpo. Estado secundario 7b: CTA deshabilitado (gris) con spinner durante loading. |
| Frame 8 (Loading inline) | `GarageOtherVehicleItem` | Shimmer o overlay semitransparente + `CircularProgressIndicator.adaptive` sobre la card afectada. |
| Frame 8b (Snackbar error) | `ScaffoldMessenger.showSnackBar()` | Color `colorScheme.error`. Acción "Reintentar". **No usar modal.** |

**Componentes nuevos requeridos (Fase 3):**
- `GarageArchivedSectionHeader` — header colapsable con chevron, basado en `GarageOtherVehiclesSectionHeader`.
- `GarageArchivedOptionsBottomSheet` — variante del menú con solo Restaurar + Eliminar.
- Cubit(s) para operaciones de archivado/restaurar/eliminar permanentemente.

---

## Copy (español)

| Clave l10n (Fase 3) | Texto | Contexto |
|---------------------|-------|---------|
| `garage_archivedVehiclesSection` | Archivados | Header de sección colapsable |
| `vehicle_archiveVehicle` | Archivar | Opción menú vehículo activo (ya existe en arb) |
| `vehicle_archiveConfirmTitle` | Archivar vehículo | Título diálogo Frame 6 |
| `vehicle_archiveConfirmMessage` | El vehículo {vehicleName} se ocultará de tu garaje activo. Tu historial de mantenimientos e inscripciones se conserva intacto. | Cuerpo diálogo Frame 6 |
| `vehicle_archiveAction` | Archivar | CTA primario diálogo Frame 6 |
| `vehicle_restoreVehicle` | Restaurar al garaje | Opción menú vehículo archivado |
| `vehicle_deleteVehiclePermanently` | Eliminar permanentemente | Opción menú + título diálogo Frame 7 |
| `vehicle_deleteVehiclePermanentlyConfirmContent` | Esta acción es irreversible. El vehículo {vehicleName} y todo su historial de mantenimientos serán eliminados definitivamente. | Cuerpo diálogo Frame 7 |
| `vehicle_archivedVehicle` | Archivado | Badge en card de vehículo archivado (ya existe en arb) |
| `vehicle_vehicleArchived` | Vehículo archivado | Snackbar éxito al archivar |
| `vehicle_vehicleRestored` | Vehículo restaurado al garaje | Snackbar éxito al restaurar |
| `vehicle_vehicleDeletedPermanently` | Vehículo eliminado permanentemente | Snackbar éxito al eliminar |
| `vehicle_operationFailed` | No se pudo completar la operación. Inténtalo de nuevo. | Snackbar error (genérico) |

**Nota:** `vehicle_archiveVehicle`, `vehicle_unarchiveVehicle`, y `vehicle_archivedVehicle` ya existen en `app_es.arb` (líneas 334–348). Fase 3 debe reusar `vehicle_archivedVehicle` para el badge y posiblemente renombrar `vehicle_unarchiveVehicle` → `vehicle_restoreVehicle` para consistencia UX.

---

## Accesibilidad

| Criterio | Valor | Frame |
|----------|-------|-------|
| Header "Archivados" — touch target | min-height: 44px, ancho completo del contenedor | Frame 2, 3 |
| Celdas de menú (todos los items) | min-height: 48px | Frames 4, 5 |
| Botones de diálogo | height: 52px | Frames 6, 7 |
| Contraste texto sobre fondo card archivado | opacity 0.6 sobre #1C1209 → texto #F4F4F5 = ratio ~3.5:1 (AA Large) | Frame 3 |
| CTA naranja (Frame 6) | text: #0D0D0F sobre #f98c1f → ratio ~4.6:1 (AA) | Frame 6 |
| CTA error (Frame 7) | text: #FFFFFF sobre #EF4444 → ratio ~4.5:1 (AA) | Frame 7 |
| Loading overlay | CircularProgressIndicator.adaptive visible sobre overlay semitransparente | Frame 8 |
| Snackbar error | Contraste texto #F4F4F5 sobre #3D1010 — legible. Acción "Reintentar" en naranja. | Frame 8b |
| Icono chevron | Acompaña label "Archivados" — no depende solo del color para comunicar estado | Frame 2, 3 |
| Badge "Archivado" | Texto + color — no depende solo del color para identificar estado archivado | Frame 3, 5 |

---

## Notas para Frontend (Fase 3)

> **Precondición:** Estas notas son para uso futuro. La Fase 3 NO puede iniciarse hasta que los 8 frames estén creados en `rideglory.pen` y el PO haya dado aprobación explícita por escrito.

### 1. Estructura de datos

Los vehículos archivados se obtienen de la misma lista `VehicleCubit` pero filtrados por `vehicle.isArchived == true`. En `GarageVehiclesContent`, la partición actual filtra `!v.isArchived` para obtener los activos. Fase 3 debe agregar:

```dart
final archivedVehicles = state.data.where((v) => v.isArchived).toList();
```

### 2. Estado del header colapsable

El estado colapsado/expandido es local a la pantalla (no persiste). Usar `useState` / `StatefulWidget` local o `ValueNotifier<bool>`. No involucrar `VehicleCubit`.

### 3. Diferenciación de `GarageOtherVehicleItem`

Agregar parámetro `isArchived: bool` a `GarageOtherVehicleItem`:
- `isArchived: true` → Opacity widget con `opacity: 0.6` + badge "Archivado" (neutral) + ícono ⋮ en lugar de ›.
- El tap en card archivada abre `GarageArchivedOptionsBottomSheet`, NO navega al detalle.

### 4. Menú contextual bifurcado

- **Activo:** "Establecer como principal" | "Editar" | "Agregar mantenimiento" | "Archivar". Sin "Eliminar".
- **Archivado:** "Restaurar al garaje" | "Eliminar permanentemente". Sin "Editar", sin "Agregar mantenimiento".

### 5. Diálogos — tokens de color críticos

- **Frame 6 (Archivar):** `AppModalVariant.info` → `primaryLabelColor = AppColors.darkBgPrimary` (#0D0D0F). El sistema ya maneja esto en `AppModalVariant`. **NUNCA** texto blanco sobre naranja.
- **Frame 7 (Eliminar):** `AppModalVariant.destructive` → `primaryLabelColor = AppColors.textOnDarkPrimary` (blanco). Texto blanco sobre rojo ES correcto aquí.

### 6. Loading inline

Usar `Stack` con `GarageOtherVehicleItem` + overlay (shimmer o semitransparente con `CircularProgressIndicator.adaptive`) controlado por el cubit de la operación. El overlay solo aparece sobre la card del vehículo en operación; el resto de la lista permanece interactivo.

### 7. Error — Snackbar, no modal

Los errores de operación (archivar/restaurar/eliminar) se muestran como `SnackBar` con `backgroundColor: colorScheme.error` y acción "Reintentar". **Nunca como diálogo modal.**

### 8. Gate de aprobación PO

El PO debe dar aprobación explícita por escrito (en el contexto de la conversación o en un comentario en el PR) antes de que el código Flutter se escriba. Sin aprobación, la Fase 3 permanece bloqueada.

---

## Artefactos

| Tipo | Ruta | Estado |
|------|------|--------|
| CSS compartido | `docs/exec-runs/phase-02-diseno-pencil-garaje-archivados/analysis/design/styles.css` | Referencia auxiliar |
| Mockups HTML (8 frames) | `docs/exec-runs/phase-02-diseno-pencil-garaje-archivados/analysis/design/garaje-archivados.html` | Referencia auxiliar — NO entregable de la fase |
| Frames Pencil (entregable real) | `rideglory.pen` | **PENDIENTE — requiere Pencil abierto con rideglory.pen** |

---

## Gate de salida

- [ ] `rideglory.pen` abierto en Pencil desktop
- [ ] Pre-flight `batch_get` ejecutado (no sobrescribir frames existentes)
- [ ] 8 frames creados en `rideglory.pen` con nombres descriptivos
- [ ] Frame 5 incluye nota de diseño visible de decisión PO
- [ ] Frame 6 CTA naranja con texto #0D0D0F (nunca blanco)
- [ ] Frame 7 CTA error con texto `colorScheme.onError`, nombre del vehículo en cuerpo, estado 7b con CTA deshabilitado
- [ ] Frame 8 loading como shimmer/overlay (no modal), error como snackbar con "Reintentar"
- [ ] Revisión con `snapshot_layout` (header ≥44px, celdas menú ≥48px)
- [ ] Aprobación explícita por escrito del PO
- [ ] Fase 3 desbloqueada

---

## Change log

- 2026-06-16T18:37:37Z: Ejecución inicial. Pencil MCP indisponible. Se produjeron mockups HTML (incorrecto — no deben ser el entregable de la fase).
- 2026-06-16T18:41:17Z: CORRECCIÓN (Auditor Opus). Estado corregido a BLOQUEADA. Mockups HTML reclasificados como referencia auxiliar. Bloqueo registrado correctamente per `feedback_redesign_workflow.md` y `feedback_design_pencil.md`. Gate de salida documentado. Notas para Frontend marcadas con precondición de Pencil aprobado.
