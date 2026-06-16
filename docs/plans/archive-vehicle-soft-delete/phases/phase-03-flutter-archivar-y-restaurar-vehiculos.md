# Fase 3 — Flutter: archivar y restaurar vehículos

_Generated: 2026-06-16T16:35:56Z_
_Revisión: Correcciones Auditor Opus aplicadas (2026-06-16)_

---

## Objetivo

El usuario puede mover un vehículo al archivo desde el garaje y restaurarlo desde la sección de archivados, sin re-fetch HTTP, conservando la coherencia local del vehículo principal.

---

## Alcance (entra / no entra)

**Entra:**
- Ampliar `VehicleDeleteCubit` → renombrarlo `VehicleActionCubit` con estado freezed unificado que incluye ramas para `archive` y `unarchive` (la rama `permanentDelete` se añade en Fase 4).
- Decisión sobre la variante nombrada `success` en el estado freezed (ver Paso 2b).
- Métodos `archiveVehicle` y `unarchiveVehicle` en `VehicleActionCubit`, con invocación real de use cases via `Either`.
- Métodos `archiveLocally(String id)` y `unarchiveLocally(String id)` en `VehicleCubit` con criterio de promoción de main local.
- Wiring de callbacks `onArchive`/`onUnarchive` desde `GarageVehiclesContent`/`GarageOptionsBottomSheet` hacia `VehicleCard` (los callbacks ya existen en el card; el cambio es pasarlos desde el parent).
- Widget nuevo `GarageArchivedSection` (sección colapsable "Archivados (N)") en archivo propio.
- Widget nuevo `GarageArchivedHeader` (header colapsable con contador) en archivo propio.
- Bifurcación de `GarageOptionsBottomSheet` por `vehicle.isArchived`: activos muestran "Archivar"; archivados muestran "Restaurar". El `ListTile` de "Eliminar" actual (líneas 162-189) se elimina del `build()` de la rama de vehículo activo y queda reemplazado por "Archivar".
- Diálogo de confirmación de archivado (tono informativo, CTA en primario con texto oscuro).
- Actualizar `vehicle_unarchiveVehicle` en `app_es.arb` de "Desarchivar" a "Restaurar".
- Añadir 8 claves l10n faltantes (listadas abajo).
- Widget tests para `GarageArchivedSection` y para el diálogo de confirmación.
- `dart analyze` y `flutter test` en verde.

**No entra:**
- Eliminación permanente (Fase 4).
- Nuevo endpoint HTTP (usa `PATCH /api/vehicles/:id` existente vía `ArchiveVehicleUseCase`/`UnarchiveVehicleUseCase`).
- Cambios en el backend (ninguno en esta fase).
- Diseño Pencil (Fase 2, prerequisito bloqueante).
- Fix de `HomeLoaded.mainVehicle` stale (Fase 5, independiente).
- Renombrado de `VehicleRepository.deleteVehicle` → `permanentlyDeleteVehicle` (Fase 4).

---

## Que se debe hacer (pasos concretos y ordenados)

### Pre-flight (antes de tocar código)

1. Verificar que la Fase 2 (diseño Pencil) tiene aprobación explícita del PO.
2. Ejecutar `grep -rn 'vehicle_unarchiveVehicle' lib/` para mapear todos los usos de la clave antes de cambiar su valor. Los consumidores actuales son `vehicle_card.dart:224`. No hay otros.
3. Ejecutar `grep -rn 'VehicleDeleteCubit\|VehicleDeleteState\|vehicle_delete_cubit\|vehicle_delete_state' lib/` para mapear todos los puntos de consumo antes de renombrar. Consumidores conocidos: `garage_options_bottom_sheet.dart`, `vehicle_form_view.dart`, y cualquier archivo que los importe.

---

### Paso 1 — l10n: actualizar y añadir claves

Editar `lib/l10n/app_es.arb`:

**Actualizar valor existente** (decisión de diseño aprobada en Fase 2):
```
"vehicle_unarchiveVehicle": "Restaurar"
```

