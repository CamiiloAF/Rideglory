> Slim handoff — read this before handoffs/architect.md

# Architect → QA — Phase 01: soft-delete de vehículos

**Date:** 2026-06-16T18:29:16Z

---

## Flutter (sin cambios en esta fase)

```bash
dart analyze          # debe pasar sin errores
flutter test          # debe pasar en verde
```

No hay cambios en `lib/` en esta fase. Estos comandos verifican que los cambios de backend no introdujeron regresiones en el cliente.

---

## Backend — criterios de aceptación trazables

### CA-01: Listado excluye vehículos eliminados/archivados

`GET /api/vehicles/my` con token válido → ningún vehículo con `isDeleted: true` ni `isArchived: true` en la respuesta.

### CA-02: Soft-delete exitoso (200)

`DELETE /api/vehicles/my/:vehicleId` con token del owner → `200 { message: "Vehicle deleted successfully", status: 200 }`.
Verificar con Prisma Studio o psql: la fila existe con `isDeleted: true`.

### CA-03: Acceso no autorizado (403)

`DELETE /api/vehicles/my/:vehicleId` con token de usuario distinto al owner → `403`.

### CA-04: Vehículo inexistente (404)

`DELETE /api/vehicles/my/:vehicleId` con UUID que no existe → `404`.

### CA-05: Promoción de main al eliminar el main

Si el vehículo eliminado tenía `isMainVehicle: true`, el siguiente vehículo activo (`isArchived: false, isDeleted: false`) ordenado por `createdAt desc` pasa a `isMainVehicle: true`.

### CA-06: Sin promoción si no era main

Si el vehículo eliminado NO era `isMainVehicle`, ningún otro vehículo cambia.

### CA-07: Sin main si no hay vehículos activos

Si el owner no tiene más vehículos activos tras el soft-delete, ningún vehículo queda con `isMainVehicle: true`.

### CA-08: Snapshots históricos accesibles

El MessagePattern `getVehicleById` / `findByIdOrNull` retorna el vehículo aunque tenga `isDeleted: true`. Verificar directamente en la DB o mediante el consumer de events-ms.

### CA-09: Bugfix de conteo en create

Crear un vehículo cuando el único previo está archivado o eliminado → el nuevo vehículo se marca `isMainVehicle: true`.

### CA-10: hard-delete intacto

`DELETE /api/vehicles/hard-delete/:id` sigue funcionando con hard-delete físico. La fila debe desaparecer de la tabla.

### CA-11: `isDeleted` no expuesto al cliente

`GET /api/vehicles/my` no incluye el campo `isDeleted` en la respuesta JSON.

### CA-12: Migración no destructiva

El SQL en `prisma/migrations/<ts>_add_soft_delete_to_vehicle/migration.sql` contiene SOLO `ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false`.

### CA-13: TypeScript compila sin errores

`npx tsc --noEmit` en vehicles-ms y api-gateway pasan sin errores.

### CA-14: Tests Jest pasan

`npx jest src/vehicles/vehicles.service.spec.ts` en vehicles-ms: todos los tests en verde.

---

## Orden de validación recomendado

1. Migración SQL (CA-12) — inspeccionar antes de aplicar
2. TypeScript compile (CA-13)
3. Jest tests (CA-14)
4. Integration manual: CA-01 → CA-11

> Full detail: handoffs/architect.md
