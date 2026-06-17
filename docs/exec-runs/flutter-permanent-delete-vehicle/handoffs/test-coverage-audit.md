# Auditoría de cobertura de pruebas — flutter-permanent-delete-vehicle

**Auditor:** Opus
**Fecha:** 2026-06-17T17:38:15Z
**Veredicto:** APROBADO con observaciones (no bloqueantes)

---

## Resultado de ejecución

- `flutter test test/features/vehicles/presentation/delete/ test/.../cubit/vehicle_cubit_test.dart` → **18 passed** (TC-perm-A/B/C + 15 cubit TCs).
- TC-veh-8 (`deleteVehicleLocally`) eliminado correctamente del cubit test.
- 2 fallos pre-existentes en `garage_options_bottom_sheet_test.dart` (TC-bs-1/TC-bs-2) por `find.byIcon(Icons.archive)` vs `LucideIcons.archive`; baseline confirmado, no regresión de esta fase.

## Matriz AC → prueba (criterio: fallaría sin el cambio)

| AC | Cobertura | Veredicto |
|----|-----------|-----------|
| 1 visibilidad contextual | TC-perm-A abre sheet sobre vehículo archivado y encuentra "Eliminar permanentemente"; grep confirma form sin entrada | OK |
| 2 diálogo destructivo | TC-perm-A asserta título `vehicle_permanentDeleteTitle` + nombre del vehículo. NO asserta `DialogActionType.danger`/color error | PARCIAL (no bloqueante; el arg danger es literal en código) |
| 3 flujo confirmación | TC-perm-A (abre) + TC-perm-C (cancelar → `verifyNever`) | OK |
| 4 anti doble-tap | TC-perm-B: dos llamadas concurrentes con Completer diferido → `called(1)`. Fallaría sin el guard `if (state is _Loading) return` | OK (prueba no trivial) |
| 5 re-fetch tras éxito | **SIN ASERCIÓN.** TC-perm-B stubea `fetchMyVehicles` y la rama de éxito la invoca, pero ningún test verifica `verify(() => vehicleCubit.fetchMyVehicles()).called(1)` | GAP (testeable barato) |
| 6 snackbar éxito | Sin test (manual M-3) | GAP |
| 7 snackbar error | Sin test (manual M-8) | GAP |
| 8 contrato Retrofit | grep `hard-delete` → 0 hits; `@DELETE('${ApiRoutes.myVehicles}/{id}') permanentlyDeleteVehicle` | OK (grep, no test) |
| 9 renombrado completo | grep `deleteVehicle\|DeleteVehicleUseCase` → solo getters l10n `vehicle_deleteVehicle` (string, fuera de scope §3), 0 hits del método/use case | OK |
| 10 tests en verde | 18 nuevos/relevantes passed | OK |
| 11 strings l10n | Inspección; sin test contextual | OK por inspección |
| 12 form limpio | grep `onDelete`/`BlocProvider.*VehicleDeleteCubit` en form → 0 hits | OK |

## Gaps de cobertura (no bloqueantes)

1. **AC-5 (re-fetch)** es la mejora barata de mayor valor: añadir a un test de cubit
   `verify(() => vehicleCubit.fetchMyVehicles()).called(1)` tras un delete exitoso
   (`Right(null)`). Fallaría con el código viejo (`deleteVehicleLocally`). Recomendado.
2. **AC-2 danger style**: TC-perm-A podría asertar el color de error del CTA del diálogo.
3. **AC-6/AC-7 snackbars**: cubiertos solo por manual M-3/M-8.

Ninguno bloquea: la lógica crítica (visibilidad, confirmación, guard anti doble-tap, contrato,
renombrado) está cubierta por pruebas que fallarían sin el cambio. Los gaps son del camino de
éxito/efectos secundarios, documentados explícitamente por QA como manual-pending.