**Añadir claves nuevas** (insertar cerca de las claves de archivado existentes):
```json
"vehicle_archivedSection": "Archivados ({count})",
"@vehicle_archivedSection": {
  "placeholders": { "count": { "type": "int" } }
},
"vehicle_archiveConfirmTitle": "Archivar vehículo",
"vehicle_archiveConfirmMessage": "El vehículo se ocultará de tu garaje activo. Tu historial de mantenimientos e inscripciones se conserva.",
"vehicle_archiveConfirmAction": "Archivar",
"vehicle_archiveSuccess": "Vehículo archivado",
"vehicle_archiveError": "No se pudo archivar el vehículo",
"vehicle_unarchiveSuccess": "Vehículo restaurado",
"vehicle_unarchiveError": "No se pudo restaurar el vehículo",
"vehicle_setMainVehicle": "Marcar como principal",
"vehicle_setMainVehicleSuccess": "Vehículo principal actualizado"
```

Ejecutar `flutter gen-l10n` para regenerar los archivos de localización.

---

### Paso 2a — Estado freezed unificado: `VehicleActionState`

Renombrar los archivos del cubit scoped:
- `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` → `vehicle_action_state.dart`
- `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` → `vehicle_action_cubit.dart`
- `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.freezed.dart` → `vehicle_action_cubit.freezed.dart` (se regenera)

**Decisión sobre la variante `success`:** Para evitar que el `build()` de `vehicle_form_view.dart:_deleteListener` y el `listener` de `garage_options_bottom_sheet.dart` dejen de compilar, se **conserva la variante nombrada `success`** con la misma firma (`{required String deletedId}`) para el flujo de delete que ya existe. Se añaden variantes nuevas `archiveSuccess` y `unarchiveSuccess`. Esto evita romper los 2 consumidores actuales sin tener que renombrar nada en ellos.

Nuevo contenido de `vehicle_action_state.dart`:
```dart
part of 'vehicle_action_cubit.dart';

@freezed
class VehicleActionState with _$VehicleActionState {
  const factory VehicleActionState.initial() = _Initial;
  const factory VehicleActionState.loading() = _Loading;
  // Rama existente para delete (conservada sin renombrar para no romper consumidores)
  const factory VehicleActionState.success({required String deletedId}) = _Success;
  const factory VehicleActionState.errorLastVehicle({required String message}) =
      _ErrorLastVehicle;
  // Ramas nuevas para archive/unarchive
  const factory VehicleActionState.archiveSuccess({required String archivedId}) =
      _ArchiveSuccess;
  const factory VehicleActionState.unarchiveSuccess({required String unarchivedId}) =
      _UnarchiveSuccess;
  const factory VehicleActionState.error({required String message}) = _Error;
}
```

Ejecutar `dart run build_runner build --delete-conflicting-outputs` para regenerar el `.freezed.dart`.

---

### Paso 2b — `VehicleActionCubit`: añadir métodos `archiveVehicle` y `unarchiveVehicle`

Actualizar `vehicle_action_cubit.dart` (ex `vehicle_delete_cubit.dart`):

1. Renombrar la clase `VehicleDeleteCubit` → `VehicleActionCubit` y el estado `VehicleDeleteState` → `VehicleActionState`.
2. Añadir `ArchiveVehicleUseCase` y `UnarchiveVehicleUseCase` como dependencias inyectadas en el constructor.
3. Añadir los métodos:

```dart
Future<void> archiveVehicle(VehicleModel vehicle) async {
  emit(const VehicleActionState.loading());
  final result = await _archiveVehicleUseCase(vehicle);
  result.fold(
    (error) => emit(VehicleActionState.error(message: error.message)),
    (archived) {
      _vehicleCubit.archiveLocally(vehicle.id!);
      _analytics.logEvent(AnalyticsEvents.vehicleArchived).ignore();
      emit(VehicleActionState.archiveSuccess(archivedId: vehicle.id!));
    },
  );
}

Future<void> unarchiveVehicle(VehicleModel vehicle) async {
  emit(const VehicleActionState.loading());
  final result = await _unarchiveVehicleUseCase(vehicle);
  result.fold(
    (error) => emit(VehicleActionState.error(message: error.message)),
    (restored) {
      _vehicleCubit.unarchiveLocally(vehicle.id!);
      _analytics.logEvent(AnalyticsEvents.vehicleUnarchived).ignore();
      emit(VehicleActionState.unarchiveSuccess(unarchivedId: vehicle.id!));
    },
  );
}
```

