# Architect Review — archive-vehicle-soft-delete

_Generated: 2026-06-16T16:12:07Z_
_Status: done_

---

## Validación por fase

### Fase 1 — Backend: soft-delete e integridad de datos

**Viabilidad:** VIABLE. Complejidad **media**.

El schema Prisma no tiene `isDeleted` — se requiere migración nueva. Todo lo demás (lógica de `remove()`, filtros, endpoint HTTP) es código NestJS sin bloqueos externos.

**Análisis detallado:**

| Tarea | Esfuerzo | Notas |
|-------|----------|-------|
| Añadir `isDeleted Boolean @default(false)` al schema | Bajo | Nueva migración SQL; filas existentes arrancan en `false` — sin riesgo de datos |
| Convertir `remove()` de hard-delete a soft-delete | Bajo | Cambiar `tx.vehicle.delete()` → `tx.vehicle.update({ data: { isDeleted: true } })`; preservar lógica de promoción de main |
| Filtrar `findByOwnerId`: excluir `isArchived: true` y `isDeleted: true` | Bajo | Añadir `where` clause |
| Filtrar `findMainVehicleByOwnerId`: excluir `isArchived: true` | Bajo | Añadir `isArchived: false` al `where` |
| Corregir `create()`: conteo excluye archivados y eliminados | Bajo | `count({ where: { ownerId, isArchived: false, isDeleted: false } })` |
| Cambiar la promoción de main en `remove()` para excluir archivados | Bajo | `findFirst({ where: { ownerId, isArchived: false, isDeleted: false } })` |
| Nuevo endpoint HTTP `DELETE /api/vehicles/my/:vehicleId` | Medio | Autenticado (igual que los otros `my/*`); encadena `softDeleteMaintenancesByVehicleId` antes de soft-delete; reutiliza el RPC a maintenances-ms ya presente en `hardDelete` |
| Mantener `DELETE /api/vehicles/hard-delete/:id` | Bajo | Conservarlo temporalmente como alias o eliminarlo tras coordinar con Flutter |

**Decisión de ruta del endpoint:** El nuevo endpoint de eliminación permanente debe ser `DELETE /api/vehicles/my/:vehicleId` (autenticado, protegido por ownership) en lugar de `DELETE /api/vehicles/hard-delete/:id` (sin autenticación de owner). El endpoint `hard-delete` puede quedar como interno (sin exposición) o eliminarse. El Flutter client (`VehicleService`) debe actualizar la ruta.

**`findByIdOrNull` (usado por events-ms):** NO debe recibir filtro `isDeleted`. Un vehículo soft-deleted sigue necesitando ser encontrado para snapshots históricos. Sin cambios aquí.

**Contratos:** No se necesita `isDeleted` en `CreateVehicleDto`/`UpdateVehicleDto` — el campo es gestionado exclusivamente por el backend.

**Prerrequisito de Fase 4 (Flutter):** Fase 4 depende del endpoint `DELETE /api/vehicles/my/:vehicleId` creado aquí. Confirmar URL antes de que Flutter implemente.

---

### Fase 2 — Diseño Pencil: garaje con sección de archivados

**Viabilidad:** VIABLE. Complejidad **baja**.

Es una fase de diseño puro — sin código de producción. No hay riesgo técnico, pero sí un riesgo de proceso: si el MCP de Pencil está caído, la fase se bloquea.

**Frames requeridos (mínimo):**
1. Garaje — lista activa + sección "Archivados (N)" colapsada
2. Garaje — sección "Archivados (N)" expandida mostrando vehículos archivados con su card diferenciada (opacidad reducida, chip "Archivado")
3. Bottom sheet de opciones — vehículo activo: "Establecer como principal" (condicional), "Editar", "Agregar mantenimiento", "Archivar", sin "Eliminar"
4. Bottom sheet de opciones — vehículo archivado: "Restaurar", "Eliminar permanentemente" (destructivo, color rojo/error)
5. Diálogo de confirmación de archivado (informativo: historial se conserva)
6. Diálogo de confirmación de eliminación permanente (destructivo, irreversible)

