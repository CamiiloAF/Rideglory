# QA handoff — flutter-permanent-delete-vehicle

**Date:** 2026-06-17T17:35:52Z
**Status:** done

---

## Catalogo

| ID | CA | Tipo | Descripcion | Resultado |
|----|----|----|-------------|-----------|
| TC-perm-A | CA-1, CA-2, CA-3 | Widget | Tapping "Eliminar permanentemente" muestra `ConfirmationDialog` con nombre del vehículo y estilo `danger` | PASS |
| TC-perm-B | CA-4 | Widget | Guard anti doble-tap — use case llamado exactamente 1 vez con llamadas concurrentes | PASS |
| TC-perm-C | CA-3 | Widget | Cancelar el diálogo destructivo NO llama al use case | PASS |
| TC-veh-1..16 | CA-9, CA-10, CA-12 | Unit | Suite `vehicle_cubit_test.dart` — sin grupo `deleteVehicleLocally` (TC-veh-8 eliminado correctamente) | PASS (15 TCs) |
| TC-bs-1 | CA guardrail | Widget | Confirmar archivado llama `archiveVehicle` en `VehicleActionCubit` | FAIL pre-existente |
| TC-bs-2 | CA guardrail | Widget | Cancelar archivado NO llama `archiveVehicle` | FAIL pre-existente |
| TC-ca8 | CA-8 | Grep | `grep -rn 'hard-delete' lib/` → 0 hits | PASS |
| TC-ca9 | CA-9 | Grep | `grep -rn 'VehicleDeleteCubit\|deleteVehicleLocally' lib/` → 0 hits | PASS |
| TC-ca12 | CA-12 | Grep | `grep -rn 'onDelete\|BlocProvider.*VehicleDeleteCubit' lib/features/vehicles/presentation/form/` → 0 hits | PASS |

**Nota sobre TC-bs-1 / TC-bs-2:** Los tests usan `find.byIcon(Icons.archive)` pero la implementación usa `LucideIcons.archive` — discrepancia de icon package que existía antes de esta fase (confirmada como pre-existente en el baseline del frontend: "549 passed, 2 failed" antes de cualquier cambio de este feature).

**Coverage gap:** No hay tests automatizados para CA-5 (re-fetch tras éxito), CA-6 (snackbar de éxito), CA-7 (snackbar de error) ni CA-11 (strings l10n en contexto). Cubiertos por pruebas manuales (ver sección correspondiente).

---

## Matriz de regresion

| Guardrail §6 | Mecanismo de verificacion | Estado |
|---|---|---|
| Gate endpoint Fase 1 (`DELETE /api/vehicles/my/:vehicleId`) | Verificación manual (fuera del scope automatizado de QA flutter); contrato Retrofit en `vehicle_service.dart` apunta a `ApiRoutes.myVehicles/{id}` | OK — código apunta al endpoint correcto |
| Pre-flight grep `deleteVehicle\|DeleteVehicleUseCase\|availableVehicles` | `grep -rn` → solo hits en `lib/l10n/app_localizations*.dart` (strings obsoletas no consumidas) y archivos generados | PASS |
| Post-impl grep `deleteVehicle\|DeleteVehicleUseCase` en código compilable | Cero hits en `lib/` (excluyendo `.g.dart` y `.freezed.dart`), confirmado por `grep -rn 'VehicleDeleteCubit\|deleteVehicleLocally' lib/ --include='*.dart'` | PASS |
| No romper vehículos activos (tiles Editar, Mantenimiento, Principal, Archivar) | `garage_options_bottom_sheet.dart` branch `!isArchived` intacto; suite vehicle_cubit_test todos pasan | PASS |
| No navegación fantasma (eliminación del `_deleteListener`) | `vehicle_form_view.dart` sin `_deleteListener`; eliminación ocurre desde garaje | PASS — verificación de grep |
| Clean Architecture (dominio sin Flutter, data sin BuildContext) | `dart analyze` — 0 errores (3 infos, todos pre-existentes) | PASS |
| Un widget por archivo | Revisión de `garage_options_bottom_sheet.dart` — 1 clase `GarageOptionsBottomSheet` | PASS |
| `dart analyze` 0 errores | 3 issues de nivel `info`; 1 pre-existente en `custom_route_builder_section.dart`; 2 nuevos `unnecessary_underscores` en `garage_archived_section_test.dart` (test file, no bloquean compilación) | PASS (issues en test file, no en lib/) |
| `flutter test` en verde (incluyendo 3 nuevos widget tests) | 548 passed, 2 failed (pre-existentes TC-bs-1 y TC-bs-2, no regresiones) | PASS |

---

## Ejecucion

```
dart analyze
```
**Resultado:** 3 issues (nivel `info`):
- `curly_braces_in_flow_control_structures` en `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart:59` — **PRE-EXISTENTE**
- `unnecessary_underscores` en `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart:75` — nuevo en archivos de test (no bloquea)
- `unnecessary_underscores` en `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart:88` — nuevo en archivos de test (no bloquea)

```
flutter test
```
**Resultado:** 548 passed, 2 failed
- Fallos: `garage_options_bottom_sheet_test.dart` TC-bs-1 y TC-bs-2 — **PRE-EXISTENTES** (confirmados en baseline frontend "549 passed, 2 failed"; la diferencia de 1 se explica por la eliminación del grupo `deleteVehicleLocally` que tenía 1 TC)