Los use cases se invocan con `.call(vehicle)` y devuelven `Either<DomainException, VehicleModel>`. El `fold` llama `archiveLocally`/`unarchiveLocally` en `VehicleCubit` **antes** de emitir el nuevo estado, para que la UI refleje el cambio de inmediato sin re-fetch HTTP.

**Nota crítica de compilación:** `deleteVehicle` permanece en el cubit sin cambios porque `vehicle_form_view.dart` sigue invocándolo. Los consumidores existentes de la rama `success` en `whenOrNull` —`vehicle_form_view.dart:_deleteListener` (línea ~308) y `garage_options_bottom_sheet.dart` (línea 52)— **no necesitan modificarse** porque la variante `success` se conservó con la misma firma.

---

### Paso 3 — `VehicleCubit`: añadir `archiveLocally` y `unarchiveLocally`

En `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart`, añadir los dos métodos después de `deleteVehicleLocally`:

```dart
void archiveLocally(String vehicleId) {
  final wasMain = _vehicles
      .any((v) => v.id == vehicleId && v.isMainVehicle);

  _vehicles = _vehicles
      .map((v) => v.id == vehicleId ? v.copyWith(isArchived: true) : v)
      .toList();

  if (wasMain) {
    _promoteNewMain();
  }

  // Si el vehículo archivado era el seleccionado, resetear selección al nuevo main
  if (_selectedVehicleId == vehicleId) {
    final actives = _vehicles.where((v) => !v.isArchived).toList();
    _selectedVehicleId = _selectionIdDefault(actives);
  }

  _emitLoadedOrEmpty();
}

void unarchiveLocally(String vehicleId) {
  _vehicles = _vehicles
      .map((v) => v.id == vehicleId ? v.copyWith(isArchived: false) : v)
      .toList();
  _emitLoadedOrEmpty();
}

/// Promueve el siguiente vehículo activo como principal.
/// Criterio: activos no archivados ordenados por createdAt desc
/// (nulls al final); tie-break por id lexicográfico asc.
/// Replica exactamente el findFirst del backend.
void _promoteNewMain() {
  final actives = _vehicles
      .where((v) => !v.isArchived)
      .toList()
    ..sort((a, b) {
      final ca = a.createdAt;
      final cb = b.createdAt;
      if (ca == null && cb == null) return a.id!.compareTo(b.id!);
      if (ca == null) return 1;  // nulls al final
      if (cb == null) return -1;
      final cmp = cb.compareTo(ca); // desc
      if (cmp != 0) return cmp;
      return a.id!.compareTo(b.id!); // tie-break asc
    });

  if (actives.isEmpty) {
    _vehicles = _vehicles
        .map((v) => v.copyWith(isMainVehicle: false))
        .toList();
    _selectedVehicleId = null;
    return;
  }

  final newMainId = actives.first.id!;
  _vehicles = _vehicles
      .map((v) => v.copyWith(isMainVehicle: v.id == newMainId))
      .toList();
  _selectedVehicleId = newMainId;
}
```

**Importante:** `_emitLoadedOrEmpty()` ya existe y opera sobre `_vehicles` completo (activos + archivados). La capa de UI filtra por `isArchived` para separar listas. No modificar `_emitLoadedOrEmpty`.

---

### Paso 4 — Actualizar todos los consumidores de `VehicleDeleteCubit`

Actualizar las importaciones y referencias en:

