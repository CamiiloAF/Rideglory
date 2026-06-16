# Scan — archive-vehicle-soft-delete

_Generated: 2026-06-16T16:08:05Z_

---

## Inventario Flutter

### Feature: vehicles

**Domain**
- `VehicleModel` — tiene `isArchived: bool` (default `false`) e `isMainVehicle: bool`. **No tiene `isDeleted`** — confirmado correcto, los eliminados no vuelven al cliente.
- `VehicleRepository` — interfaz con `getMyVehicles`, `setMainVehicle`, `addVehicle`, `updateVehicle`, `deleteVehicle`, `uploadVehicleImage`, `upsertSoat`, `getSoat`. **Falta** método `permanentlyDeleteVehicle` (o la semántica de `deleteVehicle` debe cambiar).
- `ArchiveVehicleUseCase` — existe; llama `repository.updateVehicle(vehicle.copyWith(isArchived: true))`. Listo.
- `UnarchiveVehicleUseCase` — existe; llama `repository.updateVehicle(vehicle.copyWith(isArchived: false))`. Listo.
- `DeleteVehicleUseCase` — existe; delega a `repository.deleteVehicle(vehicleId)` → actualmente equivale a hard-delete. Necesita renombrarse o bifurcarse.

**Data**
- `VehicleDto extends VehicleModel` — Pattern B correcto. No incluye `isDeleted` (OK).
- `VehicleService` (Retrofit) — tiene `deleteVehicle` apuntando a `DELETE /api/vehicles/hard-delete/{id}`. **Falta** el endpoint `DELETE /api/vehicles/{id}` para soft-delete real cuando llegue.
- `VehicleRepositoryImpl.deleteVehicle` — delega sin cambios. `_vehicleRequest()` incluye `isArchived` pero no `color` (inconsistencia existente, no bloqueante).
- `VehicleRepositoryImpl.updateVehicle` — ya construye el payload con `isArchived`, que es la vía que usan Archive/Unarchive use cases vía PATCH. Funciona hoy.

**Presentation**
- `VehicleCubit` — `@injectable`, `Cubit<ResultState<List<VehicleModel>>>`. Tiene `deleteVehicleLocally`, `applySavedVehicleEdit`, `setMainVehicle`, `addVehicleLocally`. **Faltan**: `archiveVehicle()`, `unarchiveVehicle()`, `archiveLocally()`, `unarchiveLocally()`.
- `VehicleDeleteCubit` — llama `DeleteVehicleUseCase` → hard-delete. Semántica a cambiar: "eliminar" del garaje pasa a "archivar"; "eliminar permanentemente" se añade para archivados.
- `GarageVehiclesContent` — filtra `!v.isArchived` para la lista activa (correcto). **Falta** la sección colapsable de archivados.
- `GarageOptionsBottomSheet` — menú actual: "Establecer como principal" (si no es main), "Editar", "Agregar mantenimiento", "Eliminar". **Falta** bifurcación por estado: activos → "Archivar"; archivados → "Restaurar" + "Eliminar permanentemente".
- `VehicleCard` — ya tiene `onArchive` y `onUnarchive` callbacks declarados y ramificados por `vehicle.isArchived`, pero **ningún sitio los pasa** (están desconectados).

### Feature: home

- `HomeCubit` / `HomeState` — `HomeLoaded` tiene `mainVehicle: VehicleModel?` cargado desde `GetHomeDataUseCase`. No se actualiza cuando `VehicleCubit` cambia de main.
- `HomeGarageSection` — **ya lee de `VehicleCubit`** directamente (ignora `state.mainVehicle` de `HomeCubit` si hay datos en el cubit): `vehicleState is Data<List<VehicleModel>> ? vehicleState.data.where(v.isMainVehicle).firstOrNull ?? vehicleState.data.firstOrNull : vehicle` (fallback al prop recibido de `HomeScaffold`).
- `HomeScaffold` — pasa `state.mainVehicle` al `HomeGarageSection` como prop de fallback. El riesgo de stale es solo en el caso inicial (antes de que `VehicleCubit` cargue) o si el cubit tiene `empty()`/`error()`.
- **Impacto real del stale**: cuando `VehicleCubit` tiene datos, `HomeGarageSection` los ignora y usa el cubit. El prop de `HomeLoaded.mainVehicle` solo actúa como fallback. El fix más limpio es que `HomeGarageSection` siempre lea del cubit y que el prop quede deprecado (o eliminado).