**Ajuste arquitectónico:** El diseñador debe definir el comportamiento del card de vehículo archivado. La recomendación es usar el `VehicleCard` existente con modificaciones visuales (opacidad o chip de estado) en lugar de crear un widget nuevo, para no duplicar lógica.

**Bloqueante para Fase 3:** Ningún widget nuevo se implementa hasta que el PO apruebe explícitamente los frames.

---

### Fase 3 — Flutter: archivar y restaurar vehículos

**Viabilidad:** VIABLE. Complejidad **media**.

El backend (PATCH via `ArchiveVehicleUseCase`) ya funciona. El trabajo es puramente Flutter: wiring de callbacks huérfanos, nuevos métodos en `VehicleCubit`, widget de sección archivados, bifurcación del bottom sheet.

**Análisis de componentes afectados:**

| Componente | Cambio requerido |
|-----------|-----------------|
| `VehicleCubit` | Añadir `archiveVehicle(String id)` y `unarchiveVehicle(String id)` que llaman `ArchiveVehicleUseCase`/`UnarchiveVehicleUseCase` + `archiveLocally(String id)` y `unarchiveLocally(String id)` para mutación local optimista |
| `VehicleCubit.currentVehicle` | Al archivar el main, promover automáticamente al siguiente activo no archivado en local |
| `VehicleCubit.deleteVehicleLocally` (renombrado) | Ya filtra por id; usar como modelo para `archiveLocally` |
| `GarageOptionsBottomSheet` | Bifurcar opciones según `vehicle.isArchived`: activo → "Archivar"; archivado → "Restaurar" + "Eliminar permanentemente". Wiring de callbacks `onArchive` / `onUnarchive` |
| `GarageVehiclesContent` | Añadir sección colapsable "Archivados (N)" al pie. Widget propio (`GarageArchivedSection`) |
| `VehicleCard.onArchive` / `onArchive` callbacks | Pasar desde `GarageOptionsBottomSheet` — NO desde el card directamente |
| `VehicleDeleteCubit` | Ampliar para manejar `archive` y `unarchive`, o crear `VehicleArchiveCubit` separado scoped al bottom sheet |
| l10n (`app_es.arb`) | Claves nuevas: `vehicle_archive`, `vehicle_unarchive`, `vehicle_archivedSection`, `vehicle_archiveConfirmTitle`, `vehicle_archiveConfirmMessage`, `vehicle_archiveConfirmAction`, `vehicle_unarchiveSuccess` |

**Dependencia de Fase 2:** Bloqueada hasta aprobación de diseño Pencil.
**Independencia de Fase 4:** Fase 3 puede completarse e integrarse antes de Fase 4, ya que usa el PATCH existente (no necesita el nuevo endpoint de soft-delete).
**Independencia de Fase 5:** Fase 3 es independiente de Fase 5. Pueden ejecutarse en cualquier orden.

**Cubit de archive — decisión de diseño:** Se recomienda ampliar `VehicleDeleteCubit` → renombrarlo `VehicleActionCubit` con estados para `archive`, `unarchive`, `permanentDelete`. Evita proliferación de cubits scoped. Si el scope aumenta, crear `VehicleArchiveCubit` separado. Decisión final queda al implementador.

**Nota sobre promoción local de main:** Cuando `archiveLocally(id)` es llamado y el vehículo era `isMainVehicle: true`, `VehicleCubit` debe asignar `isMainVehicle: true` al primer vehículo activo no archivado de la lista `_vehicles`. Esto debe ocurrir antes de `_emitLoadedOrEmpty()`.

---

### Fase 4 — Flutter: eliminación permanente desde archivados

**Viabilidad:** VIABLE. Complejidad **media**.

Depende de Fase 1 (endpoint `DELETE /api/vehicles/my/:vehicleId`) y de Fase 3 (menú contextual de archivados ya implementado).

**Componentes nuevos en Flutter:**