- `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` → sustituir `VehicleDeleteCubit`/`VehicleDeleteState` por `VehicleActionCubit`/`VehicleActionState`.
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` → mismas sustituciones de importación y tipo. El `.when` en `_deleteListener` (línea ~305) sigue usando `success: (deletedId) {...}` sin cambios.
- Cualquier otro consumidor detectado en el pre-flight.

---

### Paso 5 — Nuevos widgets: `GarageArchivedHeader` y `GarageArchivedSection`

**`GarageArchivedHeader`** — archivo: `lib/features/vehicles/presentation/garage/widgets/garage_archived_header.dart`

Widget `StatelessWidget`. Muestra el header colapsable con ícono de chevron que rota según el estado expandido. Touch target mínimo 44px de alto. El texto usa `context.l10n.vehicle_archivedSection(count)`.

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

**`GarageArchivedSection`** — archivo: `lib/features/vehicles/presentation/garage/widgets/garage_archived_section.dart`

Widget `StatefulWidget` (estado de expansión local). **Firma definitiva y canónica** — la misma que se usa en el Paso 7 y en todos los tests:

```dart
class GarageArchivedSection extends StatefulWidget {
  const GarageArchivedSection({
    super.key,
    required this.archivedVehicles,
    required this.onUnarchiveVehicle,
    required this.onVehicleTap,
  });

  final List<VehicleModel> archivedVehicles;
  final ValueChanged<VehicleModel> onUnarchiveVehicle;
  final ValueChanged<VehicleModel> onVehicleTap;
}
```

La `State<GarageArchivedSection>` coexiste en el mismo archivo (excepción permitida por las reglas: la clase `State<T>` puede coexistir con su `StatefulWidget`). El estado local `_isExpanded` comienza en `false`.

Si `archivedVehicles.isEmpty`, la sección retorna `const SizedBox.shrink()`.

Para mostrar el menú contextual de un vehículo archivado, `_GarageArchivedSectionState` invoca `GarageOptionsBottomSheet.show(context, vehicle, onGarageListUpdatedLocally: null)`. El `VehicleCubit` está garantizado en el árbol porque `GarageArchivedSection` vive dentro de `GarageVehiclesContent`, que a su vez vive bajo el `BlocProvider` raíz de `main.dart`. El `onGarageListUpdatedLocally` se pasa como `null` — la mutación local es suficiente.

Cuando el usuario toca "Restaurar" en el menú contextual, `GarageOptionsBottomSheet` invoca `actionCubit.unarchiveVehicle(vehicle)`, que llama `VehicleCubit.unarchiveLocally` — **nunca se llama `loadVehicles()` ni `fetchMyVehicles()`**. El callback `onUnarchiveVehicle` del widget es un hook opcional para que el parent reaccione (p.ej. cerrar la sección si queda vacía), no para disparar refetch.

---

### Paso 6 — Bifurcar `GarageOptionsBottomSheet` por `vehicle.isArchived`

En `garage_options_bottom_sheet.dart`, modificar el método `build()`:

**Rama vehículo activo (`!vehicle.isArchived`):**
- Orden de opciones (según diseño Pencil Fase 2, Frame 4): "Marcar como principal" (condicional), "Editar", "Agregar mantenimiento", "Archivar".
- El `ListTile` de "Eliminar" (líneas 162-189 del archivo actual) se **elimina completamente** del `build()` de la rama activo. `deleteVehicle` permanece en `VehicleActionCubit` porque `vehicle_form_view.dart` lo sigue invocando desde la pantalla de edición.

Añadir `ListTile` de "Marcar como principal" **antes** de "Editar" (visible solo si `!vehicle.isMainVehicle`):

```dart
if (!vehicle.isMainVehicle)
  ListTile(
    leading: Icon(Icons.star_rounded, color: context.colorScheme.primary),
    title: Text(
      context.l10n.vehicle_setMainVehicle,
      style: context.bodyLarge?.copyWith(color: Colors.white),
    ),
    onTap: () async {
      context.pop();
      final vehicleCubit = parentContext.read<VehicleCubit>();
      await vehicleCubit.setMainVehicle(vehicle.id!);
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text(parentContext.l10n.vehicle_setMainVehicleSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    },
  ),
```

- Añadir nuevo `ListTile` de "Archivar":

```dart
ListTile(
  leading: const Icon(Icons.archive_rounded, color: Colors.white),
  title: Text(
    context.l10n.vehicle_archiveVehicle,
    style: context.bodyLarge?.copyWith(color: Colors.white),
  ),
  onTap: () async {
    context.pop();
    final confirm = await ConfirmationDialog.show(
      context: parentContext,
      title: parentContext.l10n.vehicle_archiveConfirmTitle,
      content: parentContext.l10n.vehicle_archiveConfirmMessage,
      cancelLabel: parentContext.l10n.cancel,
      confirmLabel: parentContext.l10n.vehicle_archiveConfirmAction,
      isDismissible: true,
      // Tono informativo (sin confirmType: danger)
    );
    if (confirm != true || !parentContext.mounted) return;
    actionCubit.archiveVehicle(vehicle);
  },
),
```

**Rama vehículo archivado (`vehicle.isArchived`):**
- Mostrar únicamente: "Restaurar".
- "Editar" y "Agregar mantenimiento" **no aparecen** (decisión PO: un vehículo archivado no recibe nuevos registros).
- "Eliminar permanentemente" se añade en Fase 4.

```dart
ListTile(
  leading: const Icon(Icons.unarchive_rounded, color: Colors.white),
  title: Text(
    context.l10n.vehicle_unarchiveVehicle, // "Restaurar"
    style: context.bodyLarge?.copyWith(color: Colors.white),
  ),
  onTap: () {
    context.pop();
    actionCubit.unarchiveVehicle(vehicle);
  },
),
```

**Actualizar el `BlocListener`** dentro de `GarageOptionsBottomSheet.show` para manejar las ramas nuevas:
```dart
listener: (ctx, state) {
  state.whenOrNull(
    success: (_) {
      // Rama de delete existente — sin cambios
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text(parentContext.l10n.vehicle_vehicleDeleted),
          backgroundColor: AppColors.success,
        ),
      );
      onGarageListUpdatedLocally?.call();
    },
    archiveSuccess: (_) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text(parentContext.l10n.vehicle_archiveSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      onGarageListUpdatedLocally?.call();
    },
    unarchiveSuccess: (_) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text(parentContext.l10n.vehicle_unarchiveSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      onGarageListUpdatedLocally?.call();
    },
    error: (message) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ctx.colorScheme.error,
        ),
      );
    },
  );
},
```

**Aclaración de scope y BlocProvider:** `GarageOptionsBottomSheet.show` (línea 38 actual) lee `parentContext.read<VehicleCubit>()` y crea `getIt<VehicleActionCubit>()..reset()`. Cuando se invoca desde `GarageArchivedSection` (que vive dentro de `GarageVehiclesContent`), el `VehicleCubit` está en el árbol porque el `BlocProvider` raíz lo provee. El `onGarageListUpdatedLocally` que se pasa desde `GarageArchivedSection` para vehículos archivados **no dispara** `loadVehicles()`/`fetchMyVehicles()` — la mutación local vía `unarchiveLocally` es suficiente (CA #2 y #5).

---

### Paso 7 — Integrar `GarageArchivedSection` en `GarageVehiclesContent`

En `garage_vehicles_content.dart`:

1. Calcular la lista de archivados:
```dart
final archivedVehicles = state is Data<List<VehicleModel>>
    ? state.data.where((v) => v.isArchived).toList(growable: false)
    : const <VehicleModel>[];
