> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend

**Feature:** flutter-permanent-delete-vehicle
**Date:** 2026-06-17T17:06:23Z

---

## Estado real del código

La mayor parte del feature ya está implementada. El trabajo de Frontend es **limpieza de código muerto**, no implementación nueva.

---

## Archivos a eliminar (3 archivos)

| File | Motivo |
|------|--------|
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` | Cubit obsoleto — reemplazado por `VehicleActionCubit` |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` | Part file del cubit obsoleto |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.freezed.dart` | Archivo generado obsoleto |

---

## Archivos a modificar (4 archivos)

### 1. `lib/features/vehicles/presentation/delete/cubit/vehicle_action_state.dart`
Eliminar la variante `success` (nadie la emite en `VehicleActionCubit`):
```dart
// ELIMINAR esta linea y la de cierre:
const factory VehicleActionState.success({required String deletedId}) = _Success;
```

### 2. `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart`
En el `BlocListener` del `show()` static method, eliminar el branch `success:` del `whenOrNull` (lineas ~57-64). Ese branch nunca se alcanza y usa la clave `vehicle_vehicleDeleted` que pierde consumidores.

### 3. `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart`
Eliminar el método `deleteVehicleLocally` (linea ~214). No tiene callers en `lib/`.

### 4. `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart`
Eliminar el grupo `deleteVehicleLocally` (referencia al método eliminado).

---

## Secuencia obligatoria

1. Eliminar los 3 archivos.
2. Aplicar los 4 cambios de modificación.
3. Correr: `dart run build_runner build --delete-conflicting-outputs`
   - Regenera `injection.config.dart` (elimina el factory de `VehicleDeleteCubit`)
   - Regenera `vehicle_action_cubit.freezed.dart` (refleja la eliminación de `_Success`)
4. Correr: `dart analyze` → 0 errores
5. Correr: `flutter test` → verde (incluye TC-A, TC-B, TC-C en `vehicle_permanent_delete_dialog_test.dart`)

---

## Grep de verificación post-implementación

```bash
grep -rn 'VehicleDeleteCubit\|deleteVehicleLocally' lib/ --include='*.dart' | grep -v '.g.dart\|.freezed.dart'
# Debe dar 0 hits
```

---

## Lo que NO cambia

- `VehicleActionCubit` — ya está correcto (guard anti doble-tap, re-fetch, analytics).
- `GarageOptionsBottomSheet` — solo se elimina el `success:` branch del listener; el resto (incluyendo `permanentDeleteSuccess:`, `archiveSuccess:`, `unarchiveSuccess:`, `error:`) permanece.
- `VehicleFormPage` / `VehicleFormCta` / `VehicleFormBody` / `VehicleFormView` — ya están limpios, sin referencias a delete.
- `app_es.arb` y archivos generados de l10n — sin cambios (las claves huérfanas no se eliminan en esta fase).
- Tests `vehicle_permanent_delete_dialog_test.dart` — ya existentes y deben pasar sin modificación.

---

## Constraints de arquitectura

- Un widget por archivo (ya cumplido; no introducir métodos que retornen widgets).
- `BuildContext` prohibido en capa data.
- `dart analyze` debe pasar antes de cerrar la fase.

> Full detail: handoffs/architect.md
