# Architect handoff — Phase 03: Flutter — Archivar y restaurar vehículos

**Date:** 2026-06-16T22:42:02Z
**Status:** done

---

## Decisiones

### Flags de decisión

| Flag | Valor | Justificación |
|------|-------|---------------|
| `backendChanges` | false | Sin nuevos endpoints. Archive/Unarchive usan `PATCH /api/vehicles/:id` existente a través de `UpdateVehicleUseCase`. Use cases `ArchiveVehicleUseCase` y `UnarchiveVehicleUseCase` ya existen en `domain/usecases/`. |
| `dbChanges` | false | `isArchived` ya existe en `VehicleModel` y en el DTO/schema de backend (Fase 1 completada). |
| `frontendChanges` | true | Cubit de acción renombrado, nuevos métodos en `VehicleCubit`, bifurcación del bottom sheet, nuevos widgets de sección archivados, l10n additions, analytics. |
| `uiChanges` | true | `GarageArchivedSection` + `GarageArchivedHeader` son widgets nuevos; `GarageOptionsBottomSheet` bifurca su árbol de opciones. |
| `needsDesign` | false | Diseño Pencil aprobado en Fase 2 (prerrequisito satisfecho). |

---

## Feature architecture decisions

| Área | Dominio | Datos | Presentación |
|------|---------|-------|--------------|
| Cubit de acción scoped | Sin cambios (usa use cases existentes) | Sin cambios | Renombrar `VehicleDeleteCubit` → `VehicleActionCubit`; renombrar archivo `vehicle_delete_cubit.dart` → `vehicle_action_cubit.dart`; añadir variantes `archiveSuccess` / `unarchiveSuccess` al estado freezed; añadir métodos `archiveVehicle` / `unarchiveVehicle`; conservar variante `success({required String deletedId})` y método `deleteVehicle` sin cambios. |
| Cubit global de vehículos | Sin cambios | Sin cambios | Añadir `archiveLocally(String id)` y `unarchiveLocally(String id)` con promoción de principal via `_promoteNewMain`. |
| Garaje — menú contextual | Sin cambios | Sin cambios | Bifurcar `GarageOptionsBottomSheet` por `vehicle.isArchived`: activos → "Marcar como principal" (condicional si !isMainVehicle), "Editar", "Agregar mantenimiento", "Archivar" (sin "Eliminar"); archivados → solo "Restaurar". El listener del cubit escucha `archiveSuccess` y `unarchiveSuccess` además de `success`. |
| Sección archivados | Sin cambios | Sin cambios | Nuevos widgets `GarageArchivedHeader` (archivo propio) y `GarageArchivedSection` (archivo propio, StatefulWidget expansible). Integrados al final de `GarageVehiclesContent`. |
| l10n | Sin cambios | Sin cambios | Actualizar `vehicle_unarchiveVehicle` de "Desarchivar" → "Restaurar"; añadir 8 claves nuevas. |
| Analytics | Sin cambios | Sin cambios | Añadir `vehicleArchived` y `vehicleUnarchived` a `AnalyticsEvents`. |

---

