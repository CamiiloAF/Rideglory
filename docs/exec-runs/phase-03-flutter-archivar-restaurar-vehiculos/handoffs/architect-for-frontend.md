> Slim handoff — read this before handoffs/architect.md

# Frontend handoff — Phase 03: Flutter — Archivar y restaurar vehículos

**Date:** 2026-06-16T22:42:02Z

---

## Feature path

`lib/features/vehicles/presentation/`

---

## Orden de implementación

1. l10n → analytics → VehicleActionCubit/State → VehicleCubit → widgets nuevos → modificaciones → tests → verify

---

## 1. l10n (`lib/l10n/app_es.arb`)

**Modificación:**
- `vehicle_unarchiveVehicle`: cambiar "Desarchivar" → `"Restaurar"`

**Claves nuevas a añadir (7 total):**

```json
"vehicle_archiveVehicleConfirmTitle": "Archivar vehículo",
"vehicle_archiveVehicleConfirmContent": "«{vehicleName}» pasará a la sección de archivados. Podrás restaurarlo cuando quieras.",
"@vehicle_archiveVehicleConfirmContent": {
  "placeholders": { "vehicleName": { "type": "String" } }
},
"vehicle_vehicleArchived": "Vehículo archivado",
"vehicle_vehicleRestored": "Vehículo restaurado",
"vehicle_archivedSection": "ARCHIVADOS",
"vehicle_setMainVehicle": "Marcar como principal",
"vehicle_archiveConfirmButton": "Archivar"
```

> NO añadir `vehicle_restoreVehicle` — el menú de archivados reutiliza `vehicle_unarchiveVehicle` (ya modificado a "Restaurar") para la opción "Restaurar". Crear una clave separada con el mismo texto sería duplicación redundante.

Después: `flutter gen-l10n`.

---

## 2. Analytics (`lib/core/services/analytics/analytics_events.dart`)

Añadir en la sección "Vehículos":

```dart
/// Max 40 chars: 'vehicle_archived'.length == 16. ✓
static const String vehicleArchived = 'vehicle_archived';

/// Max 40 chars: 'vehicle_unarchived'.length == 18. ✓
static const String vehicleUnarchived = 'vehicle_unarchived';
```

---

## 3. VehicleActionCubit/State

**Archivos a renombrar:**
- `delete/cubit/vehicle_delete_cubit.dart` → `vehicle_action_cubit.dart`
- `delete/cubit/vehicle_delete_state.dart` → `vehicle_action_state.dart`
- `delete/cubit/vehicle_delete_cubit.freezed.dart` → regenerado automáticamente

**Clase `VehicleActionState` — freezed ampliado:**

```dart
@freezed
class VehicleActionState with _$VehicleActionState {
  const factory VehicleActionState.initial() = _Initial;
  const factory VehicleActionState.loading() = _Loading;
  const factory VehicleActionState.success({required String deletedId}) = _Success; // CONSERVAR IGUAL
  const factory VehicleActionState.archiveSuccess({required String archivedId}) = _ArchiveSuccess;
  const factory VehicleActionState.unarchiveSuccess({required String unarchivedId}) = _UnarchiveSuccess;
  const factory VehicleActionState.error({required String message}) = _Error;
  const factory VehicleActionState.errorLastVehicle({required String message}) = _ErrorLastVehicle;
}
```

**Clase `VehicleActionCubit` — nuevas dependencias e inyecciones:**

```dart
@injectable
class VehicleActionCubit extends Cubit<VehicleActionState> {
  VehicleActionCubit(
    this._deleteVehicleUseCase,
    this._archiveVehicleUseCase,   // NUEVO
    this._unarchiveVehicleUseCase, // NUEVO
    this._vehicleCubit,
    this._analytics,
  ) : super(const VehicleActionState.initial());

  // Método deleteVehicle: conservar sin cambios
  // Nuevos métodos:
  Future<void> archiveVehicle(VehicleModel vehicle) async { ... }
  Future<void> unarchiveVehicle(VehicleModel vehicle) async { ... }
}
```