```

2. Añadir `GarageArchivedSection` al final del `SliverChildListDelegate`, después de `otherVehicles`:
```dart
if (archivedVehicles.isNotEmpty)
  GarageArchivedSection(
    archivedVehicles: archivedVehicles,
    onUnarchiveVehicle: (vehicle) {
      // El bottom sheet maneja la lógica vía VehicleActionCubit.
      // onGarageListUpdatedLocally se pasa como null: sin re-fetch HTTP.
      GarageOptionsBottomSheet.show(
        context,
        vehicle,
        onGarageListUpdatedLocally: null,
        onMaintenanceCreated: onMaintenanceCreated,
        onMaintenanceRefreshRequested: onMaintenanceRefreshRequested,
      );
    },
    onVehicleTap: (vehicle) => onSelectVehicle(vehicle),
  ),
```

Esta integración usa la firma definitiva de `GarageArchivedSection` del Paso 5. El `onGarageListUpdatedLocally: null` garantiza que no se dispara `fetchMyVehicles()` al restaurar.

---

### Paso 8 — Analytics events

Si `AnalyticsEvents` no tiene `vehicleArchived` y `vehicleUnarchived`, añadirlos en `lib/core/services/analytics/analytics_events.dart`.

---

### Paso 9 — Lint y tests

1. `dart analyze` → cero errores (excluir el lint conocido de `api_base_url_resolver.dart`).
2. `flutter test` → cero fallas.
3. Escribir los widget tests requeridos (ver sección Pruebas).

---

## Archivos a crear/modificar (rutas reales)

| Acción | Archivo | Qué cambia |
|--------|---------|------------|
| Modificar | `lib/l10n/app_es.arb` | Actualizar `vehicle_unarchiveVehicle` → "Restaurar"; añadir 8 claves nuevas |
| Regenerar | `lib/l10n/app_localizations.dart` y `app_localizations_es.dart` | Salida de `flutter gen-l10n` |
| Renombrar/modificar | `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` → `vehicle_action_state.dart` | Clase `VehicleDeleteState` → `VehicleActionState`; conservar variante `success`; añadir `archiveSuccess` y `unarchiveSuccess` |
| Renombrar/modificar | `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` → `vehicle_action_cubit.dart` | Clase `VehicleDeleteCubit` → `VehicleActionCubit`; añadir `archiveVehicle` y `unarchiveVehicle`; inyectar use cases |
| Regenerar | `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.freezed.dart` | Salida de `build_runner` |
| Modificar | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` | Añadir `archiveLocally`, `unarchiveLocally`, `_promoteNewMain` |
| Modificar | `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | Bifurcar `build()` por `isArchived`; eliminar `ListTile` de "Eliminar"; añadir "Archivar" y "Restaurar"; actualizar `BlocListener`; actualizar tipo de cubit a `VehicleActionCubit` |
| Modificar | `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` | Calcular `archivedVehicles`; añadir `GarageArchivedSection` al final de la lista |
| Crear | `lib/features/vehicles/presentation/garage/widgets/garage_archived_header.dart` | Nuevo widget `GarageArchivedHeader` (1 widget por archivo) |
| Crear | `lib/features/vehicles/presentation/garage/widgets/garage_archived_section.dart` | Nuevo widget `GarageArchivedSection` + `_GarageArchivedSectionState` (coexisten en un archivo) |
| Modificar | `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` | Actualizar importación y tipo: `VehicleDeleteCubit`/`VehicleDeleteState` → `VehicleActionCubit`/`VehicleActionState` |
| Modificar | `lib/core/services/analytics/analytics_events.dart` | Añadir `vehicleArchived` y `vehicleUnarchived` si no existen |
| Crear | `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | Widget tests para `GarageArchivedSection` y diálogos de confirmación |

