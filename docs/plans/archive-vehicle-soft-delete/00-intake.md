# Intake — archive-vehicle-soft-delete

_Generated: 2026-06-16T16:04:20Z_

---

## Fuente

Objetivo inlínea provisto por el orquestador de planeación (no es un archivo PRD existente).

---

## Objetivo

Implementar el ciclo de vida completo de vehículos: **archivar** (ocultar del garaje sin perder historial), **soft-delete real** (corrección del Bug 2 — `VehiclesService.remove()` actualmente hace hard delete físico rompiendo inscripciones históricas), y **propagación correcta del vehículo principal** al cambiar el main (evitar que `HomeCubit` quede con datos stale).

---

## Alcance percibido

### Estado actual confirmado (post escaneo)

**Backend — vehicles-ms:**
- `schema.prisma` ya tiene `isArchived Boolean @default(false)` y la migración `0_init` ya la incluye. **No se necesita migración para `isArchived`.**
- **`isDeleted` NO existe** en el schema ni en el servicio. Tampoco en el `Vehicle` entity. Hay que agregarlo.
- `VehiclesService.remove()` hace `tx.vehicle.delete()` — hard delete físico. Es el bug.
- `findByOwnerId` y `findMainVehicleByOwnerId` NO filtran `isArchived: false` actualmente. Hay que agregarlo.
- `findByIdOrNull` y `getVehicleById` (usado por events-ms para `buildVehicleSummary`) NO deben filtrar `isDeleted` (para preservar nombre del vehículo en inscripciones históricas) — actualmente no filtran nada, lo cual es correcto para el caso `isDeleted`. Solo hay que asegurarse de no romperlo.
- El `MessagePattern('hardDeleteVehicle')` en el controller existe. Habrá que añadir `MessagePattern('softDeleteVehicle')` o renombrar el flujo.
- `api-gateway/vehicles.controller.ts` ya orquesta: soft-delete de mantenimientos → hardDelete vehículo. Habrá que añadir el endpoint `DELETE /api/vehicles/:id` para soft-delete (lo que ahora es "archivar definitivamente") vs el actual hardDelete.
- El `maintenances-ms` ya tiene `softDeleteAllByVehicleId` — reutilizable.

**Backend — contracts:**
- `UpdateVehicleDto` ya acepta `isArchived` (viene del `update` path de vehicles). Verificar si `isDeleted` necesita contrato propio o si la eliminación pasa por un endpoint dedicado.

**Flutter:**
- `VehicleModel` ya tiene `isArchived: bool` y `isMainVehicle: bool`. Falta `isDeleted` (no necesario en Flutter — los vehículos eliminados no vuelven al cliente).
- `ArchiveVehicleUseCase` y `UnarchiveVehicleUseCase` ya existen. Ambos delegan a `updateVehicle()` pasando `isArchived: true/false` — correcto, el backend ya persiste `isArchived` vía PATCH.
- `VehicleCubit` NO tiene `archiveVehicle()` ni `unarchiveVehicle()` — hay que agregarlos.
- `VehicleDeleteCubit` llama `deleteVehicle()` que llama `VehicleService.deleteVehicle()` → backend `hardDeleteVehicle`. Hay que cambiar la semántica: el botón "Eliminar" actual debe convertirse en "Archivar". "Eliminar permanentemente" (desde archivados) llamará a un nuevo endpoint.
- `GarageVehiclesContent` ya filtra `!v.isArchived` para la lista activa — correcto. Falta la sección colapsable de archivados.
- `GarageOptionsBottomSheet` tiene opciones: Editar, Agregar mantenimiento, Eliminar. Falta "Archivar" para vehículos activos. Para archivados: "Restaurar" + "Eliminar permanentemente".
- `vehicle_card.dart` ya tiene los hooks `onArchive` / `onUnarchive` en su menú contextual pero no están cableados a ningún cubit.
- `HomeGarageSection` ya lee de `VehicleCubit` directamente (no de `HomeCubit.mainVehicle`). El `HomeCubit` tiene su propia copia `mainVehicle` que queda stale, pero `HomeGarageSection` no la usa — solo la usa el `HomeCubit.loadHomeData()` para analytics. El riesgo real es si alguna pantalla pasa `mainVehicle` desde `HomeLoaded` a un widget. Hay que auditar todos los consumidores de `HomeLoaded.mainVehicle`.
- `VehicleCubit.setMainVehicle()` ya actualiza el estado local en memoria. `HomeCubit` no se suscribe a `VehicleCubit`. Posible fix: que `HomeCubit` exponga un método `syncMainVehicle(VehicleModel)` que `VehicleCubit` (o el widget) llame después del set, o que los widgets que muestran el main lean siempre de `VehicleCubit`.

### Entregables por fase (propuesta preliminar)

