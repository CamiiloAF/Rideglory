# Tech Lead Handoff — flutter-permanent-delete-vehicle

**Date:** 2026-06-17T17:40:07Z
**Reviewer:** Tech Lead (Sonnet)

---

## Veredicto

**READY** — sin blockers. La implementación cumple todos los ACs del PRD. El diff es limpio en las áreas de scope. Se detectaron cambios out-of-scope (benignos) que el humano puede optar por separar en commits distintos.

---

## Hallazgos

| # | Severidad | Archivo | Descripción |
|---|-----------|---------|-------------|
| 1 | Info | `lib/l10n/app_es.arb` | `vehicle_permanentDeleteCancel` = "Cancelar" es idéntico al key global `cancel`. No rompe nada; es l10n bloat. Considerar usar `context.l10n.cancel` en su lugar en una iteración futura. |
| 2 | Info | `garage_options_bottom_sheet.dart:82-91` | En `permanentDeleteSuccess` no hay `if (!parentContext.mounted)` antes de `ScaffoldMessenger.of(parentContext)`. Es el mismo patrón que `archiveSuccess`/`unarchiveSuccess` en el mismo listener (consistente con el resto del archivo). `parentContext` es la página del garaje y permanece montada tras pop del sheet. Riesgo práctico: nulo. |
| 3 | Info | Out-of-scope | `useRootNavigator: true` en 8 bottom sheets, autofill en `AppTextField`, fix de validación de fechas SOAT/RTM, `DocumentValidityCard` en Tecnomecánica, y mejoras CI — todos benignos, pero ajenos al scope de esta fase. Considerar commits separados. |
| 4 | Info | `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | 2 warnings `unnecessary_underscores` (lint info) introducidos en archivos de test. No bloquean compilación ni CI. |

---

## Seguridad

- Sin secretos ni PII expuestos en logs ni en código.
- El endpoint `DELETE /api/vehicles/my/{id}` usa `ApiRoutes.myVehicles` (ruta autenticada via Firebase Auth interceptor, sin concatenación manual de SQL ni URLs hardcodeadas).
- No se pasan DTOs a la capa de presentación. La capa de dominio no importa Flutter.
- El guard `if (state is _Loading) return` previene condición de carrera ante doble-tap.
- `if (confirm != true || !parentContext.mounted) return` antes de llamar al cubit: correcto.

---

## Arquitectura

- Clean Architecture respetada: dominio sin Flutter, data sin `BuildContext`, presentación sin DTOs ni HTTP directo.
- Un widget por archivo: `GarageOptionsBottomSheet` es la única clase widget en su archivo.
- No se usaron métodos que retornen widgets.
- `VehicleActionCubit` correctamente marcado `@injectable` (no `@singleton`); se provee via `getIt<VehicleActionCubit>()..reset()` en `show()` y `BlocProvider.value` en el sheet — patrón correcto.
- Re-fetch completo (`fetchMyVehicles()`) en lugar de mutación local: correcto dado que la eliminación permanente invalida el estado local.
- Retrofit apunta a `ApiRoutes.myVehicles/{id}` (DELETE) — contrato correcto según PRD §8.
- `VehicleDeleteCubit` eliminado limpiamente del DI container.

---

## Tests

| ID | AC | Resultado |
|----|-----|-----------|
| TC-perm-A | CA-1/2/3 — diálogo aparece con nombre y estilo danger | PASS |
| TC-perm-B | CA-4 — guard anti doble-tap, use case llamado exactamente 1 vez | PASS |
| TC-perm-C | CA-3 — cancelar no llama al use case | PASS |
| TC-veh-1..15 | Regresión vehicle_cubit_test | PASS |
| CA-5,6,7,11 | re-fetch, snackbars, l10n en contexto | Pendiente manual |
| TC-bs-1/2 | Pre-existentes (icon package mismatch) | FAIL pre-existente |

Grep de verificación post-implementación: `deleteVehicle`, `DeleteVehicleUseCase`, `VehicleDeleteCubit`, `deleteVehicleLocally` → 0 hits en código compilable. `hard-delete` → 0 hits.

---

## Pruebas manuales

Requieren backend Fase 1 (`DELETE /api/vehicles/my/:vehicleId`) activo:

| # | Escenario | Esperado |
|---|-----------|---------|
| M-1 | Vehículo activo → opciones | Sin "Eliminar permanentemente" |
| M-2 | Vehículo archivado → opciones | "Eliminar permanentemente" visible (rojo) |
| M-3 | Confirmar eliminación | Vehículo desaparece; snackbar verde |
| M-4 | Cancelar diálogo | Vehículo intacto |
| M-5 | Activo → Editar/Mantenimiento/Archivar | Sin regresión |
| M-6 | Archivado → Restaurar | Vehículo regresa a activos |
| M-7 | Formulario de edición | Sin botón "Eliminar vehículo" |
| M-8 | Error de red + confirmar | Snackbar rojo con mensaje de error |
