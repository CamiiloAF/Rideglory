# Design handoff — Phase 03: Flutter — Archivar y restaurar vehículos

**Date:** 2026-06-16T23:02:25Z
**Status:** done

---

## Design system baseline

| Token | Valor |
|-------|-------|
| Primary | `#f98c1f` (`$accent`) |
| Dark bg | `#0D0D0F` (`$bg-primary`) |
| Card bg | `#1E1E24` (`$bg-card`) |
| Border | `#2A2A32` (`$border`) |
| Text primary | `#FFFFFF` (`$text-primary`) |
| Text secondary | `#9CA3AF` (`$text-secondary`) |
| Text muted | `#6B7280` (`$text-tertiary`) |
| Success | `#22C55E` (`$success`) |
| Error | `#EF4444` (`$error`) |
| Archived badge bg | `#9CA3AF1F` |
| Font | Space Grotesk (`$font-primary`) |
| Border radius | `$radius-sm`=8 · `$radius-md`=12 · `$radius-lg`=16 · `$radius-xl`=24 |

**Cambios respecto a baseline existente:** ninguno. Todos los estados nuevos reusan tokens existentes.

---

## Frames en rideglory.pen

Todos los frames viven en `rideglory.pen`. Prefijo de nombre: `[Garaje-Archivados]`.