| Componente | Descripción |
|-----------|-------------|
| `VehicleRepository.permanentlyDeleteVehicle(String id)` | Nuevo método en la interfaz de dominio |
| `VehicleRepositoryImpl.permanentlyDeleteVehicle` | Llama `VehicleService.permanentlyDeleteVehicle(id)` vía `executeService` |
| `VehicleService.permanentlyDeleteVehicle` (Retrofit) | `@DELETE('${ApiRoutes.myVehicles}/{id}')` — apunta al nuevo endpoint autenticado |
| `PermanentlyDeleteVehicleUseCase` | Simple delegator al repositorio |
| `VehicleCubit.permanentlyDeleteVehicle(String id)` | Llama use case + `deleteVehicleLocally(id)` en éxito |
| `GarageOptionsBottomSheet` | Conectar "Eliminar permanentemente" → cubit scoped → cubit global |
| l10n | `vehicle_permanentDeleteTitle`, `vehicle_permanentDeleteMessage`, `vehicle_permanentDeleteAction`, `vehicle_permanentDeleteSuccess` |

**Ruta Retrofit:** `@DELETE('${ApiRoutes.myVehicles}/{id}')` — verificar que `ApiRoutes.myVehicles` sea `/api/vehicles/my`. Si no, ajustar o añadir constante.

**Patrón de confirmación:** El diálogo de eliminación permanente debe mostrar el nombre del vehículo y descripción irreversible. Usar `ConfirmationDialog` existente en `lib/shared/widgets/modals/`.

**Riesgo de coordinación:** La ruta del endpoint (`/api/vehicles/my/:vehicleId`) debe estar desplegada en backend antes de que el Flutter que consume Fase 4 salga a producción. Opciones: (a) mantener `/api/vehicles/hard-delete/:id` como alias temporal, o (b) coordinar despliegue simultáneo.

---

### Fase 5 — Flutter: vehículo principal siempre coherente

**Viabilidad:** VIABLE. Complejidad **baja**.

El scan ya confirmó que `HomeGarageSection` usa `VehicleCubit` como fuente primaria. El fix es eliminar la dependencia del prop `mainVehicle` de `HomeLoaded`.

**Cambios mínimos:**

| Archivo | Cambio |
|---------|--------|
| `HomeGarageSection` | Eliminar el prop `vehicle` o marcarlo deprecated. Leer `VehicleCubit` como única fuente (ya lo hace como fuente primaria) |
| `HomeScaffold` | Dejar de pasar `state.mainVehicle` a `HomeGarageSection`, o ignorar el prop en el widget |
| `HomeCubit` / `HomeLoaded` / `GetHomeDataUseCase` | Evaluar si `mainVehicle` sigue siendo necesario en el estado de home o puede eliminarse completamente |

**Advertencia:** Eliminar `mainVehicle` de `HomeLoaded` implica un cambio en el estado freezed — requiere regenerar código (`build_runner`). Si `mainVehicle` tiene otros consumidores en `HomeScaffold` que no sean `HomeGarageSection`, el campo debe mantenerse hasta limpiar todos los usos.

**No hay llamadas HTTP adicionales.** Todo es lectura de estado en memoria. `dart analyze` y `flutter test` deben pasar sin cambios de dependencias.

**Puede ejecutarse independientemente de Fases 3 y 4.** Es el cambio de menor riesgo del plan.

---

## Contratos

### Nuevo endpoint: eliminación permanente autenticada

```
DELETE /api/vehicles/my/:vehicleId
Auth: Firebase ID token (Bearer)
Params: vehicleId (UUID)
Body: ninguno
Success: 200 { message: 'Vehicle deleted successfully', status: 200 }
Errors:
  404 — vehicle not found
  403 — vehicle does not belong to authenticated user
  502 — falla al soft-delete mantenimientos (maintenances-ms timeout)
```

**Lógica backend:**
1. Resolver `user` por `request.user.email` → obtener `user.id`
2. `softDeleteMaintenancesByVehicleId({ vehicleId })` vía maintenances-ms (timeout 15s)
3. `softDeleteVehicle({ vehicleId, ownerId: user.id })` vía vehicles-ms
4. En vehicles-ms: verificar ownership, marcar `isDeleted: true`, si era main → promover siguiente activo no archivado

### Cambios en endpoint existente: archive/unarchive

Sin cambios de contrato. El `PATCH /api/vehicles/:id` con `{ isArchived: true/false }` sigue siendo la vía para archivar y restaurar. Validado en producción.

### Cambios en `GET /api/vehicles/my`