## Change map

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` | modify (→ vehicle_action_cubit.dart) | Renombrar clase a `VehicleActionCubit`, añadir métodos `archiveVehicle`/`unarchiveVehicle`, inyectar `ArchiveVehicleUseCase`/`UnarchiveVehicleUseCase`, conservar `deleteVehicle`. | med |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` | modify (→ vehicle_action_state.dart) | Renombrar a `VehicleActionState`, añadir variantes `archiveSuccess({required String archivedId})` y `unarchiveSuccess({required String unarchivedId})`; conservar `success({required String deletedId})`. | med |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.freezed.dart` | modify (regenerado) | Regenerado por build_runner tras cambiar el estado freezed. | low |
| `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` | modify | Añadir `archiveLocally(String id)`, `unarchiveLocally(String id)`, helper privado `_promoteNewMain(List<VehicleModel> actives)`. | med |
| `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | modify | Bifurcar árbol de opciones por `vehicle.isArchived`; referenciar `VehicleActionCubit` en lugar de `VehicleDeleteCubit`; escuchar `archiveSuccess`/`unarchiveSuccess`; añadir diálogo de confirmación de archivado con `DialogActionType.primary`. | med |
| `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` | modify | Integrar `GarageArchivedSection` al final de la lista sliver; pasar callbacks `onArchive`/`onUnarchive`. | low |
| `lib/features/vehicles/presentation/garage/widgets/garage_archived_header.dart` | create | Nuevo widget `GarageArchivedHeader` (archivo propio): muestra label "ARCHIVADOS" + contador + chevron de expansión. | low |
| `lib/features/vehicles/presentation/garage/widgets/garage_archived_section.dart` | create | Nuevo `GarageArchivedSection` StatefulWidget (archivo propio, `State` coexiste): lista expansible de vehículos archivados; `isEmpty` → `SizedBox.shrink()`. | low |
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | modify | Línea 30: `getIt<VehicleDeleteCubit>()..reset()` → `getIt<VehicleActionCubit>()..reset()` + actualizar import. Sin esto el renombrado no compila. | med |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` | modify | Actualizar referencias de `VehicleDeleteCubit`/`VehicleDeleteState` → `VehicleActionCubit`/`VehicleActionState`; el listener `_deleteListener` sigue escuchando solo la variante `success`. | low |
| `lib/core/services/analytics/analytics_events.dart` | modify | Añadir constantes `vehicleArchived` y `vehicleUnarchived` en la sección Vehículos. | low |
| `lib/l10n/app_es.arb` | modify | Actualizar `vehicle_unarchiveVehicle` → "Restaurar"; añadir 7 claves nuevas (ver §Contratos l10n). | low |
| `lib/l10n/app_localizations.dart` | modify (regenerado) | Regenerado por `flutter gen-l10n`. | low |
| `lib/l10n/app_localizations_es.dart` | modify (regenerado) | Regenerado por `flutter gen-l10n`. | low |
| `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | create | Widget tests (5): estado vacío, colapsado con contador, expandido con lista, confirmar archivado dispara `archiveVehicle`, cancelar no dispara. | low |
| `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` | modify | Añadir tests unitarios para `archiveLocally`/`unarchiveLocally`/`_promoteNewMain`. | low |

---

## Contratos

### No hay cambios en rideglory-api

`ArchiveVehicleUseCase` y `UnarchiveVehicleUseCase` ya existen y usan `VehicleRepository.updateVehicle(vehicle)` que llama `PATCH /api/vehicles/:id` con el cuerpo del DTO. Sin endpoints nuevos.

### Contratos l10n (7 claves nuevas + 1 modificación)

| Clave ARB | Texto ES | Notas |
|-----------|----------|-------|
| `vehicle_unarchiveVehicle` | "Restaurar" | **Modificación** — era "Desarchivar". Esta clave se reutiliza en el menú de archivados como label de la opción "Restaurar". No crear `vehicle_restoreVehicle`. |
| `vehicle_archiveVehicleConfirmTitle` | "Archivar vehículo" | Título diálogo confirmación |
| `vehicle_archiveVehicleConfirmContent` | "«{vehicleName}» pasará a la sección de archivados. Podrás restaurarlo cuando quieras." | Placeholder `vehicleName` |
| `vehicle_vehicleArchived` | "Vehículo archivado" | Snackbar éxito de archivo |
| `vehicle_vehicleRestored` | "Vehículo restaurado" | Snackbar éxito de restauración |
| `vehicle_archivedSection` | "ARCHIVADOS" | Header de sección archivados |
| `vehicle_setMainVehicle` | "Marcar como principal" | Opción en menú contextual de activos |
| `vehicle_archiveConfirmButton` | "Archivar" | CTA primario del diálogo de confirmación |

> Decisión de ambigüedad l10n (nota §77 del handoff anterior): `vehicle_restoreVehicle` queda eliminada. El menú de archivados usa `context.l10n.vehicle_unarchiveVehicle` (texto "Restaurar") en lugar de una clave separada. Esto reduce de 8 a 7 claves nuevas, evita duplicación y mantiene el contrato ARB sin claves semánticamente redundantes. `vehicle_archiveVehicle` = "Archivar" ya existe (línea 334 del ARB) y se reutiliza como opción del menú de activos sin cambios.