| Frame ID | Nombre en Pencil | Tipo | Descripción |
|----------|-----------------|------|-------------|
| `eKwEX` | `[Garaje-Archivados] Menú — Vehículo Activo` | UPDATE | Bottom sheet de activos: Establecer como principal (condicional), Editar, Agregar mantenimiento, Archivar. Sin opción Eliminar (Fase 4). |
| `EM0D6` | `[Garaje-Archivados] Menú — Vehículo Archivado` | UPDATE | Bottom sheet de archivados: solo **Restaurar**. Eliminado "Eliminar permanentemente" (Fase 4) y nota de diseño. |
| `m0Ffw` | `[Garaje-Archivados] F1 — Garaje sin archivados` | NEW | Estado base: `GarageArchivedSection` retorna `SizedBox.shrink()`. Sección archivados invisible. |
| `HtUQ8` | `[Garaje-Archivados] F2 — Garaje archivados colapsados` | NEW | `GarageArchivedHeader` visible con chevron-right + badge "2". Lista de items no renderizada. |
| `HpUYE` | `[Garaje-Archivados] F3 — Garaje archivados expandidos` | UPDATE (renombrado) | Garaje con sección expandida: 2 items archivados a opacity 0.65, chevron rotado, opción ⋮ disponible. |
| `CeaoR` | `[Garaje-Archivados] F6 — Diálogo Confirmar Archivado` | NEW | `ConfirmationDialog` con `DialogActionType.primary`: CTA naranja + texto `$text-inverse` (#0D0D0F). Botón secundario gris. |
| `vf1hj` | `[Garaje-Archivados] F7 — Snackbar éxito archivado` | NEW | Garaje actualizado + snackbar verde "Vehículo archivado". |
| `B5pRg` | `[Garaje-Archivados] F8 — Snackbar éxito restaurado` | NEW | Vehículo vuelve a activos + snackbar verde "Vehículo restaurado". Sección archivados con un item menos. |
| `gnCZx` | `[Garaje-Archivados] F9 — Snackbar error` | NEW | Garaje sin cambios + snackbar rojo (`$error`) + ícono `triangle-alert`. |

**Frames de Fase 4 — NO son entregables de Fase 3:**

| Frame ID | Nombre | Pertenece a |
|----------|--------|-------------|
| `SqWs1` | `[Garaje-Archivados] Diálogo — Eliminar Permanente` | Fase 4 |
| `x7j5iJ` | `[Garaje-Archivados] Diálogo — Eliminar (cargando)` | Fase 4 |

---

## Pantallas

| Frame | ID Pencil | Nombre | Tipo | Descripción |
|-------|-----------|--------|------|-------------|
| F1 | `m0Ffw` | Garaje — Sin archivados | NEW | Estado base — sección archivados invisible (`SizedBox.shrink()`). |
| F2 | `HtUQ8` | Garaje — Archivados colapsados | NEW | `GarageArchivedHeader` visible, colapsado por defecto, chevron-right, badge "2". |
| F3 | `HpUYE` | Garaje — Archivados expandidos | UPDATE | Items archivados visibles (opacity 0.65 + badge "Archivado" + ⋮). Sin navegación al detalle. |
| F4 | `eKwEX` | Menú contextual — Activo | UPDATE | Opciones: Establecer como principal (condicional), Editar, Agregar mantenimiento, Archivar. |
| F5 | `EM0D6` | Menú contextual — Archivado | UPDATE | Solo "Restaurar". Sin Editar, sin Agregar mantenimiento, sin Eliminar permanentemente. |
| F6 | `CeaoR` | Diálogo — Confirmar archivado | NEW | `ConfirmationDialog` `DialogActionType.primary`: CTA naranja oscuro. |
| F7 | `vf1hj` | Snackbar — Éxito archivado | NEW | Garaje actualizado + snackbar `$success`. |
| F8 | `B5pRg` | Snackbar — Éxito restaurado | NEW | Vehículo vuelve a activos + snackbar `$success`. |
| F9 | `gnCZx` | Snackbar — Error | NEW | SnackBar con `$error`. Nunca modal. |

---

## Flujos UX

### Flujo A — Archivar vehículo activo

```
Garaje [F1/F2/F3]
  └─ Tap ⋮ en vehículo activo
       └─ GarageOptionsBottomSheet [F4 — eKwEX]
            └─ Tap "Archivar"
                 └─ Diálogo confirmación [F6 — CeaoR]
                      ├─ Tap "Cancelar" → dismiss → sin cambios
                      └─ Tap "Archivar" → VehicleActionCubit.archiveVehicle()
                           ├─ Éxito → archiveLocally(id) → snackbar "Vehículo archivado" [F7 — vf1hj]
                           │         vehículo desaparece de activos, aparece en archivados [F3]
                           └─ Error → snackbar error [F9 — gnCZx]
```

**Regla de promoción de principal:** si el vehículo archivado era `isMainVehicle: true`, `VehicleCubit._promoteNewMain` elige el siguiente vehículo activo (orden: `createdAt` desc, tie-break `id` asc lexicográfico) y lo marca como principal antes de emitir el nuevo estado.

### Flujo B — Restaurar vehículo archivado

```
Garaje — sección expandida [F3 — HpUYE]
  └─ Tap ⋮ en vehículo archivado
       └─ GarageOptionsBottomSheet [F5 — EM0D6]
            └─ Tap "Restaurar" → VehicleActionCubit.unarchiveVehicle()
                 ├─ Éxito → unarchiveLocally(id) → snackbar "Vehículo restaurado" [F8 — B5pRg]
                 │         vehículo vuelve a lista activa; sección archivados se colapsa/desaparece si queda vacía
                 └─ Error → snackbar error [F9 — gnCZx]
```

**Sin re-fetch:** `fetchMyVehicles` NO se invoca en ningún paso de archive/unarchive.

### Reglas de visibilidad de la sección archivados

| Condición | Comportamiento |
|-----------|---------------|
| `archivedVehicles.isEmpty` | `GarageArchivedSection` retorna `SizedBox.shrink()` — sección invisible [F1 — m0Ffw] |
| `archivedVehicles.length >= 1`, inicial | Header visible, colapsado por defecto [F2 — HtUQ8] |
| Usuario toca header | Toggle expandir/colapsar [F2 ↔ F3] |
| Vehículo restaurado y `archivedVehicles` queda vacío | Sección desaparece sin animación extra |

### Reglas del menú contextual bifurcado

| Estado vehículo | Opciones disponibles |
|-----------------|---------------------|
| Activo, no es principal | Marcar como principal, Editar, Agregar mantenimiento, Archivar |
| Activo, es principal | Editar, Agregar mantenimiento, Archivar |
| Archivado | Restaurar |

---

## Componentes

### Componentes existentes a reusar (sin modificación)

| Componente | Archivo | Uso en esta fase |
|-----------|---------|-----------------|
| `ConfirmationDialog` | `lib/shared/widgets/modals/confirmation_dialog.dart` | Diálogo de confirmación de archivado [F6 — CeaoR] con `DialogActionType.primary` |
| `GarageOtherVehicleItem` | `garage_other_vehicle_item.dart` | Base visual para items archivados (aplicar `Opacity(opacity: 0.65)` en wrapper) |
| `GarageOtherVehiclesSectionHeader` | `garage_other_vehicles_section_header.dart` | Referencia de estilo para `GarageArchivedHeader` (mismo patrón: barra + label + badge) |
| `ScaffoldMessenger.showSnackBar` | Flutter SDK | Snackbars de éxito y error [F7, F8, F9] |

### Componentes existentes a modificar

| Componente | Modificación |
|-----------|-------------|
| `GarageOptionsBottomSheet` | Bifurcar árbol de opciones por `vehicle.isArchived`. Referenciar `VehicleActionCubit`. Escuchar `archiveSuccess`/`unarchiveSuccess`. Añadir diálogo de confirmación para "Archivar" con `DialogActionType.primary`. |
| `GarageVehiclesContent` | Añadir partición `archivedVehicles`. Integrar `GarageArchivedSection` al final del `SliverChildListDelegate`. |

### Componentes nuevos a crear

#### `GarageArchivedHeader` — `garage_archived_header.dart`

```
StatelessWidget — 1 archivo propio
Props:
  count: int            — cantidad de vehículos archivados (muestra badge)
  isExpanded: bool      — controla ícono chevron (rotado 90° cuando expanded)
  onTap: VoidCallback   — callback de toggle

Anatomía visual (igual a GarageOtherVehiclesSectionHeader pero con chevron):
  Row:
    ├─ Barra gris 3×14px ($text-secondary)
    ├─ "ARCHIVADOS" (12px, 700, letter-spacing 1.2, $text-secondary)
    ├─ Badge con count (mismo chip que OTROS VEHÍCULOS)
    └─ Spacer + AnimatedRotation(chevron_right, 0.25 turns cuando expanded)

Touch target: min-height 44px
Semantics: Semantics(button: true, label: 'Archivados, $count vehículos. Toca para ${isExpanded ? "colapsar" : "expandir"}')
```

Referencia visual: nodo `FQKhT` (archiveHeader) en frame `HpUYE`/`HtUQ8` de rideglory.pen.

#### `GarageArchivedSection` — `garage_archived_section.dart`

```
StatefulWidget — 1 archivo propio (State<GarageArchivedSection> coexiste en mismo archivo)
Props:
  archivedVehicles: List<VehicleModel>
  onRestoreTap: ValueChanged<VehicleModel>
  onGarageListUpdatedLocally: void Function([VehicleModel?])? — pasado como null

Estado interno:
  bool _isExpanded = false

Guard de vacío: if (archivedVehicles.isEmpty) return const SizedBox.shrink();

Estructura cuando tiene items:
  Column:
    ├─ GarageArchivedHeader(count, isExpanded, onTap: toggle)
    └─ if (_isExpanded)
         Column:
           └─ ...archivedVehicles.map((v) =>
                Padding(bottom: 8,
                  child: Opacity(opacity: 0.65,
                    child: GarageOtherVehicleItem(
                      vehicle: v,
                      onTap: () => onRestoreTap(v),
                      onOptionsTap: () => onRestoreTap(v),
                    )
                  )
                )
              )
```

Referencia visual: nodo `EljAr` (archivadosSection) en frame `HpUYE` de rideglory.pen.

---

## Copy

### Claves l10n — modificación

| Clave ARB | Texto actual | Texto nuevo | Justificación |
|-----------|-------------|-------------|---------------|
| `vehicle_unarchiveVehicle` | "Desarchivar" | "Restaurar" | Más claro y consistente con el flujo |

### Claves l10n — nuevas (7 claves)

| Clave ARB | Texto ES | Contexto | Placeholders |
|-----------|----------|---------|-------------|
| `vehicle_archiveVehicleConfirmTitle` | Archivar vehículo | Título del diálogo [F6 — CeaoR] | ninguno |
| `vehicle_archiveVehicleConfirmContent` | «{vehicleName}» pasará a la sección de archivados. Podrás restaurarlo cuando quieras. | Cuerpo del diálogo [F6] | `{vehicleName}` |
| `vehicle_vehicleArchived` | Vehículo archivado | Snackbar éxito archivar [F7 — vf1hj] | ninguno |
| `vehicle_vehicleRestored` | Vehículo restaurado | Snackbar éxito restaurar [F8 — B5pRg] | ninguno |
| `vehicle_archivedSection` | ARCHIVADOS | Label header sección archivados [F2/F3] | ninguno |
| `vehicle_setMainVehicle` | Marcar como principal | Opción menú activos [F4 — eKwEX] | ninguno |
| `vehicle_archiveConfirmButton` | Archivar | CTA primario del diálogo [F6] | ninguno |

### Claves l10n existentes a reusar (sin cambio de texto)

| Clave ARB | Texto | Dónde se usa |
|-----------|-------|-------------|
| `vehicle_archiveVehicle` | Archivar | Opción menú activos [F4 — eKwEX] |
| `vehicle_archivedVehicle` | Vehículo Archivado | Badge en item archivado [F3] |
| `vehicle_editVehicle` | Editar | Opción menú activos [F4] |
| `vehicle_addMaintenance` | Agregar mantenimiento | Opción menú activos [F4] |
| `cancel` | Cancelar | Botón cancelar del diálogo [F6] |

**Decisión:** `vehicle_restoreVehicle` NO se crea. El menú usa `vehicle_unarchiveVehicle` (texto "Restaurar"). 7 claves nuevas, sin duplicación semántica.

---

## Accesibilidad

| Criterio | Requisito | Aplicación |
|---------|----------|-----------|
| Touch targets | Mínimo 44×44px | Header archivados (min-height 44px), items menú (min-height 56px ListTile), botones diálogo (height 52px) |
| Contraste — item archivado | `opacity: 0.65` sobre `$bg-card` → texto `$text-primary` ratio ~3.7:1 (AA Large) | Items en `GarageArchivedSection` |
| Contraste — CTA naranja [F6 — CeaoR] | `$text-inverse` (#0D0D0F) sobre `$accent` (#f98c1f) → ratio ~4.6:1 (WCAG AA) | **NUNCA texto blanco sobre naranja** |
| Contraste — snackbar error [F9 — gnCZx] | `$text-primary` (#FFF) sobre `$error` (#EF4444) → ratio ~4.5:1 (AA) | SnackBar error |
| Semantics — header colapsable | `Semantics(button: true, label: 'Archivados, $count vehículos. Toca para ${isExpanded ? "colapsar" : "expandir"}')` | `GarageArchivedHeader` |
| Semantics — item archivado | `Semantics(button: true, label: '${vehicle.name}, archivado. Toca para ver opciones')` | `GarageOtherVehicleItem` en archivados |
| Icono chevron | Acompaña label textual — estado no depende solo de color/icono | `GarageArchivedHeader` |
| Badge "Archivado" | Texto + color — no depende solo del color | Badge en item archivado |
| Animaciones | `AnimatedRotation` del chevron — si `MediaQuery.disableAnimations` es `true`, usar toggle instantáneo | `GarageArchivedHeader` |

---

## Notas para Frontend

### 1. Filtrado de vehículos en `GarageVehiclesContent`

```dart
final allVehicles = state is Data<List<VehicleModel>> ? state.data : const <VehicleModel>[];
final activeVehicles = allVehicles.where((v) => !v.isArchived).toList(growable: false);
final archivedVehicles = allVehicles.where((v) => v.isArchived).toList(growable: false);
```

### 2. Integración de `GarageArchivedSection` en `GarageVehiclesContent`

Al final de `SliverChildListDelegate`:

```dart
const SizedBox(height: 20),
GarageArchivedSection(
  archivedVehicles: archivedVehicles,
  onRestoreTap: (vehicle) => GarageOptionsBottomSheet.show(
    context,
    vehicle,
    onGarageListUpdatedLocally: null,
  ),
  onGarageListUpdatedLocally: null,
),
```

### 3. Bifurcación del menú contextual en `GarageOptionsBottomSheet`

```
if (vehicle.isArchived):
  solo "Restaurar" → unarchiveVehicle()
else:
  if (!vehicle.isMainVehicle) "Marcar como principal" → setMainVehicle()
  "Editar" → GoRouter.pushNamed(editVehicle)
  "Agregar mantenimiento" → GoRouter.pushNamed(createMaintenance)
  "Archivar" → diálogo confirmación → archiveVehicle()
```

### 4. Tokens de color críticos para el diálogo de archivado

```dart
ConfirmationDialog.show(
  context: parentContext,
  title: parentContext.l10n.vehicle_archiveVehicleConfirmTitle,
  content: parentContext.l10n.vehicle_archiveVehicleConfirmContent(vehicle.name),
  cancelLabel: parentContext.l10n.cancel,
  confirmLabel: parentContext.l10n.vehicle_archiveConfirmButton,
  confirmType: DialogActionType.primary,  // naranja con texto $text-inverse (#0D0D0F)
  isDismissible: true,
);
```

**NUNCA** `DialogActionType.danger` para archivado (naranja, no rojo). El tono es informativo/neutro.
Referencia visual: frame `CeaoR` en rideglory.pen.

### 5. Snackbars

```dart
// Éxito archivar
ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
  content: Text(parentContext.l10n.vehicle_vehicleArchived),
  backgroundColor: AppColors.success,
));

// Éxito restaurar
ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
  content: Text(parentContext.l10n.vehicle_vehicleRestored),
  backgroundColor: AppColors.success,
));

// Error
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text(message),
  backgroundColor: context.colorScheme.error,
));
```

### 6. Íconos a usar (Material / Lucide → Material mapping)

| Acción | Ícono Lucide (Pencil) | Ícono Material (Flutter) | Color |
|--------|----------------------|--------------------------|-------|
| Marcar como principal | `star` | `Icons.star_outline` / `Icons.star` | `AppColors.primary` |
| Editar | `pencil` | `Icons.edit` | `colorScheme.onSurface` |
| Agregar mantenimiento | `wrench` | `Icons.build` | `colorScheme.primary` |
| Archivar | `archive` | `Icons.archive_outlined` | `colorScheme.onSurfaceVariant` |
| Restaurar | `archive-restore` | `Icons.unarchive_outlined` | `AppColors.success` |
| Chevron (header) | `chevron-right` | `Icons.chevron_right` | `$text-tertiary` |
| Error snackbar | `triangle-alert` | `Icons.warning_amber_rounded` | `colorScheme.onError` |

### 7. Guardrails visuales

- **Ítem archivado:** usar `Opacity(opacity: 0.65, child: GarageOtherVehicleItem(...))` — no cambiar el widget internamente.
- **Badge "Archivado":** puede reusar `GarageVehicleStatusBadge` con variante neutral, o `Container` con `#9CA3AF1F` de fondo y `$text-secondary` de texto.
- **Ítem archivado tap:** tanto `onTap` como `onOptionsTap` disparan el menú archivado (no navegar al detalle).
- **Sin `fetchMyVehicles`** en ningún punto del flujo archive/unarchive. El callback `onGarageListUpdatedLocally` pasa como `null`.

### 8. `GarageArchivedHeader` — animación del chevron

```dart
AnimatedRotation(
  turns: isExpanded ? 0.25 : 0.0,  // 0.25 turns = 90°
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  child: const Icon(Icons.chevron_right, ...),
)
```

---

## Artefactos

| Tipo | Ubicación | Estado |
|------|-----------|--------|
| Frames Pencil | `rideglory.pen` (ver tabla de IDs arriba) | Completos — 9 frames creados/actualizados |
| Mockups HTML | — | Eliminados (no son la referencia; rideglory.pen es la única fuente de verdad) |

---

## Change log

- 2026-06-16T23:02:25Z: Corrección de auditor Opus. Diseñado en Pencil (batch_design): 7 frames nuevos (m0Ffw, HtUQ8, CeaoR, vf1hj, B5pRg, gnCZx) + 2 frames actualizados (EM0D6, HpUYE). Eliminada opción "Eliminar permanentemente" de EM0D6 (Fase 4). Eliminados artefactos HTML/CSS prohibidos. Reconciliado alcance: SqWs1 y x7j5iJ son Fase 4, no entregables de Fase 3. Handoff re-anclado a node IDs reales de rideglory.pen.
- 2026-06-16T22:56:17Z: Versión inicial (Pencil MCP no disponible, mockups HTML). Corregida en esta iteración.