En `archiveVehicle`: llamar `_archiveVehicleUseCase(vehicle)`, fold éxito → `_vehicleCubit.archiveLocally(vehicle.id!)`, log `AnalyticsEvents.vehicleArchived`, emit `VehicleActionState.archiveSuccess(archivedId: vehicle.id!)`.

En `unarchiveVehicle`: llamar `_unarchiveVehicleUseCase(vehicle)`, fold éxito → `_vehicleCubit.unarchiveLocally(vehicle.id!)`, log `AnalyticsEvents.vehicleUnarchived`, emit `VehicleActionState.unarchiveSuccess(unarchivedId: vehicle.id!)`.

Después de editar: `dart run build_runner build --delete-conflicting-outputs --force-jit`.

---

## 4. VehicleCubit (`lib/features/vehicles/presentation/cubit/vehicle_cubit.dart`)

Añadir métodos:

```dart
void archiveLocally(String id) {
  _vehicles = _vehicles.map((v) {
    if (v.id != id) return v;
    return v.copyWith(isArchived: true, isMainVehicle: false);
  }).toList();
  // Si el archivado era main, promover el siguiente activo
  final wasMain = _vehicles.any((v) => v.id == id && v.isArchived && /* previo */ true);
  // Implementar con un flag pre-mutación
  _emitLoadedOrEmpty();
}

void unarchiveLocally(String id) {
  _vehicles = _vehicles.map((v) {
    if (v.id != id) return v;
    return v.copyWith(isArchived: false);
  }).toList();
  _emitLoadedOrEmpty();
}
```

**Lógica `_promoteNewMain`** — criterio exacto del PRD:

```
activos no archivados, ordenados por createdAt desc (nulls al final),
tie-break id lexicográfico asc.
Primero de esa lista → isMainVehicle = true.
```

Implementar `archiveLocally` capturando si el vehículo era main ANTES de mutarlo, y si lo era, llamar `_promoteNewMain` sobre los activos resultantes.

---

## 5. GarageArchivedHeader (`garage/widgets/garage_archived_header.dart`)

Nuevo `StatelessWidget` — archivo propio. Props:

```dart
final int count;
final bool isExpanded;
final VoidCallback onTap;
```

Visual: mismo patrón que `GarageOtherVehiclesSectionHeader` — barra vertical naranja o gris, label `context.l10n.vehicle_archivedSection`, badge con `count`, chevron `isExpanded ? Icons.expand_less : Icons.expand_more`.

---

## 6. GarageArchivedSection (`garage/widgets/garage_archived_section.dart`)

`StatefulWidget` — `State<GarageArchivedSection>` puede coexistir en el mismo archivo. Props:

```dart
final List<VehicleModel> archivedVehicles;
final ValueChanged<VehicleModel> onRestoreTap;
final void Function([VehicleModel?])? onGarageListUpdatedLocally; // siempre null desde GarageVehiclesContent
```

Si `archivedVehicles.isEmpty` → retornar `SizedBox.shrink()`.

Estado interno: `bool _isExpanded = false`.

Estructura cuando expandido: `GarageArchivedHeader` (toggle) + lista de `GarageOtherVehicleItem` reutilizados (onTap: `onRestoreTap(vehicle)`, onOptionsTap: `GarageOptionsBottomSheet.show` con vehicle archivado).

---

## 7. GarageOptionsBottomSheet — bifurcación

Cambios en `show()` y `build()`:

