> Slim handoff — read this before handoffs/architect.md

# Architect → Backend — Phase 01: soft-delete de vehículos

**Date:** 2026-06-16T18:29:16Z

---

## 1. Prisma schema (vehicles-ms)

File: `vehicles-ms/prisma/schema.prisma`

Add inside `model Vehicle`, after `isArchived`:

```prisma
isDeleted  Boolean  @default(false)
```

Then run: `prisma migrate dev --name add_soft_delete_to_vehicle`
Verify generated SQL is strictly: `ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false`

---

## 2. VehiclesService changes (vehicles-ms/src/vehicles/vehicles.service.ts)

### 2a. New method `softDeleteVehicle`

```typescript
async softDeleteVehicle(vehicleId: string, ownerId: string) {
  const existing = await this.vehicle.findUnique({ where: { id: vehicleId } });

  if (!existing) {
    throw new RpcException({ status: HttpStatus.NOT_FOUND, message: `Vehicle with id ${vehicleId} not found` });
  }
  if (existing.ownerId !== ownerId) {
    throw new RpcException({ status: HttpStatus.FORBIDDEN, message: 'Vehicle not found or does not belong to this owner' });
  }

  return this.$transaction(async (tx) => {
    const deleted = await tx.vehicle.update({
      where: { id: vehicleId },
      data: { isDeleted: true, isMainVehicle: false },
    });

    if (existing.isMainVehicle) {
      const next = await tx.vehicle.findFirst({
        where: { ownerId, isArchived: false, isDeleted: false },
        orderBy: { createdAt: 'desc' },
      });
      if (next) {
        await tx.vehicle.update({ where: { id: next.id }, data: { isMainVehicle: true } });
      }
    }

    return deleted;
  });
}
```

### 2b. Fix `findByOwnerId`

```typescript
findByOwnerId(ownerId: string) {
  return this.vehicle.findMany({
    where: { ownerId, isDeleted: false, isArchived: false },
    orderBy: { createdAt: 'desc' },
  });
}
```

### 2c. Fix `findMainVehicleByOwnerId`

```typescript
findMainVehicleByOwnerId(ownerId: string) {
  return this.vehicle.findFirst({
    where: { ownerId, isMainVehicle: true, isDeleted: false, isArchived: false },
  });
}
```

### 2d. Fix `create()` count query (bug)

```typescript
const existingCount = await this.vehicle.count({
  where: { ownerId: createVehicleDto.ownerId, isArchived: false, isDeleted: false },
});
```

### 2e. `findByIdOrNull` — NO TOCAR

This method MUST remain without any `isDeleted` filter. Historical snapshots from events-ms depend on this.

---

## 3. VehiclesController (vehicles-ms/src/vehicles/vehicles.controller.ts)

Add new MessagePattern:

```typescript
@MessagePattern('softDeleteVehicle')
softDeleteVehicle(@Payload() payload: { vehicleId: string; ownerId: string }) {
  return this.vehiclesService.softDeleteVehicle(payload.vehicleId, payload.ownerId);
}
```

---

## 4. API Gateway (api-gateway/src/vehicles/vehicles.controller.ts)

Add NEW endpoint. CRITICAL: declare this route **before** `@Delete(':id')` and before `@Delete(':vehicleId/soat')` / `@Delete(':vehicleId/tecnomecanica')`.

```typescript
@Delete('my/:vehicleId')
async softDeleteMyVehicle(
  @Req() request: AuthenticatedRequest,
  @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
) {
  const user = await this.getAuthenticatedUser(request);

  await firstValueFrom(
    this.maintenancesService
      .send('softDeleteMaintenancesByVehicleId', { vehicleId })
      .pipe(
        timeout(15_000),
        catchError((error) => {
          throw new RpcException({
            message: error?.message ?? 'Failed to soft-delete vehicle maintenances',
            status: HttpStatus.BAD_GATEWAY,
          });
        }),
      ),
  );

  await firstValueFrom(
    this.vehiclesService
      .send('softDeleteVehicle', { vehicleId, ownerId: user.id })
      .pipe(
        catchError((error) => {
          throw new RpcException({
            message: error.message,
            status: error?.status ?? HttpStatus.NOT_FOUND,
          });
        }),
      ),
  );

  return { message: 'Vehicle deleted successfully', status: HttpStatus.OK };
}
```

**Route placement** (final order in the controller):
1. `@Get('my')` — existing
2. `@Post('my')` — existing
3. `@Put('my/:vehicleId/main')` — existing
4. `@Delete('my/:vehicleId')` — **NEW, insert here**
5. `@Get(':id')` — existing
6. `@Patch(':id')` — existing
7. `@Delete('hard-delete/:id')` — existing, do NOT modify
8. `@Post/:vehicleId/soat`, `@Get/:vehicleId/soat`, `@Delete/:vehicleId/soat` — existing
9. `@Post/:vehicleId/tecnomecanica`, etc. — existing

---

## 5. Tests (vehicles-ms/src/vehicles/vehicles.service.spec.ts) — CREATE

Tests must cover:
- `softDeleteVehicle`: ownership check → 403 when ownerId mismatch
- `softDeleteVehicle`: 404 when vehicleId not found
- `softDeleteVehicle`: promotes next active vehicle as main when deleted vehicle was main
- `softDeleteVehicle`: does NOT promote if deleted vehicle was not main
- `softDeleteVehicle`: no new main vehicle if no active vehicles remain
- `findByOwnerId`: excludes `isDeleted: true` and `isArchived: true` rows
- `findMainVehicleByOwnerId`: excludes `isDeleted: true` and `isArchived: true`
- `findByIdOrNull`: returns vehicle even when `isDeleted: true` (historical access)
- `create()`: marks new vehicle as `isMainVehicle: true` when only prior vehicles are archived/deleted

Use the patterns in `soat.service.spec.ts` and `tecnomecanica.service.spec.ts` as reference.

---

## 6. Compile check

```bash
# In vehicles-ms/
npx tsc --noEmit

# In api-gateway/
npx tsc --noEmit

# Run tests
npx jest src/vehicles/vehicles.service.spec.ts
```

---

## No changes needed in

- `maintenances-ms` — `softDeleteMaintenancesByVehicleId` MessagePattern already exists and works
- `rideglory-contracts` — no new DTOs required
- `events-ms`, `users-ms`, `notifications-ms` — not in scope

> Full detail: handoffs/architect.md