| # | Fase | Repositorio(s) |
|---|------|----------------|
| 1 | **Backend: soft-delete + filtros** | `vehicles-ms`, `api-gateway`, `rideglory-contracts` |
| 2 | **Flutter: archive/unarchive cableado + sección archivados en garaje** | `Rideglory` (Flutter) |
| 3 | **Flutter: eliminar permanentemente desde archivados + VehicleCubit.deleteVehicle semántica** | `Rideglory` (Flutter) |
| 4 | **Flutter: propagación del vehículo principal (HomeCubit stale fix)** | `Rideglory` (Flutter) |

### Archivos clave por fase

**Fase 1 — Backend:**
- `vehicles-ms/prisma/schema.prisma` — agregar `isDeleted Boolean @default(false)`
- `vehicles-ms/prisma/migrations/<ts>_add_is_deleted_vehicle/migration.sql` — nueva migración
- `vehicles-ms/src/vehicles/vehicles.service.ts` — `remove()` → soft delete; `findByOwnerId()` + `findMainVehicleByOwnerId()` → filtrar `isArchived: false, isDeleted: false`; `create()` → excluir archivados/eliminados del conteo
- `vehicles-ms/src/vehicles/vehicles.controller.ts` — renombrar `hardDeleteVehicle` → `softDeleteVehicle`; añadir nuevo `hardDeleteVehicle` (solo para admin, o eliminar si no se necesita)
- `rideglory-contracts/src/vehicles/` — nuevo DTO si aplica
- `api-gateway/src/vehicles/vehicles.controller.ts` — endpoint `DELETE /api/vehicles/:id` ahora llama `softDeleteVehicle`; verificar que `getVehicleById` (para events-ms) no filtre `isDeleted`

**Fase 2 — Flutter archive UI:**
- `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` — `archiveVehicle()`, `unarchiveVehicle()`, `archiveVehicleLocally()`
- `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` — sección colapsable "Archivados (N)"
- `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` — opciones contextuales por estado (activo / archivado)
- Nuevos widgets: `GarageArchivedSection`, `GarageArchivedVehicleItem`
- `lib/l10n/app_es.arb` — claves nuevas

**Fase 3 — Flutter delete permanente:**
- `VehicleCubit` — método `permanentlyDeleteVehicle()`
- `VehicleDeleteCubit` — adaptar a nueva semántica (ahora solo se invoca desde la vista de archivados)
- `GarageOptionsBottomSheet` — diferencia entre archivado vs activo

**Fase 4 — HomeCubit stale:**
- `lib/features/home/presentation/cubit/home_cubit.dart` — exponer `syncMainVehicle(VehicleModel?)`
- `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` — llamar `homeCubit.syncMainVehicle()` o pasar callback tras `setMainVehicle()`
- Auditar todos los `HomeLoaded.mainVehicle` consumers en `lib/features/home/`

---

## Preguntas abiertas

1. **Endpoint de archive explícito vs PATCH genérico:** Actualmente `ArchiveVehicleUseCase` llama `updateVehicle()` que hace `PATCH /api/vehicles/:id` con `{ isArchived: true }`. Esto ya funciona. ¿Es preferible un endpoint dedicado `POST /api/vehicles/:id/archive` o se mantiene el PATCH? El PATCH es suficiente si el backend lo acepta — confirmar.

2. **Semántica del botón "Eliminar" actual:** ¿El CTA actual "Eliminar vehículo" en `GarageOptionsBottomSheet` debe convertirse directamente en "Archivar"? ¿O debe existir un flujo de 2 pasos: Archivar → luego Eliminar permanentemente desde archivados? Según el objetivo, parece que sí: **eliminar = archivar primero**, y la opción de borrado permanente solo aparece en la sección de archivados. Asumir esto como correctó para el plan.

3. **`isDeleted` en contrato de respuesta al cliente:** ¿Flutter necesita ver `isDeleted: true` en algún momento? Probablemente no — los vehículos eliminados no llegan al cliente en `getMyVehicles()`. Confirmar que `VehicleModel` no necesita ese campo.

4. **Propagación del main en HomeCubit:** ¿La solución preferida es (a) `HomeCubit.syncMainVehicle()` llamado desde `VehicleCubit` (acoplamiento entre cubits) o (b) que todos los widgets lean siempre de `VehicleCubit` y `HomeCubit.mainVehicle` quede deprecado? Opción (b) parece más limpia pero puede requerir refactor de la pantalla home.

5. **Vehículo principal archivado:** Si el usuario archiva su vehículo principal, ¿qué pasa? El backend debería promover automáticamente el siguiente vehículo activo como principal. Definir esta lógica en la Fase 1 (similar a lo que hace `remove()` actualmente con `wasMain`).

6. **`color` en el modelo:** `VehicleModel` tiene `color` pero el `_vehicleRequest()` en `VehicleRepositoryImpl` no lo incluye. Esto es una inconsistencia existente, no bloqueante para este plan pero vale la pena anotar.

7. **Diseño Pencil:** Este feature incluye UI nueva (sección de archivados en el garaje, opciones contextuales diferenciadas). Según las reglas del proyecto, se debe diseñar en Pencil y esperar aprobación antes de implementar la Fase 2. ¿Confirmar que esto aplica para las fases de UI?