---

## Contratos / API rideglory-api

Ninguno. Esta fase usa exclusivamente `PATCH /api/vehicles/:id` con `{ isArchived: true/false }` vía `ArchiveVehicleUseCase`/`UnarchiveVehicleUseCase` que ya funcionan en producción. No se cambia ningún contrato HTTP ni DTO.

---

## Cambios de datos / migraciones

Ninguno. El campo `isArchived Boolean @default(false)` ya existe en el schema de Prisma (vehicles-ms).

---

## Criterios de aceptación

1. Al archivar un vehículo activo, desaparece de la lista activa y aparece bajo "Archivados (N)" en la misma sesión, sin navegación ni reload de página.
2. Al restaurar un vehículo archivado, vuelve a la lista activa de inmediato, **sin re-fetch HTTP** (`fetchMyVehicles` no se invoca en el flujo de restaurar).
3. El contador "(N)" en el header de la sección archivados refleja en todo momento el número real de vehículos con `isArchived: true` en el estado local de `VehicleCubit`.
4. Si el vehículo archivado era el principal (`isMainVehicle: true`), `VehicleCubit.archiveLocally` promueve automáticamente el siguiente vehículo activo según el criterio: activos no archivados ordenados por `createdAt` desc (nulls al final), tie-break por `id` lexicográfico asc. Esto ocurre antes de emitir el nuevo estado, de modo que la UI refleja el nuevo main de inmediato.
5. El wiring de `onArchive`/`onUnarchive` se realiza en `GarageVehiclesContent`/`GarageOptionsBottomSheet`. `VehicleCard` solo recibe y ejecuta los callbacks — no llama use cases ni cubits directamente.
6. `GarageArchivedSection` y `GarageArchivedHeader` son widgets en archivos propios (un widget por archivo, sin métodos privados que retornen widgets).
7. La sección "Archivados" no se renderiza cuando no hay vehículos archivados (`archivedVehicles.isEmpty` → `SizedBox.shrink()`).
8. "Editar" y "Agregar mantenimiento" no aparecen en el menú contextual de vehículos archivados.
9. El `ListTile` de "Eliminar" no aparece en el menú contextual de vehículos activos (reemplazado por "Archivar").
10. Todos los textos de UI (labels de menú, header de sección, mensajes del diálogo, snackbars) provienen de claves `l10n` — cero strings hardcodeados.
11. `dart analyze` pasa en verde (excluido el lint conocido de `api_base_url_resolver.dart`).
12. `flutter test` pasa en verde.
13. **[Tests mínimos verificables]** Existen widget tests para `GarageArchivedSection` que cubren: (a) estado vacío — sección no renderizada, (b) estado colapsado con contador correcto, (c) estado expandido listando los vehículos archivados. Existen tests para el diálogo de confirmación de archivado: (d) flujo confirmar dispara `archiveVehicle`, (e) flujo cancelar no dispara `archiveVehicle`.

