# Architect handoff — flutter-permanent-delete-vehicle

**Date:** 2026-06-17T17:06:23Z
**Status:** done

---

## Decisiones

### Estado real vs PRD

La PRD describe un feature a implementar desde cero. El código real está **~80 % implementado** por las fases previas. Los renombrados de dominio/datos (`permanentlyDeleteVehicle`) y el cubit `VehicleActionCubit` ya existen y funcionan. Los 5 l10n keys nuevos ya existen en `app_es.arb` y están generados. Los widget tests TC-A, TC-B y TC-C ya existen en el archivo correcto.

**Lo que falta (trabajo real para Frontend):**

1. **Eliminar `VehicleDeleteCubit`** — es el cubit obsoleto (`vehicle_delete_cubit.dart`, `vehicle_delete_state.dart`, `vehicle_delete_cubit.freezed.dart`). Ya existe `VehicleActionCubit` que lo reemplaza con semántica más amplia. El cubit viejo tiene registro en `injection.config.dart` y debe eliminarse de DI.
2. **Eliminar `VehicleActionState.success`** — variante huérfana en `vehicle_action_state.dart`. Nadie en `VehicleActionCubit` la emite; el listener en `GarageOptionsBottomSheet` la maneja con `vehicle_vehicleDeleted` l10n (stale), pero esa rama nunca se alcanza. Limpiar la variante y su listener.
3. **Eliminar `deleteVehicleLocally`** en `VehicleCubit` — método sin callers en `lib/` (solo referenciado en tests que también deben actualizarse). El re-fetch ya usa `fetchMyVehicles()`.
4. **Documentar claves l10n huérfanas** — `vehicle_deleteVehicle`, `vehicle_deleteVehicleConfirmContent`, `vehicle_form_delete_vehicle` siguen en `app_es.arb` y en los archivos generados. El PRD dice: verificar con grep y documentar (no eliminar en esta fase).
5. **Verificar form limpio** — `VehicleFormPage` no tiene `VehicleDeleteCubit`; `VehicleFormCta` ya no tiene `onDelete`. Confirmado: LIMPIO. No hay trabajo.
6. **Regenerar `injection.config.dart`** — tras eliminar `VehicleDeleteCubit` hay que correr `build_runner` para que DI quede consistente.

---

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
|---------|---------------|-------------|---------------------|
| Vehicles — permanent delete | Ninguno (ya completado) | Ninguno (ya completado) | Eliminar `VehicleDeleteCubit` + variante `VehicleActionState.success` + método `deleteVehicleLocally` en `VehicleCubit`; regenerar DI |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` | delete | Cubit obsoleto, reemplazado por `VehicleActionCubit` | med — DI y freezed deben regenerarse |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` | delete | Part file del cubit obsoleto | low |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.freezed.dart` | delete | Archivo generado del cubit obsoleto (auto-regenerado, pero eliminarlo evita confusión) | low |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_state.dart` | modify | Eliminar variante `success` huérfana (`_Success`) que nadie emite | low |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.freezed.dart` | delete (regenerar) | Debe regenerarse tras cambio en state | low |
| `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | modify | Eliminar el `success:` branch del listener (que usaba `vehicle_vehicleDeleted` — nunca alcanzado) | low |
| `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` | modify | Eliminar método `deleteVehicleLocally` (sin callers en lib/) | low |
| `lib/core/di/injection.config.dart` | delete (regenerar) | Debe regenerarse via `build_runner` para eliminar el factory de `VehicleDeleteCubit` | med |
| `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` | modify | Eliminar el grupo `deleteVehicleLocally` (referencia al método eliminado) | low |

---

## Contratos rideglory-api

Sin cambios. El endpoint `DELETE /api/vehicles/my/:vehicleId` ya estaba implementado en Fase 1.

No hay nuevas rutas, DTOs ni migraciones.

---

## Datos / migraciones

No aplica en esta fase.

---

## Env

No hay nuevas variables de entorno.

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| `injection.config.dart` queda inconsistente si `build_runner` no se corre después de eliminar `VehicleDeleteCubit` | Correr `dart run build_runner build --delete-conflicting-outputs` (o con `--force-jit` en worktrees) inmediatamente tras las eliminaciones |
| `vehicle_action_cubit.freezed.dart` queda stale tras modificar `vehicle_action_state.dart` | Mismo `build_runner` run lo regenera |
| El grupo de tests `deleteVehicleLocally` en `vehicle_cubit_test.dart` rompe si se elimina el método sin actualizar el test | Eliminar el grupo de tests en el mismo commit |
| Claves l10n huérfanas (`vehicle_deleteVehicle`, etc.) en `app_es.arb` no causan error de compilación pero ensucian el arb — documentadas aquí, no se eliminan en esta fase per PRD §3 | Grep post-implementación confirma cero consumidores UI; deuda documentada |

---

## Orden de implementación

1. Eliminar `vehicle_delete_cubit.dart`, `vehicle_delete_state.dart`, `vehicle_delete_cubit.freezed.dart`.
2. Modificar `vehicle_action_state.dart`: eliminar la variante `success` (`_Success`).
3. Modificar `garage_options_bottom_sheet.dart`: eliminar el branch `success:` del `whenOrNull` listener (el que llama `vehicle_vehicleDeleted`).
4. Modificar `vehicle_cubit.dart`: eliminar el método `deleteVehicleLocally`.
5. Modificar `vehicle_cubit_test.dart`: eliminar el grupo `deleteVehicleLocally`.
6. Correr `dart run build_runner build --delete-conflicting-outputs` (regenera `injection.config.dart` y `vehicle_action_cubit.freezed.dart`).
7. Correr `dart analyze` — debe dar cero errores.
8. Correr `flutter test` — los tres TCs del `vehicle_permanent_delete_dialog_test.dart` deben estar en verde.
9. Grep de verificación: `grep -rn 'deleteVehicle\|DeleteVehicleUseCase\|VehicleDeleteCubit' lib/ --include='*.dart' | grep -v '.g.dart\|.freezed.dart'` → cero hits de `VehicleDeleteCubit`; los únicos hits de `deleteVehicle` son el método `deleteVehicleLocally` que ya fue eliminado.

---

## Superficie de regresión

- `GarageOptionsBottomSheet` — tiles de vehículos activos (Editar, Mantenimiento, Archivar) no deben verse afectados.
- `VehicleCubit` — todos los métodos excepto `deleteVehicleLocally` (eliminado) permanecen intactos.
- `VehicleFormPage` / `VehicleFormView` / `VehicleFormBody` / `VehicleFormCta` — ya no tienen referencias a delete; no requieren cambios.
- DI global — el factory de `VehicleDeleteCubit` desaparece; `VehicleActionCubit` conserva su factory.
- Tests existentes de `vehicle_cubit_test.dart` — solo el grupo `deleteVehicleLocally` se elimina; el resto permanece sin cambios.

---

## Fuera de alcance

- Eliminar el alias `hard-delete/:id` en el gateway (Fase 1 / infra backend).
- Eliminar las claves l10n huérfanas `vehicle_deleteVehicle`, `vehicle_deleteVehicleConfirmContent`, `vehicle_form_delete_vehicle` del ARB y archivos generados.
- Cambios en `HomeGarageSection` o `HomeCubit` (Fase 5).
- Cambios en diseño Pencil (Fase 2).
- Lógica de archivar/restaurar (Fase 3).
- `dart analyze` del flag `Local API hack` — los 2 lints de `shouldUseLocalApi` se ignoran per MEMORY.md.