- Reemplazar `VehicleDeleteCubit` → `VehicleActionCubit` en el type.
- El listener ahora escucha `VehicleActionState` y maneja `archiveSuccess`, `unarchiveSuccess` y `success` (existente).
- **Si `vehicle.isArchived == true`** (archivado): mostrar SOLO "Restaurar" — llama `actionCubit.unarchiveVehicle(vehicle)`.
- **Si `vehicle.isArchived == false`** (activo): mostrar:
  1. "Marcar como principal" — solo si `!vehicle.isMainVehicle` — llama `context.read<VehicleCubit>().setMainVehicle(vehicle.id!)`.
  2. "Editar" — navega `AppRoutes.editVehicle`.
  3. "Agregar mantenimiento" — navega `AppRoutes.createMaintenance`.
  4. "Archivar" — muestra `ConfirmationDialog` con `confirmType: DialogActionType.primary`, título `context.l10n.vehicle_archiveVehicleConfirmTitle`, contenido `context.l10n.vehicle_archiveVehicleConfirmContent(vehicle.name)`, CTA `context.l10n.vehicle_archiveConfirmButton`. Al confirmar: `actionCubit.archiveVehicle(vehicle)`.
  - El `ListTile` de "Eliminar" **no aparece** en activos.

---

## 8. GarageVehiclesContent — integración

Añadir al final del `SliverChildListDelegate`:

```dart
GarageArchivedSection(
  archivedVehicles: allVehicles.where((v) => v.isArchived).toList(),
  onRestoreTap: (vehicle) => GarageOptionsBottomSheet.show(
    context,
    vehicle,
    onGarageListUpdatedLocally: null, // no re-fetch
    onMaintenanceCreated: onMaintenanceCreated,
    onMaintenanceRefreshRequested: onMaintenanceRefreshRequested,
  ),
),
```

`allVehicles` = `state.data` sin filtro `!v.isArchived`; los activos se siguen filtrando para el resto del contenido.

---

## 9. VehicleFormPage + VehicleFormView — actualizar referencias

**`vehicle_form_page.dart`** (línea 30) — cambio de compilación bloqueante:

```dart
// ANTES (rompe compilación tras renombrado):
create: (context) => getIt<VehicleDeleteCubit>()..reset(),

// DESPUÉS:
create: (context) => getIt<VehicleActionCubit>()..reset(),
```

Actualizar también el import en la cabecera del archivo:
- `import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart';`
  → `import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';`

**`vehicle_form_view.dart`** — 3 referencias a actualizar:
- Import `vehicle_delete_cubit.dart` → `vehicle_action_cubit.dart`.
- `context.read<VehicleDeleteCubit>()` en `_confirmDelete` → `context.read<VehicleActionCubit>()`.
- `BlocListener<VehicleDeleteCubit, VehicleDeleteState>` en `build` → `BlocListener<VehicleActionCubit, VehicleActionState>`.

El listener `_deleteListener` sigue usando `.when(success: ...)` — la variante `success` no cambia.

---

## 10. Tests mínimos

**`test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart`** (5 tests):
1. `archivedVehicles.isEmpty` → no renderiza la sección (SizedBox.shrink).
2. Con archivados: header muestra contador correcto.
3. Con archivados: al tap en header se expande y lista los vehículos.
4. Tap en "Archivar" y confirmar → dispara `archiveVehicle` en cubit mock.
5. Tap en "Archivar" y cancelar → no dispara `archiveVehicle`.

**`test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart`** (extensión):
- `archiveLocally` marca vehículo como archivado en el estado.
- `archiveLocally` sobre el main → promueve el siguiente activo.
- `unarchiveLocally` restaura `isArchived=false` sin cambiar main.
- `_promoteNewMain` con nulls en `createdAt` → tie-break por id.

---

## Guardrails

- `VehicleActionCubit` es `@injectable` (factory), nunca `@singleton`.
- `onGarageListUpdatedLocally` en `GarageArchivedSection` siempre se pasa como `null` desde `GarageVehiclesContent`.
- Texto oscuro sobre CTA primario (naranja): usar `colorScheme.onPrimary`.
- Un widget por archivo: `GarageArchivedHeader` y `GarageArchivedSection` en archivos separados.
- Cero strings hardcodeados: todo por `context.l10n`.

> Full detail: handoffs/architect.md
