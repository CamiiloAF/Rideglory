# Frontend Handoff — flutter-permanent-delete-vehicle

**Agent:** Frontend (Flutter lib/)
**Date:** 2026-06-17T17:30:27Z

---

## Baseline

- `flutter test` antes de cambios: **549 passed, 2 failed** (fallas pre-existentes en `garage_options_bottom_sheet_test.dart` — TC-bs-1 y TC-bs-2, no relacionadas con este feature).
- `dart analyze lib/`: 1 issue pre-existente (`curly_braces_in_flow_control_structures` en `custom_route_builder_section.dart`).

---

## Archivos cambiados

### Eliminados (3 archivos)
| Archivo | Motivo |
|---------|--------|
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` | Cubit obsoleto, reemplazado por `VehicleActionCubit` |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` | Part file del cubit obsoleto |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.freezed.dart` | Generado obsoleto |

### Modificados (5 archivos)
| Archivo | Cambio |
|---------|--------|
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_state.dart` | Eliminada variante `success({required String deletedId}) = _Success` — código muerto |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.freezed.dart` | Regenerado via build_runner (refleja eliminación de `_Success`) |
| `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | Eliminado branch `success:` del `whenOrNull` listener (nunca era alcanzado) |
| `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` | Eliminado método `deleteVehicleLocally` — sin callers en lib/ |
| `lib/core/di/injection.config.dart` | Regenerado via build_runner (eliminado factory de `VehicleDeleteCubit`) |
| `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` | Eliminado grupo `deleteVehicleLocally` (TC-veh-8) — referenciaba método eliminado |

---

## Pruebas nuevas

No se requirieron pruebas nuevas; todos los cambios son eliminación de código muerto.

---

## Resultado final

- `dart analyze lib/`: **1 issue** (pre-existente, no relacionado con este feature).
- `flutter test`: **865 passed, 2 failed** (mismas 2 fallas pre-existentes de baseline en TC-bs-1 y TC-bs-2).
- Grep de verificación: `grep -rn 'VehicleDeleteCubit\|deleteVehicleLocally' lib/ --include='*.dart'` → **0 hits**.

---

## Verificacion manual

1. Abrir el garage con un vehículo archivado → opción "Eliminar permanentemente" visible.
2. Confirmar el dialogo → snackbar `vehicle_permanentDeleteSuccess` aparece y el vehículo desaparece de la lista.
3. Descartar el dialogo → sin efecto (no se llama a `permanentlyDeleteVehicle`).
4. Archivar vehículo activo → snackbar `vehicle_vehicleArchived`, vehículo pasa a sección archivados.
5. Restaurar vehículo archivado → snackbar `vehicle_vehicleRestored`, vehículo regresa a activos.

---

## Notas para QA

- **TC-bs-1 y TC-bs-2** siguen fallando — son fallas pre-existentes del test de widget del bottom sheet, no regresiones de este feature.
- El branch `success:` fue código muerto desde la introducción de `permanentDeleteSuccess:`; su eliminación no afecta ningún flujo visible.
- `VehicleDeleteCubit` fue completamente reemplazado por `VehicleActionCubit` en iteraciones anteriores; su eliminación limpia el DI container y evita confusión futura.
- No hay cambios de UI, strings ARB ni flujos nuevos en esta fase — es limpieza pura.