---

## Pruebas (unitarias/widget/integración)

### Widget tests requeridos

**Archivo:** `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart`

**Test 1 — sección vacía:**
- Dado: `archivedVehicles: []`
- Esperar: `GarageArchivedSection` retorna `SizedBox.shrink()` — `find.byType(GarageArchivedHeader)` no encuentra nada.

**Test 2 — colapsado con contador:**
- Dado: `archivedVehicles: [vehicle1, vehicle2]`
- Esperar: `GarageArchivedHeader` visible con texto "Archivados (2)".
- Esperar: los `VehicleCard` de los archivados **no** son visibles (sección colapsada por defecto).

**Test 3 — expandido muestra vehículos:**
- Dado: `archivedVehicles: [vehicle1, vehicle2]`
- Acción: tap sobre `GarageArchivedHeader`.
- Esperar: los 2 vehículos archivados son visibles en pantalla.

**Firma del widget usada en los 3 tests** (idéntica a Paso 5 y Paso 7):
```dart
GarageArchivedSection(
  archivedVehicles: archivedVehicles,
  onUnarchiveVehicle: (v) { ... },
  onVehicleTap: (v) { ... },
)
```

**Test 4 — flujo confirmar archivado:**
- Dado: `GarageOptionsBottomSheet` con vehículo activo.
- Acción: tap en "Archivar" → aparece `ConfirmationDialog` → tap en "Archivar" (confirmar).
- Esperar: `VehicleActionCubit.archiveVehicle(vehicle)` fue invocado.

**Test 5 — flujo cancelar archivado:**
- Dado: `GarageOptionsBottomSheet` con vehículo activo.
- Acción: tap en "Archivar" → aparece `ConfirmationDialog` → tap en "Cancelar".
- Esperar: `VehicleActionCubit.archiveVehicle(vehicle)` **no** fue invocado.

### Tests unitarios recomendados para `archiveLocally` / `_promoteNewMain`

- Fixture con vehículos de distintos `createdAt` y algunos `null`, uno con `isMainVehicle: true`.
- Verificar que tras `archiveLocally(mainId)`, el nuevo main coincide con el criterio (el activo con `createdAt` más reciente, o el de `id` más pequeño si `createdAt` es null).
- Verificar que tras `unarchiveLocally(id)`, el vehículo tiene `isArchived: false` en el estado emitido.

---