El endpoint no cambia su firma. El comportamiento cambia internamente: la respuesta excluye vehículos con `isArchived: true` OR `isDeleted: true`. Los clientes Flutter no requieren cambios para consumirlo.

### Nuevo mensaje RPC vehicles-ms

```typescript
// Pattern: 'softDeleteVehicle'
// Payload: { vehicleId: string, ownerId: string }
// Returns: VehicleEntity (con isDeleted: true)
// Errors: RpcException 404 (not found), 403 (not owner)
```

### Migración Prisma (vehicles-ms)

```sql
-- Nueva migración: add_soft_delete_to_vehicle
ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false;
```

Filas existentes: todas arrancan con `isDeleted = false`. Migración no destructiva.

### Flutter — nueva constante de ruta

Si `ApiRoutes` no tiene una constante para `vehicles/my`, añadir:
```dart
static const myVehiclesBase = '/api/vehicles/my'; // para DELETE /api/vehicles/my/:id
```

Verificar que `ApiRoutes.myVehicles` sea `/api/vehicles/my` — si ya existe, usarla directamente en `@DELETE`.

---

## Riesgos

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R-1 | **Despliegue descoordinado backend/Flutter**: `VehicleService.deleteVehicle` actualmente apunta a `/hard-delete/{id}`. Si el backend cambia la ruta antes de que Flutter actualice, las eliminaciones dan 404 | Media | Alto | Opción A: mantener el alias `hard-delete/:id` hasta que Fase 4 Flutter salga. Opción B: desplegar backend y Flutter simultáneamente. **Recomendación: Opción A** — alias temporal en api-gateway hasta confirmar que Fase 4 está en producción. |
| R-2 | **Migración `isDeleted` en datos existentes**: `prisma migrate dev` → `migrate deploy` en producción con filas existentes | Baja | Alto | Ejecutar `prisma migrate dev` en local primero. Revisar el SQL generado. `DEFAULT false` es seguro — no modifica filas existentes. Desplegar en ventana de bajo tráfico. |
| R-3 | **Promoción de main en local no sincronizada con backend**: Si `archiveLocally` promueve un main distinto al que elegiría el backend, la app muestra un estado inconsistente hasta el próximo `fetchMyVehicles` | Media | Medio | El backend elige el "siguiente por `createdAt desc`". Flutter debe usar la misma lógica en `archiveLocally`. Documentar el criterio de desempate en el handoff de implementación. |
| R-4 | **`VehicleCard.onArchive`/`onUnarchive` huérfanos mal wired**: Si el implementador conecta los callbacks desde `VehicleCard` en lugar de `GarageOptionsBottomSheet`, se genera duplicación de lógica | Baja | Medio | Documentar explícitamente en handoff: el wiring de archive/unarchive ocurre únicamente en `GarageOptionsBottomSheet`. `VehicleCard` solo recibe callbacks (no llama use cases directamente). |
| R-5 | **`findByIdOrNull` recibe filtro `isDeleted` por error**: Un developer añade `isDeleted: false` al `findByIdOrNull` usado por events-ms, rompiendo snapshots históricos | Baja | Alto | Documentar explícitamente: `findByIdOrNull` NO filtra `isDeleted`. Solo `findByOwnerId` y `findMainVehicleByOwnerId` filtran. |
| R-6 | **Pencil MCP caído bloquea Fase 2**: La aprobación de diseño es un gate duro antes de Fase 3 | Media | Medio | No hay mitigación — es una regla del proyecto. Planificar el diseño al inicio del sprint para dar tiempo de reintento. |
| R-7 | **`HomeLoaded.mainVehicle` tiene consumidores ocultos**: Al eliminar el campo en Fase 5, otro widget que lo use puede no compilar | Baja | Medio | Antes de eliminar el campo, ejecutar `grep -rn 'mainVehicle\|HomeLoaded' lib/` para mapear todos los usos. Eliminar o reemplazar antes de regenerar freezed. |
| R-8 | **`updateVehicle` PATCH no incluye `color`**: `VehicleRepositoryImpl._vehicleRequest()` no serializa `color`. Si `archiveLocally` usa `copyWith` y luego el backend refleja un PATCH sin color, puede haber drift de datos | Baja | Bajo | El archivado solo envía `{ isArchived: true/false }` — no pasa por `_vehicleRequest`. `ArchiveVehicleUseCase` llama `updateVehicle(vehicle.copyWith(isArchived: true))`, que en el impl construye el payload con `isArchived`. El campo `color` solo es relevante en edición completa. No bloquea este feature. |