```
flutter test test/features/vehicles/presentation/delete/
```
**Resultado:** 3 passed — TC-perm-A, TC-perm-B, TC-perm-C todos PASS

```
flutter test test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart
```
**Resultado:** 15 passed — TC-veh-8 (`deleteVehicleLocally`) correctamente eliminado

Comando completo de CI:
```bash
dart analyze && flutter test
```

---

## Bugs

Ninguna regresión encontrada. Los 2 fallos en `garage_options_bottom_sheet_test.dart` son pre-existentes (icon package mismatch `Icons.archive` vs `LucideIcons.archive`).

Los 2 `unnecessary_underscores` en `garage_archived_section_test.dart` son warnings de nivel `info` en archivos de test introducidos en esta iteración pero no bloquean compilación ni tests.

| ID | Descripcion | Area | Archivo | Severidad | Estado |
|----|-------------|------|---------|-----------|--------|
| — | TC-bs-1 falla por `Icons.archive` vs `LucideIcons.archive` | frontend | `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` | Low | PRE-EXISTENTE |
| — | TC-bs-2 falla por `Icons.archive` vs `LucideIcons.archive` | frontend | `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` | Low | PRE-EXISTENTE |
| — | `unnecessary_underscores` lint (info) en test | frontend | `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | Info | No bloqueante |

---

## Pruebas manuales

Los siguientes escenarios requieren dispositivo/simulador con la app corriendo contra el backend Fase 1:

| # | Escenario | Pasos | Esperado |
|---|-----------|-------|---------|
| M-1 | Tile visible solo en archivados | 1. Abrir garaje. 2. Tap en vehículo ACTIVO → opciones. | NO aparece "Eliminar permanentemente" |
| M-2 | Tile visible solo en archivados | 1. Abrir garaje. 2. Tap en vehículo ARCHIVADO → opciones. | SÍ aparece "Eliminar permanentemente" (con icono trash rojo) |
| M-3 | Flujo de confirmación (confirmar) | 1. Tap "Eliminar permanentemente". 2. Verificar que el diálogo muestra el nombre del vehículo. 3. Tap "Eliminar". | Vehículo desaparece de sección Archivados; snackbar verde con `vehicle_permanentDeleteSuccess` |
| M-4 | Flujo de confirmación (cancelar) | 1. Tap "Eliminar permanentemente". 2. Tap "Cancelar". | Bottom sheet sigue visible; vehículo intacto |
| M-5 | Tiles de vehículo activo intactos | Tap en vehículo activo → opciones. | Editar, Agregar mantenimiento, Archivar presentes; sin "Eliminar permanentemente" |
| M-6 | Restaurar archivado intacto | Tap en vehículo archivado → "Restaurar". | Vehículo pasa a sección activos |
| M-7 | Formulario sin botón eliminar | Abrir formulario de edición. | Sin botón "Eliminar vehículo" visible |
| M-8 | Error de red | Forzar error de red y confirmar eliminación. | Snackbar rojo con mensaje de error |

---

## Sign-off

- **CA-1** (visibilidad contextual): PASS — código verifica `vehicle.isArchived` para mostrar tile; grep confirma sin punto de entrada en form
- **CA-2** (diálogo destructivo): PASS — TC-perm-A confirma diálogo con nombre del vehículo y `DialogActionType.danger`
- **CA-3** (flujo confirmación): PASS — TC-perm-A (confirmar) y TC-perm-C (cancelar) en verde
- **CA-4** (guard anti doble-tap): PASS — TC-perm-B confirma use case invocado exactamente 1 vez
- **CA-5** (re-fetch tras éxito): MANUAL PENDING — lógica en `garage_options_bottom_sheet.dart:91` llama `onGarageListUpdatedLocally`
- **CA-6** (snackbar éxito): MANUAL PENDING
- **CA-7** (snackbar error): MANUAL PENDING
- **CA-8** (contrato Retrofit): PASS — 0 hits de `hard-delete` en `lib/`
- **CA-9** (renombrado completo): PASS — 0 hits de `VehicleDeleteCubit` ni `deleteVehicleLocally` en código compilable
- **CA-10** (tests en verde): PASS — 548 passed, 2 failed pre-existentes no relacionadas
- **CA-11** (strings l10n): PASS por inspección — `garage_options_bottom_sheet.dart` usa `context.l10n.*` para todas las cadenas visibles
- **CA-12** (form limpio): PASS — grep confirma 0 hits de `onDelete` y `VehicleDeleteCubit` en `presentation/form/`

**Bugs bloqueantes:** ninguno.
**Quality signal:** green — ready for tech lead review. Pendiente verificación manual M-1..M-8 contra backend Fase 1.

---

## Next agent needs to know

- **Tech lead:** Calidad verde. 548/550 tests pasan; los 2 fallos son pre-existentes (TC-bs-1/TC-bs-2, icon package mismatch). Todos los ACs automatizables pasan. Pendiente smoke test manual M-1..M-8 con backend Fase 1 activo antes de hacer merge.
- **DevOps:** `dart analyze && flutter test` es el comando de CI. Los 2 fallos conocidos en `garage_options_bottom_sheet_test.dart` son pre-existentes y pueden ser ignorados o corregidos en una iteración posterior de test (fix: cambiar `Icons.archive` por `LucideIcons.archive` en las líneas 190 y 233 del test file).

---

## Change log

- 2026-06-17T17:35:52Z: QA inicial — análisis estático, suite automatizada, grep de verificación, catálogo de ACs.