### Contrato de `VehicleActionCubit` (resumen)

```dart
// Constructor — inyección de 5 dependencias (las 3 existentes + 2 nuevas use cases)
VehicleActionCubit(
  DeleteVehicleUseCase deleteVehicleUseCase,
  ArchiveVehicleUseCase archiveVehicleUseCase,
  UnarchiveVehicleUseCase unarchiveVehicleUseCase,
  VehicleCubit vehicleCubit,
  AnalyticsService analytics,
)

// Nuevos métodos
Future<void> archiveVehicle(VehicleModel vehicle)
Future<void> unarchiveVehicle(VehicleModel vehicle)
// Método conservado sin cambios
Future<void> deleteVehicle(String vehicleId, {required List<VehicleModel> availableVehicles})
void reset()
```

### Contrato de `VehicleActionState` (freezed)

```dart
@freezed
class VehicleActionState with _$VehicleActionState {
  const factory VehicleActionState.initial() = _Initial;
  const factory VehicleActionState.loading() = _Loading;
  // Conservado exactamente igual — consumers dependen de esta firma
  const factory VehicleActionState.success({required String deletedId}) = _Success;
  // Nuevas variantes
  const factory VehicleActionState.archiveSuccess({required String archivedId}) = _ArchiveSuccess;
  const factory VehicleActionState.unarchiveSuccess({required String unarchivedId}) = _UnarchiveSuccess;
  const factory VehicleActionState.error({required String message}) = _Error;
  const factory VehicleActionState.errorLastVehicle({required String message}) = _ErrorLastVehicle;
}
```

### Contrato de `VehicleCubit` — métodos nuevos

```dart
// Mueve el vehículo [id] a isArchived=true localmente.
// Si el vehículo era isMainVehicle=true, invoca _promoteNewMain con la
// lista de activos resultante (activos no archivados).
void archiveLocally(String id)

// Restaura el vehículo [id] a isArchived=false localmente.
// No modifica isMainVehicle (el vehículo restaurado no se promueve a main).
void unarchiveLocally(String id)

// Helper privado: promueve el primer vehículo activo no archivado a main.
// Criterio: ordenados por createdAt desc (nulls al final), tie-break id asc lexicográfico.
// Se invoca solo cuando el archivado era isMainVehicle=true y quedan activos.
VehicleModel? _promoteNewMain(List<VehicleModel> actives)
```

### Contrato de `GarageArchivedSection`

```dart
class GarageArchivedSection extends StatefulWidget {
  const GarageArchivedSection({
    super.key,
    required this.archivedVehicles,
    required this.onRestoreTap,   // callback → lanza GarageOptionsBottomSheet
    this.onGarageListUpdatedLocally, // pasado como null (no re-fetch)
  });

  final List<VehicleModel> archivedVehicles;
  final ValueChanged<VehicleModel> onRestoreTap;
  final void Function([VehicleModel?])? onGarageListUpdatedLocally;
}
```

Si `archivedVehicles.isEmpty`, retorna `SizedBox.shrink()`.

### Contrato de `GarageArchivedHeader`

```dart
class GarageArchivedHeader extends StatelessWidget {
  const GarageArchivedHeader({
    super.key,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  final int count;
  final bool isExpanded;
  final VoidCallback onTap;
}
```

---

## Datos / migraciones

No aplica. `isArchived` está en el esquema desde Fase 1. Sin nuevas columnas, sin migraciones.

---

## Env