### Otros features relevantes

- `event_registration` — usa `vehicleSummary` (snapshot al momento de inscripción). El `getVehicleById` en events-ms llama `findByIdOrNull` sin filtrar `isDeleted` → correcto, preserva datos históricos.
- `maintenance` / `soat` / `tecnomecanica` — se ven afectados indirectamente: al archivar un vehículo, sus mantenimientos y docs siguen activos. Al eliminar permanentemente, maintenances-ms ya tiene `softDeleteAllByVehicleId`.

### Artefactos de diseño

- `docs/design/` existe pero solo contiene `html-mockups/` — no hay mocks actualizados para el flujo de archivado/garaje archivados.
- `docs/handoffs/design.md` no existe.
- Según las reglas del proyecto, **las fases con UI nueva requieren diseño en Pencil aprobado antes de implementar**. Aplica a Fase 2 (sección archivados en garaje, opciones contextuales diferenciadas).

---

## Dependencias

Relevantes para este feature (del `pubspec.yaml`):

| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter_bloc` / `bloc` | ^9.1.1 / ^9.1.0 | State management (Cubits) |
| `freezed_annotation` / `freezed` | ^3.1.0 / ^3.2.3 | Modelos inmutables, estados |
| `injectable` / `injectable_generator` | ^2.7.1+2 / ^2.7.1 | DI (cubits y use cases) |
| `retrofit` / `retrofit_generator` | ^4.9.2 / ^10.2.5 | Retrofit client para VehicleService |
| `dartz` | cualquier | Either para errores de dominio |
| `go_router` | ^17.0.0 | Navegación entre pantallas |

No se necesitan nuevas dependencias para este feature.

---

## Superficie rideglory-api

### vehicles-ms

| Pattern (microservicio) | Propósito | Estado actual |
|------------------------|-----------|---------------|
| `createVehicle` | Crea vehículo; auto-asigna `isMainVehicle: true` si es el primero | Correcto; no filtra `isArchived` en el conteo — **bug menor** (vehículo archivado cuenta, podría asignar main a uno nuevo incorrectamente si el único activo está archivado) |
| `findVehiclesByOwnerId` | Lista vehículos del owner — **no filtra** `isArchived: false` | **Falta filtro** |
| `findMainVehicleByOwnerId` | Busca vehículo con `isMainVehicle: true` — **no filtra** `isArchived: false` | **Falta filtro** (puede devolver un vehículo archivado como principal) |
| `setMainVehicleForOwner` | Actualiza `isMainVehicle` en transacción | OK |
| `updateVehicle` | `PATCH` genérico — acepta `isArchived` vía `UpdateVehicleDto` | OK — esta es la vía actual de archive/unarchive |
| `hardDeleteVehicle` | `tx.vehicle.delete()` — hard delete físico con promoción de main | **Bug**: rompe inscripciones históricas. Debe convertirse en soft-delete |
| `getVehicleById` (`findByIdOrNull`) | Usado por events-ms para `buildVehicleSummary` — no filtra `isDeleted` | Correcto — no tocar |

**Schema Prisma (`vehicles-ms`):**
- `isArchived Boolean @default(false)` — ya existe, no se necesita migración.
- `isDeleted` — **no existe** en schema ni entity. Necesita: campo en schema, nueva migración SQL, lógica en `remove()`.

### api-gateway

| Endpoint HTTP | Método | Propósito | Estado |
|--------------|--------|-----------|--------|
| `GET /api/vehicles/my` | `findVehiclesByOwnerId` | Lista vehículos del usuario | OK — hereda el bug de filtrado del MS |
| `POST /api/vehicles/my` | `createVehicle` | Crea vehículo autenticado | OK |
| `PUT /api/vehicles/my/:vehicleId/main` | `setMainVehicleForOwner` | Cambia vehículo principal | OK |
| `PATCH /api/vehicles/:id` | `updateVehicle` | Actualización genérica (incluye isArchived) | OK — vía de archive/unarchive |
| `DELETE /api/vehicles/hard-delete/:id` | soft-delete maintenances → `hardDeleteVehicle` | Hard delete físico | **Bug** — target para Fase 1 |
| `GET /api/vehicles/:id` | `findOneVehicle` | Admin/lookup | OK |

**Contratos (`rideglory-contracts`):**
- `CreateVehicleDto` — tiene `isArchived?: boolean` (opcional). OK.
- `UpdateVehicleDto extends PartialType(CreateVehicleDto)` — hereda `isArchived`. OK para PATCH de archive/unarchive.
- **No existe DTO específico para `isDeleted`** — el soft-delete vía endpoint dedicado no necesita DTO propio (el endpoint solo necesita el `id` en la URL).

### maintenances-ms

- `softDeleteMaintenancesByVehicleId` — ya existe y está publicado como `MessagePattern`. Reutilizable en el nuevo soft-delete de vehículo.

---

## Gap Analysis

| Componente | Estado | Qué falta |
|-----------|--------|-----------|
| `VehicleModel.isArchived` | **Implemented** | — |
| `ArchiveVehicleUseCase` / `UnarchiveVehicleUseCase` | **Implemented** | No están wired en ningún cubit (huérfanos) |
| `VehicleCubit.archiveVehicle()` / `unarchiveVehicle()` | **Not started** | Métodos + mutación local del estado |
| `GarageVehiclesContent` sección archivados | **Not started** | Widget colapsable "Archivados (N)" |
| `GarageOptionsBottomSheet` bifurcado por estado | **Not started** | Opciones contextuales: activo vs archivado |
| `VehicleCard.onArchive` / `onUnarchive` wiring | **Partial** | Callbacks existen pero no se pasan desde ningún parent |
| `VehicleCubit.permanentlyDeleteVehicle()` | **Not started** | Nuevo método + nuevo endpoint en VehicleService |
| `VehicleService.softDeleteVehicle()` | **Not started** | Nuevo método Retrofit → `DELETE /api/vehicles/:id` |
| `VehicleRepository.permanentlyDeleteVehicle()` | **Not started** | Nuevo método de interfaz e implementación |
| `HomeGarageSection` stale fix | **Partial** | Ya lee de `VehicleCubit` como fuente primaria; prop fallback de `HomeLoaded.mainVehicle` puede quedar obsoleto/deprecado |
| Schema Prisma `isDeleted` | **Not started** | Campo + migración en vehicles-ms |
| `VehiclesService.remove()` soft-delete | **Not started** | Cambiar `tx.vehicle.delete()` → `tx.vehicle.update({ isDeleted: true })` + lógica de main promotion |
| `findVehiclesByOwnerId` filtro `isDeleted: false, isArchived: false` | **Not started** | Agregar filtro en vehicles-ms |
| `findMainVehicleByOwnerId` filtro `isArchived: false` | **Not started** | Agregar filtro en vehicles-ms |
| `create()` conteo excluir archivados/eliminados | **Not started** | `count({ where: { ownerId, isArchived: false, isDeleted: false } })` |
| api-gateway `DELETE /api/vehicles/:id` (soft) | **Not started** | Nuevo endpoint que llama `softDeleteVehicle` en MS |
| api-gateway `DELETE /api/vehicles/hard-delete/:id` semántica | **Not started** | Renombrar/redirigir al soft-delete o eliminar |
| l10n claves para archivado/eliminación permanente | **Partial** | `vehicle_archiveVehicle`, `vehicle_unarchiveVehicle`, `vehicle_archivedVehicle`, `vehicle_archivedVehicleMessage` existen. Faltan: confirmación de archivado, "Eliminar permanentemente", sección archivados header, feedback de restauración |
| Diseño Pencil para sección archivados | **Not started** | Requerido antes de Fase 2 UI |

---

## Patrones

1. **Archive vía PATCH genérico**: `ArchiveVehicleUseCase` llama `updateVehicle()` → `PATCH /api/vehicles/:id` con `{ isArchived: true }`. Ya funciona en backend. No se necesita endpoint dedicado para archive/unarchive.

2. **Hard-delete → soft-delete**: El endpoint actual `DELETE /api/vehicles/hard-delete/:id` debe convertirse en `DELETE /api/vehicles/:id` con semántica soft-delete (`isDeleted: true`). El Flutter client ya apunta a `/hard-delete/{id}` — hay que cambiar la ruta en `VehicleService`.

3. **Local state mutation pattern** en `VehicleCubit`: operaciones `deleteVehicleLocally`, `addVehicleLocally`, `applySavedVehicleEdit` — seguir el mismo patrón para `archiveLocally` / `unarchiveLocally`.

4. **`VehicleDeleteCubit` como cubit auxiliar scoped**: Se instancia con `getIt<VehicleDeleteCubit>()..reset()` dentro del bottom sheet (no es singleton global). Patrón a replicar para un eventual `VehicleArchiveCubit` — o ampliar `VehicleDeleteCubit` para manejar ambas operaciones.

5. **`HomeGarageSection` ya es resiliente**: Lee de `VehicleCubit` como fuente primaria. El prop `vehicle` de `HomeLoaded` actúa solo como fallback cuando el cubit no tiene datos. El fix de Fase 4 puede ser simplemente eliminar ese prop y que el widget lea siempre del cubit.

6. **Pattern B obligatorio**: Cualquier DTO nuevo (p.ej. si se necesita un response DTO para el soft-delete) debe extender el model de dominio, no usar `toModel()`.

---

## Implicaciones para el plan

1. **Fase 1 (Backend) es prerequisito bloqueante**: Sin `isDeleted` en schema + `remove()` convertido a soft-delete + filtros en `findByOwnerId` + nuevo endpoint HTTP `DELETE /api/vehicles/:id`, la Fase 3 (eliminación permanente desde Flutter) no puede completarse. Las Fases 2 y 4 de Flutter sí pueden desarrollarse en paralelo o antes, ya que solo dependen del PATCH existente.

2. **Fase 2 requiere diseño Pencil primero**: La sección colapsable de archivados y el menú contextual bifurcado son UI nueva no diseñada. Según las reglas del proyecto, se debe diseñar en Pencil y esperar aprobación antes de implementar. El diseñador debe incluir: (a) sección "Archivados (N)" colapsable al pie del garaje, (b) menú de opciones para vehículo activo (Archivar en lugar de Eliminar), (c) menú de opciones para vehículo archivado (Restaurar + Eliminar permanentemente).

3. **`VehicleCard.onArchive`/`onUnarchive` están huérfanos**: Los callbacks ya existen en el widget pero ningún parent los pasa. El wiring debe hacerse en `GarageOptionsBottomSheet` y/o `GarageVehiclesContent`, no en el card directamente.

4. **Stale de `HomeCubit.mainVehicle` es menor**: `HomeGarageSection` ya prioriza `VehicleCubit`. El verdadero fix es eliminar la dependencia del prop en `HomeScaffold → HomeGarageSection`, haciendo que la sección sea completamente autónoma. No es bloqueante para ninguna otra fase.

5. **Contratos no necesitan cambios para archive**: `UpdateVehicleDto` ya acepta `isArchived`. Solo se necesita un nuevo endpoint de soft-delete en el gateway (sin DTO nuevo) y el campo `isDeleted` en `CreateVehicleDto`/schema (solo backend, no Flutter).
