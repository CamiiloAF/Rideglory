# SUMMARY — Phase 01: Backend soft-delete e integridad de datos

_Generated: 2026-06-16T21:50:10Z_
_Tech Lead: claude-sonnet-4-6_

---

## Objetivo

Implementar soft-delete de vehículos en vehicles-ms y api-gateway para que los usuarios puedan eliminar vehículos del garaje sin destruir el historial de inscripciones a eventos ni registros de mantenimiento. Campo `isDeleted` aditivo en Prisma; filtros en listados del garaje; endpoint autenticado `DELETE /api/vehicles/my/:vehicleId` que orquesta maintenances-ms → vehicles-ms en ese orden.

---

## Qué cambió por área

### Backend — vehicles-ms

- **`prisma/schema.prisma`**: campo `isDeleted Boolean @default(false)` añadido al modelo `Vehicle` después de `isArchived`.
- **`prisma/migrations/20260616183358_add_soft_delete_to_vehicle/migration.sql`**: migración estrictamente aditiva (`ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false`). Sin DROP, RENAME ni sentencias destructivas.
- **`src/vehicles/vehicles.service.ts`**:
  - `findByOwnerId`: añade `isDeleted: false, isArchived: false` al `where` y `omit: { isDeleted: true }` para no exponer el campo al cliente.
  - `findMainVehicleByOwnerId`: añade `isDeleted: false, isArchived: false` al `where`.
  - `create()`: conteo corregido — excluye `isArchived: true` e `isDeleted: true`, asegurando que un vehículo nuevo sea `isMainVehicle: true` cuando todos los anteriores estén archivados/eliminados.
  - Nuevo método `softDeleteVehicle(vehicleId, ownerId)`: ownership check antes de la transacción → `$transaction` (soft-delete + promoción de main canónica si aplica).
  - `findByIdOrNull`: intacto, sin filtro `isDeleted` (snapshots históricos de events-ms preservados).
  - `findOne`: mejora de formato de RpcException (sin cambio funcional).
- **`src/vehicles/vehicles.controller.ts`**: nuevo `@MessagePattern('softDeleteVehicle')` handler.
- **`src/vehicles/vehicles.service.spec.ts`**: creado de cero; 17 tests que ejercitan el `VehiclesService` real con Prisma mockeado via `jest.mock`.

### Backend — api-gateway

- **`src/vehicles/vehicles.controller.ts`**: nuevo endpoint `@Delete('my/:vehicleId')` en línea 103 — antes de `@Get(':id')` (140) y `@Delete('hard-delete/:id')` (169). Orquesta `softDeleteMaintenancesByVehicleId` (maintenances-ms, timeout 15s) → `softDeleteVehicle` (vehicles-ms). Ownership deriva de `getAuthenticatedUser(request).id`.

### Flutter (`lib/`)

Sin cambios. `dart analyze` — no issues. `flutter test` — exit 0.

---

## Archivos

| Repo | Archivo | Estado |
|------|---------|--------|
| `rideglory-api/vehicles-ms` | `prisma/schema.prisma` | Modificado |
| `rideglory-api/vehicles-ms` | `prisma/migrations/20260616183358_add_soft_delete_to_vehicle/migration.sql` | Creado |
| `rideglory-api/vehicles-ms` | `src/vehicles/vehicles.service.ts` | Modificado |
| `rideglory-api/vehicles-ms` | `src/vehicles/vehicles.controller.ts` | Modificado |
| `rideglory-api/vehicles-ms` | `src/vehicles/vehicles.service.spec.ts` | Creado |
| `rideglory-api/api-gateway` | `src/vehicles/vehicles.controller.ts` | Modificado |

---

## Pruebas

- **Jest vehicles-ms** (`vehicles.service.spec.ts`): 17 tests, 17 pasan. Ejercitan el `VehiclesService` real con Prisma mockeado. Cubren: ownership 403 (con guard que verifica que `$transaction` no se invoca), 404, soft vs hard delete, promoción de main con guard de orden `desc`, no-promoción cuando no era main, filtros en `findByOwnerId`/`findMainVehicleByOwnerId`, `findByIdOrNull` sin filtro `isDeleted`, fix de conteo en `create()`, omisión de `isDeleted` en respuesta.
- **TypeScript**: `tsc --noEmit` exit 0 en vehicles-ms y api-gateway.
- **Flutter**: `dart analyze` — no issues; `flutter test` — exit 0.
- **Pruebas manuales**: pendientes (requieren DB local con migración aplicada). Ver REVIEW_CHECKLIST.md.

---

## Riesgos / watchlist

1. **`isDeleted` en respuesta HTTP** — corregido con `omit: { isDeleted: true }` en `findByOwnerId`. Protegido por TC-11. Watchlist: si en el futuro se añaden selects explícitos o DTOs de mapeo, verificar que `isDeleted` no reaparezca.
2. **Orden de rutas api-gateway** — `@Delete('my/:vehicleId')` en línea 103 precede a `@Get(':id')` (140) y `@Delete('hard-delete/:id')` (169). Sin `@Delete(':id')` genérico que pudiera interceptar.
3. **`findByIdOrNull` sin filtro** — verificado: `where: { id }` únicamente. Guardrail protegido por TC-08.
4. **hard-delete intacto** — línea 169 del api-gateway controller; no modificado.
5. **Migración en entorno remoto** — ejecutar `prisma migrate dev` localmente, verificar SQL, luego desplegar. No desplegar sin verificación humana.
6. **`isArchived` no en omit** — `findByOwnerId` usa `omit: { isDeleted: true }` pero no omite `isArchived`. Campo ya existente en la API; comportamiento consistente con lo anterior.

---

## Mensaje de commit sugerido

```
feat(vehicles-ms,api-gateway): soft-delete de vehículos con integridad referencial

- Campo isDeleted en schema Prisma (migración aditiva 20260616183358)
- softDeleteVehicle(): ownership check + $transaction (soft-delete + promoción de main)
- Filtros isDeleted/isArchived en findByOwnerId y findMainVehicleByOwnerId
- omit isDeleted en respuesta HTTP de GET /api/vehicles/my
- Fix: create() cuenta solo vehículos activos para isMainVehicle
- MessagePattern 'softDeleteVehicle' en vehicles.controller.ts
- Endpoint DELETE /api/vehicles/my/:vehicleId en api-gateway (orquesta maintenances-ms)
- 17 tests Jest (VehiclesService real + Prisma mockeado)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```