Sin variables de entorno nuevas. No se genera `analysis/ENV_DELTA.md`.

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| **Romper compilación por renombrado incompleto** — `vehicle_form_page.dart` (línea 30) y `vehicle_form_view.dart` hacen `getIt<VehicleDeleteCubit>()..reset()` / `context.read<VehicleDeleteCubit>()`; `garage_options_bottom_sheet.dart` también. Los 4 archivos deben actualizarse en el mismo PR. Búsqueda global: `grep -rl "VehicleDelete" lib/` debe retornar exactamente `{vehicle_delete_cubit.dart, vehicle_delete_state.dart, vehicle_delete_cubit.freezed.dart, injection.config.dart, vehicle_form_page.dart, vehicle_form_view.dart, garage_options_bottom_sheet.dart}` — tras la migración debe retornar 0. | Todas las referencias actualizadas en el Change map. |
| **Variante `success` rota** si el freezed regenerado cambia la posición de parámetros. | La variante `success({required String deletedId})` debe preservarse idéntica en firma y nombre. No renombrar, no reordenar. |
| **`_promoteNewMain` lógica incorrecta** — si `createdAt` es nulo en todos los activos, el tie-break por `id` debe activarse. | Test unitario obligatorio cubre este caso (lista sin `createdAt`). |
| **Re-fetch involuntario** — `onGarageListUpdatedLocally` en `GarageArchivedSection` se pasa como `null`; asegurarse que el callback no sea invocado de otro lado. | `GarageOptionsBottomSheet.show` para archivados no pasa `onGarageListUpdatedLocally`. |
| **`VehicleActionCubit` singleton accidental** — GetIt lo registra como `@injectable` (transitorio). Si algo lo registra como `@singleton`, habrá conflicto de estado entre garaje y formulario. | Verificar en `injection.config.dart` después de build_runner que sea `factoryParam` o `factory`, no `singleton`. |
| **build_runner en entorno fresco** falla por hooks de `objective_c`. | Usar `--force-jit` según MEMORY.md. |

---

## Orden de implementación

1. **l10n** — editar `app_es.arb` (actualizar `vehicle_unarchiveVehicle`, añadir 8 claves) → ejecutar `flutter gen-l10n`.
2. **Analytics** — añadir `vehicleArchived`/`vehicleUnarchived` a `analytics_events.dart`.
3. **VehicleActionCubit/State** — renombrar archivos y clases; ampliar estado freezed; añadir `archiveVehicle`/`unarchiveVehicle`; ejecutar `build_runner --force-jit`.
4. **VehicleCubit** — añadir `archiveLocally`, `unarchiveLocally`, `_promoteNewMain`.
5. **GarageArchivedHeader** — crear widget (archivo propio).
6. **GarageArchivedSection** — crear widget StatefulWidget (archivo propio).
7. **GarageOptionsBottomSheet** — bifurcar por `isArchived`; cablear diálogo de confirmación.
8. **GarageVehiclesContent** — integrar `GarageArchivedSection`.
9. **VehicleFormPage + VehicleFormView** — actualizar referencias a `VehicleActionCubit`: `vehicle_form_page.dart` línea 30 (`getIt<VehicleDeleteCubit>()` → `getIt<VehicleActionCubit>()` + import) y `vehicle_form_view.dart` (import + `context.read<VehicleDeleteCubit>()` × 2 + `BlocListener<VehicleDeleteCubit, VehicleDeleteState>`).
10. **Tests** — `garage_archived_section_test.dart` (5 widget tests) + extensión de `vehicle_cubit_test.dart` (archiveLocally / unarchiveLocally / _promoteNewMain).
11. **Verificación final** — `dart analyze` + `flutter test`.

---

## Superficie de regresión

- `GarageVehiclesContent` y todo el árbol de garaje (cambio en el widget tree + callbacks).
- `GarageOptionsBottomSheet` (bifurcación condicional — todos los vehículos activos se ven afectados).
- `VehicleFormView` (referencias renombradas a `VehicleActionCubit`).
- `VehicleCubit.deleteVehicleLocally` + cualquier test que lo ejercite (sin cambios funcionales, pero el cubit cambia en contexto).
- Tests existentes de `vehicle_cubit_test.dart` — deben seguir en verde.
- DI: `injection.config.dart` regenerado — verificar que `VehicleActionCubit` no sea singleton.

---

## Fuera de alcance

- Eliminación permanente de vehículo (Fase 4).
- Renombrado `VehicleRepository.deleteVehicle` → `permanentlyDeleteVehicle` (Fase 4).
- Modo read-only del detalle de vehículo archivado (badge "Archivado", ocultar FAB, etc.).
- Fix `HomeLoaded.mainVehicle` stale (Fase 5).
- Nuevos endpoints HTTP.
- Cambios en rideglory-api.