---

## Ajustes

### AJ-1: Endpoint de eliminación permanente — cambiar a ruta autenticada

**Cambio propuesto en Fase 1:** El PO propone convertir `DELETE /api/vehicles/hard-delete/:id` al nuevo endpoint de soft-delete. La recomendación arquitectónica es **crear un endpoint nuevo** `DELETE /api/vehicles/my/:vehicleId` (autenticado, verifica ownership) y mantener `hard-delete/:id` como alias temporal hasta que Fase 4 Flutter salga. Esto elimina el riesgo R-1 de despliegue descoordinado.

**Razón:** El endpoint `hard-delete/:id` no verifica ownership — cualquier token válido puede eliminar cualquier vehículo por id. El nuevo endpoint `my/:vehicleId` resuelve esto inherentemente usando el user del token.

### AJ-2: Añadir criterio de desempate para promoción de main

**Cambio propuesto en Fases 1 y 3:** Tanto el backend como Flutter deben usar el mismo criterio al promover el nuevo vehículo principal tras archivar/eliminar el main. El backend usa `findFirst({ orderBy: { createdAt: 'desc' } })`. Flutter debe replicar esto ordenando `_vehicles` por `createdAt` descendente (filtrando `isArchived: false`) al elegir el sucesor. Documentar en handoff de Fase 3.

### AJ-3: Clarificar semántica de `deleteVehicle` en dominio Flutter

**Cambio propuesto en Fases 3 y 4:** `VehicleRepository.deleteVehicle(String id)` actualmente significa "hard-delete". Con este feature, la semántica cambia a "eliminación permanente desde archivados" (soft-delete en backend). Dos opciones:

- **Opción A (preferida):** Renombrar `deleteVehicle` → `permanentlyDeleteVehicle` en la interfaz de dominio, el repositorio impl, y el use case. Refleja la intención real. Actualizar `VehicleDeleteCubit` para invocar el nuevo método.
- **Opción B:** Mantener el nombre y cambiar solo la URL del Retrofit client. Menos claro semánticamente.

**Recomendación: Opción A.** El costo es mínimo (3 archivos + code-gen) y evita confusión futura.

### AJ-4: Fases 3 y 5 pueden ejecutarse en paralelo si hay capacidad

**Aclaración al plan:** Las Fases 3 y 5 son técnicamente independientes (no comparten archivos conflictivos). Si hay un segundo desarrollador disponible, pueden ejecutarse en paralelo. Si hay un solo desarrollador, recomendación de orden: Fase 5 (baja complejidad, cierra el bug de stale) → Fase 3 → Fase 4.

### AJ-5: `VehicleDeleteCubit` — ampliar en lugar de duplicar

**Cambio propuesto en Fases 3 y 4:** En lugar de crear un `VehicleArchiveCubit` separado, ampliar `VehicleDeleteCubit` (cubit scoped, no singleton) para manejar `archive`, `unarchive`, y `permanentDelete` como acciones distintas en un estado freezed unificado. Nombre sugerido: `VehicleActionCubit` o mantener `VehicleDeleteCubit` con estados ampliados. Evita proliferación de cubits de vida corta.

---

## Secuencia de entrega recomendada

```
Fase 1 (Backend)
    └── [bloqueante para Fase 4]
Fase 2 (Diseño Pencil)
    └── [bloqueante para Fase 3]
Fase 5 (Flutter — home coherente) ← independiente, baja complejidad, mínimo riesgo
Fase 3 (Flutter — archivar/restaurar) ← requiere Fase 2 aprobada
Fase 4 (Flutter — eliminación permanente) ← requiere Fase 1 + Fase 3
```

Fases 1 y 2 pueden ejecutarse en paralelo. Fase 5 puede ir en cualquier momento antes o después de Fases 3/4.
