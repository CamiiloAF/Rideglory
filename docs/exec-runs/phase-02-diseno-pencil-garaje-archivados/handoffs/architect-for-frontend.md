> Slim handoff — lee esto antes de handoffs/architect.md

# Architect → Frontend — Phase 02

**Esta fase NO produce código Flutter.** El agente Frontend no ejecuta en esta fase.

## Stand-down

- Cero archivos `.dart` se tocan en esta fase.
- Cero cambios en `lib/l10n/app_es.arb`.
- Cero cambios en rutas, cubits, use cases, DTOs, o DI.

## Lo que Frontend necesita saber para Fase 3 (próxima fase)

Una vez que el PO apruebe los diseños de esta fase, Fase 3 (Flutter: archivar y restaurar vehículos) comenzará. Anticipación técnica:

### Componentes a reusar (no crear nuevos)
- `GarageOtherVehicleItem` → variante archivado: opacidad 0.6 + chip estado neutro
- `ConfirmationDialog.show()` con `DialogActionType.danger` para diálogo destructivo
- `GarageOtherVehiclesSectionHeader` → referencia de estilo para header colapsable "Archivados (N)"
- `GarageOptionsBottomSheet` → bifurcar en activo vs. archivado (mismo widget, props distintas)

### L10n keys anticipadas para Fase 3
- `vehicle_archiveConfirmTitle` — "Archivar vehículo"
- `vehicle_archiveConfirmMessage` — mensaje informativo (historial conservado)
- `vehicle_deleteVehiclePermanently` — "Eliminar permanentemente"
- `vehicle_deleteVehiclePermanentlyConfirmContent` — con placeholder `{vehicleName}`
- `vehicle_restoreVehicle` — "Restaurar"
- `garage_archivedVehiclesSection` — "Archivados"
- Revisar si `vehicle_unarchiveVehicle` (ya existente, línea 335 app_es.arb) se renombra a `vehicle_restoreVehicle` para consistencia con la UX aprobada

### Modelo VehicleModel
- `isArchived` ya existe en `VehicleModel` (línea 18, `vehicle_model.dart`)
- `GarageVehiclesContent` ya filtra `!v.isArchived` para vehículos activos (línea 44)
- Fase 3 debe añadir la lista de archivados como segundo stream del mismo `VehicleCubit`

### Regla de color crítica
- CTA "Archivar" → `AppModalVariant.info` → `primaryLabelColor = AppColors.darkBgPrimary`. Nunca texto blanco sobre naranja.
- CTA "Eliminar permanentemente" → `AppModalVariant.destructive` → `primaryLabelColor = AppColors.textOnDarkPrimary` (blanco es correcto aquí porque el relleno es `AppColors.error`, no naranja).

> Full detail: handoffs/architect.md