## Riesgos y mitigaciones

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|------------|
| R-1 | **Criterio de promoción de main local diverge del backend** cuando `createdAt` es null o tiene zona horaria distinta | Media | Medio | Criterio documentado con tie-break determinista (`id` asc). Test unitario con fixture de `createdAt null` verifica la lógica de forma aislada. |
| R-2 | **`vehicle_unarchiveVehicle` actualizada rompe otros contextos** si la clave se usa en otro lugar con el label "Desarchivar" | Baja | Bajo | Pre-flight: `grep -rn 'vehicle_unarchiveVehicle' lib/` confirma consumidores actuales (`vehicle_card.dart:224`). Cambio seguro. |
| R-3 | **Firma de `GarageArchivedSection` inconsistente** entre implementación, integración y tests | Baja | Medio | La firma definitiva está fijada en esta especificación (Pasos 5, 7 y Tests). No introducir variantes. |
| R-4 | **`VehicleActionCubit` instanciado como singleton** en lugar de scoped: el estado de loading/archiveSuccess persiste entre sesiones del bottom sheet | Baja | Medio | `@injectable` (no `@singleton`); crear con `getIt<VehicleActionCubit>()..reset()` al abrir el bottom sheet. |
| R-5 | **Re-fetch HTTP disparado en el flujo de restaurar**: si `onGarageListUpdatedLocally` del `GarageArchivedSection` llama `loadVehicles()` | Baja | Bajo | El callback se pasa como `null` desde `GarageVehiclesContent`. CA #2 y #5 prohíben re-fetch en el flujo de restaurar. |
| R-6 | **Diseño Pencil no aprobado al iniciar esta fase** | Media | Alto | Gate duro: no iniciar Paso 1 sin aprobación escrita del PO sobre los frames de Pencil. |
| R-7 | **Compilación rota por la variante `success`**: si el implementador renombra `success` → `deleteSuccess` en el estado freezed sin actualizar `vehicle_form_view.dart` y `garage_options_bottom_sheet.dart` | Baja | Alto | La decisión está documentada: **conservar la variante `success` sin renombrar**. Los consumidores existentes no requieren cambios. |

---

## Dependencias (fases prerequisito y por qué)

| Fase | Tipo | Razón |
|------|------|-------|
| **Fase 2** (Diseño Pencil) | Bloqueante duro | Las reglas del proyecto prohíben implementar UI nueva sin diseño aprobado en Pencil. Esta fase introduce `GarageArchivedSection`, `GarageArchivedHeader` y el menú bifurcado — todo UI nueva. Sin aprobación del PO, no se toca código. |

**No depende de:**
- Fase 1 (Backend): esta fase usa únicamente `PATCH /api/vehicles/:id` existente.
- Fase 4 (eliminación permanente): independiente; Fase 4 depende de esta.
- Fase 5 (home coherente): independiente; pueden ejecutarse en cualquier orden.

---

## Ejecución recomendada (nivel rg-exec: normal)

**Por qué `normal`:** Feature acotada con lógica de cubit (promoción de main local con criterio determinista, estado freezed unificado con variantes de archive/unarchive) y UI nueva (sección colapsable, bifurcación de menú contextual, diálogos de confirmación). Riesgo medio: el criterio de desempate `createdAt null` debe sincronizar con el backend, y la decisión sobre la variante `success` en el estado freezed tiene impacto directo de compilación. Sin migraciones ni cambios de contrato de API en esta fase (usa PATCH existente). Un arquitecto + QA + 2 rondas de auditor cubren el riesgo adecuadamente.

**Agentes sugeridos:**
- **Implementador (Sonnet):** ejecuta los 9 pasos secuencialmente.
- **Auditor (Opus):** revisa en al menos 2 rondas: (1) tras ampliar el estado freezed y los métodos del cubit; (2) tras completar la UI y los tests.

**Secuencia de verificación local al finalizar:**
1. `flutter gen-l10n` → sin errores.
2. `dart run build_runner build --delete-conflicting-outputs` → sin errores (regenera `.freezed.dart`).
3. `dart analyze` → cero warnings (excluido lint conocido de `api_base_url_resolver.dart`).
4. `flutter test` → todos los tests en verde, incluyendo los nuevos widget tests.
